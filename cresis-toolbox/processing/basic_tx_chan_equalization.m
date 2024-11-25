function basic_tx_chan_equalization(param,defaults)
% basic_tx_chan_equalization(param,defaults)
%
% RUN THIS FUNCTION FROM "run_basic_tx_chan_equalization"
%
% This function has two purposes:
% 1. Determine the delay, phase, and amplitude values to equalize the
%    transmit channels during calibration and validation
% 2. Once each flight to ensure waveform generators are functioning
%    properly
%
% For either purpose, the txequal settings need to programmed into the
% waveform generator. With most systems, at least two complete files should
% be collected since the first and last files are often corrupted.
%
% Author: John Paden

%% basic_tx_chan_equalization preparation

physical_constants;
tstart = tic;

% .plot_en = flag to enable plots
param.basic_tx_chan_equalization.plot_en = true;

% .caxis = Color axis limits (leave empty first time since this causes it to use the
% defaults).
param.basic_tx_chan_equalization.caxis = [];
%param.basic_tx_chan_equalization.caxis = [50 120];

% .ylim = Leave empty the first time (it just uses the default limits then)
param.basic_tx_chan_equalization.ylim = [];
%param.basic_tx_chan_equalization.ylim = [1 500];

% .xlim = Leave empty the first time (it just uses the default limits then)
%   These limits are in range lines post presumming
param.basic_tx_chan_equalization.xlim = [];
%param.basic_tx_chan_equalization.xlim = [200 450];

% .rlines = 1x2 vector specifying range lines to process (to select all
%   range lines to the end, set second element to inf). These are range
%   lines post presumming
param.basic_tx_chan_equalization.rlines = [1 inf];

% .snr_threshold = SNR threshold in dB (range lines exceeding this
%   SNR for every transmit waveform are included in the estimate,
%   if even just one waveform does not meet the threshold the
%   range line is not used)
param.basic_tx_chan_equalization.snr_threshold = 10;

% param.config.presums = Integer containing number of presums (coherent
%   averaging or stacking) to do
param.config.presums = 10;

% param.noise_bins_offsets = 1x2 vector specifying bins relative to peak
%   to use in estimating the noise power (usually some range before the
%   peak is used):
%   param.noise_rbins = min(surf_bin)+param.basic_tx_chan_equal.noise_rbins_rel(1) : min(surf_bin)+param.basic_tx_chan_equal.noise_rbins_rel(2);
param.basic_tx_chan_equal.noise_rbins_rel = [-20 -10];

% param.basic_tx_chan_equal.ref_bins = 1x2 vector specifying bins relative to peak to use in
%   correlation
param.basic_tx_chan_equal.ref_bins = [-2 2];
% param.basic_tx_chan_equal.search_bins = 1x2 vector specifying max search range to use when
%   looking for the best correlation (this is to ensure that each output
%   correlation value has full support... i.e. no roll off effect)
param.basic_tx_chan_equal.search_bins = [-15 15];
% param.basic_tx_chan_equal.Mt = amount to oversample the correlation
param.basic_tx_chan_equal.Mt = 100;

param.config.img = param.config.txequal.img;

%% Get the mode to run
global g_basic_tx_chan_equalization_mode;
fprintf('Enter the mode:\n');
fprintf(' 1: Validation\n');
fprintf(' 2: Create new settings file (STEP ONE: updates delay)\n')
fprintf(' 3: Create new settings file (STEP TWO: updates amplitude and phase)\n')
fprintf(' 4: Create new settings file (ALTERNATE STEP TWO: fixes amplitude at maximum and only updates phase)\n')
if isempty(g_basic_tx_chan_equalization_mode)
  default_mode = 1;
else
  default_mode = g_basic_tx_chan_equalization_mode;
end
update_mode = [];
while length(update_mode) ~= 1
  try
    update_mode = input(sprintf('Mode [%d]: ', default_mode));
    if isempty(update_mode)
      update_mode = default_mode;
    end
  end
end

if update_mode == 2
  % STEP ONE: updates delay
  update_delay = true;
  % update_amplitude: logical which causes the DDS RAM (amplitude) values to be updated
  update_amplitude = false;
  % update_phase: logical which causes the DDS phase values to be updated
  update_phase = false;
elseif update_mode == 3
  % STEP TWO: updates amplitude and phase
  update_delay = false;
  % update_amplitude: logical which causes the DDS RAM (amplitude) values to be updated
  update_amplitude = true;
  % update_phase: logical which causes the DDS phase values to be updated
  update_phase = true;
elseif update_mode == 4
  % STEP TWO: updates amplitude and phase
  update_delay = false;
  % keep_amplitude: logical which keeps DDS RAM (amplitude) maximum values 
  update_amplitude = false;
  % update_phase: logical which causes the DDS phase values to be updated
  update_phase = true;
else
  % VALIDATION (no files generated)
  update_mode = 1;
  update_delay = false; % START WITH THIS ONE
  % update_amplitude: logical which causes the DDS RAM (amplitude) values to be updated
  update_amplitude = false; % AFTER UPDATING DELAY, ENABLE AMP/PHASE UPDATE and DISABLE DELAY
  % update_phase: logical which causes the DDS phase values to be updated
  update_phase = false; % AFTER UPDATING DELAY, ENABLE AMP/PHASE UPDATE and DISABLE DELAY
end

param.config.recs = [0 inf];
[data,fn,settings,default,gps,hdr,pc_param,settings_enc] = basic_file_loader(param,defaults);
global g_basic_file_loader_fns;
fns = g_basic_file_loader_fns;

