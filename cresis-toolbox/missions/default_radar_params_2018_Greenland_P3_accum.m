function [param,defaults] = default_radar_params_2018_Greenland_P3_accum
% [param,defaults] = default_radar_params_2018_Greenland_P3_accum
%
% Accum: 2018 Greenland P3
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Author: John Paden

%% Preprocess parameters
param.season_name = '2018_Greenland_P3';
param.radar_name = 'mcords5-accum';

param.config.file.version = 407;
param.config.file.prefix = 'mcords5';
param.config.file.suffix = '.bin';
param.config.max_time_gap = 10;
param.config.min_seg_size = 2;

param.config.daq_type = 'cresis';
param.config.wg_type = 'arena';
param.config.header_load_func = @basic_load_mcords5;
param.config.board_map = {'chan1'};
param.config.tx_map = {'awg4','awg5','awg6','awg7'};

param.config.daq.xml_version = 2.0;

param.config.max_data_rate = 100;
param.config.max_duty_cycle = 0.12;
param.config.prf_multiple = []; % Power supply sync signal that PRF must be a factor of these numbers
param.config.PRI_guard = 10e-6;
param.config.PRI_guard_percentage = 1;
param.config.tx_enable = [1 0 0 0];
param.config.max_tx = 0.7*[1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0];
param.config.max_tx_voltage = sqrt(400*50)*10^(-2/20); % voltage at max_tx

%% CReSIS Parameters
param.config.cresis.clk = 1.6e9/8;
param.config.cresis.rx_gain_dB = 45;

%% BAS ACCUM Arena Parameters
arena = [];
arena.clk = 10e6;
fs_dac = 2400e6;
subsystem_idx = 0;
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'ARENA-CTU';
arena.subsystem(subsystem_idx).subSystem{1} = 'ctu';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'ARENA2';
arena.subsystem(subsystem_idx).subSystem{1} = 'awg4';
arena.subsystem(subsystem_idx).subSystem{2} = 'awg5';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'ARENA3';
arena.subsystem(subsystem_idx).subSystem{1} = 'awg6';
arena.subsystem(subsystem_idx).subSystem{2} = 'awg7';

dac_idx = 0;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg4';
arena.dac(dac_idx).type = 'dac-ad9129_0012';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = 13;
arena.dac(dac_idx).desiredAlignMax = 27;
arena.dac(dac_idx).dcoPhase = 80;
arena.dac(dac_idx).name = 'awg5';
arena.dac(dac_idx).type = 'dac-ad9129_0012';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = 8;
arena.dac(dac_idx).desiredAlignMax = 22;
arena.dac(dac_idx).dcoPhase = 80;
arena.dac(dac_idx).name = 'awg6';
arena.dac(dac_idx).type = 'dac-ad9129_0012';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = 9;
arena.dac(dac_idx).desiredAlignMax = 23;
arena.dac(dac_idx).dcoPhase = 80;
arena.dac(dac_idx).name = 'awg7';
arena.dac(dac_idx).type = 'dac-ad9129_0012';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = 24;
arena.dac(dac_idx).desiredAlignMax = 38;
arena.dac(dac_idx).dcoPhase = 80;

adc_idx = 0;

daq_idx = 0;

arena.system.name = 'ku0001';

arena.param.tx_max = [1 1];
arena.param.PA_setup_time = 2e-6; % Time required to enable PA before transmit
arena.param.TTL_time_delay = 0.0; % TTL time delay relative to transmit start

arena.psc.type = 'psc_0003';

