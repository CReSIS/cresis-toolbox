function ctrl_chain = qlook(param,param_override)
% ctrl_chain = qlook(param,param_override)
%
% This function generates quick look outputs (CSARP_qlook), tracks the
% surface, and (optionally) stores the surface to a layer data destination
% (default is layerData).
%
% param: struct with processing parameters
%
% param_override: parameters in this struct will override parameters in
% param.  This struct must also contain the gRadar fields. Typically global
% gRadar; param_override = gRadar;
%
% Example:
%  See run_qlook.m for how to run this function directly.
%  Normally this function is called from master.m using the param spreadsheet.
%
% Authors: John Paden
%
% See also: run_master.m, master.m, run_qlook.m, qlook.m,
%   qlook_task.m

%% General Setup
% =====================================================================
if exist('param_override','var') 
  param = merge_structs(param, param_override);
end

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

% Get the standard radar name and radar type
[~,radar_type,radar_name] = ct_output_dir(param.radar_name);

%% Input Checks: cmd
% =====================================================================

% Remove frames that do not exist from param.cmd.frms list
frames = frames_load(param);
param.cmd.frms = frames_param_cmd_frms(param,frames);

%% Input Checks: records
% =====================================================================

if ~isfield(param.records,'gps') || isempty(param.records.gps)
  param.records.gps = [];
end
if ~isfield(param.records.gps,'en') || isempty(param.records.gps.en)
  % Assume that GPS synchronization is enabled
  param.records.gps.en = true;
end

%% Input Checks: qlook
% =====================================================================

if ~isfield(param.qlook,'bit_mask') || isempty(param.qlook.bit_mask)
  % Remove bad records (bit_mask==1), leave stationary records
  % (bit_mask==2), and remove bad records (bit_mask==4)
  param.qlook.bit_mask = 1 + 4;
end

if ~isfield(param.qlook,'block_size') || isempty(param.qlook.block_size)
  error('param.qlook.block_size must be specified. This is the number of range lines or records to process at a time.');
end

% Decimation (dec, B_filter) input check
if ~isfield(param.qlook,'dec') || isempty(param.qlook.dec)
  param.qlook.dec = 1;
end
if ~isfield(param.qlook,'B_filter') || isempty(param.qlook.B_filter)
  if param.qlook.dec == 1
    param.qlook.B_filter = 1;
  else
    param.qlook.B_filter = hanning(2*param.qlook.dec+1);
  end
end
if ~mod(length(param.qlook.B_filter),2)
  error('param.qlook.B_filter must be odd length.');
end
param.qlook.B_filter = param.qlook.B_filter(:).'; % Must be row vector
if abs(sum(param.qlook.B_filter)-1) > 1e4*eps % Ensure filter weights sum to 1 to preserve radiometry
  param.qlook.B_filter = param.qlook.B_filter / sum(param.qlook.B_filter);
end

if ~isfield(param.qlook,'frm_types') || isempty(param.qlook.frm_types)
  param.qlook.frm_types = {-1,-1,-1,-1,-1};
end

if ~isfield(param.qlook,'imgs') || isempty(param.qlook.imgs)
  param.qlook.imgs = {[1 1]};
end

if ~isfield(param.qlook,'img_comb') || isempty(param.qlook.img_comb)
  param.qlook.img_comb = [];
end

% Check img_comb length
if ~isempty(param.qlook.img_comb) && length(param.qlook.img_comb) ~= 3*(length(param.qlook.imgs)-1)
  error('param.qlook.img_comb not the right length. Since it is not empty, there should be 3 entries for each image combination interface ([Tpd second image for surface saturation, -inf for second image blank, Tpd first image to avoid roll off] is typical).');
end

param = img_combine_input_check(param,'qlook');

% Incoherent decimation (inc_dec, inc_B_filter) input check
% Setting inc_dec = 0: returns coherent data
% Setting inc_dec = 1: returns power detected data with no decimation
% Setting inc_dec > 1: decimates at the rate specified by inc_dec
if ~isfield(param.qlook,'inc_dec') || isempty(param.qlook.inc_dec)
  param.qlook.inc_dec = 1;
end
if ~isfield(param.qlook,'inc_B_filter') || isempty(param.qlook.inc_B_filter)
  if param.qlook.inc_dec == 0 || param.qlook.inc_dec == 1
    param.qlook.inc_B_filter = 1;
  else
    param.qlook.inc_B_filter = hanning(2*param.qlook.inc_dec+1);
  end
end
if ~mod(length(param.qlook.inc_B_filter),2)
  error('param.qlook.inc_B_filter must be odd length.');
