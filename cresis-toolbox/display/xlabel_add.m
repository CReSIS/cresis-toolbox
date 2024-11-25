function add_x_labels(ha, xtl, titles, param)
% add_x_labels(ha, xtl, titles,font_size)
%
% Adds X-Tick labels (xtl) and titles in cell formats with optional font
% size designation to axes (ha). xtl and titles must have the same number
% of elements.
%
% INPUTS: 
%   ha: Handle of axes object to add label to
%   xtl: X-Tick Labels, usually ouput from create_standard_x_labels.m
%   titles: Cell array of titles describing the new x-tick labels
%   param
%     .font_size: Font size of new x-tick labels
%     .offset_percentage: Percentage of total y-axis value range to place
%     the new x-tick labels below the x-axis.
%
% Example: add_x_labels(ha(1),{'1';'2';'3'},{'title1','title2','title3'},struct('offset_percentage',0.02))
%
% Author: L. Smith - 10/27/09
%
% See also: create_standard_x_labels.m

matlab_ver = ver('matlab');
if str2double(matlab_ver.Version) >= 9.0
  narginchk(3,4);
else
  error(nargchk(3, 4, nargin, 'struct'))
end
if size(xtl{1},1) ~= length(titles)
  error('Must have the same number of labels and titles!')
end
if nargin == 3
  param.font_size = 8;
  param.offset_percent = 0.01;
elseif nargin == 4
  if ~isfield(param,'font_size')
    param.font_size = 8;
  end
  if ~isfield(param,'offset_percent')
    param.offset_percent = 0.01;
  end
end

x_ends = xlim(ha);
xpos = linspace(x_ends(1), x_ends(2), length(xtl));
ypos = get(ha,'YLim');
ydir = get(ha,'YDir');
if strcmpi(ydir,'normal')
  ybot = min(ypos);
  txt_offset = ybot - abs(diff(ypos)).*param.offset_percent;
else
  ybot = max(ypos);
  txt_offset = ybot + abs(diff(ypos)).*param.offset_percent;
end

set(ha,'XTickLabel',[]);
set(ha,'XTick',xpos);

ha_orig_units = get(ha,'Units');
set(ha,'Units','normalized');

for ii=1:length(xpos)
  ht = text('String',xtl{ii}, ...
    'VerticalAlignment', 'top', ...
    'HorizontalAlignment', 'center ', ...
    'FontSize', param.font_size, ...
    'Position',[xpos(ii) txt_offset],...
    'FontWeight','bold','parent',ha);
  
  ha_pos = get(ha,'Position');
  
  set(ht,'Units','normalized');
  ht_pos = get(ht,'Position');
  ht_pos(2) = 0;
  set(ht,'Position',ht_pos);
  
  ht_extent = get(ht,'Extent');
  
  % Convert extent to normalized figure coordinates
  ha_adjustment = ha_pos(2) + ht_extent(2)*ha_pos(4);
  
  hs_pos_4_orig = ha_pos(2) + ha_pos(4);
  ha_pos(2) = ha_pos(2) - ha_adjustment;
  ha_pos(4) = hs_pos_4_orig - ha_pos(2);
  set(ha,'Position',ha_pos)
end

ht = text('String',titles, ...
  'VerticalAlignment', 'top', ...
  'HorizontalAlignment', 'center ', ...
  'FontSize', param.font_size, ...
  'Position',[mean([xpos(1) xpos(end)]) txt_offset],...
  'FontWeight','bold','parent',ha);

ha_pos = get(ha,'Position');

set(ht,'Units','normalized');
ht_pos = get(ht,'Position');
ht_pos(2) = 0;
set(ht,'Position',ht_pos);

ht_extent = get(ht,'Extent');

% Convert extent to normalized figure coordinates
ha_adjustment = ha_pos(2) + ht_extent(2)*ha_pos(4);

hs_pos_4_orig = ha_pos(2) + ha_pos(4);
ha_pos(2) = ha_pos(2) - ha_adjustment;
ha_pos(4) = hs_pos_4_orig - ha_pos(2);
set(ha,'Position',ha_pos);

set(ha,'Units',ha_orig_units);

end