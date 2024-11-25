function get_raw_files_tape(load_info,retrieve_mode,varargin)
% get_raw_files_tape(load_info,retrieve_mode,varargin)
%
% load_info: result from get_raw_files.m
%
% retrieve_mode: string containing the mode which can be:
% * 'list' (default): lists the files to be copied and pasted
% * 'read': retrieves the files by reading the first byte of each file
% * 'copy': copies the files to a new location, this requires passing
% base_dir and new_base_dir strings as name value pairs (see example)
%
% % Get the file information
% [load_info,gps_time,recs] = get_raw_files(ct_filename_param('rds_param_2014_Greenland_P3.xls'),{'20140410_01_057','20140410_01_058'},{[1 1;1 5;1 9; 1 13]});
%
% % List files
% get_raw_files_tape(load_info,'list');
%
% % Tape or disk
% get_raw_files_tape(load_info,'tape_or_disk');
%
% % Forces files to be retrieved by reading the first byte from each file
% get_raw_files_tape(load_info,'read');
%
% % Copies files
% get_raw_files_tape(load_info,'copy','base_dir','/cresis/snfs1/data/MCoRDS/','new_base_dir','/tmp/')
% % Copies files output:
% /cresis/snfs1/data/MCoRDS/2014_Greenland_P3/20140410/board0/mcords3_0_20140410_105853_00_0002.bin
%   /tmp/2014_Greenland_P3/20140410/board0/mcords3_0_20140410_105853_00_0002.bin (02-Feb-2021 15:05:01)
% 
% Authors: John Paden

if ~exist('retrieve_mode','var') || isempty(retrieve_mode)
  retrieve_mode = 'list';
end

for name_val_idx = 1:2:nargin-2
  param.(varargin{name_val_idx}) = varargin{name_val_idx+1};
end

if ~isempty(regexpi(retrieve_mode,'list'))
  fprintf('%s\n', repmat('=',[1 80]));
  fprintf('Raw files to be retrieved from tape\n');
  fprintf('%s\n', repmat('=',[1 80]));
  for board_idx = 1:length(load_info.filenames)
    for fn_idx = 1:length(load_info.filenames{board_idx})
      fn = load_info.filenames{board_idx}{fn_idx};
      fprintf('%s\n', fn);
    end
  end
end

if ~isempty(regexpi(retrieve_mode,'tape_or_disk'))
  fprintf('%s\n', repmat('=',[1 80]));
  fprintf('Raw files to be retrieved from tape\n');
  fprintf('%s\n', repmat('=',[1 80]));
  for board_idx = 1:length(load_info.filenames)
    for fn_idx = 1:length(load_info.filenames{board_idx})
      fn = load_info.filenames{board_idx}{fn_idx};
      cmd = sprintf('du -sk %s | awk ''{print $1}''',fn);
      cmd2 = sprintf('du -sk --apparent-size %s | awk ''{print $1}''',fn);
      [status,result] = system(cmd);
      [status2,result2] = system(cmd2);
      if status == 0 && status2 == 0
        size_kb = str2double(result);
        size_kb2 = str2double(result2);
        if 10*size_kb < size_kb2
          fprintf('%s\tTAPE\n', fn);
        else
          fprintf('%s\tDISK\n', fn);
        end
      else
        fprintf('%s: COMMAND FAILED, NO ANSWER\n', fn);
      end
    end
  end
end

if ~isempty(regexpi(retrieve_mode,'read'))
  fprintf('%s\n', repmat('=',[1 80]));
  fprintf('Retrieving (reads first byte from each file)\n');
  fprintf('%s\n', repmat('=',[1 80]));
  for board_idx = 1:length(load_info.filenames)
    for fn_idx = 1:length(load_info.filenames{board_idx})
      fn = load_info.filenames{board_idx}{fn_idx};
      fprintf('%s (%s)\n', fn, datestr(now));
      fid = fopen(fn,'r');
      fread(fid,1);
      fclose(fid);
    end
  end
end

if ~isempty(regexpi(retrieve_mode,'copy'))
  % Requires base_dir and new_base_dir to be assigned in name-value pair
  % varargin
  fprintf('%s\n', repmat('=',[1 80]));
  fprintf('Copying\n');
  fprintf('%s\n', repmat('=',[1 80]));
  for board_idx = 1:length(load_info.filenames)
    for fn_idx = 1:length(load_info.filenames{board_idx})
      fn = load_info.filenames{board_idx}{fn_idx};
      new_fn = fullfile(param.new_base_dir,fn(1+length(param.base_dir):end));
      fprintf('%s\n  %s (%s)\n', fn, new_fn, datestr(now));
      %copyfile(fn,new_fn);
    end
  end
end
