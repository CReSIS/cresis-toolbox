function fn = ct_filename_tmp(param,fn,type,filename)
% fn = ct_filename_tmp(param,fn,type,filename)
%
% Returns a standardized filename for temporary files.
% 1. Handles absolute and relative path conversions, default paths, and
%    file separator differences (e.g. windows uses '\' and unix uses '/')
% 2. There are three modes of operation:
%  - base_fn is an absolute path: the param.tmp_path and standardized
%    path are not used (base_fn replaces both)
%  - base_fn is a relative path: the param.tmp_path is used, but the
%    standardized path/directory structure is not used (base_fn is used)
%  - base_fn is empty: the param.tmp_path and standardized path are used
%
% param = control structure to data processor
%  .radar_name (e.g. mcords)
%  .season_name (e.g. 2009_antarctica_DC8)
%  .day_seg (e.g. 20091020_03)
% fn = parameter filename provided
% type = type of data (e.g. records, picker)
%
% Examples:
% ct_filename_tmp(param,'','records','workspace');
%   TMP/records/2010_Antarctica_DC8/workspace_20101026_01
% ct_filename_tmp(param,'','records',sprintf('log_adc%d',adc));
%   TMP/records/2010_Antarctica_DC8/log_adc1_20101026_01
% ct_filename_tmp(tmp_file_param,'','picker','picker_fast_load');
%   TMP/picker/2010_Antarctica_DC8/picker_fast_load
%
% Author: John Paden
%
% See also: ct_filename_data, ct_filename_out, ct_filename_support,
%  ct_filename_tmp, ct_filename_gis

global gRadar;
param = merge_structs(gRadar,param);
if ~isfield(param,'tmp_path')
  param.tmp_path = '';
end

if ~isfield(param,'radar_name')
  output_dir = '';
else
  [output_dir,radar_type] = ct_output_dir(param.radar_name);
end

if isempty(fn)
  if ~isfield(param,'day_seg') || isempty(param.day_seg)
    fn = fullfile(param.tmp_path, type, output_dir, ...
      param.season_name, filename);
  else
    % Generate the default filename
    [tmp name ext] = fileparts(filename);
    if isempty(name) && isempty(ext)
      fn = fullfile(param.tmp_path, type, output_dir, ...
        param.season_name, param.day_seg);
    else
      fn = fullfile(param.tmp_path, type, output_dir, ...
        param.season_name, sprintf('%s_%s%s', name, param.day_seg, ext));
    end
  end
elseif fn(1) == filesep || (ispc && (~isempty(strfind(fn,':\')) || ~isempty(strfind(fn,':/'))))
  % This is already an absolute path
  return
else
  % Append the current path to the support path
  fn = fullfile(param.tmp_path, fn);
end

fn(fn == '/' | fn == '\') = filesep;

return;
