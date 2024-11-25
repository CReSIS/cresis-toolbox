% script tomo_insar_image
%
% Script for creating insar figures and estimating the vertical velocity
% field from multipass.multipass coregistered images output.
%
% Authors: John Paden

%% User Settings
rlines = [];
if 0
  fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_multipass/summit_2012_2014_allwf_multipass03.mat';

  set1 = 1:15;
  set2 = 16:30;
  title_str = '2012 to 2014';
  time_year = 2;
  
  rbins = [115:1055]; % Good range including shallow and deep
%   rbins = [115+290:1055-150]; % Best range
  rbins_baseline = [600:650]; % Bins to use to estimate phase error due to GPS errors
  
  rlines = 1500:9889; % Good range lines
  %rlines = 1500:4296;
  %rlines = 4297:7092;
  %rlines = 7093:9888;
  
elseif 1
  fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_multipass/egig_2011_2012_2014_2018_allwf_multipass03.mat';
  
  set1 = 1:15;
  if 1
    set2 = 16:30;
    title_str = '2011 to 2014';
    time_year = 3;
  else
    set2 = 31:45;
    title_str = '2012 to 2014';
    time_year = 2;
  end
  rbins = [115:785]; % Good range including shallow and deep
  rbins_baseline = [500:550]; % Bins to use to estimate phase error due to GPS errors
  
  rlines = 250:6750; % Good range lines
  
elseif 0
  fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_multipass/camp_century_2011_2012_2013_2014_multipass03.mat';
  set1 = 38:52; % 20140429_01
  
  if 1
    title_str = '2011 to 2014';
    set2 = 1:15; % 2011
    time_year = 3;
  elseif 0
    title_str = '2012 to 2014';
    set2 = 16:30; % 2012
    time_year = 2;
  elseif 0
    title_str = '2013 to 2014';
    set2 = 31:37; % 2013
    time_year = 1;
  elseif 0
    title_str = '2014 to 2014 (same day)';
    set2 = 53:67; % 20140429_01
    time_year = 0/365.25;
  elseif 0
    title_str = '2014 to 2014 (two weeks)';
    set2 = 68:82; % 20140515_02
    time_year = 17/365.25;
  end
  
  rbins = [200:450];
  rbins = [2:1460];
  rbins = [102:451];
  % rbins_baseline is relative to rbins after motion compensation
  rbins_baseline = [280:310]; % Bins to use to estimate phase error due to GPS errors
end

%% Automated Section

physical_constants;

% Load data from multipass.multipass
tmp = load(fn);

% By default, process all range bins
if isempty(rbins)
  rbins = 1:size(tmp.data,1);
end

% Make rbins_baseline relative to rbins(1)
rbins_baseline = rbins_baseline - rbins(1);

% By default, process all range lines
if isempty(rlines)
  rlines = 1:size(tmp.data,2);
end

%% Form interferogram
insar1 = mean(tmp.data(rbins,rlines,set1),3);
insar2 = mean(tmp.data(rbins,rlines,set2),3);

insar_data = insar2 .* conj(insar1) ./ (abs(insar1).*abs(insar2));

%% Create surface multiple mask
multiple_guard_band = [-0.6e-6 -0e-6];
mask = true(size(insar_data));
for rline_idx = 1:length(rlines)
  rline = rlines(rline_idx);
  multiple_bins = tmp.ref.time >= tmp.ref.layers(1).twtt(rline)*2+multiple_guard_band(1) ...
    & tmp.ref.time <= tmp.ref.layers(1).twtt(rline)*2+multiple_guard_band(2);
  mask(multiple_bins,rline_idx) = false;
end

if 0
  %% Debug
  time = tmp.ref.time;
  
  figure(1); clf;
  imagesc([],time,lp(insar1));
  hold on;
  plot(tmp.ref.layers(1).twtt);
  plot(tmp.ref.layers(1).twtt*2);
  plot(tmp.ref.layers(2).twtt);
  
  figure(2); clf;
  imagesc([],time,lp(insar2));
  hold on;
  plot(tmp.ref.layers(1).twtt);
  plot(tmp.ref.layers(1).twtt*2);
  plot(tmp.ref.layers(2).twtt);
  
  figure(3); clf;
  imagesc([],time,angle(insar_data))
  hold on;
  plot(tmp.ref.layers(1).twtt*2);
  plot(tmp.ref.layers(1).twtt*2);
  
  figure(4); clf;
  imagesc([],time,mask);
  
  link_figures([1 2 3 4]);
  
