% script gps_create_2003_Greenland_P3
%
% Makes the GPS files for 2003 Greenland P3 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2003_Greenland_P3');
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

in_base_path = fullfile(data_support_path,'2003_Greenland_P3');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {};
gps_source_to_use = 'Traj';
if strcmp(gps_source_to_use,'NMEA')
  
     file_idx = file_idx + 1;
  year = 2003; month = 5; day = 9;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
    sprintf('gps_%04d%02d%02d',year,month,day),'','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
    sprintf('gps_%04d%02d%02d',year,month,day),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');
  
     file_idx = file_idx + 1;
  year = 2003; month = 5; day = 11;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
    sprintf('gps_%04d%02d%02d',year,month,day),'','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
    sprintf('gps_%04d%02d%02d',year,month,day),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');
  
     file_idx = file_idx + 1;
  year = 2003; month = 5; day = 12;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
    sprintf('gps_%04d%02d%02d',year,month,day),'','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
    sprintf('gps_%04d%02d%02d',year,month,day),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');
  
     file_idx = file_idx + 1;
  year = 2003; month = 5; day = 13;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
    sprintf('gps_%04d%02d%02d',year,month,day),'','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
    sprintf('gps_%04d%02d%02d',year,month,day),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');
  
     file_idx = file_idx + 1;
  year = 2003; month = 5; day = 14;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
    sprintf('gps_%04d%02d%02d',year,month,day),'','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
    sprintf('gps_%04d%02d%02d',year,month,day),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');
  
     file_idx = file_idx + 1;
  year = 2003; month = 5; day = 15;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
    sprintf('gps_%04d%02d%02d',year,month,day),'','.gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
    sprintf('gps_%04d%02d%02d',year,month,day),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');

elseif strcmp(gps_source_to_use,'Traj')
  
  file_idx = file_idx + 1;
  year = 2003; month = 5; day = 9;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'2003_Greenland_P3_traj'),sprintf('%02d%02d%02d',mod(year,100),month,day),'','');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'Traj';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  gps_source{file_idx} = sprintf('ATM-final_%04d%02d%02d',year,month,day);
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
    sprintf('gps%02d%02d%02d',mod(year,100),month,day),'','');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');
  
  file_idx = file_idx + 1;
  year = 2003; month = 5; day = 11;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'2003_Greenland_P3_traj'),sprintf('%02d%02d%02d',mod(year,100),month,day),'','');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'Traj';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  gps_source{file_idx} = sprintf('ATM-final_%04d%02d%02d',year,month,day);
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
    sprintf('gps%02d%02d%02d',mod(year,100),month,day),'','');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');
  
  file_idx = file_idx + 1;
  year = 2003; month = 5; day = 12;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'2003_Greenland_P3_traj'),sprintf('%02d%02d%02d',mod(year,100),month,day),'','');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'Traj';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  gps_source{file_idx} = sprintf('ATM-final_%04d%02d%02d',year,month,day);
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
    sprintf('gps%02d%02d%02d',mod(year,100),month,day),'','');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');
  
  file_idx = file_idx + 1;
  year = 2003; month = 5; day = 13;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'2003_Greenland_P3_traj'),sprintf('%02d%02d%02d',mod(year,100),month,day),'','');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'Traj';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  gps_source{file_idx} = sprintf('ATM-final_%04d%02d%02d',year,month,day);
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
    sprintf('gps%02d%02d%02d',mod(year,100),month,day),'','');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');
  
%   file_idx = file_idx + 1;
%   year = 2003; month = 5; day = 14;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,'2003_Greenland_P3_traj'),sprintf('%02d%02d%02d',mod(year,100),month,day),'','');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'Traj';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
%   gps_source{file_idx} = sprintf('ATM-final_%04d%02d%02d',year,month,day);
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
%     sprintf('gps%02d%02d%02d',mod(year,100),month,day),'','');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');
%   
%   file_idx = file_idx + 1;
%   year = 2003; month = 5; day = 15;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,'2003_Greenland_P3_traj'),sprintf('%02d%02d%02d',mod(year,100),month,day),'','');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'Traj';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
%   gps_source{file_idx} = sprintf('ATM-final_%04d%02d%02d',year,month,day);
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('nmea_%04d%02d%02d',year,month,day)), ...
%     sprintf('gps%02d%02d%02d',mod(year,100),month,day),'','');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'format',2,'time_reference','utc');

end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

