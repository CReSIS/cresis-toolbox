classdef surfdata < handle
  % tomo.surfdata(fn) < handle
  %
  % A class that manages surf data in a frame.
  %
  % fn: optional string containing a surfdata filename to load, default
  %   is to create an empty class
  %
  % Example of a filepath:
  % X:\ct_data\rds\2014_Greenland_P3\CSARP_surfData\20140401_03\Data_20140401_03_037.mat
  %
  % Example of how to generate a filepath:
  %   param.radar_name   = 'rds';
  %   param.season_name  = '2014_Greenland_P3';
  %   param.day_seg = '20140401_03'
  %   surfdata_ref = 'surfData';
  %   frm = 37;
  %   fn = fullfile(ct_filename_out(param,surfdata_ref,''),...
  %     sprintf('Data_%s_%03d.mat',param.day_seg,frm));
  %
  % Author: Shane Chu, John Paden
  %
  % See also: run_surfdata.m, surfdata.m
  
  properties (Constant)
    current_version = 3.0;
  end
  
  properties
    surfdata_source
    
    % fcs: flight (SAR) coordinate system for each column in surf.[xy]
    %  .origin: origin, 3 by Nx
    %  .x: unit x-axis vector, 3 by Nx (points along-track)
    %  .y: unit y-axis vector, 3 by Nx (points left, but equal to cross(x,z))
    %  .z: unit z-axis vector, 3 by Nx (points up, but orthogonal to x)
    fcs
    
    % gps_source: String containing the gps source
    gps_source
    
    % gps_time: GPS time of each column in surf.[xy]
    gps_time
    
    % param: parameter structure
    % param.day_seg: string containing the segment
    % param.load.frm: integer scalar containing the frame number
    % param.radar.lever_arm_fh: lever arm function handle used to create trajectories
    % param.radar_name: string containing the radar name
    % param.records.gps.time_offset: Time offset used when syncing radar records to GPS
    % param.season_name: string containing the season name
    % param.sw_version: software version structure from current_software_version.m
    param
    
    % surf: A structure array; each element holds a single surface
    %  .active: Index into surf structure which indicates the "active"
    %    surface to use when this surface is selected. Automated tracking
    %    results go to this surface.
    %  .gt: Index into surf structure which indicates the ground truth
    %    surface to use when this surface is selected. Manual labels or
    %    ground truth go to this surface.
    %  .mask: Index into surf structure which indicates the "ice mask"
    %    surface to use when this surface is selected.
    %  .name: string containing the name of the surface (e.g. 'top',
    %    'bottom')
    %  .plot_name_values: Plot (name,value) pairs stored in a cell array
    %    which will be passed in when ever this surface is plotted. These
    %    use the Matlab "plot" function and allow specifying colors,
    %    marker, and so on.
    %  .quality: Index into surf structure which indicates the "quality"
    %    surface to use when this surface is selected.
    %  .top: Index into surf structure which indicates the "top"
    %    surface to use when this surface is selected.
    %  .visible: Logical scalar indicating whether or not the surface should
    %    be plotted.
    %  .x: Nsv by Nx array containing the elevation angle of each surface
    %      point, a NaN value indicates no data at this point
    %  .y: Nsv by Nx array containing the twtt of each surface point, a NaN
    %      value indicates no data at this point
    surf
    
    theta % Support legacy "bins" unit format
    time % Support legacy "bins" unit format
    
    unit_type
  end
  
  %% PUBLIC METHODS ==========
  methods
    
    function obj = surfdata(source,surfdata_source)
      %% surfdata constructor
      
      if nargin < 2 || isempty(surfdata_source)
        surfdata_source = 'surf'; % CSARP_surf directory
      end
      obj.surfdata_source = surfdata_source;
      
      file_type = file_type_get(source);
      if strcmp(file_type,'array')
        % Input source is array echogram file: create a new surfdata
        % -----------------------------------------------------------------
        if ischar(source)
          % If a filename, load into a structure.
          source = echo_load(source);
        end
        
        tmp_param = echo_param(source);
        
        obj.fcs.origin = tmp_param.array_proc.fcs.origin;
        obj.fcs.x = tmp_param.array_proc.fcs.x;
        obj.fcs.y = tmp_param.array_proc.fcs.y;
        obj.fcs.z = tmp_param.array_proc.fcs.z;
        
        obj.gps_source = source.param_records.gps_source;
        
        obj.gps_time = source.GPS_time;
        
        obj.param.day_seg = tmp_param.day_seg;
        obj.param.load.frm = tmp_param.load.frm;
        obj.param.radar.lever_arm_fh = tmp_param.radar.lever_arm_fh;
        obj.param.radar_name = tmp_param.radar_name;
        obj.param.records.gps.time_offset = tmp_param.records.gps.time_offset;
        obj.param.season_name = tmp_param.season_name;
        obj.param.sw_version = current_software_version;
        
        obj.surf = struct('active',{}, ...
          'gt',{}, ...
          'mask',{}, ...
          'name',{}, ...
          'plot_name_values',{}, ...
          'quality',{}, ...
          'top',{}, ...
          'visible',{}, ...
          'x',{}, ...
          'y',{} );
        
      elseif strcmp(file_type,'surf')
        % Input source is surf file: load existing surfdata
        % -----------------------------------------------------------------
        if ischar(source)
          % If a filename, load into a structure.
          source = load(source);
        end
        
        obj.fcs.origin = source.fcs.origin;
        obj.fcs.x = source.fcs.x;
        obj.fcs.y = source.fcs.y;
        obj.fcs.z = source.fcs.z;
        
        obj.gps_source = source.gps_source;
        
        obj.gps_time = source.gps_time;
        
        obj.param.day_seg = source.param.day_seg;
        obj.param.load.frm = source.param.load.frm;
        obj.param.radar.lever_arm_fh = source.param.radar.lever_arm_fh;
        obj.param.radar_name = source.param.radar_name;
        obj.param.records.gps.time_offset = source.param.records.gps.time_offset;
        obj.param.season_name = source.param.season_name;
        obj.param.sw_version = current_software_version;
        
        if isempty(source.surf)
          source.surf = struct();
        end
        obj.surf = orderfields(source.surf);
      end
      
      obj.unit_type = 'standard';
    end
    
    function adjust_surf(obj, dbin, surface_name_string)
      %% adjust_surf
      % obj.adjust_surf(dbin)
      %
      % Input:
      %   dbin: Number of bins to offset the surface
      %
      %   surface_name_string: A cell array of strings that match the name
      %   of the surface in the surf struct array of the object. If empty
      %   or undefined, all surfaces will be updated.
      %
      % Result:
      %   1. surf struct .y field will be adjusted by dbin
      
      if ~exist('surface_name_string','var')
        surface_name_string = [];
      end
      for surf_idx = 1:length(obj.surf)
        if isempty(surface_name_string) ...
            || ((ischar(surface_name_string) || iscell(surface_name_string)) ...
            && any(strcmpi(obj.surf(surf_idx).name,surface_name_string)))
          imagesc(obj.surf(surf_idx).y)
          colorbar;
          obj.surf(surf_idx).name
          obj.surf(surf_idx).y(1)
          keyboard
          %           obj.surf(surf_idx).y = obj.surf(surf_idx).y + dbin;
        end
      end
      
    end
    
    function surf_idx = get_index(obj, surf_name, error_on_fail)
      %% get_index
      % obj.get_index(surf_name, error_on_fail)
      %
      % Input:
      % surf_name: A string that matches the name of a surface in the
      %   surf struct array in the object OR a cell array of similar
      %   strings OR an index array of indices into the surf structure
      % error_on_fail: Logical scalar indicating whether or not an error
      %   should be thrown if the surface is not found. Default is false.
      %
      % Return:
      % 1. The index of that surf struct in the surf
      %   struct array in the object, if it is found.
      % 2. Throws an error if it is not found and error_on_fail is true
      %   or if an array of indices were input and contain an invalid
      %   index.
      
      if isnumeric(surf_name)
        % Just check that indices are valid
        valid_list = intersect(unique(surf_name),1:length(obj.surf));
        if length(valid_list) ~= length(unique(surf_name))
          error('Some of the indices in surf_name are invalid.');
        end
        surf_idx = surf_name;
        
      else
        if ~exist('error_on_fail','var') || isempty(error_on_fail)
          error_on_fail = false;
        end
        
        if ischar(surf_name)
          surf_name = {surf_name};
        elseif ~iscell(surf_name)
          error('Input type of surf_name is not valid.');
        end
        
        for idx = 1:length(surf_name)
          new_surf_idx = find(strcmp(surf_name{idx},{obj.surf.name}));
          if error_on_fail && isempty(new_surf_idx)
            error('Surface "%s" is not in the list of surfaces.', surf_name{idx});
          end
          surf_idx(idx) = new_surf_idx;
        end
      end
    end
    
    function surf_names = get_names(obj)
      %% get_names
      % surf_names = get_names(obj)
      %
      % Returns all the surface names in a cell array
      %
      % No inputs
      %
      % surf_names: cell array of surface names
      
      if ~isempty(obj.surf)
        surf_names = {obj.surf.name};
      else
        surf_names = {};
      end
    end
    
    function surf = get_surf(obj, surf_name)
      %% get_surf
      % surf = obj.get_surf(surf_name)
      %
      % Input:
      %   surf_name: Must be one of the following:
      %     1. a string containing a valid surface name
      %     2. a cell array of strings containing valid surface names
      %     3. a numeric array of surface indices
      %
      % Return:
      %   A surf structure array matching surf_name
      
      if isa(surf_name, 'char')
        index = find(strcmpi(surf_name, {obj.surf.name}));
        if index
          surf = obj.surf(index);
        else
          error('Surface "%s" does not exist.', surf_name);
        end
        
      elseif isa(surf_name, 'cell')
        surf = [];
        match_idxs = zeros(size(surf_name));
        for idx = 1:length(surf_name)
          new_match_idx = find(strcmpi(surf_name{idx}, {obj.surf.name}));
          if isempty(new_match_idx)
            error('Surface "%s" does not exist.', surf_name{idx});
          end
          match_idxs(idx) = new_match_idx;
        end
        surf = obj.surf(match_idxs);
        
      elseif isnumeric(surf_name)
        try
          surf = obj.surf(surf_name);
        catch ME
          error('Invalid indices provided:\n\n%s', ME.getReport);
        end
        
      else
        error('Input must be either a string containing a valid surface name, a cell array of strings containing valid surface names, or a numeric array of surface indices.');
      end
    end
    
    function insert_surf(obj, surf_struct)
      %% insert_surf
      % obj.insert_surf(surf_struct)
      %
      % Input:
      %   surf_struct: A surf structure. Normally, the indexing fields
      %   such as top, active, mask, gt, quality should be cleared.
      %
      % Result:
      %   Adds a surf structure, surf_A, into the "surf" array of the object
      %
      % See also: surfdata.clear_references
      
      % check if it is a valid surf structure
      obj.valid_surf(surf_struct);
      
      % check if name of the surface already existed in the class
      if isempty(obj.surf)
        obj.surf = [obj.surf orderfields(surf_struct)];
      elseif any(strcmpi(surf_struct.name,{obj.surf.name}))
        error('This surface is already inserted.');
      else
        obj.surf = [obj.surf orderfields(surf_struct)];
      end
      
    end
    
    function remove_surf(obj, surface_name)
      %% remove_surf
      % obj.remove_surf(surface_name_string)
      %
      % Input:
      %   surface_name_string: A string that matches
      %   the name of the surface in the surf struct
      %   array of the object.
      %
      % Result:
      %   1. Removes surf struct in the surf struct array
      %   of the object.
      %   2. Throws an error if the surface_name is not
      %   in any of the surf struct in the surf struct array
      %   of the object.
      
      match_idx = obj.get_index(surface_name,true);
      
      for surf_idx = 1:length(obj.surf)
        
        if obj.surf(surf_idx).top == match_idx
          obj.surf(surf_idx).top = [];
        elseif obj.surf(surf_idx).top > match_idx
          obj.surf(surf_idx).top = obj.surf(surf_idx).top -1;
        end
        
        if obj.surf(surf_idx).active == match_idx
          obj.surf(surf_idx).active = [];
        elseif obj.surf(surf_idx).active > match_idx
          obj.surf(surf_idx).active = obj.surf(surf_idx).active -1;
        end
        
        if obj.surf(surf_idx).mask == match_idx
          obj.surf(surf_idx).mask = [];
        elseif obj.surf(surf_idx).mask > match_idx
          obj.surf(surf_idx).mask = obj.surf(surf_idx).mask -1;
        end
        
        if obj.surf(surf_idx).gt == match_idx
          obj.surf(surf_idx).gt = [];
        elseif obj.surf(surf_idx).gt > match_idx
          obj.surf(surf_idx).gt = obj.surf(surf_idx).gt -1;
        end
        
        if obj.surf(surf_idx).quality == match_idx
          obj.surf(surf_idx).quality = [];
        elseif obj.surf(surf_idx).quality > match_idx
          obj.surf(surf_idx).quality = obj.surf(surf_idx).quality -1;
        end
      end
      
      obj.surf = [obj.surf(1:match_idx-1) obj.surf(match_idx+1:end)];
    end
    
    function set(obj, surf_name, varargin)
      %% set
      % obj.set(surf_name, NAME_VALUE_PAIRS)
      %
      % Input:
      % surf_name: surface name or cell array of surface names
      % NAME_VALUE_PAIRS: Pairs of input arguments where the first
      %   argument in the pair is the property to change and the second
      %   argument in the pair is the value.
      %
      % Return:
      %   1. Nothing on success
      %   2. Throws an error if surface_old_name is not found.
      
      surf_idxs = obj.get_index(surf_name,true);
      
      for arg_idx = 3:2:nargin
        field_name = lower(varargin{arg_idx-2});
        switch field_name
          case 'name'
            if length(surf_idxs) ~= 1
              error('The name property can only be set for one surface at a time.');
            end
            new_name = varargin{arg_idx-1};
            if any(strcmpi(new_name, {obj.surf([1:surf_idxs-1, surf_idxs+1:end]).name}))
              error('The new name matches an existing name for another surface.');
            end
            obj.surf(surf_idxs).name = new_name;
            
          case {'top','active','mask','gt','quality'}
            new_surf_idx = obj.get_index(varargin{arg_idx-1});
            if length(new_surf_idx) ~= 1
              error('Field %s must be assigned to match a single existing surface.', varargin{arg_idx});
            end
            for surf_idx = surf_idxs
              obj.surf(surf_idx).(field_name) = new_surf_idx;
            end
            
          otherwise
            error('Invalid field %s', varargin{arg_idx-2});
            
        end
        
      end
      
    end
    
    function set_metadata(obj, md)
      %% set_metadata(md)
      %
      % Function for validating all the metadata fields
      %
      % md: struct containing gps_time, fcs, radar_name, param. May contain
      %   theta and time fields.
      
      obj.valid_metadata(md);
      
      obj.param = md.param;
      obj.gps_time = md.gps_time;
      obj.fcs = md.fcs;
      
      if isfield(md,'theta')
        obj.theta = md.theta;
      else
        obj.theta = [];
      end
      if isfield(md,'time')
        obj.time = md.time;
      else
        obj.time = [];
      end
      
    end
    
    function obj = set_surf(obj, surf_struct)
      %% set_surf
      % obj.set_surf(surf_struct)
      %
      % Input:
      %   surf_struct: A surf structure.
      %
      % Result:
      %   1. Replace the surf structure if the name of
      %   surf_struct mathes with another surf struct
      %   in the surf struct array in the object.
      %   2. Throws an error if the surf struct is not valid.
      
      
      % check if it is a valid surf structure
      obj.valid_surf(surf_struct);
      
      % Sets an existing surface to the new field values
      match_idx = obj.get_index(surf_struct.name,true);
      obj.surf(match_idx) = surf_struct;
    end
    
    function [] = save_surfdata(obj, fn)
      %% save_surfdata
      % obj.save_surfdata(fn)
      %
      % Input:
      %  fn: A string that will be the name of the saved surfData file.
      %
      % Result:
      %   Saves the surf struct array in the object
      %   as a .mat file. Creates directories as needed.
      
      % Ensure surface fields are all correct
      for surf_idx = 1:length(obj.surf)
        obj.valid_surf(obj.surf(surf_idx));
      end
      valid_metadata(obj,obj);
      
      old_units = obj.unit_type;
      if ~strcmp(old_units,'standard')
        obj.units('standard');
      end
      surf = [];
      for surf_idx = 1:length(obj.surf)
        surf(surf_idx).name = obj.surf(surf_idx).name;
        surf(surf_idx).x = obj.surf(surf_idx).x;
        surf(surf_idx).y = obj.surf(surf_idx).y;
        surf(surf_idx).plot_name_values = obj.surf(surf_idx).plot_name_values;
        surf(surf_idx).visible = obj.surf(surf_idx).visible;
        surf(surf_idx).top = obj.surf(surf_idx).top;
        surf(surf_idx).active = obj.surf(surf_idx).active;
        surf(surf_idx).mask = obj.surf(surf_idx).mask;
        surf(surf_idx).gt = obj.surf(surf_idx).gt;
        surf(surf_idx).quality = obj.surf(surf_idx).quality;
      end
      
      if ~strcmp(old_units,'standard')
        obj.units(old_units);
      end
      
      param = obj.param;
      gps_source = obj.gps_source;
      gps_time = obj.gps_time;
      fcs = obj.fcs;
      
      fn_dir = fileparts(fn);
      if ~exist(fn_dir,'dir')
        mkdir(fn_dir);
      end
      file_version = sprintf('%dL', obj.current_version);
      file_type = 'surf';
      ct_save(fn, 'fcs', 'file_type', 'file_version', 'gps_source', 'gps_time', ...
        'param', 'surf', '-v7.3');
    end
    
    function units(obj, unit_type)
      %% units(unit_type)
      %
      % Function for converting units of x and y in surf structure array.
      %
      % unit_type: string 'bins' or 'standard'. Standard is elevation angle in deg and
      % twtt in seconds)
      %
      % Fields "obj.theta" and "obj.time" must be set before calling this function.
      
      if strcmp(unit_type,'standard') && strcmp(obj.unit_type,'bins')
        % Switch x,y from elevation angle bins, range bins to elevation angle, twtt
        for surf_idx = 1:length(obj.surf)
          obj.surf(surf_idx).x = interp1(1:length(obj.theta),obj.theta,obj.surf(surf_idx).x);
          if ~all(obj.surf(surf_idx).y(:) == 0 | obj.surf(surf_idx).y(:) == 1)
            obj.surf(surf_idx).y = interp1(1:length(obj.time),obj.time,obj.surf(surf_idx).y);
          end
        end
        obj.unit_type = 'standard';
        
      elseif strcmp(unit_type,'bins') && strcmp(obj.unit_type,'standard')
        % Switch x,y to elevation angle bins, range bins from elevation angle, twtt
        for surf_idx = 1:length(obj.surf)
          obj.surf(surf_idx).x = interp1(obj.theta,1:length(obj.theta),obj.surf(surf_idx).x);
          if ~all(obj.surf(surf_idx).y(:) == 0 | obj.surf(surf_idx).y(:) == 1)
            obj.surf(surf_idx).y = interp1(obj.time,1:length(obj.time),obj.surf(surf_idx).y);
          end
        end
        obj.unit_type = 'bins';
      end
    end
    
    function valid_metadata(obj, md)
      %% valid_metadata(md)
      %
      % Function for validating all the metadata fields
      %
      % md: struct containing gps_time, theta, fcs, param.radar_name,
      %   param.season_name, param.day_seg, and param.load.frm.
      
      if ~ischar(md.param.day_seg)
        error('param.day_seg must be a string');
      end
      
      if ~isnumeric(md.param.load.frm)
        error('parma.load.frm must be a positive integer');
      end
      
      if ~isa(md.param.radar.lever_arm_fh,'function_handle')
        error('param.radar.lever_arm_fh must be a function handle');
      end
      
      if ~ischar(md.param.radar_name)
        error('param.radar_name must be a string');
      end
      
      if ~isnumeric(md.param.records.gps.time_offset)
        error('param.records.gps.time_offset must be a positive integer');
      end
      
      if ~ischar(md.param.season_name)
        error('param.season_name must be a string');
      end
      
      if ~ischar(md.gps_source)
        error('gps_source must be a string');
      end
      
      if size(md.gps_source,1) ~= 1
        error('gps_source must be a row vector.');
      end
      
      Nx = size(md.gps_time,2);
      
      if size(md.gps_time,1) ~= 1
        error('gps_time must be a row vector.');
      end
      
      if ~isempty(obj.surf) && size(obj.surf(1).x,2) ~= Nx
        error('gps_time must have same number of columns as surf.x');
      end
      
      if size(md.fcs.origin,2) ~= Nx
        error('fcs.origin must have same number of columns as gps_time.');
      end
      
      if size(md.fcs.x,2) ~= Nx
        error('fcs.x must have same number of columns as gps_time.');
      end
      
      if size(md.fcs.y,2) ~= Nx
        error('fcs.y must have same number of columns as gps_time.');
      end
      
      if size(md.fcs.z,2) ~= Nx
        error('fcs.z must have same number of columns as gps_time.');
      end
      
      if size(md.fcs.origin,1) ~= 3
        error('fcs.origin must have 3 rows.');
      end
      
      if size(md.fcs.x,1) ~= 3
        error('fcs.x must have 3 rows.');
      end
      
      if size(md.fcs.y,1) ~= 3
        error('fcs.y must have 3 rows.');
      end
      
      if size(md.fcs.z,1) ~= 3
        error('fcs.z must have 3 rows.');
      end
      
    end
    
    function [] = valid_surf(obj, surf_struct)
      %% valid_surf
      % obj.valid_surf(surf_struct)
      %
      % Input:
      %  surf_struct: A surf structure.
      %
      % Result:
      % 1. Nothing, if the surf structure is valid.
      % 2. Throws an error if any of the condition
      % is not satisfied.
      
      % check if it's a structure
      if ~isstruct(surf_struct)
        error('The input type is not a structure');
      end
      
      % check if all the fields exist
      if ~isfield(surf_struct, {'x', 'y', 'plot_name_values', ...
          'name', 'top', 'active', ...
          'mask', 'gt', ...
          'quality','visible'})
        error('Struct missing field(s) that are necessary for a surface struct.');
      end
      
      % type check
      if ~isa(surf_struct.x, 'double')
        error('Invalid field type for the field x (Should be type double)');
      end
      
      if ~isa(surf_struct.y, 'double') && (~isa(surf_struct.y, 'logical'))
        error('Invalid field type for the field y (Should be type double or logical)');
      end
      
      if ~isa(surf_struct.plot_name_values, 'cell')
        error('Invalid field type for the field plot_name_values (Should be type cell).');
      end
      
      if ~isa(surf_struct.name, 'char')
        error('Invalid field type for the field name (Should be type char).');
      end
      
      if ~isa(surf_struct.top, 'double')
        error('Invalid field type for the field top (Should be type double).');
      end
      
      if ~isa(surf_struct.active, 'double')
        error('Invalid field type for the field active (Should be type double).');
      end
      
      if ~isa(surf_struct.mask, 'double')
        error('Invalid field type for the field mask (Should be type double).');
      end
      
      if ~isa(surf_struct.gt, 'double')
        error('Invalid field type for the field gt (Should be type double).');
      end
      
      if ~isa(surf_struct.quality, 'double')
        error('Invalid field type for the field quality (Should be type double).');
      end
      
      if ~isa(surf_struct.visible, 'logical')
        error('Invalid field type for the field visible (Should be type logical).');
      end
      
      % Check that size of x and y match each other
      if ~isequal(size(surf_struct.x), size(surf_struct.y))
        error('Size of the field x and field y do not match each other.');
      end
      % check if all the surface_struct in the object has the same dimension in x and y
      if ~isempty(obj.surf) && ...
          ~all(arrayfun(@(arr) isequal(size(surf_struct.x), size(arr.x)), obj.surf))
        % we only check x because x and y must have the same dimension
        % from the previous check.
        error('Field x and y sizes do not match this surfdata''s surf x and y sizes.');
      end
      % Check that surface indices point to valid surface indices:
      if ~isempty(surf_struct.top) ...
          && ~(surf_struct.top > 0 || surf_struct.top < length(obj.surf))
        error('top index out of range.');
      end
      
      if ~isempty(surf_struct.active) ...
          && ~(surf_struct.active > 0 || surf_struct.active < length(obj.surf))
        error('active index out of range.');
      end
      
      if ~isempty(surf_struct.mask) ...
          && ~(surf_struct.mask > 0 || surf_struct.mask < length(obj.surf))
        error('mask index out of range.');
      end
      
      if ~isempty(surf_struct.gt) ...
          && ~(surf_struct.gt > 0 || surf_struct.gt < length(obj.surf))
        error('gt index out of range.');
      end
      
      if ~isempty(surf_struct.quality) ...
          && ~(surf_struct.quality > 0 || surf_struct.quality < length(obj.surf))
        error('quality index out of range.');
      end
    end
    
    function [rmse,mean_diff,median_diff,min_diff,max_diff,surf_diff] ...
        = compare(obj, ref, sd_other, other, DOA_trim)
      % [rmse,mean_diff,median_diff,min_diff,max_diff,surf_diff] ...
      %   = tomo.compare(ref, sd_other, other)
      %
      % Compares one of the surfaces in this object to a surface in another
      % surfdata object.
      %
      % ref: reference layer (get_surf's surf_name argument)
      % sd_other: another surfdata object to compare to (can also be this
      %   surfdata object)
      % other: layer to compare (get_surf's surf_name argument)
      % DOA_trim:
      %
      % rmse: root mean squared error of difference
      % mean_diff: mean of the absolute value of the difference
      % median_diff: median of the absolute value of the difference
      % min_diff: minimum of the absolute value of the difference
      % max_diff: maximum of the absolute value of the difference
      % surf_diff: ansolute vlaue difference matrix
      %
      % See also: tomo.run_compare_surfdata, tomo.compare_surfdata,
      %   tomo.surfdata
      
      ref = obj.get_surf(ref);
      other = sd_other.get_surf(other);
      
      if 1
        quality_mtx_ref = obj.surf(other.quality).y;
        quality_mtx_other = sd_other.surf(other.quality).y;
        
        bad_idx_ref = find(quality_mtx_ref==0);
        bad_idx_other = find(quality_mtx_other==0);
        
        ref.y(bad_idx_ref) = NaN;
        other.y(bad_idx_ref) = NaN;
        
        ref.y(bad_idx_other) = NaN;
        other.y(bad_idx_other) = NaN;
        %       if any(isnan(ref.y(:))) || any(isnan(other.y(:)))
        %         keyboard
        %       end
      end
      
      surf_diff = (other.y(1+DOA_trim(1):end-DOA_trim(end)+1,:) ...
        - ref.y(1+DOA_trim(1):end-DOA_trim(end)+1,:));
      rmse        = sqrt(nanmean(abs(surf_diff(:)).^2));
      mean_diff   = nanmean(surf_diff(:));
      median_diff = nanmedian(surf_diff(:));
      min_diff    = nanmin(surf_diff(:));
      max_diff    = nanmax(surf_diff(:));
    end
    
    function [rmse,mean_diff,median_diff,min_diff,max_diff,surf_diff] ...
        = compare_doa(obj, ref, sd_other, other, DOA_trim,fs)
      % [rmse,mean_diff,median_diff,min_diff,max_diff,surf_diff] ...
      %   = tomo.compare(ref, sd_other, other)
      %
      % Compares one of the surfaces in this object to a surface in another
      % surfdata object.
      %
      % ref: reference layer (get_surf's surf_name argument)
      % sd_other: another surfdata object to compare to (can also be this
      %   surfdata object)
      % other: layer to compare (get_surf's surf_name argument)
      % DOA_trim:
      %
      % rmse: root mean squared error of difference
      % mean_diff: mean of the absolute value of the difference
      % median_diff: median of the absolute value of the difference
      % min_diff: minimum of the absolute value of the difference
      % max_diff: maximum of the absolute value of the difference
      % surf_diff: ansolute vlaue difference matrix
      %
      % See also: tomo.run_compare_surfdata, tomo.compare_surfdata,
      %   tomo.surfdata
      last_fprintf_time = -inf;
      
      ref = obj.get_surf(ref);
      other = sd_other.get_surf(other);
      
      if 1
        quality_mtx_ref = obj.surf(other.quality).y;
        quality_mtx_other = sd_other.surf(other.quality).y;
        
        bad_doa_mask_ref = abs(ref.x) > 80*pi/180;
        bad_doa_mask_other = abs(other.x) > 80*pi/180;
        
        bad_idx_ref = find(quality_mtx_ref==0);
        bad_idx_other = find(quality_mtx_other==0);
        
        ref.y(bad_idx_ref) = NaN;
        other.y(bad_idx_ref) = NaN;
        ref.y(bad_doa_mask_ref) = NaN;
        other.y(bad_doa_mask_other) = NaN;
        
        ref.y(bad_idx_other) = NaN;
        other.y(bad_idx_other) = NaN;
        %       if any(isnan(ref.y(:))) || any(isnan(other.y(:)))
        %         keyboard
        %       end
      end
      
      Td_max = max([max(ref.y(:)), max(other.y(:))]);
      Nt = ceil(Td_max*fs);
      [Nsv,Nx] = size(ref.y);
      
      twtt = (0:Nt-1)./fs;
      
      doa_error = [];
      doa_val = [];
      for rline = 1:Nx
        
        if now > last_fprintf_time+60/86400
          fprintf('    Along track: %2.1f (%.0f of %.0f) (%s)\n', rline, rline, Nx, datestr(now));
          last_fprintf_time = now;
          last_fprintf_time_bin = now;
        end
        
        ref_theta = nan(Nt,0);
        other_theta = nan(Nt,0);
        
        x1_ref = ref.x(:,rline);
        y1_ref = ref.y(:,rline);
        
        x1_other = other.x(:,rline);
        y1_other = other.y(:,rline);
        
        x1_ref = x1_ref(:);
        y1_ref = y1_ref(:).';
        
        
        x1_other = x1_other(:);
        y1_other = y1_other(:).';
        
        for rbin_idx = 1:length(twtt)
          x2_ref = x1_ref;
          y2_ref = twtt(rbin_idx)*ones(size(y1_ref));
          x2_other = x1_other;
          y2_other = twtt(rbin_idx)*ones(size(y1_other));
          [bin_theta_ref,y0_ref,~,~] = intersections(x1_ref,y1_ref,x2_ref,y2_ref);
          [bin_theta_other,y0_other,~,~] = intersections(x1_other,y1_other,x2_other,y2_other);
          
          nsrc_ref = length(bin_theta_ref(~isnan(bin_theta_ref)));
          nsrc_other = length(bin_theta_other(~isnan(bin_theta_other)));
          
          if nsrc_ref == nsrc_other & all([nsrc_ref, nsrc_other])
            
            good_ref = sort(bin_theta_ref(~isnan(bin_theta_ref)));
            good_other = sort(bin_theta_other(~isnan(bin_theta_ref)));
            
            er_doa = good_ref - good_other;
            doa_truth = good_ref;
            
            doa_error = [doa_error, er_doa(:).'];
            doa_val  = [doa_val, doa_truth(:).'];
          end
          
        end
        
        
        
        %         surf_diff = abs(other.y(1+DOA_trim(1):end-DOA_trim(end)+1,:) ...
        %           - ref.y(1+DOA_trim(1):end-DOA_trim(end)+1,:));
        %         rmse        = sqrt(nanmean(abs(surf_diff(:)).^2));
        %         mean_diff   = nanmean(surf_diff(:));
        %         median_diff = nanmedian(surf_diff(:));
        %         min_diff    = nanmin(surf_diff(:));
        %         max_diff    = nanmax(surf_diff(:));
      end
      keyboard
    end
    
  end
  
  %% STATIC METHODS ==========
  methods(Static)
    function surf = clear_references(surf)
      %% clear_references
      for idx = 1:length(surf)
        surf(idx).top = [];
        surf(idx).active = [];
        surf(idx).mask = [];
        surf(idx).gt = [];
        surf(idx).quality = [];
      end
    end
    
    function surf = empty_surf()
      %% empty_surf
      % tomo.surfdata.empty_surf()
      %
      % Returns an empty surf structure
      surf.x = [];
      surf.y = [];
      surf.plot_name_values = {'color','blue','marker','^'};
      surf.name = '';
      surf.top = [];
      surf.active = [];
      surf.mask = [];
      surf.gt= [];
      surf.quality = [];
      surf.visible = true;
    end
    
    function modify(param,fn,layers,varargin)
      %% modify
      % tomo.surfdata.modify(param,fn,layers,varargin)
      %
      % Function for modifying surfData files. Can be used to create new layers
      % by specifying a layer that does not already exist.
      %
      % param: parameter spreadsheet structure
      %  .radar_name: determines which radar to modify
      %  .season_name: determines which season to modify
      %  .day_seg: determines which segment to modify
      %  .cmd.frms: determines which frames to modify
      % fn: filename to ct_filename_out(), leave empty for default 'surfData'
      % varargin: arbitrary list of name,value pairs.
      %  third, fifth, etc. arguments are a string containing the name of the
      %    property to modify
      %  fourth, sixth, etc. arguments are the new value to use for the
      %    corresponding named property
      %
      % Author: John Paden
      
      % Determine which frames to process
      frames = frames_load(param);
      
      if isempty(param.cmd.frms)
        param.cmd.frms = 1:length(frames.frame_idxs);
      end
      % Remove frames that do not exist from param.cmd.frms list
      [valid_frms,keep_idxs] = intersect(param.cmd.frms, 1:length(frames.frame_idxs));
      if length(valid_frms) ~= length(param.cmd.frms)
        bad_mask = ones(size(param.cmd.frms));
        bad_mask(keep_idxs) = 0;
        warning('Nonexistent frames specified in param.cmd.frms (e.g. frame "%g" is invalid), removing these', ...
          param.cmd.frms(find(bad_mask,1)));
        param.cmd.frms = valid_frms;
      end
      
      % out_path: output surfData directory
      out_path = ct_filename_out(param, fn, 'CSARP_surfData');
      
      for frm = param.cmd.frms
        fn = fullfile(out_path,sprintf('Data_%s_%03d.mat', param.day_seg, frm));
        
        % Load "surf" variable
        load(fn);
        for layer = layers(:).'
          for idx = 1:2:length(varargin)
            surf(layer).(varargin{idx}) = varargin{idx+1};
          end
        end
        ct_save(fn,'-append','surf');
      end
    end
    
    function run_update_file()
      %% run_update_file
      
      params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'');
      %       params = ct_set_params(params,'cmd.generic',0);
      params = ct_set_params(params,'cmd.generic',1,'day_seg','20140506_01');
      param_override.cmd.frms = [2 3 4];
      
      % params = read_param_xls(ct_filename_param('rds_param_2009_Antarctica_TO.xls'));
      % params = ct_set_params(params,'cmd.generic',0);
      % params = ct_set_params(params,'cmd.generic',1,'day_seg','20091224_01');
      % param_override.cmd.frms = [];
      param_override.update.input = 'surfData_sar';
      param_override.update.output = 'surf_sar';
      param_override.update.echogram = 'standard_air';
      %       param_override.update.echogram = 'CSARP_post/standard';
      
      %       params = read_param_xls(ct_filename_param('rds_param_2019_Antarctica_Ground.xls'));
      %       params = ct_set_params(params,'cmd.generic',0);
      %       params = ct_set_params(params,'cmd.generic',1,'day_seg','20200107_01');
      %       param_override.cmd.frms = [];
      %       param_override.update.input = 'surfData_paden';
      %       param_override.update.output = 'surfData_paden2';
      %       param_override.update.echogram = 'music3D_paden';
      %
      global gRadar;
      
      % Input checking
      if exist('param_override','var')
        param_override = merge_structs(gRadar,param_override);
      else
        param_override = gRadar;
      end
      
      for param_idx = 1:length(params)
        param = params(param_idx);
        if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
          continue;
        end
        
        param = merge_structs(param, param_override);
        
        % Load frames file
        frames = frames_load(param);
        param.cmd.frms = frames_param_cmd_frms(param,frames);
        
        for frm = param.cmd.frms
          
          fn = fullfile(ct_filename_out(param,param.update.input,''),sprintf('Data_%s_%03d.mat',param.day_seg,frm));
          fn_cur_ver = fullfile(ct_filename_out(param,param.update.output,''),sprintf('Data_%s_%03d.mat',param.day_seg,frm));
          echogram_fn = fullfile(ct_filename_out(param,param.update.echogram,''),sprintf('Data_img_01_%s_%03d.mat',param.day_seg,frm));
          %           echogram_fn = fullfile(ct_filename_out(param,param.update.echogram,''),sprintf('Data_%s_%03d.mat',param.day_seg,frm));
          fprintf('Update\n  %s\n  %s\n', fn, echogram_fn);
          tomo.surfdata.update_file(fn,fn_cur_ver,echogram_fn);
        end
        
      end
    end
    
    function surf = update_file(fn,fn_new,echogram_fn)
      %% update_file
      % surf = tomo.surfdata.update_file(fn,fn_new,echogram_fn)
      %
      % Updates filename fn to latest version of surfdata and stores the
      % result in fn_new. The updated surf structure is returned.
      %
      % echogram_fn: the echogram filename is only required when converting
      %   from version 1.0 and 2.0 files to the newest format. The echogram
      %   filename fields must match the surfData file or the updating will
      %   not work properly.
      
      fn_version = tomo.surfdata.version(fn);
      if fn_version == 1.0
        %% update_file: v1.0
        if ~isempty(whos('-file',echogram_fn,'param_array'))
          tmp = load(echogram_fn,'param_array','param_records','GPS_time');
          tmp.param = tmp.param_array;
        else
          tmp = load(echogram_fn,'param_combine','param_records','GPS_time');
          tmp.param = tmp.param_combine;
          tmp.param.radar.lever_arm_fh = tmp.param.csarp.lever_arm_fh;
          tmp.param_records.records.gps.time_offset = tmp.param_records.vectors.gps.time_offset;
          tmp.param.array_param.fcs.origin = tmp.param_combine.array_param.fcs{1}{1}.origin;
          tmp.param.array_param.fcs.x = tmp.param_combine.array_param.fcs{1}{1}.x;
          tmp.param.array_param.fcs.y = tmp.param_combine.array_param.fcs{1}{1}.y;
          tmp.param.array_param.fcs.z = tmp.param_combine.array_param.fcs{1}{1}.z;
        end
        
        surf_old = load(fn);
        surf_new = [];
        
        surf_new.fcs.origin = tmp.param.array_param.fcs.origin;
        surf_new.fcs.x = tmp.param.array_param.fcs.x;
        surf_new.fcs.y = tmp.param.array_param.fcs.y;
        surf_new.fcs.z = tmp.param.array_param.fcs.z;
        
        surf_new.gps_source = tmp.param_records.gps_source;
        
        surf_new.gps_time = tmp.GPS_time;
        
        surf_new.param.day_seg = surf_old.day_seg;
        surf_new.param.load.frm = surf_old.frm;
        surf_new.param.radar.lever_arm_fh = tmp.param.radar.lever_arm_fh;
        surf_new.param.radar_name = surf_old.radar_name;
        surf_new.param.records.gps.time_offset = tmp.param_records.records.gps.time_offset;
        surf_new.param.season_name = surf_old.season_name;
        surf_new.param.sw_version = current_software_version();
        
        % Convert x,y from elevation angle bins, range bins to elevation angle, twtt
        for surf_idx = 1:length(surf_new.surf)
          surf_new.surf(surf_idx).active = surf_old.surf(surf_idx).active_layer;
          surf_new.surf(surf_idx).gt = surf_old.surf(surf_idx).control_layer;
          surf_new.surf(surf_idx).mask = surf_old.surf(surf_idx).mask_layer;
          if strcmpi(surf_old.surf(surf_idx).name,'ice surface')
            surf_new.surf(surf_idx).name = 'top';
          elseif strcmpi(surf_old.surf(surf_idx).name,'surface gt')
            surf_new.surf(surf_idx).name = 'top gt';
          elseif strcmpi(surf_old.surf(surf_idx).name,'surface quality')
            surf_new.surf(surf_idx).name = 'top quality';
          else
            surf_new.surf(surf_idx).name = surf_old.surf(surf_idx).name;
          end
          surf_new.surf(surf_idx).plot_name_values = {};
          surf_new.surf(surf_idx).quality = surf_old.surf(surf_idx).quality_layer;
          surf_new.surf(surf_idx).top = surf_old.surf(surf_idx).surf_layer;
          if ischar(surf_old.surf(surf_idx).visible)
            if strcmpi(surf_old.surf(surf_idx).visible,'on')
              surf_old.surf(surf_idx).visible = true;
            else
              surf_old.surf(surf_idx).visible = false;
            end
          end
          surf_new.surf(surf_idx).x = interp1(1:length(surf_old.theta),surf_old.theta,surf_new.surf(surf_idx).x);
          if all(surf_new.surf(surf_idx).y(:) == 0 | surf_new.surf(surf_idx).y(:) == 1)
            surf_new.surf(surf_idx).y = surf_new.surf(surf_idx).y;
          else
            surf_new.surf(surf_idx).y = interp1(1:length(surf_old.time),surf_old.time,surf_new.surf(surf_idx).y);
          end
          
        end
        surfdata_updated = true;
        
      elseif fn_version == 2.0
        %% update_file: v2.0
        if ~isempty(whos('-file',echogram_fn,'param_array'))
          tmp = load(echogram_fn,'param_array','param_records');
          tmp.param = tmp.param_array;
        else
          tmp = load(echogram_fn,'param_combine','param_records');
          tmp.param = tmp.param_combine;
          tmp.param.radar.lever_arm_fh = tmp.param.csarp.lever_arm_fh;
          tmp.param_records.records.gps.time_offset = tmp.param_records.vectors.gps.time_offset;
        end
        
        surf_old = load(fn);
        surf_new = [];
        
        surf_new.fcs = surf_old.FCS;
        
        surf_new.gps_source = tmp.param_records.gps_source;
        
        surf_new.gps_time = surf_old.gps_time;
        
        surf_new.param.day_seg = surf_old.day_seg;
        surf_new.param.load.frm = surf_old.frm;
        surf_new.param.radar.lever_arm_fh = tmp.param.radar.lever_arm_fh;
        surf_new.param.radar_name = surf_old.radar_name;
        surf_new.param.records.gps.time_offset = tmp.param_records.records.gps.time_offset;
        surf_new.param.season_name = surf_old.season_name;
        surf_new.param.sw_version = current_software_version();
        surf_new.surf = surf_old.surf;
        
        % Convert x,y from elevation angle bins, range bins to elevation angle, twtt
        for surf_idx = 1:length(surf_new.surf)
          surf_new.surf(surf_idx).x = interp1(1:length(surf_old.theta),surf_old.theta,surf_new.surf(surf_idx).x);
          if all(surf_new.surf(surf_idx).y(:) == 0 | surf_new.surf(surf_idx).y(:) == 1)
            surf_new.surf(surf_idx).y = surf_new.surf(surf_idx).y;
          elseif all(~isfinite(surf_new.surf(surf_idx).y(:)) | surf_new.surf(surf_idx).y(:) < 1 )
            % Assume y-values are twtt (this should never happen)
            surf_new.surf(surf_idx).y = surf_new.surf(surf_idx).y;
          else
            surf_new.surf(surf_idx).y = interp1(1:length(surf_old.time),surf_old.time,surf_new.surf(surf_idx).y);
          end
        end
        surfdata_updated = true;
        
      elseif fn_version == 3.0
        surf_new = load(fn);
        surf_new.param.sw_version = current_software_version();
        surfdata_updated = false;
        
        % Ensure x,y converted from elevation angle bins, range bins to elevation angle, twtt
        for surf_idx = 1:length(surf_new.surf)
          if any(surf_new.surf(surf_idx).y(isfinite(surf_new.surf(surf_idx).y)) > 1)
            warning('HACK: Fixing temporary file format. Requires echogram_fn input argument. This will overwrite the existing surfdata file. Run "dbcont" to continue or "dbquit" to cancel.');
            keyboard;
            if ~surfdata_updated
              mdata = load(echogram_fn,'Time','Tomo');
              surfdata_updated = true;
            end
            if any(surf_new.surf(surf_idx).x(:) > pi)
              surf_new.surf(surf_idx).x = interp1(1:length(mdata.Tomo.theta(:,1)),mdata.Tomo.theta(:,1),surf_new.surf(surf_idx).x);
            end
            if all(surf_new.surf(surf_idx).y(:) == 0 | surf_new.surf(surf_idx).y(:) == 1)
              surf_new.surf(surf_idx).y = surf_new.surf(surf_idx).y;
            else
              surf_new.surf(surf_idx).y = interp1(1:length(mdata.Time),mdata.Time,surf_new.surf(surf_idx).y);
            end
          end
        end
        
      else
        error('Invalid file version: %g.\n', fn_version);
        
      end
      
      if nargin >= 2
        surf = tomo.surfdata(surf_new);
        if ~strcmp(fn,fn_new) || surfdata_updated
          fprintf('  Saving updated file: %s\n', fn_new);
          surf.save_surfdata(fn_new);
        end
      end
      
    end
    
    function surfdata_ver = version(fn)
      %% version
      % tomo.surfdata.version(fn)
      %
      % Returns the version of the file contained in fn.
      
      tmp = whos('-file',fn);
      file_type_idx = find(strcmp('file_type',{tmp.name}));
      if ~isempty(file_type_idx)
        load(fn,'file_type');
        if ~strcmpi(file_type,'surf')
          error('fn is not a surf file. fn: %s', fn);
        end
      end
      
      version_idx = find(strcmp('version',{tmp.name}));
      if ~isempty(version_idx)
        load(fn,'version');
        if version == 2.0
          surfdata_ver = version;
          return;
        else
          error('Invalid file version: %d.\n', version);
        end
      end
      
      file_version_idx = find(strcmp('file_version',{tmp.name}));
      if ~isempty(file_version_idx)
        load(fn,'file_version');
        if file_version(1) == '3'
          surfdata_ver = 3.0;
          return;
        else
          error('Invalid file version: %s.\n', file_version);
        end
      end
      
      surfdata_ver = 1.0;
      
    end
    
    function surf = add_surf_from_dem(param,param_override)
      %% add_surf_from_dem
      % tomo.surfdata.add_surf_from_dem(param,param_override)
      %
      % param:  struct with processing parameters or function handle to
      % script with processing parameters
      %   .add_surf_from_dem.delta_at = along track decimation factor
      %   .add_surf_from_dem.theta_vec
      %   .add_surf_from_dem.dem_res
      %
      % param_override: parameters in this struct override parameters in
      % param.  This struct must also contain the gRdar fields.
      % Typically global gRdadr; param_override = gRadar;
      %
      % Example:
      %   See run_add_surf_from_dem for how to run this function
      %   directly.  This function may be called from the run_master.m
      %   script using the param spreadsheet and enabling the cmd.generic
      %   column.
      %
      % Authors:  Theresa Moore, John Paden
      %
      % See also:  run_add_surf_from_dem
      %
      %
      % General Setup
      % =================================================================
      physical_constants
      param = merge_structs(param,param_override);
      
      fprintf('==========================================================\n');
      fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
      fprintf('==========================================================\n');
      
      % Input Checks
      % =================================================================
      
      % Load frames file
      frames = load(ct_filename_support(param, '', 'frames'));
      
      % If no frames specified, then do all frames
      if isempty(param.cmd.frms)
        param.cmd.frms = 1:length(frames.frame_idxs);
      end
      
      % Remove frames that do not exist from param.cmd.frms list
      [valid_frms,keep_idxs] = intersect(param.cmd.frms, 1:length(frames.frame_idxs));
      if length(valid_frms) ~= length(param.cmd.frms)
        bad_mask = ones(size(param.cmd.frms));
        bad_mask(keep_idxs) = 0;
        warning('Nonexistent frames specified in param.cmd.frms (e.g. frame "%g" is invalid), removing these', ...
          param.cmd.frms(find(bad_mask,1)));
        param.cmd.frms = valid_frms;
      end
      
      if ~isfield(param,'add_surf_from_dem')
        param.add_surf_from_dem = [];
      end
      
      if ~isfield(param.add_surf_from_dem,'method') || isempty(param.add_surf_from_dem.method)
        error('No valid method. User must specify either ''sar'' or ''surf''.');
      end
      
      if ~isfield(param.add_surf_from_dem,'dem_res') || isempty(param.add_surf_from_dem.dem_res)
        param.add_surf_from_dem.dem_res = 10; % Arctic DEM resolution
      end
      
      if ~isfield(param.add_surf_from_dem,'theta_bins') || isempty(param.add_surf_from_dem.theta_bins)
        param.add_surf_from_dem.theta_bins = [-88:88].';
      end
      
      if ~isfield(param.add_surf_from_dem,'dem_guard') || isempty(param.add_surf_from_dem.dem_guard)
        param.add_surf_from_dem.dem_guard = 12e3;
      end
      
      if ~isfield(param.add_surf_from_dem,'delta_at') || isempty(param.add_surf_from_dem.delta_at)
        param.add_surf_from_dem.delta_at = 10;
      end
      
      if ~isfield(param.add_surf_from_dem,'ice_mask_fn') || isempty(param.add_surf_from_dem.ice_mask_fn)
        error('User must specify an ice mask')
      end
      
      % .dem_per_slice_guard: additional region in meters around each slice to search for DEM points
      %   Setting too high slows the process down, setting too low will miss
      %   DEM points needed to properly represent the surface.
      if ~isfield(param.add_surf_from_dem,'dem_per_slice_guard') || isempty(param.add_surf_from_dem.dem_per_slice_guard)
        param.add_surf_from_dem.dem_per_slice_guard = 240;
      end
      
      if ~isfield(param.add_surf_from_dem,'surfdata_mode') || isempty(param.add_surf_from_dem.surfdata_mode)
        param.add_surf_from_dem.surfdata_mode.overwrite = true;
      end
      
      if regexp(param.add_surf_from_dem.method,'surf')
        % Output path is equal to the input path
        param.add_surf_from_dem.surf_out_path = param.add_surf_from_dem.in_path;
        param.add_surf_from_dem.delta_at = 1;
        param.add_surf_from_dem.surfdata_mode.overwrite = true;
        
        if ~isfield(param.add_surf_from_dem,'ice_mask_surf_name') || isempty(param.add_surf_from_dem.ice_mask_surf_name)
          param.add_surf_from_dem.ice_mask_surf_name = 'ice mask';
        end
        
        if ~isfield(param.add_surf_from_dem,'ref_surf_name') || isempty(param.add_surf_from_dem.ref_surf_name)
          param.add_surf_from_dem.ref_surf_name = 'top';
        end
        
      elseif regexp(param.add_surf_from_dem.method,'sar')
        if ~isfield(param.add_surf_from_dem,'surf_out_path') || isempty(param.add_surf_from_dem.surf_out_path)
          param.add_surf_from_dem.surf_out_path = 'surf_sar';
        end
      end
      
      
      
      %% add_surf_from_dem: Setup
      % =====================================================================
      
      if regexp(param.add_surf_from_dem.method,'sar')
        % Load in sar coordinates file
        sar_coord_fn = fullfile(ct_filename_out(param,param.add_surf_from_dem.in_path,''),'sar_coord.mat')
        sar_coord = load(sar_coord_fn);
        
        % Load records file
        records = records_load(param);
        
        % Load frames
        frames = frames_load(param);
      end
      
      % Input and output directories
      out_dir = ct_filename_out(param,param.add_surf_from_dem.surf_out_path);
      in_dir = ct_filename_out(param,param.add_surf_from_dem.in_path);
      
      % Physical constants
      physical_constants;
      
      % Loop over frames
      for frm_idx = 1:length(param.cmd.frms)
        
        frm = param.cmd.frms(frm_idx);
        
%         fprintf('Creating surface data object for %s_%03d \n', param.day_seg,frm);
        
        if strcmp(param.add_surf_from_dem.method,'sar')
          
          fprintf('Creating surf sar data object for %s_%03d \n', param.day_seg,frm);
          
          % recs: Determine the records for this frame
          if frm < length(frames.frame_idxs)
            recs = [frames.frame_idxs(frm), frames.frame_idxs(frm+1)-1];
          else
            recs = [frames.frame_idxs(frm), length(records.gps_time)];
          end
          
          % Find gps at frame boundaries and use this to mask out FCS of a
          % frame
          frm_gps_start = records.gps_time(recs(1));
          frm_gps_stop  = records.gps_time(recs(end));
          
          % Mask used to isolate FCS for a single frame
          gps_mask = sar_coord.gps_time >= frm_gps_start & ...
            sar_coord.gps_time <= frm_gps_stop;
          
          % GPS time, origin, Xpos, Ypos, Zpos for the frame
          frm_gps_time  = sar_coord.gps_time(gps_mask);
          frm_origin    = sar_coord.origin(:,gps_mask);
          frm_x         = sar_coord.x(:,gps_mask);
          frm_z         = sar_coord.z(:,gps_mask);
          frm_y         = cross(frm_z,frm_x);
          
          % Create the surfdata structure with necessary fields
          delta_at      = param.add_surf_from_dem.delta_at;
          
          % Create surface data structure with necessary fields
          sd = [];
          sd.fcs.x = frm_x(:,1:delta_at:end);
          sd.fcs.z = frm_z(:,1:delta_at:end);
          sd.fcs.y = frm_y(:,1:delta_at:end);
          sd.fcs.origin = frm_origin(:,1:delta_at:end);
          sd.gps_time = frm_gps_time(1:delta_at:end);
          sd.gps_source = sar_coord.gps_source;
          sd.param.day_seg = param.day_seg;
          sd.param.load.frm = frm;
          sd.param.radar.lever_arm_fh = param.radar.lever_arm_fh;
          sd.param.radar_name = param.radar_name;
          sd.param.records.gps.time_offset = param.records.gps.time_offset;
          sd.param.season_name = param.season_name;
          sd.param.sw_version = current_software_version;
          sd.file_type = 'surf';
          sd.surf(1) = tomo.surfdata.empty_surf();
          sd.surf(2) = tomo.surfdata.empty_surf();
          sd = tomo.surfdata(sd,param.add_surf_from_dem.surf_out_path);
          
        elseif strcmp(param.add_surf_from_dem.method,'surf')
          gps_time = [];
          fcs = [];
          surf_fn_name = sprintf('Data_%s_%03.0f.mat',param.day_seg,frm);
          surf_fn = fullfile(in_dir,surf_fn_name);
          
          fprintf('Updating file with ice mask: %s \n', surf_fn);
          
          load(surf_fn,'fcs','gps_time')
          sar_coord = fcs;
          sd = [];
          sd = tomo.surfdata(surf_fn);
          
          ice_mask_idx = [];
          if ~isempty(find(strcmp(param.add_surf_from_dem.ice_mask_surf_name,{sd.surf.name})))
            ice_mask_idx = sd.get_index(param.add_surf_from_dem.ice_mask_surf_name);
          else
            ice_mask_idx = [];
          end
          
          if ~isempty(find(strcmp(param.add_surf_from_dem.ref_surf_name,{sd.surf.name})))
            ref_surf_idx = sd.get_index(param.add_surf_from_dem.ref_surf_name);
            param.add_surf_from_dem.theta_bins = sd.surf(ref_surf_idx).x(:,1);
          else
            ref_surf_idx = [];
            param.add_surf_from_dem.theta_bins = sd.surf(ice_mask_idx).x(:,1);
          end
          
          if isempty(ice_mask_idx)
            error('Surfdata does not contain an ice mask surface layer')
          end
          
%           param.add_surf_from_dem.theta_bins = sd.surf(ref_surf_idx).x(:,1);
        end
        clear frm_gps_time frm_origin frm_x frm_y frm_z
        
        %% add_surf_from_dem: Geotiff and Ice Mask
        % =================================================================
        global gdem;
        if isempty(gdem) || ~isa(gdem,'dem_class') || ~isvalid(gdem)
          gdem = dem_class(param,param.add_surf_from_dem.dem_res);
        end
        gdem.set_res(param.add_surf_from_dem.dem_res);
        
        % Load ice mask
        if isfield(param.add_surf_from_dem,'ice_mask_fn') && ~isempty(param.add_surf_from_dem.ice_mask_fn)
          ice_mask_fn = ct_filename_gis(param,param.add_surf_from_dem.ice_mask_fn);
          [~,ice_mask_fn_name,ice_mask_fn_ext] = fileparts(ice_mask_fn);
          if strcmpi(ice_mask_fn_ext,'.tif')
            ice_mask_all.proj = geotiffinfo(ice_mask_fn);
            [ice_mask_all.mask, R, ~] = geotiffread(ice_mask_fn);
            ice_mask_all.X = R(3,1) + R(2,1)*(1:size(ice_mask_all.mask,2));
            ice_mask_all.Y = R(3,2) + R(1,2)*(1:size(ice_mask_all.mask,1));
          else
            ice_mask_all = load(ice_mask_fn);
          end
        else
          ice_mask_all = [];
        end
        
        if strcmp(param.add_surf_from_dem.method,'surf') && ~isempty(ref_surf_idx)
          y_active = sin(sd.surf(ref_surf_idx).x) .* sd.surf(ref_surf_idx).y * c/2;
          z_active = -cos(sd.surf(ref_surf_idx).x) .* sd.surf(ref_surf_idx).y * c/2;
          
          % Convert from radar FCS to ECEF
          x_plane = zeros(size(y_active));
          y_plane = zeros(size(y_active));
          z_plane = zeros(size(y_active));
          for rline = 1:size(y_active,2)
            x_plane(:,rline) = sd.fcs.origin(1,rline) ...
              + sd.fcs.y(1,rline) * y_active(:,rline) ...
              + sd.fcs.z(1,rline) * z_active(:,rline);
            y_plane(:,rline) = sd.fcs.origin(2,rline) ...
              + sd.fcs.y(2,rline) * y_active(:,rline) ...
              + sd.fcs.z(2,rline) * z_active(:,rline);
            z_plane(:,rline) = sd.fcs.origin(3,rline) ...
              + sd.fcs.y(3,rline) * y_active(:,rline) ...
              + sd.fcs.z(3,rline) * z_active(:,rline);
          end
          
          % Convert from ECEF to geodetic
          [points.lat,points.lon,points.elev] = ecef2geodetic(x_plane,y_plane,z_plane,WGS84.ellipsoid);
          points.lat = points.lat * 180/pi;
          points.lon = points.lon * 180/pi;
          
          % Convert from geodetic to projection
          [points.x,points.y] = projfwd(ice_mask_all.proj,points.lat,points.lon);
          intersection_x = interp_finite(points.x);
          intersection_y = interp_finite(points.y);
          
          x_mesh = repmat(ice_mask_all.X,[size(ice_mask_all.mask,1) 1]);
          y_mesh= repmat(ice_mask_all.Y(:),[1 size(ice_mask_all.mask,2)]);
%           
%           ice_mask_aligned = zeros(size(points.x));
%           ice_mask_aligned(nan_mask) = nan;
%           ice_mask_q = interp2(x_mesh,y_mesh,ice_mask_all.mask,intersection_x_good, intersection_y_good,'nearest');
%           ice_mask_aligned(~nan_mask) = ice_mask_q;
%           ice_mask = ice_mask_aligned;
%           twtt = sd.surf(ref_surf_idx).y;
          ice_mask_eval = double(ice_mask_all.mask);
          
          ice_mask_q = interp2(x_mesh,y_mesh, ice_mask_eval, intersection_x, intersection_y,'nearest');          
          nan_mask = isnan(ice_mask_q);
          ice_mask_q(nan_mask) = 1;
          ice_mask = logical(round(ice_mask_q));
          
          twtt = sd.surf(ref_surf_idx).y;
        else
          
          %% add_surf_from_dem: DEM
          % Convert decimated origin coordinates from ECEF to geodetic and
          % use these to define boundaries of the dem
          Nx = size(sd.fcs.x,2);
          dec_idxs = round(linspace(1,Nx,min(Nx,200)));
          [frm_lat_dec, frm_lon_dec, frm_elev_dec] = ecef2geodetic(sd.fcs.origin(1,dec_idxs),sd.fcs.origin(2,dec_idxs), sd.fcs.origin(3,dec_idxs),WGS84.ellipsoid);
          frm_lat_dec = frm_lat_dec*180/pi;
          frm_lon_dec = frm_lon_dec*180/pi;
          
          [latb,lonb] = bufferm(frm_lat_dec,frm_lon_dec,param.add_surf_from_dem.dem_guard/WGS84.semimajor*180/pi);
          gdem_str = sprintf('%s:%s:%s_%03d',param.radar_name,param.season_name,param.day_seg,frm);
          
          if ~strcmpi(gdem_str,gdem.name)
            gdem.set_vector(latb,lonb,gdem_str);
          end
          
          % Generated a non-decimated version of the lat,lon for the frame -
          % used below. Geocode platform positions after SAR and project
          % points to align with arctic dem
          [frm_lat, frm_lon, frm_elev] = ecef2geodetic(sd.fcs.origin(1,:),sd.fcs.origin(2,:), sd.fcs.origin(3,:),WGS84.ellipsoid);
          frm_lat = frm_lat * 180/pi;
          frm_lon = frm_lon * 180/pi;
          
          gdem.set_vector(latb,lonb,gdem_str);
          [DEM,msl,ocean_mask,proj,DEM_x,DEM_y] = gdem.get_vector_mosaic(100);
          DEM(ocean_mask) = msl(ocean_mask);
          [frm_x,frm_y] = projfwd(proj,frm_lat,frm_lon);
          
          %% add_surf_from_dem: Interpolate
          % Fill bad values using the good data
          bad_idxs = find(isnan(DEM));
          good_idxs = find(~isnan(DEM));
          x_idxs = repmat(1:size(DEM,2),[size(DEM,1) 1]);
          y_idxs = repmat((1:size(DEM,1))',[1 size(DEM,2)]);
          x_vals = x_idxs(good_idxs);
          y_vals = y_idxs(good_idxs);
          z_vals = DEM(good_idxs);
          x_out = x_idxs(bad_idxs);
          y_out = y_idxs(bad_idxs);
          z_out = single(griddata(x_vals,y_vals,double(z_vals),x_out,y_out));
          if ~isempty(z_out)
            DEM(bad_idxs) = z_out;
          end
          
          if 0
            figure(10);clf;
            % Convert DEM ecef points to geodetic
            imagesc(DEM_x.*1e-3,DEM_y.*1e-3,DEM.*1e-3);
            hold on;
            plot(frm_x.*1e-3,frm_y.*1e-3,'rx','LineWidth',2);
            set(gca,'TickLabelInterpreter','latex')
            set(gca,'FontSize',14)
            xlabel('X (km)','Interpreter','latex','FontSize',14)
            ylabel('Y (km)','Interpreter','latex','FontSize',14)
            title('ArcticDEM 20140325 07 002','FontSize',18,'Interpreter','latex')
            xlim([-880 -810]);
            ylim([-830 -750]);
            %           out_fn1 = 'arctic_dem_20140325_07_002.fig';
            %           savefig(10,out_fn1);
            
            figure(2);clf;
            % Convert DEM ecef points to geodetic
            imagesc(ice_mask_all.X.*1e-3,ice_mask_all.Y.*1e-3,ice_mask_all.mask);
            hold on;
            plot(frm_x.*1e-3,frm_y.*1e-3,'rx','LineWidth',2);
            set(gca,'TickLabelInterpreter','latex')
            set(gca,'FontSize',14)
            xlabel('X (km)','Interpreter','latex','FontSize',14)
            ylabel('Y (km)','Interpreter','latex','FontSize',14)
            title('Ice Mask 20140325 07 002','FontSize',18,'Interpreter','latex')
            xlim([-880 -810]);
            ylim([-830 -750]);
            %            out_fn2 = 'ice_mask_20140325_07_002.fig';
            %           savefig(2,out_fn2);
          end
          
          % Make x,y mesh from arctic dem bounds
          DEM_x_mesh = repmat(DEM_x,[size(DEM,1) 1]);
          DEM_y_mesh= repmat(DEM_y,[1 size(DEM,2)]);
          
          
          %% add_surf_from_dem: twtt
          % For every position along the aperture, add theta dependent TWTT to DEM from origin of the FCS
          Nx    = size(sd.fcs.x,2);
          Nsv   = length(param.add_surf_from_dem.theta_bins);
          twtt  = zeros(Nsv,Nx);
          ice_mask_tmp = NaN(Nsv,Nx);
          
          % Handle case where the DEM is all NaNs
          if all(all(isnan(DEM)))
            warning('Input DEM contains all NaN data for Frame %d.',param.proc.frm);
            twtt(:,:) = NaN;
            Nx = 0;
          end
          
          DEM_coverage_warning = false;
          
          for rline = 1:Nx
            %         for rline = 1:1
            if ~mod(rline-1,10^floor(log10(Nx)-1))
              fprintf('  %s %d of %d (%s)\n', mfilename, rline, Nx, datestr(now));
            end
            
            dem_guard = param.add_surf_from_dem.dem_guard;
            
            DEM_mask = DEM_x_mesh > frm_x(rline)-dem_guard & DEM_x_mesh < frm_x(rline)+dem_guard ...
              & DEM_y_mesh > frm_y(rline)-dem_guard & DEM_y_mesh < frm_y(rline)+dem_guard ...
              & ~isnan(DEM);
            DEM_idxs = find(DEM_mask);
            
            if numel(DEM_idxs)==0
              warning('Range Line %d of Frame %d is not spanned by DEM.',rline,frm);
            end
            
            if 0
              set(h_img,'AlphaData',DEM_mask);
            end
            
            % Convert arctic dem mesh from projection to geodetic (lat,lon,elev)
            [DEM_lat,DEM_lon] = projinv(proj,DEM_x_mesh(DEM_idxs),DEM_y_mesh(DEM_idxs));
            DEM_elev = DEM(DEM_idxs);
            
            % Convert from geodetic (lat,lon,elev) to ECEF (x,y,z)
            physical_constants;
            [DEM_ecef_x,DEM_ecef_y,DEM_ecef_z] = geodetic2ecef(single(DEM_lat)/180*pi,single(DEM_lon)/180*pi,single(DEM_elev),WGS84.ellipsoid);
            
            origin = sd.fcs.origin(:,rline);
            
            % Define matrices to change coordinate systems from FCS to ECEF
            % and vice versa
            Tfcs_ecef = [sd.fcs.x(:,rline), sd.fcs.y(:,rline), sd.fcs.z(:,rline)];
            Tecef_fcs = inv(Tfcs_ecef);
            
            % Convert DEM coordinates from ECEF to FCS
            tmp = Tecef_fcs * [DEM_ecef_x.'-origin(1); DEM_ecef_y.'-origin(2); DEM_ecef_z.'-origin(3)];
            DEM_fcs_x = tmp(1,:);
            DEM_fcs_y = tmp(2,:);
            DEM_fcs_z = tmp(3,:);
            
            if 0
              imagesc(reshape(DEM_fcs_x,[200 200]))
              colorbar;
              
              imagesc(reshape(DEM_fcs_y,[200 200]))
              colorbar;
              
              imagesc(reshape(DEM_fcs_z,[200 200]))
              colorbar;
            end
            
            slice_mask = DEM_fcs_x > -param.add_surf_from_dem.dem_per_slice_guard & DEM_fcs_x < param.add_surf_from_dem.dem_per_slice_guard;
            
            x = DEM_fcs_x(slice_mask);
            y = DEM_fcs_y(slice_mask);
            z = DEM_fcs_z(slice_mask);
            
            if (numel(x)>=3)
              faces = delaunay(double(x),double(y));
              vertices = [double(x).' double(y).' double(z).'];  % vertices stored as Nx3 matrix
              vert1 = vertices(faces(:,1),:);
              vert2 = vertices(faces(:,2),:);
              vert3 = vertices(faces(:,3),:);
              
              orig = [0 0 0];
              
              theta_rline = param.add_surf_from_dem.theta_bins*(pi/180);
              
              intersection = zeros(3,Nsv);
              
              for theta_idx = 1:length(theta_rline)
                dir = [0 sin(theta_rline(theta_idx)) -cos(theta_rline(theta_idx))];
                
                [Intersect, t] = TriangleRayIntersection(orig, dir, vert1, vert2, vert3);
                
                intersect_idx = find(Intersect);
                if isempty(intersect_idx)
                  twtt(theta_idx,rline) = NaN;
                  intersection(:,theta_idx) = NaN;
                else
                  range_intersections = t(intersect_idx);
                  [min_range_val,min_range_idx] = min(range_intersections);
                  prop_delay = min_range_val./(c/2);
                  good_intersect_idx = intersect_idx(min_range_idx);
                  
                  twtt(theta_idx,rline) = prop_delay;
                  intersection(:,theta_idx) = mean([vert1(good_intersect_idx,:);vert2(good_intersect_idx,:);vert3(good_intersect_idx,:)],1);
                end
                
              end
            else
              if ~DEM_coverage_warning
                DEM_coverage_warning = true;
                warning('DEM dem_per_slice_guard too small.');
              end
              clear intersection;
              twtt(:,rline) = NaN;
            end
            
            
            if exist('ice_mask_all','var') && ~isempty(ice_mask_all)
              if exist('intersection','var')
                % Convert from FCS/SAR to ECEF
                intersection_ecef = Tfcs_ecef * intersection;
                intersection_ecef_x = intersection_ecef(1,:).' + origin(1);
                intersection_ecef_y = intersection_ecef(2,:).' + origin(2);
                intersection_ecef_z = intersection_ecef(3,:).' + origin(3);
                % Convert from ECEF to geodetic
                [intersection_lat,intersection_lon,tri_h] = ecef2geodetic(intersection_ecef_x,intersection_ecef_y,intersection_ecef_z,WGS84.ellipsoid);
                intersection_lat = intersection_lat*180/pi;
                intersection_lon = intersection_lon*180/pi;
                % Convert from geodetic to projection (align DEM to the ice
                % mask)
                [intersection_x,intersection_y] = projfwd(ice_mask_all.proj,intersection_lat,intersection_lon);
                % Get mask coordinates nearest triangle center coordinates
                intersection_x_idx = interp1(ice_mask_all.X,1:length(ice_mask_all.X),intersection_x,'nearest');
                intersection_y_idx = interp1(ice_mask_all.Y,1:length(ice_mask_all.Y),intersection_y,'nearest');
                % Find nan values and set to integer value
                nidx = find(isnan(intersection_x_idx));
                intersection_x_idx(nidx) = 1;
                intersection_y_idx(nidx) = 1;
                % Convert triangle mask coordinates to matrix indices
                mask_idx = (intersection_x_idx-1)*length(ice_mask_all.Y) + intersection_y_idx;
                % Find ice mask for triangle coordinates
                ice_mask_tmp(:,rline) = ice_mask_all.mask(mask_idx);
                % Set previously nan valued coordinates to 0 mask
                %               ice_mask(nidx,rline) = 0;
              else
                %         for ice_mask_idx = 1:length(mask_idx)
                %           ice_mask(theta_rline_row_idx(ice_mask_idx),theta_rline_col_idx(ice_mask_idx),rline) = ice_mask_all.mask(mask_idx(ice_mask_idx));
                %         end
                %         % Set previously nan valued coordinates to 0 mask
                %         ice_mask_tmp(theta_rline_row_idx(nidx),theta_rline_col_idx(nidx),rline) = 0;
                %       end
                
              end
            end
            
          end
          
        end
        
        if regexp(param.add_surf_from_dem.method,'sar')
          ice_mask = ice_mask_tmp;
        end

        %% add_surf_from_dem: Insert Surfaces
        
        if regexp(param.add_surf_from_dem.method,'surf')
          if param.add_surf_from_dem.surfdata_mode.overwrite
            % Get existing ice mask surface layer
            surf_a = sd.get_surf(param.add_surf_from_dem.ice_mask_surf_name);
            surf_a.x = repmat(param.add_surf_from_dem.theta_bins, [1 size(twtt,2)]);
            surf_a.y = ice_mask;
            
            % If the current surface contains the ice mask surface layer,
            % remove it
            if any(strcmp(sd.get_names,param.add_surf_from_dem.ice_mask_surf_name))
              sd.remove_surf(param.add_surf_from_dem.ice_mask_surf_name);
            end
            
            % Insert ice mask surface
            sd.insert_surf(surf_a);
            
            if isempty(ref_surf_idx)
              surf_b = sd.empty_surf;
              surf_b.x = repmat(param.add_surf_from_dem.theta_bins, [1 size(twtt,2)]);
              surf_b.y = twtt;
              surf_b.name = 'top twtt';
              sd.insert_surf(surf_b);
            end
          end
          
        elseif regexp(param.add_surf_from_dem.method,'sar')
          % Insert TWTT of top surface
          sd.surf(1).name = 'top twtt';
          sd.surf(1).x = zeros(Nsv,length(sd.gps_time));
          sd.surf(1).y = zeros(Nsv,length(sd.gps_time));
          sd.surf(1).x = repmat(param.add_surf_from_dem.theta_bins,[1 size(twtt,2)]); % Nsv x Nx
          sd.surf(1).y = twtt;
          
          sd.surf(2).name = 'ice mask';
          sd.surf(2).x = zeros(Nsv,length(sd.gps_time));
          sd.surf(2).y = zeros(Nsv,length(sd.gps_time));
          sd.surf(2).x= repmat(param.add_surf_from_dem.theta_bins,[1 size(twtt,2)]); % Nsv x Nx
          sd.surf(2).y = ice_mask;
          sd.surf(2).plot_name_values = {'color','white','marker','x'};
          
        end
        
        %% add_surf_from_dem: Save output
        out_fn_dir = ct_filename_out(param,param.add_surf_from_dem.surf_out_path);
        if ~isdir(out_fn_dir)
          mkdir(out_fn_dir);
        end
        out_fn_name = sprintf('Data_%s_%03.0f.mat',param.day_seg,frm);
        out_fn = fullfile(out_fn_dir,out_fn_name);
        sd.save_surfdata(out_fn);
        fprintf('Done (%s)\n\n', datestr(now));
        
      end
    end
    
    function [] = run_add_surf_from_dem()
      %% run_add_surf_from_dem
      % tomo.surfdata.run_add_surf_from_dem
      %
      % script for running tomo.surfdata.add_surf_from_dem
      %
      % Author:  Theresa Moore
      %
      % See also: tomo.surfdata
      
      
      % User Setup
      % =========================================================================
      param_override = [];
      params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'));
      params = ct_set_params(params,'cmd.generic',0);
      
      %       params = ct_set_params(params,'cmd.generic',1,'day_seg','20140325_07');
      %       params = ct_set_params(params,'cmd.frms',[1:5]);
      
      %       params = ct_set_params(params,'cmd.generic',1,'day_seg','20140325_01');
      %       params = ct_set_params(params,'cmd.frms',[1:3]);
      
      %       params = ct_set_params(params,'cmd.generic',1,'day_seg','20140325_04');
      %       params = ct_set_params(params,'cmd.frms',[1:26]);
      
      %       params = ct_set_params(params,'cmd.generic',1,'day_seg','20140325_02');
      %       params = ct_set_params(params,'cmd.frms',[1:7]);
      
      %       params = ct_set_params(params,'cmd.generic',1,'day_seg','20140401_03');
      %       params = ct_set_params(params,'cmd.frms',[1:48]);
      
      %       params = ct_set_params(params,'cmd.generic',1,'day_seg','20140506_01');
      %       params = ct_set_params(params,'cmd.frms',[1:46]);
      
      %       params = ct_set_params(params,'cmd.generic',1,'day_seg','20140325_07');
      %       params = ct_set_params(params,'cmd.frms',[2]);
      
      %             params = ct_set_params(params,'cmd.generic',1,'day_seg','20140401_03');
      %             params = ct_set_params(params,'cmd.frms',[4,5,34,35]);
      %       params = ct_set_params(params,'cmd.generic',1,'day_seg','20140401_03');
      %       params = ct_set_params(params,'cmd.frms',[19, 41, 42, 45]);
      params = ct_set_params(params,'cmd.generic',1,'day_seg','20140401_03');
%       params = ct_set_params(params,'cmd.frms',[4, 5, 13, 15, 16, 19, 20, 34, 35, 41, 42, 45]);
%       params = ct_set_params(params,'cmd.frms',[13]);
%       params = ct_set_params(params,'cmd.frms',[34 35 38]);
%             params = ct_set_params(params,'cmd.generic',1,'day_seg','20140401_03');
%             params = ct_set_params(params,'cmd.frms',[41 42 45]);
      %       params = ct_set_params(params,'cmd.generic',1,'day_seg','20140401_03');
      %       params = ct_set_params(params,'cmd.frms',[45]);
            params = ct_set_params(params,'cmd.generic',1,'day_seg','20140401_03');
            params = ct_set_params(params,'cmd.frms',[20, 34, 35, 38]);
      %       params = ct_set_params(params,'cmd.generic',1,'day_seg','20140401_03');
      %       params = ct_set_params(params,'cmd.frms',[ 13, 15:16, 38, 41, 42, 45]);
      
      %             params = ct_set_params(params,'cmd.generic',1,'day_seg','20140506_01');
      %             params = ct_set_params(params,'cmd.frms',[41,42,44]);
      
      %       params = ct_set_params(params,'add_surf_from_dem.ice_mask_fn',fullfile('greenland','IceMask','GimpIceMask_90m_v1.1.tif'));%'antarctica\DEM\BEDMAP2\original_data\bedmap2_tiff\bedmap2_icemask_grounded_and_shelves.tif';
      params = ct_set_params(params,'add_surf_from_dem.ice_mask_fn','canada/ice_mask/03_rgi50_ArcticCanadaNorth/03_rgi50_ArcticCanadaNorth.mat');%'antarctica\DEM\BEDMAP2\original_data\bedmap2_tiff\bedmap2_icemask_grounded_and_shelves.tif';
      %       params = ct_set_params(params,'add_surf_from_dem.ice_mask_fn',ct_filename_gis(params,fullfile('greenland','IceMask','GimpIceMask_90m_v1.1.tif')));%'antarctica\DEM\BEDMAP2\original_data\bedmap2_tiff\bedmap2_icemask_grounded_and_shelves.tif';
      %       param.add_surf_from_dem.ice_mask_fn = ct_filename_gis(param,fullfile('greenland','IceMask','GimpIceMask_90m_v1.1.tif'));%'antarctica\DEM\BEDMAP2\original_data\bedmap2_tiff\bedmap2_icemask_grounded_and_shelves.tif';
      %         param.add_surf_from_dem.ice_mask_fn = ct_filename_gis([],'canada/ice_mask/03_rgi50_ArcticCanadaNorth/03_rgi50_ArcticCanadaNorth.mat');
      
      params = ct_set_params(params, 'add_surf_from_dem.dem_guard', 30e3);
      params = ct_set_params(params, 'add_surf_from_dem.delta_at',10);
      
      params = ct_set_params(params, 'add_surf_from_dem.method','surf');
      %       param_override.add_surf_from_dem.in_path = 'surf_tgrs2021_evd_20140401_03_lut';
      %             param_override.add_surf_from_dem.in_path = 'surf_tgrs2021_evd_20140325_07_lut';
      %             param_override.add_surf_from_dem.in_path = 'surf_tgrs2021_evd_20140506_01_lut';
      %
      %             param_override.add_surf_from_dem.in_path = 'surf_tgrs2021_evd_20140401_03_lut_test';
      %                   param_override.add_surf_from_dem.in_path = 'surf_tgrs2021_evd_20140325_07_lut_test';
      %       param_override.add_surf_from_dem.in_path = 'surf_tgrs2021_evd_20140506_01_lut_test';
      
%       param_override.add_surf_from_dem.in_path = 'surf_tgrs2021_evd_20140401_03_lut';
%       param_override.add_surf_from_dem.in_path = 'surf_tgrs2021_evd_20140325_07_lut';
%       param_override.add_surf_from_dem.in_path = 'surf_tgrs2021_evd_20140506_01_lut';
%       param_override.add_surf_from_dem.in_path = 'surf_nominal';

%       param_override.add_surf_from_dem.in_path = 'surf_em_model_20140325_07_lut';
%       param_override.add_surf_from_dem.in_path = 'surf_em_model_20140506_01_lut';
      param_override.add_surf_from_dem.in_path = 'surf_pseudoinverse_evd_20140506_01_lut_test';
            % Use these options for create surfdata used to generate
            % snapshots in array proc
%             params = ct_set_params(params, 'add_surf_from_dem.method','sar');
%             param_override.add_surf_from_dem.in_path = 'sar_air';
      
      
      %       param_override.add_surf_from_dem.in_path = 'sar_air';
      
      
      %       param_override.update.output = 'surf_sar';
      %       param_override.update.echogram = 'standard_air';
      
      % Automated Section
      % =========================================================================
      % Input checking
      global gRadar;
      if exist('param_override','var')
        param_override = merge_structs(gRadar,param_override);
      else
        param_override = gRadar;
      end
      
      % Process each of the segments
      ctrl_chain = {};
      for param_idx = 1:length(params)
        param = params(param_idx);
        if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
          continue;
        end
        tomo.surfdata.add_surf_from_dem(param,param_override);
      end
    end
    
  end
  
end

