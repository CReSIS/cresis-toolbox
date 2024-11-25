function basic_noise_analysis(param,defaults)
% basic_noise_analysis(param,defaults)
%
% Use run_basic_noise_analysis to run.
%
% This script evaluates 50 ohm term and receive only data.
% It loads all receive channels and then analyzes these data.
% Normally called from run_basic_noise_analysis.
%
% 1. Collect data with ? waveforms in whatever noise configuration
%    you want to measure.
% 2. Characterization should be done for 50 ohm and receive only at
%    least.
% 3. If transmitting, time gate should be large enough to include
%    noise-only data at the end of the record.
%
% Author: John Paden

physical_constants;

%% Load the files
[data,fn,settings,default,gps,hdr,pc_param] = basic_file_loader(param,defaults);

%% basic_noise_analysis preparation
[fn_dir fn_name] = fileparts(fn);

if ~isfield(param,'basic_noise_analysis')
  param.basic_noise_analysis = [];
end

if ~isfield(param.basic_noise_analysis,'seg') || isempty(param.basic_noise_analysis.seg)
  param.basic_noise_analysis.seg = '';
end

if ~isfield(param.basic_noise_analysis,'psd_en') || isempty(param.basic_noise_analysis.psd_en)
  param.basic_noise_analysis.psd_en = true;
end

if ~isfield(param.basic_noise_analysis,'pdf_en') || isempty(param.basic_noise_analysis.pdf_en)
  param.basic_noise_analysis.pdf_en = false;
end

if ~isfield(param.basic_noise_analysis,'noise_burst_removal') || isempty(param.basic_noise_analysis.noise_burst_removal)
  param.basic_noise_analysis.noise_burst_removal = 0;
end

clear data_tmp;

default_noise_rbins = 1:size(data,1);
if ~isfield(param.basic_noise_analysis,'noise_rbins') || isempty(param.basic_noise_analysis.noise_rbins)
  noise_rbins = default_noise_rbins;
elseif param.basic_noise_analysis.noise_rbins(end) > size(data,1)
  noise_rbins = param.basic_noise_analysis.noise_rbins(1):size(data,1);
elseif param.basic_noise_analysis.noise_rbins(1) <= 0
  noise_rbins = size(data,1)+param.basic_noise_analysis.noise_rbins;
else
  noise_rbins = param.basic_noise_analysis.noise_rbins(1):param.basic_noise_analysis.noise_rbins(end);
end
noise_rbins = intersect(noise_rbins,default_noise_rbins);

dt = pc_param.time(2)-pc_param.time(1);
Nt_noise = round(1e-6/dt);
box_high = [];
box_highalt(1) = find(pc_param.time > pc_param.Tpd+1e-6,1);
box_highalt(2) = box_highalt(1) + Nt_noise;
box_lowalt = [];
box_lowalt(1) = size(data,1)-Nt_noise+1;
box_lowalt(2) = size(data,1);

figure(1000); clf;
imagesc(lp( mean( abs(data).^2, 3 ) ))
hold on
plot([1 size(data,2) size(data,2) 1 1], box_highalt([1 1 2 2 1]),'k','LineWidth',2);
plot([1 size(data,2) size(data,2) 1 1], box_lowalt([1 1 2 2 1]),'r','LineWidth',2);
hold off
xlabel('Range lines');
ylabel('Range bins');
h = colorbar;
set(get(h,'YLabel'),'String','Relative power (dB)');

noise_power_highalt = lp(mean(mean( abs(data(box_highalt(1):box_highalt(2),:)).^2 ,1),2));
noise_power_lowalt = lp(mean(mean( abs(data(box_lowalt(1):box_lowalt(2),:)).^2 ,1),2));
if noise_power_highalt > noise_power_lowalt
  default_box = 2;
else
  default_box = 1;
end

