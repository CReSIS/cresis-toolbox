function create_ui(obj)
% layerdata.create_ui(obj)
%
% Function for creating the graphical user interface

if ~isempty(obj.h_fig)
  % GUI already created, so just bring to the foreground and return
  set(obj.h_fig,'Visible','on');
  set(obj.h_fig_twtt,'Visible','on');
  figure(obj.h_fig_twtt);
  figure(obj.h_fig);
  return;
end

%% Layer Figures
% =========================================================================
obj.h_fig = figure;
set(obj.h_fig,'Units','Points','Position',[35.2500  300.7500  420.0000  315.0000]);
set(obj.h_fig,'DockControls','off')
set(obj.h_fig,'NumberTitle','off');
if strcmpi(class(obj.h_fig),'double')
  set(obj.h_fig,'Name',sprintf('%d: layerdata %s',obj.h_fig, obj.param.day_seg));
else
  set(obj.h_fig,'Name',sprintf('%d: layerdata %s',obj.h_fig.Number, obj.param.day_seg));
end
set(obj.h_fig,'ToolBar','none');
set(obj.h_fig,'MenuBar','none');
set(obj.h_fig,'CloseRequestFcn',@obj.callback_closePB);

obj.h_fig_twtt = figure;
obj.h_axes_twtt = axes('parent',obj.h_fig_twtt);
set(obj.h_fig_twtt,'DockControls','off')
set(obj.h_fig_twtt,'NumberTitle','off');
if strcmpi(class(obj.h_fig_twtt),'double')
  set(obj.h_fig_twtt,'Name',sprintf('%d: twtt layerdata %s',obj.h_fig_twtt, obj.param.day_seg));
else
  set(obj.h_fig_twtt,'Name',sprintf('%d: twtt layerdata %s',obj.h_fig_twtt.Number, obj.param.day_seg));
end
set(obj.h_fig_twtt,'ToolBar','none');
set(obj.h_fig_twtt,'MenuBar','none');
set(obj.h_fig_twtt,'CloseRequestFcn',@obj.callback_closePB);

obj.h_fig_metadata = figure;
set(obj.h_fig_metadata,'Units','Points','Position',[35.2500  638.2500  420.0000  201.0000]);
set(obj.h_fig_metadata,'DockControls','off')
set(obj.h_fig_metadata,'NumberTitle','off');
if strcmpi(class(obj.h_fig_metadata),'double')
  set(obj.h_fig_metadata,'Name',sprintf('%d: metadata layerdata %s',obj.h_fig_metadata, obj.param.day_seg));
else
  set(obj.h_fig_metadata,'Name',sprintf('%d: metadata layerdata %s',obj.h_fig_metadata.Number, obj.param.day_seg));
end
set(obj.h_fig_metadata,'ToolBar','none');
set(obj.h_fig_metadata,'MenuBar','none');
set(obj.h_fig_metadata,'CloseRequestFcn',@obj.callback_closePB);

%% Main Figure: Create the widgets
% =========================================================================

% Layer selection class (populate later from preference file)
obj.h_gui.h_layers = selectionbox(obj.h_fig,'Layers',[],1);
set(obj.h_gui.h_layers.h_list_available,'TooltipString','Layers to delete (double or right click to keep).');
set(obj.h_gui.h_layers.h_list_selected,'TooltipString','Layers to keep (double or right click to delete).');
obj.h_gui.h_layers.set_enable(true);

uimenu(obj.h_gui.h_layers.h_list_availableCM, 'Label', 'Merge: diff frames', 'Callback', @obj.callback_layers_SB);
uimenu(obj.h_gui.h_layers.h_list_availableCM, 'Label', 'Merge: overwrite', 'Callback', @obj.callback_layers_SB);
uimenu(obj.h_gui.h_layers.h_list_availableCM, 'Label', 'Merge: NaN', 'Callback', @obj.callback_layers_SB);
uimenu(obj.h_gui.h_layers.h_list_availableCM, 'Label', '-', 'Callback', @obj.callback_layers_SB);
uimenu(obj.h_gui.h_layers.h_list_availableCM, 'Label', 'Order by twtt', 'Callback', @obj.callback_layers_SB);
uimenu(obj.h_gui.h_layers.h_list_availableCM, 'Label', 'Sequence layer names', 'Callback', @obj.callback_layers_SB);
uimenu(obj.h_gui.h_layers.h_list_availableCM, 'Label', 'Set name based on twtt matches', 'Callback', @obj.callback_layers_SB);
uimenu(obj.h_gui.h_layers.h_list_availableCM, 'Label', 'Undo name changes', 'Callback', @obj.callback_layers_SB);

