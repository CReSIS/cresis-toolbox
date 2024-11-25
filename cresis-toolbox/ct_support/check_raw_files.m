function check_raw_files(param,param_override)
% check_raw_files(param,param_override)
%
% Function for checking for the existence of all raw files. Looks for raw
% files based on records parameter sheet. If records file is available,
% then it does a more thorough check.
%
% Inputs:
% param = struct with processing parameters
%         -- OR --
%         function handle to script with processing parameters
% param_override = parameters in this struct will override parameters
%         in param.  This struct must also contain the gRadar fields.
%         Typically global gRadar; param_override = gRadar;
%
% Authors: John Paden
%
% See also: run_master.m, master.m

%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

command_window_out_fn = ct_filename_ct_tmp(param,'','check_raw_files', ['console.txt']);
command_window_out_fn_dir = fileparts(command_window_out_fn);
if ~exist(command_window_out_fn_dir,'dir')
  mkdir(command_window_out_fn_dir);
end
if exist(command_window_out_fn,'file')
  delete(command_window_out_fn);
end
diary(command_window_out_fn);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input Checks
% =====================================================================

[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);

% boards: List of subdirectories containing the files for each board (a
% board is a data stream stored to disk and often contains the data stream
% from multiple ADCs)
if any(param.records.file.version == [1:5 8 11 101:102 405:406 409:411 413 414])
  if ~isfield(param.records.file,'boards') || isempty(param.records.file.boards)
    % Assume a single channel system
    param.records.file.boards = {''};
  end
elseif any(param.records.file.version == [6:7 9:10 103 401:404 407:408 412])
  if ~isfield(param.records.file,'boards') || isempty(param.records.file.boards)
    error('param.records.file.boards should be specified.');
  end
else
  error('Unsupported file version\n');
end
boards = param.records.file.boards;

if ~isfield(param.records,'file') || isempty(param.records.file)
  param.records.file = [];
end
if ~isfield(param.records.file,'version') || isempty(param.records.file.version)
  error('The param.records.file.version field must be specified.');
end

records_fn = ct_filename_support(param,'','records');
if exist(records_fn,'file')
  records = records_load(param);
else
  records = [];
end


%% Check files from each board
% =====================================================================
for board_idx = 1:length(boards)
  board = boards{board_idx};
  
  fprintf('Getting files for board %s (%d of %d)\n', ...
    board, board_idx, length(boards));
  
  %% Check files: get files
  % =====================================================================
  % Matlab will enter debug mode if file count is not large enough to match
  % param.records.
  [base_dir,adc_folder_name,board_fns{board_idx},file_idxs] = get_segment_file_list(param,board_idx);
  
  %% Check files: records file
  % =====================================================================
  if isempty(records)
    fprintf('No records file so can only check file count:\n  %s\n', records_fn);
  else
    % Check each raw file
    fprintf('Records file exists, checking raw files %i to %i:\n  %s\n',file_idxs([1 end]), records_fn);
    
    for file_idx = 1:length(records.relative_filename{board_idx})
      
      fn_name = records.relative_filename{board_idx}{file_idx};
      [fn_dir] = get_segment_file_list(param,board_idx);
      fn = fullfile(fn_dir,fn_name);
      
      if ~exist(fn,'file')
        fprintf('  %i/%i %s (%s) DOES NOT EXIST!!!\n', ...
          file_idx,length(file_idxs), fn, datestr(now,'HH:MM:SS'));
      end
    end
  end
  
end

diary off;
fprintf('Console output: %s\n', command_window_out_fn);

