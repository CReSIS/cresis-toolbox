% script gps_create_2011_antarctica_DC8_GPS
%
% Makes the GPS files for 2011 Antarctica DC8 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2011_Antarctica_DC8');
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

in_base_path = fullfile(data_support_path,'2011_Antarctica_DC8');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {};

gps_source_to_use = 'ATM';
if strcmp(gps_source_to_use,'ATM')
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_04Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111004.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',04,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_05Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111005.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',05,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_09Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111009.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',09,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_10Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111010.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',10,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_12Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111012.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',12,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_13Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111013.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',13,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_14Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111014.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',14,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_17Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111017.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',17,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_18Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111018.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',18,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_20Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111020.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',20,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_21Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111021.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',21,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_23Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111023.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',23,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_24Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111024.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',24,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_25Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111025.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',25,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_26Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111026.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',26,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_29Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111029.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',29,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_30Oct11_PPPK.out');
  out_fns{file_idx} = 'gps_20111030.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',30,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_03Nov11_PPPK.out');
  out_fns{file_idx} = 'gps_20111103.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',03,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_04Nov11_PPPK.out');
  out_fns{file_idx} = 'gps_20111104.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',04,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_07Nov11_PPPK.out');
  out_fns{file_idx} = 'gps_20111107.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',07,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_09Nov11_PPPK.out');
  out_fns{file_idx} = 'gps_20111109.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',09,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_11Nov11_PPPK.out');
  out_fns{file_idx} = 'gps_20111111.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',11,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_12Nov11_PPPK.out');
  out_fns{file_idx} = 'gps_20111112.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',12,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_13Nov11_PPPK.out');
  out_fns{file_idx} = 'gps_20111113.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',13,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_14Nov11_PPPK.out');
  out_fns{file_idx} = 'gps_20111114.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',14,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_16Nov11_PPPK.out');
  out_fns{file_idx} = 'gps_20111116.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',16,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_17Nov11_PPPK.out');
  out_fns{file_idx} = 'gps_20111117.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',17,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'BD960_19Nov11_PPPK.out');
  out_fns{file_idx} = 'gps_20111119.mat';
  file_type{file_idx} = 'Applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',19,'time_reference','utc');
  gps_source{file_idx} = 'ATM-final_20120201';

  
elseif strcmp(gps_source_to_use,'reveal')
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'IWG1.14Oct2011-2342');
  out_fns{file_idx} = 'gps_20111014.mat';
  file_type{file_idx} = 'Reveal';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'reveal-field';
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'IWG1.14Oct2011-2342');
  %   out_fns{file_idx} = 'gps_20111014.mat';
  %   file_type{file_idx} = 'Reveal';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'reveal-field';
  
elseif strcmp(gps_source_to_use,'NMEA')
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20111013NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20111013.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2011,'month',10,'day',13,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'NMEA-field';
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20111014NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20111014.mat';
  %   file_type{file_idx} = 'NMEA';DMS
  %   params{file_idx} = struct('year',2011,'month',10,'day',14,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'NMEA-field';
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20111017NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20111017.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2011,'month',10,'day',17,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'NMEA-field';
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20111018NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20111018.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2011,'month',10,'day',18,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'NMEA-field';
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20111021NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20111021.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2011,'month',10,'day',21,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'NMEA-field';
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20111023NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20111023.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2011,'month',10,'day',23,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'NMEA-field';
  
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20111029NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20111029.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2011,'month',10,'day',29,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'NMEA-field';
  
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'20111103NMEA_GPGGA.TXT');
  %   out_fns{file_idx} = 'gps_20111103.mat';
  %   file_type{file_idx} = 'NMEA';
  %   params{file_idx} = struct('year',2011,'month',11,'day',03,'format',1,'time_reference','utc');
  %   gps_source{file_idx} = 'NMEA-field';
  %
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'20111104NMEA_GPGGA.TXT');
%   out_fns{file_idx} = 'gps_20111104.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',11,'day',04,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'NMEA-field';

%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'20111107NMEA_GPGGA.TXT');
%   out_fns{file_idx} = 'gps_20111107.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',11,'day',07,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'NMEA-field';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'20111109NMEA_GPGGA.TXT');
%   out_fns{file_idx} = 'gps_20111109.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',11,'day',09,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'NMEA-field';
  
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'20111111NMEA_GPGGA.TXT');
%   out_fns{file_idx} = 'gps_20111111.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',11,'day',11,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'NMEA-field';
%   

% file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'20111112NMEA_GPGGA.TXT');
%   out_fns{file_idx} = 'gps_20111112.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',11,'day',12,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'NMEA-field';
  
% file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'20111113NMEA_GPGGA.TXT');
%   out_fns{file_idx} = 'gps_20111113.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',11,'day',13,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'NMEA-field';

%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'20111114NMEA_GPGGA.TXT');
%   out_fns{file_idx} = 'gps_20111114.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',11,'day',14,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'NMEA-field';

% file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'20111116NMEA_GPGGA.TXT');
%   out_fns{file_idx} = 'gps_20111116.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',11,'day',16,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'NMEA-field';

%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'20111117NMEA_GPGGA.TXT');
%   out_fns{file_idx} = 'gps_20111117.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2011,'month',11,'day',17,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'NMEA-field';

  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'20111119NMEA_GPGGA.TXT');
  out_fns{file_idx} = 'gps_20111119.mat';
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',2011,'month',11,'day',19,'format',1,'time_reference','utc');
  gps_source{file_idx} = 'NMEA-field';

