function [h_mult_factor,h_deconvolved] = collate_deconv_ascope(param,spec,deconv,h_fig,img,wf_adc,h_nonnegative,h_negative,rline,rbins_plot,deconv_plot)
% [h_mult_factor,h_deconvolved] = collate_deconv_ascope(param,spec,deconv,h_fig,img,wf_adc,h_nonnegative,h_negative,rline,rbins_plot,deconv_plot)
%
% Support function for collate_deconv. Only called from this function.

c = 2.997924580003452e+08;
Mt = param.collate_deconv.Mt;
cmd = spec.param_analysis.analysis.cmd{param.collate_deconv.cmd_idx};
debug_out_dir = param.collate_deconv.debug_out_dir;
debug_ylim = param.collate_deconv.debug_ylim;
wf = param.analysis.imgs{img}(wf_adc,1);
adc = param.analysis.imgs{img}(wf_adc,2);

% h: impulse response
h = spec.deconv_mean{rline};

% Estimate SNR as a function of range bin
SNR = lp(abs(h).^2 ./ spec.deconv_std{rline}.^2 * cmd.rlines,1);

%% Stage 1: Plot cmd.rlines and param.collate_deconv.rbins{img}
if rbins_plot
  clf(h_fig(1));
  set(h_fig(1),'Name','Impulse response falling edge');
  h_axes = axes('parent',h_fig(1));
  max_dm = max(lp(spec.deconv_mean{rline}));
  plot(h_axes(1), lp(spec.deconv_mean{rline}) - max_dm)
  hold(h_axes(1),'on');
  [max_val,max_idx] = max(lp(spec.deconv_sample{rline}));
  plot(h_axes(1), circshift(lp(spec.deconv_sample{rline}) - max_val,[-max_idx 1]))
  plot(h_axes(1), lp(spec.deconv_std{rline},2) - lp(cmd.rlines) - max_dm)
  h_filled = [h_nonnegative; zeros(length(spec.deconv_sample{rline})-length(h_nonnegative)-length(h_negative),1); h_negative];
  plot(h_axes(1), lp(h_filled) - max_dm)
  xlabel(h_axes(1), 'Range bin');
  ylabel(h_axes(1), 'Relative power (dB)');
  title(h_axes(1), sprintf('Impulse response falling edge (rline %d of %d)',rline, length(spec.deconv_gps_time)));
  legend(h_axes(1), 'mean','sample','std','h','location','best');
  xlim(h_axes(1), [1 2*param.collate_deconv.rbins{img}(2)]);
  ylim(h_axes(1), [-debug_ylim 0]);
  grid(h_axes(1), 'on');
  
  clf(h_fig(2));
  set(h_fig(2),'Name','Impulse response rising edge');
  h_axes(2) = axes('parent',h_fig(2));
  max_dm = max(lp(spec.deconv_mean{rline}));
  plot(h_axes(2), lp(spec.deconv_mean{rline}) - max_dm)
  hold(h_axes(2),'on');
  [max_val,max_idx] = max(lp(spec.deconv_sample{rline}));
  plot(h_axes(2), circshift(lp(spec.deconv_sample{rline}) - max_val,[-max_idx 1]))
  plot(h_axes(2), lp(spec.deconv_std{rline},2) - lp(cmd.rlines) - max_dm)
  h_filled = [h_nonnegative; zeros(length(spec.deconv_sample{rline})-length(h_nonnegative)-length(h_negative),1); h_negative];
  plot(h_axes(2), lp(h_filled) - max_dm)
  xlabel(h_axes(2), 'Range bin');
  ylabel(h_axes(2), 'Relative power (dB)');
  title(h_axes(2), sprintf('Impulse response rising edge (rline %d of %d)',rline, length(spec.deconv_gps_time)));
  legend(h_axes(2), 'mean','sample','std','h','location','best');
  Nt = length(spec.deconv_mean{rline});
  xlim(h_axes(2), [Nt+2*param.collate_deconv.rbins{img}(1) Nt]);
  ylim(h_axes(2), [-debug_ylim 0]);
  grid(h_axes(2), 'on');
  
  clf(h_fig(3));
  set(h_fig(3),'Name','SNR falling edge');
  h_axes(3) = axes('parent',h_fig(3));
  plot(h_axes(3),SNR)
  hold(h_axes(3),'on');
  plot(h_axes(3),[1 length(SNR)], 20*[1 1],'k--');
  plot(h_axes(3),param.collate_deconv.rbins{img}(2)*[1 1], [0 debug_ylim],'k--');
  title(h_axes(3),sprintf('SNR falling edge (rline %d of %d)',rline, length(spec.deconv_gps_time)));
  xlabel(h_axes(3),'Range bin');
  ylabel(h_axes(3),'SNR (dB)');
  ylim(h_axes(3), [0 debug_ylim]);
  grid(h_axes(3), 'on');
  
  clf(h_fig(4));
  set(h_fig(4),'Name','SNR rising edge');
  h_axes(4) = axes('parent',h_fig(4));
  plot(h_axes(4),SNR)
  hold(h_axes(4),'on');
  plot(h_axes(4),[1 length(SNR)], 20*[1 1],'k--');
  plot(h_axes(4),(Nt+param.collate_deconv.rbins{img}(1))*[1 1], [0 debug_ylim],'k--');
  title(h_axes(4),sprintf('SNR rising edge (rline %d of %d)',rline, length(spec.deconv_gps_time)));
  xlabel(h_axes(4),'Range bin');
  ylabel(h_axes(4),'SNR (dB)');
  ylim(h_axes(4), [0 debug_ylim]);
  grid(h_axes(4), 'on');
  
  linkaxes(h_axes([1 3]),'x');
  linkaxes(h_axes([2 4]),'x');
  
  if any(strcmp('visible',param.collate_deconv.debug_plots))
    keyboard
  end
