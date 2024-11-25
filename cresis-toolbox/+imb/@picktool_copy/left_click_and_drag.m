function cmds = left_click_and_drag(obj,param)
% cmds = picktool_copy.left_click_and_drag(obj,param)
%
% Copy layer tool

image_x = param.image_x;
image_y = param.image_y;
cur_layers = param.cur_layers;
x = param.x;
y = param.y;
cmds = [];

fprintf('Copy points %f to %f, %f to %f\n', x, y);

try
  source_layer = round(str2double(get(obj.panel.sourceTB,'String')));
  if length(source_layer) ~= 1 || source_layer < 1 || source_layer > length(param.layer.y)
    error('');
  end
catch ME
  error('Source layer entered is invalid. Enter a single positive integer.\n');
end

copy_mode = get(obj.panel.modePM,'Value');

if copy_mode == 3
  try
    correct_layer = round(str2double(get(obj.panel.correctTB,'String')));
    if length(correct_layer) ~= 1 || correct_layer < 1 || correct_layer > length(param.layer.y)
      error('');
    end
  catch ME
    error('Correct layer entered is invalid. Enter a single positive integer.\n');
  end
end

param.x_bounds = 2;
param.y_bounds = 2;
if copy_mode == 3
  [manual_idxs,auto_idxs,point_idxs] = obj.find_matching_pnts(param,correct_layer);
else
  [manual_idxs,auto_idxs,point_idxs] = obj.find_matching_pnts(param,source_layer);
end

for layer_idx = 1:length(cur_layers)
  cur_layer = cur_layers(layer_idx);
  
  if ~isempty(point_idxs)
    if copy_mode == 3
      %% Diff Mode
      cmds(end+1).undo_cmd = 'insert';
      cmds(end).undo_args = {cur_layer, point_idxs, ...
        param.layer.y{cur_layer}(point_idxs), ...
        param.layer.type{cur_layer}(point_idxs), ...
        param.layer.qual{cur_layer}(point_idxs)};
      cmds(end).redo_cmd = 'insert';
      cmds(end).redo_args = {cur_layer, point_idxs, ...
        param.layer.y{cur_layer}(point_idxs) + param.layer.y{correct_layer}(point_idxs) - param.layer.y{source_layer}(point_idxs), ...
        param.layer.type{cur_layer}(point_idxs), ...
        param.layer.qual{cur_layer}(point_idxs)};
    elseif copy_mode == 2
      %% Merge Mode
      cmds(end+1).undo_cmd = 'insert';
      % Only update the NaN
      mask = isnan(param.layer.y{cur_layer}(point_idxs));
      cmds(end).undo_args = {cur_layer, point_idxs(mask), ...
        param.layer.y{cur_layer}(point_idxs(mask)), ...
        param.layer.type{cur_layer}(point_idxs(mask)), ...
        param.layer.qual{cur_layer}(point_idxs(mask))};
      cmds(end).redo_cmd = 'insert';
      % Merge vectors
      merged_layer = merge_vectors(param.layer.y{cur_layer}(point_idxs),param.layer.y{source_layer}(point_idxs));
      % Insert the merged points
      cmds(end).redo_args = {cur_layer, point_idxs(mask), ...
        merged_layer(mask), ...
        param.layer.type{source_layer}(point_idxs(mask)), ...
        param.layer.qual{source_layer}(point_idxs(mask))};
    else
      %% Copy Mode
      cmds(end+1).undo_cmd = 'insert';
      cmds(end).undo_args = {cur_layer, point_idxs, ...
        param.layer.y{cur_layer}(point_idxs), ...
        param.layer.type{cur_layer}(point_idxs), ...
        param.layer.qual{cur_layer}(point_idxs)};
      cmds(end).redo_cmd = 'insert';
      s = param.layer.y{source_layer}(point_idxs);
      try
        size_s = size(s);
        eval_cmd = get(obj.panel.source_evalTB,'String');
        evalc(eval_cmd);
        % Ensure size is correct
        if ~isequal(size_s, size(s))
          error('s changed in size which is not allowed. Source eval parameter should be modified to prevent this from happening.');
        end
        % Ensure type is correct.
        if ~isa(s,'double')
          error('s changed in type which is not allowed. Source eval parameter should be modified to prevent this from happening.');
        end
      catch ME;
        warning(ME.getReport);
      end;
      cmds(end).redo_args = {cur_layer, point_idxs, ...
        s, ...
        param.layer.type{source_layer}(point_idxs), ...
        param.layer.qual{source_layer}(point_idxs)};
    end
  end
end

end
