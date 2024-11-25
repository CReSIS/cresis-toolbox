% script gps_create_2019_Antarctica_Ground
%
% Makes the GPS files for 2019 Antarctica Ground field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2019_Antarctica_Ground');
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

in_base_path = fullfile(data_support_path,'2019_Antarctica_Ground');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_flag = {}; sync_fns = {}; sync_file_type = {}; sync_params = {};

% gps_source_to_use = 'arena';
gps_source_to_use = 'novatel';

if strcmpi(gps_source_to_use,'arena')
  %% ARENA
  
%   year = 2019; month = 9; day = 25;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
  
%   year = 2019; month = 12; day = 30;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'20191230','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'20191230','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2019; month = 12; day = 31;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'20191231','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'20191231','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2020; month = 1; day = 1;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
  
%   year = 2020; month = 1; day = 3;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
  
%   year = 2020; month = 1; day = 4;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2020; month = 1; day = 5;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2020; month = 1; day = 6;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
  year = 2020; month = 1; day = 7;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'arena';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'arena-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');
  
  year = 2020; month = 1; day = 8;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'arena';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'arena-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');

elseif strcmpi(gps_source_to_use,'novatel')
  %% NOVATEL
  
%   year = 2019; month = 9; day = 25;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
% 
%   year = 2019; month = 12; day = 30;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,'',sprintf('%04d%02d%02d',year,month,day),'ver1.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('time_reference','gps','headerlines',15,'format_str','%s%s%f%f%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg','tmp_1','tmp_2','tmp_3'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'cresis-final20200505';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2019; month = 12; day = 31;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'20191231','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'20191231','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2020; month = 1; day = 1;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,'',sprintf('%04d%02d%02d',year,month,day),'ver1.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('time_reference','gps','headerlines',15,'format_str','%s%s%f%f%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg','tmp_1','tmp_2','tmp_3'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'cresis-final20200505';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2020; month = 1; day = 3;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,'',sprintf('%04d%02d%02d',year,month,day),'ver1.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('time_reference','gps','headerlines',15,'format_str','%s%s%f%f%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg','tmp_1','tmp_2','tmp_3'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'cresis-final20200505';
%   sync_flag{file_idx} = 0;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2020; month = 1; day = 4;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,'',sprintf('%04d%02d%02d',year,month,day),'ver1.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('time_reference','gps','headerlines',15,'format_str','%s%s%f%f%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg','tmp_1','tmp_2','tmp_3'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'cresis-final20200505';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2020; month = 1; day = 5;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,'',sprintf('%04d%02d%02d',year,month,day),'ver1.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('time_reference','gps','headerlines',15,'format_str','%s%s%f%f%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg','tmp_1','tmp_2','tmp_3'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'cresis-final20200505';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
%   
%   year = 2020; month = 1; day = 6;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(in_base_path,'',sprintf('%04d%02d%02d',year,month,day),'ver1.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'General_ASCII';
%   params{file_idx} = struct('time_reference','gps','headerlines',15,'format_str','%s%s%f%f%f%f%f%f%f%f%f');
%   params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg','tmp_1','tmp_2','tmp_3'};
%   params{file_idx}.textscan = {};
%   gps_source{file_idx} = 'cresis-final20200505';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
% 
  year = 2020; month = 1; day = 7;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(in_base_path,'',sprintf('%04d%02d%02d',year,month,day),'ver1.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('time_reference','gps','headerlines',15,'format_str','%s%s%f%f%f%f%f%f%f%f%f');
  params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg','tmp_1','tmp_2','tmp_3'};
  params{file_idx}.textscan = {};
  gps_source{file_idx} = 'cresis-final20200505';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');

  year = 2020; month = 1; day = 8;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(in_base_path,'',sprintf('%04d%02d%02d',year,month,day),'ver1.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'General_ASCII';
  params{file_idx} = struct('time_reference','gps','headerlines',15,'format_str','%s%s%f%f%f%f%f%f%f%f%f');
  params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','roll_deg','pitch_deg','heading_deg','tmp_1','tmp_2','tmp_3'};
  params{file_idx}.textscan = {};
  gps_source{file_idx} = 'cresis-final20200505';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  sync_file_type{file_idx} = 'arena';
  sync_params{file_idx} = struct('time_reference','utc');

end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

for idx = 1:length(file_type)
  out_fn = fullfile(gps_path,out_fns{idx});
  
  gps = load(out_fn,'gps_source');
  if regexpi(gps.gps_source,'arena')
    % Extrapolation is necessary because GPS data starts after/stops before
    % the beginning/end of the radar data.
    warning('Extrapolating arena GPS data: %s', out_fn);
    gps = load(out_fn);
    
    if length(gps.lat) >= 2
      new_gps_time = [gps.gps_time(1)-10, gps.gps_time,gps.gps_time(end)+10];
      gps.lat = interp1(gps.gps_time,gps.lat,new_gps_time,'linear','extrap');
      gps.lon = interp1(gps.gps_time,gps.lon,new_gps_time,'linear','extrap');
      gps.elev = interp1(gps.gps_time,gps.elev,new_gps_time,'linear','extrap');
      gps.roll = interp1(gps.gps_time,gps.roll,new_gps_time,'linear','extrap');
      gps.pitch = interp1(gps.gps_time,gps.pitch,new_gps_time,'linear','extrap');
      gps.heading = interp1(gps.gps_time,gps.heading,new_gps_time,'linear','extrap');
      gps.gps_time = new_gps_time;
      
      save(out_fn,'-append','-struct','gps','gps_time','lat','lon','elev','roll','pitch','heading');
    end
  end
  
  if regexp(out_fn,'gps_20200104|gps_20200106')
    warning('Fixing radar_time and comp_time: %s', out_fn);
    gps = load(out_fn);
    
    gps.comp_time = gps.comp_time(2:end);
    gps.radar_time = gps.radar_time(2:end);
    gps.sync_elev = gps.sync_elev(2:end);
    gps.sync_gps_time = gps.sync_gps_time(2:end);
    gps.sync_lat = gps.sync_lat(2:end);
    gps.sync_lon = gps.sync_lon(2:end);
    save(out_fn,'-append','-struct','gps','comp_time','radar_time','sync_elev','sync_gps_time','sync_lat','sync_lon');
  end
  
  gps = load(out_fn,'gps_source');
  if ~isempty(regexp(gps.gps_source,'arena'))
    gps = load(out_fn,'elev');
    warning('Filtering elevation: %s', out_fn);
    gps.elev = fir_dec(gps.elev,ones(1,101)/101,1);
    save(out_fn,'-append','-struct','gps','elev');
  end
  
  if regexpi(out_fn,'201910XX')
    % Fake GPS for testing
    warning('Faking GPS data: %s', out_fn);
    gps = load(out_fn);
    
    velocity = 4;
    gps.lat = -75.5 - (gps.gps_time-gps.gps_time(1))*velocity/111111;
    gps.lon(:) = -106.75;
    gps.elev(:) = 500;
    gps.heading(:) = -pi;
    
    save(out_fn,'-append','-struct','gps','gps_time','lat','lon','elev','roll','pitch','heading');
  end
  
end
