function [param,defaults] = default_radar_params_2022_Antarctica_Ground_accum
% [param,defaults] = default_radar_params_2022_Antarctica_Ground_accum
%
% Accum: 2022_Antarctica_Ground
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Set the param.season_name to the correct season before running.
%
% Author: John Paden

%% Preprocess parameters
param.season_name = '2022_Antarctica_Ground';
param.radar_name = 'accum3';

% Reading in files
param.config.daq_type = 'arena';
param.config.wg_type = 'arena';
param.config.header_load_func = @basic_load_arena;
%param.config.board_map = {'digrx0'}; % H only polarization
param.config.board_map = {'digrx0','digrx1'}; % HV polarization
param.config.tx_map = {'awg0','awg1'};

% Creating segments
param.config.max_time_gap = 10;
param.config.min_seg_size = 1;

% Creating settings files
param.config.max_data_rate = 60;
param.config.max_duty_cycle = 0.1;
param.config.prf_multiple = [10e6 10e6/20]; % Power supply sync signal that PRF must be a factor of these numbers
param.config.PRI_guard = 1e-6;
param.config.PRI_guard_percentage = 450e6/500e6;
param.config.tx_enable = [1 1];
param.config.max_tx = 1.0;
param.config.max_tx_voltage = sqrt(400*50)*10^(-2/20); % voltage at max_tx

%% EAGER 1 ACCUM Arena Parameters
arena = [];
arena.clk = 10e6;
fs = 1000e6;
fs_dac = 2000e6;
subsystem_idx = 0;
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'CTU51';
arena.subsystem(subsystem_idx).subSystem{1} = 'ctu';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'ARENA60';
arena.subsystem(subsystem_idx).subSystem{1} = 'awg0';
arena.subsystem(subsystem_idx).subSystem{2} = 'digrx0';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'ARENA61';
arena.subsystem(subsystem_idx).subSystem{1} = 'awg1';
arena.subsystem(subsystem_idx).subSystem{1} = 'digrx1';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'Data Server';

dac_idx = 0;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg0';
arena.dac(dac_idx).type = 'dac-ad9129_0012';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = -10;
arena.dac(dac_idx).desiredAlignMax = 0;
arena.dac(dac_idx).dcoPhase = 80;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg1';
arena.dac(dac_idx).type = 'dac-ad9129_0012';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = -4;
arena.dac(dac_idx).desiredAlignMax = 6;
arena.dac(dac_idx).dcoPhase = 80;

adc_idx = 0;
adc_idx = adc_idx + 1;
arena.adc(adc_idx).name = 'digrx0';
arena.adc(adc_idx).type = 'adc-ad9680_0017';
arena.adc(adc_idx).sampFreq = fs;
arena.adc(adc_idx).adcMode = 1;
arena.adc(adc_idx).desiredAlignMin = -8;
arena.adc(adc_idx).desiredAlignMax = 2;
arena.adc(adc_idx).stream = 'socket';
arena.adc(adc_idx).ip = '172.16.0.118';
arena.adc(adc_idx).outputSelect = 1;
arena.adc(adc_idx).wf_set = 1;
arena.adc(adc_idx).gain_dB = [0 0];
adc_idx = adc_idx + 1;
arena.adc(adc_idx).name = 'digrx1';
arena.adc(adc_idx).type = 'adc-ad9680_0017';
arena.adc(adc_idx).sampFreq = fs;
arena.adc(adc_idx).adcMode = 1;
arena.adc(adc_idx).desiredAlignMin = -2;
arena.adc(adc_idx).desiredAlignMax = 8;
arena.adc(adc_idx).stream = 'socket';
arena.adc(adc_idx).ip = '172.16.0.118';
arena.adc(adc_idx).outputSelect = 1;
arena.adc(adc_idx).wf_set = 2;
arena.adc(adc_idx).gain_dB = [0 0];

daq_idx = 0;
daq_idx = daq_idx + 1;
arena.daq(daq_idx).name = 'daq0';
arena.daq(daq_idx).type = 'daq_0001';
arena.daq(daq_idx).auxDir = '/data/';
arena.daq(daq_idx).fileStripe = '/data/%b/';
arena.daq(daq_idx).fileName = 'accum';
arena.daq.udp_packet_headers = false;

arena.system.name = 'ku0001';

arena.param.tx_max = [1 1];
arena.param.PA_setup_time = 2e-6; % Time required to enable PA before transmit
arena.param.TTL_time_delay = 0.0; % TTL time delay relative to transmit start
arena.param.ADC_time_delay = 3.0720e-6; % ADC time delay relative to transmit start

arena.psc.type = 'psc_0003';

arena.daq.type = 'daq_0001';

arena.ctu.name = 'ctu';
arena.ctu.type = 'ctu_001D';
if 1
  % External GPS
  arena.ctu.nmea = 31;
  arena.ctu.nmea_baud = 115200;
  arena.ctu.pps = 10;
  arena.ctu.pps_polarity = 1;
