function create_ui_components(obj)

% create_ui_components(obj)
%
% Creates components for the snake param window's UI when the echogram
% window is first opened.
%

set(obj.h_fig,'DockControls','off')
set(obj.h_fig,'NumberTitle','off');
if strcmpi(class(obj.h_fig),'double')
  set(obj.h_fig,'Name',sprintf('%d: %s tool parameters', obj.h_fig, obj.tool_name_title));
else
  set(obj.h_fig,'Name',sprintf('%d: %s tool parameters', obj.h_fig.Number, obj.tool_name_title));
end
set(obj.h_fig,'ToolBar','none');
set(obj.h_fig,'MenuBar','none'); 
set(obj.h_fig,'KeyPressFcn',@obj.key_press);
set(obj.h_fig,'CloseRequestFcn',@obj.close_win);
%set(obj.h_fig,'Resize','off');

set(obj.h_fig,'visible','off');

% set default position (changed when window accessed)
set(obj.h_fig,'Units','Pixels');
set(obj.h_fig,'Position',[0 0 obj.w obj.h]);
% show top panel (snake params) but not bottom panel (crandall params)
%set(obj.top_panel.handle,'visible','on');
%set(obj.bottom_panel.handle,'visible','off');

%==========================================================================
% top panel
obj.top_panel.handle = uipanel('Parent',obj.h_fig);
set(obj.top_panel.handle,'HighlightColor',[0.8 0.8 0.8]);
set(obj.top_panel.handle,'ShadowColor',[0.6 0.6 0.6]);
%set(obj.top_panel.handle,'visible','off');

%--------------------------------------
% table
obj.table.ui=obj.h_fig;

row = 1; col = 1;
obj.table.handles{row,col}   = obj.top_panel.handle;
obj.table.width(row,col)     = inf;
obj.table.height(row,col)    = inf;
obj.table.width_margin(row,col) = 0;
obj.table.height_margin(row,col) = 0;

clear row col
table_draw(obj.table);

%==========================================================================
% top panel table contents

% 
% %-----mode label
% obj.top_panel.mode_label = uicontrol('Parent',obj.top_panel.handle);
% set(obj.top_panel.mode_label,'Style','text');
% set(obj.top_panel.mode_label,'String','Mode');
% 
% %----snake tool list box
% obj.top_panel.tool_PM = uicontrol('Parent',obj.top_panel.handle);
% set(obj.top_panel.tool_PM,'Style','popupmenu');
% set(obj.top_panel.tool_PM,'String',{'basic'});
% set(obj.top_panel.tool_PM,'Value',1)
% set(obj.top_panel.tool_PM,'Callback',@obj.toolPM_callback);

%----insert range
obj.top_panel.manual_range_text = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.manual_range_text,'Style','text');
set(obj.top_panel.manual_range_text,'String','Manual range:');
set(obj.top_panel.manual_range_text,'TooltipString','During manual (left click) entry, this sets the range of bins that will be searched to find the max. Set to "0" to not search.');
%----insert pt search range box
obj.top_panel.manual_rangeTB = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.manual_rangeTB,'Style','edit');
set(obj.top_panel.manual_rangeTB,'String',obj.in_rng_sv);
set(obj.top_panel.manual_rangeTB,'TooltipString','During manual (left click) entry, this sets the range of bins that will be searched to find the max. Set to "0" to not search.');

%----snake search range name
obj.top_panel.snake_range_label = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.snake_range_label,'Style','text');
set(obj.top_panel.snake_range_label,'String','Snake range:');
set(obj.top_panel.snake_range_label,'TooltipString','During auto-snake (ALT left click and drag), snake will search +/- this many bins for the peak intensity.');
%----snake search range box
obj.top_panel.snake_rangeTB = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.snake_rangeTB,'Style','edit');
set(obj.top_panel.snake_rangeTB,'String',obj.sn_rng_sv);
set(obj.top_panel.snake_rangeTB,'TooltipString','During auto-snake (ALT left click and drag), snake will search +/- this many bins for the peak intensity.');

%--------------------------------------------------------------------------
% set up top panel table
obj.top_panel.table.ui=obj.top_panel.handle;
obj.top_panel.table.width_margin = nan(30,30); % Just make these bigger than they have to be
obj.top_panel.table.height_margin = nan(30,30);
obj.top_panel.table.false_width = nan(30,30);
obj.top_panel.table.false_height = nan(30,30);
obj.top_panel.table.offset = [0 0];

row = 0;

% row = row+1; col = 1;
% obj.top_panel.table.handles{row,col}       = obj.top_panel.mode_label;
% obj.top_panel.table.width(row,col)         = inf;
% obj.top_panel.table.height(row,col)        = 20;
% obj.top_panel.table.width_margin(row,col)  = 0;
% obj.top_panel.table.height_margin(row,col) = 3;
% 
% col = 2;
% obj.top_panel.table.handles{row,col}       = obj.top_panel.tool_PM;
% obj.top_panel.table.width(row,col)         = inf;
% obj.top_panel.table.height(row,col)        = 20;
% obj.top_panel.table.width_margin(row,col)  = 0;
% obj.top_panel.table.height_margin(row,col) = 0;

row = row+1; col = 1;
obj.top_panel.table.handles{row,col}       = obj.top_panel.manual_range_text;
obj.top_panel.table.width(row,col)         = inf;
obj.top_panel.table.height(row,col)        = 20;
obj.top_panel.table.width_margin(row,col)  = 0;
obj.top_panel.table.height_margin(row,col) = 3;

col = 2;
obj.top_panel.table.handles{row,col}       = obj.top_panel.manual_rangeTB;
obj.top_panel.table.width(row,col)         = inf;
obj.top_panel.table.height(row,col)        = 20;
obj.top_panel.table.width_margin(row,col)  = 0;
obj.top_panel.table.height_margin(row,col) = 0;

row = row+1; col = 1;
obj.top_panel.table.handles{row,col}       = obj.top_panel.snake_range_label;
obj.top_panel.table.width(row,col)         = inf;
obj.top_panel.table.height(row,col)        = 20;
obj.top_panel.table.width_margin(row,col)  = 0;
obj.top_panel.table.height_margin(row,col) = 3;

col = 2;
obj.top_panel.table.handles{row,col}       = obj.top_panel.snake_rangeTB;
obj.top_panel.table.width(row,col)         = inf;
obj.top_panel.table.height(row,col)        = 20;
obj.top_panel.table.width_margin(row,col)  = 0;
obj.top_panel.table.height_margin(row,col) = 0;

% Add spacer to fill window
row = row+1; col = 1;
obj.top_panel.table.handles{row,col}       = [];
obj.top_panel.table.width(row,col)         = inf;
obj.top_panel.table.height(row,col)        = inf;
obj.top_panel.table.width_margin(row,col)  = 0;
obj.top_panel.table.height_margin(row,col) = 0;

clear row col

% Draw table
table_draw(obj.top_panel.table);

if obj.first_time
  obj.first_time = false;
else
  set(obj.h_fig,'visible','on');
end

return

