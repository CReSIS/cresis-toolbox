% script echogram_to_jpeg
%
% Converts specified echogram image .mat files into small 8-bit jpegs after
% truncation and decimation.
%
% Example to load datafiles:
% 
% mdata_orig = load('/cresis/snfs1/dataproducts/public/data/accum/2018_Antarctica_TObas/CSARP_standard/20190205_01/Data_20190205_01_010.mat');
% mdata = load('/cresis/snfs1/dataproducts/public/data/accum/2018_Antarctica_TObas/CSARP_small_mat/20190205_01/Data_20190205_01_010.mat');
% mdata.Data = imread('/cresis/snfs1/dataproducts/public/data/accum/2018_Antarctica_TObas/CSARP_small_jpg/20190205_01/Data_20190205_01_010.jpg');
% mdata.Data = single(mdata.Data)/255*mdata.Data_Scale + mdata.Data_Offset;
% 
% figure(1); clf;
% imagesc(mdata.Data);
% colormap(1-gray(256));
% hold on;
% plot(mdata.Surface);
% plot(mdata.Bottom);
% 
% figure(2); clf;
% plot(mdata_orig.Time, 10*log10(mdata_orig.Data(:,1)));
% hold on;
% plot(mdata.Time, mdata.Data(:,1));
%
% Author: John Paden
%
% See also: run_post.m, post.m, run_echogram_to_jpeg.m,
%  echogram_to_jpeg.m

%% User Setup
% =====================================================================

param_override = [];

params = read_param_xls(ct_filename_param('accum_param_2018_Antarctica_TObas.xls'));

params = ct_set_params(params,'cmd.generic',1);
params = ct_set_params(params,'cmd.generic',0,'cmd.notes','do not process');

% params = ct_set_params(params,'cmd.generic',0);
% params = ct_set_params(params,'cmd.generic',1,'day_seg','20190205_01');
% params = ct_set_params(params,'cmd.frms',10);

% Input images
param_override.echogram_to_jpeg.data_type = 'CSARP_post/standard';

% Input top/bottom layers
param_override.echogram_to_jpeg.layers = [struct('name', 'surface', 'source', 'layerdata', 'layerdata_source', 'CSARP_post/layerData', 'existence_check', false) ...
  struct('name', 'bottom', 'source', 'layerdata', 'layerdata_source', 'CSARP_post/layerData', 'existence_check', false)];

% Output path
param_override.echogram_to_jpeg.mat_out_path = 'CSARP_post/small_mat';
param_override.echogram_to_jpeg.jpeg_out_path = 'CSARP_post/small_jpg';

% Truncation parameters
param_override.echogram_to_jpeg.N_before_surface = 50;
param_override.echogram_to_jpeg.N_after_surface = 1500;
param_override.echogram_to_jpeg.N_after_bottom = 100;

% Decimation parameters
param_override.echogram_to_jpeg.decimate_fasttime = 2;
param_override.echogram_to_jpeg.decimate_slowtime = 3;

%% Automated Section
% =====================================================================

% Input checking
global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

%% Process each of the segments
% =====================================================================
for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  %echogram_to_jpeg(param,param_override);
  echogram_to_jpeg
end
