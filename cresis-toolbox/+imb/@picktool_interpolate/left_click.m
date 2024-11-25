function cmds = left_click(obj,param)

%% Get search range from tool param window
rbin_range_str = get(obj.panel.manual_rangeTB,'String');
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

param.search_range = search_range;
cmds = insert_pnt(obj,param);

return
