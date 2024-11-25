function query_redraw_map(obj,x_min,x_max,y_min,y_max)
% mapwin.query_redraw_map(obj,x_min,x_max,y_min,y_max)
%
% mapwin class support function
% Called anytime the map window needs to get a new map from the map server.
% E.g. button_up and button_scroll zoom and search functions, key_press
%   pan function, search_callback.m, update_echowin_flightlines.m and
%   map_update_cursors_callback.m in the event that the map must be
%   adjusted to keep the flightline/cursor in view
%
% x_min, x_max, y_min, y_max: Scalars that specify the new map limits
%   (in km) to get

%% Scale the requested limits to meters
map_xlim = sort([x_min x_max]*obj.map.scale);
map_ylim = sort([y_min y_max]*obj.map.scale);

%% Force requested limits to maintain the aspect ratio of the figure
old_u = get(obj.map_panel.h_axes,'units');
set(obj.map_panel.h_axes,'Units','pixels')
PixelBounds = round(get(obj.map_panel.h_axes,'Position'));
set(obj.map_panel.h_axes,'Position',PixelBounds);
height = round((PixelBounds(4))*1 - 0);
width = round((PixelBounds(3))*1 - 0);
aspect_ratio = height/width;
set(obj.map_panel.h_axes,'units',old_u);

if obj.map.source ~= 3
  % Grow the limits so that the requested region is as big or bigger
  % than the requested limits
  if aspect_ratio*diff(map_xlim) > diff(map_ylim)
    growth = aspect_ratio*diff(map_xlim) - diff(map_ylim);
    map_ylim(1) = map_ylim(1) - growth/2;
    map_ylim(2) = map_ylim(2) + growth/2;
  else
    growth = diff(map_ylim)/aspect_ratio - diff(map_xlim);
    map_xlim(1) = map_xlim(1) - growth/2;
    map_xlim(2) = map_xlim(2) + growth/2;
  end
end

if obj.map.source == 0
  %% OPS map
  obj.ops.request.ImageFormat = 'image/jpeg';
  obj.ops.request.XLim = map_xlim;
  obj.ops.request.YLim = map_ylim;

  % Build the new WMS query, submit it and then retrieve the result
  obj.ops.request.ImageHeight =  height;
  obj.ops.request.ImageWidth  = width;
  if obj.map.fline_source == 0
    modrequest = strcat(obj.ops.request.RequestURL,'&viewparams=',obj.ops.seasons_modrequest,obj.ops.season_group_ids_modrequest);
  else
    modrequest = strcat(obj.ops.request.RequestURL);
  end
  A = obj.map_pref.ops.wms.getMap(modrequest);
  R = obj.ops.request.RasterRef;
  R = R/obj.map.scale;
  
  % Create axes
  x_data = R(3,1) + [0 size(A,2)*R(2,1)];
  y_data = R(3,2) + [0 size(A,1)*R(1,2)];
  
elseif obj.map.source == 1
  %% Google map
  obj.ops.request.XLim = map_xlim;
  obj.ops.request.YLim = map_ylim;
  
  [A,x_data,y_data] = obj.google.map.request_google_map(obj.ops.request.XLim(1), obj.ops.request.XLim(2), 256-obj.ops.request.YLim(1), 256-obj.ops.request.YLim(2));
  A = flipud(A);
  if isempty(A)
    % This should generally not occur since a switch to Google maps implies that the map projection has changed and the program should automatically go to the default bounds for the map.
    error('Google map cannot be selected with the viewing area is completely outside the latitude bounds of google maps (+/-85 deg latitude).');
  end
  y_data = sort(256-y_data);
  
  if obj.map.fline_source == 0
    % png format is more precise for alpha merge
    obj.ops.request.ImageFormat = 'image/png';
    
    % Convert from Google World Coordinates to EPSG:3857 WGS 84 /
    % Pseudo-Mercator. Numbers found by comparing:
    %   https://epsg.io/transform#s_srs=4326&t_srs=3857&x=0.0000000&y=85.0511288
    %   https://epsg.io/transform#s_srs=4326&t_srs=3857&x=180.00&y=0.000
    %   google_map.world_to_latlon(256,0)
    obj.ops.request.XLim = (obj.ops.request.XLim) * 20037508.34/128 - 20037508.34;
    obj.ops.request.YLim = (obj.ops.request.YLim) * 20037508.34/128 - 20037508.34;
    
    obj.ops.request.ImageHeight =  size(A,1);
    obj.ops.request.ImageWidth  = size(A,2);
    modrequest = strcat(obj.ops.request.RequestURL,'&viewparams=',obj.ops.seasons_modrequest,obj.ops.season_group_ids_modrequest);
    obj.ops.request.XLim = (obj.ops.request.XLim + 20037508.34) * 128/20037508.34;
    obj.ops.request.YLim = (obj.ops.request.YLim + 20037508.34) * 128/20037508.34;
    A_flightlines = obj.map_pref.ops.wms.getMap(modrequest);
    % Alpha/transparency merge of OPS flightlines and google map
    A_flightlines = double(flipud(A_flightlines))/255;
    alpha = rgb2hsv(A_flightlines);
    alpha = alpha(:,:,2);
    A = bsxfun(@times,A,(1-alpha)) + bsxfun(@times,A_flightlines,alpha);
  end
  
