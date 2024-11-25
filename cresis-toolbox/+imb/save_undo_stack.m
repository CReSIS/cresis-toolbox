function save_undo_stack(undo_stack)
% imb.save_undo_stack(undo_stack)
%
% Support function for echowin and mapwin classes.  Does the actual
% saving of commands in the undo stack.
%

% =========================================================================
% IMPORTANT NOTE:
% cmds_list: The structure of each command is explained in
%   imb.echowin.cmds.cmds_execute.m/cmds_execute_insert
%   imb.echowin.cmds.cmds_execute.m/cmds_execute_delete
%
% The command list is two lists deep (i.e. a list of lists)
% 1. cmds_list is a cell vector of commands
% 2. Each cell contains a struct vector of commands (sub_idxs)
% 3. The database save operation does not care about the cell vector/struct vector
%    boundaries and so this save function flattens the lists into a single list.
%    (FYI: Undo/redo operations execute all the commands in a cell and
%    that is why the double list is used.)
% =========================================================================

% Get the command list for this undo stack and delete these commands from
% the list.
cmds_list = undo_stack.get_save_cmds(true);

%% Group commands by layer
cmd_type = char([]);
cmd_layers = [];
cmd_args = {};
cmd_idxs = [];
sub_idxs = [];
% Flatten command list struct to make it easy to parse and apply matrix
% operations to it
for cmd_idx = 1:length(cmds_list)
  for sub_idx = 1:length(cmds_list{cmd_idx})
    if strcmpi(cmds_list{cmd_idx}(sub_idx).redo_cmd,'insert')
      cmd_type(end+1) = 'i';
    elseif strcmpi(cmds_list{cmd_idx}(sub_idx).redo_cmd,'delete')
      cmd_type(end+1) = 'd';
    elseif strcmpi(cmds_list{cmd_idx}(sub_idx).redo_cmd,'layer_new')
      cmd_type(end+1) = 'n';
    elseif strcmpi(cmds_list{cmd_idx}(sub_idx).redo_cmd,'layer_delete')
      cmd_type(end+1) = 'r'; % remove/delete
    elseif strcmpi(cmds_list{cmd_idx}(sub_idx).redo_cmd,'layer_edit')
      cmd_type(end+1) = 'e';
    end
    cmd_layers(end+1) = cmds_list{cmd_idx}(sub_idx).redo_args{1};
    cmd_args{end+1} = cmds_list{cmd_idx}(sub_idx).redo_args;
    cmd_idxs(end+1) = cmd_idx;
    sub_idxs(end+1) = sub_idx;
  end
end

% Get a list of unique database layer IDs that are being modified
unique_layers = unique(cmd_layers);
if isempty(unique_layers)
  unique_layers = [];