end
param.qlook.inc_B_filter = param.qlook.inc_B_filter(:).'; % Must be row vector
if abs(sum(param.qlook.inc_B_filter)-1) > 1e4*eps % Ensure filter weights sum to 1 to preserve radiometry
  param.qlook.inc_B_filter = param.qlook.inc_B_filter / sum(param.qlook.inc_B_filter);
end

if ~isfield(param.qlook,'motion_comp') || isempty(param.qlook.motion_comp)
  param.qlook.motion_comp = false;
end

if ~isfield(param.qlook,'out_path') || isempty(param.qlook.out_path)
  param.qlook.out_path = 'qlook';
end
[~,out_path_dir] = fileparts(param.qlook.out_path);

% nan_fir_dec: if true, function uses the slower nan_fir_dec function on
% the data instead of fir_dec for the dec and inc_dec functions. Default is
% true for deramp systems and false for non-deramp systems.
if ~isfield(param.qlook,'nan_dec') || isempty(param.qlook.nan_dec)
  if strcmpi(radar_type,'deramp')
    param.qlook.nan_dec = true;
  else
    param.qlook.nan_dec = false;
  end
end

if ~isfield(param.qlook,'nan_dec_normalize_threshold') || isempty(param.qlook.nan_dec_normalize_threshold)
  param.qlook.nan_dec_normalize_threshold = 2;
end

if ~isfield(param.qlook,'presums') || isempty(param.qlook.presums)
  param.qlook.presums = 1;
end

if ~isfield(param.qlook,'radiometric_corr_dB') || isempty(param.qlook.radiometric_corr_dB)
  param.qlook.radiometric_corr_dB = NaN;
end

if ~isfield(param.qlook,'resample') || isempty(param.qlook.resample)
  param.qlook.resample = [1 1; 1 1];
end
if numel(param.qlook.resample) == 2
  param.qlook.resample = [param.qlook.resample(1) param.qlook.resample(2); 1 1];
end

if ~isfield(param.qlook,'surf') || isempty(param.qlook.surf)
  param.qlook.surf.en = false;
end

if ~isfield(param.qlook,'surf_layer') || isempty(param.qlook.surf_layer)
  param.qlook.surf_layer.name = 'surface';
  param.qlook.surf_layer.source = 'layerData';
end
% Never check for the existence of layers
param.qlook.surf_layer.existence_check = false;

if ~isfield(param.qlook,'trim') || isempty(param.qlook.trim)
  param.qlook.trim = [0 0];
end

%% Setup Processing
% =====================================================================

% Load records file
records = records_load(param);

% Quick look radar echogram output directory
out_fn_dir = ct_filename_out(param, param.qlook.out_path);
tmp_out_fn_dir_dir = ct_filename_out(param, param.qlook.out_path,'qlook_tmp');

%% Collect waveform information into one structure
%  - This is used to break the frame up into chunks
% =====================================================================
[wfs,~] = data_load_wfs(setfield(param,'load',struct('imgs',{param.qlook.imgs})),records);
param.radar.wfs = merge_structs(param.radar.wfs,wfs);

%% Setup cluster
% =====================================================================
ctrl = cluster_new_batch(param);
cluster_compile({'qlook_task.m','qlook_combine_task.m'},ctrl.cluster.hidden_depend_funs,ctrl.cluster.force_compile,ctrl);

total_num_sam = [];
if any(strcmpi(radar_name,{'acords','hfrds','hfrds2','mcords','mcords2','mcords3','mcords4','mcords5','mcords6','mcrds','rds','seaice','accum2','accum3','accum'}))
  for img = 1:length(param.qlook.imgs)
    wf = abs(param.qlook.imgs{img}(1,1));
    total_num_sam(img) = wfs(wf).Nt_raw;
  end
  cpu_time_mult = 12e-8;
  mem_mult = 14;
  
elseif any(strcmpi(radar_name,{'snow','kuband','snow2','kuband2','snow3','kuband3','kaband','kaband3','snow5','snow8'}))
  total_num_sam = 32000 * ones(size(param.qlook.imgs));
  cpu_time_mult = 8e-8;
  mem_mult = 64;

elseif strcmpi(radar_name,'snow9')
  total_num_sam = 45000 * ones(size(param.qlook.imgs));
  cpu_time_mult = 8e-8;
  mem_mult = 64;
  
else
  error('radar_name %s not supported yet.', radar_name);
  
end

ctrl_chain = {};

