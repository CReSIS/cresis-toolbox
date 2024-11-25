function [param,defaults] = default_radar_params_2017_Antarctica_P3_mcords
% [param,defaults] = default_radar_params_2017_Antarctica_P3_mcords
%
% MCORDS 3: 2017 Antarctica P3
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%1
% Author: John Paden

param.season_name = '2017_Antarctica_P3';
param.radar_name = 'mcords3';

%% Control parameters (not used in the parameter spreadsheet directly)
default.xml_file_prefix = 'mcords3';
default.data_file_prefix = 'mcords3';
default.header_load_func = @basic_load_mcords3;
default.header_load_params = struct('clk',1e9/9,'presum_mode',1);
default.xml_version = 2.0;

default.noise_50ohm = [-32.2	-26.9	-34.1	-44.4	-43.1	-43.0	-42.3	-42.7	-42.3	-41.8	-40.2	-64.4	-40.3	-39.2	-41.8];

default.Pt = 500 * [1 1 1 1 1 1 1];
default.Gt = 7*4;
default.Ae = 2*0.468 * 0.468;

default.system_loss_dB = 10.^(-5.88/10);
default.max_DDS_RAM = 40000;
default.tx_voltage = sqrt(1000*50)*10^(-2/20);

default.iq_mode = 0;
default.tx_DDS_mask = [1 1 1 1 1 1 1 0];

default.radar_worksheet_headers = {'Tpd','Tadc','Tadc_adjust','f0','f1','ft_dec','ref_fn','tukey','tx_weights','rx_paths','adc_gains','chan_equal_dB','chan_equal_deg','Tsys','DC_adjust','DDC_mode','DDC_freq'};
default.radar_worksheet_headers_type = {'r','r','r','r','r','r','r','r','r','r','r','r','r','r','r','r','r'};

default.basic_surf_track_min_time = 2e-6; % Normally -inf for lab test, 2e-6 for flight test
default.basic_surf_track_Tpd_factor = 1.1; % Normally -inf for lab test, 1.1 for flight test
default.adc_folder_name = 'board%b';

