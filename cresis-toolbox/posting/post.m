function post(param, param_override)
% post(param, param_override)
%
% Generalized function for posting data. Should be called from
% run_post.
%
% Authors: Shashanka Jagarlapudi, John Paden, Logan Smith, Theresa Stumpf, Reece Mathews
%
% See also make_layer_files, run_make_layer_files, run_picker, picker

%% General Setup
% =====================================================================
if exist('param_override','var')
  param = merge_structs(param, param_override);
end

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input arguments check and setup
% =========================================================================

% er_ice, c = speed of light
physical_constants;
[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);

% cmd worksheet inputs
% -------------------------------------------------------------------------

% Load the frames file
frames = frames_load(param);
param.cmd.frms = frames_param_cmd_frms(param,frames);

if isempty(param.cmd.frms)
  % No valid frames specified to post
  return;
end

% post worksheet inputs
% -------------------------------------------------------------------------

if ~isfield(param.post,'concat_en') || isempty(param.post.concat_en)
  param.post.concat_en = 0;
end

if ~isfield(param.post,'csv_en') || isempty(param.post.csv_en)
  param.post.csv_en = 0;
end
if param.post.concat_en && ~param.post.csv_en
  warning('post.csv_en must be true when post.concat_en is true since concatenation uses the CSV files. Setting post.csv_en to true.');
  param.post.csv_en = 1;
end

if ~isfield(param.post,'data_dirs') || isempty(param.post.data_dirs)
  % Cell array of data files to post. The first is the master and will be
  % used to create the jpg/pdf images.
  % Multichannel systems post processing: {'standard','mvdr','qlook'}
  % Single channel systems post processing: {'standard','qlook'}
  % Field processing: {'standard','qlook'}
  param.post.data_dirs = {'qlook'};
end
% Specify the location of the master data file
master_fn_dir = ct_filename_out(param, param.post.data_dirs{1});

if ~isfield(param.post,'data_en') || isempty(param.post.data_en)
  param.post.data_en = false;
end

if ~isfield(param.post,'echo') || isempty(param.post.echo)
  param.post.echo = [];
end

if ~isfield(param.post,'echo_en') || isempty(param.post.echo_en)
  param.post.echo_en = false;
end

% echo_with_no_layer_en: only activated if echo_en is true. When true, an
% echogram image file will be created with no layers plotted on it.
if ~isfield(param.post,'echo_with_no_layer_en') || isempty(param.post.echo_with_no_layer_en)
  param.post.echo_with_no_layer_en = true;
end

if ~isfield(param.post,'frm_types') || isempty(param.post.frm_types)
  param.post.frm_types = {-1,0,-1,-1,-1};
end

if ~isfield(param.post,'img_dpi') || isempty(param.post.img_dpi)
  param.post.img_dpi = 150;
end

if ~isfield(param.post,'img_type') || isempty(param.post.img_type)
  param.post.img_type = 'jpg';
end
if strcmp(param.post.img_type,'jpg')
  print_device = '-djpeg';
elseif strcmp(param.post.img_type,'png')
  print_device = '-dpng';
else
  error('Unsupported image type %s', param.post.img_type);
end
print_dpi = sprintf('-r%d', param.post.img_dpi);

if ~isfield(param.post,'img') || isempty(param.post.img)
  % Data_YYYYMMDD_SS_FFF is image 0
  % Data_img_II_YYYYMMDD_SS_FFF is image II (where II is 1 or more)
  param.post.img = 0;
end

if ~isfield(param.post, 'layers') || isempty(param.post.layers)
  param.post.layers = [struct('name', 'surface', 'source', 'layerData') ...
    struct('name', 'bottom', 'source', 'layerData')];
end

if ~isfield(param.post,'layers_en') || isempty(param.post.layers_en)
  param.post.layers_en = false;
end

if ~isfield(param.post,'maps_en') || isempty(param.post.maps_en)
  param.post.maps_en = false;
end

