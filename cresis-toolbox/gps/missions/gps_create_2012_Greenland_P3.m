% script gps_create_2012_greenland_P3
%
% Makes the GPS files for 2012 Greenland P3 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2012_Greenland_P3');
if ~exist(gps_path,'dir')
  fprintf('Making directory %s\n', gps_path);
  fprintf('  Press a key to proceed\n');
  pause;
  mkdir(gps_path);
end

if isempty(data_support_path)
  data_support_path = gRadar.data_support_path;
end

%% User Settings
% ======================================================================
debug_level = 1;

in_base_path = fullfile(data_support_path,'2012_Greenland_P3');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {}; sync_file_type = {};

gps_source_to_use = 'ATM';

if strcmpi(gps_source_to_use,'ATM')
  %% ATM
  % ======================================================================
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_14Mar12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120314.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',03,'day',14,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120314';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_15Mar12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120315.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',03,'day',15,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120315';
  
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_16Mar12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120316.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',03,'day',16,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120316';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120316','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',03,'day',16,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_17Mar12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120317.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',03,'day',17,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120317';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120317','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',03,'day',17,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_21Mar12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120321.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',03,'day',21,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120321';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_22Mar12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120322.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',03,'day',22,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120322';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120322','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',03,'day',22,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_23Mar12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120323.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',03,'day',23,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120323';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120323','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',03,'day',23,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_26Mar12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120326.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',03,'day',26,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120326';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120326','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',03,'day',26,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_27Mar12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120327.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',03,'day',27,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120327';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120327','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',03,'day',27,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_28Mar12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120328.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',03,'day',28,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120328';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_29Mar12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120329.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',03,'day',29,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120329';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120329','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',03,'day',29,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_30Mar12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120330.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',03,'day',30,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120330';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120330','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',03,'day',30,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_02Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120402.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',02,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120402';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120402','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',02,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_04Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120404.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',04,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120404';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120404','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',04,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_10Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120410.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',10,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120410';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120410','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',10,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_11Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120411.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',11,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120411';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120411','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',11,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_12Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120412.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',12,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120412';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120412','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',12,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_13Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120413.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',13,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120413';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120413','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',13,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_14Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120414.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',14,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120414';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120414','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',14,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_16Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120416.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',16,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120416';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120416','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',16,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_17Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120417.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',17,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120417';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120417','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',17,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_18Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120418.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',18,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120418';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120418','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',18,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_19Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120419.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',19,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120419';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120419','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',19,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_20Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120420.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',20,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120420';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120420','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',20,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_21Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120421.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',21,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120421';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120421','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',21,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_23Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120423.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',23,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120423';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120423','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',23,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_25Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120425.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',25,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120425';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120425','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',25,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_28Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120428.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',28,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120428';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120428','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',28,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_29Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120429.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',29,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120429';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120429','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',29,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_30Apr12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120430.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',04,'day',30,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120430';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120430','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',04,'day',30,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_02May12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120502.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',05,'day',02,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120502';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120502','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',05,'day',02,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_03May12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120503.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',05,'day',03,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120503';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120503','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',05,'day',03,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_04May12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120504.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',05,'day',04,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120504';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120504','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',05,'day',04,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_07May12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120507.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',05,'day',07,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120507';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120507','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',05,'day',07,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_08May12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120508.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',05,'day',08,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120508';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120508','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',05,'day',08,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_09May12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120509.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',05,'day',09,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120509';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120509','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',05,'day',09,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_10May12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120510.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',05,'day',10,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120510';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120510','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',05,'day',10,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_11May12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120511.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',05,'day',11,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120511';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120511','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',05,'day',11,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_14May12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120514.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',05,'day',14,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120514';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120514','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',05,'day',14,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_15May12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120515.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',05,'day',15,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120515';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120515','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',05,'day',15,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_16May12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120516.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',05,'day',16,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120516';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120516','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',05,'day',16,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_17May12_PPPK_P13Jun12.out');
  out_fns{file_idx} = 'gps_20120517.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',05,'day',17,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120517';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120517','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',05,'day',17,'time_reference','utc','format',3);
  
