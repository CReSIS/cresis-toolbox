% script gps_create_2012_antarctica_DC8
%
% Makes the GPS files for 2012 Antarctica DC8 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2012_Antarctica_DC8');
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

in_base_path = fullfile(data_support_path,'2012_Antarctica_DC8');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'ATM';

if strcmp(gps_source_to_use,'ATM')
  %% ATM DATA
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_02Oct12_PPPK_P15Nov12.out');
  out_fns{file_idx} = 'gps_20121002.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',10,'day',02,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_03Oct12_PPPK_P06Dec12.out');
  out_fns{file_idx} = 'gps_20121003.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',10,'day',03,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_12Oct12_PPPK_P15Nov12.out');
  out_fns{file_idx} = 'gps_20121012.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',10,'day',12,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_13Oct12_PPPK_P15Nov12.out');
  out_fns{file_idx} = 'gps_20121013.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',10,'day',13,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_15Oct12_PPPK_P15Nov12.out');
  out_fns{file_idx} = 'gps_20121015.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',10,'day',15,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_16Oct12_PPPK_P15Nov12.out');
  out_fns{file_idx} = 'gps_20121016.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',10,'day',16,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_18Oct12_PPPK_P19Nov12.out');
  out_fns{file_idx} = 'gps_20121018.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',10,'day',18,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_19Oct12_PPPK_P19Nov12.out');
  out_fns{file_idx} = 'gps_20121019.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',10,'day',19,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_22Oct12_PPPK_P19Nov12.out');
  out_fns{file_idx} = 'gps_20121022.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',10,'day',22,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_23Oct12_PPPK_P19Nov12.out');
  out_fns{file_idx} = 'gps_20121023.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',10,'day',23,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_25Oct12_PPPK_P19Nov12.out');
  out_fns{file_idx} = 'gps_20121025.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',10,'day',25,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_27Oct12_PPPK_P19Nov12.out');
  out_fns{file_idx} = 'gps_20121027.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',10,'day',27,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_28Oct12_PPPK_P20Nov12.out');
  out_fns{file_idx} = 'gps_20121028.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',10,'day',28,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_01Nov12_PPPK_P20Nov12.out');
  out_fns{file_idx} = 'gps_20121101.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',11,'day',01,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_02Nov12_PPPK_P20Nov12.out');
  out_fns{file_idx} = 'gps_20121102.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',11,'day',02,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_04Nov12_PPPK_P20Nov12.out');
  out_fns{file_idx} = 'gps_20121104.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',11,'day',04,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_06Nov12_PPPK_P21Nov12.out');
  out_fns{file_idx} = 'gps_20121106.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',11,'day',06,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_07Nov12_PPPK_P26Nov12.out');
  out_fns{file_idx} = 'gps_20121107.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',11,'day',07,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_09Nov12_PPPK_P26Nov12.out');
  out_fns{file_idx} = 'gps_20121109.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2012,'month',11,'day',09,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20121217';
  sync_flag{file_idx} = 0;
  
