% function cross_track_slope_est
%
% Simple script to estimate the cross track slope from a 3D image formed by
% multipass.multipass call to array_proc (usually MUSIC array processing
% method).
%
% Author: John Paden

%% User Settings

if 0
  wf = 2;
  if ispc
    fn = fullfile('X:/ct_data/rds/2014_Greenland_P3/CSARP_insar/',sprintf('rds_thule_20140429_01_067_wf%d.mat',wf));
  else
    fn = fullfile('/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_insar/',sprintf('rds_thule_20140429_01_067_wf%d.mat',wf));
  end
  last_good_bin = 450;
  min_valid_value = 100;
  
elseif 0
  if ispc
  else
    fn = fullfile('/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_insar/',sprintf('rds_thule_combine_wf%d.mat',wf));
    out_fn = fullfile('/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_insar/',sprintf('rds_thule_combine_wf%d.mat',wf));
  end
  last_good_bin = 450;
  min_valid_value = 100;
  
elseif 0
  if ispc
  else
    fn = fullfile('/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_insar/',sprintf('rds_thule_combine_wf%d_singlepass.mat',wf));
    out_fn = fullfile('/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_insar/',sprintf('rds_thule_combine_wf%d.mat',wf));
  end
  last_good_bin = 450;
  min_valid_value = 100;
  
elseif 0
  if ispc
  else
    % Summit
    % fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_insar/summit_2012_2014_wf2.mat';
    % fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_insar/summit_2012_2014_wf2_2012.mat';
    % fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_insar/summit_2012_2014_wf2_2014.mat';
    fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_multipass/summit_2012_2014_allwf_2012.mat';
    
    out_fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_multipass/summit_2012_2014_allwf.mat';
    last_good_bin = 1036;
    min_valid_value = 70;
  end
  
elseif 1
  if ispc
  else
    % EGIG
    fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_multipass/egig_2011_2012_2014_2018_allwf_2014.mat';
    
    out_fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_multipass/egig_2011_2012_2014_2018_allwf.mat';
    last_good_bin = 970;
    min_valid_value = 70;
  end
end

%% Automated Section

% Load file
[fn_dir,fn_name] = fileparts(fn);
fn_mat = fullfile(fn_dir,[fn_name '_music.mat']);
load(fn_mat);

% Very simple algorithm to extract the slope by assuming the slope is equal
% to the direction of arrival bin with the maximum value in each pixel.
[slope_val,slope] = max(Tomo.img,[],2);
slope = squeeze(slope);
slope_val = squeeze(slope_val);

% Plot the magnitude of the peak values for each pixel (usually noisy)
figure(5001); clf;
imagesc(slope_val);
colorbar

% Convert surface twtt to bins
surf_bin = round(interp1(Time,1:length(Time),Surface));

% Mask out pixels above the surface
for rline = 1:size(slope,2)
  slope(1:surf_bin(rline)-1,rline) = NaN;
end
% Mask out pixels below the bottom (currently an manual approximation)
slope(last_good_bin:end,:) = NaN;

% Mask out pixels that are below the average power for the corresponding
% range bin. Have a minimum threshold to use for the average power though.
max_slope_val = max(slope_val,[],2);
Nx = size(slope_val,2);
mean_slope_val = repmat(mean(slope_val,2),[1 Nx]);
mean_slope_val = max(mean_slope_val,min_valid_value);
bad_mask = slope_val<mean_slope_val;
slope(bad_mask) = NaN;

% Plot the masked slope estimates
figure(5002); clf;
imagesc(slope);
link_figures([5001 5002]);

% Filter the results
slope = nan_fir_dec(slope,ones(1,21)/21,1);
slope = nan_fir_dec(slope.',ones(1,11)/11,1).';
slope = interp_finite(slope);
slope = medfilt2(slope,[21 21]);
slope = echo_filt(slope,[31 31]);

% Convert the results to direction of arrival
slope = interp1(1:length(Tomo.theta),Tomo.theta,slope);

% Plot the direction of arrival (slope) which has been masked and filtered
figure(5003); clf;
imagesc(slope*180/pi)
colorbar
link_figures([5001 5002 5003]);

if 0
  % Previous filtering code for reference
  slope = medfilt1(slope.',11,5).';
  slope = medfilt1(slope,31,15);
  slope = nan_fir_dec(slope.',ones(1,11)/11,1).';
  slope = interp_finite(slope);
  imagesc(slope*180/pi)
  colorbar
end

% Save the output
[fn_dir,fn_name] = fileparts(out_fn);
fn_slope = fullfile(fn_dir,[fn_name '_slope.mat'])
save(fn_slope,'slope','GPS_time','Latitude','Longitude','Elevation','Time','Surface');