elseif strcmpi(gps_source_to_use,'ATM_field')
  %% ATM_field
  % ======================================================================
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_14Mar12_PPPK.out');
  %   out_fns{file_idx} = 'gps_20120314.mat';
  %   file_type{file_idx} = 'Applanix';
  %   params{file_idx} = struct('year',2012,'month',03,'day',14,'time_reference','utc');
  %   gps_source{file_idx} = 'ATM-PPP_field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120314','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',14,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_15Mar12_PPPK.out');
  %   out_fns{file_idx} = 'gps_20120315.mat';
  %   file_type{file_idx} = 'Applanix';
  %   params{file_idx} = struct('year',2012,'month',03,'day',15,'time_reference','utc');
  %   gps_source{file_idx} = 'ATM-PPP_field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120315','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',15,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_16Mar12_PPPK.out');
  %   out_fns{file_idx} = 'gps_20120316.mat';
  %   file_type{file_idx} = 'Applanix';
  %   params{file_idx} = struct('year',2012,'month',03,'day',16,'time_reference','utc');
  %   gps_source{file_idx} = 'ATM-PPP_field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120316','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',16,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_17Mar12_PPPK.out');
  %   out_fns{file_idx} = 'gps_20120317.mat';
  %   file_type{file_idx} = 'Applanix';
  %   params{file_idx} = struct('year',2012,'month',03,'day',17,'time_reference','utc');
  %   gps_source{file_idx} = 'ATM-PPP_field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120317','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',17,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_19Mar12_PPPK.out');
  %   out_fns{file_idx} = 'gps_20120319.mat';
  %   file_type{file_idx} = 'Applanix';
  %   params{file_idx} = struct('year',2012,'month',03,'day',19,'time_reference','utc');
  %   gps_source{file_idx} = 'ATM-PPP_field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120319','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',19,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_21Mar12_PPPK.out');
  %   out_fns{file_idx} = 'gps_20120321.mat';
  %   file_type{file_idx} = 'Applanix';
  %   params{file_idx} = struct('year',2012,'month',03,'day',21,'time_reference','utc');
  %   gps_source{file_idx} = 'ATM-PPP_field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120321','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',21,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_22Mar12_PPPK.out');
  %   out_fns{file_idx} = 'gps_20120322.mat';
  %   file_type{file_idx} = 'Applanix';
  %   params{file_idx} = struct('year',2012,'month',03,'day',22,'time_reference','utc');
  %   gps_source{file_idx} = 'ATM-PPP_field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120322','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',22,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_23Mar12_PPPK.out');
  %   out_fns{file_idx} = 'gps_20120323.mat';
  %   file_type{file_idx} = 'Applanix';
  %   params{file_idx} = struct('year',2012,'month',03,'day',23,'time_reference','utc');
  %   gps_source{file_idx} = 'ATM-PPP_field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120323','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',23,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_26Mar12_PPPK.out');
  %   out_fns{file_idx} = 'gps_20120326.mat';
  %   file_type{file_idx} = 'Applanix';
  %   params{file_idx} = struct('year',2012,'month',03,'day',26,'time_reference','utc');
  %   gps_source{file_idx} = 'ATM-PPP_field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120326','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',26,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_27Mar12_PPPK.out');
  %   out_fns{file_idx} = 'gps_20120327.mat';
  %   file_type{file_idx} = 'Applanix';
  %   params{file_idx} = struct('year',2012,'month',03,'day',27,'time_reference','utc');
  %   gps_source{file_idx} = 'ATM-PPP_field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120327','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',27,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_28Mar12_PPPK.out');
  %   out_fns{file_idx} = 'gps_20120328.mat';
  %   file_type{file_idx} = 'Applanix';
  %   params{file_idx} = struct('year',2012,'month',03,'day',28,'time_reference','utc');
  %   gps_source{file_idx} = 'ATM-PPP_field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120328','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',28,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_29Mar12_PPPK.out');
  %   out_fns{file_idx} = 'gps_20120329.mat';
  %   file_type{file_idx} = 'Applanix';
  %   params{file_idx} = struct('year',2012,'month',03,'day',29,'time_reference','utc');
  %   gps_source{file_idx} = 'ATM-PPP_field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120329','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',29,'time_reference','utc','format',3);
  
