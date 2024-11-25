% script run_records_reference_trajectory
%
% Script for running records_reference_trajectory
%
% Authors: John Paden
%
% See also: records_reference_trajectory.m,
% records_reference_trajectory_load.m, run_records_reference_trajectory.m,
% run_all_records_reference_trajectory.m

%% User Setup
% =====================================================================
param_override = [];

params = read_param_xls(ct_filename_param('rds_param_2018_Greenland_P3.xls'));

if 1
  % Example to run a specific segment and frame by overriding parameter spreadsheet values
  params = ct_set_params(params,'cmd.generic',0);
  params = ct_set_params(params,'cmd.generic',1,'day_seg','20180419_01');
  
elseif 0
  % Example to run all segments
  params = ct_set_params(params,'cmd.generic',1);
  params = ct_set_params(params,'cmd.generic',0,'cmd.notes','do not process');
end

dbstop if error;

%% Automated Section
% =====================================================================

% Input checking
global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

% Process each of the segments
for param_idx = 1:length(params)
  param = params(param_idx);
  if isfield(param.cmd,'generic') && ~iscell(param.cmd.generic) && ~ischar(param.cmd.generic) && param.cmd.generic
    records_reference_trajectory(param,param_override);
  end
end
