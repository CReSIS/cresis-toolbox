% script run_preprocess_VANILLA.m
%
% Support script for run_preprocess.m
%
% Preprocess setup script for 2021_Arctic_Vanilla.

param.config.default = [];

% Snow9 SINGLE DAY
% cur_idx = length(param.config.default)+1;
% param.config.default{cur_idx} = default_radar_params_2021_Arctic_Vanilla_snow();
% param.config.base_dir{cur_idx} = '/cresis/snfs1/data/SnowRadar/2021_Arctic_Vanilla/';
% param.config.config_folder_names{cur_idx} = '/20210414';
% param.config.board_folder_names{cur_idx} = '/20210414';
% param.config.date_strs{cur_idx} = '20210414';

cur_idx = length(param.config.default)+1;
param.config.default{cur_idx} = default_radar_params_2021_Arctic_Vanilla_snow();
param.config.base_dir{cur_idx} = '/cresis/snfs1/data/SnowRadar/2021_Arctic_Vanilla/';
param.config.config_folder_names{cur_idx} = '/20210819/sysconfig';
param.config.board_folder_names{cur_idx} = '/20210819/data';
param.config.date_strs{cur_idx} = '20210819';