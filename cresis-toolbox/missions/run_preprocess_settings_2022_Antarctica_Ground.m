% script run_preprocess_settings_2022_Antarctica_Ground.m
%
% Support script for run_preprocess.m
%
% Preprocess setup script for 2022_Antarctica_Ground.

param.config.default = [];

%% ACCUM3 SINGLE DAY
% cur_idx = length(param.config.default)+1;
% param.config.default{cur_idx} = @default_radar_params_2022_Antarctica_Ground_accum;
% param.config.base_dir{cur_idx} = '/data/2022_Antarctica_Ground/';
% param.config.config_folder_names{cur_idx} = '20221207';
% param.config.board_folder_names{cur_idx} = '20221207/%b';
% param.config.date_str{cur_idx} = '20221207';


%% ACCUM3 MULTIPLE DAYS
date_str = {'20221206', '20221207', '20221209', '20221221', '20230108', '20230109', '20230110', '20230111', '20230112', '20230113', '20230114', '20230115', '20230118', '20230119', '20230121'};
% date_str = {'20230119'};
for idx = 1:length(date_str)
  cur_idx = length(param.config.default)+1;
  param.config.default{cur_idx} = @default_radar_params_2022_Antarctica_Ground_accum;
  param.config.base_dir{cur_idx} = '/data/2022_Antarctica_Ground/';
  param.config.config_folder_names{cur_idx} = date_str{idx};
  param.config.board_folder_names{cur_idx} = [date_str{idx} '/%b'];
  param.config.date_str{cur_idx} = date_str{idx};
end

