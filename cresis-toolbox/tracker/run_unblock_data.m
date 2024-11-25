% Script for running unblock_data
%
% Authors: fill in...
%
% See also: run_FUNCTION.m, run_unblock.m, 

%% User Setup
% =====================================================================
param_override = [];

params = read_param_xls(ct_filename_param('snow_param_2012_Greenland_P3.xls'));
% Syntax for running a specific segment and frame by overriding parameter spreadsheet values
%params = read_param_xls(ct_filename_param('rds_param_2009_Antarctica_TO.xls'),'20091228_01');
params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20120330_04');
params = ct_set_params(params,'cmd.frms',[]);


% Set override parameters using ct_set_params, by setting param_override, or by setting FUNCTION_params variable which eventually is copied to param_override.FUNCTION).


param_override.unblock_data = [] ;

% block_data_param structure 

% Provide path to tracked layers and echogram path argument in ct_data
param_override.unblock_data.tracked_layers_dir_path = '/cresis/snfs1/scratch/ibikunle/ct_user_tmp/final/snow/2012_Greenland_P3/frames_001_243_20120330_04/image';
param_override.unblock_data.echo_path = 'CSARP_post/qlook'; % Argument passed into ct_filename_out(param,argument) e.g 'qlook' or for rds--> argument = 'CSARP_post/standard'

param_override.unblock_data.uncompress_en = 1;

param_override.unblock_data.tracked_layers_search_str = 'image'; % The prefix of each NN layer .mat file
param_override.unblock_data.echo_search_str = 'Data_2012'; % search string for echogram file

param_override.unblock_data.layer_dest_source = 'layerData'; %
param_override.unblock_data.layer_dest_layerdata_source = 'layerData_koenig_ibk'; % Argument to destination layerdata_source


param_override.unblock_data.dest_layer_prefix = 'Koenig_'; 

param_override.unblock_data.copy_method = 'fillgaps'; %'fill_gaps' or 'overwrite'
param_override.unblock_data.gaps_fill_method = 'preserve_gaps';  %'preserve_gaps';  %interp_finite
param_override.unblock_data.layer_source.existence_check = false;
param_override.unblock_data.layer_dest.existence_check = false;



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
  unblock_data(param,param_override);
end

% Post process code (only include if necessary)

