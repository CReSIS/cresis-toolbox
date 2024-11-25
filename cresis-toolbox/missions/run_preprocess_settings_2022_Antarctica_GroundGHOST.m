% script run_preprocess_settings_2022_Antarctica_GroundGHOST.m
%
% Support script for run_preprocess.m
%
% Preprocess setup script for 2022_Antarctica_GroundGHOST.

param.config.default = [];

%% RDS SINGLE DAY
% cur_idx = length(param.config.default)+1;
% param.config.default{cur_idx} = @default_radar_params_2022_Antarctica_GroundGHOST_rds;
% param.config.base_dir{cur_idx} = '/data/';
% param.config.config_folder_names{cur_idx} = '20230202d';
% param.config.board_folder_names{cur_idx} = '20230202d/%b';
% param.config.date_str{cur_idx} = '20230202d';

%% RDS MULTIPLE DAYS
date_str = {'20230202', '20230203', '20230206', '20230207'};
% date_str = {'20230119'};
for idx = 1:length(date_str)
  cur_idx = length(param.config.default)+1;
  param.config.default{cur_idx} = @default_radar_params_2022_Antarctica_GroundGHOST_rds;
  param.config.base_dir{cur_idx} = '/cresis/snfs1/data/MCoRDS/2022_Antarctica_GroundGHOST/';
  param.config.config_folder_names{cur_idx} = date_str{idx};
  param.config.board_folder_names{cur_idx} = [date_str{idx} '/%b'];
  param.config.date_str{cur_idx} = date_str{idx};
end