% Plot Deleted Button
obj.h_gui.plot_deletedCB = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.plot_deletedCB,'Style','CheckBox');
set(obj.h_gui.plot_deletedCB,'Value',1);
set(obj.h_gui.plot_deletedCB,'String','Plot Delete Layers');
set(obj.h_gui.plot_deletedCB,'Callback',@obj.callback_plotCB);
set(obj.h_gui.plot_deletedCB,'TooltipString','Check to plot layers in the to be deleted listbox. Layers are plotted as solid blue lines.');

% Plot Keep Button
obj.h_gui.plot_keepCB = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.plot_keepCB,'Style','CheckBox');
set(obj.h_gui.plot_keepCB,'Value',1);
set(obj.h_gui.plot_keepCB,'String','Plot Keep Layers');
set(obj.h_gui.plot_keepCB,'Callback',@obj.callback_plotCB);
set(obj.h_gui.plot_keepCB,'TooltipString','Check to plot layers in the keep listbox. Layers are plotted as dashed red lines.');

% Import Button
obj.h_gui.importPB = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.importPB,'Style','PushButton');
set(obj.h_gui.importPB,'String','Import');
set(obj.h_gui.importPB,'Callback',@obj.callback_importPB);
set(obj.h_gui.importPB,'TooltipString','Check to plot layers in the to be deleted listbox.');

% Merge Preset Button
obj.h_gui.merge_presetPB = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.merge_presetPB,'Style','PushButton');
set(obj.h_gui.merge_presetPB,'String','Merge Preset');
set(obj.h_gui.merge_presetPB,'Callback',@obj.callback_presetPB);
set(obj.h_gui.merge_presetPB,'TooltipString','Check to plot layers in the to be deleted listbox.');

% Save Button
obj.h_gui.savePB = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.savePB,'Style','PushButton');
set(obj.h_gui.savePB,'String','Save and Close');
set(obj.h_gui.savePB,'Callback',@obj.callback_savePB);
set(obj.h_gui.savePB,'TooltipString','Save and close.');

% Close Button
obj.h_gui.closePB = uicontrol('Parent',obj.h_fig);
set(obj.h_gui.closePB,'Style','PushButton');
set(obj.h_gui.closePB,'String','Close without Saving');
set(obj.h_gui.closePB,'Callback',@obj.callback_closePB);
set(obj.h_gui.closePB,'TooltipString','Close without saving.');

%% Main Figure: Create the table
% =========================================================================
obj.h_gui.table.ui=obj.h_fig;
obj.h_gui.table.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
obj.h_gui.table.height_margin = NaN*zeros(30,30);
obj.h_gui.table.false_width = NaN*zeros(30,30);
obj.h_gui.table.false_height = NaN*zeros(30,30);
obj.h_gui.table.offset = [0 0];

row = 1; col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.h_layers.h_text;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui.table.handles{row,col}   = [];
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 20;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.h_layers.h_list_available;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = inf;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.h_layers.h_list_selected;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = inf;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.plot_deletedCB;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 25;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.plot_keepCB;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 25;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.importPB;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 25;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.merge_presetPB;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 25;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui.table.handles{row,col}   = obj.h_gui.savePB;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 25;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui.table.handles{row,col}   = obj.h_gui.closePB;
obj.h_gui.table.width(row,col)     = inf;
obj.h_gui.table.height(row,col)    = 25;
obj.h_gui.table.width_margin(row,col) = 1;
obj.h_gui.table.height_margin(row,col) = 1;

clear row col
table_draw(obj.h_gui.table);


%% Metadata Figure: Create the widgets
% =========================================================================