end

%% Surface flattening
% Remove surface variations by moving all bins down so that the surface
% aligns for every range line and the surface bin is the max surface bin
tmp.ref.surface_bin = round(interp1(tmp.ref.time,1:length(tmp.ref.time),tmp.ref.surface));
max_surface_bin = ceil(max(tmp.ref.surface_bin));
dbin = tmp.ref.surface_bin(rlines) - max_surface_bin;
Nt = size(insar_data,1);
freq_bin = 1i*2*pi/Nt * ifftshift( -floor(Nt/2) : floor((Nt-1)/2) ).';
insar_data = ifft(fft(insar_data) .* exp(bsxfun(@times,dbin,freq_bin)));
for rline_idx = 1:length(rlines)
  rline = rlines(rline_idx);
  mask(:,rline_idx) = circshift(mask(:,rline_idx),-dbin(rline_idx));
end

% Remove bad circular deconvolution bins from surface flattening
[max_dbin,max_dbin_rline] = max(abs(dbin));
max_dbin = ceil(max_dbin);
insar_data = insar_data(1+max_dbin:end,:);
rbins = rbins(1+max_dbin:end);
mask = mask(1+max_dbin:end,:);
time = tmp.ref.time(1+max_dbin:end);

%% Baseline GPS/phase error correction
% baseline_correction = fir_dec(mean(insar_data(1:30,:),1),ones(1,51)/51,1);
baseline_correction = fir_dec(mean(insar_data(rbins_baseline,:),1),ones(1,51)/51,1);
insar_data = bsxfun(@times,insar_data,exp(-1i*angle(baseline_correction)));

