% script runOpsInsertLayer.m
%
% Example script for running opsInsertLayer.m. Demonstrates a few of the
% most common operations to be performed with opsInsertLayer.
%
% Authors: John Paden

%% Example Operations (just choose one)
example_str = 'mass_conservation';

if strcmpi(example_str,'gogineni_jakobshavn_point_cloud')
  %% Example 1: Gogineni's Jakobshavn Point Cloud
  % =====================================================================
  % =====================================================================
  % Use parameters spreadsheet to select segment and frame list for creating layers
  % Set the cmd.generic to 1 and cmd.frms for the selected segments and frames
  
  physical_constants;
  insert_param = [];
  
  params = read_param_xls(ct_filename_param('rds_param_2008_Greenland_TO.xls'));
  
  points_fn = '/cresis/snfs1/scratch/paden/mass_conservation/Jakobshavn_2006_2009_Composite/Jakobshavn_2006_2009_Composite/flightlines/Jakobshavn_2006_2009_Composite_Flightlines.txt';
  
  % Load CSV points file
  fid = fopen(points_fn,'r');
  first_line = fgets(fid);
  headers = textscan(first_line,'%s','Delimiter',',');
  data = textscan(fid,'%f%f%f%s%s%f%f%f%f%f%f%f%f%f%f','Delimiter',',');
  fclose(fid);
  points = [];
  for header_idx = 1:length(headers{1})
    points.(headers{1}{header_idx}) = data{header_idx};
  end
  
  % Create geotiff projection structure
  % 1. Grab from a geotiff file with the same projection
  insert_param.proj = geotiffinfo(ct_filename_gis([],'greenland\Landsat-7\Greenland_natural_90m.tif'));
  [points.x,points.y] = projfwd(insert_param.proj,points.LAT,points.LON);
  
  insert_param.eval.ref_source.name = 'surface';
  insert_param.eval.ref_source.source = 'ops';
  insert_param.eval.ref_gaps_fill.method = 'interp_finite';
  insert_param.eval.cmd = 's = ref.twtt + s;';
  insert_param.x = points.x;
  insert_param.y = points.y;
  insert_param.data = (points.A_SURF-points.A_BED) / (c/2/sqrt(er_ice));
  
  insert_param.type = 'point'; % Point data
  insert_param.layer_dest.name = 'gogineni2014_pnt';
  insert_param.layer_dest.source = 'ops';
  insert_param.layer_dest.username = 'paden'; % For OPS layer_dest source
  insert_param.layer_dest.group = 'standard'; % For OPS layer_dest source
  insert_param.layer_dest.description = 'Gogineni JofG 2014 grid'; % For OPS layer_dest source
  insert_param.copy_method = 'overwrite';
  insert_param.gaps_fill.method = 'preserve_gaps';
  insert_param.gaps_fill.method_args = [300 60];
  opsInsertLayer(params, insert_param);
  
elseif strcmpi(example_str,'atm_ramp_pass')
  %% Example 2: ATM Ramp Pass Data
  % =====================================================================
  % =====================================================================
  % Use parameters spreadsheet to select segment and frame list for creating layers
  % Set the cmd.generic to 1 and cmd.frms for the selected segments and frames
  
  physical_constants;
  insert_param = [];
  
  params = read_param_xls(ct_filename_param('kuband_param_2014_Greenland_P3.xls'));
  
  points_fn = '/scratch/metadata/2014_Greenland_P3/130407_truk_l12_kangramp_anthtrem_nopark.txt';
  [points.lat,points.lon,points.elev] = read_ramp_pass(points_fn);
  
  % Create geotiff projection structure
  % 1. Grab from a geotiff file with the same projection
  insert_param.proj = geotiffinfo(ct_filename_gis([],'greenland\Landsat-7\Greenland_natural_90m.tif'));
  
  [points.x,points.y] = projfwd(insert_param.proj,points.lat,points.lon);
  
  insert_param.eval.ref_source.name = 'surface';
  insert_param.eval.ref_source.source = 'ops';
  insert_param.eval.ref_gaps_fill.method = 'interp_finite';
  insert_param.eval.cmd = 's = (elev - s)/(c/2);';
  insert_param.x = points.x;
  insert_param.y = points.y;
  insert_param.data = points.elev;
  
  insert_param.type = 'point'; % Point data
  insert_param.layer_dest.name = 'kanger_ramp';
  insert_param.layer_dest.source = 'ops';
  insert_param.layer_dest.username = 'paden'; % For OPS layer_dest source
  insert_param.layer_dest.group = 'standard'; % For OPS layer_dest source
  insert_param.layer_dest.description = 'ATM ramp pass Kangerlussuaq 2014'; % For OPS layer_dest source
  insert_param.copy_method = 'overwrite';
  insert_param.gaps_fill.method = 'preserve_gaps';
  insert_param.gaps_fill.method_args = [300 60];
  opsInsertLayer(params, insert_param);
  
