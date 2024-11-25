% script gps_create_2011_greenland_TO
%
% Makes the GPS files for 2011 Greenland Twin Otter field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2011_Greenland_TO');
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

in_base_path = fullfile(data_support_path,'2011_Greenland_TO','2011_Greenland_TO_GPSwINS','txt');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'cresis';
if strcmpi(gps_source_to_use,'cresis')
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'rover_LC_ppp_Greenland_20110324.gps');
  out_fns{file_idx} = 'gps_20110324.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',3,'day',24,'time_reference','gps');
  gps_source{file_idx} = 'cresis-final';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'rover_TC_diff_Greenland_20110331.gps');
  out_fns{file_idx} = 'gps_20110331.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',3,'day',31,'time_reference','gps');
  gps_source{file_idx} = 'cresis-final';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'rover_LC_ppp_Greenland_20110401.gps');
  out_fns{file_idx} = 'gps_20110401.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',4,'day',1,'time_reference','gps');
  gps_source{file_idx} = 'cresis-final';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'rover_TC_diff_Greenland_20110411.gps');
  out_fns{file_idx} = 'gps_20110411.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',4,'day',11,'time_reference','gps');
  gps_source{file_idx} = 'cresis-final';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'rover_TC_diff_Greenland_20110412.gps');
  out_fns{file_idx} = 'gps_20110412.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',4,'day',12,'time_reference','gps');
  gps_source{file_idx} = 'cresis-final';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'rover_TC_diff_Greenland_20110419.gps');
  out_fns{file_idx} = 'gps_20110419.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',4,'day',19,'time_reference','gps');
  gps_source{file_idx} = 'cresis-final';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'rover_TC_diff_Greenland_20110424.gps');
  out_fns{file_idx} = 'gps_20110424.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',4,'day',24,'time_reference','gps');
  gps_source{file_idx} = 'cresis-final';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'rover_TC_diff_Greenland_20110425.gps');
  out_fns{file_idx} = 'gps_20110425.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',4,'day',25,'time_reference','gps');
  gps_source{file_idx} = 'cresis-final';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'rover_TC_diff_Greenland_20110428.gps');
  out_fns{file_idx} = 'gps_20110428.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',4,'day',28,'time_reference','gps');
  gps_source{file_idx} = 'cresis-final';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'rover_TC_diff_Greenland_20110430.gps');
  out_fns{file_idx} = 'gps_20110430.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',4,'day',30,'time_reference','gps');
  gps_source{file_idx} = 'cresis-final';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'rover_LC_ppp_Greenland_20110502.gps');
  out_fns{file_idx} = 'gps_20110502.mat';
  file_type{file_idx} = 'Novatel';
  params{file_idx} = struct('year',2011,'month',5,'day',2,'time_reference','gps');
  gps_source{file_idx} = 'cresis-final';
  sync_flag{file_idx} = 0;
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;
