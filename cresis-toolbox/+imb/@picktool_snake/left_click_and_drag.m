function cmds = left_click_and_drag(obj,param)
% cmds = left_click_and_drag(obj,param)
%
% Snake tool

image_x = param.image_x;
image_y = param.image_y;
image_c = param.image_c;
cur_layers = param.cur_layers;
x = param.x;
y = param.y;
cmds = [];

fprintf('Snake points %f to %f, %f to %f\n', x, y);

param.x_bounds = 3;
param.y_bounds = 1;

%% Get snake method
% tool_idx = get(obj.top_panel.tool_PM,'Value');
tool_idx = 1;
if tool_idx == 1
  %=========================================================================
  %% Basic Snake
  for layer_idx = 1:length(cur_layers)
    cur_layer = cur_layers(layer_idx);
    
    [manual_idxs,auto_idxs,~] = find_matching_pnts(obj,param,cur_layer);
    
    if length(manual_idxs) < 1
      warning('Insufficient points to snake');
      continue;
    elseif ~isempty(auto_idxs)
      % Run snake on values
      [y_new] = obj.snake(image_c,image_x,image_y,param.layer.x(manual_idxs), ...
        param.layer.y{cur_layer}(manual_idxs),param.layer.x(auto_idxs));
      
      cmds(end+1).undo_cmd = 'insert';
      cmds(end).undo_args = {cur_layer, auto_idxs, ...
        param.layer.y{cur_layer}(auto_idxs), ...
        param.layer.type{cur_layer}(auto_idxs), ...
        param.layer.qual{cur_layer}(auto_idxs)};
      cmds(end).redo_cmd = 'insert';
      cmds(end).redo_args = {cur_layer, auto_idxs, ...
        y_new, ...
        2*ones(size(auto_idxs)), param.cur_quality*ones(size(auto_idxs))};
    end
  end
 
end
