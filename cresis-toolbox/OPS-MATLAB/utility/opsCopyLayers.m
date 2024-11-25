function layers = opsCopyLayers(param,copy_param)
% layers = opsCopyLayers(param,copy_param)
%
% Copies contents from one layer into another layer. The copy method can
% be merge, overwrite, or fill gaps. If the destination layer does not
% exist, it will be created. The source and destination for the data can be
% OPS, layerData, echogram, or records. Additionally, the source can be
% lidar (ATM) or a custom GPS-time/two-way-travel-time.
%
% An operation on the source data using the eval field can be added. More
% complicated operations can be done using opsLoadLayers, applying the
% complex operation on that result and then using the custom input.
%
% Input:
%   param: Parameter structure from read_param_xls parameter spreadsheet
%   copy_param: Structure which controls copying process
%     .layer_source: structure specifying the source layer
%
%       .name: cell array of layer names or a string with a single layer
%       name in it; layer names must be unique even if the group name is
%       different (e.g. 'surface', 'Surface', 'bottom', 'atm', etc. are all
%       different layers); the same layer can be copied multiple times in a
%       single call
%
%       .source: string (e.g. 'records', 'echogram', 'layerdata', 'lidar',
%         'custom', or 'ops')
%       .echogram_source: used only with "echogram" source, string
%         containing file path argument to ct_filename_out.m
%         (e.g. 'qlook', 'mvdr', 'CSARP_post/standard')
%       .echogram_source_img: used only with "echogram" source, scalar
%         integer specifying the image. Zero is default.
%           0: Data_YYYYMMDD_FF.mat
%           II: Data_img_II_YYYYMMDD_FF.mat
%       .layerdata_source: used only with layerdata source, string
%         containing file path argument to ct_filename_out.m
%         (e.g. 'layerData', 'CSARP_post/layerData')
%       .existence_check: used only with ops source, set to false to allow
%         layers that do not exist (default is true)
%       -------------------------------------------------------------------
%       CUSTOM SOURCE FIELDS (used only with layer_source.source = 'custom')
%         * Each field is a cell array
%         * Each cell array should be the same length as the cell array
%           layer_source.name
%         * Entries in these cell arrays align with the corresponding entry
%           in layer_source.name.
%         * The length of each vector, Nx, in the cell array only needs to
%           be the same for a particular layer. Different layers can have
%           different values of Nx.
%         * Legacy Support: if only one layer specified in
%           layer_source.name, then each of these fields only needs one
%           cell entry and no cell array was used (just an Nx by 1 vector
%           was passed in).
%       .gps_time: used only with custom source, cell array of Nx by 1
%         vectors corresponding to GPS time (ANSI-C standard: seconds since
%         Jan 1, 1970)
%       .twtt: used only with custom source, cell array of Nx by 1 vectors
%         corresponding to gps_time field containing two way travel time to
%         layer
%       .type: used only with custom source, cell array of Nx by 1 vectors
%         corresponding to gps_time field containing type (1=manual, 2=auto),
%         2 is default when not specified or NaN
%       .quality: used only with custom source, cell array of Nx by 1
%         vectors corresponding to gps_time field containing quality (1=good,
%         2=moderate, 3=derived/poor), 1 is default when not specified or NaN
%       END CUSTOM SOURCE FIELDS
%       -------------------------------------------------------------------
%
%     .layer_dest = structure specifying the destination layer
%       .name: cell array of layer names or a string with a single layer
%         name in it. This is the destination of the layers specified in
%         source so layer_dest.name should list the same number of names as
%         layer_source.name
%       .source: string (e.g. 'records', 'echogram', 'layerdata', or 'ops')
%       .echogram_source: used only with echogram source, string
%         containing file path argument to ct_filename_out.m
%         (e.g. 'qlook', 'mvdr', 'CSARP_post/standard')
%       .layerdata_source: used only with layerdata source, string
%         containing file path argument to ct_filename_out.m
%         (e.g. 'layerData', 'CSARP_post/layerData')
%       .existence_check: used only with ops source, set to false to allow
%         layers that do not exist (default is true). If false, the layer
%         will be created if it does not exist. If true, an error will be
%         thrown if the layer does not exist.
%
%        .group_name (or .group to support legacy code): Optional argument.
%        This field is for overriding the group_name of the source. It
%        should be a cell array with the same dimensions as .name if .name
%        is a cell array or a string if .name is a string. Leave undefined
%        or an empty matrix to use the default. If a cell has an empty
%        matrix in it, [], then the default is used for that layer. Note
%        that an empty string is a valid entry and will not trigger the
%        default to be used. The strings should contain the group_name of
%        the corresponding layer in .name. The default value is the value
%        from the destination layer if it already exists. If the
%        destination layer does not exist, then the layer source value is
%        used. If the layer source does not have a value set, then the
%        value will be the string "standard" for each layer.
%
%        .desc (or .description to support legacy code): Has the same
%        behavior as .group_name except the default value is an empty
%        string when no other value is available
%
%        .age: Has the same behavior as .group_name except the fields are
%        double scalars. The default value is a NaN when no other value is
%        available.
%
%        .age_source: Has the same behavior as .group_name except the
%        fields are all structure arrays. The default value is an empty
%        structure array when no other value is available. Note that to
%        override the age_source field to remove any age sources, care must
%        be taken to ensure that an empty structure is passed in as
%        "struct()" and not "[]" since the latter will cause the default
%        value to be used.
%
%     .eval: Optional structure for performing operations on the source
%       before it is written to the destination.
%       .cmd: Command string that will be passed to eval
%       .$(custom): Custom fields
%        Variables available are:
%          physical_constants
%          "time" (ANSI-C GPS time, seconds since Jan 1, 1970)
%          "at" (along-track, m)
%          "lat" (deg)
%          "lon" (deg)
%          "elev" (m)
%          "s" (two way travel time, twtt, in sec)
%          "eval_struct" (the eval structure passed in by the user)
%        The cmd string should generally update "source" variable. For example:
%           '[B,A] = butter(0.1,2); source = filtfilt(B,A,source);' % Filter
%           'source = source + 0.1;' % Apply a twtt shift
%           'source = source*2;' % Surface multiple
%           'source = interp1(gps_time+15,source,gps_time);' % Apply a GPS time shift
%     .quality: struct controlling the quality level
%       .mode: string specifying one of these methods:
%         'overwrite': Overwrites the quality level with ".quality"
%         'preserve': Quality level preserved from source
%       .value: scalar containing 1, 2, or 3
%     .copy_method = string specifying one of these methods
%       'fillgaps': only gaps in destination data will be written to
%       'overwrite': none of the previous data are kept
%       'merge': anywhere source data exists, destination data will be
%         overwritten
%     .gaps_fill: struct controlling interpolation across gaps in source
%       .method: string specifying one of these methods
%         'preserve_gaps': runs opsInterpLayersToMasterGPSTime which tries
%           to interpolate where there is data and leave gaps where there
%           is not data (method_args controls this behavior)
%         'interp_finite': runs interp_finite which fills EVERY point
%       .method_args: arguments based on chosen method
%         'preserve_gaps': two element vector used by opsInterpLayersToMasterGPSTime
%         'interp_finite': not used
%
% Authors: John Paden, Abbey Whisler
%
% See also: runOpsCopyLayers.m, opsMergeLayerData, opsCopyLayers