elseif strcmp(gps_source_to_use,'Gravimeter')
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_202.xyz');
  %   out_fns{file_idx} = 'gps_20111012.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_203.xyz');
  %   out_fns{file_idx} = 'gps_20111013.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_204.xyz');
  %   out_fns{file_idx} = 'gps_20111014.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_205.xyz');
  %   out_fns{file_idx} = 'gps_20111017.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_206.xyz');
  %   out_fns{file_idx} = 'gps_20111018.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_207.xyz');
  %   out_fns{file_idx} = 'gps_20111020.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_208.xyz');
  %   out_fns{file_idx} = 'gps_20111021.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_209.xyz');
%     out_fns{file_idx} = 'gps_20111023.mat';
%     file_type{file_idx} = 'TXT';
%     params{file_idx} = struct('time_reference','utc');
%     gps_source{file_idx} = 'gravimeter-field';
  
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_210.xyz');
  %   out_fns{file_idx} = 'gps_20111024.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  
  % file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_211.xyz');
  %   out_fns{file_idx} = 'gps_20111025.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %
  % file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_212.xyz');
  %   out_fns{file_idx} = 'gps_20111026.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  %
%   file_idx = file_idx + 1;
%     in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_213.xyz');
%     out_fns{file_idx} = 'gps_20111029.mat';
%     file_type{file_idx} = 'TXT';
%     params{file_idx} = struct('time_reference','utc');
%     gps_source{file_idx} = 'gravimeter-field';
  
  % file_idx = file_idx + 1;
  %   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_214.xyz');
  %   out_fns{file_idx} = 'gps_20111030.mat';
  %   file_type{file_idx} = 'TXT';
  %   params{file_idx} = struct('time_reference','utc');
  %   gps_source{file_idx} = 'gravimeter-field';
  
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_215.xyz');
%   out_fns{file_idx} = 'gps_20111103.mat';
%   file_type{file_idx} = 'TXT';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'gravimeter-field';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_216.xyz');
%   out_fns{file_idx} = 'gps_20111104.mat';
%   file_type{file_idx} = 'TXT';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'gravimeter-field';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_217.xyz');
%   out_fns{file_idx} = 'gps_20111107.mat';
%   file_type{file_idx} = 'TXT';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'gravimeter-field';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_218.xyz');
%   out_fns{file_idx} = 'gps_20111109.mat';
%   file_type{file_idx} = 'TXT';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'gravimeter-field';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_219.xyz');
%   out_fns{file_idx} = 'gps_20111111.mat';
%   file_type{file_idx} = 'TXT';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'gravimeter-field';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_220.xyz');
%   out_fns{file_idx} = 'gps_20111112.mat';
%   file_type{file_idx} = 'TXT';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'gravimeter-field';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_221.xyz');
%   out_fns{file_idx} = 'gps_20111113.mat';
%   file_type{file_idx} = 'TXT';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'gravimeter-field';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_222.xyz');
%   out_fns{file_idx} = 'gps_20111114.mat';
%   file_type{file_idx} = 'TXT';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'gravimeter-field';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_223.xyz');
%   out_fns{file_idx} = 'gps_20111116.mat';
%   file_type{file_idx} = 'TXT';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'gravimeter-field';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'AIRGrav_Attitude_Flight_224.xyz');
%   out_fns{file_idx} = 'gps_20111117.mat';
%   file_type{file_idx} = 'TXT';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'gravimeter-field';
  
elseif strcmp(gps_source_to_use,'DMS')
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111012.out');
  out_fns{file_idx} = 'gps_20111012.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',12,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111013.out');
  out_fns{file_idx} = 'gps_20111013.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',13,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111014.out');
  out_fns{file_idx} = 'gps_20111014.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',14,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111017.out');
  out_fns{file_idx} = 'gps_20111017.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',17,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111018.out');
  out_fns{file_idx} = 'gps_20111018.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',18,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111020.out');
  out_fns{file_idx} = 'gps_20111020.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',20,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111021.out');
  out_fns{file_idx} = 'gps_20111021.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',21,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111023.out');
  out_fns{file_idx} = 'gps_20111023.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',23,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111024.out');
  out_fns{file_idx} = 'gps_20111024.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',24,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111025.out');
  out_fns{file_idx} = 'gps_20111025.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',25,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111026.out');
  out_fns{file_idx} = 'gps_20111026.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',26,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111029.out');
  out_fns{file_idx} = 'gps_20111029.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',29,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111030.out');
  out_fns{file_idx} = 'gps_20111030.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',10,'day',30,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111103.out');
  out_fns{file_idx} = 'gps_20111103.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',03,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111104.out');
  out_fns{file_idx} = 'gps_20111104.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',04,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111107.out');
  out_fns{file_idx} = 'gps_20111107.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',07,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111109.out');
  out_fns{file_idx} = 'gps_20111109.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',09,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111111.out');
  out_fns{file_idx} = 'gps_20111111.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',11,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111112.out');
  out_fns{file_idx} = 'gps_20111112.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',12,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111113.out');
  out_fns{file_idx} = 'gps_20111113.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',13,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111114.out');
  out_fns{file_idx} = 'gps_20111114.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',14,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111116.out');
  out_fns{file_idx} = 'gps_20111116.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',16,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111117.out');
  out_fns{file_idx} = 'gps_20111117.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',17,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = fullfile(in_base_path,'sbet_20111119.out');
  out_fns{file_idx} = 'gps_20111119.mat';
  file_type{file_idx} = 'applanix';
  params{file_idx} = struct('year',2011,'month',11,'day',19,'time_reference','gps');
  gps_source{file_idx} = 'DMS-NSIDC_20120101';
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

