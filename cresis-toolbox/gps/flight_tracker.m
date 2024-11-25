% script flight_tracker
%
% Flight tracker which reads in a NMEA stream (GPGGA) from a serial device
% or a file that is being recorded (by the radar for example) and plots the
% result on a geotiff.
%
% Example of loading KML and old datasets given.
%
% Close plotting window or press ctrl-C (multiple times rapidly!)
% to quit.  Serial device is stored in global variable,
% gflight_tracker.serial_dev, so that you can close it if the program
% fails to do so.
%
% Requires Mapping Toolbox, read_xml.m, geotiff_plot.m
%
% Examples:
%   flight_tracker
%
% Author: John Paden

global gRadar;
global gflight_tracker;
physical_constants;

%% User Settings
% =================================================================

% geotiff_fn: String containing file path for geotiff file for map
% geotiff_fn = fullfile(gRadar.gis_path,'arctic','NaturalEarth_Data\Arctic_NaturalEarth.tif'); % For Sea Ice
% geotiff_fn = fullfile(gRadar.gis_path,'arctic','Landsat-7','arctic_natural_90m.tif'); % For Land Ice
% geotiff_fn = fullfile(gRadar.gis_path,'arctic','ArcticDEM','arcticdem_mosaic_500m_v3.0.tif'); % For Land Ice
geotiff_fn = fullfile(gRadar.gis_path,'antarctica','Landsat-7','Antarctica_LIMA.tif'); % For Land Ice

% dem_fn: String containing file path for DEM
% dem_fn = fullfile(gRadar.gis_path,'arctic','ArcticDEM','arcticdem_mosaic_500m_v3.0.tif');
dem_fn = fullfile(gRadar.gis_path,'antarctica','DEM','REMA','REMA_1km_dem_filled.tif');

% gps_input_type: String containing GPS source
gps_input_type = 'file_novatelraw'; % 'file_novatelraw', 'file_mcords', 'file_accum', or 'serial'

% serial_dev: String containing the name of the serial device for 'serial'
% gps_input_type.
%
% On Linux, you may have to give file permissions from the bash terminal to
% allow the serial device to be opened: "sudo chmod a+rwx /dev/ttyS0"
serial_dev = '/dev/ttyUSB0';
% serial_dev = '/dev/ttyUSB1';
% serial_dev = '/dev/ttyS0';

% serial_serial_baud_rate: integer scaler containing BAUD rate for 'serial'
% gps_input_type.
serial_baud_rate = 115200; % e.g. 9600, 57600, 115200, etc.

% gps_input_fn_dir: string containing the file path to the directory
% containing the GPS file for 'file_mcords' and 'file_accum'
% gps_input_type.
% gps_input_fn_dir = '\\192.168.1.100\d\awi';
gps_input_fn_dir = '/data/';
% gps_input_fn_dir = '\\ground1\O\UWB\20220607';
gps_input_fn_prefix = 'GPS_Novatel_raw_aq-field22_20230124';

% gps_input_geoid_en: logical scaler. If true, the EGM-96 geoid is
% subtracted from GPS information that is read in.
gps_input_geoid_en = false;

% gps_input_fn_skip: logical scaler for 'file_mcords' and 'file_accum'
% gps_input_type. Normally false. If true, all information in existing GPS
% files will be ignored and only new information will be used by
% flight_tracker.m.
%
% Enables skipping reading old data, sometimes need to do this if files
% contain errors that cause flight_tracker.m to crash.
gps_input_fn_skip = false;

% gps_record_en: Logical scaler. If true, then this program will record
% the GPS information it receives to a file.
gps_record_en = false;

% gps_record_fn_dir: String containing the path to the directory of where
% to store the GPS information. Only used if gps_record_en is true.
gps_record_fn_dir = '/home/cresis1/tmp/';

% year,month,day: Usually do not need to modify this
[year,month,day] = datevec(now);
gps_start_ref = datenum(year,month,day);

% debug_start_line: positive integer scaler. Set to inf to disable debug
% mode, set to a finite number to load this many lines from the GPS source
% file. Only works with 'file_mcords' and 'file_accum' gps_input_type.
debug_start_line = inf; % <== Set to "inf" to disable debug mode