physical_constants;

%% Determine if the copy method and gap filling method are valid
if ~any(strcmpi(copy_param.copy_method,{'fillgaps','overwrite','merge'}))
  error('Invalid copy_method %s', copy_param.copy_method);
end

if ~any(strcmpi(copy_param.gaps_fill.method,{'preserve_gaps','interp_finite'}))
  error('Invalid gap_fill.method %s', copy_param.gaps_fill.method);
end

if strcmpi(copy_param.gaps_fill.method,'preserve_gaps') ...
    && (~isfield(copy_param.gaps_fill,'method_args') || isempty(copy_param.gaps_fill.method_args))
  copy_param.gaps_fill.method_args = [300 60];
end

if ~isfield(copy_param,'quality')
  copy_param.quality.mode = 'preserve';
  copy_param.quality.value = 1;
end

if ~any(strcmpi(copy_param.quality.mode,{'preserve','overwrite'}))
  error('Invalid quality mode %s', copy_param.quality.mode);
end

if ~any(copy_param.quality.value == [1 2 3])
  error('Invalid quality value %d', copy_param.quality.value);
end

% Legacy format used .group and .description, update these if needed
if ~isfield(copy_param.layer_dest,'desc') && isfield(copy_param.layer_dest,'description')
  copy_param.layer_dest.desc = copy_param.layer_dest.description;
end
if ~isfield(copy_param.layer_dest,'group_name') && isfield(copy_param.layer_dest,'group')
  copy_param.layer_dest.group_name = copy_param.layer_dest.group;
end

% copy_param.layer_dest.age: optional field, overrides age field in the
% corresponding output fields. If a single scalar numeric value, then all
% layers will be written with this value. If a cell array, then each cell
% corresponds to the layer_source layer at the same index. If the contents
% of the cell are [] or if the cell does not exist, then the default value
% is used. The default value first looks at the destination layer. If not
% defined, then the default value pulls from the source layer. If not
% defined, then the value is NaN.
if ~isfield(copy_param.layer_dest,'age')
  copy_param.layer_dest.age = {};
end
if iscell(copy_param.layer_dest.age)
  for idx = 1:length(copy_param.layer_dest.age)
    if ~isnumeric(copy_param.layer_dest.age{idx})
      error('copy_param.layer_dest.age{%d} must be 1) a numeric scalar or 2) an empty matrix [].', idx);
    end
  end
