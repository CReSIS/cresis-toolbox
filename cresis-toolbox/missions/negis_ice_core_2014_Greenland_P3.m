% script negis_ice_core_2014_Greenland_P3
%
% Loads accumulation radar data from 2014 Greenland P3 seasons and
% NEGIS ice core data provided from Dorthe and compares the two.
%
% The flightline intersects the core site along two paths. One path is
% parallel to ice flow and the other path is perpendicular to ice flow.
%
% RDS Along Flow:
% 20140515_02_043: 75.523918 N, -36.285775 E, X:238.804 km, Y:-1558.022 km, 2014-05-15 15:35:58.44
% 20140515_02_044: 75.683343 N, -35.735352 E, X:250.937 km, Y:-1538.350 km, 2014-05-15 15:38:53.15
%
% Author: Joe Lilek, Rosemary Leone, John Paden
%
% See also: genReflTranFromPerm.m


%% User Settings

param.radar_name = 'accum';
param.season_name = '2014_Greenland_P3';
param.day_seg = '20140515_02';

data_product = 'CSARP_post/qlook';

if 1
  % Crossing: May 15, 2014 15:21:26 to 15:27:00
  param.start.gps_time = datenum_to_epoch(datenum(2014,5,15,15,21,26));
  param.stop.gps_time = datenum_to_epoch(datenum(2014,5,15,15,27,0));
  start_figure_num = 0;
else
  % Along: May 15, 2014 15:35:00 to 15:41:50
  param.start.gps_time = datenum_to_epoch(datenum(2014,5,15,15,35,0));
  param.stop.gps_time = datenum_to_epoch(datenum(2014,5,15,15,41,50));
  start_figure_num = 10;
end

density_fn = fullfile(gRadar.data_support_path,'em_model_data','negis_density_from_Dorthe20140624.txt');
timescale_fn = fullfile(gRadar.data_support_path,'em_model_data','negis_core_from_Dorthe20140624_timescale.csv');
contaminants_fn = fullfile(gRadar.data_support_path,'em_model_data','negis_core_from_Dorthe20140624_contaminants.csv');

map_enabled = true;

%% Automated Section

physical_constants;
global gRadar;

%% Load density data
fid = fopen(density_fn,'r');
density = textscan(fid,'%f%f','Headerlines',1);
density_depth = density{1};
density = density{2};
fclose(fid);
if 0
  plot(density_depth, density);
  grid on;
  xlabel('Depth (m)');
  ylabel('NEGIS density (g/cm^3)');
end

%% Load time scale data
fid = fopen(timescale_fn,'r');
age = textscan(fid,'%f%f%f','Headerlines',1,'Delimiter',',');
age_depth = age{1};
age = age{3};
fclose(fid);
if 0
  plot(age_depth, age);
  grid on;
  xlabel('Depth (m)');
  ylabel('Age (year)');
end

%% Load contaminants
fid = fopen(contaminants_fn,'r');
core = textscan(fid,'%f%f%f%f%f%f%f%f','Headerlines',1,'Delimiter',',');
core_depth = core{1};
core_d18 = core{2};
core_dxs = core{3};
core_dust = core{4};
core_conduct = core{5};
core_dep = core{6};
core_Na = core{7};
core_NH4 = core{8};
fclose(fid);
if 0
  %% Debug plots
  figure(1); clf;
  plot(core_depth, core_d18);
  grid on;
  xlabel('Depth (m)');
  ylabel('Oxygen d18');
  
  figure(2); clf;
  plot(core_depth, core_dxs);
  grid on;
  xlabel('Depth (m)');
  ylabel('dxs');
  
  figure(3); clf;
  plot(core_depth, core_dust);
  grid on;
  xlabel('Depth (m)');
  ylabel('Dust');
  
  figure(4); clf;
  plot(core_depth, core_conduct);
  grid on;
  xlabel('Depth (m)');
  ylabel('Conductivity');
  
  figure(5); clf;
  plot(core_depth, core_dep);
  grid on;
  xlabel('Depth (m)');
  ylabel('DEP');
  
  figure(6); clf;
  plot(core_depth, core_Na);
  grid on;
  xlabel('Depth (m)');
  ylabel('Na');
  
  figure(7); clf;
  plot(core_depth, core_NH4);
  grid on;
  xlabel('Depth (m)');
  ylabel('NH_4');
