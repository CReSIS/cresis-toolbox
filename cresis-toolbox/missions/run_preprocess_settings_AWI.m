% script run_preprocess_settings_AWI.m
%
% Support script for run_preprocess.m

param.config.default = [];

%% MCORDS5 AWI UWB - SINGLE DAY
cur_idx = length(param.config.default)+1;
param.config.default{cur_idx} = @default_radar_params_2022_Greenland_Polar5_rds;
param.config.base_dir{cur_idx} = 'G:\';
param.config.config_folder_names{cur_idx} = '20220603';
param.config.board_folder_names{cur_idx} = fullfile('20220603','%b');
param.config.date_str{cur_idx} = '20220603';

%% SNOW8 SINGLE DAY
% cur_idx = length(param.config.default)+1;
% param.config.default{cur_idx} = default_radar_params_2019_Arctic_Polar6_snow();
% param.config.base_dir{cur_idx} = '/work/ollie/ajutila/Data/mnt/HDD5/';
% param.config.config_folder_names{cur_idx} = fullfile('1903080101','UWBM');
% param.config.board_folder_names{cur_idx} = fullfile('1903080101','UWBM','%b');
% param.config.date_str{cur_idx} = '20190308';
