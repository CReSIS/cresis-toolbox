function set_default_params(obj,picker_param_fn)
% set_default_params(obj,picker_param_fn)
%
% Loads factory default preferences and then loads the user's default
% preferences.

%% Set each window's default widths and heights
tmp.pref_w = 440;
tmp.pref_h = 440;
tmp.map_w_arctic    = 480;  % aspect ratio 4/3
tmp.map_h_arctic    = 640;
tmp.map_w_antarctic = 640;  % aspect ratio 1
tmp.map_h_antarctic = 640;
tmp.echo_w = 180+640; % the size of the left panel is 180 so leave 640x480 for the echogram
tmp.echo_h = 480;

% System-dependent code
tmp.monitors = get(0,'MonitorPositions');
if ispc
  % structure of tmp.monitors is Nx4 with N tmp.monitors
  % origin is placed on top edge, positive axis extends right and down
  % (N,1) = left x position
  % (N,2) = top y position
  % (N,3) = stop x position
  % (N,4) = stop y position
  tmp.p_monitor = tmp.monitors(1,:);
  tmp.monitor_w = length(tmp.p_monitor(1):tmp.p_monitor(3));
  tmp.monitor_h = length(tmp.p_monitor(2):tmp.p_monitor(4));
  % PREFWIN
  tmp.pref_x_margin = tmp.monitor_w-tmp.pref_w;
  tmp.pref_y_margin = tmp.monitor_h-tmp.pref_h;
  % height
  if tmp.monitor_h - (tmp.pref_y_margin/2 + tmp.pref_h) > 0
    % fits
    tmp.pref_y = tmp.monitor_h - tmp.pref_y_margin/2 - tmp.pref_h;
  else
    % doesn't fit
    tmp.pref_y = 0;
  end
  % width
  if tmp.monitor_w - (100 + tmp.pref_w) > 0
    % fits
    tmp.pref_x = tmp.p_monitor(1) + 100;
  else
    % doesn't fit
    tmp.pref_x = 0;
  end
  % MAPWIN
  tmp.map_x_arc_margin = tmp.monitor_w-tmp.map_w_arctic;
  tmp.map_y_arc_margin = tmp.monitor_h-tmp.map_h_arctic;
  tmp.map_x_ant_margin = tmp.monitor_w-tmp.map_w_antarctic;
  tmp.map_y_ant_margin = tmp.monitor_h-tmp.map_h_antarctic;
  % height for arctic
  if tmp.monitor_h - (tmp.map_y_arc_margin/2 + tmp.map_h_arctic) > 0
    % fits
    tmp.map_y_arctic = tmp.monitor_h - tmp.map_y_arc_margin/2 - tmp.map_h_arctic;
  else
    % doesn't fit
    tmp.map_y_arctic = 0;
  end
  % height for antarctic
  if tmp.monitor_h - (tmp.map_y_ant_margin/2 + tmp.map_h_antarctic) > 0
    % fits
    tmp.map_y_antarctic = tmp.monitor_h - tmp.map_y_ant_margin/2 - tmp.map_h_antarctic;
  else
    % doesn't fit
    tmp.map_y_antarctic = 0;
  end
  % width for arctic
  if tmp.monitor_w - (100 + tmp.map_w_arctic) > 0
    % fits
    tmp.map_x_arctic = tmp.p_monitor(1) + 100;
  else
    % doesn't fit
    tmp.map_x_arctic = 0;
  end
  % width for antarctic
  if tmp.monitor_w - (100 + tmp.map_w_antarctic) > 0
    % fits
    tmp.map_x_antarctic = tmp.p_monitor(1) + 100;
  else
    % doesn't fit
    tmp.map_x_antarctic = 0;
  end
  % ECHOWIN
  % check for two tmp.monitors
  if size(tmp.monitors,1) > 1
    % if there are two, put the echowin in the second monitor
    tmp.s_monitor = tmp.monitors(2,:);
    tmp.monitor_w = length(tmp.s_monitor(1):tmp.s_monitor(3));
    tmp.monitor_h = length(tmp.s_monitor(2):tmp.s_monitor(4));
    tmp.echo_x_margin = tmp.monitor_w-tmp.echo_w;
    tmp.echo_y_margin = tmp.monitor_h-tmp.echo_h;
    % height
    if tmp.monitor_h - (tmp.echo_y_margin/2 + tmp.echo_h) > 0
      % fits
      tmp.echo_y = tmp.monitor_h - tmp.echo_y_margin/2 - tmp.echo_h;
    else
      % doesn't fit
      tmp.echo_y = 0;
    end
    % width
    if tmp.monitor_w - (100 + tmp.echo_w) > 0
      % fits
      tmp.echo_x = 100;
    else
      % doesn't fit
      tmp.echo_x = 0;
    end
  else
    % otherwise put the echowin in the first monitor
    tmp.echo_x_margin = tmp.monitor_w-tmp.echo_w;
    tmp.echo_y_margin = tmp.monitor_h-tmp.echo_h;
    % height
    if tmp.monitor_h - (tmp.echo_y_margin/2 + tmp.echo_h) > 0
      % fits
      tmp.echo_y = tmp.monitor_h - tmp.echo_y_margin/2 - tmp.echo_h;
    else
      % doesn't fit
      tmp.echo_y = 0;
    end
    % width
    if tmp.monitor_w - (100 + tmp.echo_w) > 0
      % fits
      tmp.echo_x = 100;
    else
      % doesn't fit
      tmp.echo_x = 0;
    end
  end
  
