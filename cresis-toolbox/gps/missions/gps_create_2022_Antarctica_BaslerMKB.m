% script gps_create_2022_Antarctica_BaslerMKB
%
% Makes the GPS files for 2022_Antarctica_BaslerMKB field season

%% Setup
% =========================================================================
tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

season_name = '2022_Antarctica_BaslerMKB';

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

in_base_path = fullfile(data_support_path,season_name);

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_flag = {}; sync_fns = {}; sync_file_type = {}; sync_params = {};

%% <== CHOOSE WHICH GPS SOURCE TO PROCESS
gps_source_to_use = 'novatelraw';
% gps_source_to_use = 'cresis';

if strcmpi(gps_source_to_use,'novatelraw')
  %% sonntag_nav GPS SOURCE
  % =======================================================================

%   year = 2023; month = 1; day = 10;
%   datestr_year = 2023; datestr_month = 1; datestr_day = 9; % <--- UPDATE TO MATCH WHAT PREPROCESS PRINTS OUT
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', datestr_year, datestr_month, datestr_day);
%   date_str{file_idx} = sprintf('%04d%02d%02d', datestr_year, datestr_month, datestr_day);
%   file_type{file_idx} = 'novatelraw';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'novatelraw-field';
%   sync_flag{file_idx} = 0;

%   year = 2023; month = 1; day = 11;
%   datestr_year = 2023; datestr_month = 1; datestr_day = 10; % <--- UPDATE TO MATCH WHAT PREPROCESS PRINTS OUT
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', datestr_year, datestr_month, datestr_day);
%   date_str{file_idx} = sprintf('%04d%02d%02d', datestr_year, datestr_month, datestr_day);
%   file_type{file_idx} = 'novatelraw';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'novatelraw-field';
%   sync_flag{file_idx} = 0;

%   year = 2023; month = 1; day = 14;
%   datestr_year = 2023; datestr_month = 1; datestr_day = 13; % <--- UPDATE TO MATCH WHAT PREPROCESS PRINTS OUT
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', datestr_year, datestr_month, datestr_day);
%   date_str{file_idx} = sprintf('%04d%02d%02d', datestr_year, datestr_month, datestr_day);
%   file_type{file_idx} = 'novatelraw';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'novatelraw-field';
%   sync_flag{file_idx} = 0;

%   year = 2023; month = 1; day = 16;
%   datestr_year = 2023; datestr_month = 1; datestr_day = 16; % <--- UPDATE TO MATCH WHAT PREPROCESS PRINTS OUT
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','','gps');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', datestr_year, datestr_month, datestr_day);
%   date_str{file_idx} = sprintf('%04d%02d%02d', datestr_year, datestr_month, datestr_day);
%   file_type{file_idx} = 'novatelraw';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'novatelraw-field';
%   sync_flag{file_idx} = 0;

%   year = 2023; month = 1; day = 20;
%   datestr_year = 2023; datestr_month = 1; datestr_day = 20; % <--- UPDATE TO MATCH WHAT PREPROCESS PRINTS OUT
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','aq-field22','gps');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', datestr_year, datestr_month, datestr_day);
%   date_str{file_idx} = sprintf('%04d%02d%02d', datestr_year, datestr_month, datestr_day);
%   file_type{file_idx} = 'novatelraw';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'novatelraw-field';
%   sync_flag{file_idx} = 0;

%   year = 2023; month = 1; day = 25;
%   datestr_year = 2023; datestr_month = 1; datestr_day = 24; % <--- UPDATE TO MATCH WHAT PREPROCESS PRINTS OUT
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','aq-field22','gps');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', datestr_year, datestr_month, datestr_day);
%   date_str{file_idx} = sprintf('%04d%02d%02d', datestr_year, datestr_month, datestr_day);
%   file_type{file_idx} = 'novatelraw';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'novatelraw-field';
%   sync_flag{file_idx} = 0;

%   year = 2023; month = 1; day = 26;
%   datestr_year = 2023; datestr_month = 1; datestr_day = 25; % <--- UPDATE TO MATCH WHAT PREPROCESS PRINTS OUT
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','aq-field22','gps');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', datestr_year, datestr_month, datestr_day);
%   date_str{file_idx} = sprintf('%04d%02d%02d', datestr_year, datestr_month, datestr_day);
%   file_type{file_idx} = 'novatelraw';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'novatelraw-field';
%   sync_flag{file_idx} = 0;
% 
%   year = 2023; month = 1; day = 27;
%   datestr_year = 2023; datestr_month = 1; datestr_day = 26; % <--- UPDATE TO MATCH WHAT PREPROCESS PRINTS OUT
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','aq-field22','gps');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', datestr_year, datestr_month, datestr_day);
%   date_str{file_idx} = sprintf('%04d%02d%02d', datestr_year, datestr_month, datestr_day);
%   file_type{file_idx} = 'novatelraw';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'novatelraw-field';
%   sync_flag{file_idx} = 0;

  year = 2023; month = 1; day = 28;
  datestr_year = 2023; datestr_month = 1; datestr_day = 27; % <--- UPDATE TO MATCH WHAT PREPROCESS PRINTS OUT
  file_idx = file_idx + 1;
  in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day)),'','aq-field22','gps');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat', datestr_year, datestr_month, datestr_day);
  date_str{file_idx} = sprintf('%04d%02d%02d', datestr_year, datestr_month, datestr_day);
  file_type{file_idx} = 'novatelraw';
  params{file_idx} = struct('time_reference','utc');
  gps_source{file_idx} = 'novatelraw-field';
  sync_flag{file_idx} = 0;

  
elseif strcmpi(gps_source_to_use,'cresis')
  %% CReSIS GPS SOURCE
  % =======================================================================

  % DO NOT USE IN FIELD
end

%% gps_create
% Read and translate files according to user settings
% =========================================================================
gps_create;

%% custom fixes
% =========================================================================
for idx = 1:length(file_type)
  out_fn = fullfile(gps_path,out_fns{idx});
  
  gps = load(out_fn);

  if ~isempty(regexpi(gps_source,'novatelraw')) && ~isempty(regexpi(out_fn,'20230113'))
    gps.roll(:) = 0;
    gps.pitch(:) = 0;
    [est_heading,along_track,speed] = trajectory_coord_system(gps);
    gps.heading = est_heading;
    
    save(out_fn,'-append','-struct','gps','roll','pitch','heading');
  end
  
  % Arena 500's radar_time is UTC time, fill in sync fields with this
  % information.
  gps.radar_time = gps.gps_time - utc_leap_seconds(gps.gps_time(1));
  gps.sync_gps_time = gps.gps_time;
  gps.sync_lat = gps.lat;
  gps.sync_lon = gps.lon;
  gps.sync_elev = gps.elev;
  
  fprintf('Saving sync fields into %s\n', out_fn);
  save(out_fn,'-append','-struct','gps','radar_time','sync_gps_time','sync_lat','sync_lon','sync_elev');  
end
