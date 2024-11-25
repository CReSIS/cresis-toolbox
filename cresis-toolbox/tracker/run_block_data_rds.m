
% Script for running block_data
%
% Authors: fill in...
%
% See also: run_FUNCTION.m, run_unblock.m, 

%% User Setup
% =====================================================================
param_override = [];

params = read_param_xls(ct_filename_param('rds_param_2012_Greenland_P3.xls'));
% Syntax for running a specific segment and frame by overriding parameter spreadsheet values
%params = read_param_xls(ct_filename_param('rds_param_2009_Antarctica_TO.xls'),'20091228_01');
params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20120330_03');
params = ct_set_params(params,'cmd.frms',[]);

% Set override parameters using ct_set_params, by setting param_override, or by setting FUNCTION_params variable which eventually is copied to param_override.FUNCTION).


param_override.block_data = [] ;
param_override.block_data.block_size = 256; % Set the value for each block
param_override.block_data.block_overlap = 0.5; % Set the % of overlap between each block
param_override.block_data.top_gap = 100; % Number of rows of data before first layer

param_override.block_data.bottom_pad = 100; % Number of rows of data used to pad after the last layer
param_override.block_data.filter_len = 1;


param_override.block_data.values.user_max = [];  % Set to empty [] to use max finite value from data or set predetermined max values 
param_override.block_data.values.user_min = []; % Set min valid finite value

param_override.block_data.echo_path = 'CSARP_post/standard'; % Echogram source e.g rds uses 'CSARP\standard' => ct_filename_out(param,'CSARP\standard')

param_override.block_data.out_fn ='macgregor_troubleshoot3'; % Specify desired output path i.e fn passed into ct_filename_tmp 
%param_override.sched.type = 'no scheduler'; % Example to override default cluster settings

% Paramaters of "layer_params" argument of OpsLoadLayers(param,"layer_params"
param_override.block_data.layers_name = 'layers';
param_override.block_data.layers_source = 'layerData_ver1';
param_override.block_data.layerdata_source = 'layerData_ver1';


% param_override.block_data.layers_prefix = 'layers';

param_override.block_data.debug_plot = 0 ; % Debug plots (True or False)


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
  block_data(param,param_override);
end

% Post process code (only include if necessary)