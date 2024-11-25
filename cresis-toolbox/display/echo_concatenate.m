function cat_data = echo_concatenate(cat_data, data)
% cat_data = echo_concatenate(cat_data, data)
%
% Concatenates echogram structures together.
%
% INPUTS:
%
% cat_data: concatenated data structure (empty if no data concatenated yet)
%
% data: a struct with a field "Data" with a linear
%
% OUTPUTS:
% cat_data: cat_data with data concatenated to the end
%
% Example:
%
% param = read_param_xls(ct_filename_param('snow_param_2016_Greenland_P3.xls'),'20160519_01');
% mdata = echo_load(param,'CSARP_post/qlook',1);
% mdata = echo_concatenate(mdata,echo_load(param,'CSARP_post/qlook',2));
%
% Author: John Paden
%
% See also: echo_detrend, echo_filt, echo_mult_suppress, echo_noise,
% echo_norm, echo_param, echo_stats, echo_stats_layer, echo_xcorr,
% echo_xcorr_profile

if ischar(data)
  % data should be a filename to load
  data = load_L1B(data);
end

if isempty(cat_data)
  cat_data = data;
  return;
end

% Concatenate the metadata
good_mask = data.GPS_time > cat_data.GPS_time(end);
Nx = sum(good_mask);
cat_data.Elevation(end+(1:Nx)) = data.Elevation(good_mask);
cat_data.GPS_time(end+(1:Nx)) = data.GPS_time(good_mask);
cat_data.Heading(end+(1:Nx)) = data.Heading(good_mask);
cat_data.Latitude(end+(1:Nx)) = data.Latitude(good_mask);
cat_data.Longitude(end+(1:Nx)) = data.Longitude(good_mask);
cat_data.Pitch(end+(1:Nx)) = data.Pitch(good_mask);
cat_data.Roll(end+(1:Nx)) = data.Roll(good_mask);
cat_data.Surface(end+(1:Nx)) = data.Surface(good_mask);

% Expand original "cat_data" time axis to accomodate earlier and later times
% that are only available in "data".
dt = cat_data.Time(2)-cat_data.Time(1);
Npre = floor((cat_data.Time(1) - data.Time(1))/dt);
if Npre > 0
  cat_data.Time = [cat_data.Time(1)+dt*(-Npre:-1).'; cat_data.Time];
  cat_data.Data = [nan(Npre,size(cat_data.Data,2)); cat_data.Data];
end
Npost = floor((data.Time(end) - cat_data.Time(end))/dt);
if Npost > 0
  cat_data.Time = [cat_data.Time; cat_data.Time(end)+dt*(1:Npost).'];
  cat_data.Data = [cat_data.Data; nan(Npost,size(cat_data.Data,2))];
end

% Concatenate the data (interpolate the new data to the old time axis and
% only concatenate new data)
cat_data.Data = [cat_data.Data, interp1(data.Time,data.Data(:,good_mask),cat_data.Time)];

try
  cat_param_str = echo_param(cat_data,1);
  param_str = echo_param(data,1);

  cat_data.(cat_param_str).load.frm ...
    = unique([cat_data.(cat_param_str).load.frm data.(param_str).load.frm]);
end
