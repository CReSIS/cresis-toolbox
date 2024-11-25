% script create_configs_2019_Antarctica_Ground_rds
%
% Creates Arena accumulation radar settings
%
% See link_budgets.xls

%% Output Directories
if ispc
  arena_base_dir = 'C:\waveforms_arena\';
else
  arena_base_dir = '/arena/waveforms/';
end
calval_dir = 'cal_val';

%% Frequency ranges, DDC settings
f0_list = [180e6];
f1_list = [210e6];
cal_settings_list = [1];
prf = 1/100e-6;

%% Calculate the desired presums
% presums: Ensure lambda/4 sampling (fudge factor allows difference) and an
%   that presums are an even number.
physical_constants; % c = speed of light
velocity = [4]; % m/s
quarter_wavelength = c./max(abs(f0_list),abs(f1_list)) / 4;
presums = round(quarter_wavelength ./ velocity * prf);
fprintf('For prf %g Hz, max presums for quarter wavelength (%g m) sampling is: %g presums\n', prf, quarter_wavelength, presums);

%% Calibration Settings for AWG/DAC
final_DDS_phase = [];
final_DDS_phase_no_time = [];
final_DDS_amp = [];
final_DDS_time = [];
if 0
  % Initial conditions (usually all zeros phase/time with max amplitude)
  for idx = 1:length(f0_list)
    final_DDS_phase{idx} = [0 0 0 0];
    final_DDS_phase_no_time{idx} = [0 0 0 0]; % not used usually
    final_DDS_amp{idx} = [1 1 1 1];
    final_DDS_time{idx} =  [0 0 0 0];
  end
else
  % COPY AND PASTE RESULTS FROM basic_tx_chan_equalization_SEASON_NAME.m
  % HERE:
  
  % 180-210 MHz
  idx = 1;
  final_DDS_phase{idx} = [0 0 0 0];
  final_DDS_phase_no_time{idx} = [0 0 0 0]; % not used usually
  final_DDS_amp{idx} = [1 1 1 1];
  final_DDS_time{idx} =  [0 0 0 0];
end

%% Survey Mode + loopback, noise, and deconv modes
% <4500 m thick ice
ice_thickness = [4500];
for freq_idx = [1]
  param = default_radar_params_2019_Antarctica_Ground_rds;
  config = param.config;
  
  config.flight_hours = 10;
  config.prf = prf;
  
  config.zeropimods = [0 180]; % 180 causes a special mode in some ADC/DAC
  
  config.tg.staged_recording = {[1 2 3]};
  config.tg.altitude_guard = 100*12*2.54/100;
  config.tg.Haltitude = 100*12*2.54/100;
  config.tg.Hice_thick = ice_thickness(freq_idx);
  
  config.create_IQ = false;
  
  config.f0 = f0_list(freq_idx);
  config.f1 = f1_list(freq_idx);
  config.DDC_freq = 160e6;
  config.zeropimods = [0 180];
  
  config.wfs(1).presums = 256;
  config.wfs(2).presums = 256;
  config.wfs(3).presums = 256;
  
  config.tukey = 0.08;
  
  config.wfs(1).Tpd = 0.5e-6;
  config.wfs(2).Tpd = 3e-6;
  config.wfs(3).Tpd = 10e-6;
  
  config.wfs(1).tukey = 0.1;
  config.wfs(2).tukey = 0.1;
  config.wfs(3).tukey = 0.1;
  
  config.wfs(1).name = '0p5us_high';
  config.wfs(2).name = '3us_high';
  config.wfs(3).name = '10us_high';
  
  config.tx_weights = final_DDS_amp{cal_settings_list(freq_idx)};
  
  config.wfs(1).phase = final_DDS_phase{cal_settings_list(freq_idx)};
  config.wfs(2).phase = final_DDS_phase{cal_settings_list(freq_idx)};
  config.wfs(3).phase = final_DDS_phase{cal_settings_list(freq_idx)};

  config.wfs(1).delay = final_DDS_time{cal_settings_list(freq_idx)};
  config.wfs(2).delay = final_DDS_time{cal_settings_list(freq_idx)};
  config.wfs(3).delay = final_DDS_time{cal_settings_list(freq_idx)};
  
  config.arena.psc_name = sprintf('survey_%.0f-%.0fMHz_%.0fft_%.0fus_%.0fmthick', ...
    config.f0/1e6,config.f1/1e6,config.tg.Haltitude*100/12/2.54,config.wfs(end).Tpd*1e6,config.tg.Hice_thick);
  config.arena.fn = fullfile(arena_base_dir,sprintf('%s.xml',config.arena.psc_name));
  write_radar_config(config);
  
  for tr_antenna = 1:4
    % Loopback Mode (0e-6 delay line)
    old_config = config;
    config.tg.Haltitude = 3e8/2 * 0e-6; % Set the delay line here
    config.tg.altitude_guard = 3e8/2 * 0e-6;
    config.tg.Hice_thick = 2000;
    config.tg.staged_recording = {[0],[0]};
    config.tx_weights = [0 0 0 0];
    config.tx_enable = [0 0 0 0];
    config.tx_weights(tr_antenna) = 1;
    config.tx_enable(tr_antenna) = 1;
    config.arena.psc_name = sprintf('survey_%.0f-%.0fMHz_%.0fusDelay_%.0fus_LOOPBACK_TRANTENNA%d', ...
      config.f0/1e6,config.f1/1e6,config.tg.Haltitude/(3e8/2)*1e6,config.wfs(end).Tpd*1e6, tr_antenna);
    config.arena.fn = fullfile(arena_base_dir,calval_dir,sprintf('%s.xml',config.arena.psc_name));
    write_radar_config(config);
    config = old_config;
  end
  
  % Noise Mode
  old_config = config;
  config.tx_weights = [0 0 0 0];
  config.tx_enable = [0 0 0 0];
  config.arena.psc_name = sprintf('survey_%.0f-%.0fMHz_%.0fft_%.0fus_NOISE', ...
    config.f0/1e6,config.f1/1e6,config.tg.Haltitude*100/12/2.54,config.wfs(end).Tpd*1e6);
  config.arena.fn = fullfile(arena_base_dir,calval_dir,sprintf('%s.xml',config.arena.psc_name));
  write_radar_config(config);
  config = old_config;
