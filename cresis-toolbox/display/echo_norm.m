function data = echo_norm(mdata, param)
% data = echo_norm(mdata, param)
%
% The trend of the data is estimated using various methods and this trend
% is removed from the data.
%
% INPUTS:
%
% mdata: 2D input data matrix (log power) or echogram file structure
%
% param: struct controlling how the normalization is done
%
% OUTPUTS:
%
% data: normalized input (log power normalized)
%
% Examples:
%
% fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_standard/20140512_01/Data_20140512_01_018.mat';
% mdata = load(fn); mdata.Data = 10*log10(mdata.Data);
%
% imagesc(echo_norm(mdata)); colorbar; caxis([0 1]);
%
% imagesc(echo_norm(mdata,struct('scale',[25 255]))); colorbar; caxis([0 255]);
%
% Author: John Paden
%
% See also: echo_detrend, echo_filt, echo_mult_suppress, echo_noise,
% echo_norm, echo_param, echo_stats, echo_stats_layer, echo_xcorr,
% echo_xcorr_profile

if isstruct(mdata)
  data = mdata.Data;
else
  data = mdata;
end

if ~exist('param','var') || isempty(param)
  param = [];
end

% valid_max_range_dB: 2 element numeric vector; specifies the valid range
% for the max value; default is [-inf inf]. Use [-inf inf] to effectively
% disable this valid max value range constraint;
if ~isfield(param,'valid_max_range_dB') || isempty(param.valid_max_range_dB)
  param.valid_max_range_dB = [-inf inf];
end

if ~isfield(param,'scale') || isempty(param.scale)
  param.scale = [0.1 0.9];
end


% Estimate the noise
if isstruct(mdata)
  mdata.Data = 10.^(mdata.Data/10);
  noise = echo_noise(mdata, param);
  noise = 10*log10(mean(noise(isfinite(noise))));
else
  noise = echo_noise(10.^(mdata/10), param);
  noise = 10*log10(mean(noise(isfinite(noise))));
end

% Determine max of data
max_scalar = min(noise+param.valid_max_range_dB(2), ...
  max(noise+param.valid_max_range_dB(1), ...
  max(data(:))));

% Scale and offset data
data = param.scale(1) + (data-noise) / (max_scalar - noise) * (param.scale(2)-param.scale(1));
