function [data] = nan_fir_dec(data, Bfilter, dec_factor, start_idx, Nidxs, renormalize_en, phase_weights, nan_normalize_threshold)
% [data] = nan_fir_dec(data, Bfilter, dec_factor, start_idx, Nidxs, renormalize_en, phase_weights, nan_normalize_threshold)
%
% See fir_dec for description. This function using nansum when doing sum.
% Also the nan_normalize_threshold parameter can be used to exclude pixels
% that only have partial support.
%
% nan_normalize_threshold: Scalar. Default is inf. The threshold is the
%   amount the nansum has to be normalized (increased) to make up for
%   missing NaN values in the data. Common values:
%   inf: output pixels are good as long as they have any ~isnan support
%   <1: output pixels are good only if they have no isnan support
%   2: output pixels are good as long as the have over 50% ~isnan support
%
% Authors: John Paden
%
% See also: decimate, resample, downsample

if nargin == 2 && length(Bfilter) == 1
  coh_avgs = Bfilter;
  if coh_avgs >= 1
    siz = size(data);
    if siz(1) == 1
      new_len     = floor(siz(2)/coh_avgs);
      nearest_len = floor(siz(2)/coh_avgs)*coh_avgs;
      data        = nanmean(reshape(data(1:nearest_len),coh_avgs,new_len),1);
    elseif siz(2) == 1
      new_len     = floor(siz(1)/coh_avgs);
      nearest_len = floor(siz(1)/coh_avgs)*coh_avgs;
      data        = nanmean(reshape(data(1:nearest_len),coh_avgs,new_len),1).';
    else
      new_len     = floor(siz(2)/coh_avgs);
      nearest_len = floor(siz(2)/coh_avgs)*coh_avgs;
      data        = reshape(nanmean(reshape(data(:,1:nearest_len), ...
        [siz(1) coh_avgs new_len]),2),[siz(1) new_len]);
    end
  end
  
else
  if ~exist('start_idx','var') || isempty(start_idx)
    start_idx = 1;
  end
  if ~exist('dec_factor','var') || isempty(dec_factor)
    dec_factor = 1;
  end
  
  Nidxs_max = ceil((size(data,2) - start_idx + 1) / dec_factor);
  if ~exist('Nidxs','var') || isempty(Nidxs) || Nidxs > Nidxs_max
    Nidxs = Nidxs_max;
  end
  
  if ~exist('renormalize_en','var') || isempty(renormalize_en)
    renormalize_en = true;
  end
    
  if ~exist('phase_weights','var') || isempty(phase_weights)
    phase_weights = [];
  end
    
  if ~exist('nan_normalize_threshold','var') || isempty(nan_normalize_threshold)
    nan_normalize_threshold = inf;
  end
  
  if size(Bfilter,1) ~= 1
    error('Bfilter must be a row vector');
  end
  
  filter_order = (length(Bfilter) - 1);
  
  if mod(filter_order,2)
    error('Only even filter orders allowed (Bfilter should be odd length)');
  end
    
  if size(data,2) == 1
    data = data.';
  end
  
  out_data = zeros(size(data,1), Nidxs, class(data));
  
  for out_idx = 1:Nidxs
    renormalize = false;
    
    idx_rng(1) = start_idx + (out_idx-1)*dec_factor - filter_order/2;
    if idx_rng(1) < 1
      filter_rng(1) = 2 - idx_rng(1);
      idx_rng(1) = 1;
      renormalize = true;
    else
      filter_rng(1) = 1;
    end
    
    idx_rng(2) = start_idx + (out_idx-1)*dec_factor + filter_order/2;
    if idx_rng(2) > size(data,2)
      filter_rng(2) = size(Bfilter,2) - (idx_rng(2) - size(data,2));
      idx_rng(2) = size(data,2);
      renormalize = true;
    else
      filter_rng(2) = size(Bfilter,2);
    end
    
    if ~renormalize
      if isempty(phase_weights)
        out_data(:,out_idx) = nansum(bsxfun(@times, data(:,idx_rng(1):idx_rng(2)), Bfilter),2);
      else
        dphase = phase_weights(idx_rng(1):idx_rng(2));
        dphase = conj(dphase./exp(1i * angle(mean(dphase))));
        out_data(:,out_idx) = nansum(bsxfun(@times, data(:,idx_rng(1):idx_rng(2)), Bfilter.*dphase),2);
      end
      nan_normalize = sum(Bfilter,2) ./ sum(bsxfun(@times,Bfilter,~isnan(data(:,idx_rng(1):idx_rng(2)))),2);
      nan_normalize(~isfinite(nan_normalize) | nan_normalize>nan_normalize_threshold) = NaN;
      out_data(:,out_idx) = out_data(:,out_idx) .* nan_normalize;
    else
      Bfilter_tmp = Bfilter(filter_rng(1):filter_rng(2));
      if isempty(phase_weights)
        out_data(:,out_idx) = nansum(bsxfun(@times, data(:,idx_rng(1):idx_rng(2)), ...
          Bfilter_tmp), 2);
      else
        dphase = phase_weights(idx_rng(1):idx_rng(2));
        dphase = conj(dphase./exp(1i * angle(mean(dphase))));
        out_data(:,out_idx) = nansum(bsxfun(@times, data(:,idx_rng(1):idx_rng(2)), ...
          Bfilter_tmp.*dphase), 2);
      end
      nan_normalize = sum(Bfilter_tmp,2) ./ sum(bsxfun(@times,Bfilter_tmp,~isnan(data(:,idx_rng(1):idx_rng(2)))),2);
      nan_normalize(~isfinite(nan_normalize) | nan_normalize>nan_normalize_threshold) = NaN;
      out_data(:,out_idx) = out_data(:,out_idx) .* nan_normalize;
      
      if renormalize_en
        renormalization_factor ...
          = sum(Bfilter(1,:)) / sum(Bfilter(1,filter_rng(1):filter_rng(2)));
        out_data(:,out_idx) = out_data(:,out_idx) * renormalization_factor;
      end
    end
  end

  data = out_data;
end

return;

