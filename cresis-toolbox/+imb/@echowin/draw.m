function draw(obj,param)
% draw(obj,param)
%
% Member function of imb.echowin class.
% Loads a new dataset into the pick window from the map window.
%
% param.layers.lyr_name;
% param.layers.lyr_group_name;
% param.layers.lyr_id;
%
% param.cur_sel.frm;
% param.cur_sel.seg_id;
% param.cur_sel.season_name;
% param.cur_sel.radar_name;
% param.cur_sel.location;
% param.cur_sel.day_seg;
% 
% param.system;
% param.layer_source;
% param.layer_data_source;
% 
% param.map.source: 0 (OPS) or 1 (season layer data files)
% param.map.scale: 1 (google maps) or 1000 (OPS/geotiff)
% 
% param.start_gps_time: Nfrm length vector with start time for each frame
% param.stop_gps_time: Nfrm length vector with start time for each frame
%
% Author: John Paden

obj.busy_mode = true;
set(obj.h_fig,'Pointer','watch');
obj.status_text_set(sprintf('(%s) Drawing...', datestr(now,'HH:MM:SS')),'replace');
drawnow;
fprintf('START ECHOWIN DRAW (%s)\n',datestr(now,'HH:MM:SS'));

obj.eg.sources = param.sources;

obj.eg.layers.lyr_age = param.layers.lyr_age;
obj.eg.layers.lyr_age_source = param.layers.lyr_age_source;
obj.eg.layers.lyr_desc = param.layers.lyr_desc;
obj.eg.layers.lyr_group_name = param.layers.lyr_group_name;
obj.eg.layers.lyr_id = param.layers.lyr_id;
obj.eg.layers.lyr_name = param.layers.lyr_name;
obj.eg.layers.lyr_order = param.layers.lyr_order;
obj.eg.layers.saved.lyr_age = obj.eg.layers.lyr_age;
obj.eg.layers.saved.lyr_age_source = obj.eg.layers.lyr_age_source;
obj.eg.layers.saved.lyr_desc = obj.eg.layers.lyr_desc;
obj.eg.layers.saved.lyr_group_name = obj.eg.layers.lyr_group_name;
obj.eg.layers.saved.lyr_id = obj.eg.layers.lyr_id;
obj.eg.layers.saved.lyr_name = obj.eg.layers.lyr_name;
obj.eg.layers.saved.lyr_order = obj.eg.layers.lyr_order;

obj.eg.cur_sel.frm = param.cur_sel.frm;
obj.eg.cur_sel.seg_id = param.cur_sel.seg_id;
obj.eg.cur_sel.season_name = param.cur_sel.season_name;
obj.eg.cur_sel.radar_name = param.cur_sel.radar_name;
obj.eg.cur_sel.location = param.cur_sel.location;
obj.eg.cur_sel.day_seg = param.cur_sel.day_seg;

obj.eg.system = param.system;
obj.eg.layers.source = param.layer_source;
obj.eg.layers.data_source = param.layer_data_source;

% Get the map info and projection for the current location
obj.eg.map.source = param.map.source;
obj.eg.map.scale = param.map.scale;
obj.eg.proj = imb.get_proj_info(obj.eg.cur_sel.location);

%% Drop all currently loaded data
obj.eg.data = [];
obj.eg.gps_time = [];
obj.eg.lat = [];
obj.eg.lon = [];
obj.eg.elev = [];
obj.eg.roll = [];
obj.eg.surf_twtt = [];
obj.eg.frms = [];

%% Get all the frames for this segment
obj.eg.start_gps_time = param.start_gps_time;
obj.eg.stop_gps_time = param.stop_gps_time;
obj.eg.frm_strs = {};
for frm = 1:length(obj.eg.start_gps_time)
  obj.eg.frm_strs{frm} = sprintf('%s_%03d', obj.eg.cur_sel.day_seg, frm);
end

