% script gps_create_2013_antarctica_Basler
%
% Makes the GPS files for 2013 Antarctica Basler field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2013_Antarctica_Basler');
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

in_base_path = fullfile(data_support_path,'2013_Antarctica_Basler');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'cresis';
if strcmpi(gps_source_to_use,'NMEA')
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'GPS_082913_171801.txt');
  %   out_fns{file_idx} = 'gps_20130829.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2013,'month',08,'day',29,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'GPS_131218_215139.txt');
  out_fns{file_idx} = 'gps_20131219.mat';
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',2013,'month',12,'day',19,'format',1,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 0;
  
end

if strcmpi(gps_source_to_use,'CSV')
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'gps_20131212.csv');
  %   out_fns{file_idx} = 'gps_20131213.mat';
  %   file_type{file_idx} = 'CSV';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'csv-field';
  %   sync_flag{file_idx} = 0;
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'gps_20131215.csv');
  %   out_fns{file_idx} = 'gps_20131216.mat';
  %   file_type{file_idx} = 'CSV';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'csv-field';
  %   sync_flag{file_idx} = 0;
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'gps_20131218.csv');
  %   out_fns{file_idx} = 'gps_20131219.mat';
  %   file_type{file_idx} = 'CSV';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'csv-field';
  %   sync_flag{file_idx} = 0;
  
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'gps_20131219.csv');
  out_fns{file_idx} = 'gps_20131220.mat';
  file_type{file_idx} = 'CSV';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'csv-field';
  sync_flag{file_idx} = 0;
  
end

if strcmpi(gps_source_to_use,'cresis')
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'GPS_20130921.txt');
  %   out_fns{file_idx} = 'gps_20130921.mat';
  %   file_type{file_idx} = 'cresis';
  %   params{file_idx} = struct();
  %   gps_source{file_idx} = 'cresis-final';
  %   sync_flag{file_idx} = 0;
  
%   file_idx = file_idx + 1;
%   year = 2013; month = 12; day = 16;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('Inertial_Explorer_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-final';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   year = 2013; month = 12; day = 19;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('Inertial_Explorer_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-final';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   year = 2013; month = 12; day = 20;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('Inertial_Explorer_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-final';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   year = 2013; month = 12; day = 23;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('Inertial_Explorer_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-final';
%   sync_flag{file_idx} = 0;
  
%   file_idx = file_idx + 1;
%   year = 2013; month = 12; day = 26;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('Intertial_Explorer_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-final';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   year = 2013; month = 12; day = 27;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('Inertial_Explorer_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-final';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   year = 2013; month = 12; day = 31;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('Inertial_Explorer_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-final';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   year = 2014; month = 1; day = 2;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('Inertial_Explorer_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-final';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   year = 2014; month = 1; day = 3;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('Inertial_Explorer_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-final';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   year = 2014; month = 1; day = 4;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('Inertial_Explorer_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-final';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   year = 2014; month = 1; day = 8;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('Inertial_Explorer_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-final';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   year = 2014; month = 1; day = 9;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('Inertial_Explorer_%s.txt',date_string));
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'cresis';
%   params{file_idx} = struct();
%   gps_source{file_idx} = 'cresis-final';
%   sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  year = 2014; month = 1; day = 11;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = fullfile(in_base_path,date_string,sprintf('Inertial_Explorer_%s.txt',date_string));
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'cresis';
  params{file_idx} = struct();
  gps_source{file_idx} = 'cresis-final';
  sync_flag{file_idx} = 0;

  
  
  

end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

hack1_idx = cell2mat(strfind(out_fns,'gps_20130829.mat'));
if ~isempty(hack1_idx)
  out_fn = fullfile(gps_path,out_fns{hack1_idx{1}});
  gps = load(out_fn);
  gps.lat(:) = -60 + (gps.gps_time-gps.gps_time(1))*125/111e3;
  gps.lon(:) = -80;
  save(out_fn,'-append','-struct','gps','lat','lon')
end

if any(strcmpi('gps_20131231.mat',out_fns)) ...
  || any(strcmpi('gps_20140111.mat',out_fns))
  warning('Jan 11 and Dec 31 travelled across 180 deg line and GPS file produced by Novatel may have errors! Novatel smoothing will produce points which interpolate -179.999 to +179.999 and vice versa incorrectly and you have to manually remove these points from the .txt input file before running gps_create.');
  keyboard
end



