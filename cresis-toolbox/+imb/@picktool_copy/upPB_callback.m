function upPB_callback(obj,hObj,event)
% picktool_copy.upPB_callback(obj,hObj,event)
%
% up push button callback. Causes active layers to be shifted up according
% to the "Shift Size" field

cur_layers = find(obj.parent.eg.layers.selected_layers).';

point_idxs = 1:length(obj.parent.eg.layers.x_curUnit);

dy = obj.parent.eg.image_yaxis(2)-obj.parent.eg.image_yaxis(1);

try
  shift_size = round(str2double(get(obj.panel.shiftTB,'String')));
  if length(shift_size) ~= 1
    error('');
  end
catch ME
  error('Shift Size entered is invalid. Enter a single number.\n');
end

cmds = [];
for layer_idx = 1:length(cur_layers)
  cur_layer = cur_layers(layer_idx);
  
  cmds(end+1).undo_cmd = 'insert';
  cmds(end).undo_args = {cur_layer, point_idxs, ...
    obj.parent.eg.layers.y_curUnit{cur_layer}(point_idxs), ...
    obj.parent.eg.layers.type{cur_layer}(point_idxs), ...
    obj.parent.eg.layers.qual{cur_layer}(point_idxs)};
  cmds(end).redo_cmd = 'insert';
  cmds(end).redo_args = {cur_layer, point_idxs, ...
    obj.parent.eg.layers.y_curUnit{cur_layer}(point_idxs) - shift_size*dy, ...
    obj.parent.eg.layers.type{cur_layer}(point_idxs), ...
    obj.parent.eg.layers.qual{cur_layer}(point_idxs)};
  
end

obj.parent.undo_stack.push(obj.parent.cmds_convert_units(cmds));
