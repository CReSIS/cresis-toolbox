function loadPB_callback(obj,hObj,event)
% mapwin.loadPB_callback(obj,hObj,event)
%
% "load" pushbutton callback which loads new echo windows, called when user
% presses load button or double clicks a frame. Loads the "obj.map.sel"
% frame.

%% Setup

% Check to make sure a frame has been selected before we load
if isempty(obj.map.sel.frm_str)
  uiwait(msgbox('No frame selected, select frames with ctrl+left-click or using search','Error loading','modal'));
  return;
end

if strcmpi(obj.cur_map_pref_settings.layer_source,'ops')
  % Check to make sure the standard:surface layer is selected before we load
  found_surface = false;
  for idx=1:length(obj.cur_map_pref_settings.layers.lyr_name)
    if strcmp(obj.cur_map_pref_settings.layers.lyr_name{idx},'surface') ...
        && strcmp(obj.cur_map_pref_settings.layers.lyr_group_name{idx},'standard')
      found_surface = true;
    end
  end
  if ~found_surface
    uiwait(msgbox('standard:surface layer must be selected in mapwin prefs','Error loading','modal'));
    return;
  end
end

% Change the pointer to a watch/busy
set(obj.h_fig,'Pointer','watch');
drawnow;

%% Get the echowin that the current frame will be loaded into
idx = get(obj.top_panel.picker_windowPM,'Value');
if idx > 1
  %% Loading into a pre-existing window
  echo_idx = idx-1;
  exists_flag = true;
  cancel_operation = obj.echowin_list(echo_idx).undo_stack_modified_check();
  if cancel_operation
    set(obj.h_fig,'Pointer','Arrow');
    return;
  end
  obj.echowin_list(echo_idx).cmds_set_undo_stack([]);
else
  %% Loading into a new window, Create a new echowin class
  % Get the index for this new echowin
  echo_idx = length(obj.echowin_list) + 1;
  exists_flag = false;
  new_echowin = imb.echowin([],obj.default_params.echowin);
  
  % Add the new class instance to the echowin_list
  obj.echowin_list(echo_idx) = new_echowin;
  
  % Add a new entry in the picker window popup menu and set the active
  % entry to this new entry
  menu_string = get(obj.top_panel.picker_windowPM,'String');
  if strcmpi(class(obj.echowin_list(echo_idx).h_fig),'double')
    menu_string{end+1} = sprintf('%d: Echo',obj.echowin_list(echo_idx).h_fig);
  else
    menu_string{end+1} = sprintf('%d: Echo',obj.echowin_list(echo_idx).h_fig.Number);
  end
  set(obj.top_panel.picker_windowPM,'String',menu_string);
  set(obj.top_panel.picker_windowPM,'Value',echo_idx+1);
  
  % Set up the listeners
  addlistener(obj.echowin_list(echo_idx),'close_window',@obj.close_echowin);
  addlistener(obj.echowin_list(echo_idx),'update_echowin_flightline',@obj.update_echowin_flightlines);
  addlistener(obj.echowin_list(echo_idx),'update_cursors',@obj.update_echowin_cursors);
  addlistener(obj.echowin_list(echo_idx),'update_map_selection',@obj.update_map_selection_echowin);
  addlistener(obj.echowin_list(echo_idx),'open_crossover_event',@obj.open_crossover_echowin);
  addlistener(obj.echowin_list(echo_idx).tool.list{7},'ascope_memory',@obj.ascope_memory); % Connect picktool_browse tool to ascope
  
  % Create a selection plot that identifies the echowin on the map
  obj.echowin_maps(echo_idx).h_cursor = plot(obj.map_panel.h_axes, [NaN],[NaN],'kx','LineWidth',2,'MarkerSize',10);
  obj.echowin_maps(echo_idx).h_line = plot(obj.map_panel.h_axes, [NaN],[NaN],'g.');
  obj.echowin_maps(echo_idx).h_text = text(0, 0, '', 'parent', obj.map_panel.h_axes);
end

%  Draw the echo class in the selected echowin
param = [];
param.sources = obj.cur_map_pref_settings.sources;
param.layers = obj.cur_map_pref_settings.layers;
param.cur_sel = obj.map.sel;
param.cur_sel.frm = str2num(param.cur_sel.frm_str(13:end));
param.cur_sel.location = obj.cur_map_pref_settings.map_zone;
param.cur_sel.day_seg = param.cur_sel.frm_str(1:11);
if strcmp(obj.cur_map_pref_settings.system,'tracks')
  param.system = param.cur_sel.radar_name;
  param.cur_sel.radar_name = param.cur_sel.radar_name;
  param.cur_sel.season_name = param.cur_sel.season_name;
  % Layerdata includes system and season because segment IDs are only
  % unique for a particular system_season pair
  system_name_full = [param.system '_' param.cur_sel.season_name];
