function data = echo_xcorr(data, param)
% data = echo_xcorr(data, param)
%
% Fast-time cross correlation.
%
% INPUTS:
%
% data = 2D input data matrix (log power)
%
% param: struct controlling how the cross correlation is done
%
% OUTPUTS:
%
% data: detrended input (log power)
%
% Examples:
%
% fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_standard/20140512_01/Data_20140512_01_018.mat';
% mdata = load(fn); mdata.Data = 10*log10(mdata.Data);
%
% imagesc(echo_xcorr(mdata));
%
% imagesc(echo_xcorr(mdata,echo_xcorr_profile('peaky')));
%
% imagesc(echo_xcorr(mdata,echo_xcorr_profile('snow')));
%
% imagesc(echo_xcorr(mdata,echo_xcorr_profile('short_unitstep')));
%
% imagesc(echo_xcorr(mdata,echo_xcorr_profile('long_unitstep')));
%
% Author: John Paden
%
% See also: echo_detrend, echo_filt, echo_mult_suppress, echo_noise,
% echo_norm, echo_param, echo_stats, echo_stats_layer, echo_xcorr,
% echo_xcorr_profile

%% Input checks

if isstruct(data)
  data = data.Data;
else
  data = data;
end

if ~exist('param','var') || isempty(param)
  param = [];
end

% h_filt: vector of cross-correlation filter coefficients applied using
% filter.m
if ~isfield(param,'h_filt') || isempty(param.h_filt)
  param.h_filt = fliplr([0.1*ones(1,6) 0.5*ones(1,7)]);
end
param.h_filt = param.h_filt-mean(param.h_filt);

% h_filt_offset: integer scalar which indicates the delay compensation
% needed to remove the filter.m delay from h_filt. I.e. this is the delay
% offset in bins to apply after h_filt in order to align the filtered image
% with the desired peak location
if ~isfield(param,'h_filt_offset') || isempty(param.h_filt_offset)
  param.h_filt_offset = -4;
end

%% Fast-time correlation in log domain
data = filter(param.h_filt,1,data);
data = circshift(data,[param.h_filt_offset 0]);
data(1:length(param.h_filt),:) = NaN;
data(end-length(param.h_filt)+1:end,:) = NaN;