%% User Settings: Desired flight track
% gps_desire.en: Logical scaler. If true, load desired flight track. Set to
% false if no desired flight track exists.
gps_desire = struct('en',true);
if gps_desire.en
  gps_desire_source = 'sonntagsequence2'; % <== CHOOSE A DESIRED FLIGHT TRACK SOURCE

  if strcmpi(gps_desire_source,'records')
    %% User Settings: Desired flight track: records
    gps_desire = records_load(fullfile(gRadar.support_path,'records','rds','2018_Greenland_Polar6','records_20180509_01'));
    gps_desire.along_track = geodetic_to_along_track(gps_desire.lat,gps_desire.lon,gps_desire.elev);
    decim_idxs = get_equal_alongtrack_spacing_idxs(gps_desire.along_track,50);
    gps_desire.lat = gps_desire.lat(decim_idxs);
    gps_desire.lon = gps_desire.lon(decim_idxs);
    gps_desire.elev = gps_desire.elev(decim_idxs);
    [gps_desire.ecef_x,gps_desire.ecef_y,gps_desire.ecef_z] = geodetic2ecef(gps_desire.lat/180*pi,gps_desire.lon/180*pi,gps_desire.elev, WGS84.ellipsoid);

  elseif strcmpi(gps_desire_source,'sonntagsequence2')
    gps_desire = read_gps_sonntagsequence2(fullfile(gRadar.data_support_path,'2022_Antarctica_BaslerMKB','F16','CLX_EAST02A_5HR.sequence2'));
    gps_desire.along_track = geodetic_to_along_track(gps_desire.lat,gps_desire.lon,gps_desire.elev);
    decim_idxs = get_equal_alongtrack_spacing_idxs(gps_desire.along_track,50);
    gps_desire.lat = gps_desire.lat(decim_idxs);
    gps_desire.lon = gps_desire.lon(decim_idxs);
    gps_desire.elev = gps_desire.elev(decim_idxs);

    [gps_desire.ecef_x,gps_desire.ecef_y,gps_desire.ecef_z] = geodetic2ecef(gps_desire.lat/180*pi,gps_desire.lon/180*pi,gps_desire.elev, WGS84.ellipsoid);

    orig_lat = gps_desire.lat;
    orig_lon = gps_desire.lon;
    [gps_desire.lat,gps_desire.lon] = interpm(gps_desire.lat,gps_desire.lon,450/(2*pi*earthRadius),'gc');
    % Find original points
    gps_desire.orig_pnt = false(size(gps_desire.lat));
    for idx = 1:length(orig_lat)
      match_idx = find(gps_desire.lat == orig_lat(idx) & gps_desire.lon == orig_lon(idx));
      gps_desire.orig_pnt(match_idx) = true;
    end
    gps_desire.along_track = geodetic_to_along_track(gps_desire.lat,gps_desire.lon);
    %     decim_idxs = get_equal_alongtrack_spacing_idxs(gps_desire.along_track,50);
    %     gps_desire.along_track = gps_desire.along_track(decim_idxs);
    %     gps_desire.lat = gps_desire.lat(decim_idxs);
    %     gps_desire.lon = gps_desire.lon(decim_idxs);

    % gps_desire.constant_AGL_en: logical scaler. If true, then dem_fn will
    % be used to set the elevation according to constant_AGL_ft.
    constant_AGL_en = true;
    % gps_desire.constant_AGL_ft: double scaler. The gps_desire.elev will
    % be set to be this many feet above the dem_fn surface if
    % constant_AGL_en is true.
    constant_AGL_ft = 2000;

  elseif strcmpi(gps_desire_source,'kml_simple')
    %% User Settings: Desired flight track: kml_simple
    % NOTE: This KML example only works for some KML file types.
    % Simple KML file
    % kml_fn = 'C:\metadata\2022_Greenland_Polar5\flight_lines\AdditionalSounding1.kml';
    % kml_fn = 'C:\metadata\2022_Greenland_Polar5\flight_lines\Additional_Soundings_2_new.kml';
    kml_fn = 'C:\metadata\2022_Greenland_Polar5\flight_lines\Bons_A.kml';
    xDoc = xmlread(kml_fn);
    document = read_xml(xDoc);
    if isfield(document.kml{1}.Document{1},'Placemark')
      pos = textscan(document.kml{1}.Document{1}.Placemark{1}.LineString{1}.coordinates{1}.text{1}.node_val, ...
        '%f%f%f','Delimiter',',');
    elseif isfield(document.kml{1}.Document{1}.Folder{1},'Placemark')
      if length(document.kml{1}.Document{1}.Folder{1}.Placemark) == 1
        pos = textscan(document.kml{1}.Document{1}.Folder{1}.Placemark{1}.LineString{1}.coordinates{1}.text{1}.node_val, ...
          '%f%f','Delimiter',', ');
      else
        pos{1} = [];
        pos{2} = [];
        for idx = 1:length(document.kml{1}.Document{1}.Folder{1}.Placemark)
          tmp_pos = textscan(document.kml{1}.Document{1}.Folder{1}.Placemark{idx}.Point{1}.coordinates{1}.text{1}.node_val, ...
            '%f%f','Delimiter',', ');
          pos{1}(end+1) = tmp_pos{1};
          pos{2}(end+1) = tmp_pos{2};
        end
      end
    else
      error('Not able to find "Placemark" field that probably contains the LineString field that should be read.');
    end
    gps_desire.lon = pos{1};
    gps_desire.lat = pos{2};
    clear xDoc document;

    orig_lat = gps_desire.lat;
    orig_lon = gps_desire.lon;
    [gps_desire.lat,gps_desire.lon] = interpm(gps_desire.lat,gps_desire.lon,50/(2*pi*earthRadius),'gc');
    % Find original points
    gps_desire.orig_pnt = false(size(gps_desire.lat));
    for idx = 1:length(orig_lat)
      match_idx = find(gps_desire.lat == orig_lat(idx) & gps_desire.lon == orig_lon(idx));
      gps_desire.orig_pnt(match_idx) = true;
    end
    gps_desire.along_track = geodetic_to_along_track(gps_desire.lat,gps_desire.lon);
    %     decim_idxs = get_equal_alongtrack_spacing_idxs(gps_desire.along_track,50);
    %     gps_desire.along_track = gps_desire.along_track(decim_idxs);
    %     gps_desire.lat = gps_desire.lat(decim_idxs);
    %     gps_desire.lon = gps_desire.lon(decim_idxs);

    % gps_desire.constant_AGL_en: logical scaler. If true, then dem_fn will
    % be used to set the elevation according to constant_AGL_ft.
    constant_AGL_en = true;
    % gps_desire.constant_AGL_ft: double scaler. The gps_desire.elev will
    % be set to be this many feet above the dem_fn surface if
    % constant_AGL_en is true.
    constant_AGL_ft = 1200;

  elseif strcmpi(gps_desire_source,'kml_complex')
    %% User Settings: Desired flight track: kml_complex
    % NOTE: This KML example only works for some KML file types.
    % KML file with many named lines in it (allows for selecting one of the lines)
    kml_pos = kml_read_shapefile(kml_fn);
    if isempty(kml_mission_name)
      for idx=1:length(kml_pos)
        fprintf('%d: %s\n', idx, kml_pos(idx).name);
      end
      kml_mission_idx = input('Enter mission number: ');
    else
      kml_mission_idx = find(strcmpi(kml_mission_name,{kml_pos.name}),1);
      if isempty(kml_mission_idx)
        warning('Could not find mission "%s" in kml_pos.name .',kml_mission_name);
      end
    end
    if isempty(kml_mission_idx)
      kml_mission_name = '';
      kml_fn = '';
      kml_lon = [];
      kml_lat = [];
    else
      kml_lon = kml_pos(kml_mission_idx).X;
      kml_lat = kml_pos(kml_mission_idx).Y;
    end
    clear kml_pos kml_mission_idx;
  end
end

%% ========================================================================
%% flight_tracker
% =========================================================================

%% gflight_tracker definition
% =========================================================================
if isempty(gflight_tracker)
  gflight_tracker = struct('dem_RGB',[],'dem_proj',[],'dem_x_axis',[],'dem_y_axis',[], ...
    'serial_device',[], ...
    'lat',[],'lon',[],'elev',[],'gps_time',[],'x',[],'y',[], ...
    'h_fig',[],'h_axes',[],'h_axes_yz',[],'h_plot_yz1',[],'h_plot_yz2',[],'h_plot_yz3',[],'h_axes_dem',[],'h_plot_dem1',[],'h_plot_dem2',[]);
