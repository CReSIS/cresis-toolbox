function [params] = read_param_xls(param_fn, day_seg_filter, generic_ws)
% [params] = read_param_xls(param_fn, day_seg_filter, generic_ws)
%
% Reads params structure array in from .xls file.
%
% This params structure array is used by master/master_accum to control the
% data process.
%
% param_fn = filename to MS Excel params spreadsheet
% day_seg_filter = regular expression string, only the matching day-segment
%   parameters will be returned
% generic_ws = cell array of strings, loads generic worksheets specified in
%   the cell array in addition to the standard worksheets (e.g. analysis,
%   update_data_files). Legacy support allows generic_ws to be a string
%   and this function will detect this and place it into a cell array.
%
% Example:
%   param_fn = '/mnt/scratch2/csarp_support/documents/mcords_param_2011_Greenland_P3.xls';
%   [params] = read_param_xls(param_fn);
%
%   param_fn = '/mnt/scratch2/csarp_support/documents/mcords_param_2011_Greenland_P3.xls';
%   [params] = read_param_xls(param_fn,'20110329_02');
%
%   param_fn = ct_filename_param('rds_param_2011_Greenland_P3.xls');
%   [params] = read_param_xls(param_fn);
%
% Author: Brady Maasen, John Paden
%
% See also: ct_set_params, master, read_param_xls
%
% See also for spreadsheet cell loading:
%  read_param_xls_boolean.m, read_param_xls_general.m,
%  read_param_xls_text.m
%  
% See also for worksheet loading:
%  read_param_xls_generic.m, read_param_xls_radar.m: 
%
% See also for printing out spreadsheet to stdout:
%  read_param_xls_print, read_param_xls_print_headers.m

if isstruct(param_fn)
  day_seg_filter = param_fn.day_seg;
  param_fn = ct_filename_param(sprintf('%s_param_%s.xls', ct_output_dir(param_fn.radar_name), param_fn.season_name));
end
  
%% Load standard worksheets
warning('off','MATLAB:xlsread:Mode');
[params] = read_param_xls_radar(param_fn);

if isempty(params) || isempty(params(1).day_seg)
  warning('Parameter spreadsheet file is empty');
end

%% Load the generic worksheets if specified
if exist('generic_ws','var') && ~isempty(generic_ws)
  params = read_param_xls_generic(param_fn, generic_ws, params);
end
warning('on','MATLAB:xlsread:Mode');

%% Just get the specific day_seg that was requested
if exist('day_seg_filter','var') && ~isempty(day_seg_filter)
  good_mask = logical(zeros(size(params)));
  for idx = 1:length(params)
    if ~isempty(regexp(params(idx).day_seg, day_seg_filter))
      good_mask(idx) = 1;
    end
  end
  params = params(good_mask);
  if isempty(params)
    warning('No segment day_seg matched regexp %s .', day_seg_filter);
  end
end

return