else
  if ~isempty(copy_param.layer_dest.age) && ~isnumeric(copy_param.layer_dest.age)
    error('copy_param.layer_dest.age must be 1) a cell array of numeric scalars, 2) a numeric scalar, 3) an empty numeric matrix [], or 4) undefined.');
  end
end

% copy_param.layer_dest.age_source: Same as .age field except instead of
% numeric values it is a structure array. If not defined elsewhere, then
% the value is struct() instead of NaN.
if ~isfield(copy_param.layer_dest,'age_source')
  copy_param.layer_dest.age_source = {};
end
if iscell(copy_param.layer_dest.age_source)
  for idx = 1:length(copy_param.layer_dest.age_source)
    if ~isstruct(copy_param.layer_dest.age_source{idx})
      error('copy_param.layer_dest.age_source{%d} must be 1) a struct array or 2) an empty matrix [].', idx);
    end
  end
else
  if ~isempty(copy_param.layer_dest.age_source) && ~isstruct(copy_param.layer_dest.age_source)
    error('copy_param.layer_dest.age_source must be 1) a cell array of structure arrays, 2) a structure array, 3) an empty numeric matrix [], or 4) undefined.');
  end
end

% copy_param.layer_dest.group_name: Same as .age field except instead of
% numeric values it is a string. If not defined elsewhere, then
% the value is 'standard' instead of NaN.
if ~isfield(copy_param.layer_dest,'group_name')
  copy_param.layer_dest.group_name = {};
end
if iscell(copy_param.layer_dest.group_name)
  for idx = 1:length(copy_param.layer_dest.group_name)
    if ~ischar(copy_param.layer_dest.group_name{idx})
      error('copy_param.layer_dest.group_name{%d} must be 1) a string or 2) an empty matrix [].', idx);
    end
  end
else
  if ~isempty(copy_param.layer_dest.group_name) && ~ischar(copy_param.layer_dest.group_name)
    error('copy_param.layer_dest.group_name must be 1) a cell array of strings, 2) a string, 3) an empty numeric matrix [], or 4) undefined.');
  end
end

% copy_param.layer_dest.desc: Same as .age field except instead of
% numeric values it is a string. If not defined elsewhere, then
% the value is '' (empty string) instead of NaN.
if ~isfield(copy_param.layer_dest,'desc')
  copy_param.layer_dest.desc = {};
end
if iscell(copy_param.layer_dest.desc)
  for idx = 1:length(copy_param.layer_dest.desc)
    if ~ischar(copy_param.layer_dest.desc{idx})
      error('copy_param.layer_dest.desc{%d} must be 1) a string or 2) an empty matrix [].', idx);
    end
  end
else
  if ~isempty(copy_param.layer_dest.desc) && ~ischar(copy_param.layer_dest.desc)
    error('copy_param.layer_dest.desc must be 1) a cell array of strings, 2) a string, 3) an empty numeric matrix [], or 4) undefined.');
  end
end

if ~isfield(copy_param.layer_dest,'layerdata_source') || isempty(copy_param.layer_dest.layerdata_source)
  % Default is the CSARP_layer directory
  copy_param.layer_dest.layerdata_source = 'layer';
end

% For the opsLoadLayers to write the files if they do not already exist
copy_param.layer_dest.read_only = false;

if ~isfield(copy_param.layer_source,'layerdata_source') || isempty(copy_param.layer_source.layerdata_source)
  % Default is the CSARP_layer directory
  copy_param.layer_source.layerdata_source = 'layer';
end

if ~isfield(copy_param.layer_source,'echogram_source_img') || isempty(copy_param.layer_source.echogram_source_img)
  % Default is a combined file Data_YYYYMMDD_SS.mat
  copy_param.layer_source.echogram_source_img = 0;
end

%% Load "frames" file
frames = frames_load(param);
param.cmd.frms = frames_param_cmd_frms(param,frames);

