% script flowline_post.m
%
% Generates:
% 1. FIGURE: Geotiff plot with flowline, buffer around flowline,
%    scatter plot of queried radar points
% 2. TWO FIGURES: Plots of along track versus radar thickness and mass
%    conservation thickness
% 3. Outputs a CSV file with mass conservation, radar parameters, and
%    best-fit radar thickness [NOT DONE YET]
%
% Authors: John Paden, Levi Sedlock, Leigh Stearns

%% User Settings

shp_fn = ct_filename_gis([],'greenland/glacier_flowlines/helheim/helheim_main.shp');
radar_csv_fn = ct_filename_gis([],'greenland/glacier_flowlines/helheim/helheim_main_radar.csv');
mc_csv_fn = ct_filename_gis([],'greenland/glacier_flowlines/helheim/helheim_main_mc.csv');

geotiff_fn = ct_filename_gis([],'greenland\Landsat-7\Greenland_natural_90.tif');

data_name = 'helheim_main';

%% Automated Section

% Get WGS-84 ellipsoid constants
physical_constants;

% Load geotiff projection
proj = geotiffinfo(geotiff_fn);

% Load flowline
flowline = shaperead(shp_fn);
% Identify any NaN points in flowline
flowline.mask = isfinite(flowline.X) & isfinite(flowline.Y);
% Project flowline to geodetic coordinates
[flowline.lat,flowline.lon] = projinv(proj,flowline.X,flowline.Y);
% Determine along track position for flowline
[flowline.along_track] = geodetic_to_along_track(flowline.lat,flowline.lon);

%% Create a buffer around the flowline
max_angle = 500 / WGS84.semimajor;
max_angle_deg = max_angle * 180/pi;

[flowline.latbuffer, flowline.lonbuffer] = bufferm(flowline.lat, flowline.lon, max_angle_deg);
[flowline.xbuffer,flowline.ybuffer] = projfwd(proj,flowline.latbuffer,flowline.lonbuffer);

%% Convert bufferm to WKT polygon
% Example: 'POLYGON((-38.25483140116192 66.44313068088051,-37.87311699063848 66.40732038583339,-37.922864839206 66.28260789417318,-38.439811834265456 66.32579346233298,-39.09613390556332 66.7771718813106,-38.80410594754223 66.80604399439443,-38.25483140116192 66.44313068088051))';
WKT_polygon = [sprintf('POLYGON(('), ...
  sprintf('%0.14g %0.14g,',[flowline.lonbuffer(1:end-1).'; flowline.latbuffer(1:end-1).']), ...
  sprintf('%0.14g %0.14g',[flowline.lonbuffer(end).'; flowline.latbuffer(end).']), ...
  sprintf('))')]

%% Get radar points from OPS
sys = 'rds';
param = [];
param.properties.location = 'arctic';
param.properties.bound = WKT_polygon;
fprintf('Getting points. This may take a minute (%s)\n', datestr(now));
[status,data] = opsGetPointsWithinPolygon(sys,param);
fprintf('  Done (%s)\n', datestr(now));

[data.properties.X,data.properties.Y] = projfwd(proj,data.properties.Lat,data.properties.Lon);

data.properties.thickness = data.properties.Bottom - data.properties.Surface;

% Determine bad point mask
mask = isfinite(data.properties.Bottom - data.properties.Surface);

%% Create map figure
[~,h_fig] = plot_geotiff(geotiff_fn);
h_axes = get(h_fig,'Children');
h_image = get(h_axes,'Children');
hold on;
plot(flowline.X/1e3,flowline.Y/1e3,'k');
scatter(data.properties.X(mask)/1e3, data.properties.Y(mask)/1e3, [], data.properties.Bottom(mask) - data.properties.Surface(mask),'.');
plot(flowline.xbuffer/1e3,flowline.ybuffer/1e3,'k');
h_colorbar = colorbar;
set(get(h_colorbar,'YLabel'),'String','Thickness (m)')

axis([240 330 -2590 -2520]);
axis normal;
xlabel('X (km)');
ylabel('Y (km)');

clip_and_resample_image(h_image,h_axes,10);

saveas(h_fig,sprintf('~/flowline_%s_map.fig',data_name));
saveas(h_fig,sprintf('~/flowline_%s_map.png',data_name));

%% Find the closest point on the flowline for each radar position
[d_min, x_d_min, y_d_min, is_vertex, idx_c, xc, yc, is_in_seg, Cer, Ppr] ...
  = p_poly_dist(data.properties.X, data.properties.Y, flowline.X, flowline.Y);
