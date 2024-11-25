% script gps_create_2017_greenland_P3
%
% Makes the GPS files for 2017 Greenland P3 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2017_Greenland_P3');
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

in_base_path = fullfile(data_support_path,'2017_Greenland_P3');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

% gps_source_to_use = 'NMEA';
% gps_source_to_use = 'ATM-field';
% gps_source_to_use = 'ATM-field_traj';
% gps_source_to_use = 'ATM';
gps_source_to_use = 'DMS';

if strcmpi(gps_source_to_use,'NMEA')
  %% NMEA
    
%     year = 2017; month = 3; day = 9;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;
    
%     year = 2017; month = 3; day = 10;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;
%     
%     year = 2017; month = 3; day = 11;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;
% 
%     year = 2017; month = 3; day = 12;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;
% 
%     year = 2017; month = 3; day = 14;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;

%     year = 2017; month = 3; day = 20;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;
 
%     year = 2017; month = 3; day = 22;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;
 
%     year = 2017; month = 3; day = 23;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;
 
%     year = 2017; month = 3; day = 24;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;pl
%      
%     year = 2017; month = 3; day = 28;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;
%      
%     year = 2017; month = 3; day = 29;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;
%       
%     year = 2017; month = 3; day = 30;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;
%       
%     year = 2017; month = 3; day = 31;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;
%       
%     year = 2017; month = 4; day = 3;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;
%       
%     year = 2017; month = 4; day = 5;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;
       
%     year = 2017; month = 4; day = 6;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;

%     year = 2017; month = 4; day = 7;
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;

%   year = 2017; month = 4; day = 10;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

% year = 2017; month = 4; day = 11;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2017; month = 4; day = 12;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2017; month = 4; day = 13;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2017; month = 4; day = 14;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2017; month = 4; day = 17;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2017; month = 4; day = 19;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% 
% year = 2017; month = 4; day = 20;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% 
% year = 2017; month = 4; day = 21;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2017; month = 4; day = 22;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2017; month = 4; day = 24;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2017; month = 4; day = 26;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% 
% year = 2017; month = 4; day = 28;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2017; month = 4; day = 29;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% 
% year = 2017; month = 5; day = 1;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% 
% year = 2017; month = 5; day = 2;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% 
% year = 2017; month = 5; day = 3;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2017; month = 5; day = 5;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% 
% year = 2017; month = 5; day = 6;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% 
% year = 2017; month = 5; day = 8;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% 
% year = 2017; month = 5; day = 10;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

year = 2017; month = 5; day = 11;
file_idx = file_idx + 1;
in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
file_type{file_idx} = 'NMEA';
params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
gps_source{file_idx} = 'nmea-field';
sync_flag{file_idx} = 0;

elseif strcmpi(gps_source_to_use,'ATM-field')
  %% ATM-field
  
%   year = 2017; month = 2; day = 26;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0; 
%   
%   year = 2017; month = 3; day = 9;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;
%   
%   year = 2017; month = 3; day = 10;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;
%   
%   year = 2017; month = 3; day = 11;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;
%   
%   year = 2017; month = 3; day = 12;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;
%   
%   year = 2017; month = 3; day = 14;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;
%   
%   year = 2017; month = 3; day = 20;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;
%   
%   year = 2017; month = 3; day = 22;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;
%   
%   year = 2017; month = 3; day = 24;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;  
%       
%   year = 2017; month = 4; day = 3;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;  
%       
%   year = 2017; month = 4; day = 5;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;  
% 
%   year = 2017; month = 4; day = 7;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'applanix';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'atm-field';
%   sync_flag{file_idx} = 0;
%   
  year = 2017; month = 4; day = 19;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
  gps_source{file_idx} = 'atm-field';
  sync_flag{file_idx} = 0;
 
elseif strcmpi(gps_source_to_use,'ATM-field_traj')
    %% ATM-field_traj

%   year = 2017; month = 3; day = 9;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'itrf','noamb');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'traj';
%   params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
%   gps_source{file_idx} = 'atm-field_traj';
%   sync_flag{file_idx} = 0;
%   
%   year = 2017; month = 3; day = 10;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filename(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'itrf','noamb');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'traj';
%   params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
%   gps_source{file_idx} = 'atm-field_traj';
%   sync_flag{file_idx} = 0;
   
  year = 2017; month = 3; day = 27;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(in_base_path,datestr(datenum(year,month,day),'yyyymmdd'),'','.gps.thin');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'traj';
  params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f');
  gps_source{file_idx} = 'atm-field_traj';
  sync_flag{file_idx} = 0; 
  