%% Block: Create tasks
% =====================================================================
%
% For each frame load REC_BLOCK_SIZE records at a time (code groups
% by file index, but has to watch negative offset values which imply
% the record starts in a previous file and carries over into the next)
%    --> The last block can range from 0.5 to 1.5 * REC_BLOCK_SIZE
% =====================================================================
sparam.argsin{1} = param; % Static parameters
sparam.task_function = 'qlook_task';
sparam.num_args_out = 1;
sparam.argsin{1}.load.imgs = param.qlook.imgs;
for frm_idx = 1:length(param.cmd.frms)
  frm = param.cmd.frms(frm_idx);
  
  % Check proc_mode from frames file that contains this frames type and
  % make sure the user has specified to process this frame type
  if ct_proc_frame(frames.proc_mode(frm),param.qlook.frm_types)
    fprintf('%s %s_%03i (%i of %i) (%s)\n', sparam.task_function, param.day_seg, frm, frm_idx, length(param.cmd.frms), datestr(now));
  else
    fprintf('Skipping %s_%03i (no process frame)\n', param.day_seg, frm);
    continue;
  end
  
  % Create combine_file_success for this frame only which is used for
  % rerun_only==true checks
  if ctrl.cluster.rerun_only
    combine_file_success = {};
    if length(param.qlook.imgs) > 1
      for img = 1:length(param.qlook.imgs)
        out_fn = fullfile(out_fn_dir, sprintf('Data_img_%02d_%s_%03d.mat', ...
          img, param.day_seg, frm));
        combine_file_success{end+1} = out_fn;
      end
    end
    if length(param.qlook.imgs) == 1 || ~isempty(param.qlook.img_comb)
      % A combined file should be created
      out_fn = fullfile(out_fn_dir, sprintf('Data_%s_%03d.mat', ...
        param.day_seg, frm));
      combine_file_success{end+1} = out_fn;
    end
  end
  
  % Create output directory name
  sub_apt_shift_idx = 1;
  sub_band_idx = 1;
  tmp_out_fn_dir = fullfile(tmp_out_fn_dir_dir, ...
    sprintf('ql_data_%03d_%02d_%02d',frm,sub_apt_shift_idx,sub_band_idx));

  % recs: Determine the records for this frame
  if frm < length(frames.frame_idxs)
    recs = frames.frame_idxs(frm):frames.frame_idxs(frm+1)-1;
  else
    recs = frames.frame_idxs(frm):length(records.gps_time);
  end
  
  % Determine where breaks in processing blocks are going to occur
  %   Rename variables for readability
  block_size = param.qlook.block_size(1);
  blocks = 1:block_size:length(recs)-0.5*block_size;
  if isempty(blocks)
    warning('%s: The frame is smaller than usual. For best results, it is often best to have frames with a number of records that is more than or equal to half the block size (%d), but there are only %d records in this frame. If this is unexpected it may 1) be due to GPS errors since these can create artifically long paths over very short time periods; 2) the frame generation process needs to be revised with run_frames_create to make the frames longer; or 3) the param.qlook.block_size=%d needs to be reduced. qlook will try to process the frame, but it may fail.', mfilename, 0.5*block_size, length(recs), block_size);
    if length(recs) < 50
      warning('This frame is unusually short (<50 records). This is usually caused by a too short data segment (in which case it should be marked "do not process" in the param.cmd.notes field and not enabled) or an error in preprocessing, GPS, or records generation. Unless you know the frame is very short (e.g. lab calibration measurement where only a very small amount of data was needed), it is probably best to dbquit and fix the situation. Type "dbcont" to continue and ignore the issue. qlook processing may fail for this frame.');
      keyboard
    end
    blocks = 1;
  end
  
  % Create a cluster task for each block
  for block_idx = 1:length(blocks)
    
    % Determine the current records being processed
    % =================================================================
    if block_idx < length(blocks)
      cur_recs = [recs(blocks(block_idx)) recs(blocks(block_idx+1)-1)];
    else
      cur_recs = [recs(blocks(block_idx)) recs(end)];
    end
    
    % Fields required for manual submission to Slurm on Ollie
    if strcmp(param.cluster.type,'ollie')
      n_blocks(frm_idx) = length(blocks);
      dynamic_param.frms.(['frm',num2str(frm)]).frm_id = frm;
      dynamic_param.frms.(['frm',num2str(frm)]).blocks.(['block',num2str(block_idx)]).block_id = block_idx;
      dynamic_param.frms.(['frm',num2str(frm)]).blocks.(['block',num2str(block_idx)]).recs = cur_recs;
      dynamic_param.frms.(['frm',num2str(frm)]).blocks.(['block',num2str(block_idx)]).recs_keep = cur_recs;
      continue;
    end
    
    % Prepare task inputs
    % =================================================================
    dparam = [];
    dparam.argsin{1}.load.frm = frm;
    dparam.argsin{1}.load.recs = cur_recs;
    % Set the Nyquist zone field (FMCW radars)
    wf = 1;
    if isfield(frames,'nyquist_zone') && ~isnan(frames.nyquist_zone(frm))
      dparam.argsin{1}.radar.wfs(wf).nyquist_zone = frames.nyquist_zone(frm);
    end
    
    % Create success condition
    % =================================================================
    dparam.file_success = {};
    for img = 1:length(param.qlook.imgs)
      out_fn_name = sprintf('qlook_img_%02d_%d_%d.mat',img,cur_recs(1),cur_recs(end));
      out_fn = fullfile(tmp_out_fn_dir,out_fn_name);
      dparam.file_success{end+1} = out_fn;
      if ~ctrl.cluster.rerun_only && exist(out_fn,'file')
        delete(out_fn);
      end
    end
    
    % Rerun only mode: Test to see if we need to run this task
    % =================================================================
    dparam.notes = sprintf('%s:%s:%s:%s %s_%03d (%d of %d)/%d of %d recs %d-%d', ...
      sparam.task_function, param.radar_name, param.season_name, out_path_dir, param.day_seg, frm, frm_idx, length(param.cmd.frms), ...
      block_idx, length(blocks), cur_recs(1), cur_recs(end));
    if ctrl.cluster.rerun_only
      % If we are in rerun only mode AND the qlook task file success
      % condition passes without error (or the combined file passes),
      % then we do not run the task.
      if ~cluster_file_success(dparam.file_success) || ~cluster_file_success(combine_file_success)
        fprintf('  Already exists [rerun_only skipping]: %s (%s)\n', ...
          dparam.notes, datestr(now));
        continue;
      end
    end
    
    % Create task
    % =================================================================
    
    % CPU Time and Memory estimates:
    %  Nx*total_num_sam*K where K is some manually determined multiplier.
    Nx = cur_recs(end)-cur_recs(1)+1;
    dparam.cpu_time = 0;
    dparam.mem = 250e6;
    for img = 1:length(param.qlook.imgs)
      wf = abs(param.qlook.imgs{img}(1,1));
      adc = abs(param.qlook.imgs{img}(1,2));
      dparam.cpu_time = dparam.cpu_time + 10 + Nx*size(param.qlook.imgs{img},1)*total_num_sam(img)*log2(total_num_sam(img))*cpu_time_mult;
      data_pulse_compress_mult = 1;
      if isfield(param.radar.wfs(wf),'deconv') ...
          && isfield(param.radar.wfs(wf).deconv,'en') && any(param.radar.wfs(wf).deconv.en)
        data_pulse_compress_mult = data_pulse_compress_mult + 0.7;
      end
      if strcmpi(param.radar.wfs(wf).coh_noise_method,'analysis')
        data_pulse_compress_mult = data_pulse_compress_mult + 0.7;
      end
      dparam.mem = dparam.mem + Nx*size(param.qlook.imgs{img},1)*total_num_sam(img)*mem_mult*data_pulse_compress_mult;
    end
    
    ctrl = cluster_new_task(ctrl,sparam,dparam,'dparam_save',0);
  end
