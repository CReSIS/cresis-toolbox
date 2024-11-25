% script gps_create_2018_alaska_SO
%
% Makes the GPS files for 2018 Alaska SO field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2018_Alaska_SO');
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

in_base_path = fullfile(data_support_path,'2018_Alaska_SO');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

% gps_source_to_use = 'NMEA';
gps_source_to_use = 'Lidar-traj';

if strcmpi(gps_source_to_use,'NMEA')
    
% year = 2018; month = 5; day = 2;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-lab';
% sync_flag{file_idx} = 0;

% year = 2018; month = 5; day = 11;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-lab';
% sync_flag{file_idx} = 0;

% year = 2018; month = 5; day = 20;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2018; month = 5; day = 21;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2018; month = 5; day = 22;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2018; month = 5; day = 23;
% %% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2018; month = 5; day = 24;
% %% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2018; month = 5; day = 25;
% %% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2018; month = 5; day = 27;
% %% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2018; month = 5; day = 28;
% %% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

% year = 2018; month = 5; day = 29;
% %% 
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

year = 2018; month = 5; day = 30;
%% 
file_idx = file_idx + 1;
in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'nmea','','.gps');
out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
file_type{file_idx} = 'NMEA';
params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
gps_source{file_idx} = 'nmea-field';
sync_flag{file_idx} = 0;

elseif strcmpi(gps_source_to_use,'Lidar-traj')
    
%   year = 2018; month = 5; day = 20;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'ualidar-final';
%   sync_flag{file_idx} = 0; 
    
%   year = 2018; month = 5; day = 21;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'ualidar-final';
%   sync_flag{file_idx} = 0; 
  
%   year = 2018; month = 5; day = 22;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'ualidar-final';
%   sync_flag{file_idx} = 0; 

  year = 2018; month = 5; day = 23;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
  params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
  params{file_idx}.textscan = {};
  gps_source{file_idx} = 'ualidar-final';
  sync_flag{file_idx} = 0; 
% 
%   year = 2018; month = 5; day = 24;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'ualidar-final';
%   sync_flag{file_idx} = 0; 
%   
%   year = 2018; month = 5; day = 25;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'ualidar-final';
%   sync_flag{file_idx} = 0; 
%   
%   year = 2018; month = 5; day = 27;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'ualidar-final';
%   sync_flag{file_idx} = 0; 
%   
%   year = 2018; month = 5; day = 28;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'ualidar-final';
%   sync_flag{file_idx} = 0; 
% 
%   year = 2018; month = 5; day = 29;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'ualidar-final';
%   sync_flag{file_idx} = 0; 
% 
%   year = 2018; month = 5; day = 30;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'}
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'ualidar-final';
%   sync_flag{file_idx} = 0; 

  year = 2018; month = 8; day = 19;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(in_base_path,datestr(datenum(year,month,day),'yymmdd'),'','.pos');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','headerlines',1,'format_str','%f%f%f%f%f%f%f');
  params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg'}
  params{file_idx}.textscan = {};
  gps_source{file_idx} = 'ualidar-final';
  sync_flag{file_idx} = 0; 
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

% Debug code that sets up special processing

hack_idx = cell2mat(strfind(out_fns,'gps_20180520.mat'));
if ~isempty(hack_idx)
  out_fn = fullfile(gps_path,out_fns{hack_idx}); 
  gps = load(out_fn);
  if strcmpi(gps.gps_source,'ualidar-final')
    warning('Making monotonic gps time: %s', out_fn);
    [gps,error_flag] = gps_force_monotonic(gps);
    save(out_fn,'-append','-struct','gps');
  end
end