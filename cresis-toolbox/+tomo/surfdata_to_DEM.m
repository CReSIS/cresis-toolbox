function surfdata_to_DEM(param,param_override)
% surfdata_to_DEM(param,param_override))
%
% Takes a 3D image and surfdata and produces output data products for the
% specified surfaces that include jpg images, geotiff of the surface, and
% CSV point files.
%
% param.dem.geotiff_fn: string containing the filename of the geotiff to
%   use for the maps
% param.dem.ice_top: string containing the surface name for the top of the
%   ice
% param.dem.surface_names: cell array of strings contains the surface names
%   that should be processed
% param.dem.grid_spacing: scalar in meters (e.g. 25)
% param.dem.DOA_trim: how many DOA resolution cells to trim off on the
%   edges of the swath. Set DOA_trim=0 if DOA method is used.
% param.dem.med_filt: median2 filter arguments, 2-element double vector.
%   This is the [M N] vector in "B = medfilt2(A,[M N])"
% param.dem.figure_dots_per_km: scalar containing dots per km in the
%   output figures (e.g. 20)
% param.dem.ice_mask_ref: string containing the reference citation for the
%   ice mask data
% param.dem.geotiff_ref: string containing the reference citation for the
%   geotiff data
% param.dem.DEM_ref: string containing the reference citation for the
%   DEM data
% param.dem.surfdata_source: ct_filename_out argument to where the surfdata
%   are located (e.g. 'surfData')
% param.dem.input_dir_name: ct_filename_out argument to where the 3D image
%   is located (e.g. 'music')
% param.dem.output_dir_name: ct_filename_out argument to where the data
%   products should be stored (e.g. 'dem')
% param.dem.theta_cal_fn: string containing filename to steering vector
%   calibration file
%
% Authors: Jordan Sprick, Nick Holschuh, John Paden, Victor Berger
%
% See also: surfdata_to_DEM.m, run_surfdata_to_DEM.m

%% General Setup
% =====================================================================

if ~isstruct(param)
  % Functional form
  param();
end
param = merge_structs(param, param_override);

dbstack_info = dbstack;
fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', dbstack_info(1).name, param.day_seg, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

%% Input Checks: cmd
% =====================================================================

% Remove frames that do not exist from param.cmd.frms list
frames = frames_load(param);
param.cmd.frms = frames_param_cmd_frms(param,frames);

%% Input Checks: dem
% =====================================================================

physical_constants;

if ~isfield(param.dem,'doa_method_flag') || isempty(param.dem.doa_method_flag)
  doa_method_flag = false;
else
  doa_method_flag = param.dem.doa_method_flag;
end

if ~isfield(param.dem,'doa_limits') || isempty(param.dem.doa_limits)
  doa_limits = [-90 90]*pi/180;
else
  doa_limits = param.dem.doa_limits*pi/180;
end

% dem.er_ice: the relative dielectric of ice (defaults to 3.15 from
% physical_constants.m which is generally the setting for creating digital
% elevation models of the ice bottom). Set this to 1 for air (e.g. when
% producing a dem for an ice surface that is not the param.dem.ice_top).
% Note that this setting does not have any effect for the surface indicated by
% param.dem.ice_top (i.e. the value does not matter).
if ~isfield(param.dem,'er_ice') || isempty(param.dem.er_ice)
  param.dem.er_ice = er_ice;
end

% dem.enforce_below_top: forces the surface to be below the top surface
% (i.e. the ice surface). Defaults to true which is the setting for
% creating DEMs of the ice bottom. Set to false to generate DEMs of the ice
% surface. Note that this setting does not have any effect for the surface
% indicated by param.dem.ice_top (i.e. can be true or false).
if ~isfield(param.dem,'enforce_below_top') || isempty(param.dem.enforce_below_top)
  param.dem.enforce_below_top = true;
end

if ~isfield(param.dem,'ice_mask') || isempty(param.dem.ice_mask)
  param.dem.ice_mask = [];
end

if ~isfield(param.dem,'ice_mask_flag') || isempty(param.dem.ice_mask_flag)
  param.dem.ice_mask_flag = false;
end

if ~isfield(param.dem,'array_manifold_mask_flag') || isempty(param.dem.array_manifold_mask_flag)
  param.dem.array_manifold_mask_flag = false;
end

if param.dem.array_manifold_mask_flag
  param.dem.array_manifold_mask_flag = true;
  if isempty(param.dem.ice_mask)
    error('User must specify an ice mask surface to derive the array manifold mask')
  end
end    

surface_names = param.dem.surface_names;
figure_dots_per_km = param.dem.figure_dots_per_km;

out_dir = ct_filename_out(param,param.dem.output_dir_name);
if ~isdir(out_dir)
  mkdir(out_dir);
end

