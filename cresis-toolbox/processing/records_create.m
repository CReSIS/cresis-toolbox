function records_create(param,param_override)
% records_create(param,param_override)
%
% Function for creating records file for all radar systems. The function is
% usually called from master.m but can also be called from
% run_records_create.m.
%
% Corrects jumps in utc time, typically one second jumps. This script
% obtains headers from data indicated in the vectors param spreadsheets.
% After loading the files using basic_load*.m, the records files are saved
% in the support directories for the specific radar in .mat form for
% quicker access.
%
% Inputs:
% param: struct with processing parameters
%         -- OR --
%         function handle to script with processing parameters
% param_override: parameters in this struct will override parameters
%         in param.  This struct must also contain the gRadar fields.
%         Typically global gRadar; param_override = gRadar;
%
% Authors: John Paden
%
% See also: run_master.m, master.m, run_records_create.m, records_create.m,
%   records_create_sync.m, records_check.m

%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input Checks
% =====================================================================

[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);

% param.records.arena: structure controlling records creation of
% arena-based digital systems
if ~isfield(param.records,'arena')
  param.records.arena = [];
end

% param.records.arena.total_presums: override total_presums value that is
% normally read in from the config.xml file
if ~isfield(param.records.arena,'total_presums')
  param.records.arena.total_presums = [];
end

% boards: List of subdirectories containing the files for each board (a
% board is a data stream stored to disk and often contains the data stream
% from multiple ADCs)
if any(param.records.file.version == [1:5 8 11 101:102 405:406 409:411 413 414 415 420])
  if ~isfield(param.records.file,'boards') || isempty(param.records.file.boards)
    % Assume a single channel system
    param.records.file.boards = {''};
  end
elseif any(param.records.file.version == [6:7 9:10 103 401:404 407:408 412])
  if ~isfield(param.records.file,'boards') || isempty(param.records.file.boards)
    error('param.records.file.boards should be specified.');
  end
else
  error('Unsupported file version\n');
end
boards = param.records.file.boards;

if ~isfield(param.records,'epri_jump_threshold') || isempty(param.records.epri_jump_threshold)
  param.records.epri_jump_threshold = 10000;
end

if ~isfield(param.records,'file') || isempty(param.records.file)
  param.records.file = [];
end
if ~isfield(param.records.file,'version') || isempty(param.records.file.version)
  error('The param.records.file.version field must be specified.');
end

if ~isfield(param.records,'gps') || isempty(param.records.gps)
  param.records.gps = [];
end
if ~isfield(param.records.gps,'en') || isempty(param.records.gps.en)
  % Assume that GPS synchronization is enabled
  param.records.gps.en = true;
end
if ~isfield(param.records.gps,'time_offset') || isempty(param.records.gps.time_offset)
  param.records.gps.time_offset = 0;
end

if ~isfield(param.records,'presum_mode') || isempty(param.records.presum_mode)
  if any(param.records.file.version == [402 403 404])
    % 8-channel DDS board had a waveform bug that required an extra waveform
    % to be sent and discarded (not used for presumming)
    param.records.presum_mode = 1;
  elseif any(param.records.file.version == [407 408])
    error('The param.records.presum_mode must be specified. If using the new waveform generator (Arena-based), this field should be 0. If using the old waveform generator, this field should be set to 1. The old waveform generator is an 8-channel 1 GSPS DDS by Ledford/Leuschen (not Arena-based).');
  else
    param.records.presum_mode = 0;
  end
end

if ~isfield(param.records,'use_ideal_epri') || isempty(param.records.use_ideal_epri)
  param.records.use_ideal_epri = false;
end

if ~isfield(param.records.gps,'utc_time_halved') || isempty(param.records.gps.utc_time_halved)
  if param.records.file.version == 1
    error('The param.records.gps.utc_time_halved must be specified. Set to 0 if the UTC time in the data files is half of what it should have been.');
  else
    param.records.gps.utc_time_halved = 0;
  end
end

% records.frames: structure that controls the frame generation after the
% records file is created.
if ~isfield(param.records,'frames') || isempty(param.records.frames)
  param.records.frames = [];
end