%% Load source layer data and existing destination layer data for this segment
% Load all frames (for better edge interpolation)
load_param = param;
load_param.cmd.frms = max(1,min(param.cmd.frms)-1) : min(length(frames.frame_idxs),max(param.cmd.frms)+1);
layer_dest = opsLoadLayers(load_param,copy_param.layer_dest);
if strcmpi(copy_param.layer_source.source,'custom')
  layer_source = [];
  for layer_idx = 1:length(layer_dest)
    % gps_time copy
    if ~iscell(copy_param.layer_source.gps_time)
      copy_param.layer_source.gps_time = {copy_param.layer_source.gps_time};
    end
    layer_source(layer_idx).gps_time = copy_param.layer_source.gps_time{layer_idx};
    % twtt copy
    if ~iscell(copy_param.layer_source.twtt)
      copy_param.layer_source.twtt = {copy_param.layer_source.twtt};
    end
    layer_source(layer_idx).twtt = copy_param.layer_source.twtt{layer_idx};
    % type
    if isfield(copy_param.layer_source,'type') ...
        && ~isempty(copy_param.layer_source.type)
      if ~iscell(copy_param.layer_source.type)
        copy_param.layer_source.type = {copy_param.layer_source.type};
      end
      layer_source(layer_idx).type = copy_param.layer_source.type{layer_idx};
    else
      layer_source(layer_idx).type = 2*ones(size(layer_source(layer_idx).gps_time));
    end
    % quality
    if isfield(copy_param.layer_source,'quality') ...
        && ~isempty(copy_param.layer_source.quality)
      if ~iscell(copy_param.layer_source.quality)
        copy_param.layer_source.quality = {copy_param.layer_source.quality};
      end
      layer_source(layer_idx).quality = copy_param.layer_source.quality{layer_idx};
    else
      layer_source(layer_idx).quality = ones(size(layer_source(layer_idx).gps_time));
    end
    % age, age_source, desc, group_name not set for custom sources, these
    % can be set using the corresponding destination override fields
    layer_source(layer_idx).age = [];
    layer_source(layer_idx).age_source = [];
    layer_source(layer_idx).desc = [];
    layer_source(layer_idx).group_name = [];
  end
else
  layer_source = opsLoadLayers(load_param,copy_param.layer_source);
end

%% Load framing information (to determine start/stop gps times of each frame)
if strcmpi(copy_param.layer_dest.source,'ops')
  sys = ct_output_dir(param.radar_name);
  ops_param = struct('properties',[]);
  ops_param.properties.season = param.season_name;
  ops_param.properties.segment = param.day_seg;
  [~,ops_frames] = opsGetSegmentInfo(sys,ops_param);
end

%% Copy/Merge based on destination, copy_method, and gaps_fill.method.
%    Lists below describe the steps for each possible combination of
%    layer_dest.source, copy_method, and gaps_fill.method settings.
%
% If layer_dest.source is 'layerdata':
%
% copy_method = 'fillgaps',gaps_fill.method = 'interp_finite'
%   - Find NaN in destination
%   - Interpolate source onto these points using interpfinite style of interpolation
%   - Only update these points in the destination
% fillgaps,preserve_gaps
%   - Find NaN in destination
%   - Interpolate source onto these points using opsInterpLayersToMasterGPSTime
%   - Only update these points in the destination
% overwrite,interp_finite
%   - Find all points in destination
%   - Interpolate source onto these points using interpfinite style of interpolation
%   - Write these points on to the destination (does not require original layer information)
% overwrite,preserve_gaps
%   - Find all points in destination
%   - Interpolate source onto these points using opsInterpLayersToMasterGPSTime
%   - Write these points on to the destination (does not require original layer information)
% merge,interp_finite
%   - This is identical to overwrite,interp_finite (does not require original layer information)
% merge,preserve_gaps
%   - Find all points in destination
%   - Interpolate source onto these points using opsInterpLayersToMasterGPSTime
%   - Keep only the ~isnan points
%   - Only update these points in the destination
%
% If layer_dest.source is 'ops':
%
% fillgaps,interp_finite
%   - Find flightline points that don't have a pick in the destination
%   - Interpolate source onto these points using interpfinite style of interpolation
%   - Only update these points in the destination (does not require original layer information)
% fillgaps,preserve_gaps
%   - Find flightline points that don't have a pick in the destination
%   - Interpolate source onto these points using opsInterpLayersToMasterGPSTime
%   - Only update these points in the destination (does not require original layer information)
% overwrite,interp_finite
%   - Find all points in destination
%   - Interpolate source onto these points using interpfinite style of interpolation
%   - Write these points on to the destination (does not require original layer information)
% overwrite,preserve_gaps
%   - Find all points in destination
%   - Interpolate source onto these points using opsInterpLayersToMasterGPSTime
%   - Write these points on to the destination (does not require original layer information)
% merge,interp_finite
%   - This is identical to overwrite,interp_finite
% merge,preserve_gaps
%   - Find all points in destination
%   - Interpolate source onto these points using opsInterpLayersToMasterGPSTime
%   - Keep only the ~isnan points
%   - Only update these points in the destination (does not require original layer information)

