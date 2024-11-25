function create_ui(obj)
% echowin.create_ui(obj)
%
% Support function for imb.echowin class. Create user interface for
% echogram window
%

%% Echowin figure
% =========================================================================
set(obj.h_fig,'Units','pixels')
set(obj.h_fig,'Position',[obj.default_params.x obj.default_params.y obj.default_params.w obj.default_params.h]);
set(obj.h_fig,'Units','normalized')
set(obj.h_fig,'DockControls','off')
set(obj.h_fig,'NumberTitle','off');
if strcmpi(class(obj.h_fig),'double')
  set(obj.h_fig,'Name',sprintf('%d: pick',obj.h_fig));
else
  set(obj.h_fig,'Name',sprintf('%d: pick',obj.h_fig.Number));
end
set(obj.h_fig,'ToolBar','none');
set(obj.h_fig,'MenuBar','none');
set(obj.h_fig,'CloseRequestFcn',@obj.close_win);
set(obj.h_fig,'Pointer','custom');
zoom_pointer = [NaN   NaN   NaN   NaN     1     1     1     1   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
  NaN   NaN     1     1   NaN     2   NaN     2     1     1   NaN   NaN   NaN   NaN   NaN   NaN
  NaN     1     2   NaN     2     1     1   NaN     2   NaN     1   NaN   NaN   NaN   NaN   NaN
  NaN     1   NaN     2   NaN     1     1     2   NaN     2     1   NaN   NaN   NaN   NaN   NaN
  1   NaN     2   NaN     2     1     1   NaN     2   NaN     2     1   NaN   NaN   NaN   NaN
  1     2     1     1     1     1     1     1     1     1   NaN     1   NaN   NaN   NaN   NaN
  1   NaN     1     1     1     1     1     1     1     1     2     1   NaN   NaN   NaN   NaN
  1     2   NaN     2   NaN     1     1     2   NaN     2   NaN     1   NaN   NaN   NaN   NaN
  NaN     1     2   NaN     2     1     1   NaN     2   NaN     1   NaN   NaN   NaN   NaN   NaN
  NaN     1   NaN     2   NaN     1     1     2   NaN     2     1     2   NaN   NaN   NaN   NaN
  NaN   NaN     1     1     2   NaN     2   NaN     1     1     1     1     2   NaN   NaN   NaN
  NaN   NaN   NaN   NaN     1     1     1     1   NaN     2     1     1     1     2   NaN   NaN
  NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN     2     1     1     1     2   NaN
  NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN     2     1     1     1     2
  NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN     2     1     1     1
  NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN     2     1     2];
set(obj.h_fig,'PointerShapeCData',zoom_pointer);
set(obj.h_fig,'PointerShapeHotSpot',[6 6])

%% Table
% =========================================================================
% ----left_panel
obj.left_panel.handle = uipanel('Parent',obj.h_fig);
%----right_panel
obj.right_panel.handle = uipanel('Parent',obj.h_fig);
%---------------------------------------------------------------
% echowin table setup
obj.table.ui=obj.h_fig;
obj.table.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
obj.table.height_margin = NaN*zeros(30,30);
obj.table.false_width = NaN*zeros(30,30);
obj.table.false_height = NaN*zeros(30,30);
obj.table.offset = [0 0];
row = 1; col = 1;
obj.table.handles{row,col}   = obj.left_panel.handle;
obj.table.width(row,col)     = 180;
obj.table.height(row,col)    = inf;
obj.table.width_margin(row,col)=0;
obj.table.height_margin(row,col)=0;
row = 1; col = 2;
obj.table.handles{row,col}   = obj.right_panel.handle;
obj.table.width(row,col)     = inf;
obj.table.height(row,col)    = inf;
obj.table.width_margin(row,col)=0;
obj.table.height_margin(row,col)=0;
clear row col
table_draw(obj.table);

%% left_panel.toolPM
% =========================================================================

obj.tool.list = {};

