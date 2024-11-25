function param = default_radar_params_2019_Greenland_P3_rds
% param = default_radar_params_2019_Greenland_P3_rds
%
% RDS: 2019_Greenland_P3
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Author: John Paden

%% Preprocess parameters
param.season_name = '2019_Greenland_P3';
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
param.config.tx_enable = [1 1 1 1 1 1 1 0];
param.config.max_tx = [40000 40000 40000 40000 40000 40000 40000 0];
param.config.max_tx_voltage = sqrt([250 250 250 250 250 250 250 0]*50)*10^(-2/20); % voltage at max_tx % CHANGED FROM 1x7 to 1x8 vector

%% CReSIS parameters
param.config.cresis.clk = 1e9/9;
param.config.cresis.rx_gain_dB = 51.5;
param.config.cresis.gps_file_mask = 'GPS*';

%% Command worksheet
param.cmd.records = 1;
param.cmd.qlook = 1;
param.cmd.generic = 1;

%% Records worksheet
param.records.gps.time_offset = 1;
param.records.frames.mode = 1;
param.records.frames.geotiff_fn = fullfile('greenland','Landsat-7','Greenland_natural_150m.tif');
param.records.presum_mode = 1;

%% Qlook worksheet
param.qlook.out_path = '';
param.qlook.en = 1;
param.qlook.block_size = 10000;
param.qlook.dec = 20;
param.qlook.inc_dec = 5;
param.qlook.surf.en = 1;
param.qlook.surf.profile = 'RDS_OIB';

%% SAR worksheet
param.sar.out_path = '';
param.sar.chunk_len = 5000;
param.sar.combine_rx = 0;
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
param.array.line_rng = -5:5;
param.array.dbin = 1;
param.array.dline = 6;
param.array.DCM = [];
param.array.tomo_en = 0;
param.array.Nsv = 1;
param.array.theta_rng = [0 0];
param.array.sv_fh = @array_proc_sv;
param.array.diag_load = 0;
param.array.Nsrc = 2;

%% Radar worksheet
param.radar.fs = 1e9/9;
param.radar.Tadc = []; % normally leave empty to use value in file header
param.radar.adc_bits = 14;
param.radar.Vpp_scale = 2;
param.radar.lever_arm_fh = @lever_arm;

param.radar.wfs.rx_paths = [1 2 3 4 5 6 7 NaN];
param.radar.wfs.Tadc_adjust = -1.4455e-06; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple

param.radar.wfs(1).Tsys = [0 0 0 0 0 0 0]/1e9;
param.radar.wfs(1).chan_equal_dB = [0 0 0 0 0 0 0];
param.radar.wfs(1).chan_equal_deg = [0 0 0 0 0 0 0];

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
param.post.echo.elev_comp = 3;
param.post.echo.depth = '[publish_echogram_switch(Bbad,0.25,Surface_Elev,-3500,DBottom,-100),max(Surface_Elev+100)]';
param.post.echo.er_ice = 3.15;
param.post.ops.en = 0;
param.post.ops.location = 'arctic';
param.post.ops.layers = {'bottom','surface'};
param.post.ops.gaps_dist = [300 60];


%% Radar Settings
defaults = {};

