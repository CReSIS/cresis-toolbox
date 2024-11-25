% script gps_create_2019_Antarctica_TObas
%
% Makes the GPS files for 2019 Antarctica TObas field season

%% Setup
% =========================================================================
tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2019_Antarctica_TObas');
if ~exist(gps_path,'dir')
  fprintf('Making directory %s\n', gps_path);
  fprintf('  Press a key to proceed\n');
  pause;
  mkdir(gps_path);
end

if isempty(data_support_path)
  data_support_path = gRadar.data_support_path;
end

in_base_path = fullfile(data_support_path,'2019_Antarctica_TObas');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_flag = {}; sync_fns = {}; sync_file_type = {}; sync_params = {};

%% <== CHOOSE WHICH GPS SOURCE TO PROCESS
% gps_source_to_use = 'arena';
gps_source_to_use = 'BAS';

if strcmpi(gps_source_to_use,'arena')
  %% ARENA GPS SOURCE
  % =======================================================================
  
  year = 2019; month = 9; day = 23;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'arena';
  params{file_idx} = struct('year',2019,'time_reference','utc');
  gps_source{file_idx} = 'arena-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');
  
  year = 2019; month = 12; day = 13;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'arena';
  params{file_idx} = struct('year',2019,'time_reference','utc');
  gps_source{file_idx} = 'arena-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');
  
%   year = 2019; month = 12; day = 15;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('year',2019,'time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2019; month = 12; day = 22;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('year',2019,'time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
  
%   year = 2019; month = 12; day = 25;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('year',2019,'time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2019; month = 12; day = 26;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('year',2019,'time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
  
%   year = 2019; month = 12; day = 29;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('year',2019,'time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2019; month = 12; day = 30;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('year',2019,'time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2020; month = 1; day = 25;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('year',2020,'time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
  
%   year = 2020; month = 1; day = 26;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('year',2020,'time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2020; month = 1; day = 27;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('year',2020,'time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2020; month = 1; day = 28;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('year',2020,'time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
  
elseif strcmpi(gps_source_to_use,'bas')
  %% BAS GPS SOURCE
  % =======================================================================
  
  % IMU worked fine
  year = 2019; month = 12; day = 15;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'GNSS_IMU','T01.txt')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f';
  params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg',...
    'elev_m','roll_deg','pitch_deg','heading_deg','f1','f2','f3','f4',...
    'f5','f6','f7'};
  params{file_idx}.textscan = {};
  params{file_idx}.headerlines = 34;
  gps_source{file_idx} = 'bas-final20200306';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');
  
  % IMU worked fine
  year = 2019; month = 12; day = 22;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'GNSS_IMU','T03.txt')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f';
  params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg',...
    'elev_m','roll_deg','pitch_deg','heading_deg','f1','f2','f3','f4',...
    'f5','f6','f7'};
  params{file_idx}.textscan = {};
  params{file_idx}.headerlines = 34;
  gps_source{file_idx} = 'bas-final20200306';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');
  
  % IMU worked fine for the first part of flight, processed to IMU
  year = 2019; month = 12; day = 25;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'GNSS_IMU','T06_IMU.txt')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d_imu.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f';
  params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg',...
    'elev_m','roll_deg','pitch_deg','heading_deg','f1','f2','f3','f4',...
    'f5','f6','f7'};
  params{file_idx}.textscan = {};
  params{file_idx}.headerlines = 34;
  gps_source{file_idx} = 'bas-final20200306';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');
  
  % IMU missing for latter part of flight, processed to GPS antenna
  year = 2019; month = 12; day = 25;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'GNSS_IMU','T06_GNSS.txt')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d_gnss.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f';
  params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg',...
    'elev_m','roll_deg','pitch_deg','heading_deg','f1','f2','f3','f4',...
    'f5','f6','f7'};
  params{file_idx}.textscan = {};
  params{file_idx}.headerlines = 33;
  gps_source{file_idx} = 'bas_gnss-final20200306';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');
  
  % IMU worked fine
  year = 2019; month = 12; day = 26;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'GNSS_IMU','T07.txt')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f';
  params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg',...
    'elev_m','roll_deg','pitch_deg','heading_deg','f1','f2','f3','f4',...
    'f5','f6','f7'};
  params{file_idx}.textscan = {};
  params{file_idx}.headerlines = 34;
  gps_source{file_idx} = 'bas-final20200306';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');
  
  % IMU worked fine (T14 and T15)
  year = 2019; month = 12; day = 29;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'GNSS_IMU','T14.txt')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f';
  params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg',...
    'elev_m','roll_deg','pitch_deg','heading_deg','f1','f2','f3','f4',...
    'f5','f6','f7'};
  params{file_idx}.textscan = {};
  params{file_idx}.headerlines = 34;
  gps_source{file_idx} = 'bas-final20200306';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');
  
  % IMU worked fine (T16 and T17)
  year = 2019; month = 12; day = 30;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'GNSS_IMU','T16.txt')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f';
  params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg',...
    'elev_m','roll_deg','pitch_deg','heading_deg','f1','f2','f3','f4',...
    'f5','f6','f7'};
  params{file_idx}.textscan = {};
  params{file_idx}.headerlines = 34;
  gps_source{file_idx} = 'bas-final20200306';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');

  % No IMU data, processed to GPS antenna
  year = 2020; month = 1; day = 25;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'GNSS_IMU','T19.txt')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f';
  params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg',...
    'elev_m','roll_deg','pitch_deg','heading_deg','f1','f2','f3','f4',...
    'f5','f6','f7'};
  params{file_idx}.textscan = {};
  params{file_idx}.headerlines = 33;
  gps_source{file_idx} = 'bas_gnss-final20200306';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');

  % No IMU data, processed to GPS antenna
  year = 2020; month = 1; day = 26;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'GNSS_IMU','T20.txt')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f';
  params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg',...
    'elev_m','roll_deg','pitch_deg','heading_deg','f1','f2','f3','f4',...
    'f5','f6','f7'};
  params{file_idx}.textscan = {};
  params{file_idx}.headerlines = 33;
  gps_source{file_idx} = 'bas_gnss-final20200306';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');
  
  % No IMU data, processed to GPS antenna
  year = 2020; month = 1; day = 27;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'GNSS_IMU','T21.txt')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f';
  params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg',...
    'elev_m','roll_deg','pitch_deg','heading_deg','f1','f2','f3','f4',...
    'f5','f6','f7'};
  params{file_idx}.textscan = {};
  params{file_idx}.headerlines = 33;
  gps_source{file_idx} = 'bas_gnss-final20200306';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');
  
  % No IMU data, processed to GPS antenna
  year = 2020; month = 1; day = 28;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'GNSS_IMU','T22.txt')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f';
  params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg',...
    'elev_m','roll_deg','pitch_deg','heading_deg','f1','f2','f3','f4',...
    'f5','f6','f7'};
  params{file_idx}.textscan = {};
  params{file_idx}.headerlines = 33;
  gps_source{file_idx} = 'bas_gnss-final20200306';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');
  
  