obj.tool.list{end+1} = imb.picktool_interpolate;
addlistener(obj.tool.list{end},'hide_param',@obj.toolparam_close_callback);
% Left click: Enters a point based on parameters
%   Find max in range (specify range line/bin extent to search)
%   Find leading edge in range
%   Recomputes interp if point is within last interpolation range
% Left click and drag: Interpolates between manual points based on paramaters
%   Deletes all previous automated points in range
%   Interpolation tools: linear, spline, max-track, leading-edge-track
% Right click: Set cursor point
% Right click and drag: Delete all points in range
% Scroll: Zooms in/out
% Ctrl + any click: Select layer
% Ctrl + any click and drag: Zoom
% Any double click: Nothing
% Ctrl + double click: Zoom reset

obj.tool.list{end+1} = imb.picktool_viterbi;
addlistener(obj.tool.list{end},'hide_param',@obj.toolparam_close_callback);
% Left click: Enters a manual point based on parameters
%   Find max in range (specify range line/bin extent to search)
% Left click and drag: Runs tomo.viterbi algorithm on selected data.
% Right click: Set cursor point
% Right click and drag: Delete all points in range
% Scroll: Zooms in/out
% Ctrl + any click: Select layer
% Ctrl + any click and drag: Zoom
% Any double click: Nothing
% Ctrl + double click: Zoom reset

obj.tool.list{end+1} = imb.picktool_snake;
addlistener(obj.tool.list{end},'hide_param',@obj.toolparam_close_callback);
% Left click: Enters a point based on parameters
%   Find max in range (specify range line/bin extent to search)
%   Recomputes snake if point is within last range
% Left click and drag: Snakes between manual points based on paramaters
%   Deletes all previous automated points in range
%   Snake tools: basic, crandall, panton
% Right click: Set cursor point
% Right click and drag: Delete all points in range
% Scroll: Zooms in/out
% Ctrl + any click: Select layer
% Ctrl + any click and drag: Zoom
% Any double click: Nothing
% Ctrl + double click: Zoom reset

obj.tool.list{end+1} = imb.picktool_copy([],obj);
addlistener(obj.tool.list{end},'hide_param',@obj.toolparam_close_callback);
% Left click and drag: Copy source layers to the selected layers
%   Deletes all previous points in range
% Right click: Set cursor point
% Right click and drag: Nothing
% Scroll: Zooms in/out
% Ctrl + any click: Select layer
% Ctrl + any click and drag: Zoom
% Any double click: Nothing
% Ctrl + double click: Zoom reset

obj.tool.list{end+1} = imb.picktool_quality;
addlistener(obj.tool.list{end},'hide_param',@obj.toolparam_close_callback);
% Left click: Nothing
% Left click and drag: Sets all points contains in draw to the currently
%   selected quality level
% Right click: Set cursor point
% Right click and drag: Nothing
% Scroll: Zooms in/out
% Ctrl + any click: Select layer
% Ctrl + any click and drag: Zoom
% Any double click: Nothing
% Ctrl + double click: Zoom reset

obj.tool.list{end+1} = imb.picktool_stat;
addlistener(obj.tool.list{end},'hide_param',@obj.toolparam_close_callback);
% Left click: Nothing
% Left click and drag: Sets all points contains in draw to the currently
%   selected quality level
% Right click: Set cursor point
% Right click and drag: Nothing
% Scroll: Zooms in/out
% Ctrl + any click: Select layer
% Ctrl + any click and drag: Zoom
% Any double click: Nothing
% Ctrl + double click: Zoom reset


obj.tool.list{end+1} = imb.picktool_browse;
addlistener(obj.tool.list{end},'hide_param',@obj.toolparam_close_callback);
% Left click: Open A-scope window
% Left click and drag: Nothing
% Right click: Set cursor point
% Right click and drag: Nothing
% Scroll: Zooms in/out
% Ctrl + any click: Select layer
% Ctrl + any click and drag: Zoom
% Any double click: Nothing
% Ctrl + double click: Zoom reset


