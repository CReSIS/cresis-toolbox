function ctrl_chain = sar(param,param_override)
% ctrl_chain = sar(param,param_override)
%
% SAR processor function which breaks up the frame into chunks
% which are processed by sar_task.m
%
% param = struct with processing parameters
%         -- OR --
%         function handle to script with processing parameters
% param_override = parameters in this struct will override parameters
%         in param.  This struct must also contain the gRadar fields.
%         Typically global gRadar; param_override = gRadar;
%
% Authors: William Blake, John Paden
%
% Example:
%  See run_sar.m for how to run this function directly.
%  Normally this function is called from master.m using the param spreadsheet.
%
% See also: run_master.m, master.m, run_sar.m, sar.m, sar_task.m,
%   sar_coord_task.m

%% General Setup
% =====================================================================
if exist('param_override','var')
  param = merge_structs(param, param_override);
end

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input Checks
% =====================================================================

% Get speed of light, dielectric of ice constants
physical_constants;

% Remove frames that do not exist from param.cmd.frms list
frames = frames_load(param);
if ~isfield(param.cmd,'frms') || isempty(param.cmd.frms)
  param.cmd.frms = 1:length(frames.frame_idxs);
end
[valid_frms,keep_idxs] = intersect(param.cmd.frms, 1:length(frames.frame_idxs));
if length(valid_frms) ~= length(param.cmd.frms)
  bad_mask = ones(size(param.cmd.frms));
  bad_mask(keep_idxs) = 0;
  warning('Nonexistent frames specified in param.cmd.frms (e.g. frame "%g" is invalid), removing these', ...
    param.cmd.frms(find(bad_mask,1)));
  param.cmd.frms = valid_frms;
end

if ~isfield(param.sar,'bit_mask') || isempty(param.sar.bit_mask)
  % Remove bad records (bit_mask==1), remove stationary records
  % (bit_mask==2), and remove bad records (bit_mask==4)
  param.sar.bit_mask = 1 + 2 + 4;
end

if ~isfield(param.sar,'combine_rx') || isempty(param.sar.combine_rx)
  param.sar.combine_rx = false;
end

if ~isfield(param.sar,'chunk_len') || isempty(param.sar.chunk_len)
  param.sar.chunk_len = 2500;
end

if ~isfield(param.sar,'imgs') || isempty(param.sar.imgs)
  param.sar.imgs = {[1 1]};
end

if ~isfield(param.sar,'wf_adc_pair_task_group_method') || isempty(param.sar.wf_adc_pair_task_group_method)
  % 'one': One wf_adc pair per task, least memory and maximum
  %   parallelization at the cost of increased disk IO
  % 'img': One image per task, most constant amount of memory required for
  %   each SAR image being produced by a single task, may increase
  %   disk IO. This is the default and usually the best setting unless disk
  %   IO or memory are very important to minimize.
  % 'board': All images for a board in one task, least disk IO and maximum
  %   memory
  param.sar.wf_adc_pair_task_group_method = 'img';
end

if ~isfield(param.sar,'frm_types') || isempty(param.sar.frm_types)
  param.sar.frm_types = {-1,-1,-1,-1,-1};
end

if ~isfield(param.sar,'Lsar') || isempty(param.sar.Lsar)
  param.sar.Lsar = [];
end
if ~isfield(param.sar.Lsar,'agl') || isempty(param.sar.Lsar.agl)
  param.sar.Lsar.agl = 500;
end
if ~isfield(param.sar.Lsar,'thick') || isempty(param.sar.Lsar.thick)
  param.sar.Lsar.thick = 1000;
end

if ~isfield(param.sar,'mocomp') || isempty(param.sar.mocomp)
  param.sar.mocomp = [];
end
if ~isfield(param.sar.mocomp,'en') || isempty(param.sar.mocomp.en)
  param.sar.mocomp.en = false;
end
if ~isfield(param.sar.mocomp,'filter') || isempty(param.sar.mocomp.filter)
  param.sar.mocomp.filter = {@butter,2,0.1};
end
% Tukey window to apply when undoing motion compensation after
% fk-migration, default is 0.05. A value of 0 disables the window.
if ~isfield(param.sar.mocomp,'tukey') || isempty(param.sar.mocomp.tukey)
  param.sar.mocomp.tukey = 0.05;
end
if ~isfield(param.sar.mocomp,'type') || isempty(param.sar.mocomp.type)
  param.sar.mocomp.type = 2;
end
if ~isfield(param.sar.mocomp,'uniform_en') || isempty(param.sar.mocomp.uniform_en)
  param.sar.mocomp.uniform_en = true;
