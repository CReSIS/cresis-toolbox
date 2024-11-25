% script gps_create_2010_antarctica_DC8
%
% Makes the GPS files for 2010 Antarctica DC-8 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2010_Antarctica_DC8');
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

in_base_path = fullfile(data_support_path,'2010_Antarctica_DC8');
gps_path = fullfile(support_path,'gps','2010_Antarctica_DC8');

file_idx = 0;

clear in_fns out_fns file_type params gps_source sync_flag sync_params;

% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_20101026.out');
% out_fns{file_idx} = 'gps_20101026.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2010,'month',10,'day',26,'time_reference','utc');
% gps_source{file_idx} = 'DMSATM_20101026-final_20110608';
% sync_flag{file_idx} = 0;
% 
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'sbet_20101028.out');
out_fns{file_idx} = 'gps_20101028.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',10,'day',28,'time_reference','gps');
gps_source{file_idx} = 'DMS-final_20110608';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'sbet_20101030.out');
out_fns{file_idx} = 'gps_20101030.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',10,'day',30,'time_reference','gps');
gps_source{file_idx} = 'DMS-final_20110608';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'sbet_20101104.out');
out_fns{file_idx} = 'gps_20101104.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',11,'day',04,'time_reference','gps');
gps_source{file_idx} = 'DMS-final_20110608';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'sbet_20101105.out');
out_fns{file_idx} = 'gps_20101105.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',11,'day',05,'time_reference','gps');
gps_source{file_idx} = 'DMS-final_20110608';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'sbet_20101106.out');
out_fns{file_idx} = 'gps_20101106.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',11,'day',06,'time_reference','gps');
gps_source{file_idx} = 'DMS-final_20110608';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'sbet_20101110.out');
out_fns{file_idx} = 'gps_20101110.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',11,'day',10,'time_reference','gps');
gps_source{file_idx} = 'DMS-final_20110608';
sync_flag{file_idx} = 0;

% file_idx = file_idx + 1;
% in_fns{file_idx} = fullfile(in_base_path,'sbet_20101113.out');
% out_fns{file_idx} = 'gps_20101113.mat';
% file_type{file_idx} = 'Applanix';
% params{file_idx} = struct('year',2010,'month',11,'day',13,'time_reference','gps');
% gps_source{file_idx} = 'DMS-final_20110608';
% sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'sbet_20101119.out');
out_fns{file_idx} = 'gps_20101119.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',11,'day',19,'time_reference','gps');
gps_source{file_idx} = 'DMS-final_20110608';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'sbet_20101120.out');
out_fns{file_idx} = 'gps_20101120.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',11,'day',20,'time_reference','gps');
gps_source{file_idx} = 'DMS-final_20110608';
sync_flag{file_idx} = 0;

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

