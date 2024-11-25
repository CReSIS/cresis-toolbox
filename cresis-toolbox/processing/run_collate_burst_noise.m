% script run_collate_burst_noise
%
% Runs collate_burst_noise
%
% Authors: John Paden

%% USER SETTINGS
% =========================================================================

param_override = [];

% params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'',{'analysis_burst','analysis'});
params = read_param_xls(ct_filename_param('rds_param_2018_Greenland_P3.xls'),'',{'analysis_burst','analysis'});
% params = read_param_xls(ct_filename_param('rds_param_2019_Greenland_P3.xls'),'',{'analysis_burst','analysis'});
% params = read_param_xls(ct_filename_param('rds_param_2019_Antarctica_Ground.xls'),'',{'analysis_burst','analysis'});

param_override.collate_burst_noise.in_path = 'analysis_burst';

% param_override.collate_burst_noise.debug_plots = {};
param_override.collate_burst_noise.debug_plots = {'bn_plot'};
% param_override.collate_burst_noise.debug_plots = {'visible','bn_plot'}; % <== CHOOSE to debug

cmd_method = 'generic';
rds_settings;

if 0
  % For debugging, use this to select a specific image and wf_adc to
  % collate instead of doing them all
  for img=1:6
    param_override.collate_burst_noise.wf_adcs{img} = [];
    param_override.collate_burst_noise.wf_adcs{img} = [1 2 3 4 12 13 14 15];
    param_override.collate_burst_noise.wf_adcs{img} = [2 13];
  end
  param_override.collate_burst_noise.imgs = [3 4];
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
  %collate_burst_noise(param,param_override);
  collate_burst_noise
  if 0
    % Debug code to print out which frames are affected by burst noise
    records = records_load(param,'bit_mask','gps_time');
    bad_rec = any(bitand(records.bit_mask,param.collate_burst_noise.bit_mask));
    [~,frm_id,~] = get_frame_id(param,records.gps_time);
    param.day_seg
    unique(floor(frm_id(bad_rec)))
  end
end
