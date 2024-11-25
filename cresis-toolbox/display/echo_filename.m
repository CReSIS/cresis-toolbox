function [echo_fn,echo_fn_dir] = echo_filename(param,ct_filename_out_fn,frm,img)
% [echo_fn,echo_fn_dir] = echo_filename(param,ct_filename_out_fn,frm,img)
%
% Returns the standard filename for an echogram.
%
% param: parameter spreadsheet structure
%
% ct_filename_out_fn: string containing the ct_filename_out "fn" argument.
% For example "qlook", "standard", etc. Default is "qlook".
%
% frm: positive integer, default is 1
%
% img: nonnegative scalar integer, default is 0, 0 for combined file, >0
%
% OUTPUTS:
%
% echo_fn: echogram filename string
%
% echo_fn_dir: echogram filename string
%
% param = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'20140506_01');
% [echo_fn,echo_fn_dir] = echo_filename(param,'standard',1,0);
% if ~isdir(echo_fn_dir)
%   mkdir(echo_fn_dir);
% end
%
% Author: John Paden
%
% See also: echo_detrend, echo_filt, echo_mult_suppress, echo_noise,
% echo_norm, echo_param, echo_stats, echo_stats_layer, echo_xcorr,
% echo_xcorr_profile

if nargin < 1
  error('Must pass in param which is a parameter spreadsheet structure.');
end

if ~exist('ct_filename_out_fn','var')
  ct_filename_out_fn = 'qlook';
end

if ~exist('frm','var')
  frm = 1;
end

if ~exist('img','var')
  img = 0;
end

echo_fn_dir = ct_filename_out(param,ct_filename_out_fn);

if img == 0
  echo_fn = fullfile(echo_fn_dir,sprintf('Data_%s_%03d.mat',param.day_seg,frm));
else
  echo_fn = fullfile(echo_fn_dir,sprintf('Data_img_%02d_%s_%03d.mat',img,param.day_seg,frm));
end