if ~isfield(param.post,'ops') || isempty(param.post.ops)
  param.post.ops = [];
end
if ~isfield(param.post.ops,'gaps_dist') || isempty(param.post.ops.gaps_dist)
  param.post.ops.gaps_dist = [300 60];
end

if ~isfield(param.post,'out_path') || isempty(param.post.out_path)
  param.post.out_path = 'post';
end
% post_path: the directory where outputs will be created
post_path = ct_filename_out(param,param.post.out_path,[],1);

if ~isfield(param.post,'pdf_en') || isempty(param.post.pdf_en)
  param.post.pdf_en = false;
end

if ~isfield(param.post.echo,'num_x_tics') || isempty(param.post.echo.num_x_tics)
  param.post.echo.num_x_tics = 6;
end

if ~isfield(param.post.echo,'plot_params') || isempty(param.post.echo.plot_params)
  param.post.echo.plot_params = {'PaperPosition',[0.25 2.5 8 6]};
end

if ~isfield(param.post.echo,'plot_quality') || isempty(param.post.echo.plot_quality)
  param.post.echo.plot_quality = true;
end

if ~isfield(param.post, 'surface_source')
  param.post.surface_source = struct('name', 'surface', 'source', 'layerData', 'existence_check', false);
end


%% Loading layer data
% =========================================================================
fprintf('Loading layer data (%s)\n', datestr(now));

tmp_param = param; tmp_param.cmd.frms = []; % Get layer information for all frames
layers = [];
if param.post.layers_en
  % Load layers to output
  [layers,param.post.layers] = opsLoadLayers(tmp_param, param.post.layers);
  % Setup output layerdata class
  out_layers = layerdata(param, fullfile(post_path,'CSARP_layer'));
end
surface_layer = {opsLoadLayers(tmp_param, param.post.surface_source)};

layers_to_post = {};
for layer = layers
  layers_to_post{end + 1} = layer;
end
clear layers;

%% Create map template
if param.post.maps_en
  fprintf(' Creating map template (%s)\n', datestr(now));
  
  map_param.type = param.post.map.type;
  map_param.location = param.post.map.location;
  if isfield(param.post.map,'geotiff')
    map_param.geotiff = param.post.map.geotiff;
  end
  if exist('map_info','var')
    map_param.fig_hand = map_info.fig_hand;
  else
    map_param.fig_hand = [];
  end
  map_param.resample = true;
  map_param.map_title = '';
  map_param.decimate_seg = true;
  map_param.year = str2double(param.day_seg(1:4));
  map_param.month = str2double(param.day_seg(5:6));
  map_param.day = str2double(param.day_seg(7:8));
  
  map_info = publish_map('setup',map_param);
  map_param.fig_hand = map_info.fig_hand;
  
  % =========================================================================
  % For each day segment, find the [x,y] extent by looking at all the frames
  % in this segment
  % =========================================================================
  seg_idx = 1; % Used to support multiple segments, but now does just one at a time
  min_x(seg_idx) = inf;
  max_x(seg_idx) = -inf;
  min_y(seg_idx) = inf;
  max_y(seg_idx) = -inf;
  day_seg_x{seg_idx} = [];
  day_seg_y{seg_idx} = [];
  [x,y] = projfwd(map_info.proj,surface_layer{1}.lat,surface_layer{1}.lon);
  x = x/1e3;
  y = y/1e3;
  min_x(seg_idx) = min(x);
  max_x(seg_idx) = max(x);
  min_y(seg_idx) = min(y);
  max_y(seg_idx) = max(y);
  day_seg_x{seg_idx} = [x day_seg_x{seg_idx}];
  day_seg_y{seg_idx} = [y day_seg_y{seg_idx}];
end

%% Post Loop
% =========================================================================
% For each frame, do the following:
%  1. produce the map
%  2. produce the echogram
%  3. produce the echogram w/ layer
%  4. copy the data files
%  5. make the csv files

