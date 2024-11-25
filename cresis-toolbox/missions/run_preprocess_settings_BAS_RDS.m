% script run_preprocess_BAS_RDS.m
%
% Support script for run_preprocess.m

param.config.default = [];

%% PASIN RDS
cur_idx = length(param.config.default)+1;
param.config.default{cur_idx} = default_radar_params_2017_Antarctica_TObas_rds();
param.config.base_dir{cur_idx} = '/cresis/snfs1/data/MCoRDS/BAS/';
param.config.config_folder_names{cur_idx} = '20170122';
param.config.board_folder_names{cur_idx} = '20170122';
param.config.date_strs{cur_idx} = '20170122';
param.config.regexp{cur_idx} = '.*[0-9].mat';

