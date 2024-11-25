function create_ui(obj)
% create_ui(obj)
%
% Creates components for the window's UI when the echogram
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

set(obj.h_fig,'visible','off');

% set default position (changed when window accessed)
set(obj.h_fig,'Units','Pixels');
set(obj.h_fig,'Position',[0 0 obj.w obj.h]);

%==========================================================================
% top panel
obj.top_panel.handle = uipanel('Parent',obj.h_fig);
set(obj.top_panel.handle,'HighlightColor',[0.8 0.8 0.8]);
set(obj.top_panel.handle,'ShadowColor',[0.6 0.6 0.6]);

%--------------------------------------
% table
obj.table.ui=obj.h_fig;

obj.table.handles{1,1}        = obj.top_panel.handle;
obj.table.width(1,1)          = inf;
obj.table.height(1,1)         = inf;
obj.table.width_margin(1,1)   = 0;
obj.table.height_margin(1,1)  = 0;

table_draw(obj.table);

%==========================================================================
% top panel table contents

%----insert range
tooltip = 'Viterbi will search +/- this many bins for the peak intensity on insert';
obj.top_panel.insert_range_label = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.insert_range_label,'Style','text');
set(obj.top_panel.insert_range_label,'String','Max point range:');
set(obj.top_panel.insert_range_label,'TooltipString', tooltip);
%----insert pt search range box
obj.top_panel.insert_range_TE = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.insert_range_TE,'Style','edit');
set(obj.top_panel.insert_range_TE,'String','5');
set(obj.top_panel.insert_range_TE,'TooltipString', tooltip);

%-----Horizontal Bounding
tooltip = sprintf(['<html>How to bound the input and output of Viterbi horizontally<br /><br />', ...
                   '<b>Entire Echogram</b>: no bounding -- search entire echogram<br />', ...
                   '<b>Selection Box</b>: Search within bounds of selection box<br />', ...
                   '<b>Extreme Groundtruth</b>: Search between extreme groundtruth points within selection box</html>']);
obj.top_panel.hori_bound_label = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.hori_bound_label,'Style','text');
set(obj.top_panel.hori_bound_label,'String','Horizontal Bounding');
set(obj.top_panel.hori_bound_label,'TooltipString', tooltip);
%----Horizontal Bounding popupmenu
obj.top_panel.hori_bound_PM = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.hori_bound_PM,'Style','popupmenu');
set(obj.top_panel.hori_bound_PM,'String',{'Entire Echogram', 'Selection Box', 'Extreme Groundtruth'});
set(obj.top_panel.hori_bound_PM,'Value', 2)
set(obj.top_panel.hori_bound_PM,'TooltipString', tooltip);

%-----Vertical Bounding
tooltip = sprintf(['<html>How to bound the input and output of Viterbi vertically<br /><br />', ...
                   '<b>Entire Echogram</b>: no bounding -- search entire echogram<br />', ...
                   '<b>Selection Box</b>: Search within bounds of selection box<br />', ...
                   '<b>Layers</b>: Search between top and bottom layers specified below.</html>']);
obj.top_panel.vert_bound_label = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.vert_bound_label,'Style','text');
set(obj.top_panel.vert_bound_label,'String','Vertical Bounding');
set(obj.top_panel.vert_bound_label,'TooltipString', tooltip);
%----Vertical Bounding popupmenu
obj.top_panel.vert_bound_PM = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.vert_bound_PM,'Style','popupmenu');
set(obj.top_panel.vert_bound_PM,'String',{'Entire Echogram', 'Selection Box', 'Layers'});
set(obj.top_panel.vert_bound_PM,'Value', 2)
set(obj.top_panel.vert_bound_PM,'TooltipString', tooltip);

%----top layer label
tooltip = 'Upper search bound specified as a layer number. "n" refers to selected layer number. Expressions accepted. Ignored if vertical bounds not set to ''Layers''.';
obj.top_panel.top_layer_label = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.top_layer_label,'Style','text');
set(obj.top_panel.top_layer_label,'String','Top Layer:');
set(obj.top_panel.top_layer_label,'TooltipString', tooltip);
%----top layer box
obj.top_panel.top_layer_TE = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.top_layer_TE,'Style','edit');
set(obj.top_panel.top_layer_TE,'String', 'n-1');
set(obj.top_panel.top_layer_TE,'TooltipString', tooltip);

%----bottom layer label
tooltip = 'Lower search bound specified as a layer number. "n" refers to selected layer number. Expressions accepted. Ignored if vertical bounds not set to ''Layers''.';
obj.top_panel.bottom_layer_label = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.bottom_layer_label,'Style','text');
set(obj.top_panel.bottom_layer_label,'String','Bottom Layer:');
set(obj.top_panel.bottom_layer_label,'TooltipString', tooltip);
%----bottom layer box
obj.top_panel.bottom_layer_TE = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.bottom_layer_TE,'Style','edit');
set(obj.top_panel.bottom_layer_TE,'String', 'n+1');
set(obj.top_panel.bottom_layer_TE,'TooltipString', tooltip);

