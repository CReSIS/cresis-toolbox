function fn = ct_filename_out(param,fn,tmp_dir,generic_data_flag)
% fn = ct_filename_out(param,fn,tmp_dir,generic_data_flag)
%
% Returns a standardized filename for output files.
% 1. Handles absolute and relative path conversions, default paths, and
%    file separator differences (e.g. windows uses '\' and unix uses '/')
% 2. There are three modes of operation:
%  - base_fn is an absolute path: the param.out_path and standardized
%    path are not used (base_fn replaces both)
%  - base_fn is a relative path: the param.out_path is used, but the
%    standardized path/directory structure is not used (base_fn is used)
%  - base_fn is empty: the param.out_path and standardized path are used
%
% param: control structure to data processor
%  .radar_name (e.g. mcords)
%  .season_name (e.g. 2009_antarctica_DC8)
%  .day_seg (e.g. 20091020_03)
% fn: parameter filename provided (e.g. "qlook" or "standard"). Unless fn
%   is empty or an absolute path, "CSARP_" is always prepended to the
%   beginning of the last folder in fn.
% tmp_dir: normally empty, used to create a path to a temporary directory
%   for the actual outputs (string is usually of the form "qlook_tmp" or
%   "standard_tmp"). "CSARP_" is always prepended to the beginning of this
%   string if it is not empty. If empty or undefined, then this input has
%   no effect.
% generic_data_flag: if enabled, the segment ID is excluded from the path
%
% ct_filename_out(param,'qlook')
% ct_filename_out(param,'standard')
%
% Author: John Paden
%
% See also: ct_filename_data, ct_filename_out, ct_filename_support,
%  ct_filename_tmp, ct_filename_gis

global gRadar;
param = merge_structs(gRadar,param);

if ~exist('tmp_dir','var') || isempty(tmp_dir)
  tmp_dir = '';
else
  tmp_dir = ['CSARP_' tmp_dir];
end

if ~exist('generic_data_flag','var') || isempty(generic_data_flag)
  generic_data_flag = 0;
end

[output_dir,radar_type] = ct_output_dir(param.radar_name);

if isempty(fn)
  % Generate the default path
  if generic_data_flag
    fn = fullfile(param.out_path, output_dir, param.season_name, tmp_dir);
  else
    fn = fullfile(param.out_path, output_dir, param.season_name, tmp_dir, param.day_seg);
  end
elseif fn(1) == filesep || (ispc && (~isempty(strfind(fn,':\')) || ~isempty(strfind(fn,':/'))))
  % This is already an absolute path
  if generic_data_flag
    fn = fullfile(fn, tmp_dir);
  else
    fn = fullfile(fn, tmp_dir, param.day_seg);
  end
else
  [fn_dir fn_name] = fileparts(fn);
  fn_name = sprintf('CSARP_%s', fn_name);
  fn = fullfile(fn_dir,fn_name);
  % Generate the default path with the modified name
  if generic_data_flag
    fn = fullfile(param.out_path, output_dir, param.season_name, tmp_dir, fn);
  else
    fn = fullfile(param.out_path, output_dir, param.season_name, tmp_dir, fn, ...
      param.day_seg);
  end
end

fn(fn == '/' | fn == '\') = filesep;