fprintf('Choose the range bins to use for the noise analysis. The range bins\n');
fprintf('should contain no signal energy.\n');
fprintf('1: Choose the black box (high altitude)\n');
fprintf('2: Choose the red box (low altitude)\n');
fprintf('Custom: Enter with square brackets two numbers to choose the start\n');
fprintf('   and stop bin for the noise region. For example "[3400 %d]".\n', 3400+Nt_noise);
param.basic_noise_analysis.noise_rbins = [];
while any(size(param.basic_noise_analysis.noise_rbins) ~= [1 2])
  try
    param.basic_noise_analysis.noise_rbins = input(sprintf('[%d]: ', default_box));
    if isempty(param.basic_noise_analysis.noise_rbins)
      if noise_power_highalt > noise_power_lowalt
        param.basic_noise_analysis.noise_rbins = box_lowalt;
      else
        param.basic_noise_analysis.noise_rbins = box_highalt;
      end
    elseif length(param.basic_noise_analysis.noise_rbins) == 1
      if param.basic_noise_analysis.noise_rbins == 2
        param.basic_noise_analysis.noise_rbins = box_lowalt;
      else
        param.basic_noise_analysis.noise_rbins = box_highalt;
      end
    end
    param.basic_noise_analysis.noise_rbins = sort(param.basic_noise_analysis.noise_rbins);
  end
end

default_noise_rbins = 1:size(data,1);
if ~isfield(param.basic_noise_analysis,'noise_rbins') || isempty(param.basic_noise_analysis.noise_rbins)
  noise_rbins = default_noise_rbins;
elseif param.basic_noise_analysis.noise_rbins(end) > size(data,1)
  noise_rbins = param.basic_noise_analysis.noise_rbins(1):size(data,1);
elseif param.basic_noise_analysis.noise_rbins(1) <= 0
  noise_rbins = size(data,1)+param.basic_noise_analysis.noise_rbins;
else
  noise_rbins = param.basic_noise_analysis.noise_rbins(1):param.basic_noise_analysis.noise_rbins(end);
end
noise_rbins = intersect(noise_rbins,default_noise_rbins);

%% Convert from quantization to voltage @ ADC and Additional software presums
for wf_adc = 1:size(data,3)
  wf = abs(param.config.img(wf_adc,1));

  % Quantization to voltage
  data(:,:,wf_adc) = data(:,:,wf_adc) ...
    * default.radar.Vpp_scale/2^default.radar.adc_bits ...
    * 2^hdr.wfs(abs(wf)).bit_shifts / hdr.wfs(wf).presums;

  % Software presums
  data(:,1:floor(size(data,2)/param.config.presums),wf_adc) = fir_dec(data(:,:,wf_adc),param.config.presums);
end
data = data(:,1:floor(size(data,2)/param.config.presums),:);

%% Noise Burst Removal
if param.basic_noise_analysis.noise_burst_removal
  noise_burst_removal;
end

%% Noise power
% =====================================================================

% Calculate noise power as Vrms
[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);
if strcmp(radar_name,'mcords5') && isfield(hdr,'DDC') && hdr.DDC(1) >= 2
  % Add 3 dB for IQ combination
  fprintf('Expected ADC noise floor @ ADC %.1f dBm\n', lp((default.radar.Vpp_scale/2/sqrt(2))^2/50,1)+30 - param.config.adc_SNR_dB + 3 );
  fprintf('Expected Rx noise floor @ ADC %.1f dBm\n', lp(BoltzmannConst*290*hdr.BW_noise*param.config.noise_figure*10^(hdr.rx_gain/10),1) + 3 +30);
else
  fprintf('Expected ADC noise floor @ ADC %.1f dBm\n', lp((default.radar.Vpp_scale/2/sqrt(2))^2/50,1)+30 - param.config.adc_SNR_dB );
  fprintf('Expected Rx noise floor @ ADC %.1f dBm\n', lp(BoltzmannConst*290*hdr.BW_noise*param.config.noise_figure*10^(hdr.rx_gain/10),1)+30);
end
fprintf('All powers are compensated to mimic no presums.\n');
fprintf('Noise power (dBm) at each ADC rx input and relative to 50 ohm (dB):\n')
noise_power_dBm = zeros(1,size(data,3));
default_noise_50ohm = zeros(1,size(data,3));
for wf_adc = 1:size(data,3)
  wf = abs(param.config.img(wf_adc,1));
  adc = abs(param.config.img(wf_adc,2));
  noise_power_dBm(wf_adc) = lp(mean(mean(abs(data(noise_rbins,:,wf_adc)).^2/50, 1), 2) ...
    * hdr.wfs(wf).presums * param.config.presums, 1) + 30;
  if isfield(default.radar.wfs,'rx_paths')
    if length(default.radar.wfs) >= wf
      default_noise_50ohm(wf_adc) = param.config.noise_50ohm(default.radar.wfs(wf).rx_paths(adc));
    else
      default_noise_50ohm(wf_adc) = param.config.noise_50ohm(default.radar.wfs(1).rx_paths(adc));
    end
  else
    default_noise_50ohm(wf_adc) = param.config.noise_50ohm(default.radar.rx_paths(adc));
  end
