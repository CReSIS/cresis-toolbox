% script gps_create_2018_antarctica_Ground
%
% Makes the GPS files for 2018 Antarctica Ground field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2018_Antarctica_Ground');
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

in_base_path = fullfile(data_support_path,'2018_Antarctica_Ground');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_flag = {}; sync_fns = {}; sync_file_type = {}; sync_params = {};

% gps_source_to_use = 'arena';
% gps_source_to_use = 'arena_cpu_time';
% gps_source_to_use = 'trimble_cpu_time_shun';
gps_source_to_use = 'trimble_cpu_time_paden';

if strcmpi(gps_source_to_use,'arena')
  %% ARENA
  
  %   year = 2018; month = 10; day = 12;
  %   file_idx = file_idx + 1;
  %   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  %   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  %   file_type{file_idx} = 'arena';
  %   params{file_idx} = struct('year',2018,'time_reference','utc');
  %   gps_source{file_idx} = 'arena-field';
  %   sync_flag{file_idx} = 1;
  %   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
  %   sync_file_type{file_idx} = 'arena';
  %   sync_params{file_idx} = struct('time_reference','utc');
  
    year = 2018; month = 10; day = 14;
    file_idx = file_idx + 1;
    in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
    out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
    file_type{file_idx} = 'arena';
    params{file_idx} = struct('year',2018,'time_reference','utc');
    gps_source{file_idx} = 'arena-field';
    sync_flag{file_idx} = 1;
    sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
    sync_file_type{file_idx} = 'arena';
    sync_params{file_idx} = struct('time_reference','utc');
  
%   year = 2018; month = 10; day = 15;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('year',2018,'time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('time_reference','utc');
  
elseif strcmpi(gps_source_to_use,'arena_cpu_time')
  correction = gps_create_2018_Antarctica_Ground_cpu_time(in_base_path);
    
%   year = 2018; month = 12; day = 17;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('UA_%04d%02d%02d',year,month,day)),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','awg0.txt');
%   sync_file_type{file_idx} = 'arena_cpu_time';
%   sync_params{file_idx} = struct('time_reference','utc', ...
%     'cpu_time_fn',fullfile(in_base_path,sprintf('cpu_time_%04d%02d%02d.csv',year,month,day)));
    
  year = 2018; month = 12; day = 20;
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,'UA_LOG',sprintf('UA_%04d%02d%02d',year,month,day)),'','','gps.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
  file_type{file_idx} = 'arena';
  params{file_idx} = struct('year',year,'month',month,'day',day,'time_reference','utc');
  gps_source{file_idx} = 'arena-field';
  sync_flag{file_idx} = 1;
  sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','awg0.txt');
  sync_file_type{file_idx} = 'arena_cpu_time';
  sync_params{file_idx} = struct('time_reference','utc', ...
    'cpu_time_correction',correction);

elseif strcmpi(gps_source_to_use,'trimble_cpu_time_shun')
  correction = gps_create_2018_Antarctica_Ground_cpu_time(in_base_path);

  % Shun processed with ? software, but noticed unusually large errors:
  % currently not using this versino of the processed data
  error('Do not use this gps_source.');

%   year = 2018; month = 12;
%   for day = [17 19 20 21 22 23 24 25 26 27 28 29]
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,'GNSS_SM111'),'','','iceradar_SM111_areaABC.pos');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'General_ASCII';
%     params{file_idx} = struct('time_reference','gps','headerlines',17,'format_str','%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f');
%     params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','f1','f2','f3','f4','f5','f6','f7','f8','f9','f10'};
%     params{file_idx}.textscan = {};
%     gps_source{file_idx} = 'brice-final20190404';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','awg0.txt');
%     sync_file_type{file_idx} = 'arena_cpu_time';
%     sync_params{file_idx} = struct('time_reference','utc', ...
%       'cpu_time_correction',correction);
%   end

%   year = 2018; month = 12;
%   for day = 31
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,'GNSS_SM111'),'','','iceradar_SM111_BC_ARP2.pos');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'General_ASCII';
%     params{file_idx} = struct('time_reference','gps','headerlines',17,'format_str','%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f');
%     params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','f1','f2','f3','f4','f5','f6','f7','f8','f9','f10'};
%     params{file_idx}.textscan = {};
%     gps_source{file_idx} = 'brice-final20190404';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','awg0.txt');
%     sync_file_type{file_idx} = 'arena_cpu_time';
%     sync_params{file_idx} = struct('time_reference','utc', ...
%       'cpu_time_correction',correction);
%   end

