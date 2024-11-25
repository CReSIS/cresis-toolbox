% script gps_create_2021_Greenland_Polar5
%
% Makes the GPS files for 2021 Greenland Polar5 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';
season_name = '2021_Greenland_Polar5'

% use NMEA directly after the flight in the field
gps_source_to_use = 'NMEA';

% use AWI as soon the post processed  GPS_R_L1_......nc files are available
%gps_source_to_use = 'AWI';

%================================================================%
%Please edit this line for each new campaign flight
year = 2021; month = 7; day = 28;


%================================================================%


date_str = join([compose('%04d',year) compose('%02d',month) compose('%02d',day)],'');
date_str = date_str{1};
gps.date_str = date_str;

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps',season_name);
if ~exist(gps_path,'dir')
  fprintf('Making directory %s\n', gps_path);
  fprintf('  Press a key to proceed\n');
  pause;
  mkdir(gps_path);
end

if isempty(data_support_path)
  data_support_path = gRadar.data_support_path;
end

debug_level = 1;

in_base_path = fullfile(data_support_path,season_name);

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};


if strcmpi(gps_source_to_use,'NMEA')
  % =======================================================================
  % NMEA
  % =======================================================================
 
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(in_base_path,sprintf('GPS_%04d%02d%02d',year,month,day),'','.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 0;
  
elseif strcmpi(gps_source_to_use,'AWI')
  % =======================================================================
  % AWI
  % =======================================================================
  field_gps_in_base_path = fullfile(in_base_path,'');
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(field_gps_in_base_path,sprintf('GPS_R_L1_%04d%02d%02d',year,month,day),'','.nc');
  in_fns_ins{file_idx} = get_filenames(in_base_path,sprintf('INS_L1_%04d%02d%02d',year,month,day),'','.nc');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'awi_netcdf+awi_netcdf';
  gps_source{file_idx} = 'awi-field';
  sync_flag{file_idx} = 0;
  params{file_idx} = struct('time_reference','utc');
  params{file_idx}.nc_field = {'TIME','LATITUDE','LONGITUDE','ALTITUDE','YEAR','MONTH','DAY'};
  params{file_idx}.nc_type = {'v','v','v','v','a','a','a'};
  params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','year','month','day'};
  params{file_idx}.scale = [1e-3 1 1 1 1 1 1];
  params_ins{file_idx} = struct('time_reference','utc');
  params_ins{file_idx}.nc_field = {'TIME','ROLL','PITCH','THDG','YEAR','MONTH','DAY'};
  params_ins{file_idx}.nc_type = {'v','v','v','v','a','a','a'};
  params_ins{file_idx}.types = {'sec','roll_deg','pitch_deg','heading_deg','year','month','day'};
  params_ins{file_idx}.scale = [1e-3 1 1 1 1 1 1]; 
  
elseif strcmpi(gps_source_to_use,'AWI_final')
  
  % =======================================================================
  % AWI_final
  % =======================================================================
  
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(in_base_path,sprintf('GPS_R_L1_%04d%02d%02d',year,month,day),'','.nc');
  in_fns_ins{file_idx} = get_filenames(in_base_path,sprintf('INS_L1_%04d%02d%02d',year,month,day),'','.nc');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'awi_netcdf+awi_netcdf';
  gps_source{file_idx} = 'awi-final_20161109';
  sync_flag{file_idx} = 0;
  params{file_idx} = struct('time_reference','utc');
  params{file_idx}.nc_field = {'TIME','LATITUDE','LONGITUDE','ALTITUDE','YEAR','MONTH','DAY'};
  params{file_idx}.nc_type = {'v','v','v','v','a','a','a'};
  params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','year','month','day'};
  params{file_idx}.scale = [1e-3 1 1 1 1 1 1];
  params_ins{file_idx} = struct('time_reference','utc');
  params_ins{file_idx}.nc_field = {'TIME','ROLL','PITCH','THDG','YEAR','MONTH','DAY'};
  params_ins{file_idx}.nc_type = {'v','v','v','v','a','a','a'};
  params_ins{file_idx}.types = {'sec','roll_deg','pitch_deg','heading_deg','year','month','day'};
  params_ins{file_idx}.scale = [1e-3 1 1 1 1 1 1];
  
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
  gps_create;

%% No GPS Data Available: Fakes GPS position information
match_idx = strmatch('gps_20160331.mat',out_fns,'exact');
if ~isempty(match_idx)
  gps_fn = fullfile(gps_path,out_fns{match_idx});
  fprintf('Creating fake gps data for %s\n', gps_fn);
  gps = load(gps_fn);
  gps.gps_time = datenum_to_epoch(datenum(2016,3,31) + (50000:65000)/86400);
  gps.lon = -45 * ones(size(gps.gps_time));
  gps.lat = 70 + (1:length(gps.gps_time)) * 6e-4;
  gps.elev = 500 * ones(size(gps.gps_time));
  gps.roll = zeros(size(gps.gps_time));
  gps.pitch = zeros(size(gps.gps_time));
  gps.heading = zeros(size(gps.gps_time));
  save(gps_fn,'-append','-struct','gps','gps_time','lat','lon','elev','roll','pitch','heading');
end
   
   
