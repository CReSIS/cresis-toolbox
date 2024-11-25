function success = qlook_combine_task(param)
% success = qlook_combine_task(param)
%
% Task for combining qlook temporary outputs into images and running
% surface tracking.
%
% param = struct with processing parameters
%
% Example:
%  This function is usually called via the cluster batch setup in
%  qlook.
%
% Authors: John Paden
%
% See also: run_master.m, master.m, run_qlook.m, qlook.m,
%   qlook_task.m

%% Setup Processing
% =====================================================================

frames = frames_load(param);
% Load records file
records = records_load(param);

% Quick look radar echogram output directory
out_dir = ct_filename_out(param, param.qlook.out_path);
tmp_out_dir = ct_filename_out(param, param.qlook.out_path, 'qlook_tmp');

% Radiometric correction (dB)
radiometric_corr_dB = param.qlook.radiometric_corr_dB;

%% Loop through all the frames: combine and surface track
% =====================================================================
[output_dir,radar_type] = ct_output_dir(param.radar_name);
for frm_idx = 1:length(param.cmd.frms);
  frm = param.cmd.frms(frm_idx);
  
  outputs_done = true;
  for img = 1:length(param.qlook.imgs)
    if length(param.qlook.imgs) == 1
      out_fn = fullfile(out_dir, sprintf('Data_%s_%03d.mat', ...
        param.day_seg, frm));
    else
      out_fn = fullfile(out_dir, sprintf('Data_img_%02d_%s_%03d.mat', ...
        img, param.day_seg, frm));
    end
    if ~ct_file_lock_check(out_fn,4)
      outputs_done = false;
    end
  end
  if length(param.qlook.imgs) > 1 && ~isempty(param.qlook.img_comb)
    out_fn = fullfile(out_dir, sprintf('Data_%s_%03d.mat', ...
      param.day_seg, frm));

    if ~ct_file_lock_check(out_fn,4)
      outputs_done = false;
    end
  end
  if outputs_done
    fprintf('Done, skipping %s\n', out_fn);
    continue;
  end
  
  % Check digits of proc_mode from frames file and make sure the user has
  % specified to process this frame type
  if ct_proc_frame(frames.proc_mode(frm),param.qlook.frm_types)
    fprintf('qlook_combine frame %s_%03i (%i of %i) %s\n', param.day_seg, frm, frm_idx, length(param.cmd.frms), datestr(now));
  else
    fprintf('Skipping frame %s_%03i (no process frame)\n', param.day_seg, frm);
    continue;
  end
  
  % recs: Determine the records for this frame
  if frm < length(frames.frame_idxs)
    recs = frames.frame_idxs(frm):frames.frame_idxs(frm+1)-1;
  else
    recs = frames.frame_idxs(frm):length(records.gps_time);
  end
  
  %% Output directory
  in_fn_dir = fullfile(tmp_out_dir, sprintf('ql_data_%03d_01_01',frm));
  
  %% Concatenate blocks for each of the images
  for img = 1:length(param.qlook.imgs)
    %% Concatenate all the ql block outputs for this image
    Time = [];
    GPS_time = [];
    Latitude = [];
    Longitude = [];
    Elevation = [];
    Roll = [];
    Pitch = [];
    Heading = [];
    Surface = [];
    Data = [];
    custom = [];
    
    % Determine where breaks in processing blocks are going to occur
    %   Rename variables for readability
    block_size = param.qlook.block_size(1);
    blocks = 1:block_size:length(recs)-0.5*block_size;
    if isempty(blocks)
      blocks = 1;
    end
    
    % Load each block
    for block_idx = 1:length(blocks)
      
      % Determine the records for this block
      if block_idx < length(blocks)
        cur_recs_keep = [recs(blocks(block_idx)) recs(blocks(block_idx+1)-1)];
      else
        cur_recs_keep = [recs(blocks(block_idx)) recs(end)];
      end
      
      in_fn_name = sprintf('qlook_img_%02d_%d_%d.mat',img,cur_recs_keep(1),cur_recs_keep(end));
      in_fn = fullfile(in_fn_dir,in_fn_name);
      
      tmp = load(in_fn);
      if length(tmp.Time) == 1
        % Force length==1 in fast time to just be empty to simplify data
        % handling later. The idea is that a length 1 range line is useless
        % anyway so we might as well simplify things by making it zero length.
        tmp.Time = [];
        tmp.Data = tmp.Data([],:);
      end
      time_vector_changed = false;
      if block_idx == 1
        Time = tmp.Time;
      elseif ~isequal(Time,tmp.Time)
        % Determine the new time axis
        %   Note that even though time axis is aligned with multiples of
        %   dt, there will be rounding errors which need to be dealt with
        %   here.
        time_vector_changed = true;
        if isempty(Time)
          Time = tmp.Time;
          start_time_diff = size(Time,1);
          end_time_diff = 0;
        elseif isempty(tmp.Time)
          start_time_diff = -size(Time,1);
          end_time_diff = 0;
        else
          dt = Time(2) - Time(1);
          start_time_diff = round((Time(1) - tmp.Time(1))/dt);
          end_time_diff = round((tmp.Time(end) - Time(end))/dt);
          if start_time_diff > 0
            Time = [Time(1)+dt*(-start_time_diff:-1)'; Time];
          end
          if end_time_diff > 0
            Time = [Time; Time(end)+dt*(1:end_time_diff)'];
          end
        end
      end
      Latitude = [Latitude double(tmp.Latitude)];
      Longitude = [Longitude double(tmp.Longitude)];
      Elevation = [Elevation double(tmp.Elevation)];
      Roll = [Roll double(tmp.Roll)];
      Pitch = [Pitch double(tmp.Pitch)];
      Heading = [Heading double(tmp.Heading)];
      Surface = [Surface double(tmp.Surface)];
      GPS_time = [GPS_time tmp.GPS_time];
      param_records = tmp.param_records;
      param_qlook = tmp.param_qlook;
      
      if isfield(tmp,'custom') && ~isempty(tmp.custom)
        % Custom fields are present, so concatenate them on the last dimension
        % - Used for coherent noise/deconv information
        fields = fieldnames(tmp.custom);
        if block_idx == 1
          for field_idx = 1:length(fields)
            custom.(fields{field_idx}) = tmp.custom.(fields{field_idx});
          end
        else
          for field_idx = 1:length(fields)
            custom.(fields{field_idx}) = cat(2,custom.(fields{field_idx}),tmp.custom.(fields{field_idx}));
          end
        end
        
      end
      
      if time_vector_changed
        Data = [[zeros(start_time_diff,size(Data,2)); Data; zeros(end_time_diff,size(Data,2))], ...
          [zeros(-start_time_diff,size(tmp.Data,2)); tmp.Data; zeros(-end_time_diff,size(tmp.Data,2))]];
      else
        if size(tmp.Data,1) == 0
          % Check for no good records which results in size of fast-time
          % (first) dimension being zero. Handle this, but filling with
          % NaN.
          Data = [Data nan(size(Data,1),size(tmp.Data,2))];
        else
          Data = [Data tmp.Data];
        end
      end
    end
    
    %% Save output
    if length(param.qlook.imgs) == 1
      out_fn = fullfile(out_dir, sprintf('Data_%s_%03d.mat', ...
        param.day_seg, frm));
    else
      out_fn = fullfile(out_dir, sprintf('Data_img_%02d_%s_%03d.mat', ...
        img, param.day_seg, frm));
    end
    fprintf('  Writing output to %s\n', out_fn);
    
    if ~exist(out_dir,'dir')
      mkdir(out_dir);
    end
    
    % Truncate deramp data to nonnegative time if this is going to be the
    % final combined file
    if (length(param.qlook.imgs) == 1 || (img == 1 && isempty(param.qlook.img_comb))) ...
        && ~isempty(Time) && Time(1) < 0 && strcmpi(radar_type,'deramp')
      good_bins = Time>=0;
      Time = Time(good_bins);
      Data = Data(good_bins,:);
    end
    
    if (length(param.qlook.imgs) == 1 || (img == 1 && isempty(param.qlook.img_comb))) ...
      && (param.qlook.surf.en || ~strcmpi(radar_type,'deramp'))
      % Criteria 1: One of the following is true
      % 1. length(param.qlook.imgs) == 1: This is the combined file
      %   Data_YYYYMMDD_SS_FFF which will contain the surface and be time
      %   trimmed if these are enabled.
      %
      % 2. img == 1 && isempty(param.qlook.img_comb): This is the
      %    Data_img_01_YYYYMMDD_SS_FFF file which will contain the surface and
      %    be time trimmed if these are enabled.
      %
      % Criteria 2: This is not a deramp file for which no time trimming
      % needs to be done OR it is a deramp file for which no time trimming
      % needs to be done, but the surface still needs to be updated. Note
      % that non-deramp systems ALWAYS have time trimming done.
      
      % If Criteria 1 and 2 are satisfied, then this file will be written
      % to later and we should mark it incomplete by putting a "D" in the
      % file_version. The file_version will be updated when the final file
      % is created.
      file_version = '1D';
    elseif param.ct_file_lock
      file_version = '1L';
    else
      file_version = '1';
    end
    file_type = 'qlook';
    if isnan(radiometric_corr_dB)
      Data = single(Data);
    else
      Data = single(Data * 10^(radiometric_corr_dB/10));
    end
    if isempty(custom)
      ct_save(out_fn,'Time','Latitude','Longitude', 'radiometric_corr_dB', ...
        'Elevation','Roll','Pitch','Heading','GPS_time','Data','Surface', ...
        'param_qlook','param_records','file_version','file_type');
    else
      ct_save(out_fn,'Time','Latitude','Longitude', 'radiometric_corr_dB', ...
        'Elevation','Roll','Pitch','Heading','GPS_time','Data','Surface', ...
        'param_qlook','param_records','file_version','file_type','custom');
    end
  end
  
  %% Run ice top tracker to find ice surface
  if param.qlook.surf.en
    % Combine image with previous for surface tracking
    img_combine_param = param;
    img_combine_param.load.frm = frm;
    surf_layer.gps_time = GPS_time;
    surf_layer.twtt = Surface;
    [Data_Surface, Time_Surface] = img_combine(img_combine_param, 'qlook', surf_layer);
    
    surf_param = param;
    surf_param.layer_tracker.frms = frm;
    surf_param.layer_tracker.echogram_source = struct('Data',Data_Surface,'Time',Time_Surface,'GPS_time',GPS_time,'Latitude',Latitude,'Longitude',Longitude,'Elevation',Elevation,'Roll',Roll);
    if length(Time_Surface) < 2
      % This frame has all bad records, so surface tracking cannot be completed.
      Surface = nan(size(GPS_time));
    else
      Surface = layer_tracker_task(surf_param);
    end
  end
  
  %% Save combined image output
  if length(param.qlook.imgs) == 1 || ~isempty(param.qlook.img_comb)
    % A combined file should be created
    out_fn = fullfile(out_dir, sprintf('Data_%s_%03d.mat', ...
      param.day_seg, frm));
  else
    % Store the result in img 1 since a combined file is not created
    img = 1;
    out_fn = fullfile(out_dir, sprintf('Data_img_%02d_%s_%03d.mat', ...
      img, param.day_seg, frm));
  end
  fprintf('  Writing output to %s\n', out_fn);
  
  if param.ct_file_lock
    file_version = '1L';
  else
    file_version = '1';
  end
  if isempty(param.qlook.img_comb) && strcmpi(radar_type,'deramp')
    % There is no image combining and no time trim is necessary
    if param.qlook.surf.en
      % No images were combined, no img_comb_trim needs to be done,
      % therefore the data will remain unchanged and we can just update the
      % Surface variable and mark the file_version complete.
      ct_save(out_fn,'-append','Surface','file_version');
    end
    
  else
    % Combine images into a single image and/or trim invalid times with
    % img_comb_trim
    img_combine_param = param;
    img_combine_param.load.frm = frm;
    surf_layer.gps_time = GPS_time;
    surf_layer.twtt = Surface;
    [Data, Time] = img_combine(img_combine_param, 'qlook', surf_layer);
    file_type = 'qlook';
    
    if isempty(custom)
      ct_save(out_fn,'Time','Latitude','Longitude', 'radiometric_corr_dB', ...
        'Elevation','Roll','Pitch','Heading','GPS_time','Data','Surface', ...
        'param_qlook','param_records','file_version','file_type');
    else
      ct_save(out_fn,'Time','Latitude','Longitude', 'radiometric_corr_dB', ...
        'Elevation','Roll','Pitch','Heading','GPS_time','Data','Surface', ...
        'param_qlook','param_records','file_version','file_type','custom');
    end
  end
  
  
  %% Delete temporary files now that all combined files are created
  if 0 % HACK: DISABLE TO NOT DELETE TEMPORARY FILES
    for img = 1:length(param.qlook.imgs)
      % Determine where breaks in processing blocks are going to occur
      block_size = param.qlook.block_size(1);
      blocks = 1:block_size:length(recs)-0.5*block_size;
      if isempty(blocks)
        blocks = 1;
      end
      
      % Load each block
      for block_idx = 1:length(blocks)
        
        % Determine the records for this block
        if block_idx < length(blocks)
          cur_recs_keep = [recs(blocks(block_idx)) recs(blocks(block_idx+1)-1)];
        else
          cur_recs_keep = [recs(blocks(block_idx)) recs(end)];
        end
        
        in_fn_name = sprintf('qlook_img_%02d_%d_%d.mat',img,cur_recs_keep(1),cur_recs_keep(end));
        in_fn = fullfile(in_fn_dir,in_fn_name);
        
        delete(in_fn);
      end
    end
    % Attempt to remove ql_data_FFF_01_01 directory since it is no longer
    % needed.
    try
      rmdir(in_fn_dir);
    end
  end
  
end


%% Optionally store surface layer to disk
if param.qlook.surf.en
  if ~param.records.gps.en
    warning('Surface tracking param.qlook.surf.en is not done when param.records.gps.en is false.');
  else
    if length(param.qlook.imgs) == 1 || ~isempty(param.qlook.img_comb)
      % A combined file should be created
      echogram_source_img = 0;
    else
      % Store the result in img 1 since a combined file is not created
      echogram_source_img = 1;
    end
    
    % Read the "Surface" variable from all the frames that were created
    % by this particular run of qlook
    
    copy_param.layer_source.name = 'surface';
    copy_param.layer_source.source = 'echogram';
    copy_param.layer_source.echogram_source = param.qlook.out_path;
    copy_param.layer_source.existence_check = false;
    copy_param.layer_source.existence_warning = false;
    copy_param.layer_source.echogram_source_img = echogram_source_img;
    
    copy_param.layer_dest = param.qlook.surf_layer;
    copy_param.layer_dest.group_name = 'standard';
    copy_param.layer_dest.existence_check = false;
    copy_param.layer_dest.echogram_source_img = echogram_source_img;
    
    copy_param.copy_method = 'overwrite';
    copy_param.gaps_fill.method = 'interp_finite';
    
    opsCopyLayers(param,copy_param);
  end
end

%% Done
% =========================================================================

fprintf('%s done %s\n', mfilename, datestr(now));

success = true;
