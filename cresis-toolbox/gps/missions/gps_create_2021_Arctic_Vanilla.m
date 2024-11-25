% script gps_create_2021_Arctic_Vanilla
%
% Makes the GPS files for 2021 Aarctic Vanilla field season

%% Setup
% =========================================================================
tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2021_Arctic_Vanilla');
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
in_base_path = fullfile(data_support_path,'2021_Arctic_Vanilla');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_flag = {}; sync_fns = {}; sync_file_type = {}; sync_params = {};

season_name = '2021_Alaska_SO';
gps_source_to_use = 'arena';

if strcmpi(gps_source_to_use,'arena')
  %% ARENA GPS SOURCE
  % =======================================================================
  
%   year = 2021; month = 4; day = 14;
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day),'config_logs'),'','','gps.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
%   file_type{file_idx} = 'arena';
%   params{file_idx} = struct('year',2021,'month',4,'day',14,'time_reference','utc');
%   gps_source{file_idx} = 'arena-field';
%   sync_flag{file_idx} = 1;
%   sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day),'config_logs'),'','','gps.txt');
%   sync_file_type{file_idx} = 'arena';
%   sync_params{file_idx} = struct('year',2021,'month',4,'day',14,'time_reference','utc');
%   date_str{file_idx} = '20210414';

year = 2021; month = 8; day = 19;
file_idx = file_idx + 1;
in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day),'logs'),'','','gps.txt');
out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', year, month, day);
file_type{file_idx} = 'arena';
params{file_idx} = struct('year',2021,'month',8,'day',19,'time_reference','utc');
gps_source{file_idx} = 'arena-field';
sync_flag{file_idx} = 1;
sync_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day),'logs'),'','','gps.txt');
sync_file_type{file_idx} = 'arena';
sync_params{file_idx} = struct('year',2021,'month',8,'day',19,'time_reference','utc');
date_str{file_idx} = '20210819';
end

%% gps_create
% Read and translate files according to user settings
% =========================================================================
gps_create;

%% custom fixes
% =========================================================================
for idx = 1:length(file_type)
  if strcmpi(date_str{idx},'20210414') || strcmpi(date_str{idx},'20210819') % Radar time is 2 seconds beyond GPS time
    out_fn = fullfile(gps_path,out_fns{idx});
    
    load(out_fn,'gps_source');
    if ~isempty(regexpi(gps_source,'arena'))
      % Extrapolation is necessary because GPS data starts after/stops before
      % the beginning/end of the radar data.
      warning('Extrapolating and filtering elevation for arena GPS data: %s', out_fn);
      gps = load(out_fn);
      
      if length(gps.lat) >= 2
        new_gps_time = [gps.gps_time,gps.gps_time(end)+5];
        gps.lat = interp1(gps.gps_time,gps.lat,new_gps_time,'linear','extrap');
        gps.lon = interp1(gps.gps_time,gps.lon,new_gps_time,'linear','extrap');
        gps.elev = interp1(gps.gps_time,gps.elev,new_gps_time,'linear','extrap');
        gps.roll = interp1(gps.gps_time,gps.roll,new_gps_time,'linear','extrap');
        gps.pitch = interp1(gps.gps_time,gps.pitch,new_gps_time,'linear','extrap');
        gps.heading = interp1(gps.gps_time,gps.heading,new_gps_time,'linear','extrap');
        gps.gps_time = new_gps_time;
        
%         gps.elev = fir_dec(gps.elev,ones(1,101)/101,1);
        
        save(out_fn,'-append','-struct','gps','gps_time','lat','lon','elev','roll','pitch','heading');
      end
    end
  end
end
