function [mdata,echo_fn] = echo_load(param,echogram_source,frms,img)
% [mdata,echo_fn] = echo_load(param,echogram_source,frms,img)
%
% The trend of the data is estimated using various methods and this trend
% is removed from the data.
%
% INPUTS:
%
% param: radar parameter spreadsheet structure
%
% echogram_source: 'standard'
%
% frms: List of frames to load, default is
%
% img: Scalar nonnegative integer indicating which image to load. Default
% is zero and loads the combined file Data_YYYYMMDD_SS_FFF.mat. Positive
% integers II load the file Data_img_II_YYYYMMDD_SS_FFF.mat
%
% OUTPUTS:
%
% mdata: echogram structure
% echo_fn: string containing the filename loaded
%
% Examples:
%
% param = read_param_xls(ct_filename_param('rds_param_2019_Antarctica_Ground.xls'),'20200107_01');
% mdata = echo_load(param,'standard',1);
% mdata = echo_load(param,'standard',1:3);
%
% param = read_param_xls(ct_filename_param('snow_param_2016_Greenland_P3.xls'),'20160519_01');
% mdata = echo_load(param,'CSARP_post/qlook',1:4);
%
% Author: John Paden
%
% See also: echo_detrend, echo_filt, echo_mult_suppress, echo_noise,
% echo_norm, echo_param, echo_stats, echo_stats_layer, echo_xcorr,
% echo_xcorr_profile

if ischar(param)
  % param is a filename (second and third arguments are ignored)
  echo_fn = param;
  mdata = load_L1B(echo_fn);
  return;
  
elseif isstruct(param)
  % param is a parameter spreadsheet structure
  if length(param) > 1
    error('echo_load:param','A parameter structure array with more than one element was passed in. length(param) must be 1.');
  end
  
  % Override default echogram source if second argument defined
  if ~exist('echogram_source','var') || isempty(echogram_source)
    echogram_source = 'standard';
  end
  
  % Override default img if third argument defined
  if ~exist('img','var') || isempty(img)
    % img == 0 is combined
    img = 0;
  end
  
  % Override frames field if third argument defined
  if ~exist('frms','var') && ~isempty(frms)
    frms = 1;
  end
  
  for frm_idx = 1:length(frms)
    if img == 0
      % Combined file
      echo_fn{frm_idx} = fullfile(ct_filename_out(param,echogram_source),sprintf('Data_%s_%03d.mat',param.day_seg,frms(frm_idx)));
    else
      % Image "_img_II" file
      echo_fn{frm_idx} = fullfile(ct_filename_out(param,echogram_source),sprintf('Data_img_%02d_%s_%03d.mat',img, param.day_seg,frms(frm_idx)));
    end
  end
  
elseif iscell(param)
  % param is a cell array of filenames (second and third arguments are ignored)
  echo_fn = param;
  
else
  error('Invalid type for param.');
  
end

mdata = [];
for frm_idx = 1:length(echo_fn)
  mdata = echo_concatenate(mdata, echo_fn{frm_idx});
end
