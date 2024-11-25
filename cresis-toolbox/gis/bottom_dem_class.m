% Class bottom_dem_class
%
% Class for loading and working with ice bottom digital elevation models.
% Normally stored in the global variable gbottom_dem to avoid multiple
% loads of the GIS files.
%
% Examples:
% See run_dem_class.m
%
% Author: John Paden

classdef bottom_dem_class < handle
  properties
    % dem_info: Cell array of dem_info structures that each describe a DEM
    dem_info
    % param: gRadar/parameter spreadsheet parameter structure
    param % only .gis_path used
    
    % DEM properties
    dem_all
    x_all
    y_all
    
    % Region of interest fields
    % Truncated DEM structure: dem, x, y
    dem
    
    % Geographic vector
    name % name of vector (usually day_seg)
    x % vector query point x-value, N elements
    y % vector query point y-value, N elements
    di % DEM index for each (x,y) vector query point, N elements
    lat % vector query point latitude-value, N elements
    lon % vector query point longitude-value, N elements
    min_x
    max_x
    min_y
    max_y
    min_lat
    max_lat
    mean_lon
    max_lon
    min_lon
    
    % Mode
    dem_mode % string, either 'thickness' or 'bed'. Default is 'bed'.
  end
  
  methods
    %% constructor
    function obj = bottom_dem_class(param)
      
      % Input checks
      % ===================================================================
      if ~exist('param','var') || isempty(param) || ~isfield(param,'gis_path') || isempty(param.gis_path)
        error('param.gis_path must be defined.');
      end
      obj.param = param;
      
      % Setup DEM List
      % ===================================================================
      obj.dem_info = {};
      proj_load_standard; % Load standard projections
      
      % Arctic Ice Bottom DEM, Bed Machine Greenland v3
      % -------------------------------------------------------------------
      % 
      try
        new_dem_info.url = 'https://n5eil01u.ecs.nsidc.org/ICEBRIDGE/IDBMG4.003/1993.01.01/BedMachineGreenland-2017-09-20.nc';
        new_dem_info.res = [NaN];
        new_dem_info.res_str = {''};
        new_dem_info.tile_en = [0 0 0 0];
        new_dem_info.subtile_en = [0 0 0 0];
        new_dem_info.tile_fn_ext = '';
        new_dem_info.mosaic_fn_fh = @(res_str) '';
        new_dem_info.acknowledge = 'See citation. https://nsidc.org/data/idbmg4';
        new_dem_info.citation = sprintf('(1) Morlighem, M., C. Williams, E. Rignot, L. An, J. E. Arndt, J. Bamber, G. Catania, N. Chauché, J. A. Dowdeswell, B. Dorschel, I. Fenty, K. Hogan, I. Howat, A. Hubbard, M. Jakobsson, T. M. Jordan, K. K. Kjeldsen, R. Millan, L. Mayer, J. Mouginot, B. Noël, C. O''Cofaigh, S. J. Palmer, S. Rysgaard, H. Seroussi, M. J. Siegert, P. Slabon, F. Straneo, M. R. van den Broeke, W. Weinrebe, M. Wood, and K. Zinglersen. 2017. BedMachine v3: Complete bed topography and ocean bathymetry mapping of Greenland from multi-beam echo sounding combined with mass conservation, Geophysical Research Letters. 44. https://doi.org/10.1002/2017GL074954.\nMorlighem, M. et al. 2017, updated 2018. IceBridge BedMachine Greenland, Version 3. Boulder, Colorado USA. NASA National Snow and Ice Data Center Distributed Active Archive Center. doi: https://doi.org/10.5067/2CIX82HUV88Y.');
        new_dem_info.no_data = -9999;
        new_dem_info.out_path = fullfile(param.gis_path,'greenland','mass_conservation');
        new_dem_info.proj = arctic_proj; % Loaded from proj_load_standard.m
        obj.dem_info{end+1} = new_dem_info;
      catch ME
        warning(ME.getReport);
      end
      
      % Antarctica Ice Bottom DEM, MEaSUREs BedMachine Antarctica, Version 2
      % -------------------------------------------------------------------
      try
        new_dem_info.url = 'https://n5eil01u.ecs.nsidc.org/MEASURES/NSIDC-0756.002/1970.01.01/BedMachineAntarctica_2020-07-15_v02.nc';
        new_dem_info.res = [NaN];
        new_dem_info.res_str = {''};
        new_dem_info.tile_en = [0 0 0 0];
        new_dem_info.subtile_en = [0 0 0 0];
        new_dem_info.tile_fn_ext = '';
        new_dem_info.mosaic_fn_fh = @(res_str) '';
        new_dem_info.acknowledge = 'See citation. https://nsidc.org/data/nsidc-0756/versions/2';
        new_dem_info.citation = sprintf('(1) Morlighem, M. 2020. MEaSUREs BedMachine Antarctica, Version 2. Boulder, Colorado USA. NASA National Snow and Ice Data Center Distributed Active Archive Center. doi: https://doi.org/10.5067/E1QL9HFQ7A8M.\n(2) Morlighem, M., E. Rignot, T. Binder, D. D. Blankenship, R. Drews, G. Eagles, O. Eisen, F. Ferraccioli, R. Forsberg, P. Fretwell, V. Goel, J. S. Greenbaum, H. Gudmundsson, J. Guo, V. Helm, C. Hofstede, I. Howat, A. Humbert, W. Jokat, N. B. Karlsson, W. Lee, K. Matsuoka, R. Millan, J. Mouginot, J. Paden, F. Pattyn, J. L. Roberts, S. Rosier, A. Ruppel, H. Seroussi, E. C. Smith, D. Steinhage, B. Sun, M. R. van den Broeke, T. van Ommen, M. van Wessem, and D. A. Young. 2020. Deep glacial troughs and stabilizing ridges unveiled beneath the margins of the Antarctic ice sheet, Nature Geoscience. 13. 132-137. https://doi.org/10.1038/s41561-019-0510-8');
        new_dem_info.no_data = -9999;
        new_dem_info.out_path = fullfile(param.gis_path,'antarctica','mass_conservation');
        new_dem_info.proj = antarctic_proj; % Loaded from proj_load_standard.m
        obj.dem_info{end+1} = new_dem_info;
      catch ME
        warning(ME.getReport);
      end
      
      % Prepare DEM fields
      % -------------------------------------------------------------------
      obj.dem_mode = 'bed';
      obj.clear();
      obj.reset();
    end
    
    %% destructor
    % =====================================================================
    function delete(obj)
    end
    
    %% set_vector: Set Geographic Vector
    % =====================================================================
    function obj = set_vector(obj,lat,lon,name)
      
      % Update class fields and determine which DEM each point belongs to
      % -------------------------------------------------------------------
      if exist('name','var')
        obj.name = name;
      end
      if isempty(lat)
        return;
      else
        obj.lat = lat;
        obj.lon = lon;
        obj.x = nan(size(lat));
        obj.y = nan(size(lat));
        obj.di = nan(size(lat));
        % For each input determine the dem index to use
        % Arctic Ice Bottom DEM, Bed Machine Greenland v3
        obj.di(lat>0) = 1;
        % Antarctica Ice Bottom DEM, MEaSUREs BedMachine Antarctica, Version 2
        obj.di(lat<=0) = 1;
        
        for di = unique(obj.di)
          mask = obj.di == di;
          [obj.x(mask),obj.y(mask)] = projfwd(obj.dem_info{di}.proj,lat(mask),lon(mask));
        end
      end
      
      % Determine bounds of region of interest
      % -------------------------------------------------------------------
      obj.min_x = min(obj.x(:));
      obj.max_x = max(obj.x(:));
      obj.min_y = min(obj.y(:));
      obj.max_y = max(obj.y(:));
      
      obj.min_lat = min(obj.lat(:));
      obj.max_lat = max(obj.lat(:));
      % Handle longitude in a special way because it wraps around.
      obj.mean_lon = angle(mean(exp(1i*obj.lon(:)/180*pi)))*180/pi;
      obj.max_lon = obj.mean_lon + max(angle(exp(1i*(obj.lon(:)-obj.mean_lon)/180*pi)))*180/pi;
      obj.min_lon = obj.mean_lon + min(angle(exp(1i*(obj.lon(:)-obj.mean_lon)/180*pi)))*180/pi;
      
      % Load GIS data as needed
      % -------------------------------------------------------------------
      
      % If msl is not big enough, it is reloaded to fit vector
      %obj.load_msl();
      
      % If ocean is not big enough or has not been truncated yet, a new
      % truncated version is created
      %bj.load_ocean();
      
      % If the whole region fits into a single tile, then this tile is
      % loaded and truncated to the region of interest. If the region does
      % not fit into a single tile, then the tiles will be loaded later on
      % an as needed basis.
      obj.load_dem();
    end
    
    %% load_msl: Load MSL
    % =====================================================================
    function obj = load_msl(obj)
      if isempty(obj.x)
        return;
      end
      if ~isempty(obj.msl)
        if obj.msl.lon(1) <= obj.min_lon && obj.msl.lon(end) >= obj.max_lon ...
            && obj.msl.lat(1) <= obj.min_lat && obj.msl.lat(end) >= obj.max_lat
        end
      end
      
      % Mean Sea Level (msl)
      % -------------------------------------------------------------------
      if 0
        % EGM-96
        obj.msl.fn = ct_filename_gis(obj.param,fullfile('world','egm96_geoid','WW15MGH.DAC'));
        points = [];
        [obj.msl.lat,obj.msl.lon,obj.msl.elev] = egm96_loader(obj.msl.fn);
        obj.msl.lon = [obj.msl.lon 360];
        obj.msl.elev = [obj.msl.elev obj.msl.elev(:,1)];
        [obj.msl.lon,obj.msl.lat] = meshgrid(obj.msl.lon,obj.msl.lat);
      else
        % Load DTU mean sea level
        obj.msl.fn = ct_filename_gis(obj.param,fullfile('world','dtu_meansealevel','DTU10MSS_1min.nc'));
        obj.msl.lat = ncread(obj.msl.fn,'lat');
        obj.msl.lon = ncread(obj.msl.fn,'lon');
        dlat = obj.msl.lat(2)-obj.msl.lat(1);
        lat_idxs = find(obj.msl.lat >= obj.min_lat-2*dlat & obj.msl.lat <= obj.max_lat+2*dlat);
        dlon = obj.msl.lon(2)-obj.msl.lon(1);
        rel_lon = obj.mean_lon + angle(exp(1i*(obj.msl.lon - obj.mean_lon)/180*pi))*180/pi;
        lon_idxs = find(rel_lon >= obj.min_lon-2*dlon & rel_lon <= obj.max_lon+2*dlon);
        break_idx = find(diff(lon_idxs)~=1);
        obj.msl.lat = obj.msl.lat(lat_idxs);
        obj.msl.lon = rel_lon(lon_idxs);
        % Transpose elev because "x" axis (which is longitude) must be on the
        % column dimension for interp2.
        % Convert to single because interp2 requires single or double type
        % and single is smaller yet has enough precision.
        if isempty(break_idx)
          obj.msl.elev = single(ncread(obj.msl.fn,'mss', ...
            [lon_idxs(1) lat_idxs(1)],[length(lon_idxs) length(lat_idxs)]).');
        else
          obj.msl.elev = single(ncread(obj.msl.fn,'mss', ...
            [lon_idxs(break_idx+1) lat_idxs(1)],[length(lon_idxs)-break_idx length(lat_idxs)]).');
          obj.msl.elev = [obj.msl.elev, single(ncread(obj.msl.fn,'mss', ...
            [1 lat_idxs(1)],[break_idx length(lat_idxs)]).')];
          obj.msl.lon = obj.msl.lon([break_idx+1:end,1:break_idx]);
        end
        [obj.msl.lon,unique_idxs] = unique(obj.msl.lon);
        obj.msl.elev = obj.msl.elev(:,unique_idxs);
      end
    end
    
    %% load_ocean: Load ocean mask
    % =====================================================================
    function obj = load_ocean(obj)
      if isempty(obj.x)
        return;
      end
      
      % Load ocean mask shape file (-180 to +180 lon)
      % -------------------------------------------------------------------
      if ~isfield(obj.ocean,'shp_all')
        ocean_mask_fn = ct_filename_gis(obj.param,fullfile('world','land_mask','Land_Mask_IDL_jharbeck','GSHHS_f_L1.shp'));
        ocean_mask_fn_antarctica = ct_filename_gis(obj.param,fullfile('world','land_mask','Land_Mask_IDL_jharbeck','GSHHS_f_L5.shp'));
        warning off;
        obj.ocean.shp_all = shaperead(ocean_mask_fn);
        if isfield(obj.param,'post') && isfield(obj.param.post,'ops') ...
            && isfield(obj.param.post.ops,'location') && strcmp(obj.param.post.ops.location,'antarctic')
          shp_antarctica = shaperead(ocean_mask_fn_antarctica);
          obj.ocean.shp_all = cat(1,obj.ocean.shp_all,shp_antarctica);
        end
        warning on;
        obj.ocean.bb_all = [obj.ocean.shp_all(:).BoundingBox];
      end
      
      % Get all ocean shapes within the data segment bounding box. Shape is
      % not included if any of the following holds:
      %  - Bottom of the shape is above the top of the segment, >max_lat
      %  - Top of the shape is below the bottom of the segment, <min_lat
      %  - Left side of the shape is to the right of the segment, >max_lon
      %  - Right side of the shape is to the left of the segment, <min_lon
      % Handle longitude in a special way because it wraps around.
      if isempty(obj.ocean.bb_all)
        obj.ocean.shp = [];
      else
        rel_min_lon = obj.mean_lon + angle(exp(1i*(obj.ocean.bb_all(1,1:2:end) - obj.mean_lon)/180*pi))*180/pi;
        rel_max_lon = obj.mean_lon + angle(exp(1i*(obj.ocean.bb_all(2,1:2:end) - obj.mean_lon)/180*pi))*180/pi;
        bb_good_mask = ~(obj.ocean.bb_all(1,2:2:end)>obj.max_lat | obj.ocean.bb_all(2,2:2:end)<obj.min_lat ...
          | rel_min_lon>obj.max_lon | rel_max_lon<obj.min_lon);
        obj.ocean.shp = obj.ocean.shp_all(bb_good_mask);
        % All bounding boxes of every shape
        obj.ocean.bb = [obj.ocean.shp(:).BoundingBox];
      end
      
      if 0
        % Debug code to check bounding box code
        figure(1); clf;
        for idx=1:length(obj.ocean.shp)
          if length(obj.ocean.shp(idx).X) > 2000
            plot(obj.ocean.shp(idx).X(1:5:end),obj.ocean.shp(idx).Y(1:5:end))
          else
            plot(obj.ocean.shp(idx).X,obj.ocean.shp(idx).Y)
          end
          hold on;
        end
        plot(obj.lon(1:100:end),obj.lat(1:100:end),'k.')
      end
      
    end
    
    %% load_dem: Load land DEM
    % =====================================================================
    function obj = load_dem(obj)

      physical_constants;
      
      for di = unique(obj.di)
        mask = obj.di == di;
        if all(~mask)
          continue
        end
        ri = obj.get_ri(di);
        
        if ~obj.dem_info{di}.tile_en(ri)
          if ~isempty(obj.dem.x{di}) ...
              && obj.min_x >= min(obj.dem.x{di}) && obj.max_x <= max(obj.dem.x{di}) ...
              && obj.min_y >= min(obj.dem.y{di}) && obj.max_y <= max(obj.dem.y{di})
            continue;
          end
          
          % Single large DEM file
          % ---------------------------------------------------------------
          url = [obj.dem_info{di}.url, obj.dem_info{di}.mosaic_fn_fh(obj.dem_info{di}.res_str{ri})];
          [~,url_name,url_ext] = fileparts(url);
          nc_fn = fullfile(obj.dem_info{di}.out_path, [url_name,url_ext]);
          
          if ~exist(nc_fn,'file')
            cmd = sprintf('wget -P %s %s', obj.dem_info{di}.out_path, url);
            fprintf('  %s\n', cmd);
            system(cmd);
            if ~exist(nc_fn,'file')
              error('Failed to download file.');
            end
          end
          
          if isempty(obj.x_all{di})
            % Load the DEM file
            % ---------------------------------------------------------------
            obj.x_all{di} = double(ncread(nc_fn,'x'));
            obj.y_all{di} = double(ncread(nc_fn,'y'));
            if strcmpi(obj.dem_mode,'bed')
              obj.dem_all{di} = double(ncread(nc_fn,'bed').') / (c/2/sqrt(er_ice));
            elseif strcmpi(obj.dem_mode,'thickness')
              obj.dem_all{di} = double(ncread(nc_fn,'thickness').') / (c/2/sqrt(er_ice));
            end
          end
          
          % Truncate the DEM to region of interest
          % ---------------------------------------------------------------
          dx = abs(obj.x_all{di}(2) - obj.x_all{di}(1));
          dy = abs(obj.y_all{di}(2) - obj.y_all{di}(1));
          x_mask = obj.x_all{di} >= obj.min_x-2*dx & obj.x_all{di} <= obj.max_x+2*dx;
          y_mask = obj.y_all{di} >= obj.min_y-2*dy & obj.y_all{di} <= obj.max_y+2*dy;
          
          obj.dem.dem{di} = obj.dem_all{di}(y_mask,x_mask);
          obj.dem.dem{di}(obj.dem.dem{di}==obj.dem_info{di}.no_data) = NaN;
          obj.dem.x{di} = obj.x_all{di}(x_mask);
          obj.dem.y{di} = obj.y_all{di}(y_mask);
          
          if 0
            figure(1); clf;
            imagesc(obj.dem.x{di}/1e3,obj.dem.y{di}/1e3,obj.dem.dem{di});
            set(gca,'YDir','normal')
            hold on;
            plot(obj.x/1e3,obj.y/1e3,'k','LineWidth',2);
            cc = caxis;
          end
        end
      end
    end
    
    %% get_vector_dem: Get DEM corresponding to geographic vector
    % =====================================================================
    function [land_dem,msl,ocean_mask] = get_vector_dem(obj)
      %  When a tile is accessed and it does not exist, then it is
      %  downloaded, loaded, and stored
      
      % MSL
      % -------------------------------------------------------------------
      %msl = interp2(obj.msl.lon,obj.msl.lat,obj.msl.elev,obj.lon,obj.lat);
      
      % DEM and ocean_mask
      % -------------------------------------------------------------------
      %ocean_mask = true(size(obj.lat));
      for di = unique(obj.di)
        mask = obj.di == di;
        if all(~mask)
          continue
        end
        
        % DEM
        % -----------------------------------------------------------------
        ri = obj.get_ri(di);
        if ~obj.dem_info{di}.tile_en(ri)
          % Single DEM file
          land_dem(mask) = interp2(obj.dem.x{di},obj.dem.y{di},obj.dem.dem{di},obj.x(mask),obj.y(mask));
          
        else
          % DEM is broken into multiple tile files
          land_dem = nan(size(obj.x));
          
          % Determine which tiles are needed
          tile_x = obj.dem_info{di}.x_tile_origin + obj.x/obj.dem_info{di}.x_tile_size;
          tile_y = obj.dem_info{di}.y_tile_origin + obj.y/obj.dem_info{di}.y_tile_size;
          tiles = unique(floor([tile_x(:), tile_y(:)]),'rows');
          
          % Download and untar files
          % ===============================================================
          for tiles_idx = 1:size(tiles,1)
            url_list = {};
            xi_list = [];
            yi_list = [];
            if obj.dem_info{di}.subtile_en(ri)
              for sub_x_idx = 1:2
                for sub_y_idx = 1:2
                  if any(tile_x >= tiles(tiles_idx,1) & tile_x <= tiles(tiles_idx,1)+1 ...
                      & tile_y >= tiles(tiles_idx,2) & tile_y <= tiles(tiles_idx,2)+1)
                    % Create URL for subtile file and add to url_list to download
                    url_list{end+1} = [obj.dem_info{di}.url,obj.dem_info{di}.subtile_fn_fh(tiles(tiles_idx,1),tiles(tiles_idx,2),sub_x_idx,sub_y_idx,obj.dem_info{di}.res_str{ri})];
                    xi_list(end+1) = 2*tiles(tiles_idx,1) + sub_x_idx - 2;
                    yi_list(end+1) = 2*tiles(tiles_idx,2) + sub_y_idx - 2;
                    x_tile_size = obj.dem_info{di}.x_subtile_size;
                    y_tile_size = obj.dem_info{di}.y_subtile_size;
                    x_tile_origin = obj.dem_info{di}.x_tile_origin - 1;
                    y_tile_origin = obj.dem_info{di}.y_tile_origin - 1;
                  end
                end
              end
            else
              % Create URL for tile file and add to url_list to download
              url_list{end+1} = [obj.dem_info{di}.url,obj.dem_info{di}.tile_fn_fh(tiles(tiles_idx,1),tiles(tiles_idx,2),obj.dem_info{di}.res_str{ri})];
              xi_list(end+1) = tiles(tiles_idx,1);
              yi_list(end+1) = tiles(tiles_idx,2);
              x_tile_size = obj.dem_info{di}.x_tile_size;
              y_tile_size = obj.dem_info{di}.y_tile_size;
              x_tile_origin = obj.dem_info{di}.x_tile_origin;
              y_tile_origin = obj.dem_info{di}.y_tile_origin;
            end
            
            for url_idx = 1:length(url_list)
              url = url_list{url_idx};
              xi = xi_list(url_idx);
              yi = yi_list(url_idx);
              fprintf('%s: %s\n', datestr(now), url);
              
              [~,url_name,url_ext1] = fileparts(url);
              [~,url_name,url_ext2] = fileparts(url_name);
              % fn: archive file to be downloaded (will be deleted after we are done extracting the tif file)
              fn = fullfile(obj.dem_info{di}.out_path,[url_name,url_ext2,url_ext1]);
              % nc_fn: tif file inside the archive file that we want
              nc_fn = fullfile(obj.dem_info{di}.out_path,[url_name obj.dem_info{di}.tile_fn_ext]);
              
              % Check to see if download file AND tif file do not exist
              if ~exist(fn,'file') && ~exist(nc_fn,'file')
                cmd = sprintf('wget -P %s %s', obj.dem_info{di}.out_path, url);
                fprintf('  %s\n', cmd);
                system(cmd);
                if ~exist(fn,'file')
                  fprintf(2,'    Failed to download file. It may not exist.\n');
                  continue;
                end
              end
              
              % 
              if ~exist(nc_fn,'file')
                fprintf('Untar tar file %s\n  to tif file: %s\n', fn, nc_fn);
                untar(fn, obj.dem_info{di}.out_path);
                if ~exist(nc_fn,'file')
                  error('Failed to find tif file after untar. If tar file is corrupted, try deleting the tar file and starting over so that it will be downloaded again.');
                end
              end
              
              % Delete tar file, but keep tif file
              if exist(fn,'file')
                delete(fn);
              end
              
              if size(obj.dem_all{di},1) < xi || size(obj.dem_all{di},2) < yi ...
                  || isempty(obj.dem_all{di}{xi,yi})
                % Adapted from NSIDC website:
                % Retrieve the image info
                GeoKeys = imfinfo(nc_fn);
                N = GeoKeys.Width;
                M = GeoKeys.Height;
                dx = GeoKeys.ModelPixelScaleTag(1);
                dy = GeoKeys.ModelPixelScaleTag(2);
                minx = GeoKeys.ModelTiepointTag(4);
                maxy = GeoKeys.ModelTiepointTag(5);
                
                % Generate obj.x/obj.y pixel location vectors
                obj.x_all{di}{xi,yi} = minx + dx/2 + ((0:N-1).*dx);
                obj.y_all{di}{xi,yi} = maxy - dy/2 - ((M -1:-1:0).*dy);
                
                % Read the image data
                obj.dem_all{di}{xi,yi} = imread(nc_fn);
                
                % Set bad values to NaN
                obj.dem_all{di}{xi,yi}(obj.dem_all{di}{xi,yi}==obj.dem_info{di}.no_data) = NaN;
                
                % Flip upside down if necessary
                if GeoKeys.Orientation
                  obj.y_all{di}{xi,yi} ...
                    = obj.y_all{di}{xi,yi}(end:-1:1);
                end
              end
              
              x_min_tile = (xi-x_tile_origin) * x_tile_size;
              x_max_tile = x_min_tile + x_tile_size;
              y_min_tile = (yi-y_tile_origin) * y_tile_size;
              y_max_tile = y_min_tile + y_tile_size;
              tile_mask = obj.x >= x_min_tile & obj.x <= x_max_tile ...
                & obj.y >= y_min_tile & obj.y <= y_max_tile;
              land_dem(tile_mask) = interp2(obj.x_all{di}{xi,yi}, ...
                obj.y_all{di}{xi,yi}, obj.dem_all{di}{xi,yi}, obj.x(tile_mask), obj.y(tile_mask),'*linear');
              
            end
          end
        end
        
        % Ocean Mask
        % -----------------------------------------------------------------
        % Use shapefile to determine ocean mask
        
        %         min_x = min(obj.x);
        %         max_x = max(obj.x);
        %         min_y = min(obj.y);
        %         max_y = max(obj.y);
        %
        %         min_lat = min(obj.lat(mask));
        %         max_lat = max(obj.lat(mask));
        %         % Handle longitude in a special way because it wraps around.
        %         mean_lon = angle(mean(exp(1i*obj.lon(mask)/180*pi)))*180/pi;
        %         max_lon = mean_lon + max(angle(exp(1i*(obj.lon(mask)-mean_lon)/180*pi)))*180/pi;
        %         min_lon = mean_lon + min(angle(exp(1i*(obj.lon(mask)-mean_lon)/180*pi)))*180/pi;
        
        % Restrict ocean mask features to our dataset (i.e. mask all features
        % whose bounding boxes fall outside our limits.
        if isempty(obj.ocean.shp)
          ocean_shp = [];
        else
          rel_min_lon = obj.mean_lon + angle(exp(1i*(obj.ocean.bb(1,1:2:end) - obj.mean_lon)/180*pi))*180/pi;
          rel_max_lon = obj.mean_lon + angle(exp(1i*(obj.ocean.bb(2,1:2:end) - obj.mean_lon)/180*pi))*180/pi;
          bb_good_mask = ~(obj.ocean.bb(1,2:2:end)>obj.max_lat | obj.ocean.bb(2,2:2:end)<obj.min_lat ...
            | rel_min_lon>obj.max_lon | rel_max_lon<obj.min_lon);
          ocean_shp = obj.ocean.shp(bb_good_mask);
        end
        
        % Create polygons, poly_x/poly_y, with all ocean shape features which
        % lie in the bounding box.
        % Further restrict the polygons by checking for bounding box overlap in
        % projected coordinates
        poly_x = cell(0);
        poly_y = cell(0);
        for shp_idx = 1:length(ocean_shp)
          % convert polygon to projected coordinates
          [x,y] = projfwd(obj.dem_info{di}.proj,ocean_shp(shp_idx).Y,ocean_shp(shp_idx).X);
          % if polygon is within projected bounding box
          if min(x) < obj.max_x && max(x) > obj.min_x ...
              && min(y) < obj.max_y && max(y)>obj.min_y
            % add polygon
            poly_x{end+1} = [x,nan];
            poly_y{end+1} = [y,nan];
          end
        end
        
        % Create ocean mask to determine which points lie in the ocean
        mask_idxs = find(mask);
        for poly_idx = 1:length(poly_x)
          % Decimate polygon except within the object's bounding box. This
          % is done to speed up inpolygon
          poly_mask = false(size(poly_x{poly_idx}));
          poly_mask(1:obj.ocean_mask_dec:end) = true;
          poly_mask(poly_x{poly_idx}<=obj.max_x&poly_x{poly_idx}>=obj.min_x ...
            & poly_y{poly_idx}<=obj.max_y&poly_y{poly_idx}>=obj.min_y) = true;
          
          % Mask showing which DEM points are in polygon (on land)
          land_mask_tmp = inpolygon(obj.x(mask),obj.y(mask),[poly_x{poly_idx}(poly_mask)],[poly_y{poly_idx}(poly_mask)]);
          ocean_mask(mask_idxs(land_mask_tmp)) = false;
        end
        
        if obj.ocean_mask_mode(1) == 'l'
          % Also use land threshold to determine ocean mask
          land_threshold = 5;
          ocean_mask(land_dem-land_threshold > msl) = false;
        end
        
        % Debug
        % -----------------------------------------------------------------
        if 0
          x_out = obj.x(mask);
          y_out = obj.y(mask);
          dem_out = land_dem(mask);
          dec_idxs = round(linspace(1,length(obj.x(mask)),1000));
          mask_dec_idxs = logical(interp1(1:length(obj.x(mask)), single(ocean_mask(mask)), dec_idxs, 'nearest', 'extrap'));
          along_track = geodetic_to_along_track(obj.lat(mask),obj.lon(mask));
          
          figure(2); clf; colormap(parula(256));
          scatter(along_track(dec_idxs),dem_out(dec_idxs),[],dem_out(dec_idxs));
          hold on;
          scatter(along_track(dec_idxs),msl(dec_idxs),[],msl(dec_idxs));
          plot(along_track(dec_idxs(mask_dec_idxs)),msl(dec_idxs(mask_dec_idxs)),'k.');
          caxis([min(obj.dem.dem{di}(:)) max(obj.dem.dem{di}(:))]);
          
          figure(3); clf; colormap(parula(256));
          scatter(x_out(dec_idxs),y_out(dec_idxs),[],dem_out(dec_idxs));
          hold on;
          plot(x_out(dec_idxs(mask_dec_idxs)),y_out(dec_idxs(mask_dec_idxs)),'k.');
          caxis([min(obj.dem.dem{di}(:)) max(obj.dem.dem{di}(:))]);
        end
      end
      
    end
    
    %% get_vector_mosaic: Get DEM mosaic around geographic vector
    % =====================================================================
    function [land_dem,msl,ocean_mask,proj,x,y] = get_vector_mosaic(obj,res)
      %  When a tile is accessed and it does not exist, then it is
      %  downloaded, loaded, and stored
      
      % Find the first valid dem_info and use this dem's projection to
      % define the proj, x, and y
      proj = obj.dem_info{obj.di(1)}.proj;
      
      % Determine bounds of region of interest
      min_x = round(min(obj.x)/res)*res;
      max_x = round(max(obj.x)/res)*res;
      min_y = round(min(obj.y)/res)*res;
      max_y = round(max(obj.y)/res)*res;

      % Create output mosaic coordinates
      x = min_x : res : max_x;
      y = (min_y : res : max_y).';
      x_mesh = repmat(x,[size(y,1) 1]);
      y_mesh = repmat(y,[1 size(x,2)]);
      [lat_mesh,lon_mesh] = projinv(proj,x_mesh,y_mesh);

      obj.set_vector(lat_mesh,lon_mesh);
      
      [land_dem,msl,ocean_mask] = get_vector_dem(obj);
      
    end
    
    %% clear: Clear all loaded DEMs from memory
    % =====================================================================
    function clear(obj)
      obj.dem_all = cell(size(obj.dem_info));
      obj.x_all = cell(size(obj.dem_info));
      obj.y_all = cell(size(obj.dem_info));
    end
    
    %% reset: Reset to load a new segment
    % =====================================================================
    function reset(obj)
      if ~isempty(obj.di)
        for di = unique(obj.di)
          mask = obj.di == di;
          if all(~mask)
            continue
          end
          ri = obj.get_ri(di);
          
          if obj.dem_info{di}.tile_en(ri)
            % Tiles were used, so clear all loaded DEMs since it is likely that
            % they will not be reused
            obj.clear();
          end
        end
      end
      
      % Geographic vector
      obj.di = [];
      obj.x = [];
      obj.y = [];
      obj.lat = [];
      obj.lon = [];
      
      % Region of interest fields
      obj.name = [];
      obj.dem.dem = cell(size(obj.dem_info));
      obj.dem.x = cell(size(obj.dem_info));
      obj.dem.y = cell(size(obj.dem_info));
    end
    
    %% set_res: Set resolution
    % =====================================================================
    function set_res(obj,res)
    end
    
    %% get_ri: Get resolution index
    % =====================================================================
    function ri = get_ri(obj,di)
      ri = 1;
    end
    
    %% set_dem_mode: Set to retrieve thickness or ice bottom
    % =====================================================================
    function set_dem_mode(obj,dem_mode)
      % dem_mode is either 'bed' or 'thickness' and controls which DEM product
      % is returned
      if ~isequal(dem_mode,obj.dem_mode)
        obj.clear();
        obj.reset();
        obj.dem_mode = dem_mode;
      end
    end
    
  end
  
  
end
