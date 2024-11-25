function slope_tracker(param,param_override)
% slope_tracker(param,param_override)
%
% This function does slope tracking (in along-track and cross-track) an
% produces an echogram output designed specifically for specular internal
% layers
%
% param = struct with processing parameters
%         -- OR --
%         function handle to script with processing parameters
% param_override = parameters in this struct will override parameters
%         in param.  This struct must also contain the gRadar fields.
%         Typically global gRadar; param_override = gRadar;
%
% Authors: John Paden
%
% See also: master.m, slope_tracker_task.m

fprintf('\n\n==============================================\n\n');

dbstack_info = dbstack;
if ~exist('param','var') || isempty(param) || length(dbstack_info) == 1
  % =====================================================================
  % Debug Setup
  % =====================================================================
  param = read_param_xls(ct_filename_param('rds_param_2011_Greenland_P3.xls'),'20110429_01','slope');
%   param = read_param_xls(ct_filename_param('rds_param_2011_Greenland_P3.xls'),'20110506_01','slope');
%   param = read_param_xls(ct_filename_param('rds_param_2013_Antarctica_P3.xls'),'20131127_01','slope');
  
  clear('param_override');
  param_override.sched.type = 'no scheduler';
  
  % Input checking
  if ~exist('param','var')
    error('A struct array of parameters must be passed in\n');
  end
  global gRadar;
  if exist('param_override','var')
    param_override = merge_structs(gRadar,param_override);
  else
    param_override = gRadar;
  end

elseif ~isstruct(param)
  % Functional form
  param();
end
param = merge_structs(param, param_override);

% =====================================================================
% Setup processing
% =====================================================================
fprintf('=====================================================================\n');
fprintf('Slope tracker %s (%s)\n', param.day_seg, datestr(now));
fprintf('=====================================================================\n');

physical_constants;

% Load frames file
frames = frames_load(param);
% Load records file
records = records_load(param);

global g_data;
g_data = [];

qlook_out_path = ct_filename_out(param, param.slope.qlook.out_path, 'CSARP_slope');

if isempty(param.cmd.frms)
  param.cmd.frms = 1:length(frames.frame_idxs);
end

if ~isfield(param.sched,'rerun_only') || isempty(param.sched.rerun_only)
  param.sched.rerun_only = false;
end

% Cleanup folders
if ~param.sched.rerun_only
  for frm = param.cmd.frms
    if exist(qlook_out_path,'dir')
      del_paths = get_filenames(qlook_out_path,sprintf('slope_data_%03d',frm),'','',struct('type','d'));
      for idx = 1:length(del_paths)
        fprintf('Removing path: %s\n', del_paths{idx});
        rmdir(del_paths{idx},'s');
      end
    end
  end
end

% =====================================================================
% Setup static inputs for slope_tracker_task
% =====================================================================
task_param = param;
task_param.load.imgs = param.slope.imgs;

% =====================================================================
% Setup the scheduler
% =====================================================================

if strcmpi(param.sched.type,'custom_torque')
  global ctrl; % Make this global for convenience in debugging
  ctrl = torque_new_batch(param);
  fprintf('Torque batch: %s\n', ctrl.batch_dir);
  torque_compile('slope_tracker_task.m',ctrl.sched.hidden_depend_funs,ctrl.sched.force_compile);
  
elseif ~strcmpi(param.sched.type,'no scheduler')
  fd = [get_filenames(param.path,'','','.m',struct('recursive',1)); ...
    get_filenames(param.path,'','','.mexa64',struct('recursive',1))];
  fd_override = [get_filenames(param.path_override,'','','.m',struct('recursive',1)); ...
    get_filenames(param.path_override,'','','.mexa64',struct('recursive',1))];
  
  fd = merge_filelists(fd, fd_override);

  % Remove SVN files from path
  non_svn_path = zeros(size(fd));
  for fn_idx = 1:length(fd)
    if isempty(strfind(fd{fn_idx},'.svn'))
      non_svn_path(fn_idx) = 1;
    end
  end
  fd = fd(non_svn_path);
  
  % Initialize submission ctrl structure
  global ctrl; % Make this global for convenience in debugging
  ctrl = [];
  ctrl.cmd = 'init';
  ctrl.sched = param.sched;
  ctrl.fd = fd;
  ctrl = create_task(ctrl);
  
  % Prepare submission ctrl structure for queing jobs
  ctrl.cmd = 'task';
