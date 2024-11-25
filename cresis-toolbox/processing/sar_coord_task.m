function [success] = sar_coord_task(param)
% [success] = sar_coord_task(param)
%
% Creates the SAR coordinate system for the entire segment.
%
% Authors: John Paden
%
% Example:
%  See run_sar.m for how to run this function directly.
%  Normally this function is called from master.m using the param spreadsheet.
%
% See also: run_master.m, master.m, run_sar.m, sar.m, sar_task.m,
%   sar_coord_task.m

%% Setup processing
% =====================================================================

% Get speed of light, dielectric of ice constants
physical_constants;
wgs84 = wgs84Ellipsoid('meters');

% Get the standard radar name
[~,~,radar_name] = ct_output_dir(param.radar_name);

% Load records file
records = records_load(param);
% Apply presumming
if param.sar.presums > 1
  records.lat = fir_dec(records.lat,param.sar.presums);
  records.lon = fir_dec(records.lon,param.sar.presums);
  records.elev = fir_dec(records.elev,param.sar.presums);
  records.roll = fir_dec(records.roll,param.sar.presums);
  records.pitch = fir_dec(records.pitch,param.sar.presums);
  records.heading = fir_dec(records.heading,param.sar.presums);
  records.gps_time = fir_dec(records.gps_time,param.sar.presums);
  records.surface = fir_dec(records.surface,param.sar.presums);
end

% Load surface from layerdata
tmp_param = param;
tmp_param.cmd.frms = [];
surf_layer = opsLoadLayers(tmp_param,param.sar.surf_layer);
if isempty(surf_layer.gps_time)
  records.surface(:) = 0;
elseif length(surf_layer.gps_time) == 1
  records.surface(:) = surf_layer.twtt;
else
  records.surface = interp_finite(interp1(surf_layer.gps_time,surf_layer.twtt,records.gps_time),0);
end

% SAR output directory
sar_coord_dir = ct_filename_out(param, param.sar.coord_path);

%% Collect waveform information into one structure
%  - This is used to break the frame up into chunks
% =====================================================================
[wfs,~] = data_load_wfs(setfield(param,'load',struct('imgs',{param.sar.imgs})),records);
param.radar.wfs = merge_structs(param.radar.wfs,wfs);

%% Create the along-track axes (used for structuring processing)
% This cannot be done in advance or asynchronously because it controls how
% the data will be broken into chunks. It usually only needs to be run one
% time though.
%
% sar_ref:
%   .orig: 3xNx matrix (3 by Nx, Nx = output positions)
%   .x: 3xNx matrix, along-track unit vector
%   .z: 3xNx matrix, up unit vector (orthgonal to x)
%     Note that y, left vector, can be computed as cross of z and x
%   .along_track: 1 by Nx vector
%   .pp: spline interpolation kernel for
% =====================================================================

Lsar = c/wfs(1).fc*(param.sar.Lsar.agl+param.sar.Lsar.thick/sqrt(er_ice))/(2*param.sar.sigma_x);

trajectory_param = struct('gps_source',records.gps_source, ...
  'season_name',param.season_name,'radar_name',param.radar_name,'rx_path', 0, ...
  'tx_weights', [], 'lever_arm_fh', param.radar.lever_arm_fh);

ref = trajectory_with_leverarm(records,trajectory_param);

along_track = geodetic_to_along_track(ref.lat,ref.lon,ref.elev,Lsar);
output_along_track = along_track(1) : param.sar.sigma_x : along_track(end);

surf_idxs = get_equal_alongtrack_spacing_idxs(along_track,param.sar.sigma_x);
if surf_idxs(end) ~= length(along_track)
  if along_track(end) == along_track(surf_idxs(end))
    % Overwrite last index if it is in the same location as the last
    % record. This happens if the platform is stationary at the end.
    surf_idxs(end) = length(along_track);
  else
    % Normally, the last record is a little further along than the last
    % surf_idxs and so we append the last record to the end
    surf_idxs(end+1) = length(along_track);
  end
end

frame_length = round(param.sar.surf_filt_dist / median(diff(along_track(surf_idxs)))/2)*2+1;
if length(surf_idxs) < frame_length
  if mod(length(surf_idxs),2) == 0
    % Even length(surf_idxs), but sgolayfilt filter must be odd length
    surf = sgolayfilt(records.surface(surf_idxs),min(3,length(surf_idxs)-2),length(surf_idxs)-1);
  else
    surf = sgolayfilt(records.surface(surf_idxs),min(3,length(surf_idxs)-1),length(surf_idxs));
  end
else
  surf = sgolayfilt(records.surface(surf_idxs),3,frame_length);
end

SAR_coord_param.type = param.sar.mocomp.type;
SAR_coord_param.squint = [0 0 -1].';
SAR_coord_param.Lsar = Lsar;
fcs = SAR_coord_system(SAR_coord_param,ref,ref,along_track,output_along_track);

sar = [];
sar.file_version = '1';
sar.file_type = 'sar_coord';
sar.Lsar = Lsar;
sar.gps_source = records.gps_source;
sar.gps_time_offset = records.param_records.records.gps.time_offset;
sar.type = param.sar.mocomp.type;
sar.sigma_x = param.sar.sigma_x;
sar.presums = param.sar.presums;
sar.along_track = along_track;
sar.surf_pp = spline(along_track(surf_idxs),surf);
sar.origin = fcs.origin;
sar.x = fcs.x;
sar.z = fcs.z;
sar.roll = fcs.roll;
sar.pitch = fcs.pitch;
sar.heading = fcs.heading;
sar.gps_time = fcs.gps_time;

sar_fn = fullfile(sar_coord_dir,'sar_coord.mat');
sar_fn_dir = fileparts(sar_fn);
if ~exist(sar_fn_dir,'dir')
  mkdir(sar_fn_dir);
end
fprintf('Saving SAR coord %s (%s)\n', sar_fn, datestr(now));
if param.ct_file_lock
  file_version = '1L';
else
  file_version = '1';
end
file_type = 'sar_coord';
ct_save(sar_fn,'-struct','sar','Lsar','gps_source','gps_time_offset','type','sigma_x','presums','surf_pp','along_track','origin','x','z','roll','pitch','heading','gps_time','file_version','file_type');

fprintf('%s done %s\n', mfilename, datestr(now));

success = true;
