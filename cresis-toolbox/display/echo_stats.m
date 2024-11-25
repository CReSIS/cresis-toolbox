function echo_stats(param,param_override)
% echo_stats(param,param_override)
%
% Author: John Paden
%
% See also: echo_detrend, echo_filt, echo_mult_suppress, echo_noise,
% echo_norm, echo_param, echo_stats, echo_stats_layer, echo_xcorr,
% echo_xcorr_profile

%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input arguments check and setup
% =========================================================================

echogram_fn_dir = ct_filename_out(param,param.echo_stats.data_type);

% Load frames associated with this segment
frames = frames_load(param);

% Load layer information
layer_params = [];
layer_params.name = 'surface';
layer_params.source = 'layerdata';
layer_params.existence_check = false;

surf = opsLoadLayers(param,layer_params);

noise_bins = param.echo_stats.noise_bins;
signal_bins = param.echo_stats.signal_bins;


%% Echogram stats
% dt_frm
% bins_frm: time in units of dt_frm
gps_time = [];
bins = [];
sums = [];
counts = [];
min_means = [];
all_bins = {};
all_sums = {};
all_counts = {};
signal_max_vals = [];
signal_mean_vals = [];
noise_max_vals = [];
noise_mean_vals = [];
peak_wfs = [];
for frm = 1:length(frames.frame_idxs)
  %% Echogram stats: Load echogram
  if param.echo_stats.echogram_img == 0
    echogram_fn = fullfile(echogram_fn_dir,sprintf('Data_%s_%03d.mat',param.day_seg,frm));
  else
    echogram_fn = fullfile(echogram_fn_dir, ...
      sprintf('Data_img_%02d_%s_%03d.mat',param.echo_stats.echogram_img,param.day_seg,frm));
  end
  fprintf('%d of %d: %s\n', frm, length(frames.frame_idxs), echogram_fn);
  mdata = load_L1B(echogram_fn);
  if length(mdata.Time) < 2
    continue;
  end
  dt_frm = mdata.Time(2)-mdata.Time(1);
  mdata.Time = mdata.Time - mod(mdata.Time(1),dt_frm);
  if frm == 1
    dt = dt_frm;
  elseif abs((dt_frm-dt)/dt_frm) > 1e-6
    error('dt has changed from %.14g to %14g.', dt, dt_frm);
  end
  Nt = size(mdata.Data,1);
  Nx = size(mdata.Data,2);
  
  %% Echogram stats: Interpolate surface
  % Surface
  surf_bins = interp1(surf.gps_time,surf.twtt,mdata.GPS_time);
  surf_bins = interp_finite(surf_bins,NaN);
  surf_bins = round(interp1(mdata.Time,1:Nt,surf_bins));
  
  %% Echogram stats: Prep data
  data_nomask = lp(mdata.Data);
  data_nomask(~isfinite(data_nomask)) = NaN;
  for rline = 1:Nx
    last_bin = find(~isnan(data_nomask(:,rline)),1,'last');
    data_nomask(max(1,last_bin-4):last_bin,rline) = NaN;
  end
  
  % Create signal mask
  mask = false(Nt,Nx);
  for rline = 1:Nx
    if ~isnan(surf_bins(rline))
      mask(max(1,surf_bins(rline)+signal_bins(1)) : min(Nt,surf_bins(rline)+signal_bins(end)),rline) = true;
    end
  end
  data = data_nomask;
  data(mask) = NaN;
  data(data>param.echo_stats.detrend_threshold) = NaN;
  
  %% Echogram stats: Average bin value
  % Mean value results
  bins_frm = round(mdata.Time/dt_frm);
  sums_frm = nansum(data,2); % Take the mean of all valid samples
  counts_frm = sum(~isnan(data),2); % How many samples were used to calculate the mean
  
  if isempty(bins)
    bins = bins_frm;
    sums = zeros(size(sums_frm));
    counts = zeros(size(counts_frm));
    min_means = nan(size(sums_frm));
  end
  if bins_frm(1) < bins(1)
    % Add new bins_frm to beginning of bins
    sums = [zeros(bins(1)-bins_frm(1),1); sums];
    counts = [zeros(bins(1)-bins_frm(1),1); counts];
    min_means = [nan(bins(1)-bins_frm(1),1); min_means];
    bins = bins_frm(1) : bins(end);
  end
  if bins_frm(end) > bins(end)
    % Add new bins_frm to end of bins
    sums = [sums; zeros(bins_frm(end)-bins(end),1)];
    counts = [counts; zeros(bins_frm(end)-bins(end),1)];
    min_means = [min_means; nan(bins_frm(end)-bins(end),1)];
    bins = bins(1) : bins_frm(end);
  end
  bin_start = bins_frm(1)-bins(1);
  sums(bin_start + (1:Nt)) = sums(bin_start + (1:Nt)) + sums_frm;
  counts(bin_start + (1:Nt)) = counts(bin_start + (1:Nt)) + counts_frm;
  all_bins{frm} = bins_frm;
  all_sums{frm} = sums_frm;
  all_counts{frm} = counts_frm;
  
  first_bin = find(sums_frm~=0,1) + 0;
  last_bin = find(sums_frm~=0,1,'last') - 0;
  means_frm = sums_frm ./ counts_frm;
  idxs = find(counts_frm > param.echo_stats.sum_threshold);
  idxs = idxs(idxs>=first_bin & idxs <= last_bin);
  min_means(bin_start + idxs) = min(min_means(bin_start + idxs),means_frm(idxs));
  
  
  %% Echogram stats: Peak waveforms
  [max_vals,max_idxs] = max(data_nomask,[],1);
  peak_wfs_idxs = 1:length(param.echo_stats.peak_wfs_bins);
  cur_rline = size(peak_wfs,2);
  peak_wfs = [peak_wfs, nan(length(param.echo_stats.peak_wfs_bins),Nx)];
  for rline = 1:Nx
    if ~isnan(max_vals(rline))
      test = max_idxs(rline)+param.echo_stats.peak_wfs_bins;
      good_mask = test >= 1 & test <= Nt;
      peak_wfs(peak_wfs_idxs(good_mask),cur_rline+rline) = data_nomask(max_idxs(rline)+param.echo_stats.peak_wfs_bins(good_mask),rline);
    end
  end

  %% Echogram stats: Signal and noise
  % 1. gps_time
  gps_time(end+(1:Nx)) = mdata.GPS_time;
  
  % 2. signal
  data = data_nomask;
  data(~mask) = NaN;
  cur_rline = length(signal_max_vals);
  signal_max_vals(end+(1:Nx)) = zeros(1,Nx);
  signal_mean_vals(end+(1:Nx)) = zeros(1,Nx);
  for rline = 1:Nx
    [signal_max_vals(cur_rline+rline) max_idxs] = nanmax(data(:,rline),[],1);
    signal_mean_vals(cur_rline+rline) = nanmean(data(:,rline),1);
  end
  
  % 3. signal
  % Create noise mask
  mask = false(Nt,Nx);
  for rline = 1:Nx
    if ~isnan(surf_bins(rline))
      mask(max(1,surf_bins(rline)+noise_bins(1)) : min(Nt,surf_bins(rline)+noise_bins(end)),rline) = true;
    end
  end
  data = data_nomask;
  data(~mask) = NaN;
  cur_rline = length(noise_max_vals);
  noise_max_vals(end+(1:Nx)) = zeros(1,Nx);
  noise_mean_vals(end+(1:Nx)) = zeros(1,Nx);
  for rline = 1:Nx
    noise_max_vals(cur_rline+rline) = nanmax(data(:,rline),[],1);
    noise_mean_vals(cur_rline+rline) = nanmean(data(:,rline),1);
  end
