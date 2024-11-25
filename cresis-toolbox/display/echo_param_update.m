function mdata = echo_param_update(mdata,param_override)
% mdata = echo_param_update(mdata,param_override)
%
% Function to update the paths of each parameter structure in an echogram
% structure. Relies on ct_param_path_update.
%
% Inputs:
%
% mdata: echogram structure
%
% param_override: override parameters. If set to [] or not defined, then
% the global variable gRadar will be used.
%
% Outputs:
%
% param: updated echogram structure
%
% Example:
%
% echo_fn = '/N/dcwan/projects/cresis/output/rds/2018_Greenland_P3/CSARP_qlook/20180406_01/Data_20180406_01_001.mat';
% mdata = load_L1B(echo_fn);
% mdata = echo_param_update(mdata);
%
% Author: John Paden

if ~exist('param_override','var') || ~isstruct(param_override)
  global gRadar;
  param_override = gRadar;
end

field_names = fieldnames(mdata);
for idx=1:length(field_names)
  if strncmp(field_names{idx},'param',5)
    mdata.(field_names{idx}) = ct_param_path_update(mdata.(field_names{idx}),param_override);
  end
end
