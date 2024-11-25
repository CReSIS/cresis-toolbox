function bad_samples = burst_noise_bad_samples(data_signal,data_noise,test_metric,wfs)
% bad_samples = burst_noise_bad_samples(data_signal,data_noise,test_metric,wfs)
%
% Burst noise bad samples function example for UTIG 2023/01/20 flight
%
% To be used with analysis.m "burst_noise" command as in:
% params.analysis.cmd{1}.threshold_fh{1} = @burst_noise_bad_samples;

bad_samples = false(size(test_metric));
tt = test_metric > 25;

%% ESTIMATE TIME DELAY AND PHASE FROM OVERSAMPLED PEAK
peak_idxs = find(tt);
if isempty(peak_idxs)
  return;
end
% h_plot = plot(h_axes,NaN,NaN,'x','linewidth',4,'markersize',15);
idx = 1;
while ~isempty(idx)
  start_idx = peak_idxs(idx);
%   x = floor((start_idx-1)/size(tt,1))+1;
%   y = start_idx-(x-1)*size(tt,1);
%   set(h_plot,'xdata',x,'ydata',y);
  zero_idxs = 0;
  stop_idx = start_idx;
  while zero_idxs < 14 && stop_idx < numel(tt)
    stop_idx = stop_idx + 1;
    if tt(stop_idx) == 0
      zero_idxs = zero_idxs + 1;
    end
  end
  % REMOVE the signal (either by zero samples or subtraction)
  % Zero out peak
  bad_samples(start_idx:stop_idx) = true;
%   set(h_image,'cdata',lp(ff));
  % Skip peak idxs associate with this peak
  idx = find(peak_idxs > stop_idx,1);
end
