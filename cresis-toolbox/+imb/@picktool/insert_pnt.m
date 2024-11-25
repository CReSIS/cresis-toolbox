function cmds = insert_pnt(obj,param)
% cmds = insert_pnt(obj,param)
%
% Generic function for inserting single points (useful for child
% classes to implement for the left_click)
%
% param is standard param to left_click plus these fields:
%  search_rng = vector of relative bins to search around param.x

image_x = param.image_x;
image_y = param.image_y;
cur_layers = param.cur_layers;
x = param.x;
y = param.y;
search_range = param.search_range;
cmds = [];

fprintf('Insert point %f, %f\n', x, y);

% Clamp entered points to the x-boundaries
xlims = [min(image_x) max(image_x)];
if x < xlims(1)
  x = xlims(1);
elseif x > xlims(2)
  x = xlims(2);
end
  
% Find the closest point in the image
[~,image_x_idx] = min(abs(image_x-x));
dy = image_y(2)-image_y(1);
image_y_idx = 1 + round((y-image_y(1))/dy);
if image_y_idx < 1 || image_y_idx > size(param.image_c,1)
  max_idx = image_y_idx;
else
  % Prevent search range from searching outside bounds of param.image_c
  search_range = search_range(image_y_idx+search_range >= 1 ...
    & image_y_idx+search_range < size(param.image_c,1));
  [~,max_idx] = max(param.image_c(image_y_idx+search_range,image_x_idx));
  max_idx = search_range(max_idx) + image_y_idx;
end

[~,point_idxs] = min(abs(param.layer.x-x));
new_y = interp1(1:length(image_y),image_y,max_idx,'linear','extrap');

for layer_idx = 1:length(cur_layers)
  cur_layer = cur_layers(layer_idx);

  if ~isempty(point_idxs)
    cmds(end+1).undo_cmd = 'insert';
    cmds(end).undo_args = {cur_layer, point_idxs, ...
      param.layer.y{cur_layer}(point_idxs), ...
      param.layer.type{cur_layer}(point_idxs), ...
      param.layer.qual{cur_layer}(point_idxs)};
    cmds(end).redo_cmd = 'insert';
    cmds(end).redo_args = {cur_layer, point_idxs, ...
      new_y, 1, param.cur_quality};
  end
end

end
