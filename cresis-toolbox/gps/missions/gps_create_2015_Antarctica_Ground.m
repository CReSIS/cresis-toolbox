% script gps_create_2015_antarctica_Ground
%
% Makes the GPS files for 2015 Antarctica Ground field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2015_Antarctica_Ground');
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

in_base_path = fullfile(data_support_path,'2015_Antarctica_Ground');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'accum';

if strcmpi(gps_source_to_use,'accum')
  file_idx = file_idx + 1;
  year = 2015; month = 11; day = 20;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2015; month = 11; day = 21;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2015; month = 11; day = 24;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2015; month = 12; day = 2;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2015; month = 12; day = 3;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2015; month = 12; day = 4;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2015; month = 12; day = 9;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2015; month = 12; day = 10;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2015; month = 12; day = 16;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2015; month = 12; day = 18;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2015; month = 12; day = 20;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2015; month = 12; day = 21;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
  
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

%% Lab Measurement Data: Fakes GPS position information
% match_idx = strmatch('gps_20150413.mat',out_fns,'exact');
% if ~isempty(match_idx)
%   gps_fn = fullfile(gps_path,out_fns{match_idx});
%   fprintf('Creating fake gps data for %s\n', gps_fn);
%   gps = load(gps_fn);
%   gps.lon = -45 * ones(size(gps.lon));
%   gps.lat = 70 + (1:length(gps.gps_time)) * 1e-4;
%   save(gps_fn,'-append','-struct','gps','lat','lon');
% end

%% Conversion from GPS to UTC time since system was not allowed enough
% time to warm up before operation.
match_idx = strmatch('gps_20151202.mat',out_fns,'exact');
if ~isempty(match_idx)
  gps_fn = fullfile(gps_path,out_fns{match_idx});
  fprintf('Fixing GPS to UTC time conversion for %s\n', gps_fn);
  gps = load(gps_fn);
  gps.gps_time(1:340) = gps.gps_time(1:340) - utc_leap_seconds(gps.gps_time(1));
  gps.gps_time(5956:6036) = gps.gps_time(5956:6036) - utc_leap_seconds(gps.gps_time(1));
  gps.sync_gps_time(1:340) = gps.sync_gps_time(1:340) - utc_leap_seconds(gps.sync_gps_time(1));
  gps.sync_gps_time(5956:6036) = gps.sync_gps_time(5956:6036) - utc_leap_seconds(gps.gps_time(1));
  save(gps_fn,'-append','-struct','gps','gps_time','sync_gps_time');
end
match_idx = strmatch('gps_20151221.mat',out_fns,'exact');
if ~isempty(match_idx)
  gps_fn = fullfile(gps_path,out_fns{match_idx});
  fprintf('Fixing GPS to UTC time conversion for %s\n', gps_fn);
  gps = load(gps_fn);
  gps.gps_time(1:107) = gps.gps_time(1:107) - utc_leap_seconds(gps.gps_time(1));
  gps.sync_gps_time(1:107) = gps.sync_gps_time(1:107) - utc_leap_seconds(gps.sync_gps_time(1));
  save(gps_fn,'-append','-struct','gps','gps_time','sync_gps_time');
end

%% Filter NMEA data
for idx = 1:length(out_fns)
  gps_fn = fullfile(gps_path,out_fns{idx});
  fprintf('Filtering %s\n', gps_fn);
  gps = load(gps_fn);
  spacing = 10;
  [along_track,gps.lat,gps.lon,gps.elev] = geodetic_to_along_track(gps.lat,gps.lon,gps.elev,spacing);
  cur_along_track = along_track(1); cur_idx = 1;
  for idx = 2:length(along_track)
    if along_track(idx) <= cur_along_track
      gps.lat(idx) = gps.lat(cur_idx);
      gps.lon(idx) = gps.lon(cur_idx);
      gps.elev(idx) = gps.elev(cur_idx);
    else
      cur_along_track = along_track(idx);
      cur_idx = idx;
    end
  end
  save(gps_fn,'-append','-struct','gps','lat','lon','elev');
end
