function param = default_radar_params_2018_Antarctica_TObas_accum
% param = default_radar_params_2018_Antarctica_TObas_accum
%
% Accum: 2018_Antarctica_TObas and 2019_Antarctica_TObas
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Set the param.season_name to the correct season before running.
%
% Author: John Paden

%% Preprocess parameters
param.season_name = '2019_Antarctica_TObas';
param.radar_name = 'accum3';

param.config.daq_type = 'arena';
param.config.wg_type = 'arena';
param.config.header_load_func = @basic_load_arena;
param.config.board_map = {'digrx0','digrx1'};
param.config.tx_map = {'awg0'};

param.config.file.version = 103;
param.config.file.prefix = param.radar_name;
param.config.file.suffix = '.bin';
param.config.max_time_gap = 10;
param.config.min_seg_size = 1;

param.config.max_data_rate = 60;
param.config.max_duty_cycle = 0.1;
param.config.prf_multiple = [10e6 10e6/20]; % Power supply sync signal that PRF must be a factor of these numbers
param.config.PRI_guard = 1e-6;
param.config.PRI_guard_percentage = 450e6/500e6;
param.config.tx_enable = [1];
param.config.max_tx = 1.0;
param.config.max_tx_voltage = sqrt(400*50)*10^(-2/20); % voltage at max_tx

%% BAS ACCUM Arena Parameters
arena = [];
arena.clk = 10e6;
fs = 1000e6;
fs_dac = 2000e6;
subsystem_idx = 0;
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'ARENA-CTU';
arena.subsystem(subsystem_idx).subSystem{1} = 'ctu';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'ARENA0';
arena.subsystem(subsystem_idx).subSystem{1} = 'awg0';
arena.subsystem(subsystem_idx).subSystem{2} = 'digrx0';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'ARENA1';
arena.subsystem(subsystem_idx).subSystem{1} = 'digrx1';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'Data Server';

dac_idx = 0;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg0';
arena.dac(dac_idx).type = 'dac-ad9129_0012';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = -4;
arena.dac(dac_idx).desiredAlignMax = 10;
arena.dac(dac_idx).dcoPhase = 80;

adc_idx = 0;
adc_idx = adc_idx + 1;
arena.adc(adc_idx).name = 'digrx0';
arena.adc(adc_idx).type = 'adc-ad9680_0017';
arena.adc(adc_idx).sampFreq = fs;
arena.adc(adc_idx).adcMode = 1;
arena.adc(adc_idx).desiredAlignMin = -15;
arena.adc(adc_idx).desiredAlignMax = 0;
arena.adc(adc_idx).stream = 'socket';
arena.adc(adc_idx).ip = '10.0.0.100';
arena.adc(adc_idx).outputSelect = 1;
arena.adc(adc_idx).wf_set = 1;
arena.adc(adc_idx).gain_dB = [0 0];
adc_idx = adc_idx + 1;
arena.adc(adc_idx).name = 'digrx1';
arena.adc(adc_idx).type = 'adc-ad9680_0017';
arena.adc(adc_idx).sampFreq = fs;
arena.adc(adc_idx).adcMode = 1;
arena.adc(adc_idx).desiredAlignMin = -14;
arena.adc(adc_idx).desiredAlignMax = -0;
arena.adc(adc_idx).stream = 'socket';
arena.adc(adc_idx).ip = '10.0.0.100';
arena.adc(adc_idx).outputSelect = 1;
arena.adc(adc_idx).wf_set = 2;
arena.adc(adc_idx).gain_dB = [0 0];

daq_idx = 0;
daq_idx = daq_idx + 1;
arena.daq(daq_idx).name = 'daq0';
arena.daq(daq_idx).type = 'daq_0001';
arena.daq(daq_idx).auxDir = '/data/';
arena.daq(daq_idx).fileStripe = '/data/%b/';
arena.daq(daq_idx).fileName = 'accum3';

arena.system.name = 'ku0001';

