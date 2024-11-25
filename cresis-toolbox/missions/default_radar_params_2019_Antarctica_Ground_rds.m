function [param,defaults] = default_radar_params_2019_Antarctica_Ground_rds
% [param,defaults] = default_radar_params_2019_Antarctica_Ground_rds
%
% MCoRDS6: 2019_Antarctica_Ground
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Author: John Paden

%% Preprocess parameters
param.season_name = '2019_Antarctica_Ground';
param.radar_name = 'mcords6';

param.config.daq_type = 'arena';
param.config.wg_type = 'arena';
param.config.header_load_func = @basic_load_arena;
param.config.board_map = {'digrx0','digrx1','digrx2','digrx3'};
param.config.tx_map = {'awg0','awg1','awg2','awg3'};

param.config.file.version = 103;
param.config.file.prefix = param.radar_name;
param.config.file.suffix = '.bin';
param.config.max_time_gap = 10;
param.config.min_seg_size = 1;

param.config.max_data_rate = 60;
param.config.max_duty_cycle = 0.1;
param.config.prf_multiple = [10e6 10e6/20]; % Power supply sync signal that PRF must be a factor of these numbers
param.config.PRI_guard = 1e-6;
param.config.PRI_guard_percentage = 1;
param.config.tx_enable = [1 1 1 1];
param.config.max_tx = 1.0;
param.config.max_tx_voltage = sqrt(1000*50)*10^(-2/20); % voltage at max_tx

%% MCoRDS6 Arena Parameters
arena = [];
fs = 640e6;
fs_dac = 1280e6;
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
arena.subsystem(subsystem_idx).subSystem{1} = 'awg1';
arena.subsystem(subsystem_idx).subSystem{2} = 'digrx1';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'ARENA2';
arena.subsystem(subsystem_idx).subSystem{1} = 'awg2';
arena.subsystem(subsystem_idx).subSystem{2} = 'digrx2';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'ARENA3';
arena.subsystem(subsystem_idx).subSystem{1} = 'awg3';
arena.subsystem(subsystem_idx).subSystem{2} = 'digrx3';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'Data Server';

dac_idx = 0;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg0';
arena.dac(dac_idx).type = 'dac-ad9129_0012';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = -10;
arena.dac(dac_idx).desiredAlignMax = 4;
arena.dac(dac_idx).dcoPhase = 80;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg1';
arena.dac(dac_idx).type = 'dac-ad9129_0012';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = -14;
arena.dac(dac_idx).desiredAlignMax = 0;
arena.dac(dac_idx).dcoPhase = 80;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg2';
arena.dac(dac_idx).type = 'dac-ad9129_0012';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = 4;
arena.dac(dac_idx).desiredAlignMax = 18;
arena.dac(dac_idx).dcoPhase = 80;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg3';
arena.dac(dac_idx).type = 'dac-ad9129_0012';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = 0;
arena.dac(dac_idx).desiredAlignMax = 14;
arena.dac(dac_idx).dcoPhase = 80;

