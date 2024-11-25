function [gps,error_flag,monotonic_idxs] = gps_force_monotonic(gps)
% [gps,error_flag] = gps_force_monotonic(gps)
%
% Check gps structure for non-monotonically increasing GPS time and return
% a corrected gps structure.
%
% Author: John Paden
%
% See also read_gps_*.m, gps_plot.m, gps_create.m, gps_force_monotonic.m

error_flag = false;

if isempty(gps.gps_time)
  return;
end

%% Sort records according to gps.gps_time
[~,sort_idxs] = sort(gps.gps_time);
if any(sort_idxs ~= 1:length(sort_idxs))
  warning('GPS time is not monotonically increasing. Manual inspection is suggested. May need to run gps_force_monotonic.m in gps_create_SEASON.m for this particular file.');
  gps.gps_time = gps.gps_time(sort_idxs);
  gps.lat = gps.lat(sort_idxs);
  gps.lon = gps.lon(sort_idxs);
  gps.elev = gps.elev(sort_idxs);
  if isfield(gps,'roll')
    gps.roll = gps.roll(sort_idxs);
  end
  if isfield(gps,'pitch')
    gps.pitch = gps.pitch(sort_idxs);
  end
  if isfield(gps,'heading')
    gps.heading = gps.heading(sort_idxs);
  end
  if isfield(gps,'radar_time')
    gps.radar_time = gps.radar_time(sort_idxs);
  end
  if isfield(gps,'comp_time')
    gps.comp_time = gps.comp_time(sort_idxs);
  end
  if isfield(gps,'profileCntr')
    gps.profileCntr = gps.profileCntr(sort_idxs);
  end
  error_flag = true;
end

%% Remove nonmonotonically increasing records from gps.gps_time
good_mask = [true, (diff(gps.gps_time) > 0)];

if ~all(good_mask)
  warning('GPS time has repeated records. Manual inspection is suggested. May need to run gps_force_monotonic.m in gps_create_SEASON.m for this particular file.');
  
  gps.gps_time = gps.gps_time(good_mask);
  gps.lat = gps.lat(good_mask);
  gps.lon = gps.lon(good_mask);
  gps.elev = gps.elev(good_mask);
  if isfield(gps,'roll')
    gps.roll = gps.roll(good_mask);
  end
  if isfield(gps,'pitch')
    gps.pitch = gps.pitch(good_mask);
  end
  if isfield(gps,'heading')
    gps.heading = gps.heading(good_mask);
  end
  if isfield(gps,'radar_time')
    gps.radar_time = gps.radar_time(good_mask);
  end
  if isfield(gps,'comp_time')
    gps.comp_time = gps.comp_time(good_mask);
  end
  if isfield(gps,'profileCntr')
    gps.profileCntr = gps.profileCntr(good_mask);
  end
  error_flag = true;
end
monotonic_idxs = sort_idxs(good_mask);

%% Remove nonmonotonically increasing records from gps.radar_time
if isfield(gps,'radar_time') && any(~isnan(gps.radar_time))
  [~,sort_idxs] = sort(gps.radar_time);
  if any(sort_idxs ~= 1:length(sort_idxs))
    warning('Radar time is not monotonically increasing. Manual inspection is suggested.');
    error_flag = true;
  end

  good_mask = [true, (diff(gps.radar_time) > 0)];
  
  if ~all(good_mask)
    warning('radar_time has repeated records. Manual inspection is suggested. May need to run gps_force_monotonic.m in gps_create_SEASON.m for this particular file.');
    
    gps.gps_time = gps.gps_time(good_mask);
    gps.lat = gps.lat(good_mask);
    gps.lon = gps.lon(good_mask);
    gps.elev = gps.elev(good_mask);
    if isfield(gps,'roll')
      gps.roll = gps.roll(good_mask);
    end
    if isfield(gps,'pitch')
      gps.pitch = gps.pitch(good_mask);
    end
    if isfield(gps,'heading')
      gps.heading = gps.heading(good_mask);
    end
    gps.radar_time = gps.radar_time(good_mask);
    if isfield(gps,'comp_time')
      gps.comp_time = gps.comp_time(good_mask);
    end
    if isfield(gps,'profileCntr')
      gps.profileCntr = gps.profileCntr(good_mask);
    end
    error_flag = true;
  end
  
  monotonic_idxs = monotonic_idxs(good_mask);
end

end
