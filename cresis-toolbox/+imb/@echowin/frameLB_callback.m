function frameLB_callback(obj,hObj,event)

% Ensure focus stays on figure to prevent hotkeys registering with this
% uicontrol.
uicontrol(obj.right_panel.status_panel.statusText);

if strcmpi(get(obj.h_fig,'SelectionType'),'open')
  % Double click
  %  - On a double click, the callback is called twice: once with
  %    'normal' SelectionType and then with 'open'.
  %  - On double click, load the selection to the picking window
  
  %  menuString = get(hui.pickfig(gcf).left_panel.frameLB,'String');
  frame_idx = get(obj.left_panel.frameLB,'Value');
  
  cur_axis = axis(obj.h_axes);
  
  % Convert x_min, x_max to GPS time
  xlims = interp1(obj.eg.image_xaxis,obj.eg.image_gps_time,cur_axis(1:2),'linear','extrap');
  
  % Move the selection to the newly selected frame
  dx = obj.eg.start_gps_time(frame_idx) - xlims(1);
  if abs(dx) < mean(diff(obj.eg.image_gps_time))
    % reload the current frame
    obj.redraw(xlims(1),xlims(2),cur_axis(3),cur_axis(4),struct('clipped',3));
  else
    % Draw data with new axis
    xlims = xlims + dx;
    obj.redraw(xlims(1),xlims(2),cur_axis(3),cur_axis(4),struct('clipped',2));
  end
  
else
  % Regular click
  frame_idx = get(obj.left_panel.frameLB,'Value');
  obj.update_frame_and_sourceLB(frame_idx);
  if ~isequal(obj.eg.old_frame_idx,frame_idx)
    % Let the map window know that a different frame has been selected
    % so that the map window can change the frame selection
    obj.eg.old_frame_idx = frame_idx;
    notify(obj,'update_map_selection');
  end
end
