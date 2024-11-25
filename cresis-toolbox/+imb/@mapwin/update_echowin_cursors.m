function update_echowin_cursors(obj,src,event)
% mapwin.update_echowin_cursors(obj,src,event)
%
% Draws cursors in the map window. Can be called via a click in the map
% window (through @mapwin/draw_vector_layers) or via a listener to any echowin
% objects open (@mapwin/<callback_name>) that gets triggered by a shift-left click
% in an echogram window (@echowin/button_up + @echowin/echo_update_cursors)

% Plot the echowin source in red and with clutter

% Update the source echowin's cursor and clutter on the map
if obj.map.source == 1
  [src_x,src_y] = google_map.latlon_to_world([src.cursor.lat src.cursor.clutter_lat], [src.cursor.lon src.cursor.clutter_lon]); src_y = 256-src_y;
elseif obj.map.source == 3
  src_x = src.cursor.clutter_lon;
  src_y = src.cursor.clutter_lat;
else
  [src_x,src_y] = projfwd(obj.map.proj, [src.cursor.lat src.cursor.clutter_lat], [src.cursor.lon src.cursor.clutter_lon]);
end

for idx = 1:length(obj.echowin_list)
  if src == obj.echowin_list(idx)
    set(obj.echowin_maps(idx).h_cursor, 'XData', src_x/obj.map.scale, 'YData', src_y/obj.map.scale, 'Color','red');
  else
    % Update the echowin's cursor in the echogram (this finds the closest
    % point to the supplied x,y and that becomes the next cursor position
    % for this echowin)
    obj.echowin_list(idx).set_cursor_by_map(src.cursor.lat,src.cursor.lon,'echowin',src.cursor.target_elev);
    % Update the echowin's cursor on the map
    if obj.map.source == 1
      [x,y] = google_map.latlon_to_world(obj.echowin_list(idx).cursor.lat, obj.echowin_list(idx).cursor.lon); y = 256-y;
    elseif obj.map.source == 3
      x = obj.echowin_list(idx).cursor.lon;
      y = obj.echowin_list(idx).cursor.lat;
    else
      [x,y] = projfwd(obj.map.proj, obj.echowin_list(idx).cursor.lat, obj.echowin_list(idx).cursor.lon);
    end
    set(obj.echowin_maps(idx).h_cursor, 'XData', x/obj.map.scale, 'YData', y/obj.map.scale, 'Color', 'black');
  end
  
  ascope = [];
  ascope.echowin = get(obj.echowin_list(idx).h_fig,'Number');
  ascope.sys = obj.echowin_list(idx).eg.system;
  ascope.season_name = obj.echowin_list(idx).eg.cur_sel.season_name;
  ascope.frm_str = obj.echowin_list(idx).eg.frm_strs{obj.echowin_list(idx).eg.frms(1)};
  ascope.gps_time = obj.echowin_list(idx).cursor.gps_time;
  ascope.lat = obj.echowin_list(idx).cursor.lat;
  ascope.lon = obj.echowin_list(idx).cursor.lon;
  ascope.target_twtt = obj.echowin_list(idx).cursor.target_twtt;
  ascope.data = obj.echowin_list(idx).cursor.data;
  ascope.twtt = obj.echowin_list(idx).cursor.twtt;
  ascope.surf_twtt = obj.echowin_list(idx).cursor.surf_twtt;
  
  obj.map_ascope.update_ascope(ascope);
  % Make the cursors be plotted on top
  uistack(obj.echowin_maps(idx).h_cursor,'top');
end