% obj.tool.list{end+1} = imb.picktool_landmark;
% Left click: Create landmark point
% Left click and drag: Create landmark region
% Right click: Set cursor point
% Right click and drag: 
% Scroll: Zooms in/out
% Ctrl + any click: Select layer
% Ctrl + any click and drag: Zoom
% Any double click: Nothing
% Ctrl + double click: Zoom reset

% Build tool popup menu
obj.left_panel.toolPM = uicontrol('Parent',obj.left_panel.handle);
menuString = {};
for idx = 1:length(obj.tool.list)
  menuString{idx} = obj.tool.list{idx}.tool_name;
end
set(obj.left_panel.toolPM,'String',menuString);
clear menuString;
set(obj.left_panel.toolPM,'Value',1);
tmp = obj.tool.list{1}; obj.tool.left_click_fh = @tmp.left_click;
tmp = obj.tool.list{1}; obj.tool.left_click_and_drag_fh = @tmp.left_click_and_drag;
tmp = obj.tool.list{1}; obj.tool.right_click_fh = @tmp.right_click;
tmp = obj.tool.list{1}; obj.tool.right_click_and_drag_fh = @tmp.right_click_and_drag;

set(obj.left_panel.toolPM,'Style','popupmenu');
set(obj.left_panel.toolPM,'HorizontalAlignment','Center');
set(obj.left_panel.toolPM,'FontName','fixed');
set(obj.left_panel.toolPM,'Callback',@obj.toolPM_callback);
set(obj.left_panel.toolPM,'TooltipString','Select the active tool');

%% left_panel.paramPB
% =========================================================================
obj.left_panel.paramPB = uicontrol('Parent',obj.left_panel.handle);
set(obj.left_panel.paramPB,'Style','PushButton');
set(obj.left_panel.paramPB,'String','Tool Params');
set(obj.left_panel.paramPB,'Callback',@obj.paramPB_callback);
set(obj.left_panel.paramPB,'TooltipString','Open the tool parameters window');

%% left_panel.qualityPM
% =========================================================================
obj.left_panel.qualityPM = uicontrol('Parent',obj.left_panel.handle);
menuString = {};
menuString{1} = 'good';
menuString{2} = 'medium';
menuString{3} = 'poor';
set(obj.left_panel.qualityPM,'String',menuString);
set(obj.left_panel.qualityPM,'Value',1);
clear menuString;
set(obj.left_panel.qualityPM,'Style','popupmenu');
set(obj.left_panel.qualityPM,'HorizontalAlignment','Center');
set(obj.left_panel.qualityPM,'FontName','fixed');
set(obj.left_panel.qualityPM,'callback',@obj.qualityPM_callback);
set(obj.left_panel.qualityPM,'TooltipString','Set the active quality level');

%% left_panel.imagewin (Image Processing)
% =========================================================================
if strcmpi(class(obj.h_fig),'double')
  obj.left_panel.imagewin = imagewin(sprintf('%d: Image Params', obj.h_fig), -1, true);
else
  obj.left_panel.imagewin = imagewin(sprintf('%d: Image Params', obj.h_fig.Number), -1, true);
end
obj.left_panel.imagewin.set_auto_caxis(true);
obj.left_panel.imagewin.img_fn_save_fh = @obj.imagewin_fn_callback;
obj.left_panel.imagewin.save_mat_fh = @obj.imagewin_save_mat_callback;
obj.left_panel.imagewin.img_fn_open_fh = @obj.imagewin_fn_callback;
obj.left_panel.imagePB = uicontrol('Parent',obj.left_panel.handle);
set(obj.left_panel.imagePB,'Style','PushButton');
set(obj.left_panel.imagePB,'String','Image Params');
set(obj.left_panel.imagePB,'Callback',@obj.toggle_imagewin_visibility);
set(obj.left_panel.imagePB,'TooltipString','Open image processing window');