arena.param.tx_max = [1 1];
arena.param.PA_setup_time = 2e-6; % Time required to enable PA before transmit
arena.param.TTL_time_delay = 0.0; % TTL time delay relative to transmit start
arena.param.ADC_time_delay = 3.0720e-6; % ADC time delay relative to transmit start

arena.psc.type = 'psc_0003';

arena.daq.type = 'daq_0001';

arena.ctu.name = 'ctu';
arena.ctu.type = 'ctu_001D';
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
arena.ctu.out.bit_group(idx).name = 'TR';
arena.ctu.out.bit_group(idx).bits = 2;
arena.ctu.out.bit_group(idx).epri = [1 0];
arena.ctu.out.bit_group(idx).pri = [1 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'CalSwitch';
arena.ctu.out.bit_group(idx).bits = 3;
arena.ctu.out.bit_group(idx).epri = [1 0];
arena.ctu.out.bit_group(idx).pri = [1 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'AttenFirst18dB'; % 1 is low gain/disables attenuator
arena.ctu.out.bit_group(idx).bits = 4;
arena.ctu.out.bit_group(idx).epri = [0 0];
arena.ctu.out.bit_group(idx).pri = [0 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'AttenSecond7dB'; % 1 is high gain/disables attenuator
arena.ctu.out.bit_group(idx).bits = 5;
arena.ctu.out.bit_group(idx).epri = [1 1];
arena.ctu.out.bit_group(idx).pri = [1 1];

arena.ctu.out.time_cmd = {'2e-6+param.wfs(wf).Tpd+0.1e-6' '2/param.prf'};

param.config.arena = arena;

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
default.qlook.surf.profile = 'ACCUM';

%% SAR worksheet
default.sar.out_path = '';
default.sar.imgs = {[1*ones(4,1),(1:4).'],[2*ones(4,1),(1:4).']};
default.sar.frm_types = {0,[0 1],0,0,-1};
default.sar.chunk_len = 5000;
default.sar.chunk_overlap = 10;
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
default.radar.adc_bits = 14;
default.radar.Vpp_scale = 1.5; % Digital receiver gain is 5, full scale Vpp is 2
default.radar.Tadc_adjust = -189e-9; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple
default.radar.lever_arm_fh = @lever_arm;
% default.radar.wfs(1).adc_gains_dB = 27; % Gain from the first LNA to the ADC
% default.radar.wfs(2).adc_gains_dB = 45; % Gain from the first LNA to the ADC
default.radar.wfs(1).adc_gains_dB = 32.7; % After radiometric calibration
default.radar.wfs(2).adc_gains_dB = 50.7; % After radiometric calibration
default.radar.wfs(1).rx_paths = [1]; % ADC to rx path mapping for wf 1
default.radar.wfs(2).rx_paths = [1]; % ADC to rx path mapping for wf 2
Tsys = [0]/1e9;
chan_equal_dB = [0];
chan_equal_deg = [0];

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

%% Analysis worksheet
default.analysis.block_size = 5000;
default.analysis.imgs = {[1 1],[2 1]};
cmd_idx = 0;
cmd_idx = cmd_idx + 1;
default.analysis.cmd{cmd_idx}.method = 'statistics';
default.analysis.cmd{cmd_idx}.out_path = 'analysis_mean';
default.analysis.cmd{cmd_idx}.block_ave = 1000;
default.analysis.cmd{cmd_idx}.stats = {@(x)nanmean(x.*conj(x),2)};
cmd_idx = cmd_idx + 1;
default.analysis.cmd{cmd_idx}.method = 'statistics';
default.analysis.cmd{cmd_idx}.out_path = 'analysis_freq';
default.analysis.cmd{cmd_idx}.block_ave = 1000;
default.analysis.cmd{cmd_idx}.start_time = 's=es.Tend-es.Tpd-2e-6;';
default.analysis.cmd{cmd_idx}.stop_time = 's=es.Tend-es.Tpd;';
default.analysis.cmd{cmd_idx}.stats = {@(x)mean(abs(fft(x)).^2,2)  @(x)mean(abs(fft(fir_dec(x,10))).^2,2)  @(x)mean(abs(fft(fir_dec(x,100))).^2,2)};
cmd_idx = cmd_idx + 1;
default.analysis.cmd{cmd_idx}.method = 'statistics';
default.analysis.cmd{cmd_idx}.out_path = 'analysis_max';
default.analysis.cmd{cmd_idx}.block_ave = 1;
default.analysis.cmd{cmd_idx}.pulse_comp = 1;
default.analysis.cmd{cmd_idx}.stats = {'analysis_task_stats_max'};
cmd_idx = cmd_idx + 1;
default.analysis.cmd{cmd_idx}.method = 'statistics';
default.analysis.cmd{cmd_idx}.en = 0;
default.analysis.cmd{cmd_idx}.out_path = 'analysis_kx';
default.analysis.cmd{cmd_idx}.block_ave = 5000;
default.analysis.cmd{cmd_idx}.stats = {'analysis_task_stats_kx'};
default.analysis.cmd{cmd_idx}.kx = 1000;


%% Radar Settings

defaults = {};

% Deconvolution Mode
default.records.data_map = {[2 0 1 1],[2 0 2 1]};
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(1,1),(1:1).'],[2*ones(1,1),(1:1).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.ref_fn = '';
for wf = 1:2
  default.radar.wfs(wf).Tsys = Tsys;
  default.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
  default.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
  default.radar.wfs(wf).adcs = [1];
  default.radar.wfs(wf).tx_paths = [1];
end

default.config_regexp = '.*deconv.*';
default.name = 'Deconv Mode 600-900 MHz';
defaults{end+1} = default;

% Noise Mode
default.records.data_map = {[2 0 1 1],[2 0 2 1]};
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(1,1),(1:1).'],[2*ones(1,1),(1:1).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.ref_fn = '';
for wf = 1:2
  default.radar.wfs(wf).Tsys = Tsys;
  default.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
  default.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
  default.radar.wfs(wf).adcs = [1];
  default.radar.wfs(wf).tx_paths = [1];
end

default.config_regexp = '.*noise.*';
default.name = 'Noise Mode 600-900 MHz';
defaults{end+1} = default;

% Loopback Mode
default.records.data_map = {[2 0 1 1],[2 0 2 1]};
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(1,1),(1:1).'],[2*ones(1,1),(1:1).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.ref_fn = '';
for wf = 1:2
  default.radar.wfs(wf).Tsys = Tsys;
  default.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
  default.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
  default.radar.wfs(wf).adcs = [1];
  default.radar.wfs(wf).tx_paths = [1];
end

default.config_regexp = '.*loopback.*';
default.name = 'Loopback Mode 600-900 MHz';
defaults{end+1} = default;

% Survey Mode
default.records.data_map = {[2 0 1 1],[2 0 2 1]};
default.qlook.img_comb = [2e-06 -inf 2e-06];
default.qlook.imgs = {[1*ones(1,1),(1:1).'],[2*ones(1,1),(1:1).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.ref_fn = '';
for wf = 1:2
  default.radar.wfs(wf).Tsys = Tsys;
  default.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
  default.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
  default.radar.wfs(wf).adcs = [1];
  default.radar.wfs(wf).tx_paths = [1];
end

default.config_regexp = '.*survey.*';
default.name = 'Survey Mode 600-900 MHz';
defaults{end+1} = default;

% Other settings
default.records.data_map = {[2 0 1 1],[2 0 2 1]};
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(1,1),(1:1).'],[2*ones(1,1),(1:1).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.ref_fn = '';
for wf = 1:2
  default.radar.wfs(wf).Tsys = Tsys;
  default.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
  default.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
  default.radar.wfs(wf).adcs = [1];
  default.radar.wfs(wf).tx_paths = [1];
end

default.config_regexp = '.*';
default.name = 'Default 600-900 MHz';
defaults{end+1} = default;

%% Add default settings

param.config.defaults = defaults;