end

%% Find good records and frames
records_fn = ct_filename_support(param,'','records');
frames_fn = ct_filename_support(param,'','frames');
records = load(records_fn);
load(frames_fn);

% Find good records
first_record = find(records.gps_time >= param.start.gps_time,1);
first_frame = find(frames.frame_idxs > first_record,1)-1;

last_record = find(records.gps_time <= param.stop.gps_time,1,'last');
last_frame = find(frames.frame_idxs > last_record,1)-1;

%% Load each frame of data
mdata = [];
frms = first_frame:last_frame;
for frm_idx = 1:length(frms)
  frm = frms(frm_idx);
  frm_fn = fullfile(ct_filename_out(param,data_product,'CSARP_qlook'),sprintf('Data_%s_%03d.mat',param.day_seg,frm));
  if frm_idx == 1
    mdata = load(frm_fn);
  else
    tmp = load(frm_fn);
    mdata.Data = cat(2,mdata.Data,tmp.Data);
    mdata.GPS_time = cat(2,mdata.GPS_time,tmp.GPS_time);
    mdata.Latitude = cat(2,mdata.Latitude,tmp.Latitude);
    mdata.Longitude = cat(2,mdata.Longitude,tmp.Longitude);
    mdata.Elevation = cat(2,mdata.Elevation,tmp.Elevation);
    mdata.Surface = cat(2,mdata.Surface,tmp.Surface);
    mdata.Heading = cat(2,mdata.Heading,tmp.Heading);
    mdata.Pitch = cat(2,mdata.Pitch,tmp.Pitch);
    mdata.Roll = cat(2,mdata.Roll,tmp.Roll);
  end
end

%% Restrict data to just the range lines of interest
good_rlines_mask = mdata.GPS_time >= param.start.gps_time & mdata.GPS_time <= param.stop.gps_time;
mdata.Data = mdata.Data(:,good_rlines_mask);
mdata.GPS_time = mdata.GPS_time(:,good_rlines_mask);
mdata.Latitude = mdata.Latitude(:,good_rlines_mask);
mdata.Longitude = mdata.Longitude(:,good_rlines_mask);
mdata.Elevation = mdata.Elevation(:,good_rlines_mask);
mdata.Surface = mdata.Surface(:,good_rlines_mask);
mdata.Heading = mdata.Heading(:,good_rlines_mask);
mdata.Pitch = mdata.Pitch(:,good_rlines_mask);
mdata.Roll = mdata.Roll(:,good_rlines_mask);

if 0
  %% Debug plots
  figure(1); clf;
  imagesc([],Time,lp(Data));
  colormap(1-gray(256));
end