elseif isunix
  % structure of tmp.monitors is Nx4 with N tmp.monitors
  % see 'doc rootobject_props' for layout
  % origin extends right and down from top-left corner of rectangle
  % (N,1) = x offset (from left edge) of monitor
  % (N,2) = y offset (from top edge) of monitor
  % (N,3) = width
  % (N,4) = height
  tmp.p_monitor = tmp.monitors(1,:);
  tmp.monitor_w = tmp.p_monitor(3);
  tmp.monitor_h = tmp.p_monitor(4);
  % PREFWIN
  tmp.pref_x_margin = tmp.monitor_w-tmp.pref_w;
  tmp.pref_y_margin = tmp.monitor_h-tmp.pref_h;
  % height
  if tmp.monitor_h - (tmp.pref_y_margin/2 + tmp.pref_h) > 0
    % fits
    tmp.pref_y = tmp.monitor_h - tmp.pref_y_margin/2 - tmp.pref_h;
  else
    % doesn't fit
    tmp.pref_y = 0;
  end
  % width
  if tmp.monitor_w - (100 + tmp.pref_w) > 0
    % fits
    tmp.pref_x = 100;
  else
    % doesn't fit
    tmp.pref_x = 0;
  end
  % MAPWIN
  tmp.map_x_arc_margin = tmp.monitor_w-tmp.map_w_arctic;
  tmp.map_y_arc_margin = tmp.monitor_h-tmp.map_h_arctic;
  tmp.map_x_ant_margin = tmp.monitor_w-tmp.map_w_antarctic;
  tmp.map_y_ant_margin = tmp.monitor_h-tmp.map_h_antarctic;
  % height for arctic
  if tmp.monitor_h - (tmp.map_y_arc_margin/2 + tmp.map_h_arctic) > 0
    % fits
    tmp.map_y_arctic = tmp.monitor_h - tmp.map_y_arc_margin/2 - tmp.map_h_arctic;
  else
    % doesn't fit
    tmp.map_y_arctic = 0;
  end
  % height for antarctic
  if tmp.monitor_h - (tmp.map_y_ant_margin/2 + tmp.map_h_antarctic) > 0
    % fits
    tmp.map_y_antarctic = tmp.monitor_h - tmp.map_y_ant_margin/2 - tmp.map_h_antarctic;
  else
    % doesn't fit
    tmp.map_y_antarctic = 0;
  end
  % width for arctic
  if tmp.monitor_w - (100 + tmp.map_w_arctic) > 0
    % fits
    tmp.map_x_arctic = 100;
  else
    % doesn't fit
    tmp.map_x_arctic = 0;
  end
  % width for antarctic
  if tmp.monitor_w - (100 + tmp.map_w_antarctic) > 0
    % fits
    tmp.map_x_antarctic = 100;
  else
    % doesn't fit
    tmp.map_x_antarctic = 0;
  end
  % ECHOWIN
  % check for two tmp.monitors
  if size(tmp.monitors,1) > 1
    % if there are two, put the echowin in the second monitor
    tmp.s_monitor = tmp.monitors(2,:);
    tmp.monitor_w = tmp.s_monitor(3);
    tmp.monitor_h = tmp.s_monitor(4);
    tmp.echo_x_margin = tmp.monitor_w-tmp.echo_w;
    tmp.echo_y_margin = tmp.monitor_h-tmp.echo_h;
    % height
    if tmp.monitor_h - (tmp.echo_y_margin/2 + tmp.echo_h) > 0
      % fits
      tmp.echo_y = tmp.monitor_h - tmp.echo_y_margin/2 - tmp.echo_h;
    else
      % doesn't fit
      tmp.echo_y = 0;
    end
    % width
    if tmp.monitor_w - (100 + tmp.echo_w) > 0
      % fits
      tmp.echo_x = tmp.s_monitor(1) + 100;
    else
      % doesn't fit
      tmp.echo_x = 0;
    end
  else
    % otherwise put the echowin in the first monitor
    tmp.echo_x_margin = tmp.monitor_w-tmp.echo_w;
    tmp.echo_y_margin = tmp.monitor_h-tmp.echo_h;
    % height
    if tmp.monitor_h - (tmp.echo_y_margin/2 + tmp.echo_h) > 0
      % fits
      tmp.echo_y = tmp.monitor_h - tmp.echo_y_margin/2 - tmp.echo_h;
    else
      % doesn't fit
      tmp.echo_y = 0;
    end
    % width
    if tmp.monitor_w - (100 + tmp.echo_w) > 0
      % fits
      tmp.echo_x = 100;
    else
      % doesn't fit
      tmp.echo_x = 0;
    end
  end
