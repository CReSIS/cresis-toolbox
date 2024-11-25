function [td_out,amp_out,phase_out,full_out] = rx_chan_equal(data,param,hdr)
% [td_out,amp_out,phase_out,full_out] = rx_chan_equal(data,param,hdr)
%
% Inputs:
% data = Nt by Nx by Nc single/double matrix
%   Nt = fast time
%   Nx = slow time
%   Nc = cross-track channels
% param = structure controlling receiver channel equalization
%  .img = single wf-adc list (Nc by 2 matrix)
%    List of wf-adc pairs.
%    [wf adc; wf adc; ... ; wf adc];
%    hdr.img(wf_adc_idx,:) corresponds to data(:,:,wf_adc_idx)
%  .lever_arm_fh = function handle to lever arm code
%    no default supplied, but not required if param.mocomp_type equals 0
%  .mocomp_type = scalar integer (see param.type in motion_comp.m)
%  .td = time delay correction for each wf_adc pair (Nc by 1 vector)
%    e.g. -12 ns implies channel is delayed by 12 ns so 12 ns of delay
%    will be removed (targets will move to a closer range)
%    default is all zeros, units of seconds
%  .phase = phase correction for each wf_adc pair (Nc by 1 vector)
%    e.g. 35 deg implies channel leads by 35 deg so -35 deg phase will be
%    applied (target phases will have -35 deg phase from original)
%    default is all zeros, units of degrees (angle(voltage)*180/pi)
%  .amp = amplitude correction for each wf_adc pair (Nc by 1 vector)
%    e.g. 2 dB implies channel is 2 dB larger so -2 dB amplitude adjustment
%    will be applied (targets will be 2 dB smaller)
%    default is all zeros, units of log power (20*log(voltage))
%  .plot_en = enable plotting of outputs
%    default is false
%  .delay: struct describing how the time delay between channels is found
%   .method: string containing the system time delay method. The options
%     are:
%       'xcorr_complex': Finds time delay between channels by finding the
%         lag of the peak of the cross correlation. This is the default.
%       'peak': Finds time delay between channels by finding the offset
%         between the peak values.
%   .ref_bins: Only required for the xcorr_complex delay method. Sets the
%     bins to use from the reference wf-adc channel.
%       [-20 20] uses 20 bins before and after the surface
%     Default is [-20 20].
%   .search_bins: Depends on the delay method used. The options
%     are:
%       'xcorr_complex': For the channel being compared to the reference,
%         [-7 7] uses 7 bins before and after the surface.
%       'peak': [-7 7] searches 7 bins backward and forward from the
%         surface bin for the peak.
%     Default is [-7 7].
%   .Mt: over-sampling factor to use in determining delay. Default is 64.
% hdr = structure describing data
%  .{lat,lon,elev,roll,pitch,heading}
%    1 by Nx vectors
%    Not required if param.mocomp_mode is 0 or 1
%    lat,lon in degrees
%    elev in meters
%    roll, pitch, heading in radians
%  .time = double Nt by 1 vector, fast-time axis of data, seconds
%
% Outputs:
%   td_out = recommended hdr.td
%   phase_out = recommended hdr.phase
%   amp_out = recommended hdr.amp
%
% Authors: Logan Smith, John Paden, Jilu Li

%% Input arguments and general setup
% ======================================================================

% rlines,rbins: Format inputs to select region to find max signal
param.noise_rlines = round(param.noise_rlines);
param.noise_rbins= round(param.noise_rbins);
param.noise_rlines = sort(param.noise_rlines);
param.noise_rbins = sort(param.noise_rbins);
if param.noise_rbins(1) < 1
  param.noise_rbins(1) = 1;
end
if param.noise_rbins(end) > size(data,1)
  param.noise_rbins(end) = size(data,1);
end
if param.noise_rlines(1) < 1
  param.noise_rlines(1) = 1;
end
if param.noise_rlines(end) > size(data,2)
  param.noise_rlines(end) = size(data,2);
