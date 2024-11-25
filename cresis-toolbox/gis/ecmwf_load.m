
% cresis-toolbox\python\ECMWF\ecmwf_download.py
% D:\tmp\koenig_internal_layers\
ecmwf = ncinfo('erai_tp_e_79_17.nc');

% units: degrees_east
% long_name: longitude
ecmwf.lon = ncread('erai_tp_e_79_17.nc','longitude');

% units: degrees_north
% long_name: latitude
ecmwf.lat = ncread('erai_tp_e_79_17.nc','latitude');

% units: hours since 1900-01-01 00:00:00.0
% long_name: time
% calendar: gregorian
ecmwf.time = ncread('erai_tp_e_79_17.nc','time');
% convert to Matlab datenum format
ecmwf.time = double(ecmwf.time);
ecmwf.time = datenum(1900*ones(size(ecmwf.time)),0*ones(size(ecmwf.time)), ...
  0*ones(size(ecmwf.time)),ecmwf.time,0*ones(size(ecmwf.time)),0*ones(size(ecmwf.time)));

% scale_factor: 2.888693e-07
% add_offset: -7.720227e-03
% _FillValue: 
% missing_value: 
% units: m of water equivalent
% long_name: Evaporation
% standard_name: lwe_thickness_of_water_evaporation_amount
ecmwf.e = ncread('erai_tp_e_79_17.nc','e');

% scale_factor: 1.567633e-06
% add_offset: 5.136507e-02
% _FillValue: 
% missing_value: 
% units: m
% long_name: Total precipitation
% ncread should be applying the scale_factor, add_offset, and _FillValue
ecmwf.tp = ncread('erai_tp_e_79_17.nc','tp');

for var_idx = 1:length(ecmwf.Variables)
  for attrib_idx = 1:length(ecmwf.Variables(var_idx).Attributes)
    attrib = ecmwf.Variables(var_idx).Attributes(attrib_idx);
    if isnumeric(attrib)
      fprintf('%s: %f\n', attrib.Name, attrib.Value);
    else
      fprintf('%s: %s\n', attrib.Name, attrib.Value);
    end
  end
end

% 2 to 8 meters per year
% 37 years... 80 meters to 320 meters

ecmwf.tp = permute(ecmwf.tp,[2 1 3]);
ecmwf.e = permute(ecmwf.e,[2 1 3]);

fprintf('%s to %s\n', datestr(ecmwf.time(1)), datestr(ecmwf.time(end)))

xmask = ecmwf.lon > 360-70 & ecmwf.lon < 360-20;
ymask = ecmwf.lat > 60 & ecmwf.lat < 80;

% Greenland meters SWE per year
figure(1); clf;
imagesc(ecmwf.lon(xmask),ecmwf.lat(ymask),(mean(ecmwf.tp(ymask,xmask,:),3)+mean(ecmwf.e(ymask,xmask,:),3))*365.25)
set(gca,'YDir','normal');
xlabel('Longitude (deg)');
ylabel('Latitude (deg)');
h = colorbar;
set(get(h,'YLabel'),'String','Mean SMB (m/year)');

figure(2); clf;
imagesc(ecmwf.lon,ecmwf.lat,mean(ecmwf.tp,3))
set(gca,'YDir','normal');
xlabel('Longitude (deg)');
ylabel('Latitude (deg)');
h = colorbar;
set(get(h,'YLabel'),'String','Mean precipitation (m/day)');

figure(3); clf;
imagesc(ecmwf.lon,ecmwf.lat,mean(ecmwf.e,3))
set(gca,'YDir','normal');
xlabel('Longitude (deg)');
ylabel('Latitude (deg)');
h = colorbar;
set(get(h,'YLabel'),'String','Mean Evaporation (m/day)');