end

%% Ping Pong Mode
% <4500 m thick ice
ice_thickness = [4500];
for freq_idx = [1]
  param = default_radar_params_2019_Antarctica_Ground_rds;
  config = param.config;
  
  config.flight_hours = 10;
  config.prf = prf;
  
  config.zeropimods = [0 180]; % 180 causes a special mode in some ADC/DAC
  
  config.tg.staged_recording = {[1 2 3 3]}; % HERE
  config.tg.altitude_guard = 100*12*2.54/100;
  config.tg.Haltitude = 100*12*2.54/100;
  config.tg.Hice_thick = ice_thickness(freq_idx);
  
  config.create_IQ = false;
  
  config.f0 = f0_list(freq_idx);
  config.f1 = f1_list(freq_idx);
  config.DDC_freq = 160e6;
  config.zeropimods = [0 180];
  
  config.wfs(1).presums = 128; % HERE
  config.wfs(2).presums = 128; % HERE
  config.wfs(3).presums = 256;
  config.wfs(4).presums = 256; % HERE
  config.tukey = 0.08;
  config.wfs(1).Tpd = 0.5e-6;
  config.wfs(2).Tpd = 3e-6;
  config.wfs(3).Tpd = 10e-6;
  config.wfs(4).Tpd = 10e-6; % HERE
  config.wfs(1).tukey = 0.1;
  config.wfs(2).tukey = 0.1;
  config.wfs(3).tukey = 0.1;
  config.wfs(4).tukey = 0.1; % HERE
  
  config.wfs(1).name = '0p5us_high';
  config.wfs(2).name = '3us_high';
  config.wfs(3).name = '10us_lefttx'; % HERE
  config.wfs(4).name = '10us_righttx'; % HERE
  
  config.wfs(1).tx_weights = final_DDS_amp{cal_settings_list(freq_idx)}; % HERE
  config.wfs(1).tx_enable = [1 1 1 1]; % HERE
  config.wfs(2).tx_weights = final_DDS_amp{cal_settings_list(freq_idx)}; % HERE
  config.wfs(2).tx_enable = [1 1 1 1]; % HERE
  config.wfs(3).tx_weights = final_DDS_amp{cal_settings_list(freq_idx)}; % HERE
  config.wfs(3).tx_weights([2 4]) = 0; % HERE
  config.wfs(3).tx_enable = [1 0 1 0]; % HERE
  config.wfs(4).tx_weights = final_DDS_amp{cal_settings_list(freq_idx)}; % HERE
  config.wfs(4).tx_weights([1 3]) = 0; % HERE
  config.wfs(4).tx_enable = [0 1 0 1]; % HERE
  
  config.wfs(1).phase = final_DDS_phase{cal_settings_list(freq_idx)};
  config.wfs(2).phase = final_DDS_phase{cal_settings_list(freq_idx)};
  config.wfs(3).phase = final_DDS_phase{cal_settings_list(freq_idx)};
  config.wfs(4).phase = final_DDS_phase{cal_settings_list(freq_idx)};
  
  config.wfs(1).delay = final_DDS_time{cal_settings_list(freq_idx)};
  config.wfs(2).delay = final_DDS_time{cal_settings_list(freq_idx)};
  config.wfs(3).delay = final_DDS_time{cal_settings_list(freq_idx)};
  config.wfs(4).delay = final_DDS_time{cal_settings_list(freq_idx)};
  
  config.arena.psc_name = sprintf('pingpong_%.0f-%.0fMHz_%.0fft_%.0fus_%.0fmthick', ...
    config.f0/1e6,config.f1/1e6,config.tg.Haltitude*100/12/2.54,config.wfs(end).Tpd*1e6,config.tg.Hice_thick); % HERE
  config.arena.fn = fullfile(arena_base_dir,sprintf('%s.xml',config.arena.psc_name));
  write_radar_config(config);
end
