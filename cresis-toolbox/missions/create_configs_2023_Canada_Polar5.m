% script create_configs_2022_Greenland_Polar5
%
% Creates NI and Arena radar depth sounder settings

%% User Settings
% =========================================================================
% freq_idx [1] narrow band
% freq_idx [2] broadband
% freq_idx [] skip
% File locations
% -------------------------------------------------------------------------
% NI_base_dir: Location where National Instruments configuration files will
% be written.
% arena_base_dir: Location where Arena configuration files will be written.
if ispc
 NI_base_dir = 'C:\waveforms\';
%   NI_base_dir = 'C:\Users\uwb\Desktop\waveforms\2023\';         % for new AIR1 server
  % Air 1 Server: C:\Users\Administrator\Desktop\Arena_Shared\configs\
  %arena_base_dir = 'C:\Users\Administrator\Desktop\Arena_Shared\configs\';
%   arena_base_dir = 'C:\Users\uwb\Desktop\Arena_Shared\configs\2023\'; % for new AIR1 server
  arena_base_dir = 'C:\arena_waveforms\'; % Comment out on Air 1 Server
else
  NI_base_dir = '~/waveforms/';
  arena_base_dir = '~/rss_waveforms/';
end

% NI_calval_dir: Location where National Instruments configuration files
% for calibration and validation settings will be written (usually a
% subdirectory "calval") in the NI_base_dir
NI_calval_dir = fullfile(NI_base_dir, 'calval');
% -------------------------------------------------------------------------
% End file locations

% Specify a list of start/stop frequencies that you want to generate
% settings for. THIS OFTEN NEEDS TO BE CHANGED FOR A CAMPAIGN.
if 0
  f0_list = [180e6];
  f1_list = [210e6];
else
  f0_list = [180e6 150e6];
  f1_list = [210e6 520e6];
end

% Cal Settings
final_cal_fc = [];
final_DDS_phase = [];
final_DDS_phase_no_time = [];
final_DDS_amp = [];
final_DDS_time = [];
if 0
  % Initial conditions (usually all zeros phase/time with max amplitude)
  for idx = 1:length(f0_list)
    final_DDS_phase{idx} = [0 0 0 0 0 0 0 0];
    final_DDS_phase_no_time = [0 0 0 0 0 0 0 0]; % not used usually
    final_DDS_amp{idx} = [4000 4000 4000 4000 4000 4000 4000 4000];
    final_DDS_time{idx} =  [0 0 2.5 2.5 3.125 3.125 0 0];
  end
else
  % COPY AND PASTE RESULTS FROM basic_tx_chan_equalization_SEASON_NAME.m
  % HERE:

  % 150-520 MHz
  final_cal_fc(end+1) = 335e6;
  final_DDS_phase{end+1} = [-138.4	145.2	-33.0	0.0	-163.3	-82.7	111.3	-85.6];
  final_DDS_phase_no_time{end+1} = [0 0 0 0 0 0 0 0]; % not used usually
  final_DDS_amp{end+1} = [1426	3350	2957	3952	4000	3548	2615	273];
  final_DDS_time{end+1} =  [-4.19	-5.07	-3.85	-3.43	-5.39	-4.53	-5.31	-4.64];

  % 180-210 MHz
  final_cal_fc(end+1) = 195e6;
  final_DDS_phase_no_time{end+1} = [0 0 0 0 0 0 0 0]; % not used usually
  final_DDS_time{end+1} = [-7.35	-5.57	-2.39	-3.43	0.97	-0.75	-5.91	-4.64];
  final_DDS_amp{end+1} = [942	2585	2958	4000	3480	3183	2196	1053];
  final_DDS_phase{end+1} = [65.0	62.2	164.2	0.0	-117.9	155.4	59.3	-65.0];
end

% prf: Scaler double with units of Hertz. Desired pulse repetition
% frequency. Should be 10000 Hz.
prf = 10000;

% Hwindow_orig: Desired window created during transmit calibration. This is
% used any time a window that is different from that used during
% calibration is to be used. Should be chebwin(8,30).'.
Hwindow_orig = chebwin(8,30).';

% speed: scaler double in meters/second. Typical cruise speed of Basler is
% 90 m/s. Typical survey speed is 80 m/s. Set this speed to the maximum
% expected ground speed considering wind conditions. Using a setting of 100
% m/s is generally sufficient for all surveys.
speed = [100];
% presums: Positive scaler integer containing the number of hardware
% presums. Presums are also known as "stacking" and "coherent averaging".
% The radar only has one antenna arrayed in the along-track direction. This
% antenna has almost no directivity so the sample spacing (after
% presumming) should be one fourth of a wavelength to meet Nyquist criteria
% in all situations. We calculate the wavelength at the center frequency.
% Typically, this equation should not be modified:
%    presums = round(c./abs(f1_list+f0_list)/2 ./ speed * prf / 2)*2
physical_constants; % Loads "c" as speed of light
presums = round(c./abs(f1_list+f0_list)/2 ./ speed * prf / 2)*2