end

if ~strcmpi(param.sched.type,'no scheduler')
  param.slope.surf.manual = 0; % Turn manual pick off
end

% =====================================================================
% Load data and run slope_tracker tasks
%
% For each frame load REC_BLOCK_SIZE records at a time (code groups
% by file index, but has to watch negative offset values which imply
% the record starts in a previous file and carries over into the next)
%    --> The last block can be up to 2*REC_BLOCK_SIZE
% =====================================================================
out_recs = {};
retry_fields = {};
for frame_idx = 1:length(param.cmd.frms);
  frame = param.cmd.frms(frame_idx);
  if frames.proc_mode(frame) ~= 2
    fprintf('slope_tracker frame %s_%03i (%i of %i) %s\n', param.day_seg, frame, frame_idx, length(param.cmd.frms), datestr(now));
  else
    fprintf('Skipping frame %d (no process frame)\n', frame);
    continue;
  end
  
  if param.slope.qlook.en
    ql_path = fullfile(qlook_out_path, sprintf('ql_data_%03d_01_01',frame));
    % Create the array_proc output directories
    if ~exist(ql_path,'dir')
      mkdir(ql_path);
    end
  end
  
  if frame < length(frames.frame_idxs)
    recs = frames.frame_idxs(frame):frames.frame_idxs(frame+1);
  else
    recs = frames.frame_idxs(frame):length(records.lat);
  end
  
  % Determine where breaks in processing are going to occur
  rec = recs(1);
  if isempty(param.slope.block_size)
    REC_BLOCK_SIZE = 10000;
  else
    if numel(param.slope.block_size) == 2
      REC_BLOCK_SIZE = param.slope.block_size(1);
      block_overlap = param.slope.block_size(2);
    else
      REC_BLOCK_SIZE = param.slope.block_size;
      block_overlap = 0;
    end
  end
  if length(recs) < 2*REC_BLOCK_SIZE
    breaks = 1;
  else
    breaks = 1:REC_BLOCK_SIZE:length(recs)-REC_BLOCK_SIZE;
  end
  
  task_param.proc.frm = frame;
  
  % Begin loading data
  for break_idx = 1:length(breaks)
    % Determine the current records being processed
    if break_idx < length(breaks)
      cur_recs_keep = [recs(breaks(break_idx)) recs(breaks(break_idx+1)-1)];
      cur_recs = [max(1,recs(breaks(break_idx))-block_overlap) ...
        recs(breaks(break_idx+1)-1)+block_overlap];
    else
      cur_recs_keep = [recs(breaks(break_idx)) recs(end)];
      cur_recs = [max(1,recs(breaks(break_idx))-block_overlap) recs(end)];
    end
    
    % =====================================================================
    % Prepare task inputs
    % =====================================================================
    task_param.load.recs = cur_recs;
    task_param.load.recs_keep = cur_recs_keep;
    
    % =================================================================
    % Rerun only mode: Test to see if we need to run this task
    if param.sched.rerun_only
      % If we are in rerun only mode AND all the get heights task output files
      % already exists, then we do not run the task
      file_exists = true;
      sub_apt_shift_idx = 1;
      sub_band_idx = 1;
      out_path = fullfile(ct_filename_out(param, ...
        param.slope.qlook.out_path, 'CSARP_slope'), ...
        sprintf('ql_data_%03d_%02d_%02d',frame, ...
        sub_apt_shift_idx, sub_band_idx));
      start_time_for_fn = records.gps_time(cur_recs(1));
      for imgs_list_idx = 1:length(param.slope.imgs)
        out_fn = sprintf('%s_img_%02d', ...
          datestr(epoch_to_datenum(start_time_for_fn),'yyyymmdd_HHMMSS'), ...
          imgs_list_idx);
        out_full_fn = fullfile(out_path,[out_fn '.mat']);
        lower_out_fn = sprintf('%s_img_%02d', ...
          datestr(epoch_to_datenum(start_time_for_fn-1),'yyyymmdd_HHMMSS'), ...
          imgs_list_idx);
        lower_out_full_fn = fullfile(out_path,[lower_out_fn '.mat']);
        upper_out_fn = sprintf('%s_img_%02d', ...
          datestr(epoch_to_datenum(start_time_for_fn+1),'yyyymmdd_HHMMSS'), ...
          imgs_list_idx);
        upper_out_full_fn = fullfile(out_path,[upper_out_fn '.mat']);
        if ~exist(out_full_fn,'file') && ~exist(lower_out_full_fn,'file') && ~exist(upper_out_full_fn,'file')
          file_exists = false;
        end
      end
      if file_exists
        fprintf('  %d: Already exists records %d to %d [rerun_only skipping] (%s)\n', ...
          break_idx, cur_recs(1), cur_recs(end), datestr(now));
        continue;
      end
    end
    
    % =================================================================
    % Execute tasks/jobs
    fh = @slope_tracker_task;
    if isfield(frames,'nyquist_zone') && ~isnan(frames.nyquist_zone(frame))
      task_param.radar.wfs(1).nyquist_zone = frames.nyquist_zone(frame);
    end
    arg{1} = task_param;

    if strcmp(param.sched.type,'custom_torque')
      create_task_param.conforming = true;
      create_task_param.notes = sprintf('%d/%d records %d-%d', ...
        frame, break_idx, cur_recs(1), cur_recs(end));
      ctrl = torque_create_task(ctrl,fh,1,arg,create_task_param);
      
    elseif ~strcmp(param.sched.type,'no scheduler')
      [ctrl,job_id,task_id] = create_task(ctrl,fh,1,arg);
      fprintf('  %d: Processing records %d to %d in job,task %d,%d (%s)\n', ...
        break_idx, cur_recs(1), cur_recs(end), job_id, task_id, datestr(now));
      retry_fields{job_id,task_id}.frm = frame;
      retry_fields{job_id,task_id}.break_idx = break_idx;
      retry_fields{job_id,task_id}.arg = arg;
      out_recs{end + 1} = cur_recs;
      retry_fields{job_id,task_id}.out_idx = length(out_recs);
    else
      fprintf('  %d: Processing records %d to %d (%s)\n', ...
        break_idx, cur_recs(1), cur_recs(end), datestr(now));
      [success] = fh(arg{1});
    end
    
  end
