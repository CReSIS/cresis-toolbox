function h_fig = get_figures(num_figs,visible_flag,user_data)
% get_figures(num_figs,visible_flag,user_data)
%
% Function for creating figures in a script that is likely to be called
% more than once and should use the same figures that it already created in
% a previous run if they still exist. The script will create any figures
% that do not already exist.
%
% num_figs: scalar integer that is greater than one that specifies the
%   number of figures to create.
% visible_flag: boolean (true for visible "on", false for visible "off"),
%   default is true.
% user_data: string to uniquely identify these figures (stored in UserData
%   field of Figure handle. Default is the name of the calling function if
%   it exists, otherwise it is the name of this function.

if nargin<2 || isempty(visible_flag)
  visible_flag = true;
end

if nargin<3 || isempty(user_data)
  user_data = dbstack;
  if length(user_data)>1
    user_data = user_data(2).name;
  else
    user_data = '';
  end
end

if visible_flag
  fig_visible = 'on';
else
  fig_visible = 'off';
end
try
  h_figs = get(0,'Children');
catch ME
  warning(ME.getReport);
  h_figs = [];
end

if num_figs <= 0
  h_fig = [];
  return;
end

fig_idx = 1;
fig_UserData = sprintf('%s:%d',user_data,fig_idx);
try
  match_fig_idx = find(strcmp(fig_UserData,{h_figs.UserData}),1);
catch
  match_fig_idx = [];
end
if isempty(match_fig_idx)
  h_fig = figure('Visible',fig_visible,'UserData',fig_UserData);
else
  h_fig = h_figs(match_fig_idx);
end

for fig_idx = 2:num_figs
  fig_UserData = sprintf('%s:%d',user_data,fig_idx);
  try
    match_fig_idx = find(strcmp(fig_UserData,{h_figs.UserData}),1);
  catch
    match_fig_idx = [];
  end
  if isempty(match_fig_idx)
    h_fig(fig_idx) = figure('Visible',fig_visible,'UserData',fig_UserData);
  else
    h_fig(fig_idx) = h_figs(match_fig_idx);
  end
end

set(h_fig,'Visible',fig_visible);