%% Load Antenna Positions/Lever Arms (do not change)
% =========================================================================
param = [];
param.season_name = '2022_Greenland_Polar5'; % Any polar5/6 season works
param.radar_name = 'rds';
param.gps_source = 'awi-final';
clear phase_centers;
for tx_chan = 1:8
  % Just enable the current antenna to determine its phase center
  tx_weights = zeros(1,8);
  tx_weights(tx_chan) = 1;
  rxchan = 4; % Fix the receiver (it should not matter which one you choose)
  % Determine phase center for the antenna
  phase_centers(:,tx_chan) = lever_arm(param, tx_weights, rxchan);
end
% Adjust phase centers to the mean phase center position
phase_centers = bsxfun(@minus,phase_centers,mean(phase_centers,2));

%% Load Arena Parameters (do not change)
% =========================================================================
[param_defaults,defaults] = default_radar_params_2022_Greenland_Polar5_rds;
arena = defaults{1}.arena;

%% Survey Mode + loopback, noise, and deconv modes
% thick ice, 1200 +/- 700 ft AGL
% =========================================================================
ice_thickness = 3250;
for freq_idx = [1]
  param = struct('radar_name','mcords5','num_chan',8,'aux_dac',[255 255 255 255 255 255 255 255],'version','14.0f1','TTL_prog_delay',650,'xml_version',2.0,'fs',1600e6,'fs_sync',90.0e6,'fs_dds',1440e6,'TTL_clock',1440e6/16,'TTL_mode',[2.5e-6 260e-9 -1100e-9],'arena_base_dir',arena_base_dir);
  param = merge_structs(param,param_defaults);
  param.arena = arena;
  param.max_tx = [4000 4000 4000 4000 4000 4000 4000 4000]; param.max_data_rate = 755; param.flight_hours = 3.5; param.sys_delay = 0.75e-6; param.use_mcords4_names = true; param.arena = arena;
  BW = abs(f1_list(freq_idx)-f0_list(freq_idx));
  if BW <= 170e6
    param.DDC_select = 2; % 200 MHz sampling mode
  elseif BW <= 370e6
    param.DDC_select = 1; % 400 MHz sampling mode
  else
    error('Bandwidth (%g MHz) is too large. Must be less than or equal to 370 MHz.', BW/1e6)
  end
  cal_used_idx = -1;
  fc = abs(f0_list+f1_list)/2;
  for cal_idx = 1:length(final_cal_fc)
    if abs(final_cal_fc(cal_idx) - fc(freq_idx)) < 1e6
      cal_used_idx = cal_idx;
      break;
    end
  end
  if cal_used_idx == -1
    error('The center frequency %g MHz does not match any of the cal setting center frequencies specified in final_cal_fc. Either change the f0_list and f1_list or add a calibration setting with this center frequency.', fc/1e6);
  end
  param.max_duty_cycle = 0.12;
  param.create_IQ = false;
  param.tg.staged_recording = [1 2 3];
  param.tg.altitude_guard = 700*12*2.54/100;
  param.tg.Haltitude = 1200*12*2.54/100;
  param.tg.Hice_thick = ice_thickness;
  param.tg.rg_stop_offset = [300 300 0];
  param.prf = prf;
  param.presums = [4 4 presums(freq_idx)-8];
  param.wfs(1).atten = 37;
  param.wfs(2).atten = 0;
  param.wfs(3).atten = 0;
  DDS_amp = final_DDS_amp{cal_used_idx};
  param.tx_weights = DDS_amp;
  param.tukey = 0.08;
  param.wfs(1).Tpd = 1e-6;
  param.wfs(2).Tpd = 3e-6;
  param.wfs(3).Tpd = 10e-6;
  param.wfs(1).phase = final_DDS_phase{cal_used_idx};
  param.wfs(2).phase = final_DDS_phase{cal_used_idx};
  param.wfs(3).phase = final_DDS_phase{cal_used_idx};
  param.delay = final_DDS_time{cal_used_idx};
  param.f0 = f0_list(freq_idx);
  param.f1 = f1_list(freq_idx);
  param.DDC_freq = (param.f0+param.f1)/2;
  [param.wfs(1:3).tx_mask] = deal([0 0 0 0 0 0 0 0]);
  param.fn = fullfile(NI_base_dir,sprintf('survey_%.0f-%.0fMHz_%.0fft_%.0fus_%.0fmthick.xml',param.f0/1e6,param.f1/1e6,param.tg.Haltitude*100/12/2.54,param.wfs(end).Tpd*1e6,param.tg.Hice_thick));
  write_cresis_xml(param);
  if freq_idx == 1
    % Default Mode
    param.fn = fullfile(NI_base_dir,'default.xml');
    write_cresis_xml(param);
  end
  % Loopback Mode without delay line
  param.tg.staged_recording = false;
  param.tg.altitude_guard = 1000*12*2.54/100;
  param.tg.Haltitude = 0e-6 * c/2;
  param.tg.Hice_thick = 0; % Long enough for 10 us delay line
  param.fn = fullfile(NI_calval_dir,sprintf('survey_%.0f-%.0fMHz_%.0fus_LOOPBACK_NO_DELAY.xml',param.f0/1e6,param.f1/1e6,param.wfs(end).Tpd*1e6));
  write_cresis_xml(param);
  % Loopback Mode (10e-6 delay line)
  param.tg.staged_recording = false;
  param.tg.altitude_guard = 1000*12*2.54/100;
  param.tg.Haltitude = 10e-6 * c/2;
  param.tg.Hice_thick = 0; % Long enough for 10 us delay line
  param.fn = fullfile(NI_calval_dir,sprintf('survey_%.0f-%.0fMHz_%.0fus_LOOPBACK.xml',param.f0/1e6,param.f1/1e6,param.wfs(end).Tpd*1e6));
  write_cresis_xml(param);
  % Deconvolution Mode (for over calm lake or sea ice lead)
  param.wfs(1).atten = 43;
  param.wfs(2).atten = 43;
  param.wfs(3).atten = 43;
  param.tg.staged_recording = false;
  param.tg.altitude_guard = 3000*12*2.54/100;
  param.tg.Haltitude = 4000*12*2.54/100;
  param.tg.Hice_thick = 0 * 12*2.54/100/sqrt(er_ice);
  param.fn = fullfile(NI_calval_dir,sprintf('survey_%.0f-%.0fMHz_%.0fft_%.0fus_DECONV.xml',param.f0/1e6,param.f1/1e6,param.tg.Haltitude*100/12/2.54,param.wfs(end).Tpd*1e6));
  write_cresis_xml(param);
  if freq_idx == 1
    % Noise Mode
    param.tx_weights = [0 0 0 0 0 0 0 0];
    [param.wfs(1:3).tx_mask] = deal([1 1 1 1 1 1 1 1]);
    param.wfs(1).atten = 37;
    param.wfs(2).atten = 0;
    param.wfs(3).atten = 0;
    param.tg.staged_recording = [1 2 3];
    param.tg.altitude_guard = 500*12*2.54/100;
    param.tg.Haltitude = 1400*12*2.54/100;
    param.tg.Hice_thick = 3250;
    param.fn = fullfile(NI_calval_dir,sprintf('survey_%.0f-%.0fMHz_%.0fus_NOISE.xml',param.f0/1e6,param.f1/1e6,param.wfs(end).Tpd*1e6));
    write_cresis_xml(param);
  end
