% script gps_create_2008_greenland_TO.m
%
% Makes the GPS files for 2008 Greenland Twin Otter field season
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

gps_path = fullfile(support_path,'gps','2008_Greenland_TO');
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

in_base_path = fullfile(data_support_path,'2008_Greenland_TO');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; sync_fns = {}; sync_params = {}; gps_source = {};
gps_source_to_use = 'Litton';
if strcmp(gps_source_to_use,'Litton')
  
%   file_idx = file_idx + 1;
%   year = 2008; month = 6; day = 27;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 6; day = 30;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 2;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 6;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 7;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 8;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 9;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 10;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 11;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 15;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 16;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 17;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 18;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 19;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%% Alternate file uploaded Sept 10, 2008 -->get_filenames(in_base_path, '080720','','.motion2');
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 20;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 22;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 23;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 25;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 26;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = get_filenames(in_base_path,sprintf('nmea.%s',date_string),'','.gps');
%   sync_fns{file_idx} = get_filenames(in_base_path,sprintf('nmea.%s',date_string),'','.gps');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'NMEA';
  
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 29;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 30;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 7; day = 31;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 8; day = 1;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
%   
%   file_idx = file_idx + 1;
%   year = 2008; month = 8; day = 2;
%   date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
%   in_fns{file_idx} = fullfile(in_base_path,sprintf('output_motion_%s',date_string));
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
%   file_type{file_idx} = 'Litton_DGPS';
%   gps_source{file_idx} = 'ATM-final_20110504';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,''), ...
%     sprintf('nmea.%s',date_string),'','.gps');
%   sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

elseif strcmp(gps_source_to_use,'NMEA')
%   error('This section outdated, needs sync variables set to work');
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'');
%   out_fns{file_idx} = 'gps_20080627.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',06,'day',27,'time_reference','utc','nmea_tag','$GPGGA','format',3,'combine',1);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'');
%   out_fns{file_idx} = 'gps_20080630.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',06,'day',30,'time_reference','utc','nmea_tag','$GPGGA','format',3,'combine',1);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20080702141529.gps');
%   out_fns{file_idx} = 'gps_20080702.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',02,'time_reference','utc','nmea_tag','$GPGGA','format',3);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20080703120934.gps');
%   out_fns{file_idx} = 'gps_20080703.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',03,'time_reference','utc','nmea_tag','$GPGGA','format',3);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20080706135202.gps');
%   out_fns{file_idx} = 'gps_20080706.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',06,'time_reference','utc','nmea_tag','$GPGGA','format',3);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20080707115103.gps');
%   out_fns{file_idx} = 'gps_20080707.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',07,'time_reference','utc','nmea_tag','$GPGGA','format',3);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20080708120229.gps');
%   out_fns{file_idx} = 'gps_20080708.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',08,'time_reference','utc','nmea_tag','$GPGGA','format',3);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'');
%   out_fns{file_idx} = 'gps_20080709.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',09,'time_reference','utc','nmea_tag','$GPGGA','format',3,'combine',1);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'');
%   out_fns{file_idx} = 'gps_20080710.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',10,'time_reference','utc','nmea_tag','$GPGGA','format',3,'combine',1);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20080711165505.gps');
%   out_fns{file_idx} = 'gps_20080711.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',11,'time_reference','utc','nmea_tag','$GPGGA','format',3);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'');
%   out_fns{file_idx} = 'gps_20080715.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',15,'time_reference','utc','nmea_tag','$GPGGA','format',3,'combine',1);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'');
%   out_fns{file_idx} = 'gps_20080716.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',16,'time_reference','utc','nmea_tag','$GPGGA','format',3,'combine',1);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'');
%   out_fns{file_idx} = 'gps_20080717.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',17,'time_reference','utc','nmea_tag','$GPGGA','format',3,'combine',1);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20080718151416.gps');
%   out_fns{file_idx} = 'gps_20080718.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',18,'time_reference','utc','nmea_tag','$GPGGA','format',3);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20080719145520.gps');
%   out_fns{file_idx} = 'gps_20080719.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',19,'time_reference','utc','nmea_tag','$GPGGA','format',3);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'');
%   out_fns{file_idx} = 'gps_20080720.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',20,'time_reference','utc','nmea_tag','$GPGGA','format',3,'combine',1);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20080722124553.gps');
%   out_fns{file_idx} = 'gps_20080722.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',22,'time_reference','utc','nmea_tag','$GPGGA','format',3);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20080723121847.gps');
%   out_fns{file_idx} = 'gps_20080723.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',23,'time_reference','utc','nmea_tag','$GPGGA','format',3);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'');
%   out_fns{file_idx} = 'gps_20080725.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',25,'time_reference','utc','nmea_tag','$GPGGA','format',3,'combine',1);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20080726114147.gps');
%   sync_fns{file_idx} = get_filenames(in_base_path,'nmea.20080726','','.gps');
%   out_fns{file_idx} = 'gps_20080726.mat';
%   file_type{file_idx} = 'MCRDS_NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',26,'time_reference','utc','format',3);
%   sync_params{file_idx} = struct('year',2008,'month',07,'day',26,'time_reference','utc','format',3);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'nmea.20080729173515.gps');
%   out_fns{file_idx} = 'gps_20080729.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',29,'time_reference','utc','nmea_tag','$GPGGA','format',3);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'');
%   out_fns{file_idx} = 'gps_20080730.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',30,'time_reference','utc','nmea_tag','$GPGGA','format',3,'combine',1);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'');
%   out_fns{file_idx} = 'gps_20080731.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',07,'day',31,'time_reference','utc','nmea_tag','$GPGGA','format',3,'combine',1);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'');
%   out_fns{file_idx} = 'gps_20080801.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',08,'day',01,'time_reference','utc','nmea_tag','$GPGGA','format',3,'combine',1);
%   gps_source{file_idx} = 'NMEA';
%   
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = fullfile(in_base_path,'');
%   out_fns{file_idx} = 'gps_20080802.mat';
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',2008,'month',08,'day',02,'time_reference','utc','nmea_tag','$GPGGA','format',3,'combine',1);
%   gps_source{file_idx} = 'NMEA';
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