end
frames = [];
layerdata_frms = []; % List of frames that have been modified
for cur_layer = unique_layers
  % Commit the commands for each layer, one layer at a time
  fprintf('Saving layer id %d\n', cur_layer);
  param.properties.lyr_id = cur_layer;
  
  % Get the commands for just this layer
  cur_layer_cmds = find(cur_layer == cmd_layers);
  cur_cmd_type = cmd_type(cur_layer_cmds);
  cur_cmd_idxs = cmd_idxs(cur_layer_cmds);
  cur_sub_idxs = sub_idxs(cur_layer_cmds);
  
  %% OPS: Inserting and deleting points
  if strcmpi(undo_stack.user_data.layer_source,'OPS')
    % Loop through commands. If multiple inserts are done, these are
    % combined into a single insert
    cur_layer_cmd_idx = 1;
    while cur_layer_cmd_idx <= length(cur_layer_cmds)
      cmd_idx = cur_cmd_idxs(cur_layer_cmd_idx);
      sub_idx = cur_sub_idxs(cur_layer_cmd_idx);
      if cur_cmd_type(cur_layer_cmd_idx) == 'i'
        param.properties.point_path_id = cmds_list{cmd_idx}(sub_idx).redo_args{2};
        param.properties.twtt = cmds_list{cmd_idx}(sub_idx).redo_args{3};
        param.properties.type = cmds_list{cmd_idx}(sub_idx).redo_args{4};
        param.properties.quality = cmds_list{cmd_idx}(sub_idx).redo_args{5};
        fprintf('  Insert %d points\n', length(cmds_list{cmd_idx}(sub_idx).redo_args{2}));
        % Append any following insert commands onto this command... (if we
        % hit the end of the command list or a delete command we stop appending)
        cur_layer_cmd_idx = cur_layer_cmd_idx + 1;
        while cur_layer_cmd_idx <= length(cur_layer_cmds) ...
            && cur_cmd_type(cur_layer_cmd_idx) == 'i'
          cmd_idx = cur_cmd_idxs(cur_layer_cmd_idx);
          sub_idx = cur_sub_idxs(cur_layer_cmd_idx);
          param.properties.point_path_id = cat(2,param.properties.point_path_id, ...
            cmds_list{cmd_idx}(sub_idx).redo_args{2});
          param.properties.twtt = cat(2, param.properties.twtt, ...
            cmds_list{cmd_idx}(sub_idx).redo_args{3});
          param.properties.type = cat(2, param.properties.type, ...
            cmds_list{cmd_idx}(sub_idx).redo_args{4});
          param.properties.quality = cat(2, param.properties.quality, ...
            cmds_list{cmd_idx}(sub_idx).redo_args{5});
          cur_layer_cmd_idx = cur_layer_cmd_idx + 1;
          fprintf('  Insert %d points appended\n', length(cmds_list{cmd_idx}(sub_idx).redo_args{2}));
        end
        fprintf(' Insert commit\n');
        % Remove duplicate point ID/layerIDs
        valid_mask = logical(ones(size(param.properties.point_path_id)));
        for idx = length(valid_mask):-1:1
          if ~isempty(find(param.properties.point_path_id(idx+1:end) ...
              == param.properties.point_path_id(idx)))
            valid_mask(idx) = 0;
          end
        end
        param.properties.point_path_id = param.properties.point_path_id(valid_mask);
        param.properties.twtt = param.properties.twtt(valid_mask);
        param.properties.type = param.properties.type(valid_mask);
        param.properties.quality = param.properties.quality(valid_mask);
        opsCreateLayerPoints(undo_stack.unique_id{2},param);
      else
        param.properties.start_point_path_id = cmds_list{cmd_idx}(sub_idx).redo_args{3}(1);
        param.properties.stop_point_path_id = cmds_list{cmd_idx}(sub_idx).redo_args{3}(2);
        param.properties.min_twtt = cmds_list{cmd_idx}(sub_idx).redo_args{2}(3);
        param.properties.max_twtt = cmds_list{cmd_idx}(sub_idx).redo_args{2}(4);
        cur_layer_cmd_idx = cur_layer_cmd_idx + 1;
        fprintf(' Delete commit\n');
        opsDeleteLayerPoints(undo_stack.unique_id{2},param);
      end %end of if insert or delete
    end %while cur_layer_cmds end
    
    %% LayerData
  elseif strcmpi(undo_stack.user_data.layer_source,'layerdata')
    % (undo|redo)args fields:
    % 1: layer (array? of layer indices)
    % 2: point ids (index into the segment starting at 1)
    % 3: twtt (us)
    % 4: type (1 for manual or 2 for auto)
    % 5: quality (1 for good, 2 for moderate, or 3 for bad)
    
    % Keep a list of all frames that are modified
    cur_layer_cmd_idx = 1;
    while cur_layer_cmd_idx <= length(cur_layer_cmds)
      cmd_idx = cur_cmd_idxs(cur_layer_cmd_idx);
      sub_idx = cur_sub_idxs(cur_layer_cmd_idx);
      if cur_cmd_type(cur_layer_cmd_idx) == 'i'
        %% LayerData: Inserting Points
        % gets information about which points are to be inserted and updates
        % the layerData file accordingly. Performs necessary steps to convert
        % from the unique point_path_id to a point number relative to that position
        % in a single frame
        % Get list of frames that were modified by this command
        frms = unique(undo_stack.user_data.frame(cmds_list{cmd_idx}(sub_idx).redo_args{2}));
        % Add list of frames to the layerdata_frms list
        layerdata_frms = [layerdata_frms frms];
        % Create a mask of the modified points that are type manual
        manual_mask = cmds_list{cmd_idx}(sub_idx).redo_args{4} == 1;
        for frm_idx = 1:length(frms)
          frm = frms(frm_idx);
          % Create a mask for the modified points that is this frame only
          frm_mask = undo_stack.user_data.frame(cmds_list{cmd_idx}(sub_idx).redo_args{2}) == frm;
          % Identify the modified points that are part of this frame
          all_frame_idxs = undo_stack.user_data.frame_idxs(cmds_list{cmd_idx}(sub_idx).redo_args{2}(frm_mask));
          % Identify the modified points that are part of this frame that
          % are manual
          manual_frame_idxs = undo_stack.user_data.frame_idxs(cmds_list{cmd_idx}(sub_idx).redo_args{2}(frm_mask & manual_mask));
          
          % Determine the layer index associated with this layer ID
          lay_idx = find(cur_layer == undo_stack.user_data.layer_info(frm).id);
          if isempty(lay_idx)
            % Layer does not exist in this layerData file yet
            lay_idx = length(undo_stack.user_data.layer_info(frm).id) + 1;
            Nx = length(undo_stack.user_data.layer_info(frm).gps_time);
            undo_stack.user_data.layer_info(frm).id(lay_idx) = cur_layer;
            undo_stack.user_data.layer_info(frm).quality(lay_idx,:) = ones(1,Nx);
            undo_stack.user_data.layer_info(frm).twtt(lay_idx,:) = nan(1,Nx);
            undo_stack.user_data.layer_info(frm).type(lay_idx,:) = 2*ones(1,Nx);
          end
          
          % Update quality
          undo_stack.user_data.layer_info(frm).quality(lay_idx,all_frame_idxs) ...
            = cmds_list{cmd_idx}(sub_idx).redo_args{5}(frm_mask);
          % Update type
          undo_stack.user_data.layer_info(frm).type(lay_idx,all_frame_idxs) ...
            = cmds_list{cmd_idx}(sub_idx).redo_args{4}(frm_mask);
          % Update twtt
          undo_stack.user_data.layer_info(frm).twtt(lay_idx,all_frame_idxs) ...
            = cmds_list{cmd_idx}(sub_idx).redo_args{3}(frm_mask);
        end
        cur_layer_cmd_idx = cur_layer_cmd_idx + 1;
        
      elseif cur_cmd_type(cur_layer_cmd_idx) == 'd'
        %% LayerData: Deleting Points
        % gets information about which points are to be deleted and updates
        % the layerData file accordingly. Performs necessary steps to convert
        % from the unique point_path_id to a point number relative to that position
        % in a single frame.
        % gets the range of points to be deleted and stores it in
        % start_point_path_id, stop_point_path_id, min_twtt and max_twtt
        % respectively
        
        start_idx = cmds_list{cmd_idx}(sub_idx).redo_args{3}(1);
        stop_idx = cmds_list{cmd_idx}(sub_idx).redo_args{3}(2);
        point_ids = start_idx:stop_idx;
        
        % Get list of frames that could have been modified by this command
        frms = unique(undo_stack.user_data.frame(point_ids));
        for frm_idx = 1:length(frms)
          frm = frms(frm_idx);
          % Create a mask for the modified points that is this frame only
          frm_mask = undo_stack.user_data.frame(point_ids) == frm;
          % Identify the modified points that are part of this frame
          all_frame_idxs = undo_stack.user_data.frame_idxs(point_ids(frm_mask));
          
          % Determine the layer index associated with this layer ID
          lay_idx = find(cur_layer == undo_stack.user_data.layer_info(frm).id);
          if ~isempty(lay_idx)
            % Only need to delete points if the layer exists in the data
            % file.
            
            % Get the twtt for all the points that are in the point_ids
            twtt = undo_stack.user_data.layer_info(frm).layerData{lay_idx}.value{2}.data(all_frame_idxs);
            % Mask which ones are to be deleted based on twtt
            delete_mask = twtt > cmds_list{cmd_idx}(sub_idx).redo_args{2}(3) & twtt < cmds_list{cmd_idx}(sub_idx).redo_args{2}(4);
            % Just keep deleted points
            all_frame_idxs = all_frame_idxs(delete_mask);
            % If there are any points to be deleted:
            if ~isempty(all_frame_idxs)
              % 1. Add frm to the layerdata_frms list
              layerdata_frms = [layerdata_frms frm];
              undo_stack.user_data.layer_info(frm).twtt(lay_idx,all_frame_idxs) ...
                = NaN;
            end
          end
        end
        cur_layer_cmd_idx = cur_layer_cmd_idx + 1;
        
      elseif cur_cmd_type(cur_layer_cmd_idx) == 'n'
        %% LayerData: Create New Layer
        id = cmds_list{cmd_idx}(sub_idx).redo_args{1};
        age = cmds_list{cmd_idx}(sub_idx).redo_args{2};
        desc = cmds_list{cmd_idx}(sub_idx).redo_args{3};
        group_name = cmds_list{cmd_idx}(sub_idx).redo_args{4};
        name = cmds_list{cmd_idx}(sub_idx).redo_args{5};
        order = cmds_list{cmd_idx}(sub_idx).redo_args{6};
        
        % Update layer organizer
        % =================================================================
        undo_stack.user_data.layer_organizer.lyr_age(end+1) = age;
        undo_stack.user_data.layer_organizer.lyr_age_source{end+1} = struct('age',{},'source',{},'type',{});
        undo_stack.user_data.layer_organizer.lyr_desc{end+1} = desc;
        undo_stack.user_data.layer_organizer.lyr_group_name{end+1} = group_name;
        undo_stack.user_data.layer_organizer.lyr_id(end+1) = id;
        undo_stack.user_data.layer_organizer.lyr_name{end+1} = name;
        undo_stack.user_data.layer_organizer.lyr_order(end+1) = order;
        % Force save of layer organizer file
        layerdata_frms(end+1) = 0;
        
        % Update layer files
        % =================================================================
        for frm = 1:length(undo_stack.user_data.layer_info)
          % Create a mask for the modified points that is this frame only
          Nx = sum(undo_stack.user_data.frame == frm);
          lay_idx = length(undo_stack.user_data.layer_info(frm).id) + 1;
          undo_stack.user_data.layer_info(frm).twtt(lay_idx,1:Nx) = nan(1,Nx);
          undo_stack.user_data.layer_info(frm).quality(lay_idx,1:Nx) = ones(1,Nx);
          undo_stack.user_data.layer_info(frm).type(lay_idx,1:Nx) = 2*ones(1,Nx);
          undo_stack.user_data.layer_info(frm).id(lay_idx) = id;
          layerdata_frms(end+1) = frm;
        end

        cur_layer_cmd_idx = cur_layer_cmd_idx + 1;
        
      elseif cur_cmd_type(cur_layer_cmd_idx) == 'r'
        %% LayerData: Delete Layer (remove)
        id = cmds_list{cmd_idx}(sub_idx).redo_args{1};

        % Update layer organizer
        % =================================================================
        lay_idx = find(undo_stack.user_data.layer_organizer.lyr_id == id);
        undo_stack.user_data.layer_organizer.lyr_age(lay_idx) = [];
        undo_stack.user_data.layer_organizer.lyr_age_source(lay_idx) = [];
        undo_stack.user_data.layer_organizer.lyr_desc(lay_idx) = [];
        undo_stack.user_data.layer_organizer.lyr_group_name(lay_idx) = [];
        undo_stack.user_data.layer_organizer.lyr_id(lay_idx) = [];
        undo_stack.user_data.layer_organizer.lyr_name(lay_idx) = [];
        undo_stack.user_data.layer_organizer.lyr_order(lay_idx) = [];
        % Force save of layer organizer file
        layerdata_frms(end+1) = 0;
        
        % Update layer files
        % =================================================================
        for frm = 1:length(undo_stack.user_data.layer_info)
          lay_idx = find(id == undo_stack.user_data.layer_info(frm).id);
          if ~isempty(lay_idx)
            undo_stack.user_data.layer_info(frm).id = undo_stack.user_data.layer_info(frm).id([1:lay_idx-1,lay_idx+1:end]);
            undo_stack.user_data.layer_info(frm).quality = undo_stack.user_data.layer_info(frm).quality([1:lay_idx-1,lay_idx+1:end],:);
            undo_stack.user_data.layer_info(frm).type = undo_stack.user_data.layer_info(frm).type([1:lay_idx-1,lay_idx+1:end],:);
            undo_stack.user_data.layer_info(frm).twtt = undo_stack.user_data.layer_info(frm).twtt([1:lay_idx-1,lay_idx+1:end],:);
            layerdata_frms(end+1) = frm;
          end
        end
        
        cur_layer_cmd_idx = cur_layer_cmd_idx + 1;
        
      elseif cur_cmd_type(cur_layer_cmd_idx) == 'e'
        %% LayerData: Edit Layer
        id = cmds_list{cmd_idx}(sub_idx).redo_args{1};
        age = cmds_list{cmd_idx}(sub_idx).redo_args{2};
        desc = cmds_list{cmd_idx}(sub_idx).redo_args{3};
        group_name = cmds_list{cmd_idx}(sub_idx).redo_args{4};
        name = cmds_list{cmd_idx}(sub_idx).redo_args{5};
        order = cmds_list{cmd_idx}(sub_idx).redo_args{6};
        
        % Update layer organizer
        % =================================================================
        lay_idx = find(undo_stack.user_data.layer_organizer.lyr_id == id);
        old_name = undo_stack.user_data.layer_organizer.lyr_name(lay_idx);
        undo_stack.user_data.layer_organizer.lyr_age(lay_idx) = age;
        undo_stack.user_data.layer_organizer.lyr_age_source{lay_idx} = struct('age',{},'source',{},'type',{});
        undo_stack.user_data.layer_organizer.lyr_desc{lay_idx} = desc;
        undo_stack.user_data.layer_organizer.lyr_group_name{lay_idx} = group_name;
        undo_stack.user_data.layer_organizer.lyr_name{lay_idx} = name;
        undo_stack.user_data.layer_organizer.lyr_order(lay_idx) = order;
        % Force save of layer organizer file
        layerdata_frms(end+1) = 0;
        cur_layer_cmd_idx = cur_layer_cmd_idx + 1;
        
      end % if insert/delete/new-layer/delete-layer/edit-layer
    end% while cur_layer_cmd_idx
  end% layer_data end
end% end for loop

%% Save to layerData
if strcmpi(undo_stack.user_data.layer_source,'layerdata')
  layerdata_frms = unique(layerdata_frms);
  
  for idx = 1:length(layerdata_frms)
    frm = layerdata_frms(idx);
    if frm == 0
      layer_organizer = undo_stack.user_data.layer_organizer;
      layer_organizer_fn = fullfile(ct_filename_out(layer_organizer.param,undo_stack.user_data.layer_data_source,''), ...
        sprintf('layer_%s.mat',layer_organizer.param.day_seg));
      ct_save(layer_organizer_fn,'-struct','layer_organizer');
    else
      lay = undo_stack.user_data.layer_info(frm);
      layer_fn = undo_stack.user_data.filename{frm};
      ct_save(layer_fn,'-struct','lay') % saving to layer data file
    end
  end
end

%% Notify all echo windows using this stack of save
undo_stack.save();

