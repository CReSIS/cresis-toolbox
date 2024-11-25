% script gps_create_2014_antarctica_DC8
%
% Makes the GPS files for 2014 Antarctica DC8 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2014_Antarctica_DC8');
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

in_base_path = fullfile(data_support_path,'2014_Antarctica_DC8');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

% gps_source_to_use = 'NMEA';
% gps_source_to_use = 'ATM-field';
gps_source_to_use = 'ATM';

if strcmpi(gps_source_to_use,'NMEA')

%   year = 2014; month = 9; day = 10;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,'GPS_',datestr(datenum(year,month,day),'yyyymmdd'),'.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('accum2_%04d%02d%02d',year,month,day),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
  
%   year = 2014; month = 10; day = 7;
%   file_idx = file_idx + 1;%   year = 2014; month = 10; day = 7;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,'GPS_',datestr(datenum(year,month,day),'yyyymmdd'),'.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;

%   in_fns{file_idx} = get_filenames(in_base_path,'GPS_',datestr(datenum(year,month,day),'yyyymmdd'),'.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;
  
%   year = 2014; month = 10; day = 16;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;
  
%   year = 2014; month = 10; day = 18;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 10; day = 20
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;
  
%   year = 2014; month = 10; day = 23
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 10; day = 25
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field'%   year = 2014; month = 10; day = 28
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;
;
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 10; day = 26
%   file_idx = file_idx + 1;
%   in_fns{figps_source_to_use = 'ATM-field';
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 10; day = 28
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 10; day = 29
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;
gps_source_to_use = 'ATM-field';

%   year = 2014; month = 11; day = 2;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;
% 
%   year = 2014; month = 11; day = 3;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 11; day = 5;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 11; day = 6;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 11; day = 7;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(i0n_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 11; day = 8;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 11; day = 10;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 11; day = 11;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 11; day = 13;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 11; day = 14;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 11; day = 15;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 11; day = 16;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

  year = 2014; month = 11; day = 21;
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,strcat(datestr(datenum(year,month,day),'yyyymmdd'),'NMEA','.txt'));
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 0;

elseif strcmpi(gps_source_to_use,'ATM-field')
  
%   year = 2014; month = 10; day = 7;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;
  
%   year = 2014; month = 10; day = 16;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 10; day = 18;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 10; day = 20;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSS*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 10; day = 23;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;
% 
%   year = 2014; month = 10; day = 25;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 10; day = 26;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 10; day = 28;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;
% 
%   year = 2014; month = 10; day = 29;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'J00k3_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;

%   year = 2014; month = 11; day = 02;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;
%   
%   year = 2014; month = 11; day = 05;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;
% 
%   year = 2014; month = 11; day = 06;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;

  year = 2014; month = 11; day = 07;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'atm-field';
  sync_flag{file_idx} = 0;

  year = 2014; month = 11; day = 08;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'atm-field';
  sync_flag{file_idx} = 0;

  year = 2014; month = 11; day = 10;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'BD960_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'atm-field';
  sync_flag{file_idx} = 0;

elseif strcmpi(gps_source_to_use,'ATM')
  % Just some simple code to automate creation of the code in this section:
  %
%   ATM_fns = get_filenames(in_base_path,'','','.out');
%   fn_dates = [];
%   for idx = 1:length(ATM_fns)
%     fn = ATM_fns{idx};
%     [~,fn_name] = fileparts(fn);
%     if strcmpi(fn_name(1:2),'BD')
%       fn_dates(end+1) = datenum(sprintf('%s %s, 20%s', fn_name(9:11), fn_name(7:8), fn_name(12:13)));
%     elseif strcmpi(fn_name(1:2),'00')
%       fn_dates(end+1) = datenum(sprintf('%s %s, 20%s', fn_name(13:15), fn_name(11:12), fn_name(16:17)));
%     end
%   end
%   fn_dates = sort(fn_dates);
%   for idx = 1:length(fn_dates)
%     [year,month,day] = datevec(fn_dates(idx));
%     fprintf('year = %d; month = %d; day = %d;\n', year, month, day);
%   end
% !!!   ALL data, including test flights, from Oct 7th to OCT29th are in
% GPS time. From Nov2nd to Nov 22nd the data is in UTC time.

  year = 2014; month = 10; day = 7;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','gps');
  gps_source{file_idx} = 'atm-final_20141225';
  sync_flag{file_idx} = 0;  

  year = 2014; month = 10; day = 8;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','gps');
  gps_source{file_idx} = 'atm-final_20141225';
  sync_flag{file_idx} = 0;  

  year = 2014; month = 10; day = 16;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'00k3Javad_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','gps');
  gps_source{file_idx} = 'atm-final_20141225';
  sync_flag{file_idx} = 0;  
  
  year = 2014; month = 10; day = 18;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'00k3Javad_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','gps');
  gps_source{file_idx} = 'atm-final_20141225';
  sync_flag{file_idx} = 0;  

  year = 2014; month = 10; day = 20;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(in_base_path,'00k3Javad_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','gps');
  gps_source{file_idx} = 'atm-final_20141225';
  sync_flag{file_idx} = 0;  

  year = 2014; month = 10; day = 23;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'00k3Javad_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','gps');
  gps_source{file_idx} = 'atm-final_20141225';
  sync_flag{file_idx} = 0;  

  year = 2014; month = 10; day = 25;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'00k3Javad_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','gps');
  gps_source{file_idx} = 'atm-final_20141225';
  sync_flag{file_idx} = 0;  

  year = 2014; month = 10; day = 26;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'00k3Javad_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','gps');
  gps_source{file_idx} = 'atm-final_20141225';
  sync_flag{file_idx} = 0;  

  year = 2014; month = 10; day = 28;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'00k3Javad_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','gps');
  gps_source{file_idx} = 'atm-final_20141225';
  sync_flag{file_idx} = 0;  

  year = 2014; month = 10; day = 29;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'00k3Javad_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','gps');
  gps_source{file_idx} = 'atm-final_20141225';
  sync_flag{file_idx} = 0;  

  end


% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

hack_idx = cell2mat(strfind(out_fns,'gps_20140904.mat'));
if ~isempty(hack_idx)
  out_fn = fullfile(gps_path,out_fns{hack_idx});
  
  warning('Creating fake trajectory with lab data: %s', out_fn);
  
  gps = load(out_fn);
  gps.lat(:) = gps.lat(1) + (gps.gps_time-gps.gps_time(1))*125/111e3;
  gps.lon(:) = gps.lon(1);
  save(out_fn,'-append','-struct','gps','lat','lon')
end