if any(strcmpi('gps_20080630.mat',out_fns))
  % The DGPS data does not span the full record, so we have to use NMEA
  % data (from sync files) for part of the GPS record
  out_fn = fullfile(gps_path,'gps_20080630.mat');
  gps = load(out_fn);
  new_idxs = find(gps.gps_time(end) < gps.sync_gps_time);
  
  % Add in an error correction to make all variables continuous
  error_correction = interp1(gps.sync_gps_time(new_idxs([1 end])), ...
    [gps.lat(end)-interp1(gps.sync_gps_time,gps.sync_lat,gps.gps_time(end)) 0], ...
    gps.sync_gps_time(new_idxs));
  gps.lat = [gps.lat gps.sync_lat(new_idxs)+error_correction];
  
  error_correction = interp1(gps.sync_gps_time(new_idxs([1 end])), ...
    [gps.lon(end)-interp1(gps.sync_gps_time,gps.sync_lon+360,gps.gps_time(end)) 0], ...
    gps.sync_gps_time(new_idxs));
  gps.lon = [gps.lon gps.sync_lon(new_idxs)+360+error_correction];
  
  error_correction = interp1(gps.sync_gps_time(new_idxs([1 end])), ...
    [gps.elev(end)-interp1(gps.sync_gps_time,gps.sync_elev,gps.gps_time(end)) 0], ...
    gps.sync_gps_time(new_idxs));
  gps.elev = [gps.elev gps.sync_elev(new_idxs)+error_correction];
  
  gps.roll = [gps.roll zeros(size(new_idxs))];
  gps.pitch = [gps.pitch zeros(size(new_idxs))];
  
  error_correction = interp1(gps.sync_gps_time(new_idxs([1 end])), ...
    [gps.heading(end)-interp1(gps.sync_gps_time,gps.sync_heading,gps.gps_time(end)) 0], ...
    gps.sync_gps_time(new_idxs));
  gps.heading = [gps.heading gps.sync_heading(new_idxs)+error_correction];
  
  gps.gps_time = [gps.gps_time gps.sync_gps_time(new_idxs)];
  
  save(out_fn, '-append','-struct','gps');
