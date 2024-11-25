% Script run_collate_deconv.m
%
% Runs collate_deconv.m
%
% Author: Jilu Li, John Paden

%% USER SETTINGS
% =========================================================================
clear param_override;

params = read_param_xls(ct_filename_param('snow_param_2017_Greenland_P3.xls'),'',{'analysis_spec' 'analysis'});
% params = read_param_xls(ct_filename_param('rds_param_2018_Greenland_P3.xls'),'',{'analysis_spec' 'analysis'});

% params = ct_set_params(params,'cmd.generic',1);
% params = ct_set_params(params,'cmd.generic',0,'cmd.notes','Do not process');

params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20180322_04');

params = ct_set_params(params,'collate_deconv.f0',2.85e9);
params = ct_set_params(params,'collate_deconv.f1',7.5e9);
params = ct_set_params(params,'collate_deconv.rbins',{[-100 100]});
params = ct_set_params(params,'collate_deconv.abs_metric',[58 9.8 -25 -35 inf inf]);
params = ct_set_params(params,'collate_deconv.SL_guard_bins',10);

% STEP 1: Check peakiness to ensure that enough waveforms qualify. If
% peakiness threshold has to be adjusted to let more waveforms in, then
% analysis spec must be run again.
param_override.collate_deconv.debug_plots = {'peakiness','metric','visible'}; param_override.collate_deconv.stage_two_en = false;

% STEP 2: Use the "metric" table output to choose debug_rlines
%param_override.collate_deconv.debug_plots = {'metric','visible'}; param_override.collate_deconv.stage_two_en = false;

% STEP 3: To evaluate individual waveforms, set debug_rlines to these
% waveforms and enable rbins (evaluate SNR for the rbins setting you have
% chosen) and/or deconv (evaluate the SL_guard_bins, abs_metric, and
% sidelobe suppression achieved):
%param_override.collate_deconv.debug_rlines = [1];
%param_override.collate_deconv.debug_plots = {'deconv','metric','visible'}; param_override.collate_deconv.stage_two_en = false;
%param_override.collate_deconv.debug_plots = {'rbins','deconv','metric','visible'}; param_override.collate_deconv.stage_two_en = false;
% STEP 3 ALTERNATE: To evaluate just the best individual waveform, just enable
% "rbins_best" and/or "deconv_best"
% param_override.collate_deconv.debug_plots = {'deconv_best','metric','visible'}; param_override.collate_deconv.stage_two_en = false;
% param_override.collate_deconv.debug_plots = {'deconv_best','metric'}; param_override.collate_deconv.stage_two_en = false;

% STEP 4: Once rbins are set and waveforms appear to be deconvolving well,
% run stage one and stage two (recommend disabling "visible" if many
% segments or wf_adc pairs).
%param_override.collate_deconv.debug_plots = {'deconv_best','metric','final','visible'};
%param_override.collate_deconv.debug_plots = {'deconv_best','metric','final'};

if 0
  % For debugging, use this to test specific waveforms for the whole
  % segment.
  param_override.collate_deconv.metric_mode = 'each'; % Default mode
  %param_override.collate_deconv.metric_mode = 'best'; param_override.collate_deconv.stage_two_en = false;
  %param_override.collate_deconv.metric_mode = 'final'; param_override.collate_deconv.stage_two_en = false;
  %param_override.collate_deconv.metric_mode = 1; param_override.collate_deconv.stage_two_en = false;
end

if 0
  % For debugging, use this to select specific images and wf_adc pairs to
  % collate instead of doing them all
  param_override.collate_deconv.wf_adcs = {[1],[1],[1]};
  param_override.collate_deconv.imgs = [1];
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
ctrl_chain = {};
for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  %collate_deconv(param,param_override);
  collate_deconv
  
end
