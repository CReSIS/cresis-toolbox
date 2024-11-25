function data = echo_filt(data, filt_len)
% data = echo_filt(data, filt_len)
%
% Along-track and cross-track multilook filtering.
%
% INPUTS:
%
% data: linear power echogram or a struct with a field "Data" with a linear
% power echogram in it
%
% filt_len: optional parameter, default is 5, should be a one or two
% element vector containing positive odd integers (1, 3, 5, ...)
%   numel(filt_len)==1 means that along-track filtering will be applied
%     with a boxcar filter equal in length to filt_len(1).
%   numel(filt_len)==2 means that along-track filtering will be applied
%     with a boxcar filter equal in length to filt_len(2) and cross-track
%     filtering will be applied with a boxcar filter equal in length to
%     filt_len(1).
%
% OUTPUTS:
% data: input data after filtering, will be the same size
%
% Example:
%
% fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_standard/20140512_01/Data_20140512_01_018.mat';
% mdata = load(fn);
%
% imagesc(lp(echo_filt(mdata))); % Default 1x5 filter
% imagesc(lp(echo_filt(mdata,11))); % 1x11 filter
% imagesc(lp(echo_filt(mdata,[3 5]))); % 3x5 filter
%
% imagesc(lp(echo_filt(mdata.Data,[3 5]))); % 3x5 filter, called with data matrix
%
% Author: John Paden
%
% See also: echo_detrend, echo_filt, echo_mult_suppress, echo_noise,
% echo_norm, echo_param, echo_stats, echo_stats_layer, echo_xcorr,
% echo_xcorr_profile

if isstruct(data)
  if isfield(data,'Data')
    data = data.Data;
  else
    error('Is data is a struct, then it must contain a field Data with the echogram image.');
  end
end

if ~exist('filt_len','var') || isempty(filt_len)
  filt_len = 5;
end

if numel(filt_len) == 1
  filt_len = [1 filt_len];
end

% Ensure positive odd integer filter lengths
filt_len = 1+2*round((filt_len-1)/2);
filt_len = max(1,filt_len);

% Filter along first dimension (fast-time)
if filt_len(1) ~= 1 
  data = nan_fir_dec(data.',ones(1,filt_len(1))/filt_len(1),1,[],[],[],[],2.0).';

end
% Filter along second dimension (slow-time)
if filt_len(2) ~= 1 
  data = nan_fir_dec(data,ones(1,filt_len(2))/filt_len(2),1,[],[],[],[],2.0);
end