end

%% Survey Mode + loopback, noise, and deconv modes
% thin ice, 1200 +/- 700 ft AGL
% =========================================================================
ice_thickness = 1800;
for freq_idx = [2]
  param = struct('radar_name','mcords5','num_chan',8,'aux_dac',[255 255 255 255 255 255 255 255],'version','14.0f1','TTL_prog_delay',650,'xml_version',2.0,'fs',1600e6,'fs_sync',90.0e6,'fs_dds',1440e6,'TTL_clock',1440e6/16,'TTL_mode',[2.5e-6 260e-9 -1100e-9],'arena_base_dir',arena_base_dir);
  param = merge_structs(param,param_defaults);
  param.arena = arena;
  param.max_tx = [4000 4000 4000 4000 4000 4000 4000 4000]; param.max_data_rate = 755; param.flight_hours = 3.5; param.sys_delay = 0.75e-6; param.use_mcords4_names = true; param.arena = arena;
  BW = abs(f1_list(freq_idx)-f0_list(freq_idx));
  if BW <= 170e6
    param.DDC_select = 2; % 200 MHz sampling mode
  elseif BW <= 370e6
    param.DDC_select = 1; % 400 MHz sampling mode
  else
    error('Bandwidth (%g MHz) is too large. Must be less than or equal to 370 MHz.', BW/1e6)
  end
  cal_used_idx = -1;
  fc = abs(f0_list+f1_list)/2;
  for cal_idx = 1:length(final_cal_fc)
    if abs(final_cal_fc(cal_idx) - fc(freq_idx)) < 1e6
      cal_used_idx = cal_idx;
      break;
    end
  end
  if cal_used_idx == -1
    error('The center frequency %g MHz does not match any of the cal setting center frequencies specified in final_cal_fc. Either change the f0_list and f1_list or add a calibration setting with this center frequency.', fc/1e6);
  end
  param.max_duty_cycle = 0.12;
  param.create_IQ = false;
  param.tg.staged_recording = [1 2 3];
  param.tg.altitude_guard = 700*12*2.54/100;
  param.tg.Haltitude = 1200*12*2.54/100;
  param.tg.Hice_thick = ice_thickness;
  param.tg.rg_start_offset = [-100 -100 -100]; % Ensure good overlap between waveforms
  param.tg.rg_stop_offset = [300 300 300]; % Ensure good overlap between waveforms
  param.prf = prf;
  param.presums = [8 2 presums(freq_idx)-10];
  param.wfs(1).atten = 35;
  param.wfs(2).atten = 0;
  param.wfs(3).atten = 0;
  DDS_amp = final_DDS_amp{cal_used_idx};
  param.tx_weights = DDS_amp;
  param.tukey = 0.08;
  param.wfs(1).Tpd = 1e-6;
  param.wfs(2).Tpd = 1e-6;
  param.wfs(3).Tpd = 3e-6;
  param.wfs(1).phase = final_DDS_phase{cal_used_idx};
  param.wfs(2).phase = final_DDS_phase{cal_used_idx};
  param.wfs(3).phase = final_DDS_phase{cal_used_idx};
  param.delay = final_DDS_time{cal_used_idx};
  param.f0 = f0_list(freq_idx);
  param.f1 = f1_list(freq_idx);
  param.DDC_freq = (param.f0+param.f1)/2;
  [param.wfs(1:3).tx_mask] = deal([0 0 0 0 0 0 0 0]);
  param.fn = fullfile(NI_base_dir,sprintf('thinsurvey_%.0f-%.0fMHz_%.0fft_%.0fus_%.0fmthick.xml',param.f0/1e6,param.f1/1e6,param.tg.Haltitude*100/12/2.54,param.wfs(end).Tpd*1e6,param.tg.Hice_thick));
  write_cresis_xml(param);
  if freq_idx == 2
    % Default Mode
    param.fn = fullfile(NI_base_dir,'default.xml');
    write_cresis_xml(param);
  end
  % Loopback Mode without delay line
  param.tg.staged_recording = false;
  param.tg.altitude_guard = 1000*12*2.54/100;
  param.tg.Haltitude = 0e-6 * c/2;
  param.tg.Hice_thick = 0; % Long enough for 10 us delay line
  param.fn = fullfile(NI_calval_dir,sprintf('survey_%.0f-%.0fMHz_%.0fus_LOOPBACK_NO_DELAY.xml',param.f0/1e6,param.f1/1e6,param.wfs(end).Tpd*1e6));
  write_cresis_xml(param);
  % Loopback Mode (10e-6 delay line)
  param.tg.staged_recording = false;
  param.tg.altitude_guard = 1000*12*2.54/100;
  param.tg.Haltitude = 10e-6 * c/2;
  param.tg.Hice_thick = 0; % Long enough for 10 us delay line
  param.fn = fullfile(NI_calval_dir,sprintf('survey_%.0f-%.0fMHz_%.0fus_LOOPBACK.xml',param.f0/1e6,param.f1/1e6,param.wfs(end).Tpd*1e6));
  write_cresis_xml(param);
  % Deconvolution Mode (for over calm lake or sea ice lead)
  param.wfs(1).atten = 43;
  param.wfs(2).atten = 43;
  param.wfs(3).atten = 43;
  param.tg.staged_recording = false;
  param.tg.altitude_guard = 3000*12*2.54/100;
  param.tg.Haltitude = 4000*12*2.54/100;
  param.tg.Hice_thick = 0 * 12*2.54/100/sqrt(er_ice);
  param.fn = fullfile(NI_calval_dir,sprintf('survey_%.0f-%.0fMHz_%.0fft_%.0fus_DECONV.xml',param.f0/1e6,param.f1/1e6,param.tg.Haltitude*100/12/2.54,param.wfs(end).Tpd*1e6));
  write_cresis_xml(param);
  if 1
    % Noise Mode
    param.tx_weights = [0 0 0 0 0 0 0 0];
    [param.wfs(1:3).tx_mask] = deal([1 1 1 1 1 1 1 1]);
    param.wfs(1).atten = 35;
    param.wfs(2).atten = 0;
    param.wfs(3).atten = 0;
    param.tg.staged_recording = [1 2 3];
    param.tg.altitude_guard = 500*12*2.54/100;
    param.tg.Haltitude = 1400*12*2.54/100;
    param.tg.Hice_thick = 3250;
    param.fn = fullfile(NI_calval_dir,sprintf('survey_%.0f-%.0fMHz_%.0fus_NOISE.xml',param.f0/1e6,param.f1/1e6,param.wfs(end).Tpd*1e6));
    write_cresis_xml(param);
  end