%% Process the files
results = [];
for file_idx = 1:length(fns)
  
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
  
  ref_wf_adc = param.config.txequal.ref_wf_adc;
  [fn_dir fn_name] = fileparts(fn);
  
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
  ml_data = lp(fir_dec(abs(pc_signal(:,:,ref_wf_adc)).^2,ones(1,5)/5,1));
  good_time_bins = find(pc_time > pc_param.Tpd*param.config.basic_surf_track_Tpd_factor & pc_time > param.config.basic_surf_track_min_time);
  [max_value,surf_bin] = max(ml_data(good_time_bins,:));
  surf_bin = surf_bin + good_time_bins(1)-1;
  
  param.noise_rlines = 1:size(ml_data,2);
  param.noise_rbins = min(surf_bin)+param.basic_tx_chan_equal.noise_rbins_rel(1) : min(surf_bin)+param.basic_tx_chan_equal.noise_rbins_rel(2);
  param.noise_rbins = param.noise_rbins(param.noise_rbins >= 1);
  
  param.basic_tx_chan_equalization.rlines = 1:size(ml_data,2);
  param.rbins= min(surf_bin)-30 : max(surf_bin)+30;
  
  if (all(surf_bin==surf_bin(1)) || isempty(param.noise_rbins)) ...
      && param.config.basic_surf_track_Tpd_factor > -inf
    warning('DEBUG: Check surface tracker since surface is at the same range bin for every range line (this is normal for lab tests but not flight test). May need to adjust param.rbins and param.basic_tx_chan_equalization.rlines to ensure maximum signal in the window is the nadir surface return. Ensure param.noise_bins and param.noise_rlines enclose a region with appropriate values for the background noise. Run dbcont after setting these parameters correctly.');
    fprintf('\n');
    figure;
    imagesc(ml_data);
    hold on
    plot(surf_bin,'k.');
    title('Black dots should track surface in echogram.');
    keyboard
  end
  
  %% Convert to old format for this function
  tmp = pc_signal;
  clear data;
  for chan = 1:size(tmp,3)
    data{chan} = tmp(:,:,chan);
  end
  param.wf_mapping = param.config.txequal.wf_mapping;
  param.bad_chan_mask = param.wf_mapping == 0;
  Hwindow_desired = param.config.txequal.Hwindow_desired;
  max_DDS_amp = param.config.txequal.max_DDS_amp;
  time_delay_desired = param.config.txequal.time_delay_desired;
  phase_desired = param.config.txequal.phase_desired;
  time{1} = pc_time;
  rbins = param.rbins;
  rlines = param.basic_tx_chan_equalization.rlines;
  
  xml_version = param.config.cresis.config_version;
  cresis_xml_mapping;
  
  % .DDS_start_mag = current DDS waveform attenuation in dB or DDS counts
  %   (0 to 65535 DDS counts correspond to 0 to 2 Volts, linear map)
  param.DDS_start_mag = double(settings.(config_var).(ram_var));
  
  % param.DDS_start_mag_units: Options are "dB" (NI/ledford) and "DDS"
  param.DDS_start_mag_units = 'DDS';
  
  % .DDS_start_time = current DDS start time in nanoseconds
  param.DDS_start_time = settings.(config_var).Waveforms(1).Delay/1e9;
  
  % .DDS_start_phase = current DDS start phase in deg or DDS counts
  %   (0 to 65535 DDS counts correspond to 0 to 2*pi, linear map)
  param.DDS_start_phase = 180/pi*angle(exp(j*settings.(config_var).Waveforms(1).(phase_var)/180*pi));
  
  % param.DDS_start_phase_units: Options are "deg" (NI) and "DDS" (ledford)
  %   THIS OFTEN NEEDS TO BE SET
  param.DDS_start_phase_units = 'deg';
  
  out_xml_fn_dir = param.basic_tx_chan_equal.out_xml_fn_dir;

  %% Hack to apply time delay, amplitude and phase.
  % =======================================================================
  if 0
    t_delay_hack = zeros(size(data));
    phase_hack = zeros(size(data));
    amp_hack = ones(size(data));

    % Usually enter the difference between the Original and Mean here:
%     t_delay_hack = ([-4.19	-5.07	-3.85	-3.43	-5.39	-4.53	-5.31	-4.64]-[-7.35	-5.57	-2.39	-3.43	0.97	-0.75	-5.91	-4.64])*1e-9;
%     phase_hack = (-[-2.6	0.0	41.5	39.4	8.2	-50.4	-51.2	-46.2]+[-138.4	145.2	-33.0	0.0	-163.3	-82.7	111.3	-85.6])/180*pi;
%     amp_hack = [1426	3350	2957	3952	4000	3548	2615	273]./[443	894	1502	1751	1605	4000	902	462];

    for chan = 1:length(data)
      data{chan} = (amp_hack(chan) .* exp(1i*phase_hack(chan))) ...
        * ifft(fft(data{chan}) .* exp(-1i*2*pi*pc_freq*t_delay_hack(chan)));
    end
  end

  %% Echogram plots
  % =======================================================================
  if param.basic_tx_chan_equalization.plot_en
    for chan = 1:length(data)
      if param.wf_mapping(chan) ~= 0
        figure(chan); clf; set(gcf,'WindowStyle','docked','NumberTitle','off','Name',sprintf('E %d',chan));
        imagesc(lp(data{chan}));
        xlabel('Range line');
        ylabel('Ramge bin');
        h_echogram_axes(chan) = gca;
        title(sprintf('Chan %d File %s\nTime-Space Relative Power', chan, fn_name),'Interpreter','none');
        grid on;
        h = colorbar;
        set(get(h,'YLabel'),'String','Relative power (dB)');
        if ~isempty(param.basic_tx_chan_equalization.caxis)
          caxis(param.basic_tx_chan_equalization.caxis);
        end
        if ~isempty(param.basic_tx_chan_equalization.ylim)
          ylim(param.basic_tx_chan_equalization.ylim);
        end
        if ~isempty(param.basic_tx_chan_equalization.xlim)
          xlim(param.basic_tx_chan_equalization.xlim);
        end
      end
    end
    linkaxes(h_echogram_axes,'xy');
  end
  
  %% Surface tracker
  % =======================================================================
  % Incoherent along-track filtering
  surf_data = filter2(ones(1,6),abs(data{ref_wf_adc}.^2));
  % Simple max search to find surface
  [surf_vals surf_bins] = max(surf_data(rbins,rlines));
  surf_bins = rbins(1)-1 + surf_bins;
  
  if param.basic_tx_chan_equalization.plot_en
    for chan = 1:length(data)
      if param.wf_mapping(chan) ~= 0
        figure(chan);
        hold on;
        plot(rlines, surf_bins,'k');
        hold off;
      end
    end
  end
    
  %% Noise power estimate and SNR threshold
  % =======================================================================
  noise_power = mean(mean(abs(data{abs(param.wf_mapping(ref_wf_adc))}(param.noise_rbins,rlines)).^2));

  %% Extract delay (using oversampled cross correlation), phase and amplitude
  % differences between channels
  % =======================================================================
  ref_bins = param.basic_tx_chan_equal.ref_bins(1):param.basic_tx_chan_equal.ref_bins(2);
  search_bins = param.basic_tx_chan_equal.search_bins(1)+param.basic_tx_chan_equal.ref_bins(1) : param.basic_tx_chan_equal.search_bins(2)+param.basic_tx_chan_equal.ref_bins(2);
  zero_padding_offset = length(search_bins) - length(ref_bins);
  Hcorr_wind = hanning(length(ref_bins));
  clear tx_phases tx_powers peak_val peak_offset;
  
  tx_powers = zeros(length(data),length(rlines));
  for chan = 1:length(param.wf_mapping)
    if param.wf_mapping(chan) ~= 0
      wf = abs(param.wf_mapping(chan));
      for rline_idx = 1:length(rlines)
        rline = rlines(rline_idx);
        % Get the phases and powers right at the peak of the reference channel
        % surface
        tx_phases(chan,rline_idx) = data{chan}(surf_bins(rline_idx),rline);
        tx_powers(chan,rline_idx) = abs(data{chan}(surf_bins(rline_idx),rline)).^2;

        % Gets the time offset relative to the reference channel (a postive
        % offset means that the channel leads the reference channel)
        [corr_out,lags] = xcorr(data{chan}(surf_bins(rline_idx)+search_bins,rline), ...
          data{ref_wf_adc}(surf_bins(rline_idx)+ref_bins,rline) .* Hcorr_wind);
        corr_int = interpft(corr_out,param.basic_tx_chan_equal.Mt*length(corr_out));
        [peak_val(chan,rline_idx) peak_offset(chan,rline_idx)] = max(corr_int);
        peak_offset(chan,rline_idx) = (peak_offset(chan,rline_idx)-1)/param.basic_tx_chan_equal.Mt+1 ...
          + ref_bins(1) + search_bins(1) - 1 - zero_padding_offset;
      end
    end
  end
  tx_snr = tx_powers ./ noise_power;
  good_meas = lp(tx_snr) > param.basic_tx_chan_equalization.snr_threshold;
  good_rlines = zeros(size(rlines));
  good_rlines(sum(good_meas(~param.bad_chan_mask,:)) == sum(~param.bad_chan_mask)) = 1;
  good_rlines = logical(good_rlines);
  
  num_good_rlines = sum(good_rlines);
  fprintf('Number of good range lines: %d out of %d\n', num_good_rlines, length(good_rlines));
  fprintf('%s\n','-'*ones(1,80));
  if num_good_rlines == 0
    error('Cannot continue: no range lines exceeded the snr_threshold');
  end
    
  %% Time Offset Settings
  % =======================================================================
  ref_time_mean = zeros(size(param.DDS_start_time));
  peak_offset_time = peak_offset * (time{1}(2)-time{1}(1));
  for chan = 1:length(param.wf_mapping)
    if param.wf_mapping(chan) ~= 0
      wf = abs(param.wf_mapping(chan));
      ref_time = peak_offset_time(chan,:);
      
      if chan == ref_wf_adc
        median_mask = ones(size(good_rlines));
        ref_time_mean(chan) = 0;
      else
        % Remove outliers and take mean
        std_val = std(ref_time(good_rlines));
        median_val = median(ref_time(good_rlines));
        median_mask = ref_time >= median_val - std_val ...
          & ref_time <= median_val + std_val;
        ref_time_mean(chan) = mean(ref_time(good_rlines & median_mask));
      end
      
      fprintf('TX %d: %4.2f ns (%4.2f ns)\n', chan, 1e9*ref_time_mean(chan), ...
        1e9*std(ref_time(good_rlines & median_mask)));
      if param.basic_tx_chan_equalization.plot_en
        figure(120+chan); clf; set(gcf,'WindowStyle','docked','NumberTitle','off','Name',sprintf('Time %d',chan));
        plot(ref_time);
        xlabel('Range line');
        ylabel('Relative time (sec)');
      end
      ref_time(~(good_rlines & median_mask)) = NaN;
      if param.basic_tx_chan_equalization.plot_en
        hold on;
        plot(ref_time,'ro');
        hold off;
        title(sprintf('Relative Time (%d to ref %d)', chan, ref_wf_adc));
        ylim([min(min(ref_time),-1e-11) max(1e-11,max(ref_time))]);
      end
    end
  end
  if 0
    % Limit time delay precision to 1/20th of a range bin
    ref_time_mean = round(ref_time_mean / (time{1}(2)-time{1}(1)) * 20) ...
      * (time{1}(2)-time{1}(1)) / 20;
  end
  fprintf('Recommended new DDS time offset (ns):\n');
  new_DDS_time = param.DDS_start_time - ref_time_mean;
  fprintf('%.4f\t', new_DDS_time(1:end-1)*1e9);
  fprintf('%.4f', new_DDS_time(end)*1e9);
  fprintf('\n');
  fprintf('%s\n','-'*ones(1,80));
  results.DDS_time_error(file_idx,:) = ref_time_mean;
  results.DDS_time(file_idx,:) = new_DDS_time;
  
  %% Amplitude Settings
  % =======================================================================
  fprintf('Relative power for each waveform (dB)\n');
  delta_power = zeros(size(param.DDS_start_mag));
  for chan = 1:length(param.wf_mapping)
    if param.wf_mapping(chan) ~= 0
      wf = abs(param.wf_mapping(chan));
      ref_power = tx_powers(chan,:)./tx_powers(ref_wf_adc,:);
      
      if chan == ref_wf_adc  || update_mode == 4
        median_mask = ones(size(good_rlines));
        delta_power(chan) = 0;
      else
        % Remove outliers and take mean
        std_val = std(ref_power(good_rlines));
        mean_val = mean(ref_power(good_rlines));
        median_mask = ref_power >= mean_val - std_val ...
          & ref_power <= mean_val + std_val;
        delta_power(chan) = lp(mean(ref_power(good_rlines & median_mask)));
      end
      
      fprintf('TX %d: %4.2f dB (%4.2f dB), desired %4.2f\n', chan, delta_power(chan), ...
        lp(std(ref_power(good_rlines & median_mask))), 20*log10(Hwindow_desired(chan)));
      if param.basic_tx_chan_equalization.plot_en
        figure(10+chan); clf; set(gcf,'WindowStyle','docked','NumberTitle','off','Name',sprintf('Pow %d',chan));
        plot(lp(ref_power,1));
        xlabel('Range line');
        ylabel('Relative power (dB)');
      end
      ref_power(~(good_rlines & median_mask)) = NaN;
      if param.basic_tx_chan_equalization.plot_en
        hold on;
        plot(lp(ref_power,1),'ro');
        hold off;
        title(sprintf('Relative Power (%d to ref %d)', chan, ref_wf_adc));
      end
    end
  end
  if strcmpi(param.DDS_start_mag_units,'DDS')
    fprintf('Recommended new DDS amplitude settings (DDS counts):\n');
    new_DDS_amp = param.DDS_start_mag .* (Hwindow_desired ./ (10.^(delta_power/20)));
    fprintf('%.0f\t', new_DDS_amp(1:end-1));
    fprintf('%.0f', new_DDS_amp(end));
    fprintf('\n');
  elseif strcmpi(param.DDS_start_mag_units,'dB')
    fprintf('Recommended new DDS amplitude settings (dB):\n');
    new_DDS_amp = param.DDS_start_mag + 20*log10(  Hwindow_desired ./ (10.^(delta_power/20))  ) ;
    fprintf('%.2f\t', new_DDS_amp(1:end-1));
    fprintf('%.2f', new_DDS_amp(end));
    fprintf('\n');
  end
  fprintf('%s\n','-'*ones(1,80));
  results.DDS_amp_error(file_idx,:) = delta_power - 20*log10(Hwindow_desired);
  results.DDS_amp(file_idx,:) = new_DDS_amp;

  %% Phase Settings
  % =======================================================================
  ref_phase_mean = zeros(size(param.DDS_start_phase));
  for chan = 1:length(param.wf_mapping)
    if param.wf_mapping(chan) ~= 0
      wf = abs(param.wf_mapping(chan));
      ref_phase = tx_phases(chan,:).*conj(tx_phases(ref_wf_adc,:));
      ref_values_real = real(ref_phase);
      ref_values_imag = imag(ref_phase);
      
      median_mask = ones(size(good_rlines));
      ref_phase_mean(chan) = mean(ref_phase);