end

% =======================================================================
% Wait for jobs to complete if a scheduler was used
% =======================================================================
if strcmpi(param.sched.type,'custom_torque')
  % Wait until all submitted jobs to complete
  ctrl = torque_rerun(ctrl);
  if ~all(ctrl.error_mask == 0)
    if ctrl.sched.stop_on_fail
      torque_cleanup(ctrl);
      error('Not all jobs completed, but out of retries (%s)', datestr(now));
    else
      warning('Not all jobs completed, but out of retries (%s)', datestr(now));
      keyboard;
    end
  else
    fprintf('Jobs completed (%s)\n\n', datestr(now));
  end
  torque_cleanup(ctrl);
  
elseif ~strcmpi(param.sched.type,'no scheduler')
  % ======================================================================
  % Wait for jobs to finish and clean up
  ctrl.cmd = 'done';
  ctrl = create_task(ctrl);
  if ctrl.error_mask ~= 0 && ctrl.error_mask ~= 2
    % Quit if a bad error occurred
    fprintf('Bad errors occurred, quitting (%s)\n\n', datestr(now));
    if strcmp(ctrl.sched.type,'torque')
      fprintf('Often on the Torque scheduler, these are not bad errors\n');
      fprintf('because of system instabilities (e.g. file IO failure)\n');
      fprintf('and the task simply needs to be resubmitted. If this is the case,\n');
      fprintf('run "ctrl.error_mask = 2" and then run "dbcont".\n');
      keyboard
      if ctrl.error_mask ~= 0 && ctrl.error_mask ~= 2
        return;
      end
    else
      return
    end
  end
  
  % ======================================================================
  % Retry jobs that failed
  retry = 1;
  while ctrl.error_mask == 2 && retry <= param.sched.max_retries
    fprintf('Tasks failed, retry %d of max %d\n', retry, param.sched.max_retries);

    % Bookkeeping (move previous run information to "old_" variables)
    old_ctrl = ctrl;
    old_retry_fields = retry_fields;
    retry_fields = {};
    old_out_recs = out_recs;
    out_recs = {};
    
    % Initialize submission ctrl structure
    ctrl = [];
    ctrl.cmd = 'init';
    ctrl.sched = param.sched;
    ctrl.fd = fd;
    ctrl = create_task(ctrl);
    
    % Prepare submission ctrl structure for queing jobs
    ctrl.cmd = 'task';

    % Submit failed tasks, but keep track of these in case they fail again
    for job_idx = 1:length(old_ctrl.jobs)
      for task_idx = old_ctrl.jobs{job_idx}.error_idxs
        [ctrl,job_id,task_id] = create_task(ctrl,fh,2,old_retry_fields{job_idx,task_idx}.arg);
        out_idx = old_retry_fields{job_idx,task_idx}.out_idx;
        fprintf('  %d/%d: Processing records %d to %d in job,task %d,%d (%s)\n', ...
          old_retry_fields{job_idx,task_idx}.frm, old_retry_fields{job_idx,task_idx}.break_idx, ...
          old_out_recs{out_idx}(1), old_out_recs{out_idx}(end), ...
          job_id, task_id, datestr(now));
        retry_fields{job_id,task_id} = old_retry_fields{job_idx,task_idx};
        out_recs{end + 1} = old_out_recs{out_idx};
        retry_fields{job_id,task_id}.out_idx = length(out_recs);
      end
    end
    
    % Wait for tasks to complete and then cleanup
    ctrl.cmd = 'done';
    ctrl = create_task(ctrl);
    retry = retry + 1;
    
    if ctrl.error_mask ~= 0 && ctrl.error_mask ~= 2
      % Quit if a bad error occurred
      fprintf('Bad errors occurred, quitting (%s)\n\n', datestr(now));
      if strcmp(ctrl.sched.type,'torque')
        fprintf('Often on the Torque scheduler, these are not bad errors\n');
        fprintf('because of system instabilities (e.g. file IO failure)\n');
        fprintf('and the task simply needs to be resubmitted. If this is the case,\n');
        fprintf('run "ctrl.error_mask = 2" and then run "dbcont".\n');
        keyboard
        if ctrl.error_mask ~= 0 && ctrl.error_mask ~= 2
          return;
        end
      else
        return
      end
    end
  end
  if ctrl.error_mask ~= 0
    fprintf('Not all jobs completed, but out of retries (%s)\n', datestr(now));
    return;
  else
    fprintf('Jobs completed (%s)\n\n', datestr(now));
  end
