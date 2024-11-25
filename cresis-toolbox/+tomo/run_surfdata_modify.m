% script tomo.run_surfdata_modify.m
%
% Example script for running surfData_modify.m. Demonstrates a few of the
% most common operations to be performed with surfData_modify.
%
% Authors: John Paden

% =====================================================================
%% User Settings
% =====================================================================

% params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'));
params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'20140325_07','post');
params.cmd.generic = 1;
params.cmd.frms = [];

surfdata_source = 'paden_surfData';

SURFDATA_MODIFY_EXAMPLE = 'add_new_layer';
if strcmpi(SURFDATA_MODIFY_EXAMPLE,'update_fields')
  %% Example for updating fields of a particular layer
%   layers = [1 7];
%   args = [];
%   args{1} = 'quality';
%   args{2} = 8;
  
  layers = [2 3 4 5 6];
  args = [];
  args{1} = 'quality';
  args{2} = 9;
  
elseif strcmpi(SURFDATA_MODIFY_EXAMPLE,'add_new_layer')
  %% Example for adding a new layer from ops in
%   echo_source = 'music3D';
%   echo_source_img = 1;
%   layer_params = []; % Leave empty to not use opsLoadLayer at nadir
%   default_value = 1; % Default value to use when layer values not provided
%   new_layer = 8;
%   args = [];
%   args{end+1} = 'plot_name_values';
%   args{end+1} = {'color','red','marker','x'};
%   args{end+1} = 'name';
%   args{end+1} = 'surface quality';
%   args{end+1} = 'top';
%   args{end+1} = [];
%   args{end+1} = 'active';
%   args{end+1} = 1;
%   args{end+1} = 'mask';
%   args{end+1} = [];
%   args{end+1} = 'gt';
%   args{end+1} = 7;
%   args{end+1} = 'quality';
%   args{end+1} = 8;
%   args{end+1} = 'visible';
%   args{end+1} = true;

  echo_source = 'music3D';
  echo_source_img = 1;
  layer_params = []; % Leave empty to not use opsLoadLayer at nadir
  default_value = 1; % Default value to use when layer values not provided
  new_layer = 9;
  args = [];
  args{end+1} = 'plot_name_values';
  args{end+1} = {'color','red','marker','^'};
  args{end+1} = 'name';
  args{end+1} = 'bottom quality';
  args{end+1} = 'top';
  args{end+1} = 1;
  args{end+1} = 'active';
  args{end+1} = 2;
  args{end+1} = 'mask';
  args{end+1} = 3;
  args{end+1} = 'gt';
  args{end+1} = 4;
  args{end+1} = 'quality';
  args{end+1} = 9;
  args{end+1} = 'visible';
  args{end+1} = true;
 
%   echo_source = 'music3D';
%   echo_source_img = 1;
%   layer_params = struct('name','surface'); % Use opsLoadLayer at nadir
%   default_value = NaN; % Default value to use when layer values not provided
%   new_layer = 7;
%   args = [];
%   args{end+1} = 'plot_name_values';
%   args{end+1} = {'color','magenta','marker','^'};
%   args{end+1} = 'name';
%   args{end+1} = 'surface gt';
%   args{end+1} = 'top';
%   args{end+1} = [];
%   args{end+1} = 'active';
%   args{end+1} = 1;
%   args{end+1} = 'mask';
%   args{end+1} = [];
%   args{end+1} = 'gt';
%   args{end+1} = 7;
%   args{end+1} = 'quality';
%   args{end+1} = 8;
%   args{end+1} = 'visible';
%   args{end+1} = true; 
  
end

% =====================================================================
%% Automated Section
% =====================================================================

global gRadar;

if strcmpi(SURFDATA_MODIFY_EXAMPLE,'update_fields')
  %% Load each of the day segments
  for param_idx = 1:length(params)
    param = params(param_idx);
    if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) ...
        || ischar(param.cmd.generic) || ~param.cmd.generic
      continue;
    end
    
    param = merge_structs(param,gRadar);
    
    fprintf('surfData_modify %s\n', param.day_seg);
    tomo.surfData_modify(param,surfdata_source,layers,args{:});
  end
  
elseif strcmpi(SURFDATA_MODIFY_EXAMPLE,'add_new_layer')
  %% Load each of the day segments
  for param_idx = 1:length(params)
    param = params(param_idx);
    if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) ...
        || ischar(param.cmd.generic) || ~param.cmd.generic
      continue;
    end
    
    param = merge_structs(param,gRadar);
    
    % Determine which frames to process
    frames = frames_load(param);
    param.cmd.frms = frames_param_cmd_frms(param,frames);
    
    %% Only do one frame at a time
    all_frms = param.cmd.frms;
    for frm = all_frms(:).'
      param.cmd.frms = frm;
      echo_fn_dir = ct_filename_out(param,echo_source);
      if echo_source_img == 0
        echo_fn = fullfile(echo_fn_dir,sprintf('Data_%s_%03d.mat', param.day_seg, frm));
      else
        echo_fn = fullfile(echo_fn_dir,sprintf('Data_img_%02d_%s_%03d.mat', echo_source_img, param.day_seg, frm));
      end
      if ~exist(echo_fn,'file')
        warning('File does not exist: %s', echo_fn);
        continue;
      end
      
      mdata = load(echo_fn,'Surface','Time','GPS_time','Latitude','Longitude','Elevation','Tomo');

      args{end+1} = 'x';
      args{end+1} = repmat(mdata.Tomo.theta(:,1),[1 size(mdata.Tomo.img,3)]);
      
      args{end+1} = 'y';
      top = default_value*ones(size(mdata.Tomo.img,2), size(mdata.Tomo.img,3));

      if ~isempty(layer_params)
        % Query OPS for surface and bottom information
        param_load_layers = param;
        param_load_layers.cmd.frms = round([-1,0,1] + frm);
        
        layers = opsLoadLayers(param_load_layers,layer_params);
        
        % Interpolate surface and bottom information to mdata
        master = [];
        master.GPS_time = mdata.GPS_time;
        master.Latitude = mdata.Latitude;
        master.Longitude = mdata.Longitude;
        master.Elevation = mdata.Elevation;
        for lay_idx = 1:length(layer_params)
          ops_layer = [];
          ops_layer{1}.gps_time = layers(lay_idx).gps_time;
          
          ops_layer{1}.type = layers(lay_idx).type;
          ops_layer{1}.quality = layers(lay_idx).quality;
          ops_layer{1}.twtt = layers(lay_idx).twtt;
          ops_layer{1}.type(isnan(ops_layer{1}.type)) = 2;
          ops_layer{1}.quality(isnan(ops_layer{1}.quality)) = 1;
          lay = opsInterpLayersToMasterGPSTime(master,ops_layer,[300 60]);
          layers(lay_idx).twtt_ref = lay.layerData{1}.value{2}.data;
        end
        
        % Add surface information to surfData file
        [~,nadir_idx] = min(abs(mdata.Tomo.theta(:,1)));
        top(nadir_idx,:) = layers(1).twtt_ref;
      end
      args{end+1} = top;
      
      fprintf('surfData_modify %s_%03d\n', param.day_seg, frm);
      tomo.surfData_modify(param,surfdata_source,new_layer,args{:});
    end
  end
  
end
