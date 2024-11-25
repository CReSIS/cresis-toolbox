function opsInsertLayer(params,insert_param)
% opsInsertLayer(params,insert_param)
%
% Insert or overwrite a layer. The data source can be:
%  - point cloud using Delaunay triangulization
%  - grided data using 2D interpolation
% The layer can be stored in OPS, echogram, layerData, or records.
% The layer can overwrite, merge, or fill gaps in existing data.
%
% Input:
% params: Parameter structure array from read_param_xls parameter
%   spreadsheet
% insert_param: Structure which controls insertion process
%  .layer_dest = structure specifying the destination layer
%    .name: layer name string (e.g. 'surface', 'bottom', 'atm', etc)
%    .source: string (e.g. 'records', 'echogram', 'layerdata', or 'ops')
%    .echogram_source: used only with echogram source, string
%      containing file path argument to ct_filename_out.m
%      (e.g. 'qlook', 'mvdr', 'CSARP_post/standard')
%    .layerdata_source: used only with layerdata source, string
%      containing file path argument to ct_filename_out.m
%      (e.g. 'layerData', 'CSARP_post/layerData')
%    .existence_check: used only with ops source, set to false to allow
%      layers that do not exist (default is true). If false, the layer
%      will be created if it does not exist. If true, an error will be
%      thrown if the layer does not exist.
%    .group: used only with ops source and only needed when the layer
%      does not already exist. Should be a string containing the group
%      name that the layer should be added to. Leave blank to use the
%      standard group.
%    .description: used only with ops source and only needed when the layer
%      does not already exist. Should be a string containing a
%      description of the layer contents.
%  .type: 'point' or 'raster'
%  .proj: the projection structure of the grid map
%  .x = x-vector for data matrix
%  .y = y-vector for data matrix
%  .data = data vector, it should be two way travel time by the time it
%    is inserted. Many operations will require elevation data to be passed
%    in which will be converted to twtt data by insert_param.eval.cmd
%  .interp_method: optional string containing TriScatteredInterp method ('natural',
%    'linear', or 'nearest') with 'linear' as default
%  .gaps_fill: struct controlling interpolation across gaps in source
%     (see opsCopyLayers.m for description)
%  .copy_method = struct controlling copy method (see
%    opsCopyLayers.m for description of "copy_method" field)
%  .eval: Optional structure for performing operations on the source
%    before it is written to the destination.
%    .cmd: Command string that will be passed to eval
%    .ref_source = optional structure specifying a reference layer source.
%      This reference layer will be available to the eval command. The
%      arguments are passed directly to opsLoadLayers.m. The fields are
%      generally:
%      .name: string (e.g. 'surface', 'Surface', 'bottom', 'atm', etc)
%      .source: string (e.g. 'records', 'echogram', 'layerdata', or 'ops')
%      .echogram_source = string (e.g. 'qlook', 'mvdr', 'CSARP_post/standard')
%      .layerdata_source = string (e.g. 'layerData', 'CSARP_post/layerData')
%    .ref_gaps_fill: struct controlling interpolation across gaps in
%      ref_source (see opsCopyLayers.m for description of "gaps_fill" field)
%    .$(custom): Custom fields available to the eval command.
%    Variables available are:
%      physical_constants
%      "time" (ANSI-C GPS time, seconds since Jan 1, 1970)
%      "at" (along-track, m)
%      "lat" (deg)
%      "lon" (deg)
%      "elev" (m)
%      "s" (two way travel time, twtt, in sec)
%      "ref" (reference structure from ref_source)
%      "eval_struct" (the eval structure passed in by the user)
%    The cmd string should generally update "source" variable. For example:
%       'source = source + 0.1;' % Apply a twtt shift
%       'source = (elev - ref.twtt*c/2)/(c/2/sqrt(er_ice)) - source + ref;'
%
% Examples:
%  Examples at bottom of this file
%
% Author: Jilu Li, John Paden
%
% See also: opsCreateLayerPoints.m, opsInsertLayerFromGrid.m

physical_constants;
global gRadar;

if ~isfield(insert_param,'max_dist') || isempty(insert_param.max_dist)
  insert_param.max_dist = inf;
end

