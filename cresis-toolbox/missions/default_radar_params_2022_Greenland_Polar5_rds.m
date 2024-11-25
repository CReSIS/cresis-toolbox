function [param,defaults] = default_radar_params_2022_Greenland_Polar5_rds
% [param,defaults] = default_radar_params_2022_Greenland_Polar5_rds
%
% MCORDS 5: 2022_Greenland_Polar5
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Author: John Paden

%% Preprocess parameters
param.season_name = '2022_Greenland_Polar5';
param.radar_name = 'mcords5';

% Reading in files
param.config.daq_type = 'cresis';
param.config.wg_type = 'arena';
param.config.header_load_func = @basic_load_mcords5;
param.config.header_load_param = struct('presum_mode',true,'clk',200e6);
param.config.tx_map = {'awg0','awg1','awg2','awg3','awg4','awg5','awg6','awg7'};

% Creating segments
param.config.max_time_gap = 10;
param.config.segment_end_file_trim = 2;

% Creating settings files
param.config.max_data_rate = 240;
param.config.max_duty_cycle = 0.1;
param.config.prf_multiple = [10e6]; % Power supply sync signal that PRF must be a factor of these numbers
param.config.PRI_guard = 1e-6;
param.config.PRI_guard_percentage = 1;
param.config.tx_enable = [1 1 1 1 1 1 1 1];
param.config.max_tx = 0.63;
param.config.max_tx_voltage = sqrt(1000*50)*10^(-2/20); % voltage at max_tx

% Interpretting settings
param.config.cresis.config_version = 2.0;
param.config.cresis.rx_gain_dB = 48;
param.config.gps_file_mask = 'GPS*';

%% Control parameters (not used in the parameter spreadsheet directly)
% default.xml_file_prefix = 'mcords5';
% default.data_file_prefix = 'mcords5';

param.config.adc_SNR_dB = 59;
param.config.noise_figure = 2;
param.config.max_tx = 0.63;

param.config.noise_50ohm = [-39.8	-41.0	-40.1	-39.6	-38.4	-39.1	-38.3	-39.6	];

param.config.Pt = (4*1000 + 4*500) * sum(chebwin(8,30).^2)/8;
param.config.Gt = 8*4;
param.config.Ae = 2*0.468 * 0.468;

param.config.system_loss_dB = 10.^(-5.88/10);
param.config.max_DDS_RAM = 4000;
param.config.tx_voltage = sqrt(1000*50)*10^(-2/20);

param.config.iq_mode = 0;
param.config.tx_DDS_mask = [1 1 1 1 1 1 1 1]; % Used by basic_rx_chan_equalization

% For airborne test:
% param.config.basic_surf_track_min_time = 2e-6; % Normally 0e-6 for lab test, 2e-6 for flight test
% param.config.basic_surf_track_Tpd_factor = 1.1; % Normally -inf for lab test, 1.1 for flight test
% For ground test:
param.config.basic_surf_track_min_time = 0e-6; % Normally 0e-6 for lab test, 2e-6 for flight test
param.config.basic_surf_track_Tpd_factor = -inf; % Normally -inf for lab test, 1.1 for flight test

% default.board_folder_name = 'chan%d';

