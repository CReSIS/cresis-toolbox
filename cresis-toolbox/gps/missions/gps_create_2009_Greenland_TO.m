% script gps_create_2009_greenland_TO.m
%
% Makes the GPS files for 2009 Greenland Twin Otter field season
%
% support_path: input path to the season-specific raw gps main directory
% data_support_path: path to the season-specific processed gps main directory
% gps_path: is the output path for the final product
%

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2009_Greenland_TO');
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

in_base_path = fullfile(data_support_path,'2009_Greenland_TO');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; sync_fns = {}; sync_params = {}; gps_source = {};
gps_source_to_use = 'Novatel';
if strcmp(gps_source_to_use,'Novatel')
  
%   file_idx = file_idx + 1;
%   in_fns{file_idx}{1} = '/cresis/data1/MCRDS/2009_Greenland/DGPS/03.31.2009/RPY Files/rover_diff_greenland_090331.rpy';
%   sync_fns{file_idx} = get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090331/gpsGISMO/','nmea.20090331','','.gps');
%   out_fns{file_idx} = 'gps_20090331.mat';
%   file_type{file_idx} = 'Novatel_RPYGGA';
%   gga_fns = '/cresis/data1/MCRDS/2009_Greenland/DGPS/03.31.2009/GGA Files/rover_diff_greenland_090331.gga';
%   params{file_idx}{1} = struct('year',2009,'month',03,'day',31,'time_reference','utc','gga_fns',gga_fns);
%   sync_params{file_idx} = struct('year',2009,'month',03,'day',31,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'novatel-final_200906';
%   sync_flag{file_idx} = 1;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx}{1} = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.01.2009/RPY Files/rover_diff_greenland_090401.rpy';
%   sync_fns{file_idx} = get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090401/gpsGISMO/','nmea.20090401','','.gps');
%   out_fns{file_idx} = 'gps_20090401.mat';
%   file_type{file_idx} = 'Novatel_RPYGGA';
%   gga_fns = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.01.2009/GGA Files/rover_diff_greenland_090401.gga';
%   params{file_idx}{1} = struct('year',2009,'month',04,'day',01,'time_reference','utc','gga_fns',gga_fns);
%   sync_params{file_idx} = struct('year',2009,'month',04,'day',01,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'novatel-final_200906';
%   sync_flag{file_idx} = 1;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx}{1} = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.02.2009/RPY Files/rover_diff_greenland_090402.rpy';
%   sync_fns{file_idx} = get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090402/gpsGISMO/','nmea.20090402','','.gps');
%   out_fns{file_idx} = 'gps_20090402.mat';
%   file_type{file_idx} = 'Novatel_RPYGGA';
%   gga_fns = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.02.2009/GGA Files/rover_diff_greenland_090402.gga';
%   params{file_idx}{1} = struct('year',2009,'month',04,'day',02,'time_reference','utc','gga_fns',gga_fns);
%   sync_params{file_idx} = struct('year',2009,'month',04,'day',02,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'novatel-final_200906';
%   sync_flag{file_idx} = 1;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx}{1} = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.03.2009/RPY Files/rover_diff_greenland_090403.rpy';
%   sync_fns{file_idx} = get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090403/gpsGISMO/','nmea.20090403','','.gps');
%   out_fns{file_idx} = 'gps_20090403.mat';
%   file_type{file_idx} = 'Novatel_RPYGGA';
%   gga_fns = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.03.2009/GGA Files/rover_diff_greenland_090403.gga';
%   params{file_idx}{1} = struct('year',2009,'month',04,'day',03,'time_reference','utc','gga_fns',gga_fns);
%   sync_params{file_idx} = struct('year',2009,'month',04,'day',03,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'novatel-final_200906';
%   sync_flag{file_idx} = 1;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx}{1} = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.04.2009/RPY Files/rover_diff_greenland_090404.rpy';
%   sync_fns{file_idx} = get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090404/gpsGISMO/','nmea.20090404','','.gps');
%   out_fns{file_idx} = 'gps_20090404.mat';
%   file_type{file_idx} = 'Novatel_RPYGGA';
%   gga_fns = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.04.2009/GGA Files/rover_diff_greenland_090404.gga';
%   params{file_idx}{1} = struct('year',2009,'month',04,'day',04,'time_reference','utc','gga_fns',gga_fns);
%   sync_params{file_idx} = struct('year',2009,'month',04,'day',04,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'novatel-final_200906';
%   sync_flag{file_idx} = 1;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx}{1} = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.06.2009/RPY Files/rover_diff_greenland_090406.rpy';
%   sync_fns{file_idx} = get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090406/gpsGISMO/','nmea.20090406','','.gps');
%   out_fns{file_idx} = 'gps_20090406.mat';
%   file_type{file_idx} = 'Novatel_RPYGGA';
%   gga_fns = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.06.2009/GGA Files/rover_diff_greenland_090406.gga';
%   params{file_idx}{1} = struct('year',2009,'month',04,'day',06,'time_reference','utc','gga_fns',gga_fns);
%   sync_params{file_idx} = struct('year',2009,'month',04,'day',06,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'novatel-final_200906';
%   sync_flag{file_idx} = 1;
%   
% % NO DGPS FILES
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090407/gpsGISMO/','nmea.20090407','','.gps');
%   sync_fns{file_idx} = get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090407/gpsGISMO/','nmea.20090407','','.gps');
%   out_fns{file_idx} = 'gps_20090407.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx}{1} = struct('year',2009,'month',04,'day',07,'time_reference','utc','format',3);
%   sync_params{file_idx} = struct('year',2009,'month',04,'day',07,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx}{1} = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.09.2009/RPY Files/rover_diff_greenland_090409.rpy';
%   sync_fns{file_idx} = get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090409/gpsGISMO/','nmea.20090409','','.gps');
%   out_fns{file_idx} = 'gps_20090409.mat';
%   file_type{file_idx} = 'Novatel_RPYGGA';
%   gga_fns = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.09.2009/GGA Files/rover_diff_greenland_090409.gga';
%   params{file_idx}{1} = struct('year',2009,'month',04,'day',09,'time_reference','utc','gga_fns',gga_fns);
%   sync_params{file_idx} = struct('year',2009,'month',04,'day',09,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'novatel-final_200906';
%   sync_flag{file_idx} = 1;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx}{1} = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.11.2009/RPY Files/rover_diff_greenland_090411.rpy';
%   sync_fns{file_idx} = get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090411/gpsGISMO/','nmea.20090411','','.gps');
%   out_fns{file_idx} = 'gps_20090411.mat';
%   file_type{file_idx} = 'Novatel_RPYGGA';
%   gga_fns = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.11.2009/GGA Files/rover_diff_greenland_090411.gga';
%   params{file_idx}{1} = struct('year',2009,'month',04,'day',11,'time_reference','utc','gga_fns',gga_fns);
%   sync_params{file_idx} = struct('year',2009,'month',04,'day',11,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'novatel-final_200906';
%   sync_flag{file_idx} = 1;
%     
%   file_idx = file_idx + 1;
%   in_fns{file_idx}{1} = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.14.2009_A/RPY Files/rover_diff_greenland_090414.rpy';
%   in_fns{file_idx}{2} = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.14.2009_B/RPY Files/rover_diff_greenland_090414.rpy';
%   sync_fns{file_idx} = [get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090414/gpsGISMO/kanger_1_20090414','nmea.20090414','','.gps'),
%     get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090414/gpsGISMO/','nmea.20090414','','.gps')];
%   out_fns{file_idx} = 'gps_20090414.mat';
%   file_type{file_idx} = 'Novatel_RPYGGA';
%   gga_fns = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.14.2009_A/GGA Files/rover_diff_greenland_090414.gga';
%   params{file_idx}{1} = struct('year',2009,'month',04,'day',14,'time_reference','utc','gga_fns',gga_fns);
%   gga_fns= '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.14.2009_B/GGA Files/rover_diff_greenland_090414.gga';
%   params{file_idx}{2} = struct('year',2009,'month',04,'day',14,'time_reference','utc','gga_fns',gga_fns);
%   sync_params{file_idx} = struct('year',2009,'month',04,'day',14,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'novatel-final_200906';
%   sync_flag{file_idx} = 1;
%   
% % NO DGPS FILES
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090416/gpsGISMO/','nmea.20090416','','.gps');
%   sync_fns{file_idx} = get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090416/gpsGISMO/','nmea.20090416','','.gps');
%   out_fns{file_idx} = 'gps_20090416.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx}{1} = struct('year',2009,'month',04,'day',16,'time_reference','utc','format',3);
%   sync_params{file_idx} = struct('year',2009,'month',04,'day',16,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
  
%   file_idx = file_idx + 1;
%   in_fns{file_idx}{1} = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.22.2009_A/RPY Files/rover_diff_greenland_090422.rpy';
%   in_fns{file_idx}{2} = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.22.2009_B/RPY Files/rover_diff_greenland_090422.rpy';
%   sync_fns{file_idx} = [get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090422/gpsGISMO/042209a','nmea.20090422','','.gps'),
%     get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090422/gpsGISMO/042209b','nmea.20090422','','.gps')];
%   out_fns{file_idx} = 'gps_20090422.mat';
%   file_type{file_idx} = 'Novatel_RPYGGA';
%   gga_fns = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.22.2009_A/GGA Files/rover_diff_greenland_090422.gga';
%   params{file_idx}{1} = struct('year',2009,'month',04,'day',22,'time_reference','utc','gga_fns',gga_fns);
%   gga_fns= '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.22.2009_B/GGA Files/rover_diff_greenland_090422.gga';
%   params{file_idx}{2} = struct('year',2009,'month',04,'day',22,'time_reference','utc','gga_fns',gga_fns);
%   sync_params{file_idx} = struct('year',2009,'month',04,'day',22,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'novatel-final_200906';
%   sync_flag{file_idx} = 1;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx}{1} = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.23.2009_A/RPY Files/rover_diff_greenland_090423.rpy';
%   in_fns{file_idx}{2} = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.23.2009_B/RPY Files/rover_diff_greenland_090423.rpy';
%   sync_fns{file_idx} = [get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090423/gpsGISMO/042309a','nmea.20090423','','.gps'),
%     get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090423/gpsGISMO/042309b','nmea.20090423','','.gps')];
%   out_fns{file_idx} = 'gps_20090423.mat';
%   file_type{file_idx} = 'Novatel_RPYGGA';
%   gga_fns = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.23.2009_A/GGA Files/rover_diff_greenland_090423.gga';
%   params{file_idx}{1} = struct('year',2009,'month',04,'day',23,'time_reference','utc','gga_fns',gga_fns);
%   gga_fns= '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.23.2009_B/GGA Files/rover_diff_greenland_090423.gga';
%   params{file_idx}{2} = struct('year',2009,'month',04,'day',23,'time_reference','utc','gga_fns',gga_fns);
%   sync_params{file_idx} = struct('year',2009,'month',04,'day',23,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'novatel-final_200906';
%   sync_flag{file_idx} = 1;
  
% NO DGPS FILES
% Error/binary-crap in NMEA file (corrected one in metadata), disks corrupted on this day
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,'hand_corrected_nmea.20090424','','.gps');
%   sync_fns{file_idx} = get_filenames(in_base_path,'hand_corrected_nmea.20090424','','.gps');
%   out_fns{file_idx} = 'gps_20090424.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx}{1} = struct('year',2009,'month',04,'day',24,'time_reference','utc','format',3);
%   sync_params{file_idx} = struct('year',2009,'month',04,'day',24,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 1;
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.28.2009/RPY Files/rover_diff_greenland_090428.rpy';
%   sync_fns{file_idx} = get_filenames('/cresis/data1/MCRDS/2009_Greenland/20090428/gpsGISMO/','nmea.20090428','','.gps');
%   out_fns{file_idx} = 'gps_20090428.mat';
%   file_type{file_idx} = 'Novatel_RPYGGA';
%   gga_fns = '/cresis/data1/MCRDS/2009_Greenland/DGPS/04.28.2009/GGA Files/rover_diff_greenland_090428.gga';
%   params{file_idx}{1} = struct('year',2009,'month',04,'day',28,'time_reference','utc','gga_fns',gga_fns);
%   sync_params{file_idx} = struct('year',2009,'month',04,'day',28,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'novatel-final_200906';
%   sync_flag{file_idx} = 1;
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

