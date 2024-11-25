% script gps_create_2020_arctic_Polar6
%
% Makes the GPS files for 2020_Arctic_Polar6 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2020_Arctic_Polar6');
if ~exist(gps_path,'dir')
  fprintf('Making directory %s\n', gps_path);
  fprintf('  Press a key to proceed\n');
  pause;
  mkdir(gps_path);
end

if isempty(data_support_path)
  data_support_path = gRadar.data_support_path;
end

debug_level = 1;

in_base_path = fullfile(data_support_path,'2020_Arctic_Polar6');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_flag = {}; sync_fns = {}; sync_file_type = {}; sync_params = {};

gps_source_to_use = 'NMEA';

if strcmpi(gps_source_to_use,'NMEA')
  % =======================================================================
  % NMEA
  % =======================================================================
 
  file_idx = file_idx + 1;
  year = 2020; month = 2; day = 6; nmea_day_of_first_line_in_file = 5;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path, 'nmea', ...
    sprintf('%04d%02d%02d',year,month,day)),'GPS_','','.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',nmea_day_of_first_line_in_file,'format',1,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 0;
  
elseif strcmpi(gps_source_to_use,'AWI_final')

end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

%% No GPS Data Available: Fakes GPS position information
match_idx = strmatch('gps_20160331.mat',out_fns,'exact');
if ~isempty(match_idx)
  gps_fn = fullfile(gps_path,out_fns{match_idx});
  fprintf('Creating fake gps data for %s\n', gps_fn);
  gps = load(gps_fn);
  gps.gps_time = datenum_to_epoch(datenum(2016,3,31) + (50000:65000)/86400);
  gps.lon = -45 * ones(size(gps.gps_time));
  gps.lat = 70 + (1:length(gps.gps_time)) * 6e-4;
  gps.elev = 500 * ones(size(gps.gps_time));
  gps.roll = zeros(size(gps.gps_time));
  gps.pitch = zeros(size(gps.gps_time));
  gps.heading = zeros(size(gps.gps_time));
  save(gps_fn,'-append','-struct','gps','gps_time','lat','lon','elev','roll','pitch','heading');
end
   
   