% Layer age label
obj.h_gui_metadata.age_text = uicontrol('Parent',obj.h_fig_metadata);
set(obj.h_gui_metadata.age_text,'Style','Text');
set(obj.h_gui_metadata.age_text,'String','Layer age:');
tooltip_str = 'Layer age scalar. Age represents when the layer was formed on the ice surface in Julian years.';
set(obj.h_gui_metadata.age_text,'TooltipString',tooltip_str);

% Layer age edit
obj.h_gui_metadata.age_edit = uicontrol('Parent',obj.h_fig_metadata);
set(obj.h_gui_metadata.age_edit,'Style','Edit');
set(obj.h_gui_metadata.age_edit,'String','');
set(obj.h_gui_metadata.age_edit,'TooltipString',tooltip_str);

% Layer age source label
obj.h_gui_metadata.age_source_text = uicontrol('Parent',obj.h_fig_metadata);
set(obj.h_gui_metadata.age_source_text,'Style','Text');
set(obj.h_gui_metadata.age_source_text,'String','Layer age source:');
tooltip_str = 'Layer age scalar. Age represents when the layer was formed on the ice surface in Julian years.';
set(obj.h_gui_metadata.age_source_text,'TooltipString',tooltip_str);

% Layer age source edit
obj.h_gui_metadata.age_source_edit = uicontrol('Parent',obj.h_fig_metadata);
set(obj.h_gui_metadata.age_source_edit,'Style','Edit');
set(obj.h_gui_metadata.age_source_edit,'String','');
set(obj.h_gui_metadata.age_source_edit,'TooltipString',tooltip_str);

% Layer age source age label
obj.h_gui_metadata.age_source_age_text = uicontrol('Parent',obj.h_fig_metadata);
set(obj.h_gui_metadata.age_source_age_text,'Style','Text');
set(obj.h_gui_metadata.age_source_age_text,'String','Layer age source age:');
tooltip_str = 'Layer age scalar. Age represents when the layer was formed on the ice surface in Julian years.';
set(obj.h_gui_metadata.age_source_age_text,'TooltipString',tooltip_str);

% Layer age source age edit
obj.h_gui_metadata.age_source_age_edit = uicontrol('Parent',obj.h_fig_metadata);
set(obj.h_gui_metadata.age_source_age_edit,'Style','Edit');
set(obj.h_gui_metadata.age_source_age_edit,'String','');
set(obj.h_gui_metadata.age_source_age_edit,'TooltipString',tooltip_str);

% Layer age source type label
obj.h_gui_metadata.age_source_type_text = uicontrol('Parent',obj.h_fig_metadata);
set(obj.h_gui_metadata.age_source_type_text,'Style','Text');
set(obj.h_gui_metadata.age_source_type_text,'String','Layer age source type:');
tooltip_str = 'Layer age scalar. Age represents when the layer was formed on the ice surface in Julian years.';
set(obj.h_gui_metadata.age_source_type_text,'TooltipString',tooltip_str);

% Layer age source type edit
obj.h_gui_metadata.age_source_type_edit = uicontrol('Parent',obj.h_fig_metadata);
set(obj.h_gui_metadata.age_source_type_edit,'Style','Edit');
set(obj.h_gui_metadata.age_source_type_edit,'String','');
set(obj.h_gui_metadata.age_source_type_edit,'TooltipString',tooltip_str);

% Layer description label
obj.h_gui_metadata.description_text = uicontrol('Parent',obj.h_fig_metadata);
set(obj.h_gui_metadata.description_text,'Style','Text');
set(obj.h_gui_metadata.description_text,'String','Layer description:');
tooltip_str = 'String containing the layer description.';
set(obj.h_gui_metadata.description_text,'TooltipString',tooltip_str);

% Layer description edit
obj.h_gui_metadata.description_edit = uicontrol('Parent',obj.h_fig_metadata);
set(obj.h_gui_metadata.description_edit,'Style','Edit');
set(obj.h_gui_metadata.description_edit,'String','');
set(obj.h_gui_metadata.description_edit,'TooltipString',tooltip_str);