%       if chan == ref_wf_adc
%         median_mask = ones(size(good_rlines));
%         ref_phase_mean(chan) = 1;
%       else
%         % Remove outliers and take mean (real and imaginary done separately)
%         std_val = std(ref_values_real(good_rlines));
%         mean_val = mean(ref_values_real(good_rlines));
%         median_mask = ref_values_real > mean_val - std_val ...
%           & ref_values_real < mean_val + std_val;
%         
%         std_val = std(ref_values_imag(good_rlines));
%         mean_val = mean(ref_values_imag(good_rlines));
%         median_mask = median_mask & ref_values_imag > mean_val - std_val ...
%           & ref_values_imag < mean_val + std_val;
%         
%         ref_values_real_mean = mean(ref_values_real(good_rlines & median_mask));
%         ref_values_imag_mean = mean(ref_values_imag(good_rlines & median_mask));
%         
%         ref_phase_mean(chan) = ref_values_real_mean + j*ref_values_imag_mean;
%       end
      fprintf('WF %d: relative phase: %1.3f radians, %3.1f deg\n', chan, ...
        angle(ref_phase_mean(chan)), angle(ref_phase_mean(chan))*180/pi);
      
      if param.basic_tx_chan_equalization.plot_en
        figure(20+chan); clf; set(gcf,'WindowStyle','docked','NumberTitle','off','Name',sprintf('Ang %d',chan));
        plot(angle(ref_phase)*180/pi);
        xlabel('Range line');
        ylabel('Relative phase (deg)');
        ylim([-180 180]);
      end
      ref_phase(~(good_rlines & median_mask)) = NaN;
      if param.basic_tx_chan_equalization.plot_en
        hold on;
        plot(angle(ref_phase)*180/pi,'ro');
        hold off;
        title(sprintf('Relative Phase (%d to ref %d)', chan, ref_wf_adc));
      end
    else
      ref_phase_mean(chan) = 1;
    end
  end
  DDS_error = angle(ref_phase_mean) * 65536/(2*pi);
  if strcmpi(param.DDS_start_phase_units,'DDS')
    fprintf('Recommended new DDS phase settings (DDS counts):\n');
    new_DDS_phase = exp(j*param.DDS_start_phase/65536*2*pi - ref_phase_mean);
  elseif strcmpi(param.DDS_start_phase_units,'deg')
    fprintf('Recommended new DDS phase settings (deg):\n');
    new_DDS_phase = param.DDS_start_phase/360*2*pi - angle(ref_phase_mean);
  end
  fprintf('%.1f\t', new_DDS_phase(1:end-1)*180/pi);
  fprintf('%.1f', new_DDS_phase(end)*180/pi);
  fprintf('\n');
  fprintf('%s\n','='*ones(1,80));
  results.DDS_phase_error(file_idx,:) = ref_phase_mean;
  results.DDS_phase(file_idx,:) = new_DDS_phase;
    
