function cmds = left_click_and_drag(obj,param)
% cmds = left_click_and_drag(obj,param)
%
% imb.picker statistics tool
%
% Does not return any commands.
%
% Author: Dhagash Kapadia, John Paden

% General setup
image_x = param.image_x;
image_y = param.image_y;

x = param.x;
y = param.y;
cmds = [];

% Get Tool Params statistics method
stat_idx = get(obj.panel.stat_modePM,'Value');

% Find x and y limits
xlims = sort(image_x([1 end]));
ylims = sort(image_y([1 end]));

% Check to make sure selection box is valid
if all(x < xlims(1)) || all(x > xlims(2))
  % button down and button up outside x-axis limits so ignore
  return
end

% Clip selection box to image limits
x(x<xlims(1)) = xlims(1);
x(x>xlims(2)) = xlims(2);
y(y<ylims(1)) = ylims(1);
y(y>ylims(2)) = ylims(2);

% Find image indices
x_idxs = sort(interp1(image_x,1:length(image_x),x,'nearest','extrap'));
y_idxs = sort(interp1(image_y,1:length(image_y),y,'nearest','extrap'));

% Create frame ID string
cur_frm = num2str(find(param.echowin.eg.image_gps_time(x_idxs(1)) >= param.echowin.eg.start_gps_time,1,'last'));
if isempty(cur_frm)
  cur_frm = num2str(1);
end
frm_str = strcat(param.echowin.eg.cur_sel.day_seg,'_',cur_frm);

% Extract the region of interest
data = param.image_c(y_idxs(1):y_idxs(end),x_idxs(1):x_idxs(2));

% Run the selected Tool Params statistics method selected by user
if stat_idx == 1
  % Overall Statistics
  data = data(:);
  frame_stat_str  = sprintf('Frame_ID    \t%s\n', frm_str);
  x_lim_str       = sprintf('x_limits    \t%g\t%g\n', x);
  y_lim_str       = sprintf('y_limits    \t%g\t%g\n', y);
  max_str         = sprintf('Min_value   \t%g\n',nanmax(data));
  min_str         = sprintf('Max_value   \t%g\n',nanmin(data));
  mean_str        = sprintf('Mean_value  \t%g\n',10*log10(nanmean(10.^(data./10))));
  median_str      = sprintf('Median_value\t%g\n',nanmedian(data));
  fprintf([frame_stat_str x_lim_str y_lim_str max_str min_str mean_str median_str]);
  
elseif stat_idx == 2
  % Histogram
  obj.h_fig_stat(end+1) = figure;
  clf(obj.h_fig_stat(end));
  h_axes(1) = axes('parent',obj.h_fig_stat(end));
  histogram(h_axes(1),data,max(round(0.01*numel(data)),10));
  title(h_axes(1),sprintf('%s x %g-%g y %g-%g',frm_str,x(1),x(2),y(1),y(2)),'interpreter','none');
  xlabel('Relative power (dB)');
  ylabel(sprintf('Frequency (counts out of %g)',numel(data)));
  
elseif stat_idx == 3
  % Line by Line Statistics
  obj.h_fig_stat(end+1) = figure;
  clf(obj.h_fig_stat(end));
  h_axes(1) = axes('parent',obj.h_fig_stat(end));
  rlines = image_x(x_idxs(1):x_idxs(2));
  plot(h_axes(1),rlines,nanmax(data));
  hold(h_axes(1),'on')
  plot(h_axes(1),rlines,nanmin(data));
  plot(h_axes(1),rlines,10*log10(nanmean(10.^(data./10))));
  plot(h_axes(1),rlines,nanmedian(data));
  xlabel(param.echowin.eg.x_label)
  ylabel('Relative power (dB)')
  title(h_axes(1),sprintf('%s x %g-%g y %g-%g',frm_str,x(1),x(2),y(1),y(2)),'interpreter','none');
  legend('Max', 'Min', 'Mean', 'Median')
end
