function [param,defaults] = default_radar_params_2016_Greenland_Polar6_snow
% [param,defaults] = default_radar_params_2016_Greenland_Polar6_snow
%
% SNOW5: 2016 Greenland Polar6
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Author: John Paden

param.season_name = '2016_Greenland_Polar6';
param.radar_name = 'snow5';

%% Control parameters (not used in the parameter spreadsheet directly)
default.xml_file_prefix = '';
default.data_file_prefix = 'snow5';
default.header_load_func = @basic_load;
default.header_load_params = struct('clk',125e6);
default.xml_version = [];

default.noise_50ohm = [0 0];

default.Pt = 0.1;
default.Gt = 10;
default.Ae = 0.01;

default.system_loss_dB = 10.^(0/10);

default.iq_mode = 0;
default.tx_DDS_mask = [1];

default.radar_worksheet_headers = {'Tpd','Tadc','Tadc_adjust','f0','f1','ref_fn','tukey','tx_weights','rx_paths','adc_gains','chan_equal_dB','chan_equal_deg','Tsys','DC_adjust','DDC_mode','DDC_freq'};
default.radar_worksheet_headers_type = {'r','r','r','r','r','r','r','r','r','r','r','r','r','r','r','r'};

default.basic_surf_track_min_time = 2e-6;
default.adc_folder_name = 'chan%d';

%% Vectors worksheet in parameter spreadsheet
default.vectors.gps.time_offset = 1;

%% Records worksheet in parameter spreadsheet
default.records.geotiff_fn = 'greenland/Landsat-7/Greenland_natural_150m';
default.records.file.adcs = [1:2];
default.records.file.adc_headers = [1:2];
default.records.gps.en = 1;
default.records.frame_mode = 0;
default.records.tmp_fn_uses_adc_folder_name = 1;

%% Get heights (quick-look) worksheet in parameter spreadsheet
default.get_heights.qlook.out_path = '';
default.get_heights.qlook.en = 1;
default.get_heights.block_size = 5000;
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
default.csarp.imgs = {[1*ones(24,1),(1:24).'],[2*ones(24,1),(1:24).'],[3*ones(24,1),(1:24).']};
default.csarp.frm_types = {0,[0 1],0,0,-1};
default.csarp.chunk_len = 3500;
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
default.radar.fs = 125000000;
default.radar.prf = 3906.25;
default.radar.adc_bits = 14;
default.radar.Vpp_scale = 2;
default.radar.wfs.f0 = 1500000000;
default.radar.wfs.f1 = 1375000000;
default.radar.wfs.fmult = 16;
default.radar.wfs.fLO = -20000000000;
default.radar.wfs.Tpd = 0.00024000000000000001;
default.radar.wfs.Tadc = [];
default.radar.wfs.record_start_idx = [];
default.radar.wfs.presum_override = [];
default.radar.wfs.loopback_mode = [];
default.radar.wfs.nyquist_zone = [];
default.radar.wfs.good_rbins = [];
default.radar.wfs.tx_weights = [0.1 0.1];
default.radar.wfs.rx_paths = [1 2];
default.radar.wfs.adc_gains = [1 1];
default.radar.wfs.chan_equal_dB = [0 0];
default.radar.wfs.chan_equal_deg = [0 0];
default.radar.wfs.Tsys = [3.7e-08 3.7e-08];

defaults = {};

%% Wideband settings
default.radar.wfs(1).chan_equal_Tsys = [0 0]/1e9;
default.radar.wfs(1).chan_equal_dB = [0 0];
default.radar.wfs(1).chan_equal_deg = [0 0];

% survey mode
default.get_heights.qlook.img_comb = [3e-06 -inf 1e-06 1e-05 -inf 3e-06];
default.get_heights.imgs = {[1 1; 1 2; 2 1; 2 2]};
default.combine.imgs = default.get_heights.imgs;
default.combine.img_comb = default.get_heights.qlook.img_comb;
default.name = 'Survey Mode 2-18 GHz';
defaults{end+1} = default;

return;
