% script run_img_combine_update
%
% Script for running img_combine_update
%
% Authors: John Paden
%
% See also: run_img_combine_update.m, img_combine_update.m

%% User Setup
% =====================================================================
params = read_param_xls(ct_filename_param('rds_param_2019_Antarctica_Ground.xls'),'');
params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20200107_01');


mode = 'array'; % <== OFTEN CHANGED (qlook or array)

img_combine_update_param.out_path = 'standard'; % <== OFTEN CHANGED (no default)
img_combine_update_param.img_comb_mult = inf; % <== OFTEN CHANGED (inf default)
img_combine_update_param.img_comb_bins = 10; % <== OFTEN CHANGED (1 default)
img_combine_update_param.img_comb_layer_params = struct('name','surface','source','layerdata','layerdata_source','layer');% <== OFTEN CHANGED

%% Automated Section
% =====================================================================

param_override = [];
param_override.(mode) = img_combine_update_param;
param_override.img_combine_update.mode = mode;

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
  img_combine_update(param,param_override);
end
