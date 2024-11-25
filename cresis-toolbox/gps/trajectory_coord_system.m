function [est_heading,along_track,speed,origin,x,y,z,pos] = trajectory_coord_system(gps)
% [est_heading,along_track,speed,origin,x,y,z,pos] = trajectory_coord_system(gps)

physical_constants; % Load WGS84.spheroid

%% Along-track vector
along_track = geodetic_to_along_track(gps.lat,gps.lon,gps.elev);
rlines = get_equal_alongtrack_spacing_idxs(along_track,40);

%% Loop to calculate trajectory every 40 meters
est_heading = zeros(1,length(gps.lat));
x = zeros(3,length(gps.lat));
y = zeros(3,length(gps.lat));
z = zeros(3,length(gps.lat));
clear origin heading east north up;
for rline_idx = 1:length(rlines)-1
  rline = rlines(rline_idx);
  if rline_idx < length(rlines)
    rline_end = rlines(rline_idx+1);
  else
    rline_end = length(along_track);
  end
  
  %% Estimate heading
  [origin(1),origin(2),origin(3)] = geodetic2ecef(WGS84.spheroid,gps.lat(rline),gps.lon(rline),gps.elev(rline));
  [heading(1),heading(2),heading(3)] = geodetic2ecef(WGS84.spheroid,gps.lat(rline_end),gps.lon(rline_end),gps.elev(rline_end));
  heading = heading - origin;
  % Determine east vector
  [east(1) east(2) east(3)] = enu2ecef(1,0,0,gps.lat(rline),gps.lon(rline),gps.elev(rline),WGS84.spheroid);
  east = east - origin;
  % Determine north vector
  [north(1) north(2) north(3)] = enu2ecef(0,1,0,gps.lat(rline),gps.lon(rline),gps.elev(rline),WGS84.spheroid);
  north = north - origin;
  % Determine up vector
  [up(1) up(2) up(3)] = enu2ecef(0,0,1,gps.lat(rline),gps.lon(rline),gps.elev(rline),WGS84.spheroid);
  up = up - origin;
  % Determine heading (North is zero, positive towards east)
  est_heading(rline:rline_end) = pi/2-atan2(dot(north,heading),dot(east,heading));
  
  %% Create local trajectory coordinate system: x,y,z
  % Matches standard SAR coordinate system:
  % x along-track
  % y pointing left
  % z pointing up
  x_vec = heading(:)/norm(heading);
  z_vec = up(:) - x_vec*dot(up(:),x_vec);
  z_vec = z_vec/norm(z_vec);
  y_vec = cross(z_vec,x_vec);
  x(:,rline:rline_end) = repmat(x_vec,[1 rline_end-rline+1]);
  y(:,rline:rline_end) = repmat(y_vec,[1 rline_end-rline+1]);
  z(:,rline:rline_end) = repmat(z_vec,[1 rline_end-rline+1]);
end

%% Complete local coordinate system: origin, pos
origin = zeros(3,length(gps.lat));
[origin(1,:),origin(2,:),origin(3,:)] = geodetic2ecef(WGS84.spheroid,gps.lat,gps.lon,gps.elev);
pos = zeros(3,length(gps.lat));

%% Calculate speed and interpolate heading through low-speed sections
if isfield(gps,'gps_time')
  speed = diff(along_track)./diff(gps.gps_time);
  speed(end+1) = speed(end);
else
  speed = nan(size(along_track));
end

% Don't trust heading when speed is too low
est_heading(speed < 0.5) = NaN;
est_heading = interp_finite(est_heading,0,@gps_interp1);