%% Create all_points: a structure containing every point in the destination
% for this segments with these fields
%  .gps_time, .lat, .lon, .elev
%  .ids: only if ops is the destination (database point IDs)
%  .twtt: the current twtt for each point (NaN means does not exist)
%  .twtt_interp: the new twtt for each point
all_points = [];
if strcmpi(copy_param.layer_dest.source,'ops')
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
  
  for layer_idx = 1:length(layer_dest)
    all_points(layer_idx).gps_time = ops_data.properties.gps_time;
    all_points(layer_idx).lat = ops_data.properties.Y;
    all_points(layer_idx).lon = ops_data.properties.X;
    all_points(layer_idx).elev = ops_data.properties.elev;
    
    % Runs through each data point. At each ops_data point id, if there is
    % no layer_dest point id that matches it, that point is assigned NaN
    all_points(layer_idx).ids = ops_data.properties.id;
    all_points(layer_idx).twtt = zeros(size(ops_data.properties.id));
    
    for point_idx = 1:length(all_points(layer_idx).ids)
      match_idx = find(all_points(layer_idx).ids(point_idx) == layer_dest(layer_idx).point_path_id);
      if isempty(match_idx)
        all_points(layer_idx).twtt(point_idx) = NaN;
        all_points(layer_idx).quality(point_idx) = 1;
        all_points(layer_idx).type(point_idx) = 2;
      else
        all_points(layer_idx).twtt(point_idx) = layer_dest(layer_idx).twtt(match_idx);
        all_points(layer_idx).quality(point_idx) = layer_dest(layer_idx).quality(match_idx);
        all_points(layer_idx).type(point_idx) = layer_dest(layer_idx).type(match_idx);
      end
    end
  end
  
else
  % Non-OPS sources automatically include all points since NaN are used to
  % fill in missing points
  for layer_idx = 1:length(layer_dest)
    all_points(layer_idx).gps_time = layer_dest(layer_idx).gps_time;
    all_points(layer_idx).lat = layer_dest(layer_idx).lat;
    all_points(layer_idx).lon = layer_dest(layer_idx).lon;
    all_points(layer_idx).elev = layer_dest(layer_idx).elev;
    all_points(layer_idx).ids = layer_dest(layer_idx).point_path_id;
    all_points(layer_idx).type = layer_dest(layer_idx).type;
    all_points(layer_idx).twtt = layer_dest(layer_idx).twtt;
    all_points(layer_idx).quality = layer_dest(layer_idx).quality;
  end
end
% Check to make sure there are any points to copy
if any(cellfun(@isempty,{all_points.gps_time}))
  error('Destination layer(s) have no GPS time points. No work to do. This might be an error caused by echogram destination source not finding any echograms.');
end

for layer_idx = 1:length(layer_source)
  % Set invalid types to "auto" or 2
  layer_source(layer_idx).type(~isfinite(layer_source(layer_idx).type)) = 2;
  % Set invalid quality levels to "good" or 1
  layer_source(layer_idx).quality(~isfinite(layer_source(layer_idx).quality)) = 1;
  layer_source(layer_idx).quality(layer_source(layer_idx).quality ~= 1 & layer_source(layer_idx).quality ~= 2 & layer_source(layer_idx).quality ~= 3) = 1;
end

%% Apply evaluation operation to source
if isfield(copy_param,'eval') && ~isempty(copy_param.eval)
  for layer_idx = 1:length(layer_source)
    s = layer_source(layer_idx).twtt;
    time = layer_source(layer_idx).gps_time;
    lat = layer_source(layer_idx).lat;
    lon = layer_source(layer_idx).lon;
    elev = layer_source(layer_idx).elev;
    at = geodetic_to_along_track(lat,lon,elev);
    eval_struct = copy_param.eval;
    eval(copy_param.eval.cmd);
    layer_source(layer_idx).twtt = s;
  end
end

%% Interpolate two way travel time (twtt) from layer_source to all_points
if strcmpi(copy_param.gaps_fill.method,'preserve_gaps')
  % interpolation preserves_gaps which preserves gaps in the data
  
  for layer_idx = 1:length(layer_source)
    master = [];
    master.GPS_time = all_points(layer_idx).gps_time;
    master.Latitude = all_points(layer_idx).lat;
    master.Longitude = all_points(layer_idx).lon;
    master.Elevation = all_points(layer_idx).elev;
    ops_layer = [];
    ops_layer{1}.gps_time = layer_source(layer_idx).gps_time;
    ops_layer{1}.type = layer_source(layer_idx).type;
    ops_layer{1}.quality = layer_source(layer_idx).quality;
    ops_layer{1}.twtt = layer_source(layer_idx).twtt;
    if length(master.GPS_time) < 2
      error('Too few points in destination to interpolate onto.');
    end
    lay = opsInterpLayersToMasterGPSTime(master,ops_layer,copy_param.gaps_fill.method_args);
    all_points(layer_idx).twtt_interp = lay.layerData{1}.value{2}.data;
    % All points automated (type 2) by default
    all_points(layer_idx).type_interp = 2*ones(size(all_points(layer_idx).twtt_interp));
    % Overwrite manual points (type 1)
    manual_mask = isfinite(lay.layerData{1}.value{1}.data);
    all_points(layer_idx).type_interp(manual_mask) = 1;
    all_points(layer_idx).twtt_interp(manual_mask) = lay.layerData{1}.value{1}.data(manual_mask);
  end
  
