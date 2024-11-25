function [fns,status] = get_filenames(filepath,fn_prefix,fn_midfix,fn_suffix,param)
% [fns,status] = get_filenames(filepath,fn_prefix,fn_midfix,fn_suffix,param)
%
% Gets a list of filenames that match the pattern specified by the input
% arguments. Supports regular expression, file/directory, and recursive
% file searches.
%
% Inputs:
%
% filepath: string containing path to search
%
% fn_prefix: beginning of filename must match this string
%
% fn_midfix: middle of filename must match this string
%
% fn_suffix: end of filename must match this string
%
% param: optional structure containing one or more of these fields:
%
%  .recursive: Logical scalar. Default is false. If true, causes the search
%  to recurse into subfolders.
%
%  .type: String containing either 'f' or 'd'. Default is 'f'. Files
%  matched according to f=file, d=directory.
%
%  .exact: Logical scalar. Default is false. If true, requires that the
%  string exactly match with no characters in between the prefix, midfix,
%  and suffix.
%
%  .regexp: Regular expression string. Default is empty. Field ignored if
%  empty.
%
% Output:
%    Returns a column cell vector of filenames that correspond to paths of
%    filenames that meet the pattern specified in the arguements
%
% Example:
%    fns = get_filenames('\\emperor\d5\wblake','InSAR','','wf_01_tx_01_rx_01.mat');
%    fns = get_filenames('/d5/wblake','InSAR','','wf_01_tx_01_rx_01.mat');
%
%    Get all files (including in subdirectories):
%    fns = get_filenames('/d5/wblake','','','',struct('recursive',true));
%
% Author: William Blake, John Paden

if nargin < 4 || nargin > 5
  error('Args:IncorrectFormat','Must have 4 or 5 arguments');
elseif nargin == 4
  param.recursive = 0;
  param.type = 'f';
  param.exact = 0;
  param.regexp = [];
else
  if ~ischar(param) && ~isstruct(param) && ~isempty(param)
    error('Args:IncorrectFormat','Fifth argument must be a string or struct');
  end
  if ischar(param)
    if strcmpi(param,'recursive')
      param = struct('recursive',1);
      param.type = 'f';
      param.exact = 0;
      param.regexp = [];
    else
      param.recursive = 0;
      param.type = 'f';
      param.exact = 0;
      param.regexp = [];
    end
  else
    if ~isfield(param,'recursive')
      param.recursive = 0;
    end
    if ~isfield(param,'type')
      param.type = 'f';
    end
    if ~isfield(param,'exact')
      param.exact = 0;
    end
    if ~isfield(param,'regexp')
      param.regexp = [];
    end
  end
end
if ~ischar(filepath) || ~ischar(fn_prefix) || ~ischar(fn_midfix) || ...
    ~ischar(fn_suffix)
  error('Args:IncorrectFormat','First four arguments must be strings');
end

if param.exact
  filename_exp = sprintf('%s%s%s', fn_prefix, fn_midfix, ...
    fn_suffix);
else
  filename_exp = sprintf('%s*%s*%s', fn_prefix, fn_midfix, ...
    fn_suffix);
end

if ispc
  % Remove double slash for paths beginning with letters
  if ~isempty(filepath) && filepath(1) ~= '/'&& filepath(1) ~= '\'
    colon_idx = regexp(filepath,':[/\\]+');
    if ~isempty(colon_idx)
      end_idx = find(filepath(colon_idx(1)+1:end)~= '/'& filepath(colon_idx(1)+1:end)~= '\',1);
      if ~isempty(end_idx) && end_idx > 2
        filepath = [filepath(1:colon_idx) filepath(colon_idx+end_idx-1:end)];
      end
    end
  end
  % Create system command to get filenames
  file_match_str = fullfile(filepath, filename_exp);
  if param.recursive
    if param.type == 'f'
      sysCmd = sprintf('dir /a:-d /B /ON /s "%s"', ...
        file_match_str);
    else
      sysCmd = sprintf('dir /a:d /B /ON /s "%s"', ...
        file_match_str);
    end
  else
    if param.type == 'f'
      sysCmd = sprintf('dir /a:-d /B /ON "%s"', ...
        file_match_str);
    else
      sysCmd = sprintf('dir /a:d /B /ON "%s"', ...
        file_match_str);
    end
  end
  % Execute system command to get filenames
  [status,tmp_filenames] = system(sysCmd);
  fns = {};
  % Parse returned filenames
  if isempty(tmp_filenames) || status ~= 0
    return;
  end
  files = textscan(tmp_filenames,'%s','Delimiter','\n');
  files = files{1};
  for idx = 1:size(files,1)
    if ~param.recursive
      fns{end+1,1} = fullfile(filepath,files{idx});
    else
      fns{end+1,1} = files{idx};
    end
  end
else
  % Add trailing slash (required for symbolic links to work)
  if length(filepath)>1 && filepath(end) ~= '/'
    filepath = [filepath '/'];
  end
  % Create system command to get filenames
  if param.recursive
    sysCmd = sprintf('find "%s" \\( ! -regex ''.*/\\..*'' \\) -type %s -name ''%s'' </dev/null', ...
      filepath, param.type,filename_exp);
  else
    sysCmd = sprintf('find "%s" -maxdepth 1 \\( ! -regex ''.*/\\..*'' \\) -type %s -name ''%s'' </dev/null', ...
      filepath, param.type,filename_exp);
  end
  % Execute system command to get filenames
  [status,tmp_filenames] = system(sysCmd);
  
  fns = {};
  % Parse returned filenames
  if isempty(tmp_filenames) || status ~= 0
    return;
  end
  files = textscan(tmp_filenames,'%s','Delimiter','\n');
  files = sort(files{1});
  for idx = 1:size(files,1)
    fns{end+1,1} = files{idx};
  end
  fns = sort(fns);
end

if ~isempty(param.regexp)
  good_mask = logical(ones(size(fns)));
  for idx = 1:length(fns)
    good_mask(idx) = ~isempty(regexp(files{idx},param.regexp));
  end
  fns = fns(good_mask);
end