%% left_panel.yaxisPM
% =========================================================================
obj.left_panel.yaxisPM = uicontrol('Parent',obj.left_panel.handle);
set(obj.left_panel.yaxisPM,'Style','PopupMenu');
set(obj.left_panel.yaxisPM,'String',{'TWTT','WGS84','Range','Range Bin','Surface Flat'});
set(obj.left_panel.yaxisPM,'Value',1);
set(obj.left_panel.yaxisPM,'Callback',@obj.yaxisPM_callback);
set(obj.left_panel.yaxisPM,'TooltipString','Set the y-axis units');

%% left_panel.xaxisPM
% =========================================================================
obj.left_panel.xaxisPM = uicontrol('Parent',obj.left_panel.handle);
set(obj.left_panel.xaxisPM,'Style','PopupMenu');
set(obj.left_panel.xaxisPM,'String',{'Range Line','Along Track','GPS Time'});
set(obj.left_panel.xaxisPM,'Value',1);
set(obj.left_panel.xaxisPM,'Callback',@obj.xaxisPM_callback);
set(obj.left_panel.xaxisPM,'TooltipString','Set the x-axis units');

%% left_panel.framesPM
% =========================================================================
obj.left_panel.framesPM = uicontrol('Parent',obj.left_panel.handle);
set(obj.left_panel.framesPM,'Style','popupmenu');
set(obj.left_panel.framesPM,'HorizontalAlignment','Center');
set(obj.left_panel.framesPM,'FontName','fixed');
set(obj.left_panel.framesPM,'String',{'1 Frame','2 Frames','3 Frames','4 Frames','5 Frames','6 Frames','7 Frames','8 Frames','9 Frames','10 Frames'});
set(obj.left_panel.framesPM,'Value',obj.default_params.max_frames);
set(obj.left_panel.framesPM,'Callback',@obj.framesPM_callback);
set(obj.left_panel.framesPM,'TooltipString','Set the number of frames to load/buffer');

%% left_panel.crossoverPB
% =========================================================================
if strcmpi(class(obj.h_fig),'double')
  obj.crossovers.gui = imb.crossover(sprintf('%d: Crossovers',obj.h_fig), true);
else
  obj.crossovers.gui = imb.crossover(sprintf('%d: Crossovers',obj.h_fig.Number), true);
end
addlistener(obj.crossovers.gui,'update_event',@obj.set_visibility);
addlistener(obj.crossovers.gui,'open_crossover_event',@obj.open_crossover);
addlistener(obj.crossovers.gui,'update_cursor',@obj.cursor_crossover);
addlistener(obj.crossovers.gui,'refresh_crossovers_event',@obj.load_crossovers);
obj.left_panel.crossoverPB = uicontrol('Parent',obj.left_panel.handle);
set(obj.left_panel.crossoverPB,'Style','PushButton');
set(obj.left_panel.crossoverPB,'String','Crossovers');
set(obj.left_panel.crossoverPB,'Enable','off');
set(obj.left_panel.crossoverPB,'Callback',@obj.crossoverPB_callback);
set(obj.left_panel.crossoverPB,'TooltipString','Open flightline crossover browse window');

%% left_panel.savePB
% =========================================================================
obj.left_panel.savePB = uicontrol('Parent',obj.left_panel.handle);
set(obj.left_panel.savePB,'Style','PushButton');
set(obj.left_panel.savePB,'String','(S)ave Layer');
set(obj.left_panel.savePB,'Callback',@obj.savePB_callback);
set(obj.left_panel.savePB,'TooltipString','Save layers to database');

%% left_panel.topTable
% =========================================================================
obj.left_panel.topTable.ui = []; % Parent is a table container
obj.left_panel.topTable.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
obj.left_panel.topTable.height_margin = NaN*zeros(30,30);
obj.left_panel.topTable.false_width = NaN*zeros(30,30);
obj.left_panel.topTable.false_height = NaN*zeros(30,30);

row = 1; col = 1;
obj.left_panel.topTable.handles{row,col}   = obj.left_panel.toolPM;
obj.left_panel.topTable.width(row,col)     = inf;
obj.left_panel.topTable.height(row,col)    = 25;

