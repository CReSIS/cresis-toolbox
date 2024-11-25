function [h_axes] = link_figures(h_fig,option)
% [h_axes] = link_figures(h_fig,option)
%
% Function for conveniently linking all the axes of a set of figures. The
% figures can be referenced by their double value (e.g. 1,2,3) or by their
% Matlab object handle.
%
% h_fig: list of figures (either double array or Matlab figure objects
% option: optional argument passed to linkaxes, default is 'xy'
%
% Author: John Paden
%
% See also: linkaxes.m

if ~exist('h_fig','var') || isempty(h_fig)
  h_fig = get(0,'Children');
end
if ~exist('option','var') || isempty(option)
  option = 'xy';
end

% Get all the axes children of each figure that is passed in
h_axes = [];
for fig_idx = 1:length(h_fig)
  try
    h_children = get(h_fig(fig_idx),'children');
    for child_idx = 1:length(h_children)
      if isa(h_children(child_idx),'matlab.graphics.axis.Axes')
        h_axes(end+1) = h_children(child_idx);
      end
    end
  end
end

% Link them all together
linkaxes(h_axes,option);