end

%% Save Results
output_dir = fileparts(ct_filename_ct_tmp(param,'','echo_stats',''));
if ~exist(output_dir,'dir')
  fprintf('Creating directory %s\n', output_dir);
  mkdir(output_dir);
end

% detrend file
h_fig = figure;
h_axes = axes('parent',h_fig);
[B,A] = butter(2,1/(0.05*length(min_means))); % Smooth to 5% of total length
plot(h_axes, dt*bins*1e6, min_means)
hold(h_axes,'on');
plot(h_axes, dt*bins*1e6, filtfilt(B,A,interp_finite(min_means)))
grid(h_axes,'on');
xlabel(h_axes,'Two way travel time (\mus)');
ylabel(h_axes,'Relative power (dB)');
fig_fn = [ct_filename_ct_tmp(param,'','echo_stats','detrend') '.fig'];
fprintf('Saving %s\n', fig_fn);
saveas(h_fig,fig_fn);
fig_fn = [ct_filename_ct_tmp(param,'','echo_stats','detrend') '.jpg'];
fprintf('Saving %s\n', fig_fn);
saveas(h_fig,fig_fn);
close(h_fig);

% peak_wfs file
SNR = round(signal_max_vals - noise_mean_vals);
SNR_bins = unique(SNR(SNR>10));
SNR_wfs = nan(size(peak_wfs,1),length(SNR_bins));
for idx = 1:length(SNR_bins)
  good_mask = SNR == SNR_bins(idx);
  if sum(good_mask)>500
    SNR_wfs(:,idx) = nanmean(peak_wfs(:,good_mask),2);
  end