col = col +1;
obj.left_panel.topTable.handles{row,col}   = obj.left_panel.paramPB;
obj.left_panel.topTable.width(row,col)     = inf;
obj.left_panel.topTable.height(row,col)    = 25;

row = row + 1; col = 1;
obj.left_panel.topTable.handles{row,col}   = obj.left_panel.qualityPM;
obj.left_panel.topTable.width(row,col)     = inf;
obj.left_panel.topTable.height(row,col)    = 25;

col = col + 1;
obj.left_panel.topTable.handles{row,col}   = obj.left_panel.imagePB;
obj.left_panel.topTable.width(row,col)     = inf;
obj.left_panel.topTable.height(row,col)    = 25;

row = row + 1; col = 1;
obj.left_panel.topTable.handles{row,col}   = obj.left_panel.yaxisPM;
obj.left_panel.topTable.width(row,col)     = inf;
obj.left_panel.topTable.height(row,col)    = 25;

col = 2;
obj.left_panel.topTable.handles{row,col}   = obj.left_panel.xaxisPM;
obj.left_panel.topTable.width(row,col)     = inf;
obj.left_panel.topTable.height(row,col)    = 25;

row = row + 1; col = 1;
obj.left_panel.topTable.handles{row,col}   = obj.left_panel.framesPM;
obj.left_panel.topTable.width(row,col)     = inf;
obj.left_panel.topTable.height(row,col)    = 25;

col = 2;
obj.left_panel.topTable.handles{row,col}   = obj.left_panel.crossoverPB;
obj.left_panel.topTable.width(row,col)     = inf;
obj.left_panel.topTable.height(row,col)    = 25;

row = row + 1; col = 1;
obj.left_panel.topTable.handles{row,col}   = obj.left_panel.savePB;
obj.left_panel.topTable.width(row,col)     = inf;
obj.left_panel.topTable.height(row,col)    = 25;

clear row col