elseif strcmpi(copy_param.gaps_fill.method,'interp_finite')
  % interpolation interp_finite which interpolates through gaps
  
  for layer_idx = 1:length(layer_source)
    % Interpolate source onto destination points using linear interpolation
    if length(layer_source(layer_idx).gps_time) >= 2
      all_points(layer_idx).twtt_interp = interp1(layer_source(layer_idx).gps_time, layer_source(layer_idx).twtt, all_points(layer_idx).gps_time);
    else
      all_points(layer_idx).twtt_interp = NaN(size(all_points(layer_idx).gps_time));
    end
    % Fill in NaN gaps using interp_finite (default is 0 twtt if no good data
    % exists)
    all_points(layer_idx).twtt_interp = interp_finite(all_points(layer_idx).twtt_interp,0);
    
    % All points automated (type 2) by default
    all_points(layer_idx).type_interp = 2*ones(size(all_points(layer_idx).twtt_interp));
    % Overwrite manual points (type 1)
    manual_idxs = find(layer_source(layer_idx).type == 1);
    manual_idxs_map = interp1_robust(all_points(layer_idx).gps_time, 1:length(all_points(layer_idx).gps_time), ...
      layer_source(layer_idx).gps_time(manual_idxs),'nearest');
    manual_idxs = manual_idxs(~isnan(manual_idxs_map));
    manual_idxs_map = manual_idxs_map(~isnan(manual_idxs_map));
    all_points(layer_idx).twtt_interp(manual_idxs_map) ...
      = layer_source(layer_idx).twtt(manual_idxs);
    all_points(layer_idx).type_interp(manual_idxs_map) = 1;
  end
end

update_mask = {};
for layer_idx = 1:length(layer_source)
  
  %% Combine the newly interpolated result with the current values
  if strcmpi(copy_param.copy_method,'fillgaps')
    update_mask{layer_idx} = isnan(all_points(layer_idx).twtt) & ~isnan(all_points(layer_idx).twtt_interp);
  elseif strcmpi(copy_param.copy_method,'merge')
    update_mask{layer_idx} = ~isnan(all_points(layer_idx).twtt_interp);
  elseif strcmpi(copy_param.copy_method,'overwrite')
    update_mask{layer_idx} = logical(ones(size(all_points(layer_idx).twtt)));
  end
  
  %% For nonselected frames, set update_mask{layer_idx} to zero for all points in those frames
  all_frms = 1:length(frames.frame_idxs);
  % If the user selects all frames in the segment on the params
  % spreadsheet, then the update mask will not change.
  % Otherwise we will create a new mask where each point within the start
  % and stop gps times of the selected frames is equal to 1 and all other
  % points are equal to 0.
  %
  % We divide up the segment into frames so that we avoid rounding issues and
  % to every point is included in a frame.
  frms_mask = zeros(size(update_mask{layer_idx}));
  if strcmpi(copy_param.layer_dest.source,'ops')
    for frm = param.cmd.frms
      if frm == 1
        if frm == length(ops_frames.properties.start_gps_time)
          frms_mask(:) = 1;
        else
          frms_mask(all_points(layer_idx).gps_time < ops_frames.properties.start_gps_time(frm+1)) = 1;
        end
      elseif frm < length(ops_frames.properties.start_gps_time)
        frms_mask(all_points(layer_idx).gps_time >= ops_frames.properties.start_gps_time(frm)...
          & all_points(layer_idx).gps_time < ops_frames.properties.start_gps_time(frm+1)) = 1;
      else
        frms_mask(all_points(layer_idx).gps_time >= ops_frames.properties.start_gps_time(frm)) = 1;
      end
    end
    
  else
    for frm = param.cmd.frms
      if frm == 1
        if frm == length(frames.frame_idxs)
          frms_mask(:) = 1;
        else
          frms_mask(all_points(layer_idx).gps_time < frames.gps_time(frm+1)) = 1;
        end
      elseif frm < length(frames.frame_idxs)
        frms_mask(all_points(layer_idx).gps_time >= frames.gps_time(frm)...
          & all_points(layer_idx).gps_time < frames.gps_time(frm+1)) = 1;
      else
        frms_mask(all_points(layer_idx).gps_time >= frames.gps_time(frm)) = 1;
      end
    end
  end
  
  update_mask{layer_idx} = frms_mask & update_mask{layer_idx};
  
  %% Quality level overwrite
  if isempty(layer_source(layer_idx).gps_time)
    all_points(layer_idx).quality_interp = NaN*zeros(size(all_points(layer_idx).gps_time));
  elseif length(layer_source(layer_idx).gps_time) == 1
    all_points(layer_idx).quality_interp = layer_source(layer_idx).quality;
  else
    all_points(layer_idx).quality_interp = interp1(layer_source(layer_idx).gps_time,layer_source(layer_idx).quality,all_points(layer_idx).gps_time,'nearest');
  end
  if strcmpi(copy_param.quality.mode,'overwrite')
    all_points(layer_idx).quality_interp(:) = copy_param.quality.value;
  end
  
  %% Mask the output
  all_points(layer_idx).twtt_final = all_points(layer_idx).twtt;
  all_points(layer_idx).twtt_final(update_mask{layer_idx}) = all_points(layer_idx).twtt_interp(update_mask{layer_idx});
  all_points(layer_idx).quality_final = all_points(layer_idx).quality;
  all_points(layer_idx).quality_final(update_mask{layer_idx}) = all_points(layer_idx).quality_interp(update_mask{layer_idx});
  all_points(layer_idx).type_final = all_points(layer_idx).type;
  all_points(layer_idx).type_final(update_mask{layer_idx}) = all_points(layer_idx).type_interp(update_mask{layer_idx});
  
  if 0
    % Debug code
    figure(1); clf;
    plot(all_points(layer_idx).twtt);
    hold on;
    plot(surface(update_mask{layer_idx}),'rx');
    grid on;
    hold off;
    drawnow;
    pause(1);
  end
  