end
% Masks bad records based on the data_load hdr.bad_recs field. Masked
% records are not included in the sinc interpolation.
if ~isfield(param.sar.mocomp,'param.sar.mocomp.uniform_mask_en') || isempty(param.sar.mocomp.uniform_mask_en)
  param.sar.mocomp.uniform_mask_en = true;
end

if ~isfield(param.sar,'out_path') || isempty(param.sar.out_path)
  param.sar.out_path = 'sar';
end
if ~isfield(param.sar,'coord_path') || isempty(param.sar.coord_path)
  param.sar.coord_path = param.sar.out_path;
end

if ~isfield(param.sar,'presums') || isempty(param.sar.presums)
  param.sar.presums = 1;
end

if ~isfield(param.sar,'sar_type') || isempty(param.sar.sar_type)
  param.sar.sar_type = 'fk';
end
if strcmpi(param.sar.sar_type,'f-k')
  error('Deprecated sar_type name. Change param.sar.sar_type from ''f-k'' to ''fk'' in  your parameters (or remove parameter since ''fk'' is the default mode).');
end

if ~isfield(param.sar,'start_eps') || isempty(param.sar.start_eps)
  param.sar.start_eps = er_ice;
end

if ~isfield(param.sar,'time_start') || isempty(param.sar.time_start)
  param.sar.time_start = [];
end

if ~isfield(param.sar,'time_stop') || isempty(param.sar.time_stop)
  param.sar.time_stop = [];
end

if ~isfield(param.sar,'st_wind') || isempty(param.sar.st_wind)
  param.sar.st_wind = @hanning;
end

if ~isfield(param.sar,'sub_aperture_steering') || isempty(param.sar.sub_aperture_steering)
  % Single aperture which points broadside to SAR is default
  param.sar.sub_aperture_steering = [0];
end

if ~isfield(param.sar,'surf_filt_dist') || isempty(param.sar.surf_filt_dist)
  param.sar.surf_filt_dist = 3e3;
  warning('Surface filtering is not set. Using default value: %.0f m.',param.sar.surf_filt_dist);
end

if ~isfield(param.sar,'surf_layer') || isempty(param.sar.surf_layer)
  param.sar.surf_layer.name = 'surface';
  param.sar.surf_layer.source = 'layerData';
end
% Never check for the existence of layers
param.sar.surf_layer.existence_check = false;

if ~isfield(param.sar,'time_of_full_support') || isempty(param.sar.time_of_full_support)
  param.sar.time_of_full_support = inf;
end

%% Setup processing
% =====================================================================

% Get the standard radar name
[~,radar_type,radar_name] = ct_output_dir(param.radar_name);

% Load records file
records = records_load(param);
if any(isnan(records.gps_time)) ...
    || any(isnan(records.lat)) ...
    || any(isnan(records.lon)) ...
    || any(isnan(records.elev)) ...
    || any(isnan(records.roll)) ...
    || any(isnan(records.pitch)) ...
    || any(isnan(records.heading))
  error('NaN in records gps_time, trajectory, or attitude is not allowed for SAR processing.');
end
% Determine records bad mask (especially important for removing stationary
% records and correct computation of cluster resources). All boards must
% be bad for a record to be discarded.
good_recs = records.bit_mask(1,:) & param.sar.bit_mask;
for board_idx = 2:size(records.bit_mask,1)
  good_recs = bitand(good_recs,records.bit_mask(board_idx,:) & param.sar.bit_mask);
end
% At this point good_recs is "true" for a particular record if all boards
% are bad for that record. Now we find the indices of the records that are
% false (i.e. at least one good board).
good_recs = find(~good_recs);
% Apply presumming
if param.sar.presums > 1
  records.lat = fir_dec(records.lat,param.sar.presums);
  records.lon = fir_dec(records.lon,param.sar.presums);
  records.elev = fir_dec(records.elev,param.sar.presums);
  records.roll = fir_dec(records.roll,param.sar.presums);
  records.pitch = fir_dec(records.pitch,param.sar.presums);
  records.heading = fir_dec(records.heading,param.sar.presums);
  records.gps_time = fir_dec(records.gps_time,param.sar.presums);
end
% Along-track
along_track_approx = nan(size(records.gps_time));
along_track_approx(good_recs) = geodetic_to_along_track(records.lat(good_recs),records.lon(good_recs),records.elev(good_recs));
along_track_approx = interp_finite(along_track_approx);

% SAR output directory
sar_out_dir = ct_filename_out(param, param.sar.out_path);
sar_coord_dir = ct_filename_out(param, param.sar.coord_path);