%% left_panel.layerLB
% =========================================================================
obj.left_panel.layerLB = uicontrol('Parent',obj.left_panel.handle);
set(obj.left_panel.layerLB,'Style','listbox');
set(obj.left_panel.layerLB,'HorizontalAlignment','Center');
set(obj.left_panel.layerLB,'Min',0);
set(obj.left_panel.layerLB,'Max',1e9);
set(obj.left_panel.layerLB,'FontName','fixed');
set(obj.left_panel.layerLB,'Callback',@obj.layerLB_callback);
set(obj.left_panel.layerLB,'TooltipString','Select layers to operate on, right click to open context menu to manipulate list of layers. Red font indicates layer visibility is off.');
obj.left_panel.layerCM = uicontextmenu('Parent',obj.h_fig);
% Define the context menu items and install their callbacks
obj.left_panel.layerCM_visible = uimenu(obj.left_panel.layerCM, 'Label', '&Visible', 'Callback', @obj.layerCM_callback);
obj.left_panel.layerCM_hide = uimenu(obj.left_panel.layerCM, 'Label', '&Hide', 'Callback', @obj.layerCM_callback);
obj.left_panel.layerCM_set_surf = uimenu(obj.left_panel.layerCM, 'Label', 'Set surface layer', 'Callback', @obj.layerCM_callback);
uimenu(obj.left_panel.layerCM, 'Label', '---', 'Callback', @obj.layerCM_callback);
obj.left_panel.layerCM_new = uimenu(obj.left_panel.layerCM, 'Label', '&New layer', 'Callback', @obj.layerCM_callback);
obj.left_panel.layerCM_copy = uimenu(obj.left_panel.layerCM, 'Label', '&Copy layer', 'Callback', @obj.layerCM_callback);
obj.left_panel.layerCM_insert = uimenu(obj.left_panel.layerCM, 'Label', '&Insert layer in sequence', 'Callback', @obj.layerCM_callback);
obj.left_panel.layerCM_edit = uimenu(obj.left_panel.layerCM, 'Label', '&Edit layer', 'Callback', @obj.layerCM_callback);
obj.left_panel.layerCM_sequence = uimenu(obj.left_panel.layerCM, 'Label', '&Sequence layer names', 'Callback', @obj.layerCM_callback);
obj.left_panel.layerCM_order = uimenu(obj.left_panel.layerCM, 'Label', '&Order by twtt', 'Callback', @obj.layerCM_callback);
obj.left_panel.layerCM_up = uimenu(obj.left_panel.layerCM, 'Label', '&Up', 'Callback', @obj.layerCM_callback);
obj.left_panel.layerCM_down = uimenu(obj.left_panel.layerCM, 'Label', '&Down', 'Callback', @obj.layerCM_callback);
obj.left_panel.layerCM_top = uimenu(obj.left_panel.layerCM, 'Label', '&Top', 'Callback', @obj.layerCM_callback);
obj.left_panel.layerCM_bottom = uimenu(obj.left_panel.layerCM, 'Label', '&Bottom', 'Callback', @obj.layerCM_callback);
obj.left_panel.layerCM_detrend = uimenu(obj.left_panel.layerCM, 'Label', 'Detrend', 'Callback', @obj.layerCM_callback,'Checked','off');
obj.left_panel.layerCM_multiple = uimenu(obj.left_panel.layerCM, 'Label', 'Surface Multiple Suppression', 'Callback', @obj.layerCM_callback,'Checked','off');
obj.left_panel.layerCM_properties = uimenu(obj.left_panel.layerCM, 'Label', 'Set properties', 'Callback', @obj.layerCM_callback);
uimenu(obj.left_panel.layerCM, 'Label', '---', 'Callback', @obj.layerCM_callback);
obj.left_panel.layerCM_merge = uimenu(obj.left_panel.layerCM, 'Label', '&Merge layers', 'Callback', @obj.layerCM_callback);
obj.left_panel.layerCM_delete = uimenu(obj.left_panel.layerCM, 'Label', 'Delete layer', 'Callback', @obj.layerCM_callback);
set(obj.left_panel.layerLB,'uicontextmenu',obj.left_panel.layerCM);

%% left_panel.frameLB
% =========================================================================
obj.left_panel.frameLB = uicontrol('Parent',obj.left_panel.handle);
set(obj.left_panel.frameLB,'Style','listbox');
set(obj.left_panel.frameLB,'HorizontalAlignment','Center');
set(obj.left_panel.frameLB,'FontName','fixed');
set(obj.left_panel.frameLB,'Callback',@obj.frameLB_callback);
obj.left_panel.frameCM = uicontextmenu('Parent',obj.h_fig);
% Define the context menu items and install their callbacks
uimenu(obj.left_panel.frameCM, 'Label', 'Copy', 'Callback', @obj.frameCM_callback);
set(obj.left_panel.frameLB,'UIContextMenu',obj.left_panel.frameCM);
set(obj.left_panel.frameLB,'TooltipString','Load frame');

%% left_panel.sourceLB
% =========================================================================
obj.left_panel.sourceLB = uicontrol('Parent',obj.left_panel.handle);
set(obj.left_panel.sourceLB,'Style','listbox');
set(obj.left_panel.sourceLB,'HorizontalAlignment','Center');
set(obj.left_panel.sourceLB,'FontName','fixed');
set(obj.left_panel.sourceLB,'Callback',@obj.sourceLB_callback);
set(obj.left_panel.sourceLB,'TooltipString','Echogram data source to load');
obj.left_panel.sourceCM = uicontextmenu('Parent',obj.h_fig);
% Define the context menu items and install their callbacks
uimenu(obj.left_panel.sourceCM, 'Label', 'Add', 'Callback', @obj.sourceCM_callback);
uimenu(obj.left_panel.sourceCM, 'Label', 'Remove', 'Callback', @obj.sourceCM_callback);
uimenu(obj.left_panel.sourceCM, 'Label', 'Refresh', 'Callback', @obj.sourceCM_callback);
set(obj.left_panel.sourceLB,'uicontextmenu',obj.left_panel.sourceCM);