else
  param.system = obj.cur_map_pref_settings.system;
  param.cur_sel.radar_name = obj.cur_map_pref_settings.system;
  % OPS includes only the system because segment IDs are unique for each
  % system
  system_name_full = obj.cur_map_pref_settings.system;
end
param.layer_source = obj.cur_map_pref_settings.layer_source;
param.layer_data_source = obj.cur_map_pref_settings.layer_data_source;

%-------------------------------------------------------------------------
%% Create link between the echowin and undo_stack list

% Look through the unique identifiers in the undo stack document list to
% see if an undo stack already exists for this echowin's system-segment
% combination
undo_stack_match_idx = [];
for stack_idx = 1:length(obj.undo_stack_list)
  if strcmpi(obj.undo_stack_list(stack_idx).unique_id{1}, param.layer_source) ...
      && strcmpi(obj.undo_stack_list(stack_idx).unique_id{2}, param.system) ...
      && strcmpi(obj.undo_stack_list(stack_idx).unique_id{3}, param.cur_sel.season_name) ...
      && obj.undo_stack_list(stack_idx).unique_id{4} == obj.map.sel.seg_id
    % An undo stack already exists for this layer_source-system-season-segment tuple
    undo_stack_match_idx = stack_idx;
    break;
  end
end

%% LayerData: Load layerdata into undostack
layer_info = [];
layer_organizer = [];
param.frame = [];
param.frame_idxs = [];
param.filename = {};
param.map = obj.map;
if strcmpi(param.layer_source,'layerdata')
  % Find this season in the list of seasons
  if strcmp(obj.cur_map_pref_settings.system,'tracks')
    % Season layer files: Load segment information
    season_idx = find(strcmp(system_name_full,obj.cur_map_pref_settings.seasons));
    % Create a mask that identifies the frames for the selected segment in this season
    frm_idxs = find(param.cur_sel.seg_id == floor(obj.trackdata.frm_info(season_idx).frm_id/1000));
    num_frm = length(frm_idxs);
  else
    % OPS: Load segment information
    ops_param = struct('properties',[]);
    ops_param.properties.location = param.cur_sel.location;
    ops_param.properties.segment_id = param.cur_sel.seg_id;
    [status,data] = opsGetSegmentInfo(param.system,ops_param);
    num_frm = length(data.properties.frame);
    % Database may return them out of order
    param.start_gps_time = sort(double(data.properties.start_gps_time));
    param.stop_gps_time = sort(double(data.properties.stop_gps_time));
  end

  % Load layer organizer file into param.layers
  %   param.layers.lyr_age % layer_organizer.lyr_age (age of layer or NaN)
  %   param.layers.lyr_age_source % layer_organizer.lyr_age_source (age of layer or NaN)
  %   param.layers.lyr_desc % layer_organizer.lyr_desc (layer description string)
  %   param.layers.lyr_group_name = % layer_organizer.lyr_group_name (string)
  %   param.layers.lyr_id % Immutable lyr_id
  %   param.layers.lyr_name % layer_organizer.lyr_name
  %   param.layers.lyr_order % layer_organizer.lyr_order (positive integer contained in 1 to N)
  
  layer_organizer_fn = fullfile(ct_filename_out(param.cur_sel,param.layer_data_source,''),sprintf('layer_%s.mat',param.cur_sel.day_seg));
  fprintf('Loading layer organizer: %s\n', layer_organizer_fn);
  layer_fn_dir = ct_filename_out(param.cur_sel,param.layer_data_source,'');
  fprintf('Loading layer files: %s\n', layer_fn_dir);
  param_layerdata = param.cur_sel;
  param_layerdata.sw_version = current_software_version();
  param_layerdata.records.gps.time_offset = NaN;
  param_layerdata.radar.lever_arm_fh = [];
  layers = layerdata(param_layerdata,param.layer_data_source);
  layers.check_layer_organizer();
  
  for frm = 1:num_frm
    % Stores the filename for all frames in the segment
    param.filename{frm} = layers.layer_fn(frm);
    gps_time = layers.gps_time(frm); % Get the gps_time to take its length
    Nx = length(gps_time);
    param.frame(end+(1:Nx)) = frm; % stores the frame number for each point path id in each frame
    param.frame_idxs(end+(1:Nx)) = 1:length(gps_time);  % contains the point number for each individual point in each frame
    % Stores the layer information for all frames in the segment
    if frm == 1
      layer_info = layers.layer{frm};
    else
      layer_info(end+1) = layers.layer{frm};
    end
  end
  
  param.layers.lyr_age = layers.layer_organizer.lyr_age;
  param.layers.lyr_age_source = layers.layer_organizer.lyr_age_source;
  param.layers.lyr_desc = layers.layer_organizer.lyr_desc;
  param.layers.lyr_group_name = layers.layer_organizer.lyr_group_name;
  param.layers.lyr_id = layers.layer_organizer.lyr_id;
  param.layers.lyr_name = layers.layer_organizer.lyr_name;
  param.layers.lyr_order = layers.layer_organizer.lyr_order;
  
  [~,new_order] = sort(param.layers.lyr_order);
  param.layers.lyr_age = param.layers.lyr_age(new_order);
  param.layers.lyr_age_source = param.layers.lyr_age_source(new_order);
  param.layers.lyr_desc = param.layers.lyr_desc(new_order);
  param.layers.lyr_group_name = param.layers.lyr_group_name(new_order);
  param.layers.lyr_id = param.layers.lyr_id(new_order);
  param.layers.lyr_name = param.layers.lyr_name(new_order);
  param.layers.lyr_order = param.layers.lyr_order(new_order);
  
  if strcmp(obj.cur_map_pref_settings.system,'tracks')
    param.start_gps_time = obj.trackdata.frm_info(season_idx).start_gps_time(frm_idxs);
    param.stop_gps_time = obj.trackdata.frm_info(season_idx).stop_gps_time(frm_idxs);
  end