end

%% Prefwin default parameters
default_params.prefwin.sources = sort({'standard','qlook','mvdr','CSARP_post/standard','CSARP_post/mvdr','CSARP_post/qlook'});
default_params.prefwin.season_names = {};
default_params.prefwin.layer_names = {'surface'};
default_params.prefwin.system = 'tracks';
default_params.prefwin.map_name = '';
default_params.prefwin.flightlines = 'tracks files Flightlines';
%
default_params.prefwin.layer_source = 'layerdata';
default_params.prefwin.layer_data_source = 'layer';
%
default_params.prefwin.x = tmp.pref_x;
default_params.prefwin.y = tmp.pref_y;
default_params.prefwin.w = tmp.pref_w;
default_params.prefwin.h = tmp.pref_h;

%% Echowin default parameters
default_params.echowin.max_frames = 2;
default_params.echowin.x = tmp.echo_x;
default_params.echowin.y = tmp.echo_y;
default_params.echowin.w = tmp.echo_w;
default_params.echowin.h = tmp.echo_h;
default_params.mapwin.x = tmp.map_x_arctic;
default_params.mapwin.y = tmp.map_y_arctic;
default_params.mapwin.w = tmp.map_w_arctic;
default_params.mapwin.h = tmp.map_h_arctic;

%% Load user passed in file and override the default parameters with the contents of this file
if exist(picker_param_fn,'file')
  fprintf('Loading user parameters file: %s\n', picker_param_fn);
  default_params_override = load(picker_param_fn);
  default_params = merge_structs(default_params,default_params_override);
else
  fprintf('Loading user parameters file, but not found: %s\n', picker_param_fn);
end
default_params.picker_param_fn = picker_param_fn;

%% Store param variable to default params file
picker_param_fn_dir = fileparts(picker_param_fn);
if ~exist(picker_param_fn_dir,'dir')
  try
    mkdir(picker_param_fn_dir);
  catch ME
    warning('Failed to create default params directory: %s\n%s', ...
      picker_param_fn_dir, ME.getReport);
  end
end
try
  fprintf('Saving user parameters file: %s\n', picker_param_fn);
  ct_save(picker_param_fn,'-append','-struct','default_params');
catch ME
  warning('Failed to save default parameters file %s', picker_param_fn);
end


%% Set mapwin's default parameters
obj.default_params = default_params;
