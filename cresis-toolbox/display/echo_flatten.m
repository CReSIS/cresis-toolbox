function [data,resample_field] = echo_flatten(mdata,resample_field,inverse_flag,interp_method,ref_col,trim_nan_en)
% [data,resample_field] = echo_flatten(mdata,resample_field,inverse_flag,interp_method,ref_col,trim_nan_en)
%
% Shifts columns up/down in echogram using interpolation in order to
% flatten one or more 1D layers in the data or to flatten a 2D slope field.
% Defaults to flattening the surface stored in CSARP_layer if no
% resample_field given.
%
% There are two interpolations done by echo_flatten: the first ons is to
% interpolate to find the shift at each point in the data matrix. The
% second interpolation is used to apply the shift to the data and linear or
% Fourier based interpolation may be used.
%
% For layers provided by the user, interp_finite is used to fill in any
% gaps.
%
% For the shift field, spline is use on the interior points and linear
% exterpolation is used.
%
% Since interpolation is used for the shifts, oversampling (e.g. 2x) in the
% fast-time domain is recommended for best results when the shifts are
% non-integer.
%
% The shift can also be inverted so that a flattened echogram can be
% unflattened.
%
% The reference column is used as the reference that all shifts are made
% relative to and is left unchanged except for padding at the start or end.
% The reference column defaults to column 1, but the reference column may
% be specified.
%
% To compensate for aircraft elevation, just pass in a custom resample_field
% similar to opsCopyLayers and set the twtt = elev*c/2.
%
% INPUTS:
%
% mdata: echogram structure from an echogram file (e.g. returned from
% echo_load) or a data matrix. If a data matrix, then resample_field must
% be a numeric matrix.
%
% resample_field: input resample field information; several types are
% supported:
%
%  opsLoadLayers struct array or empty matrix: an array of opsLoadLayers to
%  layers that will be flattened. When an empty matrix, default layer is
%  "surface".
%
%  string: slope field file path (ct_filename_out will be used to determine
%  filepath) Should have a 'resample_field' field containing layer_bins to
%  flatten. If an empty string, then set to "slope" for CSARP_slope.
% 
%  numeric array: double, assumed to be layer_bins (one indexed so valid
%  range is from 1 to Nt)
%
% interp_method: string containing 'circular_convolution', 'linear' or
% 'sinc'. The default is 'linear'. sinc is not recommended unless
% the data are Nyquist sampled. Note that power detection doubles the
% required sampling rate; for example 30 MHz data must be sampled at 60 MHz
% before power detection occurs.
%
% inverse_flag: logical scalar, default is false. If true, the shift will be
% inverted (undoes the flattening operation).
%
% ref_col: scalar positive integer indicating the column to use as a
% reference
%
% trim_nan: logical scalar. Default is true. Removes NaN at the start and
% end of the record.
%
% OUTPUTS:
%
% data: flattened data matrix
%
% resample_field: resampling matrix that was used (can be used to undo the
% resampling using the inverse_flag and to interpret layers in the
% flattened domain)
%
% Examples:
%
% param = read_param_xls(ct_filename_param('snow_param_2012_Greenland_P3.xls'),'20120330_04');
% mdata = echo_load(param,'CSARP_post/qlook',3);
%
% figure(1); clf; imagesc(lp(mdata.Data));
% [mdata.Data,resample_field] = echo_flatten(mdata); % Flatten to surface in layerdata-CSARP_layer-surface
% figure(2); clf; imagesc(lp(mdata.Data));
% mdata.Data = echo_flatten(mdata,[],true); % Unflatten
% figure(3); clf; imagesc(lp(mdata.Data));
% 
% physical_constants; mdata = echo_flatten(mdata, interp1(mdata.Time,...
%   1:length(mdata.Time), mdata.Elevation*c/2)); % Flatten elevation
% mdata = echo_flatten(mdata, 'slope'); % Flatten to slope-field in CSARP_slope
%
% % Load "layer_param" with a list of opsLoadLayers layer_param structures
% mdata = echo_flatten(mdata, resample_field); % Flatten to surface in layerdata-CSARP_layer-surface
%
% Author: John Paden, Reece Mathews
%
% See also: echo_detrend, echo_filt, echo_mult_suppress, echo_noise,
% echo_norm, echo_param, echo_stats, echo_stats_layer, echo_xcorr,
% echo_xcorr_profile

%% Input checks

if ~exist('resample_field','var')
  resample_field = [];
end
if isempty(resample_field)
  if ischar(resample_field)
    % slope file path
    resample_field = 'slope';
  else
    % opsLoadLayers structure
    resample_field.name = 'surface';
  end
end

if ~exist('interp_method','var') || isempty(interp_method)
  interp_method = 'linear';
end

if ~exist('inverse_flag','var') || isempty(inverse_flag)
  inverse_flag = false;
end

if ~exist('ref_col','var') || isempty(ref_col)
  ref_col = 1;
end

if ~exist('trim_nan_en','var') || isempty(trim_nan_en)
  trim_nan_en = true;