end

%% Print DDS Time
fprintf('\nDDS_time_error (ns)\n');
for file_idx = 1:length(fns)
  fn_length = fprintf('%s', fns{file_idx});
  for wf = 1:size(results.DDS_time_error,2)
    fprintf('\t%.2f', results.DDS_time_error(file_idx,wf)*1e9);
  end
  fprintf('\n');
end
if update_mode == 1
  mean_error = mean(results.DDS_time_error,1);
  if param.config.txequal.remove_linear_phase_en
    mean_error = detrend(mean_error);
    mean_error = mean_error - mean_error(ref_wf_adc);
    fprintf('%*s',fn_length,'Mean Error (slope removed)');
  else
    fprintf('%*s',fn_length,'Mean Error');
  end
  for wf = 1:size(mean_error,2)
    fprintf('\t%.1f', mean_error(wf)*1e9);
  end
  fprintf('\n');
  fprintf('%s',' '*ones(1,fn_length));
  for wf = 1:size(mean_error,2)
    if abs(mean_error(wf)) <= param.config.txequal.time_validation(wf)
      fprintf('\tPASS');
    else
      fprintf('\tFAIL');
    end
  end
  fprintf('\n');
  fprintf('%s',' '*ones(1,fn_length));
  for wf = 1:size(mean_error,2)
    if abs(mean_error(wf)) <= param.config.txequal.time_validation(wf)
      fprintf('\t');
    else
      fprintf('\t%.1f>%.1f', abs(mean_error(wf))*1e9, param.config.txequal.time_validation(wf)*1e9);
    end
  end
  fprintf('\n');
else
  fprintf('DDS_time (ns)\n');
  for file_idx = 1:length(fns)
    fprintf('%s', fns{file_idx});
    for wf = 1:size(results.DDS_time,2)
      fprintf('\t%.2f', results.DDS_time(file_idx,wf)*1e9);
    end
    fprintf('\n');
  end
  fprintf('Original');
  for chan = 1:length(param.DDS_start_time)
    fprintf('\t%.2f', param.DDS_start_time(chan)*1e9);
  end
  fprintf('\n');
  fprintf('Mean');
  final_DDS_time = mean(results.DDS_time,1)*1e9;
  for wf = 1:size(results.DDS_time,2)
    fprintf('\t%.2f', final_DDS_time(wf));
  end
  fprintf('\n');
  fprintf('Median');
  for wf = 1:size(results.DDS_time,2)
    fprintf('\t%.2f', median(results.DDS_time(:,wf))*1e9);
  end
  fprintf('\n');
  fprintf('Stdev');
  for wf = 1:size(results.DDS_time,2)
    fprintf('\t%.2f', std(results.DDS_time(:,wf))*1e9);
  end
  fprintf('\n');
end

%% Print DDS Amplitude
fprintf('\nDDS_amp_error (dB)\n');
for file_idx = 1:length(fns)
  fn_length = fprintf('%s', fns{file_idx});
  for wf = 1:size(results.DDS_amp_error,2)
    fprintf('\t%.1f', results.DDS_amp_error(file_idx,wf));
  end
  fprintf('\n');
end
if update_mode == 1
  mean_error = mean(results.DDS_amp_error,1);
  fprintf('%*s',fn_length,'Mean Error');
  for wf = 1:size(mean_error,2)
    fprintf('\t%.1f', mean_error(wf));
  end
  fprintf('\n');
  fprintf('%s',' '*ones(1,fn_length));
  for wf = 1:size(mean_error,2)
    if abs(mean_error(wf)) <= param.config.txequal.amp_validation(wf);
      fprintf('\tPASS');
    else
      fprintf('\tFAIL');
    end
  end
  fprintf('\n');
  fprintf('%s',' '*ones(1,fn_length));
  for wf = 1:size(mean_error,2)
    if abs(mean_error(wf)) <= param.config.txequal.amp_validation(wf);
      fprintf('\t');
    else
      fprintf('\t%.0f>%.0f', abs(mean_error(wf)), param.config.txequal.amp_validation(wf));
    end
  end
  fprintf('\n');
