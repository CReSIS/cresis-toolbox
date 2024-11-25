% script run_preprocess_settings_2023_Greenland_Ground.m
%
% Support script for run_preprocess.m
%
% Preprocess setup script for 2023_Greenland_Ground.

param.config.default = [];

%% ACCUM3 SINGLE DAY
cur_idx = length(param.config.default)+1;
param.config.default{cur_idx} = @default_radar_params_2023_Greenland_Ground_accum;
param.config.base_dir{cur_idx} = '/data/';
param.config.config_folder_names{cur_idx} = '20230407';
param.config.board_folder_names{cur_idx} = '20230407/%b';
param.config.date_str{cur_idx} = '20230407';
