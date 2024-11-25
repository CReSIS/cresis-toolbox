function radiometric_calibration(param, param_override)
% radiometric_calibration(param)
%
% !!! header not updated for current script !!!
%    being modified from post
%
%
%
% Generalized function for posting data. Should be called from
% run_post.
%
% Author: Shashanka Jagarlapudi, Logan Smith, John Paden, Theresa Stumpf, Anthony Hoch
%
% See also run_post, post

if ~exist('param','var')
  error('Call function from run_radiometric');
end

param = merge_structs(param,param_override);

% =========================================================================
% Automated Section
% =========================================================================

fprintf('============================================================\n');
fprintf('Radiometric Calibration %s (%s)\n', param.day_seg, datestr(now));
fprintf('============================================================\n');
radiometric_tstart = tic;


physical_constants;

% Load frames file
frames = frames_load(param);
% Load records file
records = records_load(param);

global g_data;
g_data = [];

if isempty(param.cmd.frms)
  param.cmd.frms = 1:length(frames.frame_idxs);
end

in_path = ct_filename_out(param, param.radiometric.in_path, '',1);

if ~isempty(param.radiometric.out_path)
  out_path = ct_filename_out(param,param.radiometric.out_path,'',1);
else
  out_path = ct_filename_out(param,param.radiometric.out_path,'CSARP_radCal',1);
end