end

%% Geoid EGM96 Load
% =================================================================
if gps_input_geoid_en
  egm96_fn = ct_filename_gis([],'world\egm96_geoid\WW15MGH.DAC');
  [gflight_tracker.egm96_lat,gflight_tracker.egm96_lon,gflight_tracker.egm96_elev] = egm96_loader(egm96_fn);
end

%% DEM load
% =================================================================
[gflight_tracker.dem_RGB, dem_R, ~] = geotiffread(dem_fn);
gflight_tracker.dem_proj = geotiffinfo(dem_fn);
gflight_tracker.dem_x_axis = dem_R(3,1) + dem_R(2,1)*(1:size(gflight_tracker.dem_RGB,2));
gflight_tracker.dem_y_axis = dem_R(3,2) + dem_R(1,2)*(1:size(gflight_tracker.dem_RGB,1));

[dem_x,dem_y] = projfwd(gflight_tracker.dem_proj,gps_desire.lat,gps_desire.lon);
gps_desire.elev_ground = double(interp2(gflight_tracker.dem_x_axis,gflight_tracker.dem_y_axis,gflight_tracker.dem_RGB,dem_x,dem_y));
if constant_AGL_en
  gps_desire.elev = gps_desire.elev_ground + constant_AGL_ft*12*2.54/100;
end
[gps_desire.ecef_x,gps_desire.ecef_y,gps_desire.ecef_z] = geodetic2ecef(gps_desire.lat/180*pi,gps_desire.lon/180*pi,gps_desire.elev, WGS84.ellipsoid);

%% Get plot figure handles
% =========================================================================
% h_fig(1): geotiff map with flightlines plotted on it (also displays the
% current status information)
% h_fig(2): Elevation plot
% h_fig(3): YZ-offset from line (plot of last 10 seconds, estimate of next
% 10 seconds based on current heading)
%   KML used for YZ-offset (resampled to 100 m) or gps source (e.g. gps or
%   records file from a previous flight)
gflight_tracker.h_fig = get_figures(3,true);
set(gflight_tracker.h_fig,'DockControls','off')
set(gflight_tracker.h_fig,'NumberTitle','off');
set(gflight_tracker.h_fig,'MenuBar','none');
set(gflight_tracker.h_fig(2:3),'ToolBar','none');
clf(gflight_tracker.h_fig(2));
clf(gflight_tracker.h_fig(3));
set(gflight_tracker.h_fig(1),'ToolBar','figure');
if strcmpi(class(gflight_tracker.h_fig(1)),'double')
  set(gflight_tracker.h_fig(1),'Name',sprintf('%d: map',gflight_tracker.h_fig(1)));
else
  set(gflight_tracker.h_fig(1),'Name',sprintf('%d: map',gflight_tracker.h_fig(1).Number));
end
if strcmpi(class(gflight_tracker.h_fig(2)),'double')
  set(gflight_tracker.h_fig(2),'Name',sprintf('%d: offset',gflight_tracker.h_fig(2)));
else
  set(gflight_tracker.h_fig(2),'Name',sprintf('%d: offset',gflight_tracker.h_fig(2).Number));
end
if strcmpi(class(gflight_tracker.h_fig(3)),'double')
  set(gflight_tracker.h_fig(3),'Name',sprintf('%d: elev',gflight_tracker.h_fig(3)));
else
  set(gflight_tracker.h_fig(3),'Name',sprintf('%d: elev',gflight_tracker.h_fig(3).Number));
end

gflight_tracker.h_axes_yz = axes('parent',gflight_tracker.h_fig(2));
hold(gflight_tracker.h_axes_yz,'on');
grid(gflight_tracker.h_axes_yz,'on');
gflight_tracker.h_plot_yz1 = plot(NaN,NaN,'x-','parent',gflight_tracker.h_axes_yz,'linewidth',2,'color','white');
gflight_tracker.h_plot_yz3 = plot(NaN,NaN,'o-','markersize',6,'linewidth',1,'parent',gflight_tracker.h_axes_yz,'color','green');
gflight_tracker.h_plot_yz2 = plot(NaN,NaN,'o','markersize',12,'linewidth',4,'parent',gflight_tracker.h_axes_yz,'color','white');
xlabel(gflight_tracker.h_axes_yz,'Horizontal (ft)')
ylabel(gflight_tracker.h_axes_yz,'Elevation (ft)')
plot(gflight_tracker.h_axes_yz,[-1e5 1e5],[0 0],'m','LineWidth',2);
plot(gflight_tracker.h_axes_yz,[0 0],[-1e5 1e5],'m','LineWidth',2);
xlims_old = 50;
ylims_old = 50;
set(gflight_tracker.h_axes_yz,'FontSize',14)

gflight_tracker.h_axes_dem = subplot(2,1,1,'parent',gflight_tracker.h_fig(3));
gflight_tracker.h_axes_dem_all = subplot(2,1,2,'parent',gflight_tracker.h_fig(3));
hold(gflight_tracker.h_axes_dem,'on');
grid(gflight_tracker.h_axes_dem,'on');
gflight_tracker.h_plot_dem1 = plot(NaN,NaN,'x','parent',gflight_tracker.h_axes_dem);
gflight_tracker.h_plot_dem2 = plot(NaN,NaN,'x','parent',gflight_tracker.h_axes_dem);
xlabel(gflight_tracker.h_axes_dem,'Future (seconds)')
ylabel(gflight_tracker.h_axes_dem,'Elevation (ft)')
plot(gflight_tracker.h_axes_dem,[0 0],[-1e3 50e3],'w','LineWidth',2);
set(gflight_tracker.h_axes_dem,'FontSize',14)

set(gflight_tracker.h_fig(2),'Color','k')
set(gflight_tracker.h_axes_yz,'Color','k')
set(gflight_tracker.h_axes_yz,'GridColor','w')
set(gflight_tracker.h_axes_yz,'MinorGridColor','w')
set(gflight_tracker.h_axes_yz,'GridAlpha',0.5)
set(gflight_tracker.h_axes_yz,'XColor','w')
set(gflight_tracker.h_axes_yz,'YColor','w')
set(gflight_tracker.h_fig(3),'Color','k')
set(gflight_tracker.h_axes_dem,'Color','k')
set(gflight_tracker.h_axes_dem,'GridColor','w')
set(gflight_tracker.h_axes_dem,'MinorGridColor','w')
set(gflight_tracker.h_axes_dem,'GridAlpha',0.5)
set(gflight_tracker.h_axes_dem,'XColor','w')
set(gflight_tracker.h_axes_dem,'YColor','w')

