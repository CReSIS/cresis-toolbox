% script run_preprocess_2022_Greenland_P3.m
%
% Support script for run_preprocess.m

param.config.default = [];

%% HERC MCORDS6 GROUND
cur_idx = length(param.config.default)+1;
param.config.default{cur_idx} = default_radar_params_2022_Greenland_P3_snow();
param.config.base_dir{cur_idx} = '/mnt/data/';
param.config.config_folder_names{cur_idx} = '20220419/';
param.config.board_folder_names{cur_idx} = '20220419/%b';
param.config.date_strs{cur_idx} = '20220419';
