function update_echowin_flightlines(obj,src,event)
% update_echowin_flightlines(obj,src,event)
%
% Interface between the map window and the pick window. Allows all current
% pick locations to be plotted on the map and labeled with their respective
% window numbers.
%
% obj contains the mapwin class data
% src contains the echowin class data (see loadPB_callback.m)

% Get GPS time being displayed in echogram window to determine
% flightline information
xlimits = xlim(src.h_axes);
start_gps = src.eg.image_gps_time(find(src.eg.image_xaxis>=xlimits(1),1));
stop_gps = src.eg.image_gps_time(find(src.eg.image_xaxis<=xlimits(2),1,'last'));
% Handle special edge cases for the first and last column when the user
% selects xlimits before the first pixel or after the last pixel.
if isempty(start_gps)
  start_gps = stop_gps;
elseif isempty(stop_gps)
  stop_gps = start_gps;
end

valid_idxs = find(src.eg.map_gps_time >= start_gps & src.eg.map_gps_time <= stop_gps);
if isempty(valid_idxs)
  valid_idxs = find(src.eg.map_gps_time >= start_gps,1);
end
if isempty(valid_idxs)
  valid_idxs = length(src.eg.map_gps_time);
end

if obj.map.source==0
  % OPS Map
  new_xdata = src.eg.map_x(valid_idxs);
  new_ydata = src.eg.map_y(valid_idxs);
else
  % Google map in world coordinates
  new_xdata = src.eg.map_x(valid_idxs);
  new_ydata = src.eg.map_y(valid_idxs);
end

% Update the echowin's flightline graphics
echowin_idx = find(obj.echowin_list == src);
set(obj.echowin_maps(echowin_idx).h_line,{'XData','YData'},{new_xdata,new_ydata});
if strcmpi(class(src.h_fig),'double')
  set(obj.echowin_maps(echowin_idx).h_text,'Position',[new_xdata(1),new_ydata(1)], ...
    'String',sprintf('%d',src.h_fig),'FontSize',18);
else
  set(obj.echowin_maps(echowin_idx).h_text,'Position',[new_xdata(1),new_ydata(1)], ...
    'String',sprintf('%d',src.h_fig.Number),'FontSize',18);
end

% Update map limits if necessary
if get(obj.top_panel.trackCB,'Value')
  [changed,pos] = obj.compute_new_map_limits(new_xdata,new_ydata);
  if changed
    obj.query_redraw_map(pos(1),pos(2),pos(3),pos(4));
  end
end

return;
