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
% gps_source_to_use = 'novatelraw';
gps_source_to_use = 'utig';
% gps_source_to_use = 'cresis';

if strcmpi(gps_source_to_use,'utig')
  %% "utig ELSA" GPS SOURCE
  % =======================================================================

%   year = 2023; month = 1; day = 16;
%   datestr_year = 2023; datestr_month = 1; datestr_day = 16; % <--- UPDATE TO MATCH WHAT PREPROCESS PRINTS OUT
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day),'ELSA'),'serial','','');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d_utig.mat', datestr_year, datestr_month, datestr_day);
%   date_str{file_idx} = sprintf('%04d%02d%02d', datestr_year, datestr_month, datestr_day);
%   file_type{file_idx} = 'utig';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'utig-field';
%   sync_flag{file_idx} = 0;

%   year = 2023; month = 1; day = 20;
%   datestr_year = 2023; datestr_month = 1; datestr_day = 20; % <--- UPDATE TO MATCH WHAT PREPROCESS PRINTS OUT
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day),'ELSA'),'serial','','');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d_utig.mat', datestr_year, datestr_month, datestr_day);
%   date_str{file_idx} = sprintf('%04d%02d%02d', datestr_year, datestr_month, datestr_day);
%   file_type{file_idx} = 'utig';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'utig-field';
%   sync_flag{file_idx} = 0;

%   year = 2023; month = 1; day = 25;
%   datestr_year = 2023; datestr_month = 1; datestr_day = 25; % <--- UPDATE TO MATCH WHAT PREPROCESS PRINTS OUT
%   file_idx = file_idx + 1;
%   in_fns{file_idx} = get_filenames(fullfile(in_base_path,sprintf('%04d%02d%02d',year,month,day),'ELSA'),'serial','','');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d_utig.mat', datestr_year, datestr_month, datestr_day);
%   date_str{file_idx} = sprintf('%04d%02d%02d', datestr_year, datestr_month, datestr_day);
%   file_type{file_idx} = 'utig';
%   params{file_idx} = struct('time_reference','utc');
%   gps_source{file_idx} = 'utig-field';
%   sync_flag{file_idx} = 0;
  
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
  
%   gps = load(out_fn);
end
