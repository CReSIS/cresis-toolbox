% script gps_create_2012_antarctica_GPRwais
%
% Makes the GPS files for 2012 Greenland P3 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2012_antarctica_GPRwais');
if ~exist(gps_path,'dir')
  fprintf('Making directory %s\n', gps_path);
  fprintf('  Press a key to proceed\n');
  pause;
  mkdir(gps_path);
end

if isempty(data_support_path)
  data_support_path = gRadar.data_support_path;
end

% ======================================================================
% User Settings
% ======================================================================
debug_level = 1;

in_base_path = fullfile(data_support_path,'2012_antarctica_GPRwais');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'NMEA';
if strcmpi(gps_source_to_use,'NMEA')
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'20120504NMEA_GPGGA.TXT');
  out_fns{file_idx} = 'gps_20120504.mat';
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',2012,'month',05,'day',04,'format',1,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120504','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',05,'day',04,'time_reference','utc','format',3);
  
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

