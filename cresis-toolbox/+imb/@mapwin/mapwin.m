classdef (HandleCompatible = true) mapwin < handle
% Map Window for imb.picker
  
  properties
    % Sub classes
    map_pref          % Preference window
    echowin_list      % Vector of imb.echowin class windows
    undo_stack_list   % Vector of imb.undo_stack class objects (one per segment that is modified)
    map_ascope        % Ascope window

    % GUI handles and UI related objects
    h_fig             % Figure handle
    table             % Figure's top level table
    top_panel         % Top panel and handles
    map_panel         % Axes panel and handles
    % map_panel.handle
    % map_panel.h_axes
    % map_panel.h_image
    % map_panel.h_flightline
    % map_panel.h_cur_sel
    % map_panel.h_ascopes_selected
    % map_panel.h_ascopes
    status_panel      % Bottom panel and status bar handles
    echowin_maps      % Struct vector of echowin map graphics:
                      % flightlines (h_line), labels (h_text), and cursors (h_cursor)

    % Status information for mouse/key board callbacks
    control_pressed
    shift_pressed
    alt_pressed
    click_x
    click_y
    zoom_mode
    busy_mode

    % Other properties
    default_params % Contains the default parameters for mapwin, echowin, prefwin, etc
    
    % Map properties
    cur_map_pref_settings % Struct containing currently loaded preference window settings (set in get_map)
    % cur_map_pref_settings.layer_source: string, either 'layerdata' or 'ops'
    % cur_map_pref_settings.layer_data_source: string, layerdata directory to use if 'layerdata' layer data selected 
    % cur_map_pref_settings.layers: struct array of all selected layers if 'ops'layer data selected
    % cur_map_pref_settings.layers.lyr_name: string, OPS layer name
    % cur_map_pref_settings.layers.lyr_group_name: string, OPS group name
    % cur_map_pref_settings.layers.lyr_id: OPS layer ID
    % cur_map_pref_settings.seasons: cell array of strings containing seasons loaded (tracks files flightlines include system in the season name)
    % cur_map_pref_settings.system: string, system name if OPS flight lines, otherwise 'tracks'
    % cur_map_pref_settings.sources: echogram sources to load
    % cur_map_pref_settings.map_zone: string, 'antarctic' or 'arctic'
    % cur_map_pref_settings.map_name: string, name of map
    % cur_map_pref_settings.flightlines: string containing flight line type selection
    
    map
    % map.source % 0 for OPS map, 1 for blank, 2 for Google
    % map.scale % 1e3 (km to meters for OPS/Blank), 1 for Google
    % map.fline_source % 0 for OPS flight lines, 1 for csarp_support/tracks files
    % map.proj % Matlab Projection Structure
    % map.xaxis_default % Current xaxis default bounds
    % map.yaxis_default % Current yaxis default bounds
    % map.xaxis % Current xaxis
    % map.yaxis % Current yaxis
    % map.sel % map selection (red line): .frm_str, .season_name, .segment_id
    % map.sel.frm_str
    % map.sel.radar_name
    % map.sel.season_name
    % map.sel.seg_id
    % map.CoordRefSysCode % string containing EPSG:3413, EPSG:3031, or EPSG:3857
    
    % OPS
    ops
    % ops.request % wms current request information set in get_map, query_redraw_map
    % ops.season_group_ids_as_string % Current season_group_ids loaded in string format (for WMS requests)
    % ops.seasons_as_string % Current seasons loaded in string format (for WMS requests)
    
    % Google map
    google
    % google.map % Stores imp info about the google map obj
    
    % Tracks files:
    % (.../csarp_support/tracks/tracks_MAPZONE_SYSTEM_SEASON.mat)
    trackdata
    % trackdata.x
    % trackdata.y
    % trackdata.frm_id
    % trackdata.season_idx
    % trackdata.frm_info().frm_id
    % trackdata.frm_info().start_gps_time
    % trackdata.frm_info().stop_gps_time

    
  end
  
  properties (SetAccess = private, GetAccess = private)
  end
  
  events
  end
  
  methods
    %% mapwin(h_fig,param)
    function obj = mapwin(h_fig,param)
      % h_fig: optional scalar integer parameter which specifies a specific
      %   figure handle to use (leave empty or undefined to have a new
      %   figure handle assigned)
      % param: structure controlling general behavior
      %   .picker_param_fn: filename of picker parameters to load
      %      ---
      
      % GUI: properties
      % -------------------------------------------------------------------
      if nargin == 0 || isempty(h_fig)
        h_fig = figure;
      else
        figure(h_fig);
      end
      obj.h_fig = h_fig; % Figure handle that map is drawn in
      % Each echowin has a cursor, line, and text associated with it
      obj.echowin_maps = [];    % Struct vector holding echowin map graphics:
                                %   .h_cursor: cursor plot handle
                                %   .h_line: flight lines plot handle
                                %   .h_text: label handle
      % Mouse and keyboard callback state information
      obj.click_x = []; % Last click x position
      obj.click_y = []; % Last click y position
      obj.control_pressed = false; % Is control key currently pressed?
      obj.shift_pressed = false; % Is shift key currently pressed?
      obj.zoom_mode = true; % Show zoom mouse pointer
      obj.busy_mode = false; % Show busy mouse pointer

      % Echogram window and undo stack lists
      % -------------------------------------------------------------------
      obj.echowin_list = imb.echowin.empty(1,0);
      obj.undo_stack_list = imb.undo_stack.empty(1,0);

      % Map properties
      % -------------------------------------------------------------------
      obj.map = [];
      obj.map.source = []; % 0 for OPS, 1 for Google
      obj.map.scale = []; % 1e3 (km to meters for OPS), 1 for Google
      % Currently selected flight line information
      obj.map.sel.frm_str = ''; % Current frame name
      obj.map.sel.seg_id = []; % Current segment ID (Database ID for OPS layer source, index into obj.cur_map_pref_settings.seasons for csarp_support/tracks files source)
      obj.map.sel.season_name = ''; % Current season name
      obj.map.sel.radar_name = ''; % Current radar name
      obj.map.xaxis = [];
      obj.map.yaxis = [];
      obj.map.xaxis_default = [];
      obj.map.yaxis_default = [];
      obj.map.CoordRefSysCode = [];

      % Open Polar Server (OPS) properties
      % -------------------------------------------------------------------
      obj.ops = [];
      obj.ops.proj = []; % Matlab Projection Structure
      obj.ops.request = []; % wms current request information set in get_map, query_redraw_map
      obj.ops.season_group_ids_as_string = []; % Current season_group_ids loaded in string format (for WMS requests)
      obj.ops.seasons_as_string = []; % Current seasons loaded in string format (for WMS requests)
      
      % Google map properties
      % -------------------------------------------------------------------
      obj.google = [];
      obj.google.map = []; % Stores imp info about the google map obj
      
      % csarp_support/tracks files properties
      % -------------------------------------------------------------------
      obj.trackdata = [];
      obj.trackdata.x = []; % Nx length vector of flightlines in local map coordinates
      obj.trackdata.y = []; % Nx length vector of flightlines in local map coordinates
      obj.trackdata.frm_id = []; % Nx length vector of frame ids (as numeric)
      obj.trackdata.season_idx = []; % Nx length vector of season indices into obj.cur_map_pref_settings.seasons
      obj.trackdata.frm_info = []; % Frame information struct array (one struct per entry in obj.cur_map_pref_settings.seasons)
      obj.trackdata.frm_info.frm_id = []; % Nf length vector of frames, frame id (numeric)
      obj.trackdata.frm_info.start_gps_time = []; % Nf length vector, start GPS time of frame (ANSI-C seconds since Jan 1, 1970)
      obj.trackdata.frm_info.stop_gps_time = []; % Nf length vector, stop GPS time of frame (ANSI-C seconds since Jan 1, 1970)

      % Set default parameters
      % -------------------------------------------------------------------
      if ~exist('param','var')
        param = struct();
      end
      if ~isfield(param,'picker_param_fn')
        param.picker_param_fn = ct_filename_tmp([],'picker.mat');
      end
      obj.set_default_params(param.picker_param_fn);

      %% mapwin: Create user interface and preference window
      % -------------------------------------------------------------------
      try
        create_ui(obj);
        obj.map_pref = imb.prefwin([],obj.default_params.prefwin);
        obj.cur_map_pref_settings = obj.map_pref.settings;
        addlistener(obj.map_pref,'StateChange',@obj.get_map);
        obj.map_ascope = imb.ascopewin([]);
        addlistener(obj.map_ascope,'StateChange',@obj.update_ascopewin_cursors);

      catch ME
        delete(obj);
        rethrow(ME);
      end
    end
    
    %% delete()
    function delete(obj)
      try
        % Delete the map preferences window
        delete(obj.map_pref);
      end
      
      try
        % Delete the map ascope window
        delete(obj.map_ascope);
      end
      
      try
        % Delete the map figure handle
        delete(obj.h_fig);
      end
      
      % Delete all the echogram windows
      for idx = 1:length(obj.echowin_list)
        try
          delete(obj.echowin_list(idx));
        end
      end
      
      % Delelte all the undo_stack classes
      for idx = 1:length(obj.undo_stack_list)
        try
          delete(obj.undo_stack_list(idx));
        end
      end

    end
    
    create_ui(obj); % Create GUI, called from constructor
    query_redraw_map(obj,x_min,x_max,y_min,y_max); % Called whenever map perspective changes
    update_vector_layers(obj); % Draws/updates current selection, echowin flightlines, and cursors
    get_map(obj,hObj,event); % Makes original WMS query request
    get_closest_frame(obj, param);
    outside_limits = check_limits(obj,xaxis,yaxis,dir); % Support function for key_press.m pan functions, checks to see if current request is in the map limits
    set_default_params(obj,picker_param_fn); % Set the default parameters loaded from the default preferences file
    save_default_params(obj);
    [changed,pos] = compute_new_map_limits(obj,new_xdata,new_ydata); % Compute new map axis limits based on new data that must be in view
    
    % Callback Functions
    button_up(obj,src,event);
    button_down(obj,src,event);
    button_motion(obj,src,event);
    button_scroll(obj,src,event);
    flightCM_callback(obj,src,event);
    key_press(obj,src,event);
    key_release(obj,src,event);
    loadPB_callback(obj,src,event);
    prefPB_callback(obj,src,event);
    close_win(obj,varargin); % Handles mapwin close event
    search_callback(obj,src,event); % Updates the currect flight line selection (from search)
    open_crossover_echowin(obj,src,event); % Opens a cross over in a new echowindow

    % Echowin-related Callback Functions
    close_echowin(obj,h_obj,event); % Handles echowin close window event
    update_echowin_flightlines(obj,src,event); % Called when echowin x-axis (i.e. flightline position) changes, updates the map
    update_echowin_cursors(obj,src,event); % Called when a echowin cursor position changes, causes all echowin cursors to be updated
    update_map_selection_echowin(obj,src,event); % Updates the currect flight line selection (from echowin frame selection)
    ascope_memory(obj,h_obj,event); % Handles echowin/picktool_browse ascope_memory event
  end
  
end


