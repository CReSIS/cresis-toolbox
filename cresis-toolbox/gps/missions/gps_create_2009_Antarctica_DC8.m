% script gps_create_2009_antarctica_DC8
%
% Makes the GPS files for 2009 Antarctica DC-8 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2009_Antarctica_DC8');
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

in_base_path = fullfile(data_support_path,'2009_Antarctica_DC8');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'DMS';

if strcmp(gps_source_to_use,'DMS')
    
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_16Oct09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091016.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',10,'day',16,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_18Oct09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091018.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',10,'day',18,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_20Oct09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091020.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',10,'day',20,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_21Oct09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091021.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',10,'day',21,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_24Oct09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091024.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',10,'day',24,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_25Oct09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091025.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',10,'day',25,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_27Oct09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091027.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',10,'day',27,'time_reference','gps');
  gps_source{file_idx} = 'DMS-20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_28Oct09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091028.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',10,'day',28,'time_reference','gps');
  gps_source{file_idx} = 'DMS-20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_29Oct09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091029.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',10,'day',29,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_30Oct09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091030.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',10,'day',30,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_31Oct09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091031.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',10,'day',31,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_02Nov09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091102.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',11,'day',02,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_03Nov09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091103.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',11,'day',03,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_04Nov09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091104.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',11,'day',04,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_05Nov09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091105.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',11,'day',05,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_07Nov09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091107.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',11,'day',07,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_09Nov09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091109.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',11,'day',09,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_12Nov09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091112.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',11,'day',12,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_15Nov09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091115.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',11,'day',15,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_16Nov09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091116.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',11,'day',16,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'Javadsbet_18Nov09_PPP_Revised.out');
  out_fns{file_idx} = 'gps_20091118.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2009,'month',11,'day',18,'time_reference','gps');
  gps_source{file_idx} = 'DMS-final_20100810';
  sync_flag{file_idx} = 0;
  
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;