elseif strcmpi(gps_source_to_use,'NMEA')
  %% NMEA DATA
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20121002NMEA.TXT');
  %   out_fns{file_idx} = 'gps_20121002.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2012,'month',10,'day',02,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'NMEA-field';
  %   sync_flag{file_idx} = 0;
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20121013NMEA.TXT');
  %   out_fns{file_idx} = 'gps_20121013.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2012,'month',10,'day',13,'format',1,'time_reference','utc','nmea_tag','$GPGGA');
  %   gps_source{file_idx} = 'NMEA-field';
  %   sync_flag{file_idx} = 0;
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20121018NMEA.TXT');
  %   out_fns{file_idx} = 'gps_20121018.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2012,'month',10,'day',18,'format',1,'time_reference','utc','nmea_tag','$GPGGA');
  %   gps_source{file_idx} = 'NMEA-field';
  %   sync_flag{file_idx} = 0;
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20121019NMEA.TXT');
  %   out_fns{file_idx} = 'gps_20121019.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2012,'month',10,'day',19,'format',1,'time_reference','utc','nmea_tag','$GPGGA');
  %   gps_source{file_idx} = 'NMEA-field';
  %   sync_flag{file_idx} = 0;
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20121023NMEA.TXT');
  %   out_fns{file_idx} = 'gps_20121023.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2012,'month',10,'day',23,'format',1,'time_reference','utc','nmea_tag','$GPGGA');
  %   gps_source{file_idx} = 'NMEA-field';
  %   sync_flag{file_idx} = 0;
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20121028NMEA.TXT');
  %   out_fns{file_idx} = 'gps_20121028.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2012,'month',10,'day',28,'format',1,'time_reference','utc','nmea_tag','$GPGGA');
  %   gps_source{file_idx} = 'NMEA-field';
  %   sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'20121104NMEA.TXT');
  out_fns{file_idx} = 'gps_20121104.mat';
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',2012,'month',11,'day',04,'format',1,'time_reference','utc','nmea_tag','$GPGGA');
  gps_source{file_idx} = 'NMEA-field';
  sync_flag{file_idx} = 0;
  
elseif strcmpi(gps_source_to_use,'gravimeter')
  %% Gravimeter DATA
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_301.xyz');
  %   out_fns{file_idx} = 'gps_20121012.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravmeter-field';
  %   sync_flag{file_idx} = 0;
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_302.xyz');
  %   out_fns{file_idx} = 'gps_20121013.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_flag{file_idx} = 0;
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_303.xyz');
  %   out_fns{file_idx} = 'gps_20121015.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_flag{file_idx} = 0;
  %
  %   %%% GRAVIMETER ERROR: no 304 file (20121016)
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_305.xyz');
  %   out_fns{file_idx} = 'gps_20121018.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_flag{file_idx} = 0;
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_306.xyz');
  %   out_fns{file_idx} = 'gps_20121019.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_flag{file_idx} = 0;
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_307.xyz');
  %   out_fns{file_idx} = 'gps_20121022.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_flag{file_idx} = 0;
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_308.xyz');
  %   out_fns{file_idx} = 'gps_20121023.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_flag{file_idx} = 0;
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_309.xyz');
  %   out_fns{file_idx} = 'gps_20121025.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_flag{file_idx} = 0;
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_310.xyz');
  %   out_fns{file_idx} = 'gps_20121027.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_flag{file_idx} = 0;
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_311.xyz');
  %   out_fns{file_idx} = 'gps_20121028.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_flag{file_idx} = 0;
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_312.xyz');
  %   out_fns{file_idx} = 'gps_20121101.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %   sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_313.xyz');
  out_fns{file_idx} = 'gps_20121102.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_314.xyz');
  out_fns{file_idx} = 'gps_20121104.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_315.xyz');
  out_fns{file_idx} = 'gps_20121106.mat';
  file_type{file_idx} = 'TXT';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'gravimeter-field';
  sync_flag{file_idx} = 0;
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_314.xyz');
  %     out_fns{file_idx} = 'gps_20121107.mat';
  %     file_type{file_idx} = 'TXT';
  %     params{file_idx} = struct('time_reference','utc');
  %     gps_source{file_idx} = 'gravimeter-field';
  %     sync_flag{file_idx} = 0;
  
