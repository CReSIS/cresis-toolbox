function status = ops_connect(obj)

status = 0;

%% Get System Info from OPS Database
% =========================================================================
fprintf('  Querying database to get data list (%s)\n', datestr(now));
try
  [ops_status,data] = opsGetSystemInfo();
catch ME
  %uiwait(msgbox('No seasons are selected.','Error updating preferences','modal'));
  warning('opsGetSystemInfo failed. Continuing without database. Error message: %s', ME.getReport);
  status = 1;
  return;
end

%% Get Maps/Layers from OPS Geoserver
% =========================================================================
fprintf('  Querying WMS to get map list (%s)\n', datestr(now,'HH:MM:SS'));
opsCmd; % Populate gOPS variable
wms_maps = {};
obj.ops.wms = WebMapServer(sprintf('%swms/',gOps.geoServerUrl));
try
  obj.ops.wms_capabilities = obj.ops.wms.getCapabilities();
  % Create a list of all layers excluding "*line_paths*",
  % "*data_quality*","*data_coverage*", "*crossover_errors*","*data_elevation*"
  wms_layers = obj.ops.wms_capabilities.Layer;
  for idx = 1:length(wms_layers)
    if isempty(regexpi(wms_layers(idx).LayerName,'line_paths|crossover_errors|data_quality|data_coverage|data_elevation|google'))
      % Did not match the above strings, so it should be a map layer
      wms_maps{end+1} = wms_layers(idx).LayerName;
    end
  end
  clear wms_layers;
catch ME
  %uiwait(msgbox('No seasons are selected.','Error updating preferences','modal'));
  warning('wms.getCapabilities failed. Continuing without no layers or maps. Error message: %s', ME.getReport);
  status = 2;
  return;
end
% Add Blank and Google maps
wms_maps = [{'arctic:Blank Geodetic Map';'antarctic:Blank Geodetic  Map';'arctic:Blank Stereographic Map';'antarctic:Blank Stereographic Map';'arctic:Google Map';'antarctic:Google Map'}; wms_maps(:)];

flightlines = {'tracks files Flightlines','OPS Flightlines','OPS Quality Flightlines','OPS Coverage Flightlines', 'OPS Crossover Errors','OPS Bottom Elevation'};
set(obj.h_gui.flightlinesPM,'String',flightlines);

set(obj.h_gui.mapsPM,'String',wms_maps);

set(obj.h_gui.layerSourcePM,'String',{'layerdata','OPS'});

obj.ops.profile = data.opsProfile;
obj.systems = [obj.systems data.properties.systems];
obj.seasons = [obj.seasons data.properties.seasons];
obj.locations = [obj.locations data.properties.locations];

fprintf('  Done connecting to OPS (%s)\n', datestr(now));