if map_enabled
  %% Locate the range line closest to the radar data
  negis_core.lat = 75.626;
  negis_core.lon = -35.9415;
  negis_core.elev = 2750;
  negis_core.vel = [22.079012 51.326889]; % m per year [x y] in polar stereographic map projection
  
  [negis_core.x negis_core.y negis_core.z] = geodetic2ecef(negis_core.lon/180*pi, ...
    negis_core.lat/180*pi,negis_core.elev, WGS84.ellipsoid);
  [mdata.x mdata.y mdata.z] = geodetic2ecef(mdata.Longitude/180*pi, ...
    mdata.Latitude/180*pi, negis_core.elev*ones(size(mdata.Elevation)), WGS84.ellipsoid);
  
  % Finding the closest point without accounting for ice sheet motion
  dist = sqrt( (mdata.x-negis_core.x).^2 + (mdata.y-negis_core.y).^2 ...
    + (mdata.z-negis_core.z).^2 );
  [min_dist, min_dist_rline] = min(dist);
  
  % Finding the closest point accounting for ice sheet motion
  % Step 1. Project data into polar stereographic map projection
  geotiff_fn = fullfile(gRadar.gis_path,'greenland','Landsat-7','mzl7geo_90m_lzw.tif');
  [proj,fig_h] = plot_geotiff(geotiff_fn,[],[],3+start_figure_num);
  [mdata.proj_x mdata.proj_y] = projfwd(proj, mdata.Latitude, mdata.Longitude);
  [negis_core.proj_x negis_core.proj_y] = projfwd(proj, negis_core.lat, negis_core.lon);
  
  % Step 2. Apply offset due to ice sheet velocity
  negis_core.proj_x_present = negis_core.proj_x + negis_core.vel(1)*2;
  negis_core.proj_y_present = negis_core.proj_y + negis_core.vel(2)*2;
  
  % Step 3. Project data into geodetic coordinate system
  [negis_core.lat_present,negis_core.lon_present] = projinv(proj,negis_core.proj_x_present,negis_core.proj_y_present);
  negis_core.elev_present = negis_core.elev;
  
  % Step 4. Convert to ECEF to calculate distances
  [negis_core.x_present negis_core.y_present negis_core.z_present] = geodetic2ecef(negis_core.lon_present/180*pi, ...
    negis_core.lat_present/180*pi,negis_core.elev_present, WGS84.ellipsoid);
  
  % Step 5. Find minimum distance between radar data and present NEGIS core location
  dist_present = sqrt( (mdata.x-negis_core.x_present).^2 + (mdata.y-negis_core.y_present).^2 ...
    + (mdata.z-negis_core.z_present).^2 );
  [min_dist_present, min_dist_rline_present] = min(dist_present);
  fprintf('  Closest point is %.0f m away\n', min_dist_present);
  
  hold on;
  plot(mdata.proj_x/1e3, mdata.proj_y/1e3);
  plot(negis_core.proj_x/1e3, negis_core.proj_y/1e3,'kx','LineWidth',3,'MarkerSize',10);
  plot(negis_core.proj_x_present/1e3, negis_core.proj_y_present/1e3,'rx','LineWidth',3,'MarkerSize',10);
  hold off;
end

%% Account for densification
densify_years = 2; %n years
age_depth_densified = interp1(age,age_depth,age-densify_years,'linear','extrap');%accounts for n years of accumulation
core_depth_densified = core_depth+interp1(age_depth,age_depth_densified,core_depth,'linear','extrap');%interpolates age_depth_densified over 66201 layers
density_depth_densified = density_depth+interp1(age_depth,age_depth_densified,density_depth,'linear','extrap');%accounts for compression of layers and accumulation above

final_depth = sort(unique([core_depth_densified; density_depth_densified]));%combines core and density depth measurements, making final_depth most precise

final_dep = interp1(core_depth_densified, core_dep, final_depth);
final_density = interp1(density_depth_densified, density, final_depth);
final_dep = interp_finite(final_dep);
final_density = interp_finite(final_density);


%% Complex permittivity using DEP
temperature = 273.15-25;
freq = 750e6;
Tref = 273.15-20;
eV = 0.22;

er = iceCond(temperature,final_density,freq,final_dep * 1e-6,eV,Tref);
er = reshape(er,length(er),1);


%% Create time and frequency axes for the radar data
Time = mdata.Time;
t0 = Time(1);
dt = Time(2)-Time(1);
Nt = length(Time);
time = [t0+dt*(0:Nt-1)]';
T = dt*Nt;
df = 1/T;
B = (Nt-1)*df;
fc = 750e6;
freq = fc + df*(-floor(Nt/2):floor((Nt-1)/2))';