% build list of files to process
for data_dir_idx = 1:length(param.radiometric.data_dirs)
  % Get a data directory
  data_path_in = fullfile(in_path,sprintf('CSARP_%s',param.radiometric.data_dirs{data_dir_idx}),param.day_seg);
  if ~exist(data_path_in,'dir')
    continue;
  end
  
  data_path_out = fullfile(out_path,param.radiometric.data_dirs{data_dir_idx},param.day_seg);
  
  % Get all the data files in the data directory and then sort out
  % just the filename and day_seg
  data_files_in = get_filenames(data_path_in,'Data_','','.mat',struct('recursive',1));  % this works for QLook and standard
  clear data_files_name data_files_day_seg;
  data_files_name = {};       % whole file name
  data_files_frm_id = {};     % day_seg_frame
  data_files_frm_num = {};    % frame number
  
  if ~isempty(data_files_in)  % data is in QLook format
    
    for file_idx = 1:length(data_files_in)
      [tmp data_files_name{file_idx}] = fileparts(data_files_in{file_idx});
      data_files_frm_num{file_idx} = str2num(data_files_name{file_idx}(end-2:end));
      if data_files_name{file_idx}(6) == 'i'                                          % if file is an img_##_ rather than base filename
        data_files_frm_id{file_idx} = data_files_name{file_idx}(13:end);
      else
        data_files_frm_id{file_idx} = data_files_name{file_idx}(6:end);
      end
    end
    
    files_keep = []; % filter for frames to process
    for file_idx = 1:length(data_files_in)
      if any(param.cmd.frms == data_files_frm_num{file_idx})
        files_keep = [files_keep, file_idx];
      end
    end
    %data_files_in = {data_files_in{files_keep}}.';
    data_files_in = data_files_in(files_keep);
    data_files_frm_num = data_files_frm_num(files_keep);
    
    data_files_out = cell(size(data_files_in));
    for file_idx = 1:length(data_files_in)
      [file_path file_name file_ext] = fileparts(data_files_in{file_idx});
      data_files_out{file_idx} = fullfile(data_path_out,[file_name file_ext]);
    end
    
  else % assume data is in CSARP format (contains the letters 'chk')
    data_files_in = get_filenames(data_path_in,'','chk_','.mat',struct('recursive',1));
    
    for file_idx = 1:length(data_files_in)
      [tmp data_files_name{file_idx}] = fileparts(data_files_in{file_idx});
      frame_str_loc = findstr(data_files_in{file_idx},'array');
      if ~isempty(frame_str_loc)
        data_files_frm_num{file_idx} = str2num(data_files_in{file_idx}(frame_str_loc+[6:1:8]));
      else
        frame_str_loc = findstr(data_files_in{file_idx},'fk_data');
        data_files_frm_num{file_idx} = str2num(data_files_in{file_idx}(frame_str_loc+[8:1:10]));
      end
      if data_files_name{file_idx}(6) == 'i'                                          % if file is an img_##_ rather than base filename
        data_files_frm_id{file_idx} = data_files_name{file_idx}(13:end);
      else
        data_files_frm_id{file_idx} = data_files_name{file_idx}(6:end);
      end
    end
    
    files_keep = []; % filter for frames to process
    for file_idx = 1:length(data_files_in)
      if any(param.cmd.frms == data_files_frm_num{file_idx})
        files_keep = [files_keep, file_idx];
      end
    end
    %data_files_in = {data_files_in{files_keep}}.';
    data_files_in = data_files_in(files_keep);
    data_files_frm_num = data_files_frm_num(files_keep);
    
    data_files_out = cell(size(data_files_in));
    for file_idx = 1:length(data_files_in)
      [file_path file_name file_ext] = fileparts(data_files_in{file_idx});
      data_files_out{file_idx} = fullfile(data_path_out,file_path(length(data_path_in)+2:end),[file_name file_ext]);
      
      data_files_frm_num{file_idx} = str2num(data_files_out{1}(end-41:end-39));
    end
    
  end
  
  
  % =====================================================================
  % Setup static inputs for get_heights_task
  % =====================================================================
  global gRadar;
  task_param.gRadar = gRadar;
  
  task_param.radar_name = param.radar_name;
  task_param.season_name = param.season_name;
  task_param.day_seg = param.day_seg;
  
  if ~isfield(param,'debug_level')
    task_param.debug_level = 1;
  else
    task_param.debug_level = param.debug_level;
  end
  
  task_param.load.records_fn = ct_filename_support(param,'','records');
  
  task_param.radiometric = param.radiometric;
  
  
  % Currently every field in param.get_heights is used by get_heights_task
  % so we just pass the whole structure
  task_param.get_heights = param.get_heights;
  task_param.get_heights = rmfield(task_param.get_heights, {'imgs'});
  %task_param.load.imgs = param.get_heights.imgs;
  
  task_param.radar = param.radar;
  task_param.radar.Vpp_scale = param.radar.Vpp_scale;
  
  % =====================================================================
  % Setup the scheduler
  % =====================================================================
  
  if strcmpi(param.sched.type,'custom_torque')
    global ctrl; % Make this global for convenience in debugging
    ctrl = torque_new_batch(param);
    fprintf('Torque batch: %s\n', ctrl.batch_dir);
    torque_compile('get_heights_task.m',ctrl.sched.hidden_depend_funs,ctrl.sched.force_compile);
    
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
  
  
  % =====================================================================
  % Load data and run get_heights tasks
  %
  %
  % =====================================================================
  out_recs = {};
  retry_fields = {};
  for file_idx = 1:length(data_files_in)
    frame = data_files_frm_num(file_idx);
    frm = frame{1};
    start_rec = frames.frame_idxs(frm);
    
    if frm == length(frames.frame_idxs)
      
      stop_rec = length(records.raw.epri);
      
    else 
      
      stop_rec = frames.frame_idxs(frm + 1) - 1;
      
    end
    
    cur_recs = [start_rec stop_rec];
    
    % note: does not accomodate for block size, one frame per task, run
    % locally on high memory machine for large frames
    
    
    % =====================================================================
    % Prepare task inputs
    % =====================================================================
    task_param.load.data_file_in = data_files_in{file_idx};
    task_param.load.data_file_out = data_files_out{file_idx};
    
    % =================================================================
    % Execute tasks/jobs
    fh = @radiometric_calibration_task;
    arg{1} = task_param;
    
    if strcmp(param.sched.type,'custom_torque')
      create_task_param.conforming = true;
      create_task_param.notes = sprintf('%d', ...
        frame{1});
      ctrl = torque_create_task(ctrl,fh,1,arg,create_task_param);
      
    elseif ~strcmp(param.sched.type,'no scheduler')
      [ctrl,job_id,task_id] = create_task(ctrl,fh,1,arg);
      fprintf('  %d: Processing records %d to %d in job,task %d,%d (%s)\n', ...
        frm, cur_recs(1), cur_recs(end), job_id, task_id, datestr(now));
      retry_fields{job_id,task_id}.frm = frm;
%       retry_fields{job_id,task_id}.break_idx = break_idx;
      retry_fields{job_id,task_id}.arg = arg;
      out_recs{end + 1} = cur_recs;
      retry_fields{job_id,task_id}.out_idx = length(out_recs);
    else
      fprintf('  %d: Processing records %d to %d (%s)\n', ...
        frm, cur_recs(1), cur_recs(end), datestr(now));
      [success] = fh(arg{1});
    end
    
  end  % end of files
  
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
    
    if param.get_heights.surf.en
      % ======================================================================
      % Prepare records.surface variable
      if ~isfield(records,'surface')
        records.surface = zeros(size(records.lat),'double');
      end
      blockSize = param.get_heights.inc_ave * param.get_heights.decimate_factor;
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
  
 
  if ctrl.error_mask ~= 0
    fprintf('Not all jobs completed, but out of retries (%s)\n', datestr(now));
    return;
  else
    fprintf('Jobs completed (%s)\n\n', datestr(now));
  end
  
  
end


 % end of directories

fprintf('Done (%.1f sec)\n', toc(radiometric_tstart));

return;