ctrl_chain = {};

%% Collect waveform information into one structure
%  - This is used to break the frame up into chunks
% =====================================================================
[wfs,~] = data_load_wfs(setfield(param,'load',struct('imgs',{param.sar.imgs})),records);
param.radar.wfs = merge_structs(param.radar.wfs,wfs);

%% Create the SAR coordinate system (used for structuring processing)
% =====================================================================
  
% Load surface from layerdata
tmp_param = param;
tmp_param.cmd.frms = [];
surf_layer = opsLoadLayers(tmp_param,param.sar.surf_layer);
if isempty(surf_layer.gps_time)
  records.surface(:) = 0;
elseif length(surf_layer.gps_time) == 1
  records.surface(:) = surf_layer.twtt;
else
  records.surface = interp_finite(interp1(surf_layer.gps_time,surf_layer.twtt,records.gps_time),0);
end

sar_fn = fullfile(sar_coord_dir,'sar_coord.mat');
fprintf('sar_coord_task %s (%s):\n  %s\n', datestr(now), param.day_seg, sar_fn);
if exist(sar_fn,'file')
  sar_fields = whos('-file',sar_fn);
  if any(strcmp('version',{sar_fields.name}))
    warning('Old SAR coordinate file. Updating file_version and file_type fields in file.');
    fcs = load(sar_fn);
    fcs = rmfield(fcs,'version');
    fcs.file_version = '1';
    fcs.file_type = 'sar_coord';
    ct_save(sar_fn,'-struct','fcs');
  end
  sar_fields = {'Lsar','gps_source','gps_time_offset','type','sigma_x','presums','file_version','file_type','along_track'};
  fcs = load(sar_fn,sar_fields{:});
  for sar_field = sar_fields
    if ~isfield(fcs,sar_field{1})
      error('SAR coordinates file missing %s field. Either delete file or correct file and then rerun.', sar_field{1});
    end
  end
end
Lsar = c/wfs(1).fc*(param.sar.Lsar.agl+param.sar.Lsar.thick/sqrt(er_ice))/(2*param.sar.sigma_x);
if ~exist(sar_fn,'file') ...
    || fcs.Lsar ~= Lsar ...
    || ~strcmpi(fcs.gps_source,records.gps_source) ...
    || any(fcs.gps_time_offset ~= records.param_records.records.gps.time_offset) ...
    || fcs.type ~= param.sar.mocomp.type ...
    || fcs.sigma_x ~= param.sar.sigma_x ...
    || fcs.presums ~= param.sar.presums ...
    || fcs.file_version(1) ~= '1'
  %% SAR coordinates file does not exist or needs to be recreated
  
  ctrl = cluster_new_batch(param);
  
  if any(strcmpi(radar_name,{'acords','hfrds','hfrds2','mcords','mcords2','mcords3','mcords4','mcords5','mcords6','mcrds','rds','seaice','accum2','accum3'}))
    cpu_time_mult = 2e-3;
    mem_mult = 5;
    
  elseif any(strcmpi(radar_name,{'snow','kuband','snow2','kuband2','snow3','kuband3','kaband','kaband3','snow5','snow8'}))
    cpu_time_mult = 2e-3;
    mem_mult = 5;
  end
  
  sparam = [];
  sparam.argsin{1} = param; % Static parameters
  sparam.task_function = 'sar_coord_task';
  sparam.num_args_out = 1;
  Nx = numel(records.gps_time);
  sparam.cpu_time = 60 + Nx*cpu_time_mult;
  records_var = whos('records');
  sparam.mem = 250e6 + records_var.bytes*mem_mult;
  sparam.notes = sprintf('%s %s:%s:%s %s', ...
    sparam.task_function, param.sar.out_path, param.radar_name, param.season_name, param.day_seg);
    
  % Create success condition
  success_error = 64;
  sparam.success = ...
    sprintf('error_mask = bitor(error_mask,%d*~exist(''%s'',''file''));\n', success_error, sar_fn);
  if ~ctrl.cluster.rerun_only && exist(sar_fn,'file')
    delete(sar_fn);
  end
  
  ctrl = cluster_new_task(ctrl,sparam,[]);
  
  ctrl_chain{end+1} = ctrl;