else
  fprintf('DDS_amp (DDS Counts, linear)\n');
  for file_idx = 1:length(fns)
    fprintf('%s', fns{file_idx});
    for wf = 1:size(results.DDS_amp,2)
      fprintf('\t%.0f', results.DDS_amp(file_idx,wf));
    end
    fprintf('\n');
  end
  fprintf('Original');
  for chan = 1:length(param.DDS_start_mag)
    fprintf('\t%.0f', param.DDS_start_mag(chan));
  end
  fprintf('\n');
  fprintf('Mean');
  final_DDS_amp = mean(results.DDS_amp,1);
  % Normalize DDS amplitude to the maximum relative to the max_DDS_amp vector
  if length(max_DDS_amp) == 1
    % All DDS's have the same maximum
    final_DDS_amp = final_DDS_amp / max(final_DDS_amp(~param.bad_chan_mask)) * max_DDS_amp;
  else
    % Each DDS has a separate maximum
    [~,max_DDS_idx] = max(final_DDS_amp(~param.bad_chan_mask) ./ max_DDS_amp(~param.bad_chan_mask));
    good_chan_idxs = find(~param.bad_chan_mask);
    max_DDS_idx = good_chan_idxs(max_DDS_idx);
    final_DDS_amp = final_DDS_amp / final_DDS_amp(max_DDS_idx) * max_DDS_amp(max_DDS_idx);
  end
  for wf = 1:size(results.DDS_amp,2)
    fprintf('\t%.0f', final_DDS_amp(wf));
  end
  fprintf('\n');
  fprintf('Median');
  for wf = 1:size(results.DDS_amp,2)
    fprintf('\t%.0f', median(results.DDS_amp(:,wf)));
  end
  fprintf('\n');
  fprintf('Stdev');
  for wf = 1:size(results.DDS_amp,2)
    fprintf('\t%.0f', std(results.DDS_amp(:,wf)));
  end
  fprintf('\n');
end

%% Print DDS Phase
fprintf('\nDDS_phase_error (deg)\n');
for file_idx = 1:length(fns)
  fn_length = fprintf('%s', fns{file_idx});
  for wf = 1:size(results.DDS_phase_error,2)
    fprintf('\t%.1f', 180/pi*angle(results.DDS_phase_error(file_idx,wf)));
  end
  fprintf('\n');
end
if update_mode == 1
  mean_error = mean(results.DDS_phase_error,1);
  if param.config.txequal.remove_linear_phase_en
    [~,tmp] = max(fft(mean_error,100*length(mean_error))); tmp = tmp - 1;
    mean_error = mean_error .* exp(-1i*2*pi*tmp/100*(0:length(mean_error)-1)/length(mean_error));
    fprintf('%*s',fn_length,'Mean Error (slope removed)');
  else
    fprintf('%*s',fn_length,'Mean Error');
  end
  mean_error = 180/pi*angle(mean_error);
  mean_error = mean_error - mean_error(ref_wf_adc);
  for wf = 1:size(mean_error,2)
    fprintf('\t%.1f', mean_error(wf));
  end
  fprintf('\n');
  fprintf('%s',' '*ones(1,fn_length));
  for wf = 1:size(mean_error,2)
    if abs(mean_error(wf)) <= param.config.txequal.phase_validation(wf);
      fprintf('\tPASS');
    else
      fprintf('\tFAIL');
    end
  end
  fprintf('\n');
  fprintf('%s',' '*ones(1,fn_length));
  for wf = 1:size(mean_error,2)
    if abs(mean_error(wf)) <= param.config.txequal.phase_validation(wf);
      fprintf('\t');
    else
      fprintf('\t%.0f>%.0f', abs(mean_error(wf)), param.config.txequal.phase_validation(wf));
    end
  end
  fprintf('\n');
else
  fprintf('DDS_phase (deg)\n');
  for file_idx = 1:length(fns)
    fprintf('%s', fns{file_idx});
    for wf = 1:size(results.DDS_phase,2)
      fprintf('\t%.0f', 180/pi*results.DDS_phase(file_idx,wf));
    end
    fprintf('\n');
  end
  fprintf('Original');
  for chan = 1:length(param.DDS_start_phase)
    fprintf('\t%.1f', param.DDS_start_phase(chan));
  end
  fprintf('\n');
  fprintf('Mean');
  final_DDS_phase = angle(mean(exp(j*(results.DDS_phase-results.DDS_phase(ref_wf_adc))),1))*180/pi;
  for wf = 1:size(results.DDS_time,2)
    fprintf('\t%.1f', final_DDS_phase(:,wf));
  end
  fprintf('\n');
  fprintf('Median');
  for wf = 1:size(results.DDS_time,2)
    fprintf('\t%.1f', final_DDS_phase(wf) + angle(mean(exp(j*(results.DDS_phase(:,wf)-results.DDS_phase(ref_wf_adc))) .* exp(-j*final_DDS_phase(wf)/180*pi),1))*180/pi);
  end
  fprintf('\n');
  fprintf('Stdev');
  for wf = 1:size(results.DDS_time,2)
    fprintf('\t%.1f', 180/pi*std(angle(exp(j*(results.DDS_phase(:,wf) - mean(results.DDS_phase(:,wf)))) )));
  end
  fprintf('\n');
  
  if update_delay
    fprintf('Delay Compensated Mean');
    final_DDS_phase_comp = final_DDS_phase + 360*(final_DDS_time/1e9 ...
      - param.DDS_start_time)*(pc_param.f0+pc_param.f1)/2;
    final_DDS_phase_comp = 180/pi*angle(exp(j*(final_DDS_phase_comp - final_DDS_phase_comp(ref_wf_adc))/180*pi));
    final_DDS_phase_comp(logical(param.bad_chan_mask)) = 0;
    for wf = 1:size(results.DDS_time,2)
      fprintf('\t%.1f', final_DDS_phase_comp(:,wf));
    end
    fprintf('\n');
    final_DDS_phase = final_DDS_phase_comp;
  end
end