%% Update file listing of all source files
obj.update_source_fns_existence();

%% Load echogram data

set(obj.left_panel.sourceLB,'Value',1);
set(obj.left_panel.sourceLB,'String',obj.eg.sources);
%set(obj.left_panel.sourceLB,'Value',find(strcmp(obj.eg.sources,existing_sources(first_idx))));

% Set current listbox frame to this frame since it is the one that was
% specifically asked for (load_echogram uses this value)
set(obj.left_panel.frameLB,'Value',obj.eg.cur_sel.frm);
% But load some other frames around this one for more responsive GUI behavior
desire_frms = obj.eg.cur_sel.frm ...
  : min(obj.eg.cur_sel.frm+obj.default_params.max_frames-1,length(obj.eg.frm_strs));
clipped = 3;
load_new_data = 1;
x_min = -inf;
x_max = inf;
y_min = -inf;
y_max = inf;

% Update "Frames" listbox
set(obj.left_panel.frameLB,'String',obj.eg.frm_strs);

[x_min,x_max,y_min,y_max] = obj.load_echogram(desire_frms,clipped,x_min,x_max,y_min,y_max);

%% Create variables for the layer list box
% ===================================================================

% set up state variables of radio buttons (selected layer) and checkboxes
% (visible layers)
obj.eg.layers.selected_layers = false(size(obj.eg.layers.lyr_id));
obj.eg.layers.visible_layers = true(size(obj.eg.layers.lyr_id));

obj.layerLB_str(false);


%% Load flightlines, layers, crossovers and place the cursor
% ===================================================================
obj.load_flightline();
obj.load_layers_init();
obj.load_layers();
obj.plot_echogram(x_min,x_max,y_min,y_max);
obj.plot_layers();
obj.crossovers.en = obj.crossovers.gui.crossovers_en();
obj.load_crossovers();
obj.plot_cursors();

%% Set layer and cross over visibility
obj.set_visibility();

%% Plot cursor (if valid)
xlimits = xlim(obj.h_axes);
start_gps = obj.eg.image_gps_time(find(obj.eg.image_xaxis>=xlimits(1),1));
stop_gps = obj.eg.image_gps_time(find(obj.eg.image_xaxis<=xlimits(2),1,'last'));

if ~isempty(obj.cursor.gps_time) ...
    && obj.cursor.gps_time >= start_gps && obj.cursor.gps_time <= stop_gps
  obj.plot_cursors();
  str = obj.status_text_cursor();
  obj.status_text_set(str,'replace');
end

%% Plot new selection on flight path
notify(obj,'update_echowin_flightline');

% Set echowin figure callback properties (these are set here rather than
% create_ui since most of the do not work before data is loaded for the
% first time)
set(obj.h_fig,'WindowButtonDownFcn',@obj.button_down);
set(obj.h_fig,'WindowButtonMotionFcn',@obj.button_motion);
set(obj.h_fig,'WindowButtonUpFcn',@obj.button_up);
set(obj.h_fig,'WindowKeyPressFcn',@obj.key_press);
set(obj.h_fig,'WindowKeyReleaseFcn',@obj.key_release);
set(obj.h_fig,'WindowScrollWheelFcn',@obj.button_scroll);

if strcmpi(obj.eg.layers.source,'layerdata')
  set(obj.left_panel.crossoverPB,'Enable','off')
  obj.crossovers.en = false;
  obj.crossovers.gui.visibility_toggle(false);
else
  set(obj.left_panel.crossoverPB,'Enable','on')
end

obj.busy_mode = false;
if obj.zoom_mode
  set(obj.h_fig,'Pointer','custom');
else
  set(obj.h_fig,'Pointer','Arrow');
end

obj.status_text_set(sprintf(' done. (%s)', datestr(now,'HH:MM:SS')),'append');  

fprintf(' DONE (%s)\n',datestr(now,'HH:MM:SS'));

return;




