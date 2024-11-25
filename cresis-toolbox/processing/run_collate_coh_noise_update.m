% script run_collate_coh_noise_update
%
% Runs collate_coh_noise_update
%
% Authors: John Paden

%% USER SETTINGS
% =========================================================================

param_override = [];

params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'',{'analysis_noise','analysis'});

% Enable a specific segment
params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20140401_03');

% Update the collate_coh_noise file location
for param_idx = 1:length(params)
  for wf = 1:length(params(param_idx).radar.wfs)
    % params(param_idx).radar.wfs(wf).coh_noise_arg.fn = 'analysis';
    params(param_idx).radar.wfs(wf).coh_noise_arg.fn = 'analysis_threshold';
  end
end

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
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  collate_coh_noise_update(param,param_override);
%   collate_coh_noise_update
  
end
