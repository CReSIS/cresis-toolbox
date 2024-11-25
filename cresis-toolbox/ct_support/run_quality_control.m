% script run_quality_control
%
% Script for running "quality_control.m"
%
% Author: John Paden
%
% See also: quality_control.m, run_quality_control.m

clear param;

if 0
  param.radar_name = 'rds';
  
  param.day_seg = '20140514_01';
  
  param.season_name = '2014_Greenland_P3';
  param.image_out_dir = {
    {ct_filename_out(rmfield(param,'day_seg'),'','post/images',1)}};
  param.mat_out_dir = {{'/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_post/CSARP_standard'}};
  param.mat_out_img = {0};
  
  param.img_type = 'echo.jpg';
  
  % RDS image debugging mode (for snow, kuband radars)
  fmcw_img_debug_mode = false;
  noise_time_buffer = 250e-9;
  noise_time_duration = 45e-9;
  img_sidelobe = -40;
  noise_threshold_offset_dB = 5.2;
  
elseif 1
  param.radar_name = 'snow';
  
  param.day_seg = '20170407_02';
  
  param.season_name = '2017_Greenland_P3';
  param.image_out_dir = {{ct_filename_out(rmfield(param,'day_seg'),'','post/images',1)},
    {ct_filename_out(rmfield(param,'day_seg'),'','post_uwb/images',1)},
    {ct_filename_out(rmfield(param,'day_seg'),'','post_deconv/images',1)},
    {ct_filename_out(rmfield(param,'day_seg'),'','post_kuband/images',1)}};
  param.mat_out_dir = {{'/N/dcwan/projects/cresis/output/snow/2017_Greenland_P3/CSARP_qlook'},
    {'/N/dcwan/projects/cresis/output/snow/2017_Greenland_P3/CSARP_qlook_uwb'},
    {'/N/dcwan/projects/cresis/output/snow/2017_Greenland_P3/CSARP_deconv'},
    {'/N/dcwan/projects/cresis/output/snow/2017_Greenland_P3/CSARP_qlook_kuband'}};
  param.mat_out_img = {0,0,0,0};
  
  param.img_type = 'echo.jpg';
  
  % FMCW image debugging mode (for snow, kuband radars)
  fmcw_img_debug_mode = true;
  noise_time_buffer = 250e-9;
  noise_time_duration = 45e-9;
  img_sidelobe = -40;
  noise_threshold_offset_dB = 5.2;
end

% update_field: string containing the field in frames file to update.
% Currently there are two options:
%               ('proc_mode', 'quality')
if 0
  update_field = 'proc_mode'; update_field_type = 'double';
else
  update_field = 'quality'; update_field_type = 'mask';
  update_field_mask = {'turn all masks off','coherent noise','deconvolution artifact', ...
    'raised noise floor/vertical stripes','missing data','no good data','low SNR','unclassified','land or iceberg'};
  % 8-bit mask:
  %
  % 1: coherent noise -- horizontal lines in "i" view which plots against
  % two way travel. In the posted image view which uses WGS-84, coherent
  % noise is not horizontal but can be distinguished by parallel lines. If
  % unusual line present, switch to "i" view that plots against two way
  % travel time to verify this as coherent noise. Mark this bit even if a
  % part of frame has them. Also, only mark as noise if the lines exceed
  % the color threshold in the "I" view which shows gray scale + HSV scale.
  %
  % 2: deconvolution artifact -- rising edge sidelobe levels to high, use
  % "i" mode to verify the sidelobe exceeds the threshold (use the "I" mode
  % which shows a gray scale + HSV scale and mark sidelobes that are in
  % color), ignore first sidelobe if very close in to peak as the first
  % hanning sidelobe is expected to exceed 40 dB
  %
  % 3: raised noise floor/vertical stripes -- vertical stripes when noise
  % level increases suddenly
  %
  % 4: missing data -- see a white space in posted image
  % 5: no good data -- salt and pepper noise type (no obvious signal present)
  %
  % 6: low SNR -- barely visible sea ice or surface, usually caused by weak
  % signal (e.g. caused by high altitude, vertical stripe noise, or very
  % fast altitude changes)
  %
  % 7: unclassified -- any other kind of artifact that does not fit into the other categories
  % 8: land or iceberg -- if any land or iceberg is present in the frame (iceberg > 3 m above average surface height)
  % All bits are independent of each other. A frame with missing data+coherent noise+deconv artifact will be 124 instead of just 4
end

audio_tone_for_nonzero_nonisnan = true;
audio_tone_check_code = '~isnan(frames.(update_field)(frm)) && frames.(update_field)(frm) ~= 0';

%update_field_match = [1 2 3];
update_field_match = [];

quality_control;
