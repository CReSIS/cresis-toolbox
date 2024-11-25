function [param] = default_radar_params_2019_Antarctica_Polar6_mcords
% [param] = default_radar_params_2019_Antarctica_Polar6_mcords
%
% MCORDS 5: 2018 Greenland Polar6
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Author: John Paden

param.season_name = '2019_Antarctica_Polar6';
param.radar_name = 'mcords5';

%% CReSIS parameters
param.config.file.version = 407;
param.config.file.prefix = param.radar_name;
param.config.file.suffix = '.bin';
param.config.max_time_gap = 10;
param.config.min_seg_size = 2;

param.config.daq_type = 'cresis';
param.config.wg_type = 'cresis';
param.config.header_load_func = @basic_load_mcords5;
param.config.board_map = {'chan1','chan2','chan3','chan4','chan5','chan6','chan7','chan8'};
param.config.tx_map = {'','','','','','','',''};

param.config.daq.xml_version = 2.0;

param.config.max_data_rate = 100;
param.config.max_duty_cycle = 0.12;
param.config.prf_multiple = []; % Power supply sync signal that PRF must be a factor of these numbers
param.config.PRI_guard = 10e-6;
param.config.PRI_guard_percentage = 1;
param.config.tx_enable = [1 1 1 1 1 1 1 0];
param.config.max_tx = [4000 4000 4000 4000 4000 4000 4000 4000];
param.config.max_tx_voltage = sqrt([500 500 1000 1000 1000 1000 500 500]*50)*10^(-2/20); % voltage at max_tx

%% CReSIS parameters
param.config.cresis.clk = 200e6;
param.config.cresis.rx_gain_dB = 48;
param.config.cresis.gps_file_mask = 'GPS*';


