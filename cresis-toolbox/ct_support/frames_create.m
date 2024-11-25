% Class frames_create
%
% Class for creating and manipulating frames.
%
% Examples:
% obj = frames_create(param,param_overide);

classdef (HandleCompatible = true) frames_create < handle
  properties
    % GUI handles
    h_fig
    h_geotiff % Handle to geotiff class
    h_gui % Structure with all the other graphics handles and graphics related properties
    
    % frame information
    param
    records
    frames
    
  end
  
  methods
    %% Creator
    function obj = frames_create(param,param_override)
      
      %% Creator: General Setup
      % =====================================================================
      if exist('param_override','var')
        obj.param = merge_structs(param, param_override);
      else
        obj.param = param;
      end
      
      fprintf('=====================================================================\n');
      fprintf('%s: %s (%s)\n', mfilename, obj.param.day_seg, datestr(now));
      fprintf('=====================================================================\n');

      %% Creator: Input checks
      % =====================================================================
      
      if ~isfield(obj.param.records.frames,'length') || isempty(obj.param.records.frames.length)
        output_dir = ct_output_dir(obj.param.radar_name);
        if any(strcmpi(output_dir,'rds'))
          obj.param.records.frames.length = 50000;
        elseif any(strcmpi(output_dir,'accum'))
          obj.param.records.frames.length = 20000;
        elseif any(strcmpi(output_dir,{'kaband','kuband','snow'}))
          obj.param.records.frames.length = 5000;
        else
          % Unknown output_dir
          obj.param.records.frames.length = 20000;
        end
      end
      if ~isfield(obj.param.records.frames,'min_length') || isempty(obj.param.records.frames.min_length)
        obj.param.records.frames.min_length = obj.param.records.frames.length/2;
      end
      
      %% Creator: Setup
      % =====================================================================
      
      frames_fn = ct_filename_support(obj.param,'','frames');
      
      obj.records = records_load(obj.param,'gps_time','lat','lon');
      
      if exist(frames_fn,'file')
        obj.frames = frames_load(obj.param);
        if any(obj.frames.frame_idxs > length(obj.records.lat))
          warning('Frames file %s\ncontains indices past the end of the records file. These indices will be ignored.', frames_fn);
          obj.frames.frame_idxs = obj.frames.frame_idxs(obj.frames.frame_idxs <= length(obj.records.lat));
        end
      else
        obj.frames.frame_idxs = 1;
        obj.frames.proc_mode = 0;
      end
      
      if ~isfield(obj.records,'lat') || isempty(obj.records.lat) || all(isnan(obj.records.lat))
        if exist(frames_fn,'file')
          warning('No geographic data present in records file. Frames file already exists, just exiting.');
        else
          warning('No geographic data present in records file. No frames file exists, creating single frame and exiting.');
          
          frames.gps_time = [obj.records.gps_time(frames.frame_idxs), obj.records.gps_time(end)];
          Nfrms = length(frames.frame_idxs);
          frames.notes = cell(1,Nfrms);
          if ~isfield(frames,'quality')
            frames.quality = zeros(1,Nfrms);
          end
          if ~isfield(frames,'proc_mode')
            frames.proc_mode = zeros(1,Nfrms);
          end
          frames.Nx = length(obj.records.gps_time);
          frames.param.day_seg = param.day_seg;
          frames.param.season_name = param.season_name;
          frames.param.radar_name = param.radar_name;
          frames.param.sw_version = param.sw_version;
          
          if param.ct_file_lock
            frames.file_version = '1L';
          else
            frames.file_version = '1';
          end
          frames.file_type = 'frames';
          fprintf('  Saving %s\n', frames_fn);
          frames_fn_dir = fileparts(frames_fn);
          if ~exist(frames_fn_dir,'dir')
            mkdir(frames_fn_dir);
          end
          ct_save(frames_fn,'-struct','frames');
        end
        delete(obj);
        return;
      end
      
      obj.records.along_track = geodetic_to_along_track(obj.records.lat,obj.records.lon);

      %% Creator: GUI Setup
      % =====================================================================
      
      obj.h_gui = [];
      obj.h_fig = figure;
      pos = get(obj.h_fig,'Position');
      set(obj.h_fig,'Position',[pos(1:2) 800 420]);
      set(obj.h_fig,'Name',param.day_seg);
      set(obj.h_fig,'DockControls','off');
      set(obj.h_fig,'ToolBar','none');
      set(obj.h_fig,'MenuBar','none');

      % Create widgets of main table
      obj.h_gui.fig.ctrl_panel.handle = uipanel('Parent',obj.h_fig);
      set(obj.h_gui.fig.ctrl_panel.handle,'Title','Frame Controls');
      set(obj.h_gui.fig.ctrl_panel.handle,'TitlePosition','CenterTop');
      set(obj.h_gui.fig.ctrl_panel.handle,'HighlightColor',[0.8 0.8 0.8]);
      set(obj.h_gui.fig.ctrl_panel.handle,'ShadowColor',[0.6 0.6 0.6]);
      
      obj.h_gui.fig.map_axes.handle = axes('parent',obj.h_fig);
      
      % Setup main table
      obj.h_gui.fig.table.ui = obj.h_fig;
      row = 1; col = 1;
      obj.h_gui.fig.table.handles{row,col}   = obj.h_gui.fig.ctrl_panel.handle;
      obj.h_gui.fig.table.width(row,col)     = 220;
      obj.h_gui.fig.table.height(row,col)    = inf;
      obj.h_gui.fig.table.false_height(row,col) = 0;
      col = col + 1;
      obj.h_gui.fig.table.handles{row,col}   = obj.h_gui.fig.map_axes.handle;
      obj.h_gui.fig.table.width(row,col)     = inf;
      obj.h_gui.fig.table.height(row,col)    = inf;
      obj.h_gui.fig.table.false_height(row,col) = 0;
      obj.h_gui.fig.table.width_margin(row,col) = 60;
      obj.h_gui.fig.table.height_margin(row,col) = 40;
      clear row col
      table_draw(obj.h_gui.fig.table);
      
      obj.h_gui.fig.ctrl_panel.framesLB = uicontrol('Parent',obj.h_gui.fig.ctrl_panel.handle);
      set(obj.h_gui.fig.ctrl_panel.framesLB,'Style','listbox');
      set(obj.h_gui.fig.ctrl_panel.framesLB,'HorizontalAlignment','Center');
      set(obj.h_gui.fig.ctrl_panel.framesLB,'FontName','fixed');
      set(obj.h_gui.fig.ctrl_panel.framesLB,'Max',inf);
      set(obj.h_gui.fig.ctrl_panel.framesLB,'Callback',@obj.framesLB_callback);
      
      obj.h_gui.fig.ctrl_panel.startLabel = uicontrol('Parent',obj.h_gui.fig.ctrl_panel.handle);
      set(obj.h_gui.fig.ctrl_panel.startLabel,'Style','Text');
      set(obj.h_gui.fig.ctrl_panel.startLabel,'String','Start Record');
      set(obj.h_gui.fig.ctrl_panel.startLabel,'HorizontalAlignment','Center');
      
      obj.h_gui.fig.ctrl_panel.startTB = uicontrol('Parent',obj.h_gui.fig.ctrl_panel.handle);
      set(obj.h_gui.fig.ctrl_panel.startTB,'Style','Edit');
      set(obj.h_gui.fig.ctrl_panel.startTB,'HorizontalAlignment','Center');
      set(obj.h_gui.fig.ctrl_panel.startTB,'Enable','off');
      
      obj.h_gui.fig.ctrl_panel.stopLabel = uicontrol('Parent',obj.h_gui.fig.ctrl_panel.handle);
      set(obj.h_gui.fig.ctrl_panel.stopLabel,'Style','Text');
      set(obj.h_gui.fig.ctrl_panel.stopLabel,'String','Stop Record');
      set(obj.h_gui.fig.ctrl_panel.stopLabel,'HorizontalAlignment','Center');
      
      obj.h_gui.fig.ctrl_panel.stopTB = uicontrol('Parent',obj.h_gui.fig.ctrl_panel.handle);
      set(obj.h_gui.fig.ctrl_panel.stopTB,'Style','Edit');
      set(obj.h_gui.fig.ctrl_panel.stopTB,'HorizontalAlignment','Center');
      set(obj.h_gui.fig.ctrl_panel.stopTB,'Enable','off');
      
      obj.h_gui.fig.ctrl_panel.procLabel = uicontrol('Parent',obj.h_gui.fig.ctrl_panel.handle);
      set(obj.h_gui.fig.ctrl_panel.procLabel,'Style','Text');
      set(obj.h_gui.fig.ctrl_panel.procLabel,'String','Process Mode');
      set(obj.h_gui.fig.ctrl_panel.procLabel,'HorizontalAlignment','Center');
      
      obj.h_gui.fig.ctrl_panel.procTB = uicontrol('Parent',obj.h_gui.fig.ctrl_panel.handle);
      set(obj.h_gui.fig.ctrl_panel.procTB,'Style','Edit');
      set(obj.h_gui.fig.ctrl_panel.procTB,'HorizontalAlignment','Center');
      set(obj.h_gui.fig.ctrl_panel.procTB,'Callback',@obj.procTB_callback);
      
      obj.h_gui.fig.ctrl_panel.createPB = uicontrol('Parent',obj.h_gui.fig.ctrl_panel.handle);
      set(obj.h_gui.fig.ctrl_panel.createPB,'Style','PushButton');
      set(obj.h_gui.fig.ctrl_panel.createPB,'String','Create');
      set(obj.h_gui.fig.ctrl_panel.createPB,'Callback',@obj.createPB_callback);
      set(obj.h_gui.fig.ctrl_panel.createPB,'Enable','off');
      
      obj.h_gui.fig.ctrl_panel.deletePB = uicontrol('Parent',obj.h_gui.fig.ctrl_panel.handle);
      set(obj.h_gui.fig.ctrl_panel.deletePB,'Style','PushButton');
      set(obj.h_gui.fig.ctrl_panel.deletePB,'String','Delete');
      set(obj.h_gui.fig.ctrl_panel.deletePB,'Callback',@obj.deletePB_callback);
      
      obj.h_gui.fig.ctrl_panel.frmTable.ui = []; % Parent is a table container
      obj.h_gui.fig.ctrl_panel.frmTable.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
      obj.h_gui.fig.ctrl_panel.frmTable.height_margin = NaN*zeros(30,30);
      obj.h_gui.fig.ctrl_panel.frmTable.false_width = NaN*zeros(30,30);
      obj.h_gui.fig.ctrl_panel.frmTable.false_height = NaN*zeros(30,30);
      row = 1; col = 1;
      obj.h_gui.fig.ctrl_panel.frmTable.handles{row,col}   = obj.h_gui.fig.ctrl_panel.startLabel;
      obj.h_gui.fig.ctrl_panel.frmTable.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.frmTable.height(row,col)    = 25;
      obj.h_gui.fig.ctrl_panel.frmTable.false_width(row,col) = 5;
      col = col + 1;
      obj.h_gui.fig.ctrl_panel.frmTable.handles{row,col}   = obj.h_gui.fig.ctrl_panel.startTB;
      obj.h_gui.fig.ctrl_panel.frmTable.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.frmTable.height(row,col)    = 25;
      obj.h_gui.fig.ctrl_panel.frmTable.false_width(row,col) = 5;
      col = 1; row = row + 1;
      obj.h_gui.fig.ctrl_panel.frmTable.handles{row,col}   = obj.h_gui.fig.ctrl_panel.stopLabel;
      obj.h_gui.fig.ctrl_panel.frmTable.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.frmTable.height(row,col)    = 25;
      obj.h_gui.fig.ctrl_panel.frmTable.false_width(row,col) = 5;
      col = col + 1;
      obj.h_gui.fig.ctrl_panel.frmTable.handles{row,col}   = obj.h_gui.fig.ctrl_panel.stopTB;
      obj.h_gui.fig.ctrl_panel.frmTable.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.frmTable.height(row,col)    = 25;
      obj.h_gui.fig.ctrl_panel.frmTable.false_width(row,col) = 5;
      col = 1; row = row + 1;
      obj.h_gui.fig.ctrl_panel.frmTable.handles{row,col}   = obj.h_gui.fig.ctrl_panel.procLabel;
      obj.h_gui.fig.ctrl_panel.frmTable.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.frmTable.height(row,col)    = 25;
      obj.h_gui.fig.ctrl_panel.frmTable.false_width(row,col) = 5;
      col = col + 1;
      obj.h_gui.fig.ctrl_panel.frmTable.handles{row,col}   = obj.h_gui.fig.ctrl_panel.procTB;
      obj.h_gui.fig.ctrl_panel.frmTable.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.frmTable.height(row,col)    = 25;
      obj.h_gui.fig.ctrl_panel.frmTable.false_width(row,col) = 5;
      col = 1; row = row + 1;
      obj.h_gui.fig.ctrl_panel.frmTable.handles{row,col}   = obj.h_gui.fig.ctrl_panel.createPB;
      obj.h_gui.fig.ctrl_panel.frmTable.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.frmTable.height(row,col)    = 25;
      obj.h_gui.fig.ctrl_panel.frmTable.false_width(row,col) = 5;
      col = col + 1;
      obj.h_gui.fig.ctrl_panel.frmTable.handles{row,col}   = obj.h_gui.fig.ctrl_panel.deletePB;
      obj.h_gui.fig.ctrl_panel.frmTable.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.frmTable.height(row,col)    = 25;
      obj.h_gui.fig.ctrl_panel.frmTable.false_width(row,col) = 5;
      clear row col
      
      obj.h_gui.fig.ctrl_panel.lengthLabel = uicontrol('Parent',obj.h_gui.fig.ctrl_panel.handle);
      set(obj.h_gui.fig.ctrl_panel.lengthLabel,'Style','Text');
      set(obj.h_gui.fig.ctrl_panel.lengthLabel,'String','Min Length (km)');
      set(obj.h_gui.fig.ctrl_panel.lengthLabel,'HorizontalAlignment','Center');
      
      obj.h_gui.fig.ctrl_panel.lengthTB = uicontrol('Parent',obj.h_gui.fig.ctrl_panel.handle);
      set(obj.h_gui.fig.ctrl_panel.lengthTB,'Style','Edit');
      set(obj.h_gui.fig.ctrl_panel.lengthTB,'String',sprintf('%g',obj.param.records.frames.length/2/1e3));
      set(obj.h_gui.fig.ctrl_panel.lengthTB,'HorizontalAlignment','Center');
      set(obj.h_gui.fig.ctrl_panel.lengthTB,'Enable','on');
      
      obj.h_gui.fig.ctrl_panel.maxLengthLabel = uicontrol('Parent',obj.h_gui.fig.ctrl_panel.handle);
      set(obj.h_gui.fig.ctrl_panel.maxLengthLabel,'Style','Text');
      set(obj.h_gui.fig.ctrl_panel.maxLengthLabel,'String','Max Length (km)');
      set(obj.h_gui.fig.ctrl_panel.maxLengthLabel,'HorizontalAlignment','Center');
      
      obj.h_gui.fig.ctrl_panel.maxLengthTB = uicontrol('Parent',obj.h_gui.fig.ctrl_panel.handle);
      set(obj.h_gui.fig.ctrl_panel.maxLengthTB,'Style','Edit');
      set(obj.h_gui.fig.ctrl_panel.maxLengthTB,'HorizontalAlignment','Center');
      set(obj.h_gui.fig.ctrl_panel.maxLengthTB,'String',sprintf('%g',obj.param.records.frames.length/1e3));
      
      obj.h_gui.fig.ctrl_panel.autoTable.ui = []; % Parent is a table container
      obj.h_gui.fig.ctrl_panel.autoTable.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
      obj.h_gui.fig.ctrl_panel.autoTable.height_margin = NaN*zeros(30,30);
      obj.h_gui.fig.ctrl_panel.autoTable.false_width = NaN*zeros(30,30);
      obj.h_gui.fig.ctrl_panel.autoTable.false_height = NaN*zeros(30,30);
      row = 1; col = 1;
      obj.h_gui.fig.ctrl_panel.autoTable.handles{row,col}   = obj.h_gui.fig.ctrl_panel.lengthLabel;
      obj.h_gui.fig.ctrl_panel.autoTable.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.autoTable.height(row,col)    = 25;
      obj.h_gui.fig.ctrl_panel.autoTable.false_width(row,col) = 5;
      col = col + 1;
      obj.h_gui.fig.ctrl_panel.autoTable.handles{row,col}   = obj.h_gui.fig.ctrl_panel.lengthTB;
      obj.h_gui.fig.ctrl_panel.autoTable.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.autoTable.height(row,col)    = 25;
      obj.h_gui.fig.ctrl_panel.autoTable.false_width(row,col) = 5;
      col = 1; row = row + 1;
      obj.h_gui.fig.ctrl_panel.autoTable.handles{row,col}   = obj.h_gui.fig.ctrl_panel.maxLengthLabel;
      obj.h_gui.fig.ctrl_panel.autoTable.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.autoTable.height(row,col)    = 25;
      obj.h_gui.fig.ctrl_panel.autoTable.false_width(row,col) = 5;
      col = col + 1;
      obj.h_gui.fig.ctrl_panel.autoTable.handles{row,col}   = obj.h_gui.fig.ctrl_panel.maxLengthTB;
      obj.h_gui.fig.ctrl_panel.autoTable.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.autoTable.height(row,col)    = 25;
      obj.h_gui.fig.ctrl_panel.autoTable.false_width(row,col) = 5;
      
      obj.h_gui.fig.ctrl_panel.autoGenPB = uicontrol('Parent',obj.h_gui.fig.ctrl_panel.handle);
      set(obj.h_gui.fig.ctrl_panel.autoGenPB,'Style','PushButton');
      set(obj.h_gui.fig.ctrl_panel.autoGenPB,'String','Autogenerate');
      set(obj.h_gui.fig.ctrl_panel.autoGenPB,'Callback',@obj.autoGenPB_callback);
      
      obj.h_gui.fig.ctrl_panel.savePB = uicontrol('Parent',obj.h_gui.fig.ctrl_panel.handle);
      set(obj.h_gui.fig.ctrl_panel.savePB,'Style','PushButton');
      set(obj.h_gui.fig.ctrl_panel.savePB,'String','Save Frames');
      set(obj.h_gui.fig.ctrl_panel.savePB,'Callback',@obj.savePB_callback);
      
      obj.h_gui.fig.ctrl_panel.table.ui = obj.h_gui.fig.ctrl_panel.handle;
      obj.h_gui.fig.ctrl_panel.table.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
      obj.h_gui.fig.ctrl_panel.table.height_margin = NaN*zeros(30,30);
      obj.h_gui.fig.ctrl_panel.table.false_width = NaN*zeros(30,30);
      obj.h_gui.fig.ctrl_panel.table.false_height = NaN*zeros(30,30);
      obj.h_gui.fig.ctrl_panel.table.offset = [0 10];
      row = 1; col = 1;
      obj.h_gui.fig.ctrl_panel.table.handles{row,col}   = obj.h_gui.fig.ctrl_panel.framesLB;
      obj.h_gui.fig.ctrl_panel.table.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.table.height(row,col)    = inf;
      obj.h_gui.fig.ctrl_panel.table.false_width(row,col) = 5;
      row = row + 1;
      obj.h_gui.fig.ctrl_panel.table.handles{row,col}   = obj.h_gui.fig.ctrl_panel.frmTable;
      obj.h_gui.fig.ctrl_panel.table.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.table.height(row,col)    = 100;
      obj.h_gui.fig.ctrl_panel.table.false_width(row,col) = 0;
      obj.h_gui.fig.ctrl_panel.table.width_margin(row,col) = 0;
      obj.h_gui.fig.ctrl_panel.table.height_margin(row,col) = 0;
      obj.h_gui.fig.ctrl_panel.table.false_width(row,col) = 5;
      row = row + 1;
      obj.h_gui.fig.ctrl_panel.table.handles{row,col}   = obj.h_gui.fig.ctrl_panel.autoTable;
      obj.h_gui.fig.ctrl_panel.table.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.table.height(row,col)    = 50;
      obj.h_gui.fig.ctrl_panel.table.false_width(row,col) = 0;
      obj.h_gui.fig.ctrl_panel.table.width_margin(row,col) = 0;
      obj.h_gui.fig.ctrl_panel.table.height_margin(row,col) = 0;
      row = row + 1;
      obj.h_gui.fig.ctrl_panel.table.handles{row,col}   = obj.h_gui.fig.ctrl_panel.autoGenPB;
      obj.h_gui.fig.ctrl_panel.table.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.table.height(row,col)    = 25;
      obj.h_gui.fig.ctrl_panel.table.false_width(row,col) = 5;
      row = row + 1;
      obj.h_gui.fig.ctrl_panel.table.handles{row,col}   = obj.h_gui.fig.ctrl_panel.savePB;
      obj.h_gui.fig.ctrl_panel.table.width(row,col)     = inf;
      obj.h_gui.fig.ctrl_panel.table.height(row,col)    = 25;
      obj.h_gui.fig.ctrl_panel.table.false_width(row,col) = 5;
      clear row col
      table_draw(obj.h_gui.fig.ctrl_panel.table);
      
      %% Creator: Map
      % =====================================================================
      obj.h_geotiff = geotiff(ct_filename_gis(param,obj.param.records.frames.geotiff_fn), [obj.h_fig obj.h_gui.fig.map_axes.handle]);
      addlistener(obj.h_geotiff,'close_window_event',@obj.close_win);
      addlistener(obj.h_geotiff,'selection_event',@obj.frm_selection_callback);
      obj.h_geotiff.stdout = false;
      obj.h_geotiff.marker = 'x';
      obj.h_geotiff.line_style = 'none';
      obj.h_geotiff.F1_callback = @obj.F1_callback;
      obj.h_geotiff.button_up_callback = @obj.button_up_callback;
      obj.h_geotiff.key_press_callback = @obj.key_press_callback;

      hold(obj.h_geotiff.h_axes,'on');
      if isempty(obj.h_geotiff.proj)
        x = obj.records.lon;
        y = obj.records.lat;
      else
        [x,y] = projfwd(obj.h_geotiff.proj,obj.records.lat,obj.records.lon);
        x = x/1e3;
        y = y/1e3;
      end
      obj.h_gui.plot_records = plot(x,y,'Color','blue');
      
      segment = [];
      segment.lat = obj.records.lat(obj.frames.frame_idxs);
      segment.lon = obj.records.lon(obj.frames.frame_idxs);
      segment.lat = segment.lat(:);
      segment.lon = segment.lon(:);
      segment.name = regexprep(param.day_seg,'_','\\_');
      segment.value = {};
      segment.value_name = {};
      obj.h_geotiff.insert_segment(segment);
      
      % Set strings in GUI according to frames list
      for idx = 1:length(obj.frames.frame_idxs)
        if idx == length(obj.frames.frame_idxs)
          frm = [obj.frames.frame_idxs(idx) length(obj.records.lat)];
        else
          frm = [obj.frames.frame_idxs(idx); obj.frames.frame_idxs(idx+1)-1];
        end
        frm_text{idx} = sprintf('Frm %2d: %8d-%8d %4.1f km', idx, frm(1), frm(2), diff(obj.records.along_track(frm(1:2))/1e3));
      end
      set(obj.h_gui.fig.ctrl_panel.framesLB,'String',frm_text);
      
      % Update GUI with new frame list
      obj.update_frame_gui();
      
    end
    
    %% Destructor
    % =====================================================================
    function delete(obj)
      % Delete the map figure handle
      try
        delete(obj.h_geotiff);
      end
      try
        delete(obj.h_fig);
      end
    end
    
    %% Close Window Handler
    % =====================================================================
    function close_win(obj,h_obj,event)
      try
        delete(obj);
      end
    end
    
    
    %% framesLB_callback
    % =====================================================================
    function framesLB_callback(obj,hObj,event)
      frm = get(obj.h_gui.fig.ctrl_panel.framesLB,'Value');
      
      obj.h_geotiff.set_selection(1,frm)
      
      obj.update_frame_gui;
    end
    
    %% frm_selection_callback
    % =====================================================================
    function frm_selection_callback(obj,hObj,event)
      mask = obj.h_geotiff.get_selection(1);
      mask = mask{1}; mask(1) = 0;
      
      set(obj.h_gui.fig.ctrl_panel.framesLB,'Value',find(mask));
      
      obj.update_frame_gui;
    end
    
    %% procTB_callback
    % =====================================================================
    function procTB_callback(obj,hObj,event)
      
      obj.frames.proc_mode(obj.cur_frame) = str2double(get(hObj,'String'));
      
    end
    
    %% createPB_callback
    % =====================================================================
    function createPB_callback(obj,hObj,event)
      
    end
    
    %% deletePB_callback
    % =====================================================================
    function deletePB_callback(obj,hObj,event)
      
      mask = obj.h_geotiff.get_selection(1);
      mask = mask{1}; mask(1) = 0;
      
      obj.frames.frame_idxs = obj.frames.frame_idxs(~mask);
      obj.frames.proc_mode = obj.frames.proc_mode(~mask);
      
      obj.h_geotiff.delete_pnt(1,find(mask));
      
      frm_text = get(obj.h_gui.fig.ctrl_panel.framesLB,'String');
      frm_text = frm_text(~mask);
      for frm = 1:length(frm_text)
        if frm == length(obj.frames.frame_idxs)
          recs = [obj.frames.frame_idxs(frm) length(obj.records.lat)];
        else
          recs = [obj.frames.frame_idxs(frm); obj.frames.frame_idxs(frm+1)-1];
        end
        frm_text{frm} = sprintf('Frm %2d: %8d-%8d %4.1f km', frm, recs(1), recs(2), diff(obj.records.along_track(recs(1:2))/1e3));
      end
      set(obj.h_gui.fig.ctrl_panel.framesLB,'String',frm_text);
  
      obj.update_frame_gui;
      
    end
    
    %% autoGenPB_callback
    % =====================================================================
    function autoGenPB_callback(obj,hObj,event)
      
      mask = obj.h_geotiff.get_selection(1);
      frm = find(mask{1},1); % Only autogenerate for the first selection
      if isempty(frm)
        return;
      end
      
      start_rec = obj.frames.frame_idxs(frm);
      if frm == length(obj.frames.frame_idxs)
        stop_rec = length(obj.records.lat);
      else
        stop_rec = obj.frames.frame_idxs(frm+1);
      end
      
      try
        obj.param.records.frames.length = str2double(get(obj.h_gui.fig.ctrl_panel.maxLengthTB,'String'))*1e3;
      end
      try
        obj.param.records.frames.min_length = str2double(get(obj.h_gui.fig.ctrl_panel.lengthTB,'String'))*1e3;
      end
      frame_breaks = obj.records.along_track(start_rec)+obj.param.records.frames.length ...
        : obj.param.records.frames.length : obj.records.along_track(stop_rec);
      if isempty(frame_breaks)
        return;
      end
      if obj.records.along_track(stop_rec)-frame_breaks(end) < obj.param.records.frames.min_length
        frame_breaks = frame_breaks(1:end-1);
      end
      if isempty(frame_breaks)
        return;
      end
      num = length(frame_breaks);
      
      obj.frames.frame_idxs(frm+1+num:end+num) = obj.frames.frame_idxs(frm+1:end);
      idx = 1;
      rec = start_rec;
      while idx <= num
        if obj.records.along_track(rec) > frame_breaks(idx)
          obj.frames.frame_idxs(frm+idx) = rec;
          idx = idx + 1;
        end
        rec = rec + 1;
      end
      
      obj.frames.proc_mode(frm+1+num:end+num) = obj.frames.proc_mode(frm+1:end);
      new_proc_mode = str2double(get(obj.h_gui.fig.ctrl_panel.procTB,'String'));
      obj.frames.proc_mode(frm+(1:num)) = new_proc_mode;
      
      segment.lat = obj.records.lat(obj.frames.frame_idxs(frm+(1:num)));
      segment.lon = obj.records.lon(obj.frames.frame_idxs(frm+(1:num)));
      segment.value = cell(num,0);
      obj.h_geotiff.insert_pnt(1,frm,segment);
      
      % Set strings in GUI according to frames list
      for frm = 1:length(obj.frames.frame_idxs)
        if frm == length(obj.frames.frame_idxs)
          recs = [obj.frames.frame_idxs(frm) length(obj.records.lat)];
        else
          recs = [obj.frames.frame_idxs(frm); obj.frames.frame_idxs(frm+1)-1];
        end
        frm_text{frm} = sprintf('Frm %2d: %8d-%8d %4.1f km', frm, recs(1), recs(2), diff(obj.records.along_track(recs(1:2))/1e3));
      end
      set(obj.h_gui.fig.ctrl_panel.framesLB,'String',frm_text);
      
      obj.update_frame_gui;
      
    end
    
    %% savePB_callback
    % =====================================================================
    function savePB_callback(obj,hObj,event)
      
      frames_fn = ct_filename_support(obj.param,'','frames');
      frames_fn_dir = fileparts(frames_fn);
      if ~exist(frames_fn_dir,'dir')
        fprintf('Making directory %s\n', frames_fn_dir);
        mkdir(frames_fn_dir);
      end
      
      obj.frames.gps_time = [obj.records.gps_time(obj.frames.frame_idxs), obj.records.gps_time(end)];
      Nfrms = length(obj.frames.frame_idxs);
      obj.frames.notes = cell(1,Nfrms);
      if ~isfield(obj.frames,'quality')
        obj.frames.quality = zeros(1,Nfrms);
      end
      if ~isfield(obj.frames,'proc_mode')
        obj.frames.proc_mode = zeros(1,Nfrms);
      end
      obj.frames.Nx = length(obj.records.gps_time);
      obj.frames.param.day_seg = obj.param.day_seg;
      obj.frames.param.season_name = obj.param.season_name;
      obj.frames.param.radar_name = obj.param.radar_name;
      obj.frames.param.sw_version = obj.param.sw_version;
      
      if obj.param.ct_file_lock
        obj.frames.file_version = '1L';
      else
        obj.frames.file_version = '1';
      end
      obj.frames.file_type = 'frames';
      ct_file_lock_check(frames_fn,3);
      fprintf('Saving %s\n', frames_fn);
      frames = obj.frames;
      ct_save(frames_fn,'-struct','frames');
      
    end
    
    %% find_closest_point
    function [min_dist min_idx] = find_closest_point(obj,x,y)
      
      records_x = get(obj.h_gui.plot_records,'XData');
      records_y = get(obj.h_gui.plot_records,'YData');
      [min_dist min_idx] = min((x - records_x).^2 + (y - records_y).^2);
      
    end
    
    %% update_frame_gui
    % =====================================================================
    function update_frame_gui(obj)
      
      mask = obj.h_geotiff.get_selection(1);
      mask = mask{1};
      frm = find(mask,1);
      if isempty(frm)
        frm = 1;
      end
      
      if frm == length(obj.frames.frame_idxs)
        recs = [obj.frames.frame_idxs(frm) length(obj.records.lat)];
      else
        recs = [obj.frames.frame_idxs(frm); obj.frames.frame_idxs(frm+1)-1];
      end
      set(obj.h_gui.fig.ctrl_panel.startTB,'String',sprintf('%d',recs(1)));
      set(obj.h_gui.fig.ctrl_panel.stopTB,'String',sprintf('%d',recs(2)));
      set(obj.h_gui.fig.ctrl_panel.procTB,'String',sprintf('%d',obj.frames.proc_mode(frm)));
      
      set(obj.h_gui.fig.ctrl_panel.framesLB,'Value',find(mask));
      
    end
    
    %% button_up_callback
    % =====================================================================
    function status = button_up_callback(obj,src,event)
      status = 0;
      
      [x,y,but] = get_mouse_info(obj.h_fig,obj.h_gui.fig.map_axes.handle);
      %fprintf('Button Up: x = %.3f, y = %.3f, but = %d\n', x, y, but); % DEBUG ONLY
      
      xlimits = xlim(obj.h_gui.fig.map_axes.handle);
      ylimits = ylim(obj.h_gui.fig.map_axes.handle);
      if x < xlimits(1) || x > xlimits(2) || y < ylimits(1) || y > ylimits(2)
        return;
      end
      
      if but == 3
        % ===================================================================
        % Right mouse button: add a frame break
        
        % Find the closest point
        [min_dist min_idx] = obj.find_closest_point(x,y);
        
        % Determine where the new break is in the list of frames
        frm = find(obj.frames.frame_idxs >= min_idx,1);
        if isempty(frm)
          frm = length(obj.frames.frame_idxs) + 1;
        elseif min_idx == obj.frames.frame_idxs(frm)
          return;
        end
        obj.frames.frame_idxs(frm+1:end+1) = obj.frames.frame_idxs(frm:end);
        obj.frames.frame_idxs(frm) = min_idx;
        obj.frames.proc_mode(frm+1:end+1) = obj.frames.proc_mode(frm:end);
        obj.frames.proc_mode(frm) = str2double(get(obj.h_gui.fig.ctrl_panel.procTB,'String'));
        segment.lat = obj.records.lat(min_idx);
        segment.lon = obj.records.lon(min_idx);
        segment.value = cell(1,0);
        obj.h_geotiff.insert_pnt(1,frm-1,segment);
      
        % Set strings in GUI according to frames list
        for frm = 1:length(obj.frames.frame_idxs)
          if frm == length(obj.frames.frame_idxs)
            recs = [obj.frames.frame_idxs(frm) length(obj.records.lat)];
          else
            recs = [obj.frames.frame_idxs(frm); obj.frames.frame_idxs(frm+1)-1];
          end
          frm_text{frm} = sprintf('Frm %2d: %8d-%8d %4.1f km', frm, recs(1), recs(2), diff(obj.records.along_track(recs(1:2))/1e3));
        end
        set(obj.h_gui.fig.ctrl_panel.framesLB,'String',frm_text);
        
        obj.update_frame_gui;
        status = 0;
      end
      
    end
    
    %% F1_callback
    % =====================================================================
    function F1_callback(obj,src,event)
      fprintf('<strong>Frames</strong>\n');
      fprintf('right-click: Create a new frame break at click\n');
      fprintf('Delete: Delete the selected frame break\n');
    end
    
    %% key_press_callback
    % =====================================================================
    function status = key_press_callback(obj,src,event)
      status = 1;
      
      % see event.Modifier for modifiers
      switch event.Key
        case {'backspace','delete'}
          obj.deletePB_callback();
          status = 0;
        case 'downarrow'
          if gco == obj.h_gui.fig.ctrl_panel.framesLB
            status = 0;
          end
          
        case 'uparrow'
          if gco == obj.h_gui.fig.ctrl_panel.framesLB
            status = 0;
          end
      end
      
    end
    
  end
end
