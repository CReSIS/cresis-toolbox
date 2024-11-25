% script run_collate_coh_noise
%
% Runs collate_coh_noise
%
% Authors: John Paden

%% USER SETTINGS
% =========================================================================

param_override = [];

params = read_param_xls(ct_filename_param('snow_param_2017_Arctic_Polar5.xls'),'',{'analysis_noise','analysis'});

% Enable a specific segment
params = ct_set_params(params,'cmd.generic',0);
% params = ct_set_params(params,'cmd.generic',1,'day_seg','20170330_01');

if 1
  % Near-DC removal
  param_override.collate_coh_noise.method = {'firdec'};
  param_override.collate_coh_noise.firdec_fcutoff = {@(t) 1/30}; % Update coherent noise estimate every 30 seconds
  param_override.collate_coh_noise.firdec_fs = 1/7.5; % Should update about 4 times as often as the estimate: 30/4 = 7.5
else
  % DC removal when dft_corr_time set to inf
  param_override.collate_coh_noise.method = {'dft'};
  param_override.collate_coh_noise.dft_corr_time = inf;
end

% Threshold: This example combines a -120 dB threshold, threshold
% estimate+6dB guard, and a max filtered coherent noise mask for the feed
% through.
%
% for param_idx = 1:length(params)
%   param = params(param_idx);
%   if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
%     continue;
%   end
%   for img = 1:length(params(param_idx).analysis.imgs)
%     nt = -120; % Specify noise floor (may need to make this img dependent)
%     params(param_idx).collate_coh_noise.threshold_eval{img} = 'threshold = max(min(nt,threshold+6),max_filt1(10*log10(abs(noise.dft(:,1)).^2)+15-1e6*(time>(Tpd+1.2e-6)),5));';
%   end
% end

% param_override.collate_coh_noise.in_path = 'analysis_threshold'; % Enable during second pass if threshold was used.
% param_override.collate_coh_noise.out_path = 'analysis_threshold'; % Enable during second pass if threshold was used.

param_override.collate_coh_noise.debug_plots = {'visible','cn_plot','threshold_plot'}; % Debugging
% param_override.collate_coh_noise.debug_plots = {'cn_plot','threshold_plot'}; % Typical setting when not debugging
% param_override.collate_coh_noise.debug_plots = {}; % Necessary if plots are too large for memory

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
%   collate_coh_noise(param,param_override);
  collate_coh_noise
  
end
