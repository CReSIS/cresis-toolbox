function [mdata] = plot_L1B(echo_fn,layerdata_source)
% [mdata] = plot_L1B(echo_fn,layerdata_source)
%
% Example of loading data with load_L1B.m and using elevation_compensation.m
%
% Plots data in three different ways:
%   Figure 1: time-delay on y-axis
%   Figure 2: range on y-axis
%   Figure 3: time-delay on y-axis
%
% Examples:
%
% fn = 'IRMCR1B_V01_20130408_01_020.nc';
% mdata = plot_L1B(fn);
%
% fn = '/cresis/snfs1/dataproducts/ct_data/rds/2012_Greenland_P3/CSARP_post/CSARP_qlook/20120412_01/Data_img_01_20120412_01_001.mat';
% [mdata,lay] = plot_L1B(fn,'CSARP_post/layerData');
%
% Author: John Paden
%
% See also: load_L1B.m, elevation_compensation.m

mdata = load_L1B(echo_fn);
if exist('layerdata_source','var')
  % Replace L1B echogram surface and bottom with L2 surface and bottom from layer data file
  [mdata.Surface,mdata.Bottom] = layerdata.load_layers(mdata,layerdata_source,'surface','bottom');
end

%% Set which bins to plot
param.ylims_bins = [-inf inf];
good_bins = round(max(1,min(mdata.Surface)+param.ylims_bins(1)) : min(max(mdata.Surface)+param.ylims_bins(2),size(mdata.Data,1)));

figure(1); clf;
imagesc([],mdata.Time(good_bins)*1e6,10*log10(mdata.Data(good_bins,:)))
xlabel('Range line');
ylabel('Two way travel time (us)')
colormap(1-gray(256))
hold on
plot(mdata.Surface*1e6);
if isfield(mdata,'Bottom')
  plot(mdata.Bottom*1e6);
end
hold off;

%% Elevation Correction Example
param = [];
param.update_surf = false;
param.filter_surf = true;
if 1
  param.er_ice = 3.15;
  param.elev_comp = 3;
  %param.depth = '[min(Surface_Elev)-20 max(Surface_Elev)+2]';
  [mdata_WGS84,depth_good_idxs] = elevation_compensation(mdata,param);
  
  %% Plot versus range
  figure(2); clf;
  imagesc([],mdata_WGS84.Elevation(1) - mdata_WGS84.Elevation_Fasttime(depth_good_idxs),10*log10(mdata_WGS84.Data(depth_good_idxs,:)));
  xlabel('Range line');
  ylabel('Range (m)')
  colormap(1-gray(256))
  hold on
  plot(mdata_WGS84.Elevation(1) - mdata_WGS84.Surface_Elev);
  if isfield(mdata,'Bottom')
    plot(mdata_WGS84.Elevation(1) - mdata_WGS84.Bottom_Elev);
  end
  hold off;
  
  %% Plot versus WGS-84 elevation
  figure(3); clf;
  imagesc([],mdata_WGS84.Elevation_Fasttime(depth_good_idxs),10*log10(mdata_WGS84.Data(depth_good_idxs,:)));
  xlabel('Range line');
  ylabel('WGS-84 (m)')
  set(gca,'YDir','normal')
  colormap(1-gray(256))
  hold on
  plot(mdata_WGS84.Surface_Elev);
  if isfield(mdata,'Bottom')
    plot(mdata_WGS84.Bottom_Elev);
  end
  hold off;
  
else
  param.er_ice = linspace(1.5,3.15,101);
  param.er_depth = linspace(0,100,101);
  param.elev_comp = 2;
  param.depth = '[-2 20]';
  [mdata_WGS84,depth_axis] = elevation_compensation(mdata,param);
  
  %% Plot versus depth
  figure(2); clf;
  imagesc([],depth_axis,10*log10(mdata_WGS84.Data));
  xlabel('Range line');
  ylabel('Depth (m)')
  colormap(1-gray(256))
end