elseif strcmpi(gps_source_to_use,'NMEA')
  %% NMEA
  % ======================================================================
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20120314NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20120314.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2012,'month',05,'day',14,'format',1,'time_reference','utc');
  %     gps_source{file_idx} = 'NMEA-field';
  %
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20120315NMEA_INGGA.TXT');
  %     out_fns{file_idx} = 'gps_20120315.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2012,'month',03,'day',15,'format',1,'time_reference','utc');
  %     gps_source{file_idx} = 'NMEA-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'20120317NMEA_GPGGA.txt');
  out_fns{file_idx} = 'gps_20120317.mat';
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',2012,'month',03,'day',17,'format',1,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120317','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',03,'day',17,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20120321NMEA_GPGGA.TXT');
  %     out_fns{file_idx} = 'gps_20120321.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2012,'month',03,'day',21,'format',1,'time_reference','utc');
  %     gps_source{file_idx} = 'NMEA-field';
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120322NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120322.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2012,'month',03,'day',22,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'NMEA-field';
  
  %     file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120326NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120326.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',03,'day',26,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120326','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',26,'time_reference','utc','format',3);
  
  %       file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120327NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120327.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',03,'day',27,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120327','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',27,'time_reference','utc','format',3);
  
  %       file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120328NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120328.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2012,'month',03,'day',28,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  
  %         file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120329NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120329.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',03,'day',29,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120329','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',29,'time_reference','utc','format',3);
  
  %         file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120330NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120330.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',03,'day',30,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120330','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',30,'time_reference','utc','format',3);
  
  %         file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120402NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120402.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',02,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120402','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',02,'time_reference','utc','format',3);
  
  %          file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120404NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120404.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',04,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120404','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',04,'time_reference','utc','format',3);
  
  %            file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120410NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120410.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',10,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120410','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',10,'time_reference','utc','format',3);
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120411NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120411.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',11,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120411','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',11,'time_reference','utc','format',3);
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120412NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120412.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',12,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120412','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',12,'time_reference','utc','format',3);
  %
  %     file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120413NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120413.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',13,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120413','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',13,'time_reference','utc','format',3);
  %
  %       file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120414NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120414.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',14,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120414','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',14,'time_reference','utc','format',3);
  
  %       file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120416NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120416.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',16,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120416','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',16,'time_reference','utc','format',3);
  
  %       file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120417NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120417.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',17,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120417','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',17,'time_reference','utc','format',3);
  
  %         file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120418NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120418.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',18,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120418','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',18,'time_reference','utc','format',3);
  
  %           file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120419NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120419.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',19,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120419','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',19,'time_reference','utc','format',3);
  
  %             file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120420NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120420.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',20,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120420','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',20,'time_reference','utc','format',3);
  
  %             file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120421NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120421.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',21,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120421','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',21,'time_reference','utc','format',3);
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120423NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120423.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',23,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120423','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',23,'time_reference','utc','format',3);
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120425NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120425.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',25,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120425','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',25,'time_reference','utc','format',3);
  
  %    file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120428NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120428.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',28,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120428','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',28,'time_reference','utc','format',3);
  %
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20120429NMEA_GPGGA.TXT');
  % out_fns{file_idx} = 'gps_20120429.mat';
  % file_type{file_idx} = 'MCRDS_NMEA';
  % params{file_idx} = struct('year',2012,'month',04,'day',29,'format',1,'time_reference','utc');
  % gps_source{file_idx} = 'nmea-field';
  % sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120429','','.gps');
  % sync_params{file_idx} = struct('year',2012,'month',04,'day',29,'time_reference','utc','format',3);
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120430NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120430.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',04,'day',30,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120430','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',30,'time_reference','utc','format',3);
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120502NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120502.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',05,'day',02,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120502','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',02,'time_reference','utc','format',3);
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120503NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120503.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',05,'day',03,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120503','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',03,'time_reference','utc','format',3);
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120504NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120504.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',05,'day',04,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120504','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',04,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120507NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120507.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',05,'day',07,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120507','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',07,'time_reference','utc','format',3);
  
  %    file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120508NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120508.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',05,'day',08,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120508','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',08,'time_reference','utc','format',3);
  
  %    file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120509NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120509.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',05,'day',09,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120509','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',09,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120510NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120510.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',05,'day',10,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120510','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',10,'time_reference','utc','format',3);
  %
  %    file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120511NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120511.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',05,'day',11,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120511','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',11,'time_reference','utc','format',3);
  
  %    file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120514NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120514.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',05,'day',14,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120514','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',14,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120515NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120515.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',05,'day',15,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120515','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',15,'time_reference','utc','format',3);
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120516NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120516.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',05,'day',16,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120516','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',16,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20120517NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20120517.mat';
  %   file_type{file_idx} = 'MCRDS_NMEA';
  %   params{file_idx} = struct('year',2012,'month',05,'day',17,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'nmea-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120517','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',17,'time_reference','utc','format',3);
  %
  % %