if 1
  % Example 1: Normal configuration:
  %   Connect antenna N to WFG N for all N = 1 to 8
  ref_adc = 1;
  param.config.txequal.img = [(1:8).', ref_adc*ones(8,1)];
  param.config.txequal.ref_wf_adc = 4;
  param.config.txequal.wf_mapping = [1 2 3 4 5 6 7 8];
  param.config.txequal.Hwindow_desired = chebwin(8,30).';
  param.config.txequal.max_DDS_amp = [4000 4000 4000 4000 4000 4000 4000 4000];
  param.config.txequal.time_delay_desired = [0 0 0 0 0 0 0 0];
  param.config.txequal.phase_desired = [0 0 0 0 0 0 0 0];
  param.config.txequal.time_validation = [0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4]*1e-9;
  param.config.txequal.amp_validation = [3 3 3 3 3 3 3 3];
  param.config.txequal.phase_validation = [35 35 35 35 35 35 35 35];
  param.config.txequal.remove_linear_phase_en = true;
elseif 0
  % Channel 4 ADC is bad:
  ref_adc = 5;
  param.config.txequal.img = [(1:8).', ref_adc*ones(8,1)];
  param.config.txequal.ref_wf_adc = 4;
  param.config.txequal.wf_mapping = [1 2 3 4 5 6 7 8];
  param.config.txequal.Hwindow_desired = chebwin(8,30).';
  param.config.txequal.max_DDS_amp = [4000 4000 4000 4000 4000 4000 4000 4000];
  param.config.txequal.time_delay_desired = [0 0 0 0 0 0 0 0];
  param.config.txequal.phase_desired = [0 0 0 0 0 0 0 0];
  param.config.txequal.time_validation = [0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4]*1e-9;
  param.config.txequal.amp_validation = [3 3 3 3 3 3 3 3];
  param.config.txequal.phase_validation = [35 35 35 35 35 35 35 35];
  param.config.txequal.remove_linear_phase_en = true;
elseif 0
  % DDS 3 is not used, but create settings not changed:
  %   Connect antenna 1 to a 50 oxhm load
  %   Connect antenna 2 to WFG 1
  %   Connect antenna 3 to WFG 2
  ref_adc = 4;
  param.config.txequal.img = [(1:8).', ref_adc*ones(8,1)];
  param.config.txequal.wf_mapping = [1 2 0 4 5 6 7 8];
  param.config.txequal.ref_wf_adc = 4;
  param.config.txequal.Hwindow_desired = chebwin(7,30).';
  param.config.txequal.max_DDS_amp = [4000 4000 0 4000 4000 4000 4000 4000];
  param.config.txequal.time_delay_desired = [0 0 0 0 0 0 0 0];
  param.config.txequal.phase_desired = [0 0 0 0 0 0 0 0];
  param.config.txequal.time_validation = [0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4]*1e-9;
  param.config.txequal.amp_validation = [3 3 3 3 3 3 3 3];
  param.config.txequal.phase_validation = [35 35 35 35 35 35 35 35];
  param.config.txequal.remove_linear_phase_en = true;
elseif 0
  % DDS 3 to 8 are not used and ADC's 3 to 24 are not used, create settings
  % also only uses first two DDS
  ref_adc = 1;
  param.config.txequal.img = [(1:2).', ref_adc*ones(2,1)];
  default.wf_mapping = [1 2 0 0 0 0 0 0];
  param.config.txequal.ref_wf_adc = 1;
  param.config.txequal.Hwindow_desired = [1 1];
  param.config.txequal.max_DDS_amp = [4000 4000 0 0 0 0 0 0];
  param.config.txequal.time_delay_desired = [0 0 0 0 0 0 0 0];
  param.config.txequal.phase_desired = [0 0 0 0 0 0 0 0];
  param.config.txequal.time_validation = [0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4]*1e-9;
  param.config.txequal.amp_validation = [3 3 3 3 3 3 3 3];
  param.config.txequal.phase_validation = [35 35 35 35 35 35 35 35];
  param.config.txequal.remove_linear_phase_en = false;
end

%% AWI MCoRDS Arena Parameters
arena = [];
arena.clk = 10e6;
% fs = 1600e6;
fs_dac = 1600e6;
subsystem_idx = 0;
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'arena-awg0';
arena.subsystem(subsystem_idx).subSystem{1} = 'awg0';
arena.subsystem(subsystem_idx).subSystem{2} = 'awg1';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'arena-awg1';
arena.subsystem(subsystem_idx).subSystem{1} = 'awg2';
arena.subsystem(subsystem_idx).subSystem{2} = 'awg3';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'arena-awg2';
arena.subsystem(subsystem_idx).subSystem{1} = 'awg4';
arena.subsystem(subsystem_idx).subSystem{2} = 'awg5';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'arena-awg3';
arena.subsystem(subsystem_idx).subSystem{1} = 'awg6';
arena.subsystem(subsystem_idx).subSystem{2} = 'awg7';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'arena-ctu0';
arena.subsystem(subsystem_idx).subSystem{1} = 'ctu0';

dac_idx = 0;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg0';
arena.dac(dac_idx).type = 'dac-ad9129_0014';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = 3;
arena.dac(dac_idx).desiredAlignMax = 17;
arena.dac(dac_idx).dcoPhase = 80;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg1';
arena.dac(dac_idx).type = 'dac-ad9129_0014';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = 10;
arena.dac(dac_idx).desiredAlignMax = 24;
arena.dac(dac_idx).dcoPhase = 80;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg2';
arena.dac(dac_idx).type = 'dac-ad9129_0014';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = -3;
arena.dac(dac_idx).desiredAlignMax = 11;
arena.dac(dac_idx).dcoPhase = 80;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg3';
arena.dac(dac_idx).type = 'dac-ad9129_0014';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = 11;
arena.dac(dac_idx).desiredAlignMax = 25;
arena.dac(dac_idx).dcoPhase = 80;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg4';
arena.dac(dac_idx).type = 'dac-ad9129_0014';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = 4;
arena.dac(dac_idx).desiredAlignMax = 18;
arena.dac(dac_idx).dcoPhase = 80;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg5';
arena.dac(dac_idx).type = 'dac-ad9129_0014';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = 10;
arena.dac(dac_idx).desiredAlignMax = 24;
arena.dac(dac_idx).dcoPhase = 80;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg6';
arena.dac(dac_idx).type = 'dac-ad9129_0014';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = 3;
arena.dac(dac_idx).desiredAlignMax = 17;
arena.dac(dac_idx).dcoPhase = 80;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg7';
arena.dac(dac_idx).type = 'dac-ad9129_0014';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = 13;
arena.dac(dac_idx).desiredAlignMax = 27;
arena.dac(dac_idx).dcoPhase = 80;

arena.zeropimods = [0 180];

% arena.awg = [];
% arena.awg(end+1).awg = 0;
% arena.awg(end).dacs = [0 1];
% arena.awg(end).dacClk = [1600e6 1600e6];
% arena.awg(end).desiredAlignMin = [3 10];
% arena.awg(end).desiredAlignMax = [17 24];
% arena.awg(end+1).awg = 1;
% arena.awg(end).dacs = [2 3];
% arena.awg(end).dacClk = [1600e6 1600e6];
% arena.awg(end).desiredAlignMin = [-3 11];
% arena.awg(end).desiredAlignMax = [11 25];
% arena.awg(end+1).awg = 2;
% arena.awg(end).dacs = [4 5];
% arena.awg(end).dacClk = [1600e6 1600e6];
% arena.awg(end).desiredAlignMin = [4 10];
% arena.awg(end).desiredAlignMax = [18 24];
% arena.awg(end+1).awg = 3;
% arena.awg(end).dacs = [6 7];
% arena.awg(end).dacClk = [1600e6 1600e6];
% arena.awg(end).desiredAlignMin = [3 13];
% arena.awg(end).desiredAlignMax = [17 27];
% arena.dacs = [0 1 2 3 4 5 6 7];
% arena.dacs_sampFreq = [1600e6 1600e6 1600e6 1600e6 1600e6 1600e6 1600e6 1600e6];
arena.max_tx = [0.63 0.63 0.63 0.63 0.63 0.63 0.63 0.63];
arena.TTL_time = [0.1 0.2 2.2];
arena.dacs_internal_delay = 0.0;
arena.dacs_start_delay = 0.0;

arena.TTL_names = {};
for PA = 1:8
  arena.TTL_names{end+1} = sprintf('PA ENA %d',PA);
end
arena.TTL_names{end+1} = 'T/R';
arena.TTL_names{end+1} = 'ISO';
arena.TTL_names{end+1} = 'EPRI';
arena.TTL_names{end+1} = 'PRI';
arena.TTL_names{end+1} = 'EPRI';
arena.TTL_names{end+1} = 'PRI';
arena.TTL_names{end+1} = 'EPRI';
arena.TTL_names{end+1} = 'PRI';
arena.TTL_states{1} = [
  0 1 1 0 % PA ENA 1
  0 1 1 0 % PA ENA 2
  0 1 1 0 % PA ENA 3
  0 1 1 0 % PA ENA 4
  0 1 1 0 % PA ENA 5
  0 1 1 0 % PA ENA 6
  0 1 1 0 % PA ENA 7
  0 1 1 0 % PA ENA 8
  0 1 1 0 % T/R
  0 1 1 0 % ISO
  1 0 0 0 % EPRI
  0 1 0 0 % PRI
  1 0 0 0 % EPRI
  0 1 0 0 % PRI
  1 0 0 0 % EPRI
  0 1 0 0 % PRI
  ];
arena.TTL_states{2} = [
  0 1 1 0 % PA ENA 1
  0 1 1 0 % PA ENA 2
  0 1 1 0 % PA ENA 3
  0 1 1 0 % PA ENA 4
  0 1 1 0 % PA ENA 5
  0 1 1 0 % PA ENA 6
  0 1 1 0 % PA ENA 7
  0 1 1 0 % PA ENA 8
  0 1 1 0 % T/R
  0 1 1 0 % ISO
  0 0 0 0 % EPRI
  0 1 0 0 % PRI
  0 0 0 0 % EPRI
  0 1 0 0 % PRI
  0 0 0 0 % EPRI
  0 1 0 0 % PRI
  ];

arena.system.name = 'ku0001';

arena.param.tx_max = [1 1];
arena.param.PA_setup_time = 2e-6; % Time required to enable PA before transmit
arena.param.TTL_time_delay = 0.0; % TTL time delay relative to transmit start
arena.param.ADC_time_delay = 3.0720e-6; % ADC time delay relative to transmit start

arena.psc.type = 'psc_0001';

arena.ctu.type = 'ctu_0013';
arena.ctu.name = 'ctu0';

if 0
  % External GPS
  arena.ctu.nmea = 31;
  arena.ctu.nmea_baud = 9600;
  arena.ctu.pps = 10;
  arena.ctu.pps_polarity = 1;
else
  % Internal GPS
  arena.ctu.nmea = 60;
  arena.ctu.nmea_baud = 115200;
  arena.ctu.pps = 63;
  arena.ctu.pps_polarity = 1;
end
for idx = 1:8
  arena.ctu.out.bit_group(idx).name = sprintf('PA ENA %d',idx);
  arena.ctu.out.bit_group(idx).bits = 0;
  arena.ctu.out.bit_group(idx).epri = [0 1 1 0];
  arena.ctu.out.bit_group(idx).pri = [0 1 1 0];
end
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'T/R';
arena.ctu.out.bit_group(idx).bits = 1;
arena.ctu.out.bit_group(idx).epri = [0 1 1 0];
arena.ctu.out.bit_group(idx).pri = [0 1 1 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'ISO';
arena.ctu.out.bit_group(idx).bits = 2;
arena.ctu.out.bit_group(idx).epri = [0 1 1 0];
arena.ctu.out.bit_group(idx).pri = [0 1 1 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'EPRI';
arena.ctu.out.bit_group(idx).bits = 3;
arena.ctu.out.bit_group(idx).epri = [1 0 0 0];
arena.ctu.out.bit_group(idx).pri = [0 0 0 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'PRI';
arena.ctu.out.bit_group(idx).bits = 4;
arena.ctu.out.bit_group(idx).epri = [0 1 0 0];
arena.ctu.out.bit_group(idx).pri = [0 1 0 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'EPRI';
arena.ctu.out.bit_group(idx).bits = 3;
arena.ctu.out.bit_group(idx).epri = [1 0 0 0];
arena.ctu.out.bit_group(idx).pri = [0 0 0 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'PRI';
arena.ctu.out.bit_group(idx).bits = 4;
arena.ctu.out.bit_group(idx).epri = [0 1 0 0];
arena.ctu.out.bit_group(idx).pri = [0 1 0 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'EPRI';
arena.ctu.out.bit_group(idx).bits = 3;
arena.ctu.out.bit_group(idx).epri = [1 0 0 0];
arena.ctu.out.bit_group(idx).pri = [0 0 0 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'PRI';
arena.ctu.out.bit_group(idx).bits = 4;
arena.ctu.out.bit_group(idx).epri = [0 1 0 0];
arena.ctu.out.bit_group(idx).pri = [0 1 0 0];

arena.ctu.out.time_cmd = {'2e-6+param.wfs(wf).Tpd+0.1e-6' '2e-6+param.wfs(wf).Tpd+0.1e-6' '2e-6+param.wfs(wf).Tpd+0.1e-6' '2/param.prf'};

default.arena = arena;

%% Records worksheet in parameter spreadsheet
param.records.file.version = 407;
param.records.file.boards = {'chan1','chan2','chan3','chan4','chan5','chan6','chan7','chan8'};
param.records.file.board_folder_name = '%b';
param.records.file.prefix = param.radar_name;
param.records.file.suffix = '.bin';
param.records.file.clk = 200e6;
param.records.gps.time_offset = 1;
param.records.presum_mode = 0;
param.records.frames.mode = 1;
param.records.frames.geotiff_fn = fullfile('greenland','Landsat-7','Greenland_natural_150m.tif');

%% Qlook worksheet in parameter spreadsheet
param.qlook.out_path = '';
param.qlook.imgs = {[1*ones(8,1),(1:8).'],[2*ones(8,1),(1:8).'],[3*ones(8,1),(1:8).']};
param.qlook.en = 1;
param.qlook.block_size = 10000;
param.qlook.dec = 20;
param.qlook.inc_dec = 5;
param.qlook.surf.en = 1;
param.qlook.surf.profile = 'RDS';

%% SAR worksheet in parameter spreadsheet
param.sar.out_path = '';
param.sar.imgs = {[1*ones(8,1),(1:8).'],[2*ones(8,1),(1:8).'],[3*ones(8,1),(1:8).']};
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

%% Array worksheet in parameter spreadsheet
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

%% Radar worksheet in parameter spreadsheet
param.radar.fs = 1600e6;
param.radar.Tadc = []; % normally leave empty to use value in file header
param.radar.adc_bits = 12;
param.radar.Vpp_scale = 2;
param.radar.lever_arm_fh = @lever_arm;

param.radar.wfs.rx_paths = [1:8];
param.radar.wfs.Tadc_adjust = 0.000010179163-1.936020e-6; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple

param.radar.wfs(1).Tsys = [0 0 0 0 0 0 0 0]/1e9;
param.radar.wfs(1).chan_equal_dB = [0 0 0 0 0 0 0 0];
param.radar.wfs(1).chan_equal_deg = [0 0 0 0 0 0 0 0];

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
% param.post.echo.elev_comp = 2;
% param.post.echo.depth = '[publish_echogram_switch(Bbad,0.25,Surface_Depth,-2800,DBottom,-100),max(Surface_Depth+100)]';
param.post.echo.elev_comp = 3;
param.post.echo.depth = '[publish_echogram_switch(Bbad,0.25,Surface_Elev,-3500,DBottom,-100),max(Surface_Elev+100)]';
param.post.echo.er_ice = 3.15;
param.post.ops.location = 'arctic';

defaults = {};

%% Wideband settings
default.radar.wfs(1).Tsys = [-31.8 -32.1 -31.7 -31.6 -31.2 -30.8 -31.5 -31.1]/1e9;
default.radar.wfs(1).chan_equal_dB = [-4 -4.3 -2.9 -4.6 -1.2 -1.5 -0.9 -2.2];
default.radar.wfs(1).chan_equal_deg = [113.1 64.8 124.3 133.7 108 138.1 71.6 102.9];
default.radar.ft_dec = [37 40];

 % survey mode
default.qlook.img_comb = [3e-06 -inf 1e-06 1e-05 -inf 3e-06];
default.qlook.imgs = {[1*ones(8,1),(1:8).'],[2*ones(8,1),(1:8).'],[3*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.ref_fn = '';
default.config_regexp = 'survey_150-520MHz_.*thick.xml';
default.name = 'Survey Mode 150-520 MHz';
defaults{end+1} = default;

 % thin ice mode
default.qlook.img_comb = [1e-06 -inf 1e-06 3e-06 -inf 1e-06];
default.qlook.imgs = {[1*ones(8,1),(1:8).'],[2*ones(8,1),(1:8).'],[3*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.ref_fn = '';
default.config_regexp = 'thinice_150-520MHz_.*thick.xml';
default.name = 'Thin Ice Mode 150-520 MHz';
defaults{end+1} = default;

 % 2 beam imaging mode
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.ref_fn = '';
default.config_regexp = 'image_150-520MHz_.*thick.xml';
default.name = '2 Beam Image Mode 150-520 MHz';
defaults{end+1} = default;

 % 3 beam imaging mode
default.qlook.img_comb = [];
default.qlook.imgs = {[2*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.ref_fn = '';
default.config_regexp = 'image3_150-520MHz_.*thick.xml';
default.name = '3 Beam Image Mode 150-520 MHz';
defaults{end+1} = default;

 % sea ice mode
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.ref_fn = '';
default.config_regexp = 'seaice_150-520MHz_.*.xml';
default.name = 'Sea Ice 150-520 MHz';
defaults{end+1} = default;

 % image high thin with narrowband
default.qlook.img_comb = [];
default.qlook.imgs = {[2*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.ref_fn = '';
default.config_regexp = 'imagehighthin_150-520MHz_.*.xml';
default.name = 'High Alt Thin Ice Image Mode 150-520 MHz';
defaults{end+1} = default;

%% Narrowband settings
default.radar.wfs(1).Tsys = [-31.8 -32.1 -31.7 -31.6 -31.2 -30.8 -31.5 -31.1]/1e9;
default.radar.wfs(1).chan_equal_dB = [0 0.9 0.2 0 3.2 1.7 3.9 2.4];
default.radar.wfs(1).chan_equal_deg = [-14.6 -69.7 -6.8 0 -13.9 -1.8 -48.8 -15.8];
default.radar.ft_dec = [3 20];

% survey mode
default.qlook.img_comb = [3e-06 -inf 1e-06 1e-05 -inf 3e-06];
default.qlook.imgs = {[1*ones(8,1),(1:8).'],[2*ones(8,1),(1:8).'],[3*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'survey_180-210MHz_.*thick.xml';
default.name = 'Survey Mode 180-210 MHz';
defaults{end+1} = default;

% polarimetric mode
default.qlook.img_comb = [3e-06 -inf 1e-06 1e-05 -inf 3e-06];
default.qlook.imgs = {[1*ones(4,1),(3:6).'],[3*ones(4,1),(3:6).'],[5*ones(4,1),(3:6).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'polarimetric_180-210MHz_.*thick.xml';
default.name = 'Polarimetric Mode 180-210 MHz';
defaults{end+1} = default;

% survey polarimetric mode
default.qlook.img_comb = [3e-06 -inf 1e-06 1e-05 -inf 3e-06];
default.qlook.imgs = {[1*ones(4,1),(3:6).'],[2*ones(4,1),(3:6).'],[3*ones(4,1),(3:6).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'sur_pol_180-210MHz_.*thick.xml';
default.name = 'Survey Polarimetric Mode 180-210 MHz';
defaults{end+1} = default;

% thin ice mode
default.qlook.img_comb = [1e-06 -inf 1e-06 3e-06 -inf 1e-06];
default.qlook.imgs = {[1*ones(8,1),(1:8).'],[2*ones(8,1),(1:8).'],[3*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'thinice_180-210MHz_.*thick.xml';
default.name = 'Thin Ice Mode 180-210 MHz';
defaults{end+1} = default;

 % 2 beam imaging mode
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = '^image_180-210MHz_.*thick.xml';
default.name = '2 Beam Image Mode 180-210 MHz';
defaults{end+1} = default;

% 3 beam imaging mode
default.qlook.img_comb = [];
default.qlook.imgs = {[2*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'image3_180-210MHz_.*thick.xml';
default.name = '3 Beam Image Mode 180-210 MHz';
defaults{end+1} = default;

% egrip imaging mode
default.qlook.img_comb = [1e-06 -inf 1e-06 3e-06 -inf 1e-06];
default.qlook.imgs = {[1*ones(8,1),(1:8).'],[2*ones(8,1),(1:8).'],[3*ones(8,1),(1:8).'; 4*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'egrip_image.*.xml';
default.name = 'EGRIP Image 180-210 MHz';
defaults{end+1} = default;

%% Other settings

default.qlook.img_comb = [];
default.qlook.imgs = [];
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;

default.config_regexp = 'survey_180-210MHz_.*DECONV.xml';
default.name = 'Deconv 180-210 MHz';
defaults{end+1} = default;

default.config_regexp = '.*180-210MHz.*';
default.name = 'Other Settings 180-210 MHz';
defaults{end+1} = default;

default.radar.wfs(1).Tsys = [-31.8 -32.1 -31.7 -31.6 -31.2 -30.8 -31.5 -31.1]/1e9;
default.radar.wfs(1).chan_equal_dB = [-4 -4.3 -2.9 -4.6 -1.2 -1.5 -0.9 -2.2];
default.radar.wfs(1).chan_equal_deg = [113.1 64.8 124.3 133.7 108 138.1 71.6 102.9];

default.config_regexp = 'survey_150-520MHz_.*DECONV.xml';
default.name = 'Deconv 150-520 MHz';
defaults{end+1} = default;

default.config_regexp = '.*150-520MHz.*';
default.name = 'Other Settings 150-520 MHz';
defaults{end+1} = default;
