function button_up(obj,src,event)
% map_win.button_up(obj,src, event)
%
% Called by mapwin when a mouse press is released. Handles zoom in/out,
% frame selection, and marker updating.

if strcmpi(get(obj.map_panel.h_axes,'Visible'),'off')
  return;
end

[x,y,but] = get_mouse_info(obj.h_fig,obj.map_panel.h_axes);
modifier_string = '';
if obj.control_pressed
  modifier_string = strcat(modifier_string,' ctrl');
end
if obj.shift_pressed
  modifier_string = strcat(modifier_string,' shift');
end
fprintf('Map But: (%.1f, %.1f) but %d %s\n', x, y, but, modifier_string);

% Make sure click is in the axis
xlims = xlim(obj.map_panel.h_axes);
ylims = ylim(obj.map_panel.h_axes);
if x < xlims(1) || x > xlims(2) || y < ylims(1) || y > ylims(2)
  click_in_axis = false;
else
  click_in_axis = true;
end

% ===================================================================
% Pointer Mode
% Left click: Select closest frame
% Left click and drag: Zoom to region
% Zoom Mode
% Left click: Zoom at point
% Left click and drag: Zoom to region
% Right click: Zoom out at point
% Double click: Zoom reset
% Any Mode
% Scroll: Zooms in/out (handled by button_scroll.m)
% Ctrl  + any click: Select closest frame
% Shift + any click: Set cursor

if (obj.control_pressed || (but == 4 && ~obj.zoom_mode)) && click_in_axis % control click
  % ===================================================================
  % Note: All single clicks become right clicks when Ctrl is held down
  if but == 3
    % ===================================================================
    % Ctrl + Normal click: Select closest frame
    obj.get_closest_frame(struct('x',x,'y',y));
    
  elseif but == 4
    % ===================================================================
    % Ctrl + double click: Load the selected frame
    obj.loadPB_callback;
    
  end
  
elseif obj.shift_pressed && click_in_axis % shift click
  % ===================================================================
  % Note: All single clicks become middle clicks when Shift is held down
  if but == 2
    % ===================================================================
    % Ctrl + Normal click: Get closest point to each echowin flightline and
    % move the echowin cursors to their respective closest points
    
    if (obj.map.source == 1)
      [lat, lon] = google_map.world_to_latlon(x*obj.map.scale, 256-y*obj.map.scale);
    elseif (obj.map.source == 3)
      lon = x*obj.map.scale;
      lat = y*obj.map.scale;
    else
      [lat,lon] = projinv(obj.map.proj,x*obj.map.scale,y*obj.map.scale);
    end
    % Find closest point for each echowin and update cursor information
    for idx = 1:length(obj.echowin_list)
      % Update the echowin's cursor in the echogram (this finds the closest
      % point to the supplied x,y and that becomes the next cursor position
      % for this echowin)
      obj.echowin_list(idx).set_cursor_by_map(lat,lon,'mapwin_notify');
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
      % Make the cursors be plotted on top
      uistack(obj.echowin_maps(idx).h_cursor,'top');
    end
  end
  
elseif ~obj.control_pressed && ~obj.shift_pressed % no modifiers
  if but == 1
    % ===================================================================
    % Left click: Zoom in
    % Ctrl + left click: Select closest frame
    if x~=obj.click_x && y~=obj.click_y
      % zoom into rbbox
      % change axis
      xaxis = get(obj.map_panel.h_axes,'XLim');
      yaxis = get(obj.map_panel.h_axes,'YLim');
      [x_min x_max y_min y_max] = imb.sort_clicks(xaxis,yaxis,obj.click_x,obj.click_y,x,y);
      
      fprintf('Selected area: x = %.2f to %.2f, y = %.2f to %.2f\n',...
        x_min, x_max, y_min, y_max);
      
      % query the new map view area, then draw it
      obj.query_redraw_map(x_min,x_max,y_min,y_max);
    elseif x == obj.click_x && y == obj.click_y && click_in_axis
      if ~obj.zoom_mode
        % ===================================================================
        % Normal click: Select closest frame
        obj.get_closest_frame(struct('x',x,'y',y));
      else
        % zoom on click
        % get updated x and y axis
        x_extent = diff(get(obj.map_panel.h_axes,'XLim'));
        y_extent = diff(get(obj.map_panel.h_axes,'YLim'));
        
        % zoom in by a factor of 1/2 and perform error checking (for zooms made
        % close to the map's edges)
        new_xaxis = [obj.click_x - x_extent/4, obj.click_x + x_extent/4];
        new_yaxis = [obj.click_y - y_extent/4, obj.click_y + y_extent/4];
        
        if new_yaxis(1) < obj.map.yaxis_default(1)
          new_yaxis(1) = obj.map.yaxis_default(1);
        end
        if new_yaxis(end) > obj.map.yaxis_default(end)
          new_yaxis(end) = obj.map.yaxis_default(end);
        end
        if new_xaxis(1) < obj.map.xaxis_default(1)
          new_xaxis(1) = obj.map.xaxis_default(1);
        end
        if new_xaxis(end) > obj.map.xaxis_default(end)
          new_xaxis(end) = obj.map.xaxis_default(end);
        end
        
        % get a new map for these limits
        obj.query_redraw_map(new_xaxis(1),new_xaxis(end),new_yaxis(1),new_yaxis(end));
      end
    end
    
  elseif but == 3 && click_in_axis
    % ===================================================================
    % Right click: Zoom out
    % Ctrl + right click: Set marker point
    
    % get updated x and y axis
    x_extent = diff(get(obj.map_panel.h_axes,'XLim'));
    y_extent = diff(get(obj.map_panel.h_axes,'YLim'));
    
    % zoom out by a factor of 2 and perform error checking (for zooms made
    % close to the map's edges)
    new_xaxis = [obj.click_x - 1.0*x_extent, obj.click_x + 1.0*x_extent];
    new_yaxis = [obj.click_y - 1.0*y_extent, obj.click_y + 1.0*y_extent];
    
    if new_yaxis(1) < obj.map.yaxis_default(1)
      new_yaxis(1) = obj.map.yaxis_default(1);
    end
    if new_yaxis(end) > obj.map.yaxis_default(end)
      new_yaxis(end) = obj.map.yaxis_default(end);
    end
    if new_xaxis(1) < obj.map.xaxis_default(1)
      new_xaxis(1) = obj.map.xaxis_default(1);
    end
    if new_xaxis(end) > obj.map.xaxis_default(end)
      new_xaxis(end) = obj.map.xaxis_default(end);
    end
    
    % get a new map for these limits
    obj.query_redraw_map(new_xaxis(1),new_xaxis(end),new_yaxis(1),new_yaxis(end));
  elseif but == 4 && click_in_axis
    % ===================================================================
    % Double click: Zoom reset
    % Ctrl + double click: Select closest frame and load
    
    new_yaxis = obj.map.yaxis_default;
    new_xaxis = obj.map.xaxis_default;
    
    % get a new map for these limits
    obj.query_redraw_map(new_xaxis(1),new_xaxis(end),new_yaxis(1),new_yaxis(end));
    
  end
end

return