% records.frames.mode: 0, 1, or 2. Default is 0. 0: do nothing with frames,
% 1: autogenerate frames if they do not exist and then manually edit the
% frames, 2: autogenerate the frames
if ~isfield(param.records.frames,'mode') || isempty(param.records.frames.mode)
  param.records.frames.mode = 0;
end

command_window_out_fn = ct_filename_ct_tmp(param,'','records', ['console.txt']);
command_window_out_fn_dir = fileparts(command_window_out_fn);
if ~exist(command_window_out_fn_dir,'dir')
  mkdir(command_window_out_fn_dir);
end
diary(command_window_out_fn);


if any(param.records.file.version == [9 10 103 412])
  % Arena based systems
  h_fig = get_figures(1,true);
end

%% Load headers from each board
% =====================================================================
clear board_hdrs;
board_hdrs = {};
records = [];
for board_idx = 1:length(boards)
  board = boards{board_idx};
  
  fprintf('Getting files for board %s (%d of %d) (%s)\n', ...
    board, board_idx, length(boards), datestr(now));
  
  %% Load headers: get files
  % =====================================================================
  [base_dir,adc_folder_name,board_fns{board_idx},file_idxs] = get_segment_file_list(param,board_idx);
  
  % Load header from radar data file
  fprintf('Loading raw files %i to %i\n',file_idxs([1 end]));
  
  % Initialize variables to store header fields
  if any(param.records.file.version == [9 10 103 412])
    % Arena based systems
    board_hdrs{board_idx}.file_size = zeros([0 0],'int32');
    board_hdrs{board_idx}.file_idx = zeros([0 0],'int32');
    board_hdrs{board_idx}.offset = zeros([0 0],'int32');
    board_hdrs{board_idx}.mode_latch = zeros([0 0],'int32');
    board_hdrs{board_idx}.subchannel = zeros([0 0],'int32');
    board_hdrs{board_idx}.pps_cntr_latch = zeros([0 0],'double'); % Time when PPS edge came in
    board_hdrs{board_idx}.pps_ftime_cntr_latch = zeros([0 0],'double'); % Fractional time since edge
    board_hdrs{board_idx}.profile_cntr_latch = zeros([0 0],'double'); % PRI counter
    board_hdrs{board_idx}.rel_time_cntr_latch = zeros([0 0],'double'); % 10 MHz counts counter
    cur_idx = 0;
    
  elseif any(param.records.file.version == [413 414])
    board_hdrs{board_idx}.gps_time = zeros([0 0],'double');
    board_hdrs{board_idx}.file_idx = zeros([0 0],'int32');
    board_hdrs{board_idx}.offset = zeros([0 0],'int32');
    
  elseif any(param.records.file.version == [415])
    board_hdrs{board_idx}.file_idx = zeros([0 0],'int32');
    board_hdrs{board_idx}.radar_time = zeros([0 0],'double');
    board_hdrs{board_idx}.comp_time = zeros([0 0],'double');
    board_hdrs{board_idx}.offset = zeros([0 0],'int32');
    
  else
    % NI, Rink, Paden, Leuschen, and Ledford systems
    board_hdrs{board_idx}.seconds = zeros([0 0],'uint32');
    board_hdrs{board_idx}.fraction = zeros([0 0],'uint32');
    board_hdrs{board_idx}.offset = zeros([0 0],'int32');
    board_hdrs{board_idx}.file_idx = zeros([0 0],'uint32');
    % records.relative_rec_num = This variable contains the first record
    % number of each file. After the loop runs there will always be one
    % to many elements (161 files will mean 162 elements in the array)
    % and the last entry is the record number that would have been next
    % so that length(hdr.utc_time_sod) = records.relative_rec_num(end)-1
    records.relative_rec_num{board_idx} = 1;
    
    if param.records.file.version ~= 101
      board_hdrs{board_idx}.epri = zeros([0 0],'uint32');
    end
    if param.records.file.version == 2
      board_hdrs{board_idx}.nyquist_zone = zeros([0 0],'uint8');
      board_hdrs{board_idx}.loopback_mode = zeros([0 0],'uint8');
    elseif param.records.file.version == 8
      board_hdrs{board_idx}.nyquist_zone = zeros([0 0],'uint8');
      board_hdrs{board_idx}.waveform_ID = zeros([0 0],'uint64');
    end
  end
  
  for file_idx = 1:length(file_idxs)
    % Get the temporary filename from the filename list
    file_num = file_idxs(file_idx);
    [~,fn_name] = fileparts(board_fns{board_idx}{file_num});