%----layer guard label
tooltip = 'Restrict the vertical layer bounds by this many more bins. Only used for ''layer'' vertical bounding.';
obj.top_panel.layer_guard_label = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.layer_guard_label,'Style','text');
set(obj.top_panel.layer_guard_label,'String','Layer Guard:');
set(obj.top_panel.layer_guard_label,'TooltipString', tooltip);
%----layer guard box
obj.top_panel.layer_guard_TE = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.layer_guard_TE,'Style','edit');
set(obj.top_panel.layer_guard_TE,'String', '2');
set(obj.top_panel.layer_guard_TE,'TooltipString', tooltip);

%----along track weight label
tooltip = 'The weight by which to multiply the binary cost. Greater weight = smoother. This value should be larger (e.g. 1) for low resolution radars or smooth layers. This value should be smaller (e.g. 0.001) for fine resolution radars or where the layer is changing rapidly.';
obj.top_panel.along_track_weight_label = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.along_track_weight_label,'Style','text');
set(obj.top_panel.along_track_weight_label,'String','Smoothness weight:');
set(obj.top_panel.along_track_weight_label,'TooltipString', tooltip);
%----along track weight box
obj.top_panel.along_track_weight_TE = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.along_track_weight_TE,'Style','edit');
set(obj.top_panel.along_track_weight_TE,'String', '0.1');
set(obj.top_panel.along_track_weight_TE,'TooltipString', tooltip);

%----gt cutoff label
tooltip = 'Points must be chosen within this many rangebins of a ground truth point when present. -1 for any distance allowed.';
obj.top_panel.ground_truth_cutoff_label = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.ground_truth_cutoff_label,'Style','text');
set(obj.top_panel.ground_truth_cutoff_label,'String','Ground Truth Cutoff:');
set(obj.top_panel.ground_truth_cutoff_label,'TooltipString', tooltip);
%----gt cutoff box
obj.top_panel.ground_truth_cutoff_TE = uicontrol('Parent',obj.top_panel.handle);
set(obj.top_panel.ground_truth_cutoff_TE,'Style','edit');
set(obj.top_panel.ground_truth_cutoff_TE,'String', '0');
set(obj.top_panel.ground_truth_cutoff_TE,'TooltipString', tooltip);
%%
%---------------------------------------------------------------------------------------------
% set up top panel table
cols = 2;
rows = 8;  % Just keep this larger or equal to actual number of rows.

% set up top panel table
default_dimensions = NaN*zeros(rows,cols);
obj.top_panel.table.ui=obj.top_panel.handle;
obj.top_panel.table.width_margin = default_dimensions;
obj.top_panel.table.height_margin = default_dimensions;
obj.top_panel.table.false_width = default_dimensions;
obj.top_panel.table.false_height = default_dimensions;
obj.top_panel.table.offset = [0 0];

obj.top_panel.table.width = ones(rows, cols) * inf;
obj.top_panel.table.height = ones(rows, cols) * inf;
obj.top_panel.table.width_margin = ones(rows, cols) * 1.5;
obj.top_panel.table.height_margin = ones(rows, cols) * 1.5;

row = 0;

%% Insert Range
row = row + 1;
obj.top_panel.table.handles{row,1}   = obj.top_panel.insert_range_label;
obj.top_panel.table.handles{row,2}   = obj.top_panel.insert_range_TE;
%% Horizontal Bound
row = row + 1;
obj.top_panel.table.handles{row,1}   = obj.top_panel.hori_bound_label;
obj.top_panel.table.handles{row,2}   = obj.top_panel.hori_bound_PM;
%% Vertical Bound
row = row + 1;
obj.top_panel.table.handles{row,1}   = obj.top_panel.vert_bound_label;
obj.top_panel.table.handles{row,2}   = obj.top_panel.vert_bound_PM;
%% Top Layer
row = row + 1;
obj.top_panel.table.handles{row,1}   = obj.top_panel.top_layer_label;
obj.top_panel.table.handles{row,2}   = obj.top_panel.top_layer_TE;
%% Bottom Layer
row = row + 1;
obj.top_panel.table.handles{row,1}   = obj.top_panel.bottom_layer_label;
obj.top_panel.table.handles{row,2}   = obj.top_panel.bottom_layer_TE;
%% Layer Guard
row = row + 1;
obj.top_panel.table.handles{row,1}   = obj.top_panel.layer_guard_label;
obj.top_panel.table.handles{row,2}   = obj.top_panel.layer_guard_TE;
%% Along-track Weight
row = row + 1;
obj.top_panel.table.handles{row,1}  = obj.top_panel.along_track_weight_label;
obj.top_panel.table.handles{row,2}  = obj.top_panel.along_track_weight_TE;
%% gt cutoff
row = row + 1;
obj.top_panel.table.handles{row,1}  = obj.top_panel.ground_truth_cutoff_label;
obj.top_panel.table.handles{row,2}  = obj.top_panel.ground_truth_cutoff_TE;

if row > rows
  warning('Viterbi create_ui does not have default values for new rows. Update rows variable to match number of rows present.');
end

clear row cols

% Draw table
table_draw(obj.top_panel.table);
