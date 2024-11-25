function plot_update(obj)
% plot_update(obj)
%
% This function is called any time anything changes that requires an update
% in the ascope plot (change of order, new ascope, hide/visible, etc.)

% Update plot based on selection
set(obj.h_ascope(obj.ascope.selected),'Color','red');
set(obj.h_ascope(~obj.ascope.selected),'Color','black');

% Update plot based on visibility
set(obj.h_ascope(obj.ascope.visible),'Visible','on');
set(obj.h_ascope(~obj.ascope.visible),'Visible','off');
set(obj.h_cursor(obj.ascope.visible),'Visible','on');
set(obj.h_cursor(~obj.ascope.visible),'Visible','off');

first_plot = ~isfinite(obj.xlims(1));

% Update list box entries
LB_strings = cell(1,length(obj.ascope.echowin));
obj.xlims = [inf -inf];
obj.ylims = [inf -inf];
for idx = 1:length(obj.ascope.echowin)
  if isnan(obj.ascope.echowin(idx))
    echogram_str = '';
  else
    echogram_str = sprintf('%d: ',obj.ascope.echowin(idx));
  end
  if obj.ascope.visible(idx)
    LB_strings{idx} = sprintf('%s%s %s', ...
      echogram_str, obj.ascope.frm_str{idx},datestr(epoch_to_datenum(obj.ascope.gps_time(idx)),'HH:mm:SS'));
  else
    LB_strings{idx} = sprintf('<HTML><FONT color="red">%s%s %s</FONT></HTML>', ...
      echogram_str, obj.ascope.frm_str{idx},datestr(epoch_to_datenum(obj.ascope.gps_time(idx)),'HH:mm:SS'));
  end
  uistack(obj.h_ascope(idx),'bottom');
  uistack(obj.h_cursor(idx),'bottom');
  if obj.ascope.xlims{idx}(1) < obj.xlims(1)
    obj.xlims(1) = obj.ascope.xlims{idx}(1);
  end
  if obj.ascope.xlims{idx}(2) > obj.xlims(2)
    obj.xlims(2) = obj.ascope.xlims{idx}(2);
  end
  if obj.ascope.ylims{idx}(1) < obj.ylims(1)
    obj.ylims(1) = obj.ascope.ylims{idx}(1);
  end
  if obj.ascope.ylims{idx}(2) > obj.ylims(2)
    obj.ylims(2) = obj.ascope.ylims{idx}(2);
  end
end
set(obj.left_panel.ascopeLB,'String',LB_strings);
set(obj.left_panel.ascopeLB,'Value',find(obj.ascope.selected));

obj.ylims = [floor(obj.ylims(1)) ceil(obj.ylims(2))];

% Convert all x-limits to depth if needed
val = get(obj.left_panel.xaxisPM,'Value');
if val == 2
  physical_constants;
  % Depth in air for above the surface
  obj.xlims = obj.xlims/1e6 * c/2;
elseif val == 3
  physical_constants;
  % Depth in air for above the surface
  obj.xlims(obj.xlims<0) = obj.xlims(obj.xlims<0)/1e6 * c/2;
  % Depth in ice for below the surface
  obj.xlims(obj.xlims>0) = obj.xlims(obj.xlims>0)/1e6 * c/2/sqrt(er_ice);
end
if first_plot
  xlim(obj.h_axes, obj.xlims);
  ylim(obj.h_axes, obj.ylims);
end

notify(obj,'StateChange');

end
