function button_motion(obj,src,event)
% mapwin.button_motion(obj,src, event)
%
% Called by mapwin when mouse is moved.  Handles tracking mouse position
% and mouse cursor changing when outside of axes.

if obj.busy_mode
  %% Set the mouse pointer graphic
  set(obj.h_fig,'Pointer','watch');
  
elseif strcmpi(get(obj.map_panel.h_axes,'Visible'),'on')
  %% Check to make sure map is in the map panel
  set(obj.h_fig,'Units','normalized');
  mouse_pos = get(obj.h_fig,'CurrentPoint');
  set(obj.map_panel.handle,'Units','normalized');
  uipanel_pos = get(obj.map_panel.handle,'Position');
  
  set(obj.status_panel.handle,'Units','normalized');
  status_pos = get(obj.status_panel.handle,'Position');
  
  if mouse_pos(2) < uipanel_pos(2) || mouse_pos(2) > uipanel_pos(4)
    % Not in the axes
    set(obj.h_fig,'Pointer','Arrow');
    return;
  end
  
  %% Set the mouse pointer graphic
  if obj.zoom_mode
    set(obj.h_fig,'Pointer','custom');
  else
    set(obj.h_fig,'Pointer','Arrow');
  end
  
  % print current mouse position to status bar
  axis_pos = get(obj.map_panel.h_axes,'CurrentPoint');
  x = axis_pos(1,1);
  y = axis_pos(1,2);
  if (obj.map.source == 1)
    [lat, lon] = google_map.world_to_latlon(x*obj.map.scale, 256-y*obj.map.scale);
    set(obj.status_panel.mouseCoordText,'String',sprintf('%8.3fN %8.3fW; X=%8.3f Y=%8.3f  ',lat,lon,x,y));
  elseif (obj.map.source == 3)
    lat = y;
    lon = x;
    set(obj.status_panel.mouseCoordText,'String',sprintf('%8.3fN %8.3fW; X=%8.3f Y=%8.3f  ',lat,lon,x,y));
  else
    [lat,lon] = projinv(obj.map.proj,x*obj.map.scale,y*obj.map.scale);
    set(obj.status_panel.mouseCoordText,'String',sprintf('%8.3fN %8.3fW; X=%8.3fkm Y=%8.3fkm  ',lat,lon,x,y));
  end
  
  for idx = 1:length(obj.echowin_list)
    if obj.echowin_list(idx).cursor_mode
      % Update the echowin's cursor in the echogram (this finds the closest
      % point to the supplied x,y and that becomes the next cursor position
      % for this echowin)
      obj.echowin_list(idx).set_cursor_by_map(lat,lon,'mapwin');
      % Update the echowin's cursor on the map
      if obj.map.source == 1
        [x,y] = google_map.latlon_to_world(obj.echowin_list(idx).cursor.lat, obj.echowin_list(idx).cursor.lon); y = 256-y;
      else
        [x,y] = projfwd(obj.map.proj, obj.echowin_list(idx).cursor.lat, obj.echowin_list(idx).cursor.lon);
      end
      set(obj.echowin_maps(idx).h_cursor, 'XData', x/obj.map.scale, 'YData', y/obj.map.scale, 'Color', 'black');
    end
  end
end

end