%% left_panel.table
% =========================================================================
obj.left_panel.table.ui = obj.left_panel.handle;
obj.left_panel.table.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
obj.left_panel.table.height_margin = NaN*zeros(30,30);
obj.left_panel.table.false_width = NaN*zeros(30,30);
obj.left_panel.table.false_height = NaN*zeros(30,30);
obj.left_panel.table.offset = [0 0];

row = 1; col = 1;
obj.left_panel.table.handles{row,col}   = obj.left_panel.topTable;
obj.left_panel.table.width(row,col)     = inf;
obj.left_panel.table.height(row,col)    = 130;
obj.left_panel.table.width_margin(row,col) = 3;
obj.left_panel.table.height_margin(row,col) = 3;

row = 2; col = 1;
obj.left_panel.table.handles{row,col}   = obj.left_panel.layerLB;
obj.left_panel.table.width(row,col)     = inf;
obj.left_panel.table.height(row,col)    = inf;
obj.left_panel.table.width_margin(row,col) = 3;
obj.left_panel.table.height_margin(row,col) = 3;

row = 3; col = 1;
obj.left_panel.table.handles{row,col}   = obj.left_panel.frameLB;
obj.left_panel.table.width(row,col)     = inf;
obj.left_panel.table.height(row,col)    = inf;
obj.left_panel.table.width_margin(row,col) = 3;
obj.left_panel.table.height_margin(row,col) = 3;

row = 4; col = 1;
obj.left_panel.table.handles{row,col}   = obj.left_panel.sourceLB;
obj.left_panel.table.width(row,col)     = inf;
obj.left_panel.table.height(row,col)    = 75;
obj.left_panel.table.width_margin(row,col) = 3;
obj.left_panel.table.height_margin(row,col) = 9;
clear row col

% Draw table
table_draw(obj.left_panel.table);

%% right_panel.axes_panel
% =========================================================================

% create axes panel and axes
obj.right_panel.axes_panel = uipanel('parent',obj.right_panel.handle);
obj.h_axes = axes('parent',obj.right_panel.axes_panel);
axis_pos = get(obj.h_axes,'Position');
% scale up the size of the axes (image part)
% about 87% width of panel and 87% height of panel
xy_diff = axis_pos(1)-axis_pos(2);
x_delta = axis_pos(1)-0.08;
y_delta = axis_pos(2)-0.10+xy_diff;
new_pos = [axis_pos(1)-x_delta axis_pos(2)-y_delta axis_pos(3)+2*x_delta axis_pos(4)+2*y_delta];
set(obj.h_axes,'Position',new_pos);
set(obj.h_axes,'activepositionproperty','outerposition');
set(obj.h_fig,'Colormap',1-gray(256));

% Create imagesc handle
hold(obj.h_axes,'on');
obj.h_image = imagesc([],[],[],'parent',obj.h_axes);
obj.left_panel.imagewin.set_img(obj.h_image);

% Create cursor plot handle
obj.cursor.h = plot(NaN,NaN,'kx--','parent',obj.h_axes);

% create statusbar panel
obj.right_panel.status_panel.handle = uipanel('Parent',obj.right_panel.handle);

% create statusbar's elements: cmd info, cursor info, mouse coordinate info
% command info display
obj.right_panel.status_panel.statusText = uicontrol('parent',obj.right_panel.status_panel.handle);
set(obj.right_panel.status_panel.statusText,'Style','text');
%set(obj.right_panel.status_panel.statusText,'FontName','courier');
if isunix
  set(obj.right_panel.status_panel.statusText,'FontSize',9)
else
  set(obj.right_panel.status_panel.statusText,'FontSize',8)
