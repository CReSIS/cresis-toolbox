function create_ui(obj)
% picktool_copy.create_ui(obj)

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

%----source layer label
obj.panel.source_label = uicontrol('Parent',obj.panel.handle);
set(obj.panel.source_label,'Style','text');
set(obj.panel.source_label,'String','Source layer:');
set(obj.panel.source_label,'FontSize',10);
tooptip_str = 'This is the source layer to copy into all active layers. Select parts of this layer in the echogram to copy layers for the selected section.';
set(obj.panel.source_label,'TooltipString',tooptip_str);

%----source layer edit
obj.panel.sourceTB = uicontrol('Parent',obj.panel.handle);
set(obj.panel.sourceTB,'Style','edit');
set(obj.panel.sourceTB,'String','1');
set(obj.panel.sourceTB,'FontSize',10);
set(obj.panel.sourceTB,'TooltipString',tooptip_str);

%----source eval label
obj.panel.source_eval_label = uicontrol('Parent',obj.panel.handle);
set(obj.panel.source_eval_label,'Style','text');
set(obj.panel.source_eval_label,'String','Source eval:');
set(obj.panel.source_eval_label,'FontSize',10)
tooltip_str = 'Only used for "Copy" mode. The source layer will have this operation run on it. The source layer is stored in a variable called "s". Default is "s=s" which does no operation. "s=0.5*s" would halve the value of the source layer.';
set(obj.panel.source_eval_label,'TooltipString',tooltip_str);

%----source eval edit
obj.panel.source_evalTB = uicontrol('Parent',obj.panel.handle);
set(obj.panel.source_evalTB,'Style','edit');
set(obj.panel.source_evalTB,'String','s=s');
set(obj.panel.source_evalTB,'FontSize',10);
set(obj.panel.source_evalTB,'TooltipString',tooltip_str);

%----correct layer label
obj.panel.correct_label = uicontrol('Parent',obj.panel.handle);
set(obj.panel.correct_label,'Style','text');
set(obj.panel.correct_label,'String','Correct layer:');
set(obj.panel.correct_label,'FontSize',10)
tooltip_str = 'If Enable Diff selected, then selecting the source layer will cause active layers to change by correct - source.';
set(obj.panel.correct_label,'TooltipString',tooltip_str);

%----correct layer edit
obj.panel.correctTB = uicontrol('Parent',obj.panel.handle);
set(obj.panel.correctTB,'Style','edit');
set(obj.panel.correctTB,'String','1');
set(obj.panel.correctTB,'FontSize',10);
set(obj.panel.correctTB,'TooltipString',tooltip_str);

%----mode label
obj.panel.mode_label = uicontrol('Parent',obj.panel.handle);
set(obj.panel.mode_label,'Style','text');
set(obj.panel.mode_label,'String','Copy Mode:');
set(obj.panel.mode_label,'FontSize',10);
tooltip_str = sprintf('Copy: Copies the "Source layer" to the selected layers after running "Source eval"\nMerge: Merges the "Source layer" into the undefined sections of the selected layers.\nDiff: Applies the difference between the "Correct layer" and the "Source layer" to the selected layers.');
set(obj.panel.mode_label,'TooltipString',tooltip_str);

%----mode checkbox
obj.panel.modePM = uicontrol('Parent',obj.panel.handle);
set(obj.panel.modePM,'Style','popupmenu');
set(obj.panel.modePM,'String', {'Copy','Merge','Diff'});
set(obj.panel.modePM,'Value', 1);
set(obj.panel.modePM,'TooltipString',tooltip_str);

%----shift layer label
obj.panel.shift_label = uicontrol('Parent',obj.panel.handle);
set(obj.panel.shift_label,'Style','text');
set(obj.panel.shift_label,'String','Shift Size:');
set(obj.panel.shift_label,'FontSize',10)
set(obj.panel.shift_label,'TooltipString','This controls the number of range bins that the up/down functions shift a layer.');

%----shift layer edit
obj.panel.shiftTB = uicontrol('Parent',obj.panel.handle);
set(obj.panel.shiftTB,'Style','edit');
set(obj.panel.shiftTB,'String','1');
set(obj.panel.shiftTB,'FontSize',10);
set(obj.panel.shiftTB,'TooltipString','This controls the number of range bins that the up/down functions shift a layer.');

%----up pushbutton
obj.panel.upPB = uicontrol('Parent',obj.panel.handle);
set(obj.panel.upPB,'Style','PushButton');
set(obj.panel.upPB,'String','Up'); 
set(obj.panel.upPB,'FontSize',10);
set(obj.panel.upPB,'Callback',@obj.upPB_callback);
set(obj.panel.upPB,'TooltipString','Shift selected layers up by number of range bins listed in Shift Size'); 

%----down pushbutton
obj.panel.downPB = uicontrol('Parent',obj.panel.handle);
set(obj.panel.downPB,'Style','PushButton');
set(obj.panel.downPB,'String','Down'); 
set(obj.panel.downPB,'FontSize',10);
set(obj.panel.downPB,'Callback',@obj.downPB_callback);
set(obj.panel.downPB,'TooltipString','Shift selected layers down by number of range bins listed in Shift Size'); 

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
obj.panel.table.handles{row,col}   = obj.panel.source_label;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 3;

col = 2;
obj.panel.table.handles{row,col}   = obj.panel.sourceTB;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 0;

row = row+1; col = 1;
obj.panel.table.handles{row,col}   = obj.panel.source_eval_label;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 3;

col = 2;
obj.panel.table.handles{row,col}   = obj.panel.source_evalTB;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 0;

row = row+1; col = 1;
obj.panel.table.handles{row,col}   = obj.panel.correct_label;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 3;

col = 2;
obj.panel.table.handles{row,col}   = obj.panel.correctTB;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 0;

row = row+1; col = 1;
obj.panel.table.handles{row,col}   = obj.panel.mode_label;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 3;

col = 2;
obj.panel.table.handles{row,col}   = obj.panel.modePM;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 0;

row = row+1; col = 1;
obj.panel.table.handles{row,col}   = obj.panel.shift_label;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 3;

col = 2;
obj.panel.table.handles{row,col}   = obj.panel.shiftTB;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 0;

row = row+1; col = 1;
obj.panel.table.handles{row,col}   = obj.panel.upPB;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
obj.panel.table.width_margin(row,col) = 0;
obj.panel.table.height_margin(row,col) = 0;

col = 2;
obj.panel.table.handles{row,col}   = obj.panel.downPB;
obj.panel.table.width(row,col)     = inf;
obj.panel.table.height(row,col)    = 20;
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