end

%% Stage 1: Test deconvolution

% Create frequency axis
Nt = length(spec.deconv_sample{rline});

% Get sample rline parameters
fc = spec.deconv_fc(rline);
t0 = spec.deconv_t0(rline);
dt = spec.dt;
time = t0 + dt*(0:Nt-1).';

% Adjust deconvolution signal to match sample rline
h_filled = [h_nonnegative; zeros(length(spec.deconv_sample{rline})-length(h_nonnegative)-length(h_negative),1); h_negative];
deconv_Nt = length(h_filled);
% Is dt different? Error
if dt ~= spec.dt
  error('The fast time sample spacing of the data (%g) does not match the deconvolution waveform sampling (%g).',dt,spec.dt);
end
% Is fc different? Multiply time domain by exp(1i*2*pi*dfc*deconv_time)
dfc = fc - spec.deconv_fc(rline);
if dfc/fc > 1e-6
  deconv_time = t0 + dt*(0:Nt-1).';
  h_filled = h_filled .* exp(1i*2*pi*dfc*deconv_time);
end
% Take FFT of deconvolution impulse response
h_filled = fft(h_filled);

% Create inverse filter relative to window
df = 1/(Nt*dt);
freq = spec.deconv_fc(rline) + df * ifftshift(-floor(Nt/2) : floor((Nt-1)/2)).';
freq = fftshift(freq);
Nt_shorten = find(param.collate_deconv.f0 <= freq,1);
Nt_shorten(2) = length(freq) - find(param.collate_deconv.f1 >= freq,1,'last');
Nt_Hwind = Nt - sum(Nt_shorten);
Hwind = deconv.ref_window(Nt_Hwind);
Hwind_filled = ifftshift([zeros(Nt_shorten(1),1); Hwind; zeros(Nt_shorten(end),1)]);
if ~param.collate_deconv.magnitude_only.en
  % Apply regular inverse filter (default)
  h_filled_inverse = Hwind_filled ./ h_filled;
else
  % Apply filtered magnitude-only correction
  h_filled_abs_filt = sgolayfilt(double(abs(h_filled)),2,round(param.collate_deconv.magnitude_only.f_cutoff*Nt_Hwind)*2+1);
  if 0
    % For debugging
    clf;
    plot(lp(h_filled))
    hold on
    plot(lp(h_filled_abs_filt));
    keyboard
  end
  h_filled_inverse = Hwind_filled ./ h_filled_abs_filt;
