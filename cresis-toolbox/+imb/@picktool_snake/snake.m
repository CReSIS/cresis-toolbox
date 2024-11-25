function vals = snake(obj,image_c,image_x,image_y,x_old,y_old,x_new)
%
% Snake layer tracking tool .
%
% Author: John Paden

%% Get search range from tool param window
rbin_range_str = get(obj.top_panel.snake_rangeTB,'String');
try
  % Assumes the value entered is a matlab expression that can be evaluated
  search_range = eval(sprintf('[%s]', rbin_range_str));
  if length(search_range) == 1
    search_range = -search_range:search_range;
  else
    search_range = round(min(search_range)):round(max(search_range));
  end
catch ME
  warning('Search range parameter is not valid, using default range');
  search_range = -5:5;
end

if isempty(search_range)
  search_range = -5:5;
end

%% Fill "snake" tools structure and then call
for idx = 1:length(x_old)
  dataPnts(idx).row = round(interp1(image_y, ...
    1:length(image_y),y_old(idx),'linear','extrap'));
  dataPnts(idx).col = round(interp1(image_x, ...
    1:length(image_x),x_old(idx),'linear','extrap'));
  dataPnts(idx).method = 's';
  dataPnts(idx).snake.search_range = search_range;
  dataPnts(idx).start = false;
  dataPnts(idx).stop = false;
end
dataPnts(1).start = true;
dataPnts(end).stop = true;

% Debug Code to plot points that are passed in:
% figure; clf;
% imagesc(image_c);
% hold on
% for idx = 1:length(x_old)
%   plot(dataPnts(idx).col,dataPnts(idx).row,'.k');
% end
% hold off;

layer = tracker_snake(image_c,dataPnts);

vals = interp1(1:length(image_y),...
 image_y,layer,'linear','extrap');

vals = interp1(image_x,vals,x_new,'linear');
