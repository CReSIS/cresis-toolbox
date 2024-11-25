% script run_preprocess_UTUA.m
%
% Support script for run_preprocess.m; University of Texas/Arizona HF Sounder

param.config.default = [];

%% HF SINGLE DAY
cur_idx = length(param.config.default)+1;
param.config.default{cur_idx} = default_radar_params_2018_Alaska_SO_rds();
param.config.base_dir{cur_idx} = 'E:\tmp\google_drive\radar';
param.config.config_folder_names{cur_idx} = '\20180819';
param.config.board_folder_names{cur_idx} = '\20180819';
param.config.date_strs{cur_idx} = '20180819';
param.config.file.prefix = '20180819';

return;

%% HF MULTIPLE DAYS
% date_strs = {'20180315','20180322','20180404','20180405','20180406','20180418','20180419','20180420','20180421','20180422','20180423','20180425','20180426','20180427','20180429','20180430','20180501'};
% config_format_str = '%s/mcords/';
% board_format_str = '%s/mcords/%%b';
% defaults_fh = @default_radar_params_2018_Greenland_P3_rds;
% base_dir = '/N/dcwan/projects/cresis/2018_Greenland_P3/';

% for idx = 1:length(date_strs)
  % cur_idx = length(param.config.default)+1;
  % param.config.default{cur_idx} = defaults_fh();
  % param.config.base_dir{cur_idx} = base_dir;
  % param.config.config_folder_names{cur_idx} = sprintf(config_format_str,date_strs{idx});
  % param.config.board_folder_names{cur_idx} = sprintf(board_format_str,date_strs{idx});
  % param.config.date_strs{cur_idx} = date_strs{idx};
% end
