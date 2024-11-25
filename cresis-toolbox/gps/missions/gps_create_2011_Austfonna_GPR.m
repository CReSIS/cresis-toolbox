% script gps_create_2011_Austfonna_GPR
%
% Makes the GPS files for 2011 Austfonna GPR field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2011_Austfonna_GPR');
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

in_base_path = fullfile(data_support_path);

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'CSRS_PPP';
if strcmpi(gps_source_to_use,'CSRS_PPP')

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'28631210.csv');
  out_fns{file_idx} = 'gps_20110501.mat';
  file_type{file_idx} = 'csv';
  params{file_idx} = struct('year',2011,'month',05,'day',1,'time_reference','utc','type',2);
  gps_source{file_idx} = 'Trimble_CSRS_PPP';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'28631220.csv');
  out_fns{file_idx} = 'gps_20110502.mat';
  file_type{file_idx} = 'csv';
  params{file_idx} = struct('year',2011,'month',05,'day',2,'time_reference','utc','type',2);
  gps_source{file_idx} = 'Trimble_CSRS_PPP';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'28631230.csv');
  out_fns{file_idx} = 'gps_20110503.mat';
  file_type{file_idx} = 'csv';
  params{file_idx} = struct('year',2011,'month',05,'day',3,'time_reference','utc','type',2);
  gps_source{file_idx} = 'Trimble_CSRS_PPP';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'28631240.csv');
  out_fns{file_idx} = 'gps_20110504.mat';
  file_type{file_idx} = 'csv';
  params{file_idx} = struct('year',2011,'month',05,'day',4,'time_reference','utc','type',2);
  gps_source{file_idx} = 'Trimble_CSRS_PPP';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'28631250.csv');
  out_fns{file_idx} = 'gps_20110505.mat';
  file_type{file_idx} = 'csv';
  params{file_idx} = struct('year',2011,'month',05,'day',5,'time_reference','utc','type',2);
  gps_source{file_idx} = 'Trimble_CSRS_PPP';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'28631260.csv');
  out_fns{file_idx} = 'gps_20110506.mat';
  file_type{file_idx} = 'csv';
  params{file_idx} = struct('year',2011,'month',05,'day',6,'time_reference','utc','type',2);
  gps_source{file_idx} = 'Trimble_CSRS_PPP';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'28631270.csv');
  out_fns{file_idx} = 'gps_20110507.mat';
  file_type{file_idx} = 'csv';
  params{file_idx} = struct('year',2011,'month',05,'day',7,'time_reference','utc','type',2);
  gps_source{file_idx} = 'Trimble_CSRS_PPP';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'28631280.csv');
  out_fns{file_idx} = 'gps_20110508.mat';
  file_type{file_idx} = 'csv';
  params{file_idx} = struct('year',2011,'month',05,'day',8,'time_reference','utc','type',2);
  gps_source{file_idx} = 'Trimble_CSRS_PPP';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'28631310.csv');
  out_fns{file_idx} = 'gps_20110511.mat';
  file_type{file_idx} = 'csv';
  params{file_idx} = struct('year',2011,'month',05,'day',11,'time_reference','utc','type',2);
  gps_source{file_idx} = 'Trimble_CSRS_PPP';
  
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

