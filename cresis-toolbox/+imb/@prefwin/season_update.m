function season_update(obj,status,event)
% imb.prefwin.season_update(obj,status,event)
%
% Update obj.h_gui.systemsLB
% Update obj.h_gui.h_seasons
% Update obj.h_gui.h_layers
%
% Author: John Paden

%% Setup

% Determine what kind of flightline is selected (OPS or tracks files)
flightlines_value = get(obj.h_gui.flightlinesPM,'Value');
flightlines_list = get(obj.h_gui.flightlinesPM,'String');
flightlines = flightlines_list(flightlines_value);

% Determine which system is selected (relevant only for OPS since tracks
% files group all systems together)
systems_value = get(obj.h_gui.systemsLB,'Value');
systems = get(obj.h_gui.systemsLB,'String');
if ~isempty(systems)
  system_name = systems{systems_value};
else
  system_name = [];
end

%% Update obj.h_gui.systemsLB 
if strcmp(flightlines{1}(1:3),'OPS')
  % OPS based flight tracks
  unique_systems = setdiff(unique(obj.systems),{'tracks'});
  set(obj.h_gui.systemsLB,'String',unique_systems);
  system_value = find(strcmp(system_name,unique_systems),1);
  if isempty(system_value)
    system_value = 1;
  end
  if isempty(unique_systems)
    set(obj.h_gui.systemsLB,'Value',1);
    system_name = [];
  else
    set(obj.h_gui.systemsLB,'Value',system_value);
    system_name = unique_systems{system_value};
  end
  set(obj.h_gui.systemsText,'String','Radar Systems');
  set(obj.h_gui.systemsLB,'Enable','on');
else
  % tracks files based flight tracks
  system_name = 'tracks';
  set(obj.h_gui.systemsText,'String','-');
  set(obj.h_gui.systemsLB,'String',{'tracks'});
  set(obj.h_gui.systemsLB,'Value',1);
  set(obj.h_gui.systemsLB,'Enable','off');
end

%% Update obj.h_gui.h_seasons
% only list seasons that correspond to the map location selected (arctic or
% antarctic)
map_value = get(obj.h_gui.mapsPM,'Value');
map_list = get(obj.h_gui.mapsPM,'String');
map = map_list(map_value);

[map_zone,~] = strtok(map,':');

zone_mask = strcmp(map_zone,obj.locations);
systems_mask = strcmp(system_name,obj.systems);

obj.h_gui.h_seasons.set_list(sort(obj.seasons(zone_mask & systems_mask)));

%% Update obj.h_gui.h_layers
layer_sources = get(obj.h_gui.layerSourcePM,'String');
layer_source = layer_sources{get(obj.h_gui.layerSourcePM,'Value')};
if strcmp(layer_source,'layerdata')
  obj.h_gui.h_layers.set_enable(false);
else
  obj.h_gui.h_layers.set_enable(true);
end
obj.layers_callback_refresh();
