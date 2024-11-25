% script gps_create_2010_greenland_DC8_DGPSwINS
%
% Makes the DGPSwINS files for 2010 Greenland DC-8 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2010_Greenland_DC8');
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

in_base_path = fullfile(data_support_path,'2010_Greenland_DC8_DGPSwINS');

file_idx = 0;

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_17Mar10_PPP.out');
out_fns{file_idx} = 'gps_20100317.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',03,'day',17,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_23Mar10_PPP.out');
out_fns{file_idx} = 'gps_20100323.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',03,'day',23,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_24Mar10_PPP.out');
out_fns{file_idx} = 'gps_20100324.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',03,'day',24,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_26Mar10_PPP.out');
out_fns{file_idx} = 'gps_20100326.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',03,'day',26,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_29Mar10_PPP.out');
out_fns{file_idx} = 'gps_20100329.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',03,'day',29,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_30Mar10_PPP.out');
out_fns{file_idx} = 'gps_20100330.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',03,'day',30,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_02Apr10_PPP.out');
out_fns{file_idx} = 'gps_20100402.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',04,'day',02,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_05Apr10_PPP.out');
out_fns{file_idx} = 'gps_20100405.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',04,'day',05,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_09Apr10_PPP.out');
out_fns{file_idx} = 'gps_20100409.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',04,'day',09,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_12Apr10_PPP.out');
out_fns{file_idx} = 'gps_20100412.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',04,'day',12,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_13Apr10_PPP.out');
out_fns{file_idx} = 'gps_20100413.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',04,'day',13,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_14Apr10_PPP.out');
out_fns{file_idx} = 'gps_20100414.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',04,'day',14,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_19Apr10_PPP.out');
out_fns{file_idx} = 'gps_20100419.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',04,'day',19,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_20Apr10_PPP.out');
out_fns{file_idx} = 'gps_20100420.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',04,'day',20,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_21Apr10_PPP.out');
out_fns{file_idx} = 'gps_20100421.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',04,'day',21,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';

file_idx = file_idx + 1;
in_fns{file_idx} = fullfile(in_base_path,'BD960_22Apr10_PPP.out');
out_fns{file_idx} = 'gps_20100422.mat';
file_type{file_idx} = 'Applanix';
params{file_idx} = struct('year',2010,'month',04,'day',22,'time_reference','utc');
gps_source{file_idx} = 'atm-final_20101231';

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

