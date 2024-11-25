function create_ui(obj)
% create_ui(obj)
%
% Create tool parameters user interface for imb.picker statistics tool
%
% Author: Dhagash Kapadia, John Paden

set(obj.h_fig,'DockControls','off')
set(obj.h_fig,'NumberTitle','off');
if strcmpi(class(obj.h_fig),'double')
  set(obj.h_fig,'Name',sprintf('%d: %s tool parameters', obj.h_fig, obj.tool_name_title));
else
  set(obj.h_fig,'Name',sprintf('%d: %s tool parameters', obj.h_fig.Number, obj.tool_name_title));
end
set(obj.h_fig,'ToolBar','none');
set(obj.h_fig,'MenuBar','none'); 
set(obj.h_fig,'CloseRequestFcn',@obj.close_win);
set(obj.h_fig,'KeyPressFcn',@obj.key_press);
%set(obj.h_fig,'Resize','off');
% set default position (changed when window accessed)
set(obj.h_fig,'Position',[0 0 obj.w obj.h]);

%==========================================================================
% top panel
obj.panel.handle = uipanel('Parent',obj.h_fig);
set(obj.panel.handle,'HighlightColor',[0.8 0.8 0.8]);
set(obj.panel.handle,'ShadowColor',[0.6 0.6 0.6]);
%set(obj.panel.handle,'visible','off');

%--------------------------------------
% table
obj.table.ui=obj.h_fig;

row = 1; col = 1;
obj.table.handles{row,col}       = obj.panel.handle;
obj.table.width(row,col)         = inf;
obj.table.height(row,col)        = inf;
obj.table.width_margin(row,col)  = 0;
obj.table.height_margin(row,col) = 0;

clear row col
table_draw(obj.table);

%----Stat Options label
obj.panel.stat_mode_label = uicontrol('Parent',obj.h_fig);
set(obj.panel.stat_mode_label,'Style','text');
set(obj.panel.stat_mode_label,'String',sprintf('Stat Options:'));
set(obj.panel.stat_mode_label,'FontSize',10)
set(obj.panel.stat_mode_label,'TooltipString','Choose the action to be taken on the selected image pixels.');

%----Stat Options pulldown menu
obj.panel.stat_modePM = uicontrol('Parent',obj.h_fig);
set(obj.panel.stat_modePM,'Style','popupmenu');
set(obj.panel.stat_modePM,'String',...
  {'Overall Statistics', 'Histogram', 'Line by Line Statistics'});
set(obj.panel.stat_modePM,'FontSize',10);
set(obj.panel.stat_modePM,'TooltipString','Choose the action to be taken on the selected image pixels.');

%----Close Stat Window label
obj.panel.close_stat_window_label = uicontrol('Parent',obj.h_fig);
set(obj.panel.close_stat_window_label,'Style','text');
set(obj.panel.close_stat_window_label,'String',sprintf('Stat Options:'));
set(obj.panel.close_stat_window_label,'FontSize',10);
set(obj.panel.close_stat_window_label,'TooltipString','Choose the action to be taken on the selected image pixels.');

%----Close Stat Window pushbutton
obj.panel.close_stat_windowPB = uicontrol('Parent',obj.h_fig);
set(obj.panel.close_stat_windowPB,'Style','PushButton');
set(obj.panel.close_stat_windowPB,'String','Close Stat Tool Windows');
set(obj.panel.close_stat_windowPB,'FontSize',10);
set(obj.panel.close_stat_windowPB,'TooltipString','Closes all the windows that this stat window has opened.');
set(obj.panel.close_stat_windowPB,'Callback',@obj.close_stat_windows);

%---------------------------------------------------------------------------------------------
% set up top panel table
obj.panel.table.ui=obj.panel.handle;
obj.panel.table.width_margin = nan(30,30); % Just make these bigger than they have to be
obj.panel.table.height_margin = nan(30,30);
obj.panel.table.false_width = nan(30,30);
obj.panel.table.false_height = nan(30,30);
obj.panel.table.offset = [0 0];

row = 0;

row = row+1; col = 1;
obj.panel.table.handles{row,col}   = obj.panel.stat_mode_label;
obj.panel.table.width(row,col)     = 100;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 3;

col = 2;
obj.panel.table.handles{row,col}   = obj.panel.stat_modePM;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 0;

row = row+1; col = 1;
obj.panel.table.handles{row,col}   = obj.panel.close_stat_window_label;
obj.panel.table.width(row,col)     = 100;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 3;

col = 2;
obj.panel.table.handles{row,col}   = obj.panel.close_stat_windowPB;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 25;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 0;

% Add spacer to fill window
row = row+1; col = 1;
obj.panel.table.handles{row,col}   = [];
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = inf;
obj.panel.table.width_margin(row,col)= 1.5;
obj.panel.table.height_margin(row,col)=1.5;

clear row col
table_draw(obj.panel.table);
