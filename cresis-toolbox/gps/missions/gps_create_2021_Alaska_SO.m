
% script gps_create_2021_alaska_SO
%
% Makes the GPS files for 2021 Alaska SO field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2021_Alaska_SO');
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

in_base_path = fullfile(data_support_path,'2021_Alaska_SO');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

season_name = '2021_Alaska_SO';
% gps_source_to_use = 'NMEA';
gps_source_to_use = 'Lidar-traj';

if strcmpi(gps_source_to_use,'NMEA')
    
% year = 2021; month = 4; day = 20;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% date_str{file_idx} = '20210420';

% year = 2021; month = 5; day = 2;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% date_str{file_idx} = '20210502';

% year = 2021; month = 5; day = 3;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% date_str{file_idx} = '20210503';

% year = 2021; month = 5; day = 5;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% date_str{file_idx} = '20210505';

% year = 2021; month = 5; day = 6;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% date_str{file_idx} = '20210506';

% year = 2021; month = 5; day = 9;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% date_str{file_idx} = '20210509';

% year = 2021; month = 5; day = 10;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% date_str{file_idx} = '20210510';

% year = 2021; month = 5; day = 12;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% date_str{file_idx} = '20210512';

year = 2021; month = 5; day = 13;
file_idx = file_idx + 1;
in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
file_type{file_idx} = 'NMEA';
params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
gps_source{file_idx} = 'nmea-field';
sync_flag{file_idx} = 0;
date_str{file_idx} = '20210513';


elseif strcmpi(gps_source_to_use,'Lidar-traj')
    
%   year = 2021; month = 5; day = 2;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'lidar-final';
%   sync_flag{file_idx} = 0; 
%   date_str{file_idx} = '20210502';  

%   year = 2021; month = 5; day = 3;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'lidar-final';
%   sync_flag{file_idx} = 0; 
%   date_str{file_idx} = '20210503';  
  
%   year = 2021; month = 5; day = 5;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'lidar-final';
%   sync_flag{file_idx} = 0; 
%   date_str{file_idx} = '20210505';  
  
%   year = 2021; month = 5; day = 6;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'lidar-final';
%   sync_flag{file_idx} = 0; 
%   date_str{file_idx} = '20210506';  
%   
%   year = 2021; month = 5; day = 9;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'lidar-final';
%   sync_flag{file_idx} = 0; 
%   date_str{file_idx} = '20210509';  
%   
%   year = 2021; month = 5; day = 10;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'lidar-final';
%   sync_flag{file_idx} = 0; 
%   date_str{file_idx} = '20210510';  
%   
  year = 2021; month = 5; day = 12;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
  params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
  params{file_idx}.textscan = {};
  gps_source{file_idx} = 'lidar-final';
  sync_flag{file_idx} = 0; 
  date_str{file_idx} = '20210512';    
% 
%   year = 2021; month = 5; day = 13;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'lidar-final';
%   sync_flag{file_idx} = 0; 
%   date_str{file_idx} = '20210513';  
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

% Debug code that sets up special processing

hack_idx = cell2mat(strfind(out_fns,'gps_20210502.mat')); % snow radar data collected before LiDAR data, so need to combine radar NMEA and LiDAR gps times.
if ~isempty(hack_idx)
  out_fn = fullfile(gps_path,out_fns{hack_idx}); 
  gps = load(out_fn);
  gps_nmea = load(fullfile(gps_path,'NMEA_gps',out_fns{hack_idx}));
  append_idxs = find(gps_nmea.gps_time < gps.gps_time(1));
  gps.gps_time = [gps_nmea.gps_time(append_idxs),gps.gps_time];
  gps.lat = [gps_nmea.lat(append_idxs),gps.lat];
  gps.lon = [gps_nmea.lon(append_idxs),gps.lon];
  gps.elev = [gps_nmea.elev(append_idxs),gps.elev];
  gps.pitch = [gps_nmea.pitch(append_idxs),gps.pitch];
  gps.roll = [gps_nmea.roll(append_idxs),gps.roll];
  gps.heading = [gps_nmea.heading(append_idxs),gps.heading];
  gps.gps_source = 'lidar-final+NMEA';
  save(out_fn,'-append','-struct','gps');
end

hack_idx = cell2mat(strfind(out_fns,'gps_20210505.mat')); % snow radar data collected after LiDAR data, so need to combine radar NMEA and LiDAR gps times.
if ~isempty(hack_idx)
  out_fn = fullfile(gps_path,out_fns{hack_idx}); 
  gps = load(out_fn);
  gps_nmea = load(fullfile(gps_path,'NMEA_gps',out_fns{hack_idx}));
  append_idxs = find(gps_nmea.gps_time > gps.gps_time(end));
  gps.gps_time = [gps.gps_time,gps_nmea.gps_time(append_idxs)];
  gps.lat = [gps.lat,gps_nmea.lat(append_idxs)];
  gps.lon = [gps.lon,gps_nmea.lon(append_idxs)];
  gps.elev = [gps.elev,gps_nmea.elev(append_idxs)];
  gps.pitch = [gps.pitch,gps_nmea.pitch(append_idxs)];
  gps.roll = [gps.roll,gps_nmea.roll(append_idxs)];
  gps.heading = [gps.heading,gps_nmea.heading(append_idxs)];
  gps.gps_source = 'lidar-final+NMEA';
  save(out_fn,'-append','-struct','gps');
end

hack_idx = cell2mat(strfind(out_fns,'gps_20210512.mat')); % snow radar data collected after LiDAR data, so need to combine radar NMEA and LiDAR gps times.
if ~isempty(hack_idx)
  out_fn = fullfile(gps_path,out_fns{hack_idx}); 
  gps = load(out_fn);
  gps_nmea = load(fullfile(gps_path,'NMEA_gps',out_fns{hack_idx}));
  append_idxs = find(gps_nmea.gps_time > gps.gps_time(end));
  gps.gps_time = [gps.gps_time,gps_nmea.gps_time(append_idxs)];
  gps.lat = [gps.lat,gps_nmea.lat(append_idxs)];
  gps.lon = [gps.lon,gps_nmea.lon(append_idxs)];
  gps.elev = [gps.elev,gps_nmea.elev(append_idxs)];
  gps.pitch = [gps.pitch,gps_nmea.pitch(append_idxs)];
  gps.roll = [gps.roll,gps_nmea.roll(append_idxs)];
  gps.heading = [gps.heading,gps_nmea.heading(append_idxs)];
  gps.gps_source = 'lidar-final+NMEA';
  save(out_fn,'-append','-struct','gps');
end