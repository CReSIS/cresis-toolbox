% script run_preprocess_BAS.m
%
% Support script for run_preprocess.m
%
% Preprocess setup script for 2018_Antarctica_TObas and
% 2019_Antarctica_TObas.

param.config.default = [];

%% ACCUM3 SINGLE DAY
% cur_idx = length(param.config.default)+1;
% param.config.default{cur_idx} = default_radar_params_2018_Antarctica_TObas_accum();
% param.config.base_dir{cur_idx} = '/cresis/snfs1/data/Accum_Data/2019_Antarctica_TObas/';
% param.config.config_folder_names{cur_idx} = '20191225';
% param.config.board_folder_names{cur_idx} = '20191225/%b';
% param.config.date_strs{cur_idx} = '20191225';


%% ACCUM3 MULTIPLE DAYS
% date_strs = {'20191215','20191222','20191225','20191226','20191229','20191230'};
date_strs = {'20200125','20200126','20200127','20200128'};
config_format_str = '%s/';
board_format_str = '%s/%%b';
defaults_fh = @default_radar_params_2018_Antarctica_TObas_accum;
base_dir = '/cresis/snfs1/data/Accum_Data/2019_Antarctica_TObas/';

for idx = 1:length(date_strs)
  cur_idx = length(param.config.default)+1;
  param.config.default{cur_idx} = defaults_fh();
  param.config.base_dir{cur_idx} = base_dir;
  param.config.config_folder_names{cur_idx} = sprintf(config_format_str,date_strs{idx});
  param.config.board_folder_names{cur_idx} = sprintf(board_format_str,date_strs{idx});
  param.config.date_strs{cur_idx} = date_strs{idx};
end
