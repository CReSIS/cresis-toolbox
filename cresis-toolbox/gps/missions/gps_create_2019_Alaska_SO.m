% script gps_create_2019_Alaska_SO
%
% Makes the GPS files for 2019_Alaska_SO field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2019_Alaska_SO');
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

in_base_path = fullfile(data_support_path,'2019_Alaska_SO');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_flag = {}; sync_fns = {}; sync_file_type = {}; sync_params = {};

gps_source_to_use = 'NMEA';

if strcmpi(gps_source_to_use,'NMEA')
%% NMEA
  
year = 2019; month = 3; day = 25;
file_idx = file_idx + 1;
in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'GPS','','.txt');
out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
file_type{file_idx} = 'NMEA';
params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
gps_source{file_idx} = 'nmea-field';
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
end
