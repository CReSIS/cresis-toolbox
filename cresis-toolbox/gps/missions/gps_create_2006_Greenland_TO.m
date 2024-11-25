% script gps_create_2006_greenland_TO
%
% Makes the GPS files for 2006 Greenland TO field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2006_Greenland_TO');
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

in_base_path = fullfile(data_support_path,'2006_Greenland_TO');

file_idx = 0; in_fns = {}; in_fns_ins = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'ATM';
if strcmpi(gps_source_to_use,'ATM')
   
  file_idx = file_idx + 1;
  year = 2006; month = 5; day = 11;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'ATM_trajectory/Text Files'), ...
    sprintf('Alt%s',date_string),'','');
  params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ATM_ins/%s',date_string)), ...
    date_string,'','');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Traj+Litton';
  gps_source{file_idx} = 'ATM-final_20061109';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  year = 2006; month = 5; day = 16;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'ATM_trajectory/Text Files'), ...
    sprintf('Alt%s',date_string),'','');
  params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ATM_ins/%s',date_string)), ...
    date_string,'','');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Traj+Litton';
  gps_source{file_idx} = 'ATM-final_20061109';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  year = 2006; month = 5; day = 18;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'ATM_trajectory/Text Files'), ...
    sprintf('Alt%s',date_string),'','');
  params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ATM_ins/%s',date_string)), ...
    date_string,'','');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Traj+Litton';
  gps_source{file_idx} = 'ATM-final_20061109';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  year = 2006; month = 5; day = 20;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'ATM_trajectory/Text Files'), ...
    sprintf('Alt%s',date_string),'','');
  params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ATM_ins/%s',date_string)), ...
    date_string,'','');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Traj+Litton';
  gps_source{file_idx} = 'ATM-final_20061109';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  year = 2006; month = 5; day = 21;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'ATM_trajectory/Text Files'), ...
    sprintf('Alt%s',date_string),'','');
  params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ATM_ins/%s',date_string)), ...
    date_string,'','');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Traj+Litton';
  gps_source{file_idx} = 'ATM-final_20061109';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  year = 2006; month = 5; day = 22;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'ATM_trajectory/Text Files'), ...
    sprintf('Alt%s',date_string),'','');
  params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ATM_ins/%s',date_string)), ...
    date_string,'','');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Traj+Litton';
  gps_source{file_idx} = 'ATM-final_20061109';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  year = 2006; month = 5; day = 23;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'ATM_trajectory/Text Files'), ...
    sprintf('Alt%s',date_string),'','');
  params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ATM_ins/%s',date_string)), ...
    date_string,'','');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Traj+Litton';
  gps_source{file_idx} = 'ATM-final_20061109';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2006; month = 5; day = 26;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = '/cresis/snfs1/dataproducts/metadata/2006_Greenland_TO/060526.motion2';
  params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Litton_DGPS';
  gps_source{file_idx} = 'ATM-final_20080621';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
   
  file_idx = file_idx + 1;
  year = 2006; month = 5; day = 27;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = '/cresis/snfs1/dataproducts/metadata/2006_Greenland_TO/060527.motion2';
  params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Litton_DGPS';
  gps_source{file_idx} = 'ATM-final_20080621';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
  
  file_idx = file_idx + 1;
  year = 2006; month = 5; day = 28;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'ATM_trajectory/Text Files'), ...
    sprintf('Alt%s',date_string),'','');
  params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ATM_ins/%s',date_string)), ...
    date_string,'','');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Traj+Litton';
  gps_source{file_idx} = 'ATM-final_20061109';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
   
  file_idx = file_idx + 1;
  year = 2006; month = 5; day = 29;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = '/cresis/snfs1/dataproducts/metadata/2006_Greenland_TO/060529.motion2';
  params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Litton_DGPS';
  gps_source{file_idx} = 'ATM-final_20080621';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
   
  file_idx = file_idx + 1;
  year = 2006; month = 5; day = 30;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = '/cresis/snfs1/dataproducts/metadata/2006_Greenland_TO/060530.motion2';
  params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Litton_DGPS';
  gps_source{file_idx} = 'ATM-final_20080621';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2006; month = 6; day = 1;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'ATM_trajectory/Text Files'), ...
    sprintf('Alt%s',date_string),'','');
  params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ATM_ins/%s',date_string)), ...
    date_string,'','');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Traj+Litton';
  gps_source{file_idx} = 'ATM-final_20061109';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2006; month = 6; day = 2;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'ATM_trajectory/Text Files'), ...
    sprintf('Alt%s',date_string),'','');
  params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ATM_ins/%s',date_string)), ...
    date_string,'','');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Traj+Litton';
  gps_source{file_idx} = 'ATM-final_20061109';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2006; month = 6; day = 6;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'ATM_trajectory/Text Files'), ...
    sprintf('Alt%s',date_string),'','');
  params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ATM_ins/%s',date_string)), ...
    date_string,'','');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Traj+Litton';
  gps_source{file_idx} = 'ATM-final_20061109';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2006; month = 6; day = 8;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'ATM_trajectory/Text Files'), ...
    sprintf('Alt%s',date_string),'','');
  params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ATM_ins/%s',date_string)), ...
    date_string,'','');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Traj+Litton';
  gps_source{file_idx} = 'ATM-final_20061109';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2006; month = 6; day = 9;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'ATM_trajectory/Text Files'), ...
    sprintf('Alt%s',date_string),'','');
  params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ATM_ins/%s',date_string)), ...
    date_string,'','');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Traj+Litton';
  gps_source{file_idx} = 'ATM-final_20061109';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2006; month = 6; day = 10;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'ATM_trajectory/Text Files'), ...
    sprintf('Alt%s',date_string),'','');
  params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ATM_ins/%s',date_string)), ...
    date_string,'','');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Traj+Litton';
  gps_source{file_idx} = 'ATM-final_20061109';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  file_idx = file_idx + 1;
  year = 2006; month = 6; day = 11;
  date_string = sprintf('%04.0f%02.0f%02.0f',year,month,day);
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'ATM_trajectory/Text Files'), ...
    sprintf('Alt%s',date_string),'','.txt');
  params{file_idx} = struct('year',year,'time_reference','gps','input_format','%f%f%f%f%f%f%f%f%f%f%f%f%f%f');
  in_fns_ins{file_idx} = get_filenames(fullfile(in_base_path,sprintf('ATM_ins/%s',date_string)), ...
    date_string,'','');
  params_ins{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  out_fns{file_idx} = sprintf('gps_%s.mat',date_string);
  file_type{file_idx} = 'Traj+Litton';
  gps_source{file_idx} = 'ATM-final_20061109';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,'gpsMCRDS/'), ...
    sprintf('nmea.%s',date_string),'','.gps');
  sync_params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);

  
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;