% survey mode
default.qlook.img_comb = [3e-06 -inf 1e-06 1e-05 -inf 3e-06];
default.qlook.imgs = {[1*ones(4,1),(1:4).'],[2*ones(4,1),(1:4).'],[3*ones(4,1),(1:4).']};
default.sar.imgs = {[1*ones(7,1),(1:7).'],[2*ones(7,1),(1:7).'],[3*ones(7,1),(1:7).']};
default.array.imgs = {[1*ones(7,1),(1:7).'],[2*ones(7,1),(1:7).'],[3*ones(7,1),(1:7).']};
default.array.img_comb = default.qlook.img_comb;
default.radar.DC_adjust = {'','',''};
default.radar.ref_fn = '';
default.config_regexp = '(survey_.*thick.xml';
default.name = 'Nadir Thick Ice Mode';
defaults{end+1} = default;

% survey mode
default.qlook.img_comb = [3e-06 -inf 1e-06];
default.qlook.imgs = {[1*ones(4,1),(1:4).'],[2*ones(4,1),(1:4).']};
default.sar.imgs = {[1*ones(7,1),(1:7).'],[2*ones(7,1),(1:7).']};
default.array.imgs = {[1*ones(7,1),(1:7).'],[2*ones(7,1),(1:7).']};
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'survey_.*thin_ice.xml';
default.name = 'Nadir Thin Ice Mode';
defaults{end+1} = default;

% image mode
default.qlook.img_comb = [3e-06 -inf 1e-06 1e-05 -inf 3e-06];
default.qlook.imgs = {[1*ones(4,1),(1:4).'],[3*ones(4,1),(1:4).'],[5*ones(4,1),(1:4).']};
default.sar.imgs = {[1*ones(7,1),(1:7).'],[2*ones(7,1),(1:7).'],[3*ones(7,1),(1:7).'],[4*ones(7,1),(1:7).'],[5*ones(7,1),(1:7).'],[6*ones(7,1),(1:7).']};
default.array.imgs = {[[1*ones(7,1),(1:7).'];[2*ones(7,1),(1:7).']],[[3*ones(7,1),(1:7).'];[4*ones(7,1),(1:7).']],[[5*ones(7,1),(1:7).'];[6*ones(7,1),(1:7).']]};
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'image_.*thick.xml';
default.name = 'Image Thick Ice Mode';
defaults{end+1} = default;

% image mode
default.qlook.img_comb = [3e-06 -inf 1e-06];
default.qlook.imgs = {[1*ones(4,1),(1:4).'],[3*ones(4,1),(1:4).']};
default.sar.imgs = {[1*ones(7,1),(1:7).'],[2*ones(7,1),(1:7).'],[3*ones(7,1),(1:7).'],[4*ones(7,1),(1:7).']};
default.array.imgs = {[[1*ones(7,1),(1:7).'];[2*ones(7,1),(1:7).']],[[3*ones(7,1),(1:7).'];[4*ones(7,1),(1:7).']]};
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'image_.*thin.xml';
default.name = 'Image Thin Ice Mode';
defaults{end+1} = default;

% high altitude mode
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(7,1),(1:7).']};
default.sar.imgs = {[1*ones(7,1),(1:7).'],[2*ones(7,1),(1:7).']};
default.array.imgs = {[[1*ones(7,1),(1:7).'];[2*ones(7,1),(1:7).']]};
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'image_.*high_altitude.xml';
default.name = 'High Altitude Mode';
defaults{end+1} = default;

% survey mode deconvolution
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(4,1),(1:4).'],[3*ones(4,1),(1:4).'],[5*ones(4,1),(1:4).']};
default.sar.imgs = {[1*ones(7,1),(1:7).'],[2*ones(7,1),(1:7).'],[3*ones(7,1),(1:7).'],[4*ones(7,1),(1:7).'],[5*ones(7,1),(1:7).'],[6*ones(7,1),(1:7).']};
default.array.imgs = {[[1*ones(7,1),(1:7).'];[2*ones(7,1),(1:7).']],[[3*ones(7,1),(1:7).'];[4*ones(7,1),(1:7).']],[[5*ones(7,1),(1:7).'];[6*ones(7,1),(1:7).']]};
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'survey_.*DECONVOLUTION.xml';
default.name = 'Deconvolution Mode';
defaults{end+1} = default;

% image mode deconvolution
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(4,1),(1:4).'],[2*ones(4,1),(1:4).'],[3*ones(4,1),(1:4).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'image_.*DECONVOLUTION.xml';
default.name = 'Deconvolution Mode';
defaults{end+1} = default;

% noise mode
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(7,1),(1:7).'],[2*ones(7,1),(1:7).'],[3*ones(7,1),(1:7).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'survey_.*NOISE.xml';
default.name = 'Noise Mode';
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
