function [status_str] = status_text_cursor(obj)
% [status_str] = echowin.status_text_cursor(obj)
%
% Builds a string containing information about the current cursor position 
% to be printed to the echogram window's status text bar. 

[~,rline] = min(abs(obj.cursor.gps_time-obj.eg.image_gps_time));
lat = obj.eg.image_lat(rline);
lon = obj.eg.image_lon(rline);

[~,map_rline] = min(abs(obj.cursor.gps_time-obj.eg.map_gps_time));
x = obj.eg.map_x(map_rline);
y = obj.eg.map_y(map_rline);

date_str = [datestr(epoch_to_datenum(obj.cursor.gps_time),'yyyy-mm-dd HH:MM:SS') sprintf('.%02.0f',mod(obj.cursor.gps_time,1)*100)];

% Current layers
cur_layers = find(obj.eg.layers.selected_layers).';

if isempty(cur_layers)
  status_str = sprintf('%.6f N, %.6f E, X:%.3f km, Y:%.3f km, %s',...
    lat,lon,x,y,date_str);
else
  physical_constants;
  elev = obj.eg.image_elev(rline);
  [~,unique_idxs] = unique(obj.eg.layers.x);
  warning off;
  surf_y = interp1(obj.eg.layers.x(unique_idxs), ...
    obj.eg.layers.y{1}(unique_idxs),obj.cursor.gps_time);
  [~,unique_idxs] = unique(obj.eg.layers.x);
  try
    layer_y = interp1(obj.eg.layers.x(unique_idxs), ...
      obj.eg.layers.y{cur_layers(1)}(unique_idxs),obj.cursor.gps_time);
    if ~all(isfinite(layer_y))
      error('');
    end
    depth = (layer_y-surf_y)*c/2/sqrt(er_ice);
    status_str = sprintf('%.6f N, %.6f E, X:%.3f km, Y:%.3f km, %s, %.2f Elevation, %.2f Depth',...
      lat,lon,x,y,date_str,elev - surf_y*c/2 - depth, depth);
  catch
    % There may be insufficient layer data to interpolate, so just print
    % out all the non-layer information
    status_str = sprintf('%.6f N, %.6f E, X:%.3f km, Y:%.3f km, %s',...
      lat,lon,x,y,date_str);
  end
  warning on;
end