end
noise_rlines = param.noise_rlines(1):param.noise_rlines(end);
noise_rbins = param.noise_rbins(1):param.noise_rbins(end);

param.rlines = round(param.rlines);
param.rbins= round(param.rbins);
param.rlines = sort(param.rlines);
param.rbins = sort(param.rbins);
if param.rbins(1) < 1
  param.rbins(1) = 1;
end
if param.rbins(end) > size(data,1)
  param.rbins(end) = size(data,1);
end
if param.rlines(1) < 1
  param.rlines(1) = 1;
end
if param.rlines(end) > size(data,2)
  param.rlines(end) = size(data,2);
end
rlines = param.rlines(1):param.rlines(end);
rbins = param.rbins(1):param.rbins(end);

% ref_idx: index into data that will be the reference
ref_idx = param.config.ref_wf_adc;

% colors: used for plotting
colors = {'k.','r.','y.','g.','c.','b.','m.','kx','rx','yx','gx','cx','bx','mx','ko','ro','yo','go','co','bo','mo','k+','r+','y+'};

% ave_fh: averaging function handle
ave_fh = param.averaging_fh;

% freq,time: extract frequency and time axes
freq = param.freq;
time = param.time;

if ~isfield(param.config,'delay')
  param.config.delay = [];
end

if ~isfield(param.config.delay,'method') || isempty(param.config.delay.method)
  param.config.delay.method = 'xcorr_complex';
end
  
%% Setup code for estimation equalization coefficients
switch(param.config.delay.method)
  case 'threshold'
    delay_method = 1;
  case 'xcorr_complex'
    delay_method = 2;
  case 'xcorr_magnitude'
    delay_method = 3;
  case 'peak'
    delay_method = 4;
  otherwise
    error('delay.method %d is not supported', param.analysis.surf.delay.method);
end

if ~isfield(param.config.delay,'ref_bins') || isempty(param.config.delay.ref_bins)
  param.config.delay.ref_bins = -20:20;
end

if ~isfield(param.config.delay,'search_bins') || isempty(param.config.delay.search_bins)
  param.config.delay.search_bins = -7:7;
end

if ~isfield(param.config.delay,'Mt') || isempty(param.config.delay.Mt)
  param.config.delay.Mt = 64;
end

if ~isfield(param,'td') || isempty(param.td)
  param.td = zeros(size(data,3),1);
end

if ~isfield(param,'amp') || isempty(param.amp)
  param.amp = zeros(size(data,3),1);
end

if ~isfield(param,'phase') || isempty(param.phase)
  param.phase = zeros(size(data,3),1);
end

if ~isfield(param,'coherent_noise_removal') || isempty(param.coherent_noise_removal)
  param.coherent_noise_removal = false;
end

if ~isfield(param,'multilook') || isempty(param.multilook)
  param.multilook = ones(1,7)/7;
end

if ~isfield(param,'plot_en') || isempty(param.plot_en)
  param.plot_en = false;
end

clear full_out;

%% Prepare surface data
% ======================================================================
if param.coherent_noise_removal
  data = data - repmat(mean(data,2), [1 size(data,2) 1]);
end

%% Motion compensation
% ======================================================================
mocomp_param.type = param.mocomp_type;
mocomp_param.tx_weights = param.tx_weights;
mocomp_param.season_name = param.season_name;
mocomp_param.radar_name = param.radar_name;
mocomp_param.gps_source = hdr.gps_source;
for wf_adc_idx = 1:size(data,3)
  wf = abs(param.config.img(wf_adc_idx,1));
  adc = param.config.img(wf_adc_idx,2);
  mocomp_param.rx = param.rx_paths{wf}(adc);
  
  % drange = change in range (positive is longer range)
  drange = basic_motion_comp(mocomp_param,param.lever_arm_fh,hdr.roll, ...
    hdr.pitch,hdr.heading,hdr.lat,hdr.lon,hdr.elev);
  % dtime = Convert to time (in air), positive is longer range/time-delay
  dtime = 2*drange/3e8;
  Nt = size(data,1);
  Nx = size(data,2);
  if 0
    figure(1); clf;
    plot(dtime*1e9);
    title('adc %d');
    pause;
  end
  % Time shift data in the frequency domain
  %   A positive dtime implies a larger negative phase delay (since
  %   delay is negative/lagging phase)
  data(:,:,wf_adc_idx) = ifft(fft(data(:,:,wf_adc_idx)) ...
    .*exp(-1i*2*pi*repmat(freq,1,Nx).*repmat(dtime,Nt,1)));
