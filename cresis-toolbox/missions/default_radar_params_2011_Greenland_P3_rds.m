function param = default_radar_params_2011_Greenland_P3_rds
% param = default_radar_params_2011_Greenland_P3_rds
%
% RDS: 2011_Greenland_P3
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Author: John Paden

%% Preprocess parameters
param.season_name = '2011_Greenland_P3';
param.radar_name = 'mcords3';

param.config.file.version = 402;
param.config.file.prefix = param.radar_name;
param.config.file.suffix = '.bin';
param.config.max_time_gap = 10;
param.config.min_seg_size = 2;

param.config.daq_type = 'cresis';
param.config.wg_type = 'cresis';
param.config.header_load_func = @basic_load_mcords2;
param.config.board_map = {'board0','board1','board2','board3'};
param.config.tx_map = {'','','','','','','',''};

param.config.daq.xml_version = 1.0;

param.config.max_data_rate = 100;
param.config.max_duty_cycle = 0.12;
param.config.prf_multiple = []; % Power supply sync signal that PRF must be a factor of these numbers
param.config.PRI_guard = 10e-6;
param.config.PRI_guard_percentage = 1;
param.config.tx_enable = [1 1 1 1 1 1 1 0];
param.config.max_tx = 40000;
param.config.max_tx_voltage = sqrt(250*50)*10^(-2/20); % voltage at max_tx

%% CReSIS parameters
param.config.cresis.clk = 1e9/9;
param.config.cresis.rx_gain_dB = 51.5;
param.config.cresis.gps_file_mask = 'GPS*';

%% Command worksheet
default.cmd.records = 1;
default.cmd.qlook = 1;
default.cmd.generic = 1;

%% Records worksheet
default.records.gps.time_offset = 1;
default.records.file.adcs = [2:16];
default.records.frames.mode = 1;
default.records.frames.geotiff_fn = 'greenland\Landsat-7\mzl7geo_90m_lzw.tif';
default.records.presum_mode = 1;

%% Qlook worksheet
default.qlook.out_path = '';
default.qlook.en = 1;
default.qlook.block_size = 10000;
default.qlook.dec = 50;
default.qlook.inc_dec = 10;
default.qlook.surf.en = 1;
default.qlook.surf.method = 'threshold';
default.qlook.surf.noise_rng = [0 -50 10];
default.qlook.surf.min_bin = 1.8e-6;
default.qlook.surf.max_bin = [];
default.qlook.surf.threshold = 15;
default.qlook.surf.sidelobe = 15;
default.qlook.surf.medfilt = 3;
default.qlook.surf.search_rng = [0:2];

%% SAR worksheet
default.sar.out_path = '';
default.sar.imgs = {[1*ones(15,1),(2:16).'],[2*ones(15,1),(2:16).'],[3*ones(15,1),(2:16).']};
default.sar.frm_types = {0,[0 1],0,0,-1};
default.sar.chunk_len = 5000;
default.sar.chunk_overlap = 10;
default.sar.frm_overlap = 0;
default.sar.coh_noise_removal = 0;
default.sar.combine_rx = 0;
default.sar.time_of_full_support = 3.5e-5;
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
default.radar.fs = 1e9/9;
default.radar.Tadc = []; % normally leave empty to use value in file header
default.radar.adc_bits = 14;
default.radar.Vpp_scale = 2;

default.radar.wfs.rx_paths = [8 9 10 11 1 1 2 3 4 5 6 7 12 13 14 15];
default.radar.wfs.noise_figure = 2;
default.radar.wfs.Tadc_adjust = -1.4455e-06; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple

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
default.post.echo.elev_comp = 3;
default.post.echo.depth = '[publish_echogram_switch(Bbad,0.25,Surface_Elev,-3500,DBottom,-100),max(Surface_Elev+100)]';
default.post.echo.er_ice = 3.15;
default.post.ops.en = 0;
default.post.ops.location = 'arctic';
default.post.ops.layers = {'bottom','surface'};
default.post.ops.gaps_dist = [300 60];


%% Radar Settings
defaults = {};

default.radar.wfs(1).Tsys = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]/1e9;
default.radar.wfs(1).chan_equal_dB = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
default.radar.wfs(1).chan_equal_deg = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];

% survey mode
default.qlook.img_comb = [9e-06 -inf 2e-06];
default.qlook.imgs = {[1*ones(4,1),(1:4).'],[2*ones(4,1),(1:4).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.DC_adjust = {'','',''};
default.radar.ref_fn = '';
default.config_regexp = '(survey_.*thick.xml';
default.name = 'Survey Mode';
defaults{end+1} = default;

% high altitude mode
default.qlook.img_comb = [9e-06 -inf 2e-06];
default.qlook.imgs = {[1*ones(4,1),(1:4).'],[2*ones(4,1),(1:4).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'survey_.*high_altitude.xml';
default.name = 'High Altitude Mode';
defaults{end+1} = default;

% Other settings

default.qlook.img_comb = [];
default.qlook.imgs = [];
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = '.*';
default.name = 'Other Settings';
defaults{end+1} = default;

%% Add default settings

param.config.defaults = defaults;
