function param = echo_param(mdata,mode)
% param = echo_param(mdata,mode)
%
% Returns the processing parameters structure used to create the data
% mdata. mdata is loaded from qlook.m or array.m echogram outputs. gRadar
% is merged with this structure to ensure paths are updated to the current
% environment.
%
% mdata: structure loaded from echogram file (e.g. CSARP_qlook or
% CSARP_standard) or a filename string that can be loaded to obtain the
% structure.
%
% mode: scalar numeric, default is zero. mode 0 returns parameter
% structure, mode 1 returns the string
%
% OUTPUTS:
%
% param: mode 0 returns parameter spreadsheet structure that was used to
% create echo_param, mode 1 returns the string containing the fieldname to
% this param structure
%
% fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_standard/20140512_01/Data_20140512_01_018.mat';
% mdata = load(fn);
% param = echo_param(mdata);
%
% Author: John Paden
%
% See also: echo_detrend, echo_filt, echo_mult_suppress, echo_noise,
% echo_norm, echo_param, echo_stats, echo_stats_layer, echo_xcorr,
% echo_xcorr_profile

if ~exist('mode','var') || isempty(mode)
  mode = 0;
end

if ischar(mdata)
  % Assume mdata contains a filename string and load it
  mdata = load(mdata);
end

if mode == 0
  if isfield(mdata,'param')
    param = mdata.param;
  elseif isfield(mdata,'param_array')
    param = mdata.param_array;
  elseif isfield(mdata,'param_qlook')
    param = mdata.param_qlook;
  elseif isfield(mdata,'param_combine')
    param = mdata.param_combine;
  elseif isfield(mdata,'param_combine_wf_chan')
    param = mdata.param_csarp;
  elseif isfield(mdata,'param_get_heights')
    param = mdata.param_get_heights;
  else
    error('There is no param_array, param_qlook, param_combine, param_combine_wf_chan, or param_get_heights field in mdata.');
  end
  param = ct_param_path_update(param);

else
  if isfield(mdata,'param')
    param = 'param';
  elseif isfield(mdata,'param_array')
    param = 'param_array';
  elseif isfield(mdata,'param_qlook')
    param = 'param_qlook';
  elseif isfield(mdata,'param_combine')
    param = 'param_combine';
  elseif isfield(mdata,'param_combine_wf_chan')
    param = 'param_combine_wf_chan';
  elseif isfield(mdata,'param_get_heights')
    param = 'param_get_heights';
  else
    error('There is no param_array, param_qlook, param_combine, param_combine_wf_chan, or param_get_heights field in mdata.');
  end
  return
end

% Merge the gRadar structure into the param structure so that the file
% paths match the current environment rather than the file paths from when
% it was processed.
global gRadar;
param = merge_structs(param,gRadar);
