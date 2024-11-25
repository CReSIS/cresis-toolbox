% script run_preprocess_settings_2018_Greenland_P3.m
%
% Support script for run_preprocess.m

param.config.default = [];


%% MCORDS3 SINGLE DAY
% cur_idx = length(param.config.default)+1;
% param.config.default{cur_idx} = @default_radar_params_2019_Antarctica_GV_rds;
% param.config.base_dir{cur_idx} = '/cresis/snfs1/data/MCoRDS/2019_Antarctica_GV/';
% param.config.config_folder_names{cur_idx} = '20191009/';
% param.config.board_folder_names{cur_idx} = '20191009/%b';
% param.config.date_str{cur_idx} = '20191009';

%% SNOW8 SINGLE DAY
cur_idx = length(param.config.default)+1;
param.config.default{cur_idx} = @default_radar_params_2018_Greenland_P3_snow;
param.config.base_dir{cur_idx} = '/mnt/raid_ssdorange/2018_Greenland_P3/';
param.config.config_folder_names{cur_idx} = '20180320';
param.config.board_folder_names{cur_idx} = '20180320';
param.config.date_str{cur_idx} = '20180320';

%% MCORDS5-ACCUM SINGLE DAY
% cur_idx = length(param.config.default)+1;
% param.config.default{cur_idx} = @default_radar_params_2018_Greenland_P3_accum;
% param.config.base_dir{cur_idx} = '/N/dcwan/projects/cresis/2018_Greenland_P3/';
% param.config.config_folder_names{cur_idx} = '20180405/accum';
% param.config.board_folder_names{cur_idx} = '20180405/accum/%b';
% param.config.date_str{cur_idx} = '20180405';

% return;

%% MCORDS3 MULTIPLE DAYS
% date_str = {'20180315','20180322','20180404','20180405','20180406','20180418','20180419','20180420','20180421','20180422','20180423','20180425','20180426','20180427','20180429','20180430','20180501'};
% config_format_str = '%s/mcords/';
% board_format_str = '%s/mcords/%%b';
% defaults_fh = @default_radar_params_2018_Greenland_P3_rds;
% base_dir = '/N/dcwan/projects/cresis/2018_Greenland_P3/';
% 
% for idx = 1:length(date_str)
%   cur_idx = length(param.config.default)+1;
%   param.config.default{cur_idx} = defaults_fh();
%   param.config.base_dir{cur_idx} = base_dir;
%   param.config.config_folder_names{cur_idx} = sprintf(config_format_str,date_str{idx});
%   param.config.board_folder_names{cur_idx} = sprintf(board_format_str,date_str{idx});
%   param.config.date_str{cur_idx} = date_str{idx};
% end

%% SNOW8 MULTIPLE DAYS
% date_str = {'20180322','20180403','20180404','20180405','20180406','20180407','20180408','20180414','20180416','20180418','20180419','20180421','20180422','20180423','20180425','20180426','20180427','20180429','20180430','20180501'};
% config_format_str = '%s/fmcw/snow/';
% board_format_str = '%s/fmcw/snow/';
% defaults_fh = @default_radar_params_2018_Greenland_P3_snow;
% base_dir = '/N/dcwan/projects/cresis/2018_Greenland_P3/';
% 
% for idx = 1:length(date_str)
%   cur_idx = length(param.config.default)+1;
%   param.config.default{cur_idx} = defaults_fh();
%   param.config.base_dir{cur_idx} = base_dir;
%   param.config.config_folder_names{cur_idx} = sprintf(config_format_str,date_str{idx});
%   param.config.board_folder_names{cur_idx} = sprintf(board_format_str,date_str{idx});
%   param.config.date_str{cur_idx} = date_str{idx};
% end

%% MCORDS5-ACCUM MULTIPLE DAYS
% date_str = {'20180315','20180404','20180405','20180406','20180418','20180419','20180420','20180421','20180422','20180423','20180425','20180426','20180427','20180429','20180430','20180501'};
% config_format_str = '%s/accum/';
% board_format_str = '%s/accum/%%b';
% defaults_fh = @default_radar_params_2018_Greenland_P3_accum;
% base_dir = '/N/dcwan/projects/cresis/2018_Greenland_P3/';
% 
% for idx = 1:length(date_str)
%   cur_idx = length(param.config.default)+1;
%   param.config.default{cur_idx} = defaults_fh();
%   param.config.base_dir{cur_idx} = base_dir;
%   param.config.config_folder_names{cur_idx} = sprintf(config_format_str,date_str{idx});
%   param.config.board_folder_names{cur_idx} = sprintf(board_format_str,date_str{idx});
%   param.config.date_str{cur_idx} = date_str{idx};
% end
