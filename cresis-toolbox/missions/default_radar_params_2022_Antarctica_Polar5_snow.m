function [param,defaults] = default_radar_params_2022_Antarctica_Polar5_snow
% [param,defaults] = default_radar_params_2022_Antarctica_Polar5_snow
%
% Snow: 2022_Antarctica_Polar5
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Author: John Paden

%% Preprocess parameters
param.season_name = '2022_Antarctica_Polar5';
param.radar_name = 'snow5';

param.config.max_time_gap = 10;
param.config.min_seg_size = 2;

param.config.daq_type = 'cresis';
param.config.wg_type = 'cresis';
param.config.header_load_func = @basic_load;
% param.config.board_map = {'chan1'};
param.config.tx_map = {'',''};

param.config.daq.xml_version = -1; % No XML file available

param.config.tx_enable = [1];

%% CReSIS parameters
param.config.cresis.clk = 125e6;
param.config.cresis.expected_rec_sizes = [30288 60480      120864      181296];

%% Command worksheet
param.cmd.records = 1;
param.cmd.qlook = 1;
param.cmd.generic = 1;

%% Records worksheet
param.records.file.boards = {'chan1','chan2'};
param.records.file.clk = 125e6;
param.records.file.prefix = param.radar_name;
param.records.file.suffix = '.bin';
param.records.file.version = 7;
%param.records.frames.geotiff_fn = 'arctic/NaturalEarth_Data/Arctic_NaturalEarth.tif';
param.records.frames.geotiff_fn = 'antarctica\NaturalEarth_Data\Antarctica_NaturalEarth.tif';
param.records.frames.mode = 2;
param.records.gps.en = 1;
param.records.gps.time_offset = 1;

%% Qlook worksheet
param.qlook.img_comb = [];
param.qlook.imgs = {[2 1],[1 1],[1 2],[2 2]};
% param.qlook.imgs = {[2 1],[1 1]};
param.qlook.out_path = '';
param.qlook.block_size = 2000;
param.qlook.motion_comp = 0;
param.qlook.dec = 4;
param.qlook.inc_dec = 5;
param.qlook.surf.en = 1;
param.qlook.surf.profile = 'snow_AWI';

%% SAR worksheet
param.sar.out_path = '';
param.sar.imgs = param.qlook.imgs;
param.sar.frm_types = {0,[0 1],0,0,-1};
param.sar.chunk_len = 500;
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
param.sar.start_eps = 1.53;

%% Array worksheet
param.array.in_path = '';
param.array.array_path = '';
param.array.out_path = '';
param.array.imgs = param.qlook.imgs;
param.array.img_comb = param.qlook.img_comb;
param.array.method = 'standard';
param.array.window = @hanning;
param.array.bin_rng = 0;
param.array.line_rng = -2:2;
param.array.dbin = 1;
param.array.dline = 5;
param.array.DCM = [];
param.array.Nsv = 1;
param.array.theta_rng = [0 0];
param.array.sv_fh = @array_proc_sv;
param.array.diag_load = 0;
param.array.Nsig = 2;

%% Radar worksheet
param.radar.prf = 1/256e-6;
param.radar.fs = 125e6;
param.radar.adc_bits = 14;
param.radar.Vpp_scale = 2; % Digital receiver gain is 5, full scale Vpp is 2
param.radar.Tadc_adjust = []; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple
param.radar.lever_arm_fh = @lever_arm;
chan_equal_Tsys = [0]/1e9;
chan_equal_dB = [0];
chan_equal_deg = [0];
param.radar.wfs(1).tx_weights = [0.1 0]; % Watts
param.radar.wfs(2).tx_weights = [0 0.1]; % Watts
for wf = 1:2
  param.radar.wfs(wf).fmult = 16;
  param.radar.wfs(wf).prepulse_H.type = 'NI_DDC_2019';
  %param.radar.wfs(wf).coh_noise_method = 'analysis'; % Post-processing
  param.radar.wfs(wf).coh_noise_method = 'estimated'; % Field processing
  %param.radar.wfs(wf).coh_noise_method = ''; % Lab data
  param.radar.wfs(wf).fLO = -20e9;
  param.radar.wfs(wf).adc_gains_dB = [95.8 95.8]; % Radiometric calibration to 1/R^2
  param.radar.wfs(wf).rx_paths = [1 2]; % ADC to rx path mapping
  param.radar.wfs(wf).ref_fn = '';
  param.radar.wfs(wf).chan_equal_Tsys = chan_equal_Tsys;
  param.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
  param.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
  param.radar.wfs(wf).nz_trim = {[100 100],[0 0],[0 0],[0 0]};
end

%% Post worksheet
param.post.data_dirs = {'qlook'};
param.post.layer_dir = 'layerData';
param.post.maps_en = 0;
param.post.echo_en = 1;
param.post.layers_en = 0;
param.post.data_en = 0;
param.post.csv_en = 0;
param.post.concat_en = 0;
param.post.pdf_en = 0;
param.post.map.location = 'Antarctic';
param.post.map.type = 'contour';
param.post.echo.elev_comp = 3;
param.post.echo.depth = '[min(Surface_Elev)-2.5 max(Surface_Elev)+4]';
% param.post.echo.elev_comp = 3;
% param.post.echo.depth = '[min(Surface_Elev)-25 max(Surface_Elev)+2]';
param.post.echo.er_ice = round((1+0.51*0.3)^3 * 100)/100;
param.post.ops.location = 'arctic';

%% Add default settings

% Initialize the list of default settings
defaults = {};

% Create a default setting
default = param;
  
%% Radar Settings

% Survey Mode 2-18 GHz
for wf = 1:2
  default.radar.wfs(wf).f1 = 2.375e9;
  default.radar.wfs(wf).f0 = 1.375e9;
  default.radar.wfs(wf).Tpd = 240e-6;
  %default.radar.wfs(wf).BW_window = [2.5e9 17.493e9];
  default.radar.wfs(wf).BW_window = [2798933333.33 16947200000];
  default.radar.wfs(wf).t_ref = -0.000000040063;
end

default.config_regexp = '.*';
default.name = 'Survey Mode 2-18 GHz';

% Add the default setting to the list of default settings
defaults{end+1} = default;