end

if strcmpi(copy_param.layer_dest.source,'ops')
  %% Save OPS
  
  % Check to see if layer exists
  % -----------------------------------------------------------------------
  [status,data] = opsGetLayers(sys);
  for layer_idx = 1:length(layer_dest)
    if ~any(strcmpi(data.properties.lyr_name,layer_dest(layer_idx).name))
      % Create the layer if it does not exist
      ops_param = [];
      ops_param.properties.lyr_name = layer_dest(layer_idx).name;
      
      if ischar(copy_param.layer_dest.group_name)
        ops_param.properties.lyr_group_name = copy_param.layer_dest.group_name;
        
      elseif length(copy_param.layer_dest.group_name) >= layer_idx && ischar(copy_param.layer_dest.group_name{layer_idx})
        ops_param.properties.lyr_group_name = copy_param.layer_dest.group_name{layer_idx};

      elseif ischar(layer_dest(layer_idx).group_name)
        ops_param.properties.lyr_group_name = layer_dest(layer_idx).group_name;
        
      elseif ischar(layer_source(layer_idx).group_name)
        ops_param.properties.lyr_group_name = layer_source(layer_idx).group_name;
        
      else
        ops_param.properties.lyr_group_name = 'standard';
      end
      
      if ischar(copy_param.layer_dest.desc)
        ops_param.properties.lyr_description = copy_param.layer_dest.desc;
        
      elseif length(copy_param.layer_dest.desc) >= layer_idx && ischar(copy_param.layer_dest.desc{layer_idx})
        ops_param.properties.lyr_description = copy_param.layer_dest.desc{layer_idx};

      elseif ischar(layer_dest(layer_idx).group_name)
        ops_param.properties.lyr_description = layer_dest(layer_idx).desc;
        
      elseif ischar(layer_source(layer_idx).desc)
        ops_param.properties.lyr_description = layer_source(layer_idx).desc;
        
      else
        ops_param.properties.lyr_description = 'standard';
      end
      
      ops_param.properties.public = true;
      
      [status,ops_data] = opsCreateLayer(sys,ops_param);
    end
    
    % Remove all_points that are not in the selected frames
    % Use update_mask to exclude all points that are not getting updated
    % -----------------------------------------------------------------------
    ops_param.properties.point_path_id = all_points(layer_idx).ids(update_mask{layer_idx});
    ops_param.properties.twtt = all_points(layer_idx).twtt_final(update_mask{layer_idx});
    ops_param.properties.type = all_points(layer_idx).type_final(update_mask{layer_idx});
    ops_param.properties.quality = all_points(layer_idx).quality_final(update_mask{layer_idx});
    ops_param.properties.lyr_name = layer_dest(layer_idx).name;
    
    % Update these points
    % -----------------------------------------------------------------------
    opsCreateLayerPoints(sys,ops_param);
  end
  
