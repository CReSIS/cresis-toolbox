function data_rgb = hsv_plot_coherence(coherence,coherence_limits)
% data_rgb = hsv_plot_coherence(coherence,coherence_limits)
%
% Creates HSV data from complex data where:
%  hue is set to normalized angle (0 to 1 is -pi to pi)
%  sat is 1
%  val is set to coherence (magnitude of "coherence" with values 0 to 1)
% Useful for displaying interferograms/insar.
%
% coherence = 2D complex matrix
% coherence_limits = default is [min(abs(coherence(:))) max(abs(coherence(:)))].
%  This field allows the limits to be overridden (typically to [0 1]).
%
% Example:
%
% % Form interferogram
% coherence = data{1}(:,:,1) .* conj(data{1}(:,:,2)) ./ abs(data{1}(:,:,1) .* data{1}(:,:,2));
% % Plot interferogram
% imagesc(hsv_plot_coherence(coherence,[0 1]));
% colormap(hsv(256))
% h_colorbar = colorbar;
% caxis([-pi pi])
% set(get(h_colorbar,'ylabel'),'string','angle (rad)')
%
% Author: John Paden
%
% See also: hsv_plot.m, hsv_plot_coherence.m

val = abs(coherence);

if ~exist('coherence_limits','var') || isempty(coherence_limits)
  coherence_limits = [min(val(:)) max(val(:))];
end

hue = (angle(coherence)) / (2*pi) + 0.5;
sat = ones(size(coherence));
% Threshold coherence and scale range from 0 to 1
val(val<coherence_limits(1)) = coherence_limits(1);
val(val>coherence_limits(2)) = coherence_limits(2);
val = val - coherence_limits(1);
val = val / coherence_limits(2);

data_rgb = hsv2rgb(cat(3,hue,sat,val));