else
  %% SAR coordinates file exists and only needs surface updated
  surf_idxs = get_equal_alongtrack_spacing_idxs(fcs.along_track,param.sar.sigma_x);
  if surf_idxs(end) ~= length(fcs.along_track)
    if fcs.along_track(end) == fcs.along_track(surf_idxs(end))
      % Overwrite last index if it is in the same location as the last
      % record. This happens if the platform is stationary at the end.
      surf_idxs(end) = length(fcs.along_track);
    else
      % Normally, the last record is a little further along than the last
      % surf_idxs and so we append the last record to the end
      surf_idxs(end+1) = length(fcs.along_track);
    end
  end
  
  frame_length = round(param.sar.surf_filt_dist / median(diff(fcs.along_track(surf_idxs)))/2)*2+1;
  if length(surf_idxs) <= 3
    % Handle too short segment
    error('This data is too short in along-track length (possibly stationary data) to be SAR processed.');
  elseif length(surf_idxs) < frame_length
    % Handle very short segment
    if mod(length(surf_idxs),2) == 0
      % Even length(surf_idxs), but sgolayfilt filter must be odd length
      surf = sgolayfilt(records.surface(surf_idxs),3,length(surf_idxs)-1);
    else
      surf = sgolayfilt(records.surface(surf_idxs),3,length(surf_idxs));
    end
  else
    % Handle normal segment
    surf = sgolayfilt(records.surface(surf_idxs),3,frame_length);
  end
  fcs.surf_pp = spline(fcs.along_track(surf_idxs),surf);
  
  fprintf('  Exists. Updating with current surface values from param.sar.surf_layer.\n');
  save(sar_fn,'-append','-struct','fcs','surf_pp');
end

%% Create imgs_list
% =====================================================================
% Create imgs_list which divides up imgs into several imgs in a data IO
% efficient way so that all SAR images from a particular data stream are
% done together. The assumption is that each board_idx represents a single
% data stream.
%
% imgs_list: cell array of new broken apart imgs
%  imgs_list{imgs_idx}: cell array of wf-adc pair lists PER task
%   imgs_list{imgs_idx}{task}: array of wf-adc pairs to be processed by a task
imgs_list = {};
if param.sar.combine_rx
  % One SAR image with all wf-adc pairs
  for img = 1:length(param.sar.imgs)
    imgs_list{1}{img} = param.sar.imgs{img};
  end
  
else
  if strcmpi(param.sar.wf_adc_pair_task_group_method,'one')
    % One SAR image task per wf-adc pair. This requires the least memory
    % but requires more file IO for systems that have multiple wf-adc pairs
    % in a single ADC board.
    for img = 1:length(param.sar.imgs)
      for wf_adc = 1:length(param.sar.imgs{img})
        imgs_list{end+1}{1}(1,:) = param.sar.imgs{img}(wf_adc,:);
      end
    end
    
  else
    % Handles:
    %  strcmpi(param.sar.wf_adc_pair_task_group_method,'board')
    %    All SAR images for a single ADC board are put into one task. A
    %    single ADC board implies a single data file which contains data
    %    streams for one or more wf-adc pairs. By processing all the wf-adc
    %    pairs together, this reduces file IO but does take more memory.
    %  strcmpi(param.sar.wf_adc_pair_task_group_method,'img')
    %    All SAR images for a single ADC board/image pair are processed in
    %    one task. This breaks up the wf-adc pairs from each board into
    %    images. This requires extra file-IO, but makes the images within a
    %    task all use the same amount of memory.
    
    % Divide images up into boards
    for img = 1:length(param.sar.imgs)
      for wf_adc = 1:size(param.sar.imgs{img},1)
        wf = param.sar.imgs{img}(wf_adc,1);
        adc = param.sar.imgs{img}(wf_adc,2);
        [board,board_idx,~] = wf_adc_to_board(param,[wf adc]);
        
        if length(imgs_list) < board_idx
          imgs_list{board_idx} = {};
        end
        if length(imgs_list{board_idx}) < img
          imgs_list{board_idx}{img} = [];
        end
        imgs_list{board_idx}{img}(end+1,:) = param.sar.imgs{img}(wf_adc,:);
      end
    end
    % Remove empty imgs
    mask = ~cellfun(@isempty,imgs_list);
    imgs_list = imgs_list(mask);
    for imgs_list_idx = 1:length(imgs_list)
      mask = ~cellfun(@isempty,imgs_list{imgs_list_idx});
      imgs_list{imgs_list_idx} = imgs_list{imgs_list_idx}(mask);
    end
    
    if strcmpi(param.sar.wf_adc_pair_task_group_method,'img')
      % All SAR images from the same image per task, but also breaks at
      % board boundaries.
      
      % Break each imgs_list into a single image
      new_imgs_list = {};
      for imgs_list_idx = 1:length(imgs_list)
        for img = 1:length(imgs_list{imgs_list_idx})
          new_imgs_list{end+1}{1} = imgs_list{imgs_list_idx}{img};
        end
      end
      imgs_list = new_imgs_list;
      clear new_imgs_list;
    end
  end
