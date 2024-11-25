function param = default_radar_params_2018_Antarctica_DC8_rds
% param = default_radar_params_2018_Antarctica_DC8_rds
%
% RDS: 2018_Antarctica_DC8
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Author: John Paden

%% Preprocess parameters
param.season_name = '2018_Antarctica_DC8';
param.radar_name = 'mcords3';

param.config.file.version = 403;
param.config.file.prefix = param.radar_name;
param.config.file.suffix = '.bin';
param.config.max_time_gap = 10;
param.config.min_seg_size = 2;

param.config.daq_type = 'cresis';
param.config.wg_type = 'cresis';
param.config.header_load_func = @basic_load_mcords3;
param.config.board_map = {'board0','board1'};
param.config.tx_map = {'','','','','','','',''};

param.config.daq.xml_version = 2.0;

param.config.max_data_rate = 100;
param.config.max_duty_cycle = 0.12;
param.config.prf_multiple = []; % Power supply sync signal that PRF must be a factor of these numbers
param.config.PRI_guard = 10e-6;
param.config.PRI_guard_percentage = 1;
param.config.tx_enable = [1 1 1 1 1 1 0 0];
param.config.max_tx = [57750 57750 65450 61292 61600 54478 0 0];
param.config.max_tx_voltage = sqrt(1000*50)*10^(-2/20); % voltage at max_tx

%% CReSIS parameters
param.config.cresis.clk = 900e6/6;
param.config.cresis.rx_gain_dB = 51.5;
param.config.cresis.gps_file_mask = 'GPS*';

%% Command worksheet
default.cmd.records = 1;
default.cmd.qlook = 1;
default.cmd.generic = 1;

%% Records worksheet
default.records.gps.time_offset = 1;
default.records.frames.mode = 1;
default.records.frames.geotiff_fn = 'antarctica/Landsat-7/Antarctica_LIMA_480m';
default.records.presum_mode = 1;

%% Qlook worksheet
default.qlook.out_path = '';
default.qlook.en = 1;
default.qlook.block_size = 10000;
default.qlook.dec = 50;
default.qlook.inc_dec = 10;
default.qlook.surf.en = 1;
default.qlook.surf.method = 'threshold';
default.qlook.surf.threshold_noise_rng = [0 -1e-6 -0.5e-6];
default.qlook.surf.min_bin = 1.8e-6;
default.qlook.surf.threshold = 15;
default.qlook.surf.sidelobe = 15;
default.qlook.surf.medfilt = 3;
default.qlook.surf.search_rng = [0 0.1e-6];

%% SAR worksheet
default.sar.out_path = '';
default.sar.imgs = {[1*ones(6,1),(1:6).'],[2*ones(6,1),(1:6).'],[3*ones(6,1),(1:6).']};
default.sar.frm_types = {0,[0 1],0,0,-1};
default.sar.chunk_len = 5000;
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
default.array.line_rng = -5:5;
default.array.dline = 6;
default.array.DCM = struct('bin_rng',-2:1:2,'rline_rng',-15:1:15);
default.array.Nsv = 1;
default.array.Nsrc = 2;

%% Radar worksheet
default.radar.fs = 150e6;
default.radar.Tadc = []; % normally leave empty to use value in file header
default.radar.adc_bits = 14;
default.radar.Vpp_scale = 2;

default.radar.wfs.rx_paths = [1 2 3 4 5 6];
default.radar.wfs.noise_figure = 2;
default.radar.wfs.Tadc_adjust = -1.4455e-06; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple

%% Post worksheet
default.post.data_dirs = {'mvdr','standard','qlook'};
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
default.post.echo.elev_comp = 3;
default.post.echo.depth = '[publish_echogram_switch(Bbad,0.25,Surface_Elev,-4200,DBottom,-100),max(Surface_Elev+100)]';
default.post.echo.er_ice = 3.15;
default.post.ops.en = 0;
default.post.ops.location = 'antarctic';
default.post.ops.layers = {'bottom','surface'};
default.post.ops.gaps_dist = [300 60];


%% Radar Settings
defaults = {};

default.radar.wfs(1).Tsys = [0 0 0 0 0 0]/1e9;
default.radar.wfs(1).chan_equal_dB = [0 0 0 0 0 0];
default.radar.wfs(1).chan_equal_deg = [0 0 0 0 0 0];

% survey mode
default.qlook.img_comb = [3e-06 -inf 1e-06 1e-05 -inf 3e-06];
default.qlook.imgs = {[1*ones(6,1),(1:6).'],[2*ones(6,1),(1:6).'],[3*ones(6,1),(1:6).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.DC_adjust = {'','',''};
default.radar.ref_fn = '';
default.config_regexp = 'survey_.*thick.xml';
default.name = 'Survey Mode';
defaults{end+1} = default;

% survey mode
default.qlook.img_comb = [3e-06 -inf 1e-06];
default.qlook.imgs = {[1*ones(6,1),(1:6).'],[2*ones(6,1),(1:6).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'survey_.*thin_ice.xml';
default.name = 'Thin Ice Mode';
defaults{end+1} = default;

% image mode
default.qlook.img_comb = [3e-06 -inf 1e-06 1e-05 -inf 3e-06];
default.qlook.imgs = {[1*ones(6,1),(1:6).'],[3*ones(6,1),(1:6).'],[5*ones(6,1),(1:6).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'image_.*thick.xml';
default.name = 'Image Mode';
defaults{end+1} = default;

% image mode
default.qlook.img_comb = [3e-06 -inf 1e-06];
default.qlook.imgs = {[1*ones(6,1),(1:6).'],[3*ones(6,1),(1:6).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'image_.*thin_ice.xml';
default.name = 'Image Mode Thin Ice';
defaults{end+1} = default;

% high altitude mode
default.qlook.img_comb = [1e-05 -inf 3e-06];
default.qlook.imgs = {[1*ones(6,1),(1:6).'],[2*ones(6,1),(1:6).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'survey_.*high_altitude.xml';
default.name = 'High Altitude Mode';
defaults{end+1} = default;

% deconvolution mode
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(6,1),(1:6).'],[2*ones(6,1),(1:6).'],[3*ones(6,1),(1:6).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'survey_.*DECONVOLUTION.xml';
default.name = 'Deconvolution Mode';
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