adc_idx = 0;
adc_idx = adc_idx + 1;
arena.adc(adc_idx).name = 'digrx0';
arena.adc(adc_idx).type = 'adc-ad9680_0017';
arena.adc(adc_idx).sampFreq = fs;
arena.adc(adc_idx).adcMode = 2;
arena.adc(adc_idx).desiredAlignMin = -12;
arena.adc(adc_idx).desiredAlignMax = 8;
arena.adc(adc_idx).stream = 'tcp';
arena.adc(adc_idx).ip = '10.0.0.100';
arena.adc(adc_idx).outputSelect = 0;
arena.adc(adc_idx).gain_dB = [2.4 2.4];
adc_idx = adc_idx + 1;
arena.adc(adc_idx).name = 'digrx1';
arena.adc(adc_idx).type = 'adc-ad9680_0017';
arena.adc(adc_idx).sampFreq = fs;
arena.adc(adc_idx).adcMode = 2;
arena.adc(adc_idx).desiredAlignMin = -17;
arena.adc(adc_idx).desiredAlignMax = 3;
arena.adc(adc_idx).stream = 'tcp';
arena.adc(adc_idx).ip = '10.0.0.100';
arena.adc(adc_idx).outputSelect = 0;
arena.adc(adc_idx).gain_dB = [2.4 2.4];
adc_idx = adc_idx + 1;
arena.adc(adc_idx).name = 'digrx2';
arena.adc(adc_idx).type = 'adc-ad9680_0017';
arena.adc(adc_idx).sampFreq = fs;
arena.adc(adc_idx).adcMode = 2;
arena.adc(adc_idx).desiredAlignMin = -21;
arena.adc(adc_idx).desiredAlignMax = -1;
arena.adc(adc_idx).stream = 'tcp';
arena.adc(adc_idx).ip = '10.0.0.100';
arena.adc(adc_idx).outputSelect = 0;
arena.adc(adc_idx).gain_dB = [2.4 2.4];
adc_idx = adc_idx + 1;
arena.adc(adc_idx).name = 'digrx3';
arena.adc(adc_idx).type = 'adc-ad9680_0017';
arena.adc(adc_idx).sampFreq = fs;
arena.adc(adc_idx).adcMode = 2;
arena.adc(adc_idx).desiredAlignMin = -20;
arena.adc(adc_idx).desiredAlignMax = 0;
arena.adc(adc_idx).stream = 'tcp';
arena.adc(adc_idx).ip = '10.0.0.100';
arena.adc(adc_idx).outputSelect = 0;
arena.adc(adc_idx).gain_dB = [2.4 2.4];

daq_idx = 0;
daq_idx = daq_idx + 1;
arena.daq(daq_idx).name = 'daq0';
arena.daq(daq_idx).type = 'daq_0001';
arena.daq(daq_idx).auxDir = '/data/';
arena.daq(daq_idx).fileStripe = '/data/%b/';
arena.daq(daq_idx).fileName = 'mcords';

arena.system.name = 'ku0001';

arena.param.tx_max = [1 1 1 1];
arena.param.PA_setup_time = 2e-6; % Time required to enable PA before transmit
arena.param.TTL_time_delay = 0.0; % TTL time delay relative to transmit start
arena.param.ADC_time_delay = 3.0720e-6; % ADC time delay relative to transmit start
   