%   year = 2019; month = 1;
%   for day = [2 3 4 5 6 7 8]
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,'GNSS_SM111'),'','','iceradar_SM111_BC_ARP2.pos');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'General_ASCII';
%     params{file_idx} = struct('time_reference','gps','headerlines',17,'format_str','%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f');
%     params{file_idx}.types = {'date_MDY','time_HMS','lat_deg','lon_deg','elev_m','f1','f2','f3','f4','f5','f6','f7','f8','f9','f10'};
%     params{file_idx}.textscan = {};
%     gps_source{file_idx} = 'brice-final20190404';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','awg0.txt');
%     sync_file_type{file_idx} = 'arena_cpu_time';
%     sync_params{file_idx} = struct('time_reference','utc', ...
%       'cpu_time_correction',correction);
%   end
      
elseif strcmpi(gps_source_to_use,'trimble_cpu_time_paden')
  correction = gps_create_2018_Antarctica_Ground_cpu_time(in_base_path);
  
  % Paden processed with the Canadian online service. The results seem to
  % be smoother than Shun's processed results and the reported errors are
  % much smaller.
  %
  % HDR GRP CANADIAN GEODETIC SURVEY, SURVEYOR GENERAL BRANCH, NATURAL RESOURCES CANADA
  % HDR ADR GOVERNMENT OF CANADA, 588 BOOTH STREET ROOM 334, OTTAWA ONTARIO K1A 0Y7
  % HDR TEL 343-292-6617
  % HDR EMA nrcan.geodeticinformation-informationgeodesique.rncan@canada.ca
  % NOTE: Estimated positions are at the epoch of data
  % NOTE: Positive northing indicates northern hemisphere, negative northing indicates southern hemisphere
  % DIR FRAME  STN   DAYofYEAR YEAR-MM-DD HR:MN:SS.SS NSV GDOP RMSC(m) RMSP(m)       DLAT(m)       DLON(m)       DHGT(m)          CLK(ns)  TZD(m) SDLAT(95%) SDLON(95%) SDHGT(95%) SDCLK(95%) SDTZD(95%) LATDD LATMN    LATSS LONDD LONMN    LONSS     HGT(m) UTMZONE    UTM_EASTING   UTM_NORTHING UTM_SCLPNT UTM_SCLCBN
  % BWD IGS14 1812  352.161215 2018-12-18 03:52:09.00   5  6.2   0.328  0.0011       -2.5820       35.4766        8.8807     1604085.1542  1.3879     1.0353     0.9430     3.1299     6.8905     0.0046   -77    44  7.88354    39     6 55.84620  3777.0632      37    502739.2062  -1371143.1844   0.999600   0.999010

%   year = 2018; month = 12; day = 18; day_radar = 17;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,'Field_data_SM100',sprintf('%04d%02d%02d_PPP',year,month,day)),'','','0000.pos');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day_radar);
%   file_type{file_idx} = 'General_ASCII';
%     params{file_idx} = struct('time_reference','utc');
%     params{file_idx}.format_str = '%s%s%f%f%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f';
%     params{file_idx}.types = {'f01','f02','f03','f04','date_MDY','time_HMS','f05','f06','f07','f08','f09', ...
%       'f10','f11','f12','f13','f14','f15','f16','f17','f18','lat_deg','lat_min','lat_sec', ...
%       'lon_deg','lon_min','lon_sec','elev_m','f19','f20','f21','f22','f23'};
%     params{file_idx}.textscan = {};
%     params{file_idx}.headerlines = 7;
%   gps_source{file_idx} = 'trimble-final20200121';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day_radar)),'','','awg0.txt');
%   sync_file_type{file_idx} = 'arena_cpu_time';
%   sync_params{file_idx} = struct('time_reference','utc', ...
%     'cpu_time_correction',correction);

  year = 2018; month = 12;
  for day = 24%[19 20 21 22 23 24 25 26 27 28 29 31]
    file_idx = file_idx + 1;
    in_fns{file_idx} = get_filenames(fullfile(in_base_path,'Field_data_SM100',sprintf('%04d%02d%02d_PPP',year,month,day)),'','','0000.pos');
    out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
    file_type{file_idx} = 'General_ASCII';
    params{file_idx} = struct('time_reference','utc');
    params{file_idx}.format_str = '%s%s%f%f%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f';
    params{file_idx}.types = {'f01','f02','f03','f04','date_MDY','time_HMS','f05','f06','f07','f08','f09', ...
      'f10','f11','f12','f13','f14','f15','f16','f17','f18','lat_deg','lat_min','lat_sec', ...
      'lon_deg','lon_min','lon_sec','elev_m','f19','f20','f21','f22','f23'};
    params{file_idx}.textscan = {};
    params{file_idx}.headerlines = 7;
    gps_source{file_idx} = 'trimble-final20200121';
    sync_flag{file_idx} = 1;
    sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','awg0.txt');
    sync_file_type{file_idx} = 'arena_cpu_time';
    sync_params{file_idx} = struct('time_reference','utc', ...
      'cpu_time_correction',correction);
  end