elseif strcmpi(gps_source_to_use,'DMS')
  %% DMS
  % ======================================================================
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'05March12_Real-time_Trajectory.csv');
  %   out_fns{file_idx} = 'gps_20120305.mat';
  %   file_type{file_idx} = 'DMSraw';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'DMS-raw';
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'16March2012_Real-time_Trajectory.csv');
  %   out_fns{file_idx} = 'gps_20120316.mat';
  %   file_type{file_idx} = 'DMSraw';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'DMS-raw';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'26Mar2012_Real-Time_trajectory.csv');
  out_fns{file_idx} = 'gps_20120326.mat';
  file_type{file_idx} = 'MCRDS_DMSraw';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'DMS-raw';
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120326','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',03,'day',26,'time_reference','utc','format',3);
elseif strcmpi(gps_source_to_use,'Gravimeter')
  %% Gravimeter
  % ======================================================================
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_200.xyz');
  %   out_fns{file_idx} = 'gps_20120312.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_201.xyz');
  %   out_fns{file_idx} = 'gps_20120314.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_202.xyz');
  %   out_fns{file_idx} = 'gps_20120315.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_203.xyz');
  %   out_fns{file_idx} = 'gps_20120316.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120316','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',16,'time_reference','utc','format',3);
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_204.xyz');
  %   out_fns{file_idx} = 'gps_20120317.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120317','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',17,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_205.xyz');
  %   out_fns{file_idx} = 'gps_20120319.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_206.xyz');
  %   out_fns{file_idx} = 'gps_20120321.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_207.xyz');
  %   out_fns{file_idx} = 'gps_20120322.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120322','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',22,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_208.xyz');
  %   out_fns{file_idx} = 'gps_20120323.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120323','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',23,'time_reference','utc','format',3);
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_209.xyz');
  %   out_fns{file_idx} = 'gps_20120326_check_for_errors_gravimeter.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120326','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',26,'time_reference','utc','format',3);
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_210.xyz');
  %   out_fns{file_idx} = 'gps_20120327.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120327','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',27,'time_reference','utc','format',3);
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_211.xyz');
  %   out_fns{file_idx} = 'gps_20120328.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  
  %     file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_212.xyz');
  %   out_fns{file_idx} = 'gps_20120329.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120329','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',29,'time_reference','utc','format',3);
  %
  %
  %     file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_213.xyz');
  %   out_fns{file_idx} = 'gps_20120330.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120330','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',03,'day',30,'time_reference','utc','format',3);
  %
  %
  %     file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_214.xyz');
  %   out_fns{file_idx} = 'gps_20120402.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120402','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',02,'time_reference','utc','format',3);
  %
  %     file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_215.xyz');
  %   out_fns{file_idx} = 'gps_20120404.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120404','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',04,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_216.xyz');
  %   out_fns{file_idx} = 'gps_20120410.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120410','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',10,'time_reference','utc','format',3);
  %
  %       file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_217.xyz');
  %   out_fns{file_idx} = 'gps_20120411.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120411','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',11,'time_reference','utc','format',3);
  %
  %       file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_218.xyz');
  %   out_fns{file_idx} = 'gps_20120412.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120412','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',12,'time_reference','utc','format',3);
  %
  %       file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_219.xyz');
  %   out_fns{file_idx} = 'gps_20120413.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120413','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',13,'time_reference','utc','format',3);
  %
  %       file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_220.xyz');
  %   out_fns{file_idx} = 'gps_20120414.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120414','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',14,'time_reference','utc','format',3);
  %
  %       file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_221.xyz');
  %   out_fns{file_idx} = 'gps_20120416.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120416','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',16,'time_reference','utc','format',3);
  %
  %       file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_222.xyz');
  %   out_fns{file_idx} = 'gps_20120417.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120417','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',17,'time_reference','utc','format',3);
  %
  %       file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_224.xyz');
  %   out_fns{file_idx} = 'gps_20120418.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120418','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',18,'time_reference','utc','format',3);
  %
  %       file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_225.xyz');
  %   out_fns{file_idx} = 'gps_20120419.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120419','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',19,'time_reference','utc','format',3);
  %
  %       file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_226.xyz');
  %   out_fns{file_idx} = 'gps_20120420.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120420','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',20,'time_reference','utc','format',3);
  %
  %       file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_227.xyz');
  %   out_fns{file_idx} = 'gps_20120421.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120421','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',21,'time_reference','utc','format',3);
  %
  %      file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_228.xyz');
  %   out_fns{file_idx} = 'gps_20120423.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120423','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',23,'time_reference','utc','format',3);
  %
  %      file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_229.xyz');
  %   out_fns{file_idx} = 'gps_20120425.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120425','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',25,'time_reference','utc','format',3);
  
  %      file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_230.xyz');
  %   out_fns{file_idx} = 'gps_20120428.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120428','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',28,'time_reference','utc','format',3);
  %
  %    file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_232.xyz');
  %   out_fns{file_idx} = 'gps_20120430.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120430','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',04,'day',30,'time_reference','utc','format',3);
  %
  %    file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_233.xyz');
  %   out_fns{file_idx} = 'gps_20120502.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120502','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',02,'time_reference','utc','format',3);
  %
  %    file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_234.xyz');
  %   out_fns{file_idx} = 'gps_20120503.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120503','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',03,'time_reference','utc','format',3);
  
  %    file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_235.xyz');
  %   out_fns{file_idx} = 'gps_20120504.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120504','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',04,'time_reference','utc','format',3);
  
  %    file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_236.xyz');
  %   out_fns{file_idx} = 'gps_20120507.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120507','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',07,'time_reference','utc','format',3);
  
  
  %    file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_237.xyz');
  %   out_fns{file_idx} = 'gps_20120508.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120508','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',08,'time_reference','utc','format',3);
  
  %    file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_238.xyz');
  %   out_fns{file_idx} = 'gps_20120509.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120509','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',09,'time_reference','utc','format',3);
  %
  %     file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_239.xyz');
  %   out_fns{file_idx} = 'gps_20120510.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120510','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',10,'time_reference','utc','format',3);
  
  %    file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_240.xyz');
  %   out_fns{file_idx} = 'gps_20120511.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120511','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',11,'time_reference','utc','format',3);
  %
  
  %    file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_241.xyz');
  %   out_fns{file_idx} = 'gps_20120514.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120514','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',14,'time_reference','utc','format',3);
  
  %    file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_242.xyz');
  %   out_fns{file_idx} = 'gps_20120515.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120515','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',15,'time_reference','utc','format',3);
  
  %     file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_243.xyz');
  %   out_fns{file_idx} = 'gps_20120516.mat';
  %   file_type{file_idx} = 'MCRDS_TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120516','','.gps');
  %   sync_params{file_idx} = struct('year',2012,'month',05,'day',16,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_244.xyz');
  out_fns{file_idx} = 'gps_20120517.mat';
  file_type{file_idx} = 'MCRDS_TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20120517','','.gps');
  sync_params{file_idx} = struct('year',2012,'month',05,'day',17,'time_reference','utc','format',3);
  
  