end

if param.slope.qlook.en
  % Get all the directories in "input_path"
  list.in_path = get_filenames(qlook_out_path, '', '_data_', '', struct('type','d'));
  
  % Parse each directory name.
  for idx = 1:length(list.in_path)
    [tmp in_name] = fileparts(list.in_path{idx});
    
    % Indices:
    %   1: Start of PROC-TYPE-STRING
    %   tokenIdx1: End of PROC-TYPE-STRING
    %   tokenIdx2: Start of frame/index
    %   tokenIdx3: End of frame/index
    %   tokenIdx4: Start of SUBAPERTURE-STRING
    tokenIdx1 = regexp(in_name,'_data_\d+');
    tokenIdx1 = tokenIdx1 - 1;
    tokenIdx2 = tokenIdx1 + 7;
    tokenIdx3 = regexp(in_name(tokenIdx2:end),'_');
    if isempty(tokenIdx3)
      tokenIdx3 = length(in_name);
      tokenIdx4 = [];
    else
      % There is a subaperture
      tokenIdx3 = tokenIdx2 - 1 + tokenIdx3(1);
      tokenIdx3 = tokenIdx3 - 1;
      tokenIdx4 = tokenIdx3 + 2;
      tokenIdx5 = tokenIdx4 + 3;
    end
    
    list.procType{idx} = in_name(1:tokenIdx1);
    
    list.frmInd(idx) = str2double(in_name(tokenIdx2:tokenIdx3));
    
    list.subAperture(idx) = str2double(in_name(tokenIdx4:end));
    
  end
  % Get a sorted list of the unique frames
  [frmList fileInds] = sort(list.frmInd);
  
  % Create the output directory
  if ~exist(qlook_out_path,'dir')
    mkdir(qlook_out_path);
  end
  
  % =====================================================================
  % Loop through all the directories and combine
  % =====================================================================
  for fileInd = fileInds(1:end)

    [tmp ql_dir] = fileparts(list.in_path{fileInd});
    in_path = list.in_path{fileInd};
    
    % Check to see if this frame should be processed/combined
    if ~isempty(param.cmd.frms) && ~any(str2double(ql_dir(9:11)) == param.cmd.frms)
      continue;
    end

    if param.debug_level >= 1
      [tmp in_name] = fileparts(list.in_path{fileInd});
      fprintf('\nCombining %s (%s)\n', in_name, datestr(now));
    end
    
    if strcmpi(list.procType(fileInds(1)),'pc')
      fprintf('  Skipping pulse compressed data\n');
      continue;
    end
        
    Surface = [];
    % =====================================================================
    % Concatenate all the ql block outputs from slope_tracker_task
    for img_idx = 1:length(param.slope.imgs)
      
      filenames = get_filenames(in_path,'','',sprintf('img_%02d.mat', img_idx));

      Time = [];
      Latitude = [];
      Longitude = [];
      Elevation = [];
      Roll = [];
      Pitch = [];
      Heading = [];
      GPS_time = [];
      Data = [];
      Topography = [];
      for qlook_fn = filenames.'
        tmp = load(qlook_fn{1});
        time_vector_changed = false;
        if isempty(Time)
          Time = tmp.Time;
        elseif any(size(Time) ~= size(tmp.Time)) || any(Time ~= tmp.Time)
          % Determine the new time axis
          time_vector_changed = true;
          old_time = Time;
          dt = Time(2) - Time(1);
          start_time_diff = floor((Time(1) - tmp.Time(1))/dt);
          end_time_diff = floor((tmp.Time(end) - Time(end))/dt);
          if start_time_diff > 0
            Time = [Time(1)+dt*(start_time_diff:-1)'; Time];
          end
          if end_time_diff > 0
            Time = [Time; Time(end)+dt*(1:end_time_diff)'];
          end
        end
        Depth = Time * c/2;
        Latitude = [Latitude double(tmp.Latitude)];
        Longitude = [Longitude double(tmp.Longitude)];
        Elevation = [Elevation double(tmp.Elevation)];
        Roll = [Roll double(tmp.Roll)];
        Pitch = [Pitch double(tmp.Pitch)];
        Heading = [Heading double(tmp.Heading)];
        GPS_time = [GPS_time tmp.GPS_time];
        param_records = tmp.param_records;
        param_slope_tracker = tmp.param_slope_tracker;
        if img_idx == param.slope.surf.img_idx
          Surface = [Surface double(tmp.Surface)];
        end
        if time_vector_changed
          Data = [interp1(old_time,Data,Time,'spline',0) interp1(tmp.Time,tmp.Data,Time,'spline',0)];
        else
          Data = [Data tmp.Data];
        end
      end
      
      % =====================================================================
      % Save output
      if length(param.slope.imgs) == 1
        out_fn = fullfile(qlook_out_path, sprintf('Data_%s_%03d.mat', ...
          param.day_seg, list.frmInd(fileInd)));
      else
        out_fn = fullfile(qlook_out_path, sprintf('Data_img_%02d_%s_%03d.mat', ...
          img_idx, param.day_seg, list.frmInd(fileInd)));
      end
      fprintf('  Writing output to %s\n', out_fn);
      save('-v6',out_fn,'Depth','Time','Latitude','Longitude', ...
        'Elevation','Roll','Pitch','Heading','GPS_time','Data','Surface', 'param_slope_tracker', 'param_records');
      
      % If combining waveforms, save the output
      if length(param.slope.imgs) > 1
        if img_idx == 1
          img1.Data = Data;
          img1.Time = Time;
        elseif img_idx == 2
          img2.Data = Data;
          img2.Time = Time;
        end
      end
    end
    
    if length(param.slope.imgs) > 1
      % =====================================================================
      % Combine waveforms
      
      % Interpolate waveform 2 onto waveform 1 (assumption is that waveform
      % 1 always comes before waveform 2)
      dt = img1.Time(2)-img1.Time(1);
      Time = (img1.Time(1) : dt : img2.Time(end)).';
      Depth = Time * c/2;
      img2.Data= interp1(img2.Time,img2.Data,Time,'linear',0);
      
      param.img_bins(1) = find(Time > param.slope.qlook.img_comb, 1);
      param.img_bins(2) = param.img_bins(1) + 10;
      param.img_bin_comp = param.img_bins(1) + (30:40);
      
      % Combine waveforms
      difference = mean(mean(img1.Data(param.img_bin_comp,:))) ...
        ./ mean(mean(img2.Data(param.img_bin_comp,:)));
      
      trans_bins = param.img_bins(1)+1:param.img_bins(2);
      weights = 0.5+0.5*cos(pi*linspace(0,1,length(trans_bins)).');
      Data = [img1.Data(1:param.img_bins(1),:); ...
        repmat(weights,[1 size(img1.Data,2)]).*img1.Data(trans_bins,:) ...
        + difference*repmat(1-weights,[1 size(img2.Data,2)]).*img2.Data(trans_bins,:); ...
        difference*img2.Data(param.img_bins(2)+1:end,:)];
      
      % =====================================================================
      % Save output
      out_fn = fullfile(qlook_out_path, sprintf('Data_%s_%03d.mat', ...
        param.day_seg, list.frmInd(fileInd)));
      fprintf('  Writing output to %s\n', out_fn);
      save('-v6',out_fn,'Depth','Time','Latitude','Longitude', ...
        'Elevation','Roll','Pitch','Heading','GPS_time','Data','Surface', 'param_slope_tracker', ...
        'param_records');
    end
    
    if ~param.sched.rerun_only && exist(in_path,'dir')
      % Remove the temporary files
      rmdir(in_path,'s');
    end
  end
end

if param.slope.surf.en
  % Read the "Surface" variable from all the frames that were created
  % by this particular run of slope_tracker
  
  if isfield(records,'lat')
    num_recs = length(records.lat);
  end
  
  if ~isfield(records,'surface')
    records.surface = zeros(1,num_recs);
  end
  
  if length(records.surface) ~= num_recs
    warning('Debug catch incase records.surface is wrong length... hand-fix to be correct length');
    keyboard
  end
  
  for frame = param.cmd.frms
    if frames.proc_mode(frame) == 2
      continue;
    end
    out_fn = fullfile(qlook_out_path, sprintf('Data_%s_%03d.mat', ...
      param.day_seg, frame));
    load(out_fn,'GPS_time','Surface');
    
    if frame < length(frames.frame_idxs)
      recs = frames.frame_idxs(frame):frames.frame_idxs(frame+1);
    else
      recs = frames.frame_idxs(frame):num_recs;
    end
    
    records.surface(recs) = interp1(GPS_time,Surface,records.gps_time(recs),'linear','extrap');
  end
  
  % Store surface information to the records file
  save(records_fn,'-APPEND','-struct','records','surface');
end

return;

