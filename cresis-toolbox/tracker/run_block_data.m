% run_block_data.m
%
%Script for running block_data
%
% Authors: Ibikunle, John Paden
%
% See also: run_block_data.m, block_data.m, run_unblock_data.m,
% unblock_data.m

%% User Setup
% =====================================================================
param_override = [];

params = read_param_xls(ct_filename_param('snow_param_2016_Greenland_P3.xls'));

% Syntax for running a specific segment and frame by overriding parameter spreadsheet values
%params = read_param_xls(ct_filename_param('rds_param_2009_Antarctica_TO.xls'),'20091228_01');
params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20160519_01');
params = ct_set_params(params,'cmd.frms',[34:44]);

param_override.block_data.block_along_track = 50e3; % Along-track length of each block
param_override.block_data.block_Nx = 256; % Number of samples in each block
param_override.block_data.block_overlap = 0.5; % Set the % of overlap between each block
param_override.block_data.rows.t0_pad = 50;
param_override.block_data.rows.t1_pad = 35;

param_override.block_data.inc_B_filter = ones(1,41)/41;
param_override.block_data.inc_dec = 20;
param_override.block_data.nan_dec_normalize_threshold = [];
param_override.block_data.nan_dec = false;
param_override.block_data.norm.scale = [0.4 1];
param_override.block_data.detrend.method = 'polynomial';

param_override.block_data.flatten.resample_field = [];
param_override.block_data.flatten.resample_field.name = 'surface';
param_override.block_data.flatten.resample_field.source = 'layerdata';
param_override.block_data.flatten.resample_field.layerdata_source = 'layer_overly2021';
param_override.block_data.flatten.interp_method = [];

param_override.block_data.echo_path = 'CSARP_post/qlook';

param_override.block_data.out_path = 'block_data';

param_override.block_data.surf_param = [];
param_override.block_data.surf_param.name = 'surface';
param_override.block_data.surf_param.source = 'layerdata';
param_override.block_data.surf_param.layerdata_source = 'layer_overly2021';

param_override.block_data.layer_params = [];
param_override.block_data.layer_params.name = 'surface';
param_override.block_data.layer_params(1).source = 'layerdata';
param_override.block_data.layer_params(1).layerdata_source = 'layer_overly2021';
param_override.block_data.layer_params(2).regexp = 'snow.*';
param_override.block_data.layer_params(2).source = 'layerdata';
param_override.block_data.layer_params(2).layerdata_source = 'layer_overly2021';

param_override.block_data.file.img_en = true;
param_override.block_data.file.layer_bin_en = true;
param_override.block_data.file.layer_mult_en = true;
param_override.block_data.file.layer_seg_en = true;
param_override.block_data.file.mat_en = true;

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
  %block_data(param,param_override);
  block_data
  return
end