plot(gflight_tracker.h_axes_dem_all, gps_desire.along_track/1852, gps_desire.elev_ground*100/12/2.54, 'r-','linewidth',2);
hold(gflight_tracker.h_axes_dem_all,'on');
grid(gflight_tracker.h_axes_dem_all,'on');
plot(gflight_tracker.h_axes_dem_all, gps_desire.along_track/1852, gps_desire.elev*100/12/2.54, 'm-', 'linewidth', 2);
ylim(gflight_tracker.h_axes_dem_all, ...
  [min([gps_desire.elev_ground;gps_desire.elev])*100/12/2.54, ...
  max([gps_desire.elev_ground;gps_desire.elev])*100/12/2.54])
xlim(gflight_tracker.h_axes_dem_all, gps_desire.along_track([1 end])/1852);
gflight_tracker.h_plot_dem_all = plot(gflight_tracker.h_axes_dem_all, NaN, NaN, 'w-', 'linewidth', 2);
set(gflight_tracker.h_axes_dem_all,'Color','k')
set(gflight_tracker.h_axes_dem_all,'GridColor','w')
set(gflight_tracker.h_axes_dem_all,'MinorGridColor','w')
set(gflight_tracker.h_axes_dem_all,'GridAlpha',0.5)
set(gflight_tracker.h_axes_dem_all,'XColor','w')
set(gflight_tracker.h_axes_dem_all,'YColor','w')
set(gflight_tracker.h_axes_dem_all,'FontSize',14)
xlabel(gflight_tracker.h_axes_dem_all,'Along-track (nm)')
ylabel(gflight_tracker.h_axes_dem_all,'Elevation (ft)')

%% Serial device open
% =========================================================================
if strcmpi(gps_input_type,'serial')
  if isempty(gflight_tracker.serial_dev)
    fprintf('Getting serial device %s handle\n', serial_dev);
    gflight_tracker.serial_dev = serial(serial_dev,'BaudRate',serial_baud_rate);
  end

  if ~strcmpi(get(gflight_tracker.serial_dev,'Status'),'open')
    fprintf('Opening serial device %s\n', serial_dev);
    fopen(gflight_tracker.serial_dev);
  else
    fprintf('Serial device %s already open, just going to start reading\n', ...
      serial_dev);
  end
end

%% Geotiff
% =========================================================================
fprintf('Plotting geotiff\n');
[gflight_tracker.proj,gflight_tracker.h_fig(1),gflight_tracker.h_axes,gflight_tracker.h_image] ...
  = geotiff_plot(geotiff_fn, [], [], gflight_tracker.h_fig(1),'r');
set(gflight_tracker.h_fig(1),'color','black');
set(gflight_tracker.h_axes,'color','black','xcolor','white','ycolor','white','fontsize',14);

%% Desired flight track (e.g. from previous mission)
% =========================================================================
if exist('gps_desire','var')
  fprintf('Plotting desired flight track\n')
  [gps_desire.x,gps_desire.y] = projfwd(gflight_tracker.proj,gps_desire.lat,gps_desire.lon);
  % Convert from m to km:
  gps_desire.x = gps_desire.x/1e3;
  gps_desire.y = gps_desire.y/1e3;
  hold(gflight_tracker.h_axes,'on');
  gflight_tracker.h_plot_gps_prev = plot(gps_desire.x, gps_desire.y,'parent',gflight_tracker.h_axes(1),'Color','magenta');
end

%% Plot existing flight track data
% =========================================================================
if any(strcmpi(gps_input_type,{'file_novatelraw'}))
  gflight_tracker.lat = [];
  gflight_tracker.lon = [];
  gflight_tracker.elev = [];
  gflight_tracker.gps_time = [];
  gflight_tracker.x = [];
  gflight_tracker.y = [];

  gps_in_fns = get_filenames(gps_input_fn_dir,gps_input_fn_prefix,'','.gps');
  gps_in_fn = gps_in_fns{end};
  gps_input = read_gps_novatelraw(gps_in_fn);
  gflight_tracker.lat = gps_input.lat;
  gflight_tracker.lon = gps_input.lon;
  gflight_tracker.elev = gps_input.elev;
  gflight_tracker.gps_time = gps_input.gps_time;
  [gflight_tracker.x,gflight_tracker.y] = projfwd(gflight_tracker.proj, gflight_tracker.lat, gflight_tracker.lon);
  gflight_tracker.x = gflight_tracker.x/1e3;
  gflight_tracker.y = gflight_tracker.y/1e3;

  gps_in_fn_pos = dir(gps_in_fn);
  gps_in_fn_pos = gps_in_fn_pos.bytes;

