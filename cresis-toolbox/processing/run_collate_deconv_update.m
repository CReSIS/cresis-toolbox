% Script run_collate_deconv_update.m
%
% Runs collate_deconv_update.m
%
% Author: John Paden

%% USER SETTINGS
% =========================================================================

param_override = [];

params = read_param_xls(ct_filename_param('accum_param_2019_Antarctica_TObas.xls'),'',{'analysis_spec' 'analysis'});
% params = read_param_xls(ct_filename_param('snow_param_2017_Greenland_P3.xls'),'',{'analysis_spec' 'analysis'});

params = ct_set_params(params,'cmd.generic',0);
% params = ct_set_params(params,'cmd.generic',1,'day_seg','20170327_01');
params = ct_set_params(params,'cmd.generic',1,'day_seg','20200127_01');
param_override.collate_deconv_update.cmd = {};
% param_override.collate_deconv_update.cmd{end+1}.method = 'delete';
% param_override.collate_deconv_update.cmd{end}.idxs = [1 2 3];
param_override.collate_deconv_update.cmd{end+1}.method = 'replace';
% param_override.collate_deconv_update.cmd{end}.day_seg = {'20170323_02'}
% param_override.collate_deconv_update.cmd{end}.day_seg = {'20170320_01'}
param_override.collate_deconv_update.cmd{end}.day_seg = {'20200128_01'};
param_override.collate_deconv_update.cmd{end}.idxs = {[1]};

% 2-18 GHz Deconvolution Settings (3 sets)
% params = ct_set_params(params,'analysis.cmd{1}.abs_metric',[58 4.5 -25 -35 inf inf]);
% param_override.collate_deconv_update.in_dir = 'analysis_uwb';

% params = ct_set_params(params,'analysis.cmd{1}.abs_metric',[58 9.8 -25 -35 inf inf]);
% param_override.collate_deconv_update.in_dir = 'analysis';

% params = ct_set_params(params,'analysis.cmd{1}.abs_metric',[58 24 -25 -28 inf inf]);
% param_override.collate_deconv_update.in_dir = 'analysis_kuband';

% 2-8 GHz Deconvolution Settings
% params = ct_set_params(params,'analysis.cmd{1}.abs_metric',[65 4.5 -25 -35 inf inf]);
param_override.collate_deconv_update.in_dir = 'analysis';

% param_override.collate_deconv_update.debug_plots = {'final','visible'};
param_override.collate_deconv_update.debug_plots = {'final'};

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
  collate_deconv_update(param,param_override);
  %collate_deconv_update
  
end
