function ascopeCM_callback(obj,source,event)
% ascopeCM_callback(obj,source,event)

% Ensure focus stays on figure to prevent hotkeys registering with this
% uicontrol.
uicontrol(obj.right_panel.status_panel.statusText);

if source == obj.left_panel.ascopeCM_visible || source == obj.left_panel.ascopeCM_hide
  %% ascopeCM_visible/ascopeCM_hide
  val = get(obj.left_panel.ascopeLB,'Value');
  
  obj.ascope.visible(val) = source == obj.left_panel.ascopeCM_visible;
  
  obj.plot_update();
  
elseif source == obj.left_panel.ascopeCM_copy
  %% ascopeCM_copy
  vals = get(obj.left_panel.ascopeLB,'Value');
  str = [];
  for val = vals
    str = [str, sprintf('%s %s %s %s\n', ...
      obj.ascope.sys{val},obj.ascope.season_name{val}, ...
      obj.ascope.frm_str{val},datestr(epoch_to_datenum(obj.ascope.gps_time(val)),'HH:mm:SS'))];
  end
  fprintf('%s', str);
  clipboard('copy',str);
  
elseif source == obj.left_panel.ascopeCM_memory
  %% ascopeCM_memory
  vals = get(obj.left_panel.ascopeLB,'Value');
  obj.memory(vals);
  
elseif source == obj.left_panel.ascopeCM_up
  %% ascopeCM_up
  % Get the currently selected ascopes.
  val = get(obj.left_panel.ascopeLB,'Value');
  val = val(val>1);
  if ~isempty(val)
    val = val(1);
    new_val = val-1;
    reorder_ascopes(obj,val,new_val);
    obj.plot_update();
  end
  
elseif source == obj.left_panel.ascopeCM_down
  %% ascopeCM_down
  % Get the currently selected ascopes.
  val = get(obj.left_panel.ascopeLB,'Value');
  val = val(val<length(obj.ascope.sys));
  if ~isempty(val)
    val = val(1);
    new_val = val+1;
    reorder_ascopes(obj,val,new_val);
    obj.plot_update();
  end
  
elseif source == obj.left_panel.ascopeCM_top
  %% ascopeCM_top
  % Get the currently selected ascopes.
  val = get(obj.left_panel.ascopeLB,'Value');
  if ~isempty(val)
    val = val(1);
    new_val = 1;
    reorder_ascopes(obj,val,new_val);
    obj.plot_update();
  end
  
elseif source == obj.left_panel.ascopeCM_bottom
  %% ascopeCM_bottom
  % Get the currently selected ascopes.
  val = get(obj.left_panel.ascopeLB,'Value');
  if ~isempty(val)
    val = val(1);
    new_val = length(obj.ascope.sys);
    reorder_ascopes(obj,val,new_val);
    obj.plot_update();
  end
  
elseif source == obj.left_panel.ascopeCM_delete
  %% ascopeCM_delete
  % Get the currently selected ascopes.
  vals = get(obj.left_panel.ascopeLB,'Value');
  
  delete(obj.h_ascope(vals));
  delete(obj.h_cursor(vals));
  
  delete_mask = true(size(obj.ascope.echowin));
  delete_mask(vals) = false;
  obj.h_ascope = obj.h_ascope(delete_mask);
  obj.h_cursor = obj.h_cursor(delete_mask);
  obj.ascope.echowin = obj.ascope.echowin(delete_mask);
  obj.ascope.sys = obj.ascope.sys(delete_mask);
  obj.ascope.season_name = obj.ascope.season_name(delete_mask);
  obj.ascope.frm_str = obj.ascope.frm_str(delete_mask);
  obj.ascope.gps_time = obj.ascope.gps_time(delete_mask);
  obj.ascope.twtt = obj.ascope.twtt(delete_mask);
  obj.ascope.data = obj.ascope.data(delete_mask);
  obj.ascope.surf_twtt = obj.ascope.surf_twtt(delete_mask);
  obj.ascope.lat = obj.ascope.lat(delete_mask);
  obj.ascope.lon = obj.ascope.lon(delete_mask);
  obj.ascope.target_twtt = obj.ascope.target_twtt(delete_mask);
  obj.ascope.visible = obj.ascope.visible(delete_mask);
  obj.ascope.selected = obj.ascope.selected(delete_mask);
  set(obj.left_panel.ascopeLB,'Value',[]);
  
  obj.plot_update();
  
end

end

%% reorder_ascopes(obj,val,new_val)
function reorder_ascopes(obj,val,new_val)

if new_val ~= val
  % Reorder layers
  Nascopes = length(obj.ascope.echowin);
  new_order = [1:val-1, val+1:Nascopes];
  new_order = [new_order(1:new_val-1) val new_order(new_val:Nascopes-1)];
  
  obj.ascope.echowin = obj.ascope.echowin(new_order);
  obj.ascope.sys = obj.ascope.sys(new_order);
  obj.ascope.season_name = obj.ascope.season_name(new_order);
  obj.ascope.frm_str = obj.ascope.frm_str(new_order);
  obj.ascope.gps_time = obj.ascope.gps_time(new_order);
  obj.ascope.twtt = obj.ascope.twtt(new_order);
  obj.ascope.data = obj.ascope.data(new_order);
  obj.ascope.surf_twtt = obj.ascope.surf_twtt(new_order);
  obj.ascope.lat = obj.ascope.lat(new_order);
  obj.ascope.lon = obj.ascope.lon(new_order);
  obj.ascope.target_twtt = obj.ascope.target_twtt(new_order);
  obj.ascope.xlims = obj.ascope.xlims(new_order);
  obj.ascope.ylims = obj.ascope.ylims(new_order);
  obj.ascope.visible = obj.ascope.visible(new_order);
  obj.ascope.selected = obj.ascope.selected(new_order);
  obj.plot_update();
end

end