elseif strcmpi(example_str,'tomography_point_cloud')
  %% Example 3: Insert 3-D Tomography Swath Point Cloud
  % =====================================================================
  % =====================================================================
  % Use parameters spreadsheet to select segment and frame list for creating layers
  % Set the cmd.generic to 1 and cmd.frms for the selected segments and frames
  
  physical_constants;
  insert_param = [];
  
  params = read_param_xls(ct_filename_param('rds_param_2009_Greenland_TO.xls'));
  
  load('jakob_frm1.mat','points');
  frm2 = load('jakob_frm2.mat','points');
  points.lat = cat(2,points.lat,frm2.points.lat);
  points.lon = cat(2,points.lon,frm2.points.lon);
  points.elev = cat(2,points.elev,frm2.points.elev);
  frm3 = load('jakob_2009frm1.mat','points');
  points.lat = cat(2,points.lat,frm3.points.lat);
  points.lon = cat(2,points.lon,frm3.points.lon);
  points.elev = cat(2,points.elev,frm3.points.elev);
  
  % Create geotiff projection structure
  % 1. Grab from a geotiff file with the same projection
  insert_param.proj = geotiffinfo(ct_filename_gis([],'greenland\Landsat-7\Greenland_natural_90m.tif'));
  
  [points.x,points.y] = projfwd(insert_param.proj,points.lat,points.lon);
  good_mask = ~isnan(points.elev);
  points.x = points.x(good_mask);
  points.y = points.y(good_mask);
  points.elev = points.elev(good_mask);
  
  insert_param.eval.ref_source.name = 'surface';
  insert_param.eval.ref_source.source = 'ops';
  insert_param.eval.ref_gaps_fill.method = 'interp_finite';
  insert_param.eval.cmd = 's = (elev - ref.twtt*c/2)/(c/2/sqrt(er_ice)) - s + ref.twtt;';
  insert_param.x = points.x;
  insert_param.y = points.y;
  insert_param.data = points.elev/(c/2/sqrt(er_ice));
  
  insert_param.type = 'point'; % Point data
  insert_param.layer_dest.name = 'jakobshavn3D';
  insert_param.layer_dest.source = 'ops';
  insert_param.layer_dest.username = 'paden'; % For OPS layer_dest source
  insert_param.layer_dest.group = 'standard'; % For OPS layer_dest source
  insert_param.layer_dest.description = 'Basic 3D results for 20060530_08'; % For OPS layer_dest source
  insert_param.copy_method = 'overwrite';
  insert_param.gaps_fill.method = 'preserve_gaps';
  insert_param.gaps_fill.method_args = [300 60];
  opsInsertLayer(params, insert_param);
  
elseif strcmpi(example_str,'EGM96')
  %% Example 4: Insert EGM96 Geoid data
  % =====================================================================
  % =====================================================================
  % Use parameters spreadsheet to select segment and frame list for creating layers
  % Set the cmd.generic to 1 and cmd.frms for the selected segments and frames
  
  physical_constants;
  insert_param = [];
  
  params = read_param_xls(ct_filename_param('snow_param_2017_Greenland_P3.xls'),'20170311_02');
  params.cmd.generic = 1;
  
  % Load in Geoid
  geoid_fn = ct_filename_gis([],'world\egm96_geoid\WW15MGH.DAC');
  points = [];
  [points.lat,points.lon,points.elev] = egm96_loader(geoid_fn);
  points.lon = [points.lon 360];
  points.elev = [points.elev points.elev(:,1)];
  [points.lon,points.lat] = meshgrid(points.lon,points.lat);
  
  % Create geotiff projection structure
  % 1. Grab from a geotiff file with the same projection
  insert_param.proj = geotiffinfo(ct_filename_gis([],'greenland\Landsat-7\Greenland_natural_90m.tif'));
  
  [points.x,points.y] = projfwd(insert_param.proj,points.lat,points.lon);
  good_mask = ~isnan(points.elev);
  points.x = points.x(good_mask);
  points.y = points.y(good_mask);
  points.elev = points.elev(good_mask);
  
  insert_param.eval.cmd = 's = (elev - s)/(c/2);';
  insert_param.x = points.x;
  insert_param.y = points.y;
  insert_param.data = points.elev;
  
  insert_param.type = 'point'; % Point data
  insert_param.layer_dest.name = 'surface';
  insert_param.layer_dest.source = 'records';
  insert_param.layer_dest.username = 'paden'; % For OPS layer_dest source
  insert_param.layer_dest.group = 'standard'; % For OPS layer_dest source
  insert_param.layer_dest.description = ''; % For OPS layer_dest source
  insert_param.layer_dest.layerdata_source = 'layerData'; % For layerData layer_dest source
  insert_param.copy_method = 'overwrite'; % overwrite or fillgaps
  insert_param.gaps_fill.method = 'interp_finite';
  opsInsertLayer(params, insert_param);
  