end
fprintf('wf-adc\t'); fprintf('%2.0f-%2.0f\t', param.config.img.'); fprintf('\n');
fprintf('Noise \t'); fprintf('%+5.1f\t', noise_power_dBm); fprintf('\n');
fprintf('Rel   \t'); fprintf('%+5.1f\t', noise_power_dBm - default_noise_50ohm); fprintf('\n');

%% Quantization analysis
% =====================================================================
if param.basic_noise_analysis.pdf_en
  for wf_adc = 1:size(data,3)
    figure(wf_adc); clf;
    plot(real(data(:,1,wf_adc)),'.');
    grid on;
    xlabel('Range bin');
    ylabel('Quantization level');
    
    figure(100+wf_adc);
    imagesc(lp(data(:,:,wf_adc),2));
    colorbar;
    
    % Plot estimated pdf and approximate a gaussian to it
    figure(200+wf_adc);
    ROI = data(noise_rbins,:,wf_adc);
    ROI = real(ROI(:));
    [n,x] = hist(ROI,64);    
    bar(x,n);
    mean_x = mean(ROI);
    var_x = var(ROI);
    hold on;
    plot(x, numel(ROI)*(x(2)-x(1)) * 1/sqrt(2*pi*var_x) * exp(-(x - mean_x).^2 / (2*var_x)),'r');
    hold off;
  end
  for wf_adc = 1:size(data,3)
    set(wf_adc,'WindowStyle','docked','NumberTitle','off','Name',sprintf('Q%d',wf_adc));
  end
  for wf_adc = 1:size(data,3)
    set(100+wf_adc,'WindowStyle','docked','NumberTitle','off','Name',sprintf('E%d',wf_adc));
  end
  for wf_adc = 1:size(data,3)
    set(200+wf_adc,'WindowStyle','docked','NumberTitle','off','Name',sprintf('P%d',wf_adc));
  end
end

%% Power Spectrum
% =====================================================================
if param.basic_noise_analysis.psd_en
  plot_combined_psd = true;
  combined_psd_cmap = hsv(size(data,3));
  combined_psd_legend = {};
  if plot_combined_psd
    h_psd_fig = figure(500); clf; h_psd_axes = axes('parent',h_psd_fig); hold(h_psd_axes,'on'); grid(h_psd_axes,'on'); xlabel('Frequency (MHz)','parent',h_psd_axes); ylabel('Relative noise power (dB)','parent',h_psd_axes);
  end
  
  for wf_adc = 1:size(data,3)
    wf = abs(param.config.img(wf_adc,1));
    adc = abs(param.config.img(wf_adc,2));
    
    fir_data = fir_dec(data(noise_rbins(1):noise_rbins(end),:,wf_adc),param.config.presums);
    
    if strcmp(radar_name,'mcords5') && isfield(hdr,'DDC') && hdr.DDC(1) >= 2
      dt = pc_param.time(2) - pc_param.time(1);
      Nt = size(fir_data,1);
      df = 1/(Nt*dt);
      freq = pc_param.DDC_freq + (-floor(Nt/2)*df : df : floor((Nt-1)/2)*df);
      
      figure(400+adc); clf;
      set(400+adc,'WindowStyle','docked','NumberTitle','off','Name',sprintf('M%d',wf_adc));
      plot(freq/1e6, lp(mean(abs(fftshift(fft(fir_data),1)).^2*2^2 / 50,2)/size(fir_data,1)) + 30)
      title(sprintf('MeanFFT adc%d ave%d %s/%s', adc, param.config.presums, param.basic_noise_analysis.seg, fn_name),'Interpreter','none');
      ylabel('Relative power (dB)');
      xlabel('Frequency (MHz)');
      grid on;
      ylims = ylim;
      if 0
        saveas(400+adc,sprintf('noisePSD_wf_%d_adc_%d.fig',wf,adc));
      end
      
      figure(300+adc); clf;
      set(300+adc,'WindowStyle','docked','NumberTitle','off','Name',sprintf('FFT%d',wf_adc));
      imagesc([], freq/1e6, lp(fftshift(fft(fir_data),1)) + 30 + 10*log10(2^2/50/size(fir_data,1)) )
      title(sprintf('Freq-space adc%d ave%d %s/%s', adc, param.config.presums, param.basic_noise_analysis.seg, fn_name),'Interpreter','none');
      xlabel('Range line');
      ylabel('Frequency (MHz)');
      h = colorbar;
      set(get(h,'YLabel'),'String','Relative power (dB)');
      caxis_lims = caxis;
      caxis([ylims(1) caxis_lims(2)]);
      
      if plot_combined_psd
        plot(freq/1e6, lp(mean(abs(fftshift(fft(fir_data))).^2*2^2 / 50,2)/size(fir_data,1)) + 30, 'parent',h_psd_axes,'color',combined_psd_cmap(wf_adc,:))
        combined_psd_legend{wf_adc} = sprintf('w%d-a%d', wf, adc);
      end
      
    else
      pc_param.time = hdr.wfs(wf).t0 + (0:size(fir_data,1)-1)/default.radar.fs;
      dt = pc_param.time(2) - pc_param.time(1);
      Nt = length(pc_param.time);
      df = 1/(Nt*dt);
      freq = (0:df:(Nt-1)*df).';
      f0 = settings.DDS_Setup.Waveforms(wf).Start_Freq(1);
      f1 = settings.DDS_Setup.Waveforms(wf).Stop_Freq(1);
      fc = (f0+f1)/2;
      freq = freq + default.radar.fs*floor(fc/default.radar.fs);
      
      figure(300+adc); clf;
      set(300+adc,'WindowStyle','docked','NumberTitle','off','Name',sprintf('FFT%d',wf_adc));
      imagesc([], freq/1e6, lp(fft(fir_data)) + 30 + 10*log10(2^2/50/size(fir_data,1)) )
      title(sprintf('Freq-space adc%d ave%d %s/%s', adc, param.config.presums, param.basic_noise_analysis.seg, fn_name),'Interpreter','none');
      xlabel('Range line');
      ylabel('Frequency (MHz)');
      if fc<(freq(1)+freq(end))/2
        ylim(freq([1 round(end/2)])/1e6);
      else
        ylim(freq([round(end/2) end])/1e6);
      end
      h = colorbar;
      set(get(h,'YLabel'),'String','Relative power (dB)');
      
      figure(400+adc); clf;
      set(400+adc,'WindowStyle','docked','NumberTitle','off','Name',sprintf('M%d',wf_adc));
      plot(freq/1e6, lp(mean(abs(fft(fir_data)).^2*2^2 / 50,2)/size(fir_data,1)) + 30)
      title(sprintf('MeanFFT adc%d ave%d %s/%s', adc, param.config.presums, param.basic_noise_analysis.seg, fn_name),'Interpreter','none');
      ylabel('Relative power (dB)');
      xlabel('Frequency (MHz)');
      if fc<(freq(1)+freq(end))/2
        xlim(freq([1 round(end/2)])/1e6);
      else
        xlim(freq([round(end/2) end])/1e6);
      end
      grid on;
      
      if plot_combined_psd
        plot(freq/1e6, lp(mean(abs(fft(fir_data)).^2*2^2 / 50,2)/size(fir_data,1)) + 30, 'parent',h_psd_axes,'color',combined_psd_cmap(wf_adc,:))
        combined_psd_legend{wf_adc} = sprintf('w%d-a%d', wf, adc);
      end
    end
  end
  link_figures(300+(1:size(data,3)));
  link_figures(400+(1:size(data,3)));
end
if plot_combined_psd
  legend(h_psd_axes,combined_psd_legend,'location','best')
  title(sprintf('PSD All ave%d %s/%s', param.config.presums, param.basic_noise_analysis.seg, fn_name),'Interpreter','none','parent',h_psd_axes);
end

%% Done
return;

