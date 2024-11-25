function update_ascopewin_cursors(obj,src,event)
% mapwin.update_ascopewin_cursors(obj,src,event)
%
% Updates which cursor 'x' are red and which are black.
% visible false: turn off
% visible true, selected false: turn blue
% visible true, selected true: turn red

x_red = [];
y_red = [];
x = [];
y = [];

for idx = 1:length(obj.map_ascope.ascope.gps_time)
  if obj.map_ascope.ascope.visible(idx)
    if obj.map_ascope.ascope.selected(idx)
      if obj.map.source == 1
        [x_red(end+1),y_red(end+1)] ...
          = google_map.latlon_to_world(obj.map_ascope.ascope.lat(idx), obj.map_ascope.ascope.lon(idx)); y = 256-y;
      elseif obj.map.source == 3
        x_red(end+1) = obj.map_ascope.ascope.lon(idx);
        y_red(end+1) = obj.map_ascope.ascope.lat(idx);
      else
        [x_red(end+1),y_red(end+1)] ...
          = projfwd(obj.map.proj, obj.map_ascope.ascope.lat(idx), obj.map_ascope.ascope.lon(idx));
      end
    else
      if obj.map.source == 1
        [x(end+1),y(end+1)] = google_map.latlon_to_world(obj.map_ascope.ascope.lat(idx), obj.map_ascope.ascope.lon(idx)); y = 256-y;
      else
        [x(end+1),y(end+1)] = projfwd(obj.map.proj, obj.map_ascope.ascope.lat(idx), obj.map_ascope.ascope.lon(idx));
      end
    end
  end
end

% Update the echowin's cursor on the map
set(obj.map_panel.h_ascopes_selected, {'XData', 'YData'}, {x_red/obj.map.scale, y_red/obj.map.scale});
set(obj.map_panel.h_ascopes, {'XData', 'YData'}, {x/obj.map.scale, y/obj.map.scale});
uistack(obj.map_panel.h_ascopes_selected,'top');
uistack(obj.map_panel.h_ascopes,'top');