elseif obj.map.source == 2
  %% Blank Stereographic map

  if obj.map.fline_source == 0
    obj.ops.request.ImageFormat = 'image/png';
    obj.ops.request.XLim = map_xlim;
    obj.ops.request.YLim = map_ylim;
    
    % Build the new WMS query, submit it and then retrieve the result
    obj.ops.request.ImageHeight =  height;
    obj.ops.request.ImageWidth  = width;
    modrequest = strcat(obj.ops.request.RequestURL,'&viewparams=',obj.ops.seasons_modrequest,obj.ops.season_group_ids_modrequest);
    A = obj.map_pref.ops.wms.getMap(modrequest);
    R = obj.ops.request.RasterRef;
    R = R/obj.map.scale;
  
    % Create axes
    x_data = R(3,1) + [0 size(A,2)*R(2,1)];
    y_data = R(3,2) + [0 size(A,1)*R(1,2)];
  else
    A = ones(1,1,3);
    x_data = map_xlim/obj.map.scale;
    y_data = map_ylim/obj.map.scale;
  end
  
elseif obj.map.source == 3
  %% Blank Geodetic map

  if obj.map.fline_source == 0
    % THIS IS NOT SUPPORTED... MAYBE OUR GEOSERVER IS TOO OLD AND MATLAB
    % DOES NOT KNOW HOW TO INTERFACE
    obj.ops.request.ImageFormat = 'image/png';
    %obj.ops.request.Latlim = map_ylim;
    %obj.ops.request.Lonlim = map_xlim;
    obj.ops.request.Latlim = map_xlim; % HACK FOR OLD GEOSERVER?
    obj.ops.request.Lonlim = map_ylim; % HACK FOR OLD GEOSERVER?
    
    % Build the new WMS query, submit it and then retrieve the result
    obj.ops.request.ImageHeight =  height;
    obj.ops.request.ImageWidth  = width;
    modrequest = strcat(obj.ops.request.RequestURL,'&viewparams=',obj.ops.seasons_modrequest,obj.ops.season_group_ids_modrequest);
    A = obj.map_pref.ops.wms.getMap(modrequest);
    R = obj.ops.request.RasterRef;
    R = R/obj.map.scale;
  
    % Create axes
    %x_data = R(3,1) + [0 size(A,2)*R(2,1)];
    %y_data = R(3,2) + [0 size(A,1)*R(1,2)];
    y_data = fliplr(R(3,1) + [0 size(A,2)*R(2,1)]); % HACK FOR OLD GEOSERVER?
    x_data = fliplr(R(3,2) + [0 size(A,1)*R(1,2)]); % HACK FOR OLD GEOSERVER?
  else
    A = ones(1,1,3);
    x_data = map_xlim/obj.map.scale;
    y_data = map_ylim/obj.map.scale;
  end
end

set(obj.map_panel.h_image,'XData',x_data,'YData',y_data,'CData',A);
set(obj.map_panel.h_axes, {'XLim','YLim'}, {sort(x_data([1 end])) sort(y_data([1 end]))});

obj.map.xaxis = x_data([1 end]);
obj.map.yaxis = y_data([1 end]);