%   year = 2019; month = 1;
%   for day = [2 3 4 5 6 7 8]
%     file_idx = file_idx + 1;
%     in_fns{file_idx} = get_filenames(fullfile(in_base_path,'Field_data_SM100',sprintf('%04d%02d%02d_PPP',year,month,day)),'','','0000.pos');
%     out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%     file_type{file_idx} = 'General_ASCII';
%     params{file_idx} = struct('time_reference','utc');
%     params{file_idx}.format_str = '%s%s%f%f%s%s%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f';
%     params{file_idx}.types = {'f01','f02','f03','f04','date_MDY','time_HMS','f05','f06','f07','f08','f09', ...
%       'f10','f11','f12','f13','f14','f15','f16','f17','f18','lat_deg','lat_min','lat_sec', ...
%       'lon_deg','lon_min','lon_sec','elev_m','f19','f20','f21','f22','f23'};
%     params{file_idx}.textscan = {};
%     params{file_idx}.headerlines = 7;
%     gps_source{file_idx} = 'trimble-final20200121';
%     sync_flag{file_idx} = 1;
%     sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','awg0.txt');
%     sync_file_type{file_idx} = 'arena_cpu_time';
%     sync_params{file_idx} = struct('time_reference','utc', ...
%       'cpu_time_correction',correction);
%   end
  
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
  
  if 0 && regexpi(gps.gps_source,'trimble_cpu_time_paden')
    % Smoothing is necessary due to vibration
    warning('Smoothing GPS and IMU data: %s', out_fn);
    gps = load(out_fn);
    
    gps.elev = sgolayfilt(gps.elev,2,201); % Adjust filter length as needed to remove high frequency noise
    
    heading_x = cos(gps.heading);
    heading_y = sin(gps.heading);
    heading_x  = sgolayfilt(heading_x,2,501); % Adjust filter length as needed to remove high frequency noise
    heading_y  = sgolayfilt(heading_y,2,501); % Adjust filter length as needed to remove high frequency noise
    new_heading = atan2(heading_y,heading_x);
    filter_mask = abs(new_heading-gps.heading) < 20/180*pi;
    gps.heading(filter_mask) = new_heading(filter_mask);
    
    save(out_fn,'-append','-struct','gps','elev','heading');
    
  end
  
  if regexpi(gps.gps_source,'trimble_cpu_time_shun')
    % Smoothing is necessary because data are poor quality
    warning('Smoothing GPS and IMU data: %s', out_fn);
    gps = load(out_fn);
    
    gps.lat = sgolayfilt(gps.lat,2,31); % Adjust filter length as needed to remove high frequency noise
    gps.lon = sgolayfilt(gps.lon,2,31); % Adjust filter length as needed to remove high frequency noise
    gps.elev = sgolayfilt(gps.elev,2,201); % Adjust filter length as needed to remove high frequency noise
    
    heading_x = cos(gps.heading);
    heading_y = sin(gps.heading);
    heading_x  = sgolayfilt(heading_x,2,31); % Adjust filter length as needed to remove high frequency noise
    heading_y  = sgolayfilt(heading_y,2,31); % Adjust filter length as needed to remove high frequency noise
    gps.heading = atan2(heading_y,heading_x);
    
    save(out_fn,'-append','-struct','gps','lat','lon','elev','heading');

  end
  
  if regexpi(out_fn,'201810XX')
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