end

if any(strcmpi('gps_20080731.mat',out_fns))
  % The DGPS data does not span the full record, so we have to use NMEA
  % data (from sync files) for part of the GPS record
  out_fn = fullfile(gps_path,'gps_20080731.mat');
  gps = load(out_fn);
  new_idxs = find(gps.gps_time(end) < gps.sync_gps_time);
  
  % Add in an error correction to make all variables continuous
  error_correction = interp1(gps.sync_gps_time(new_idxs([1 end])), ...
    [gps.lat(end)-interp1(gps.sync_gps_time,gps.sync_lat,gps.gps_time(end)) 0], ...
    gps.sync_gps_time(new_idxs));
  gps.lat = [gps.lat gps.sync_lat(new_idxs)+error_correction];
  
  error_correction = interp1(gps.sync_gps_time(new_idxs([1 end])), ...
    [gps.lon(end)-interp1(gps.sync_gps_time,gps.sync_lon+360,gps.gps_time(end)) 0], ...
    gps.sync_gps_time(new_idxs));
  gps.lon = [gps.lon gps.sync_lon(new_idxs)+360+error_correction];
  
  error_correction = interp1(gps.sync_gps_time(new_idxs([1 end])), ...
    [gps.elev(end)-interp1(gps.sync_gps_time,gps.sync_elev,gps.gps_time(end)) 0], ...
    gps.sync_gps_time(new_idxs));
  gps.elev = [gps.elev gps.sync_elev(new_idxs)+error_correction];
  
  gps.roll = [gps.roll zeros(size(new_idxs))];
  gps.pitch = [gps.pitch zeros(size(new_idxs))];
  
  error_correction = interp1(gps.sync_gps_time(new_idxs([1 end])), ...
    [gps.heading(end)-interp1(gps.sync_gps_time,gps.sync_heading,gps.gps_time(end)) 0], ...
    gps.sync_gps_time(new_idxs));
  gps.heading = [gps.heading gps.sync_heading(new_idxs)+error_correction];
  
  gps.gps_time = [gps.gps_time gps.sync_gps_time(new_idxs)];
  
  save(out_fn, '-append','-struct','gps');
end

if any(strcmpi('gps_20080706.mat',out_fns))
  % The 1PPS radar time in the NMEA sync GPS file stopped counting
  out_fn = fullfile(gps_path,'gps_20080706.mat');
  gps = load(out_fn);
  good_idxs = find(gps.radar_time>2000 & gps.radar_time<7000);
  time_jump = diff(gps.radar_time(good_idxs));
  time_jump = mean(time_jump(time_jump > 0.6));
  correction = zeros(size(gps.radar_time));
  correction(12472:end) = gps.sync_gps_time(12472:end) - gps.sync_gps_time(12472);
  gps.radar_time = gps.radar_time + correction;
  save(out_fn, '-append','-struct','gps','radar_time');
end

if any(strcmpi('gps_20080715.mat',out_fns))
  % Beginning of file has zero radar times
  out_fn = fullfile(gps_path,'gps_20080715.mat');
  gps = load(out_fn);
  good_idxs = 5000:25000;
  time_jump = diff(gps.radar_time(good_idxs));
  time_jump = mean(time_jump(time_jump > 0.6));
  gps.radar_time(1:2345) = gps.sync_gps_time(1:2345) - gps.sync_gps_time(2345) + gps.radar_time(2345);
  save(out_fn, '-append','-struct','gps','radar_time');
end