elseif strcmpi(gps_source_to_use,'reveal')
  %% Reveal DATA
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'IWG1_20121002.txt');
  %   out_fns{file_idx} = 'gps_20121002.mat';
  %   file_type{file_idx} = 'reveal';
  %   params{file_idx} = struct('year',2012,'month',10,'day',02,'time_reference','utc');
  %   gps_source{file_idx} = 'reveal-field';
  %   sync_flag{file_idx} = 0;
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'IWG1_10Oct2012-1614.txt');
  %   out_fns{file_idx} = 'gps_20121010.mat';
  %   file_type{file_idx} = 'reveal';
  %   params{file_idx} = struct('year',2012,'month',10,'day',10,'time_reference','utc');
  %   gps_source{file_idx} = 'reveal-field';
  %   sync_flag{file_idx} = 0;
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'IWG1_20121012_partial.txt');
  %   out_fns{file_idx} = 'gps_20121012.mat';
  %   file_type{file_idx} = 'reveal';
  %   params{file_idx} = struct('year',2012,'month',10,'day',12,'time_reference','utc','filter',0.02);
  %   gps_source{file_idx} = 'reveal-field';
  %   sync_flag{file_idx} = 0;
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'IWG1_20121012.txt');
  %   out_fns{file_idx} = 'gps_20121012.mat';
  %   file_type{file_idx} = 'reveal';
  %   params{file_idx} = struct('year',2012,'month',10,'day',12,'time_reference','utc','filter',0.02);
  %   gps_source{file_idx} = 'reveal-field';
  %   sync_flag{file_idx} = 0;
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'IWG1_20121015.txt');
  %   out_fns{file_idx} = 'gps_20121015.mat';
  %   file_type{file_idx} = 'reveal';
  %   params{file_idx} = struct('year',2012,'month',10,'day',15,'time_reference','utc','filter',0.02);
  %   gps_source{file_idx} = 'reveal-field';
  %   sync_flag{file_idx} = 0;
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'IWG1_20121016.txt');
  %   out_fns{file_idx} = 'gps_20121016.mat';
  %   file_type{file_idx} = 'reveal';
  %   params{file_idx} = struct('year',2012,'month',10,'day',16,'time_reference','utc','filter',0.02);
  %   gps_source{file_idx} = 'reveal-field';
  %   sync_flag{file_idx} = 0;
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'IWG1_20121025.txt');
  %   out_fns{file_idx} = 'gps_20121025.mat';
  %   file_type{file_idx} = 'reveal';
  %   params{file_idx} = struct('year',2012,'month',10,'day',25,'time_reference','utc','filter',0.02);
  %   gps_source{file_idx} = 'reveal-field';
  %   sync_flag{file_idx} = 0;
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'IWG1_20121027.txt');
  %   out_fns{file_idx} = 'gps_20121027.mat';
  %   file_type{file_idx} = 'reveal';
  %   params{file_idx} = struct('year',2012,'month',10,'day',27,'time_reference','utc','filter',0.02);
  %   gps_source{file_idx} = 'reveal-field';
  %   sync_flag{file_idx} = 0;
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'IWG1_20121104.txt');
  %   out_fns{file_idx} = 'gps_20121104.mat';
  %   file_type{file_idx} = 'reveal';
  %   params{file_idx} = struct('year',2012,'month',11,'day',04,'time_reference','utc','filter',0.02);
  %   gps_source{file_idx} = 'reveal-field';
  %   sync_flag{file_idx} = 0;
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'IWG1_20121106.txt');
  %   out_fns{file_idx} = 'gps_20121106.mat';
  %   file_type{file_idx} = 'reveal';
  %   params{file_idx} = struct('year',2012,'month',11,'day',06,'time_reference','utc','filter',0.02);
  %   gps_source{file_idx} = 'reveal-field';
  %   sync_flag{file_idx} = 0;
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'IWG1_20121107.txt');
  out_fns{file_idx} = 'gps_20121107.mat';
  file_type{file_idx} = 'reveal';
  params{file_idx} = struct('year',2012,'month',11,'day',07,'time_reference','utc','filter',0.02);
  gps_source{file_idx} = 'reveal-field';
  sync_flag{file_idx} = 0;
  
  % elseif strcmpi(gps_source_to_use,'ATM-field')
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'BD960_02Oct12_PPPK_P19Oct12.out');
  %   out_fns{file_idx} = 'gps_20121002.mat';
  %   file_type{file_idx} = 'applanix';
  %   params{file_idx} = struct('year',2012,'month',10,'day',02,'time_reference','gps');
  %   gps_source{file_idx} = 'ATM-field';
  %   sync_flag{file_idx} = 0;
  
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

% Hand corrections to GPS files go here so that everything is automated




