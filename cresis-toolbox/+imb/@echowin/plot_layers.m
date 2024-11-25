function plot_layers(obj)
% echowin.plot_layers(obj)
%
% Update layer plot handles

physical_constants;
vel_air = c/2;
vel_ice = c/(sqrt(er_ice)*2);

% ======================================================================
%% Convert the data along the y-axis according to the units
% perform y-axis conversion (from twtt)
yaxis_choice = get(obj.left_panel.yaxisPM,'Value');
if yaxis_choice == 1 % TWTT
  % convert layerPnts_y from TWTT to current unit
  layer_y_curUnit = cell(1,length(obj.eg.layers.y));
  for idx = 1:length(obj.eg.layers.y)
    layer_y_curUnit{idx} = obj.eg.layers.y{idx}*1e6;
  end
  
elseif yaxis_choice == 2 % WGS_84 Elevation
  % Convert layerPnts_y from TWTT to WGS_84 Elevation
  layer_y_curUnit = obj.eg.layers.y;
  elevation = interp1(obj.eg.gps_time,...
    obj.eg.elev,...
    obj.eg.layers.x,'linear','extrap');
  surface = interp1(obj.eg.gps_time,...
    obj.eg.surf_twtt,...
    obj.eg.layers.x,'linear','extrap');
  for idx = 1: length(layer_y_curUnit)
    range = min(layer_y_curUnit{idx},surface)*vel_air ...
      +max(0,layer_y_curUnit{idx}-surface) * vel_ice;
    layer_y_curUnit{idx} = elevation - range;
    layer_y_curUnit{idx}(isnan(obj.eg.layers.y{idx})) = NaN;
  end
  
elseif yaxis_choice == 3 % Depth/Range
  % convert layerPnts_y from TWTT to depth
  layer_y_curUnit = obj.eg.layers.y;
  surface = interp1(obj.eg.gps_time,...
    obj.eg.surf_twtt,...
    obj.eg.layers.x,'linear','extrap');
  for idx = 1:length(layer_y_curUnit)
    layer_y_curUnit{idx} = min(layer_y_curUnit{idx},surface)*vel_air ...
      +max(0,layer_y_curUnit{idx}-surface)*vel_ice;
    layer_y_curUnit{idx}(isnan(obj.eg.layers.y{idx})) = NaN;
  end
  
elseif yaxis_choice == 4 % Range bin
  % convert layerPnts_y from TWTT to range bin
  layer_y_curUnit = obj.eg.layers.y;
  for idx = 1:length(layer_y_curUnit)
    layer_y_curUnit{idx} = interp1(obj.eg.time,...
      1:length(obj.eg.time),...
      layer_y_curUnit{idx},'linear','extrap');
  end
  
elseif yaxis_choice == 5 % Surface flat
  % convert layerPnts_y from TWTT to depth
  layer_y_curUnit = obj.eg.layers.y;
  surface = interp1(obj.eg.gps_time,...
    obj.eg.surf_twtt,...
    obj.eg.layers.x,'linear','extrap');
  for idx = 1:length(layer_y_curUnit)
    layer_y_curUnit{idx} = min(0,(layer_y_curUnit{idx}-surface))*vel_air ...
      +max(0,(layer_y_curUnit{idx}-surface))*vel_ice;
    layer_y_curUnit{idx}(isnan(obj.eg.layers.y{idx})) = NaN;
  end
  
end

%% Plot layers
%% WARNING: DO NOT IMPLEMENT WITH SCATTER... TOO SLOW RENDERING
obj.eg.layers.x_curUnit = [];
obj.eg.layers.y_curUnit = {};
try
  delete(obj.h_layer(2*length(obj.eg.layers.y) + 1:end));
end
obj.h_layer = obj.h_layer(1:2*length(obj.eg.layers.y));
try
  delete(obj.h_quality(6*length(obj.eg.layers.y)+1:end));
end
obj.h_quality = obj.h_quality(1:6*length(obj.eg.layers.y));
for idx = 1:length(obj.eg.layers.y)
  % Convert x-axis units
  layer_x_curUnit = interp1(obj.eg.image_gps_time,...
    obj.eg.image_xaxis,...
    obj.eg.layers.x,'linear','extrap');
  
  % get manual/auto pts (use them for layer handles)
  layer_manual = obj.eg.layers.type{idx} == 1;
  
  % Manual points (plot this way to handle empty XData or YData
  set(obj.h_layer(2*(idx-1)+1),{'XData','YData'}, ...
    {layer_x_curUnit(layer_manual),layer_y_curUnit{idx}(layer_manual)});
  % Auto and manual points
  set(obj.h_layer(2*(idx-1)+2),{'XData','YData'}, ...
    {layer_x_curUnit,layer_y_curUnit{idx}});
  
  layer_good = obj.eg.layers.qual{idx} == 1;
  layer_moderate = obj.eg.layers.qual{idx} == 2;
  layer_derived = obj.eg.layers.qual{idx} == 3;
  layer_y_curUnit_good = layer_y_curUnit{idx};
  layer_y_curUnit_good(~layer_good) = NaN;
  layer_y_curUnit_moderate= layer_y_curUnit{idx};
  layer_y_curUnit_moderate(~layer_moderate) = NaN;
  layer_y_curUnit_derived= layer_y_curUnit{idx};
  layer_y_curUnit_derived(~layer_derived) = NaN;

  % Good manual points (plot this way to handle empty XData or YData
  set(obj.h_quality(6*(idx-1)+1),{'XData','YData'}, ...
    {layer_x_curUnit(layer_good&layer_manual),layer_y_curUnit{idx}(layer_good&layer_manual)});
  
  % Good auto points (plot this way to handle empty XData or YData
  set(obj.h_quality(6*(idx-1)+2),{'XData','YData'}, ...
    {layer_x_curUnit,layer_y_curUnit_good});

  % Moderate manual points (plot this way to handle empty XData or YData
  set(obj.h_quality(6*(idx-1)+3),{'XData','YData'}, ...
    {layer_x_curUnit(layer_moderate&layer_manual),layer_y_curUnit{idx}(layer_moderate&layer_manual)});
  
  % Moderate auto points (plot this way to handle empty XData or YData
  set(obj.h_quality(6*(idx-1)+4),{'XData','YData'}, ...
    {layer_x_curUnit,layer_y_curUnit_moderate});

  % Derived manual points (plot this way to handle empty XData or YData
  set(obj.h_quality(6*(idx-1)+5),{'XData','YData'}, ...
    {layer_x_curUnit(layer_derived&layer_manual),layer_y_curUnit{idx}(layer_derived&layer_manual)});
  
  % Derived auto points (plot this way to handle empty XData or YData
  set(obj.h_quality(6*(idx-1)+6),{'XData','YData'}, ...
    {layer_x_curUnit,layer_y_curUnit_derived});

  %% Update obj.eg layers with current units
  obj.eg.layers.x_curUnit = layer_x_curUnit;
  obj.eg.layers.y_curUnit{idx} = layer_y_curUnit{idx};
end

end
