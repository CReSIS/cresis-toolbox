% script gps_create_2018_antarctica_DC8
%
% Makes the GPS files for 2018 Antarctica DC8 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2018_Antarctica_DC8');
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
in_base_path = fullfile(data_support_path,'2018_Antarctica_DC8','Applanix_data');
sync_path = fullfile(data_support_path,'2018_Antarctica_DC8','Trajectory');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};sync_file_type = {};

% gps_source_to_use = 'NMEA';
% gps_source_to_use = 'ATM-field';
gps_source_to_use = 'ATM';

if strcmpi(gps_source_to_use,'NMEA')
  
  %     year = 2018; month = 9; day = 27;
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
  %     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 0;
  
%       year = 2018; month = 10; day = 10;
%       file_idx = file_idx + 1;
%       in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%       out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%       file_type{file_idx} = 'NMEA';
%       params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%       gps_source{file_idx} = 'nmea-field';
%       sync_flag{file_idx} = 0;

%       year = 2018; month = 10; day = 11;
%       file_idx = file_idx + 1;
%       in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%       out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%       file_type{file_idx} = 'NMEA';
%       params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%       gps_source{file_idx} = 'nmea-field';
%       sync_flag{file_idx} = 0;
  
  %     year = 2018; month = 10; day = 12;
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
  %     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 0;
  
  %     year = 2018; month = 10; day = 13;
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
  %     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 0;
  
%       year = 2018; month = 10; day = 15;
%       file_idx = file_idx + 1;
%       in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%       out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%       file_type{file_idx} = 'NMEA';
%       params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%       gps_source{file_idx} = 'nmea-field';
%       sync_flag{file_idx} = 0;
  
  %     year = 2018; month = 10; day = 16;
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
  %     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 0;
  
  %     year = 2018; month = 10; day = 18;
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
  %     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 0;
  
  %     year = 2018; month = 10; day = 19;
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
  %     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 0;
  
  %     year = 2018; month = 10; day = 20;
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
  %     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 0;
  
  %     year = 2018; month = 10; day = 22;
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
  %     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 0;
  
  %     year = 2018; month = 10; day = 30;
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
  %     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 0;
 
      year = 2018; month = 10; day = 31;
      file_idx = file_idx + 1;
      in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
      out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
      file_type{file_idx} = 'NMEA';
      params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
      gps_source{file_idx} = 'nmea-field';
      sync_flag{file_idx} = 0;
  
 
  %     year = 2018; month = 11; day = 3;
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
  %     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  %     gps_source{file_idx} = 'nmea-field';
  %     sync_flag{file_idx} = 0;
  
      year = 2018; month = 11; day = 4;
      file_idx = file_idx + 1;
      in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
      out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
      file_type{file_idx} = 'NMEA';
      params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
      gps_source{file_idx} = 'nmea-field';
      sync_flag{file_idx} = 0;
  
%   year = 2018; month = 11; day = 5;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2018; month = 11; day = 7;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2018; month = 11; day = 9;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;
  
%   year = 2018; month = 11; day = 10;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2018; month = 11; day = 11;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2018; month = 11; day = 12;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2018; month = 11; day = 14;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

  year = 2018; month = 11; day = 15;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 0;
  
  year = 2018; month = 11; day = 16;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 0;

elseif strcmpi(gps_source_to_use,'ATM-field')
  
  year = 2018; month = 09; day = 28;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  gps_source{file_idx} = 'atm-field';
  sync_flag{file_idx} = 0;
  
elseif strcmpi(gps_source_to_use,'ATM')
%   year = 2018; month = 10; day = 10;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;
%   
%   year = 2018; month = 10; day = 11;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;
  
%   year = 2018; month = 10; day = 12;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;
% 
%   year = 2018; month = 10; day = 13;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;
%   
%   year = 2018; month = 10; day = 15;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;
% 
%   year = 2018; month = 10; day = 16;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;
% 
%   year = 2018; month = 10; day = 18;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;
% 
%   year = 2018; month = 10; day = 19;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;
% 
%   year = 2018; month = 10; day = 20;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;
% 
%   year = 2018; month = 10; day = 22;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;
% 
%   year = 2018; month = 10; day = 27;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;
% 
%   year = 2018; month = 10; day = 30;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;

%   year = 2018; month = 10; day = 31;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;

%   year = 2018; month = 11; day = 03;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;

%   year = 2018; month = 11; day = 04;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;
% % 
%   year = 2018; month = 11; day = 05;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;
% 
%   year = 2018; month = 11; day = 07;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;
% 
%   year = 2018; month = 11; day = 09;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;
% 
%   year = 2018; month = 11; day = 10;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;
% 
%   year = 2018; month = 11; day = 11;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;

  year = 2018; month = 11; day = 12;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
  file_type{file_idx} = 'traj+applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  gps_source{file_idx} = 'atm-final_20190205';
  sync_flag{file_idx} = 0;

%   year = 2018; month = 11; day = 14;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;

%   year = 2018; month = 11; day = 15;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
%   file_type{file_idx} = 'traj+applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
%   in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   gps_source{file_idx} = 'atm-final_20190205';
%   sync_flag{file_idx} = 0;

  year = 2018; month = 11; day = 16;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(sync_path,datestr(datenum(year,month,day),'yymmdd'),'amu2','');
  file_type{file_idx} = 'traj+applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','gps','input_format', '%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  gps_source{file_idx} = 'atm-final_20190205';
  sync_flag{file_idx} = 0;

end


% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

% Debug code that can be used when no GPS data is available and we need to
% fake it.
hack_idx = cell2mat(strfind(out_fns,'gps_?.mat'));
if ~isempty(hack_idx)
  out_fn = fullfile(gps_path,out_fns{hack_idx});
  
  warning('Creating fake trajectory with lab data: %s', out_fn);
  
  gps = load(out_fn);
  gps.lat(:) = gps.lat(1) + (gps.gps_time-gps.gps_time(1))*125/111e3;
  gps.lon(:) = gps.lon(1);
  save(out_fn,'-append','-struct','gps','lat','lon')
end

% Reveal files are known to have GPS time errors which are corrected here.
for idx = 1:length(file_type)
  out_fn = fullfile(gps_path,out_fns{idx});
  
  gps = load(out_fn);
  if regexp(gps.gps_source,'reveal')
    
    warning('Fixing non-monotonic GPS data in reveal file: %s', out_fn);
    
    [gps,error_flag] = gps_force_monotonic(gps);
    
    if error_flag
      save(out_fn,'-append','-struct','gps');
    end
  end
end

% ATM files are known to have a small high frequency INS error which is
% corrected here.
for idx = 1:length(file_type)
  out_fn = fullfile(gps_path,out_fns{idx});
  
  gps = load(out_fn);
  if regexpi(gps.gps_source,'atm')
    
    warning('Smoothing INS data: %s', out_fn);
    
    gps.roll = sgolayfilt(gps.roll,2,101);
    gps.pitch = sgolayfilt(gps.pitch,2,101);
    gps.heading  = sgolayfilt(gps.heading,2,101);
    
    save(out_fn,'-append','-struct','gps','roll','pitch','heading');
  end
end