elseif strcmpi(copy_param.layer_dest.source,'layerdata')
  %% Save layerdata
  layers = layerdata(param, copy_param.layer_dest.layerdata_source);
  for layer_idx = 1:length(layer_dest)
    id = layers.get_id(layer_dest(layer_idx).name);
    if isempty(id)
      if copy_param.layer_dest.existence_check
        error('Layer %s not found in layer organizer file %s. Set copy_param.layer_dest.existence_check to false to ignore this error and opsCopyLayers will create layers that do not exist already.\n', layer_dest(layer_idx).name, layers.layer_organizer_fn());
      else
        layer_organizer = [];
        
        if ischar(copy_param.layer_dest.group_name)
          layer_organizer.lyr_group_name = {copy_param.layer_dest.group_name};
          
        elseif length(copy_param.layer_dest.group_name) >= layer_idx && ischar(copy_param.layer_dest.group_name{layer_idx})
          layer_organizer.lyr_group_name = {copy_param.layer_dest.group_name{layer_idx}};
          
        elseif ischar(layer_dest(layer_idx).group_name)
          layer_organizer.lyr_group_name = {layer_dest(layer_idx).group_name};
          
        elseif ischar(layer_source(layer_idx).group_name)
          layer_organizer.lyr_group_name = {layer_source(layer_idx).group_name};
          
        else
          ops_param.properties.lyr_group_name = 'standard';
        end
        
        layer_organizer.lyr_name = {layer_dest(layer_idx).name};
        id = layers.insert_layers(layer_organizer);
      end
    end
    % Update "desc" field
    if ischar(copy_param.layer_dest.desc)
      layers.set_desc(id,copy_param.layer_dest.desc);
      
    elseif length(copy_param.layer_dest.desc) >= layer_idx && ischar(copy_param.layer_dest.desc{layer_idx})
      layers.set_desc(id,copy_param.layer_dest.desc{layer_idx});
      
    elseif ischar(layer_dest(layer_idx).desc)
      layers.set_desc(id,layer_dest(layer_idx).desc);
      
    elseif ischar(layer_source(layer_idx).desc)
      layers.set_desc(id,layer_source(layer_idx).desc);
      
    else
      layers.set_desc(id,NaN);
    end
    % Update "age" field
    if isnumeric(copy_param.layer_dest.age)
      layers.set_age(id,copy_param.layer_dest.age);
      
    elseif length(copy_param.layer_dest.age) >= layer_idx && isnumeric(copy_param.layer_dest.age{layer_idx})
      layers.set_age(id,copy_param.layer_dest.age{layer_idx});
      
    elseif isnumeric(layer_dest(layer_idx).age)
      layers.set_age(id,layer_dest(layer_idx).age);
      
    elseif isnumeric(layer_source(layer_idx).age)
      layers.set_age(id,layer_source(layer_idx).age);
      
    else
      layers.set_age(id,'standard');
    end
    % Update "age_source" field
    if isstruct(copy_param.layer_dest.age_source)
      layers.set_age_source(id,copy_param.layer_dest.age_source);
      
    elseif length(copy_param.layer_dest.age_source) >= layer_idx && isstruct(copy_param.layer_dest.age_source{layer_idx})
      layers.set_age_source(id,copy_param.layer_dest.age_source{layer_idx});
      
    elseif isstruct(layer_dest(layer_idx).age_source)
      layers.set_age_source(id,layer_dest(layer_idx).age_source);
      
    elseif isstruct(layer_source(layer_idx).age_source)
      layers.set_age_source(id,layer_source(layer_idx).age_source);
      
    else
      layers.set_age_source(id,struct());
    end
    
    % Update layer vectors
    layers.update_layer(param.cmd.frms, id, all_points(layer_idx).gps_time, ...
      all_points(layer_idx).twtt_final,all_points(layer_idx).quality_final,all_points(layer_idx).type_final);
  end
  layers.save();
  
elseif strcmpi(copy_param.layer_dest.source,'echogram')
  %% Save echogram
  for frm = param.cmd.frms
    % Create file name for each frame
    if copy_param.layer_source.echogram_source_img == 0
      echo_fn = fullfile(ct_filename_out(param,copy_param.layer_dest.echogram_source,''), ...
        sprintf('Data_%s_%03d.mat', param.day_seg, frm));
    else
      echo_fn = fullfile(ct_filename_out(param,copy_param.layer_dest.echogram_source,''), ...
        sprintf('Data_img_%02d_%s_%03d.mat', copy_param.layer_source.echogram_source_img, param.day_seg, frm));
    end
    if ~exist(echo_fn,'file')
      warning('Echogram data file does not exist: %s\n', echo_fn);
      continue;
    end
    
    % Load echogram
    echo = load(echo_fn,'GPS_time');
    
    layers = layerdata(param, copy_param.layer_dest.layerdata_source);
    for layer_idx = 1:length(layer_dest)
      
      % Create automated points:
      if strcmpi(copy_param.layer_dest.name,'surface')
        echo.Surface = interp1(all_points(layer_idx).gps_time,all_points(layer_idx).twtt_final,echo.GPS_time);
        % Append the new results back to the echogram file
        ct_save(echo_fn,'-append','-struct','echo','Surface');
      elseif strcmpi(copy_param.layer_dest.name,'bottom')
        echo.Bottom = interp1(all_points(layer_idx).gps_time,all_points(layer_idx).twtt_final,echo.GPS_time);
        % Append the new results back to the echogram file
        ct_save(echo_fn,'-append','-struct','echo','Bottom');
      else
        echo.(copy_param.layer_dest.name) = interp1(all_points(layer_idx).gps_time,all_points(layer_idx).twtt_final,echo.GPS_time);
        % Append the new results back to the echogram file
        ct_save(echo_fn,'-append','-struct','echo',copy_param.layer_dest.name);
      end
      
    end
  
  end
  
end
