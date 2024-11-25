function cmds = left_click(obj,param)
% cmds = left_click(obj,param)
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

% Find x and y limits
xlims = sort(image_x([1 end]));
ylims = sort(image_y([1 end]));

% Check to make sure selection box is valid
if all(x < xlims(1)) || all(x > xlims(2))
  % button down and button up outside x-axis limits so ignore
  return
end

% Clip selection point to image limits
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

% Compute statistics for range line and value of selected point
data = param.image_c(:,x_idxs);
frame_stat_str  = sprintf('Frame_ID    \t%s\n', frm_str);
x_lim_str       = sprintf('x_value     \t%g\n', x);
y_lim_str       = sprintf('y_value     \t%g\n', y);
cur_val_str     = sprintf('Cur_value   \t%g\n',data(y_idxs));
max_str         = sprintf('Min_value   \t%g\n',nanmax(data));
min_str         = sprintf('Max_value   \t%g\n',nanmin(data));
mean_str        = sprintf('Mean_value  \t%g\n',10*log10(nanmean(10.^(data./10))));
median_str      = sprintf('Median_value\t%g\n',nanmedian(data));
fprintf([frame_stat_str x_lim_str y_lim_str cur_val_str max_str min_str mean_str median_str]);
