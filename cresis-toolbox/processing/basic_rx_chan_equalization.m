function basic_rx_chan_equalization(param,defaults)
% basic_rx_chan_equalization(param,defaults)
%
% RUN THIS FUNCTION FROM "run_basic_rx_chan_equalization"
%
% This script is for helping with setting the receiver coefficients
% from raw data. It requires loading one waveform and N receive channels
% and then analyzing these data.
%
% 1. Collect data with so that receiver gain settings are the same as
%    the ordinary data collection, but the air/ice surface response
%    is unsaturated.  Flatter surfaces work best. If INS data is not
%    available, then the platform should be straight and level.
%    If the TR switch is slow, you will need to collect the data from
%    a high enough altitude where the fast-time gain changes of the TR
%    switch are stable (this is 10 us after the switch change for the
%    original MCoRDS system).
% 2. Pulse duration should not matter, but probably affects results
%    slightly
% 3. Time gate should be large enough to include noise-only data which
%    will be used to determine the SNR of the surface return (SNR
%    threshold is used to exclude low SNR data points from the measurement)
%
% Author: John Paden, Logan Smith
%
% See Also: run_basic_rx_chan_equalization

%% basic_rx_chan_equalization preparation

physical_constants;

param.multiselect = true;
[data,fn,settings,default,gps,hdr,pc_param,settings_enc] = basic_file_loader(param,defaults);
global g_basic_file_loader_fns;
fns = g_basic_file_loader_fns;
num_files = length(g_basic_file_loader_fns);
 
%% Process the files
td_out = [];
amp_out = [];
phase_out = [];
for file_idx = 1:num_files
  %% Load the files
  if file_idx == 1
    fn = fns{1};
  else
    param.config.file_search_mode = 'default+s';
    [data,fn,settings,default,gps,hdr,pc_param,settings_enc] = basic_file_loader(param,defaults);
  end
  if size(data,2) < param.config.presums
    error('Not enough data in file to process. Choose a different file.');
  end
  
  %% Convert from quantization to voltage @ ADC
  wf = abs(param.config.img(1,1));
  data = data ...
    * default.radar.Vpp_scale/2^default.radar.adc_bits ...
    * 2^hdr.wfs(abs(wf)).bit_shifts / hdr.wfs(wf).presums;
  
  %% Additional software presums
  for wf_adc = 1:size(data,3)
    data(:,1:floor(size(data,2)/param.config.presums),wf_adc) = fir_dec(data(:,:,wf_adc),param.config.presums);
  end
  data = data(:,1:floor(size(data,2)/param.config.presums),:);
  hdr.radar_time = fir_dec(hdr.radar_time,param.config.presums);
  hdr.gps_time = fir_dec(hdr.gps_time,param.config.presums);
  hdr.lat = fir_dec(hdr.lat,param.config.presums);
  hdr.lon = fir_dec(hdr.lon,param.config.presums);
  hdr.elev = fir_dec(hdr.elev,param.config.presums);
  hdr.roll = fir_dec(hdr.roll,param.config.presums);
  hdr.pitch = fir_dec(hdr.pitch,param.config.presums);
  hdr.heading = fir_dec(hdr.heading,param.config.presums);
  
  %% Pulse compression
  [pc_signal,pc_time,pc_freq] = pulse_compress(data,pc_param);

  %% Track surface
  ml_data = lp(fir_dec(abs(pc_signal(:,:,param.config.ref_wf_adc)).^2,ones(1,5)/5,1));
  good_time_bins = find(pc_time > pc_param.Tpd*1.1 & pc_time > param.config.basic_surf_track_min_time);
  [max_value,surf_bin] = max(ml_data(good_time_bins,:));
  surf_bin = surf_bin + good_time_bins(1)-1;
  
  param.noise_rlines = 1:size(ml_data,2);
  param.noise_rbins = min(surf_bin)-40 : min(surf_bin)-30;
  param.noise_rbins = param.noise_rbins(param.noise_rbins >= 1);
  
  param.rlines = 1:size(ml_data,2);
  param.rbins= min(surf_bin)-30 : max(surf_bin)+30;
  
  if all(surf_bin==surf_bin(1)) || isempty(param.noise_rbins)
    warning('DEBUG: Check surface tracker. May need to adjust param.rbins and param.rlines to ensure maximum signal in the window is the nadir surface return. Ensure param.noise_bins and param.noise_rlines enclose a region with appropriate values for the background noise. Run dbcont after setting these parameters correctly.');
    figure(1000); clf;
    imagesc(ml_data);
    hold on
    plot(surf_bin);


    keyboard
  end

  %% Perform receiver channel equalization
  param.averaging_fh = @mean;
  param.time = pc_time;
  dt = pc_time(2) - pc_time(1);
  Nt = length(pc_time);
  df = 1/(Nt*dt);
  param.freq = pc_freq;
  
  if all(gps.roll==0)
    param.mocomp_type = 2;
  else
    param.mocomp_type = 4;
  end
  param.tx_weights = double(settings.DDS_Setup.Ram_Amplitude(logical(param.config.tx_DDS_mask)));
  param.rx_paths = {};
  if isfield(default.radar.wfs,'rx_paths')
    if length(default.radar.wfs) >= wf
      param.rx_paths{wf} = default.radar.wfs(wf).rx_paths;
    else
      param.rx_paths{wf} = default.radar.wfs(1).rx_paths;
    end
  else
    param.rx_paths{wf} = default.radar.rx_paths;
  end
  param.lever_arm_fh = @lever_arm;
  
  param.combine_channels = false;
  param.snr_threshold = 10;
   param.phase = default.radar.wfs(1).chan_equal_deg;
   param.amp = default.radar.wfs(1).chan_equal_dB;
   param.td = default.radar.wfs(1).chan_equal_Tsys;

  [td_out(:,file_idx),amp_out(:,file_idx),phase_out(:,file_idx), full_out] = rx_chan_equal(pc_signal,param,hdr);
  
  %% Collate results
  if file_idx == 1
    gps_time = full_out.gps_time;
    peak_ref = full_out.peak_ref;
    peak_offset = full_out.peak_offset;
    roll_est_theta = full_out.roll_est_theta;
    roll_est_val = full_out.roll_est_val;
    roll_est_gps_time = full_out.gps_time;
  else
    gps_time = cat(2,gps_time,full_out.gps_time);
    peak_ref = cat(2,peak_ref,full_out.peak_ref);
    peak_offset = cat(2,peak_offset,full_out.peak_offset);
    roll_est_theta = cat(2,roll_est_theta,full_out.roll_est_theta);
    roll_est_val = cat(2,roll_est_val,full_out.roll_est_val);
    roll_est_gps_time = cat(2,roll_est_gps_time,full_out.gps_time);
  end
  
