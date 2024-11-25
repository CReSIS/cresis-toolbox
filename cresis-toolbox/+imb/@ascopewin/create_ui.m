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
  set(obj.h_fig,'Name',sprintf('%d: ascope',obj.h_fig));
else
  set(obj.h_fig,'Name',sprintf('%d: ascope',obj.h_fig.Number));
end
set(obj.h_fig,'ToolBar','none');
set(obj.h_fig,'MenuBar','none');
%% Set up general handles
set(obj.h_fig,'WindowButtonDownFcn',@obj.button_down);
set(obj.h_fig,'WindowButtonMotionFcn',@obj.button_motion);
set(obj.h_fig,'WindowButtonUpFcn',@obj.button_up);
set(obj.h_fig,'WindowScrollWheelFcn',@obj.button_scroll);
set(obj.h_fig,'CloseRequestFcn',@obj.close_win);
set(obj.h_fig,'WindowKeyPressFcn',@obj.key_press);

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

%% left_panel.ascopeLB
% =========================================================================
obj.left_panel.ascopeLB = uicontrol('Parent',obj.left_panel.handle);
set(obj.left_panel.ascopeLB,'Style','listbox');
set(obj.left_panel.ascopeLB,'HorizontalAlignment','Center');
set(obj.left_panel.ascopeLB,'Min',0);
set(obj.left_panel.ascopeLB,'Max',1e9);
set(obj.left_panel.ascopeLB,'FontName','fixed');
set(obj.left_panel.ascopeLB,'Callback',@obj.ascopeLB_callback);
set(obj.left_panel.ascopeLB,'TooltipString','Select ascopes to operate on, right click to open context menu to manipulate ascopes. Red font indicates ascope visibility is off.');
obj.left_panel.ascopeCM = uicontextmenu('Parent',obj.h_fig);
% Define the context menu items and install their callbacks
obj.left_panel.ascopeCM_visible = uimenu(obj.left_panel.ascopeCM, 'Label', '&Visible', 'Callback', @obj.ascopeCM_callback);
obj.left_panel.ascopeCM_hide = uimenu(obj.left_panel.ascopeCM, 'Label', '&Hide', 'Callback', @obj.ascopeCM_callback);
uimenu(obj.left_panel.ascopeCM, 'Label', '---', 'Callback', @obj.ascopeCM_callback);
obj.left_panel.ascopeCM_memory = uimenu(obj.left_panel.ascopeCM, 'Label', '&Memory', 'Callback', @obj.ascopeCM_callback);
obj.left_panel.ascopeCM_copy = uimenu(obj.left_panel.ascopeCM, 'Label', '&Copy information', 'Callback', @obj.ascopeCM_callback);
obj.left_panel.ascopeCM_up = uimenu(obj.left_panel.ascopeCM, 'Label', '&Up', 'Callback', @obj.ascopeCM_callback);
obj.left_panel.ascopeCM_down = uimenu(obj.left_panel.ascopeCM, 'Label', '&Down', 'Callback', @obj.ascopeCM_callback);
obj.left_panel.ascopeCM_top = uimenu(obj.left_panel.ascopeCM, 'Label', '&Top', 'Callback', @obj.ascopeCM_callback);
obj.left_panel.ascopeCM_bottom = uimenu(obj.left_panel.ascopeCM, 'Label', '&Bottom', 'Callback', @obj.ascopeCM_callback);
uimenu(obj.left_panel.ascopeCM, 'Label', '---', 'Callback', @obj.ascopeCM_callback);
obj.left_panel.ascopeCM_delete = uimenu(obj.left_panel.ascopeCM, 'Label', 'Delete ascope', 'Callback', @obj.ascopeCM_callback);
set(obj.left_panel.ascopeLB,'uicontextmenu',obj.left_panel.ascopeCM);

%% left_panel.xaxisPM
% =========================================================================
obj.left_panel.xaxisPM = uicontrol('Parent',obj.left_panel.handle);
set(obj.left_panel.xaxisPM,'Style','PopupMenu');
set(obj.left_panel.xaxisPM,'String',{'Twtt','Depth Air','Depth Ice'});
set(obj.left_panel.xaxisPM,'Value',1);
set(obj.left_panel.xaxisPM,'Callback',@obj.xaxisPM_callback);
set(obj.left_panel.xaxisPM,'TooltipString','Set the x-axis units');

%% left_panel.table
% =========================================================================
obj.left_panel.table.ui = obj.left_panel.handle;
obj.left_panel.table.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
obj.left_panel.table.height_margin = NaN*zeros(30,30);
obj.left_panel.table.false_width = NaN*zeros(30,30);
obj.left_panel.table.false_height = NaN*zeros(30,30);
obj.left_panel.table.offset = [0 0];

row = 1; col = 1;
obj.left_panel.table.handles{row,col}   = obj.left_panel.ascopeLB;
obj.left_panel.table.width(row,col)     = inf;
obj.left_panel.table.height(row,col)    = inf;
obj.left_panel.table.width_margin(row,col) = 3;
obj.left_panel.table.height_margin(row,col) = 3;

row = 2; col = 1;
obj.left_panel.table.handles{row,col}   = obj.left_panel.xaxisPM;
obj.left_panel.table.width(row,col)     = inf;
obj.left_panel.table.height(row,col)    = 25;
obj.left_panel.table.width_margin(row,col) = 3;
obj.left_panel.table.height_margin(row,col) = 3;
clear row col

% Draw table
table_draw(obj.left_panel.table);

%% right_panel.axes_panel
% =========================================================================

% create axes panel and axes
obj.right_panel.axes_panel = uipanel('parent',obj.right_panel.handle);
obj.h_axes = axes('parent',obj.right_panel.axes_panel,'XGrid','on','YGrid','on');
xlabel(obj.h_axes,'TWTT (us)');
ylabel(obj.h_axes,'Relative power (dB)');

axis_pos = get(obj.h_axes,'Position');
% scale up the size of the axes (image part)
% about 87% width of panel and 87% height of panel
xy_diff = axis_pos(1)-axis_pos(2);
x_delta = axis_pos(1)-0.12;
y_delta = axis_pos(2)-0.14+xy_diff;
new_pos = [axis_pos(1)-x_delta axis_pos(2)-y_delta axis_pos(3)+2*x_delta axis_pos(4)+2*y_delta];
set(obj.h_axes,'Position',new_pos);
set(obj.h_axes,'activepositionproperty','outerposition');
set(obj.h_fig,'Colormap',1-gray(256));

% Create imagesc handle
hold(obj.h_axes,'on');

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
obj.right_panel.status_panel.table.width(row,col)         = 200;
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