end

%% Equalization (Using Ocean)
% Haltitude +/- 2000 ft
% For lower altitude, increase attenuation
% Use these settings over ocean or sea ice for fast-time equalization,
% transmit equalization, and receiver equalization.
% Creates one waveform for each of N DDS-transmitters plus a combined
% waveform with all transmitters going.
% =========================================================================
Haltitude = [2500 2500 0 3500 6000];
Tpd_list = [1e-6 1e-6 3e-6 3e-6 3e-6];
attenuation = [62 45 43 61 55];
fn_hint = {'WATER','ICE','NO_DELAY','WATER','WATER'};
for Tpd_idx = 1:length(Tpd_list)
  Tpd = Tpd_list(Tpd_idx);
  for freq_idx = [2]
    param = struct('radar_name','mcords5','num_chan',8,'aux_dac',[255 255 255 255 255 255 255 255],'version','14.0f1','TTL_prog_delay',650,'xml_version',2.0,'fs',1600e6,'fs_sync',90.0e6,'fs_dds',1440e6,'TTL_clock',1440e6/16,'TTL_mode',[2.5e-6 260e-9 -1100e-9],'arena_base_dir',arena_base_dir);
    param = merge_structs(param,param_defaults);
    param.arena = arena;
    param.max_tx = [4000 4000 4000 4000 4000 4000 4000 4000]; param.max_data_rate = 700; param.flight_hours = 3.5; param.sys_delay = 0.75e-6; param.use_mcords4_names = true; param.arena = arena;
    BW = abs(f1_list(freq_idx)-f0_list(freq_idx));
    if BW <= 170e6
      param.DDC_select = 2; % 200 MHz sampling mode
    elseif BW <= 370e6
      param.DDC_select = 1; % 400 MHz sampling mode
    else
      error('Bandwidth (%g MHz) is too large. Must be less than or equal to 370 MHz.', BW/1e6)
    end
    cal_used_idx = -1;
    fc = abs(f0_list+f1_list)/2;
    for cal_idx = 1:length(final_cal_fc)
      if abs(final_cal_fc(cal_idx) - fc(freq_idx)) < 1e6
        cal_used_idx = cal_idx;
        break;
      end
    end
    if cal_used_idx == -1
      error('The center frequency %g MHz does not match any of the cal setting center frequencies specified in final_cal_fc. Either change the f0_list and f1_list or add a calibration setting with this center frequency.', fc/1e6);
    end
    param.max_duty_cycle = 0.12;
    param.create_IQ = false;
    param.tg.staged_recording = false;
    param.tg.altitude_guard = 2000*12*2.54/100;
    param.tg.Haltitude = Haltitude(Tpd_idx)*12*2.54/100;
    param.tg.Hice_thick = 0;
    param.prf = prf;
    param.presums = [10 10 10 10 10 10 10 10 10];
    [param.wfs(1:8).atten] = deal(attenuation(Tpd_idx)-12);
    [param.wfs(9:9).atten] = deal(attenuation(Tpd_idx));
    param.tx_weights = final_DDS_amp{cal_used_idx};
    param.tukey = 0.08;
    param.Tpd = Tpd;
    for wf=1:9
      param.wfs(wf).phase = final_DDS_phase{cal_used_idx};
    end
    param.delay = final_DDS_time{cal_used_idx};
    param.f0 = f0_list(freq_idx);
    param.f1 = f1_list(freq_idx);
    param.DDC_freq = (param.f0+param.f1)/2;
    for wf=1:8
      param.wfs(wf).tx_mask = ones(1,8);
      param.wfs(wf).tx_mask(9-wf) = 0;
    end
    for wf=9:9
      param.wfs(wf).tx_mask = [0 0 0 0 0 0 0 0];
    end
    param.fn = fullfile(NI_calval_dir,sprintf('txequal_%.0f-%.0fMHz_%.0fft_%.0fft_%.0fus_%s.xml', ...
      param.f0/1e6, param.f1/1e6, (param.tg.Haltitude+[-param.tg.altitude_guard param.tg.altitude_guard])*100/12/2.54, ...
      param.Tpd*1e6,fn_hint{Tpd_idx}));
    write_cresis_xml(param);
  end
