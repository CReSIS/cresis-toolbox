% script gps_create_2013_greenland_P3
%
% Makes the GPS files for 2013 Greenland P3 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2013_Greenland_P3');
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

in_base_path = fullfile(data_support_path,'2013_Greenland_P3');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'ATM';
if strcmpi(gps_source_to_use,'ATM')
  %% ATM DATA
  
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_15Mar13_PPPK_P21Mar13.out');
%   out_fns{file_idx} = 'gps_20130315.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',03,'day',15,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-field';
%   sync_flag{file_idx} = 0;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_20Mar13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130320.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',03,'day',20,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130320','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',03,'day',20,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_21Mar13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130321.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',03,'day',21,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130321','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',03,'day',21,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_22Mar13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130322.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',03,'day',22,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130322','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',03,'day',22,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_23Mar13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130323.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',03,'day',23,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130323','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',03,'day',23,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_24Mar13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130324.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',03,'day',24,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130324','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',03,'day',24,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_26Mar13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130326.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',03,'day',26,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130326','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',03,'day',26,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_27Mar13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130327.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',03,'day',27,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130327','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',03,'day',27,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_28Mar13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130328.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',03,'day',28,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130328','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',03,'day',28,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_02Apr13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130402.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',04,'day',02,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130402','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',04,'day',02,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_04Apr13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130404.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',04,'day',04,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130404','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',04,'day',04,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_05Apr13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130405.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',04,'day',05,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130405','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',04,'day',05,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_06Apr13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130406.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',04,'day',06,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130406','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',04,'day',06,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_08Apr13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130408.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',04,'day',08,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130408','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',04,'day',08,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_09Apr13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130409.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',04,'day',09,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130409_combined','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',04,'day',09,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_10Apr13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130410.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',04,'day',10,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130410','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',04,'day',10,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_11Apr13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130411.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',04,'day',11,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130411','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',04,'day',11,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_12Apr13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130412.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',04,'day',12,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130412_combined','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',04,'day',12,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_15Apr13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130415.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',04,'day',15,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130415_combined','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',04,'day',15,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_18Apr13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130418.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',04,'day',18,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130418','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',04,'day',18,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'BD960_19Apr13_PPPK_P10May13.out');
%   out_fns{file_idx} = 'gps_20130419.mat';
%   file_type{file_idx} = 'Applanix';
%   params{file_idx} = struct('year',2013,'month',04,'day',19,'time_reference','utc');
%   gps_source{file_idx} = 'ATM-final_20130510';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130419','','.gps');
%   sync_params{file_idx} = struct('year',2013,'month',04,'day',19,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_20Apr13_PPPK_P10May13.out');
  out_fns{file_idx} = 'gps_20130420.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2013,'month',04,'day',20,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20130510';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130420_combined','','.gps');
  sync_params{file_idx} = struct('year',2013,'month',04,'day',20,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_22Apr13_PPPK_P10May13.out');
  out_fns{file_idx} = 'gps_20130422.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2013,'month',04,'day',22,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20130510';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130422_combined','','.gps');
  sync_params{file_idx} = struct('year',2013,'month',04,'day',22,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_23Apr13_PPPK_P10May13.out');
  out_fns{file_idx} = 'gps_20130423.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2013,'month',04,'day',23,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20130510';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130423','','.gps');
  sync_params{file_idx} = struct('year',2013,'month',04,'day',23,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_24Apr13_PPPK_P10May13.out');
  out_fns{file_idx} = 'gps_20130424.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2013,'month',04,'day',24,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20130510';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130424_combined','','.gps');
  sync_params{file_idx} = struct('year',2013,'month',04,'day',24,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_25Apr13_PPPK_P10May13.out');
  out_fns{file_idx} = 'gps_20130425.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2013,'month',04,'day',25,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20130510';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130425_combined','','.gps');
  sync_params{file_idx} = struct('year',2013,'month',04,'day',25,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_26Apr13_PPPK_P10May13.out');
  out_fns{file_idx} = 'gps_20130426.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2013,'month',04,'day',26,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20130510';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130426_combined','','.gps');
  sync_params{file_idx} = struct('year',2013,'month',04,'day',26,'time_reference','utc','format',3);
  
elseif strcmpi(gps_source_to_use,'NMEA')
  %% NMEA DATA
  
  %     file_idx = file_idx + 1;
  %     in_fns{file_idx} = fullfile(in_base_path,'20130315NMEA.TXT');
  %     out_fns{file_idx} = 'gps_20130315.mat';
  %     file_type{file_idx} = 'NMEA';
  %     params{file_idx} = struct('year',2013,'month',03,'day',15,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 0;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130315','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',03,'day',15,'time_reference','utc','format',3);
%   
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130320NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130320.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',03,'day',20,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130320','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',03,'day',20,'time_reference','utc','format',3);
  
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130321_NMEA_ACCUM.TXT');
%     out_fns{file_idx} = 'gps_20130321.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',03,'day',21,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130321','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',03,'day',21,'time_reference','utc','format',3);
  
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'accum2_20130322_160928.gps');
%     out_fns{file_idx} = 'gps_20130322.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',03,'day',22,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130322','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',03,'day',22,'time_reference','utc','format',3);

%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'accum2_20130323_154919.gps');
%     out_fns{file_idx} = 'gps_20130323.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',03,'day',23,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130323','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',03,'day',23,'time_reference','utc','format',3);

%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130324NMEA.txt');
%     out_fns{file_idx} = 'gps_20130324.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',03,'day',24,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130324','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',03,'day',24,'time_reference','utc','format',3);

%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130326NMEA.txt');
%     out_fns{file_idx} = 'gps_20130326.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',03,'day',26,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130326','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',03,'day',26,'time_reference','utc','format',3);

%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'accum2_20130327_121824.gps');
%     out_fns{file_idx} = 'gps_20130327.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',03,'day',27,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130327','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',03,'day',27,'time_reference','utc','format',3);
    
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130328NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130328.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',03,'day',28,'format',3,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130328','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',03,'day',28,'time_reference','utc','format',3);
%     
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130402NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130402.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',02,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130402','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',02,'time_reference','utc','format',3);
    
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130404NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130404.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',04,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130404','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',04,'time_reference','utc','format',3);

