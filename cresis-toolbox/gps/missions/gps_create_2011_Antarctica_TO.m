% script gps_create_2011_antarctica_TO
%
% Makes the GPS files for 2011 Antarctica TO field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2011_Antarctica_TO');
if ~exist(gps_path,'dir')
  fprintf('Making directory %s\n', gps_path);
  fprintf('  Press a key to proceed\n');
  pause;
  mkdir(gps_path);
end

if isempty(data_support_path)
  data_support_path = gRadar.data_support_path;
end

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};

% ======================================================================
% User Settings
% ======================================================================
debug_level = 1;

in_base_path = fullfile(data_support_path,'2011_Antarctica_TO');

gps_source_to_use = 'Novatel_diff';
if strcmpi(gps_source_to_use,'NMEA')
  
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20111127.gps');
%   out_fns{file_idx} = 'gps_20111127.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',11,'day',27,'time_reference','utc','format',1);
%   gps_source{file_idx} = 'NMEA-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20111129.gps');
%   out_fns{file_idx} = 'gps_20111129.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',11,'day',29,'time_reference','utc','format',1);
%   gps_source{file_idx} = 'NMEA-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20111201.gps');
%   out_fns{file_idx} = 'gps_20111201.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',12,'day',1,'time_reference','utc','format',1);
%   gps_source{file_idx} = 'NMEA-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20111205.gps');
%   out_fns{file_idx} = 'gps_20111205.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',12,'day',5,'time_reference','utc','format',1);
%   gps_source{file_idx} = 'NMEA-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20111206.gps');
%   out_fns{file_idx} = 'gps_20111206.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',12,'day',6,'time_reference','utc','format',1);
%   gps_source{file_idx} = 'NMEA-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20111209.gps');
%   out_fns{file_idx} = 'gps_20111209.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',12,'day',9,'time_reference','utc','format',1);
%   gps_source{file_idx} = 'NMEA-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20111212.gps');
%   out_fns{file_idx} = 'gps_20111212.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',12,'day',12,'time_reference','utc','format',1);
%   gps_source{file_idx} = 'NMEA-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20111213.gps');
%   out_fns{file_idx} = 'gps_20111213.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',12,'day',13,'time_reference','utc','format',1);
%   gps_source{file_idx} = 'NMEA-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20111214.gps');
%   out_fns{file_idx} = 'gps_20111214.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',12,'day',14,'time_reference','utc','format',1);
%   gps_source{file_idx} = 'NMEA-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20111216.gps');
%   out_fns{file_idx} = 'gps_20111216.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',12,'day',16,'time_reference','utc','format',1);
%   gps_source{file_idx} = 'NMEA-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20111218.gps');
%   out_fns{file_idx} = 'gps_20111218.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',12,'day',18,'time_reference','utc','format',1);
%   gps_source{file_idx} = 'NMEA-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20111228.gps');
%   out_fns{file_idx} = 'gps_20111228.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',12,'day',28,'time_reference','utc','format',1);
%   gps_source{file_idx} = 'NMEA-field';
%   sync_flag{file_idx} = 0; 
  
elseif strcmpi(gps_source_to_use,'Novatel_PPP')
  
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'TWINOTTER_PPP_antarctica_20111127.txt');
%   out_fns{file_idx} = 'gps_20111127.mat';
%   file_type{file_idx} = 'Novatel';
%   params{file_idx} = struct('year',2011,'month',11,'day',27,'time_reference','gps','format',5);
%   gps_source{file_idx} = 'Novatelppp-field';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'TWINOTTER_PPP_antarctica_20111129.txt');
%   out_fns{file_idx} = 'gps_20111129.mat';
%   file_type{file_idx} = 'Novatel';
%   params{file_idx} = struct('year',2011,'month',11,'day',29,'time_reference','gps','format',5);
%   gps_source{file_idx} = 'Novatelppp-field';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'TWINOTTER_ppp_antarctica_20111201.txt');
%   out_fns{file_idx} = 'gps_20111201.mat';
%   file_type{file_idx} = 'Novatel';
%   params{file_idx} = struct('year',2011,'month',12,'day',1,'time_reference','gps','format',5);
%   gps_source{file_idx} = 'Novatelppp-field';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'TWINOTTER_ppp_antarctica_20111205.txt');
%   out_fns{file_idx} = 'gps_20111205.mat';
%   file_type{file_idx} = 'Novatel';
%   params{file_idx} = struct('year',2011,'month',12,'day',5,'time_reference','gps','format',5);
%   gps_source{file_idx} = 'Novatelppp-field';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'TWINOTTER_ppp_antarctica_20111206.txt');
%   out_fns{file_idx} = 'gps_20111206.mat';
%   file_type{file_idx} = 'Novatel';
%   params{file_idx} = struct('year',2011,'month',12,'day',6,'time_reference','gps','format',5);
%   gps_source{file_idx} = 'Novatelppp-field';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'TWINOTTER_ppp_antarctica_20111214_seg2.txt');
%   out_fns{file_idx} = 'gps_20111214.mat';
%   file_type{file_idx} = 'Novatel';
%   params{file_idx} = struct('year',2011,'month',12,'day',14,'time_reference','gps','format',5);
%   gps_source{file_idx} = 'Novatelppp-field';
  
