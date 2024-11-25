function [param,defaults] = default_radar_params_2018_Greenland_P3_snow
% [param,defaults] = default_radar_params_2018_Greenland_P3_snow
%
% Snow: 2018_Greenland_P3
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Author: John Paden

%% Preprocess parameters
param.season_name = '2018_Greenland_P3';
param.radar_name = 'snow8';

param.config.max_time_gap = 10;
param.config.min_seg_size = 2;

param.config.daq_type = 'cresis';
param.config.wg_type = 'cresis';
param.config.header_load_func = @basic_load_fmcw8;
param.config.board_map = {''};
param.config.tx_map = {''};

param.config.daq.xml_version = -1; % No XML file available

param.config.tx_enable = [1];

%% CReSIS parameters
param.config.cresis.clk = 125e6;

%% Command worksheet
param.cmd.records = 1;
param.cmd.qlook = 1;
param.cmd.generic = 1;

%% Records worksheet
param.records.file.boards = {''};
param.records.file.version = 8;
param.records.file.prefix = param.radar_name;
param.records.file.suffix = '.bin';
param.records.file.clk = 125000000;
param.records.frames.geotiff_fn = 'greenland/Landsat-7/Greenland_natural_150m.tif';
param.records.frames.mode = 2;
param.records.gps.en = 1;
param.records.gps.time_offset = 1;

%% Qlook worksheet
param.qlook.img_comb = [];
param.qlook.imgs = {[1 1]};
param.qlook.out_path = '';
param.qlook.block_size = 2000;
param.qlook.motion_comp = 0;
param.qlook.dec = 4;
param.qlook.inc_dec = 5;
param.qlook.surf.en = 1;
param.qlook.surf.min_bin = 1e-6;
param.qlook.surf.method = 'threshold';
param.qlook.surf.threshold = 17;
param.qlook.surf.filter_len = 7;
param.qlook.surf.sidelobe = 19;
param.qlook.surf.max_diff = 1.2e-7;
param.qlook.surf.noise_rng = [100 -700 -300];
param.qlook.surf.search_rng = [0:9];

%% SAR worksheet
param.sar.out_path = '';
param.sar.imgs = param.qlook.imgs;
param.sar.frm_types = {0,[0 1],0,0,-1};
param.sar.chunk_len = 2000;
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
param.sar.sigma_x = 1;
param.sar.sub_aperture_steering = 0;
param.sar.st_wind = @hanning;
param.sar.start_eps = 3.15;

%% Array worksheet
param.array.in_path = '';
param.array.array_path = '';
param.array.out_path = '';
param.array.imgs = param.qlook.imgs;
param.array.img_comb = param.qlook.img_comb;
param.array.method = 'standard';
param.array.window = @hanning;
param.array.bin_rng = 0;
param.array.rline_rng = -5:5;
param.array.dbin = 1;
param.array.dline = 6;
param.array.DCM = [];
param.array.Nsv = 1;
param.array.theta_rng = [0 0];
param.array.sv_fh = @array_proc_sv;
param.array.diag_load = 0;
param.array.Nsig = 2;

%% Radar worksheet
param.radar.prf = 1/256e-6;
param.radar.fs = 250e6;
param.radar.adc_bits = 14;
param.radar.Vpp_scale = 2; % Digital receiver gain is 5, full scale Vpp is 2
param.radar.Tadc_adjust = []; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple
param.radar.lever_arm_fh = @lever_arm;
chan_equal_Tsys = [0]/1e9;
chan_equal_dB = [0];
chan_equal_deg = [0];
for wf = 1:1
  param.radar.wfs(wf).tx_weights = 1; % Watts
  param.radar.wfs(wf).adc_gains_dB = 95.8; % Radiometric calibration to 1/R^2
  param.radar.wfs(wf).rx_paths = [1]; % ADC to rx path mapping
  param.radar.wfs(wf).ref_fn = '';
  param.radar.wfs(wf).chan_equal_Tsys = chan_equal_Tsys;
  param.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
  param.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
  param.radar.wfs(wf).adcs = [1];
  param.radar.wfs(wf).nz_trim = {[0 0],[0 2],[0 0],[0 0]};
  param.radar.wfs(wf).nz_valid = [0 1 2 3];
end

%% Post worksheet
param.post.data_dirs = {'qlook'};
param.post.layer_dir = 'layerData';
param.post.maps_en = 1;
param.post.echo_en = 1;
param.post.layers_en = 0;
param.post.data_en = 0;
param.post.csv_en = 1;
param.post.concat_en = 1;
param.post.pdf_en = 1;
param.post.map.location = 'Greenland';
param.post.map.type = 'combined';
param.post.echo.elev_comp = 2;
param.post.echo.depth = '[min(Surface_Depth)-2 max(Surface_Depth)+25]';
% param.post.echo.elev_comp = 3;
% param.post.echo.depth = '[min(Surface_Elev)-25 max(Surface_Elev)+2]';
param.post.echo.er_ice = round((1+0.51*0.3)^3 * 100)/100;
param.post.ops.location = 'arctic';
  
%% Radar Settings

defaults = {};

default = param;

% Survey Mode 2-18 GHz
default.radar.wfs(1).f0 = 2e9;
default.radar.wfs(1).f1 = 18e9;
default.radar.wfs(1).Tpd = 240e-6;
default.radar.wfs(1).BW_window = [2.7e9 17.5e9];
default.radar.wfs(1).t_ref = -0.000000040063;

default.config_regexp = '.*';
default.name = 'Survey Mode 2-18 GHz';
defaults{end+1} = default;

% Survey Mode 2-8 GHz
default.radar.wfs(1).f0 = 2e9;
default.radar.wfs(1).f1 = 18e9;
default.radar.wfs(1).Tpd = 240e-6;
default.radar.wfs(1).BW_window = [2.7e9 17.5e9];
default.radar.wfs(1).t_ref = -0.000000040063;

default.config_regexp = '.*';
default.name = 'Survey Mode 2-8 GHz';
defaults{end+1} = default;

% Survey Mode 2-14 GHz, dual waveform
default.radar.wfs(1).f0 = 2e9;
default.radar.wfs(1).f1 = 14e9;
default.radar.wfs(1).Tpd = 200e-6;
default.radar.wfs(1).BW_window = [2.7e9 13.5e9];
default.radar.wfs(1).t_ref = -0.000000040063;

default.config_regexp = '.*';
default.name = 'Survey Mode 2-14 GHz Dual Waveform';
defaults{end+1} = default;
