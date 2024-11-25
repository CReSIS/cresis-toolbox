function update_layer_plots(obj)
% update_layer_plots(obj)
%
% Updates the layer plot handles with the latest layer data. Called from
% cmds_execute.

layer_y_curUnit = obj.eg.layers.y_curUnit;

for idx = 1:length(layer_y_curUnit)
  layer_x_curUnit = obj.eg.layers.x_curUnit;
  
  % get manual/auto pts (use them for layer handles)
  layer_manual = obj.eg.layers.type{idx} == 1;
  
  % Manual points (plot this way to handle empty XData or YData
  set(obj.h_layer(2*(idx-1)+1),{'XData','YData'}, ...
    {layer_x_curUnit(layer_manual),layer_y_curUnit{idx}(layer_manual)});
  % Auto and manual points
  set(obj.h_layer(2*(idx-1)+2),'YData',layer_y_curUnit{idx});
  
  layer_good = obj.eg.layers.qual{idx} == 1;
  layer_moderate = obj.eg.layers.qual{idx} == 2;
  layer_derived = obj.eg.layers.qual{idx} == 3;
  layer_y_curUnit_good = layer_y_curUnit{idx};
  layer_y_curUnit_good(~layer_good) = NaN;
  layer_y_curUnit_moderate= layer_y_curUnit{idx};
  layer_y_curUnit_moderate(~layer_moderate) = NaN;
  layer_y_curUnit_derived= layer_y_curUnit{idx};
  layer_y_curUnit_derived(~layer_derived) = NaN;

  set(obj.h_quality(6*(idx-1)+1),{'XData','YData'}, ...
    {layer_x_curUnit(layer_good&layer_manual),layer_y_curUnit{idx}(layer_good&layer_manual)});
  set(obj.h_quality(6*(idx-1)+2),{'XData','YData'}, ...
    {layer_x_curUnit,layer_y_curUnit_good});
  set(obj.h_quality(6*(idx-1)+3),{'XData','YData'}, ...
    {layer_x_curUnit(layer_moderate&layer_manual),layer_y_curUnit{idx}(layer_moderate&layer_manual)});
  set(obj.h_quality(6*(idx-1)+4),{'XData','YData'}, ...
    {layer_x_curUnit,layer_y_curUnit_moderate});
  set(obj.h_quality(6*(idx-1)+5),{'XData','YData'}, ...
    {layer_x_curUnit(layer_derived&layer_manual),layer_y_curUnit{idx}(layer_derived&layer_manual)});
  set(obj.h_quality(6*(idx-1)+6),{'XData','YData'}, ...
    {layer_x_curUnit,layer_y_curUnit_derived});
end

end