np = length(d_min);
d_min = Ppr(2,(1:np) + np*(idx_c(1:np).'-1));

% For each radar point, n, find its along track position on the flowline
data.properties.along_track = zeros(1,length(data.properties.X));
for n = 1:length(data.properties.X)
  data.properties.along_track(n) = flowline.along_track(idx_c(n)) ...
    + sqrt( (x_d_min(n)-flowline.X(idx_c(n)))^2 + (y_d_min(n)-flowline.Y(idx_c(n)))^2 );
end

%% Load mass conservation netcdf
mc_fn = ct_filename_gis([],fullfile('greenland','mass_conservation','MCdataset-2015-03-12.nc'));

mc.x = ncread(mc_fn,'x');
mc.y = ncread(mc_fn,'y');
mc.surf = ncread(mc_fn,'surface');
mc.thick = ncread(mc_fn,'thickness');
mc.bottom = ncread(mc_fn,'bed');
% Transpose matrices so that X-axis is along the 2nd dimension and y-axis
% is long the 1st dimension (required for plotting with imagesc)
mc.surf = mc.surf.';
mc.thick = mc.thick.';
mc.bottom = mc.bottom.';

% Create projection structure for the mc_fn netcdf
proj = [];
proj.CornerCoords = [];
proj.Ellipsoid = [];
proj.PM = [];
proj.PMLongToGreenwich = [];
proj.Zone = [];
geoid = almanac('earth','WGS84','m');
proj.SemiMajor = geoid(1);
proj.SemiMinor = minaxis(geoid);
proj.ProjParm = zeros(7,1);
proj.ProjParm(1) = ncreadatt(mc_fn,'polar_stereographic','standard_parallel');
proj.ProjParm(2) = ncreadatt(mc_fn,'polar_stereographic','straight_vertical_longitude_from_pole');
proj.ProjParm(3) = 0;
proj.ProjParm(4) = 0;
proj.ProjParm(5) = 1;
proj.ProjParm(6) = ncreadatt(mc_fn,'polar_stereographic','false_easting');
proj.ProjParm(7) = ncreadatt(mc_fn,'polar_stereographic','false_northing');
proj.CTProjection = 'CT_PolarStereographic';
proj.GeoTIFFCodes.CTProjection = 15;

proj.GeoTIFFCodes.Model = int16(1);
proj.GeoTIFFCodes.PCS = int16(32767);
proj.GeoTIFFCodes.GCS = int16(32767);
proj.GeoTIFFCodes.UOMAngle = int16(32767);
proj.GeoTIFFCodes.Datum = int16(32767);
proj.GeoTIFFCodes.PM = int16(32767);
proj.GeoTIFFCodes.ProjCode = int16(32767);
proj.GeoTIFFCodes.Projection= int16(32767);
proj.GeoTIFFCodes.MapSys = int16(32767);
proj.GeoTIFFCodes.UOMLength = int16(9001);

% Interpolat the flowline to max 100 m steps
max_angle = 100 / WGS84.semimajor;
max_angle_deg = max_angle * 180/pi;
[flowline.latM,flowline.lonM] = interpm(flowline.lat,flowline.lon,max_angle_deg);
[flowline.XM,flowline.YM] = projfwd(proj,flowline.latM,flowline.lonM);
flowline.along_trackM = geodetic_to_along_track(flowline.latM,flowline.lonM);

% Interpolate the mass conservation grid onto the flowline
[mc.xmesh,mc.ymesh] = meshgrid(mc.x,mc.y);
flowline.mc_thick = interp2(single(mc.xmesh),single(mc.ymesh),single(mc.thick),flowline.XM,flowline.YM);
flowline.mc_surf = interp2(single(mc.xmesh),single(mc.ymesh),single(mc.surf),flowline.XM,flowline.YM);
flowline.mc_bottom = interp2(single(mc.xmesh),single(mc.ymesh),single(mc.bottom),flowline.XM,flowline.YM);

%% Create along track versus thickness figures
h_fig = figure;
scatter(data.properties.along_track(mask)/1e3, ...
  data.properties.thickness(mask),[],d_min(mask), '.');
hold on;
plot(flowline.along_trackM/1e3, flowline.mc_thick,'k');
h_colorbar = colorbar;
set(get(h_colorbar,'YLabel'),'String','Distance from flowline (m)');
xlabel('Along flowline (km)');
ylabel('Thickness (m)');
xlim([0 80]);
ylim([-50 2000]);
grid on;
legend('Radar','Mass conservation','location','best')

saveas(h_fig,sprintf('~/flowline_%s_distance.fig',data_name));
saveas(h_fig,sprintf('~/flowline_%s_distance.png',data_name));

h_fig = figure;
scatter(data.properties.along_track(mask)/1e3, ...
  data.properties.thickness(mask),[],data.properties.thickness(mask), '.');
hold on;
plot(flowline.along_trackM/1e3, flowline.mc_thick,'k');
h_colorbar = colorbar;
set(get(h_colorbar,'YLabel'),'String','Thickness (m)');
xlabel('Along flowline (km)');
ylabel('Thickness (m)');
xlim([0 80]);
ylim([-50 2000]);
grid on;
legend('Radar','Mass conservation','location','best')

saveas(h_fig,sprintf('~/flowline_%s_thickness.fig',data_name));
saveas(h_fig,sprintf('~/flowline_%s_thickness.png',data_name));

[fid,msg] = fopen(mc_csv_fn,'w');
if fid<0
  error('Could not open %s: %s\n', mc_csv_fn, msg);
end

fprintf(fid,'Latitude,Longitude,X,Y,Surface_Elevation,Bottom_Elevation,Flowline_Alongtrack\n');
for idx = 1:length(flowline.along_track)
  fprintf(fid,'%.7f,%.7f,%.1f,%.1f,%.1f,%.1f,%.1f\n', ...
    flowline.latM(idx),flowline.lonM(idx),flowline.XM(idx),flowline.YM(idx), ...
    flowline.mc_surf(idx),flowline.mc_bottom(idx),flowline.along_trackM(idx));
end

fclose(fid);

%% Create CSV files for radar points and for mass conservation points
% Geodetic coordinates

%                 Lat: [1x32819 double]
%                 Lon: [1x32819 double]
%           Elevation: [1x32819 double]
%            Gps_Time: [1x32819 double]
%             Surface: [1x32819 double]
%              Bottom: [1x32819 double]
%           Thickness: [1x32819 double]
%     Surface_Quality: [1x32819 int32]
%      Bottom_Quality: [1x32819 int32]
%              Season: {32819x1 cell}
%               Frame: {32819x1 cell}
%                   X: [1x32819 double]
%                   Y: [1x32819 double]
%           thickness: [1x32819 double]
%         along_track: [1x32819 double]

% HACK:
mask = mask & ~strcmp(data.properties.Season,'2005_Greenland_TO').';

lat = data.properties.Lat(mask);
lon = data.properties.Lon(mask);
elev = data.properties.Elevation(mask);
gps_time = data.properties.Gps_Time(mask);
surf = data.properties.Elevation(mask) - data.properties.Surface(mask);
bottom = data.properties.Elevation(mask) - data.properties.Bottom(mask);
quality = data.properties.Bottom_Quality(mask);
season = data.properties.Season(mask);
frm_id = data.properties.Frame(mask);
x = data.properties.X(mask);
y = data.properties.Y(mask);
along_track = data.properties.along_track(mask);
d_min_masked = d_min(mask);

[along_track,sort_idxs] = sort(along_track);
lat = lat(sort_idxs);
lon = lon(sort_idxs);
elev = elev(sort_idxs);
gps_time = gps_time(sort_idxs);
surf = surf(sort_idxs);
bottom = bottom(sort_idxs);
quality = quality(sort_idxs);
season = season(sort_idxs);
frm_id = frm_id(sort_idxs);
x = x(sort_idxs);
y = y(sort_idxs);
d_min_masked = d_min_masked(sort_idxs);

[fid,msg] = fopen(radar_csv_fn,'w');
if fid<0
  error('Could not open %s: %s\n', radar_csv_fn, msg);
end

fprintf(fid,'Latitude,Longitude,X,Y,Elevation,Date,Time_SOD,Surface_Elevation,Bottom_Elevation,Quality,Season,Frame,Flowline_Alongtrack,Flowline_Distance\n');
sod = epoch_to_sod(gps_time);
for idx = 1:length(lat)
  fprintf(fid,'%.7f,%.7f,%.1f,%.1f,%.1f,%s,%.3f,%.1f,%.1f,%.0f,%s,%s,%.1f,%.1f\n', ...
    lat(idx),lon(idx),x(idx),y(idx),elev(idx),datestr(epoch_to_datenum(gps_time(idx)),'YYYYmmDD'), ...
    sod(idx),surf(idx),bottom(idx),quality(idx),season{idx},frm_id{idx}, ...
    along_track(idx),d_min_masked(idx));
end

fclose(fid);
