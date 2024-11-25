% script fmcw_compare_echogram
%
% Author: John Paden
%
% See also: 

%  fn = 'IRMCR1B_V01_20130408_01_020.nc';
%  mdata = load_L1B(fn);

param = read_param_xls(ct_filename_param('snow_param_2012_Greenland_P3.xls'),'20120319_05');
param2 = read_param_xls(ct_filename_param('kuband_param_2012_Greenland_P3.xls'),'20120319_05');

frames = frames_load(param);

fn = fullfile(gRadar.data_support_path,'kurtz_seaice_thickness','2012.03.19','IDCSI2_20120319.txt');
data = read_seaice_kurtz(fn);

for frm = 40%1:length(frames.frame_idxs)
  
  fn = fullfile(ct_filename_out(param,'CSARP_post/qlook'), ...
    sprintf('Data_%s_%03d.mat',param.day_seg, frm));
  mdata = load_L1B(fn);
  
  fn = fullfile(ct_filename_out(param2,'CSARP_post/qlook'), ...
    sprintf('Data_%s_%03d.mat',param2.day_seg, frm));
  mdata2 = load_L1B(fn);
  
  
  %% Set which bins to plot
  % param.ylims_bins = [-inf inf];
  % good_bins = round(max(1,min(mdata.Surface)+param.ylims_bins(1)) : min(max(mdata.Surface)+param.ylims_bins(2),size(mdata.Data,1)));
  
  % figure(1); clf;
  % imagesc([],mdata.Time(good_bins)*1e6,10*log10(mdata.Data(good_bins,:)))
  % xlabel('Range line');
  % ylabel('Two way travel time (us)')
  % colormap(1-gray(256))
  % hold on
  % plot(mdata.Surface*1e6);
  % hold off;
  
  %% Elevation Correction Example
  elev_param = [];
  elev_param.update_surf = true;
  elev_param.filter_surf = false;
  elev_param.er_ice = 3.15;
  elev_param.er_ice = 1.64;
  elev_param.depth = '[min(Surface_Elev)-20 max(Surface_Elev)+2]';
  [mdata_WGS84,depth_good_idxs] = elevation_compensation(mdata,elev_param);
  [mdata2_WGS84,depth_good_idxs2] = elevation_compensation(mdata2,elev_param);
  
  mdata_WGS84.Data = fir_dec(mdata_WGS84.Data,ones(1,11)/11,1);
  mdata2_WGS84.Data = fir_dec(mdata2_WGS84.Data,ones(1,11)/11,1);
  
  % Corrections to make images align
  mdata2_WGS84.Elevation_Fasttime = mdata2_WGS84.Elevation_Fasttime + 0.4;
  mdata2_WGS84.Data = mdata2_WGS84.Data*10;
  
  %% Plot versus range
  
  mdata_WGS84.snow_depth = zeros(size(mdata_WGS84.Surface_Elev));
  mdata_WGS84.atm_elev = zeros(size(mdata_WGS84.Surface_Elev));
  mdata_WGS84.ssh = zeros(size(mdata_WGS84.Surface_Elev));
  in_idx = 1;
  out_idx = 1;
  physical_constants;
  [data.x,data.y,data.z] = geodetic2ecef(data.lat/180*pi,data.lon/180*pi,zeros(size(data.elev)),WGS84.ellipsoid);
  [mdata_WGS84.x,mdata_WGS84.y,mdata_WGS84.z] = geodetic2ecef(mdata_WGS84.Latitude/180*pi,mdata_WGS84.Longitude/180*pi,zeros(size(mdata_WGS84.Elevation)),WGS84.ellipsoid);
  search_rng = [-5 5];
  while out_idx <= length(mdata_WGS84.snow_depth)
    if data.gps_time(in_idx+1)+1 > mdata_WGS84.GPS_time(out_idx)
      search_rng_trunc = max(1,in_idx+search_rng(1)) : min(length(data.x),in_idx+search_rng(end));
      dist = (mdata_WGS84.x(out_idx)-data.x(search_rng_trunc)).^2 ...
        + (mdata_WGS84.y(out_idx)-data.y(search_rng_trunc)).^2 ...
        + (mdata_WGS84.z(out_idx)-data.z(search_rng_trunc)).^2;
      [~,in_idx] = min(dist);
      in_idx = search_rng_trunc(in_idx);
      mdata_WGS84.snow_depth(out_idx) = data.snow_depth(in_idx);
      mdata_WGS84.atm_elev(out_idx) = data.elev(in_idx);
      mdata_WGS84.ssh(out_idx) = data.ssh(in_idx);
      out_idx = out_idx + 1;
    else
      in_idx = in_idx + 1;
    end
  end
  
  %along_track = geodetic_to_along_track(mdata_WGS84.Latitude,mdata_WGS84.Longitude);
  
  %% Plot versus WGS-84 elevation
  figure(1); clf;
  title(sprintf('%s: %s_%03d',param.radar_name,param.day_seg,frm),'interpreter','none');
  h_img = imagesc([],mdata_WGS84.Elevation_Fasttime(depth_good_idxs),10*log10(mdata_WGS84.Data(depth_good_idxs,:)));
  xlabel('Range line');
  ylabel('WGS-84 (m)')
  set(gca,'YDir','normal')
  colormap(1-gray(256))
  hold on
  h = [];
  h(end+1) = plot(mdata_WGS84.Surface_Elev);
  h(end+1) = plot(mdata_WGS84.Surface_Elev - mdata_WGS84.snow_depth,'r');
  h(end+1) = plot(mdata_WGS84.atm_elev-2.15,'g');
  
  figure(2); clf;
  h_img2 = imagesc([],mdata2_WGS84.Elevation_Fasttime(depth_good_idxs2),10*log10(mdata2_WGS84.Data(depth_good_idxs2,:)));
  title(sprintf('%s: %s_%03d',param2.radar_name,param2.day_seg,frm),'interpreter','none');
  xlabel('Range line');
  ylabel('WGS-84 (m)')
  set(gca,'YDir','normal')
  colormap(1-gray(256))
  hold on
  h(end+1) = plot(mdata_WGS84.Surface_Elev);
  h(end+1) = plot(mdata_WGS84.Surface_Elev - mdata_WGS84.snow_depth,'r');
  h(end+1) = plot(mdata_WGS84.atm_elev-2.45,'g');
  
  set(h,'Visible','off')
  break;
  
end

obj = column_browser('Ascope',[h_img h_img2],180,false);
xlabel('WGS-84 Elevation (m)');
ylabel('Relative power (dB)');
set(obj.h_fig,'MenuBar','figure');
xlim([15.95 19.55])
ylim([-30.5 -4.5])

return;

freq = [5e9 15e9];
er = sea_ice(freq,-10,0.0008,0.95,2);
figure(1); clf;
h1 = semilogx(freq/1e9,real(er),'k-');
hold on;
h2 = semilogx(freq/1e9,-imag(er),'k:');
hold off;
legend([h1 h2], 'er_b''', 'er_b''''');
xlabel('frequency (GHz)');
ylabel('dielectric constant of sea ice, er_b');
xlim([1 20]);