%% Create or load the reflection coefficient file
refl_coef_fn = ct_filename_tmp(gRadar,'refl_coef_data.mat');
if 1
  warning('Only need to run this once to create refl_coef_data.mat file!')
  % script negis_gen_refl_coef
  %
  % Load shallow ice core data for NEGIS, 2014 Greenland P3 accumulation
  % radar data and generate a corresponding simulated radar response for
  % comparison
  
  % Thick is the distance between two layers
  thick = diff(final_depth);
  thick = [0; thick]; % Forcing to match previous work
  thick(end) = thick(end-1); % Forcing to match previous work
  
  %% Generate the reflection coefficient, refl_coef, for each frequency
  refl_coef = zeros(size(freq));
  for idx = 1:length(freq)
    er = iceCond(temperature,final_density,freq(idx),final_dep * 1e-6,eV,Tref);
    er = reshape(er,length(er),1);
    refl_coef(idx) = genReflTranFromPerm(thick,ones(size(er)),er,freq(idx),zeros(size(er)));
  end
  refl_coef = refl_coef';
  
  % Save output
  save(refl_coef_fn,'freq','refl_coef');
end
load(refl_coef_fn);

% layered media impulse response
ifftGamma = ifft(refl_coef);
%ifftGamma = ifft(Gamma);
time_shift = 9.2401e-006;
%ifftGamma_shift = ifftGamma .* exp(1j*freq*time_shift);

%% Elevation compensate the data
param = [];
param.update_surf = false;
param.filter_surf = false;
param.depth = '[-2 132.75]';
param.er_ice = [abs(er(1)); abs(er)];
param.er_depth = [0; final_depth];
param.elev_comp = 2;
[mdataEC,depth_axis] = elevation_compensation(mdata,param);

% Compensate for surface offset
%depth_axis = depth_axis - 0.6;
% Perform incoherent moving average to help reduce fading of layers
mdataEC.Data = fir_dec(mdataEC.Data, ones(1,11), 1);

%% convert time data into depth data
param.er_depth = depth_axis;%depth = the thing from down below that is used on the plots
param.er_ice = er;
param.er_freq = 750e6;
% Depth time axis
depth_time = size(depth_axis);
% Above surface
depth_time(depth_axis <= 0) = depth_axis(depth_axis <= 0) / (c/2);
% Below surface and within DEP defined depth
if length(param.er_depth) > 1
  TWtime = genPropProfileFromPerm(param.er_depth,param.er_ice, param.er_freq);
  profile_idxs = depth_axis > 0 & depth_axis < param.er_depth(end);
  depth_time(profile_idxs) = interp1(param.er_depth, TWtime, depth_axis(profile_idxs));
end
depth_time = depth_time';
depth_time = [0;depth_time]; %ensure vectors are the same length
% Below surface and below DEP defined depth
const_idxs = depth_axis >= param.er_depth(end);
depth_time(const_idxs) = TWtime(end) + (depth_axis(const_idxs) - param.er_depth(end)) / (c/2/sqrt(param.er_ice(end)));
time_shifted = time-time_shift; %line up time and depth_time
time_shifted2 = time_shifted(time_shifted>0); %keeps only positive values
depth_time2 = interp1(time_shifted2,depth_time);

% Re-interpolate data to get constant depth axis
%new_impulse = interp1(time_shifted,real(ifftGamma),depth_time);
sim_response = interp1(time,real(ifftGamma),depth_time);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Plot echogram
figure(1+start_figure_num); clf;
imagesc([], depth_axis, 10*log10(mdataEC.Data))
colormap(1-gray(256))
xlabel('Range line');
ylabel('Depth (m)');
if map_enabled
  hold on;
  plot(min_dist_rline_present*ones(1,2),ylim,'r');
  hold off;
end

%% Fit polynomials to the data

