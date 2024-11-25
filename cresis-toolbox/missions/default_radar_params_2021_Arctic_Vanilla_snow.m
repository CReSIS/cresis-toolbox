function param = default_radar_params_2021_Arctic_Vanilla_snow
% param = default_radar_params_2021_Arctic_Vanilla_snow
%
% Snow: 2021_Arctic_Vanilla
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Author: John Paden

%% Preprocess parameters
param.season_name = '2021_Arctic_Vanilla';
param.radar_name = 'snow9';

param.config.file.version = 9;
param.config.file.prefix = '';
param.config.file.suffix = '.dat';
param.config.max_time_gap = 10;
param.config.min_seg_size = 2;

param.config.daq_type = 'arena';
param.config.wg_type = 'arena';
param.config.header_load_func = @basic_load_arena;
param.config.board_map = {'digrx0'};
param.config.tx_map = {'awg0'};

param.config.daq.xml_version = -1; % No XML file available

param.config.tx_enable = [1];

%% VANILLA SNOW Arena Parameters
arena = [];
arena.clk = 10e6;
fs = 1000e6;
fs_dac = 2000e6;
subsystem_idx = 0;
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'ARENA0';
arena.subsystem(subsystem_idx).subSystem{1} = 'ctu';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'ARENA0';
arena.subsystem(subsystem_idx).subSystem{1} = 'awg0';
arena.subsystem(subsystem_idx).subSystem{2} = 'digrx0';
subsystem_idx = subsystem_idx + 1;
arena.subsystem(subsystem_idx).name = 'Data Server';

dac_idx = 0;
dac_idx = dac_idx + 1;
arena.dac(dac_idx).name = 'awg0';
arena.dac(dac_idx).type = 'dac-ad9129_0012';
arena.dac(dac_idx).dacClk = fs_dac;
arena.dac(dac_idx).desiredAlignMin = -5;
arena.dac(dac_idx).desiredAlignMax = 5;
arena.dac(dac_idx).dcoPhase = 0;

adc_idx = 0;
adc_idx = adc_idx + 1;
arena.adc(adc_idx).name = 'digrx0';
arena.adc(adc_idx).type = 'adc-ad9680_0017';
arena.adc(adc_idx).sampFreq = fs;
arena.adc(adc_idx).adcMode = 1;
arena.adc(adc_idx).desiredAlignMin = -6;
arena.adc(adc_idx).desiredAlignMax = 10;
arena.adc(adc_idx).stream = 'file';
arena.adc(adc_idx).ip = '10.0.0.51';
arena.adc(adc_idx).outputSelect = 1;
arena.adc(adc_idx).wf_set = 1;
arena.adc(adc_idx).gain_dB = [-6 -6];
%          <dataStream type="file">
%             <id>0</id>
%             <name>dataStream0</name>
%             <filename>f0</filename>
%             <config>NewItem</config>
%          </dataStream>


daq_idx = 0;
daq_idx = daq_idx + 1;
arena.daq(daq_idx).name = 'daq0';
arena.daq(daq_idx).type = 'daq_0001';
arena.daq(daq_idx).auxDir = '/data/';
arena.daq(daq_idx).fileStripe = '/data/%b/';
arena.daq(daq_idx).fileName = 'accum3';

arena.system.name = 'ku0002';

arena.param.tx_max = [1 1];
arena.param.PA_setup_time = 2e-6; % Time required to enable PA before transmit
arena.param.TTL_time_delay = 0.0; % TTL time delay relative to transmit start
arena.param.ADC_time_delay = 3.0720e-6; % ADC time delay relative to transmit start

arena.psc.type = 'psc_0003';

arena.daq.type = 'daq_0001';

arena.ctu.name = 'ctu00';
arena.ctu.type = 'ctu_0032';
if 1
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
default.records.file.boards = [1];
default.records.frames.geotiff_fn = fullfile('greenland','Landsat-7','Greenland_natural_150m.tif');
default.records.frames.mode = 2;
default.records.gps.en = 1;
default.records.gps.time_offset = 1;

