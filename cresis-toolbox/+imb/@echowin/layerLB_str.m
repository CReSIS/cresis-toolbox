function layerLB_str(obj,keep_value)

if exist('keep_value','var') || isempty(keep_value)
  keep_value = false;
end

if ~keep_value
  set(obj.left_panel.layerLB,'Value',[]);
end
LB_strings = cell(1,length(obj.eg.layers.lyr_name));
for idx = 1:length(obj.eg.layers.lyr_name)
  name = sprintf(obj.eg.layers.lyr_name{idx},idx);
  if obj.eg.layers.visible_layers(idx)
    LB_strings{idx} = sprintf('(%d) %s:%s',idx,obj.eg.layers.lyr_group_name{idx},name);
  else
    LB_strings{idx} = sprintf('<HTML><FONT color="red">(%d) %s:%s</FONT></HTML>',idx,obj.eg.layers.lyr_group_name{idx},name);
  end
end
set(obj.left_panel.layerLB,'String',LB_strings);