% Fit a polynomial to the radar data
good_bins = depth_axis > 0;
p_data = polyfit(depth_axis(good_bins), 10*log10(mdataEC.Data(good_bins,min_dist_rline_present)),3);
r_data = 10*log10(mdataEC.Data(:,min_dist_rline_present)) - polyval(p_data,depth_axis);
r_raw = mdataEC.Data(:,min_dist_rline_present);
r_data2 = abs(r_data);

% Fit a polynomial to the simulated radar
good_bins2 = depth_axis > 0 & ~isnan(sim_response); %NaN's inhibit polyfit, so they must be ignored
p_simul = polyfit(depth_axis(good_bins2),10*log10(sim_response(good_bins2)),3);
r_simul = 10*log10(sim_response)-polyval(p_simul,depth_axis);
r_simul2 = abs(real(r_simul));
r_simul2(463) = r_simul2(462);

% Fit a polynomial to the density
p_density = polyfit(final_depth, final_density, 4);
r_density = final_density - polyval(p_density,final_depth);

% Fit a polynomial to the DEP
good_mask = ~isnan(core_dep);
p_dep = polyfit(core_depth(good_mask), core_dep(good_mask), 4);
r_dep = core_dep - polyval(p_dep,core_depth);

%% Plot figures to compare simulated radar response to echogram

figure(2+start_figure_num); clf;
subplot(2,1,1); %echogram
plot(depth_axis, r_data);
title('Radar compared to simulation')
ylabel(sprintf('Radar Power\ndeviation (dB)'));
grid on;
xlim([-0.5 140]);
hold off;

subplot(2,1,2); %simulation
plot(depth_axis, r_simul);
ylabel(sprintf('Simulated Power\ndeviation (dB)'));
grid on;
xlim([-0.5 140]);
xlabel('Depth');

figure(3+start_figure_num); clf;
subplot(5,1,1); %echogram
plot(depth_axis, r_data);
title('Radar compared to simulation')
ylabel(sprintf('Radar power\ndeviation (dB)'));
grid on;
xlim([-0.5 140]);
hold off;

subplot(5,1,2); %simulation
plot(depth_axis, r_simul);
ylabel(sprintf('Simulated Radar\ndeviation (dB)'));
grid on;
xlim([-0.5 140]);
xlabel('Depth');

subplot(5,1,3); % dielectric
plot(final_depth,final_dep);
ylabel(sprintf('DEP\n(uS/m)'));
grid on;
xlim([-0.5 140]);
hold off;

subplot(5,1,4); % conductivity
plot(core_depth+interp1(age_depth,age_depth_densified,core_depth,'linear','extrap'), core_conduct);
ylabel(sprintf('Conductivity\n(uS/m)'));
grid on;
xlim([-0.5 140]);
xlabel('Depth');

subplot(5,1,5); % density
plot(final_depth, r_density);
ylabel(sprintf('Density\ndeviation (g/cm^3)'));
grid on;
xlim([-0.5 140]);
hold off;

figure(6)
plot(depth_axis,r_data);
hold on;
plot(depth_axis,real(r_simul)/2,'r');
xlim([-0.5 140]);
ylim([-20 20]);
title('Echogram Deviation and Scaled Simulation Deviation Superimposed')
ylabel(sprintf('(dB)'));
legend('Echogram','Simulation')

figure(7) %
plot(depth_axis,r_data);
hold on;
plot(depth_axis,1e5*sim_response,'r');
title('Echogram Deviation and Scaled Simulation Superimposed')
legend('Echogram','Simulation')
ylabel(sprintf('(dB)'));
xlim([-0.5 140]);
ylim([-20 20]);

figure(8)
plot(depth_axis,r_data2);
hold on;
plot(depth_axis,r_simul2,'r');
title('Absolute value of Echogram Deviation and Simulation Superimposed')
legend('Echogram','Simulation')
ylabel(sprintf('(dB)'));
xlim([-0.5 140]);
ylim([0 40]);