end

%% Create and Setup the cluster batch
% =====================================================================
ctrl = cluster_new_batch(param);
cluster_compile({'sar_task.m','sar_coord_task'},ctrl.cluster.hidden_depend_funs,ctrl.cluster.force_compile,ctrl);

total_raw_num_sam = {};
total_pc_num_sam = {};
if any(strcmpi(radar_name,{'acords','hfrds','hfrds2','mcords','mcords2','mcords3','mcords4','mcords5','mcords6','mcrds','rds','seaice','accum2','accum3'}))
  for imgs_idx = 1:length(imgs_list)
    for img = 1:length(imgs_list{imgs_idx})
      wf = abs(imgs_list{imgs_idx}{img}(1,1));
      total_raw_num_sam{imgs_idx}{img} = wfs(wf).Nt_raw;
    end
  end
  for imgs_idx = 1:length(imgs_list)
    for img = 1:length(imgs_list{imgs_idx})
      wf = abs(imgs_list{imgs_idx}{img}(1,1));
      total_pc_num_sam{imgs_idx}{img} = wfs(wf).Nt;
    end
  end
  cpu_time_mult = 65e-10;
  mem_mult = [1.3 1.3];
  
elseif any(strcmpi(radar_name,{'snow','kuband','snow2','kuband2','snow3','kuband3','kaband','kaband3','snow5','snow8'}))
  for imgs_idx = 1:length(imgs_list)
    for img = 1:length(imgs_list{imgs_idx})
      wf = abs(imgs_list{imgs_idx}{img}(1,1));
      total_raw_num_sam{imgs_idx}{img} = 32000;
    end
  end
  for imgs_idx = 1:length(imgs_list)
    for img = 1:length(imgs_list{imgs_idx})
      wf = abs(imgs_list{imgs_idx}{img}(1,1));
      total_pc_num_sam{imgs_idx}{img} = 32000;
    end
  end
  cpu_time_mult = 8e-8;
  mem_mult = [64 64];
  
else
  error('radar_name %s not supported yet.', radar_name);
  
end

