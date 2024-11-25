% script gps_create_2015_greenland_Ground
%
% Makes the GPS files for 2015 Greenland Ground field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2015_Greenland_Ground');
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

in_base_path = fullfile(data_support_path,'2015_Greenland_Ground');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'accum';

if strcmpi(gps_source_to_use,'accum')
  file_idx = file_idx + 1;
  year = 2015; month = 4; day = 30;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'gps/'),sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gps/'),sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2015; month = 5; day = 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'gps/'),sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gps/'),sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2015; month = 5; day = 2;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'gps/'),sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gps/'),sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2015; month = 5; day = 3;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'gps/'),sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gps/'),sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

%% Lab Measurement Data: Fakes GPS position information
match_idx = strmatch('gps_20150413.mat',out_fns,'exact');
if ~isempty(match_idx)
  gps_fn = fullfile(gps_path,out_fns{match_idx});
  fprintf('Creating fake gps data for %s\n', gps_fn);
  gps = load(gps_fn);
  gps.lon = -45 * ones(size(gps.lon));
  gps.lat = 70 + (1:length(gps.gps_time)) * 1e-4;
  save(gps_fn,'-append','-struct','gps','lat','lon');
end

%% Conversion from GPS to UTC time since system was not allowed enough
% time to warm up before operation.
match_idx = strmatch('gps_20150503.mat',out_fns,'exact');
if ~isempty(match_idx)
  gps_fn = fullfile(gps_path,out_fns{match_idx});
  fprintf('Fixing GPS to UTC time conversion for %s\n', gps_fn);
  gps = load(gps_fn);
  gps.gps_time(1:63) = gps.gps_time(1:63) - 16;
  save(gps_fn,'-append','-struct','gps','gps_time');
end