elseif strcmpi(gps_source_to_use,'Novatel_diff')
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'twinotter_diff_antarctica_20111127.txt');
  out_fns{file_idx} = 'gps_20111127.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',11,'day',27,'time_reference','gps','format',5);
  gps_source{file_idx} = 'Novateldiff-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'twinotter_diff_antarctica_20111129.txt');
  out_fns{file_idx} = 'gps_20111129.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',11,'day',29,'time_reference','gps','format',5);
  gps_source{file_idx} = 'Novateldiff-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'twinotter_diff_antarctica_20111206.txt');
  out_fns{file_idx} = 'gps_20111206.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',12,'day',6,'time_reference','gps','format',5);
  gps_source{file_idx} = 'Novateldiff-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'twinotter_diff_antarctica_20111209.txt');
  out_fns{file_idx} = 'gps_20111209.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',12,'day',9,'time_reference','gps','format',5);
  gps_source{file_idx} = 'Novateldiff-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'twinotter_diff_antarctica_20111212.txt');
  out_fns{file_idx} = 'gps_20111212.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',12,'day',12,'time_reference','gps','format',5);
  gps_source{file_idx} = 'Novateldiff-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'twinotter_diff_antarctica_20111213.txt');
  out_fns{file_idx} = 'gps_20111213.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',12,'day',13,'time_reference','gps','format',5);
  gps_source{file_idx} = 'Novateldiff-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'twinotter_diff_antarctica_20111216.txt');
  out_fns{file_idx} = 'gps_20111216.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',12,'day',16,'time_reference','gps','format',5);
  gps_source{file_idx} = 'Novateldiff-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'twinotter_diff_antarctica_20111218.txt');
  out_fns{file_idx} = 'gps_20111218.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',12,'day',18,'time_reference','gps','format',5);
  gps_source{file_idx} = 'Novateldiff-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'twinotter_diff_antarctica_20111219.txt');
  out_fns{file_idx} = 'gps_20111219.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',12,'day',19,'time_reference','gps','format',5);
  gps_source{file_idx} = 'Novateldiff-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'twinotter_diff_antarctica_20111220.txt');
  out_fns{file_idx} = 'gps_20111220.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',12,'day',20,'time_reference','gps','format',5);
  gps_source{file_idx} = 'Novateldiff-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'twinotter_diff_antarctica_20111222.txt');
  out_fns{file_idx} = 'gps_20111222.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',12,'day',22,'time_reference','gps','format',5);
  gps_source{file_idx} = 'Novateldiff-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'twinotter_diff_antarctica_20111228.txt');
  out_fns{file_idx} = 'gps_20111228.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',12,'day',28,'time_reference','gps','format',5);
  gps_source{file_idx} = 'Novateldiff-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'twinotter_diff_antarctica_20120105.txt');
  out_fns{file_idx} = 'gps_20120105.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2012,'month',1,'day',5,'time_reference','gps','format',5);
  gps_source{file_idx} = 'Novateldiff-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'twinotter_diff_antarctica_20120106.txt');
  out_fns{file_idx} = 'gps_20120106.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2012,'month',1,'day',6,'time_reference','gps','format',5);
  gps_source{file_idx} = 'Novateldiff-field';
  
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================

gps_create;