end

%% Polarimetric Mode 3250m
% <3250 m thick ice, 1200 +/- 700 ft AGL
% =========================================================================
ice_thickness = 3250;
polarimetric_f0_list = f0_list;
polarimetric_f1_list = f1_list;
for freq_idx = []
  param = struct('radar_name','mcords5','num_chan',8,'aux_dac',[255 255 255 255 255 255 255 255],'version','14.0f1','TTL_prog_delay',650,'xml_version',2.0,'fs',1600e6,'fs_sync',90.0e6,'fs_dds',1440e6,'TTL_clock',1440e6/16,'TTL_mode',[2.5e-6 260e-9 -1100e-9],'arena_base_dir',arena_base_dir);
  param = merge_structs(param,param_defaults);
  param.arena = arena;
  param.max_tx = [4000 4000 4000 4000 4000 4000 4000 4000]; param.max_data_rate = 700; param.flight_hours = 3.5; param.sys_delay = 0.75e-6; param.use_mcords4_names = true; param.arena = arena;
  BW = abs(polarimetric_f1_list(freq_idx)-polarimetric_f0_list(freq_idx));
  if BW <= 170e6
    param.DDC_select = 2; % 200 MHz sampling mode
  elseif BW <= 370e6
    param.DDC_select = 1; % 400 MHz sampling mode
  else
    error('Bandwidth (%g MHz) is too large. Must be less than or equal to 370 MHz.', BW/1e6)
  end
  cal_used_idx = -1;
  fc = abs(polarimetric_f0_list+polarimetric_f1_list)/2;
  for cal_idx = 1:length(final_cal_fc)
    if abs(final_cal_fc(cal_idx) - fc(freq_idx)) < 1e6
      cal_used_idx = cal_idx;
      break;
    end
  end
  if cal_used_idx == -1
    error('The center frequency %g MHz does not match any of the cal setting center frequencies specified in final_cal_fc. Either change the f0_list and f1_list or add a calibration setting with this center frequency.', fc/1e6);
  end
  param.max_duty_cycle = 0.12;
  param.create_IQ = false;
  param.tg.staged_recording = [1 1 2 2 3 3];
  param.tg.altitude_guard = 700*12*2.54/100;
  param.tg.Haltitude = 1200*12*2.54/100;
  param.tg.Hice_thick = ice_thickness;
  param.prf = prf;
  param.presums = [2 4 2 4 16 16];
  param.wfs(1).atten = 37;
  param.wfs(2).atten = 37;
  param.wfs(3).atten = 0;
  param.wfs(4).atten = 0;
  param.wfs(5).atten = 0;
  param.wfs(6).atten = 0;
  param.tx_weights = [4000 4000 4000 4000 4000 4000 4000 4000];
  param.tukey = 0.08;
  param.wfs(1).Tpd = 1e-6;
  param.wfs(2).Tpd = 1e-6;
  param.wfs(3).Tpd = 3e-6;
  param.wfs(4).Tpd = 3e-6;
  param.wfs(5).Tpd = 10e-6;
  param.wfs(6).Tpd = 10e-6;
  param.wfs(1).phase = final_DDS_phase{cal_used_idx};
  param.wfs(2).phase = final_DDS_phase{cal_used_idx};
  param.wfs(3).phase = final_DDS_phase{cal_used_idx};
  param.wfs(4).phase = final_DDS_phase{cal_used_idx};
  param.wfs(5).phase = final_DDS_phase{cal_used_idx};
  param.wfs(6).phase = final_DDS_phase{cal_used_idx};
  param.delay = final_DDS_time{cal_used_idx};
  param.f0 = polarimetric_f0_list(freq_idx);
  param.f1 = polarimetric_f1_list(freq_idx);
  param.DDC_freq = (param.f0+param.f1)/2;
  [param.wfs([1 3 5]).tx_mask] = deal([1 1 0 0 0 0 1 1]);
  [param.wfs([2 4 6]).tx_mask] = deal([0 0 1 1 1 1 0 0]);
  param.tg.rg_stop_offset = [300 300 300 300 0 0];
  param.fn = fullfile(NI_base_dir,sprintf('polarimetric_%.0f-%.0fMHz_%.0fft_%.0fus_%.0fmthick.xml',param.f0/1e6,param.f1/1e6,param.tg.Haltitude*100/12/2.54,param.wfs(end).Tpd*1e6,param.tg.Hice_thick));
  write_cresis_xml(param);
