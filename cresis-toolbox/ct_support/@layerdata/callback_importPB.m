function callback_importPB(obj,status,event)

%% Get import directory
% =========================================================================
folder_name = uigetdir(ct_filename_out(obj.param,obj.layerdata_source,[],1),'Choose layer data folder');
if isnumeric(folder_name)
  % User canceled in uigetdir
  return;
end

%% Load layers
% =========================================================================
obj.gui_layers{end+1} = layerdata(obj.param,folder_name);
obj.gui_layers{end}.check_layer_organizer();
obj.gui_layers{end}.check_all_frames();

%% Set auto-merge settings 
% =========================================================================


%% Update user interface
% =========================================================================
obj.update_ui();