else
  % OPS: Load segment information
  ops_param = struct('properties',[]);
  ops_param.properties.location = param.cur_sel.location;
  ops_param.properties.segment_id = param.cur_sel.seg_id;
  [status,data] = opsGetSegmentInfo(param.system,ops_param);
  num_frm = length(data.properties.frame);
  % Database may return them out of order
  param.start_gps_time = sort(double(data.properties.start_gps_time));
  param.stop_gps_time = sort(double(data.properties.stop_gps_time));

  param.layers.lyr_age = nan(size(param.layers.lyr_id)); % layer.age (age of layer or NaN)
  param.layers.lyr_age_source = cell(size(param.layers.lyr_id)); % layer.age_source (struct vector of age sources)
  param.layers.lyr_desc = cellfun(@char,cell(size(param.layers.lyr_id)),'UniformOutput',false); % layer.desc (layer description string)
  param.layers.lyr_order = [1:length(param.layers.lyr_id)]; % layer.order (positive integer, 1 to N where N is the number of layers)
  layers.layer_organizer = param.layers;
  
end

if isempty(undo_stack_match_idx)
  % An undo stack does not exist for this layer_source system season
  % segment tuple, so create a new undo stack
  param.id = {param.layer_source param.system param.cur_sel.season_name obj.map.sel.seg_id};
  obj.undo_stack_list(end+1) = imb.undo_stack(param);
  undo_stack_match_idx = length(obj.undo_stack_list);
end

% Attach echowin to the undo stack
cmds_list = obj.echowin_list(echo_idx).cmds_set_undo_stack(obj.undo_stack_list(undo_stack_match_idx));
% user_data: This is only used for param.layer_source == 'layerdata' except
% for the field param.layer_source.
obj.undo_stack_list(undo_stack_match_idx).user_data.layer_source = param.layer_source; % string containing layer source ('OPS' or 'layerdata')
obj.undo_stack_list(undo_stack_match_idx).user_data.layer_data_source = param.layer_data_source; % string containing layer source ('OPS' or 'layerdata')
obj.undo_stack_list(undo_stack_match_idx).user_data.layer_info = layer_info; % contains the layer twtt/name/quality/type/etc information
obj.undo_stack_list(undo_stack_match_idx).user_data.layer_organizer = layers.layer_organizer; % contains the layer parameters (age, desc, group_name, id, name, order)
obj.undo_stack_list(undo_stack_match_idx).user_data.frame = param.frame; % contains the frame number for each point path id
obj.undo_stack_list(undo_stack_match_idx).user_data.frame_idxs = param.frame_idxs; % contains the point number for each individual point in each frame
obj.undo_stack_list(undo_stack_match_idx).user_data.filename = param.filename; % contains the frame filenames

%%
try
  obj.echowin_list(echo_idx).draw(param);
catch ME
  % Draw failed... close echo window and report error
  obj.close_echowin(obj.echowin_list(echo_idx));
  set(obj.h_fig,'Pointer','Arrow');
  rethrow(ME);
end

% Since there may be commands in the undo stack already, we will run these
% commands so that the new echowin is synced up with the stack.
obj.echowin_list(echo_idx).cmds_set_undo_stack_after_draw(cmds_list);

%% Cleanup
set(obj.h_fig,'Pointer','Arrow');