if strcmpi(insert_param.type, 'point')
  %% Create triangulation function handle
  % Ensure input data are column vectors
  insert_param.x = insert_param.x(:);
  insert_param.y = insert_param.y(:);
  insert_param.data = insert_param.data(:);
  % Remove non-unique points
  [dtri_pnts,dtri_idxs] = unique([insert_param.x insert_param.y],'rows');
  if ~isfield(insert_param,'interp_method') || isempty(insert_param.interp_method)
    insert_param.interp_method = 'linear';
  end
  insert_param.interp_fh = scatteredInterpolant(dtri_pnts(:,1),dtri_pnts(:,2),insert_param.data(dtri_idxs),insert_param.interp_method,'nearest');
elseif strcmpi(insert_param.type, 'raster')
  %% Prepare gridded data
else
  error('Invalid insert_param.type %s', insert_param.type);
end

%% Create destination layer if it does not exist
if strcmpi(insert_param.layer_dest.source,'ops')
  % Check to see if layer exists
  sys = ct_output_dir(params(1).radar_name);
  [status,data] = opsGetLayers(sys);
  if ~any(strcmpi(data.properties.lyr_name,insert_param.layer_dest.name))
    % Create the layer if it does not exist
    ops_param = [];
    ops_param.properties.lyr_name = insert_param.layer_dest.name;
    ops_param.properties.lyr_group_name = insert_param.layer_dest.group;
    ops_param.properties.lyr_description = insert_param.layer_dest.description;
    ops_param.properties.public = true;
    
    [status,ops_data] = opsCreateLayer(sys,ops_param);
  end
end