arena.ctu.name = 'ctu';
arena.ctu.type = 'ctu_001D';
arena.ctu.nmea = 31;
arena.ctu.pps = 10;
arena.ctu.pps_polarity = 1;
idx = 0;
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'test';
arena.ctu.out.bit_group(idx).bits = 0;
arena.ctu.out.bit_group(idx).epri = [0 1 0 0];
arena.ctu.out.bit_group(idx).pri = [0 1 0 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'EPRI';
arena.ctu.out.bit_group(idx).bits = 1;
arena.ctu.out.bit_group(idx).epri = [1 0 0 0];
arena.ctu.out.bit_group(idx).pri = [1 0 0 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'PRI';
arena.ctu.out.bit_group(idx).bits = 2;
arena.ctu.out.bit_group(idx).epri = [0 1 0 0];
arena.ctu.out.bit_group(idx).pri = [0 1 0 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'PA_ENA';
arena.ctu.out.bit_group(idx).bits = 3;
arena.ctu.out.bit_group(idx).epri = [1 1 1 0];
arena.ctu.out.bit_group(idx).pri = [1 1 1 0];

arena.ctu.out.time_cmd = {'2e-6' '2.1e-6' '2.1e-6+param.wfs(wf).Tpd+0.3e-6' '2/param.prf'};

param.config.arena = arena;

%% Command worksheet
default.cmd.records = 1;
default.cmd.qlook = 1;
default.cmd.generic = 1;

%% Records worksheet
default.records.file.adcs = 1;
default.records.frames.geotiff_fn = 'greenland/Landsat-7/Greenland_natural_150m';
default.records.frames.mode = 2;
default.records.gps.en = 1;
default.records.gps.time_offset = 1;
default.records.presum_mode = 0;

%% Qlook worksheet
default.qlook.out_path = '';
default.qlook.en = 1;
default.qlook.block_size = 5000;
default.qlook.frm_types = {0,[0 1],0,0,-1};
default.qlook.coh_noise_method = [];
default.qlook.coh_noise_arg = [];
default.qlook.ft_wind = @hanning;
default.qlook.ft_wind_time = false;
default.qlook.ft_dec = true;
default.qlook.pulse_comp = [];
default.qlook.pulse_rfi.en = [];
default.qlook.pulse_rfi.inc_ave= [];
default.qlook.pulse_rfi.thresh_scale = [];
default.qlook.roll_correction = 0;
default.qlook.lever_arm_fh = @lever_arm;
default.qlook.elev_correction = 0;
default.qlook.B_filter = ones(1,20)/20;
default.qlook.decimate_factor = 20;
default.qlook.inc_ave = 10;
default.qlook.surf.en = 1;
default.qlook.surf.method = 'threshold';
default.qlook.surf.noise_rng = [0 -50 10];
default.qlook.surf.min_bin = 2e-6;
default.qlook.surf.max_bin = [];
default.qlook.surf.threshold = 9;
default.qlook.surf.sidelobe = 15;
default.qlook.surf.medfilt = 3;
default.qlook.surf.search_rng = [0:2];

%% SAR worksheet
default.sar.out_path = '';
default.sar.imgs = {[1 1],[2 1]};
default.sar.frm_types = {0,[0 1],0,0,-1};
default.sar.chunk_len = 5000;
default.sar.chunk_overlap = 10;
default.sar.frm_overlap = 0;
default.sar.coh_noise_removal = 0;
default.sar.combine_rx = 0;
default.sar.time_of_full_support = inf;
default.sar.pulse_rfi.en = [];
default.sar.pulse_rfi.inc_ave= [];
default.sar.pulse_rfi.thresh_scale = [];
default.sar.trim_vals = [];
default.sar.pulse_comp = 1;
default.sar.ft_dec = 1;
default.sar.ft_wind = @hanning;
default.sar.ft_wind_time = 0;
default.sar.lever_arm_fh = @lever_arm;
default.sar.mocomp.en = 1;
default.sar.mocomp.type = 2;
default.sar.mocomp.filter = {@butter  [2]  [0.1000]};
default.sar.mocomp.uniform_en = 1;
default.sar.sar_type = 'f-k';
default.sar.sigma_x = 2.5;
default.sar.sub_aperture_steering = 0;
default.sar.st_wind = @hanning;
default.sar.start_eps = 3.15;

%% Array worksheet
default.array.in_path = '';
default.array.array_path = '';
default.array.out_path = '';
default.array.method = 'standard';
default.array.window = @hanning;
default.array.bin_rng = 0;
default.array.rline_rng = -5:5;
default.array.dbin = 1;
default.array.dline = 6;
default.array.DCM = [];
default.array.Nsv = 1;
default.array.theta_rng = [0 0];
default.array.sv_fh = @array_proc_sv;
default.array.diag_load = 0;
default.array.Nsig = 2;

%% Radar worksheet
default.radar.fs = 1600e6;
default.radar.Tadc = []; % normally leave empty to use value in file header
default.radar.adc_bits = 12;
default.radar.adc_full_scale = 2;
default.radar.noise_figure = 2;
default.radar.adc_SNR_dB = 59;

%% Post worksheet
default.post.data_dirs = {'qlook'};
default.post.layer_dir = 'layerData';
default.post.maps_en = 1;
default.post.echo_en = 1;
default.post.layers_en = 0;
default.post.data_en = 0;
default.post.csv_en = 1;
default.post.concat_en = 1;
default.post.pdf_en = 1;
default.post.map.location = 'Greenland';
default.post.map.type = 'combined';
default.post.echo.elev_comp = 2;
default.post.echo.depth = '[min(Surface_Depth)-20 max(Surface_Depth)+200]';
% default.post.echo.elev_comp = 3;
% default.post.echo.depth = '[min(Surface_Elev)-200 max(Surface_Elev)+20]';
default.post.echo.er_ice = 3.15;
default.post.ops.location = 'arctic';
  
%% Radar Settings

defaults = {};

% survey mode
default.qlook.img_comb = [1e-06 -inf 2e-06];
default.qlook.imgs = {[1 1],[2 1]};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'survey_600-900MHz_.*.xml';
default.name = 'Survey Mode 600-900 MHz';
for wf = 1:2
  default.radar.wfs(wf).rx_paths = [1:4];
  default.radar.wfs(wf).Tadc_adjust = 6.95E-06; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple
  default.radar.wfs(wf).chan_equal_Tsys = [0.15	0.00	0.10	0.68]/1e9;
  default.radar.wfs(wf).chan_equal_dB = [0 0 0 0];
  default.radar.wfs(wf).chan_equal_deg = [-105.5	-0.0	55.2	128.8];
end
defaults{end+1} = default;

% Other settings
default.qlook.img_comb = [];
default.qlook.imgs = {[1 1],[2 1]};
default.sar.imgs = {[1 1],[2 1]};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = '.*';
default.name = 'Default 600-900 MHz';
for wf = 1:2
  default.radar.wfs(wf).rx_paths = [1:4];
  default.radar.wfs(wf).Tadc_adjust = 6.95E-06; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple
  default.radar.wfs(wf).chan_equal_Tsys = [0.15	0.00	0.10	0.68]/1e9;
  default.radar.wfs(wf).chan_equal_dB = [0 0 0 0];
  default.radar.wfs(wf).chan_equal_deg = [-105.5	-0.0	55.2	128.8];
end
defaults{end+1} = default;

%% Add default settings

param.config.defaults = defaults;
