% script gps_create_2017_antarctica_TObas
%
% Makes the GPS files for 2017 Antarctica TObas field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2017_Antarctica_TObas');
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

in_base_path = fullfile(data_support_path,'2017_Antarctica_TObas');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_flag = {}; sync_fns = {}; sync_file_type = {}; sync_params = {};

gps_source_to_use = 'bas';

if strcmpi(gps_source_to_use,'bas')
  %% BAS

  year = 2017; month = 1; day = 22;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'F31.ASC')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('time_reference','utc');
  params{file_idx}.format_str = '%f%f%f%f%f%f%f%f%f%f%f';
  params{file_idx}.types = {'date_datenum','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg','f4','f5','f6','f7'};
  params{file_idx}.textscan = {'delimiter',','};
  params{file_idx}.headerlines = 0;
  params{file_idx}.time_reference = 'utc';
  gps_source{file_idx} = 'bas-final201903';
  sync_flag{file_idx} = 0;

end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;
