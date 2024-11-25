function button_motion(obj,src,event)
% button_motion(obj,src, event)
%
% Called by echowin when mouse cursor is moved. Handles tracking mouse position
% and mouse cursor changing when outside of axes

if obj.busy_mode
  set(obj.h_fig,'Pointer','watch'); drawnow;
else
  mouse_pos = get(obj.h_fig,'CurrentPoint');
  uipanel_pos = get(obj.right_panel.handle,'Position');
  % check if inside status bar
  status_pos = get(obj.right_panel.status_panel.handle,'Position');
  status_h = status_pos(4);
  if mouse_pos(1) < uipanel_pos(1) || mouse_pos(2) < status_h
    set(obj.h_fig,'Pointer','Arrow');
    return;
  elseif obj.zoom_mode
    set(obj.h_fig,'Pointer','custom');
  end
  
  % Check limits and clamp point to be axes limits
  axis_pos = get(obj.h_axes,'CurrentPoint');
  axis_pos = axis_pos(1,:);
  xlim = sort(get(obj.h_axes,'XLim'));
  ylim = sort(get(obj.h_axes,'YLim'));
  below_x = axis_pos(1) < xlim(1);
  above_x = axis_pos(1) > xlim(2);
  below_y = axis_pos(2) < ylim(1);
  above_y = axis_pos(2) > ylim(2);
  % correct edges
  if below_x
    x = xlim(1);
  elseif above_x
    x = xlim(2);
  else
    x = axis_pos(1);
  end
  if below_y
    y = ylim(1);
  elseif above_y
    y = ylim(2);
  else
    y = axis_pos(2);
  end
  
  if obj.cursor_mode
    rline = obj.update_cursor(x,y,true);
  else
    % Find the range line in the image closest to the x-value "x"
    [~,rline] = min(abs(obj.eg.image_xaxis-x));
  end
  
  % Get the CData
  cdata = 10*log10(obj.eg.image_data(min(size(obj.eg.image_data,1),max(1,1+round((y-obj.eg.image_yaxis(1))/(obj.eg.image_yaxis(2)-obj.eg.image_yaxis(1))))), rline));
  
  % Get the frame number
  cur_frm = find(obj.eg.image_gps_time(rline) >= obj.eg.start_gps_time,1,'last');
  if isempty(cur_frm)
    cur_frm = 1;
  end

  % Print mouse position to status bar
  set(obj.right_panel.status_panel.mouseCoordText,'String',sprintf('%03d %.3fN %.3fW |%.0f|%g|%.0f',cur_frm,obj.eg.image_lat(rline),obj.eg.image_lon(rline),x,y,cdata));
  
  % OLD: Print mouse position to status bar
  %       yaxis_unit = get(obj.left_panel.yaxisPM,'Value');
  %       switch yaxis_unit
  %         case 1
  %           y_unit = 'us';
  %         case 2
  %           y_unit = 'm';
  %         case 3
  %           y_unit = 'm';
  %         case 4
  %           y_unit = '';
  %         case 5
  %           y_unit = 'm';
  %       end
  % set(obj.right_panel.status_panel.mouseCoordText,'String',sprintf('%8.3fN %8.3fW Y=%8.4f%s',lat,lon,y,y_unit));
end

end
