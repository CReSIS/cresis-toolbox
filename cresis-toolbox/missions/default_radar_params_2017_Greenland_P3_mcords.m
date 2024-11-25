function [param,defaults] = default_radar_params_2017_Greenland_P3_mcords
% [param,defaults] = default_radar_params_2017_Greenland_P3_mcords
%
% MCORDS 3: 2017 Greenland P3
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Author: John Paden

% param.season_name = '2017_Greenland_P3';
% param.radar_name = 'mcords3';
% 
% %% Control parameters (not used in the parameter spreadsheet directly)
% default.xml_file_prefix = 'mcords3';
% default.data_file_prefix = 'mcords3';
% default.header_load_func = @basic_load_mcords3;
% default.header_load_params = struct('clk',1e9/9,'presum_mode',1);
% default.xml_version = 2.0;
% 
% default.noise_50ohm = [-45.5	-44.3	-44.8	-44.9	-40.2	-40.8	-40.5	-41.4	-39.9	-40.2	-42.0	-43.6	-43.0	-44.1	-44.6];
% 
% default.Pt = 1000 * [1 1 1 1 1 1 1];
% default.Gt = 7*4;
% default.Ae = 2*0.468 * 0.468;
% 
% default.system_loss_dB = 10.^(-5.88/10);
% default.max_DDS_RAM = 40000;
% default.tx_voltage = sqrt(1000*50)*10^(-2/20);
% 
% default.iq_mode = 0;
% default.tx_DDS_mask = [1 1 1 1 1 1 1 0];
% 
% default.radar_worksheet_headers = {'Tpd','Tadc','Tadc_adjust','f0','f1','ref_fn','tukey','tx_weights','rx_paths','adc_gains','chan_equal_dB','chan_equal_deg','Tsys','DC_adjust','DDC_mode','DDC_freq'};
% default.radar_worksheet_headers_type = {'r','r','r','r','r','r','r','r','r','r','r','r','r','r','r','r'};
% 
% default.basic_surf_track_min_time = 2e-6; % Normally -inf for lab test, 2e-6 for flight test
% default.basic_surf_track_Tpd_factor = 1.1; % Normally -inf for lab test, 1.1 for flight test
% default.adc_folder_name = 'board%b';
% 
% if 1
%   % Example 1: Normal configuration:
%   %   Connect antenna N to WFG N for all N = 1 to 7
%   ref_adc = 14;
%   default.txequal.img = [(1:7).', ref_adc*ones(7,1)];
%   default.txequal.ref_wf_adc = 3;
%   default.txequal.wf_mapping = [1 2 3 4 5 6 7 0];
%   default.txequal.Hwindow_desired = [1 1 1 1 1 1 1 0];
%   default.txequal.max_DDS_amp = [40000 40000 40000 40000 40000 40000 40000 0];
%   default.txequal.time_delay_desired = [0 0 0 0 0 0 0 0];
%   default.txequal.phase_desired = [0 0 0 0 0 0 0 0];
%   default.txequal.time_validation = [3 3 3 3 3 3 3 3]*1e-9;
%   default.txequal.amp_validation = [3 3 3 3 3 3 3 3];
%   default.txequal.phase_validation = [35 35 35 35 35 35 35 35];
%   default.txequal.remove_linear_phase_en = true;
% end

%% Preprocess parameters
param.season_name = '2017_Greenland_P3';
param.radar_name = 'mcords3';

param.config.file.version = 403;
param.config.file.prefix = param.radar_name;
param.config.file.suffix = '.bin';
param.config.max_time_gap = 10;
param.config.min_seg_size = 2;

param.config.daq_type = 'cresis';
param.config.wg_type = 'cresis';
param.config.header_load_func = @basic_load_mcords3;
param.config.board_map = {'board0','board1','board2','board3'};
param.config.tx_map = {'','','','','','','',''};

param.config.daq.xml_version = 2.0;

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
default.sar.imgs = {[1*ones(4,1),(9:12).'],[2*ones(4,1),(9:12).'],[3*ones(4,1),(9:12).']};
default.sar.frm_types = {0,[0 1],0,0,-1};
default.sar.chunk_len = 5000;
default.sar.array_rx = 0;
default.sar.time_of_full_support = 3.5e-5;
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
default.array.tomo_en = 0;
default.array.Nsv = 1;
default.array.theta_rng = [0 0];
default.array.sv_fh = @array_proc_sv;
default.array.diag_load = 0;
default.array.Nsrc = 2;

%% Radar worksheet
default.radar.fs = 1e9/9;
default.radar.Tadc = []; % normally leave empty to use value in file header
default.radar.adc_bits = 14;
default.radar.Vpp_scale = 2;

%default.radar.rx_paths = [1,1:15];
default.radar.rx_paths = [1 8 9 10 11 1 2 3 4 5 6 7 12 13 14 15];
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

defaults = {};

%% Settings
default.radar.wfs(1).chan_equal_Tsys = [16.51	11.76	8.57	5.91	1.60	-0.13	0.00	-2.44	-4.83	-3.16	-2.76	-10.60	-6.05	-1.68	5.19]/1e9;
default.radar.wfs(1).chan_equal_dB = [1.1	1.0	1.0	3.0	3.9	1.0	0.0	-2.6	-0.7	0.9	1.3	3.7	2.0	0.2	3.3];
default.radar.wfs(1).chan_equal_deg = [97.1	25.2	-60.1	-126.1	-38.7	6.4	-0.0	-131.0	0.6	-25.1	-47.5	-86.3	-33.5	165.4	-106.6];

% survey mode
default.qlook.qlook.img_comb = [3e-06 -inf 1e-06 1e-05 -inf 3e-06];
default.qlook.imgs = {[1*ones(4,1),(2:5).'],[2*ones(4,1),(2:5).'],[3*ones(4,1),(2:5).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.qlook.img_comb;
default.radar.DC_adjust = {'','',''};
default.radar.ref_fn = '';
default.xml_regexp = 'survey_.*thick.xml';
default.name = 'Survey Mode';
defaults{end+1} = default;

% survey mode
default.qlook.qlook.img_comb = [3e-06 -inf 1e-06];
default.qlook.imgs = {[1*ones(4,1),(2:5).'],[2*ones(4,1),(2:5).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.qlook.img_comb;
default.radar.DC_adjust = {'','',''};
default.radar.ref_fn = '';
default.xml_regexp = 'survey_.*thin_ice.xml';
default.name = 'Thin Ice Mode';
defaults{end+1} = default;

% high altitude mode
default.qlook.qlook.img_comb = [1e-05 -inf 3e-06];
default.qlook.imgs = {[1*ones(4,1),(2:5).'],[2*ones(4,1),(2:5).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.qlook.img_comb;
default.radar.DC_adjust = {'','',''};
default.radar.ref_fn = '';
default.xml_regexp = 'survey_.*high_altitude.xml';
default.name = 'High Altitude Mode';
defaults{end+1} = default;

% deconvolution mode
default.qlook.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(4,1),(2:5).'],[2*ones(4,1),(2:5).'],[3*ones(4,1),(2:5).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.qlook.img_comb;
default.radar.DC_adjust = {'','',''};
default.radar.ref_fn = '';
default.xml_regexp = 'survey_.*DECONVOLUTION.xml';
default.name = 'Deconvolution Mode';
defaults{end+1} = default;

%% Other settings

default.qlook.qlook.img_comb = [];
default.qlook.imgs = [];
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.qlook.img_comb;

default.radar.DC_adjust = {'DC_20160413_04_wf1.mat','DC_20160413_04_wf2.mat','DC_20160413_04_wf2.mat'};
default.radar.ref_fn = 'deconv_wf_%w_adc_%a_20160413_06';
default.xml_regexp = 'survey_180-210MHz_.*DECONV.xml';
default.name = 'Deconv 180-210 MHz';
defaults{end+1} = default;

default.radar.DC_adjust = [];
default.radar.ref_fn = '';
default.xml_regexp = '.*';
default.name = 'Other Settings';
defaults{end+1} = default;

return;