end

% Apply deconvolution with unnormalized filter
h_deconvolved = ifft(fft(spec.deconv_sample{rline}) .* h_filled_inverse);
% Oversample to get a good measurement of the peak value
h_deconvolved = interpft(h_deconvolved,Mt*Nt);

% Create ideal response (follow same steps as h_deconvolved)
h_ideal = deconv.ref_window(Nt_Hwind);
h_ideal = ifftshift([zeros(Nt_shorten(1),1); h_ideal; zeros(Nt_shorten(end),1)]);
h_ideal = ifft(h_ideal);
h_ideal = interpft(h_ideal,Mt*Nt);

% Oversample sample signal by the same amount as the deconvolved
% signal
h_sample = interpft(spec.deconv_sample{rline},Mt*Nt);

% Scale so that the peak value matches between deconvolved and
% sample (this h_mult_factor is used in data_pulse_compress)
h_mult_factor = max(abs(h_sample)) / max(abs(h_deconvolved));
h_filled_inverse = h_filled_inverse * h_mult_factor;
h_deconvolved = h_deconvolved * h_mult_factor;

% Find maximum values and indices for the deconvolved and
% undeconvolved signals.
[ideal_max_val,ideal_max_idx] = max(h_ideal);
[deconv_max_val,deconv_max_idx] = max(h_deconvolved);
[max_val,max_idx] = max(h_sample);

