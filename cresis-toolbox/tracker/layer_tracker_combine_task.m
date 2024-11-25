function success = layer_tracker_combine_task(param)
% success = layer_tracker_combine_task(param)
%
% Combines temporary layer data from layer_tracker_task.m and stores the
% output with opsCopyLayers. See run_layer_tracker.m.
%
% Authors: Anjali Pare, John Paden
%
% See also: layer_tracker.m, layer_tracker_combine_task.m,
% layer_tracker_task.m, layer_tracker_input_check.m,
% layer_tracker_profile.m, run_layer_tracker.m, run_layer_tracker_tune.m

%% Setup Processing
% =====================================================================
frames = frames_load(param);

% Create output directory path
if strcmp(param.layer_tracker.layer_params.source,'ops')
  tmp_out_fn_dir_dir = ct_filename_out(param,'ops','layer_tracker_tmp');
else
  tmp_out_fn_dir_dir = ct_filename_out(param,param.layer_tracker.layer_params.layerdata_source,'layer_tracker_tmp');
end

layer_dest.name = {};
layer_dest.age = {};
layer_dest.age_source = {};
layer_dest.desc = {};
layer_dest.group_name = {};
layer_source.twtt = [];
layer_source.gps_time = [];

%% Track loop
% =====================================================================
% Combine and Copy each tracking result
for track_idx = 1:length(param.layer_tracker.track)
  track = param.layer_tracker.track{track_idx};
  %% Track: Load in all temporary files
  % =====================================================================
  gps_time = [];
  twtt = [];
  for frm_idx = 1:length(param.cmd.frms)
    frm = param.cmd.frms(frm_idx);
    
    if ct_proc_frame(frames.proc_mode(frm),param.layer_tracker.frm_types)
      fprintf('layer_tracker_combine frame %s_%03i (%i of %i) %s\n', param.day_seg, frm, frm_idx, length(param.cmd.frms), datestr(now));
    else
      fprintf('Skipping frame %s_%03i (no process frame)\n', param.day_seg, frm);
      continue;
    end
    
    tmp_out_fn_name = sprintf('t%03d_%s.mat', track_idx, track.method);
    tmp_out_fn = fullfile(tmp_out_fn_dir_dir,sprintf('layer_tracker_%03d', frm),tmp_out_fn_name);
    fprintf('Loading %s (%s)\n', tmp_out_fn, datestr(now));
    tmp = load(tmp_out_fn);
    
    Nx = length(tmp.gps_time);
    gps_time(1,end+(1:Nx)) = tmp.gps_time;
    try
%       if size(tmp.twtt,1) ~= length(param.layer_tracker.track{track_idx}.lsm.storeIter) * 2
%         tmp.twtt(36,:) = tmp.twtt(35,:);
%       end
      twtt(:,end+(1:Nx)) = tmp.twtt;
    catch ME
      tmp.twtt(36,:) = tmp.twtt(35,:);
      twtt(:,end+(1:Nx)) = tmp.twtt;
    end
      
  end
  
  %% Track: opsCopyLayer copy struct
  % =====================================================================
  param.layer_tracker.copy_param.gaps_fill.method = 'preserve_gaps';
  copy_param = param.layer_tracker.copy_param;
  copy_param.layer_source.existence_check = false;
  copy_param.layer_source.source = 'custom';
  copy_param.layer_source.gps_time = gps_time;
  copy_param.layer_dest = param.layer_tracker.layer_params;
  copy_param.layer_dest.existence_check = false;
  if ~isfield(param.layer_tracker.track{track_idx},'layer_names') || isempty(param.layer_tracker.track{track_idx}.layer_names)
    automated_name_en = true;
  else
    automated_name_en = false;
    layer_dest.name = param.layer_tracker.track{track_idx}.layer_names;
  end
  
  %% Track: Copy each layer
  % =====================================================================
  for layer_idx = 1:size(twtt,1)
    if automated_name_en
      switch track.method
        case 'lsm'
          if layer_idx <= length(track.lsm.storeIter)
            layer_dest.name{end+1} = sprintf('%s_%s_surface_%03d', ...
              track.name,track.method,layer_idx);
            layer_dest.desc{end+1} =  sprintf('y = %d, dy = %d, iter = %d', ...
              track.lsm.y,track.lsm.dy,layer_idx);
          else
            layer_dest.name{end+1} = sprintf('%s_%s_bottom_%03d', ...
              track.name,track.method,layer_idx-length(track.lsm.storeIter));
            layer_dest.desc{end+1} =  sprintf('y = %d, dy = %d, iter = %d', ...
              track.lsm.y,track.lsm.dy,layer_idx-length(track.lsm.storeIter));
          end
        case {'mcmc','stereo'}
          if layer_idx == 1
            layer_dest.name{end+1} = sprintf('%s_%s_surface',track.name,track.method);
          else
            layer_dest.name{end+1} = sprintf('%s_%s_bottom',track.name,track.method);
          end
        case 'viterbi'
          layer_dest.name{end+1} = sprintf('%s_%s_bottom',track.name,track.method);
          layer_dest.desc{end+1} =  sprintf('smoothness = %d', track.viterbi.transition_weight);
        otherwise
          layer_dest.name{end+1} = sprintf('%s_%s_surface',track.name,track.method);
      end
    end
    
    layer_source.twtt{end+1} = twtt(layer_idx,:);
    layer_source.gps_time{end+1} = gps_time;
    
    % Update age, age_source, desc, and group_name if override values are
    % given
    if iscell(track.age) && length(track.age) >= layer_idx
      layer_dest.age{end+1} = track.age{layer_idx};
    elseif ~isempty(track.age)
      layer_dest.age{end+1} = track.age;
    end
    if iscell(track.age_source) && length(track.age_source) >= layer_idx
      layer_dest.age_source{end+1} = track.age_source{layer_idx};
    elseif ~isempty(track.age_source)
      layer_dest.age_source{end+1} = track.age_source;
    end
    if iscell(track.desc) && length(track.desc) >= layer_idx
      layer_dest.desc{end+1} = track.desc{layer_idx};
    elseif ~isempty(track.desc)
      layer_dest.desc{end+1} = track.desc;
    end
    if iscell(track.group_name) && length(track.group_name) >= layer_idx
      layer_dest.group_name{end+1} = track.group_name{layer_idx};
    elseif ~isempty(track.group_name)
      layer_dest.group_name{end+1} = track.group_name;
    end
    
  end
  
end

copy_param.layer_source.gps_time = layer_source.gps_time;
copy_param.layer_source.twtt = layer_source.twtt;
copy_param.layer_dest.name = layer_dest.name;
copy_param.layer_source.age = layer_dest.age;
copy_param.layer_source.age_source = layer_dest.age_source;
copy_param.layer_source.desc = layer_dest.desc;
copy_param.layer_source.group_name = layer_dest.group_name;

fprintf('opsCopyLayers %s (%s)\n', param.day_seg, datestr(now));
opsCopyLayers(param,copy_param);

fprintf('Done (%s)\n', datestr(now));
success = true;