% Layer group name label
obj.h_gui_metadata.group_name_text = uicontrol('Parent',obj.h_fig_metadata);
set(obj.h_gui_metadata.group_name_text,'Style','Text');
set(obj.h_gui_metadata.group_name_text,'String','Layer group name:');
tooltip_str = 'String containing the group name.';
set(obj.h_gui_metadata.group_name_text,'TooltipString',tooltip_str);

% Layer group name edit
obj.h_gui_metadata.group_name_edit = uicontrol('Parent',obj.h_fig_metadata);
set(obj.h_gui_metadata.group_name_edit,'Style','Edit');
set(obj.h_gui_metadata.group_name_edit,'String','');
set(obj.h_gui_metadata.group_name_edit,'TooltipString',tooltip_str);

% Layer name label
obj.h_gui_metadata.name_text = uicontrol('Parent',obj.h_fig_metadata);
set(obj.h_gui_metadata.name_text,'Style','Text');
set(obj.h_gui_metadata.name_text,'String','Layer name:');
tooltip_str = 'String containing the layer name. Layer names must be unique.';
set(obj.h_gui_metadata.name_text,'TooltipString',tooltip_str);

% Layer name edit
obj.h_gui_metadata.name_edit = uicontrol('Parent',obj.h_fig_metadata);
set(obj.h_gui_metadata.name_edit,'Style','Edit');
set(obj.h_gui_metadata.name_edit,'String','');
set(obj.h_gui_metadata.name_edit,'TooltipString',tooltip_str);

% Save Metadata Button
obj.h_gui_metadata.save_metadataPB = uicontrol('Parent',obj.h_fig_metadata);
set(obj.h_gui_metadata.save_metadataPB,'Style','PushButton');
set(obj.h_gui_metadata.save_metadataPB,'String','Save Metadata');
set(obj.h_gui_metadata.save_metadataPB,'Callback',@obj.callback_save_metadataPB);
set(obj.h_gui_metadata.save_metadataPB,'TooltipString','Press "Save Metadata" to update the metadata for the selected layer.');

%% Metadata Figure: Create the table
% =========================================================================
obj.h_gui_metadata.table.ui=obj.h_fig_metadata;
obj.h_gui_metadata.table.width_margin = NaN*zeros(30,30); % Just make these bigger than they have to be
obj.h_gui_metadata.table.height_margin = NaN*zeros(30,30);
obj.h_gui_metadata.table.false_width = NaN*zeros(30,30);
obj.h_gui_metadata.table.false_height = NaN*zeros(30,30);
obj.h_gui_metadata.table.offset = [0 0];

