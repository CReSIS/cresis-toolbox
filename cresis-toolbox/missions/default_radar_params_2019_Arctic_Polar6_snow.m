function param = default_radar_params_2019_Arctic_Polar6_snow
% param = default_radar_params_2019_Arctic_Polar6_snow
%
% Snow: 2019_Arctic_Polar6
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Author: John Paden

%% Preprocess parameters
% param.season_name = '2019_Arctic_Polar6';
param.season_name = '2020_Arctic_Polar6';
param.radar_name = 'snow5';

param.config.file.version = 7;
param.config.file.prefix = param.radar_name;
param.config.file.suffix = '.bin';
param.config.max_time_gap = 10;
param.config.min_seg_size = 2;

param.config.daq_type = 'cresis';
param.config.wg_type = 'cresis';
param.config.header_load_func = @basic_load;
param.config.board_map = {'chan1','chan2'};
% param.config.board_map = {'chan1'};
param.config.tx_map = {'',''};

param.config.daq.xml_version = -1; % No XML file available

param.config.tx_enable = [1];

%% CReSIS parameters
param.config.cresis.clk = 125e6;
param.config.cresis.expected_rec_sizes = [30288 60480      120864      181296];

%% Command worksheet
default.cmd.records = 1;
default.cmd.qlook = 1;
default.cmd.generic = 1;

%% Records worksheet
default.records.frames.geotiff_fn = 'arctic/NaturalEarth_Data/Arctic_NaturalEarth.tif';
default.records.frames.mode = 2;
default.records.gps.en = 1;
default.records.gps.time_offset = 1;

%% Qlook worksheet
default.qlook.img_comb = [];
default.qlook.imgs = {[2 1],[1 1],[1 2],[2 2]};
% default.qlook.imgs = {[2 1],[1 1]};
default.qlook.out_path = '';
default.qlook.block_size = 2000;
default.qlook.motion_comp = 0;
default.qlook.dec = 4;
default.qlook.inc_dec = 5;
default.qlook.surf.en = 1;
default.qlook.surf.profile = 'snow_AWI';

%% SAR worksheet
default.sar.out_path = '';
default.sar.imgs = default.qlook.imgs;
default.sar.frm_types = {0,[0 1],0,0,-1};
default.sar.chunk_len = 500;
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
default.sar.sar_type = 'fk';
default.sar.sigma_x = 1;
default.sar.sub_aperture_steering = 0;
default.sar.st_wind = @hanning;
default.sar.start_eps = 1.53;

%% Array worksheet
default.array.in_path = '';
default.array.array_path = '';
default.array.out_path = '';
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.array.method = 'standard';
default.array.window = @hanning;
default.array.bin_rng = 0;
default.array.line_rng = -2:2;
default.array.dbin = 1;
default.array.dline = 5;
default.array.DCM = [];
default.array.Nsv = 1;
default.array.theta_rng = [0 0];
default.array.sv_fh = @array_proc_sv;
default.array.diag_load = 0;
default.array.Nsig = 2;

%% Radar worksheet
default.radar.prf = 1/256e-6;
default.radar.fs = 125e6;
default.radar.adc_bits = 14;
default.radar.Vpp_scale = 2; % Digital receiver gain is 5, full scale Vpp is 2
default.radar.Tadc_adjust = []; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple
default.radar.lever_arm_fh = @lever_arm;
chan_equal_Tsys = [0]/1e9;
chan_equal_dB = [0];
chan_equal_deg = [0];
default.radar.wfs(1).tx_weights = [0.1 0]; % Watts
default.radar.wfs(2).tx_weights = [0 0.1]; % Watts
for wf = 1:2
  default.radar.wfs(wf).fmult = 16;
  default.radar.wfs(wf).prepulse_H.type = 'NI_DDC_2019';
  %default.radar.wfs(wf).coh_noise_method = 'analysis'; % Post-processing
  default.radar.wfs(wf).coh_noise_method = 'estimated'; % Field processing
  %default.radar.wfs(wf).coh_noise_method = ''; % Lab data
  default.radar.wfs(wf).fLO = -20e9;
  default.radar.wfs(wf).adc_gains_dB = [95.8 95.8]; % Radiometric calibration to 1/R^2
  default.radar.wfs(wf).rx_paths = [1 2]; % ADC to rx path mapping
  default.radar.wfs(wf).ref_fn = '';
  default.radar.wfs(wf).chan_equal_Tsys = chan_equal_Tsys;
  default.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
  default.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
  default.radar.wfs(wf).nz_trim = {[100 100],[0 0],[0 0],[0 0]};
end

%% Post worksheet
default.post.data_dirs = {'qlook'};
default.post.layer_dir = 'layerData';
default.post.maps_en = 0;
default.post.echo_en = 1;
default.post.layers_en = 0;
default.post.data_en = 0;
default.post.csv_en = 0;
default.post.concat_en = 0;
default.post.pdf_en = 0;
default.post.map.location = 'Arctic';
default.post.map.type = 'contour';
default.post.echo.elev_comp = 3;
default.post.echo.depth = '[min(Surface_Elev)-2.5 max(Surface_Elev)+4]';
% default.post.echo.elev_comp = 3;
% default.post.echo.depth = '[min(Surface_Elev)-25 max(Surface_Elev)+2]';
default.post.echo.er_ice = round((1+0.51*0.3)^3 * 100)/100;
default.post.ops.location = 'arctic';
  
%% Radar Settings

defaults = {};

% Survey Mode 2-18 GHz
for wf = 1:2
  default.radar.wfs(wf).f1 = 2.375e9;
  default.radar.wfs(wf).f0 = 1.375e9;
  default.radar.wfs(wf).Tpd = 240e-6;
  default.radar.wfs(wf).BW_window = [2.5e9 17.493e9];
  default.radar.wfs(wf).t_ref = -0.000000040063;
end

default.config_regexp = '.*';
default.name = 'Survey Mode 2-18 GHz';
defaults{end+1} = default;

%% Add default settings

param.config.defaults = defaults;
