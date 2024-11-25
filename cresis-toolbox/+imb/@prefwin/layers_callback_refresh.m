function layers_callback_refresh(obj)

% Get the system that is currently selected
system_name = get(obj.h_gui.systemsLB,'String');
if isempty(system_name)
  system_name = [];
else
  system_name = system_name{get(obj.h_gui.systemsLB,'Value')};
end

if ~isempty(system_name)
  %% layerdata systems
  if strcmpi(system_name,'tracks')
    layer_sources = get(obj.h_gui.layerSourcePM,'String');
    layer_source = layer_sources{get(obj.h_gui.layerSourcePM,'Value')};
    if strcmp(layer_source,'OPS')
      map_value = get(obj.h_gui.mapsPM,'Value');
      map_list = get(obj.h_gui.mapsPM,'String');
      map = map_list(map_value);
      
      [map_zone,map_name] = strtok(map,':');
      map_name = map_name(2:end);
      
      zone_mask = strcmp(map_zone,obj.locations);
      systems_mask = strcmp(system_name,obj.systems);
      
      season_list = obj.seasons(zone_mask & systems_mask);
      for idx=1:length(season_list)
        season_list{idx} = strtok(season_list{idx},'_');
      end
      season_list = unique(season_list);
      
      % Get layers from all systems
      menuString = {};
      for idx = 1:length(season_list)
        system_name = season_list{idx};
        % Find all the layers associated with this system
        [status,data] = opsGetLayers(system_name);
        obj.ops.layers = data.properties;
        for idx = 1:length(data.properties.lyr_name)
          menuString{idx} = sprintf('%s:%s', data.properties.lyr_group_name{idx}, data.properties.lyr_name{idx});
        end
      end
      
      % Create the new list of layers for the system that is selected
      obj.h_gui.h_layers.set_list(sort(menuString));
      obj.h_gui.h_layers.set_selected({'standard:surface','standard:bottom'},true);
      
      set(obj.h_gui.h_layers.h_list_availableCM.Children([2 3 4]),'Enable','off');
    end
    
  else
    %% OPS system
    % Find all the layers associated with this system
    [status,data] = opsGetLayers(system_name);
    obj.ops.layers = data.properties;
    menuString = {};
    for idx = 1:length(data.properties.lyr_name)
      menuString{idx} = sprintf('%s:%s', data.properties.lyr_group_name{idx}, data.properties.lyr_name{idx});
    end
    
    % Create the new list of layers for the system that is selected
    obj.h_gui.h_layers.set_list(sort(menuString));
    obj.h_gui.h_layers.set_selected({'standard:surface','standard:bottom'},true);
    
    set(obj.h_gui.h_layers.h_list_availableCM.Children([2 3 4]),'Enable','on');
  end
end