row = 1; col = 1;
obj.h_gui_metadata.table.handles{row,col}   = obj.h_gui_metadata.age_text;
obj.h_gui_metadata.table.width(row,col)     = inf;
obj.h_gui_metadata.table.height(row,col)    = 25;
obj.h_gui_metadata.table.width_margin(row,col) = 1;
obj.h_gui_metadata.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui_metadata.table.handles{row,col}   = obj.h_gui_metadata.age_edit;
obj.h_gui_metadata.table.width(row,col)     = inf;
obj.h_gui_metadata.table.height(row,col)    = 25;
obj.h_gui_metadata.table.width_margin(row,col) = 1;
obj.h_gui_metadata.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui_metadata.table.handles{row,col}   = obj.h_gui_metadata.age_source_text;
obj.h_gui_metadata.table.width(row,col)     = inf;
obj.h_gui_metadata.table.height(row,col)    = 25;
obj.h_gui_metadata.table.width_margin(row,col) = 1;
obj.h_gui_metadata.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui_metadata.table.handles{row,col}   = obj.h_gui_metadata.age_source_edit;
obj.h_gui_metadata.table.width(row,col)     = inf;
obj.h_gui_metadata.table.height(row,col)    = 25;
obj.h_gui_metadata.table.width_margin(row,col) = 1;
obj.h_gui_metadata.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui_metadata.table.handles{row,col}   = obj.h_gui_metadata.age_source_age_text;
obj.h_gui_metadata.table.width(row,col)     = inf;
obj.h_gui_metadata.table.height(row,col)    = 25;
obj.h_gui_metadata.table.width_margin(row,col) = 1;
obj.h_gui_metadata.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui_metadata.table.handles{row,col}   = obj.h_gui_metadata.age_source_age_edit;
obj.h_gui_metadata.table.width(row,col)     = inf;
obj.h_gui_metadata.table.height(row,col)    = 25;
obj.h_gui_metadata.table.width_margin(row,col) = 1;
obj.h_gui_metadata.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui_metadata.table.handles{row,col}   = obj.h_gui_metadata.age_source_type_text;
obj.h_gui_metadata.table.width(row,col)     = inf;
obj.h_gui_metadata.table.height(row,col)    = 25;
obj.h_gui_metadata.table.width_margin(row,col) = 1;
obj.h_gui_metadata.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui_metadata.table.handles{row,col}   = obj.h_gui_metadata.age_source_type_edit;
obj.h_gui_metadata.table.width(row,col)     = inf;
obj.h_gui_metadata.table.height(row,col)    = 25;
obj.h_gui_metadata.table.width_margin(row,col) = 1;
obj.h_gui_metadata.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui_metadata.table.handles{row,col}   = obj.h_gui_metadata.description_text;
obj.h_gui_metadata.table.width(row,col)     = inf;
obj.h_gui_metadata.table.height(row,col)    = 25;
obj.h_gui_metadata.table.width_margin(row,col) = 1;
obj.h_gui_metadata.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui_metadata.table.handles{row,col}   = obj.h_gui_metadata.description_edit;
obj.h_gui_metadata.table.width(row,col)     = inf;
obj.h_gui_metadata.table.height(row,col)    = 25;
obj.h_gui_metadata.table.width_margin(row,col) = 1;
obj.h_gui_metadata.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui_metadata.table.handles{row,col}   = obj.h_gui_metadata.group_name_text;
obj.h_gui_metadata.table.width(row,col)     = inf;
obj.h_gui_metadata.table.height(row,col)    = 25;
obj.h_gui_metadata.table.width_margin(row,col) = 1;
obj.h_gui_metadata.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui_metadata.table.handles{row,col}   = obj.h_gui_metadata.group_name_edit;
obj.h_gui_metadata.table.width(row,col)     = inf;
obj.h_gui_metadata.table.height(row,col)    = 25;
obj.h_gui_metadata.table.width_margin(row,col) = 1;
obj.h_gui_metadata.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui_metadata.table.handles{row,col}   = obj.h_gui_metadata.name_text;
obj.h_gui_metadata.table.width(row,col)     = inf;
obj.h_gui_metadata.table.height(row,col)    = 25;
obj.h_gui_metadata.table.width_margin(row,col) = 1;
obj.h_gui_metadata.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui_metadata.table.handles{row,col}   = obj.h_gui_metadata.name_edit;
obj.h_gui_metadata.table.width(row,col)     = inf;
obj.h_gui_metadata.table.height(row,col)    = 25;
obj.h_gui_metadata.table.width_margin(row,col) = 1;
obj.h_gui_metadata.table.height_margin(row,col) = 1;

row = row + 1; col = 1;
obj.h_gui_metadata.table.handles{row,col}   = [];
obj.h_gui_metadata.table.width(row,col)     = inf;
obj.h_gui_metadata.table.height(row,col)    = 25;
obj.h_gui_metadata.table.width_margin(row,col) = 1;
obj.h_gui_metadata.table.height_margin(row,col) = 1;

col = 2;
obj.h_gui_metadata.table.handles{row,col}   = obj.h_gui_metadata.save_metadataPB;
obj.h_gui_metadata.table.width(row,col)     = inf;
obj.h_gui_metadata.table.height(row,col)    = 25;
obj.h_gui_metadata.table.width_margin(row,col) = 1;
obj.h_gui_metadata.table.height_margin(row,col) = 1;

clear row col
table_draw(obj.h_gui_metadata.table);

%% Load layers
% =========================================================================
obj.gui_layers{end+1} = obj;
obj.gui_layers{end}.check_layer_organizer();
obj.gui_layers{end}.check_all_frames();

%% Set auto-merge settings 
% =========================================================================


%% Update user interface
% =========================================================================
obj.update_ui();