%% Qlook worksheet
default.qlook.img_comb = [];
default.qlook.imgs = {[1 1]};
default.qlook.out_path = '';
default.qlook.block_size = 2000;
default.qlook.motion_comp = 0;
default.qlook.dec = 4;
default.qlook.inc_dec = 5;
default.qlook.surf.en = 1;
default.qlook.surf.profile = 'SNOW_AWI';

%% SAR worksheet
default.sar.out_path = '';
default.sar.imgs = default.qlook.imgs;
default.sar.frm_types = {0,[0 1],0,0,-1};
default.sar.chunk_len = 2000;
default.sar.combine_rx = 0;
default.sar.time_of_full_support = 4e-6;
default.sar.mocomp.en = 1;
default.sar.mocomp.type = 2;
default.sar.mocomp.filter = {@butter  [2]  [0.1000]};
default.sar.mocomp.uniform_en = 1;
default.sar.sar_type = 'fk';
default.sar.sigma_x = 1;
default.sar.sub_aperture_steering = 0;
default.sar.st_wind = @hanning;
default.sar.start_eps = 3.15;

%% Array worksheet
default.array.in_path = '';
default.array.array_path = '';
default.array.out_path = '';
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.array.method = 'standard';
default.array.window = @hanning;
default.array.bin_rng = 0;
default.array.line_rng = -2:2;
default.array.dbin = 1;
default.array.dline = 5;
default.array.DCM = [];

%% Radar worksheet
default.radar.prf = 1/256e-6;
default.radar.fs = 1000e6;
default.radar.adc_bits = 14;
default.radar.Vpp_scale = 2; % Digital receiver gain is 5, full scale Vpp is 2
default.radar.lever_arm_fh = @lever_arm;
chan_equal_Tsys = [0]/1e9;
chan_equal_dB = [0];
chan_equal_deg = [0];
for wf = 1:1
  default.radar.wfs(wf).tx_weights = 1; % Watts
  default.radar.wfs(wf).Tadc_adjust = []; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple
  default.radar.wfs(wf).adc_gains_dB = 105.8; % Radiometric calibration to 1/R^2
  default.radar.wfs(wf).rx_paths = [1]; % ADC to rx path mapping
  default.radar.wfs(wf).ref_fn = '';
  default.radar.wfs(wf).chan_equal_Tsys = chan_equal_Tsys;
  default.radar.wfs(wf).chan_equal_dB = chan_equal_dB;
  default.radar.wfs(wf).chan_equal_deg = chan_equal_deg;
  default.radar.wfs(wf).adcs = [1];
  default.radar.wfs(wf).coh_noise_method = 'estimated';
  default.radar.wfs(wf).nz_trim = {[0 0],[0 0],[0 0],[0 0]};
  default.radar.wfs(wf).nz_valid = [0 1 2 3];
end

%% Post worksheet
default.post.data_dirs = {'qlook'};
default.post.layer_dir = 'layerData';
default.post.maps_en = 1;
default.post.echo_en = 1;
default.post.layers_en = 0;
default.post.data_en = 0;
default.post.csv_en = 0;
default.post.concat_en = 0;
default.post.pdf_en = 0;
default.post.map.location = 'Greenland';
default.post.map.type = 'combined';
default.post.echo.elev_comp = 2;
default.post.echo.depth = '[min(Surface_Depth)-2 max(Surface_Depth)+25]';
% default.post.echo.elev_comp = 3;
% default.post.echo.depth = '[min(Surface_Elev)-25 max(Surface_Elev)+2]';
default.post.echo.er_ice = round((1+0.51*0.3)^3 * 100)/100;
default.post.ops.location = 'arctic';
  
%% Radar Settings

defaults = {};

% Survey Mode 2-8 GHz
default.records.data_map = {[0 0 1 1]};
default.radar.wfs(1).f0 = 500e6;
default.radar.wfs(1).f1 = 750e6;
default.radar.wfs(1).fmult = 24;
default.radar.wfs(1).fLO = -10e9
default.radar.wfs(1).Tpd = 180e-6;
default.radar.wfs(1).BW_window = [2e9 8e9];
default.radar.wfs(1).t_ref = 0;
default.radar.wfs(1).tx_paths = [1];

default.config_regexp = '.*';
default.name = 'Survey Mode 2-8 GHz';
defaults{end+1} = default;

%% Add default settings

param.config.defaults = defaults;