else
  % Internal GPS
  arena.ctu.nmea = 60;
  arena.ctu.nmea_baud = 115200;
  arena.ctu.pps = 63;
  arena.ctu.pps_polarity = 1;
end
idx = 0;
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'EPRI';
arena.ctu.out.bit_group(idx).bits = 0;
arena.ctu.out.bit_group(idx).epri = [1 0];
arena.ctu.out.bit_group(idx).pri = [0 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'PRI';
arena.ctu.out.bit_group(idx).bits = 1;
arena.ctu.out.bit_group(idx).epri = [1 0];
arena.ctu.out.bit_group(idx).pri = [1 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'TX_EN'; % 1 enables the transmitter, sets the T/R to transmit
arena.ctu.out.bit_group(idx).bits = 2;
arena.ctu.out.bit_group(idx).epri = [1 0];
arena.ctu.out.bit_group(idx).pri = [1 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'CAL_EN'; % 1 enables rx calibration switch
arena.ctu.out.bit_group(idx).bits = 3;
arena.ctu.out.bit_group(idx).epri = [1 0];
arena.ctu.out.bit_group(idx).pri = [1 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'Atten1_TRISO_NOT_USED'; % unused
arena.ctu.out.bit_group(idx).bits = 4;
arena.ctu.out.bit_group(idx).epri = [0 0];
arena.ctu.out.bit_group(idx).pri = [0 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'LOW_GAIN_EN'; % 1 is low gain
arena.ctu.out.bit_group(idx).bits = 5;
arena.ctu.out.bit_group(idx).epri = [1 1];
arena.ctu.out.bit_group(idx).pri = [1 1];

arena.ctu.out.time_cmd = {'2e-6+param.wfs(wf).Tpd+0.1e-6' '2e-6+param.wfs(wf).Tpd+0.1e-6' '2e-6+param.wfs(wf).Tpd+0.1e-6' '2/param.prf'};

%% Command worksheet
param.cmd.records = 1;
param.cmd.qlook = 1;
param.cmd.generic = 1;

%% Records worksheet
param.records.gps.time_offset = 0;
param.records.frames.geotiff_fn = 'antarctica\Landsat-7\Antarctica_LIMA.tif';
param.records.frames.mode = 1;
param.records.file.version = 103;
param.records.file.prefix = param.radar_name;
param.records.file.suffix = '.bin';
%param.records.file.boards = {'digrx0'}; % H only polarization
param.records.file.boards = {'digrx0','digrx1'}; % HV Polarization
param.records.file.board_folder_name = '%b';
param.records.file.clk = 10e6;

%% Qlook worksheet
param.qlook.out_path = '';
param.qlook.block_size = 5000;
param.qlook.motion_comp = 0;
param.qlook.dec = 20;
param.qlook.inc_dec = 10;
param.qlook.surf.en = 1;
param.qlook.surf.method = 'fixed';
param.qlook.surf.fixed_value = 0;
param.qlook.resample = [2 1];

%% SAR worksheet
param.sar.out_path = '';
param.sar.frm_types = {0,[0 1],0,0,-1};
param.sar.chunk_len = 5000;
param.sar.chunk_overlap = 10;
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
param.radar.adc_bits = 14;
param.radar.Vpp_scale = 1.5;
param.radar.lever_arm_fh = @lever_arm;
for wf = 1:4 
  param.radar.wfs(wf).adc_gains_dB = [38 38]; % ADC gain
  param.radar.wfs(wf).adcs = [1 2]; % ADC to rx path mapping
  param.radar.wfs(wf).rx_paths = [1 2]; % ADC to rx path mapping
  param.radar.wfs(wf).gain_en = [0 0]; % Disable fast-time gain correction
  param.radar.wfs(wf).coh_noise_method = ''; % No coherent noise removal
  param.radar.wfs(wf).Tadc_adjust = 0;
  param.radar.wfs(wf).bit_shifts = [6 8];
end
Tsys = [0 0]/1e9;
chan_equal_dB = [0 0];
chan_equal_deg = [0 0];

%% Post worksheet
param.post.data_dirs = {'qlook'};
param.post.img = 1;
param.post.layer_dir = 'layerData';
param.post.maps_en = 1;
param.post.echo_en = 1;
param.post.layers_en = 0;
param.post.data_en = 0;
param.post.csv_en = 1;
param.post.concat_en = 1;
param.post.pdf_en = 1;
param.post.map.location = 'Antarctica';
param.post.map.type = 'combined';
param.post.echo.elev_comp = 2;
param.post.echo.depth = '[min(Surface_Depth)-100 max(Surface_Depth)+2900]';
% param.post.echo.elev_comp = 3;
% param.post.echo.depth = '[min(Surface_Elev)-1500 max(Surface_Elev)+100]';
param.post.echo.er_ice = 3.15;
param.post.ops.location = 'antarctic';

%% Analysis worksheet
param.analysis_noise.block_size = 10000;
cmd_idx = 0;
cmd_idx = cmd_idx + 1;
param.analysis_noise.cmd{cmd_idx}.method = 'coh_noise';
param.analysis_noise.cmd{cmd_idx}.distance_weight = 1; % Enable distance weighting of the average

%% Radar Settings

defaults = {};

default = param;
default.arena = arena;


% % Survey Mode Shallow Ice
% % Note data_map has unusual ordering with mode 4 first instead of mode 0. This is due to
% % an error in the settings where mode 0 and mode 1 both acquired data that should have only
% % gone to mode 0.
% default.records.data_map = {[4 0 2 1;0 0 1 1;1 0 1 1],[4 0 2 2;0 0 1 2;1 0 1 2;]};
% default.qlook.img_comb = [];
% default.qlook.imgs = {[1 1],[2 1],[1 2],[2 2]};
% default.sar.imgs = default.qlook.imgs;
% default.array.imgs = default.qlook.imgs;
% default.array.img_comb = default.qlook.img_comb;
% default.analysis_noise.imgs = default.qlook.imgs;
% default.radar.ref_fn = '';
% default.radar.wfs = param.radar.wfs(1:2);
% for wf = 1:2
%   default.radar.wfs(wf).Tsys = Tsys;
%   default.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
%   default.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
%   param.radar.wfs(wf).bit_shifts = [7 7];
%   param.radar.wfs(wf).tx_paths = [1 2];
% end
% default.post.echo.depth = '[min(Surface_Depth)-5 max(Surface_Depth)+300]';
% % Note psc config name was incorrectly set, but it is for shallow ice:
% default.config_regexp = 'psc_survey_600-900MHz_0usDelay_2us_LOOPBACK';
% default.name = 'Survey Mode 600-900 MHz Shallow Ice';
% defaults{end+1} = default;

% % Survey Mode Thick Ice Single Polarization
% % Note data_map has unusual ordering with mode 4 first instead of mode 0. This is due to
% % an error in the settings where mode 0 and mode 1 both acquired data that should have only
% % gone to mode 0.
% default.records.arena.total_presums = 300;
% default.records.data_map = {[0 0 1 1;1 0 1 1;2 0 2 1;3 0 2 1]};
% default.qlook.img_comb = [];
% default.qlook.imgs = {[1 1],[2 1]};
% default.sar.imgs = default.qlook.imgs;
% default.array.imgs = default.qlook.imgs;
% default.array.img_comb = default.qlook.img_comb;
% default.analysis_noise.imgs = default.qlook.imgs;
% default.radar.ref_fn = '';
% default.radar.wfs = param.radar.wfs(1:2);
% for wf = 1:2
%   default.radar.wfs(wf).Tsys = Tsys;
%   default.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
%   default.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
%   default.radar.wfs(wf).bit_shifts = [6 8];
%   default.radar.wfs(wf).tx_paths = [1 inf];
% end
% default.post.echo.depth = '[min(Surface_Depth)-5 max(Surface_Depth)+4300]';
% % Note psc config name was incorrectly set, but it is for shallow ice:
% default.config_regexp = 'psc_eager_config';
% default.name = 'Survey Mode 600-900 MHz Thick Ice';
% defaults{end+1} = default;

% Survey Mode Thick Ice Polarimetric
% Note data_map has unusual ordering with mode 4 first instead of mode 0. This is due to
% an error in the settings where mode 0 and mode 1 both acquired data that should have only
% gone to mode 0.
default.records.arena.total_presums = 600;
default.records.data_map = {[0 0 1 1;1 0 1 1;2 0 2 1;3 0 2 1;4 0 3 1;5 0 3 1;6 0 4 1;7 0 4 1], ...
  [0 0 1 2;1 0 1 2;2 0 2 2;3 0 2 2;4 0 3 2;5 0 3 2;6 0 4 2;7 0 4 2]};
default.qlook.img_comb = [];
default.qlook.imgs = {[1 1],[2 1],[3 1],[4 1],[1 2],[2 2],[3 2],[4 2]};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.analysis_noise.imgs = default.qlook.imgs;
default.radar.ref_fn = '';
default.radar.wfs = param.radar.wfs(1:4);
for wf = 1:4
  default.radar.wfs(wf).Tsys = Tsys;
  default.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
  default.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
  default.radar.wfs(wf).bit_shifts = [6 8];
  default.radar.wfs(wf).tx_paths = {[1],[2]};
end
default.post.echo.depth = '[min(Surface_Depth)-5 max(Surface_Depth)+4300]';
% Note psc config name was incorrectly set, but it is for shallow ice:
%default.config_regexp = 'psc_eager_configHV';
default.config_regexp = '.*';
default.name = 'Polarimetric Mode 600-900 MHz Thick Ice';
defaults{end+1} = default;