%% Iterate through each parameter structure
for param_idx = 1:length(params)
  param = params(param_idx);
  
  %% Determine if this segment should be processed or not
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  
  param = merge_structs(param,gRadar);
  
  fprintf('opsInsertLayer %s\n', param.day_seg);
  
  %% Load framing information (to determine start/stop gps times of each frame)
  if strcmpi(insert_param.layer_dest.source,'ops')
    sys = ct_output_dir(param.radar_name);
    ops_param = struct('properties',[]);
    ops_param.properties.season = param.season_name;
    ops_param.properties.segment = param.day_seg;
    [~,ops_frames] = opsGetSegmentInfo(sys,ops_param);
  end
  % Load frames file
  frames = frames_load(param);
  
  %% Load existing destination layer data for this segment
  % Load all frames 
  load_param = param;
  load_param.cmd.frms = 1:length(frames.frame_idxs);
  layer_source = opsLoadLayers(load_param,insert_param.layer_dest);
  
  %% Create all_points: a structure containing every point in the destination
  % for this segments with these fields
  %  .gps_time, .lat, .lon, .elev
  %  .ids: only if ops is the destination (database point IDs)
  %  .twtt: the current twtt for each point (NaN means does not exist)
  %  .twtt_interp: the new twtt for each point
  if strcmpi(insert_param.layer_dest.source,'ops')
    % OPS source only returns points with picks from opsLoadLayers. So to get the
    % points that do not have picks, we have to load the flight lines.
    ops_param = struct('properties',[]);
    ops_param.properties.location = param.post.ops.location;
    ops_param.properties.season = param.season_name;
    ops_param.properties.start_gps_time = ops_frames.properties.start_gps_time(1);
    ops_param.properties.stop_gps_time = ops_frames.properties.stop_gps_time(end);
    ops_param.properties.nativeGeom = true;
    %ops_param.properties.lyr_id = ops_data.properties.id;
    [~,ops_data] = opsGetPath(sys,ops_param);
    
    all_points.gps_time = ops_data.properties.gps_time;
    all_points.lat = ops_data.properties.Y;
    all_points.lon = ops_data.properties.X;
    all_points.elev = ops_data.properties.elev;
    
    % Runs through each data point. At each ops_data point id, if there is
    % no layer_dest point id that matches it, that point is assigned NaN
    all_points.ids = ops_data.properties.id;
    all_points.twtt = zeros(size(ops_data.properties.id));
    
    for point_idx = 1:length(all_points.ids)
      match_idx = find(all_points.ids(point_idx) == layer_source.point_path_id);
      if isempty(match_idx)
        all_points.twtt(point_idx) = NaN;
      else
        all_points.twtt(point_idx) = layer_source.twtt(match_idx);
      end
    end
    
  else
    % Non-OPS sources automatically include all points since NaN are used to
    % fill in missing points
    all_points.gps_time = layer_source.gps_time;
    all_points.lat = layer_source.lat;
    all_points.lon = layer_source.lon;
    all_points.elev = layer_source.elev;
    all_points.ids = layer_source.point_path_id;
    all_points.twtt = layer_source.twtt;
  end

  %% Update layer source with interpolated data
  if strcmpi(insert_param.type, 'point')
    [all_points.x,all_points.y] = projfwd(insert_param.proj,all_points.lat,all_points.lon);
    all_points.twtt = insert_param.interp_fh(all_points.x,all_points.y);
    
  elseif strcmpi(insert_param.type, 'raster')
    [all_points.x,all_points.y] = projfwd(insert_param.proj,all_points.lat,all_points.lon);
    all_points.twtt = interp2(reshape(insert_param.x,[1 numel(insert_param.x)]), ...
      reshape(insert_param.y,[numel(insert_param.y) 1]),insert_param.data,all_points.x,all_points.y);
    
  end
  
  %% Run eval command
  if isfield(insert_param,'eval') && ~isempty(insert_param.eval)
    %% Load reference layer for eval command
    if isfield(insert_param.eval,'ref_source') && ~isempty(insert_param.eval.ref_source)
      load_param = param;
      load_param.cmd.frms = 1:length(frames.frame_idxs);
      ref = opsLoadLayers(load_param,insert_param.eval.ref_source);
      
      if strcmpi(insert_param.eval.ref_gaps_fill.method,'preserve_gaps')
        %% interpolation preserves_gaps
        
        master = [];
        master.GPS_time = all_points.gps_time;
        master.Latitude = all_points.lat;
        master.Longitude = all_points.lon;
        master.Elevation = all_points.elev;
        ops_layer = [];
        ops_layer{1}.gps_time = ref.gps_time;
        ops_layer{1}.type = ref.type;
        ops_layer{1}.quality = ref.quality;
        ops_layer{1}.twtt = ref.twtt;
        lay = opsInterpLayersToMasterGPSTime(master,ops_layer,insert_param.eval.ref_gaps_fill.method_args);
        ref.twtt = lay.layerData{1}.value{2}.data;
        
      elseif strcmpi(insert_param.eval.ref_gaps_fill.method,'interp_finite')
        %% interpolation follows interp_finite
        
        % Interpolate source onto destination points using linear interpolation
        ref.twtt = interp1(ref.gps_time, ref.twtt, all_points.gps_time);
        % Fill in NaN gaps using interp_finite
        ref.twtt = interp_finite(ref.twtt,0);
      end
    end

    %% Prepare variables for eval command
    s = all_points.twtt;
    time = all_points.gps_time;
    lat = all_points.lat;
    lon = all_points.lon;
    elev = all_points.elev;
    at = geodetic_to_along_track(lat,lon,elev);
    eval_struct = insert_param.eval;
    eval(insert_param.eval.cmd);
    all_points.twtt = s;
  end
  
  if strcmpi(insert_param.type, 'point') && insert_param.max_dist < inf
    TR = delaunayTriangulation(dtri_pnts(:,1),dtri_pnts(:,2));
    idxs = TR.nearestNeighbor(all_points.x(:),all_points.y(:));
    dist = (dtri_pnts(idxs,1)-all_points.x(:)).^2 + (dtri_pnts(idxs,2)-all_points.y(:)).^2;
    all_points.twtt(dist > insert_param.max_dist^2) = NaN;
  end
  
  copy_param = [];
  copy_param.layer_source.name = '';
  copy_param.layer_source.source = 'custom';
  copy_param.layer_source.twtt = all_points.twtt;
  copy_param.layer_source.gps_time = all_points.gps_time;
  
  copy_param.layer_dest = insert_param.layer_dest;
  
  copy_param.copy_method = insert_param.copy_method;
  copy_param.gaps_fill = insert_param.gaps_fill;
  
  opsCopyLayers(param,copy_param);
end