end
set(obj.right_panel.status_panel.statusText,'HorizontalAlignment','left');
set(obj.right_panel.status_panel.statusText,'String','');
set(obj.right_panel.status_panel.statusText,'TooltipString','Right click or ctrl-C to copy status bar text. Status bar text shows time and location at cursor; shows layer depth if a layer is selected.');

% mouse coordinate info display
obj.right_panel.status_panel.mouseCoordText = uicontrol('parent',obj.right_panel.status_panel.handle);
set(obj.right_panel.status_panel.mouseCoordText,'Style','text');
%set(obj.right_panel.status_panel.mouseCoordText,'FontName','courier');
if isunix
  set(obj.right_panel.status_panel.mouseCoordText,'FontSize',9)
else
  set(obj.right_panel.status_panel.mouseCoordText,'FontSize',8)
end
set(obj.right_panel.status_panel.mouseCoordText,'HorizontalAlignment','left');
set(obj.right_panel.status_panel.mouseCoordText,'String','');
set(obj.right_panel.status_panel.mouseCoordText,'TooltipString','Frame Latitude (deg, N) Longitude (deg, W) |X-coordinate|Y-coordinate|Z-coordinate/intensity.');

%----echogram context menu
obj.right_panel.echoCM= uicontextmenu('parent',obj.h_fig);
% Define the context menu items and install their callbacks
obj.right_panel.echoCM_copy = uimenu(obj.right_panel.echoCM, 'Label', 'Copy Cursor Info (Ctrl-C)', 'Callback',@obj.status_text_copy_callback);
set(obj.right_panel.status_panel.statusText,'uicontextmenu',obj.right_panel.echoCM);

%% right_panel.status_panel
% =========================================================================
obj.right_panel.status_panel.table.ui = obj.right_panel.status_panel.handle;
obj.right_panel.status_panel.table.offset = [0 2];
row = 1; col = 1;
obj.right_panel.status_panel.table.handles{row,col}       = obj.right_panel.status_panel.statusText;
obj.right_panel.status_panel.table.width(row,col)         = inf;
obj.right_panel.status_panel.table.height(row,col)        = inf;
obj.right_panel.status_panel.table.width_margin(row,col)  = 0;
obj.right_panel.status_panel.table.height_margin(row,col) = 0;
row = 1; col = 2;
obj.right_panel.status_panel.table.handles{row,col}       = obj.right_panel.status_panel.mouseCoordText;
obj.right_panel.status_panel.table.width(row,col)         = 250;
obj.right_panel.status_panel.table.height(row,col)        = inf;
obj.right_panel.status_panel.table.width_margin(row,col)  = 0;
obj.right_panel.status_panel.table.height_margin(row,col) = 0;
clear row col
table_draw(obj.right_panel.status_panel.table);

% make the right panel's table 
obj.right_panel.table.ui=obj.right_panel.handle;
obj.right_panel.table.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
obj.right_panel.table.height_margin = NaN*zeros(30,30);
obj.right_panel.table.false_width = NaN*zeros(30,30);
obj.right_panel.table.false_height = NaN*zeros(30,30);
obj.right_panel.table.offset = [0 0];
row = 1; col = 1;
obj.right_panel.table.handles{row,col}   = obj.right_panel.axes_panel;
obj.right_panel.table.width(row,col)     = inf;
obj.right_panel.table.height(row,col)    = inf;
obj.right_panel.table.width_margin(row,col)=0;
obj.right_panel.table.height_margin(row,col)=0;
row = 2; col = 1;
obj.right_panel.table.handles{row,col}   = obj.right_panel.status_panel.handle;
obj.right_panel.table.width(row,col)     = inf;
obj.right_panel.table.height(row,col)    = 15;
obj.right_panel.table.width_margin(row,col)=0;
obj.right_panel.table.height_margin(row,col)=0;
obj.right_panel.table.false_height(row,col)=0;
clear row col
table_draw(obj.right_panel.table);

% Set all units to normalized for doing calculations with mouse clicks later
set(obj.right_panel.handle,'Units','normalized');
set(obj.right_panel.status_panel.handle,'Units','normalized');