for frm_idx = 1:length(param.cmd.frms)
  frm = param.cmd.frms(frm_idx);
  % Check to make sure this frame should be processed (frames file field
  % proc_mode and param.post.frm_types controls this)
  if ~ct_proc_frame(frames.proc_mode(frm),param.post.frm_types)
    continue;
  end
  frm_id = sprintf('%s_%03d', param.day_seg, frm);
  fprintf('  Posting frame %s, %d of %d (%s)\n', ...
    frm_id, frm_idx, length(param.cmd.frms), datestr(now));
  
  % master_fn_name: data filename string Data_YYYYMMDD_SS_FFF.mat or
  %             Data_img_II_YYYYMMDD_SS_FFF.mat
  if param.post.img == 0
    master_fn_name = sprintf('Data_%s.mat', frm_id);
  else
    master_fn_name = sprintf('Data_img_%02d_%s.mat', param.post.img, frm_id);
  end
  % master_fn = full path to the master data filename
  master_fn = fullfile(master_fn_dir,master_fn_name);
  
  if ~exist(master_fn,'file')
    warning('The master echogram file does not exist for this frame. Skipping this frame. Perhaps the param.data_dirs{1} is incorrect or param.post.img needs to be set properly. File does not exist:\n  %s.', master_fn);
    continue;
  end
  
  %% Post Loop: Interpolate each layer onto the master data file's gps time
  % =======================================================================
  
  lay = load(master_fn,'GPS_time','Latitude','Longitude','Elevation');
  
  lay = opsInterpLayersToMasterGPSTime(lay,layers_to_post,param.post.ops.gaps_dist);
  
  if ~param.post.layers_en
    lay.layerData = {};
  end
  
  surface_lay = opsInterpLayersToMasterGPSTime(lay,surface_layer,param.post.ops.gaps_dist);
  
  lay.Surface = surface_lay.layerData{1}.value{2}.data;
  if length(lay.layerData) >= 1
    lay.Bottom = lay.layerData{end}.value{2}.data;
  else
    lay.Bottom = NaN*zeros(size(lay.Surface));
  end
  
  if param.post.maps_en || param.post.echo_en
    image_dir = fullfile(post_path,'images',param.day_seg);
    if ~exist(image_dir,'dir')
      mkdir(image_dir)
    end
  end
  if param.post.pdf_en
    pdf_dir = fullfile(post_path,'pdf',param.day_seg);
    if ~exist(pdf_dir,'dir')
      mkdir(pdf_dir)
    end
  end
  
  % =======================================================================
  %% Post Loop: Create Map
  % =======================================================================
  if param.post.maps_en
    % Plot the map for each frame
    seg_idx = 1;
    map_param.day_seg_x = day_seg_x{seg_idx}*1000;
    map_param.day_seg_y = day_seg_y{seg_idx}*1000;
    [frame_X,frame_Y] = projfwd(map_info.proj,lay.Latitude,lay.Longitude);
    map_param.frame_X = {frame_X};
    map_param.frame_Y = {frame_Y};
    map_info = publish_map('delete',map_param,map_info);
    map_param.map_title = sprintf('%s\n%s', param.cmd.mission_names, frm_id);
    map_info = publish_map('plot',map_param,map_info);
    set(map_info.h_title,'fontSize',8,'fontweight','normal');
    
    % Remove current file and save new file
    map_fn = sprintf('%s_0maps.%s',frm_id,param.post.img_type);
    map_fn = fullfile(image_dir,map_fn);
    if exist(map_fn,'file')
      delete(map_fn);
    end
    set(map_info.fig_hand(1),'PaperUnits','inches');
    set(map_info.fig_hand(1),'PaperPosition',[0.5 0.5 10 7.5]);
    set(map_info.fig_hand(1),'PaperOrientation','Portrait');
    fprintf('    Saving output %s\n', map_fn);
    print(map_info.fig_hand(1),print_device,print_dpi,map_fn);
    
    if param.post.pdf_en
      % Remove current file and save new file
      map_fn = sprintf('%s_0maps.pdf',frm_id);
      map_fn = fullfile(pdf_dir,map_fn);
      if exist(map_fn,'file')
        delete(map_fn);
      end
      set(map_info.fig_hand(1),'PaperOrientation','Landscape');
      set(map_info.fig_hand(1),'PaperUnits','inches');
      set(map_info.fig_hand(1),'PaperPosition',[0.5 0.5 10 7.5]);
      saveas(map_info.fig_hand(1),map_fn);
    end
  end
  
  % =======================================================================
  %% Post Loop: Plot Echogram and Echogram w/ Layers
  % =======================================================================
  if param.post.echo_en
    % Load master file (mdata)
    fprintf('    Loading %s\n', master_fn);
    mdata = load(master_fn);
    mdata = uncompress_echogram(mdata); % Uncompress if necessary
    
    if size(mdata.Data,2) > 5000
      % Decimate data to less than 5000 along-track samples to prevent
      % failure in pdf generation
      old_rlines = 1:size(mdata.Data,2);
      new_rlines = linspace(1,size(mdata.Data,2),5000);
      mdata.Data = interp1(old_rlines,mdata.Data.',new_rlines).';
      mdata.Latitude = interp1(old_rlines,mdata.Latitude,new_rlines);
      mdata.Longitude = interp1(old_rlines,mdata.Longitude,new_rlines);
      mdata.Elevation = interp1(old_rlines,mdata.Elevation,new_rlines);
      mdata.GPS_time = interp1(old_rlines,mdata.GPS_time,new_rlines);
    end
    
    GPS_time_nan = false;
    if any(isnan(lay.GPS_time))
      warning('GPS time in layer data has NaN. Faking GPS time.');
      GPS_time_nan = true;
    end
    if any(isnan(mdata.GPS_time))
      warning('GPS time in echogram data has NaN. Faking GPS time.');
      GPS_time_nan = true;
    end
    if GPS_time_nan
      lay.GPS_time = 1:length(lay.GPS_time);
      mdata.GPS_time = linspace(lay.GPS_time(1),lay.GPS_time(end),length(mdata.GPS_time));
    end
    
    echo_param = param.post.echo;
    if exist('echo_info','var')
      echo_param.fig_hand = echo_info.fig_hand;
    else
      echo_param.fig_hand = [];
    end
    
    echo_param.frm_id = sprintf('%s_%03d', param.day_seg, frm);
    
    echo_info = publish_echogram(echo_param,mdata,lay, surface_lay.layerData{1});
    for handle_idx = 1:length(echo_info.h_layers)
      set(echo_info.h_layers{handle_idx},'Visible','off');
    end
    set(echo_info.fig_hand(1),'Name',param.post.data_dirs{1});
    
    % Update title (handle segment wrapping from one day to the next)
    seg_year = str2double(param.day_seg(1:4));
    seg_month = str2double(param.day_seg(5:6));
    seg_day = str2double(param.day_seg(7:8));
    
    [year,month,day,hour,minute,sec] = datevec(epoch_to_datenum(lay.GPS_time(1)));
    days_offset = datenum(year,month,day) - datenum(seg_year,seg_month,seg_day);
    hour = hour + 24*days_offset;
    start_time_str = sprintf('%02d:%02d:%04.1f', hour, minute, sec);
    
    [year,month,day,hour,minute,sec] = datevec(epoch_to_datenum(lay.GPS_time(end)));
    days_offset = datenum(year,month,day) - datenum(seg_year,seg_month,seg_day);
    hour = hour + 24*days_offset;
    stop_time_str = sprintf('%02d:%02d:%04.1f', hour, minute, sec);
    
    if GPS_time_nan
      echo_info.h_title = title(echo_info.ah_echo,sprintf('%s %s: "%s"  %s: No GPS', output_dir, param.season_name, ...
        param.cmd.mission_names, frm_id), ...
        'Interpreter','none','FontWeight','normal','FontSize',9);
    else
      echo_info.h_title = title(echo_info.ah_echo,sprintf('%s %s: "%s"  %s: %s to %s GPS', output_dir, param.season_name, ...
        param.cmd.mission_names, frm_id, start_time_str, ...
        stop_time_str),'Interpreter','none','FontWeight','normal','FontSize',9);
    end
    
    % Remove current file and save new file
    echo_fn = sprintf('%s_1echo.%s',frm_id,param.post.img_type);
    echo_fn = fullfile(image_dir,echo_fn);
    if exist(echo_fn,'file')
      delete(echo_fn);
    end
    set(echo_info.fig_hand(1),'PaperUnits','inches');
    set(echo_info.fig_hand(1),param.post.echo.plot_params{1},param.post.echo.plot_params{2});
    set(echo_info.fig_hand(1),'PaperOrientation','Portrait');
    if param.post.echo_with_no_layer_en
      fprintf('    Saving output %s\n', echo_fn);
      print(echo_info.fig_hand(1),print_device,print_dpi,echo_fn);
    end
    
    if param.post.pdf_en
      % Remove current file and save new file
      echo_fn = sprintf('%s_1echo.pdf',frm_id);
      echo_fn = fullfile(pdf_dir,echo_fn);
      if exist(echo_fn,'file')
        delete(echo_fn);
      end
      set(echo_info.fig_hand(1),'PaperOrientation','Landscape');
      set(echo_info.fig_hand(1),'PaperUnits','inches');
      set(echo_info.fig_hand(1),'PaperPosition',[0.5 0.5 10 7.5]);
      %print(echo_info.fig_hand(1),'-depsc','-r72',echo_fn);
      saveas(echo_info.fig_hand(1),echo_fn);
    end
    % =====================================================================
    % Plot echogram w/ layers
    if param.post.layers_en
      for handle_idx = 1:length(echo_info.h_layers)
        set(echo_info.h_layers{handle_idx},'Visible','on');
      end
      
      % Remove current file and save new file
      echo_fn = sprintf('%s_2echo_picks.%s',frm_id,param.post.img_type);
      echo_fn = fullfile(image_dir,echo_fn);
      if exist(echo_fn,'file')
        delete(echo_fn);
      end
      set(echo_info.fig_hand(1),param.post.echo.plot_params{1},param.post.echo.plot_params{2});
      set(echo_info.fig_hand(1),'PaperOrientation','Portrait');
      fprintf('    Saving output %s\n', echo_fn);
      print(echo_info.fig_hand(1),print_device,print_dpi,echo_fn);
      
      if param.post.pdf_en
        % Remove current file and save new file
        echo_fn = sprintf('%s_2echo_picks.pdf',frm_id);
        echo_fn = fullfile(pdf_dir,echo_fn);
        if exist(echo_fn,'file')
          delete(echo_fn);
        end
        set(echo_info.fig_hand(1),'PaperOrientation','Landscape');
        set(echo_info.fig_hand(1),'PaperUnits','inches');
        set(echo_info.fig_hand(1),'PaperPosition',[0.5 0.5 10 7.5]);
        %print(echo_info.fig_hand(1),'-depsc','-r72',echo_fn);
        saveas(echo_info.fig_hand(1),echo_fn);
      end
    end
  end
  
  %% Post Loop: Create .csv files
  if param.post.csv_en
    csv_dir = fullfile(post_path,'csv',param.day_seg);
    if ~exist(csv_dir,'dir')
      mkdir(csv_dir)
    end
    % Remove current file and save new file
    csv_fn = sprintf('Data_%s.csv',frm_id);
    csv_fn = fullfile(csv_dir,csv_fn);
    if exist(csv_fn,'file')
      delete(csv_fn);
    end
    csv_good_dir = fullfile(post_path,'csv_good',param.day_seg);
    if ~exist(csv_good_dir,'dir')
      mkdir(csv_good_dir)
    end
    % Remove current file and save new file
    csv_good_fn = sprintf('Data_%s.csv',frm_id);
    csv_good_fn = fullfile(csv_good_dir,csv_good_fn);
    if exist(csv_good_fn,'file')
      delete(csv_good_fn);
    end
    PThickness = (lay.Bottom-lay.Surface)*c/2/sqrt(param.post.echo.er_ice);
    PSurface = lay.Surface*c/2;
    PBottom = PThickness+PSurface;
    
    PThickness(~isfinite(PThickness)) = -9999;
    PBottom(~isfinite(PBottom)) = -9999;
    PSurface(~isfinite(PSurface)) = -9999;
    % Quality of thickness is the lowest/worst confidence level of the surface
    % and bottom picks which each have their own quality level
    % (higher quality numbers mean lower confidence, so we take the max)
    if param.post.layers_en
      bottom_quality = lay.layerData{end}.quality(1);
    else
      bottom_quality = lay.Bottom;  % Should be NaN array size of Surface
    end
    Quality = max(surface_lay.layerData{1}.quality,bottom_quality);
    
    % Compute seconds of day relative to the data frame ID
    UTC_time = lay.GPS_time - utc_leap_seconds(lay.GPS_time(1));
    UTC_time_start = datenum_to_epoch(datenum(str2double(param.day_seg(1:4)), ...
      str2double(param.day_seg(5:6)), ...
      str2double(param.day_seg(7:8))));
    UTC_time = UTC_time - UTC_time_start;
    
    bad_idxs = isnan(lay.Latitude) | isnan(lay.Longitude) | isnan(lay.Elevation) | isnan(UTC_time);
    if any(bad_idxs)
      warning('There are NaN in the data: suggest correcting and rerunning');
      keyboard;
      lay.Latitude = lay.Latitude(~bad_idxs);
      lay.Longitude = lay.Longitude(~bad_idxs);
      lay.Elevation = lay.Elevation(~bad_idxs);
      PThickness = PThickness(~bad_idxs);
      PBottom = PBottom(~bad_idxs);
      PSurface = PSurface(~bad_idxs);
      UTC_time = UTC_time(~bad_idxs);
      Quality = Quality(~bad_idxs);
    end
    
    fid_csv = fopen(csv_fn,'w');
    fid_csv_good = fopen(csv_good_fn,'w');
    fprintf(fid_csv,'%s,%s,%s,%s,%s,%s,%s,%s,%s\n',...
      'LAT','LON','UTCTIMESOD','THICK','ELEVATION','FRAME','SURFACE','BOTTOM','QUALITY');
    fprintf(fid_csv_good,'%s,%s,%s,%s,%s,%s,%s,%s,%s\n',...
      'LAT','LON','UTCTIMESOD','THICK','ELEVATION','FRAME','SURFACE','BOTTOM','QUALITY');
    for txt_idx = 1:length(lay.Latitude)
      frm_id_num = [frm_id(1:8) frm_id(10:11) frm_id(13:15)];
      fprintf(fid_csv,'%2.6f,%2.6f,%5.4f,%6.2f,%4.4f,%s,%6.2f,%6.2f,%01d\n',...
        lay.Latitude(txt_idx),lay.Longitude(txt_idx),...
        UTC_time(txt_idx),PThickness(txt_idx),...
        lay.Elevation(txt_idx),frm_id_num,PSurface(txt_idx),PBottom(txt_idx),Quality(txt_idx));
      if PThickness(txt_idx) > -9999
        if isnan(lay.Latitude(txt_idx)) || isnan(lay.Longitude(txt_idx))
          fprintf('NaN values found in latitdue or logitude at frame: %3d,continue after debug the error\n',frm_id_num);
          keyboard
        end
        fprintf(fid_csv_good,'%2.6f,%2.6f,%5.4f,%6.2f,%4.4f,%s,%6.2f,%6.2f,%01d\n',...
          lay.Latitude(txt_idx),lay.Longitude(txt_idx),...
          UTC_time(txt_idx),PThickness(txt_idx),...
          lay.Elevation(txt_idx),frm_id_num,PSurface(txt_idx),PBottom(txt_idx),Quality(txt_idx));
      end
    end
    fclose(fid_csv);
    fclose(fid_csv_good);
  end
  
  %% Post Loop: Create layer files
  if param.post.layers_en
    % NEW FILE FORMAT
    for layer_idx = 1:length(layers_to_post)
      id = out_layers.get_id(layers_to_post{layer_idx}.name);
      if isempty(id)
        layer_organizer = [];
        layer_organizer.age = layers_to_post{layer_idx}.age;
        layer_organizer.age_source = {layers_to_post{layer_idx}.age_source};
        layer_organizer.lyr_desc = {layers_to_post{layer_idx}.desc};
        layer_organizer.lyr_group_name = {layers_to_post{layer_idx}.group_name};
        layer_organizer.lyr_name = {layers_to_post{layer_idx}.name};
        id = out_layers.insert_layers(layer_organizer);
      end
      out_layers.update_layer(frm, id, layers_to_post{layer_idx}.gps_time, ...
        layers_to_post{layer_idx}.twtt,layers_to_post{layer_idx}.quality,layers_to_post{layer_idx}.type);
    end
    if 1
      % OLD FILE FORMAT
      
      % Copy layer file
      layer_out_fn_dir = fullfile(post_path,sprintf('CSARP_layerData'),param.day_seg);
      if ~exist(layer_out_fn_dir,'dir')
        mkdir(layer_out_fn_dir)
      end
      layer_out_fn = fullfile(layer_out_fn_dir,sprintf('Data_%s.mat',frm_id));
      
      save(layer_out_fn,'-struct','lay','GPS_time','Latitude','Longitude','Elevation','layerData');
    end
  end
  
  %% Post Loop: Copy data files
  if param.post.data_en
    % Copy data files
    for data_idx = 1:length(param.post.data_dirs)
      if param.post.img == 0
        data_fn = fullfile(ct_filename_out(param,param.post.data_dirs{data_idx}),sprintf('Data_%s.mat',frm_id));
      else
        data_fn = fullfile(ct_filename_out(param,param.post.data_dirs{data_idx}),sprintf('Data_img_%02d_%s.mat',param.post.img,frm_id));
      end
      if ~exist(data_fn,'file')
        warning('Data file does not exist, skipping:\n  %s', data_fn);
        continue;
      end
      [tmp data_name] = fileparts(data_fn);
      data_fn_dir = fileparts(data_fn);
      data_fn_dir_dir = fileparts(data_fn_dir);
      [~,data_fn_dir_dir_name] = fileparts(data_fn_dir_dir);
      data_out_dir = fullfile(post_path,data_fn_dir_dir_name,param.day_seg);
      if ~exist(data_out_dir,'dir')
        mkdir(data_out_dir)
      end
      data_out_fn = fullfile(data_out_dir,[data_name '.mat']);
      
      copyfile(data_fn, data_out_fn);
      
      if 0
        % DATA FILES SHOULD NOT BE UPDATED! They represent the surface
        % and bottom used during processing.
        
        % Interpolate onto the data files GPS time
        data_file = load(data_out_fn,'Time','GPS_time','Elevation');
        
        % Create fast-time correction vector
        %   The layer file may contain a different elevation profile
        %   than the data file. The surface and bottom need to be adjusted
        %   to account for these differences.
        elev_interp    = interp1(lay.GPS_time,lay.Elevation,data_file.GPS_time,'linear','extrap');
        fast_time_correction = (data_file.Elevation - elev_interp)/(c/2);
        
        warning('off','MATLAB:interp1:NaNinY');
        Surface = interp1(lay.GPS_time,lay.Surface,data_file.GPS_time,'linear','extrap') ...
          + fast_time_correction;
        Bottom = interp1(lay.GPS_time,lay.Bottom,data_file.GPS_time,'linear','extrap') ...
          + fast_time_correction;
        warning('on','MATLAB:interp1:NaNinY');
        save(data_out_fn,'Bottom','Surface','-APPEND');
      end
    end
  end
end

% Save layer files
% =======================================================================
if param.post.layers_en
  out_layers.save();
end

% =======================================================================
%% Create segment CSV/KML files
% =======================================================================

if param.post.concat_en
  fprintf(' Creating csv and kml files (%s)\n', datestr(now));
  
  csv_dir = fullfile(post_path,'csv',param.day_seg);
  
  if ~exist(csv_dir,'dir')
    warning('No csv files to concatenate.');
  else
    [csv_dir_path csv_dir_name] = fileparts(csv_dir);
    out_fn = fullfile(csv_dir_path,sprintf('Data_%s.csv',csv_dir_name));
    concatenate_thickness_files(csv_dir,'*.csv',out_fn,',');
  end
  
  % Repeat for csv_good and kml_good
  csv_dir = fullfile(post_path,'csv_good',param.day_seg);
  
  if ~exist(csv_dir,'dir')
    warning('No csv files to concatenate.');
  else
    [csv_dir_path csv_dir_name] = fileparts(csv_dir);
    out_fn = fullfile(csv_dir_path,sprintf('Data_%s.csv',csv_dir_name));
    concatenate_thickness_files(csv_dir,'*.csv',out_fn,',');
  end
end

% =======================================================================
%% Create segment pdf file
% =======================================================================
if param.post.pdf_en
  fprintf(' Creating combined pdf files (%s)\n', datestr(now));
  gs_path = 'C:\Progra~1\gs\gs9.16\bin\gswin64.exe';
  if ispc && ~exist(gs_path,'file')
    warning('  Can not do this final step on a PC without ghostscript (gs version 9.02) commands. Rerun posting with just pdf enabled on the post worksheet on a linux machine and it will skip to this combine step so you don''t have to recreate all the temporary frame pdf files again.');
  else
    pdf_base_dir = fullfile(post_path,'pdf');
    % The PDF creation used to do all available directories:
    %pdf_dirs = get_filenames(pdf_base_dir,'[0-9]','','',struct('type','d'));
    % Now the PDF creation just does the current segment:
    pdf_dirs = {fullfile(pdf_base_dir,param.day_seg)};
    
    for dir_idx = 1:length(pdf_dirs)
      in_search_str = fullfile(pdf_dirs{dir_idx},'*.pdf');
      [pdf_dir_path pdf_dir_name] = fileparts(pdf_dirs{dir_idx});
      out_fn = fullfile(pdf_dir_path,sprintf('%s.pdf',pdf_dir_name));
      fprintf('  Creating pdf %s\n', out_fn);
      if ispc
        pdf_fns = get_filenames(pdf_dirs{dir_idx},'','','.pdf');
        pdf_fns = sprintf('%s ', pdf_fns{:});
        sys_cmd = sprintf('%s -dNOPAUSE -dBATCH -dSAFER -sOutputFile=%s -sDEVICE=pdfwrite -f %s', ...
          gs_path, out_fn, pdf_fns);
      else
        sys_cmd = sprintf('gs -dNOPAUSE -dBATCH -dSAFER -sOutputFile=%s -sDEVICE=pdfwrite -f %s </dev/null', ...
          out_fn, in_search_str);
      end
      [status,result] = system(sys_cmd);
      if status > 1
        warning('pdf creation may have failed');
        fprintf('Not deleting temporary files so that pdf can be run again\n');
        fprintf('Ghostscript version (gs --version):\n');
        system('gs --version');
        fprintf('Try using gs version 9.02: you may need to download this\n');
      else
        % Remove temporary files
        try
          delete(in_search_str);
        catch ME
          warning(ME.getReport);
        end
        try
          rmdir(pdf_dirs{dir_idx});
        catch ME
          warning(ME.getReport);
        end
      end
    end
  end
end

fprintf('Done %s (%s)\n', param.day_seg, datestr(now));

try
  delete(map_info.fig_hand)
end
try
  delete(echo_info.fig_hand)
end