end

%% Print Results
for wf_adc = 1:size(param.config.img,1)
  wf = abs(param.config.img(wf_adc,1));
  adc = param.config.img(wf_adc,2);
  rx_path(wf_adc) = param.rx_paths{wf}(adc);
end
[rx_path_sort,rx_path_sort_idxs] = sort(rx_path);

fprintf('========================================================\n');
fprintf('Recommended equalization coefficients (averaged results)\n');

sw_version = current_software_version;
fprintf('  mocomp:%d, wf/adc:%d/%d method:"%s" bins:%d-%d git-hash:%s (%s)\n', ...
  param.mocomp_type, param.config.img(param.config.ref_wf_adc,1), ...
  param.config.img(param.config.ref_wf_adc,2), param.config.delay.method, param.rbins(1), param.rbins(end), ...
  sw_version.rev, sw_version.cur_date_time);
fprintf('td settings\n');
for file_idx = 1:num_files
  [~,fn_name] = fileparts(fns{file_idx});
  fprintf('%s', fn_name);
  fprintf('\t%.2f', td_out(rx_path_sort,file_idx)*1e9);
  fprintf('\n');
end
fprintf('amp settings\n');
for file_idx = 1:num_files
  [~,fn_name] = fileparts(fns{file_idx});
  fprintf('%s', fn_name);
  fprintf('\t%.1f', amp_out(rx_path_sort,file_idx));
  fprintf('\n');
end
fprintf('phase settings\n');
for file_idx = 1:num_files
  [~,fn_name] = fileparts(fns{file_idx});
  fprintf('%s', fn_name);
  fprintf('\t%.1f', phase_out(rx_path_sort,file_idx));
  fprintf('\n');
end

td_ave = mean(td_out,2);
amp_ave = mean(amp_out,2);
phase_ave = angle(mean(exp(j*phase_out/180*pi),2))*180/pi;

fprintf('Rx Path\n');
for wf_adc = rx_path_sort_idxs
  wf = abs(param.config.img(wf_adc,1));
  adc = param.config.img(wf_adc,2);
  fprintf('%d\t', param.rx_paths{wf}(adc));
end
fprintf('\n');

fprintf('Original/Recommended/Difference td settings (ns):\n');
fprintf('%.2f\t', param.td(rx_path_sort)*1e9);
fprintf('\n');
fprintf('%.2f\t', td_ave(rx_path_sort)*1e9);
fprintf('\n');
fprintf('%.2f\t', (td_ave(rx_path_sort).' - param.td(rx_path_sort))*1e9);
fprintf('\n');

fprintf('Original/Recommended/Difference amp settings (dB):\n');
fprintf('%.1f\t', param.amp(rx_path_sort));
fprintf('\n');
fprintf('%.1f\t', amp_ave(rx_path_sort));
fprintf('\n');
fprintf('%.1f\t', amp_ave(rx_path_sort).' - param.amp(rx_path_sort));
fprintf('\n');

% Rewrap each phase so that the output does not print +355 deg and -5 deg
fprintf('Original/Recommended/Difference phase settings (deg):\n');
phase_rewrapped = angle(exp(j*param.phase/180*pi)) * 180/pi;
fprintf('%.1f\t', phase_rewrapped(rx_path_sort));
fprintf('\n');
phase_rewrapped = angle(exp(j*phase_ave/180*pi)) * 180/pi;
fprintf('%.1f\t', phase_rewrapped(rx_path_sort));
fprintf('\n');
phase_rewrapped = angle(exp(j*(phase_ave(:).' - param.phase)/180*pi)) * 180/pi;
fprintf('%.1f\t', phase_rewrapped(rx_path_sort));
fprintf('\n');

%% Plot Results
[~,fn_name] = fileparts(fns{1});

figure(1); clf;
plot(peak_offset(rx_path_sort_idxs,:).');
xlabel('Range line');
ylabel('Delay (samples)');
grid on;
title(fn_name,'interpreter','none');

figure(2); clf;
plot(lp(peak_ref(rx_path_sort_idxs,:)).');
xlabel('Range line');
ylabel('Relative power (dB)');
grid on;
title(fn_name,'interpreter','none');

figure(3); clf;
plot(angle(peak_ref(rx_path_sort_idxs,:)).' * 180/pi);
hold on
plot(interp1(gps.gps_time,gps.roll,gps_time)*180/pi,'k-','LineWidth',2);
xlabel('Range line');
ylabel('Phase (deg)');
grid on;
title(fn_name,'interpreter','none');

