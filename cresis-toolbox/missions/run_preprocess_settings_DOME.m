% script run_preprocess_DOME.m
%
% Support script for run_preprocess.m

param.config.default = [];

%% DOME MCORDS6 GROUND
cur_idx = length(param.config.default)+1;
param.config.default{cur_idx} = default_radar_params_2018_Antarctica_Ground_rds();
param.config.base_dir{cur_idx} = '/data/';
param.config.config_folder_names{cur_idx} = '20181014';
param.config.board_folder_names{cur_idx} = '20181014/%b';
param.config.date_strs{cur_idx} = '20181014';

return;
