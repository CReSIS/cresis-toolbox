function cmds = left_click_and_drag(obj,param)
% cmds = left_click_and_drag(obj,param)
%
% Interpolate tool

image_x = param.image_x;
image_y = param.image_y;
cur_layers = param.cur_layers;
x = param.x;
y = param.y;
cmds = [];

fprintf('Interpolate points %f to %f, %f to %f\n', x, y);

%% Get tool interpolate method
interp_idx = get(obj.panel.interp_modePM,'Value');
interp_type = get(obj.panel.interp_modePM,'String');
interp_type = interp_type{interp_idx};

param.x_bounds = 3;
param.y_bounds = 1;

for layer_idx = 1:length(cur_layers)
  cur_layer = cur_layers(layer_idx);
  
  [manual_idxs,auto_idxs,~] = find_matching_pnts(obj,param,cur_layer);
  
  if length(manual_idxs) < 2
    warning('Insufficient points to interpolate');
    continue;
    
  elseif ~isempty(auto_idxs)
    cmds(end+1).undo_cmd = 'insert';
    cmds(end).undo_args = {cur_layer, auto_idxs, ...
      param.layer.y{cur_layer}(auto_idxs), ...
      param.layer.type{cur_layer}(auto_idxs), ...
      param.layer.qual{cur_layer}(auto_idxs)};
    cmds(end).redo_cmd = 'insert';
    cmds(end).redo_args = {cur_layer, auto_idxs, ...
      interp1(param.layer.x(manual_idxs),param.layer.y{cur_layer}(manual_idxs),param.layer.x(auto_idxs),interp_type), ...
      2*ones(size(auto_idxs)), param.cur_quality*ones(size(auto_idxs))};
    
%     if get(obj.panel.reinterp_mode_cbox,'Value')==1
%       % Need to implement
%     end
  end
end

return

