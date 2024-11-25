% script gps_create_2011_greenland_P3_GPS
%
% Makes the GPS files for 2011 Greenland P3 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2011_Greenland_P3');
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

in_base_path = fullfile(data_support_path,'2011_Greenland_P3');
gps_path = fullfile(support_path,'gps','2011_Greenland_P3');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {};

gps_source_to_use = 'ATM';
if strcmp(gps_source_to_use,'ATM')
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'ATM_Applanix_20110310.out');
  % out_fns{file_idx} = 'gps_20110310.mat';
  % file_type{file_idx} = 'Applanix';
  % params{file_idx} = struct('year',2011,'month',03,'day',10,'time_reference','utc');
  % gps_source{file_idx} = 'ATM-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_09Mar11_PPPK.out');
  out_fns{file_idx} = 'gps_20110309.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',03,'day',09,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_14Mar11_PPPK.out');
  out_fns{file_idx} = 'gps_20110314.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',03,'day',14,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_16Mar11_PPPK.out');
  out_fns{file_idx} = 'gps_20110316.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',03,'day',16,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_17Mar11_PPPK.out');
  out_fns{file_idx} = 'gps_20110317.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',03,'day',17,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_18Mar11_PPPK.out');
  out_fns{file_idx} = 'gps_20110318.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',03,'day',18,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_22Mar11_PPPK.out');
  out_fns{file_idx} = 'gps_20110322.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',03,'day',22,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_23Mar11_PPPK.out');
  out_fns{file_idx} = 'gps_20110323.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',03,'day',23,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_25Mar11_PPPK.out');
  out_fns{file_idx} = 'gps_20110325.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',03,'day',25,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_26Mar11_PPPK.out');
  out_fns{file_idx} = 'gps_20110326.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',03,'day',26,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_28Mar11_PPPK.out');
  out_fns{file_idx} = 'gps_20110328.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',03,'day',28,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_29Mar11_PPPK.out');
  out_fns{file_idx} = 'gps_20110329.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',03,'day',29,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_31Mar11_PPPK.out');
  out_fns{file_idx} = 'gps_20110331.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',03,'day',31,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_06Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110406.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',06,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_07Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110407.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',07,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_08Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110408.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',08,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_09Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110409.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',09,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_11Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110411.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',11,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_12Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110412.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',12,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_13Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110413.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',13,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_14Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110414.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',14,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_15Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110415.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',15,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_16Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110416.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',16,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_18Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110418.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',18,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_19Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110419.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',19,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_22Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110422.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',22,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_23Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110423.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',23,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_25Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110425.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',25,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_26Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110426.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',26,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_28Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110428.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',28,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_29Apr11_PPPK.out');
  out_fns{file_idx} = 'gps_20110429.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',04,'day',29,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_02May11_PPPK.out');
  out_fns{file_idx} = 'gps_20110502.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',05,'day',02,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_04May11_PPPK.out');
  out_fns{file_idx} = 'gps_20110504.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',05,'day',04,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_05May11_PPPK.out');
  out_fns{file_idx} = 'gps_20110505.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',05,'day',05,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_06May11_PPPK.out');
  out_fns{file_idx} = 'gps_20110506.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',05,'day',06,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_07May11_PPPK.out');
  out_fns{file_idx} = 'gps_20110507.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',05,'day',07,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_09May11_PPPK.out');
  out_fns{file_idx} = 'gps_20110509.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',05,'day',09,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_10May11_PPPK.out');
  out_fns{file_idx} = 'gps_20110510.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',05,'day',10,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_11May11_PPPK.out');
  out_fns{file_idx} = 'gps_20110511.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',05,'day',11,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_12May11_PPPK.out');
  out_fns{file_idx} = 'gps_20110512.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',05,'day',12,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_13May11_PPPK.out');
  out_fns{file_idx} = 'gps_20110513.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',05,'day',13,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_16May11_PPPK.out');
  out_fns{file_idx} = 'gps_20110516.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',05,'day',16,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20110820';

