function update_ui(obj)
% layerdata.update_ui(obj)
%
% Function for updating the graphical user interface

%% Populate layers listbox
% =========================================================================

lyr_name = {};
lyr_id = [];
lyr_order = [];
lyr_idx = [];

for gui_layers_idx = 1:length(obj.gui_layers)
  
  import_name = '';
  fn_dir = ct_filename_out(obj.param, obj.gui_layers{gui_layers_idx}.layerdata_source,[],1);
  [fn_dir,fn_name] = fileparts(fn_dir);
  while strncmp(fn_name,'CSARP_',6)
    if isempty(import_name)
      import_name = fn_name(7:end);
    else
      import_name = [import_name '/' fn_name(7:end)];
    end
    [fn_dir,fn_name] = fileparts(fn_dir);
  end
  
  if isempty(import_name)
    import_name = sprintf('/%d',length(obj.gui_layers)+1);
  end
  
  for lyr_name_idx = 1:length(obj.gui_layers{gui_layers_idx}.layer_organizer.lyr_name)
    lyr_name{end+1} = [import_name '/' obj.gui_layers{gui_layers_idx}.layer_organizer.lyr_name{lyr_name_idx}];
    % Add the automated layer match information
    % Add the merge information
  end
  if gui_layers_idx == 1
    lyr_id(end+(1:length(obj.gui_layers{gui_layers_idx}.layer_organizer.lyr_id))) = obj.gui_layers{gui_layers_idx}.layer_organizer.lyr_id;
    lyr_order(end+(1:length(obj.gui_layers{gui_layers_idx}.layer_organizer.lyr_order))) = obj.gui_layers{gui_layers_idx}.layer_organizer.lyr_order;
  else
    lyr_id(end+(1:length(obj.gui_layers{gui_layers_idx}.layer_organizer.lyr_id))) = max(lyr_id)+1 + obj.gui_layers{gui_layers_idx}.layer_organizer.lyr_id;
    lyr_order(end+(1:length(obj.gui_layers{gui_layers_idx}.layer_organizer.lyr_order))) = max(lyr_order)+1 + obj.gui_layers{gui_layers_idx}.layer_organizer.lyr_order;
  end
  lyr_idx(end+(1:length(obj.gui_layers{gui_layers_idx}.layer_organizer.lyr_id))) = gui_layers_idx * ones(size(obj.gui_layers{gui_layers_idx}.layer_organizer.lyr_id));
end

obj.h_gui.h_layers.set_list(lyr_name, lyr_id, lyr_order);

%% Plot layers
% =========================================================================

%% Update metadata window
% =========================================================================

%% Notes
% Example listbox contents
% =========================================================================
% layer/surface
% post/layer/surface merge into surface NaN
% post/layer/bottom
% /2/lay_001
% /2/bottom merge diff frames into bottom
% /3/lay_001 rename lay_002
% /3/bottom merge diff frames into bottom 

% Context Menu Commands: (check in menu depends on first selected entry)
% =========================================================================
% THIS can be set by param.layerdata_merge.automerge_merge_mode
% Auto-merge diff frames
% Merge diff frames into... (opens dialog to determine which base layer to merge into)
% Auto-merge NaN
% Merge NaN into... (opens dialog to determine which layers to merge into)
% Overwrite

% THIS can be set by param.layerdata_merge.automerge_match_mode
% Set auto-merge based on twtt and name (may cause metadata rename)
% Set auto-merge based only on name

% Sequence layer names (may cause metadata renames)

% Merge Preset: just reruns import without adding any new layerdata
% sources, update_gui called with no arguments
% create_gui: update_gui called with no arguments
% import: import directory dialog and then call update_gui

% On Save:
% =========================================================================
% 1. Run through the listbox for each item (while idx < end)
% 2. For each item search ahead for other layers that match and apply each
% merge command and then mark the mask for each item that is applied
% 3. idx increased until the next entry that has not been handled yet.