end
SNR_wfs_norm = bsxfun(@minus,SNR_wfs,max(SNR_wfs,[],1));
h_fig = figure;
h_axes = axes('parent',h_fig);
plot_color = colormap(jet(length(SNR_bins)));
for idx = 1:length(SNR_bins)
  %scatter(h_axes,param.echo_stats.peak_wfs_bins,SNR_wfs_norm(:,idx),[],SNR_bins(idx)*ones(size(SNR_wfs,1),1),'.');
  plot(h_axes,param.echo_stats.peak_wfs_bins,SNR_wfs_norm(:,idx),'Color', plot_color(idx,:));
  hold(h_axes,'on');
end
xlabel(h_axes,'Range bin');
ylabel(h_axes,'Relative power (dB)');
if length(SNR_bins)>1
  caxis([SNR_bins(1) SNR_bins(end)])
end
h_color = colorbar(h_axes);
set(get(h_color,'ylabel'),'string','SNR (dB)')
grid(h_axes,'on');
fig_fn = [ct_filename_ct_tmp(param,'','echo_stats','peak_wfs') '.fig'];
fprintf('Saving %s\n', fig_fn);
saveas(h_fig,fig_fn);
fig_fn = [ct_filename_ct_tmp(param,'','echo_stats','peak_wfs') '.jpg'];
fprintf('Saving %s\n', fig_fn);
saveas(h_fig,fig_fn);
close(h_fig);

max_vals = max(SNR_wfs,[],1);
max_vals_rounded = round(max_vals);
sidelobe_dB = bsxfun(@minus,SNR_wfs,max_vals-max_vals_rounded);
good_mask = isfinite(max_vals_rounded);
max_vals_rounded = max_vals_rounded(good_mask);
sidelobe_dB = sidelobe_dB(:,good_mask);
[max_vals_rounded,unique_idxs] = unique(max_vals_rounded);
sidelobe_dB = sidelobe_dB(:,unique_idxs);
sidelobe_vals = min(max_vals_rounded) : max(max_vals_rounded);
sidelobe_rows = param.echo_stats.peak_wfs_bins;
if isempty(max_vals_rounded)
  sidelobe_dB = nan(size(sidelobe_rows));
  sidelobe_dB = sidelobe_dB(:);
  sidelobe_vals = nan;
elseif length(max_vals_rounded) >= 2
  % Nothing to do if length(max_vals_rounded) == 1, linear interpolation
  % otherwise:
  sidelobe_dB = interp1(max_vals_rounded, sidelobe_dB.', sidelobe_vals).';
end

% SNR file
records_fn = ct_filename_support(param,'','records');
records = load(records_fn);
frms = interp1([records.gps_time(frames.frame_idxs), records.gps_time(end)+diff(records.gps_time(end-1:end))], ...
  [1:length(frames.frame_idxs), length(frames.frame_idxs)+1], gps_time);
h_fig = figure;
h_axes = axes('parent',h_fig);
plot(h_axes,frms,signal_max_vals);
hold(h_axes,'on');
plot(h_axes,frms,noise_mean_vals);
legend(h_axes,'Signal','Noise');
xlabel(h_axes,'Frames');
ylabel(h_axes,'Relative power (dB)');
grid(h_axes,'on');
title(sprintf('%s',regexprep(param.day_seg,'_','\\_')));
fig_fn = [ct_filename_ct_tmp(param,'','echo_stats','SNR') '.fig'];
fprintf('Saving %s\n', fig_fn);
saveas(h_fig,fig_fn);
fig_fn = [ct_filename_ct_tmp(param,'','echo_stats','SNR') '.jpg'];
fprintf('Saving %s\n', fig_fn);
saveas(h_fig,fig_fn);
close(h_fig);

% Matlab file
mat_fn = [ct_filename_ct_tmp(param,'','echo_stats','stats') '.mat'];
fprintf('Saving %s\n', mat_fn);
param_echo_stats = param;
save(mat_fn,'-v7.3','param_echo_stats','dt','gps_time','bins','sums','counts','min_means','all_bins','all_sums','all_counts','signal_max_vals','signal_mean_vals','noise_max_vals','noise_mean_vals','peak_wfs','SNR_wfs','SNR_bins','sidelobe_vals','sidelobe_rows','sidelobe_dB');