%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130405NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130405.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',05,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130405','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',05,'time_reference','utc','format',3);
% 
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130406NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130406.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',06,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130406','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',06,'time_reference','utc','format',3);
% 
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130408NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130408.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',08,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130408','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',08,'time_reference','utc','format',3);

%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130409NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130409.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',09,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130409_combined','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',09,'time_reference','utc','format',3);
% 
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130410NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130410.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',10,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130410','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',10,'time_reference','utc','format',3);
% 
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130411NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130411.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',11,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130411','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',11,'time_reference','utc','format',3);

%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130412NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130412.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',12,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130412_combined','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',12,'time_reference','utc','format',3);
%     
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130415NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130415.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',15,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130415_combined','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',15,'time_reference','utc','format',3);

%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130418NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130418.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',18,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130418','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',18,'time_reference','utc','format',3);
%     
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130419NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130419.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',19,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130419','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',19,'time_reference','utc','format',3);
% 
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130420NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130420.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',20,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130420_combined','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',20,'time_reference','utc','format',3);

%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130422NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130422.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',22,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130422_combined','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',22,'time_reference','utc','format',3);
    
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130423NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130423.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',23,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130423','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',23,'time_reference','utc','format',3);
    
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130424NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130424.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',24,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130424_combined','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',24,'time_reference','utc','format',3);
% 
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'20130425NMEA.TXT');
%     out_fns{file_idx} = 'gps_20130425.mat';
%     file_type{file_idx} = 'NMEA';
%     params{file_idx} = struct('year',2013,'month',04,'day',25,'format',1,'time_reference','utc');
%     gps_source{file_idx} = 'nmea-field';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130425_combined','','.gps');
%     sync_params{file_idx} = struct('year',2013,'month',04,'day',25,'time_reference','utc','format',3);

    file_idx = file_idx + 1;
    in_fns{file_idx} = fullfile(in_base_path,'20130426NMEA.TXT');
    out_fns{file_idx} = 'gps_20130426.mat';
    file_type{file_idx} = 'NMEA';
    params{file_idx} = struct('year',2013,'month',04,'day',26,'format',1,'time_reference','utc');
    gps_source{file_idx} = 'nmea-field';
    sync_flag{file_idx} = 1;
    sync_fns{file_idx} = get_filenames(in_base_path,'accum2_20130426_combined','','.gps');
    sync_params{file_idx} = struct('year',2013,'month',04,'day',26,'time_reference','utc','format',3);
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;




