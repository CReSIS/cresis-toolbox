function ct_save(varargin)
% ct_save(varargin)
%
% Use ct_save instead of save for all toolbox commands.
% 1. Uses gRadar.mat_file_version for the file version
% 2. Checks to ensure that gRadar.min_disk_space remains on disk
% 3. Ensures that the output directory exists
%
% Author: John Paden

% Input checks
global gRadar;
if ~isfield(gRadar,'min_disk_space') || isempty(gRadar.min_disk_space)
  min_disk_space = 10e9;
else
  min_disk_space = gRadar.min_disk_space;
end
if ~isfield(gRadar,'mat_file_version') || isempty(gRadar.mat_file_version)
  mat_file_version = '-v7.3';
else
  mat_file_version = gRadar.mat_file_version;
end

% Find first regular string and assume this is the filename
fn = '';
for idx = 1:length(varargin)
  arg = varargin{idx};
  if ~isempty(arg) && arg(1) ~= '-'
    fn = arg;
    varargin = varargin([1:idx-1 idx+1:end]);
    break;
  end
end

% Get the free space where the file is going to be stored
free = get_disk_space(fn);

% Assume free == 0 is an error in get_disk_space and so ignore it because
% the save will fail anyway if this is the case.
if free > 0 && free < min_disk_space
  error('Insufficient disk space (%g MB free, minimum allowed % MB).', free/1e6, min_disk_space/1e6);
end

% Check that output directory exists
fn_dir = fileparts(fn);
if ~isempty(fn_dir) && ~exist(fn_dir,'dir')
  mkdir(fn_dir);
end

% Run the save command
if ~isempty(varargin)
  append_field_mask = ~strcmp('-append',varargin);
  if exist(fn,'file')
    if any(append_field_mask)
      % If file exists then we cannot set the file version if we are
      % appending
      cmd = sprintf('save(''%s''%s)',fn,sprintf(',''%s''',varargin{:}));
    else
    cmd = sprintf('save(''%s''%s,''%s'')',fn,sprintf(',''%s''',varargin{:}),mat_file_version);
    end
  else
    % If the file does not exist, then we cannot append.
    varargin = varargin(append_field_mask);
    cmd = sprintf('save(''%s''%s,''%s'')',fn,sprintf(',''%s''',varargin{:}),mat_file_version);
  end
else
  cmd = sprintf('save(''%s'',''%s'')',fn,mat_file_version);
end
evalin('caller',cmd);