if 1
  % Example 1: Normal configuration:
  %   Connect antenna N to WFG N for all N = 1 to 7
  ref_adc = 9;
  default.txequal.img = [(1:7).', ref_adc*ones(7,1)];
  default.txequal.ref_wf_adc = 4;
  default.txequal.wf_mapping = [1 2 3 4 5 6 7 0];
  default.txequal.Hwindow_desired = [1 1 1 1 1 1 1 0];
  default.txequal.max_DDS_amp = [40000 40000 40000 40000 40000 40000 40000 0];
  default.txequal.time_delay_desired = [0 0 0 0 0 0 0 0];
  default.txequal.phase_desired = [0 0 0 0 0 0 0 0];
  default.txequal.time_validation = [3 3 3 3 3 3 3 3]*1e-9;
  default.txequal.amp_validation = [3 3 3 3 3 3 3 3];
  default.txequal.phase_validation = [35 35 35 35 35 35 35 35];
  default.txequal.remove_linear_phase_en = true;
end

%% Vectors worksheet in parameter spreadsheet
default.vectors.gps.time_offset = 1;

%% Records worksheet in parameter spreadsheet
default.records.geotiff_fn = 'antarctica\Landsat-7\Antarctica_LIMA_peninsula.tif';
default.records.file.adcs = [2:16];
default.records.file.adc_headers = [2:16];
default.records.gps.en = 1;
default.records.frame_mode = 0;
default.records.presum_mode = 1;
default.records.tmp_fn_uses_adc_folder_name = 1;

%% Get heights (quick-look) worksheet in parameter spreadsheet
default.get_heights.qlook.out_path = '';
default.get_heights.qlook.en = 1;
default.get_heights.block_size = 10000;
default.get_heights.frm_types = {0,[0 1],0,0,-1};
default.get_heights.coh_noise_method = [];
default.get_heights.coh_noise_arg = [];
default.get_heights.ft_wind = @hanning;
default.get_heights.ft_wind_time = false;
default.get_heights.ft_dec = true;
default.get_heights.pulse_comp = [];
default.get_heights.pulse_rfi.en = [];
default.get_heights.pulse_rfi.inc_ave= [];
default.get_heights.pulse_rfi.thresh_scale = [];
default.get_heights.roll_correction = 0;
default.get_heights.lever_arm_fh = @lever_arm;
default.get_heights.elev_correction = 0;
default.get_heights.B_filter = ones(1,20)/20;
default.get_heights.decimate_factor = 20;
default.get_heights.inc_ave = 10;
default.get_heights.surf.en = 1;
default.get_heights.surf.method = 'threshold';
default.get_heights.surf.noise_rng = [0 -50 10];
default.get_heights.surf.min_bin = 2e-6;
default.get_heights.surf.max_bin = [];
default.get_heights.surf.threshold = 9;
default.get_heights.surf.sidelobe = 15;
default.get_heights.surf.medfilt = 3;
default.get_heights.surf.search_rng = [0:2];

%% CSARP worksheet in parameter spreadsheet
default.csarp.out_path = '';
default.csarp.imgs = {[1*ones(7,1),(6:12).'],[2*ones(7,1),(6:12).'],[3*ones(7,1),(6:12).']};
default.csarp.frm_types = {0,[0 1],0,0,-1};
default.csarp.chunk_len = 5000;
default.csarp.chunk_overlap = 10;
default.csarp.frm_overlap = 0;
default.csarp.coh_noise_removal = 0;
default.csarp.combine_rx = 0;
default.csarp.time_of_full_support = 3.5e-5;
default.csarp.pulse_rfi.en = [];
default.csarp.pulse_rfi.inc_ave= [];
default.csarp.pulse_rfi.thresh_scale = [];
default.csarp.trim_vals = [];
default.csarp.pulse_comp = 1;
default.csarp.ft_dec = 1;
default.csarp.ft_wind = @hanning;
default.csarp.ft_wind_time = 0;
default.csarp.lever_arm_fh = @lever_arm;
default.csarp.mocomp.en = 1;
default.csarp.mocomp.type = 2;
default.csarp.mocomp.filter = {@butter  [2]  [0.1000]};
default.csarp.mocomp.uniform_en = 1;
default.csarp.sar_type = 'f-k';
default.csarp.sigma_x = 2.5;
default.csarp.sub_aperture_steering = 0;
default.csarp.st_wind = @hanning;
default.csarp.start_eps = 3.15;

%% Combine worksheet in parameter spreadsheet
default.combine.in_path = '';
default.combine.array_path = '';
default.combine.out_path = '';
default.combine.method = 'standard';
default.combine.window = @hanning;
default.combine.bin_rng = 0;
default.combine.rline_rng = -5:5;
default.combine.dbin = 1;
default.combine.dline = 6;
default.combine.DCM = [];
default.combine.Nsv = 1;
default.combine.theta_rng = [0 0];
default.combine.sv_fh = @array_proc_sv;
default.combine.diag_load = 0;
default.combine.Nsig = 2;

%% Radar worksheet in parameter spreadsheet
default.radar.fs = 1e9/9;
default.radar.Tadc = []; % normally leave empty to use value in file header
default.radar.adc_bits = 14;
default.radar.adc_full_scale = 2;
default.radar.rx_paths = [1,1:15];
default.radar.rx_paths = [1 8 9 10 11 1 2 3 4 5 6 7 12 13 14 15];
default.radar.noise_figure = 2;
default.radar.rx_gain = 51.5;
default.radar.adc_SNR_dB = 70;
default.radar.Tadc_adjust = -1.6e-6; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple
default.radar.ft_dec = [27 100];
default.radar.ref_fn = '';
defaults = {};

%% Settings
fprintf('Enter set_number = 1 for dates on and before 20171104, set_number = 2 for dates after 20171104:\n');
set_number = [];
while length(set_number) ~= 1
  try
    set_number = input('set_number = ');
    if (set_number~=1 && set_number~=2)
      set_number = [];
    end
  end
end
if set_number == 1
    default.radar.wfs(1).chan_equal_Tsys = [2.62 -2.11 0.22 0 1.20 -1.42 -0.24 -67.30 -69.95 -68.15 -63.77 -78.86 -75.19 -74.19 -70.62]/1e9;
    default.radar.wfs(1).chan_equal_dB = [4.5 2.73 1.23	0.0	0.45 2.1 3.18 7.3 3.75 6.23	-50.18 -33.90 -38.13 3.8 6.18];
    default.radar.wfs(1).chan_equal_deg = [-23.75 24.28	154.48	0.00 -152.88 -129.43 96.43 10.28 32.53 12.18 41.98 92.83 -80.25	-64.18 25.48];
elseif set_number == 2
    default.radar.wfs(1).chan_equal_Tsys = [2.118 -2.294 1.114 0 1.438 -1.552 -2.006 -69.14 -71.464 -77.642 -79.04 -81.518 -75.348 -76.456 -73.114]/1e9;
    default.radar.wfs(1).chan_equal_dB = [4.96 2.29 1.96 0.00 0.79 2.41 3.37 7.03 3.70 4.64 -1.87 5.96 3.97 3.57 5.93];
    default.radar.wfs(1).chan_equal_deg = [-52.04 18.07 -137.29 0.00 -132.03 25.69 -24.59 -1.14 9.34 -27.19 -13.43 16.47 47.87 -24.56 81.49];
end

% survey mode
default.get_heights.qlook.img_comb = [3e-06 -inf 1e-06 1e-05 -inf 3e-06];
default.get_heights.imgs = {[1*ones(7,1),(6:12).'],[2*ones(7,1),(6:12).'],[3*ones(7,1),(6:12).']};
default.csarp.imgs = default.get_heights.imgs;
default.combine.imgs = default.get_heights.imgs;
default.combine.img_comb = default.get_heights.qlook.img_comb;
default.radar.DC_adjust = {'','',''};
default.radar.ref_fn = '';
default.xml_regexp = 'survey_.*thick.xml';
default.name = 'Survey Mode';
defaults{end+1} = default;

% survey mode
default.get_heights.qlook.img_comb = [3e-06 -inf 1e-06];
default.get_heights.imgs = {[1*ones(7,1),(6:12).'],[2*ones(7,1),(6:12).']};
default.csarp.imgs = default.get_heights.imgs;
default.combine.imgs = default.get_heights.imgs;
default.combine.img_comb = default.get_heights.qlook.img_comb;
default.radar.DC_adjust = {'','',''};
default.radar.ref_fn = '';
default.xml_regexp = 'survey_.*thin_ice.xml';
default.name = 'Thin Ice Mode';
defaults{end+1} = default;

% high altitude mode
default.get_heights.qlook.img_comb = [1e-05 -inf 3e-06];
default.get_heights.imgs = {[1*ones(7,1),(6:12).'],[2*ones(7,1),(6:12).']};
default.csarp.imgs = default.get_heights.imgs;
default.combine.imgs = default.get_heights.imgs;
default.combine.img_comb = default.get_heights.qlook.img_comb;
default.radar.DC_adjust = {'','',''};
default.radar.ref_fn = '';
default.xml_regexp = 'survey_.*high_altitude.xml';
default.name = 'High Altitude Mode';
defaults{end+1} = default;

% deconvolution mode
default.get_heights.qlook.img_comb = [];
default.get_heights.imgs = {[1*ones(7,1),(6:12).'],[2*ones(7,1),(6:12).'],[3*ones(7,1),(6:12).']};
default.csarp.imgs = default.get_heights.imgs;
default.combine.imgs = default.get_heights.imgs;
default.combine.img_comb = default.get_heights.qlook.img_comb;
default.radar.DC_adjust = {'','',''};
default.radar.ref_fn = '';
default.xml_regexp = 'survey_.*DECONVOLUTION.xml';
default.name = 'Deconvolution Mode';
defaults{end+1} = default;

%% Other settings

default.get_heights.qlook.img_comb = [];
default.get_heights.imgs = [];
default.combine.imgs = default.get_heights.imgs;
default.combine.img_comb = default.get_heights.qlook.img_comb;

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
