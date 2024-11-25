% script run_check_surface
%
% Runs check_surface.m
%
% cat /N/dcwan/projects/cresis/output/ct_tmp/check_surface/snow/2017_Greenland_P3/*.txt
%
% Author: John Paden

%% User Settings
param_override = [];

params = read_param_xls(ct_filename_param('snow_param_2017_Arctic_Polar5.xls'));

% params.cmd.generic=1;
params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20170410_01');
% params = ct_set_params(params,'cmd.generic',1,'cmd.mission_names','^sea.*');
% params = ct_set_params(params,'cmd.generic',1,'cmd.mission_names','(?(?!^sea.*)^.*)');
% params = ct_set_params(params,'cmd.generic',1);
% params = ct_set_params(params,'cmd.generic',0,'cmd.notes','Do not process');

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
ctrl_chain = {};
for param_idx = 1:length(params)
  param = params(param_idx);
  if isfield(param.cmd,'generic') && ~iscell(param.cmd.generic) && ~ischar(param.cmd.generic) && param.cmd.generic
    check_surface(param,param_override);
  end
end

% Output all results as table
checksur_dir = fileparts(ct_filename_ct_tmp(params(1),'','check_surface','*.txt'));
try
  system(sprintf('cat %s/*.txt',checksur_dir))
catch ME
  warning('Output all results as table failed. %s', ME.getReport);
end