%% Loop through each frame and create data products
% =====================================================================
for frm_idx = 1:length(param.cmd.frms)
  
  frm = param.cmd.frms(frm_idx);
  notes = sprintf('%s %s_%03d (%d of %d)', ...
    param.radar_name, param.day_seg, frm, frm_idx, length(param.cmd.frms));
  fprintf('%s (%s)\n', notes, datestr(now));
  
  surfdata_fn = fullfile(ct_filename_out(param,param.dem.surfdata_source),sprintf('Data_%s_%03d.mat',param.day_seg,frm));
  data_fn = fullfile(ct_filename_out(param,param.dem.input_dir_name),sprintf('Data_%s_%03d.mat',param.day_seg,frm));
  
  %% Load surfdata, echogram, steering vector calibration and handle error conditions
  
  % Load surface data (usually top and bottom)
  fprintf('  %s\n', surfdata_fn);
  if ~doa_method_flag
  sd = tomo.surfdata(surfdata_fn);
  else
    sd_param.doa_method_flag = doa_method_flag;
    sd = tomo.surfdata(surfdata_fn,sd_param);
  end
  
  % Find the index to the ice top
  ice_top_idx = sd.get_index(param.dem.ice_top);
  
  if ~isempty(find(strcmp(param.dem.ice_mask,{sd.surf.name}))) && param.dem.ice_mask_flag
    ice_mask_idx = sd.get_index(param.dem.ice_mask);
    ice_mask = sd.surf(ice_mask_idx).y; 
    array_manifold_mask = ice_mask;
    array_manifold_mask = cumsum(array_manifold_mask,1,'reverse') >= 1 | cumsum(array_manifold_mask,1,'forward') >= 1;
  else
    ice_mask_idx =[];
    ice_mask = [];
    array_manifold_mask = [];
  end
  
  if isempty(ice_mask) && param.dem.array_manifold_mask_en
    error('No valid ice mask found in surfdata file')
  end
  
  if isempty(ice_mask) && param.dem.ice_mask
    error('No valid ice mask found in surfdata file')
  end
  
  % Load the echogram
  fprintf('  %s\n', data_fn);
  mdata = load(data_fn);
  
  % Load the steering vector calibration file if specified
  if(~isfield(mdata.Tomo,'theta'))
    global gRadar
    theta = load(fullfile(gRadar.out_path,'rds','2014_Greenland_P3','CSARP_CSA_music','20140401_03','Data_20140401_03_037'),'theta');
    mdata.Tomo.theta = theta.theta;
  end
  
  %% Setup for convert doa,twtt to radar FCS for each surface
  
  % FCS: flight coordinate system (aka SAR coordinate system)
  Nx = length(mdata.GPS_time);
  if ~doa_method_flag
    theta = reshape(mdata.theta,[length(mdata.theta) 1]);
  else
    theta = mdata.Tomo.theta;
  end
  
  DOA_trim = 0;
  if ~doa_method_flag
    if isfield(param.dem,'DOA_trim')
      DOA_trim = param.dem.DOA_trim;
    end
  end
  
  % Convert top from range bins to twtt (the top is needed with each
  % surface to handle refraction)
  ice_top = sd.surf(ice_top_idx).y;
  % If no top defined, then assume top is a zero time (i.e.
  %   ground based radar operation with antenna at surface)
  if all(all(isnan(ice_top)))
    ice_top = zeros(size(ice_top));
  end
  
  % Setup Bounds of DEM
  min_x = inf;
  max_x = -inf;
  min_y = inf;
  max_y = -inf;
  
  %% Convert doa,twtt to radar FCS for each surface
  for surface_names_idx = 1:numel(surface_names)
    
    % Determine which surface index in surfData file we are working with
    surface_idx = sd.get_index(surface_names{surface_names_idx});
    
    if param.dem.enforce_below_top
      % Ensure non-negative ice thickness (threshold all values above the
      % ice surface ("top") to be equal to the ice surface)
      sd.surf(surface_idx).y(sd.surf(surface_idx).y<sd.surf(ice_top_idx).y) = sd.surf(ice_top_idx).y(sd.surf(surface_idx).y<sd.surf(ice_top_idx).y);
    end
    
    % Convert surface from range bins to twtt
    surface_twtt = sd.surf(surface_idx).y;
    % Apply spatial filtering
    if isfield(param.dem,'med_filt') && ~isempty(param.dem.med_filt)
      surface_twtt = medfilt2(surface_twtt,param.dem.med_filt);
      surface_twtt(:,1:floor(param.dem.med_filt(2)/2)) = NaN;
      surface_twtt(:,end-floor(param.dem.med_filt(2)/2)+1:end) = NaN;
    end
    
  %%%%%%%%%%% This section accomodates ground-based data collection
    if ~isfield(param.dem,'ground_based_flag')
      er_surf = 1;
    else
      if param.dem.ground_based_flag == true;      
        if isfield(param.dem,'er_z') 
          % er_z is an Nx2 matrix containing depths, and
          % associated complex permittivities. For ground data,
          % the real permittivity at the surface is used for
          % down-going refraction
          
          % Identify the surface index.
          [~,s_ind] = min(abs(param.dem.er_z(:,1)));
          
          % Then extract the permittivity at that depth
          er_surf = real(param.dem.er_z(s_ind,2)); 
        else
          er_surf = 1;
        end
        
        % For files that have erroneous steering vectors (that
        % assume the medium containing the antenna is air, when
        % it is not), the resulting theta matrix is adjusted
        % here.
        if isfield(param.dem,'theta_adjust')
          if param.dem.theta_adjust == true
            theta = asin(sin(theta)*1/sqrt(er_surf));
          end
        end
        
      else
        er_surf = 1;
      end      
    end
    
    if ~doa_method_flag
      [y_active,z_active] = tomo.twtt_doa_to_yz(repmat(theta(DOA_trim+1:end-DOA_trim),[1 Nx]), ...
        theta(DOA_trim+1:end-DOA_trim),ice_top(DOA_trim+1:end-DOA_trim,:), ...
        er_surf,param.dem.er_ice,surface_twtt(DOA_trim+1:end-DOA_trim,:));
    else
      [y_active,z_active] = tomo.twtt_doa_to_yz(theta, ...
        [],ice_top,er_surf,param.dem.er_ice,surface_twtt,doa_method_flag,doa_limits);
    end
    
    % Convert from radar FCS to ECEF
    x_plane = zeros(size(y_active));
    y_plane = zeros(size(y_active));
    z_plane = zeros(size(y_active));
    for rline = 1:size(y_active,2)
      x_plane(:,rline) = mdata.param_array.array_proc.fcs.origin(1,rline) ...
        + mdata.param_array.array_proc.fcs.y(1,rline) * y_active(:,rline) ...
        + mdata.param_array.array_proc.fcs.z(1,rline) * z_active(:,rline);
      y_plane(:,rline) = mdata.param_array.array_proc.fcs.origin(2,rline) ...
        + mdata.param_array.array_proc.fcs.y(2,rline) * y_active(:,rline) ...
        + mdata.param_array.array_proc.fcs.z(2,rline) * z_active(:,rline);
      z_plane(:,rline) = mdata.param_array.array_proc.fcs.origin(3,rline) ...
        + mdata.param_array.array_proc.fcs.y(3,rline) * y_active(:,rline) ...
        + mdata.param_array.array_proc.fcs.z(3,rline) * z_active(:,rline);
    end
    
    % Convert from ECEF to geodetic
    [points.lat,points.lon,points.elev] = ecef2geodetic(x_plane,y_plane,z_plane,WGS84.ellipsoid);
    points.lat = points.lat * 180/pi;
    points.lon = points.lon * 180/pi;
    
    % Convert from geodetic to projection
    proj = geotiffinfo(param.dem.geotiff_fn);
    [points.x,points.y] = projfwd(proj,points.lat,points.lon);
    
    if 0
      % Debug plot
      clf;
      good_mask = isfinite(points.elev);
      scatter(points.lon(good_mask),points.lat(good_mask),[],points.elev(good_mask),'Marker','.')
      hcolor = colorbar;
      set(get(hcolor,'YLabel'),'String','Elevation (WGS-84,m)')
      hold on;
      hplot = plot(points.lon(33,:),points.lat(33,:),'k');
      xlabel('Longitude (deg,E)');
      ylabel('Latitude (deg,N)');
      legend(hplot,'Flight line');
    end
    
    % Keep track of min/max bounds of each surface
    min_x = min(min_x,min(points.x(:)));
    max_x = max(max_x,max(points.x(:)));
    min_y = min(min_y,min(points.y(:)));
    max_y = max(max_y,max(points.y(:)));
    
    % Stash these results for later so we don't have to recreate
    points_stash{surface_idx} = points;
    
  end
  % Clean up
  clear surface_twtt y_active z_active x_plane y_plane z_plane;
  
  % Setup Bounds of data products
  min_x = param.dem.grid_spacing * round(min_x/param.dem.grid_spacing);
  max_x = param.dem.grid_spacing * round(max_x/param.dem.grid_spacing);
  min_y = param.dem.grid_spacing * round(min_y/param.dem.grid_spacing);
  max_y = param.dem.grid_spacing * round(max_y/param.dem.grid_spacing);
  
  %% Create data products for each surface
  h_fig_dem = [];
  for surface_names_idx = 1:numel(surface_names)
    
    % Find the index of this surface in the surfData file
    surface_idx = sd.get_index(surface_names{surface_names_idx});
    
    % Create the file output surface name
    surf_str = surface_names{surface_names_idx};
    surf_str(~isstrprop(surf_str,'alphanum')) = '_';
    
    %  Grab DEM points from stash
    points = points_stash{surface_idx};
    
    % Find the index for the quality layer
    quality_idx = sd.get_index(param.dem.quality_surface_names{surface_names_idx});
    
    %% Grid data
    grid_spacing = 25;
    xaxis = min_x:grid_spacing:max_x;
    yaxis = (min_y:grid_spacing:max_y).';
    [xmesh,ymesh] = meshgrid(xaxis,yaxis);
    
    % Create a constrained delaunay triangulization that forces edges
    % along the boundary (concave_hull) of our swath
    sd.surf(quality_idx).y(:) = 1;
    good_mask = isfinite(points.x) & isfinite(points.y) & isfinite(points.elev) & sd.surf(quality_idx).y(DOA_trim+1:end-DOA_trim,:);
    
    if 0
      % This method only handles a single object/region
      row = find(good_mask,1);
      col = floor(row/size(good_mask,1)) + 1;
      row = row - (col-1)*size(good_mask,1);
      B = bwtraceboundary(good_mask,[row col],'S',8,inf,'counterclockwise');
      B = B(:,1) + (B(:,2)-1)*size(good_mask,1);
      concave_hull = [B(1:end-1) B(2:end); B(end) B(1)];
      
    elseif 0
      % This method finds all regions, but still has problems when
      % constraints get dropped in Delaunay triangulization
      B = bwboundaries(good_mask,8);
      polyB_x = cell(size(B));
      polyB_y = cell(size(B));
      for idx=1:length(polyB_x)
        polyB_x{idx} = B{idx}(:,1).';
        polyB_y{idx} = B{idx}(:,2).';
      end
      B = [];
      [B(:,1),B(:,2)] = polygon_join(polyB_x,polyB_y);
      
      B = B(:,1) + (B(:,2)-1)*size(good_mask,1);
      concave_hull = [B(1:end-1) B(2:end)];
      
    elseif 0
      % This method is not exhausitively tested and does not handle cutouts
      % in the good_mask (these cutouts are interpolated)
      
      % bwboundaries: Returns a polygon for every distinct (nonoverlapping) object
      % This is necessary because the swath could be broken into multiple sections if there is bad quality or missing data
      [Bs,Bs_L,Bs_N,Bs_A] = bwboundaries(good_mask,8);
      DEM_final = [];
      IMG_3D_final = [];
      % Create the DEM and 3D image for each distinct object and then combine them all into one DEM/IMG_3D
      for B_idx = 1:length(Bs)
        
        if any(Bs_A(B_idx,:))
          % This polygon is a child of another polygon (i.e. it is within another polygon and we ignore it)
          continue
        end
        % Get the boundary polygon that we are working on
        B = Bs{B_idx};
        % Convert row,col indexing to single index
        B = B(:,1) + (B(:,2)-1)*size(good_mask,1);
        % Close the polygon and convert to concave hull format:
        % First column: Start index of edge
        % Second column: End index of edge
        concave_hull = [B(1:end-1) B(2:end); B(end) B(1)];
        
        % Get just the indices for the object that is surrounded by the polygon Bs(B_idx)
        good_idxs = find(Bs_L == B_idx);
        % Translate these absolute (to the good_mask matrix) indices into a relative indexing
        % on this object only.
        new_good_idxs = 1:length(good_idxs);
        idx_translate = zeros(size(good_mask));
        idx_translate(good_idxs) = new_good_idxs;
        concave_hull = idx_translate(concave_hull);
        
        % Get the 3D points/gps_time corresponding to this object, note that the ordering
        % of these "pnts" and "gps_time" is in the relative indexing
        pnts = zeros(3,length(good_idxs));
        pnts(1,:) = points.x(good_idxs);
        pnts(2,:) = points.y(good_idxs);
        pnts(3,:) = points.elev(good_idxs);
        ice_mask_pnts = ice_mask(good_idxs);
        gps_time = repmat(mdata.GPS_time,size(good_mask,1),1);
        gps_time = gps_time(good_idxs);
        
        % The concave hull has to be one polygon with no intersections
        % The boundary polygon meets this requirement, but the "pnts" associated with
        % this object may not. Since the triangulization is based on "pnts", we need
        % to adjust concave_hull in the pnts domain.
        px = pnts(1,concave_hull(:,1));
        py = pnts(2,concave_hull(:,1));
        
        [px,py,idxs] = tomo.remove_intersections(px,py,0.1,true);
        if isempty(idxs)
          % No valid points in this region
          continue;
        end
        c1 = concave_hull(idxs(~isnan(idxs)),1);
        
        concave_hull = zeros(length(c1),2);
        concave_hull(:,1) = c1;
        concave_hull(:,2) = [c1(2:end);c1(1)];
        
        % Perform constrained triangulization
        dt = DelaunayTri(pnts(1,:).',pnts(2,:).',concave_hull);
        
        % Interpolate to find gridded DEM
        warning off;
        F = TriScatteredInterp(dt,pnts(3,:).');
        warning on;
        DEM = F(xmesh,ymesh);
        
        % Interpolate to find gridded 3D image
        img_3D_idxs = round(interp1(mdata.Time, 1:length(mdata.Time), sd.surf(surface_idx).y(:))) + size(mdata.Tomo.img,1)*(0:numel(sd.surf(surface_idx).y)-1).';
        img_3D = NaN*zeros(size(img_3D_idxs));
        img_3D(~isnan(img_3D_idxs)) = mdata.Tomo.img(img_3D_idxs(~isnan(img_3D_idxs)));
        img_3D = double(reshape(img_3D, size(sd.surf(surface_idx).y)));
        img_3D = img_3D(DOA_trim+1:end-DOA_trim,:);
        warning off;
        F = TriScatteredInterp(dt,img_3D(good_idxs));
        warning on;
        IMG_3D = F(xmesh,ymesh);
        
        % Use the to remove interpolation outside the boundary
        if 1
          % Slow method using inpolygon
          idxs_to_check = find(~isnan(DEM));
          bad_mask = ~inpolygon(xmesh(idxs_to_check),ymesh(idxs_to_check),px,py);
          DEM(idxs_to_check(bad_mask)) = NaN;
          IMG_3D(idxs_to_check(bad_mask)) = NaN;
        else
          % Faster method using inOutStatus/pointLocation with edge constraints
          % Finds the triangles outside the concave hull (the bad ones). The
          % technique, although faster, is not reliable for complicated
          % polygons because the Delaunay triangulation removes duplicate
          % edges which means the concave hull can be distorted and no longer
          % work properly for in/out calculations.
          
          bad_tri_mask = ~inOutStatus(dt);
          % Selects just the points that were in the convex hull
          constraint_mask = ~isnan(DEM);
          constraint_mask_idx = find(constraint_mask);
          % For each point in the convex hull, find the triangle enclosing it
          tri_list = pointLocation(dt,xmesh(constraint_mask),ymesh(constraint_mask));
          % Use the bad triangle list to find the bad points
          bad_mask = bad_tri_mask(tri_list);
          % Set all the points in bad triangles to NaN
          constraint_mask(constraint_mask_idx(bad_mask)) = 0;
          DEM(~constraint_mask) = NaN;
          IMG_3D(~constraint_mask) = NaN;
        end
        
        % Combine DEM and IMG_3D from each polygon into a final DEM/IMG_3D
        if isempty(DEM_final)
          DEM_final = DEM;
        else
          DEM_final(~isnan(DEM)) = DEM(~isnan(DEM));
        end
        if isempty(IMG_3D_final)
          IMG_3D_final = IMG_3D;
        else
          IMG_3D_final(~isnan(IMG_3D)) = IMG_3D(~isnan(IMG_3D));
        end
      end
      DEM = DEM_final;
      IMG_3D = IMG_3D_final;
      
    else
      % bwboundaries: Returns a polygon for every distinct (nonoverlapping) object
      % This is necessary because the swath could be broken into multiple sections if there is bad quality or missing data
      [B_all,B_L,~,B_A] = bwboundaries(good_mask,8,'holes');
      
      % Convert cell format of B_all to vector polygon format
      B_x = cell(size(B_all));
      B_y = cell(size(B_all));
      for B_idx=1:length(B_all)
        if any(B_A(B_idx,:))
          % This polygon is inside of another.
          
          % Background:
          % The outermost polygons trace objects. For us objects are
          % the good regions where good_mask = 1. For bwboundaries.m, the
          % polygon boundaries of objects lie completely within the object
          % so that all the boundary pixels have good_mask = 1.
          % Polygon boundaries inside another polygon trace the boundary
          % of holes in the object. These holes are defined as regions
          % where good_mask = 0 that are completely inside the object.
          % The polygon boundary of holes lies completely in the good_mask
          % = 0 region.
          
          % Solution:
          % We retrace the hole after growing the hole region. The
          % polygon boundary for the hole region, after growing the hole by
          % one, will lie completely in the good_mask = 1 region.
          B_hole = bwboundaries(grow(B_L==B_idx,1,8),8,'noholes');
          B_x{B_idx} = B_hole{1}(:,1);
          B_y{B_idx} = B_hole{1}(:,2);
        else
          B_x{B_idx} = B_all{B_idx}(:,1);
          B_y{B_idx} = B_all{B_idx}(:,2);
        end
      end
      [B_x,B_y] = polyjoin(B_x,B_y);
      
      % Convert row,col indexing to single index (both still absolute
      % indexing in good_mask)
      B = B_x + (B_y-1)*size(good_mask,1);
      % Close the polygon:
      B = [B(1:end); B(1)];
      
      % Get just the indices for the object that is surrounded by the polygon Bs(B_idx)
      good_idxs = find(good_mask);
      % Translate these absolute (to the good_mask matrix) indices into a relative indexing
      % on this object only.
      new_good_idxs = 1:length(good_idxs);
      idx_translate = zeros(size(good_mask));
      idx_translate(good_idxs) = new_good_idxs;
      B(~isnan(B)) = idx_translate(B(~isnan(B)));
      
      % Get the 3D points/gps_time corresponding to this object, note that the ordering
      % of these "pnts" and "gps_time" is in the relative indexing
      pnts = zeros(3,length(good_idxs));
      pnts(1,:) = points.x(good_idxs);
      pnts(2,:) = points.y(good_idxs);
      pnts(3,:) = points.elev(good_idxs);
      gps_time = repmat(mdata.GPS_time,size(good_mask,1),1);
      gps_time = gps_time(good_idxs);
      
      % Convert boundary B (which is now in relative indexing into
      % good_idxs) into a polygon in XY projection space.
      px = B;
      py = B;
      px(~isnan(B)) = pnts(1,B(~isnan(B)));
      py(~isnan(B)) = pnts(2,B(~isnan(B)));
      
      % Perform constrained triangulization
      dt = DelaunayTri(pnts(1,:).',pnts(2,:).');
      
      % Interpolate to find gridded DEM
      warning off;
      F = TriScatteredInterp(dt,pnts(3,:).');
      warning on;
      DEM = F(xmesh,ymesh);
      
      if param.dem.ice_mask_flag
        ice_mask_pnts = ice_mask(good_idxs);
        ice_mask_eval = double(ice_mask_pnts);        
        Fi = TriScatteredInterp(dt,ice_mask_eval(:),'nearest');
        ice_mask_dem = Fi(xmesh,ymesh);
        ice_mask_dem = logical(round(ice_mask_dem));
        
%         ICE_MASK = Fi(xmesh,ymesh);
%         ICE_MASK = logical(round(ICE_MASK));
        
        if param.dem.array_manifold_mask_flag
          array_manifold_mask_pnts = array_manifold_mask(good_idxs);
          array_manifold_mask_eval = double(array_manifold_mask_pnts);
          Fa = TriScatteredInterp(dt,array_manifold_mask_eval(:),'nearest');
          array_manifold_mask_dem =  Fa(xmesh,ymesh);
          array_manifold_mask_dem = logical(round(array_manifold_mask_dem));
%           ARRAY_MANIFOLD_MASK = Fa(xmesh,ymesh);
%           ARRAY_MANIFOLD_MASK = logical(round(ARRAY_MANIFOLD_MASK));
        end       
      end
      
      if 0
        % Debug
        figure;imagesc(DEM)
        h = colorbar;
        h.Label.String = 'Elevation (m)';
      end
      % Interpolate to find gridded 3D image
      if ~doa_method_flag
        % Beamforming method
        img_3D_idxs = round(interp1(mdata.Time, 1:length(mdata.Time), sd.surf(surface_idx).y(:))) + size(mdata.Tomo.img,1)*(0:numel(sd.surf(surface_idx).y)-1).';
        img_3D = NaN(size(img_3D_idxs));
        img_3D(~isnan(img_3D_idxs)) = mdata.Tomo.img(img_3D_idxs(~isnan(img_3D_idxs)));
        img_3D = double(reshape(img_3D, size(sd.surf(surface_idx).y)));
        img_3D = img_3D(DOA_trim+1:end-DOA_trim,:);
        doa_ax_trim = sd.surf(surface_idx).x(DOA_trim + 1:end-DOA_trim,:);
        ice_mask_trim = ice_mask(DOA_trim+1:end-DOA_trim,:);
      else
        % DOA method: 3D points are the estmated DOAs, which are usually
        % different for each range-line.
        img_3D = NaN(size(sd.surf(surface_idx).y));
        for rline = 1:size(mdata.Tomo.theta,3)
          tmp_theta = mdata.Tomo.theta(:,:,rline);
          tmp_theta = sort(tmp_theta(~isnan(tmp_theta)),'ascend');
%           if ~all(isnan(tmp_theta(:)))
            % Interpolate the bad (NaN) points in between the good points
%             for theta_idx = 1:size(mdata.Tomo.theta,2)
%               good_theta_idx = find(~isnan(tmp_theta(:,theta_idx)));
%               tmp_theta(good_theta_idx(1):good_theta_idx(end),theta_idx) = interp1(good_theta_idx,tmp_theta(good_theta_idx,theta_idx),[good_theta_idx(1):good_theta_idx(end)].');
%             end
            img_3D(1:length(tmp_theta),rline) = sort(tmp_theta,'ascend');
%           end
        end
        img_3D(img_3D<doa_limits(1) | img_3D>doa_limits(2)) = NaN;
      end
      warning off;
      F = TriScatteredInterp(dt,img_3D(good_idxs));
      F2 = TriScatteredInterp(dt,doa_ax_trim(good_idxs));
      warning on;
      IMG_3D = F(xmesh,ymesh);
      DOA_GRID = F2(xmesh,ymesh);
      
      % Use inpolygon to find bad interpolation points and set to NaN
      idxs_to_check = find(~isnan(DEM));
      bad_mask = ~inpolygon(xmesh(idxs_to_check),ymesh(idxs_to_check),px,py);
      DEM(idxs_to_check(bad_mask)) = NaN;
      IMG_3D(idxs_to_check(bad_mask)) = NaN;
      DOA_GRID(idxs_to_check(bad_mask))=NaN;
      if param.dem.ice_mask_flag
        nan_mask = idxs_to_check(bad_mask);
        ICE_MASK = ice_mask_dem;
        ICE_MASK(nan_mask) = true;
%         ICE_MASK(~nan_mask) = ice_mask_dem;
%         ICE_MASK(idxs_to_check(bad_mask)) = NaN;
        if param.dem.array_manifold_mask_flag
          ARRAY_MANIFOLD_MASK = array_manifold_mask_dem;
          ARRAY_MANIFOLD_MASK(nan_mask) = true;
%           ARRAY_MANIFOLD_MASK(idxs_to_check(bad_mask)) = NaN;
        end
      end
    end
    
    %% Create DEM scatter plot over geotiff
    try; delete(h_fig_dem); end; h_fig_dem = figure; clf;
    
    % Load and plot background geotiff
    [RGB_bg, R_bg, ~] = geotiffread(param.dem.geotiff_fn);
    h_axes = axes;
    h_img = imagesc( (R_bg(3,1) + R_bg(2,1)*(0:size(RGB_bg,2)-1))/1e3, ...
      (R_bg(3,2) + R_bg(1,2)*(0:size(RGB_bg,1)-1))/1e3, RGB_bg,'parent',h_axes);
    set(gca,'YDir','normal');
    hold on;
    
    % Plot the data in the desired format
    if 0
      contourf((xaxis-xaxis(1))/1e3,(yaxis-yaxis(1))/1e3,DEM_contour,linspace(zlims(1),zlims(end),20));
    elseif 0
      good_mask = isfinite(points.elev);
      scatter(points.x(good_mask)/1e3,points.y(good_mask)/1e3,[],points.elev(good_mask),'Marker','.');
    else
      % DEBUG ONLY CODE FOR PLOTTING TGRS ERROR MAPS
      if 0
%         dat = load('/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_DEM_tgrs2021_evd_20140506_01_lut_error_maps/20140401_03/20140401_03_042_top_lut.mat');
        dat = load('/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_DEM_nominal_tgrs2021_error_maps/20140401_03/20140401_03_042_top_lut.mat');
        dem1 = nan(size(DEM));
        dem1(~ARRAY_MANIFOLD_MASK) = DEM(~ARRAY_MANIFOLD_MASK);
        mask1 = nan(size(DEM));
       
        dem2 = nan(size(dat.ARRAY_MANIFOLD_MASK));
        dem2(~dat.ARRAY_MANIFOLD_MASK) = dat.DEM(~dat.ARRAY_MANIFOLD_MASK);
        nanmask = dem2==32767;
        dem2(nanmask) = nan;
        
        error_map = dem1 - dem2;
        imagesc(xaxis/1e3,yaxis/1e3,error_map,'parent',h_axes,'alphadata',~isnan(error_map));
        % Plot flightline
        [fline.lat,fline.lon,fline.elev] = ecef2geodetic( ...
          mdata.param_array.array_proc.fcs.origin(1,:), ...
          mdata.param_array.array_proc.fcs.origin(2,:), ...
          mdata.param_array.array_proc.fcs.origin(3,:),WGS84.ellipsoid);
        fline.lat = fline.lat*180/pi;
        fline.lon = fline.lon*180/pi;
        [fline.x,fline.y] = projfwd(proj,fline.lat,fline.lon);
        hplot = plot(fline.x/1e3,fline.y/1e3,'k');
        
        % Colorbar, labels, and legends
        hcolor = colorbar;
        set(get(hcolor,'YLabel'),'String','Elevation (WGS-84,m)');
        xlabel('X (km)');
        ylabel('Y (km)');
        legend(hplot,'Flight line');
        
        axis(axis_equal(h_axes, fline.x,fline.y));
        h_fig_dem.Position = [50 50 800 600];
        set(h_fig_dem,'PaperPositionMode','auto');
        %
        % Clip and decimate the geotiff because it is usually very large
        clip_and_resample_image(h_img,gca,10);
        title(sprintf('DEM %s_%03d %s',param.day_seg,frm,surface_names{surface_names_idx}),'interpreter','none');
        
        % Save output
        out_fn_name = sprintf('%s_%03d_%s',param.day_seg,frm,'error');
        out_fn = [fullfile(out_dir,out_fn_name),'.fig'];
        fprintf('  %s\n', out_fn);
        saveas(h_fig_dem,out_fn);
        keyboard
        
      else
        imagesc(xaxis/1e3,yaxis/1e3,DEM,'parent',h_axes,'alphadata',~isnan(DEM));
      end
    end
    
    % Plot flightline
    [fline.lat,fline.lon,fline.elev] = ecef2geodetic( ...
      mdata.param_array.array_proc.fcs.origin(1,:), ...
      mdata.param_array.array_proc.fcs.origin(2,:), ...
      mdata.param_array.array_proc.fcs.origin(3,:),WGS84.ellipsoid);
    fline.lat = fline.lat*180/pi;
    fline.lon = fline.lon*180/pi;
    [fline.x,fline.y] = projfwd(proj,fline.lat,fline.lon);
    hplot = plot(fline.x/1e3,fline.y/1e3,'k');
    
    % Colorbar, labels, and legends
    hcolor = colorbar;
    set(get(hcolor,'YLabel'),'String','Elevation (WGS-84,m)');
    xlabel('X (km)');
    ylabel('Y (km)');
    legend(hplot,'Flight line');
    
    axis(axis_equal(h_axes, fline.x,fline.y));
    h_fig_dem.Position = [50 50 800 600];
    
    % Set figure/axes to 1 km:1 km scaling with a buffer around product
%         map_buffer = 2e3;
%         map_axis = min_x-map_buffer;
%         map_axis(2) = max_x+map_buffer;
%         map_axis(3) = min_y-map_buffer;
%         map_axis(4) = max_y+map_buffer;
%     %     axis(h_axes, map_axis/1e3);
%     
%         set(h_axes,'Units','pixels');
%         map_axes = get(h_axes,'Position');
%         set(h_fig_dem,'Units','pixels');
%         map_pos = get(h_fig_dem,'Position');
%     
%         map_new_axes = map_axes;
%         map_new_axes(3) = round(figure_dots_per_km*(map_axis(2)-map_axis(1))/1e3);
%         map_new_axes(4) = round(figure_dots_per_km*(map_axis(4)-map_axis(3))/1e3);
%         map_pos(3) = map_new_axes(3) + map_pos(3)-map_axes(3);
%         map_pos(4) = map_new_axes(4) + map_pos(4)-map_axes(4);
%     %     set(h_fig_dem,'Position',map_pos);
%     %     set(h_axes,'Position',map_new_axes);
    set(h_fig_dem,'PaperPositionMode','auto');  
%     
    % Clip and decimate the geotiff because it is usually very large
    clip_and_resample_image(h_img,gca,10);
    title(sprintf('DEM %s_%03d %s',param.day_seg,frm,surface_names{surface_names_idx}),'interpreter','none');
    
    % Save output
    out_fn_name = sprintf('%s_%03d_%s',param.day_seg,frm,surf_str);
    out_fn = [fullfile(out_dir,out_fn_name),'.fig'];
    fprintf('  %s\n', out_fn);
    saveas(h_fig_dem,out_fn);
    out_fn = [fullfile(out_dir,out_fn_name),'.jpg'];
    fprintf('  %s\n', out_fn);
    print(out_fn,'-djpeg','-r0');
%     saveas(h_fig_dem,out_fn);
    
    %% 3D rendering of DEM surface (disabled)
    if 0
      figure(1); clf;
      set(1,'Color',[1 1 1]);
      
      hA2 = axes;
      %hC = contourf((xaxis-xaxis(1))/1e3,(yaxis-yaxis(1))/1e3,double(DEM),12);
      hC = surf((xaxis-xaxis(1))/1e3,(yaxis-yaxis(1))/1e3,double(DEM)*0+25,double(DEM));
      set(hC(1),'EdgeAlpha',0); grid off;
      %axis([2 38 0 10 zlims]);
      set(hA2,'Box','off');
      set(hA2,'View',[7.5   74]);
      set(hA2,'Position',[0.025 0.1 0.875 0.53]);
      set(hA2,'YTick',[0 5 10]);
      set(hA2,'ZColor',[1 1 1]);
      colormap(jet(256))
      hc = colorbar;
      zlims = caxis;
      caxis(zlims);
      set(hc,'Position',[0.95 0.1 0.015 0.8]);
      set(get(hc,'YLabel'),'String','Bed height (m)');
      
      hA = axes;
      hS = surf((xaxis-xaxis(1))/1e3,(yaxis-yaxis(1))/1e3,double(DEM),double(1*DEM));
      hA = gca; grid off;
      %axis([2 38 0 10 zlims]);
      set(hA,'Box','off');
      % View ["" "elevation angle of observer"]
      set(hA,'View',[7.5 74]);
      set(hA,'Position',[0.025 0.45 0.875 0.66]);
      set(hA,'XTick',[]);
      set(hA,'YTick',[]);
      set(hA,'ZTick',[]);
      set(hA,'XColor',[1 1 1]);
      set(hA,'YColor',[1 1 1]);
      set(hA,'ZColor',[1 1 1]);
      set(hS(1),'EdgeAlpha',0.2);
      
      if 0 % surf with color
        colormap(jet(256))
        hc = colorbar;
        caxis(zlims);
        set(hc,'Position',[0.95 0.1 0.015 0.8]);
        set(get(hc,'YLabel'),'String','Bed height (m)');
      end
      
      axes(hA2);
      hx = xlabel('X (km)');
      %set(hx,'Position',[19 -1.8 0]);
      hy = ylabel('Y (km)');
      %set(hy,'Position',[40 3.5 0]);
      %set(hy,'Rotation',54);
      
      % =========================================================================
      % =========================================================================
      figure(3); clf;
      set(3,'Position',[50 50 500 500]);
      set(3,'Color',[1 1 1]);
      
      hS = surf((xaxis-xaxis(1))/1e3-2,(yaxis-yaxis(1))/1e3-1,double(DEM),double(DEM));
      hA = gca; grid off;
      %axis([0 36 0 10 zlims]);
      set(hA,'Box','off');
      % View ["" "elevation angle of observer"]
      set(hA,'YTick',[0 5 10]);
      set(hA,'ZColor',[1 1 1]);
      set(hA,'View',[7.5 74]);
      set(hA,'Position',[0.025 0.135 0.875 1.1]);
      set(hA,'ZColor',[1 1 1]);
      set(hS(1),'EdgeAlpha',0.2);
      
      colormap(jet(256))
      hc = colorbar;
      set(hc,'Position',[0.95 0.1 0.015 0.8]);
      set(get(hc,'YLabel'),'String','Bed height (m)');
      caxis(zlims);
      
      hx = xlabel('X (km)');
      set(hx,'Position',[19 -1.2 0]);
      set(hx,'Rotation',-2);
      hy = ylabel('Y (km)');
      set(hy,'Position',[38 3.5 0]);
      set(hy,'Rotation',68);
    end
    
    %% Save Geotiff of Surface
    
    % ProjectedCSTypeGeoKey: The projection type key to use with geotiff_en.
    % The most reliable way to
    % set this is to create a geotiff file with the right projection in
    % another program and read in the key from that program using geotiffinfo.
    % proj = geotiffinfo('/cresis/projects/GIS_data/greenland/Landsat-7/Greenland_natural_150m.tif');
    % proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjectedCSTypeGeoKey
    %  ans =
    %       32767
    % Some keys are not fully supported and you'll just have to try different
    % projections until you find one that works.  Test the output file by
    % loading it with Matlab and another program like Arc or Globalmapper
    ProjectedCSTypeGeoKey = 32622;
    ProjectedCSTypeGeoKey = 3031;
    ProjectedCSTypeGeoKey = proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjectedCSTypeGeoKey;
    
    R = maprasterref;
    R.XLimWorld = [xaxis(1)-(xaxis(2)-xaxis(1))/2 xaxis(end)+(xaxis(2)-xaxis(1))/2];
    R.YLimWorld = [yaxis(1)-(yaxis(2)-yaxis(1))/2 yaxis(end)+(yaxis(2)-yaxis(1))/2];
    R.RasterSize = size(DEM);
    %R.RasterInterpretation = 'cells';
    R.ColumnsStartFrom = 'south';
    R.RowsStartFrom = 'west';
    %R.RasterInterpretation = 'postings';
    
    key.GTModelTypeGeoKey  = 1;  % Projected Coordinate System (PCS)
    key.GTRasterTypeGeoKey = 2;  % PixelIsPoint
    key.GTRasterTypeGeoKey = 1;  % PixelIsPoint
    key.ProjectedCSTypeGeoKey = ProjectedCSTypeGeoKey;
    DEM(isnan(DEM)) = param.dem.bad_geotiff_value;
    
    DEM_geotiff_fn_name = sprintf('%s_%03d_%s.tif',param.day_seg,frm,surf_str);
    DEM_geotiff_fn = fullfile(out_dir,DEM_geotiff_fn_name);
    fprintf('  %s\n', DEM_geotiff_fn);
    geotiffwrite(DEM_geotiff_fn, int16(DEM), R, 'GeoKeyDirectoryTag', key);
    
    DEM_geotiff_fn_name = sprintf('%s_%03d_%s_quality.tif',param.day_seg,frm,surf_str);
    DEM_geotiff_fn = fullfile(out_dir,DEM_geotiff_fn_name);
    fprintf('  %s\n', DEM_geotiff_fn);
    IMG_3D(isnan(IMG_3D)) = param.dem.bad_geotiff_value;
    geotiffwrite(DEM_geotiff_fn, int16(IMG_3D), R, 'GeoKeyDirectoryTag', key);
    
    
    %% Save CSV File of surface points
    
    % Convert from x,y back to lat,lon
    [pnts(4,:),pnts(5,:)] = projinv(proj,pnts(1,:),pnts(2,:));
    pnts(6,:) = gps_time;
    
    csv_fn_name = sprintf('%s_%03d_%s.csv',param.day_seg,frm,surf_str);
    csv_fn = fullfile(out_dir,csv_fn_name);
    
    fprintf('  %s\n', csv_fn);
    fid = fopen(csv_fn,'w');
    fprintf(fid,'X,Y,Elevation,Latitude,Longitude,GPS Time\n');
    fprintf(fid,'%f,%f,%f,%f,%f,%f\n',pnts);
    fclose(fid);
    
    %% Save mat file of data products
    sw_version = [];
    if isfield(param,'sw_version')
      sw_version = param.sw_version;
    end
    param_array = [];
    if isfield(mdata,'param_array')
      param_array = mdata.param_array;
    end
    ice_mask_ref = [];
    if isfield(param,'ice_mask_ref')
      ice_mask_ref = param.dem.ice_mask_ref;
    end
    geotiff_ref = [];
    if isfield(param,'geotiff_ref')
      geotiff_ref = param.dem.geotiff_ref;
    end
    DEM_ref = [];
    if isfield(param,'DEM_ref')
      DEM_ref = param.dem.DEM_ref;
    end
    
    boundary = []; boundary.x = px; boundary.y = py;
    param_surfdata = param;
    
    mat_fn_name = sprintf('%s_%03d_%s.mat',param.day_seg,frm,surf_str);
    mat_fn = fullfile(out_dir,mat_fn_name);
    
    fprintf('  %s\n', mat_fn);
    if param.ct_file_lock
      file_version = '1L';
    else
      file_version = '1';
    end

    dem_savefields = {'sw_version','param_array','ice_mask_ref','geotiff_ref','DEM_ref','xaxis','yaxis','DEM','IMG_3D','points','boundary','param_surfdata','file_version'};
    
    if param.dem.ice_mask_flag
      dem_savefields = [dem_savefields {'ICE_MASK'}];
    end
    
    if param.dem.array_manifold_mask_flag
      dem_savefields = [dem_savefields {'ARRAY_MANIFOLD_MASK','DOA_GRID'}];
    end

    ct_save(mat_fn, dem_savefields{:});

  end
  try; delete(h_fig_dem); end;
end

