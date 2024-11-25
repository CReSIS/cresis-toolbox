% script run_preprocess_MINISNOW.m
%
% Support script for run_preprocess.m

param.config.default = [];

%% SNOW SINGLE DAY
% cur_idx = length(param.config.default)+1;
% param.config.default{cur_idx} = default_radar_params_2019_Alaska_SO_snow();
% param.config.base_dir{cur_idx} = '/cresis/snfs1/projects/Ka-band/Radar_Data/';
% param.config.config_folder_names{cur_idx} = '/';
% param.config.board_folder_names{cur_idx} = '/';
% param.config.date_strs{cur_idx} = '20190321';

%% KUBAND SINGLE DAY
cur_idx = length(param.config.default)+1;
param.config.default{cur_idx} = default_radar_params_2019_Greenland_TO_kuband();
param.config.base_dir{cur_idx} = '/cresis/snfs1/projects/Ka-band/Radar_Data/outside_tests';
param.config.config_folder_names{cur_idx} = '/';
param.config.board_folder_names{cur_idx} = '/';
param.config.date_strs{cur_idx} = '20190322';

%% KABAND SINGLE DAY
cur_idx = length(param.config.default)+1;
param.config.default{cur_idx} = default_radar_params_2019_Greenland_TO_kaband();
param.config.base_dir{cur_idx} = '/cresis/snfs1/projects/Ka-band/Radar_Data/outside_tests';
param.config.config_folder_names{cur_idx} = '/';
param.config.board_folder_names{cur_idx} = '/';
param.config.date_strs{cur_idx} = '20190322';

return;

%% SNOW MULTIPLE DAYS
% date_strs = {'20180928','20181010','20181011','20181012','20181013','20181015','20181016','20181018','20181019','20181020','20181022','20181027','20181030','20181031','20181103','20181104','20181105','20181107','20181109','20181110','20181111','20181112','20181114','20181115','20181116'};
% config_format_str = '%s/';
% board_format_str = '%s/';
% defaults_fh = @default_radar_params_2019_Alaska_SO_snow;
% base_dir = '/cresis/snfs1/data/SnowRadar/2019_Alaska_SO/';
% 
% for idx = 1:length(date_strs)
%   cur_idx = length(param.config.default)+1;
%   param.config.default{cur_idx} = defaults_fh();
%   param.config.base_dir{cur_idx} = base_dir;
%   param.config.config_folder_names{cur_idx} = sprintf(config_format_str,date_strs{idx});
%   param.config.board_folder_names{cur_idx} = sprintf(board_format_str,date_strs{idx});
%   param.config.date_strs{cur_idx} = date_strs{idx};
% end

%% KUBAND MULTIPLE DAYS
% date_strs = {'20180928','20181010','20181011','20181012','20181013','20181015','20181016','20181018','20181019','20181020','20181022','20181027','20181030','20181031','20181103','20181104','20181105','20181107','20181109','20181110','20181111','20181112','20181114','20181115','20181116'};
% config_format_str = '%s/';
% board_format_str = '%s/';
% defaults_fh = @default_radar_params_2019_Greenland_TO_kuband;
% base_dir = '/cresis/snfs1/data/SnowRadar/2019_Greenland_TO/';
% 
% for idx = 1:length(date_strs)
%   cur_idx = length(param.config.default)+1;
%   param.config.default{cur_idx} = defaults_fh();
%   param.config.base_dir{cur_idx} = base_dir;
%   param.config.config_folder_names{cur_idx} = sprintf(config_format_str,date_strs{idx});
%   param.config.board_folder_names{cur_idx} = sprintf(board_format_str,date_strs{idx});
%   param.config.date_strs{cur_idx} = date_strs{idx};
% end

%% KABAND MULTIPLE DAYS
% date_strs = {'20180928','20181010','20181011','20181012','20181013','20181015','20181016','20181018','20181019','20181020','20181022','20181027','20181030','20181031','20181103','20181104','20181105','20181107','20181109','20181110','20181111','20181112','20181114','20181115','20181116'};
% config_format_str = '%s/';
% board_format_str = '%s/';
% defaults_fh = @default_radar_params_2019_Greenland_TO_kaband;
% base_dir = '/cresis/snfs1/data/SnowRadar/2019_Greenland_TO/';
% 
% for idx = 1:length(date_strs)
%   cur_idx = length(param.config.default)+1;
%   param.config.default{cur_idx} = defaults_fh();
%   param.config.base_dir{cur_idx} = base_dir;
%   param.config.config_folder_names{cur_idx} = sprintf(config_format_str,date_strs{idx});
%   param.config.board_folder_names{cur_idx} = sprintf(board_format_str,date_strs{idx});
%   param.config.date_strs{cur_idx} = date_strs{idx};
% end
