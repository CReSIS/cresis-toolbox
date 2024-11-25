function yq = gps_interp1(xi,yi,xq,varargin)
% yq = gps_interp1(xi,yi,xq,varargin)
%
% Interpolates heading and longitude properly through 2*pi wraps.
%
% The data is assumed to be in radians!
%
% Examples:
% gps.lon = gps_interp1(old_gps_time, gps.lon/180*pi, new_gps_time)*180/pi;
% gps.heading = gps_interp1(old_gps_time, gps.heading, new_gps_time);

yi_x = cos(yi);
yi_y = sin(yi);
yq_x = interp1(xi, yi_x, xq, varargin{:});
yq_y = interp1(xi, yi_y, xq, varargin{:});
yq = atan2(yq_y,yq_x);