%% Update XML settings structure
if update_mode ~= 1
  if update_amplitude
    settings_enc.(config_var_enc).(ram_var_enc)(~param.bad_chan_mask) = uint16(final_DDS_amp(~param.bad_chan_mask));
  end
  for wf = 1:length(settings_enc.(config_var_enc).Waveforms)
    if update_phase
      if all(isreal(param.wf_mapping))
        settings_enc.(config_var_enc).Waveforms(wf).(phase_var_enc)(~param.bad_chan_mask) ...
          = mod(double(final_DDS_phase(~param.bad_chan_mask) + phase_desired(~param.bad_chan_mask)), 360);
      else
        if mod(wf,2)
          settings_enc.(config_var_enc).Waveforms(wf).(phase_var_enc)(~param.bad_chan_mask) ...
            = double(final_DDS_phase(~param.bad_chan_mask) + phase_desired(~param.bad_chan_mask));
        else
          settings_enc.(config_var_enc).Waveforms(wf).(phase_var_enc)(~param.bad_chan_mask) = ...
            angle(exp(j*(double(final_DDS_phase(~param.bad_chan_mask) + phase_desired(~param.bad_chan_mask))/180*pi+pi/2)))*180/pi;
        end
      end
    end
    if update_delay
      settings_enc.(config_var_enc).Waveforms(wf).Delay(~param.bad_chan_mask) ...
        = double(final_DDS_time(~param.bad_chan_mask) + time_delay_desired(~param.bad_chan_mask));
    end
  end
end

%% Write XML file
if update_mode ~= 1
  [xml_fn_dir xml_fn_name xml_fn_ext] = ct_fileparts(settings.fn);
  out_xml_fn = fullfile(out_xml_fn_dir, sprintf('txequal_%s%s', xml_fn_name, xml_fn_ext));
  
  settings_enc = rmfield(settings_enc,'fn');
  settings_enc = rmfield(settings_enc,'datenum');
  if isfield(settings_enc,'FPGAZ20Configuration')
    settings_enc = rmfield(settings_enc,'FPGAZ20Configuration');
  end
  
  if isfield(settings_enc,'xmlversion') && str2double(settings_enc.xmlversion{1}.values) >= 2.0
    settings_enc.sys.DDCZ20Ctrl = settings_enc.DDCZ20Ctrl;
    settings_enc.sys.DDSZ5FSetup = settings_enc.DDSZ5FSetup;
    settings_enc.sys.XMLZ20FileZ20Path = settings_enc.XMLZ20FileZ20Path;
    settings_enc.sys.xmlversion = settings_enc.xmlversion;
    settings_enc = rmfield(settings_enc,'DDCZ20Ctrl');
    settings_enc = rmfield(settings_enc,'DDSZ5FSetup');
    settings_enc = rmfield(settings_enc,'XMLZ20FileZ20Path');
    settings_enc = rmfield(settings_enc,'xmlversion');

    % Try to write the new XML file to the settings directory (this will
    % generally work if running basic_tx_chan_equal on the same computer
    % that the data is being collected on). If the path does not exist,
    % then use the default out_xml_fn.
    [old_fn_dir,old_fn_name,old_fn_ext] = fileparts(settings_enc.sys.XMLZ20FileZ20Path{1}.values{1});
    new_out_xml_fn = fullfile(old_fn_dir, sprintf('%s_%s%s', old_fn_name, xml_fn_name, old_fn_ext));
    if exist(old_fn_dir,'dir')
      out_xml_fn = new_out_xml_fn;
    end
  end
  
  if strcmpi(param.season_name,'2017_Antarctica_Basler')
    %% HACK CODE to deal with presum error in DDS
    % Remove dummy waveforms (every second waveform)
    settings_enc.sys.DDSZ5FSetup.Waveforms = settings_enc.sys.DDSZ5FSetup.Waveforms(1:2:end);
    settings_enc.sys.DDSZ5FSetup.Z23Wave = settings_enc.sys.DDSZ5FSetup.Z23Wave/2;
    for wave_idx = 1:length(settings_enc.sys.DDSZ5FSetup.Waveforms)
      settings_enc.sys.DDSZ5FSetup.Waveforms(wave_idx).Presums ...
        = settings_enc.sys.DDSZ5FSetup.Waveforms(wave_idx).Presums + 1;
    end
  end
  % Ensure that disabled channels are masked out
  for wf = 1:length(settings_enc.sys.DDSZ5FSetup.Waveforms)
    % Tx 1 is bit 0, tx 2 is bit 1, tx 3 is bit 2, ...
    tx_mask = settings_enc.sys.DDSZ5FSetup.Waveforms(wf).TXZ20Mask;
    tx_mask = fliplr(dec2bin(tx_mask,8))-'0';
    tx_mask = tx_mask | param.config.txequal.wf_mapping==0;
    tx_mask = bin2dec(char(fliplr(tx_mask+'0')));
    settings_enc.sys.DDSZ5FSetup.Waveforms(wf).TXZ20Mask = uint8(tx_mask);
  end
  
  fprintf('\nWriting %s\n', out_xml_fn);
  out_xml_fn_dir = fileparts(out_xml_fn);
  if ~exist(out_xml_fn_dir,'dir')
    mkdir(out_xml_fn_dir);
  end
  fid = fopen(out_xml_fn,'w');
  fprintf(fid,'<?xml version=''1.0'' standalone=''yes'' ?>\n');
  fprintf(fid,'<LVData xmlns="http://www.ni.com/LVData">\n');
  write_ni_xml_object(settings_enc,fid,true,struct('array_list','Waveforms','enum_list','DDCZ20sel'));
  fprintf(fid,'</LVData>');
  fclose(fid);
  
  %% Write RSS Arena XML config file
  if isfield(default,'arena') && ~strcmpi(param.season_name,'2017_Antarctica_Basler')
    % Create arena parameter structure
    arena = default.arena;
