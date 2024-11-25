function [lat,lon,gps_time,frm_id,elev,surf,bottom,quality,frm_info,gps_source] = create_track_files(param,param_override)
% [lat,lon,gps_time,frm_id,elev,surf,bottom,quality,frm_info,gps_source] = create_track_files(param,param_override)
%
% Return tracks file information including lat, lon. See
% imb.run_all_create_track_files. The imb.picker loads this file when
% plotting flightlines without OPS. Loading all the individual
% CSARP_layerData files would be slow so this helps speed up the loading in
% imb.picker (and potentially other programs).
%
% param = struct with processing parameters
% param_override = parameters in this struct will override parameters
%         in param.  This struct must also contain the gRadar fields.
%         Typically global gRadar; param_override = gRadar;
%
% param.day_seg
% param.create_track_files.layer_params: opsLoadLayers struct
%   array which should define the loading of two layers. The first layer
%   should be the surface and the second layer should be the bottom.
%
% Outputs:
%
% These variables are all 1 by Nx vectors of the same length, segments are
% terminated with NaN and all segments are included in these Nx length
% vectors:
%   bottom: ice bottom two way travel time in seconds
%   elev: elevation in meters
%   frm_id: full frame ID 2019020401123
%   gps_time: GPS time in ANSI-C standard (seconds since Jan 1, 1970)
%   lat: latitude in degrees
%   lon: longitude in degrees
%   surf: ice surface two way travel time in seconds
%   quality: integer enumeration of bottom quality, 1=good, 2=moderate,
%     3=poor or derived from another source
%  frm_info: structure containing frame information
%    .frm_id: Nfrm element vector of frame IDs
%    .start_gps_time: Nfrm element vector of start GPS times for each frame
%    .stop_gps_time: Nfrm element vector of stop GPS times for each frame
%
% Author: John Paden, Rohan Choudhari
%
% See also: imb.run_all_create_track_files.m,
% imb.create_track_files.m

%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

% fprintf('=====================================================================\n');
% fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
% fprintf('=====================================================================\n');

%% Reading layer data
% =====================================================================
try
  layer = opsLoadLayers(param,param.create_track_files.layer_params);
catch ME
  rethrow(ME);
end

if isempty(layer)
  error('%s\tno_layers_returned!!!', param.day_seg);
end

if isempty(layer(1).gps_time)
  error('%s\tempty_layer!!!', param.day_seg);
end

if any(isnan(layer(1).twtt))
  fprintf('%s\tsurface_NaN!!!\t%d\t%d\n', param.day_seg, sum(isnan(layer(1).twtt)), length(layer(1).twtt));
end

% Checking for inconsistent field lengths
if length(layer(1).lat) ~= length(layer(1).lon) ...
    || length(layer(1).lat) ~= length(layer(1).gps_time) ...
    || length(layer(1).lat) ~= length(layer(1).frm) ...
    || length(layer(1).lat) ~= length(layer(1).elev) ...
    || length(layer(1).lat) ~= length(layer(1).twtt) ...
    || length(layer(1).lat) ~= length(layer(2).twtt) ...
    || length(layer(1).lat) ~= length(layer(2).quality)
  warning('%s\tLength of fields in layer files are not matched. This should never happen and indicates corrupt layer data files.\n');
  keyboard;
  return;
end

%% Loading frames and records files
% =====================================================================
frames = frames_load(param);
records = records_load(param,'gps_time','gps_source'); % loads "gps_time", "gps_source" variables

%% Create outputs
% =====================================================================

lat = layer(1).lat;
lon = layer(1).lon;
gps_time = layer(1).gps_time;
% Store full frame ID number 20190204_01_003 --> 2019020401003
frm_id = str2num(param.day_seg([1:8,10:11]))*1000+layer(1).frm;
elev = layer(1).elev;
surf = layer(1).twtt;
bottom = layer(2).twtt;
quality = layer(2).quality;
if isfield(records,'gps_source')
  gps_source = records.gps_source;
else
  gps_source = '';
end

% Store frame GPS time boundaries
frm_info.frm_id = str2num(param.day_seg([1:8,10:11]))*1000+(1:length(frames.frame_idxs));
frm_info.start_gps_time = records.gps_time(frames.frame_idxs);
frm_info.stop_gps_time = [records.gps_time(frames.frame_idxs(2:end)) records.gps_time(end)];
