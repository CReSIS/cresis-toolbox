% script gps_create_2010_greenland_P3
%
% Makes the DGPSwINS files for 2010 Greenland P3 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2010_Greenland_P3');
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

in_base_path = fullfile(data_support_path,'2010_Greenland_P3');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames('/cresis/data1/NASA/2010_Greenland_P3_INS/','ln100g.','','.bin.asc');
% out_fns{file_idx} = 'gps_20100503.mat';
% file_type{file_idx} = 'Litton';
% params{file_idx} = struct('year',2010,'month',05,'day',3,'time_reference','gps');
% gps_source{file_idx} = 'litton-final_20101231';
% sync_flag{file_idx} = 0;
% 
file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_07May10_PPPK.out');
out_fns{file_idx} = 'gps_20100507.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',05,'day',7,'time_reference','gps');
gps_source{file_idx} = 'atm-final_20101231';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_08May10_PPPK.out');
out_fns{file_idx} = 'gps_20100508.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',05,'day',8,'time_reference','gps');
gps_source{file_idx} = 'atm-final_20101231';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_10May10_PPPK.out');
out_fns{file_idx} = 'gps_20100510.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',05,'day',10,'time_reference','gps');
gps_source{file_idx} = 'atm-final_20101231';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_12May10_PPPK.out');
out_fns{file_idx} = 'gps_20100512.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',05,'day',12,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_13May10_PPPK.out');
out_fns{file_idx} = 'gps_20100513.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',05,'day',13,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_14May10_PPPK.out');
out_fns{file_idx} = 'gps_20100514.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',05,'day',14,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_15May10_PPPK.out');
out_fns{file_idx} = 'gps_20100515.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',05,'day',15,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_17May10_PPPK.out');
out_fns{file_idx} = 'gps_20100517.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',05,'day',17,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_19May10_PPPK.out');
out_fns{file_idx} = 'gps_20100519.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',05,'day',19,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_20May10_PPPK.out');
out_fns{file_idx} = 'gps_20100520.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',05,'day',20,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_21May10_PPPK.out');
out_fns{file_idx} = 'gps_20100521.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',05,'day',21,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_25May10_PPPK.out');
out_fns{file_idx} = 'gps_20100525.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',05,'day',25,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';
sync_flag{file_idx} = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_26May10_PPPK.out');
out_fns{file_idx} = 'gps_20100526.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',05,'day',26,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';
sync_flag{file_idx} = 0;


% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

