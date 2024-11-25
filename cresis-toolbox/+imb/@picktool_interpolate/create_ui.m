function create_ui(obj)

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

%----max rbins label
obj.panel.manual_range_label = uicontrol('Parent',obj.h_fig);
set(obj.panel.manual_range_label,'Style','text');
set(obj.panel.manual_range_label,'String',sprintf('Manual range:'));
set(obj.panel.manual_range_label,'FontSize',10)
set(obj.panel.manual_range_label,'TooltipString','During manual (left click) entry, this sets the range of bins that will be searched to find the max. Set to "0" to not search.');

%----max rbins entry
obj.panel.manual_rangeTB = uicontrol('Parent',obj.h_fig);
set(obj.panel.manual_rangeTB,'Style','edit');
set(obj.panel.manual_rangeTB,'String','1');
set(obj.panel.manual_rangeTB,'FontSize',10);
set(obj.panel.manual_rangeTB,'TooltipString','During manual (left click) entry, this sets the range of bins that will be searched to find the max. Set to "0" to not search.');

% %----threshold label
% obj.panel.leading_edge_thresh_label = uicontrol('Parent',obj.h_fig);
% set(obj.panel.leading_edge_thresh_label,'Style','text');
% set(obj.panel.leading_edge_thresh_label,'String','LE threshold:');
% set(obj.panel.leading_edge_thresh_label,'FontSize',10)
% 
% %----threshold entry
% obj.panel.leading_edge_thresh_tbox = uicontrol('Parent',obj.h_fig);
% set(obj.panel.leading_edge_thresh_tbox,'Style','edit');
% set(obj.panel.leading_edge_thresh_tbox,'String','0');
% set(obj.panel.leading_edge_thresh_tbox,'FontSize',10);
% 
%----Interpolation label
obj.panel.interp_mode_label = uicontrol('Parent',obj.h_fig);
set(obj.panel.interp_mode_label,'Style','text');
set(obj.panel.interp_mode_label,'String',sprintf('Interpolation:'));
set(obj.panel.interp_mode_label,'FontSize',10)
set(obj.panel.interp_mode_label,'TooltipString','During auto-interp (ALT left click and drag), manual points will be interpolated with this method.');

%----Interpolation pulldown menu
obj.panel.interp_modePM = uicontrol('Parent',obj.h_fig);
set(obj.panel.interp_modePM,'Style','popupmenu');
set(obj.panel.interp_modePM,'String',...
  {'linear','spline'});
set(obj.panel.interp_modePM,'FontSize',10);
set(obj.panel.interp_modePM,'TooltipString','During auto-interp (ALT left click and drag), manual points will be interpolated with this method.');
% 
% %----reinterp mode label
% obj.panel.reinterp_mode_label = uicontrol('Parent',obj.h_fig);
% set(obj.panel.reinterp_mode_label,'Style','text');
% set(obj.panel.reinterp_mode_label,'String',sprintf('Reinterpolation: (beta)'));
% set(obj.panel.reinterp_mode_label,'FontSize',10)
% 
% %----reinterp mode checkbox
% obj.panel.reinterp_mode_cbox = uicontrol('Parent',obj.h_fig);
% set(obj.panel.reinterp_mode_cbox,'Style','checkbox');

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
obj.panel.table.handles{row,col}   = obj.panel.manual_range_label;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 3;

col = 2;
obj.panel.table.handles{row,col}   = obj.panel.manual_rangeTB;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 0;

% row = row+1; col = 1;
% obj.panel.table.handles{row,col}   = obj.panel.leading_edge_thresh_label;
% obj.panel.table.width(row,col)     = inf;
% obj.panel.table.height(row,col)    = 20;
% obj.panel.table.width_margin(row,col) = 0;
% obj.panel.table.height_margin(row,col) = 3;
% 
% col = 2;
% obj.panel.table.handles{row,col}   = obj.panel.leading_edge_thresh_tbox;
% obj.panel.table.width(row,col)     = inf;
% obj.panel.table.height(row,col)    = 20;
% obj.panel.table.width_margin(row,col) = 0;
% obj.panel.table.height_margin(row,col) = 0;
% 
row = row+1; col = 1;
obj.panel.table.handles{row,col}   = obj.panel.interp_mode_label;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 3;

col = 2;
obj.panel.table.handles{row,col}   = obj.panel.interp_modePM;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 0;
% 
% row = row+1; col = 1;
% obj.panel.table.handles{row,col}   = obj.panel.reinterp_mode_label;
% obj.panel.table.width(row,col)     = inf;
% obj.panel.table.height(row,col)    = 20;
% obj.panel.table.width_margin(row,col) = 0;
% obj.panel.table.height_margin(row,col) = 3;
% 
% col = 2;
% obj.panel.table.handles{row,col}   = obj.panel.reinterp_mode_cbox;
% obj.panel.table.width(row,col)     = inf;
% obj.panel.table.height(row,col)    = 20;
% obj.panel.table.width_margin(row,col) = 0;
% obj.panel.table.height_margin(row,col) = 0;

% Add spacer to fill window
row = row+1; col = 1;
obj.panel.table.handles{row,col}   = [];
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = inf;
obj.panel.table.width_margin(row,col)= 1.5;
obj.panel.table.height_margin(row,col)=1.5;

clear row col
table_draw(obj.panel.table);
