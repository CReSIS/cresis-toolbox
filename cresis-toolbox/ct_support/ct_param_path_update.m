function param = ct_param_path_update(param,param_override)
% param = ct_param_path_update(param,param_override)
%
% Function to update the paths of a parameter structure with another
% parameter structure. This is useful when a parameter structure is read in
% from a file that was processed on a different system and therefore may
% have paths that do no work with the current system, but we want to use
% the parameter structure. This function allows the paths to be easily
% updated with the current systems paths.
%
% Inputs:
%
% param: parameter spreadsheet structure
%
% param_override: override parameters. If set to [] or not defined, then
% the global variable gRadar will be used.
%
% Outputs:
%
% param: updated parameter spreadsheet structure
%
% Example:
%
% echo_fn = '/N/dcwan/projects/cresis/output/rds/2018_Greenland_P3/CSARP_qlook/20180406_01/Data_20180406_01_001.mat';
% mdata = load_L1B(echo_fn);
% param = ct_param_path_update(mdata.param_qlook);
%
% Author: John Paden

if ~exist('param_override','var') || ~isstruct(param_override)
  global gRadar;
  param_override = gRadar;
end

field_names = {'cluster','path','path_override','param_path','tmp_path', ...
  'ct_tmp_path','data_path','data_support_path','support_path','out_path', ...
  'gis_path','ct_file_lock_check','ct_file_lock','slurm_jobs_path','ops'};

for idx = 1:length(field_names)
  if isfield(param_override,field_names{idx})
    param.(field_names{idx}) = param_override.(field_names{idx});
  end
end
