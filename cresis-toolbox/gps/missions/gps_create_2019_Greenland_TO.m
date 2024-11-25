% script gps_create_2019_greenland_TO
%
% Makes the GPS files for 2019_Greenland_TO field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2019_Greenland_TO');
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

in_base_path = fullfile(data_support_path,'2019_Greenland_TO');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_flag = {}; sync_fns = {}; sync_file_type = {}; sync_params = {};

gps_source_to_use = 'NMEA';
gps_source_to_use = 'DTU-precision';

if strcmpi(gps_source_to_use,'NMEA')
%% NMEA
  
% year = 2019; month = 3; day = 21;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
%   
% year = 2019; month = 3; day = 22;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

year = 2019; month = 8; day = 10;
file_idx = file_idx + 1;
in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
file_type{file_idx} = 'NMEA';
params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
gps_source{file_idx} = 'nmea-field';
sync_flag{file_idx} = 0;

% year = 2019; month = 8; day = 11;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% 
% year = 2019; month = 8; day = 12;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;
% 
% year = 2019; month = 8; day = 14;
% file_idx = file_idx + 1;
% in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
% out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
% file_type{file_idx} = 'NMEA';
% params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
% gps_source{file_idx} = 'nmea-field';
% sync_flag{file_idx} = 0;

elseif strcmpi(gps_source_to_use,'DTU-precision')
  
year = 2019; month = 8; day = 9;
file_idx = file_idx + 1;
in_fns{file_idx} = get_filenames(in_base_path,'221','','.pos');
out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
file_type{file_idx} = 'General_ASCII';
params{file_idx} = struct('year',year,'month',month,'day',day,'format_str','%f%f%f%f%f%f%f%f','headerlines',0,'time_reference','utc');
params{file_idx}.types = {'hour','lat_deg','lon_deg','elev_m','pitch_deg','roll_deg','heading_deg','non_relevant_int'};
params{file_idx}.textscan = {};
gps_source{file_idx} = 'dtu_final_20191108';
sync_flag{file_idx} = 0;
    
year = 2019; month = 8; day = 10;
file_idx = file_idx + 1;
in_fns{file_idx} = get_filenames(in_base_path,'222','','.pos');
out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
file_type{file_idx} = 'General_ASCII';
params{file_idx} = struct('year',year,'month',month,'day',day,'format_str','%f%f%f%f%f%f%f%f','headerlines',0,'time_reference','utc');
params{file_idx}.types = {'hour','lat_deg','lon_deg','elev_m','pitch_deg','roll_deg','heading_deg','non_relevant_int'};
params{file_idx}.textscan = {};
gps_source{file_idx} = 'dtu_final_20191108';
sync_flag{file_idx} = 0;

year = 2019; month = 8; day = 11;
file_idx = file_idx + 1;
in_fns{file_idx} = get_filenames(in_base_path,'223','','.pos');
out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
file_type{file_idx} = 'General_ASCII';
params{file_idx} = struct('year',year,'month',month,'day',day,'format_str','%f%f%f%f%f%f%f%f','headerlines',0,'time_reference','utc');
params{file_idx}.types = {'hour','lat_deg','lon_deg','elev_m','pitch_deg','roll_deg','heading_deg','non_relevant_int'};
params{file_idx}.textscan = {};
gps_source{file_idx} = 'dtu_final_20191108';
sync_flag{file_idx} = 0;

year = 2019; month = 8; day = 12;
file_idx = file_idx + 1;
in_fns{file_idx} = get_filenames(in_base_path,'224','','.pos');
out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
file_type{file_idx} = 'General_ASCII';
params{file_idx} = struct('year',year,'month',month,'day',day,'format_str','%f%f%f%f%f%f%f%f','headerlines',0,'time_reference','utc');
params{file_idx}.types = {'hour','lat_deg','lon_deg','elev_m','pitch_deg','roll_deg','heading_deg','non_relevant_int'};
params{file_idx}.textscan = {};
gps_source{file_idx} = 'dtu_final_20191108';
sync_flag{file_idx} = 0;

end


% ======================================================================
% Read and translate files according to user settings
% ======================================================================
gps_create;

for idx = 1:length(file_type)
  out_fn = fullfile(gps_path,out_fns{idx});
  
  gps = load(out_fn);
  if regexpi(gps.gps_source,'atm')
    
    warning('Smoothing INS data: %s', out_fn);
    
    gps.roll = sgolayfilt(gps.roll,2,101); % Adjust filter length as needed to remove high frequency noise
    gps.pitch = sgolayfilt(gps.pitch,2,101); % Adjust filter length as needed to remove high frequency noise
    heading_x = cos(gps.heading);
    heading_y = sin(gps.heading);
    heading_x  = sgolayfilt(heading_x,2,101); % Adjust filter length as needed to remove high frequency noise
    heading_y  = sgolayfilt(heading_y,2,101); % Adjust filter length as needed to remove high frequency noise
    gps.heading = atan2(heading_y,heading_x);
    
    save(out_fn,'-append','-struct','gps','roll','pitch','heading');
  end
  
  if regexpi(out_fn,'20190322')
    % Fake GPS for testing
    warning('Faking GPS data: %s', out_fn);
    gps = load(out_fn);
    
    velocity = 70;
    gps.lat = 75.5 - (gps.gps_time-gps.gps_time(1))*velocity/111111;
    gps.lon(:) = -45;
    gps.elev(:) = 500;
    gps.heading(:) = -pi;
    
    save(out_fn,'-append','-struct','gps','gps_time','lat','lon','elev','roll','pitch','heading');
  end
end