elseif strcmpi(gps_source_to_use,'ATM')
  %% ATM
  
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
  
 ATM_fns = get_filenames(in_base_path,'','','.out');
  fn_dates = [];
  for idx = 1:length(ATM_fns)
    fn = ATM_fns{idx};
    [~,fn_name] = fileparts(fn);
    fn_dates(end+1) = datenum(sprintf('%s %s, 20%s', fn_name(9:11), fn_name(7:8), fn_name(12:13)));
  end
  fn_dates = sort(fn_dates);
  
  for idx = 1:length(fn_dates)
    [year,month,day] = datevec(fn_dates(idx));
    fprintf('year = %d; month = %d; day = %d;\n', year, month, day);
    file_idx = file_idx + 1;
      if idx==1 
      in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'GNSSK*.out');
    else
      in_fns{file_idx} = get_filename(in_base_path,'BD982_',datestr(datenum(year,month,day),'ddmmmyy'),'PPPK*.out');
    end
    out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
    file_type{file_idx} = 'applanix';
    params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
    gps_source{file_idx} = 'atm-final_20170620';
    sync_flag{file_idx} = 0;
  end
  
elseif strcmpi(gps_source_to_use,'DMS')
  %% DMS
  
  year = 2017; month = 4; day = 20;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filename(fullfile(in_base_path,'Wing_Flexure'),'Paden_',datestr(datenum(year,month,day),'yyyymmdd'),'.out');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','gps');
  gps_source{file_idx} = 'dms-final_20170530';
  sync_flag{file_idx} = 0;
  
end


% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

% Debug code that sets up special processing
hack_idx = cell2mat(strfind(out_fns,'gps_20170329.mat'));
if ~isempty(hack_idx)
  out_fn = fullfile(gps_path,out_fns{hack_idx});
  
  gps = load(out_fn);
  if strcmpi(gps.gps_source,'nmea-field')
    warning('Making monotonic gps time: %s', out_fn);
    [gps,error_flag] = gps_force_monotonic(gps);
    save(out_fn,'-append','-struct','gps');
  end
end
hack_idx = cell2mat(strfind(out_fns,'gps_20170403.mat'));
if ~isempty(hack_idx)
  out_fn = fullfile(gps_path,out_fns{hack_idx});
  
  gps = load(out_fn);
  if strcmpi(gps.gps_source,'nmea-field')
    warning('Making monotonic gps time: %s', out_fn);
    [gps,error_flag] = gps_force_monotonic(gps);
    save(out_fn,'-append','-struct','gps');
  end
end
hack_idx = cell2mat(strfind(out_fns,'gps_20170405.mat'));
if ~isempty(hack_idx)
  out_fn = fullfile(gps_path,out_fns{hack_idx});
    
  gps = load(out_fn);
  if strcmpi(gps.gps_source,'nmea-field')
    warning('Correcting elevation: %s', out_fn);
    gps.elev(16000:20674) = interp1([16000 20674],gps.elev([16000 20674]),16000:20674);
    save(out_fn,'-append','-struct','gps');
  end
end

hack_idx = cell2mat(strfind(out_fns,'gps_20170424.mat'));
if ~isempty(hack_idx)
  out_fn = fullfile(gps_path,out_fns{hack_idx});
  
  gps = load(out_fn);
  if strcmpi(gps.gps_source,'nmea-field')
    warning('Making monotonic gps time: %s', out_fn);
    [gps,error_flag] = gps_force_monotonic(gps);
    save(out_fn,'-append','-struct','gps');
  end
end



for idx = 1:length(file_type)
  out_fn = fullfile(gps_path,out_fns{idx});
  
  gps = load(out_fn);
  if regexpi(gps.gps_source,'atm')
    
    warning('Smoothing INS data: %s', out_fn);
    
    gps.roll = sgolayfilt(gps.roll,2,101); % Adjust filter length as needed to remove high frequency noise
    gps.pitch = sgolayfilt(gps.pitch,2,101); % Adjust filter length as needed to remove high frequency noise
    heading_x = cos(gps.heading);
    heading_y = sin(gps.heading);
    heading_x  = sgolayfilt(heading_x,2,101); % Adjust filter length as needed to remove high frequency noise
    heading_y  = sgolayfilt(heading_y,2,101); % Adjust filter length as needed to remove high frequency noise
    gps.heading = atan2(heading_y,heading_x);
     
    save(out_fn,'-append','-struct','gps','roll','pitch','heading');
  end
end