% mode 0, subchannel 0, board_idx 1 is wf-adc 1-1
% mode 0, subchannel 0, board_idx 2 is wf-adc 2-1

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
arena.ctu.out.bit_group(idx).epri = [1 0 0];
arena.ctu.out.bit_group(idx).pri = [0 0 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'PRI';
arena.ctu.out.bit_group(idx).bits = 1;
arena.ctu.out.bit_group(idx).epri = [1 0 0];
arena.ctu.out.bit_group(idx).pri = [1 0 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'TR';
arena.ctu.out.bit_group(idx).bits = 2;
arena.ctu.out.bit_group(idx).epri = [1 0 0];
arena.ctu.out.bit_group(idx).pri = [1 0 0];
idx = idx + 1;
arena.ctu.out.bit_group(idx).name = 'Isolation';
arena.ctu.out.bit_group(idx).bits = 3;
arena.ctu.out.bit_group(idx).epri = [1 1 0];
arena.ctu.out.bit_group(idx).pri = [1 1 0];
% idx = idx + 1;
% arena.ctu.out.bit_group(idx).name = 'Atten';
% arena.ctu.out.bit_group(idx).bits = 4:8;
% arena.ctu.out.bit_group(idx).epri = [0 0];
% arena.ctu.out.bit_group(idx).pri = [0 0];

arena.ctu.out.time_cmd = {'2e-6+param.wfs(wf).Tpd+0.5e-6' '2e-6+param.wfs(wf).Tpd+2.5e-6' '2/param.prf'};

param.config.arena = arena;

%% Command worksheet
default.cmd.records = 1;
default.cmd.qlook = 1;
default.cmd.generic = 1;

%% Records worksheet
default.records.gps.time_offset = 0;
default.records.frames.geotiff_fn = 'antarctica/Landsat-7/Antarctica_LIMA_480m.tif';
default.records.frames.mode = 1;

%% Quick Look worksheet
default.qlook.out_path = '';
default.qlook.block_size = 5000;
default.qlook.motion_comp = 0;
default.qlook.dec = 20;
default.qlook.inc_dec = 10;
default.qlook.surf.en = 1;
default.qlook.surf.method = 'fixed';
default.qlook.surf.fixed_value = 0;

%% SAR worksheet
default.sar.out_path = '';
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
default.radar.Vpp_scale = 1.37;
default.radar.Tadc_adjust = 8.3042e-06; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple
default.radar.lever_arm_fh = @lever_arm;
Tsys = [0 0 0 0 0 0 0 0]/1e9;
chan_equal_dB = [0 0 0 0 0 0 0 0];
chan_equal_deg = [0 0 0 0 0 0 0 0];

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
default.post.echo.depth = '[min(Surface_Depth)-10 max(Surface_Depth)+4500]';
% default.post.echo.elev_comp = 3;
% default.post.echo.depth = '[min(Surface_Elev)-4500 max(Surface_Elev)+10]';
default.post.echo.er_ice = 3.15;
default.post.ops.location = 'antarctic';

%% Analysis worksheet
default.analysis.block_size = 5000;
default.analysis.imgs = {[1*ones(8,1),(1:8).'],[2*ones(8,1),(1:8).'],[3*ones(8,1),(1:8).']};
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
default.analysis.cmd{cmd_idx}.start_time = 's=es.Tend-es.Tpd-3e-6;';
default.analysis.cmd{cmd_idx}.stop_time = 's=es.Tend-es.Tpd;';
default.analysis.cmd{cmd_idx}.stats = {@(x)mean(abs(fft(x)).^2,2)  @(x)mean(abs(fft(fir_dec(x,10))).^2,2)  @(x)mean(abs(fft(fir_dec(x,100))).^2,2)};
cmd_idx = cmd_idx + 1;
default.analysis.cmd{cmd_idx}.method = 'statistics';
default.analysis.cmd{cmd_idx}.out_path = 'analysis_max';
default.analysis.cmd{cmd_idx}.block_ave = 1;
default.analysis.cmd{cmd_idx}.pulse_comp = 1;
default.analysis.cmd{cmd_idx}.start_time = 's=min(es.Tend-2*es.Tpd,es.Tpd+6e-6);';
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

% Noise Mode
default.records.data_map = {[2 0 1 1;2 1 1 2;5 0 2 1;5 1 2 2;8 0 3 1;8 1 3 2],[2 0 1 3;2 1 1 4;5 0 2 3;5 1 2 4;8 0 3 3;8 1 3 4],[2 0 1 5;2 1 1 6;5 0 2 5;5 1 2 6;8 0 3 5;8 1 3 6],[2 0 1 7;2 1 1 8;5 0 2 7;5 1 2 8;8 0 3 7;8 1 3 8]};
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(8,1),(1:8).'],[2*ones(8,1),(1:8).'],[3*ones(8,1),(1:8).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.ref_fn = '';
for wf = 1:3
  default.radar.wfs(wf).Tsys = Tsys;
  default.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
  default.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
  default.radar.wfs(wf).adcs = [1 2 3 4 5 6 7 8];
  default.radar.wfs(wf).rx_paths = [2 4 1 3 5 6 7 8];
  default.radar.wfs(wf).tx_paths = [1 2 3 4];
  default.radar.wfs(wf).adc_gains_dB = [45 45 45 45 45 45 45 45]; % Gain from the first LNA to the ADC
end

default.config_regexp = '.*NOISE.*';
default.name = 'Noise Mode 180-210 MHz';
defaults{end+1} = default;

% Survey Mode
default.records.data_map = {[2 0 1 1;2 1 1 2;5 0 2 1;5 1 2 2;8 0 3 1;8 1 3 2],[2 0 1 3;2 1 1 4;5 0 2 3;5 1 2 4;8 0 3 3;8 1 3 4],[2 0 1 5;2 1 1 6;5 0 2 5;5 1 2 6;8 0 3 5;8 1 3 6],[2 0 1 7;2 1 1 8;5 0 2 7;5 1 2 8;8 0 3 7;8 1 3 8]};
default.qlook.img_comb = [3e-6 -inf 0.5e-6 10e-06 -inf 3e-06];
default.qlook.imgs = {[1*ones(8,1),(1:8).'],[2*ones(8,1),(1:8).'],[3*ones(8,1),(1:8).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
for wf = 1:3
  default.radar.wfs(wf).Tsys = Tsys;
  default.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
  default.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
  default.radar.wfs(wf).adcs = [1 2 3 4 5 6 7 8];
  default.radar.wfs(wf).rx_paths = [7 8 1 2 3 4 5 6];
  default.radar.wfs(wf).tx_paths = [1 2 3 4];
  default.radar.wfs(wf).adc_gains_dB = [46 46 46 46 46 46 46 46]; % Gain from the first LNA to the ADC
end

default.config_regexp = '.*survey.*';
default.name = 'Survey Mode 180-210 MHz';
defaults{end+1} = default;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PingPong Mode

default.records.data_map = {[2 0 1 1; 2 1 1 2; 5 0 2 1; 5 1 2 2; 8 0 3 1; 8 1 3 2; 11 0 4 1; 11 1 4 2],[2 0 ...
  1 3; 2 1 1 4; 5 0 2 3; 5 1 2 4; 8 0 3 3; 8 1 3 4; 11 0 4 3; 11 1 4 4],[2 0 1 5; 2 1 1 6; 5 0 2 5; 5 1 2 6; 8 0 3 ...
  5; 8 1 3 6; 11 0 4 5; 11 1 4 6],[2 0 1 7; 2 1 1 8; 5 0 2 7; 5 1 2 8; 8 0 3 7; 8 1 3 8; 11 0 4 7; 11 1 4 8]};
default.qlook.img_comb = [3e-6 -inf 0.5e-6 10e-06 -inf 3e-06];
default.qlook.imgs = {[1*ones(8,1),(1:8).'],[2*ones(8,1),(1:8).'],[[3*ones(8,1),(1:8).'];[4*ones(8,1),(1:8).']]};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
for wf = 1:4
  default.radar.wfs(wf).Tsys = Tsys;
  default.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
  default.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
  default.radar.wfs(wf).adcs = [1 2 3 4 5 6 7 8];
  default.radar.wfs(wf).rx_paths = [7 8 1 2 3 4 5 6];
  default.radar.wfs(wf).tx_paths = [1 2 3 4];
  default.radar.wfs(wf).adc_gains_dB = [46 46 46 46 46 46 46 46]; % Gain from the first LNA to the ADC
end
default.config_regexp = '.*pingpong.*';
default.name = 'Ping Pong Mode 180-210 MHz';
defaults{end+1} = default;


% Other settings
default.records.data_map = {[2 0 1 1;2 1 1 2;5 0 2 1;5 1 2 2;8 0 3 1;8 1 3 2],[2 0 1 3;2 1 1 4;5 0 2 3;5 1 2 4;8 0 3 3;8 1 3 4],[2 0 1 5;2 1 1 6;5 0 2 5;5 1 2 6;8 0 3 5;8 1 3 6],[2 0 1 7;2 1 1 8;5 0 2 7;5 1 2 8;8 0 3 7;8 1 3 8]};
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(8,1),(1:8).'],[2*ones(8,1),(1:8).'],[3*ones(8,1),(1:8).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.ref_fn = '';
for wf = 1:3
  default.radar.wfs(wf).Tsys = Tsys;
  default.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
  default.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
  default.radar.wfs(wf).adcs = [1 2 3 4 5 6 7 8];
  default.radar.wfs(wf).rx_paths = [2 4 1 3 5 6 7 8];
  default.radar.wfs(wf).tx_paths = [1 2 3 4];
  default.radar.wfs(wf).adc_gains_dB = [46 46 46 46 46 46 46 46]; % Gain from the first LNA to the ADC
end

default.config_regexp = '.*';
default.name = 'Default 180-210 MHz';
defaults{end+1} = default;

%% Add default settings

param.config.defaults = defaults;