%% Stage 1: Plot h_deconvolved, f0, f1, SL_guard_bins
if deconv_plot
  
  comp_bins = param.collate_deconv.rbins{img}(2)+1:2*param.collate_deconv.rbins{img}(2);
  comp_bins = Nt+2*param.collate_deconv.rbins{img}(1) : Nt+param.collate_deconv.rbins{img};
  dnoise = lp(mean(abs(h_sample(comp_bins)).^2) ./ mean(abs(h_deconvolved(comp_bins)).^2));
  dsignal = lp(max(abs(h_sample).^2) ./ max(abs(h_deconvolved).^2));
  dSNR = dsignal - dnoise;
  
  fprintf('Deconvolved response relative to regular response:\n');
  fprintf('  SNR loss: %.1f dB\n', dSNR)
  fprintf('  Peak magnitude offset: %.1f (dB)\n', lp(max_val./deconv_max_val));
  fprintf('  Peak angle offset: %.1f (deg)\n', angle(max_val./deconv_max_val) * 180/pi);
  fprintf('  Index offset: %d\n', mod(max_idx - deconv_max_idx + Nt*Mt/2, Nt*Mt)-Nt*Mt/2);
  
  bins_Mt = 0:1/Mt:Nt-1/Mt;
  
  clf(h_fig(1));
  set(h_fig(1),'Name','Impulse response falling edge');
  h_axes = axes('parent',h_fig(1));
  [max_val,max_idx] = max(lp(h_sample,2));
  plot(h_axes(1), bins_Mt, circshift(lp(h_sample) - max_val,[-max_idx 1]))
  hold(h_axes(1),'on');
  plot(h_axes(1), bins_Mt, circshift(lp(h_deconvolved) - max_val + dsignal,[-max_idx 1]))
  plot(h_axes(1), bins_Mt, circshift(lp(h_ideal) - lp(ideal_max_val,2),[-ideal_max_idx 1]))
  plot(h_axes(1), param.collate_deconv.SL_guard_bins*[1 1], [-debug_ylim 0], 'k--');
  xlabel(h_axes(1), 'Range bin');
  ylabel(h_axes(1), 'Relative power (dB)');
  title(h_axes(1), sprintf('Impulse response falling edge (frm %d-rec %d-rline %d) %d-%d',floor(deconv.frm(rline)),deconv.rec(rline),rline,wf,adc));
  legend(h_axes(1), 'sample','deconvolved','ideal','location','best');
  xlim(h_axes(1), [0 2*param.collate_deconv.rbins{img}(2)]);
  ylim(h_axes(1), [-debug_ylim 0]);
  grid(h_axes(1), 'on');
  
  clf(h_fig(2));
  set(h_fig(2),'Name','Impulse response rising edge');
  h_axes(2) = axes('parent',h_fig(2));
  [max_val,max_idx] = max(lp(h_sample,2));
  plot(h_axes(2), fliplr(bins_Mt+1), circshift(lp(h_sample) - max_val,[-max_idx 1]))
  hold(h_axes(2),'on');
  plot(h_axes(2), fliplr(bins_Mt+1), circshift(lp(h_deconvolved) - max_val + dsignal,[-max_idx 1]))
  plot(h_axes(2), fliplr(bins_Mt+1), circshift(lp(h_ideal) - lp(ideal_max_val,2),[-ideal_max_idx 1]))
  plot(h_axes(2), (1+param.collate_deconv.SL_guard_bins)*[1 1], [-debug_ylim 0], 'k--');
  xlabel(h_axes(2), 'Range bin');
  ylabel(h_axes(2), 'Relative power (dB)');
  title(h_axes(2), sprintf('Impulse response rising edge (frm %d-rec %d-rline %d) %d-%d',floor(deconv.frm(rline)),deconv.rec(rline),rline,wf,adc));
  legend(h_axes(2), 'sample','deconvolved','ideal','location','best');
  xlim(h_axes(2), [0 -2*param.collate_deconv.rbins{img}(1)]);
  ylim(h_axes(2), [-debug_ylim 0]);
  grid(h_axes(2), 'on');
  
  clf(h_fig(3));
  set(h_fig(3),'Name','Transfer function');
  h_axes(3) = axes('parent',h_fig(3));
  plot(h_axes(3), lp(h_filled))
  hold(h_axes(3),'on');
  plot(h_axes(3), lp(Hwind_filled,1) - max(lp(Hwind_filled,1)) + max(lp(h_filled)))
  plot(h_axes(3), lp(h_filled_inverse) - max(lp(h_filled_inverse)) + max(lp(h_filled)))
  xlabel(h_axes(3), 'Frequency bin');
  ylabel(h_axes(3), 'Relative power (dB)');
  % Title gives frame, record, and range line for this deconvolution
  % waveform. It also gives the radiometric error.
  title(h_axes(3), sprintf('Transfer function (frm %d-rec %d-rline %d) %.1f/%.1f dB %d-%d',floor(deconv.frm(rline)),deconv.rec(rline),rline,deconv.radiometric_error_dB(rline),max(deconv.radiometric_error_dB),wf,adc));
  legend(h_axes(3), 'sample','window','inverse','location','best');
  grid(h_axes(3), 'on');
  
  fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_falling_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.fig'];
  fprintf('Saving %s\n', fig_fn);
  fig_fn_dir = fileparts(fig_fn);
  if ~exist(fig_fn_dir,'dir')
    mkdir(fig_fn_dir);
  end
  ct_saveas(h_fig(1),fig_fn);
  fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_falling_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.jpg'];
  fprintf('Saving %s\n', fig_fn);
  ct_saveas(h_fig(1),fig_fn);
  
  fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_rising_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.fig'];
  fprintf('Saving %s\n', fig_fn);
  fig_fn_dir = fileparts(fig_fn);
  if ~exist(fig_fn_dir,'dir')
    mkdir(fig_fn_dir);
  end
  ct_saveas(h_fig(2),fig_fn);
  fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_rising_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.jpg'];
  fprintf('Saving %s\n', fig_fn);
  ct_saveas(h_fig(2),fig_fn);
  
  fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_transfer_func_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.fig'];
  fprintf('Saving %s\n', fig_fn);
  fig_fn_dir = fileparts(fig_fn);
  if ~exist(fig_fn_dir,'dir')
    mkdir(fig_fn_dir);
  end
  ct_saveas(h_fig(3),fig_fn);
  fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_transfer_func_wf_%02d_adc_%02d',param.collate_deconv.out_path,wf,adc)) '.jpg'];
  fprintf('Saving %s\n', fig_fn);
  ct_saveas(h_fig(3),fig_fn);
  
  if any(strcmp('visible',param.collate_deconv.debug_plots))
    keyboard
  end
end