end
if any(strcmpi(gps_input_type,{'file_accum','file_mcords'}))
  gflight_tracker.lat = [];
  gflight_tracker.lon = [];
  gflight_tracker.elev = [];
  gflight_tracker.gps_time = [];
  gflight_tracker.x = [];
  gflight_tracker.y = [];
  % Look for, load, and plot all GPS files
  if strcmpi(gps_input_type,'file_accum')
    gps_input_fn_ext = '.gps';
  else
    gps_input_fn_ext = '.txt';
  end

  % Monitoring:
  % Look for the latest GPS file
  % If there is no file, skip steps
  % If newest file matches the current file, then keep current position
  % Load latest file and search for '$'
  if ~gps_input_fn_skip
    gps_in_fns = get_filenames(gps_input_fn_dir,'','',gps_input_fn_ext);
    if isempty(gps_in_fns)
      warning('No GPS files in %s\n', gps_input_fn_dir);
    else
      gps_param = struct('year',year,'month',month,'day',day,'time_reference','utc','format',3);
      for gps_in_fn_idx = 1:length(gps_in_fns)
        gps_in_fn = gps_in_fns{gps_in_fn_idx};
        fid = fopen(gps_in_fn,'r');
        debug_num_lines = 0;
        while ~feof(fid) && debug_num_lines < debug_start_line
          line_input = fgets(fid);
          if feof(fid)
            break;
          end
          A = textscan(line_input,'%s%f%f%c%f%c%u%u%f%f%c%f%c%s%s%f%f%f%f','delimiter',', ','emptyvalue',NaN);
          try
            if all(~cellfun(@isempty,A([1 2 3 4 5 6 10]))) && strcmp(A{1},'$GPGGA') && ~isnan(A{3}) && any(strcmpi(A{4},{'N','S'})) && ~isnan(A{5}) && any(strcmpi(A{6},{'W','E'}))
              hour = floor(A{2}/1e4);
              minute = floor((A{2}-hour*1e4)/1e2);
              sec= A{2}-hour*1e4-minute*1e2;
              gflight_tracker.gps_time(1,end+1) = gps_start_ref + hour/24 + minute/1440 + sec/86400;
              gflight_tracker.lat(1,end+1) = ((A{4}=='N')*2-1) .* A{3};
              gflight_tracker.lon(1,end+1) = ((A{6}=='E')*2-1) .* A{5};
              gflight_tracker.elev(1,end+1) = A{10};
            end
          end
          debug_num_lines = debug_num_lines + 1;
          gps_in_fn_pos = ftell(fid);
        end
        fclose(fid);
      end
      gflight_tracker.lat = fix(gflight_tracker.lat/100) + (gflight_tracker.lat/100 - fix(gflight_tracker.lat/100))./60*100;
      gflight_tracker.lon = fix(gflight_tracker.lon/100) + (gflight_tracker.lon/100 - fix(gflight_tracker.lon/100))./60*100;
      [gflight_tracker.x,gflight_tracker.y] = projfwd(gflight_tracker.proj, gflight_tracker.lat, gflight_tracker.lon);
      gflight_tracker.x = gflight_tracker.x/1e3;
      gflight_tracker.y = gflight_tracker.y/1e3;
    end
  end
  if debug_start_line == inf;
    gps_in_fn = '';
    gps_in_fn_pos = -inf;
  end
end

%% Plotting existing flight track data recorded by flight_tracker.m
% =========================================================================
if gps_record_en
  gps_fn = fullfile(gps_record_fn_dir,sprintf('gps_%04d%02d%02d.csv',year,month,day));
  if exist(gps_fn,'file')
    try
      gps = read_gps_csv(gps_fn, struct('time_reference','utc'));
      [x,y] = projfwd(gflight_tracker.proj,gps.lat,gps.lon);
      x = x/1e3;
      y = y/1e3;
      idx_to_use = max(1,length(x)-size(pos_buf,1)+1) : length(x);
      pos_buf(1:length(idx_to_use),1) = fliplr(x(idx_to_use));
      pos_buf(1:length(idx_to_use),2) = fliplr(y(idx_to_use));
      set(hline,'XData',pos_buf(:,1));
      set(hline,'YData',pos_buf(:,2));
      set(hpos,'XData',pos_buf(1,1));
      set(hpos,'YData',pos_buf(1,2));
      drawnow;
      pos_buf(2:end,:) = pos_buf(1:end-1,:);
    catch
    end
  end

  %% Plotting existing flight track data: Open log file
  % ===========================================================
  fprintf('Opening GPS log file %s\n', gps_fn);
  [gflight_tracker.fid_out,msg] = fopen(gps_fn,'a');
  if fid_out <= 0
    error(msg);
  end
  if ftell(gflight_tracker.fid_out) == 0
    % Write header line if file is empty
    fprintf('  New file, writing CSV header line\n');
    fprintf(gflight_tracker.fid_out,'year,month,day,UTC_sod,latNdeg,lonEdeg,elevm\n');
  end
end

hold(gflight_tracker.h_axes,'on');
gflight_tracker.h_line= plot(gflight_tracker.x,gflight_tracker.y,'b-','Parent',gflight_tracker.h_axes);
gflight_tracker.h_plot = plot(gflight_tracker.x(end),gflight_tracker.y(end),'rx','MarkerSize',10,'LineWidth',3,'Parent',gflight_tracker.h_axes);
hold(gflight_tracker.h_axes,'off');

% update_geotiff_tstart: timer to force map to update XY axes every 30
% seconds to the current position
update_geotiff_tstart = uint64(0);
update_plot_tstart = uint64(0);

