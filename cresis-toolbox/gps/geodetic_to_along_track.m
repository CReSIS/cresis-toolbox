function [along_track,lat_filt,lon_filt,elev_filt] = geodetic_to_along_track(lat,lon,elev,spacing)
% [along_track,lat_filt,lon_filt,elev_filt] = geodetic_to_along_track(lat,lon,elev,spacing)
%
% Converts geodetic (lat,lon,elev) in WGS-84 into along-track. The distance
% between each point is cumulated to create the along_track vector.
% Used by functions like csarp.m.
%
% lat,lon in degrees
% elev in meters (optional, filled in with zeros if left empty or undefined)
% spacing: optional scalar argument. When specified and not empty, the geodetic
%   coordinates are decimated to a minimum along track spacing specified
%   by "spacing" using the get_equal_alongtrack_spacing_idxs.m function
%   and then all the samples are filled in using these decimated indices.
%   This is better for SAR processing and helps deal with the case when
%   gps errors are on the order of the sample spacing (e.g. due to very
%   slow moving trajectory).
%
% Author: John Paden
%
% See also: geodetic_to_along_track.m, get_equal_alongtrack_spacing_idxs.m

% Load WGS84 ellipsoid
physical_constants;

if isstruct(lat) && isfield(lat,'Latitude')
  elev = lat.Elevation;
  lon = lat.Longitude;
  lat = lat.Latitude;
end
if isstruct(lat) && isfield(lat,'lat')
  elev = lat.elev;
  lon = lat.lon;
  lat = lat.lat;
end

if ~exist('elev','var') || isempty(elev)
  elev = zeros(size(lat));
end

if isempty(lat)
  along_track = [];
  return;
elseif length(lat) == 1
  along_track = 0;
  return;
end

if ~exist('spacing','var') || isempty(spacing)
  % Cumulative sum for each step of motion
  [x,y,z] = geodetic2ecef(lat/180*pi,lon/180*pi,elev,WGS84.ellipsoid);
  if size(x,1) > 1
    along_track = [0; cumsum(sqrt(diff(x).^2 + diff(y).^2 + diff(z).^2))];
  else
    along_track = [0 cumsum(sqrt(diff(x).^2 + diff(y).^2 + diff(z).^2))];
  end
  lat_filt = lat;
  lon_filt = lon;
  elev_filt = elev;
else
  % Find the decimation indices
  %   Even indices are the center of the sections that we will use
  %   Odd indices define the boundaries of which points contribute to the
  %   even points during averaging
  decim_idxs = get_equal_alongtrack_spacing_idxs( ...
    struct('lat',lat,'lon',lon,'elev',elev),spacing/2);
  physical_constants;
  [ecef(1,:),ecef(2,:),ecef(3,:)] = geodetic2ecef(lat/180*pi,lon/180*pi,elev,WGS84.ellipsoid);
  if length(decim_idxs) < 2
    decim_idxs = [1 length(lat)];
  end
  % If odd length, then just truncate to even length
  if mod(length(decim_idxs),2)
    decim_idxs = decim_idxs(1:end-1);
  end
  
  %% Preallocate outputs
  along_track = zeros(size(lat));
  filt_ecef = zeros(3,numel(lat));
  
  %% Find averaged positions for each section
  pnt_ecef = zeros(3,length(decim_idxs));
  for decim_idxs_idx = 2:2:length(decim_idxs)
    % Start index of averaging
    start_idx = decim_idxs(decim_idxs_idx-1);

    % Stop index of averaging
    if decim_idxs_idx >= length(decim_idxs)-1
      stop_idx = length(lat);
    else
      stop_idx = decim_idxs(decim_idxs_idx+1)-1;
    end
        
    pnt_ecef(:,decim_idxs_idx) = mean(ecef(:,start_idx:stop_idx),2);
  end
  
  %% Find along-track value for every point for each section
  for decim_idxs_idx = 2:2:length(decim_idxs)
    
    % Determine range of along-track positions we will be filling in
    if decim_idxs_idx == 2
      start_idx = 1;
    else
      start_idx = decim_idxs(decim_idxs_idx);
    end
    if decim_idxs_idx == length(decim_idxs)
    	stop_idx = length(lat);
    else
      stop_idx = decim_idxs(decim_idxs_idx+2);
    end
    
    % Determine which points will be used for the line fit
    if length(decim_idxs) >= 4
      if decim_idxs_idx == length(decim_idxs)
        % Last point does not have a next point, so we use the previous
        % point instead
        start_pnt = decim_idxs_idx-2;
        stop_pnt = decim_idxs_idx;
      else
        start_pnt = decim_idxs_idx;
        stop_pnt = decim_idxs_idx+2;
      end
      % The origin and vector produce a line connecting two averaged positions
      ref_orig = [pnt_ecef(1,decim_idxs_idx); ...
        pnt_ecef(2,decim_idxs_idx); pnt_ecef(3,decim_idxs_idx)];
      ref_vector = [pnt_ecef(1,stop_pnt)-pnt_ecef(1,start_pnt); ...
        pnt_ecef(2,stop_pnt)-pnt_ecef(2,start_pnt); pnt_ecef(3,stop_pnt)-pnt_ecef(3,start_pnt)];
    else
      % This is a short track with only two points after decimation
      % (i.e. length(decim_idxs) == 2)
      
      % For the origin, we use the averaged position
      start_pnt = decim_idxs_idx;
      ref_orig = [pnt_ecef(1,decim_idxs_idx); ...
        pnt_ecef(2,decim_idxs_idx); pnt_ecef(3,decim_idxs_idx)];

      % For the direction vector, we just use the first and last point
      start_pnt = 1;
      stop_pnt = length(lat);
      ref_vector = [ecef(1,stop_pnt)-ecef(1,start_pnt); ...
        ecef(2,stop_pnt)-ecef(2,start_pnt); ecef(3,stop_pnt)-ecef(3,start_pnt)];
      ref_vector = ref_vector./sqrt(dot(ref_vector,ref_vector));
    end
    ref_vector = ref_vector./sqrt(dot(ref_vector,ref_vector));
    
    % Find the closest point on the line joining the two ~closest reference points
    % to the current point
    %  See equation 21.4.16 from section "Lines in Three Dimensions", Numerical Recipes

    % ref_orig (a) is origin of line joining two closest reference points
    % ref_vector (v) is unit vector connecting two closest reference points
    
    idxs = start_idx:stop_idx;
    offset_from_origin = dot([ecef(1,idxs)-ref_orig(1); ecef(2,idxs)-ref_orig(2); ecef(3,idxs)-ref_orig(3)], ...
      repmat(ref_vector,[1 length(idxs)]));
    filt_ecef(:,idxs) = bsxfun(@plus,ref_orig,bsxfun(@times,offset_from_origin,ref_vector));
    if start_idx == 1
      along_track(idxs) = offset_from_origin - offset_from_origin(1);
    else
      along_track(idxs) = along_track(start_idx) + offset_from_origin - offset_from_origin(1);
    end
  end
  [lat_filt,lon_filt,elev_filt] = ecef2geodetic(filt_ecef(1,:),filt_ecef(2,:),filt_ecef(3,:),WGS84.ellipsoid);
  lat_filt = lat_filt*180/pi;
  lon_filt = lon_filt*180/pi;

end

return;