%% Setup tasks to SAR process each frame
% =====================================================================
retry_fields = {};
sparam.argsin{1} = param; % Static parameters
sparam.task_function = 'sar_task';
sparam.num_args_out = 1;
for frm_idx = 1:length(param.cmd.frms)
  frm = param.cmd.frms(frm_idx);
  if ct_proc_frame(frames.proc_mode(frm),param.sar.frm_types)
    fprintf('%s %s_%03i (%i of %i) (%s)\n', sparam.task_function, param.day_seg, frm, frm_idx, length(param.cmd.frms), datestr(now));
  else
    fprintf('Skipping frame %s_%03i (no process frame)\n', param.day_seg, frm);
    continue;
  end

  % Current frame goes from the start record specified in the frames file
  % to the record just before the start record of the next frame.  For
  % the last frame, the stop record is just the last record in the segment.
  start_rec = ceil(frames.frame_idxs(frm)/param.sar.presums);
  if frm < length(frames.frame_idxs)
    stop_rec = ceil((frames.frame_idxs(frm+1)-1)/param.sar.presums);
  else
    stop_rec = length(records.gps_time);
  end
  
  % Determine length of the frame
  frm_dist = along_track_approx(stop_rec) - along_track_approx(start_rec);
  dx_approx = median(diff(along_track_approx(good_recs)));
  
  % Determine number of chunks and range lines per chunk
  num_chunks = round(frm_dist / param.sar.chunk_len);
  if num_chunks == 0
    warning('Frame %d length (%g m) is smaller than the param.sar.chunk_len (%g m), there could be problems. Consider making the chunk length smaller for this frame. Possibly the frame is too small and should be combined with a neighboring frame.', frm_dist, param.sar.chunk_len);
    num_chunks = 1;
  end
  
  % Estimate number of input range lines per chunk
  num_rlines_per_chunk = round((stop_rec-start_rec) / num_chunks);
  
  cur_rec = start_rec;
  for chunk_idx = 1:num_chunks
    % Setup dynamic params
    % =====================================================================
    dparam.argsin{1}.load.frm = frm;
    dparam.argsin{1}.load.chunk_idx = chunk_idx;
    dparam.argsin{1}.load.num_chunks = num_chunks;
    if chunk_idx == num_chunks
      dparam.argsin{1}.load.recs = [start_rec + num_rlines_per_chunk*(chunk_idx-1), stop_rec];
    else
      dparam.argsin{1}.load.recs = start_rec + num_rlines_per_chunk*(chunk_idx-1) + [0, num_rlines_per_chunk-1];
    end
    if chunk_idx == num_chunks
      dparam.argsin{1}.load.recs = [cur_rec, stop_rec];
    else
      dparam.argsin{1}.load.recs = cur_rec-1+[find(along_track_approx(cur_rec:end)-along_track_approx(start_rec) >= (chunk_idx-1)*param.sar.chunk_len,1), ...
        find(along_track_approx(cur_rec:end)-along_track_approx(start_rec) < chunk_idx*param.sar.chunk_len,1,'last')];
    end
    dparam.argsin{1}.load.recs
    cur_rec = dparam.argsin{1}.load.recs(2)+1;
    
    for imgs_idx = 1:length(imgs_list)
      if isempty(imgs_list{imgs_idx})
        continue;
      end
      dparam.argsin{1}.load.imgs = imgs_list{imgs_idx};
      sub_band_idx = 1;
      dparam.argsin{1}.load.sub_band_idx = sub_band_idx;
    
      % Create a list of waveform/adc pairs for displaying to the string.
      wf_adc_str = '';
      for img = 1:length(dparam.argsin{1}.load.imgs)
        for wf_adc = 1:size(dparam.argsin{1}.load.imgs{img},1)
          wf = abs(dparam.argsin{1}.load.imgs{img}(wf_adc,1));
          adc = abs(dparam.argsin{1}.load.imgs{img}(wf_adc,2));
          if isempty(wf_adc_str)
            wf_adc_str = [wf_adc_str sprintf('wf,adc: %d,%d',wf,adc)];
          else
            wf_adc_str = [wf_adc_str sprintf(' %d,%d',wf,adc)];
          end
        end
      end
      
      % Estimate chunk overlap to help decide memory and cpu times
      % =================================================================
      % Determine overlap of chunks from the range to furthest target
      
      chunk_overlap_est = [];
      for img = 1:length(dparam.argsin{1}.load.imgs)
        if strcmp(radar_type,'deramp')
          if ~isfinite(param.sar.time_of_full_support)
            error('param.sar.time_of_full_support must be finite for deramp radars.');
          end
          max_time = param.sar.time_of_full_support;
        else
          max_time = min(wfs(wf).time(end),param.sar.time_of_full_support);
        end
        % wavelength (m)
        wf = param.sar.imgs{img}(1,1);
        lambda = c/wfs(wf).fc;
        % twtt to surface (sec)
        surf_time = min(max_time,min(records.surface));
        % effective in air max range (m)
        max_range = ((max_time-surf_time)/sqrt(param.sar.start_eps) + surf_time) * c/2;
        % chunk overlap (m)
        chunk_overlap_est(img) = round((max_range*lambda)/(2*param.sar.sigma_x) / 2);
        % chunk_overlap_est(img) = max_range/sqrt((2*param.sar.sigma_x/lambda)^2-1);
      end
      
      % Create success condition
      % =================================================================
      dparam.file_success = {};
      for subap = 1:length(param.sar.sub_aperture_steering)
        out_fn_dir = fullfile(sar_out_dir, ...
          sprintf('%s_data_%03d_%02d_%02d',param.sar.sar_type,frm, ...
          subap, sub_band_idx));
        for img = 1:length(dparam.argsin{1}.load.imgs)
          if param.sar.combine_rx
            out_fn = fullfile(out_fn_dir,sprintf('img_%02d_chk_%03d.mat',img,chunk_idx));
            
            dparam.file_success{end+1} = out_fn;
            if ~ctrl.cluster.rerun_only && exist(out_fn,'file')
              delete(out_fn);
            end
          else
            for wf_adc = 1:size(dparam.argsin{1}.load.imgs{img},1)
              wf  = abs(dparam.argsin{1}.load.imgs{img}(wf_adc,1));
              adc = abs(dparam.argsin{1}.load.imgs{img}(wf_adc,2));
              out_fn = fullfile(out_fn_dir,sprintf('wf_%02d_adc_%02d_chk_%03d.mat',wf,adc,chunk_idx));
              
              dparam.file_success{end+1} = out_fn;
              if ~ctrl.cluster.rerun_only && exist(out_fn,'file')
                delete(out_fn);
              end
            end
          end
        end
      end
      
      % Rerun only mode: Test to see if we need to run this task
      % =================================================================
      dparam.notes = sprintf('%s %s:%s:%s %s_%03d (%d of %d)/%d of %d %s %.0f to %.0f recs', ...
        sparam.task_function, param.sar.out_path, param.radar_name, param.season_name, param.day_seg, frm, frm_idx, length(param.cmd.frms), ...
        chunk_idx, num_chunks, wf_adc_str, (dparam.argsin{1}.load.recs(1)-1)*param.sar.presums+1, ...
        dparam.argsin{1}.load.recs(2)*param.sar.presums);
      if ctrl.cluster.rerun_only
        % If we are in rerun only mode AND the sar task file success
        % condition passes without error, then we do not run the task.
        if ~cluster_file_success(dparam.file_success)
          fprintf('  Already exists [rerun_only skipping]: %s (%s)\n', ...
            dparam.notes, datestr(now));
          continue;
        end
      end
      
      % Create task
      % =================================================================
      
      % CPU Time and Memory estimates:
      %  1. Raw data for all images stored (gets replaced during pulse
      %     compression)
      %  2. Pulse compressed data for all images (gets replaced during
      %     motion compensation IF there is a single wf-adc pair, otherwise it
      %     must be stored in memory the whole time)
      %  3. Motion compensated data 
      %  Nx*total_num_sam*mem_mult where K is some manually determined multiplier.
      dparam.cpu_time = 60;
      mem_raw = [];
      mem_pulse_compress = [];
      for img = 1:length(dparam.argsin{1}.load.imgs)
        Nx = diff(dparam.argsin{1}.load.recs) + 2*chunk_overlap_est(img)/dx_approx;
        if strcmpi(param.sar.sar_type,'fk')
          
          dparam.cpu_time = dparam.cpu_time + 10 + Nx*log2(Nx)*total_pc_num_sam{imgs_idx}{img} ...
            *(10+2*log2(total_pc_num_sam{imgs_idx}{img}))*size(dparam.argsin{1}.load.imgs{img},1)^1.6*cpu_time_mult;
          
          % Raw Data and Pulse Compression Memory Requirements:
          
          % Nx: Number of along-track samples
          % total_raw_num_sam{imgs_idx}{img}: Number of fast-time raw samples
          % size(dparam.argsin{1}.load.imgs{img},1): Number of wf-adc pair data streams to load
          % 4: size of a complex number
          % (1+wfs(wf).complex): accounts for complex data
          % 2x: To hold two copies of the data during matrix operations
          mem_raw(img) = Nx*total_raw_num_sam{imgs_idx}{img}*size(dparam.argsin{1}.load.imgs{img},1)*4*(1+wfs(wf).complex)*2;
          
          % total_pc_num_sam{imgs_idx}{img}: Number of fast-time pulse compressed samples
          % size(dparam.argsin{1}.load.imgs{img},1): Number of wf-adc pair data streams to load
          % 8: size of a complex single
          % 2: To hold two copies of the data during matrix operations
          % (+1): If coherent noise enabled
          mem_pulse_compress(img) = Nx*total_pc_num_sam{imgs_idx}{img}*size(dparam.argsin{1}.load.imgs{img},1)*8*2;
          if strcmpi(wfs(wf).coh_noise_method,'analysis')
            mem_pulse_compress(img) = 2*mem_pulse_compress(img);
          end
          
          % Only one channel is SAR processed at a time 
          mem_sar = Nx*total_pc_num_sam{imgs_idx}{img}*8*2;

          % Pulse compressed data overwritten during SAR processing when
          % there is only one wf-adc channel in the image
          if size(dparam.argsin{1}.load.imgs{img},1) == 1
            mem_pulse_compress(img) = max(mem_pulse_compress(img),mem_sar);
          else
            mem_pulse_compress(img) = mem_pulse_compress(img) + mem_sar;
          end
        elseif strcmpi(param.sar.sar_type,'tdbp')
          dparam.cpu_time = ctrl.cluster.max_time_per_job - 40;
        end
      end
      dparam.mem = 1e9 + sum(max(mem_raw,mem_pulse_compress));
      
      if dparam.mem > ctrl.cluster.max_mem_per_job
        if strcmpi(param.sar.wf_adc_pair_task_group_method,'board')
          error('Task is requiring too much memory. Adjust ctrl.cluster.max_mem_per_job or use param.sar.wf_adc_pair_task_group_method = ''img'' or ''one'' to reduce memory usage.');
        elseif strcmpi(param.sar.wf_adc_pair_task_group_method,'one')
          error('Task is requiring too much memory. Adjust ctrl.cluster.max_mem_per_job, decrease the chunk size, or increase cluster.max_mem_per_job.');
        end
        warning('Task is requiring too much memory. Consider adjusting ctrl.cluster.max_mem_per_job. Converting this task to param.sar.wf_adc_pair_task_group_method = ''one''.');
        for wf_adc = 1:size(dparam.argsin{1}.load.imgs{1},1)
          tmp_dparam = dparam;
          tmp_dparam.argsin{1}.load.imgs = {dparam.argsin{1}.load.imgs{1}(wf_adc,:)};
          wf = tmp_dparam.argsin{1}.load.imgs{1}(1,1);
          adc = tmp_dparam.argsin{1}.load.imgs{1}(1,2);
          wf_adc_str = sprintf('%d,%d', wf, adc);
          tmp_dparam.notes = sprintf('%s %s:%s:%s %s_%03d (%d of %d)/%d of %d %s %.0f to %.0f recs', ...
            sparam.task_function, param.sar.out_path, param.radar_name, param.season_name, param.day_seg, frm, frm_idx, length(param.cmd.frms), ...
            chunk_idx, num_chunks, wf_adc_str, (dparam.argsin{1}.load.recs(1)-1)*param.sar.presums+1, ...
            dparam.argsin{1}.load.recs(2)*param.sar.presums);
          
          tmp_dparam.cpu_time = 0;
          tmp_dparam.mem = 400e6;
          mem_biggest = 0;
          for img = 1:length(tmp_dparam.argsin{1}.load.imgs)
            Nx = diff(tmp_dparam.argsin{1}.load.recs) + 2*chunk_overlap_est(img)/dx_approx;
            if strcmpi(param.sar.sar_type,'fk')
              tmp_dparam.cpu_time = tmp_dparam.cpu_time + 10 + Nx*log2(Nx)*total_pc_num_sam{imgs_idx}{img} ...
                *(10+2*log2(total_pc_num_sam{imgs_idx}{img}))*size(tmp_dparam.argsin{1}.load.imgs{img},1)^1.6*cpu_time_mult;
              % Raw Data and Pulse Compression Memory Requirements:
              mem_biggest = max(mem_biggest,Nx*total_pc_num_sam{imgs_idx}{img}*16);
              mem_pulse_compress = Nx*total_pc_num_sam{imgs_idx}{img}*size(tmp_dparam.argsin{1}.load.imgs{img},1)*8*mem_mult(1);
              % SAR Memory Requirements:
              % NOTE: Need to consider number of SAR subapertures, length(param.sar.sub_aperture_steering)
              mem_sar = 0;
              tmp_dparam.mem = tmp_dparam.mem + max(mem_pulse_compress);
            elseif strcmpi(param.sar.sar_type,'tdbp')
              tmp_dparam.cpu_time = ctrl.cluster.max_time_per_job - 40;
            end
          end
          % Two copies of 256 MB file or Double, two copies, divided into 8 blocks
          tmp_dparam.mem = tmp_dparam.mem + max(1e9/2,2*2*mem_biggest/8)*mem_mult(2);
          
      
          tmp_dparam.file_success = {};
          for subap = 1:length(param.sar.sub_aperture_steering)
            out_fn_dir = fullfile(sar_out_dir, ...
              sprintf('%s_data_%03d_%02d_%02d',param.sar.sar_type,frm, ...
              subap, sub_band_idx));
            for img = 1:length(tmp_dparam.argsin{1}.load.imgs)
              if param.sar.combine_rx
                out_fn = fullfile(out_fn_dir,sprintf('img_%02d_chk_%03d.mat',img,chunk_idx));
                
                tmp_dparam.file_success{end+1} = out_fn;
              else
                for wf_adc = 1:size(tmp_dparam.argsin{1}.load.imgs{img},1)
                  wf  = abs(tmp_dparam.argsin{1}.load.imgs{img}(wf_adc,1));
                  adc = abs(tmp_dparam.argsin{1}.load.imgs{img}(wf_adc,2));
                  out_fn = fullfile(out_fn_dir,sprintf('wf_%02d_adc_%02d_chk_%03d.mat',wf,adc,chunk_idx));
                  
                  tmp_dparam.file_success{end+1} = out_fn;
                end
              end
            end
          end
          
          ctrl = cluster_new_task(ctrl,sparam,tmp_dparam,'dparam_save',0);
        end
      else
        ctrl = cluster_new_task(ctrl,sparam,dparam,'dparam_save',0);
      end
    end
  end
end

ctrl = cluster_save_dparam(ctrl);

ctrl_chain{end+1} = ctrl;

fprintf('Done %s\n', datestr(now));

return;

