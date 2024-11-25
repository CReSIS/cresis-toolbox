function wp = write_gps_sonntagsequence2(fn, wp, along_track_spacing_minimum, interp_method,dem_fn,constant_AGL_ft)
% wp = write_gps_sonntagsequence2(fn, wp, along_track_spacing_minimum, interp_method)
%
% Sonntag navigation software waypoint writer. This includes the option to
% oversample the flight track using the Mathworks Mapping toolbox interpm
% function.
% 
% See read_gps_sonntagsequence2 for details on the file format.
%
% Inputs:
% wp.name = A{1};
% wp.lat = A{2};
% wp.lon = A{3};
% wp.elev = A{4};
%
% Example:
%   wp = read_gps_sonntagsequence2('SAD_backup1.sequence2');
%   wp_over_sampled = write_gps_sonntagsequence2('SAD_backup1_OVER_SAMPLED.sequence2', wp);
%
% Author: John Paden
%
% See also: read_gps_sonntagsequence2.m, read_gps*.m

%% Input checks
if ~exist('along_track_spacing_minimum','var')
  along_track_spacing_minimum = 100000;
end

if ~exist('interp_method','var')
  interp_method = 'gc';
end

if ~exist('dem_fn','var')
  global gRadar;
  if wp.lat(1) < 0
    dem_fn = fullfile(gRadar.gis_path,'antarctica','DEM','REMA','REMA_1km_dem_filled.tif');
  else
    dem_fn = fullfile(gRadar.gis_path,'arctic','ArcticDEM','arcticdem_mosaic_500m_v3.0.tif');
  end
end

if ~exist('constant_AGL_ft','var')
  constant_AGL_ft = 2000;
end

% Earth Radius (m) from WGS-84 ellipsoid (larger: equatorial radius,
% smaller: polar radius)
% earthRadius = 0.5*(6378137+6356752.31424518);
earthRadius = 6.367444657122590e+06;

%% Interpolation
orig_lat = wp.lat;
orig_lon = wp.lon;
orig_name = wp.name;
% Interpolate
[wp.lat,wp.lon] = interpm(wp.lat,wp.lon,along_track_spacing_minimum/earthRadius*180/pi,'gc');
% Find original points
last_match_idx = 0;
for idx = 1:length(wp.lat)
  match_idx = find(wp.lat(idx) == orig_lat & wp.lon(idx) == orig_lon);
  if ~isempty(match_idx)
    % This is one of the original waypoints, so copy its name
    wp.name{idx} = orig_name{match_idx};
    sub_waypoint_idx = 0;
    last_match_idx = match_idx;
  elseif last_match_idx ~= 0
    sub_waypoint_idx = sub_waypoint_idx + 1;
    %wp.name{idx} = sprintf('%s_%03d', orig_name{last_match_idx}, sub_waypoint_idx);
    wp.name{idx} = '-';
  end
end


%% Load DEM
if ~isempty(dem_fn)
  [dem_RGB, dem_R, ~] = geotiffread(dem_fn);
  dem_proj = geotiffinfo(dem_fn);
  dem_x_axis = dem_R(3,1) + dem_R(2,1)*(1:size(dem_RGB,2));
  dem_y_axis = dem_R(3,2) + dem_R(1,2)*(1:size(dem_RGB,1));

  [dem_x,dem_y] = projfwd(dem_proj,wp.lat,wp.lon);
  elev_ground = double(interp2(dem_x_axis,dem_y_axis,dem_RGB,dem_x,dem_y));
  wp.elev = elev_ground + constant_AGL_ft*12*2.54/100;
end

%% Write file
fid = fopen(fn,'w');
for idx = 1:length(wp.name)
  fprintf(fid,'%s %f %f %.1f\n', wp.name{idx}, wp.lat(idx), wp.lon(idx), wp.elev(idx) * 100/2.54/12);
end
fclose(fid);
