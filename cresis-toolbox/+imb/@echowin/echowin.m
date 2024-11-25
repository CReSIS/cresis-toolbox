classdef (HandleCompatible = true) echowin < handle
  % Echogram Window for imb.picker
  %
  % General operation:
  % 1. Creator function is called
  %   Initializes obj.eg fields (eg = echogram)
  %   Calls "imb.echowin.create_ui" which creates the GUI objects
  % 2. Draw function is called
  %   Queries file system to get echograms obj.update_source_fns_existence();
  %   Calls load_flightline, load_layers_init, load_layers, load_crossovers
  %   Calls plot_echogram, plot_layers, plot_cursors
  %   Plot functions convert to the proper units and displays them in the
  %   right_panel imagesc and layer plots are created here. Note that ALL the
  %   data is plotted and xlim/ylim/caxis are used to control what is seen.
  % 3. If the user loads a new echogram from the map window, then the
  %    draw function is called again.
  % 4. If the user applies an operation, update_layer updates all the
  %    variables and modifies the layer plots
  % 5. If the user changes something redraw is called
  %    * If the x-axis or y-axis units change or user loads a different
  %    frame from within this echowin (either frameLB_callback or by
  %    using the left/right arrow keys) then redraw calls
  %    * If the user causes redraw to be called for some other reason
  %    and new data does not need to be loaded, then plot_echogram
  %    is not called.
  % 6. Normal operation
  %    keyboard_down --> used to interpret hot keys and ctrl/shift/alt keys
  %    button_down --> sets things up for button_up
  %    button_up --> Various different modes of operation
  %      ctrl: select layer
  %      shift: set cursor
  %      zoom-mode: just zooms
  %      alt: apply region tool (call obj.tool.left_click_and_drag_fh then obj.update_layers)
  %      no modifiers: apply point tool (call obj.tool.left_click_fh then obj.update_layers)
  %      right click: apply delete tool (call obj.right_click then obj.update_layers)
  %  7. set_visibility: this function sets the visibility for all the objects and
  %    is called by redraw. It is also called by a bunch of other places
  %    (like keyboard short cuts and special mouse button clicks) when object
  %    visibility might have changed).
  
  properties
    %% GUI Properties
    h_fig % Main echowin figure handle
    h_axes % Main axis handle
    h_image % Image handle
    h_quality % Layer quality plot handles (6 * # of layers)
    h_layer % Layer auto/manual plot handles (2 * # of layers)
    
    left_panel % Structure with fields:
    % handle
    % toolPM
    % paramPB
    % qualityPM
    % imagewin: imagewin class (controls filtering/colorbar)
    % imagePB
    % yaxisPM
    % xaxisPM
    % framesPM
    % crossoverPB
    % savePB
    % topTable
    % layerLB
    % layerCM
    % layerCM_visible
    % layerCM_hide
    % layerCM_new
    % layerCM_copy
    % layerCM_edit
    % layerCM_up
    % layerCM_down
    % layerCM_top
    % layerCM_bottom
    % layerCM_delete
    % frameLB
    % frameCM
    % sourceLB
    % sourceCM
    % table
    right_panel % Structure with fields:
    % handle
    % axes_panel
    % status_panel
    %   handle
    %   statusText
    %   mouseCoordText
    %   table
    % echoCM
    % echoCM_copy
    % table
    table
    cursor % Cursor handle + state information (.h, .gps_time)
    % cursor.gps_time: GPS time of cursor location
    % cursor.lat: latitude of cursor location
    % cursor.lon: longitude of cursor location
    % cursor.target_elev: elevation of cursor location
    % cursor.clutter_lat: latitude of clutter locations
    % cursor.clutter_lon: longitude of clutter locations
    % cursor.target_twtt: twtt of cursor location for the a-scope data
    % cursor.surf_twtt: surface twtt for the a-scope data
    % cursor.twtt: twtt axis for the a-scope data
    % cursor.data: a-scope data signal
    % cursor.h: Cursor plot handle
    crossovers
    % crossovers.en: logical scalar determining whether or not crossovers are loaded
    % crossovers.gui: imb.crossover class
    % crossovers.gps_time: gps time for each crossover
    % crossovers.h: cross over plot handles
    % crossovers.x_curUnit: x value for each crossover in current x-axis units
    % crossovers.y_curUnit: y value for each crossover in current y-axis units
    % crossovers.source_point_path_id: OPS database point path ID from the loaded echogram
    % crossovers.cross_point_path_id: OPS database point path ID from the crossover echogram
    % crossovers.source_elev: elevation of platform for each crossover
    % crossovers.cross_elev: elevation of platform in crossover echogram for each crossover
    % crossovers.layer_id: layer ID for each crossover
    % crossovers.frm_str: frame string ID of crossover echogram
    % crossovers.twtt: twtt of the layer in the crossover echogram
    % crossovers.angle: crossover angle (0 deg means crossover echogram is
    %   parallel to the currently loaded echogram)
    % crossovers.abs_error: absolute difference between twtt to each layer
    
    %% Keyboard/Mouse Properties
    alt_pressed % Logical indicating the state of the alt-key
    control_pressed % Logical indicating the state of the ctrl-key
    shift_pressed % Logical indicating the state of the shift-key
    zoom_mode % Logical indicating the zoom mode
    cursor_mode % Logical indicating the cursor mode (true causes cursor to constantly update with mouse motion)
    busy_mode % Logical indicating the busy mode for mouse pointer, also disables some functions
    click_x % Last mouse click x-position
    click_y % Last mouse click y-position
    switch_layers % struct with fields for key_press switching layers feature
    % switch_layers.time: stores time since last key press
    % switch_layers.keys: accumulates consecutive key strokes
    
    %% Tool Properties
    tool % Struct with tool information
    % tool.list: List of tool class objects
    % tool.left_click_fh % Current: left click tool function handle
    % tool.left_click_and_drag_fh: Current left click and drag tool function handle
    % tool.right_click_fh: Current right click tool function handle
    % tool.right_click_and_drag_fh: Current right click and drag tool function handle
    % tool.accessed % True if any pick tool parameter window has been opened
    % tool.visible % True if tool parameter window is visible
    % tool.old_idx % Index of last tool
    % tool.layer_multiple: which layer multiple to track (the twtt of the mouse
    %   click is automatically converted based on this value to allow
    %   tracking of layers via their multiple)
    % tool.old_visibility: Copy of old visibility settings (used by
    % spacebar toggle)
    
    %% Echogram Properties
    % eg = Struct with image information, crossover information, and
    % echogram and layer information
    eg
    % sources: cell array of echogram source file paths
    % system: string containing accum, kaband, kuband, rds, or snow
    % cur_sel
    %  frm: frame corresponding to the left side of the echogram display
    %    (this will be the active selection in the frameLB)
    %  segment_id: 2.0120e+09
    %  season_name: '2012_Greenland_P3'
    %  radar_name: 'snow'
    %  location: 'arctic'
    %  day_seg: '20120330_04'
    %  map_zone: string containing 'arctic' or 'antarctic'
    %  map_mask: mask on lat/lon/elev for what is actually being shown in
    %    the echogram window
    %
    % frms: frames that are actively loaded
    % frm_strs: Nfrm length cell array of frame names
    % old_frame_idx: last frame to be loaded (-1 default)
    % start_gps_time: Nfrm length numeric vector of start GPS times for each frame
    % stop_gps_time: Nfrm length numeric vector of stop GPS times for each frame
    % source_fns_existence: logical array that is Nfrm by Nsrc where Nfrm
    %   is the number of frames in this segment and Nsrc is the number of
    %   echogram sources in eg.sources
    %
    % data: original Nt by Nx single data matrix (a copy must be kept in case operations
    %   are done on the matrix)
    % gps_time: GPS time of data matrix, represents seconds since Jan 1,
    %   1970 (ANSI-C standard), 1 by Nx double vector
    % elev: Elevation of data matrix in meters, 1 by Nx double vector
    % lat: Latitude of data matrix, 1 by Nx double vector
    % lon: Longitude of data matrix, 1 by Nx double vector
    % surf_twtt: Surface of data matrix, 1 by Nx double vector
    % time: Fast time of data matrix, Nt by 1 double vector
    %
    % image_data: modified (image processed/resampled) Nt_img by Nx_img single data matrix
    % image_xaxis: Nx_img double vector for x-axis of image_data (units determined by x-axis choice)
    % image_gps_time: Nx_img double vector for gps-axis of image_data (units of seconds since Jan 1, 1970)
    % image_yaxis: Nx_img double vector for y-axis of image_data (units determined by x-axis choice)
    % image_ecef: 3 by Nx_img double array for earth centered earth fixed coordinates (meters) of image_data
    % image_yvec: 3 by Nx_img double array for unit y-vector (left looking) in earth centered earth fixed coordinates (meters) of image_data
    % image_zvec: 3 by Nx_img double array for unit z-vector (left looking) in earth centered earth fixed coordinates (meters) of image_data
    % image_surf_twtt: Nx_img double vector for surface twtt (sec) of image_data
    % image_lat: Nx_img double vector for platform latitude (deg North) of image_data
    % image_lon: Nx_img double vector for platform longitude (deg East) of image_data
    % image_elev: Nx_img double vector for platform elevation (WGS-84 meters) of image_data
    % x_label: string containing x-axis label
    % y_label: string containing x-axis label
    % y_order: string containing "normal" or "reverse" for obj.h_axes
    % detrend: detrend properties structure
    % multiple_suppression: surface multiple suppression properties structure
    %
    % layers
    %   show_manual_pts % Logical scalar, Show manual points in layer plots
    %   show_dots_only % Logical scalar, Show dots only in layer plots
    %   quality_en % Logical scalar, show quality layers if true
    %   source: string containing "ops" or "layerdata"
    %   layer_data_source: file path to layerdata if "layerdata" source being used
    %   lyr_age = []; % Nlayer length vector of layer ages (set in draw)
    %   lyr_age_source = {}; % Nlayer length vector of layer age sources (set in draw)
    %   lyr_desc = {}; % Nlayer length cell array of layer description (set in draw)
    %   lyr_group_name = {}; % Nlayer length cell array of layer group names (set in draw)
    %   lyr_id = []; % Nlayer length numeric vector of layer IDs (OPS IDs or the index into the layer structure of layer files (set in draw)
    %   lyr_name = {}; % Nlayer length cell array of layer names (set in draw)
    %   lyr_order = []; % Nlayer length vector of layer orders (set in draw)
    %   surf_id: surface ID
    %   selected_layers: Nlayer length logical vector, true means layer is
    %     selected (tools and operations will act on the layer)
    %   visible_layers: Nlayer length logical vector, true means layer visible
    %   x: 1 by Nx vector of x-values in GPS time
    %   y: Cell array of 1 by Nx vectors of y-values in twtt
    %   qual: Cell array of 1 by Nx vectors of quality values (1=good,2=medium,3=bad,NaN=unassigned)
    %   type: Cell array of 1 by Nx vectors of type values (1=
    %   x_curUnit: 1 by Nx vector of x-values in current x-axis units
    %   y_curUnit: Cell array of 1 by Nx vectors of y-values in current y-axis units
    %   saved.lyr_name = {}; % Last saved version
    %   saved.lyr_group_name = {}; % Last saved version
    %   saved.lyr_id = {}; % Last saved version
    %
    % eg.map_id
    % eg.map_gps_time
    % eg.map_x
    % eg.map_y
    % eg.map_elev
    % eg.map.source
    % eg.map.scale

    
    %% Undostack Properties
    undo_stack
    undo_stack_save_listener
    undo_stack_synchronize_listener
    
    %% default_params Properties
    % default_params = Default parameters loaded from default parameters file
    default_params
    
  end
  
  properties (SetAccess = private, GetAccess = private)
  end
  
  properties (SetAccess = immutable, GetAccess = public) %constants
  end
  
  events
    close_window % Signalled when a user closes the window
    update_echowin_flightline % Signalled when the x-axis changes (draw and redraw)
    update_cursors % Signalled when a user changes the cursor (button_up)
    update_map_selection % Signalled when the frame selection changes (frameLB_callback)
    open_crossover_event % Signalled when user requests a cross over opened from the cross over window (open_crossover)
  end
  
  methods
    function obj = echowin(h_fig,default_params)
      %% Constructor Input Checks
      % If passed a figure, then plot the echogram in that.  Otherwise
      % create a new figure
      if nargin == 0 || isempty(h_fig)
        h_fig = figure;
      else
        figure(h_fig);
      end
      
      % Set up defaults for the param structure
      if ~exist('default_params','var')
        default_params = struct();
      end
      if ~isfield(default_params,'max_frames')
        default_params.max_frames = 2;
      end
      set(obj.h_fig,'Units','pixels');
      echowin_pos = get(h_fig,'Position');
      set(obj.h_fig,'Units','normalized');
      if ~isfield(default_params,'x')
        default_params.x = echowin_pos(1);
      end
      if ~isfield(default_params,'y')
        default_params.y = echowin_pos(2);
      end
      if ~isfield(default_params,'w')
        default_params.w = echowin_pos(3);
      end
      if ~isfield(default_params,'h')
        default_params.h = echowin_pos(4);
      end
      
      %% Constructor: Keyboard/Mouse
      obj.alt_pressed = false; % Logical indicating the state of the alt-key
      obj.control_pressed = false; % Logical indicating the state of the ctrl-key
      obj.shift_pressed = false; % Logical indicating the state of the shift-key
      obj.busy_mode = true; % Logical indicating the busy mode for mouse pointer, also disables some functions
      obj.zoom_mode = true; % Logical indicating the zoom mode for mouse pointer
      obj.cursor_mode = false; % Logical indicating the cursor mode (true causes cursor to constantly update with mouse motion)
      obj.click_x; % Last mouse click x-position
      obj.click_y; % Last mouse click y-position
      obj.switch_layers = []; % struct with fields for key_press switching layers feature
      obj.switch_layers.time = -inf; % stores time since last key press
      obj.switch_layers.keys = ''; % accumulates consecutive key strokes
      
      %% Constructor: Tool
      obj.tool = []; % Struct with tool information
      obj.tool.list = []; % List of tool class objects
      obj.tool.left_click_fh = []; % Current: left click tool function handle
      obj.tool.left_click_and_drag_fh = []; % Current left click and drag tool function handle
      obj.tool.right_click_fh = []; % Current: right click tool function handle
      obj.tool.right_click_and_drag_fh = []; % Current right click and drag tool function handle
      obj.tool.accessed = false; % True if any pick tool parameter window has been opened
      obj.tool.visible = false; % True if tool parameter window is visible
      obj.tool.old_idx = 1; % Index of last tool
      obj.tool.layer_multiple = 1; % Numeric scalar determining layer multiple to track (the twtt of the mouse click is automatically scaled by this value to allow tracking of layers via their multiple)
      
      %% Constructor: Echogram
      % eg = Struct with image information, crossover information, and
      % echogram and layer information
      obj.eg = [];
      obj.eg.sources = {}; % cell array of echogram source file paths
      obj.eg.system = ''; % string containing accum, kaband, kuband, rds, or snow
      obj.eg.cur_sel = []; % Current selection (originally comes from mapwin current selection)
      obj.eg.cur_sel.frm = []; % frame corresponding to the left side of the echogram display (this will be the active selection in the frameLB)
      obj.eg.cur_sel.seg_id = []; % 2.0120e+09
      obj.eg.cur_sel.season_name = ''; % '2012_Greenland_P3'
      obj.eg.cur_sel.radar_name = ''; % 'snow'
      obj.eg.cur_sel.location = ''; % 'arctic'
      obj.eg.cur_sel.day_seg = ''; % '20120330_04'
      obj.eg.map_zone = ''; % string containing 'arctic' or 'antarctic'
      obj.eg.map_mask = []; % mask on lat/lon/elev for what is actually being shown in the echogram window
      obj.eg.frms = []; % frames that are actively loaded
      obj.eg.frm_strs = {}; % Nfrm length cell array of frame names
      obj.eg.old_frame_idx = []; % last frame to be loaded (-1 default)
      obj.eg.start_gps_time = []; % Nfrm length numeric vector of start GPS times for each frame
      obj.eg.stop_gps_time = []; % Nfrm length numeric vector of stop GPS times for each frame
      obj.eg.source_fns_existence = logical([]); % logical array that is Nfrm by Nsrc where Nfrm is the number of frames in this segment and Nsrc is the number of echogram sources in eg.sources
      
      obj.eg.data = []; % original Nt by Nx single data matrix (a copy must be kept in case operations are done on the matrix)
      obj.eg.gps_time = []; % GPS time of data matrix, represents seconds since Jan 1, 1970 (ANSI-C standard), 1 by Nx double vector
      obj.eg.elev = []; % Elevation of data matrix in meters, 1 by Nx double vector
      obj.eg.lat = []; % Latitude of data matrix, 1 by Nx double vector, degrees N
      obj.eg.lon = []; % Longitude of data matrix, 1 by Nx double vector, degrees E
      obj.eg.roll = []; % Roll of data matrix, 1 by Nx double vector, radians right wing tip down from level
      obj.eg.surf_twtt = []; % Surface of data matrix, 1 by Nx double vector
      obj.eg.time = []; % Fast time of data matrix, Nt by 1 double vector
      
      obj.eg.image_data = []; % modified (image processed/resampled) Nt_img by Nx_img single data matrix
      obj.eg.image_xaxis = []; % Nx_img double vector for x-axis of image_data
      obj.eg.image_gps_time = []; % Nx_img double vector for gps-axis of image_data
      obj.eg.image_yaxis = []; % Nx_img double vector for y-axis of image_data
      obj.eg.x_label = ''; % string containing x-axis label
      obj.eg.y_label = ''; % string containing x-axis label
      obj.eg.y_order = ''; % string containing "normal" or "reverse" for obj.h_axes
      obj.eg.detrend.top = 1; % index or name to top layer
      obj.eg.detrend.bottom = 2; % index or name to bottom layer
      obj.eg.detrend.order = 7; % order of detrend polynomial
      
      obj.eg.layers = [];
      obj.eg.layers.show_manual_pts = true; % Logical scalar, Show manual points in layer plots
      obj.eg.layers.show_dots_only = false; % Logical scalar, Show dots only in layer plots
      obj.eg.layers.quality_en = false; % Logical scalar, show quality layers if true
      obj.eg.layers.source = ''; % string containing "ops" or "layerdata"
      obj.eg.layers.layer_data_source = ''; % file path to layerdata if "layerdata" source being used
      obj.eg.layers.lyr_age = []; % Nlayer length vector of layer ages (set in draw)
      obj.eg.layers.lyr_age_source = {}; % Nlayer length vector of layer age sources (set in draw)
      obj.eg.layers.lyr_desc = {}; % Nlayer length cell array of layer description (set in draw)
      obj.eg.layers.lyr_group_name = {}; % Nlayer length cell array of layer group names (set in draw)
      obj.eg.layers.lyr_id = []; % Nlayer length numeric vector of layer IDs (OPS IDs or the index into the layer structure of layer files (set in draw)
      obj.eg.layers.lyr_name = {}; % Nlayer length cell array of layer names (set in draw)
      obj.eg.layers.lyr_order = []; % Nlayer length vector of layer orders (set in draw)
      obj.eg.layers.surf_id = []; % surface ID (set in draw)
      obj.eg.layers.selected_layers = []; % Nlayer length logical vector, true means layer is selected (tools and operations will act on the layer) (set in draw)
      obj.eg.layers.visible_layers = []; % Nlayer length logical vector, true means layer visible (set in draw)
      obj.eg.layers.x = []; % 1 by Nx vector of x-values in GPS time (set in load_layers)
      obj.eg.layers.y = {}; % Cell array of 1 by Nx vectors of y-values in twtt (set in load_layers)
      obj.eg.layers.qual = {}; % Cell array of 1 by Nx vectors of quality values (1=good,2=medium,3=bad,NaN=unassigned) (set in load_layers)
      obj.eg.layers.type = {}; % Cell array of 1 by Nx vectors of type values 1 (manual) or 2 (auto) (set in load_layers)
      obj.eg.layers.x_curUnit = []; % 1 by Nx vector of x-values in current x-axis units (set in plot_layers)
      obj.eg.layers.y_curUnit = {}; % Cell array of 1 by Nx vectors of y-values in current y-axis units (set in plot_layers)
      obj.eg.layers.saved.lyr_age = {}; % Last saved version
      obj.eg.layers.saved.lyr_age_source = {}; % Last saved version
      obj.eg.layers.saved.lyr_desc = {}; % Last saved version
      obj.eg.layers.saved.lyr_group_name = {}; % Last saved version
      obj.eg.layers.saved.lyr_order = {}; % Last saved version
      obj.eg.layers.saved.lyr_id = {}; % Last saved version
      obj.eg.layers.saved.lyr_name = {}; % Last saved version
      
      %% Constructor: Undostack
      obj.undo_stack = [];
      obj.undo_stack_save_listener = [];
      obj.undo_stack_synchronize_listener = [];
      
      % default_params = Default parameters loaded from default parameters file
      %% Constructor: default_params
      obj.default_params = default_params;
      
      %% Constructor: GUI
      obj.h_fig = h_fig;
      obj.h_axes = []; % Main axis handle
      obj.h_image = []; % Image handle
      obj.h_quality = [];% Layer quality plot handles (6 * # of layers)
      obj.h_layer = []; % Layer auto/manual plot handles (2 * # of layers)
      
      obj.cursor = []; % Cursor handle + state information (.h, .gps_time)
      obj.cursor.gps_time = []; % GPS time of cursor location
      obj.cursor.lat = []; % latitude of cursor location
      obj.cursor.lon = []; % longitude of cursor location
      obj.cursor.elev = []; % elevation of cursor location
      obj.cursor.surf_twtt = []; % twtt to surface
      obj.cursor.bottom_twtt = []; % twtt to bottom
      obj.cursor.lat = []; % latitude of clutter locations
      obj.cursor.lon = []; % longitude of clutter locations
      obj.cursor.h = []; % Cursor plot handle
      
      obj.crossovers = [];
      obj.crossovers.en = false; % logical scalar determining whether or not crossovers are loaded
      obj.crossovers.gui = []; % imb.crossover class
      obj.crossovers.gps_time = []; % gps time for each crossover
      obj.crossovers.h = []; % cross over plot handles
      obj.crossovers.x_curUnit = []; % x value for each crossover in current x-axis units
      obj.crossovers.y_curUnit = []; % y value for each crossover in current y-axis units
      obj.crossovers.source_point_path_id = []; % OPS database point path ID from the loaded echogram
      obj.crossovers.cross_point_path_id = []; % OPS database point path ID from the crossover echogram
      obj.crossovers.source_elev = []; % elevation of platform for each crossover
      obj.crossovers.cross_elev = []; % elevation of platform in crossover echogram for each crossover
      obj.crossovers.layer_id = []; % layer ID for each crossover
      obj.crossovers.frm_str = []; % frame string ID of crossover echogram
      obj.crossovers.twtt = []; % twtt of the layer in the crossover echogram
      obj.crossovers.angle = []; % crossover angle (0 deg means crossover echogram is parallel to the currently loaded echogram)
      obj.crossovers.abs_error = []; % absolute difference between twtt to each layer
      
      create_ui(obj);
    end
    
    function delete(obj)
      % Delete the figure handle
      try
        delete(obj.h_fig);
      end
      
      % Delete the tools
      try
        for idx = 1:length(obj.tool.list)
          try
            delete(obj.tool.list{idx});
          end
        end
      end
      
      try
        delete(obj.left_panel.imagewin);
      end
      
      try
        delete(obj.crossovers.gui);
      end
      
      % Remove echowin from undo_stack
      obj.cmds_set_undo_stack([]);
    end
    
    %% Button, key Methods
    button_down(obj,src,event);
    button_motion(obj,src,event);
    button_up(obj,src,event);
    key_press(obj,src,event);
    key_release(obj,src,event);
    button_scroll(obj,src,event);
    
    %% Echowin GUI callback Methods
    close_win(obj,varargin);
    crossoverPB_callback(obj,hObj,event);
    display_modePM_callback(obj,hObj,event);
    framesPM_callback(obj,hObj,event);
    frameCM_callback(obj,hObj,event);
    frameLB_callback(obj,hObj,event);
    layerCM_callback(obj,source,event);
    layerLB_callback(obj,hObj,event);
    paramPB_callback(obj,hObj,event);
    qualityPM_callback(obj,source,event);
    savePB_callback(obj,hObj,event);
    sourceCM_callback(obj,source,event);
    sourceLB_callback(obj,hObj,event);
    toolPM_callback(obj,hObj,event);
    xaxisPM_callback(obj,hObj,event);
    yaxisPM_callback(obj,hObj,event);
    
    open_crossover(obj,source,event);
    cursor_crossover(obj,source,event);
    cur_frame = get_crossover(pbj);
    [fn,comment] = imagewin_fn_callback(obj,fn);
    imagewin_save_mat_callback(obj,h_obj,event);
    status_text_copy_callback(obj,source,event);
    status_text_print(obj,str,type);
    status_str = status_text_cursor(obj,param);
    
    %% Load and plot Methods
    create_ui(obj);
    draw(obj,param);  % Load EG data, frames, etc.
    [x_min,x_max,y_min,y_max] = load_echogram(obj,desire_frame_idxs,clipped,x_min,x_max,y_min,y_max);
    load_crossovers(obj,source,event);
    load_flightline(obj);
    load_layers_init(obj);
    load_layers(obj);
    plot_echogram(obj,x_min,x_max,y_min,y_max);
    plot_crossovers(obj);
    plot_layers(obj);
    plot_cursors(obj);
    rline = update_cursor(obj,x,y,notify_en);
    set_cursor_by_map(obj,lat,lon,type,elev)
    update_source_fns_existence(obj);
    update_frame_and_sourceLB(obj,frm);
    
    set_visibility(obj,varargin); % Layer colors
    change_dynamic_range(obj);
    change_display_c(obj);
    layerLB_str(obj,keep_value);
    new_layerPB_OKbutton_callback(obj,hObj,event);
    new_layerPB_close_callback(obj,hObj,event);
    cancel_operation = undo_stack_modified_check(obj,force_save_or_cancel_flag);
    toggle_imagewin_visibility(obj,h_obj,event);
    update_layer_plots(obj); % Update layer plots, called from cmds_execute
    
    %% Commands/Undo stack Methods
    cmds_list = cmds_set_undo_stack(obj,undo_stack); % Attaches and detaches undo stack and listener, call before draw
    cmds_set_undo_stack_after_draw(obj,cmds_list); % Run this with cmds_list from cmds_set_undo_stack after draw called
    cmds = cmds_convert_units(obj,cmds); % Converts tool commands from current units to gps-time and twtt
    cmds_execute(obj,cmds_list,cmds_direction); % Executes a set of commands on this echowin
    cmds_synchronize(obj,varargin); % for tools (callback for the undo_stack synchronize event)
    cmds_save(obj,varargin); % for tools (callback for the undo_stack save event)
    
  end
  
end


