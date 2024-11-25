function ctrl_chain = preprocess(param,param_override)
% ctrl_chain = preprocess(param,param_override)
%
% 1. Copy metadata files if applicable
% 2. Load raw data files:
%   a. Create temporary header files for records_create
%   b. Create network header stripped raw data files if applicable
% 3. Break data into segments
% 4. Create parameter spreadsheet entries
% 5. Load GPS data and create maps of each segment and file if applicable
%
% Author: John Paden
%
% See also: run_preprocess.m, preprocess.m, preprocess_task.m

%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, '', datestr(now));
fprintf('=====================================================================\n');

%% Create each task
% =========================================================================

fun = 'preprocess_task';

ctrl = cluster_new_batch(param_override);

cluster_compile(fun,[],0,ctrl);

sparam = [];
sparam.task_function = fun;
sparam.argsin{1} = param; % Static parameters
sparam.num_args_out = 1;
for config_idx = 1:numel(param.config.default)

  cparam = param.config.default{config_idx}();
  cparam.config.default = param.config.default{config_idx};
  if isfield(param.config,'base_dir')
    cparam.config.base_dir = param.config.base_dir{config_idx};
    cparam.config.config_folder_names = param.config.config_folder_names{config_idx};
    cparam.config.board_folder_names = param.config.board_folder_names{config_idx};
    cparam.config.date_str = param.config.date_str{config_idx};
  else
    cparam.config.base_dir = '';
    cparam.config.config_folder_names = '';
    cparam.config.board_folder_names = '%b';
    cparam.config.date_str = datestr(now,'yyyymmdd');
  end
  if isfield(param.config,'regexp')
    cparam.config.file.regexp = param.config.regexp{config_idx};
  end
  cparam = merge_structs(cparam, param_override);
  
  %% Input checks
  % =========================================================================
  
  % .config.cpu_time_per_file: Positive double with units of seconds.
  % Default is 10 seconds. Cluster cpu_time allotment per raw data file
  if ~isfield(cparam.config,'cpu_time_per_file') || isempty(cparam.config.cpu_time_per_file)
    cparam.config.cpu_time_per_file = 10;
  end
  if ~isfield(cparam.config,'date_str') || isempty(cparam.config.date_str)
    % Segment ID is created from the date of the config folder unless this
    % cell array is set.
    cparam.config.date_str = {};
  end
  if ~isfield(cparam.config,'file') || isempty(cparam.config.file)
    cparam.config.file = [];
  end
  % .config.file.prefix: get_filenames prefix argument. Leave empty to
  % not use. Default is ''.
  if ~isfield(cparam.config.file,'prefix') || isempty(cparam.config.file.prefix)
    cparam.config.file.prefix = '';
  end
  % .config.file.midfix: get_filenames midfix argument. Leave empty to
  % not use. Default is ''.
  if ~isfield(cparam.config.file,'midfix') || isempty(cparam.config.file.midfix)
    cparam.config.file.midfix = '';
  end
  % .config.file.suffix: get_filenames suffix argument. Leave empty to
  % not use. Default is ''.
  if ~isfield(cparam.config.file,'suffix') || isempty(cparam.config.file.suffix)
    cparam.config.file.suffix = '';
  end
  % .config.file.regexp: get_filenames regular expression. Leave empty to
  % not use. Default is ''.
  if ~isfield(cparam.config.file,'regexp') || isempty(cparam.config.file.regexp)
    cparam.config.file.regexp = '';
  end
  % .config.gps_file_mask: File mask relative to
  % param.config.config_folder_name for GPS files. Leave empty if there are
  % no GPS files to copy. Default is an empty string.
  if ~isfield(cparam.config,'gps_file_mask') || isempty(cparam.config.gps_file_mask)
    cparam.config.gps_file_mask = '';
  end
  if ~isfield(cparam.config,'max_time_gap') || isempty(cparam.config.max_time_gap)
    % Maximum time in seconds between two data records before forcing a segment break
    cparam.config.max_time_gap = 10;
  end
  % .config.min_seg_size: Scalar integer. Default is 2. Minimum number of files in
  % a segment (segments with less files will be discarded)
  if ~isfield(cparam.config,'min_seg_size') || isempty(cparam.config.min_seg_size)
    cparam.config.min_seg_size = 2;
  end
  % .config.online_mode: Scaler integer. Default is 0. Allowed values:
  % * 0: not online mode
  % * 1: online mode (process all files)
  % * 2: online mode (process only the most recent file)
  if ~isfield(cparam.config,'online_mode') || isempty(cparam.config.online_mode)
    cparam.config.online_mode = 0;
  end
  % .config.param_fn: String containing the parameter spreadsheet filename.
  % Default is RADARNAME_param_SEASONNAME.xls.
  if ~isfield(cparam.config,'param_fn') || isempty(cparam.config.param_fn)
    cparam.config.param_fn ...
      = ct_filename_param(sprintf('%s_param_%s.xls',ct_output_dir(cparam.radar_name),cparam.season_name));
  end
  % .config.reuse_tmp_files: Logical scaler. Default is true. If true, the
  % function will use any existing header files in ct_tmp and not recreate
  % them.
  if ~isfield(cparam.config,'reuse_tmp_files') || isempty(cparam.config.reuse_tmp_files)
    cparam.config.reuse_tmp_files = true;
  end
  % .config.skip_files_end: Scaler integer. Default is 0. Number of files
  % to ignore at the end of the segment
  if ~isfield(cparam.config,'skip_files_end') || isempty(cparam.config.skip_files_end)
    cparam.config.skip_files_end = 0;
  end
  % .config.skip_files_start: Scaler integer. Default is 0. Number of files
  % to ignore at the beginning of the segment.
  if ~isfield(cparam.config,'skip_files_start') || isempty(cparam.config.skip_files_start)
    cparam.config.skip_files_start = 0;
  end
  % .config.tmp_load_mode: Scaler logical. Default is false. If true, then
  % preprocess runs just for quick temporary loading of files.
  if ~isfield(cparam.config,'tmp_load_mode') || isempty(cparam.config.tmp_load_mode)
    cparam.config.tmp_load_mode = false;
  end

  %% Setup preprocess task
  
  dparam = [];
  dparam.argsin{1} = cparam;
  
  num_fns = 0;
  for board_idx = 1:length(cparam.records.file.boards)
    board = cparam.records.file.boards{board_idx};
    board_folder_name = cparam.config.board_folder_names;
    board_folder_name = regexprep(board_folder_name,'%b',board);

    get_filenames_param = struct('regexp',cparam.config.file.regexp);
    fns = get_filenames(fullfile(cparam.config.base_dir,board_folder_name), ...
      cparam.config.file.prefix, cparam.config.file.midfix, ...
      cparam.config.file.suffix, get_filenames_param);
    num_fns = num_fns + length(fns);
  end

  dparam.cpu_time = 60 + cparam.config.cpu_time_per_file*num_fns;
  dparam.mem = 4e9;
  dparam.notes = sprintf('%s:%s:%s %d files', ...
    mfilename, cparam.config.base_dir, cparam.config.config_folder_names, num_fns);
  ctrl = cluster_new_task(ctrl,sparam,dparam);
end

ctrl_chain = {{ctrl}};

fprintf('%s: Done %s\n', mfilename, datestr(now));