%% Example plots for Summit, Greenland
if 0
  range = (tmp.ref.time(rbins) - tmp.ref.time(max_surface_bin)) * c/2 / sqrt(er_ice);
  relative_velocity_offset = 324;
  displacement = relative_velocity_offset+unwrap(angle(mean(insar_data,2))) * c/(4*pi*195e6) / 2 / 1.78 * 1000;
  pp = polyfit(range,displacement,2);
  
  % displacement = fir_dec(displacement - polyval(pp,range),ones(1,5)/5,1);
  
  figure(6000);clf;
  displacement(240:287) = nan;
  displacement_single = displacement;
  thickness = nanmean(tmp.ref.layers(2).twtt-tmp.ref.layers(1).twtt)*3e8/2/1.78;
  plot(displacement_single, thickness-range, '.','Color','red');
  hold on;
  displacement(240:287) = nan;
  displacement = polyval(pp,range(:).') + nan_fir_dec(displacement(:).' - polyval(pp,range(:).'),ones(1,51)/51,1);
  displacement = displacement(:).';
  range = range(:).';
  % displacement = displacement;
  plot(displacement, thickness-range, 'LineWidth', 3, 'Color', 'blue');
  hold on;
  grid on;
  xlim([-20 300])
  ylim([0 3082]);
  xlabel(sprintf('Vertical velocity\n(mm/year)'));
  ylabel('Height above bed (m)');
  
  figure(6001);clf;
  plot(thickness-range, displacement_single, '.','Color','red');
  hold on;
  plot(thickness-range, displacement, 'LineWidth', 2, 'Color', 'blue');
  grid on;
  ylim([-20 300])
  xlim([0 3082]);
  ylabel(sprintf('Vertical velocity\n(mm/year)'));
  xlabel('Height above bed (m)');
  plot([3082 3082], [-20 300],'Color',[0.5 0.5 0.5],'linewidth',3);
  h=text(3082-100,50,'Surface','Rotation',90);
  plot([0 0], [-20 300],'Color',[0.5 0.5 0.5],'linewidth',3);
  text(100,50,'Bottom','Rotation',90);
  legend('Measured','Smoothed','location','best')
  
  %
  displacement(1:100) = nan;
  displacement(235:292) = nan;
  displacement(850:end) = nan;
  strain_rate = nan_fir_dec(diff(displacement) ./ diff(range), ones(1,3)/3,1);
  figure(6002); clf;
  plot(-strain_rate/1000, thickness-range(2:end), '.','Color','red');
  hold on
  strain_rate = fir_dec(strain_rate,ones(1,101)/101,1);
  plot(-strain_rate/1000, thickness-range(2:end), 'LineWidth', 3, 'Color', 'blue');
  grid on;
  xlabel(sprintf('Strain rate\n(m\\cdotm^{-1}\\cdota^{-1})'));
  ylabel('Height above bed (m)');
  ylim([0 3082]);
  xlim([0 0.3]/1000);
  
  return;
end

%% Example plots for EGIG, Greenland
if 0
  range = (tmp.ref.time(rbins) - tmp.ref.time(max_surface_bin)) * c/2 / sqrt(er_ice);
  relative_velocity_offset = 425;
  displacement = relative_velocity_offset+unwrap(angle(mean(insar_data,2))) * c/(4*pi*195e6) / 2 / 1.78 * 1000;
  pp = polyfit(range(325:650),displacement(325:650),2);
  max_vel = 450;
 
  % displacement = fir_dec(displacement - polyval(pp,range),ones(1,5)/5,1);
  
  figure(6000);clf;
%   displacement(240:287) = nan;
  displacement_single = displacement;
  thickness = nanmean(tmp.ref.layers(2).twtt-tmp.ref.layers(1).twtt)*3e8/2/1.78;
  plot(displacement_single, thickness-range, '.','Color','red');
  hold on;
%   displacement(240:287) = nan;
  displacement = polyval(pp,range(:).') + nan_fir_dec(displacement(:).' - polyval(pp,range(:).'),ones(1,51)/51,1);
  displacement = displacement(:).';
  range = range(:).';
  % displacement = displacement;
  plot(displacement, thickness-range, 'LineWidth', 3, 'Color', 'blue');
  hold on;
  grid on;
  xlim([-20 max_vel])
  ylim([0 3082]);
  xlabel(sprintf('Vertical velocity\n(mm/year)'));
  ylabel('Height above bed (m)');
  
  figure(6001);clf;
  plot(thickness-range, displacement_single, '.','Color','red');
  hold on;
  plot(thickness-range, displacement, 'LineWidth', 2, 'Color', 'blue');
  grid on;
  ylim([-20 max_vel])
  xlim([0 3082]);
  ylabel(sprintf('Vertical velocity\n(mm/year)'));
  xlabel('Height above bed (m)');
  plot([3082 3082], [-20 max_vel],'Color',[0.5 0.5 0.5],'linewidth',3);
  h=text(3082-100,50,'Surface','Rotation',90);
  plot([0 0], [-20 max_vel],'Color',[0.5 0.5 0.5],'linewidth',3);
  text(100,50,'Bottom','Rotation',90);
  legend('Measured','Smoothed','location','best')
  
  %
  displacement(1:100) = nan;
  displacement(235:292) = nan;
  displacement(850:end) = nan;
  strain_rate = nan_fir_dec(diff(displacement) ./ diff(range), ones(1,3)/3,1);
  figure(6002); clf;
  plot(-strain_rate/1000, thickness-range(2:end), '.','Color','red');
  hold on
  strain_rate = fir_dec(strain_rate,ones(1,101)/101,1);
  plot(-strain_rate/1000, thickness-range(2:end), 'LineWidth', 3, 'Color', 'blue');
  grid on;
  xlabel(sprintf('Strain rate\n(m\\cdotm^{-1}\\cdota^{-1})'));
  ylabel('Height above bed (m)');
  ylim([0 3082]);
  xlim([0 0.3]/1000);
  
  return;
end

%% Estimate vertical velocity
range = (tmp.ref.time(rbins) - tmp.ref.time(max_surface_bin)) * c/2 / sqrt(er_ice);

insar_data(~mask) = NaN;

insar_data_filt = fir_dec(fir_dec(insar_data,ones(1,31)/31,1).',ones(1,3)/3).';

meter_units = true;

along_track = geodetic_to_along_track(tmp.ref.lat(rlines),tmp.ref.lon(rlines));

figure(3001); clf;
if meter_units
  imagesc(along_track/1e3,range,hsv_plot(insar_data_filt,-2));
else
  imagesc(hsv_plot(insar_data_filt,-2));
end
colormap(hsv(256))
h_colorbar = colorbar;
caxis([-pi pi])
set(get(h_colorbar,'ylabel'),'string','Angle (radians)');
grid on;
if meter_units
  xlabel('Along-track (km)');
  ylabel('Depth, \epsilon_{r,ice}=3.15 (m)');
else
  xlabel('Range line');
  ylabel('Range bin');
end
title(title_str);
set(3001,'Position',[56   470   867   426]);

figure(3000); clf;
if meter_units
  imagesc(along_track/1e3,range,abs(insar_data_filt));
else
  imagesc(abs(insar_data_filt));
end
h_colorbar = colorbar;
set(get(h_colorbar,'ylabel'),'string','Coherence');
grid on;
if meter_units
  xlabel('Along-track (km)');
  ylabel('Depth, \epsilon_{r,ice}=3.15 (m)');
else
  xlabel('Range line');
  ylabel('Range bin');
end
title(title_str);
set(3000,'Position',[56   470   867   426]);
caxis([0 1]);

%% Save Figures
% =========================================================================
if 0
  [fn_dir,fn_name] = fileparts(fn);
  fn_insar_phase = fullfile(fn_dir,[fn_name '_phase.fig']);
  fprintf('Saving %s (%s)\n', fn_insar_phase, datestr(now));
  saveas(3001,fn_insar_phase);
  fn_insar_phase = fullfile(fn_dir,[fn_name '_phase.png']);
  fprintf('Saving %s (%s)\n', fn_insar_phase, datestr(now));
  saveas(3001,fn_insar_phase);
  
  [fn_dir,fn_name] = fileparts(fn);
  fn_insar_coherence = fullfile(fn_dir,[fn_name '_coherence.fig']);
  fprintf('Saving %s (%s)\n', fn_insar_coherence, datestr(now));
  saveas(3000,fn_insar_coherence);
  fn_insar_coherence = fullfile(fn_dir,[fn_name '_coherence.png']);
  fprintf('Saving %s (%s)\n', fn_insar_coherence, datestr(now));
  saveas(3000,fn_insar_coherence);
end

link_figures([3000 3001]);

%%

figure(3003); clf;
Nt = size(insar_data_filt,1);
Mt = 200;
insar_data_filt_mask = insar_data_filt;
insar_data_filt_mask(~isfinite(insar_data_filt_mask)) = 0;
dd=abs(fftshift(fft(insar_data_filt_mask,Mt*Nt),1)).^2;
along_track_filt = 2001;
dd=fir_dec(dd,ones(1,along_track_filt)/along_track_filt,20);
along_track_dec=fir_dec(along_track,ones(1,along_track_filt)/along_track_filt,20);

% imagesc(lp(dd));

% time_years = (tmp.pass(set1(1)).gps_time(1) - tmp.pass(set2(1)).gps_time(1))/86400/365.25;

[dd_val,dd_idx] = max(dd);
max_freq = 1 + dd_idx - Nt*Mt/2;

lambda = 3e8/195e6;
dt = tmp.ref.time(2)-tmp.ref.time(1);
dr = dt*3e8/2;
if meter_units
  plot(along_track_dec/1e3, 2*pi*max_freq/(Nt*Mt) * lambda/(4*pi) / dr / time_year)
  xlabel('Along-track (km)');
  ylabel('Vertical strain rate (m\cdotm^{-1}\cdota^{-1})');
else
  plot(2*pi*max_freq/(Nt*Mt) * lambda/(4*pi) / dr / time_year)
  xlabel('Range line');
  ylabel('Radians/range bin');
end
grid on;
hold on;
xlim(along_track_dec([1 end])/1e3);

mean(2*pi*max_freq/(Nt*Mt) * lambda/(4*pi) / dr / time_year)

mean(2*pi*max_freq(end-90:end-10)/(Nt*Mt) * lambda/(4*pi) / dr / time_year)

strain_rate = 2*pi*max_freq/(Nt*Mt) * lambda/(4*pi) / dr / time_year;