end

num_chan = size(data,3);

%% Apply time correction
%   Time delay is removed (positive moves targets closer in range)
% =======================================================================
w = 2*pi*freq;
for wf_adc_idx = 1:size(data,3)
  wf = abs(param.config.img(wf_adc_idx,1));
  adc = param.config.img(wf_adc_idx,2);
  data(:,:,wf_adc_idx) = ifft(fft(data(:,:,wf_adc_idx)).*exp(1i*repmat(w,1,size(data,2))*param.td(param.rx_paths{wf}(adc))));
end

%% Apply amplitude and phase correction
%   Amp/phase are DIVIDED out as opposed to being multiplied
% =======================================================================

for wf_adc_idx = 1:size(data,3)
  wf = abs(param.config.img(wf_adc_idx,1));
  adc = param.config.img(wf_adc_idx,2);
  data(:,:,wf_adc_idx) = data(:,:,wf_adc_idx) ./ (10^(param.amp(param.rx_paths{wf}(adc))/20).*exp(1i*param.phase(param.rx_paths{wf}(adc))/180*pi));
end
ascope_check_flag = 0;  % compare average ascopes before and after equalization
if ascope_check_flag
  data_combine = sum(data,3);
  figure(4);plot(mean(lp(data_combine),2),'r');grid;legend('no eq','with eq');hold off;
  disp('press any key to continue')
  pause
end

%% Surface tracker
% =======================================================================
if param.combine_channels
  surf_data = mean(data,3);
else
  surf_data = data(:,:,ref_idx);
end
surf_data = fir_dec(abs(surf_data).^2,param.multilook,1);

[surf_vals surf_bins] = max(surf_data(rbins,rlines));
surf_bins = rbins(1)-1 + surf_bins;

surface_tracker_check_flag = 1;
if surface_tracker_check_flag
  % Debug code for checking surface tracker
  figure(1000); clf;
  %imagesc([],rbins,lp(data(rbins,:,ref_idx)));
  imagesc([],rbins,lp(surf_data(rbins,:)));
  colormap(1-gray(256));
  hold on;
  plot(rlines, surf_bins,'r-.');
  hold off;
  xlabel('Record');
  ylabel('Range bin');
  title('Echogram with surface track result');
end

if 0
  % Check that all channels are good
  sig_power = zeros(size(data,3),length(rlines));
  for rline_idx = 1:length(rlines)
    rline = rlines(rline_idx);
    sig_power(:,rline_idx) = data(surf_bins(rline_idx),rline,:);
  end
else
  % Check only that the reference channel is good
  sig_power = zeros(1,length(rlines));
  for rline_idx = 1:length(rlines)
    rline = rlines(rline_idx);
    sig_power(:,rline_idx) = data(surf_bins(rline_idx),rline,ref_idx);
  end
end