end

if isnumeric(mdata)
  mdata = struct('Data',mdata);
else
  param = echo_param(mdata);
end

Nx = size(mdata.Data, 2);

%% Load resample_field
if isstruct(resample_field)
  %% Load resample_field: opsLoadLayers layer_params
  
  % Check inputs
  if ~isfield(mdata,'Time')
    error('When opsLoadLayers resample_field are passed in, mdata.Time must be defined.');
  end
  if ~isfield(mdata,'GPS_time')
    error('When opsLoadLayers resample_field are passed in, mdata.GPS_time must be defined.');
  end
  
  % Load layers
  ops_param = param;
  ops_param.cmd.frms = [param.load.frm(1)-1 : param.load.frm(end)+1];
  layers = opsLoadLayers(ops_param, resample_field);
  
  % Interpolate layers onto mdata.GPS_time and convert from twtt to
  % range-bins (rows)
  resample_field = nan(length(layers), Nx);
  for lay_idx = length(layers)
    resample_field(lay_idx,:) = interp1(mdata.Time, 1:length(mdata.Time), ...
      interp_finite(interp1(layers(lay_idx).gps_time, layers(lay_idx).twtt, mdata.GPS_time),0),'linear','extrap');
  end
  
elseif isnumeric(resample_field)
  %% Load resample_field: passed in directly
  % Passed layer in units of range-bins (rows)
  
elseif ischar(resample_field)
  %% Load resample_field: along-track slope file
  
  % Check inputs
  if ~isfield(mdata,'Time')
    error('When opsLoadLayers resample_field are passed in, mdata.Time must be defined.');
  end
  dt = mdata.Time(2)-mdata.Time(1);
  if ~isfield(mdata,'GPS_time')
    error('When opsLoadLayers resample_field are passed in, mdata.GPS_time must be defined.');
  end
  
  % Interpolate layers onto mdata.GPS_time
  frms = [param.load.frm(1)-1 param.load.frm param.load.frm(end)+1];
  for frm_idx = 1:length(frms)
    frm = frms(frm_idx);
    slope_fn = fullfile(ct_filename_out(param,'',resample_field), ...
      sprintf('slope_%s_%03d.mat', param.day_seg, frm));
    if frm_idx == 1
      load(slope_fn, 'gps_time', 'resample_field');
    else
      error('Combining slope field files across frames not supported since overlap is required to do the interpolation properly.');
      tmp = load(slope_fn, 'gps_time', 'resample_field');
      gps_time = [gps_time tmp.gps_time];
      resample_field = [resample_field tmp.resample_field];
    end
  end
  resample_field = interp_finite(interp1(gps_time, resample_field.', mdata.GPS_time)).'/dt;
  
else
  error('resample_field must be a struct or numeric matrix.');
end

%% Interpolate resample_field

% Find relative shifts to the reference (fixed, master) column
ref_axis = resample_field(:,ref_col);
resample_field = bsxfun(@minus,resample_field,ref_axis);
Nt = size(mdata.Data,1);
Nt_resample_init = size(resample_field,1);

if inverse_flag
  resample_axis = (1-round(max(-resample_field(:))) : Nt - round(min(-resample_field(:)))).';
else
  resample_axis = (1-round(max(resample_field(:))) : Nt - round(min(resample_field(:)))).';
end
Nt_resample = length(resample_axis);

for col = 1:Nx
  if Nt_resample_init == 1
    resample_field(1:Nt_resample,col) = resample_field(1,col);
  else
    resample_field(1:Nt_resample,col) = interp1(resample_axis,(1:Nt_resample_init).',resample_field(1:Nt_resample_init,col),'spline');
  end
end
if inverse_flag
  resample_field = bsxfun(@plus,-interp_finite(resample_field,0),resample_axis);
else
  resample_field = bsxfun(@plus,interp_finite(resample_field,0),resample_axis);
end

%% Interpolate mdata.Data

if strcmpi(interp_method,'linear')
  data = zeros(Nt_resample,Nx);
  for col = 1:Nx
    data(:, col) = interp1(1:Nt, mdata.Data(1:Nt, col), resample_field(:,col), 'linear');
  end
elseif strcmpi(interp_method,'sinc')
  error('interp_method = sinc not supported.');
else
  error('resample_field must be a struct or numeric matrix.');
end

%% Trim NaN from start/end of record

if trim_nan_en
  start_bin = nan(1,Nx);
  stop_bin = nan(1,Nx);
  for rline = 1:Nx
    start_bin_tmp = find(~isnan(data(:,rline)),1);
    if ~isempty(start_bin_tmp)
      start_bin(rline) = start_bin_tmp;
    end
    stop_bin_tmp = find(~isnan(data(:,rline)),1,'last');
    if ~isempty(stop_bin_tmp)
      stop_bin(rline) = stop_bin_tmp;
    end
  end
  start_bin = min(start_bin);
  stop_bin = max(stop_bin);
  data = data(start_bin:stop_bin,:);
  resample_field = resample_field(start_bin:stop_bin,:);
end
