% script gps_create_2016_greenland_TOdtu
%
% Makes the GPS files for 2016 Greenland TOdtu field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2016_Greenland_TOdtu');
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

in_base_path = fullfile(data_support_path,'2016_Greenland_TOdtu');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

% gps_source_to_use = 'NMEA';
gps_source_to_use = 'DTU';

if strcmpi(gps_source_to_use,'NMEA')
    
%   year = 2016; month = 11; day = 1;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',3,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

elseif strcmpi(gps_source_to_use,'DTU')
    
  year = 2016; month = 11; day = 1;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'306_a2_ppp.p10')};
  in_fns_ins{file_idx} = {fullfile(in_base_path,'INS','306_gpsegi.pos')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'General_ASCII';
  file_type_ins{file_idx} = 'General_ASCII';
  gps_source{file_idx} = 'dtu-final20161129';
  sync_flag{file_idx} = 0;
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%f%f%f%f%f%f%f';
  params{file_idx}.types = {'sow','lat_deg','lon_deg','elev_m'};
  params{file_idx}.textscan = {'Delimiter',' ','EmptyValue',NaN,'MultipleDelimsAsOne',true};
  params{file_idx}.headerlines = 14;
  params{file_idx}.year = year;
  params{file_idx}.month = month;
  params{file_idx}.day = day;
  params_ins{file_idx} = struct('time_reference','gps');
  params_ins{file_idx}.format_str = '%f%f%f%f%f%f%f';
  params_ins{file_idx}.types = {'hour','lat_deg','lon_deg','elev_m','pitch_deg','roll_deg','heading_deg'};
  params_ins{file_idx}.textscan = {'Delimiter',' ','EmptyValue',NaN,'MultipleDelimsAsOne',true};
  params_ins{file_idx}.headerlines = 0;
  params_ins{file_idx}.year = year;
  params_ins{file_idx}.month = month;
  params_ins{file_idx}.day = day;
  sync_flag{file_idx} = 0;
      
  year = 2016; month = 11; day = 2;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'307_a2_ppp.p10')};
  in_fns_ins{file_idx} = {fullfile(in_base_path,'INS','307_gpsegi.pos')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'General_ASCII';
  file_type_ins{file_idx} = 'General_ASCII';
  gps_source{file_idx} = 'dtu-final20161129';
  sync_flag{file_idx} = 0;
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%f%f%f%f%f%f%f';
  params{file_idx}.types = {'sow','lat_deg','lon_deg','elev_m'};
  params{file_idx}.textscan = {'Delimiter',' ','EmptyValue',NaN,'MultipleDelimsAsOne',true};
  params{file_idx}.headerlines = 14;
  params{file_idx}.year = year;
  params{file_idx}.month = month;
  params{file_idx}.day = day;
  params_ins{file_idx} = struct('time_reference','gps');
  params_ins{file_idx}.format_str = '%f%f%f%f%f%f%f';
  params_ins{file_idx}.types = {'hour','lat_deg','lon_deg','elev_m','pitch_deg','roll_deg','heading_deg'};
  params_ins{file_idx}.textscan = {'Delimiter',' ','EmptyValue',NaN,'MultipleDelimsAsOne',true};
  params_ins{file_idx}.headerlines = 0;
  params_ins{file_idx}.year = year;
  params_ins{file_idx}.month = month;
  params_ins{file_idx}.day = day;
  sync_flag{file_idx} = 0;
    
  year = 2016; month = 11; day = 7;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'312_a2_ppp.p10')};
  in_fns_ins{file_idx} = {fullfile(in_base_path,'INS','312_gpsegi.pos')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'General_ASCII';
  file_type_ins{file_idx} = 'General_ASCII';
  gps_source{file_idx} = 'dtu-final20161129';
  sync_flag{file_idx} = 0;
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%f%f%f%f%f%f%f';
  params{file_idx}.types = {'sow','lat_deg','lon_deg','elev_m'};
  params{file_idx}.textscan = {'Delimiter',' ','EmptyValue',NaN,'MultipleDelimsAsOne',true};
  params{file_idx}.headerlines = 14;
  params{file_idx}.year = year;
  params{file_idx}.month = month;
  params{file_idx}.day = day;
  params_ins{file_idx} = struct('time_reference','gps');
  params_ins{file_idx}.format_str = '%f%f%f%f%f%f%f';
  params_ins{file_idx}.types = {'hour','lat_deg','lon_deg','elev_m','pitch_deg','roll_deg','heading_deg'};
  params_ins{file_idx}.textscan = {'Delimiter',' ','EmptyValue',NaN,'MultipleDelimsAsOne',true};
  params_ins{file_idx}.headerlines = 0;
  params_ins{file_idx}.year = year;
  params_ins{file_idx}.month = month;
  params_ins{file_idx}.day = day;
  sync_flag{file_idx} = 0;
    
  year = 2016; month = 11; day = 8;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'313_a2_ppp.p10')};
  in_fns_ins{file_idx} = {fullfile(in_base_path,'INS','313_gpsegi.pos')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'General_ASCII';
  file_type_ins{file_idx} = 'General_ASCII';
  gps_source{file_idx} = 'dtu-final20161129';
  sync_flag{file_idx} = 0;
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%f%f%f%f%f%f%f';
  params{file_idx}.types = {'sow','lat_deg','lon_deg','elev_m'};
  params{file_idx}.textscan = {'Delimiter',' ','EmptyValue',NaN,'MultipleDelimsAsOne',true};
  params{file_idx}.headerlines = 14;
  params{file_idx}.year = year;
  params{file_idx}.month = month;
  params{file_idx}.day = day;
  params_ins{file_idx} = struct('time_reference','gps');
  params_ins{file_idx}.format_str = '%f%f%f%f%f%f%f';
  params_ins{file_idx}.types = {'hour','lat_deg','lon_deg','elev_m','pitch_deg','roll_deg','heading_deg'};
  params_ins{file_idx}.textscan = {'Delimiter',' ','EmptyValue',NaN,'MultipleDelimsAsOne',true};
  params_ins{file_idx}.headerlines = 0;
  params_ins{file_idx}.year = year;
  params_ins{file_idx}.month = month;
  params_ins{file_idx}.day = day;
  sync_flag{file_idx} = 0;
  
  year = 2016; month = 11; day = 10;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'315_a2_ppp.p10')};
  in_fns_ins{file_idx} = {fullfile(in_base_path,'INS','315_gpsegi.pos')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'General_ASCII';
  file_type_ins{file_idx} = 'General_ASCII';
  gps_source{file_idx} = 'dtu-final20161129';
  sync_flag{file_idx} = 0;
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%f%f%f%f%f%f%f';
  params{file_idx}.types = {'sow','lat_deg','lon_deg','elev_m'};
  params{file_idx}.textscan = {'Delimiter',' ','EmptyValue',NaN,'MultipleDelimsAsOne',true};
  params{file_idx}.headerlines = 14;
  params{file_idx}.year = year;
  params{file_idx}.month = month;
  params{file_idx}.day = day;
  params_ins{file_idx} = struct('time_reference','gps');
  params_ins{file_idx}.format_str = '%f%f%f%f%f%f%f';
  params_ins{file_idx}.types = {'hour','lat_deg','lon_deg','elev_m','pitch_deg','roll_deg','heading_deg'};
  params_ins{file_idx}.textscan = {'Delimiter',' ','EmptyValue',NaN,'MultipleDelimsAsOne',true};
  params_ins{file_idx}.headerlines = 0;
  params_ins{file_idx}.year = year;
  params_ins{file_idx}.month = month;
  params_ins{file_idx}.day = day;
  sync_flag{file_idx} = 0;
  
  year = 2016; month = 11; day = 11;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'316_a2_ppp.p10')};
  in_fns_ins{file_idx} = {fullfile(in_base_path,'INS','316_gpsegi.pos')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'General_ASCII';
  file_type_ins{file_idx} = 'General_ASCII';
  gps_source{file_idx} = 'dtu-final20161129';
  sync_flag{file_idx} = 0;
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%f%f%f%f%f%f%f';
  params{file_idx}.types = {'sow','lat_deg','lon_deg','elev_m'};
  params{file_idx}.textscan = {'Delimiter',' ','EmptyValue',NaN,'MultipleDelimsAsOne',true};
  params{file_idx}.headerlines = 14;
  params{file_idx}.year = year;
  params{file_idx}.month = month;
  params{file_idx}.day = day;
  params_ins{file_idx} = struct('time_reference','gps');
  params_ins{file_idx}.format_str = '%f%f%f%f%f%f%f';
  params_ins{file_idx}.types = {'hour','lat_deg','lon_deg','elev_m','pitch_deg','roll_deg','heading_deg'};
  params_ins{file_idx}.textscan = {'Delimiter',' ','EmptyValue',NaN,'MultipleDelimsAsOne',true};
  params_ins{file_idx}.headerlines = 0;
  params_ins{file_idx}.year = year;
  params_ins{file_idx}.month = month;
  params_ins{file_idx}.day = day;
  sync_flag{file_idx} = 0;
  
  year = 2016; month = 11; day = 12;
  file_idx = file_idx + 1;
  in_fns{file_idx} = {fullfile(in_base_path,'317_a2_ppp.p10')};
  in_fns_ins{file_idx} = {fullfile(in_base_path,'INS','317_gpsegi.pos')};
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'General_ASCII';
  file_type_ins{file_idx} = 'General_ASCII';
  gps_source{file_idx} = 'dtu-final20161129';
  sync_flag{file_idx} = 0;
  params{file_idx} = struct('time_reference','gps');
  params{file_idx}.format_str = '%f%f%f%f%f%f%f';
  params{file_idx}.types = {'sow','lat_deg','lon_deg','elev_m'};
  params{file_idx}.textscan = {'Delimiter',' ','EmptyValue',NaN,'MultipleDelimsAsOne',true};
  params{file_idx}.headerlines = 14;
  params{file_idx}.year = year;
  params{file_idx}.month = month;
  params{file_idx}.day = day;
  params_ins{file_idx} = struct('time_reference','gps');
  params_ins{file_idx}.format_str = '%f%f%f%f%f%f%f';
  params_ins{file_idx}.types = {'hour','lat_deg','lon_deg','elev_m','pitch_deg','roll_deg','heading_deg'};
  params_ins{file_idx}.textscan = {'Delimiter',' ','EmptyValue',NaN,'MultipleDelimsAsOne',true};
  params_ins{file_idx}.headerlines = 0;
  params_ins{file_idx}.year = year;
  params_ins{file_idx}.month = month;
  params_ins{file_idx}.day = day;
  sync_flag{file_idx} = 0;
  
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

