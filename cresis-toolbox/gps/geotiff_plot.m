function [proj,h_fig,h_axes,h_image,h_plot,h_plot_start] = geotiff_plot(geotiff_fn, lat, lon, h_fig, varargin)
% [proj,h_fig,h_axes,h_image,h_plot,h_plot_start] = geotiff_plot(geotiff_fn, lat, lon, h_fig, varargin)
%
% Function for quickly plotting a geotiff and optionally plotting
% some points/vectors on top of that.  The first point is plotted
% with 'bo'.
%
% Inputs:
%  h_fig: optional figure handle to use (leave empty or undeclared
%     if the function should generate the figure)
%  varargin: parameters are passed directly to plot for plotting the
%     latitude and longitude.
%
% Outputs:
%  proj: geotiff projection information to plot other points
%  h_fig: figure handle
%
% Examples:
%   geotiff_fn = ct_filename_gis('greenland/Landsat-7/mzl7geo_90m_lzw.tif');
%   geotiff_plot(geotiff_fn);
%
%   geotiff_fn = ct_filename_gis('world/NaturalEarth/NE2_HR_LC_SR_W_DR.tif');
%   geotiff_plot(geotiff_fn);
%
%   geotiff_fn = ct_filename_gis('antarctica/Landsat-7/Antarctica_LIMA_480m.tif');
%   geotiff_plot(geotiff_fn,Latitude,Longitude,'b-');
%
% Author: John Paden

% Get the projection information
proj = geotiffinfo(geotiff_fn);

% Read the image
switch lower(proj.ColorType)
  case {'indexed'}
    [X, CMAP, R] = geotiffread(geotiff_fn);
    error('Not supported.');
  otherwise
    [RGB, R, tmp] = geotiffread(geotiff_fn);
end
switch lower(proj.ModelType)
  case {'modeltypeprojected'}
    R = R/1e3; % Convert to km
  case {'modeltypegeographic'}
    R = R; % lat/lon in degrees
  otherwise
    error('Not supported.');
end
if size(RGB,3) == 3 && strcmp(class(RGB),'uint16') && max(RGB(:)) <= 255
  RGB = uint8(RGB);
end
if strcmpi(class(RGB),'int16') || strcmpi(class(RGB),'single')
  RGB = double(RGB);
end

if ~exist('h_fig','var') || isempty(h_fig)
  h_fig = figure;
  h_axes = axes('parent',h_fig);
else
  if isnumeric(h_fig(1)) && ~ishandle(h_fig(1))
    % User supplied a new figure number to use
    h_fig = figure(h_fig);
    h_axes = axes('parent',h_fig);
  elseif length(h_fig) == 1
    clf(h_fig);
    h_axes = axes('parent',h_fig);
  elseif length(h_fig) == 2
    h_axes = h_fig(2);
    h_fig = h_fig(1);
  end
end
if 0
  % DEBUG
  RGB(RGB<0) = NaN;
end
h_image = imagesc(R(3,1) + R(2,1)*(1:size(RGB,2)), R(3,2) + R(1,2)*(1:size(RGB,1)), RGB,'parent',h_axes);
if isa(RGB,'uint8')
  colormap(h_axes,gray(256));
end
set(h_axes,'YDir','normal');

h_plot = [];
h_plot_start = [];
if exist('lat','var') && ~isempty(lat)
  switch lower(proj.ModelType)
    case {'modeltypeprojected'}
      [X,Y] = projfwd(proj,lat,lon);
      X = X/1e3;
      Y = Y/1e3;
    case {'ModelTypeGeographic'}
      X = lon;
      Y = lat;
  end
  cur_hold = ishold(h_axes);
  hold(h_axes,'on');
  h_plot = plot(h_axes,X,Y,varargin{:});
  h_plot_start = plot(h_axes,X(1),Y(1),'bo');
  if ~cur_hold
    hold(h_axes,'off');
  end
end