elseif strcmpi(example_str,'mass_conservation')
  %% Example 5: mass conservation grid
  % =====================================================================
  % =====================================================================
  % Use parameters spreadsheet to select segment and frame list for creating layers
  % Set the cmd.generic to 1 and cmd.frms for the selected segments and frames
  
  physical_constants;
  insert_param = [];
  
  % params = read_param_xls(ct_filename_param('rds_param_2018_Greenland_P3.xls'),'');
  params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'');
  params = ct_set_params(params,'cmd.generic',0);
  params = ct_set_params(params,'cmd.generic',1);
  params = ct_set_params(params,'cmd.generic',0,'cmd.notes','do not process');
  params = ct_set_params(params,'cmd.generic',0, 'day_seg', '20140423_01');
  params = ct_set_params(params,'cmd.frms',[]);
%   params = ct_set_params(params,'cmd.generic',0);
%   params = ct_set_params(params,'cmd.generic',1,'day_seg','20140313_08');
%   params = ct_set_params(params,'cmd.frms',[]);
  
  proj_load_standard;
  if 1
    % Greenland Mass Conservation
    grid_fn = ct_filename_gis(fullfile('greenland','mass_conservation','BedMachineGreenland-2017-09-20.nc'));
    insert_param.proj = arctic_proj;
  else
    % Antarctica Mass Conservation
    grid_fn = ct_filename_gis(fullfile('antarctica','mass_conservation','BedMachineAntarctica_2020-07-15_v02.nc'));
    insert_param.proj = antarctic_proj;
  end
  
  insert_param.eval.ref_source.name = 'surface';
  insert_param.eval.ref_source.source = 'layerdata';
  insert_param.eval.ref_source.layerdata_source = 'layer';
  insert_param.eval.ref_gaps_fill.method = 'interp_finite';
  insert_param.eval.cmd = 's = ref.twtt + s;';
  insert_param.x = double(ncread(grid_fn,'x'));
  insert_param.y = double(ncread(grid_fn,'y'));
  
  insert_param.type = 'raster'; % Raster data
  insert_param.layer_dest.source = 'layerdata';
  insert_param.layer_dest.layerdata_source = 'layer';
  insert_param.layer_dest.username = 'paden'; % For OPS layer_dest source
  insert_param.layer_dest.group = 'standard'; % For OPS layer_dest source
  insert_param.layer_dest.description = 'Mass conservation ice bottom'; % For OPS layer_dest source
  insert_param.layer_dest.existence_check = false; % Create layer if it does not exist
  insert_param.copy_method = 'overwrite';
  insert_param.gaps_fill.method = 'interp_finite';
  
  % ENABLE EACH DESIRED LAYER
  if 1
    % Mass conservation estimate
    insert_param.data = max(0,(double(ncread(grid_fn,'thickness'))).' / (c/2/sqrt(er_ice)));
    insert_param.layer_dest.name = 'bottom_mc';
    opsInsertLayer(params, insert_param);
  end
  
  if 0
    % Mass conservation estimate, lower (minimum elevation) bound
    insert_param.data = max(0,(double(ncread(grid_fn,'thickness')) - ncread(grid_fn,'errbed')).' / (c/2/sqrt(er_ice))); % bottom_mc_top
    insert_param.layer_dest.name = 'bottom_mc_top';
    opsInsertLayer(params, insert_param);
  end
  
  if 0
    % Mass conservation estimate, upper (maximum elevation) bound
    insert_param.data = max(0,(double(ncread(grid_fn,'thickness')) + ncread(grid_fn,'errbed')).' / (c/2/sqrt(er_ice))); % bottom_mc_bottom
    insert_param.layer_dest.name = 'bottom_mc_bot';
    opsInsertLayer(params, insert_param);
  end
  
elseif strcmpi(example_str,'gogineni_jakobshavn_grid')
  %% Example 6: Gogineni's Jakobshavn Grid
  % =====================================================================
  % =====================================================================
  % Use parameters spreadsheet to select segment and frame list for creating layers
  % Set the cmd.generic to 1 and cmd.frms for the selected segments and frames
  
  physical_constants;
  insert_param = [];
  
  params = read_param_xls(ct_filename_param('rds_param_2009_Greenland_TO.xls'));
  
  grid_fn = '/cresis/snfs1/scratch/paden/mass_conservation/Jakobshavn_2006_2009_Composite/Jakobshavn_2006_2009_Composite/grids/jakobshavn_2006_2009_composite_thickness.txt';
  
  % Load grid
  fid = fopen(grid_fn,'r');
  fseek(fid,0,-1);
  grid = [];
  for idx=1:6
    fields = textscan(fid,'%s%f',1);
    grid.(fields{1}{1}) = fields{2};
  end
  thickness = textscan(fid,'%f');
  fclose(fid);
  thickness = reshape(thickness{1},[grid.ncols grid.nrows]).';
  thickness(thickness == grid.NODATA_value) = NaN;
  imagesc(thickness);
  x_axis = grid.xllcorner + grid.cellsize*(0:grid.ncols-1);
  y_axis = grid.yllcorner + grid.cellsize*(0:grid.nrows-1);
  y_axis = y_axis(end:-1:1);
  
  % Create geotiff projection structure
  % 1. Grab from a geotiff file with the same projection
  insert_param.proj = geotiffinfo(ct_filename_gis([],'greenland\Landsat-7\Greenland_natural_90m.tif'));
  
  insert_param.eval.ref_source.name = 'surface';
  insert_param.eval.ref_source.source = 'ops';
  insert_param.eval.ref_gaps_fill.method = 'interp_finite';
  insert_param.eval.cmd = 's = ref.twtt + s;';
  insert_param.x = x_axis;
  insert_param.y = y_axis;
  insert_param.data = thickness / (c/2/sqrt(er_ice));
  
  insert_param.type = 'raster'; % Raster data
  insert_param.layer_dest.name = 'gogineni2014';
  insert_param.layer_dest.source = 'ops';
  insert_param.layer_dest.username = 'paden'; % For OPS layer_dest source
  insert_param.layer_dest.group = 'standard'; % For OPS layer_dest source
  insert_param.layer_dest.description = 'Gogineni JofG 2014 grid'; % For OPS layer_dest source
  insert_param.layer_dest.existence_check = false; % Create layer if it does not exist
  insert_param.copy_method = 'overwrite';
  insert_param.gaps_fill.method = 'interp_finite';
  opsInsertLayer(params, insert_param);
  
elseif strcmpi(example_str,'joel_plummer_jakobshavn_grid')
  %% Example 7: Joe Plummer's Jakobshavn Grid
  % =====================================================================
  % =====================================================================
  % Use parameters spreadsheet to select segment and frame list for creating layers
  % Set the cmd.generic to 1 and cmd.frms for the selected segments and frames
  
  physical_constants;
  insert_param = [];
  
  params = read_param_xls(ct_filename_param('rds_param_2009_Greenland_TO.xls'));
  
  grid_fn = ct_filename_gis([],'greenland/plummer_jakobshavn/jak_grid.tif');
  
  insert_param.proj = geotiffinfo(grid_fn);
  
  % Load the grid
  [bt_elev,R] = geotiffread(grid_fn);
  bt_elev(bt_elev == min(min(bt_elev))) = NaN;
  x_axis = R.XLimWorld(1) + [R.XLimIntrinsic(1):R.XLimIntrinsic(2)-1]'*R.DeltaX;
  y_axis = R.YLimWorld(2) + [R.YLimIntrinsic(1):R.YLimIntrinsic(2)-1]'*R.DeltaY;
  
  insert_param.eval.ref_source.name = 'surface';
  insert_param.eval.ref_source.source = 'ops';
  insert_param.eval.ref_gaps_fill.method = 'interp_finite';
  insert_param.eval.cmd = 's = (elev - ref.twtt*c/2)/(c/2/sqrt(er_ice)) - s + ref.twtt;';
  insert_param.x = x_axis;
  insert_param.y = y_axis;
  insert_param.data = bt_elev/(c/2/sqrt(er_ice));
  
  insert_param.type = 'raster'; % Raster data
  insert_param.layer_dest.name = 'plummer';
  insert_param.layer_dest.source = 'ops';
  insert_param.layer_dest.username = 'paden'; % For OPS layer_dest source
  insert_param.layer_dest.group = 'standard'; % For OPS layer_dest source
  insert_param.layer_dest.description = 'Plummer Jakobshavn Grid'; % For OPS layer_dest source
  insert_param.layer_dest.existence_check = false; % Create layer if it does not exist
  insert_param.copy_method = 'overwrite';
  insert_param.gaps_fill.method = 'interp_finite';
  opsInsertLayer(params, insert_param);
  
elseif strcmpi(example_str,'gimp_grid')
  %% Example 8: GIMP Grid
  % =====================================================================
  % =====================================================================
  % Use parameters spreadsheet to select segment and frame list for creating layers
  % Set the cmd.generic to 1 and cmd.frms for the selected segments and frames
  
  physical_constants;
  insert_param = [];
  
  %params = read_param_xls(ct_filename_param('snow_param_2015_Greenland_Polar6.xls'));
  params = read_param_xls(ct_filename_param('rds_param_2016_Greenland_G1XB.xls'),'');
  
  grid_fn = ct_filename_gis([],'greenland/DEM/GIMP/gimpdem_90m.tif');
  
  % Load the grid
  points = [];
  [points.elev,R] = geotiffread(grid_fn);
  points.elev = double(points.elev);
  x_axis = R.XLimWorld(1) + [R.XLimIntrinsic(1):R.XLimIntrinsic(2)-1]'*R.DeltaX;
  y_axis = R.YLimWorld(2) + [R.YLimIntrinsic(1):R.YLimIntrinsic(2)-1]'*R.DeltaY;
  
  insert_param.proj = geotiffinfo(grid_fn);
  
  insert_param.eval.cmd = 's = (elev - s)/(c/2);';
  insert_param.x = x_axis;
  insert_param.y = y_axis;
  insert_param.data = points.elev;
  
  insert_param.type = 'raster'; % Raster data
  insert_param.layer_dest.name = 'GIMP';
  insert_param.layer_dest.source = 'ops';
  insert_param.layer_dest.username = 'paden'; % For OPS layer_dest source
  insert_param.layer_dest.group = 'standard'; % For OPS layer_dest source
  insert_param.layer_dest.description = 'GIMP Grid'; % For OPS layer_dest source
  insert_param.layer_dest.layerdata_source = 'layerData'; % For layerData layer_dest source
  insert_param.layer_dest.existence_check = false; % Create layer if it does not exist
  insert_param.copy_method = 'overwrite';
  insert_param.gaps_fill.method = 'interp_finite';
  opsInsertLayer(params, insert_param);
  
elseif strcmpi(example_str,'bedmap2_grid')
  %% Example 9: BEDMAP2 Grid
  % =====================================================================
  % =====================================================================
  % Use parameters spreadsheet to select segment and frame list for creating layers
  % Set the cmd.generic to 1 and cmd.frms for the selected segments and frames
  
  physical_constants;
  insert_param = [];
  
  params = read_param_xls(ct_filename_param('rds_param_2018_Antarctica_Ground.xls'),'');
  params = ct_set_params(params,'cmd.generic',0);
  %params = ct_set_params(params,'cmd.generic',1,'day_seg','20181224_03');
  
  grid_fn = ct_filename_gis([],fullfile('antarctica','DEM','BEDMAP2','original_data','bedmap2_tiff','bedmap2_surface.tif'));
  geoid_fn = ct_filename_gis([],fullfile('antarctica','DEM','BEDMAP2','original_data','bedmap2_tiff','gl04c_geiod_to_WGS84.tif'));
  
  % Load the grid
  points = [];
  [points.elev,R] = geotiffread(grid_fn);
  [geoid.elev,R] = geotiffread(geoid_fn);
  points.elev = double(points.elev) + double(geoid.elev);
  x_axis = R.XLimWorld(1) + [R.XLimIntrinsic(1):R.XLimIntrinsic(2)-1]'*R.DeltaX;
  y_axis = R.YLimWorld(2) + [R.YLimIntrinsic(1):R.YLimIntrinsic(2)-1]'*R.DeltaY;
  
  insert_param.proj = geotiffinfo(grid_fn);
  
  insert_param.eval.cmd = 's = (elev - s)/(c/2);';
  insert_param.x = x_axis;
  insert_param.y = y_axis;
  insert_param.data = points.elev;
  
  insert_param.type = 'raster'; % Raster data
  insert_param.layer_dest.name = 'BEDMAP_surface';
  insert_param.layer_dest.desc = 'BEDMAP 2 Surface'; % For OPS layer_dest source
  insert_param.layer_dest.source = 'layerdata';
  insert_param.layer_dest.username = 'paden'; % For OPS layer_dest source
  insert_param.layer_dest.group_name = ''; % For OPS layer_dest source
  insert_param.layer_dest.layerdata_source = 'layer'; % For layerData layer_dest source
  insert_param.layer_dest.existence_check = false; % Create layer if it does not exist
  insert_param.copy_method = 'overwrite';
  insert_param.gaps_fill.method = 'interp_finite';
  opsInsertLayer(params, insert_param);
  
elseif strcmpi(example_str,'south_dakota_grid')
  %% Example 10: South Dakota Grid
  % =====================================================================
  % =====================================================================
  % Use parameters spreadsheet to select segment and frame list for creating layers
  % Set the cmd.generic to 1 and cmd.frms for the selected segments and frames
  
  physical_constants;
  insert_param = [];
  
  params = read_param_xls(ct_filename_param('snow_param_2019_SouthDakota_N1KU.xls'),'');
  params = ct_set_params(params,'cmd.generic',0);
  %params = ct_set_params(params,'cmd.generic',1,'day_seg','20200129_01');
  
  grid_fn = ct_filename_gis([],fullfile('usa','DEM','NED','National_Elevation_Data_DEM_10m.tif'));
  
  % Load the grid
  points = [];
  [points.elev,R] = geotiffread(grid_fn);
  points.elev = double(points.elev);
  x_axis = R.XLimWorld(1) + [R.XLimIntrinsic(1):R.XLimIntrinsic(2)]'*R.DeltaX;
  y_axis = R.YLimWorld(2) + [R.YLimIntrinsic(1):R.YLimIntrinsic(2)]'*R.DeltaY;
  
  insert_param.proj = geotiffinfo(grid_fn);
  
  insert_param.eval.cmd = 's = (elev - s)/(c/2);';
  insert_param.x = x_axis;
  insert_param.y = y_axis;
  insert_param.data = points.elev;
  
  insert_param.type = 'raster'; % Raster data
  insert_param.layer_dest.name = 'USGS_surface';
  insert_param.layer_dest.desc = 'USGS Surface'; % For OPS layer_dest source
  insert_param.layer_dest.source = 'layerdata';
  insert_param.layer_dest.username = 'paden'; % For OPS layer_dest source
  insert_param.layer_dest.group_name = ''; % For OPS layer_dest source
  insert_param.layer_dest.layerdata_source = 'layer'; % For layerData layer_dest source
  insert_param.layer_dest.existence_check = false; % Create layer if it does not exist
  insert_param.copy_method = 'overwrite';
  insert_param.gaps_fill.method = 'interp_finite';
  opsInsertLayer(params, insert_param);
  
elseif strcmpi(example_str,'other_season_points')
  %% Example 11: Other Season Points
  % =====================================================================
  % =====================================================================
  % Use parameters spreadsheet to select segment and frame list for creating layers
  % Set the cmd.generic to 1 and cmd.frms for the selected segments and frames
  
  global gRadar;
  physical_constants;
  insert_param = [];
  
  params = read_param_xls(ct_filename_param('accum_param_2019_Antarctica_TObas.xls'),'');
  params = ct_set_params(params,'cmd.generic',0);
  params = ct_set_params(params,'cmd.generic',1,'day_seg','20191225_01');
  params = ct_set_params(params,'cmd.generic',1,'day_seg','20191226_01');
  params = ct_set_params(params,'cmd.generic',1,'day_seg','20200127_01');
  
  % Setup the points
  proj_load_standard;
  insert_param.proj = arctic_proj;
  insert_param.x = [];
  insert_param.y = [];
  insert_param.data = [];
  insert_param.eval.ref_source.name = 'surface';
  insert_param.eval.ref_source.source = 'layerdata';
  insert_param.eval.ref_gaps_fill.method = 'interp_finite';
  % Convert "layer twtt below the surface" to "total twtt"
  insert_param.eval.cmd = 's = s + ref.twtt;';
  insert_param.interp_method = 'nearest';
  
  % Load points from other segments
  param = read_param_xls(ct_filename_param('accum_param_2018_Antarctica_TObas.xls'),'20190201_01','post');
  layer_params = struct('name',{'surface','bottom'},'source','ops');
  layers = opsLoadLayers(merge_structs(param,gRadar), layer_params);
  [layers(2).x,layers(2).y] = projfwd(insert_param.proj, layers(2).lat, layers(2).lon);
  insert_param.x = layers(2).x(:);
  insert_param.y = layers(2).y(:);
  % Convert "total twtt" to "twtt below the surface"
  insert_param.data = layers(2).twtt-interp1(layers(1).gps_time,layers(1).twtt,layers(2).gps_time);
  insert_param.data = insert_param.data(:);
  
  insert_param.type = 'point'; % Point data
  insert_param.layer_dest.name = 'bottom_old';
  insert_param.layer_dest.desc = 'Layer from other segments'; % For OPS layer_dest source
  insert_param.layer_dest.source = 'layerdata';
  insert_param.layer_dest.username = 'paden'; % For OPS layer_dest source
  insert_param.layer_dest.group_name = ''; % For OPS layer_dest source
  insert_param.layer_dest.layerdata_source = 'layer'; % For layerData layer_dest source
  insert_param.layer_dest.existence_check = false; % Create layer if it does not exist
  insert_param.copy_method = 'overwrite';
  insert_param.gaps_fill.method = 'interp_finite';
  opsInsertLayer(params, insert_param);
  
elseif strcmpi(example_str,'snotel')
  %% Example 12: SNOTEL
  % =====================================================================
  % =====================================================================
  % Use parameters spreadsheet to select segment and frame list for creating layers
  % Set the cmd.generic to 1 and cmd.frms for the selected segments and frames
  
  global gRadar;
  physical_constants;
  insert_param = [];
  
  params = read_param_xls(ct_filename_param('snow_param_2019_SouthDakota_N1KU.xls'),'');
  params = ct_set_params(params,'cmd.generic',1);
  params = ct_set_params(params,'cmd.generic',0,'cmd.notes','do not process');
  
%   params = ct_set_params(params,'cmd.generic',0);
%   params = ct_set_params(params,'cmd.generic',1,'day_seg','20200128_03');
%   params = ct_set_params(params,'cmd.frms',27);
  
  % Setup the points
  proj_load_standard;
  insert_param.proj = arctic_proj;
  insert_param.gaps_fill.method = 'preserve_gaps';
  insert_param.gaps_fill.method_args = [300 60];
  insert_param.eval.ref_source.name = 'surface';
  insert_param.eval.ref_source.source = 'layerdata';
  insert_param.eval.ref_gaps_fill.method = 'interp_finite';
  insert_param.interp_method = 'nearest';
  insert_param.type = 'point'; % Point data
  insert_param.layer_dest.source = 'layerdata';
  insert_param.layer_dest.username = 'paden'; % For OPS layer_dest source
  insert_param.layer_dest.group_name = ''; % For OPS layer_dest source
  insert_param.layer_dest.layerdata_source = 'layer'; % For layerData layer_dest source
  insert_param.layer_dest.existence_check = false; % Create layer if it does not exist
  insert_param.copy_method = 'overwrite';
  
  % max_time_diff_sec: maximum number of days between measurement and segment
  max_time_diff_sec = inf;
  % insert_param.max_dist: maximum distance from point to interpolate (NaN
  % beyond this distance)
  insert_param.max_dist = 1500;

  % Load Snotel files
  snotel_fns = get_filenames(fullfile(gRadar.data_support_path, params(1).season_name,'snotel'),'','','.csv');
  snotel_data = [];
  for snotel_fns_idx = 1:length(snotel_fns)
    snotel_fn = snotel_fns{snotel_fns_idx};
    [fid,msg] = fopen(snotel_fn,'r');
    if fid<0
      error('Failed to open file: %s', msg);
    end
    % Expected file format:
    % GPS_Date,GPS_Time,Station Id,Station Name,Latitude,Longitude,Snow Water Equivalent (in) Start of Day Values,Snow Depth (in) Start of Day Values
    % 1/26/2020,14:00,920,North Rapid Creek,44.20617,-103.78758,4,20
    raw_data = textscan(fid,'%s %s %s %s %f %f %f %f','headerlines',1','delimiter',',');
    fclose(fid);
    if length(raw_data) == 8
      % Use the length of the last field since an incomplete last record
      % should be ignored
      N = length(raw_data{8});
      % date_str: Combine date and time fields
      date_str = cellfun(@(x,y) cat(2,x,' ',y),raw_data{1},raw_data{2},'UniformOutput',false);
      if isempty(snotel_data)
        % Initialize variables on the first good data
        snotel_data = struct('gps_time',datenum_to_epoch(datenum(date_str)));
        snotel_data.lat = raw_data{5}(1:N);
        snotel_data.lon = raw_data{6}(1:N);
        snotel_data.SWE = raw_data{7}(1:N)*2.54/100;
        snotel_data.depth = raw_data{8}(1:N)*2.54/100;
      else
        % Append variables
        snotel_data.gps_time(end+(1:N)) = datenum_to_epoch(datenum(date_str));
        snotel_data.lat(end+(1:N)) = raw_data{5}(1:N);
        snotel_data.lon(end+(1:N)) = raw_data{6}(1:N);
        snotel_data.SWE(end+(1:N)) = raw_data{7}(1:N)*2.54/100;
        snotel_data.depth(end+(1:N)) = raw_data{8}(1:N)*2.54/100;
      end
    end
  end
  [snotel_data.x,snotel_data.y] = projfwd(insert_param.proj,snotel_data.lat,snotel_data.lon);
  
  % Since different points need to be used depending on the date, we only
  % do this one segment at a time
  for param_idx = 1:length(params)
    param = params(param_idx);
    if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
      continue;
    end
    records = records_load(param);
    % done_mask: when true it means the snotel point will no longer be
    % considered
    done_mask = snotel_data.gps_time < records.gps_time(1)-max_time_diff_sec ...
      | snotel_data.gps_time > records.gps_time(end)+max_time_diff_sec;
    insert_param.x = [];
    insert_param.y = [];
    insert_param.data = [];
    while ~all(done_mask)
      idx = find(~done_mask,1);
      % Only use one data value at each location
      cur_idxs = find(snotel_data.x(idx) == snotel_data.x & snotel_data.y(idx) == snotel_data.y);
      done_mask(cur_idxs) = true;
      % Find the closest point in time at this location
      [~,match_idx] = min(snotel_data.gps_time(cur_idxs));
      % Append the new point
      insert_param.x(end+1) = snotel_data.x(cur_idxs(match_idx));
      insert_param.y(end+1) = snotel_data.y(cur_idxs(match_idx));
      % Convert SWE and snow depth into density
      density = 0.917 * snotel_data.SWE(cur_idxs(match_idx)) / snotel_data.depth(cur_idxs(match_idx));
      % Use Tiuri et al. 1984 to turn density into relative permitivity
      er_snow = 1 + 1.7*density + 0.7*density^2;
      % Turn depth and permitivity into twtt through snow layer
      insert_param.data(end+1) = snotel_data.depth(cur_idxs(match_idx)) * sqrt(er_snow) * 2/c;
    end
    
    if length(insert_param.data) < 3
      % Not enough points to triangulate so create a small triangle around
      % the last point to satisfy the opsInsertLayer's triangulation
      % interpolation
      insert_param.x(end+(1:2)) = insert_param.x(end) + [1; 0];
      insert_param.y(end+(1:2)) = insert_param.y(end) + [0; 1];
      insert_param.data(end+(1:2)) = insert_param.data(end);
    end
    
    insert_param.layer_dest.name = 'snotel_surface';
    insert_param.layer_dest.desc = 'SNOTEL snow surface'; % For OPS layer_dest source
    % Convert "layer twtt in air" to "total twtt"
    insert_param.eval.cmd = 's = ref.twtt;';
    opsInsertLayer(param, insert_param);
    
    insert_param.layer_dest.name = 'snotel';
    insert_param.layer_dest.desc = 'SNOTEL snow bottom'; % For OPS layer_dest source
    % Convert "layer twtt in air" to "total twtt"
    insert_param.eval.cmd = 's = s + ref.twtt;';
    opsInsertLayer(param, insert_param);
  end
  
end
