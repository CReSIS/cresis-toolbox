function okPB_callback(obj,hObj,event)

%% Update default parameters
cur_unit = get(obj.h_fig,'Units');
set(obj.h_fig,'Units','pixels')
prefwin_pos = get(obj.h_fig,'Position');
set(obj.h_fig,'Unit',cur_unit);
obj.default_params.x = prefwin_pos(1);
obj.default_params.y = prefwin_pos(2);
obj.default_params.w = prefwin_pos(3);
obj.default_params.h = prefwin_pos(4);
obj.default_params.sources = get(obj.h_gui.sourceLB,'String');
map_names = get(obj.h_gui.mapsPM,'String');
flightlines = get(obj.h_gui.flightlinesPM,'String');
obj.default_params.map_name = map_names{get(obj.h_gui.mapsPM,'Value')};
obj.default_params.flightlines = flightlines{get(obj.h_gui.flightlinesPM,'Value')};
systems = get(obj.h_gui.systemsLB,'String');
obj.default_params.system = systems{get(obj.h_gui.systemsLB,'Value')};
%
layer_source = get(obj.h_gui.layerSourcePM,'String');
obj.default_params.layer_source = layer_source{get(obj.h_gui.layerSourcePM,'Value')};
layer_data_source = get(obj.h_gui.layerDataSourcePM,'String');
if isempty(layer_data_source)
  obj.default_params.layer_data_source = 'layer';
else
  obj.default_params.layer_data_source = layer_data_source{get(obj.h_gui.layerDataSourcePM,'Value')};
end
%
obj.default_params.season_names = obj.h_gui.h_seasons.get_selected_strings();
obj.default_params.layer_names = obj.h_gui.h_layers.get_selected_strings();

%% Check if anything has been selected
selected_seasons = obj.h_gui.h_seasons.get_selected_strings().';
if isempty(selected_seasons)
  % if not, don't plot a map
  uiwait(msgbox('No seasons are selected.','Error updating preferences','modal'));
  return;
end

%% Filter available maps based on selected system and season
systems = get(obj.h_gui.systemsLB,'string');
system_name = systems{get(obj.h_gui.systemsLB,'value')};
selected_idxs = zeros(size(selected_seasons));
for idx = 1:length(selected_seasons)
  % For each season selected, find its index in obj.seasons
  found = false;
  for search_idx = 1:length(obj.seasons)
    if strcmp(obj.seasons{search_idx},selected_seasons{idx}) ...
        && strcmp(obj.systems{search_idx},system_name)
      selected_idxs(idx) = search_idx;
      found = true;
      break;
    end
  end
  if ~found
    warning('This should never happen, selection was not found in the list');
    keyboard
  end
end

%% Filter layers
selected_layer_names = obj.h_gui.h_layers.get_selected_strings().';
selected_layers.lyr_name = {};
selected_layers.lyr_group_name = {};
selected_layers.lyr_id = [];
for idx = 1:length(obj.ops.layers.lyr_name)
  layer_name = sprintf('%s:%s', obj.ops.layers.lyr_group_name{idx}, obj.ops.layers.lyr_name{idx});
  match_idx = strmatch(layer_name,selected_layer_names,'exact');
  if ~isempty(match_idx)
    selected_layers.lyr_name{end+1} = obj.ops.layers.lyr_name{idx};
    selected_layers.lyr_group_name{end+1} = obj.ops.layers.lyr_group_name{idx};
    selected_layers.lyr_id(end+1) = obj.ops.layers.lyr_id(idx);
  end
end

%% Check map zone
map_names = get(obj.h_gui.mapsPM,'String');
map_name = map_names{get(obj.h_gui.mapsPM,'Value')};
% Parse map name from GUI into 'zone:map'
colon_idx = find(map_name==':',1);
if isempty(colon_idx)
  map_zone = '';
else
  map_zone = map_name(1:colon_idx-1);
  map_name = map_name(colon_idx+1:end);
  % This map is "arctic" or "antarctic" only, verify all seasons are from
  % the correct map zone.
  if any(~strcmp(map_zone,obj.locations(selected_idxs)))
    warning('This should never happen: The map selected (%s) does not support arctic and antarctic seasons. Select only seasons from %s.\n', map_name, map_zone);
    return
  end
end

%% Check flightlines
flightlines = get(obj.h_gui.flightlinesPM,'String');
flightlines = flightlines{get(obj.h_gui.flightlinesPM,'Value')};
if strcmp(map_name,'Blank Geodetic Map') && ~strcmp(flightlines,'tracks files Flightlines')
  % if so, don't plot a map
  uiwait(msgbox('Only "tracks files Flightlines" supports "Blank Geodetic Map". Change either the map setting or the flightline setting.','Error updating preferences','modal'));
  return;
end

%% Pass information to map window
% Give information on the season, location (arctic/antarctic) and system_name
% (rds accum etc.) to the map window

% Copy settings to obj.settings
layer_sources = get(obj.h_gui.layerSourcePM,'String');
obj.settings.layer_source = layer_sources{get(obj.h_gui.layerSourcePM,'Value')};

layer_data_sources = get(obj.h_gui.layerDataSourcePM,'String');
if isempty(layer_data_sources)
  obj.settings.layer_data_source = 'layer';
else
  obj.settings.layer_data_source = layer_data_sources{get(obj.h_gui.layerDataSourcePM,'Value')};
end

obj.settings.layers = selected_layers;
obj.settings.seasons = selected_seasons;
obj.settings.system = obj.systems(selected_idxs);
obj.settings.system = obj.settings.system{1};
obj.settings.sources = get(obj.h_gui.sourceLB,'String');
obj.settings.map_zone = map_zone;
obj.settings.map_name = map_name;

obj.settings.flightlines = flightlines;

% Broadcast notice that StateChange event has occurred (calls imb.mapwin.get_map)
notify(obj,'StateChange');
