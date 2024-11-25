% script deconv.test_deconv_wfs
%
% Run this while debugging load_fmcw_data.m just before this line runs:
%   deconv_H = spec.deconv_H{closest_idx};
%
% Start by setting run_version 1 and then update rline variable and switch
% to run_version 2 or 3.


%% User Settings

% Override deconvolution waveforms file... useful for trying waveforms from
% other segments.

% spec = load('/cresis/snfs1/dataproducts/ct_data/snow/2009_Greenland_P3/CSARP_noise/deconv_20090402_02.mat');
% spec = load('/cresis/snfs1/dataproducts/ct_data/snow/2009_Greenland_P3/CSARP_noise/deconv_20090402_03.mat');
% spec = load('/cresis/snfs1/dataproducts/ct_data/snow/2009_Greenland_P3/CSARP_noise/deconv_20090405_01.mat');
% spec = load('/cresis/snfs1/dataproducts/ct_data/snow/2009_Greenland_P3/CSARP_noise/deconv_20090405_02.mat');
% spec = load('/cresis/snfs1/dataproducts/ct_data/snow/2009_Greenland_P3/CSARP_noise/deconv_20090405_01.mat');

% run_version: integer 1, 2, or 3.
%   1: Run this version first: just shows the currently selected result,
%      use this to select the rline with a good specular lead
%   2: Run this version to look at the echogram and range line results for
%      each deconvolution waveform
%   3: Quick version of 2, only summary results shown
run_version = 2;

% rline: range line to use for metrics in run_version 2 or 3
rline = 297;

% Limits for run_version 2 figure(6) A-scope plot
xlim_rng = [-70 +50];
% xlim_rng = [-40 +10];

% regions: Regions used for sidelobes metrics (units of range bins)
regions = {[-35:-16],[-16:-7]};

% ml_threshold: Main lobe threshold in dB
ml_threshold = -20;

closest_idx_list = 1:length(spec.deconv_H);
%closest_idx_list = [22]; % SOMETIMES YOU MAY WANT TO RESTRICT THE WFS TO TEST

%% Automated Section

if run_version == 1
  closest_idx_list = closest_idx;
elseif run_version == 2;
  figure(5);
  aa = axis;
elseif run_version == 3;
end

metrics = [];
ml_width = [];
peak_vals = [];

if run_version == 2
  figure(5);
  figure(6); clf;
elseif run_version == 1;
  figure(5); clf;
end

for closest_idx = closest_idx_list
  
  deconv_H = spec.deconv_H{closest_idx};
  if length(freq) ~= length(spec.freq{closest_idx}) % replace with ~isequal?
    deconv_H = spec.deconv_H{closest_idx};
    % If we ever needed to apply frequency domain interpolation... initial
    % results indicate that this does not work very well... possibly because
    % the corrections at each frequency change for different chirp parameters.
    %           deconv_H = interp1(fftshift(spec.freq(:,closest_idx)), spec.deconv_H(:,closest_idx), fftshift(freq),'linear','extrap');
    deconv_H = interp1(spec.freq{closest_idx}, spec.deconv_H{closest_idx}, freq,'linear','extrap');
    deconv_H = interp_finite(deconv_H);
  end
  % Create a mask that will apply the deconvolution only to the data
  % collected in this twtt bin.
  %mask = round(dec_records.elev(idxs)/ (c/2)/spec.twtt_bin_spacing) == twtt_bin;
  mask = logical(ones(1,size(tmp_data,2)));
  tmp_data2 = ifft(fft(tmp_data(:,mask)) .* repmat(deconv_H,[1 sum(mask)]));
  
  xx = db(fir_dec(abs(tmp_data2).^2,5),'power');
  
  if run_version == 1 || run_version == 2
    % Use this to set the rline
    figure(5); clf;
    imagesc(xx)
    title('closest_idx: %d', closest_idx)
    caxis([-31 0]);
    colormap(1-gray(256));
    if run_version == 1
      return
    else
      axis(aa);
    end
  end
  
  [peak_val,peak_idx] = max(xx(:,rline));
  
  if run_version == 2
    figure(6);
    % clf;
    plot(xx(:,rline),'g');
    xlim(peak_idx + xlim_rng)
    ylim(peak_val + [-50 3]);
    grid on;
    title(sprintf('closest_idx %d', closest_idx));
    hold on;
  else
    fprintf('closest_idx %d\n', closest_idx);
  end
  
  re = find(xx(peak_idx:-1:1,rline) < peak_val+ml_threshold,1);
  fe = find(xx(peak_idx:end,rline) < peak_val+ml_threshold,1);
  ml_width(closest_idx) = re+fe - 2;
  peak_vals(closest_idx) = peak_val;
  for region_idx = 1:length(regions)
    metrics(closest_idx,region_idx) = max(xx(peak_idx + regions{region_idx},rline));
  end
  
  if run_version == 2
    if closest_idx ~= closest_idx_list(end)
      pause;
      plot(xx(:,rline),'c');
    end
  end
  
end
% blue green red
frames = frames_load(param);
frm = find(mean(param.load.recs) >= frames.frame_idxs,1,'last');

figure(7); clf;
plot(1:size(metrics,1),metrics,'.-')
title(sprintf('%s_%03d rline %d\n', param.day_seg, frm, rline),'interpreter','none');
hold on
plot(sum(metrics,2),'k.-')
plot(ml_width,'m.-')
plot(peak_vals,'c.-')
grid on