%     arena = struct('version','1');
%     arena.awg = default.arena.awg;
%     arena.dacs = default.arena.dacs;
%     arena.dacs_sampFreq = default.arena.dacs_sampFreq;
%     arena.dacs_internal_delay = default.arena.dacs_internal_delay;
%     arena.dacs_start_delay = default.arena.dacs_start_delay;
%     arena.zeropimods = default.arena.zeropimods;
%     arena.TTL_time = default.arena.TTL_time;
%     arena.TTL_names = default.arena.TTL_names;
%     arena.TTL_states = default.arena.TTL_states;
    % Ensure non-negative delays
    min_delay = inf;
    for wf = 1:length(settings_enc.sys.DDSZ5FSetup.Waveforms)
      if min(settings_enc.sys.DDSZ5FSetup.Waveforms(wf).Delay) < min_delay
        min_delay = min(settings_enc.sys.DDSZ5FSetup.Waveforms(wf).Delay);
      end
    end
    for wf = 1:length(settings_enc.sys.DDSZ5FSetup.Waveforms)
      arena.PRI = 1 / settings_enc.sys.DDSZ5FSetup.PRF;
      arena.wfs(wf).zeropimods = default.arena.zeropimods;
      arena.wfs(wf).name = '';
      arena.wfs(wf).tukey = settings_enc.sys.DDSZ5FSetup.RAMZ20Taper;
      arena.wfs(wf).enabled = fliplr(~logical(dec2bin(settings_enc.sys.DDSZ5FSetup.Waveforms(wf).TXZ20Mask(1),8)-'0'));
      %arena.wfs(wf).scale = double(settings_enc.sys.DDSZ5FSetup.RamZ20Amplitude) .* param.config.max_tx ./ param.config.txequal.max_DDS_amp;
      arena.wfs(wf).scale = double(settings_enc.sys.DDSZ5FSetup.RamZ20Amplitude) .* arena.max_tx ./ max_DDS_amp;
      arena.wfs(wf).f0 = settings_enc.sys.DDSZ5FSetup.Waveforms(wf).StartZ20Freq;
      arena.wfs(wf).f1 = settings_enc.sys.DDSZ5FSetup.Waveforms(wf).StopZ20Freq;
%       arena.wfs(wf).fc = (settings_enc.sys.DDSZ5FSetup.Waveforms(wf).StartZ20Freq ...
%         + settings_enc.sys.DDSZ5FSetup.Waveforms(wf).StopZ20Freq)/2;
%       arena.wfs(wf).BW = abs(settings_enc.sys.DDSZ5FSetup.Waveforms(wf).StopZ20Freq ...
%         - settings_enc.sys.DDSZ5FSetup.Waveforms(wf).StartZ20Freq);
      arena.wfs(wf).delay = settings_enc.sys.DDSZ5FSetup.Waveforms(wf).Delay - min_delay;
      arena.wfs(wf).phase = settings_enc.sys.DDSZ5FSetup.Waveforms(wf).PhaseZ20Offset;
      arena.wfs(wf).Tpd = double(settings_enc.sys.DDSZ5FSetup.Waveforms(wf).LenZ20Mult) ...
        * settings_enc.sys.DDSZ5FSetup.BaseZ20Len;
      arena.wfs(wf).presums = settings_enc.sys.DDSZ5FSetup.Waveforms(wf).Presums;
    end
    
    % Create XML document
    xml_param = param;
    xml_param.wfs = arena.wfs;
    xml_param.prf = 1/arena.PRI;
    xml_param.arena = arena;
    xml_param.arena.adc = [];
    xml_param.board_map = {};

    [~,xml_param.arena.psc_name] = ct_fileparts(out_xml_fn);
    xml_param.arena.fn = fullfile(param.basic_tx_chan_equal.arena_base_dir,[xml_param.arena.psc_name '.xml']);

    [doc,xml_param] = write_arena_xml([],xml_param);

    % Create XML document
    out_str = xmlwrite(doc);
    out_str = ['<!DOCTYPE systemXML>' out_str(find(out_str==10,1):end)];
    arena_fn_dir = fileparts(xml_param.arena.fn);
    if ~exist(arena_fn_dir,'dir')
      mkdir(arena_fn_dir);
    end
    fprintf('  Writing Arena XML: %s\n', xml_param.arena.fn);
    fid = fopen(xml_param.arena.fn,'w');
    fwrite(fid,out_str,'char');
    fclose(fid);
    
%     [doc,param] = write_arena_xml(doc,param);
%     xml_doc = write_arena_xml([],'init',arena);
%     xml_doc = write_arena_xml(xml_doc,'ctu_0013',arena);
%     xml_doc = write_arena_xml(xml_doc,'dac-ad9129_0014',arena);
%     xml_doc = write_arena_xml(xml_doc,'dac-ad9129_0014_waveform',arena);
%     xml_doc = write_arena_xml(xml_doc,'psc_0001',arena);
%     xml_doc = write_arena_xml(xml_doc,'subsystems',arena);
%     
%     out_str = xmlwrite(xml_doc);
%     out_str = ['<!DOCTYPE systemXML>' out_str(find(out_str==10,1):end)];
%     [~,rss_fn_name] = ct_fileparts(out_xml_fn);
%     rss_fn = fullfile(param.rss_base_dir,[rss_fn_name '.xml']);
%     fprintf('\nWriting %s\n', rss_fn);
%     if ~exist(param.rss_base_dir,'dir')
%       mkdir(param.rss_base_dir);
%     end
%     fid = fopen(rss_fn,'w');
%     fwrite(fid,out_str,'char');
%     fclose(fid);
  end
  
end
