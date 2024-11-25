% script run_preprocess_HERC.m
%
% Support script for run_preprocess.m

param.config.default = [];

%% HERC MCORDS6 GROUND
cur_idx = length(param.config.default)+1;
param.config.default{cur_idx} = default_radar_params_2019_Antarctica_Ground_rds();
param.config.base_dir{cur_idx} = '/data/';
param.config.config_folder_names{cur_idx} = '20190920';
param.config.board_folder_names{cur_idx} = '20190920/%b';
param.config.date_strs{cur_idx} = '20190920';
