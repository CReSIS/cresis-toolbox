function [base_dir,board_folder_name,fns,file_idxs] = get_segment_file_list(param,board_idx)
% [base_dir,board_folder_name,fns,file_idxs] = get_segment_file_list(param,board_idx)
%
% Support function for records_create.m.
% Can also be used to get all the file information for every segment
% using run_get_segment_file_list.m.
%
% param: struct from param spreadsheet read in by read_param_xls
%
%  .records
%
%   .file
%
%    .base_dir: base directory
%
%    .board_folder_name: board folder name (%b in the filename will be
%    replaced by the corresponding string for the current board from the
%    cell array of strings param.records.file.boards)
%
%    .boards: cell array of strings containing the board folder names (e.g.
%    {'board0','board1',...} or {'chan1','chan2',...})
%
%    .midfix: string containing middle filename search term. Default is
%    empty string.
%
%    .prefix: string containing beginning filename search term. Default is
%    empty string.
%
%    .regexp: optional regular expression string that runs after the
%    initial file search if not empty. Default is empty string.
%
%    .suffix: string containing end filename search term. Default is empty
%    string.
%
%    .version: integer scaler containing the raw file version (see "raw
%    file guide" on wiki)
%
% board: optional parameter used with some radars that have multiple adcs
%
% Author: John Paden
%
% See also: get_frame_id, get_raw_files.m, get_segment_file_list.m,
%   run_get_segment_file_list.m

if ~isfield(param.records.file,'prefix') || isempty(param.records.file.prefix)
  param.records.file.prefix = '';
end

if ~isfield(param.records.file,'midfix') || isempty(param.records.file.midfix)
  param.records.file.midfix = '';
end

if ~isfield(param.records.file,'suffix') || isempty(param.records.file.suffix)
  param.records.file.suffix = '';
end

if ~isfield(param.records.file,'boards') || isempty(param.records.file.boards)
  param.records.file.boards = {''};
end

% Determine default regular expression to apply to file search
if ~isfield(param.records.file,'regexp') || isempty(param.records.file.regexp)
  if any(param.records.file.version == [405 406])
    param.records.file.regexp = '\.[0-9]*$';
  elseif any(param.records.file.version == [409])
    param.records.file.regexp = '\.[0-9][0-9][0-9]$';
  else
    param.records.file.regexp = '';
  end
end

% Determine raw filename extension and check file version
if any(param.records.file.version == [1 9:10 101 103 401 412 415 420])
  ext = '.dat';
elseif any(param.records.file.version == [2:8 11 102 402:408 411])
  ext = '.bin';
elseif any(param.records.file.version == [410])
  ext = '.raw';
elseif any(param.records.file.version == [405 406 409])
  ext = '';
elseif any(param.records.file.version == [413 414])
  ext = '.mat';
else 
  error('Unsupported file version\n');
end

board_folder_name = param.records.file.board_folder_name;
board_folder_name = regexprep(board_folder_name,'%b',param.records.file.boards{board_idx});

base_dir = fullfile(ct_filename_data(param,param.records.file.base_dir),board_folder_name);

%% Return file list
if nargout > 2
  if 0
    fprintf('Getting files for %s (%s)\n', base_dir, datestr(now));
  end
  
  if any(param.records.file.version == [414])
    board = param.records.file.boards{board_idx};
    board_folder_name = param.records.file.board_folder_name;
    board_folder_name = regexprep(board_folder_name,'%b',board);
    get_filenames_param = struct('regexp',param.records.file.regexp,'recursive',true);
    fns_all = get_filenames(fullfile(param.records.file.base_dir,board_folder_name), ...
      param.records.file.prefix, param.records.file.midfix, ...
      param.records.file.suffix, get_filenames_param);
    datenum_list = [];
    fns = {};
    for fn_idx = 1:length(fns_all)
      fn = fns_all{fn_idx};
      fname = fname_info_bas(fn);
      if ~any(datenum_list == fname.datenum)
        % File time stamp not added to list yet, so add it
        datenum_list(end+1) = fname.datenum;
        fns{end+1} = sprintf('%sPort_%s_Tx%s_Rx%s_%s%02.0fL%.0f_T01_%04.0f.mat', ...
          fname.name, datestr(fname.datenum,'YYYYmmDDHHMMSS'), 'P1234', 'P1', 'C', ...
          0, 0, fname.file_idx);
      end
    end
    [datenum_list,sort_idxs] = sort(datenum_list);
    fns = fns(sort_idxs);
    
  else
    get_fns_param = struct('regexp',param.records.file.regexp);
    if ~isfield(param.records.file,'file_suffix')
      fns = get_filenames(base_dir,param.records.file.prefix,param.records.file.midfix,ext,get_fns_param);
    else
      fns = get_filenames(base_dir,param.records.file.prefix,param.records.file.midfix,param.records.file.suffix,get_fns_param);
    end
    
    % Sort ACORDS filenames because the extenions are not a standard length
    if any(param.records.file.version == [405 406])
      basenames = {};
      file_idxs = [];
      new_fns = {};
      for fidx = 1:length(fns)
        fname = fname_info_acords(fns{fidx},struct('hnum',1,'file_version',param.records.file.version));
        new_fns{fidx} = [fname.basename sprintf('.%03d',fname.file_idx)];
      end
      [new_fns,sorted_idxs] = sort(new_fns);
      fns = fns(sorted_idxs);
    end
  end

  if 0
    fprintf('  Found %d files in %s\n', length(fns), base_dir);
  end
  
  if isempty(fns)
    fprintf('No files match the mask:\n');
    fprintf('  path: %s\n', base_dir);
    fprintf('  mask: %s*%s\n', param.records.file.prefix, ext);
    error('No files found');
  end
  
  if param.records.file.stop_idx == inf
    % A stop index of infinity says to include all files
    stop_idx = length(fns);
  elseif param.records.file.stop_idx > length(fns)
    warning('Stop index (%d) is larger than number of files available (%d). This can be caused by an error in the stop index or missing files. dbcont to continue.',param.records.file.stop_idx,length(fns));
    keyboard
    stop_idx = length(fns);
  elseif param.records.file.stop_idx < 0;
    % A stop index of -N says to include all but the last N files
    stop_idx = length(fns) + param.records.file.stop_idx;
  else
    if board_idx > 1 && length(param.records.file.stop_idx) == 1
      % Old parameter spreadsheet format only contained a single entry for
      % all boards in param.records.file.stop_idx
      stop_idx = param.records.file.stop_idx;
    else
      stop_idx = param.records.file.stop_idx(board_idx);
    end
  end
  if board_idx > 1 && length(param.records.file.start_idx) == 1
    % Old parameter spreadsheet format only contained a single entry for
    % all boards in param.records.file.start_idx
    file_idxs = param.records.file.start_idx:stop_idx;
  else
    file_idxs = param.records.file.start_idx(board_idx):stop_idx;
  end
  
  if isempty(file_idxs)
    error('No files selected to load out of %i files', length(fns));
  end
end

return;
