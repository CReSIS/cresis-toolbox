function [param,defaults] = default_radar_params_2022_Antarctica_BaslerMKB_rds
% param = default_radar_params_2022_Antarctica_BaslerMKB_rds
%
% rds: 2022_Antarctica_BaslerMKB
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Set the param.season_name to the correct season before running.
%
% Author: John Paden
%
% See also: default_radar_params_*.m

%% Preprocess parameters
param.season_name = '2022_Antarctica_BaslerMKB';
param.radar_name = 'rds';

% Reading in files
param.config.daq_type = 'utig';
param.config.header_load_func = @basic_load_utig;
param.config.file.prefix = 'radar';
param.config.board_map = {''};

% Creating segments
param.config.max_time_gap = 10;
param.config.min_seg_size = 1;

default = [];

%% Command worksheet
param.cmd.records = 1;
param.cmd.qlook = 1;
param.cmd.generic = 1;

%% Records worksheet
param.records.gps.time_offset = 0;
param.records.gps.en = 1;
param.records.frames.geotiff_fn = 'antarctica\Landsat-7\Antarctica_LIMA.tif';
param.records.frames.mode = 1;
param.records.file.version = 415;
param.records.file.prefix = 'radar0';
param.records.file.suffix = '.dat';
param.records.file.boards = {''};
param.records.file.board_folder_name = '';
param.records.file.clk = 10e6;

%% Qlook worksheet
param.qlook.out_path = '';
param.qlook.block_size = 20000;
param.qlook.motion_comp = 0;
param.qlook.dec = 10;
param.qlook.inc_dec = 5;
param.qlook.surf.en = 1;
param.qlook.surf.method = 'rds';
param.qlook.resample = [2 1];

%% SAR worksheet
param.sar.out_path = '';
param.sar.frm_types = {0,[0 1],0,0,-1};
param.sar.chunk_len = 5000;
param.sar.chunk_overlap = 10;
param.sar.frm_overlap = 0;
param.sar.coh_noise_removal = 0;
param.sar.combine_rx = 0;
param.sar.time_of_full_support = inf;
param.sar.pulse_rfi.en = [];
param.sar.pulse_rfi.inc_ave= [];
param.sar.pulse_rfi.thresh_scale = [];
param.sar.trim_vals = [];
param.sar.pulse_comp = 1;
param.sar.ft_dec = 1;
param.sar.ft_wind = @hanning;
param.sar.ft_wind_time = 0;
param.sar.lever_arm_fh = @lever_arm;
param.sar.mocomp.en = 1;
param.sar.mocomp.type = 2;
param.sar.mocomp.filter = {@butter  [2]  [0.1000]};
param.sar.mocomp.uniform_en = 1;
param.sar.sar_type = 'fk';
param.sar.sigma_x = 2.5;
param.sar.sub_aperture_steering = 0;
param.sar.st_wind = @hanning;
param.sar.start_eps = 3.15;

%% Array worksheet
param.array.in_path = '';
param.array.array_path = '';
param.array.out_path = '';
param.array.method = 'standard';
param.array.window = @hanning;
param.array.bin_rng = 0;
param.array.line_rng = -10:10;
param.array.dbin = 1;
param.array.dline = 11;
param.array.DCM = [];
param.array.Nsv = 1;
param.array.theta_rng = [0 0];
param.array.sv_fh = @array_proc_sv;
param.array.diag_load = 0;
param.array.Nsig = 2;

%% Radar worksheet
param.radar.fs = 50e6;
param.radar.prf = 6250;
param.radar.adc_bits = 14;
param.radar.Vpp_scale = 2;
param.radar.lever_arm_fh = @lever_arm;
param.radar.wfs = [];
for wf = 1:1
  param.radar.wfs(wf).adcs = [1 2 3 4]; % ADCs
  param.radar.wfs(wf).f0 = 52.5e6;
  param.radar.wfs(wf).f1 = 67.5e6;
  param.radar.wfs(wf).DDC_dec = 1;
  param.radar.wfs(wf).DDC_freq = 0;
  param.radar.wfs(wf).BW_window = [param.radar.wfs(wf).f0 param.radar.wfs(wf).f1];
  param.radar.wfs(wf).ft_dec = [1 1];
  param.radar.wfs(wf).Tpd = 1e-6;
  param.radar.wfs(wf).tukey = 0.1;
  param.radar.wfs(wf).system_dB = 0;
  param.radar.wfs(wf).rx_paths = [1 2 1 2];
  param.radar.wfs(wf).adc_gains_dB = [4 50 4 50]; % ADC gain
  param.radar.wfs(wf).chan_equal_dB = [0 0 0 0];
  param.radar.wfs(wf).chan_equal_deg = [0 0 0 0];
  param.radar.wfs(wf).Tsys = [0 0 0 0];
  param.radar.wfs(wf).presums = 32;
  param.radar.wfs(wf).bit_shifts = [0 0 0 0];
  param.radar.wfs(wf).Tadc_adjust = -1.2e-6;
  param.radar.wfs(wf).Tadc = 0;
  param.radar.wfs(wf).gain_en = [0 0 0 0]; % Disable fast-time gain correction
  param.radar.wfs(wf).coh_noise_method = ''; % No coherent noise removal
end

%% Post worksheet
param.post.data_dirs = {'qlook'};
param.post.img = 0;
param.post.layer_dir = 'layerData';
param.post.maps_en = 1;
param.post.echo_en = 1;
param.post.layers_en = 0;
param.post.data_en = 0;
param.post.csv_en = 1;
param.post.concat_en = 1;
param.post.pdf_en = 1;
param.post.map.location = 'Antarctica';
param.post.map.type = 'combined';
param.post.echo.elev_comp = 2;
param.post.echo.depth = '[min(Surface_Depth)-100 max(Surface_Depth)+3500]';
% param.post.echo.elev_comp = 3;
% param.post.echo.depth = '[min(Surface_Elev)-1500 max(Surface_Elev)+100]';
param.post.echo.er_ice = 3.15;
param.post.ops.location = 'antarctic';

%% Analysis worksheet
param.analysis_noise.block_size = 10000;
cmd_idx = 0;
cmd_idx = cmd_idx + 1;
param.analysis_noise.cmd{cmd_idx}.method = 'coh_noise';
param.analysis_noise.cmd{cmd_idx}.distance_weight = 1; % Enable distance weighting of the average

%% Radar Settings

defaults = {};

% Survey Mode Thick Ice
default.records.arena.total_presums = 32;
default.qlook.img_comb = [4e-06 -inf 1e-06];
default.qlook.imgs = {[ones(2,1) [1 3].'],[ones(2,1) [2 4].']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.analysis_noise.imgs = default.qlook.imgs;
default.radar.ref_fn = '';
default.radar.wfs = param.radar.wfs(1:1);
default.post.echo.depth = '[min(Surface_Depth)-5 max(Surface_Depth)+4200]';
default.config_regexp = 'survey';
default.name = 'Survey Mode 52.5-67.5 MHz Thick Ice';
defaults{end+1} = default;