elseif strcmp(gps_source_to_use,'NMEA')
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110329NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110329.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',03,'day',29,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110331NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110331.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',03,'day',31,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110406NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110406.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',06,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110407NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110407.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',07,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110408NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110408.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',08,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110409NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110409.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',09,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110412NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110412.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',12,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  %
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110413NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110413.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',13,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  %
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110414NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110414.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',14,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110415NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110415.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',15,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110416NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110416.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',16,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110418NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110418.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',18,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110419NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110419.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',19,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110422NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110422.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',22,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110423NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110423.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',23,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110425NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110425.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',25,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110426NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110426.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',26,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110428NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110428.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',28,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  %
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110429NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110429.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',04,'day',29,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110502NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110502.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',05,'day',02,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110505NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110505.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',05,'day',05,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110506NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110506.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',05,'day',06,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110507NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110507.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',05,'day',07,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110509NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110509.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',05,'day',09,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110510NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110510.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',05,'day',10,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110511NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110511.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',05,'day',11,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110512NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110512.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',05,'day',12,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110513NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110513.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',05,'day',13,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'20110516NMEA.TXT');
  % out_fns{file_idx} = 'gps_20110516.mat';
  % file_type{file_idx} = 'NMEA';
  % params{file_idx} = struct('year',2011,'month',05,'day',16,'time_reference','utc','nmea_tag','$GPGGA');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'gps_20110415.csv');
  % out_fns{file_idx} = 'gps_20110415.mat';
  % file_type{file_idx} = 'csv';
  % params{file_idx} = struct('time_reference','utc');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'gps_20110416.csv');
  % out_fns{file_idx} = 'gps_20110416.mat';
  % file_type{file_idx} = 'csv';
  % params{file_idx} = struct('time_reference','utc');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'gps_20110418.csv');
  % out_fns{file_idx} = 'gps_20110418.mat';
  % file_type{file_idx} = 'csv';
  % params{file_idx} = struct('time_reference','utc');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'gps_20110419.csv');
  % out_fns{file_idx} = 'gps_20110419.mat';
  % file_type{file_idx} = 'csv';
  % params{file_idx} = struct('time_reference','utc');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'gps_20110422.csv');
  % out_fns{file_idx} = 'gps_20110422.mat';
  % file_type{file_idx} = 'csv';
  % params{file_idx} = struct('time_reference','utc');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'gps_20110425.csv');
  % out_fns{file_idx} = 'gps_20110425.mat';
  % file_type{file_idx} = 'csv';
  % params{file_idx} = struct('time_reference','utc');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'gps_20110426.csv');
  % out_fns{file_idx} = 'gps_20110426.mat';
  % file_type{file_idx} = 'csv';
  % params{file_idx} = struct('time_reference','utc');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'gps_20110428.csv');
  % out_fns{file_idx} = 'gps_20110428.mat';
  % file_type{file_idx} = 'csv';
  % params{file_idx} = struct('time_reference','utc');
  % gps_source{file_idx} = 'NMEA';
  %
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'gps_20110429.csv');
  % out_fns{file_idx} = 'gps_20110429.mat';
  % file_type{file_idx} = 'csv';
  % params{file_idx} = struct('time_reference','utc');
  % gps_source{file_idx} = 'NMEA';
  
  % file_idx = file_idx + 1;
  % in_fns{file_idx} = fullfile(in_base_path,'110411.traj');
  % out_fns{file_idx} = 'gps_20110411.mat';
  % file_type{file_idx} = 'Traj';
  % params{file_idx} = struct('time_reference','utc');
  % gps_source{file_idx} = 'NMEA';
  
elseif strcmp(gps_source_to_use,'gravimeter')
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_001.xyz');
  out_fns{file_idx} = 'gps_20110314.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_002.xyz');
  out_fns{file_idx} = 'gps_20110316.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_003.xyz');
  out_fns{file_idx} = 'gps_20110317.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_004.xyz');
  out_fns{file_idx} = 'gps_20110318.mat';4
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_005.xyz');
  out_fns{file_idx} = 'gps_20110322.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_006.xyz');
  out_fns{file_idx} = 'gps_20110323.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_007.xyz');
  out_fns{file_idx} = 'gps_20110325.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_008.xyz');
  out_fns{file_idx} = 'gps_20110326.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_009.xyz');
  out_fns{file_idx} = 'gps_20110328.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('year',2011,'month',3','day',28,'time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_010.xyz');
  out_fns{file_idx} = 'gps_20110329.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_011.xyz');
  out_fns{file_idx} = 'gps_20110331.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_012.xyz');
  out_fns{file_idx} = 'gps_20110406.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_013.xyz');
  out_fns{file_idx} = 'gps_20110407.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_014.xyz');
  out_fns{file_idx} = 'gps_20110408.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_015.xyz');
  out_fns{file_idx} = 'gps_20110409.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_016.xyz');
  out_fns{file_idx} = 'gps_20110411.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_017.xyz');
  out_fns{file_idx} = 'gps_20110412.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_018.xyz');
  out_fns{file_idx} = 'gps_20110413.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_019.xyz');
  out_fns{file_idx} = 'gps_20110414.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_020.xyz');
  out_fns{file_idx} = 'gps_20110415.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_021.xyz');
  out_fns{file_idx} = 'gps_20110416.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_022.xyz');
  out_fns{file_idx} = 'gps_20110418.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_023.xyz');
  out_fns{file_idx} = 'gps_20110419.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_024.xyz');
  out_fns{file_idx} = 'gps_20110422.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_025.xyz');
  out_fns{file_idx} = 'gps_20110423.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_026.xyz');
  out_fns{file_idx} = 'gps_20110425.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_027.xyz');
  out_fns{file_idx} = 'gps_20110426.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_028.xyz');
  out_fns{file_idx} = 'gps_20110428.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_029.xyz');
  out_fns{file_idx} = 'gps_20110429.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_030.xyz');
  out_fns{file_idx} = 'gps_20110502.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_031.xyz');
  out_fns{file_idx} = 'gps_20110504.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_032.xyz');
  out_fns{file_idx} = 'gps_20110505.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_033.xyz');
  out_fns{file_idx} = 'gps_20110506.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_034.xyz');
  out_fns{file_idx} = 'gps_20110507.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_035.xyz');
  out_fns{file_idx} = 'gps_20110509.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_036.xyz');
  out_fns{file_idx} = 'gps_20110510.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_037.xyz');
  out_fns{file_idx} = 'gps_20110511.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_038.xyz');
  out_fns{file_idx} = 'gps_20110512.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_039.xyz');
  out_fns{file_idx} = 'gps_20110513.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_040.xyz');
  out_fns{file_idx} = 'gps_20110516.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

