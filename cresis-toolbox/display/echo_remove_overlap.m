function mdata = echo_remove_overlap(mdata)
% mdata = echo_remove_overlap(mdata)
%
% Old data files contained data from neighboring frames so that the frame
% data overlapped from frame to frame. This function removes this
% overlapped data.
%
% INPUTS:
%
% mdata: structure loaded from echogram file (e.g. CSARP_qlook or
% CSARP_standard)
%
% OUTPUTS:
%
% mdata: structure loaded from echogram file (e.g. CSARP_qlook or
% CSARP_standard) with overlapped data removed from all fields (Data,
% GPS_time, Latitude, Longitude, Elevation, Roll, Pitch, Heading, Surface,
% Bottom)
%
% Examples:
%
% fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_standard/20140512_01/Data_20140512_01_018.mat';
% mdata = load(fn);
% mdata = echo_remove_overlap(mdata);
%
% Author: John Paden
%
% See also: echo_detrend, echo_filt, echo_mult_suppress, echo_noise,
% echo_norm, echo_param, echo_stats, echo_stats_layer, echo_xcorr,
% echo_xcorr_profile

param = echo_param(mdata);

frames = frames_load(param);

% Mask data from this frame only
mask_valid = mdata.GPS_time >= frames.gps_time(param.load.frm) & mdata.GPS_time < frames.gps_time(param.load.frm+1);

mdata.GPS_time = mdata.GPS_time(mask_valid);
mdata.Latitude = mdata.Latitude(mask_valid);
mdata.Longitude = mdata.Longitude(mask_valid);
mdata.Elevation = mdata.Elevation(mask_valid);
mdata.Roll = mdata.Roll(mask_valid);
mdata.Pitch = mdata.Pitch(mask_valid);
mdata.Heading = mdata.Heading(mask_valid);

mdata.Data = mdata.Data(:,mask_valid);

if isfield(mdata,'Surface')
  mdata.Surface = mdata.Surface(mask_valid);
end

if isfield(mdata,'Bottom')
  mdata.Bottom = mdata.Bottom(mask_valid);
end
