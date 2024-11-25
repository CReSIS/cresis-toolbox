function run_merge()
% layerdata.run_merge()
%
% Runs layerdata.merge.m
%
% Author: John Paden

%% User Settings
param_override = [];

params = read_param_xls(ct_filename_param('snow_param_2012_Greenland_P3.xls'));

params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20120330_04');
% params = ct_set_params(params,'cmd.generic',1);
% params = ct_set_params(params,'cmd.generic',0,'cmd.notes','Do not process');

param_override.layerdata_merge.old = 'layer';
param_override.layerdata_merge.new = 'layer_test';

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
first_time = true;
for param_idx = 1:length(params)
  param = params(param_idx);
  if isfield(param.cmd,'generic') && ~iscell(param.cmd.generic) && ~ischar(param.cmd.generic) && param.cmd.generic
    if ~first_time
      fprintf('Run dbcont when ready to open the next layerdata GUI.\n');
      keyboard
    end
    layerdata.merge(param,param_override);
  end
end
