% script gps_create_2014_alaska_TOnrl
%
% Makes the GPS files for 2014 Alaska TOnrl field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2014_Alaska_TOnrl');
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

in_base_path = fullfile(data_support_path,'2014_Alaska_TOnrl');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'NRL';
if strcmpi(gps_source_to_use,'NMEA')
  
elseif strcmpi(gps_source_to_use,'NRL')
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'gps_20140315.out');
%   out_fns{file_idx} = 'gps_20140315.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2014,'month',3,'day',15,'time_reference','utc');
%   gps_source{file_idx} = 'NRL-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'gps_20140316.out');
%   out_fns{file_idx} = 'gps_20140316.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2014,'month',3,'day',16,'time_reference','utc');
%   gps_source{file_idx} = 'NRL-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'gps_20140318.out');
%   out_fns{file_idx} = 'gps_20140318.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2014,'month',3,'day',18,'time_reference','utc');
%   gps_source{file_idx} = 'NRL-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'gps_20140319.out');
%   out_fns{file_idx} = 'gps_20140319.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2014,'month',3,'day',19,'time_reference','utc');
%   gps_source{file_idx} = 'NRL-field';
%   sync_flag{file_idx} = 0;
   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'sbet_0321_f06r_SB_bo.out');
%   out_fns{file_idx} = 'gps_20140321.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2014,'month',3,'day',21,'time_reference','utc');
%   gps_source{file_idx} = 'NRL-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'sbet_0322_f07r_puo1_bo.out');
%   out_fns{file_idx} = 'gps_20140322.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2014,'month',3,'day',22,'time_reference','utc');
%   gps_source{file_idx} = 'NRL-field';
%   sync_flag{file_idx} = 0;
  
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'sbet_0323_f08r_brw1_bo.out');
%   out_fns{file_idx} = 'gps_20140323.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2014,'month',3,'day',23-7,'time_reference','utc');
%   gps_source{file_idx} = 'NRL-field';
%   sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
% %in_fns{file_idx} = fullfile(in_base_path,'sbet_0324_f09r_brw1_bo.out');
  in_fns{file_idx} = fullfile(in_base_path,'sbet_0324_f09r_rnav.out');
  out_fns{file_idx} = 'gps_20140325.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2014,'month',3,'day',24,'time_reference','utc');
  gps_source{file_idx} = 'NRL-field';
  sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'sbet_0327_f10r_rnav.out');
%   out_fns{file_idx} = 'gps_20140327.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2014,'month',3,'day',27,'time_reference','utc');
%   gps_source{file_idx} = 'NRL-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'sbet_0328_f11r_brw1_bo.out');
%   out_fns{file_idx} = 'gps_20140328.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2014,'month',3,'day',28,'time_reference','utc');
%   gps_source{file_idx} = 'NRL-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'sbet_0329_f13r_brw1_bo.out');
%   out_fns{file_idx} = 'gps_20140329.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2014,'month',3,'day',29,'time_reference','utc');
%   gps_source{file_idx} = 'NRL-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'sbet_0331_f14r_snow_po.out');
%   out_fns{file_idx} = 'gps_20140331.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2014,'month',3,'day',31,'time_reference','utc');
%   gps_source{file_idx} = 'NRL-field';
%   sync_flag{file_idx} = 0;
  
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

% Fabricate loopback GPS data for testing
% gps.gps_time = datenum_to_epoch(datenum(2014,02,25,0,0,0:1000));
% gps.lat = 71 + 70*(0:1000)/1e3/111;
% gps.lon = -156 * ones(size(gps.gps_time));
% gps.elev = 1500 * ones(size(gps.gps_time));
% gps.roll = zeros(size(gps.gps_time));
% gps.pitch = zeros(size(gps.gps_time));
% gps.heading = zeros(size(gps.gps_time));
% gps.gps_source = 'test-test';
% save(fullfile(gps_path,'gps_20140225.mat'),'-struct','gps');