end

%% Survey Mode 3250m with Polarimetric Setup
% <3250 m thick ice, 1200 +/- 700 ft AGL
% =========================================================================
ice_thickness = 3250;
for freq_idx = []
  param = struct('radar_name','mcords5','num_chan',8,'aux_dac',[255 255 255 255 255 255 255 255],'version','14.0f1','TTL_prog_delay',650,'xml_version',2.0,'fs',1600e6,'fs_sync',90.0e6,'fs_dds',1440e6,'TTL_clock',1440e6/16,'TTL_mode',[2.5e-6 260e-9 -1100e-9],'arena_base_dir',arena_base_dir);
  param = merge_structs(param,param_defaults);
  param.arena = arena;
  param.max_tx = [4000 4000 4000 4000 4000 4000 4000 4000]; param.max_data_rate = 700; param.flight_hours = 3.5; param.sys_delay = 0.75e-6; param.use_mcords4_names = true; param.arena = arena;
  BW = abs(f1_list(freq_idx)-f0_list(freq_idx));
  if BW <= 170e6
    param.DDC_select = 2; % 200 MHz sampling mode
  elseif BW <= 370e6
    param.DDC_select = 1; % 400 MHz sampling mode
  else
    error('Bandwidth (%g MHz) is too large. Must be less than or equal to 370 MHz.', BW/1e6)
  end
  cal_used_idx = -1;
  fc = abs(f0_list+f1_list)/2;
  for cal_idx = 1:length(final_cal_fc)
    if abs(final_cal_fc(cal_idx) - fc(freq_idx)) < 1e6
      cal_used_idx = cal_idx;
      break;
    end
  end
  if cal_used_idx == -1
    error('The center frequency %g MHz does not match any of the cal setting center frequencies specified in final_cal_fc. Either change the f0_list and f1_list or add a calibration setting with this center frequency.', fc/1e6);
  end
  param.max_duty_cycle = 0.12;
  param.create_IQ = false;
  param.tg.staged_recording = [1 2 3];
  param.tg.altitude_guard = 700*12*2.54/100;
  param.tg.Haltitude = 1200*12*2.54/100;
  param.tg.Hice_thick = ice_thickness;
  param.prf = prf;
  param.presums = [4 4 34];
  param.wfs(1).atten = 37;
  param.wfs(2).atten = 0;
  param.wfs(3).atten = 0;
  param.tx_weights = [4000 4000 4000 4000 4000 4000 4000 4000];
  param.tukey = 0.08;
  param.wfs(1).Tpd = 1e-6;
  param.wfs(2).Tpd = 3e-6;
  param.wfs(3).Tpd = 10e-6;
  param.wfs(1).phase = final_DDS_phase{cal_used_idx};
  param.wfs(2).phase = final_DDS_phase{cal_used_idx};
  param.wfs(3).phase = final_DDS_phase{cal_used_idx};
  param.delay = final_DDS_time{cal_used_idx};
  param.f0 = f0_list(freq_idx);
  param.f1 = f1_list(freq_idx);
  param.DDC_freq = (param.f0+param.f1)/2;
  [param.wfs([1 2 3]).tx_mask] = deal([1 1 0 0 0 0 1 1]);
  param.tg.rg_stop_offset = [300 300 0];
  param.fn = fullfile(NI_base_dir,sprintf('sur_pol_%.0f-%.0fMHz_%.0fft_%.0fus_%.0fmthick.xml',param.f0/1e6,param.f1/1e6,param.tg.Haltitude*100/12/2.54,param.wfs(end).Tpd*1e6,param.tg.Hice_thick));
  write_cresis_xml(param);
