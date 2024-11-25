% script run_echo_stats
%
% Author: John Paden

%% User Setup
% =====================================================================
param_override = [];

params = read_param_xls(ct_filename_param('snow_param_2011_Greenland_P3.xls'));

% Example to run a specific segment and frame by overriding parameter spreadsheet values
params = ct_set_params(params,'cmd.generic',0);
% params = ct_set_params(params,'cmd.generic',1,'day_seg','20110329');
params = ct_set_params(params,'cmd.generic',1,'day_seg','20110425_0[5-9]');
params = ct_set_params(params,'cmd.generic',1,'day_seg','20110425_10');
params = ct_set_params(params,'cmd.generic',1,'day_seg','20110426');
params = ct_set_params(params,'cmd.generic',0,'cmd.notes','Do not process');
% params = ct_set_params(params,'cmd.frms',[1]);

params = ct_set_params(params,'echo_stats.data_type','CSARP_post/qlook');
params = ct_set_params(params,'echo_stats.echogram_img',0);
params = ct_set_params(params,'echo_stats.noise_bins',[-400 -100]);
params = ct_set_params(params,'echo_stats.signal_bins',[-99 500]);
params = ct_set_params(params,'echo_stats.detrend_threshold',inf);
params = ct_set_params(params,'echo_stats.sum_threshold',100);
params = ct_set_params(params,'echo_stats.peak_wfs_bins',[-200:40]);

dbstop if error;
% param_override.cluster.type = 'torque';
% param_override.cluster.type = 'matlab';
param_override.cluster.type = 'debug';
% param_override.cluster.rerun_only = true;
% param_override.cluster.desired_time_per_job  = 240*60;
% param_override.cluster.cpu_time_mult  = 2;
% param_override.cluster.mem_mult  = 2;

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
  echo_stats(param,param_override);
end
