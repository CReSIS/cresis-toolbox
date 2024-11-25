% script run_preprocess_settings_2022_Antarctica_GroundGHOST.m
%
% Support script for run_preprocess.m
%
% Preprocess setup script for 2022_Antarctica_GroundGHOST.

param.config.default = [];

%% RDS SINGLE DAY
% cur_idx = length(param.config.default)+1;
% param.config.default{cur_idx} = @default_radar_params_2022_Antarctica_BaslerMKB_rds;
% param.config.base_dir{cur_idx} = '/data/UTIG_all/orig/xped/CXA1/acqn/MARFA/';
% param.config.config_folder_names{cur_idx} = '../../ELSA/F14/';
% param.config.board_folder_names{cur_idx} = 'F14';
% param.config.date_str{cur_idx} = '20230123';

%% RDS EVERY DAY

%good_flights = [3 4 11 12 14 15 16 19 20];
%missing_flights = [17 18]
for flight = [1 2 5 6 7 8 9 10 13]
  cur_idx = length(param.config.default)+1;
  param.config.default{cur_idx} = @default_radar_params_2022_Antarctica_BaslerMKB_rds;
  param.config.base_dir{cur_idx} = '/data/UTIG_all/orig/xped/CXA1/acqn/MARFA/';
  param.config.config_folder_names{cur_idx} = sprintf('../../ELSA/F%02d/', flight);
  param.config.board_folder_names{cur_idx} = sprintf('F%02d', flight);
  if flight == 1
    param.config.date_str{cur_idx} = '20221210';
    %     utig_pkt_strip 7/35 /data/UTIG_all/orig/xped/CXA1/acqn/MARFA/F01/radar0_20221210-005833-0006.dat (01-May-2023 22:00:54)
    %     /scratch/ct_tmp/headers/rds/2022_Antarctica_BaslerMKB/F01/radar0_20221210-005833-0006.dat
    %     Error using basic_load_utig (line 216)
    %     Bad record
    %     Error in preprocess_task_utig (line 119)
    %     hdr = basic_load_utig(fn);
  elseif flight == 2
    param.config.date_str{cur_idx} = '20221212';
    % utig_pkt_strip 14/49 /data/UTIG_all/orig/xped/CXA1/acqn/MARFA/F02/radar0_20221212-000310-0013.dat (01-May-2023 22:11:37)
    %     /scratch/ct_tmp/headers/rds/2022_Antarctica_BaslerMKB/F02/radar0_20221212-000310-0013.dat
    % Error using basic_load_utig (line 216)
    % Bad record
  elseif flight == 3
    param.config.date_str{cur_idx} = '20221213';
  elseif flight == 4
    param.config.date_str{cur_idx} = '20221228';
  elseif flight == 5
    param.config.date_str{cur_idx} = '20221229';
    %     utig_pkt_strip 15/44 /data/UTIG_all/orig/xped/CXA1/acqn/MARFA/F05/radar0_20221229-192430-0016.dat (04-May-2023 03:56:03)
    %     /scratch/ct_tmp/headers/rds/2022_Antarctica_BaslerMKB/F05/radar0_20221229-192430-0016.dat
    % Error using basic_load_utig (line 216)
    % Bad record
  elseif flight == 6
    param.config.date_str{cur_idx} = '20230106';
    % line 129: if hdr{1}.rseq(idx) ~= hdr{3}.rseq(idx)
    % preprocess_task_utig.m
  elseif flight == 7
    param.config.date_str{cur_idx} = '20230107';
%     utig_pkt_strip 39/40 /data/UTIG_all/orig/xped/CXA1/acqn/MARFA/F07/radar0_20230107-191130-0044.dat (04-May-2023 04:36:51)
%     /scratch/ct_tmp/headers/rds/2022_Antarctica_BaslerMKB/F07/radar0_20230107-191130-0044.dat
% Error using basic_load_utig (line 216)
% Bad record
  elseif flight == 8
    param.config.date_str{cur_idx} = '20230108';
%     utig_pkt_strip 4/44 /data/UTIG_all/orig/xped/CXA1/acqn/MARFA/F08/radar0_20230108-215526-0004.dat (04-May-2023 11:02:01)
%     /scratch/ct_tmp/headers/rds/2022_Antarctica_BaslerMKB/F08/radar0_20230108-215526-0004.dat
% Error using basic_load_utig (line 216)
% Bad record
  elseif flight == 9
    param.config.date_str{cur_idx} = '20230109';
%     utig_pkt_strip 42/45 /data/UTIG_all/orig/xped/CXA1/acqn/MARFA/F09/radar0_20230109-205352-0041.dat (04-May-2023 11:41:28)
%     /scratch/ct_tmp/headers/rds/2022_Antarctica_BaslerMKB/F09/radar0_20230109-205352-0041.dat
% Error using basic_load_utig (line 216)
% Bad record
  elseif flight == 10
    param.config.date_str{cur_idx} = '20230110';
%     utig_pkt_strip 1/44 /data/UTIG_all/orig/xped/CXA1/acqn/MARFA/F10/radar0_20230110-203509-0001.dat (04-May-2023 13:34:28)
%     /scratch/ct_tmp/headers/rds/2022_Antarctica_BaslerMKB/F10/radar0_20230110-203509-0001.dat
% Copy /data/UTIG_all/orig/xped/CXA1/acqn/MARFA/F10/../../ELSA/F10/serial*
%   /scratch/metadata/2022_Antarctica_BaslerMKB/20230110/ELSA
% Error using basic_load_utig (line 216)
% Bad record
  elseif flight == 11
    param.config.date_str{cur_idx} = '20230112';
  elseif flight == 12
    param.config.date_str{cur_idx} = '20230113';
  elseif flight == 13
    param.config.date_str{cur_idx} = '20230116';
    %     utig_pkt_strip 2/45 /data/UTIG_all/orig/xped/CXA1/acqn/MARFA/F13/radar0_20230116-200145-0001.dat (04-May-2023 14:58:08)
    %     /scratch/ct_tmp/headers/rds/2022_Antarctica_BaslerMKB/F13/radar0_20230116-200145-0001.dat
    % Warning: Variable 'comp_time' not found.
    % > In preprocess_task_utig (line 111)
    % In preprocess_task (line 29)
    % In cluster_exec_task (line 122)
    % In cluster_submit_job (line 194)
    % In cluster_run (line 202)
    % In cluster_run (line 99)
    % Unrecognized function or variable 'comp_time'.
    % Error in preprocess_task_utig (line 113)
    %     board_hdrs{1}.comp_time(end+(1:length(radar_time))) = comp_time;
  elseif flight == 14 % CANCELLED FLIGHT?
    param.config.date_str{cur_idx} = '20230117';
  elseif flight == 15
    param.config.date_str{cur_idx} = '20230120';
  elseif flight == 16
    param.config.date_str{cur_idx} = '20230124';
  elseif flight == 19
    param.config.date_str{cur_idx} = '20230127';
  elseif flight == 20
    param.config.date_str{cur_idx} = '20230129';
  end
end