end

%% Image Mode (EGRIP Low Altitude, Thick Ice)
% Ice thickness "param.tg.Hice_thick_min" m to "param.tg.Hice_thick" m, "param.tg.Haltitude" +/- "param.tg.altitude_guard" ft AGL
% =========================================================================
for freq_idx = []
  param = struct('radar_name','mcords5','num_chan',8,'aux_dac',[255 255 255 255 255 255 255 255],'version','14.0f1','TTL_prog_delay',650,'xml_version',2.0,'fs',1600e6,'fs_sync',90.0e6,'fs_dds',1440e6,'TTL_clock',1440e6/16,'TTL_mode',[2.5e-6 260e-9 -1100e-9],'arena_base_dir',arena_base_dir);
  param = merge_structs(param,param_defaults);
  param.arena = arena;
  param.max_tx = [4000 4000 4000 4000 4000 4000 4000 4000]; param.max_data_rate = 700; param.flight_hours = 3.5; param.sys_delay = 0.75e-6; param.use_mcords4_names = true; param.arena = arena;
  BW = abs(f1_list(freq_idx)-f0_list(freq_idx));
  if BW <= 170e6
    param.DDC_select = 2; % 200 MHz sampling mode
  elseif BW <= 370e6
    param.DDC_select = 1; % 400 MHz sampling mode
  else
    error('Bandwidth (%g MHz) is too large. Must be less than or equal to 370 MHz.', BW/1e6)
  end
  cal_used_idx = -1;
  fc = abs(f0_list+f1_list)/2;
  for cal_idx = 1:length(final_cal_fc)
    if abs(final_cal_fc(cal_idx) - fc(freq_idx)) < 1e6
      cal_used_idx = cal_idx;
      break;
    end
  end
  if cal_used_idx == -1
    error('The center frequency %g MHz does not match any of the cal setting center frequencies specified in final_cal_fc. Either change the f0_list and f1_list or add a calibration setting with this center frequency.', fc/1e6);
  end
  param.max_duty_cycle = 0.12;
  param.create_IQ = false;
  param.tg.staged_recording = [1 2 3 3];
  param.tg.altitude_guard = 700 * 12*2.54/100;
  param.tg.Haltitude = 1200 * 12*2.54/100;
  param.tg.rg_stop_offset = [300 300 0 0];
  param.tg.Hice_thick = 3250;
  param.tg.look_angle_deg = [0 0 40 40];
  param.prf = prf;
  param.presums = [4 4 ceil((presums(freq_idx)-6)/4)*2 ceil((presums(freq_idx)-6)/4)*2];
  % Switch from tx calibration window to hanning window to broaden beam
  DDS_amp = final_DDS_amp{cal_used_idx} .* hanning(8).' ./ Hwindow_orig;
  % Renormalize the amplitudes
  [~,relative_max_idx] = max(DDS_amp./param.max_tx);
  DDS_amp = round(DDS_amp .* param.max_tx(relative_max_idx) / DDS_amp(relative_max_idx));
  param.tx_weights = DDS_amp;
  param.tukey = 0.08;
  param.wfs(1).Tpd = 1e-6;
  param.wfs(2).Tpd = 3e-6;
  param.wfs(3).Tpd = 10e-6;
  param.wfs(4).Tpd = 10e-6;
  param.wfs(1).phase = final_DDS_phase{cal_used_idx};
  param.wfs(2).phase = final_DDS_phase{cal_used_idx};
  param.wfs(3).phase = final_DDS_phase{cal_used_idx};
  param.wfs(4).phase = final_DDS_phase{cal_used_idx};
  param.wfs(1).name = 'nadir1';
  param.wfs(2).name = 'nadir3';
  param.wfs(3).name = 'left';
  param.wfs(4).name = 'right';
  % Loop through each waveform and adjust time delays to match the
  % desired beam angle for that waveform. Note that the delays that need to
  % be added in are the delay RELATIVE to a nadir beam since final_DDS_time
  % contains the equalized delays for a nadir beam.
  % param.tg.look_angle (negative is to the left, positive is to the right)
  param.tg.look_angle = [0 0 -20 20];
  for wf = 1:length(param.tg.look_angle)
    nadir_vec = [0 0 1];
    beam_vec = [0 sind(param.tg.look_angle(wf)) cosd(param.tg.look_angle(wf))];
    nadir_delay = -nadir_vec * phase_centers;
    beam_delay = -beam_vec * phase_centers;
    % Only need relative phases, so adjust by a constant
    nadir_delay = nadir_delay - nadir_delay(4);
    beam_delay = beam_delay - beam_delay(4);
    % Convert from range to one-way delay
    nadir_delay = nadir_delay / c;
    beam_delay = beam_delay / c - nadir_delay; % Only include delay relative to nadir
    beam_delay = beam_delay - mean(beam_delay);
    % param.wfs(wf).delay and final_DDS_time{cal_used_idx} are in units of ns
    param.wfs(wf).delay = (final_DDS_time{cal_used_idx} - beam_delay*1e9);
  end
  param.f0 = f0_list(freq_idx);
  param.f1 = f1_list(freq_idx);
  param.DDC_freq = (param.f0+param.f1)/2;
  [param.wfs(1:4).tx_mask] = deal([0 0 0 0 0 0 0 0]);
  param.wfs(1).atten = 37;
  param.wfs(2).atten = 0;
  param.wfs(3).atten = 0;
  param.wfs(4).atten = 0;
  param.fn = fullfile(NI_base_dir,sprintf('egrip_image_%.0f-%.0fMHz_%.0fft_%.0fus_%.0fmthick.xml', ...
    param.f0/1e6,param.f1/1e6,param.tg.Haltitude*100/2.54/12,param.wfs(end).Tpd*1e6,param.tg.Hice_thick));
  write_cresis_xml(param);
end