end

% Export jobs files for manual submission to Slurm on Ollie
if strcmp(param.cluster.type,'ollie')
  dynamic_param.day_seg = param.day_seg;
  static_param = sparam.argsin{1};
  dynamic_param_file_name = sprintf('%s/qlook_%s_dynamic_param.mat', param.slurm_jobs_path, param.day_seg);
  save(dynamic_param_file_name,'dynamic_param');
  fprintf('Writing %s\n',dynamic_param_file_name);
  
  static_param_file_name = sprintf('%s/qlook_%s_static_param.mat', param.slurm_jobs_path, param.day_seg);
  save(static_param_file_name,'static_param');
  fprintf('Writing %s\n',static_param_file_name);
  
  txt_file_name = sprintf('%s/qlook_%s_parameters.txt', param.slurm_jobs_path, dynamic_param.day_seg);
  fid = fopen(txt_file_name,'w');
  fprintf(fid,'%3s\t %5s\n','frm','break');
  frms = fieldnames(dynamic_param.frms);
  for frm_idx = 1:length(param.cmd.frms)
    blocks = fieldnames(dynamic_param.frms.(frms{frm_idx}).blocks);
    for block_idx = 1:n_blocks(frm_idx)
      params = [dynamic_param.frms.(frms{frm_idx}).frm_id, dynamic_param.frms.(frms{frm_idx}).blocks.(blocks{block_idx}).block_id];
      formatSpec = '%03d\t %03d\n';
      fprintf(fid,formatSpec,params);
    end
  end
  fclose(fid);
  fprintf('Writing %s\n',txt_file_name);
  fprintf('Run batch_qlook.sh and batch_qlook_2.sh\n');
  
  ctrl_chain = {};
  return;
