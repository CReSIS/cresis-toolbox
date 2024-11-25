function data_rgb = hsv_plot(data,val_limits)
% data_rgb = hsv_plot(data,val_limits)
%
% Creates HSV data from complex data where:
%  hue is set to normalized angle (0 to 1 is -pi to pi)
%  sat is 1
%  val is set to normalized log power
% Useful for displaying interferograms/insar.
%
% data = 2D complex matrix
% val_limits = val will be clipped to this log value (default is the minimum
%   value of the data). This is important to use when the smallest log value 
%   of your data is really small and messes up the dynamic range.
%   Typical setting would be at your average noise power (in dB).
%
% Example:
%
% % Form interferogram (couple options)
% complex_data = mean(data{1}(:,:,3:4),3) .* conj(mean(data{1}(:,:,5:6),3));
% complex_data = data{1}(:,:,1) .* conj(data{1}(:,:,2))
% % Plot interferogram
% imagesc(hsv_plot(complex_data,-70));
% colormap(hsv(256))
% h_colorbar = colorbar;
% caxis([-pi pi])
% set(get(h_colorbar,'ylabel'),'string','angle (rad)')
%
% Author: John Paden
%
% See also: hsv_plot.m, hsv_plot_coherence.m

if exist('val_limits','var')
  if length(val_limits) == 1
    val_limits(2) = inf;
  end
else
  val_limits(1) = -inf;
  val_limits(2) = inf;
end

hue = (angle(data)) / (2*pi) + 0.5;
sat = ones(size(data));
val = lp(abs(data) / max(abs(data(:))));
if isfinite(val_limits(1))
  val(val<val_limits(1)) = val_limits(1);
end
if isfinite(val_limits(2))
  val(val>val_limits(2)) = val_limits(2);
end
val = val - min(val(:));
val = val / max(val(:));

data_rgb = hsv2rgb(cat(3,hue,sat,val));

return;
