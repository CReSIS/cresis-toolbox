% script run_preprocess_N1KU.m
%
% Support script for run_preprocess.m

param.config.default = [];

%% SNOW SINGLE DAY
cur_idx = length(param.config.default)+1;
param.config.default{cur_idx} = default_radar_params_2020_SouthDakota_N1KU_snow();
param.config.base_dir{cur_idx} = '/cresis/snfs1/data/SnowRadar/2020_SouthDakota_CESSNA/';
param.config.base_dir{cur_idx} = '/run/media/cresis1/KUSNOW/';
param.config.config_folder_names{cur_idx} = '20210209/gps';
param.config.board_folder_names{cur_idx} = '20210209/snow';
param.config.date_strs{cur_idx} = '20210209';

% return;

%% SNOW MULTIPLE DAYS
% date_strs = {'20210204','20210205','20210209'};
% date_strs = {'20210209'};
% config_format_str = '%s/gps';
% board_format_str = '%s/snow';
% defaults_fh = @default_radar_params_2020_SouthDakota_N1KU_snow;
% %base_dir = '/cresis/snfs1/data/SnowRadar/2020_SouthDakota_N1KU/';
% base_dir = '/run/media/cresis1/KUSNOW/';
% 
% for idx = 1:length(date_strs)
%   cur_idx = length(param.config.default)+1;
%   param.config.default{cur_idx} = defaults_fh();
%   param.config.base_dir{cur_idx} = base_dir;
%   param.config.config_folder_names{cur_idx} = sprintf(config_format_str,date_strs{idx});
%   param.config.board_folder_names{cur_idx} = sprintf(board_format_str,date_strs{idx});
%   param.config.date_strs{cur_idx} = date_strs{idx};
% end