%     if any(param.records.file.version == [9 10 103 412])
%       % Update the filename to point to the packet stripped files
%       board_fns{board_idx}{file_num} = ct_filename_ct_tmp(rmfield(param,'day_seg'),'','headers', ...
%         fullfile(adc_folder_name, [fn_name '.dat']));
%     end
    fn = board_fns{board_idx}{file_num};
    dir_info = dir(fn);
    
    fprintf('  %i/%i %s (%s)\n', ...
      file_idx,length(file_idxs), fn, datestr(now,'HH:MM:SS'));
    
    if any(param.records.file.version == [415])
      % Files may be empty, these are skipped in preprocessing
      if dir_info.bytes == 0
        continue
      end
    end
    
    % Load temporary files
    tmp_hdr_fn = ct_filename_ct_tmp(rmfield(param,'day_seg'),'','headers', ...
      fullfile(adc_folder_name, [fn_name '.mat']));
    if any(param.records.file.version == [413 414])
      hdr_tmp = load(tmp_hdr_fn,'gps_time','wfs');
    else
      hdr_tmp = load(tmp_hdr_fn);
    end
    
    %% Concatenate all the fields together
    %  - Note that all fields from the file should have the same hdr_tmp
    %  length. Error in the file if not.
    if any(param.records.file.version == [9 10 103 412])
      % Arena based systems
      if hdr_tmp.offset > 1e9
        keyboard
      end

      board_hdrs{board_idx}.file_size(cur_idx + (1:length(hdr_tmp.mode_latch))) = dir_info.bytes;
      board_hdrs{board_idx}.file_idx(cur_idx + (1:length(hdr_tmp.mode_latch))) = file_num;

      if isfield(hdr_tmp,'profile')
        board_hdrs{board_idx}.profile(cur_idx + (1:length(hdr_tmp.mode_latch))) = hdr_tmp.profile;
      else
        board_hdrs{board_idx}.profile(cur_idx + (1:length(hdr_tmp.mode_latch))) = nan(size(hdr_tmp.mode_latch));
      end
      board_hdrs{board_idx}.mode_latch(cur_idx + (1:length(hdr_tmp.mode_latch))) = hdr_tmp.mode_latch;
      board_hdrs{board_idx}.offset(cur_idx + (1:length(hdr_tmp.mode_latch))) = hdr_tmp.offset;
      board_hdrs{board_idx}.subchannel(cur_idx + (1:length(hdr_tmp.mode_latch))) = hdr_tmp.subchannel;
      
      board_hdrs{board_idx}.pps_cntr_latch(cur_idx + (1:length(hdr_tmp.mode_latch))) = hdr_tmp.pps_cntr_latch;
      board_hdrs{board_idx}.pps_ftime_cntr_latch(cur_idx + (1:length(hdr_tmp.mode_latch))) = hdr_tmp.pps_ftime_cntr_latch;
      board_hdrs{board_idx}.profile_cntr_latch(cur_idx + (1:length(hdr_tmp.mode_latch))) = hdr_tmp.profile_cntr_latch;
      board_hdrs{board_idx}.rel_time_cntr_latch(cur_idx + (1:length(hdr_tmp.mode_latch))) = hdr_tmp.rel_time_cntr_latch;
      
      cur_idx = cur_idx + length(hdr_tmp.mode_latch);
      
    elseif any(param.records.file.version == [413 414])
      board_hdrs{board_idx}.gps_time(end+1:end+length(hdr_tmp.gps_time)) = hdr_tmp.gps_time;
      board_hdrs{board_idx}.file_idx(end+1:end+length(hdr_tmp.gps_time)) = file_num;
      board_hdrs{board_idx}.offset(end+1:end+length(hdr_tmp.gps_time)) = 1:length(hdr_tmp.gps_time);
      wfs = hdr_tmp.wfs;
      
    elseif any(param.records.file.version == [415])
      % UTIG RDS 60 MHZ MARFA/HICARS
      board_hdrs{board_idx}.radar_time(end+1:end+length(hdr_tmp.radar_time)) = hdr_tmp.radar_time;
      board_hdrs{board_idx}.comp_time(end+1:end+length(hdr_tmp.radar_time)) = datenum_to_epoch(hdr_tmp.comp_time);
      board_hdrs{board_idx}.offset(end+1:end+length(hdr_tmp.radar_time)) = int32(hdr_tmp.offset);
      board_hdrs{board_idx}.file_idx(end+1:end+length(hdr_tmp.radar_time)) = file_num;
      wfs = [];
      
    else
      % NI, Rink, Paden, Leuschen, and Ledford systems
      if isempty(hdr_tmp.seconds)
        fprintf('    File with no records.\n');
        records.relative_rec_num{board_idx}(file_idx+1) = records.relative_rec_num{board_idx}(file_idx);
        continue;
      end

      board_hdrs{board_idx}.seconds(end+1:end+length(hdr_tmp.seconds)) = hdr_tmp.seconds;
      board_hdrs{board_idx}.fraction(end+1:end+length(hdr_tmp.seconds)) = hdr_tmp.fraction;
      board_hdrs{board_idx}.file_idx(end+1:end+length(hdr_tmp.seconds)) = file_num;
      board_hdrs{board_idx}.offset(end+1:end+length(hdr_tmp.seconds)) = int32(hdr_tmp.offset);
      
      if any(param.records.file.version == [1:8 11 102 401:404 407:408 420])
        % Ledford, Rink and NI systems have EPRI field
        board_hdrs{board_idx}.epri(end+1:end+length(hdr_tmp.seconds)) = hdr_tmp.epri;
      end
      if param.records.file.version == 8
        board_hdrs{board_idx}.nyquist_zone(end+1:end+length(hdr_tmp.seconds)) = hdr_tmp.nyquist_zone;
        board_hdrs{board_idx}.waveform_ID(end+1:end+length(hdr_tmp.seconds)) = hdr_tmp.waveform_ID;
      end
      
      % Copy the waveform structure
      wfs = hdr_tmp.wfs;
      
      % Create records and file numbers
      records.relative_rec_num{board_idx}(file_idx+1) = length(hdr_tmp.seconds)+records.relative_rec_num{board_idx}(file_idx);
      [fn_dir fn_name fn_ext] = fileparts(fn);
      
      % Handle records that span two files
      if file_idx ~= length(file_idxs)
        % The last record in a file is generally incomplete and continues
        % in the next file. This incomplete record is marked as being
        % in the next file (so we increment file_idx) and we use a negative
        % index to indicate that it actually started in this file where the
        % negative index is relative to the end of this file.
        board_hdrs{board_idx}.file_idx(end) = board_hdrs{board_idx}.file_idx(end) + 1;
        file_size = dir(fn);
        board_hdrs{board_idx}.offset(end) = board_hdrs{board_idx}.offset(end) - file_size.bytes;
      else
        % Drop the last record of the last file since it is generally not a
        % complete record and there is no additional file to load which
        % contains the remainder of the record.
        if any(param.records.file.version == [1:8 11 102 401:404 407:408 420])
          board_hdrs{board_idx}.epri = board_hdrs{board_idx}.epri(1:end-1);
        end
        if param.records.file.version == 8
          board_hdrs{board_idx}.nyquist_zone = board_hdrs{board_idx}.nyquist_zone(1:end-1);
          board_hdrs{board_idx}.waveform_ID = board_hdrs{board_idx}.waveform_ID(1:end-1);
        end
        board_hdrs{board_idx}.seconds = board_hdrs{board_idx}.seconds(1:end-1);
        board_hdrs{board_idx}.fraction = board_hdrs{board_idx}.fraction(1:end-1);
        board_hdrs{board_idx}.file_idx = board_hdrs{board_idx}.file_idx(1:end-1);
        board_hdrs{board_idx}.offset = board_hdrs{board_idx}.offset(1:end-1);
      end
    end
  end
  