%% Loop for new data
% =========================================================================
% try
done = false;
nmea_dollarsign_synced = false;
while ~done
  %% Loop for new data: Load GPS data from serial
  % =====================================================================
  if strcmpi(gps_input_type,'serial')
    try
      nmea_str = fscanf(gflight_tracker.serial_dev);
    catch ME
      pause(0.5);
      continue;
    end
    if isempty(nmea_str)
      fprintf('Empty string\n');
      pause(0.5);
      continue;
    end
    A = textscan(nmea_str,'%s%f%f%c%f%c%u%u%f%f%c%f%c%s%s','delimiter',',','emptyvalue',NaN);
    clear nmea_str;
  end

  %% Loop for new data: Load GPS data from file
  % =====================================================================
  if any(strcmpi(gps_input_type,{'file_novatelraw'}))
    % Load in the last BESTPOSB record in the file
    gps_in_fns = get_filenames(gps_input_fn_dir,gps_input_fn_prefix,'','.gps');
    if ~isempty(gps_in_fns)
      if ~strcmpi(gps_in_fn,gps_in_fns{end})
        gps_in_fn = gps_in_fns{end};
        gps_in_fn_pos = 0;
      end
      gps = read_gps_novatelraw(gps_in_fn,struct('first_byte',gps_in_fn_pos));

      if ~isempty(gps.gps_time)
        gps_in_fn_pos = dir(gps_in_fn);
        gps_in_fn_pos = gps_in_fn_pos.bytes;
        gflight_tracker.lat(end+(1:length(gps.gps_time))) = gps.lat;
        gflight_tracker.lon(end+(1:length(gps.gps_time))) = gps.lon;
        gflight_tracker.elev(end+(1:length(gps.gps_time))) = gps.elev;
        if gps_input_geoid_en
          gflight_tracker.elev(end) = gflight_tracker.elev(end) ...
            + interp2(gflight_tracker.egm96_lon,gflight_tracker.egm96_lat,gflight_tracker.egm96_elev, ...
            mod(gflight_tracker.lon(end),360),gflight_tracker.lat(end));
        end
        gflight_tracker.gps_time(end+(1:length(gps.gps_time))) = gps.gps_time;
        [x,y] = projfwd(gflight_tracker.proj,gps.lat,gps.lon);
        gflight_tracker.x(end+(1:length(gps.gps_time))) = x/1e3;
        gflight_tracker.y(end+(1:length(gps.gps_time))) = y/1e3;
        set(gflight_tracker.h_line,'XData',gflight_tracker.x,'YData',gflight_tracker.y);
        set(gflight_tracker.h_plot,'XData',gflight_tracker.x(end),'YData',gflight_tracker.y(end));
        drawnow;
      end

      %       if length(lat) > 10
      %         along_track = geodetic_to_along_track(lat(end-9:end),lon(end-9:end),elev(end-9:end));
      %         speed = along_track(end) / abs(utc_time(end)-utc_time(end-9));
      %       end
      %       fprintf('%9.6f N %11.6f E | %6.1f m | %6.1f m AGL | %3.0f m/s %3.0f kn\n', lat, lon, elev, elev-dem_elev, speed, speed/0.5144444);

      if gps_record_en
        fprintf(fid_out,'%04d,%02d,%02d,%f,%f,%f,%f\n', year, month, day, utc_sod, lat, lon, elev);
      end
    end
  end

  if any(strcmpi(gps_input_type,{'file_accum','file_mcords'}))
    % Look for, load, and plot all GPS files
    if strcmpi(gps_input_type,'file_accum')
      gps_input_fn_ext = '.gps';
    else
      gps_input_fn_ext = '.txt';
    end
    % Check to see if we are looking at the most recent GPS file
    gps_in_fns = get_filenames(gps_input_fn_dir,gps_input_fn_prefix,'',gps_input_fn_ext);
    if ~isempty(gps_in_fns)
      if ~strcmpi(gps_in_fn,gps_in_fns{end})
        % New GPS file so set the current gps file to the last in the
        % list
        gps_in_fn = gps_in_fns{end};
        nmea_dollarsign_synced = false;

        % Find the last dollar sign '$' in the file
        fid = fopen(gps_in_fn,'r');
        fseek(fid,0,1); % Seek to end of file
        gps_in_fn_pos = ftell(fid)-1;
        while ~nmea_dollarsign_synced
          if ftell(fid) == 0
            % Last GPS file does not contain '$', this may be because the
            % file is just getting written to for the first time. Try to
            % read the file again on the next time around.
            break;
          end
          % Go back 1 character in the file
          fseek(fid,-1,0);
          % Read the character
          A = fread(fid,1,'char');
          if A == '$'
            % Found $
            gps_in_fn_pos = ftell(fid)-1;
            nmea_dollarsign_synced = true;
            break;
          else
            % Character is not $, so go back one more character
            fseek(fid,-1,0);
          end
        end
        fclose(fid);
      end

      fid = fopen(gps_in_fn,'r');
      fseek(fid,gps_in_fn_pos,-1);
      if ~nmea_dollarsign_synced
        % Search forward for a dollar sign character
        while ~feof(fid)
          test_char = fread(fid,1,'char');
          if test_char=='$'
            nmea_dollarsign_synced = true;
            gps_in_fn_pos = ftell(fid)-1;
            break;
          end
        end
      end
      if ~nmea_dollarsign_synced
        pause(0.5);
      else
        % We have a valid file position handle pointing at the '$'
        % character at the start of a NMEA string.
        fseek(fid,gps_in_fn_pos,-1);
        nmea_str = fgets(fid);
        if nmea_str(end) ~= 10 && nmea_str(end) ~= 13
          % End of file since nmea_str is not terminated in a end of line
          % character (10 or 13).
          % End of file, try again on the next loop and maybe some new
          % data has been written to the file by then.
          A = {''};
          pause(0.5);
        else
          % fgets terminated in an end of line character
          A = textscan(nmea_str,'%s%f%f%c%f%c%u%u%f%f%c%f%c%s%s%f%f%f%f','delimiter',',','emptyvalue',NaN);
          A{1} = A{1}{1};

          test_char = fread(fid,1,'char');
          if isempty(test_char)
            % End of file, try again on the next loop and maybe some new
            % data has been written to the file by then.
            gps_in_fn_pos = ftell(fid);
            nmea_dollarsign_synced = false;
            pause(0.5);
          elseif  test_char ~= '$'
            % Bad line, throw away previous result just in case.
            gps_in_fn_pos = ftell(fid);
            nmea_dollarsign_synced = false;
            A = {''};
          else
            gps_in_fn_pos = ftell(fid)-1;
          end
        end
      end
      fclose(fid);
    end
  end

  %% Loop for new data: Interpret NMEA string
  % =====================================================================
  if ~strcmpi(gps_input_type,'file_novatelraw') ...
      && length(A) >= 10 && strcmpi(A{1},'$GPGGA')
    lat_deg = floor(A{3}/100);
    lat_min = A{3}-lat_deg*100;
    lat = lat_deg + lat_min/60;
    if A{4} ~= 'N'
      lat = -lat;
    end
    lon_deg = floor(A{5}/100);
    lon_min = A{5}-lon_deg*100;
    lon = lon_deg + lon_min/60;
    if A{6} ~= 'E'
      lon = -lon;
    end
    hour = floor(A{2}/1e4);
    minute = floor((A{2}-hour*1e4)/1e2);
    sec= A{2}-hour*1e4-minute*1e2;

    elev = A{10};

    utc_time = datenum(year,month,day,hour,minute,sec);
    day_start = datenum(year,month,day,0,0,0);
    utc_sod = (utc_time - day_start)*86400;

    if ~isempty(lat) && ~isempty(lon) && ~isempty(elev) && ~isempty(utc_time)
      gflight_tracker.lat(end+1) = lat;
      gflight_tracker.lon(end+1) = lon;
      gflight_tracker.elev(end+1) = elev;
      if gps_input_geoid_en
        gflight_tracker.elev(end) = gflight_tracker.elev(end) ...
          + interp2(gflight_tracker.egm96_lon,gflight_tracker.egm96_lat,gflight_tracker.egm96_elev, ...
          mod(gflight_tracker.lon(end),360),gflight_tracker.lat(end));
      end
      gflight_tracker.gps_time(end+1) = utc_time;
      [x,y] = projfwd(gflight_tracker.proj,gflight_tracker.lat(end),gflight_tracker.lon(end));
      gflight_tracker.x(end+1) = x/1e3;
      gflight_tracker.y(end+1) = y/1e3;
      set(gflight_tracker.h_line,'XData',gflight_tracker.x,'YData',gflight_tracker.y);
      set(gflight_tracker.h_plot,'XData',gflight_tracker.x(end),'YData',gflight_tracker.y(end));
      drawnow;
    end

    %       if length(lat) > 10
    %         along_track = geodetic_to_along_track(lat(end-9:end),lon(end-9:end),elev(end-9:end));
    %         speed = along_track(end) / abs(utc_time(end)-utc_time(end-9));
    %       end
    %       fprintf('%9.6f N %11.6f E | %6.1f m | %6.1f m AGL | %3.0f m/s %3.0f kn\n', lat, lon, elev, elev-dem_elev, speed, speed/0.5144444);

    if gps_record_en
      fprintf(fid_out,'%04d,%02d,%02d,%f,%f,%f,%f\n', year, month, day, utc_sod, lat, lon, elev);
    end
  end

  %% Loop for new data: DEM profile plot and y-z offset plot
  % =====================================================================
  if exist('gps_desire','var')
    if isfinite(debug_start_line)
      % finite debug_start_line implies we are in debug mode. Simulate
      % the regular delay between GPS updates (1 second).
      update_plot_delay = toc(update_plot_tstart);
      update_plot_tstart = tic;
      if update_plot_delay < 1
        fprintf('Delaying %.3f sec\n', update_plot_delay);
        pause(1 - update_plot_delay);
      end
    end
    num_pnts = 19;
    gps_time = gflight_tracker.gps_time(end-num_pnts:end);
    lat = gflight_tracker.lat(end-num_pnts:end);
    lon = gflight_tracker.lon(end-num_pnts:end);
    elev = gflight_tracker.elev(end-num_pnts:end);

    % Generate heading from last end-10:end-5 trajectory positions
    % Generate heading from last end-5:end trajectory positions
    [ecef_x,ecef_y,ecef_z] = geodetic2ecef(lat/180*pi,lon/180*pi,elev, WGS84.ellipsoid);

    future_x = [ecef_x(end-3:end-1), ecef_x(end) + (ecef_x(end)-ecef_x(end-1))*(0:num_pnts)/1];
    future_y = [ecef_y(end-3:end-1), ecef_y(end) + (ecef_y(end)-ecef_y(end-1))*(0:num_pnts)/1];
    future_z = [ecef_z(end-3:end-1), ecef_z(end) + (ecef_z(end)-ecef_z(end-1))*(0:num_pnts)/1];

    % Find closest point on previous trajectory
    dist = sqrt((gps_desire.ecef_x-ecef_x(end)).^2+(gps_desire.ecef_y-ecef_y(end)).^2+(gps_desire.ecef_z-ecef_z(end)).^2);
    [min_dist,min_idx] = min(dist);
    [up.ecef_x,up.ecef_y,up.ecef_z] = geodetic2ecef(gps_desire.lat(min_idx)/180*pi,gps_desire.lon(min_idx)/180*pi,gps_desire.elev(min_idx)+1, WGS84.ellipsoid);

    set(gflight_tracker.h_plot_dem_all,'XData',gps_desire.along_track(min_idx)/1852*[1 1], ...
      'YData', [-50e3 50e3]);

    % Generate FCS on previous trajectory using next N_lookahead positions
    N_lookahead = 1;
    fcs_x = [gps_desire.ecef_x(min_idx+N_lookahead) - gps_desire.ecef_x(min_idx);
      gps_desire.ecef_y(min_idx+N_lookahead) - gps_desire.ecef_y(min_idx);
      gps_desire.ecef_z(min_idx+N_lookahead) - gps_desire.ecef_z(min_idx)];
    fcs_z = [up.ecef_x(1) - gps_desire.ecef_x(min_idx);
      up.ecef_y(1) - gps_desire.ecef_y(min_idx);
      up.ecef_z(1) - gps_desire.ecef_z(min_idx)];
    fcs_x = fcs_x / sqrt(dot(fcs_x,fcs_x));
    fcs_z = fcs_z - fcs_x*dot(fcs_z,fcs_x);
    fcs_z = fcs_z / sqrt(dot(fcs_z,fcs_z));
    fcs_y = cross(fcs_z, fcs_x);
    T = [fcs_x fcs_y fcs_z];
    % Project current position into FCS x,y,z
    offset = T \ [future_x - gps_desire.ecef_x(min_idx);
      future_y - gps_desire.ecef_y(min_idx);
      future_z - gps_desire.ecef_z(min_idx)];

    set(gflight_tracker.h_plot_yz1,'XData',-offset(2,4:12)*100/12/2.54,'YData',offset(3,4:12)*100/12/2.54);
    set(gflight_tracker.h_plot_yz3,'XData',-offset(2,1:4)*100/12/2.54,'YData',offset(3,1:4)*100/12/2.54);
    set(gflight_tracker.h_plot_yz2,'XData',-offset(2,4)*100/12/2.54,'YData',offset(3,4)*100/12/2.54);

    speed = sqrt((ecef_x(end)-ecef_x(end-1)).^2+(ecef_y(end)-ecef_y(end-1)).^2+(ecef_z(end)-ecef_z(end-1)).^2) / (gps_time(end)-gps_time(end-1)) / 86400;

    distance_to_end = gps_desire.along_track(end) - gps_desire.along_track(min_idx);
    distance_to_next = gps_desire.along_track(min_idx - 1 + find(gps_desire.orig_pnt(min_idx:end),1)) - gps_desire.along_track(min_idx);

    %       if min_dist > 1000
    %         title(sprintf('Minimum distance between desired and current trajectory: %g km\n', min_dist/1e3),'parent',gflight_tracker.h_axes_yz);
    %       else
    % bearing: required change in bearing to get back on the line
    % within 9 seconds
    bearing = atan2d(offset(2,4)/9,speed) - atan2d(diff(-offset(2,3:4)),speed);
    % climb_ft_min: required change in climb to get back on the line
    % within 9 seconds
    climb_ft_min = -offset(3,4)*100/2.54/12/9*60 - diff(offset(3,3:4))*100/2.54/12*60;
    % ft/min
    % max_climb_ft_min: maximum climb rate for the given prf, presums,
    % and wavelength
    prf = 10000;
    presums = 38;
    freq = 195e6;
    max_climb_ft_min = 45/360 * 3e8/2/freq * (prf/presums)*100/12/2.54 * 60;
    if abs(climb_ft_min) > max_climb_ft_min
      climb_ft_min = max_climb_ft_min * sign(climb_ft_min);
    end
    title(sprintf('Bearing: %+5.1f deg\nClimb: %+5.1f ft/min\nY: %4.0f ft   Z: %4.0f ft\n DTE %5.1f nm   DTN: %5.1f nm', ...
      bearing, climb_ft_min, -offset(2,4)*100/2.54/12, offset(3,4)*100/2.54/12, distance_to_end/1852, distance_to_next/1852), 'parent',gflight_tracker.h_axes_yz,'FontSize',24,'FontWeight','bold','color','white');
    %       end
    % Implement hysteresis on the autoscale of the y-z plot
    xlims_tight = 50*2^(max(0,ceil(log2(max(abs(offset(2,4)))/50/0.5*100/2.54/12))));
    ylims_tight = 50*2^(max(0,ceil(log2(max(abs(offset(3,4)))/50/0.5*100/2.54/12))));
    xlims = 50*2^(max(0,ceil(log2(max(abs(offset(2,4)))/50/0.8*100/2.54/12))));
    ylims = 50*2^(max(0,ceil(log2(max(abs(offset(3,4)))/50/0.8*100/2.54/12))));
    if xlims_old > xlims_tight
      xlims_old = xlims_tight;
    elseif xlims_old < xlims
      xlims_old = xlims;
    end
    if ylims_old > ylims_tight
      ylims_old = ylims_tight;
    elseif ylims_old < ylims
      ylims_old = ylims;
    end
    xlim(gflight_tracker.h_axes_yz, xlims_old*[-1 1]);
    ylim(gflight_tracker.h_axes_yz, ylims_old*[-1 1]);

    [future_lat,future_lon,future_elev] = ecef2geodetic(future_x,future_y,future_z,WGS84.ellipsoid);
    future_lat = future_lat*180/pi;
    future_lon = future_lon*180/pi;

    [future_dem_x,future_dem_y] = projfwd(gflight_tracker.dem_proj,future_lat,future_lon);
    future_dem_elev = interp2(gflight_tracker.dem_x_axis,gflight_tracker.dem_y_axis,gflight_tracker.dem_RGB,future_dem_x,future_dem_y);
    future_dem_elev_ft = future_dem_elev*100/2.54/12;

    future_elev_ft = future_elev*100/2.54/12;
    future_elev_agl_ft = (future_elev_ft - future_dem_elev_ft);
    if any(future_elev_agl_ft < 700)
      set(gflight_tracker.h_plot_dem1,'linewidth',4,'color','red');
      set(gflight_tracker.h_plot_dem2,'linewidth',4,'color','white');
    else
      set(gflight_tracker.h_plot_dem1,'linewidth',2,'color','white');
      set(gflight_tracker.h_plot_dem2,'linewidth',2,'color','white');
    end
    set(gflight_tracker.h_plot_dem1,'XData',-3:num_pnts,'YData',future_elev_ft);
    set(gflight_tracker.h_plot_dem2,'XData',-3:num_pnts,'YData',future_dem_elev_ft);
    ylims(1) = min([future_elev_ft,future_dem_elev_ft]);
    ylims(2) = max([future_elev_ft,future_dem_elev_ft]);
    ylim(gflight_tracker.h_axes_dem, ylims);

    [year,month,day,hour,minute,sec] = datevec(epoch_to_datenum(gflight_tracker.gps_time(end) - utc_leap_seconds(gflight_tracker.gps_time(end))));
    title(sprintf('UTC %02d:%02d:%05.2f %.0f m/%.0f ft, %.0f m / %.0f ft AGL',hour,minute,sec, ...
      elev(end), elev(end)*100/2.54/12, elev(end)-future_dem_elev(4), (elev(end)-future_dem_elev(4))*100/2.54/12),'parent',gflight_tracker.h_axes,'color','white');
  end

  %% Loop for new data: Update Map Axes to Show Current Position
  % =====================================================================
  xlim_orig = xlim(gflight_tracker.h_axes);
  ylim_orig = ylim(gflight_tracker.h_axes);
  axis normal;
  % Force axis to be equal
  xlim_new = xlim(gflight_tracker.h_axes);
  ylim_new = ylim(gflight_tracker.h_axes);
  axes_pos = get(gflight_tracker.h_axes,'position'); aspect_ratio = axes_pos(3)/axes_pos(4);
  xlim_bigger = diff(xlim_new)/diff(ylim_new)/aspect_ratio > 1;
  if xlim_bigger
    ylim_new(1) = mean(ylim_new) - diff(xlim_new)/2*aspect_ratio;
    ylim_new(2) = mean(ylim_new) + diff(xlim_new)/2*aspect_ratio;
  else
    xlim_new(1) = mean(xlim_new) - diff(ylim_new)/2/aspect_ratio;
    xlim_new(2) = mean(xlim_new) + diff(ylim_new)/2/aspect_ratio;
  end
  if toc(update_geotiff_tstart) > 0
    update_geotiff_tstart = tic;
    if isfinite(gflight_tracker.x(end)) && isfinite(gflight_tracker.y(end))
      % Update to current platform position
      xlim_new = xlim_new + gflight_tracker.x(end) - mean(xlim_new);
      ylim_new = ylim_new + gflight_tracker.y(end) - mean(ylim_new);
    end
  end
  xlim(gflight_tracker.h_axes,xlim_new);
  ylim(gflight_tracker.h_axes,ylim_new);
  clear xlim_orig ylim_orig xlim_new ylim_new axes_pos xlim_bigger

  %% Force redraw
  drawnow;
end
% end

%% Cleanup
if strcmpi(gps_input_type,'serial')
  fprintf('Closing serial device %s\n', serial_dev);
  fclose(gflight_tracker.serial_dev);
end
if gps_record_en
  fprintf('Closing gps log file %s\n', gps_fn);
  fclose(fid_out);
end