%% Control parameters (not used in the parameter spreadsheet directly)
% default.xml_file_prefix = 'mcords5';
% default.data_file_prefix = 'mcords5';
% default.header_load_func = @basic_load_mcords5;
% default.header_load_params = struct('clk',1600e6,'presum_bug_fixed',true);
% default.xml_version = 2.0;
% 
% default.noise_50ohm = [-39.8	-41.0	-40.1	-39.6	-38.4	-39.1	-38.3	-39.6	];
% 
% default.Pt = (4*1000 + 4*500) * sum(chebwin(8,30).^2)/8;
% default.Gt = 8*4;
% default.Ae = 2*0.468 * 0.468;
% 
% default.system_loss_dB = 10.^(-5.88/10);
% default.max_DDS_RAM = 4000;
% default.tx_voltage = sqrt(1000*50)*10^(-2/20);
% 
% default.iq_mode = 0;
% default.tx_DDS_mask = [1 1 1 1 1 1 1 1];
% 
% default.radar_worksheet_headers = {'Tpd','Tadc','Tadc_adjust','f0','f1','ft_dec','ref_fn','tukey','tx_weights','rx_paths','adc_gains','chan_equal_dB','chan_equal_deg','Tsys','DC_adjust','DDC_mode','DDC_freq','bit_shifts'};
% default.radar_worksheet_headers_type = {'r','r','r','r','r','r','r','r','r','r','r','r','r','r','r','r','r','r'};
% 
% default.basic_surf_track_min_time = 2e-6; % Normally 0e-6 for lab test, 2e-6 for flight test
% default.basic_surf_track_Tpd_factor = 1.1; % Normally -inf for lab test, 1.1 for flight test
% default.adc_folder_name = 'chan%d';
% 
% if 1
%   % Example 1: Normal configuration:
%   %   Connect antenna N to WFG N for all N = 1 to 8
%   ref_adc = 1;
%   default.txequal.img = [(1:8).', ref_adc*ones(8,1)];
%   default.txequal.ref_wf_adc = 4;
%   default.txequal.wf_mapping = [1 2 3 4 5 6 7 8];
%   default.txequal.Hwindow_desired = chebwin(8,30).';
%   default.txequal.max_DDS_amp = [4000 4000 4000 4000 4000 4000 4000 4000];
%   default.txequal.time_delay_desired = [0 0 0 0 0 0 0 0];
%   default.txequal.phase_desired = [0 0 0 0 0 0 0 0];
%   default.txequal.time_validation = [0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4]*1e-9;
%   default.txequal.amp_validation = [3 3 3 3 3 3 3 3];
%   default.txequal.phase_validation = [35 35 35 35 35 35 35 35];
%   default.txequal.remove_linear_phase_en = true;
% elseif 0
%   % Channel 4 ADC is bad:
%   ref_adc = 5;
%   default.txequal.img = [(1:8).', ref_adc*ones(8,1)];
%   default.txequal.ref_wf_adc = 4;
%   default.txequal.wf_mapping = [1 2 3 4 5 6 7 8];
%   default.txequal.Hwindow_desired = chebwin(8,30).';
%   default.txequal.max_DDS_amp = [4000 4000 4000 4000 4000 4000 4000 4000];
%   default.txequal.time_delay_desired = [0 0 0 0 0 0 0 0];
%   default.txequal.phase_desired = [0 0 0 0 0 0 0 0];
%   default.txequal.time_validation = [0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4]*1e-9;
%   default.txequal.amp_validation = [3 3 3 3 3 3 3 3];
%   default.txequal.phase_validation = [35 35 35 35 35 35 35 35];
%   default.txequal.remove_linear_phase_en = true;
% elseif 0
%   % DDS 3 is not used, but create settings not changed:
%   %   Connect antenna 1 to a 50 oxhm load
%   %   Connect antenna 2 to WFG 1
%   %   Connect antenna 3 to WFG 2
%   ref_adc = 4;
%   default.txequal.img = [(1:8).', ref_adc*ones(8,1)];
%   default.txequal.wf_mapping = [1 2 0 4 5 6 7 8];
%   default.txequal.ref_wf_adc = 4;
%   default.txequal.Hwindow_desired = chebwin(7,30).';
%   default.txequal.max_DDS_amp = [4000 4000 0 4000 4000 4000 4000 4000];
%   default.txequal.time_delay_desired = [0 0 0 0 0 0 0 0];
%   default.txequal.phase_desired = [0 0 0 0 0 0 0 0];
%   default.txequal.time_validation = [0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4]*1e-9;
%   default.txequal.amp_validation = [3 3 3 3 3 3 3 3];
%   default.txequal.phase_validation = [35 35 35 35 35 35 35 35];
%   default.txequal.remove_linear_phase_en = true;
% elseif 0
%   % DDS 3 to 8 are not used and ADC's 3 to 24 are not used, create settings
%   % also only uses first two DDS
%   ref_adc = 1;
%   default.txequal.img = [(1:2).', ref_adc*ones(2,1)];
%   default.wf_mapping = [1 2 0 0 0 0 0 0];
%   default.txequal.ref_wf_adc = 1;
%   default.txequal.Hwindow_desired = [1 1];
%   default.txequal.max_DDS_amp = [4000 4000 0 0 0 0 0 0];
%   default.txequal.time_delay_desired = [0 0 0 0 0 0 0 0];
%   default.txequal.phase_desired = [0 0 0 0 0 0 0 0];
%   default.txequal.time_validation = [0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4]*1e-9;
%   default.txequal.amp_validation = [3 3 3 3 3 3 3 3];
%   default.txequal.phase_validation = [35 35 35 35 35 35 35 35];
%   default.txequal.remove_linear_phase_en = false;
% end

%% AWI MCoRDS Arena Parameters
arena.awg = [];
arena.awg(end+1).awg = 0;
arena.awg(end).dacs = [0 1];
arena.awg(end).dacClk = [1600e6 1600e6];
arena.awg(end).desiredAlignMin = [3 10];
arena.awg(end).desiredAlignMax = [17 24];
arena.awg(end+1).awg = 1;
arena.awg(end).dacs = [2 3];
arena.awg(end).dacClk = [1600e6 1600e6];
arena.awg(end).desiredAlignMin = [-3 11];
arena.awg(end).desiredAlignMax = [11 25];
arena.awg(end+1).awg = 2;
arena.awg(end).dacs = [4 5];
arena.awg(end).dacClk = [1600e6 1600e6];
arena.awg(end).desiredAlignMin = [4 10];
arena.awg(end).desiredAlignMax = [18 24];
arena.awg(end+1).awg = 3;
arena.awg(end).dacs = [6 7];
arena.awg(end).dacClk = [1600e6 1600e6];
arena.awg(end).desiredAlignMin = [3 13];
arena.awg(end).desiredAlignMax = [17 27];
arena.dacs = [0 1 2 3 4 5 6 7];
arena.dacs_sampFreq = [1600e6 1600e6 1600e6 1600e6 1600e6 1600e6 1600e6 1600e6];
arena.max_tx = [0.63 0.63 0.63 0.63 0.63 0.63 0.63 0.63];
arena.zeropimods = [0 180];
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

default.arena = arena;

%% Command worksheet
default.cmd.records = 1;
default.cmd.qlook = 1;
default.cmd.generic = 1;

%% Records worksheet
default.records.gps.time_offset = 1;
default.records.frames.mode = 2;
default.records.frames.geotiff_fn = fullfile('antarctica','Landsat-7','Antarctica_LIMA_480m.tif');
default.records.presum_bug_fixed = 1;

%% Qlook worksheet
default.qlook.block_size = 5000;
default.qlook.dec = 20;
default.qlook.inc_dec = 5;
default.qlook.surf.en = 1;
default.qlook.surf.profile = 'RDS_OIB';

%% SAR worksheet
default.sar.out_path = '';
default.sar.imgs = {[1*ones(8,1),(1:8).'],[2*ones(8,1),(1:8).'],[3*ones(8,1),(1:8).']};
default.sar.chunk_len = 3500;
default.sar.mocomp.en = 1;
default.sar.mocomp.type = 2;
default.sar.mocomp.filter = {@butter  [2]  [0.1000]};
default.sar.mocomp.uniform_en = 1;
default.sar.sar_type = 'fk';
default.sar.sigma_x = 2.5;
default.sar.sub_aperture_steering = 0;
default.sar.st_wind = @hanning;
default.sar.start_eps = 3.15;

%% Combine worksheet in parameter spreadsheet
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

%% Radar worksheet in parameter spreadsheet
default.radar.fs = 1600e6;
default.radar.Tadc = []; % normally leave empty to use value in file header
default.radar.fs = 1600e6;
default.radar.adc_bits = 12;
default.radar.adc_full_scale = 2;
default.radar.rx_paths = [1:8];
default.radar.noise_figure = 2;
default.radar.rx_gain = 48;
default.radar.adc_SNR_dB = 59;
default.radar.Tadc_adjust = 0.000010179163; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple

defaults = {};

%% Wideband settings
default.radar.wfs(1).chan_equal_Tsys = [-31.8 -32.1 -31.7 -31.6 -31.2 -30.8 -31.5 -31.1]/1e9;
default.radar.wfs(1).chan_equal_dB = [-4 -4.3 -2.9 -4.6 -1.2 -1.5 -0.9 -2.2];
default.radar.wfs(1).chan_equal_deg = [113.1 64.8 124.3 133.7 108 138.1 71.6 102.9];

 % survey mode
default.qlook.img_comb = [3e-06 -inf 1e-06 1e-05 -inf 3e-06];
default.qlook.imgs = {[1*ones(8,1),(1:8).'],[2*ones(8,1),(1:8).'],[3*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'survey_150-520MHz_.*thick.xml';
default.name = 'Survey Mode 150-520 MHz';
defaults{end+1} = default;

 % thin ice mode
default.qlook.img_comb = [1e-06 -inf 1e-06 3e-06 -inf 1e-06];
default.qlook.imgs = {[1*ones(8,1),(1:8).'],[2*ones(8,1),(1:8).'],[3*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'thinice_150-520MHz_.*thick.xml';
default.name = 'Thin Ice Mode 150-520 MHz';
defaults{end+1} = default;

 % 2 beam imaging mode
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'image_150-520MHz_.*thick.xml';
default.name = '2 Beam Image Mode 150-520 MHz';
defaults{end+1} = default;

 % 3 beam imaging mode
default.qlook.img_comb = [];
default.qlook.imgs = {[2*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'image3_150-520MHz_.*thick.xml';
default.name = '3 Beam Image Mode 150-520 MHz';
defaults{end+1} = default;

 % sea ice mode
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'seaice_150-520MHz_.*.xml';
default.name = 'Sea Ice 150-520 MHz';
defaults{end+1} = default;

 % image high thin with narrowband
default.qlook.img_comb = [];
default.qlook.imgs = {[2*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'imagehighthin_150-520MHz_.*.xml';
default.name = 'High Alt Thin Ice Image Mode 150-520 MHz';
defaults{end+1} = default;

%% Narrowband settings
default.radar.wfs(1).chan_equal_Tsys = [-31.8 -32.1 -31.7 -31.6 -31.2 -30.8 -31.5 -31.1]/1e9;
default.radar.wfs(1).chan_equal_dB = [0 0.9 0.2 0 3.2 1.7 3.9 2.4];
default.radar.wfs(1).chan_equal_deg = [-14.6 -69.7 -6.8 0 -13.9 -1.8 -48.8 -15.8];

% survey mode
default.qlook.img_comb = [3e-06 -inf 1e-06 1e-05 -inf 3e-06];
default.qlook.imgs = {[1*ones(8,1),(1:8).'],[2*ones(8,1),(1:8).'],[3*ones(8,1),(1:8).']};
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'survey_180-210MHz_.*thick.xml';
default.name = 'Survey Mode 180-210 MHz';
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

default.radar.wfs(1).chan_equal_Tsys = [-31.8 -32.1 -31.7 -31.6 -31.2 -30.8 -31.5 -31.1]/1e9;
default.radar.wfs(1).chan_equal_dB = [-4 -4.3 -2.9 -4.6 -1.2 -1.5 -0.9 -2.2];
default.radar.wfs(1).chan_equal_deg = [113.1 64.8 124.3 133.7 108 138.1 71.6 102.9];

default.config_regexp = 'survey_150-520MHz_.*DECONV.xml';
default.name = 'Deconv 150-520 MHz';
defaults{end+1} = default;

default.config_regexp = '.*150-520MHz.*';
default.name = 'Other Settings 150-520 MHz';
defaults{end+1} = default;

%% Add default settings

param.config.defaults = defaults;