if any(strcmpi('gps_20080722.mat',out_fns))
  % Beginning of file has zero radar times
  out_fn = fullfile(gps_path,'gps_20080722.mat');
  gps = load(out_fn);
  good_idxs = find(gps.radar_time>2000);
  time_jump = diff(gps.radar_time(good_idxs));
  time_jump = mean(time_jump(time_jump > 0.6));
  gps.radar_time(1:3414) = gps.sync_gps_time(1:3414) - gps.sync_gps_time(3414) + gps.radar_time(3414);
  save(out_fn, '-append','-struct','gps','radar_time');
end

if any(strcmpi('gps_20080730.mat',out_fns))
  out_fn = fullfile(gps_path,'gps_20080730.mat');
  gps = load(out_fn);
  
  good_idxs = 40000:48000;
  time_jump = diff(gps.radar_time(good_idxs));
  time_jump = mean(time_jump(time_jump > 0.6));
  
  % Segment 20080730_04 start and stop computer times
  %   Numbers pulled from workspace file created during record generation
  %    hdrs.comp_time(1)
  %    hdrs.comp_time(end)
  %    median(hdrs.comp_time-hdrs.radar_time)
  %    hdrs.radar_time([1 end])
  
  % Radar times from raw data files for mcrds records 4-6:
  % 1714.504542200000   1819.214942200000
  % 42.1504848000000   167.4496848000000
  % 220.779884800000   7750.945884799999
  % 7777.838684800000  8338.017884799999
  % Computer times from raw data files for mcrds records 4-6
  % 1.217462717686343e9   1.217462822389378e9
  % 1.217462896648844e9   1.217463021938513e9
  % 1.217463075264676e9   1.217470605087623e9
  % 1.217470631978391e9   1.217471192115368e9
  
  guard_time = 5;

  match_idxs = find(gps.comp_time >= 1.217462717686343e9-guard_time & gps.comp_time <= 1.217462822389378e9+guard_time);
  gps.radar_time(match_idxs) = gps.comp_time(match_idxs(1))-1.217461003178069e9;
  correction = zeros(size(gps.radar_time));
  correction(match_idxs) = gps.sync_gps_time(match_idxs) - gps.sync_gps_time(match_idxs(1));
  gps.radar_time = gps.radar_time + correction;

  match_idxs = find(gps.comp_time >= 1.217462896648844e9-guard_time & gps.comp_time <= 1.217463021938513e9+guard_time);
  gps.radar_time(match_idxs) = gps.comp_time(match_idxs(1))-1.217462854493836e9;
  correction = zeros(size(gps.radar_time));
  correction(match_idxs) = gps.sync_gps_time(match_idxs) - gps.sync_gps_time(match_idxs(1));
  gps.radar_time = gps.radar_time + correction;

  match_idxs = find(gps.comp_time >= 1.217463075264676e+09-guard_time & gps.comp_time <= 1.217470605087623e+09+guard_time);
  gps.radar_time(match_idxs) = gps.comp_time(match_idxs(1))-1.217462854427286e+09;
  correction = zeros(size(gps.radar_time));
  correction(match_idxs) = gps.sync_gps_time(match_idxs) - gps.sync_gps_time(match_idxs(1));
  gps.radar_time = gps.radar_time + correction;
 
  match_idxs = find(gps.comp_time >= 1.217470631978391e+09-guard_time & gps.comp_time <= 1.217471192115368e+09+guard_time);
  gps.radar_time(match_idxs) = gps.comp_time(match_idxs(1))-1.217462854118927e+09;
  correction = zeros(size(gps.radar_time));
  correction(match_idxs) = gps.sync_gps_time(match_idxs) - gps.sync_gps_time(match_idxs(1));
  gps.radar_time = gps.radar_time + correction;
  
  % figure(1); clf;
  % plot(gps.comp_time)
  % hold on
  % plot(match_idxs,gps.comp_time(match_idxs),'r')
  
  save(out_fn, '-append','-struct','gps','radar_time');
end