end

%% Correct EPRI for each board individually
% ======================================================================

if any(param.records.file.version == [9 10 103 412])
  % Arena based systems

  % Load XML configs file
  config_fn = ct_filename_ct_tmp(rmfield(param,'day_seg'),'','headers', ...
    fullfile(param.records.config_fn));
  configs = read_arena_xml(config_fn);
  
  for board_idx = 1:length(boards)
    %% Correct EPRI/Arena: Find the PRIs associated with the EPRI profile
    % =====================================================================
    if size(param.records.data_map{board_idx},2) == 4
      % No Profile Processor Digital System (use mode_latch,subchannel instead)
      % Each row of param.records.data_map{board_idx} = [mode_latch subchannel wf adc]
      
      % Get the first row (which is always the EPRI row)
      epri_mode = param.records.data_map{board_idx}(1,1);
      epri_subchannel = param.records.data_map{board_idx}(1,2);
      
      mask = board_hdrs{board_idx}.mode_latch == epri_mode & board_hdrs{board_idx}.subchannel == epri_subchannel;
    else
      % Profile Processor Digital System
      % Each row of param.records.data_map{board_idx} = [profile mode_latch subchannel wf adc]
      
      % Get the first row (which is always the EPRI row)
      epri_profile = param.records.data_map{board_idx}(1,1);
      epri_mode = param.records.data_map{board_idx}(1,2);
      epri_subchannel = param.records.data_map{board_idx}(1,3);
      
      mask = board_hdrs{board_idx}.profile == epri_profile;
    end
    % Data before first PPS reset may be incorrectly time tagged so we do not
    % use it
    first_reset = find(diff(board_hdrs{board_idx}.pps_cntr_latch)>0,1);
    if board_hdrs{board_idx}.pps_ftime_cntr_latch(first_reset) > 10e6
      mask(1:first_reset) = 0;
    end
    epri_pris = board_hdrs{board_idx}.profile_cntr_latch(mask);

    %% Correct EPRI/Arena: Find EPRI jumps and mask out
    % =====================================================================
    if isempty(param.records.arena.total_presums)
      total_presums = configs.total_presums;
    else
      total_presums = param.records.arena.total_presums;
    end
    jump_idxs = find( abs(diff(double(epri_pris))/total_presums - 1) > 0.1);
    
    bad_mask = zeros(size(epri_pris));
    for jump_idx = jump_idxs
      jump = (epri_pris(jump_idx+1)-epri_pris(jump_idx))/total_presums - 1;
      fprintf('jump_idx: %d, jump: %d\n', jump_idx, jump);
      fprintf('epri_pris: %d to %d\n', epri_pris(jump_idx), epri_pris(jump_idx+1));
      if jump < -0.1
        fprintf('Negative or zero time jump\n');
        keyboard
        bad_mask(jump_idx+1:end) = epri_pris(jump_idx+1:end) < epri_pris(jump_idx);
      elseif jump > 0.1 && jump < 100
        fprintf('Dropped some records\n');
        %keyboard
      elseif jump > 50000
        fprintf('Record header error or dropped > 50000 records\n');
        keyboard
        epri_pris(jump_idx+1) = epri_pris(jump_idx);
        bad_mask(jump_idx+1) = 1;
      elseif jump > 100
        fprintf('Dropped many records or record header error\n');
        %       keyboard
      end
    end
    
    mask(mask) = ~bad_mask;
    
    %% Correct EPRI/Arena: Update epri_pri_idxs
    % Find the first subrecord in each epri_pri and update epri_pri_idxs
    epri_pri_idxs = find(mask);
    for idx = 1:length(epri_pri_idxs)
      %if ~mod(idx-1,10000)
      %  fprintf('%d\n', idx);
      %end
      epri_pri_idx = epri_pri_idxs(idx);
      pri = board_hdrs{board_idx}.profile_cntr_latch(epri_pri_idx);
      if board_hdrs{board_idx}.profile_cntr_latch(1) == pri
        % Special case for first PRI
        epri_pri_idxs(idx) = 1;
      else
        % For second and later PRIs
        while board_hdrs{board_idx}.profile_cntr_latch(epri_pri_idx) == pri
          epri_pri_idx = epri_pri_idx-1; % Search backwards until we find the previous PRI
        end
        epri_pri_idxs(idx) = epri_pri_idx+1; % The subrecord after this is the first PRI in the current EPRI
      end
    end
    
    %% Correct EPRI/Arena: Ensure all records are valid in each EPRI
    % =====================================================================
    mask = zeros(size(board_hdrs{board_idx}.pps_cntr_latch));
    mask(epri_pri_idxs) = 1;
    found_board = false;
    for idx = 1:length(epri_pri_idxs)-1
      %if ~mod(idx-1,1000000)
      %  fprintf('%d\n', idx);
      %end
      for pri_idx = epri_pri_idxs(idx):epri_pri_idxs(idx+1)-1
        
        if ~found_board
          for configs_board_idx = 1:size(configs.adc,1)
            if isfield(configs.adc{configs_board_idx,board_hdrs{board_idx}.mode_latch(pri_idx)+1,board_hdrs{board_idx}.subchannel(pri_idx)+1},'name') ...
                && strcmpi(configs.adc{configs_board_idx,board_hdrs{board_idx}.mode_latch(pri_idx)+1,board_hdrs{board_idx}.subchannel(pri_idx)+1}.name, boards{board_idx});
              found_board = true;
              break;
            end
          end
          if ~found_board
            error('boards(%d)=%s not found in configs file\n', board_idx, boards(board_idx));
          end
        end

        if mod(board_hdrs{board_idx}.mode_latch(pri_idx),2)
          board_hdrs{board_idx}.mode_latch(pri_idx)=board_hdrs{board_idx}.mode_latch(pri_idx)-1;
        end
        if board_hdrs{board_idx}.mode_latch(pri_idx) >= size(configs.adc,2) ...
            || board_hdrs{board_idx}.subchannel(pri_idx) >= size(configs.adc,3) ...
            || ~isfield(configs.adc{configs_board_idx,board_hdrs{board_idx}.mode_latch(pri_idx)+1,board_hdrs{board_idx}.subchannel(pri_idx)+1},'rg') ...
            || isempty(configs.adc{configs_board_idx,board_hdrs{board_idx}.mode_latch(pri_idx)+1,board_hdrs{board_idx}.subchannel(pri_idx)+1}.rg)
          fprintf('Bad record %d\n', pri_idx);
          mask(pri_idx) = 0;
          break;
        end
      end
    end
    mask(find(mask,1,'last')) = 0; % Remove last potentially incomplete record
    epri_pri_idxs = find(mask);
    
    %% Correct EPRI/Arena: Fix records split between two files
    % Find records that are split between two files and use a negative
    % offset to indicate this.
    for idx = 2:length(epri_pri_idxs)
      if board_hdrs{board_idx}.file_idx(epri_pri_idxs(idx)) > board_hdrs{board_idx}.file_idx(epri_pri_idxs(idx-1))
        % This record is split between files
        if board_hdrs{board_idx}.offset(epri_pri_idxs(idx)) >= 2^31
          % This split is already handled by arena_packet_strip, but we need
          % to convert uint32 number to negative int32.
          board_hdrs{board_idx}.offset(epri_pri_idxs(idx)) = board_hdrs{board_idx}.offset(epri_pri_idxs(idx)) - 2^32;
        else
          % Convert last record from previous file to negative offset in the
          % new file
          board_hdrs{board_idx}.offset(epri_pri_idxs(idx-1)) = board_hdrs{board_idx}.offset(epri_pri_idxs(idx-1)) - board_hdrs{board_idx}.file_size(epri_pri_idxs(idx-1));
          board_hdrs{board_idx}.file_idx(epri_pri_idxs(idx-1)) = board_hdrs{board_idx}.file_idx(epri_pri_idxs(idx-1)) + 1;
        end
      end
    end
    
    % Store new outputs
    board_hdrs{board_idx}.epri_pri_idxs = epri_pri_idxs;
    board_hdrs{board_idx}.mask = logical(mask);
  end

  %% Correct EPRI/Arena: Mask outputs
  for board_idx = 1:length(boards)
    board_hdrs{board_idx}.offset = board_hdrs{board_idx}.offset(board_hdrs{board_idx}.mask);
    board_hdrs{board_idx}.file_idx = board_hdrs{board_idx}.file_idx(board_hdrs{board_idx}.mask);
    board_hdrs{board_idx}.profile_cntr_latch = board_hdrs{board_idx}.profile_cntr_latch(board_hdrs{board_idx}.mask);
    board_hdrs{board_idx}.rel_time_cntr_latch = board_hdrs{board_idx}.rel_time_cntr_latch(board_hdrs{board_idx}.mask);
    board_hdrs{board_idx}.pps_cntr_latch = board_hdrs{board_idx}.pps_cntr_latch(board_hdrs{board_idx}.mask);
    board_hdrs{board_idx}.pps_ftime_cntr_latch = board_hdrs{board_idx}.pps_ftime_cntr_latch(board_hdrs{board_idx}.mask);
    board_hdrs{board_idx} = rmfield(board_hdrs{board_idx},{'file_size','mode_latch','subchannel','mask'});
  end
  
  %% Correct EPRI/Arena: Populate wfs structure
  for board_idx = 1:length(boards)
    board = boards(board_idx);
    
    for map_idx = 1:size(param.records.data_map{board_idx},1)
      if size(param.records.data_map{board_idx},2) == 4
        % No Profile Processor Digital System (use mode_latch,subchannel instead)
        % Each row of param.records.data_map{board_idx} = [mode_latch channel wf adc]
        
        wf = param.records.data_map{board_idx}(map_idx,3);
        % adc = param.records.data_map{board_idx}(map_idx,4);
        mode_latch = param.records.data_map{board_idx}(map_idx,1);
        subchannel = param.records.data_map{board_idx}(map_idx,2);
        
      else
        % Profile mode
        % Each row of param.records.data_map{board_idx} = [profile mode_latch channel wf adc]
        
        wf = param.records.data_map{board_idx}(map_idx,4);
        % adc = param.records.data_map{board_idx}(map_idx,5);
        mode_latch = param.records.data_map{board_idx}(map_idx,2);
        subchannel = param.records.data_map{board_idx}(map_idx,3);
        profile = param.records.data_map{board_idx}(map_idx,1);
      end
      
      found_board = false;
      for configs_board_idx = 1:size(configs.adc,1)
        if isfield(configs.adc{configs_board_idx,mode_latch+1,subchannel+1},'name') ...
            && strcmpi(configs.adc{configs_board_idx,mode_latch+1,subchannel+1}.name, boards{board_idx});
          found_board = true;
          break;
        end
      end
      if ~found_board
        error('boards(%d)=%s not found in configs file\n', board_idx, boards(board_idx));
      end
      
      wfs(wf).num_sam = configs.adc{configs_board_idx,mode_latch+1,subchannel+1}.num_sam;
      wfs(wf).bit_shifts = param.radar.wfs(wf).bit_shifts;
      wfs(wf).t0 = param.radar.wfs(wf).Tadc;
      wfs(wf).presums = configs.adc{configs_board_idx,mode_latch+1,subchannel+1}.presums;
    end
  end

elseif any(param.records.file.version == [413 414])
  % UTUA RDS systems
  % BAS RDS systems
  
elseif any(param.records.file.version == [415])
  % UTIG RDS systems
  
else
  % NI, Rink, Paden, Leuschen, and Ledford systems

end

%% Save workspace in case there is a failure
records_create_save_workspace;

%% Correct time, sync GPS data, and save records
records_create_sync;

%% Create reference trajectory file
if param.records.gps.en
  records_reference_trajectory(param);
end

%% Create frames
% param.records.frames.mode == 0: Do nothing
if param.records.frames.mode == 1 % Autogenerate if needed and then manually edit
  frames_fn = ct_filename_support(param,'','frames');
  if ~exist(frames_fn,'file')
    frames_autogenerate(param,param_override);
  end
  obj = frames_create(param,param_override);
elseif param.records.frames.mode >= 2 % Autogenerate the frames file
  frames_autogenerate(param,param_override);
end

diary off;
fprintf('Console output: %s\n', command_window_out_fn);