noise_power = mean(mean(abs(data(noise_rbins,noise_rlines)).^2));
good_rlines = find(all(lp(sig_power.') > lp(noise_power) + param.snr_threshold,2));
data = data(:,good_rlines,:);
surf_bins = surf_bins(good_rlines);
rlines = 1:length(good_rlines);

data_check_flag = 0;
if data_check_flag
  lp(noise_power)
  h_axes = [];
  for h_fig = 1:size(data,3)
    figure(h_fig+100); clf;
    set(h_fig+100,'WindowStyle','docked');
    imagesc(lp(data(:,:,h_fig)));
    colorbar;
    hold on;
    plot(surf_bins);
    hold off;
    h_axes(end+1) = gca;
    xlabel('Record');
    ylabel('Range bin');
    h = colorbar;
    set(get(h,'YLabel'),'String','Relative power (dB)');
    title(sprintf('wf_adc pair %d',h_fig),'interpreter','none')
    ylim([max(1,rbins(1)-10) min(size(data,1),rbins(end)+10)]);
  end
  linkaxes(h_axes,'xy');
end

if ascope_check_flag
  data_combine = sum(data,3);
  figure(4);plot(mean(lp(data_combine),2));hold on;
end

%% Cross correlation to determine recommended time, phase, and amplitude offsets
% =======================================================================
ref_bins = param.config.delay.ref_bins(1) : param.config.delay.ref_bins(end);
search_bins = param.config.delay.search_bins(1) : param.config.delay.search_bins(end);
zero_padding_offset = length(search_bins) - length(ref_bins);
Hcorr_wind = hanning(length(ref_bins));
clear peak_val peak_offset;

peak_val = zeros(size(data,3),length(rlines));
peak_offset = zeros(size(data,3),length(rlines));

if delay_method == 2
  %% Cross correlation method with complex data
  for adc_idx = 1:size(data,3)
    for rline_idx = 1:length(rlines)
      rline = rlines(rline_idx);
      [corr_out,lags] = xcorr(data(surf_bins(rline_idx)+search_bins,rline,adc_idx), ...
        data(surf_bins(rline_idx)+ref_bins,rline,ref_idx) .* Hcorr_wind);
      corr_int = interpft(corr_out,param.config.delay.Mt*length(corr_out));
      [peak_val(adc_idx,rline_idx) peak_offset(adc_idx,rline_idx)] = max(corr_int);
      peak_val(adc_idx,rline_idx) = abs(max(data(surf_bins(rline_idx)+search_bins,rline,adc_idx))) ...
        .*exp(1i*angle(peak_val(adc_idx,rline_idx)));
      peak_offset(adc_idx,rline_idx) = (peak_offset(adc_idx,rline_idx)-1)/param.config.delay.Mt+1 ...
        + ref_bins(1) + search_bins(1) - 1 - zero_padding_offset;
    end
  end
  
  peak_offset = peak_offset - repmat(peak_offset(ref_idx,:),[size(peak_offset,1),1]);
  dt = (time(2)-time(1));
  
elseif delay_method == 3
  %% Cross correlation method with magnitude data
  error('Not finished');
  
elseif delay_method == 3
  %% Threshold method
  error('Not finished');
  
elseif delay_method == 4
  %% Peak method
  for rline_idx = 1:length(rlines)
    rline = rlines(rline_idx);
    data_int = interpft(data(surf_bins(rline_idx)+search_bins,rline,ref_idx),param.config.delay.Mt*length(search_bins));
    [peak_val(ref_idx,rline_idx),peak_offset(ref_idx,rline_idx)] = max(data_int);
  end
  
  adc_idxs = 1:size(data,3);
  adc_idxs(adc_idxs==ref_idx) = [];
  for adc_idx = adc_idxs
    for rline_idx = 1:length(rlines)
      rline = rlines(rline_idx);
      data_int = interpft(data(surf_bins(rline_idx)+search_bins,rline,adc_idx),param.config.delay.Mt*length(search_bins));
      [peak_val(adc_idx,rline_idx),peak_offset(adc_idx,rline_idx)] = max(data_int);
      peak_offset(adc_idx,rline_idx) = peak_offset(adc_idx,rline_idx) - peak_offset(ref_idx,rline_idx);
      peak_val(adc_idx,rline_idx) = abs(peak_val(adc_idx,rline_idx)).*exp(1i*angle(data_int(peak_offset(ref_idx,rline_idx))));
    end
  end
  peak_offset = peak_offset / param.config.delay.Mt;
  peak_offset(ref_idx,:) = 0;
  dt = (time(2)-time(1));
else
    error('method not supported');
end

%% Roll Estimation
param.roll_est.bin_rng = 0;
param.roll_est.rline_rng = -5:5;
param.roll_est.Nsig = 1;
y_offset = zeros(size(data,3),1);
z_offset = zeros(size(data,3),1);
lever_arm_param.season_name = param.season_name;
lever_arm_param.radar_name = ct_output_dir(param.radar_name);
lever_arm_param.gps_source = hdr.gps_source;
for wf_adc_idx = 1:size(data,3)
  wf = abs(param.config.img(wf_adc_idx,1));
  adc = param.config.img(wf_adc_idx,2);
  mocomp_param.rx = param.rx_paths{wf}(adc);
  phase_center = lever_arm(lever_arm_param, param.tx_weights, mocomp_param.rx);
  y_offset(wf_adc_idx) = -phase_center(2);
  z_offset(wf_adc_idx) = -phase_center(3);
end

% [theta,sv] = array_proc_sv(256,param.freq(1), y_offset, z_offset);
[theta,sv] = array_proc_sv(param.freq(1), y_offset, z_offset, 256);

theta = fftshift(theta);
sv = fftshift(sv,2);

Nt = size(data,1);
Nx = size(data,2);
Nc = size(data,3);
roll_est_val = [];
roll_est_theta = [];
for rline = 1:length(rlines)
  bin = surf_bins(rline);
  
  if rline+param.roll_est.rline_rng(1) < 1
    start_rline_rng = 1-rline;
  else
    start_rline_rng = param.roll_est.rline_rng(1);
  end
  if rline+param.roll_est.rline_rng(end) > Nx
    stop_rline_rng = Nx-rline;
  else
    stop_rline_rng = param.roll_est.rline_rng(end);
  end
  rline_rng = start_rline_rng : stop_rline_rng;
  
  if bin+param.roll_est.bin_rng(1) < 1
    bin_rng = 1-bin : param.roll_est.bin_rng(end);
  elseif  bin+param.roll_est.bin_rng(end) > Nt
    bin_rng = param.roll_est.bin_rng(1) : Nt-bin;
  else
    bin_rng = param.roll_est.bin_rng;
  end
  
  dataSample = data(bin+bin_rng,rline+rline_rng,:);
  dataSample = reshape(dataSample,[length(bin_rng)*length(rline_rng) Nc]).';
  
  Rxx = 1/size(dataSample,1) * (dataSample * dataSample');
  [V,D] = eig(Rxx);
  eigenVals = diag(D);
  [eigenVals noiseIdxs] = sort(eigenVals);
  noiseIdxs = noiseIdxs(1:end-param.roll_est.Nsig);
  music_pattern = mean(abs(sv'*V(:,noiseIdxs)).^2,2);
  [roll_est_val(rline),roll_est_idx] = min(music_pattern);
  roll_est_theta(rline) = theta(roll_est_idx);
end
full_out.roll_est_theta = roll_est_theta;
full_out.roll_est_val = roll_est_val;
full_out.gps_time = hdr.gps_time(rlines);

%% Calculate corrections
% =======================================================================

ref_val = zeros(size(data,3),1);
ref_val_pow = zeros(size(data,3),1);
full_out.peak_ref = zeros(size(peak_val));
full_out.peak_offset = peak_offset;
for wf_adc_idx = 1:size(data,3)
  full_out.peak_ref(wf_adc_idx,:) = peak_val(wf_adc_idx,:)./peak_val(ref_idx,:);
  ref_val(wf_adc_idx) = ave_fh(peak_val(wf_adc_idx,:)./peak_val(ref_idx,:),2);
  ref_val_pow(wf_adc_idx) = ave_fh(abs(peak_val(wf_adc_idx,:)./peak_val(ref_idx,:)).^2,2);
end

td_out = param.td;
amp_out = param.amp;
phase_out = param.phase;
for wf_adc_idx = 1:size(data,3)
  wf = abs(param.config.img(wf_adc_idx,1));
  adc = param.config.img(wf_adc_idx,2);
  td_out(param.rx_paths{wf}(adc)) = param.td(param.rx_paths{wf}(adc)) + ave_fh(peak_offset(wf_adc_idx,:))*dt;
  amp_out(param.rx_paths{wf}(adc)) = param.amp(param.rx_paths{wf}(adc)) + lp(ref_val_pow(wf_adc_idx),1);
  phase_out(param.rx_paths{wf}(adc)) = param.phase(param.rx_paths{wf}(adc)) + angle(ref_val(wf_adc_idx))*180/pi;
end

%% Optional printing and plotting
% =======================================================================

if param.plot_en
  figure(1); clf;
  ha1 = axes;  hold on;
  figure(2); clf;
  ha2 = axes;  hold on;
  figure(3); clf;
  subplot(3,1,1);
  plot(hdr.roll(good_rlines)*180/pi)
  ylabel('roll (deg)');
  subplot(3,1,2:3);
  plot([]); ha3 = gca;  hold on;
  clear leg_cell;
  for wf_adc_idx = 1:size(data,3)
    wf = abs(param.config.img(wf_adc_idx,1));
    adc = param.config.img(wf_adc_idx,2);
    rx = param.rx_paths{wf}(adc);
    plot(ha1,peak_offset(wf_adc_idx,:) - peak_offset(ref_idx,:),[colors{mod(wf_adc_idx-1,length(colors))+1}])
    plot(ha2,lp(peak_val(wf_adc_idx,:)./peak_val(ref_idx,:),2),[colors{mod(wf_adc_idx-1,length(colors))+1}])
    plot(ha3,180/pi*angle(peak_val(wf_adc_idx,:)./peak_val(ref_idx,:)),[colors{mod(wf_adc_idx-1,length(colors))+1}])
    leg_cell{wf_adc_idx} = sprintf('rx %d',rx);
  end
  for wf_adc_idx = 1:size(data,3)
    plot(ha1,[1 length(rlines)],[ave_fh(peak_offset(wf_adc_idx,:) - peak_offset(ref_idx,:)) ave_fh(peak_offset(wf_adc_idx,:) - peak_offset(ref_idx,:))],colors{mod(wf_adc_idx-1,length(colors))+1})
    plot(ha2,[1 length(rlines)],[lp(ref_val_pow(wf_adc_idx),1) lp(ref_val_pow(wf_adc_idx),1)],colors{mod(wf_adc_idx-1,length(colors))+1})
    plot(ha3,[1 length(rlines)],180/pi*[angle(ave_fh(peak_val(wf_adc_idx,:)./peak_val(ref_idx,:))) angle(ave_fh(peak_val(wf_adc_idx,:)./peak_val(ref_idx,:)))],colors{mod(wf_adc_idx-1,length(colors))+1})
  end
  title(ha1,'index offset')
  title(ha2,'power offset')
  title(ha3,'phase offset')
  legend(ha1,leg_cell);
  legend(ha2,leg_cell);
  legend(ha3,leg_cell);
  hold(ha1,'off')
  hold(ha2,'off')
  hold(ha3,'off')
  drawnow;
  
  fprintf('Peak offset indices:\n');
  fprintf('%.1f\t', ave_fh(peak_offset(1:end-1,:),2));
  fprintf('%.1f', ave_fh(peak_offset(end,:),2));
  fprintf('\n');
  
  fprintf('Recommended td settings (ns):\n');
  fprintf('%.1f\t', td_out(1:end-1)*1e9);
  fprintf('%.1f', td_out(end)*1e9);
  fprintf('\n');
  
  fprintf('Recommended amp settings (dB):\n');
  fprintf('%.1f\t', amp_out(1:end-1));
  fprintf('%.1f', amp_out(end));
  fprintf('\n');
  
  fprintf('Recommended phase settings (deg):\n');
  fprintf('%.1f\t', phase_out(1:end-1));
  fprintf('%.1f', phase_out(end));
  fprintf('\n');
  
end

return;