end

ctrl = cluster_save_dparam(ctrl);

ctrl_chain{end+1} = ctrl;


%% Combine: Create combine task
% =====================================================================
ctrl = cluster_new_batch(param);
if param.qlook.surf.en && strcmpi(param.qlook.surf_layer.source,'records')
  % If surface is enabled and the surf_layer type is records, this should
  % not be done on the cluster.
  ctrl.cluster.type = 'debug';
end

if any(strcmpi(radar_name,{'acords','hfrds','hfrds2','mcords','mcords2','mcords3','mcords4','mcords5','mcords6','mcrds','rds','seaice','accum2','accum3','accum'}))
  cpu_time_mult = 12e-7;
  mem_mult = 24;
  
elseif any(strcmpi(radar_name,{'snow','kuband','snow2','kuband2','snow3','kuband3','kaband','kaband3','snow5','snow8'}))
  cpu_time_mult = 100e-8;
  mem_mult = 24;
end

sparam = [];
sparam.argsin{1} = param; % Static parameters
sparam.task_function = 'qlook_combine_task';
sparam.num_args_out = 1;
sparam.cpu_time = 60;
sparam.mem = 0;
fprintf('%s %s (%s)\n', sparam.task_function, param.day_seg, datestr(now));
% Add up all records being processed and find the most records in a frame
Nx = 0;
Nx_max = 0;
for frm = param.cmd.frms
  % recs: Determine the records for this frame
  if frm < length(frames.frame_idxs)
    Nx_frm = frames.frame_idxs(frm+1) - frames.frame_idxs(frm);
  else
    Nx_frm = length(records.gps_time) - frames.frame_idxs(frm) + 1;
  end
  if Nx_frm > Nx_max
    Nx_max = Nx_frm;
  end
  Nx = Nx + Nx_frm;
end
% Account for averaging
Nx_max = Nx_max / param.qlook.dec / max(1,param.qlook.inc_dec);
Nx = Nx / param.qlook.dec / max(1,param.qlook.inc_dec);

records_var = whos('records');
for img = 1:length(param.qlook.imgs)
  sparam.cpu_time = sparam.cpu_time + (Nx*total_num_sam(img)*cpu_time_mult);
  if isempty(param.qlook.img_comb)
    % Individual images, so need enough memory to hold the largest image
    sparam.mem = max(sparam.mem,350e6 + records_var.bytes + Nx_max*total_num_sam(img)*mem_mult);
  else
    % Images combined into one so need enough memory to hold all images
    sparam.mem = 350e6 + records_var.bytes + Nx*sum(total_num_sam)*mem_mult;
  end
end
if param.qlook.surf.en
  sparam.cpu_time = sparam.cpu_time + numel(records.gps_time)/5e6*120;
end
sparam.notes = sprintf('%s:%s:%s:%s %s', ...
  sparam.task_function, param.radar_name, param.season_name, out_path_dir, param.day_seg);

% Create success critera
sparam.file_success = {};
for frm = param.cmd.frms
  if length(param.qlook.imgs) > 1
    for img = 1:length(param.qlook.imgs)
      out_fn = fullfile(out_fn_dir, sprintf('Data_img_%02d_%s_%03d.mat', ...
        img, param.day_seg, frm));
      sparam.file_success{end+1} = out_fn;
      if ~ctrl.cluster.rerun_only
        % Mark file for deletion
        ct_file_lock_check(out_fn,3);
      end
    end
  end
  if length(param.qlook.imgs) == 1 || ~isempty(param.qlook.img_comb)
    % A combined file should be created
    out_fn = fullfile(out_fn_dir, sprintf('Data_%s_%03d.mat', ...
      param.day_seg, frm));
    sparam.file_success{end+1} = out_fn;
    if ~ctrl.cluster.rerun_only
      % Mark file for deletion
      ct_file_lock_check(out_fn,3);
    end
  end
  
end

ctrl = cluster_new_task(ctrl,sparam,[]);

ctrl_chain{end+1} = ctrl;
    
fprintf('Done %s\n', datestr(now));