end

%% gps_create
% ======================================================================
gps_create;

% Hand correction of gps_20120317 accum2 sync radar time information
hand_idx = strmatch('gps_20120317.mat',out_fns);
if ~isempty(hand_idx)
  % No radar time was recorded in this GPS file because software was still
  % being developed
  out_fn = fullfile(gps_path,out_fns{hand_idx});
  fprintf('Hand update of %s\n', out_fn);
  gps = load(out_fn);
  % gps.radar_time = 15 + gps.sync_gps_time - gps.gps_time(1); % original correction when loading NMEA data???
  gps.radar_time = gps.sync_gps_time - gps.sync_gps_time(1) - 6965;
  save(out_fn,'-v6','-struct','gps');
end

% Smooth ATM INS data
for idx = 1:length(file_type)
  out_fn = fullfile(gps_path,out_fns{idx});
  
  gps = load(out_fn);
  if regexpi(gps.gps_source,'atm')
    
    warning('Smoothing INS data: %s', out_fn);
    
    gps.roll = sgolayfilt(gps.roll,2,101); % Adjust filter length as needed to remove high frequency noise
    gps.pitch = sgolayfilt(gps.pitch,2,101); % Adjust filter length as needed to remove high frequency noise
    heading_x = cos(gps.heading);
    heading_y = sin(gps.heading);
    heading_x  = sgolayfilt(heading_x,2,101); % Adjust filter length as needed to remove high frequency noise
    heading_y  = sgolayfilt(heading_y,2,101); % Adjust filter length as needed to remove high frequency noise
    gps.heading = atan2(heading_y,heading_x);
    
    save(out_fn,'-append','-struct','gps','roll','pitch','heading');
  end
end