if any(strcmpi('gps_20110328.mat',out_fns))
  file_idx = find(strcmpi('gps_20110328.mat',out_fns))  
  
  if strcmpi(gps_source_to_use,'ATM')
    % Fill gap in ATM data
    gps2 = read_gps_txt('/cresis/snfs1/dataproducts/metadata/2011_Greenland_P3/AIRGrav_Attitude_Flight_009.xyz', ...
      struct('year',2011,'month',3,'day',28,'time_reference','utc'));
    hack_fn = fullfile(gps_path,out_fns{file_idx});
    gps = load(hack_fn);
    start_idx = find(gps.gps_time > 1.301321775068589e+09,1);
    stop_idx = find(gps.gps_time > 1.301322232266553e+09,1);
    start_gps_time = gps.gps_time(start_idx);
    stop_gps_time = gps.gps_time(stop_idx);
    splice_idxs = find(gps2.gps_time > start_gps_time & gps2.gps_time < stop_gps_time);
    keep_idxs = [1:start_idx-1, stop_idx+1:length(gps.gps_time)];
    new_gps = [];
    new_gps.gps_time = [gps.gps_time(1:start_idx-1), ...
      gps2.gps_time(splice_idxs), gps.gps_time(stop_idx+1:end)];
    % To prevent a jump in the GPS data we adjust the spliced in values
    % based on a linear interpolation of their mismatch with the ATM data
    % at the two splice end points.
    error = interp1(gps.gps_time,gps.lat,gps2.gps_time(splice_idxs([1 end]))) ...
      - gps2.lat(splice_idxs([1 end]));
    error_fix = interp1(gps2.gps_time(splice_idxs([1 end])), error, gps2.gps_time(splice_idxs));
    new_gps.lat = [gps.lat(1:start_idx-1), ...
      gps2.lat(splice_idxs) + error_fix, gps.lat(stop_idx+1:end)];
    
    error = interp1(gps.gps_time,gps.lon,gps2.gps_time(splice_idxs([1 end]))) ...
      - gps2.lon(splice_idxs([1 end]));
    error_fix = interp1(gps2.gps_time(splice_idxs([1 end])), error, gps2.gps_time(splice_idxs));
    new_gps.lon = [gps.lon(1:start_idx-1), ...
      gps2.lon(splice_idxs) + error_fix, gps.lon(stop_idx+1:end)];
    
    error = interp1(gps.gps_time,gps.elev,gps2.gps_time(splice_idxs([1 end]))) ...
      - gps2.elev(splice_idxs([1 end]));
    error_fix = interp1(gps2.gps_time(splice_idxs([1 end])), error, gps2.gps_time(splice_idxs));
    new_gps.elev = [gps.elev(1:start_idx-1), ...
      gps2.elev(splice_idxs) + error_fix, gps.elev(stop_idx+1:end)];
    
    error = interp1(gps.gps_time,gps.roll,gps2.gps_time(splice_idxs([1 end]))) ...
      - gps2.roll(splice_idxs([1 end]));
    error_fix = interp1(gps2.gps_time(splice_idxs([1 end])), error, gps2.gps_time(splice_idxs));
    new_gps.roll = [gps.roll(1:start_idx-1), ...
      gps2.roll(splice_idxs) + error_fix, gps.roll(stop_idx+1:end)];
    
    error = interp1(gps.gps_time,gps.pitch,gps2.gps_time(splice_idxs([1 end]))) ...
      - gps2.pitch(splice_idxs([1 end]));
    error_fix = interp1(gps2.gps_time(splice_idxs([1 end])), error, gps2.gps_time(splice_idxs));
    new_gps.pitch = [gps.pitch(1:start_idx-1), ...
      gps2.pitch(splice_idxs) + error_fix, gps.pitch(stop_idx+1:end)];
    
    error = interp1(gps.gps_time,gps.heading,gps2.gps_time(splice_idxs([1 end]))) ...
      - gps2.heading(splice_idxs([1 end]));
    error_fix = interp1(gps2.gps_time(splice_idxs([1 end])), error, gps2.gps_time(splice_idxs));
    new_gps.heading = [gps.heading(1:start_idx-1), ...
      gps2.heading(splice_idxs) + error_fix, gps.heading(stop_idx+1:end)];
    new_gps.gps_source = 'ATM-final_20110820wGravFill';
    save(hack_fn,'-v6','-struct','new_gps');
  end
end
