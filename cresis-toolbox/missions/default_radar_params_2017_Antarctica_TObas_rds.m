function param = default_radar_params_2017_Antarctica_TObas_rds
% param = default_radar_params_2017_Antarctica_TObas_rds
%
% RDS: 2017_Antarctica_TObas
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Author: John Paden

%% Preprocess parameters
param.season_name = '2017_Antarctica_TObas';
param.radar_name = 'rds';

param.config.daq_type = 'bas';
param.config.header_load_func = @load;
param.config.board_map = {''};

param.config.file.version = 414;
param.config.max_time_gap = 10;
param.config.min_seg_size = 1;

%% Command worksheet
default.cmd.records = 1;
default.cmd.qlook = 1;
default.cmd.generic = 1;

%% Records worksheet
default.records.gps.time_offset = 0;
default.records.frames.geotiff_fn = 'antarctica/Landsat-7/Antarctica_LIMA_480m.tif';
default.records.frames.mode = 1;

%% Qlook worksheet
default.qlook.out_path = '';
default.qlook.block_size = 5000;
default.qlook.motion_comp = 0;
default.qlook.dec = 20;
default.qlook.inc_dec = 10;
default.qlook.surf.en = 1;
default.qlook.surf.profile = 'RDS_OIB';

%% SAR worksheet
default.sar.out_path = '';
default.sar.chunk_len = 5000;
default.sar.combine_rx = 0;
default.sar.time_of_full_support = inf;
default.sar.mocomp.en = 1;
default.sar.mocomp.type = 2;
default.sar.mocomp.filter = {@butter  [2]  [0.1000]};
default.sar.mocomp.uniform_en = 1;
default.sar.sar_type = 'fk';
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
default.array.line_rng = -5:5;
default.array.dbin = 1;
default.array.dline = 6;
default.array.DCM = [];
default.array.Nsv = 1;
default.array.theta_rng = [0 0];
default.array.sv_fh = @array_proc_sv;
default.array.diag_load = 0;
default.array.Nsig = 2;

%% Radar worksheet
default.radar.fs = 120e6;
default.radar.Tadc = []; % normally leave empty to use value in file header
default.radar.adc_bits = 14;
default.radar.Vpp_scale = 2;
default.radar.lever_arm_fh = @lever_arm;

default.radar.wfs.rx_paths = [1:12]; % ADC to rx path mapping
default.radar.wfs.noise_figure = 2;
default.radar.wfs.Tadc_adjust = 0; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple

default.radar.wfs(1).Tsys = [0 0 0 0 0 0 0 0 0 0 0 0]/1e9;
default.radar.wfs(1).chan_equal_dB = [0 0 0 0 0 0 0 0 0 0 0 0];
default.radar.wfs(1).chan_equal_deg = [0 0 0 0 0 0 0 0 0 0 0 0];

default.radar.adc_bits = 14;
default.radar.fs = 120e6;
default.radar.prf = 15625;
default.radar.Vpp_scale = 2;
default.radar.Tadc_adjust = 0; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple
default.radar.lever_arm_fh = @lever_arm;
for wf = 1:5
  default.radar.wfs(wf).f0 = 143.5e6;
  default.radar.wfs(wf).f1 = 156.5e6;
  default.radar.wfs(wf).rx_paths = [1:12]; % ADC to rx path mapping
  default.radar.wfs(wf).presums = 25;
end
default.radar.wfs(1).Tpd = 1e-6;
default.radar.wfs(2).Tpd = 4e-6;
default.radar.wfs(3).Tpd = 4e-6;
default.radar.wfs(4).Tpd = 4e-6;
default.radar.wfs(5).Tpd = 4e-6;
for adc = 1:12
  default.radar.wfs(2).wf_adc_sum{adc} = [2 adc 0.5; 3 adc -0.5];
  default.radar.wfs(4).wf_adc_sum{adc} = [4 adc 0.5; 5 adc -0.5];
end
default.radar.wfs(1).adc_gains_dB = 27*ones(1,12); % Gain from the first LNA to the ADC
default.radar.wfs(2).adc_gains_dB = 45*ones(1,12); % Gain from the first LNA to the ADC
default.radar.wfs(3).adc_gains_dB = 45*ones(1,12); % Gain from the first LNA to the ADC
default.radar.wfs(4).adc_gains_dB = 45*ones(1,12); % Gain from the first LNA to the ADC
default.radar.wfs(5).adc_gains_dB = 45*ones(1,12); % Gain from the first LNA to the ADC
default.radar.wfs(1).tx_weights = [2000 2000 2000 2000 0 0 0 0 0 0 0 0];
default.radar.wfs(2).tx_weights = [2000 2000 2000 2000 0 0 0 0 0 0 0 0];
default.radar.wfs(3).tx_weights = [2000 2000 2000 2000 0 0 0 0 0 0 0 0];
default.radar.wfs(4).tx_weights = [0 0 0 0 0 0 0 0 2000 2000 2000 2000];
default.radar.wfs(5).tx_weights = [0 0 0 0 0 0 0 0 2000 2000 2000 2000];

Tsys = [0 0 0 0 0 0 0 0 0 0 0 0]/1e9;
chan_equal_dB = [0 0 0 0 0 0 0 0 0 0 0 0];
chan_equal_deg = [0 0 0 0 0 0 0 0 0 0 0 0];

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
default.post.map.location = 'Antarctica';
default.post.map.type = 'combined';
default.post.echo.elev_comp = 2;
default.post.echo.depth = '[min(Surface_Depth)-100 max(Surface_Depth)+1500]';
% default.post.echo.elev_comp = 3;
% default.post.echo.depth = '[min(Surface_Elev)-1500 max(Surface_Elev)+100]';
default.post.echo.er_ice = 3.15;
default.post.ops.location = 'antarctic';

%% Radar Settings

defaults = {};

% Survey Mode
default.qlook.img_comb = [4e-06 -inf 1e-06];
default.qlook.imgs = {[1*ones(4,1),(1:4).'],[2*ones(4,1),(1:4).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.ref_fn = '';
for wf = 1:5
  default.radar.wfs(wf).Tsys = Tsys;
  default.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
  default.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
end
default.config_regexp = '.*';
default.name = 'Survey Mode 143.5-156.5 MHz';
defaults{end+1} = default;

%% Add default settings

param.config.defaults = defaults;