end

%% gps_create
% Read and translate files according to user settings
% =========================================================================
gps_create;

%% custom fixes
% =========================================================================
for idx = 1:length(file_type)
  out_fn = fullfile(gps_path,out_fns{idx});
  
  load(out_fn,'gps_source');
  if ~isempty(regexpi(gps_source,'arena'))
    % Extrapolation is necessary because GPS data starts after/stops before
    % the beginning/end of the radar data.
    warning('Extrapolating and filtering elevation for arena GPS data: %s', out_fn);
    gps = load(out_fn);
    
    if length(gps.lat) >= 2
      new_gps_time = [gps.gps_time(1)-10, gps.gps_time,gps.gps_time(end)+10];
      gps.lat = interp1(gps.gps_time,gps.lat,new_gps_time,'linear','extrap');
      gps.lon = interp1(gps.gps_time,gps.lon,new_gps_time,'linear','extrap');
      gps.elev = interp1(gps.gps_time,gps.elev,new_gps_time,'linear','extrap');
      gps.roll = interp1(gps.gps_time,gps.roll,new_gps_time,'linear','extrap');
      gps.pitch = interp1(gps.gps_time,gps.pitch,new_gps_time,'linear','extrap');
      gps.heading = interp1(gps.gps_time,gps.heading,new_gps_time,'linear','extrap');
      gps.gps_time = new_gps_time;
      
      gps.elev = fir_dec(gps.elev,ones(1,101)/101,1);
      
      save(out_fn,'-append','-struct','gps','gps_time','lat','lon','elev','roll','pitch','heading');
    end
  end
  
  if ~isempty(regexpi(out_fn,'20191225')) && ~isempty(regexpi(gps_source,'bas-'))
    % Merge of IMU and GNSS data
    warning('Merging IMU and GNSS GPS data: %s', out_fn);
    
    gps_imu = load(out_fn);
    out_fn_dir = fileparts(out_fn);
    gps_gnss = load(fullfile(out_fn_dir,'gps_20191225_gnss.mat'));
    
    % Apply lever arm to IMU GPS data to take it to GPS antenna
    trajectory_param = struct('gps_source','bas_imu_to_gps-final', ...
      'season_name','2019_Antarctica_TObas','radar_name','accum','rx_path', 0, ...
      'tx_weights', [], 'lever_arm_fh', @lever_arm);
    gps_gnss_imu = trajectory_with_leverarm(gps_imu,trajectory_param);
    
    gnss_only_start_idx = find(gps_gnss.gps_time > gps_imu.gps_time(end),1);
    gps = gps_gnss;
    gps.gps_time = [gps_imu.gps_time gps_gnss.gps_time(gnss_only_start_idx:end)];
    gps.lat = [gps_gnss_imu.lat gps_gnss.lat(gnss_only_start_idx:end)];
    gps.lon = [gps_gnss_imu.lon gps_gnss.lon(gnss_only_start_idx:end)];
    gps.elev = [gps_gnss_imu.elev gps_gnss.elev(gnss_only_start_idx:end)];
    gps.roll = [gps_gnss_imu.roll gps_gnss.roll(gnss_only_start_idx:end)];
    gps.pitch = [gps_gnss_imu.pitch gps_gnss.pitch(gnss_only_start_idx:end)];
    gps.heading = [gps_gnss_imu.heading gps_gnss.heading(gnss_only_start_idx:end)];
    
    if 0
      % Debug
      figure(1); clf;
      plot(gps_gnss.gps_time, gps_gnss.elev); % Original GNSS only
      hold on;
      plot(gps.gps_time, gps.elev); % Combined
      plot(gps_gnss_imu.gps_time, gps_gnss_imu.elev,'--'); % IMU only
      xlabel('GPS time');
      ylabel('Elevation (m)');
      legend('GNSS-only','Combined','IMU+GNSS');
      
      figure(2); clf;
      plot(gps_gnss.gps_time, gps_gnss.heading*180/pi); % Original GNSS only
      hold on;
      plot(gps.gps_time, gps.heading*180/pi); % Combined
      plot(gps_gnss_imu.gps_time, gps_gnss_imu.heading*180/pi,'--'); % IMU only
      xlabel('GPS time');
      ylabel('Heading (deg)');
      legend('GNSS-only','Combined','IMU+GNSS');
      
    end;
    
    out_fn = fullfile(out_fn_dir,'gps_20191225.mat');
    ct_save(out_fn,'-struct','gps');
  end
  
  if ~isempty(regexpi(gps_source,'bas')) && isempty(regexpi(out_fn,'gps_20191225_gnss'))
    % gps_20191225_gnss is skipped because gps_20191225 is taken care of
    % when gps_20191225_imu is produced.
    %
    % BAS GPS data are referenced to:
    % # ITRF2014(2020.07117)
    % # Ellipsoid: GRS80 (a=6378137.0000, f=1/298.25722210)
    % Convert to WGS84... the effect seems to be very very small (0.1 mm difference between the ellipsoids)
    
    warning('Converting from GRS80 ellipsoid to WGS84 ellipsoid: %s', out_fn);
    
    physical_constants;
    gps = load(out_fn);
    old_gps = gps;
    [x,y,z] = geodetic2ecef(gps.lat/180*pi, gps.lon/180*pi, gps.elev, GRS80.ellipsoid);
    [gps.lat,gps.lon,gps.elev] = ecef2geodetic(x, y, z, WGS84.ellipsoid);
    gps.lat = gps.lat*180/pi;
    gps.lon = gps.lon*180/pi;
    
    if 0
      figure(1); clf;
      plot(gps.lon, gps.lat);
      hold on;
      plot(old_gps.lon, old_gps.lat,'--');
      grid on;
      
      figure(2); clf;
      plot(gps.elev);
      hold on;
      plot(old_gps.elev,'--');
      grid on;
    end
    
    save(out_fn,'-append','-struct','gps','lat','lon','elev');

  end
  
  if ~isempty(regexpi(out_fn,'201910XX'))
    % Fake GPS for testing
    warning('Faking GPS data: %s', out_fn);
    gps = load(out_fn);
    
    velocity = 4;
    gps.lat = -75.5 - (gps.gps_time-gps.gps_time(1))*velocity/111111;
    gps.lon(:) = -106.75;
    gps.elev(:) = 500;
    gps.heading(:) = -pi;
    
    save(out_fn,'-append','-struct','gps','gps_time','lat','lon','elev','roll','pitch','heading');
  end
  
end
