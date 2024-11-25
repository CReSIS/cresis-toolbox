% script run_preprocess_2013_Antarctica_Basler.m
%
% Support script for run_preprocess.m

param.config.default = [];


%% MCORDS3 SINGLE DAY
cur_idx = length(param.config.default)+1;
param.config.default{cur_idx} = default_radar_params_2013_Antarctica_Basler_rds();
param.config.base_dir{cur_idx} = '/cresis/snfs1/data/MCoRDS/2013_Antarctica_Basler/';
param.config.config_folder_names{cur_idx} = '20140102/';
param.config.board_folder_names{cur_idx} = '20140102/%b';
param.config.date_strs{cur_idx} = '20140102';

%% SNOW8 SINGLE DAY
% cur_idx = length(param.config.default)+1;
% param.config.default{cur_idx} = default_radar_params_2018_Greenland_P3_snow();
% param.config.base_dir{cur_idx} = '/N/dcwan/projects/cresis/2018_Greenland_P3/';
% param.config.config_folder_names{cur_idx} = '20180405/fmcw/snow';
% param.config.board_folder_names{cur_idx} = '20180405/fmcw/snow';
% param.config.date_strs{cur_idx} = '20180405';

%% MCORDS5-ACCUM SINGLE DAY
% cur_idx = length(param.config.default)+1;
% param.config.default{cur_idx} = default_radar_params_2018_Greenland_P3_accum();
% param.config.base_dir{cur_idx} = '/N/dcwan/projects/cresis/2018_Greenland_P3/';
% param.config.config_folder_names{cur_idx} = '20180405/accum';
% param.config.board_folder_names{cur_idx} = '20180405/accum/%b';
% param.config.date_strs{cur_idx} = '20180405';

return;

%% MCORDS3 MULTIPLE DAYS
date_strs = {'20180315','20180322','20180404','20180405','20180406','20180418','20180419','20180420','20180421','20180422','20180423','20180425','20180426','20180427','20180429','20180430','20180501'};
config_format_str = '%s/mcords/';
board_format_str = '%s/mcords/%%b';
defaults_fh = @default_radar_params_2018_Greenland_P3_rds;
base_dir = '/N/dcwan/projects/cresis/2018_Greenland_P3/';

for idx = 1:length(date_strs)
  cur_idx = length(param.config.default)+1;
  param.config.default{cur_idx} = defaults_fh();
  param.config.base_dir{cur_idx} = base_dir;
  param.config.config_folder_names{cur_idx} = sprintf(config_format_str,date_strs{idx});
  param.config.board_folder_names{cur_idx} = sprintf(board_format_str,date_strs{idx});
  param.config.date_strs{cur_idx} = date_strs{idx};
end

%% SNOW8 MULTIPLE DAYS
% date_strs = {'20180322','20180403','20180404','20180405','20180406','20180407','20180408','20180414','20180416','20180418','20180419','20180421','20180422','20180423','20180425','20180426','20180427','20180429','20180430','20180501'};
% config_format_str = '%s/fmcw/snow/';
% board_format_str = '%s/fmcw/snow/';
% defaults_fh = @default_radar_params_2018_Greenland_P3_snow;
% base_dir = '/N/dcwan/projects/cresis/2018_Greenland_P3/';
% 
% for idx = 1:length(date_strs)
%   cur_idx = length(param.config.default)+1;
%   param.config.default{cur_idx} = defaults_fh();
%   param.config.base_dir{cur_idx} = base_dir;
%   param.config.config_folder_names{cur_idx} = sprintf(config_format_str,date_strs{idx});
%   param.config.board_folder_names{cur_idx} = sprintf(board_format_str,date_strs{idx});
%   param.config.date_strs{cur_idx} = date_strs{idx};
% end

%% MCORDS5-ACCUM MULTIPLE DAYS
% date_strs = {'20180315','20180404','20180405','20180406','20180418','20180419','20180420','20180421','20180422','20180423','20180425','20180426','20180427','20180429','20180430','20180501'};
% config_format_str = '%s/accum/';
% board_format_str = '%s/accum/%%b';
% defaults_fh = @default_radar_params_2018_Greenland_P3_accum;
% base_dir = '/N/dcwan/projects/cresis/2018_Greenland_P3/';
% 
% for idx = 1:length(date_strs)
%   cur_idx = length(param.config.default)+1;
%   param.config.default{cur_idx} = defaults_fh();
%   param.config.base_dir{cur_idx} = base_dir;
%   param.config.config_folder_names{cur_idx} = sprintf(config_format_str,date_strs{idx});
%   param.config.board_folder_names{cur_idx} = sprintf(board_format_str,date_strs{idx});
%   param.config.date_strs{cur_idx} = date_strs{idx};
% end