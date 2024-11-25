function [h_axes,clims] = link_caxis(h_fig,clims)
% [h_axes] = link_caxis(h_fig,clims)
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
if ~exist('clims','var') || isempty(clims)
  clims = [];
end

% Get all the axes children of each figure that is passed in
h_axes = [];
for fig_idx = 1:length(h_fig)
  h_children = get(h_fig(fig_idx),'children');
  for child_idx = 1:length(h_children)
    if isa(h_children(child_idx),'matlab.graphics.axis.Axes')
      h_axes(end+1) = h_children(child_idx);
    end
  end
end

if ~isempty(h_axes)
  % Set all caxis equal
  if isempty(clims)
    clims = caxis(h_axes(1));
  end
  clims = sort(clims);
  for axis_idx = 1:length(h_axes)
    caxis(h_axes(axis_idx),clims);
  end
end
