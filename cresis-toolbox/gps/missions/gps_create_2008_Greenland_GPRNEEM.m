% script gps_create_2008_greenland_Ground_NEEM_GPS
%
% Makes the GPS files for 2008 Greenland Ground NEEM field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2008_Greenland_Ground');
if ~exist(gps_path,'dir')
  fprintf('Making directory %s\n', gps_path);
  fprintf('  Press a key to proceed\n');
  pause;
  mkdir(gps_path);
end

if isempty(data_support_path)
  data_support_path = gRadar.data_support_path;
end

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {};

% ======================================================================
% User Settings
% ======================================================================
debug_level = 1;

% in_base_path = fullfile(data_support_path,'2008_Greenland_Ground');
gps_path = fullfile(support_path,'gps','2008_Greenland_Ground');

file_idx = 0;
% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(gps_path,'nmea.20080807.gps');
% out_fns{file_idx} = 'gps_20080807.mat';
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',2008,'month',8,'day',07,'time_reference','utc','format',3);

% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(gps_path,'nmea.20080808.gps');
% out_fns{file_idx} = 'gps_20080808.mat';
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',2008,'month',8,'day',08,'time_reference','utc','format',3);

file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'nmea.20080809.gps');
in_fns{file_idx} = fullfile(gps_path,'nmea.20080809.gps');
out_fns{file_idx} = 'gps_20080809.mat';
file_type{file_idx} = 'NMEA';
params{file_idx} = struct('year',2008,'month',8,'day',9,'time_reference','utc','format',3);

% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(gps_path,'nmea.20080810.gps');
% out_fns{file_idx} = 'gps_20080810.mat';
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',2008,'month',8,'day',10,'time_reference','utc','format',3);

% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(gps_path,'nmea.20080811.gps');
% out_fns{file_idx} = 'gps_20080811.mat';
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',2008,'month',8,'day',11,'time_reference','utc','format',3);

% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(gps_path,'nmea.20080812.gps');
% out_fns{file_idx} = 'gps_20080812.mat';
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',2008,'month',8,'day',12,'time_reference','utc','format',3);

% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(gps_path,'nmea.20080813.gps');
% out_fns{file_idx} = 'gps_20080813.mat';
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',2008,'month',8,'day',13,'time_reference','utc','format',3);

% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(gps_path,'nmea.20080814.gps');
% out_fns{file_idx} = 'gps_20080814.mat';
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',2008,'month',8,'day',14,'time_reference','utc','format',3);

% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(gps_path,'nmea.20080816.gps');
% out_fns{file_idx} = 'gps_20080816.mat';
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',2008,'month',8,'day',16,'time_reference','utc','format',3);

gps_source = 'nmea';
% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;
if strcmpi(in_fns{file_idx}(end-11:end-4),'20080807')
    gps.time_offset = 9.1617;
elseif strcmpi(in_fns{file_idx}(end-11:end-4),'20080808')
    gps.time_offset = 11.8599;
elseif strcmpi(in_fns{file_idx}(end-11:end-4),'20080809')
    gps.time_offset = 11.6068;
elseif strcmpi(in_fns{file_idx}(end-11:end-4),'20080810')
    gps.time_offset = 13.1348;
elseif strcmpi(in_fns{file_idx}(end-11:end-4),'20080811')
    gps.time_offset = 13.1348;
%     gps.gps_time (62492:130434) = gps.gps_time (52492:130434) - 14.5 + 0.1;    
%     gps.gps_time (117910:130434) = gps.gps_time (117910:130434) - 12 + 0.1;
elseif strcmpi(in_fns{file_idx}(end-11:end-4),'20080812')
    gps.time_offset = 14.8802;
elseif strcmpi(in_fns{file_idx}(end-11:end-4),'20080813')
    gps.time_offset = 17.7433;
elseif strcmpi(in_fns{file_idx}(end-11:end-4),'20080814')
    gps.time_offset = 19.66;
elseif strcmpi(in_fns{file_idx}(end-11:end-4),'20080816')
    gps.time_offset = 22.1825;
end
save(out_fn, '-STRUCT','gps','gps_time','time_offset','lat','lon','elev','roll','pitch','heading','gps_source');