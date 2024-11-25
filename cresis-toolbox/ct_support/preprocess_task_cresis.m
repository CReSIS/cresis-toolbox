function success = preprocess_task_cresis(param)
% success = preprocess_task_cresis(param)
%
% Support function for preprocess.m
%
% Example:
% Called from preprocess_task.m
%
% Author: John Paden
%
% See also: run_preprocess.m, preprocess.m, preprocess_task.m,
% preprocess_task_arena.m, preprocess_task_cresis.m

% 1. Use what we already have
% 2. Use file version instead of radar name
% 3. Use last read to allow header wraps... or not.

%% Input checks
% =========================================================================

if ~isfield(param.config,'field_time_gap') || isempty(param.config.field_time_gap)
  param.config.field_time_gap = 'utc_time_sod';
end

if ~isfield(param.config,'segment_end_file_trim') || isempty(param.config.segment_end_file_trim)
  param.config.segment_end_file_trim = 1;
end

if ~isfield(param.config,'plots_visible') || isempty(param.config.plots_visible)
  param.config.plots_visible = 1;
end

%% Read Headers
% =========================================================================

% Save concatenated temporary file
fn_board_hdrs = ct_filename_ct_tmp(param,'','headers', fullfile(param.config.date_str,'board_hdrs.mat'));
num_board_to_load = numel(param.records.file.boards);
board_hdrs = cell(1,num_board_to_load);
failed_load = cell(1,num_board_to_load);
fns_list = cell(1,num_board_to_load);
if param.config.reuse_tmp_files && exist(fn_board_hdrs,'file') && ~param.config.tmp_load_mode
  try
    fprintf('Found %s\n  Trying to load...\n', fn_board_hdrs);
    load(fn_board_hdrs,'board_hdrs','fns_list','failed_load');
    num_board_to_load = 0;
  catch ME
    ME.getReport
  end
end

for board_idx = 1:num_board_to_load
  %% Read Headers: Filenames
  board = param.records.file.boards{board_idx};
  board_folder_name = param.config.board_folder_names;
  board_folder_name = regexprep(board_folder_name,'%b',board);
  
  get_filenames_param = struct('regexp',param.config.file.regexp);
  fns = get_filenames(fullfile(param.config.base_dir,board_folder_name), ...
    param.records.file.prefix, param.config.file.midfix, ...
    param.config.file.suffix, get_filenames_param);
  
  if param.config.online_mode == 2
    fns = fns(end);
  end
  fns_list{board_idx} = fns;
  
  % Copy Log Files
  if board_idx == 1 && ~isempty(param.config.gps_file_mask)
    log_files = fullfile(param.config.base_dir,param.config.config_folder_names,param.config.gps_file_mask);
    out_log_dir = fullfile(param.data_support_path, param.season_name, param.config.date_str);
    fprintf('Copy %s\n  %s\n', log_files, out_log_dir);
    try
      if ~exist(out_log_dir,'dir')
        mkdir(out_log_dir)
      end
      copyfile(log_files, out_log_dir);
    catch ME
      warning('Error while copying log files:\n%s\n', ME.getReport);
    end
  end
  
  if isempty(fns)
    warning('No files found matching %s*%s*%s', ...
      fullfile(param.config.base_dir,board_folder_name,param.records.file.prefix), ...
      param.config.file.midfix, param.config.file.suffix);
    fprintf('%s done %s\n', mfilename, datestr(now));
    success = true;
    return
  end
  
  % Assumption is that fns is in chronological order. Most radar systems
  % have filenames that are in chronological order with a simple
  % alphabetical sort.
  
  % ACORDS filenames are not in chronological order, resort by their
  % extension (.1, .2, .3, ..., .100, etc.)
  if any(param.records.file.version == [405 406])
    basenames = {};
    file_idxs = [];
    new_fns = {};
    finfo_param.hnum = 1;
    finfo_param.preprocess.file.version = param.records.file.version;
    for fidx = 1:length(fns)
      fname = fname_info_acords(fns{fidx},finfo_param);
      new_fns{fidx} = [fname.basename sprintf('.%03d',fname.file_idx)];
    end
    [new_fns,sorted_idxs] = sort(new_fns);
    fns = fns(sorted_idxs);
  end
  
  %% Read Headers: Header Info
  hdr_param = struct('file_mode','ieee-be');
  if any(param.records.file.version == [1])
    hdr_param.frame_sync = uint32(hex2dec('DEADBEEF'));
    hdr_param.field_offsets = int32([4 16 20]); % epri seconds fractions
    hdr_param.field_types = {uint32(1) uint32(1) uint32(1)};
    
  elseif any(param.records.file.version == [2])
    hdr_param.frame_sync = uint32(hex2dec('BADA55E5'));
    hdr_param.field_offsets = int32([4 8 12 24]); % epri seconds fractions loopback/nyquist-zone
    hdr_param.field_types = {uint32(1) uint32(1) uint32(1) uint32(1)};
    
  elseif any(param.records.file.version == [4])
    hdr_param.frame_sync = uint32(hex2dec('BADA55E5'));
    hdr_param.field_offsets = int32([4 8 12 16]); % epri sec1 sec2 fractions
    hdr_param.field_types = {uint32(1) uint32(1) uint32(1) uint64(1)};
    
  elseif any(param.records.file.version == [3 5])
    hdr_param.frame_sync = uint32(hex2dec('BADA55E5'));
    hdr_param.field_offsets = int32(4*[1 2 3 9 10 11]); % epri seconds fractions start/stop-index DDCfield1 DDCfield2
    hdr_param.field_types = {uint32(1) uint32(1) uint32(1) uint32(1) uint32(1) uint32(1)};
    
  elseif any(param.records.file.version == [8])
    hdr_param.frame_sync = uint32(hex2dec('BADA55E5'));
    hdr_param.field_offsets = int32([4 8 12 16 33 36 38 40]);
    % epri seconds fractions counter nyquist-zone waveform-ID
    hdr_param.field_types = {uint32(1) uint32(1) uint32(1) uint64(1) uint8(1) uint16(1) uint16(1) uint64(1)};
    
  elseif any(param.records.file.version == [101])
    hdr_param.frame_sync = uint32(hex2dec('DEADBEEF'));
    hdr_param.field_offsets = int32([4 8 12]); % epri seconds fractions
    hdr_param.field_types = {uint32(1) uint32(1) uint32(1)};
    
  elseif any(param.records.file.version == [102])
    hdr_param.frame_sync = uint32(hex2dec('1ACFFC1D'));
    hdr_param.field_offsets = int32(4*[1 3 4 5 6]); % epri seconds fractions
    hdr_param.field_types = {uint32(1) uint32(1) uint32(1) uint32(1) uint32(1)};
    hdr_param.frame_sync = hex2dec('1ACFFC1D');
    
  elseif any(param.records.file.version == [401])
    hdr_param.frame_sync = uint32(hex2dec('DEADBEEF'));
    hdr_param.field_offsets = int32([16 8 12]); % epri seconds fractions
    hdr_param.field_types = {uint32(1) uint32(1) uint32(1)};
    
  elseif any(param.records.file.version == [402 403])
    hdr_param.frame_sync = uint32(hex2dec('BADA55E5'));
    hdr_param.field_offsets = int32([4 8 12 16]); % epri seconds fraction counter
    hdr_param.field_types = {uint32(1) uint32(1) uint32(1) uint64(1)};
    
  elseif any(param.records.file.version == [404])
    hdr_param.frame_sync = uint32(hex2dec('1ACFFC1D'));
    hdr_param.field_offsets = int32([4 16 20 24]); % epri seconds fraction counter
    hdr_param.field_types = {uint32(1) uint32(1) uint32(1) uint64(1)};
    
  elseif any(param.records.file.version == [405 406])
    hdr_param.file_mode = 'ieee-le';
    hdr_param.frame_sync = uint32(0);
    hdr_param.field_offsets = int32([0 4]); % epri seconds fractions
    hdr_param.field_types = {uint32(1) uint32(1)};
    
  elseif any(param.records.file.version == [7 11 407 408])
    hdr_param.frame_sync = uint32(hex2dec('1ACFFC1D'));
 
  elseif any(param.records.file.version == [420])
    hdr_param.frame_sync = uint32(1212568132);
    hdr_param.field_offsets = int32([4 8 12]); % epri seconds fraction 
    hdr_param.field_types = {uint32(1) uint32(1) uint32(1)};    
    hdr_param.file_mode = 'ieee-le';   
  else
    error('Unsupported file version %d (%s)', param.records.file.version, param.radar_name);
  end
  
  %% Read Headers: File Loop
  failed_load{board_idx} = false(size(fns));
  board_hdrs{board_idx}.unknown = [];
  board_hdrs{board_idx}.radar_time = [];
  board_hdrs{board_idx}.radar_time_1pps = [];
  board_hdrs{board_idx}.epri = [];
  board_hdrs{board_idx}.seconds = [];
  board_hdrs{board_idx}.fraction = [];
  board_hdrs{board_idx}.waveform_ID = [];
  board_hdrs{board_idx}.counter = [];
  board_hdrs{board_idx}.file_idxs = [];
  for fn_idx = 1:length(fns)
    
    % Create temporary filename that will store the header information for
    % this file.
    fn = fns{fn_idx};
    if any(param.records.file.version == [405 406])
      [~,fn_name,ext] = fileparts(fn);
      fn_name = [fn_name,ext];
    else
      [~,fn_name] = fileparts(fn);
    end
    tmp_hdr_fn = ct_filename_ct_tmp(param,'','headers', ...
      fullfile(board_folder_name, [fn_name '.mat']));
    tmp_hdr_fn_dir = fileparts(tmp_hdr_fn);
    if ~exist(tmp_hdr_fn_dir,'dir')
      mkdir(tmp_hdr_fn_dir);
    end
    
    if param.config.online_mode == 0
      % Reading in all files one time, print each out
      fprintf('%d of %d: %s (%s)\n', fn_idx, length(fns), fn, datestr(now,'HH:MM:SS'));
      fprintf('  %s\n', tmp_hdr_fn);
      if param.config.reuse_tmp_files && exist(tmp_hdr_fn,'file')
        % Try to load temporary file
        try
          if any(param.records.file.version == [101])
            hdr = load(tmp_hdr_fn);
            board_hdrs{board_idx}.unknown ...
              = cat(2,board_hdrs{board_idx}.unknown,reshape(hdr.unknown,[1 length(hdr.unknown)]));
            board_hdrs{board_idx}.seconds ...
              = cat(2,board_hdrs{board_idx}.seconds,reshape(hdr.seconds,[1 length(hdr.seconds)]));
            board_hdrs{board_idx}.fraction ...
              = cat(2,board_hdrs{board_idx}.fraction,reshape(hdr.fraction,[1 length(hdr.fraction)]));
          elseif any(param.records.file.version == [102])
            hdr = load(tmp_hdr_fn);
            board_hdrs{board_idx}.radar_time ...
              = cat(2,board_hdrs{board_idx}.radar_time,hdr.radar_time);
            board_hdrs{board_idx}.radar_time_1pps ...
              = cat(2,board_hdrs{board_idx}.radar_time_1pps,hdr.radar_time_1pps);
          elseif any(param.records.file.version == [405 406])
            hdr = load(tmp_hdr_fn);
            hdr_log = [hdr_log,hdr.hdr];
            hdr_raw = [hdr_raw fn_idx*ones(1,length(hdr.hdr))];
            htime = [htime hdr.htime];
            board_hdrs{board_idx}.seconds ...
              = cat(2,board_hdrs{board_idx}.seconds,reshape(hdr.seconds,[1 length(hdr.seconds)]));
          else
            hdr = load(tmp_hdr_fn);
            board_hdrs{board_idx}.epri ...
              = cat(2,board_hdrs{board_idx}.epri,reshape(hdr.epri,[1 length(hdr.epri)]));
            board_hdrs{board_idx}.seconds ...
              = cat(2,board_hdrs{board_idx}.seconds,reshape(hdr.seconds,[1 length(hdr.seconds)]));
            board_hdrs{board_idx}.fraction ...
              = cat(2,board_hdrs{board_idx}.fraction,reshape(hdr.fraction,[1 length(hdr.fraction)]));
            if any(param.records.file.version == [8])
              board_hdrs{board_idx}.waveform_ID = cat(2,board_hdrs{board_idx}.waveform_ID,reshape(hdr.waveform_ID,[1 length(hdr.waveform_ID)]));
            elseif any(param.records.file.version == [403 407 408])
              board_hdrs{board_idx}.counter = cat(2,board_hdrs{board_idx}.counter,reshape(hdr.counter,[1 length(hdr.counter)]));
            end
          end
          board_hdrs{board_idx}.file_idxs = cat(2,board_hdrs{board_idx}.file_idxs,fn_idx*ones([1 length(hdr.offset)]));
          
          % Temp file loaded with no problems, so skip to the next one
          continue;
        catch ME
          % Temp file loading failed, so delete and try to recreate
          ME.getReport
          delete(tmp_hdr_fn);
        end
      end
      
    else
      % ONLINE MODE:
      % Repeatedly reading in files as new files are added, only print
      % out the filename if it has not been processed yet
      if param.config.reuse_tmp_files && exist(tmp_hdr_fn,'file')
        continue;
      else
        fprintf('%d of %d: %s (%s)\n', fn_idx, length(fns), fn, datestr(now,'HH:MM:SS'));
      end
    end
    
    try
      if any(param.records.file.version == [1])
        hdr = basic_load_fmcw(fn, struct('file_version',param.records.file.version,'clk',param.records.file.clk));
        wfs = hdr.wfs;
      elseif any(param.records.file.version == [2])
        hdr = basic_load_fmcw2(fn, struct('file_version',param.records.file.version,'clk',param.records.file.clk));
        wfs = hdr.wfs;
      elseif any(param.records.file.version == [4])
        hdr = basic_load_fmcw2(fn, struct('file_version',param.records.file.version,'clk',param.records.file.clk));
        wfs = hdr.wfs;
      elseif any(param.records.file.version == [3 5])
        hdr = basic_load_fmcw3(fn, struct('file_version',param.records.file.version,'clk',param.records.file.clk));
        wfs = struct('presums',hdr.presums);
      elseif any(param.records.file.version == [6])
        hdr = basic_load_fmcw4(fn, struct('file_version',param.records.file.version,'clk',param.records.file.clk));
        wfs = struct('presums',hdr.presums);
      elseif any(param.records.file.version == [7 11])
        hdr = basic_load(fn, struct('file_version',param.records.file.version,'clk',param.records.file.clk));
        wfs = hdr.wfs;
        hdr_param.field_offsets = int32([4 8 12 16]); % epri seconds fractions counter
      elseif any(param.records.file.version == [8])
        hdr = basic_load_fmcw8(fn, struct('file_version',param.records.file.version,'clk',param.records.file.clk));
        wfs = struct('presums',hdr.presums);
      elseif any(param.records.file.version == [101])
        hdr = basic_load_accum(fn, struct('file_version',param.records.file.version,'clk',param.records.file.clk));
        wfs = hdr.wfs;
      elseif any(param.records.file.version == [102])
        hdr = basic_load_accum2(fn, struct('file_version',param.records.file.version,'clk',param.records.file.clk));
        wfs = hdr.wfs;
      elseif any(param.records.file.version == [401])
        hdr = basic_load_mcords(fn, struct('file_version',param.records.file.version,'clk',param.records.file.clk));
        wfs = hdr.wfs;
      elseif any(param.records.file.version == [402])
        hdr = basic_load_mcords2(fn, struct('file_version',param.records.file.version,'clk',param.records.file.clk));
        wfs = hdr.wfs;
      elseif any(param.records.file.version == [403])
        hdr = basic_load_mcords3(fn, struct('file_version',param.records.file.version,'clk',param.records.file.clk));
        wfs = hdr.wfs;
      elseif any(param.records.file.version == [404])
        hdr = basic_load_mcords4(fn, struct('file_version',param.records.file.version,'clk',param.records.file.clk));
        wfs = hdr.wfs;
      elseif any(param.records.file.version == [405 406])
        % Load header information that never changes
        %   You need to get the record sizes
        clear hdr wfs
        hdr = basic_load_acords(fn,struct('datatype',0,'file_version',param.records.file.version,'verbose',0));
        for hidx = 1:length(hdr)
          wfs{1}.num_samp(hidx) = hdr(hidx).num_samp;
          wfs{2}.num_samp(hidx) = hdr(hidx).num_samp;
          wfs{1}.presums(hidx) = hdr(hidx).presums;
          wfs{2}.presums(hidx) = hdr(hidx).presums;
          wfs{1}.shifts(hidx) = hdr(hidx).shifts;
          wfs{2}.shifts(hidx) = hdr(hidx).shifts;
          wfs{1}.prf(hidx) = hdr(hidx).prf;
          wfs{2}.prf(hidx) = hdr(hidx).prf;
          wfs{1}.f0(hidx) = hdr(hidx).f0;
          wfs{2}.f0(hidx) = hdr(hidx).f0;
          wfs{1}.f1(hidx) = hdr(hidx).f1;
          wfs{2}.f1(hidx) = hdr(hidx).f1;
          wfs{1}.wf_gen_clk(hidx) = hdr(hidx).wf_gen_clk;
          wfs{2}.wf_gen_clk(hidx) = hdr(hidx).wf_gen_clk;
          wfs{1}.daq_clk(hidx) = hdr(hidx).daq_clk;
          wfs{2}.daq_clk(hidx) = hdr(hidx).daq_clk;
          wfs{1}.tpd(hidx) = hdr(hidx).tpd;
          wfs{2}.tpd(hidx) = hdr(hidx).tpd;
          wfs{1}.tx_win(hidx) = hdr(hidx).tx_win;
          wfs{2}.tx_win(hidx) = hdr(hidx).tx_win;
          wfs{1}.t0(hidx) = hdr(hidx).samp_win_delay;
          wfs{2}.t0(hidx) = hdr(hidx).samp_win_delay;
          if param.records.file.version == 406
            wfs{1}.elem_slots(hidx,:) = [hdr(hidx).elem_1 hdr(hidx).elem_2 hdr(hidx).elem_3 hdr(hidx).elem_4];
            wfs{2}.elem_slots(hidx,:) = [hdr(hidx).elem_1 hdr(hidx).elem_2 hdr(hidx).elem_3 hdr(hidx).elem_4];
            wfs{1}.blank(hidx) = hdr(hidx).rx_blank_end;
            wfs{1}.adc_gains(hidx,:) = 10.^((44-hdr(hidx).low_gain_atten).*ones(1,hdr(hidx).num_elem+1)./20);
            wfs{2}.blank(hidx) = hdr(hidx).hg_blank_end;
            wfs{2}.adc_gains(hidx,:) = 10.^((80-hdr(hidx).high_gain_atten).*ones(1,hdr(hidx).num_elem+1)./20);
          elseif param.records.file.version == 405
            wfs{1}.blank(hidx) = hdr(hidx).rx_blank_end;
            wfs{1}.adc_gains(hidx,:) = 10.^(44-hdr(hidx).low_gain_atten./20);
            wfs{2}.blank(hidx) = hdr(hidx).hg_blank_end;
            wfs{2}.adc_gains(hidx,:) = 10.^(80-hdr(hidx).high_gain_atten./20);
          end
        end
      elseif any(param.records.file.version == [407 408])
        try
          if ~isfield(param.records,'presum_mode')
            error('param.records.presum_mode must be set. 1 for the old DDS and 0 for the new Arena waveform generator.');
          end
          hdr = basic_load_mcords5(fn,struct('presum_mode',param.records.presum_mode));
          hdr_param.frame_sync = uint32(hex2dec('1ACFFC1D'));
          if hdr.file_version == 407
            hdr_param.field_offsets = int32([4 16 20 24]); % epri seconds fractions counter
          elseif hdr.file_version == 408
            hdr_param.field_offsets = int32([4 32 36 48]); % epri seconds fractions counter
          end
          hdr_param.field_types = {uint32(1) uint32(1) uint32(1) uint64(1)};
        catch ME
          if 1
            fprintf('Warning HACK NOT enabled for mcords5 without frame sync field. Enabling may fix this problem.\n');
            rethrow(ME);
          else
            fprintf('Warning HACK enabled for mcords5 without frame sync field\n');
            fn_hack = '/mnt/HDD10/1805101801/UWB/chan6/mcords5_06_20180510_112936_00_0000.bin';
            hdr = basic_load_mcords5(fn_hack,struct('presum_mode',param.records.presum_mode));
            hdr_param.frame_sync = uint32(hex2dec('01600558')); % Used for 20180510 Greenland Polar6 recovery
            hdr_param.field_offsets = int32([4 16 20 24]-36); % epri seconds fractions counter % Used for 20180511 Greenland Polar6 recovery
            hdr_param.field_types = {uint32(1) uint32(1) uint32(1) uint64(1)};
          end
        end
        wfs = hdr.wfs;
        for wf=1:length(wfs); wfs(wf).file_version = hdr.file_version; end;
      elseif any(param.records.file.version == [420])
        hdr = hfrds.basic_load_vapor(fn, struct('file_version',param.records.file.version,'clk',param.config.cresis.clk));
        wfs = hdr.wfs;
      end
    catch ME
      ME.getReport
      warning('  Failed to load... skipping.\n');
      failed_load{board_idx}(fn_idx) = true;
      continue;
    end
    
    if any(param.records.file.version == [1])
      [file_size offset epri seconds fraction] = basic_load_hdr_mex(fn,hdr_param.frame_sync,hdr_param.field_offsets,hdr_param.field_types,hdr_param.file_mode);
      
      % Find bad records by checking their size (i.e. the distance between
      % frame syncs which should be constant).
      expected_rec_size = median(diff(offset));
      meas_rec_size = diff(offset);
      bad_mask = meas_rec_size ~= expected_rec_size;
      bad_mask(end+1) = file_size < offset(end) + expected_rec_size;
      
      % Remove bad records (i.e. ones with sizes that are not expected
      offset = double(offset(~bad_mask));
      epri = double(epri(~bad_mask));
      seconds = double(seconds(~bad_mask));
      fraction = double(fraction(~bad_mask));
      
      save(tmp_hdr_fn,'offset','epri','seconds','fraction','wfs');
      
    elseif any(param.records.file.version == [2])
      [file_size offset epri seconds fraction tmp] = basic_load_hdr_mex(fn,hdr_param.frame_sync,hdr_param.field_offsets,hdr_param.field_types,hdr_param.file_mode);
      loopback = mod(floor(tmp/2^16),2^2) - 1;
      nyquist_zone = mod(tmp,2^3) - 1;
      
      % Find bad records by checking their size (i.e. the distance between
      % frame syncs which should be constant).
      expected_rec_size = median(diff(offset));
      meas_rec_size = diff(offset);
      bad_mask = meas_rec_size ~= expected_rec_size;
      bad_mask(end+1) = file_size < offset(end) + expected_rec_size;
      
      % Remove bad records (i.e. ones with sizes that are not expected
      offset = double(offset(~bad_mask));
      epri = double(epri(~bad_mask));
      seconds = double(seconds(~bad_mask));
      fraction = double(fraction(~bad_mask));
      loopback = double(loopback(~bad_mask));
      nyquist_zone = double(nyquist_zone(~bad_mask));
      
      save(tmp_hdr_fn,'offset','epri','seconds','fraction','loopback','nyquist_zone','wfs');
      
    elseif any(param.records.file.version == [4])
      [file_size offset epri sec1 sec2 fraction] = basic_load_hdr_mex(fn,hdr_param.frame_sync,hdr_param.field_offsets,hdr_param.field_types,hdr_param.file_mode);
      
      % Convert seconds from NMEA ASCII string
      %   64 bits: 00 HH MM SS
      %   ASCII zero is "48"
      seconds = ((floor(sec1/2^8)-48)*10 + mod(sec1,2^8)-48) * 3600 ...
        + ((floor(sec2/2^24)-48)*10 + mod(floor(sec2/2^16),2^8)-48) * 60 ...
        + ((floor(mod(sec2,2^16)/2^8)-48)*10 + mod(mod(sec2,2^16),2^8)-48);
      
      % Find bad records by checking their size (i.e. the distance between
      % frame syncs which should be constant).
      expected_rec_size = median(diff(offset));
      meas_rec_size = diff(offset);
      bad_mask = meas_rec_size ~= expected_rec_size;
      bad_mask(end+1) = file_size < offset(end) + expected_rec_size;
      
      % Remove bad records (i.e. ones with sizes that are not expected
      offset = double(offset(~bad_mask));
      epri = double(epri(~bad_mask));
      seconds = double(seconds(~bad_mask));
      fraction = double(fraction(~bad_mask));
      
      save(tmp_hdr_fn,'offset','epri','seconds','fraction','wfs');
      
    elseif any(param.records.file.version == [3 5 6])
      [file_size offset epri seconds fraction hdr9 hdr10 hdr11] = basic_load_hdr_mex(fn,hdr_param.frame_sync,hdr_param.field_offsets,hdr_param.field_types,hdr_param.file_mode);
      
      start_idx = floor(hdr9/2^16);
      stop_idx = mod(hdr9,2^16);
      NCO_freq_step = mod(hdr10,2^16);
      if param.records.file.version == 6
        nadir_or_sidelooking_select = mod(floor(hdr11/2^24),2^8);
      else
        nyquist_zone = mod(floor(hdr11/2^24),2^8);
      end
      if param.records.file.version == 3
        DDC_filter_select = mod(floor(hdr11/2^16),2^8) + 1;
      else
        DDC_filter_select = mod(floor(hdr11/2^16),2^8);
      end
      if param.records.file.version == 3 || param.records.file.version == 6
        DDC_or_raw_select = mod(hdr11,2^8);
      else
        DDC_or_raw_select = mod(hdr11,2^8);
        DDC_filter_select(DDC_or_raw_select == 1) = DDC_filter_select(DDC_or_raw_select == 1) - 1;
        DDC_or_raw_select(DDC_or_raw_select == 1) = 0;
      end
      if DDC_or_raw_select
        % Raw data
        num_sam = stop_idx - start_idx;
      else
        % DDC data
        num_sam = floor(((stop_idx - start_idx) ./ 2.^(1+DDC_filter_select)));
      end
      HEADER_SIZE = 48;
      SAMPLE_SIZE = 2;
      expected_rec_size = HEADER_SIZE + SAMPLE_SIZE*double(num_sam).*(1+(DDC_or_raw_select==0));
      meas_rec_size = diff(offset);
      bad_mask = meas_rec_size ~= expected_rec_size(1:end-1);
      bad_mask(end+1) = file_size < offset(end) + expected_rec_size(end);
      if any(bad_mask)
        warning('Found %d of %d record size errors', sum(bad_mask), length(bad_mask));
      end
      offset = offset(~bad_mask);
      epri = epri(~bad_mask);
      seconds = seconds(~bad_mask);
      fraction = fraction(~bad_mask);
      
      seconds = BCD_to_seconds(seconds);
      save(tmp_hdr_fn,'offset','epri','seconds','fraction','wfs', ...
        'start_idx','stop_idx','DDC_filter_select','DDC_or_raw_select', ...
        'num_sam','nyquist_zone','NCO_freq_step');
      
    elseif any(param.records.file.version == [8])
      [file_size offset epri seconds fraction counter nyquist_zone start_idx stop_idx waveform_ID] = basic_load_hdr_mex(fn,hdr_param.frame_sync,hdr_param.field_offsets,hdr_param.field_types,hdr_param.file_mode);
      
      HEADER_SIZE = 48;
      SAMPLE_SIZE = 2;
      num_sam = 2*(stop_idx - start_idx);
      expected_rec_size = HEADER_SIZE + SAMPLE_SIZE*double(num_sam);
      meas_rec_size = diff(offset);
      bad_mask = meas_rec_size ~= expected_rec_size(1:end-1);
      % Last record in file is probably bad if its size does not match any
      % of the good records.
      bad_mask(end+1) = all(expected_rec_size(end) ~= expected_rec_size(~bad_mask));
      if sum(bad_mask) > 0
        warning('Found %d of %d record size errors', sum(bad_mask), length(bad_mask));
      end
      offset = offset(~bad_mask);
      epri = epri(~bad_mask);
      seconds = seconds(~bad_mask);
      fraction = fraction(~bad_mask);
      counter = counter(~bad_mask);
      nyquist_zone = nyquist_zone(~bad_mask);
      start_idx = start_idx(~bad_mask);
      stop_idx = stop_idx(~bad_mask);
      waveform_ID = waveform_ID(~bad_mask);
      
      seconds = BCD_to_seconds(seconds);
      save(tmp_hdr_fn,'offset','epri','seconds','fraction','wfs', ...
        'counter','nyquist_zone','start_idx','stop_idx','waveform_ID');
      
    elseif any(param.records.file.version == [101])
      [file_size offset unknown seconds fraction] = basic_load_hdr_mex(fn,hdr_param.frame_sync,hdr_param.field_offsets,hdr_param.field_types,hdr_param.file_mode);
      
      % Find bad records by checking their size (i.e. the distance between
      % frame syncs which should be constant).
      expected_rec_size = median(diff(offset));
      meas_rec_size = diff(offset);
      bad_mask = meas_rec_size ~= expected_rec_size;
      bad_mask(end+1) = file_size < offset(end) + expected_rec_size;
      
      % Remove bad records (i.e. ones with sizes that are not expected
      offset = double(offset(~bad_mask));
      unknown = double(unknown(~bad_mask));
      seconds = double(seconds(~bad_mask));
      fraction = double(fraction(~bad_mask));
      
      save(tmp_hdr_fn,'offset','unknown','seconds','fraction');
      
    elseif any(param.records.file.version == [102])
      [file_size offset radar_time_ms radar_time_ls radar_time_1pps_ms radar_time_1pps_ls] ...
        = basic_load_hdr_mex(fn,hdr_param.frame_sync,hdr_param.field_offsets,hdr_param.field_types,hdr_param.file_mode);
      radar_time = (hdr_data(3,:)*2^32 + hdr_data(4,:)) / (param.records.file.clk/100);
      radar_time_1pps = (hdr_data(5,:)*2^32 + hdr_data(6,:)) / (param.records.file.clk/100);
      
      save(tmp_hdr_fn,'offset','radar_time','radar_time_1pps','wfs');
      
    elseif any(param.records.file.version == [401])
      error('Not supported');
      
    elseif any(param.records.file.version == [402])
      error('Not supported');
      
    elseif any(param.records.file.version == [403])
      [file_size offset epri seconds fraction counter] = basic_load_hdr_mex(fn,hdr_param.frame_sync,hdr_param.field_offsets,hdr_param.field_types,hdr_param.file_mode);
      seconds = BCD_to_seconds(seconds);
      
      % Find bad records by checking their size
      % The distance between frame syncs should be constant
      expected_rec_size = median(diff(offset));
      meas_rec_size = diff(offset);
      bad_mask = all(bsxfun(@(x,y) x ~= y, meas_rec_size, expected_rec_size(:)),1);
      % Note that we always assume that the last record in the file is
      % good (since it is a partial record and we would have to look at
      % the next file to see if the complete record is there)
      bad_mask(end+1) = false;
      
      % Remove bad records (i.e. ones with sizes that are not expected
      offset = double(offset(~bad_mask));
      epri = double(epri(~bad_mask));
      seconds = double(seconds(~bad_mask));
      fraction = double(fraction(~bad_mask));
      counter = double(counter(~bad_mask));
      
      save(tmp_hdr_fn,'offset','epri','seconds','fraction','counter','wfs');
      
    elseif any(param.records.file.version == [404])
      [file_size offset epri seconds fraction counter] = basic_load_hdr_mex(fn,hdr_param.frame_sync,hdr_param.field_offsets,hdr_param.field_types,hdr_param.file_mode);
      seconds = BCD_to_seconds(seconds);
      
      % Find bad records by checking their size
      % The distance between frame syncs should be constant
      expected_rec_size = median(diff(offset));
      meas_rec_size = diff(offset);
      bad_mask = all(bsxfun(@(x,y) x ~= y, meas_rec_size, expected_rec_size(:)),1);
      % Note that we always assume that the last record in the file is
      % good (since it is a partial record and we would have to look at
      % the next file to see if the complete record is there)
      bad_mask(end+1) = false;
      
      % Remove bad records (i.e. ones with sizes that are not expected
      offset = double(offset(~bad_mask));
      epri = double(epri(~bad_mask));
      seconds = double(seconds(~bad_mask));
      fraction = double(fraction(~bad_mask));
      counter = double(counter(~bad_mask));
      
      save(tmp_hdr_fn,'offset','epri','seconds','fraction','counter','wfs');
      
    elseif any(param.records.file.version == [405 406])
      % Load header information that can change on every record AND
      % is required for records generation (radar time)
      %     radar_time =
      file_size = 0;
      offset = [];
      seconds = [];
      % Get header timestamps and offsets
      [hdr htime hoffset] = basic_load_acords(fn,struct('datatype',0,'file_version',param.records.file.version,'verbose',0));
      raw_file_time = htime(1);
      % Get data records timestamps and offsets
      [data seconds offset] = basic_load_acords(fn,struct('datatype',2,'file_version',param.records.file.version,'verbose',0));
      fractions = zeros(size(seconds));
      save(tmp_hdr_fn,'offset','seconds','hdr','hoffset','htime','wfs','raw_file_time');
      
    elseif any(param.records.file.version == [7 11 407 408])
      hdr_param.field_types = {uint32(1) uint32(1) uint32(1) uint64(1)};
      [file_size offset epri seconds fraction counter] = basic_load_hdr_mex(fn,hdr_param.frame_sync,hdr_param.field_offsets,hdr_param.field_types,hdr_param.file_mode);
      seconds = BCD_to_seconds(seconds);
      
      % Find bad records by checking their size
      if any(param.records.file.version == [407 408])
        % The distance between frame syncs should be constant
        expected_rec_size = median(diff(offset));
        meas_rec_size = diff(offset);
        bad_mask = all(bsxfun(@(x,y) x ~= y, meas_rec_size, expected_rec_size(:)),1);
        % Note that we always assume that the last record in the file is
        % good (since it is a partial record and we would have to look at
        % the next file to see if the complete record is there)
        bad_mask(end+1) = false;
        
      elseif any(param.records.file.version == [7 11])
        % User must supply the valid record sizes
        if ~isfield(param.config.cresis,'expected_rec_sizes') || isempty(param.config.cresis.expected_rec_sizes)
          fprintf('Record sizes found in this file:\n');
          fprintf('  %d', unique(diff(offset)));
          fprintf('\n');
          error('For file version 7 expected record sizes must be supplied in param.config.cresis.expected_rec_sizes (usually set in default_radar_params_SEASON_RADAR). You can start by using the record sizes listed here, but there may be other valid record sizes and the output of this function should be monitored.');
        end
        expected_rec_size = param.config.cresis.expected_rec_sizes;
        meas_rec_size = diff(offset);
        bad_mask = all(bsxfun(@(x,y) x ~= y, meas_rec_size, expected_rec_size(:)),1);
        if any(bad_mask)
          fprintf('Record sizes found in this file:\n');
          fprintf('  %d', unique(diff(offset)));
          fprintf('\n');
          warning('param.config.cresis.expected_rec_sizes does not match %d of the records in this file. Records not matching are removed. If these are valid records, update param.config.cresis.expected_rec_sizes.', sum(bad_mask));
        end
        bad_mask(end+1) = false;
      end
      
      % Remove bad records (i.e. ones with sizes that are not expected
      offset = double(offset(~bad_mask));
      epri = double(epri(~bad_mask));
      seconds = double(seconds(~bad_mask));
      fraction = double(fraction(~bad_mask));
      counter = double(counter(~bad_mask));
      
      save(tmp_hdr_fn,'offset','epri','seconds','fraction','counter','wfs');
     
    elseif any(param.records.file.version == [420])
      [file_size offset epri seconds fraction] = basic_load_hdr_mex(fn,hdr_param.frame_sync,hdr_param.field_offsets,hdr_param.field_types,hdr_param.file_mode);
      seconds = BCD_to_seconds(seconds,1);
      
      % Find bad records by checking their size (i.e. the distance between
      % frame syncs which should be constant).
      expected_rec_size = median(diff(offset));
      meas_rec_size = diff(offset);
      bad_mask = meas_rec_size ~= expected_rec_size;
      bad_mask(end+1) = file_size < offset(end) + expected_rec_size;
      
      % Remove bad records (i.e. ones with sizes that are not expected
      offset = double(offset(~bad_mask));
      epri = double(epri(~bad_mask));
      seconds = double(seconds(~bad_mask));
      fraction = double(fraction(~bad_mask));
      
      save(tmp_hdr_fn,'offset','epri','seconds','fraction','wfs');
    end
    
    % Load and concatenate temporary file
    if any(param.records.file.version == [101])
      hdr = load(tmp_hdr_fn);
      board_hdrs{board_idx}.unknown ...
        = cat(2,board_hdrs{board_idx}.unknown,reshape(hdr.unknown,[1 length(hdr.unknown)]));
      board_hdrs{board_idx}.seconds ...
        = cat(2,board_hdrs{board_idx}.seconds,reshape(hdr.seconds,[1 length(hdr.seconds)]));
      board_hdrs{board_idx}.fraction ...
        = cat(2,board_hdrs{board_idx}.fraction,reshape(hdr.fraction,[1 length(hdr.fraction)]));
    elseif any(param.records.file.version == [102])
      hdr = load(tmp_hdr_fn);
      board_hdrs{board_idx}.radar_time ...
        = cat(2,board_hdrs{board_idx}.radar_time,hdr.radar_time);
      board_hdrs{board_idx}.radar_time_1pps ...
        = cat(2,board_hdrs{board_idx}.radar_time_1pps,hdr.radar_time_1pps);
    elseif any(param.records.file.version == [405 406])
      hdr = load(tmp_hdr_fn);
      hdr_log = [hdr_log,hdr.hdr];
      hdr_raw = [hdr_raw fn_idx*ones(1,length(hdr.hdr))];
      htime = [htime hdr.htime];
      board_hdrs{board_idx}.seconds ...
        = cat(2,board_hdrs{board_idx}.seconds,reshape(hdr.seconds,[1 length(hdr.seconds)]));
    else
      hdr = load(tmp_hdr_fn);
      board_hdrs{board_idx}.epri ...
        = cat(2,board_hdrs{board_idx}.epri,reshape(hdr.epri,[1 length(hdr.epri)]));
      board_hdrs{board_idx}.seconds ...
        = cat(2,board_hdrs{board_idx}.seconds,reshape(hdr.seconds,[1 length(hdr.seconds)]));
      board_hdrs{board_idx}.fraction ...
        = cat(2,board_hdrs{board_idx}.fraction,reshape(hdr.fraction,[1 length(hdr.fraction)]));
      if any(param.records.file.version == [8])
        board_hdrs{board_idx}.waveform_ID = cat(2,board_hdrs{board_idx}.waveform_ID,reshape(hdr.waveform_ID,[1 length(hdr.waveform_ID)]));
      elseif any(param.records.file.version == [403 407 408])
        board_hdrs{board_idx}.counter = cat(2,board_hdrs{board_idx}.counter,reshape(hdr.counter,[1 length(hdr.counter)]));
      end
    end
    board_hdrs{board_idx}.file_idxs = cat(2,board_hdrs{board_idx}.file_idxs,fn_idx*ones([1 length(hdr.offset)]));
    
  end
end

% Save concatenated temporary file
fn_board_hdrs_dir = fileparts(fn_board_hdrs);
if ~exist(fn_board_hdrs_dir,'dir')
  mkdir(fn_board_hdrs_dir);
end
save(fn_board_hdrs,'-v7.3','board_hdrs','fns_list','failed_load');

%% List bad files
% =========================================================================
for board_idx = 1:numel(param.records.file.boards)
  if any(failed_load{board_idx})
    warning('Some files failed to load, consider deleting these to avoid problems:');
    for fn_idx = find(failed_load{board_idx})
      fprintf('  %s\n', fns_list{board_idx}{fn_idx});
    end
  end
end

%% waveform_ID Debug
% =========================================================================
if 0
  % waveform_ID decoding for: any(param.records.file.version == [8])
  keyboard
  waveform_ID_unique = unique(waveform_ID)
  waveform_ID_char = char(reshape(typecast(waveform_ID_unique,'int8'),[8 length(waveform_ID_unique)]).')
  dec2bin(waveform_ID_unique)
  % Manually create the map from waveform_ID_unique values to tref using
  % the above three outputs:
  waveform_map = [uint64(2314885530819506224) 0
    uint64(2314885530819508528) 9
    uint64(2314885530819572272) 12
    uint64(2314885530819703600) 33
    uint64(4629771061639012448) 0
    uint64(4629771061639017056) 9
    uint64(4629771061639144544) 12
    uint64(4629771061639407200) 33
    uint64(5713170579264979799) 0];
  % Use manually created map to map from waveform_ID to tref:
  waveform_t_ref = nan(size(waveform_ID));
  for idx = 1:size(waveform_map,1)
    waveform_t_ref(waveform_map(idx,1) == waveform_ID) = double(waveform_map(idx,2)) * 1.0e-6;
  end
  any(isnan(waveform_t_ref))
  plot(waveform_t_ref);
  xlabel('Record');
  ylabel('t\_ref (us)')
  
  % Example from 20170426:
  %
  % waveform_ID_unique =
  %   Columns 1 through 6
  %   2314885530819506224  2314885530819508528  2314885530819572272  2314885530819703600  4629771061639012448  4629771061639017056
  %   Columns 7 through 9
  %   4629771061639144544  4629771061639407200  5713170579264979799
  % waveform_ID_char = char(reshape(typecast(waveform_ID_unique,'int8'),[8 length(waveform_ID_unique)]).')
  % waveform_ID_char =
  % 000
  % 090
  % 021
  % 033
  % ```@@@@@
  % `r`@@@@@
  % `db@@@@@
  % `ff@@@@@
  % WCMF_BIO
  % ans =
  % 010000000100000001000000010000000100000001100000011000000000000
  % 010000000100000001000000010000000100000001100000011101000000000
  % 010000000100000001000000010000000100000001100010011001000000000
  % 010000000100000001000000010000000100000001100110011010000000000
  % 100000001000000010000000100000001000000011000000110000000000000 <-- 1-bit shift error
  % 100000001000000010000000100000001000000011000000111010000000000 <-- 1-bit shift error
  % 100000001000000010000000100000001000000011000100110010000000000 <-- 1-bit shift error
  % 100000001000000010000000100000001000000011001100110100000000000 <-- 1-bit shift error
  % 100111101001001010000100101111101000110010011010100010000000000 <-- manually determine tref
end
  
%% Online Mode
% =========================================================================
if param.config.online_mode
  
  for board_idx = 1:numel(param.records.file.boards)
    epri_jumps = diff(double(board_hdrs{board_idx}.epri));
    fprintf('Board %d: List of up to 10 last EPRI jumps of >100 records:\n', board_idx);
    bad_jumps = epri_jumps(abs(epri_jumps) > 100);
    fprintf('  %.0f jumps. Up to last 10: ', length(bad_jumps));
    fprintf(' %.0f', bad_jumps(max(1,end-9):end));
    fprintf(' record jumps\n');
    
    utc_time_sod = double(board_hdrs{board_idx}.seconds) + double(board_hdrs{board_idx}.fraction) / param.records.file.clk;
    fprintf('Board %d: UTC time SOD jumps of >0.5 sec:\n', board_idx);
    utc_time_sod_jumps = diff(utc_time_sod);
    bad_jumps = utc_time_sod_jumps(abs(utc_time_sod_jumps) > 0.5);
    fprintf('  %.0f jumps. Up to last 10: ', length(bad_jumps));
    fprintf(' %.1f', bad_jumps(max(1,end-9):end));
    fprintf(' second jumps\n');
  end
  
  return;
end
  
%% Correct time variable
% =========================================================================
for board_idx = 1:numel(param.records.file.boards)
  
  if any(param.records.file.version == [1 2 3 4 5 6 7 8 11 101 403 404 407 408 420])
    utc_time_sod = double(board_hdrs{board_idx}.seconds) + double(board_hdrs{board_idx}.fraction) / param.records.file.clk;
    epri = double(board_hdrs{board_idx}.epri);
    
    if 0
      % Test sequences
      utc_time_sod = [0 1 2 3 10000 5 6 7 8 9 10 11 12 13 24 25 26 27 28 19 20 21 22 19 20 21 22]
      utc_time_sod = utc_time_sod + 0.0001*randn(size(utc_time_sod))
      epri = 100 + [1:23, 20:23]
      epri(15) = 5000;
    end
    
    % Estimate the pulse repetition interval, PRI
    PRI = medfilt1(diff(utc_time_sod),51);
    
    % Create an EPRI sequence from the time record
    time_epri = utc_time_sod(1)/PRI(1) + [0 cumsum(diff(utc_time_sod) ./ PRI)];
    [~,good_time_idx] = min(abs(utc_time_sod - median(utc_time_sod)));
    time_epri = time_epri - time_epri(good_time_idx);
    
    % Find the difference of the time-generated epri and the recorded epri
    dtime_epri = diff(time_epri);
    depri = diff(epri);
    
    % Find good/bad differences. Mask values are:
    %  0: both differences are bad
    %  1: EPRI good
    %  2: Time-generated EPRI good
    %  3: EPRI and time-generated EPRI good
    % "EPRI good" means that depri == 1
    % "Time-generated EPRI good" means 0.9 < dtime_epri < 1.1
    dtime_epri_threshold = 0.1; % Allow for 10% PRI error
    mask = (depri == 1) + (2*(abs(dtime_epri-1) < dtime_epri_threshold));
    % If the EPRI's both indicate the same number of skipped records,
    % consider it a good difference.
    mask(mask ~= 3 & depri == round(dtime_epri)) = 3;
    
    % Fix differenced time-generated EPRIs using differenced EPRIs
    dtime_epri(mask==1) = depri(mask==1);
    % Fix differenced EPRIs using differenced time-generated EPRIs
    depri(mask==2) = round(dtime_epri(mask==2));
    
    % Find sequences of good records (where mask > 0) and deal with each
    % segment separately.
    good_out_mask = false(size(utc_time_sod));
    start_idx = find(mask ~= 0,1);
    while ~isempty(start_idx)
      stop_idx = start_idx-1 + find(mask(start_idx+1:end) == 0,1);
      if isempty(stop_idx)
        stop_idx = numel(mask);
      end
      
      % Find a median point in each segment and assume this value is good
      [~,good_time_idx] = min(abs(utc_time_sod(start_idx:stop_idx+1) - median(utc_time_sod(start_idx:stop_idx+1))));
      [~,good_epri_idx] = min(abs(epri(start_idx:stop_idx+1) - median(epri(start_idx:stop_idx+1))));
      
      % Reconstruct epri
      tmp = [0 cumsum(depri(start_idx:stop_idx))];
      tmp = tmp - tmp(good_epri_idx) + epri(start_idx-1+good_epri_idx);
      
      % Reconstruct time from time-generated EPRIs
      tmp = [0 cumsum(dtime_epri(start_idx:stop_idx).*PRI(start_idx:stop_idx))];
      tmp = tmp - tmp(good_time_idx) + utc_time_sod(start_idx-1+good_time_idx);
      utc_time_sod_new(start_idx:stop_idx+1) = tmp;
      
      % Mark these records as good outputs
      good_out_mask(start_idx:stop_idx+1) = true;
      
      % Find the next sequence
      start_idx = stop_idx + find(mask(stop_idx+1:end) ~= 0,1);
    end
    
    % START IMPORTANT TIME CORRECTION
    
    % NOTE: If custom per-day utc_time_sod corrections are required,
    % include that code here to change the utc_time_sod_new.m. This
    % function should be able to identify the radar and date of the data
    % and apply the custom correction based on that.
    
    % utc_time_sod_new = preprocess_task_cresis_custom(); % <-- CREATE
    
    % END IMPORTANT TIME CORRECTION
    
    h_fig = get_figures(3,param.config.plots_visible,mfilename);
    
    clf(h_fig(1)); h_axes = axes('parent',h_fig(1));
    set(h_fig(1),'NumberTitle','off');
    set(h_fig(1),'Name',sprintf('%d: UTC Time',h_fig(1).Number));
    plot(h_axes,utc_time_sod);
    hold(h_axes,'on');
    plot(h_axes,find(good_out_mask), utc_time_sod_new(good_out_mask),'r.');
    hold(h_axes,'off');
    xlabel(h_axes,'Record number');
    ylabel(h_axes,'UTC Time SOD (sec)');
    legend(h_axes,'Original','Corrected','location','best');
    title(h_axes,sprintf('%s: UTC time original and corrected should\nmatch except at outliers',param.config.date_str),'fontsize',10);
    
    UTC_MAX_ERROR = 0.1;
    clf(h_fig(2)); h_axes = axes('parent',h_fig(2));
    set(h_fig(2),'NumberTitle','off');
    set(h_fig(2),'Name',sprintf('%d: Time Correction',h_fig(1).Number));
    plot(h_axes,find(good_out_mask), utc_time_sod(good_out_mask) - utc_time_sod_new(good_out_mask),'.');
    xlabel(h_axes,'Record number');
    ylabel(h_axes,'Time correction (sec)');
    ylim(h_axes,[-UTC_MAX_ERROR UTC_MAX_ERROR]);
    title(h_axes,sprintf('%s: Time correction should be within limits\nexcept for a few outliers.',param.config.date_str),'fontsize',10);
    
    clf(h_fig(3)); h_axes = axes('parent',h_fig(3));
    set(h_fig(3),'NumberTitle','off');
    set(h_fig(3),'Name',sprintf('%d: Diff EPRI',h_fig(1).Number));
    h_axes = subplot(2,1,1);
    plot(h_axes,diff(epri),'.');
    ylabel(h_axes,'Diff EPRI');
    h_axes = subplot(2,1,2);
    plot(h_axes,diff(epri),'.');
    ylim(h_axes,[-3 5]);
    xlabel(h_axes,'Record number');
    ylabel(h_axes,'Diff EPRI');
    title(h_axes,sprintf('%s: Should be 1 except occasional record drops.',param.config.date_str),'fontsize',10);
    
    fn_fig = ct_filename_ct_tmp(param,'','headers', sprintf('preprocess_%s_utc_time_sod_board_%d.fig',param.config.date_str,board_idx));
    fn_fig_dir = fileparts(fn_fig);
    if ~exist(fn_fig_dir,'dir')
      mkdir(fn_fig_dir);
    end
    fprintf('Saving %s\n', fn_fig);
    saveas(h_fig(1),fn_fig);
    fn_fig = [fn_fig(1:end-3), 'jpg'];
    fprintf('Saving %s\n', fn_fig);
    saveas(h_fig(1),fn_fig);
    fn_fig = ct_filename_ct_tmp(param,'','headers', sprintf('preprocess_%s_utc_time_sod_error_board_%d.fig',param.config.date_str,board_idx));
    fprintf('Saving %s\n', fn_fig);
    saveas(h_fig(2),fn_fig);
    fn_fig = [fn_fig(1:end-3), 'jpg'];
    fprintf('Saving %s\n', fn_fig);
    saveas(h_fig(2),fn_fig);
    fn_fig = ct_filename_ct_tmp(param,'','headers', sprintf('preprocess_%s_epri_board_%d.fig',param.config.date_str,board_idx));
    fprintf('Saving %s\n', fn_fig);
    saveas(h_fig(3),fn_fig);
    fn_fig = [fn_fig(1:end-3), 'jpg'];
    fprintf('Saving %s\n', fn_fig);
    saveas(h_fig(3),fn_fig);
    
    utc_time_sod = utc_time_sod_new;
    utc_time_sod(~good_out_mask) = NaN;
    utc_time_sod = interp_finite(utc_time_sod,NaN);
    
    % Check for day wraps in the UTC time seconds of day
    day_wrap_idxs = find(diff(utc_time_sod) < -50000);
    board_hdrs{board_idx}.day_wrap_offset = zeros(size(utc_time_sod));
    if ~isempty(day_wrap_idxs)
      fprintf('Found %d potential day wraps in board %d. Unwrapping times.', numel(day_wrap_idxs), board_idx);
      board_hdrs{board_idx}.day_wrap_offset = zeros(size(utc_time_sod));
      for day_wrap_idx = day_wrap_idxs
        board_hdrs{board_idx}.day_wrap_offset(day_wrap_idx+1:end) = board_hdrs{board_idx}.day_wrap_offset(day_wrap_idx+1:end) + 86400;
      end
      utc_time_sod = utc_time_sod + board_hdrs{board_idx}.day_wrap_offset;
    end
    
    clear depri dtime_epri dtime_epri_threshold time_epri utc_time_sod_new day_wrap_idxs;
    board_hdrs{board_idx}.utc_time_sod = utc_time_sod;
    board_hdrs{board_idx}.epri = epri;
    
  elseif any(param.records.file.version == [405 406])
    utc_time_sod = board_hdrs{board_idx}.seconds; % this is actually comp_time but doesn't need to
    % be converted to actual utc_time_sod since it's only looking at gaps in
    % the data
    
    day_wrap_idxs = find(diff(utc_time_sod) < -50000);
    day_wrap_offset = zeros(size(utc_time_sod));
    for day_wrap_idx = day_wrap_idxs
      day_wrap_offset(day_wrap_idx+1:end) = day_wrap_offset(day_wrap_idx+1:end) + 86400;
    end
    utc_time_sod = utc_time_sod + day_wrap_offset;
    
    time_gaps = find(abs(diff(utc_time_sod)) > MAX_TIME_GAP);
    
    reason = {};
    
    figure(1); clf;
    plot(utc_time_sod);
    ylabel('UTC time seconds of day');
    xlabel('Record');
    grid on;
    hold on;
    plot(time_gaps, utc_time_sod(time_gaps),'ro');
    hold off;
    
    names = fieldnames(hdr_log(1));
    if param.records.file.version == 406
      change_fields = [2 5 6 7 8 9 10 11 12 17 18 19 20 21];
    elseif param.records.file.version == 405
      change_fields = [2 5 6 7 8 9 10 11 12];
    end
    
    % Detect changes in header file information that would necessitate
    % creating a new segment.
    hdr_gaps = [];
    change_log = {};
    for n_idx = change_fields
      %     fprintf('Checking %s...\n',names{n_idx})
      hdr_changes = eval(sprintf('find(diff(squeeze(horzcat(hdr_log(:).%s))) ~= 0)',names{n_idx}));
      hdr_gaps = [hdr_gaps, hdr_changes];
      if ~isempty(hdr_changes)
        reason = [reason; repmat({names{n_idx}},eval(sprintf('length(find(diff(squeeze(horzcat(hdr_log(:).%s))) ~= 0))',names{n_idx})),1)];
        for cl_idx=1:length(hdr_changes)
          change_log{end+1} = eval(sprintf('[hdr_log(hdr_changes(cl_idx)).%s hdr_log(hdr_changes(cl_idx)+1).%s]',names{n_idx},names{n_idx}));
        end
      end
    end
    
    [hdr_gaps I J] = unique(hdr_gaps);
    comb_reason = cell(1,length(I));
    comb_change = cell(1,length(I));
    for uidx=1:length(J)
      comb_reason{J(uidx)} = [comb_reason{J(uidx)} reason{uidx}];
      comb_change{J(uidx)} = [comb_change{J(uidx)} change_log{uidx}];
    end
    
    % Convert from file index to file offset
    hdr_idxs = [];
    time_idxs = [];
    for gaps_idx = 1:length(hdr_gaps)
      hdr_idxs(gaps_idx) = find(utc_time_sod == htime(hdr_gaps(gaps_idx)+1),1,'last')-1;
    end
    
    if ~isempty(hdr_gaps)
      figure(1);
      hold on;
      plot(hdr_idxs, utc_time_sod(hdr_idxs),'go');
      hold off;
    end
    
    [time_gaps I J] = unique([time_gaps hdr_idxs]);
    if ~isempty(reason)
      extend_unique = [repmat({'time'},length(time_gaps),1); comb_reason.'];
      reason_unique = extend_unique(I);
      extend_change_log = [repmat({'N/A'},length(time_gaps),1); comb_change.'];
      change_log_unique = extend_change_log(I);
    else
      reason_unique = repmat({''},length(I),1);
      change_log_unique = repmat({''},length(I),1);
    end
  else
    error('Not supported');
  end

  board_hdrs{board_idx}.utc_time_sod = utc_time_sod;
  board_hdrs{board_idx}.epri = epri;
end

% if any(strcmpi(radar_name,{'accum'}))
%   %% Accum filter of bad records
%   % Repeated data often occurs in accum during a FIFO overflow. Remove
%   % these blocks.
%   bad_mask = zeros(size(utc_time-sod));
%   start_segment_time = utc_time_sod(1);
%   cur_time = utc_time_sod(1);
%   for idx = 2:utc_time_sod
%     diff_time = utc_time_sod(idx) - utc_time_sod(idx-1);
%     if diff_time > MAX_TIME_GAP
%       start_segment_time = utc_time_sod(idx);
%       cur_time = utc_time_sod(idx);
%     else
%       if utc_time_sod(idx) < start_segment_time
%       end
%       if utc_time_sod(idx) < cur_time
%         bad_mask(idx) = 1;
%       end
%     end
%   end
% end

%% Create Segments
% =========================================================================

if any(param.records.file.version == [403 404 407 408])
  %% Create Segments: Read XML settings
  % NI XML settings files available, break segments based on settings files
  % and header information
  
  xml_version = param.config.cresis.config_version;
  cresis_xml_mapping;
  
  settings_fn_dir = fullfile(param.config.base_dir,param.config.config_folder_names);
  fprintf('\nSettings Directory: %s\n\n', settings_fn_dir);
  
  % Read XML files in this directory
  [settings,~] = read_ni_xml_directory(settings_fn_dir,xml_file_prefix,false);
  
  % Get the date information out of the filename
  fn_datenums = {};
  for board_idx = 1:numel(param.records.file.boards)
    fn_datenums{board_idx} = [];
    for data_fn_idx = 1:length(fns_list{board_idx})
      fname = fname_info_mcords2(fns_list{board_idx}{data_fn_idx});
      fn_datenums{board_idx}(end+1) = fname.datenum;
    end
  end
  
  %% Create Segments: Print settings
  oparams = {};
  [~,defaults] = param.config.default();
  for set_idx = 1:length(settings)
    % Print out settings
    [~,settings_fn_name] = fileparts(settings(set_idx).fn);
    fprintf('===================== Setting %d =================\n', set_idx);
    fprintf('%s: %d waveforms\n', settings_fn_name, length(settings(set_idx).(config_var).Waveforms));
    if isfield(settings(set_idx),'XML_File_Path')
      fprintf('  %s\n', settings(set_idx).XML_File_Path{1}.values{1});
    end
    fprintf('   PRF:'); fprintf(' %g', settings(set_idx).(config_var).(prf_var)); fprintf('\n');
    fprintf('   Amp:'); fprintf(' %g', settings(set_idx).(config_var).(ram_amp_var)); fprintf('\n');
    fprintf('   Tukey:'); fprintf(' %g', settings(set_idx).(config_var).RAM_Taper); fprintf('\n');
    Tpd = double(settings(set_idx).(config_var).Waveforms(1).Len_Mult)*settings(set_idx).(config_var).Base_Len;
    fprintf('   f0-f1:'); fprintf(' %g-%g MHz %g us', settings(set_idx).(config_var).Waveforms(1).Start_Freq(1)/1e6, ...
      settings(set_idx).(config_var).Waveforms(1).Stop_Freq(1)/1e6, Tpd*1e6); fprintf('\n');
    fprintf('   Tx Mask:'); fprintf(' %g', settings(set_idx).(config_var).Waveforms(1).TX_Mask); fprintf('\n');
    for wf = 1:length(settings(set_idx).(config_var).Waveforms)
      fprintf('    WF %d Atten:', wf); fprintf(' %g', settings(set_idx).(config_var).Waveforms(wf).Attenuator_2); fprintf('\n');
      fprintf('    WF %d Len:', wf); fprintf(' %.1f us', 1e6*settings(set_idx).(config_var).Base_Len*settings(set_idx).(config_var).Waveforms(wf).Len_Mult); fprintf('\n');
    end
    
    for board_idx = 1:numel(param.records.file.boards)
      if set_idx < length(settings)
        settings(set_idx).file_matches{board_idx} = find(fn_datenums{board_idx} >= settings(set_idx).datenum & fn_datenums{board_idx} < settings(set_idx+1).datenum);
      else
        settings(set_idx).file_matches{board_idx} = find(fn_datenums{board_idx} >= settings(set_idx).datenum);
      end
    end
    
    % Associate default parameters with each settings
    default = default_radar_params_settings_match(defaults,settings(set_idx));
    default = merge_structs(param,default);
    oparams{end+1} = default;
    try; oparams{end} = rmfield(oparams{end},'config_regexp'); end;
    try; oparams{end} = rmfield(oparams{end},'name'); end;
    
    % Parameter spreadsheet
    % =======================================================================
    oparams{end}.cmd.notes = default.name;
    
    oparams{end}.records.file.base_dir = param.config.base_dir;
    oparams{end}.records.file.board_folder_name = param.config.board_folder_names;
    if ~isempty(oparams{end}.records.file.board_folder_name) ...
        && oparams{end}.records.file.board_folder_name(1) ~= filesep
      % Ensures that board_folder_name is not a text number which Excel
      % will misinterpret as a numeric type
      oparams{end}.records.file.board_folder_name = ['/' oparams{end}.records.file.board_folder_name];
    end
    oparams{end}.records.file.boards = param.records.file.boards;
    oparams{end}.records.file.version = param.records.file.version;
    oparams{end}.records.file.prefix = param.records.file.prefix;
    oparams{end}.records.file.clk = param.records.file.clk;
    oparams{end}.radar.prf = settings(set_idx).(config_var).(prf_var);

    % Usually the default.radar.wfs structure only has one waveform
    % entry which is to be copied to all the waveforms.
    if numel(oparams{end}.radar.wfs) == 1
      oparams{end}.radar.wfs = repmat(oparams{end}.radar.wfs,[1 numel(settings(set_idx).(config_var).Waveforms)]);
    end
      
    for wf = 1:numel(settings(set_idx).(config_var).Waveforms)
      oparams{end}.radar.wfs(wf).Tpd = double(settings(set_idx).(config_var).Waveforms(wf).Len_Mult)*settings(set_idx).(config_var).Base_Len;
      oparams{end}.radar.wfs(wf).f0 = settings(set_idx).(config_var).Waveforms(wf).Start_Freq(1);
      oparams{end}.radar.wfs(wf).f1 = settings(set_idx).(config_var).Waveforms(wf).Stop_Freq(1);
      oparams{end}.radar.wfs(wf).tukey = settings(set_idx).(config_var).RAM_Taper;
      % Transmit weights
      if any(param.records.file.version == [403 407 408])
        tx_mask_inv = fliplr(~(dec2bin(double(settings(set_idx).(config_var).Waveforms(wf).TX_Mask),8) - '0'));
        tx_weights = double(settings(set_idx).(config_var).(ram_var)) .* tx_mask_inv ./ param.config.max_tx.*param.config.max_tx_voltage;
      else
        tx_mask_inv = ~(dec2bin(double(settings(set_idx).(config_var).Waveforms(wf).TX_Mask),8) - '0');
        tx_weights = double(settings(set_idx).(config_var).(ram_var)) .* tx_mask_inv ./ param.config.max_tx.*param.config.max_tx_voltage;
      end

      tx_weights = tx_weights(logical(param.config.tx_enable));
      oparams{end}.radar.wfs(wf).tx_weights = tx_weights;
      
      % ADC Gains
      atten = double(settings(set_idx).(config_var).Waveforms(wf).Attenuator_1(1)) ...
        + double(settings(set_idx).(config_var).Waveforms(wf).Attenuator_2(1));
      if isfield(oparams{end}.radar.wfs(wf),'rx_paths')
        oparams{end}.radar.wfs(wf).adc_gains_dB = param.config.cresis.rx_gain_dB - atten(1)*ones(1,length(oparams{end}.radar.wfs(wf).rx_paths));
      else
        oparams{end}.radar.wfs(wf).adc_gains_dB = param.config.cresis.rx_gain_dB - atten(1)*ones(1,length(oparams{end}.radar.rx_paths));
      end
      
      % DDC mode and frequency
      if isfield(settings(set_idx), 'DDC_Ctrl')
        oparams{end}.radar.wfs(wf).DDC_dec = 2^(1+settings(set_idx).DDC_Ctrl.DDC_sel.Val);
        oparams{end}.radar.wfs(wf).DDC_freq = settings(set_idx).DDC_Ctrl.(NCO_freq)*1e6;
      else
        oparams{end}.radar.wfs(wf).DDC_dec = 1;
        oparams{end}.radar.wfs(wf).DDC_freq = 0;
      end
    end
    
    counters = {};
    file_idxs = {};
    for board_idx = 1:numel(param.records.file.boards)
      counters{board_idx} = double(board_hdrs{board_idx}.(param.config.field_time_gap));
      file_idxs{board_idx} = board_hdrs{board_idx}.file_idxs;
      day_wrap_offset{board_idx} = board_hdrs{board_idx}.day_wrap_offset;
      % Restrict to just these settings
      if isempty(settings(set_idx).file_matches{board_idx})
        counters{board_idx} = [];
        file_idxs{board_idx} = [];
      else
        mask = file_idxs{board_idx} >= settings(set_idx).file_matches{board_idx}(1) ...
          & file_idxs{board_idx} <= settings(set_idx).file_matches{board_idx}(end);
        counters{board_idx} = counters{board_idx}(mask);
        file_idxs{board_idx} = file_idxs{board_idx}(mask);
        day_wrap_offset{board_idx} = day_wrap_offset{board_idx}(mask);
      end
    end
    [segs,stats] = preprocess_create_segments(counters,file_idxs,day_wrap_offset,param.config.max_time_gap,param.config.segment_end_file_trim);
    
    if 1
      % Debug: Test Code
      for seg_idx = 1:length(segs)
        fprintf('Segment %d\n', seg_idx);
        disp(segs(seg_idx))
      end
      
      fprintf('On time: %g\n', sum(stats.on_time));
      fprintf('Seg\tOn%%\tOn');
      for board_idx = 1:size(stats.board_time,2)
        fprintf('\t%d%%\t%d', board_idx, board_idx);
      end
      fprintf('\n');
      
      for seg_idx = 1:length(segs)
        fprintf('%d\t%.0f%%\t%.1g', seg_idx, stats.on_time(seg_idx)/sum(stats.on_time)*100, stats.on_time(seg_idx));
        for board_idx = 1:size(stats.board_time,2)
          fprintf('\t%.0f%%\t%.1g', stats.board_time(seg_idx,board_idx)/stats.on_time(seg_idx)*100, stats.board_time(seg_idx,board_idx));
        end
        fprintf('\n');
      end
    end
    
    if isempty(segs)
      oparams = oparams(1:end-1);
    else
      for seg_idx = 1:length(segs)
        segment = segs(seg_idx);
        if seg_idx > 1
          oparams{end+1} = oparams{end};
        end
        oparams{end}.day_seg = sprintf('%s_%02d',param.config.date_str,length(oparams));
        oparams{end}.records.file.start_idx = segment.start_idxs;
        oparams{end}.records.file.stop_idx = segment.stop_idxs;
        oparams{end}.records.gps.time_offset = param.records.gps.time_offset + segment.day_wrap_offset;
      end
    end
  end
  
elseif any(param.records.file.version == [410])
  % MCRDS headers available, break segments based on filenames
  
else
  % No heading information, break segments based on time, epri, or radar
  % counter information (param.config.field_time_gap and
  % param.config.max_time_gap determine which field and gap size to use).
  counters = {};
  file_idxs = {};
  for board_idx = 1:numel(param.records.file.boards)
    counters{board_idx} = double(board_hdrs{board_idx}.(param.config.field_time_gap));
    file_idxs{board_idx} = board_hdrs{board_idx}.file_idxs;
    day_wrap_offset{board_idx} = board_hdrs{board_idx}.day_wrap_offset;
  end
  [segs,stats] = preprocess_create_segments(counters,file_idxs,day_wrap_offset,param.config.max_time_gap);
  
  if 1
    % Debug: Test Code
    for seg_idx = 1:length(segs)
      fprintf('Segment %d\n', seg_idx);
      disp(segs(seg_idx))
    end
    
    fprintf('On time: %g\n', sum(stats.on_time));
    fprintf('Seg\tOn%%\tOn');
    for board_idx = 1:size(stats.board_time,2)
      fprintf('\t%d%%\t%d', board_idx, board_idx);
    end
    fprintf('\n');
    
    for seg_idx = 1:length(segs)
      fprintf('%d\t%.0f%%\t%.1g', seg_idx, stats.on_time(seg_idx)/sum(stats.on_time)*100, stats.on_time(seg_idx));
      for board_idx = 1:size(stats.board_time,2)
        fprintf('\t%.0f%%\t%.1g', stats.board_time(seg_idx,board_idx)/stats.on_time(seg_idx)*100, stats.board_time(seg_idx,board_idx));
      end
      fprintf('\n');
    end
  end

  % Create the parameters to output
  oparams = {};
  [~,defaults] = param.config.default();
  for segment_idx = 1:length(segs)
    segment = segs(segment_idx);
    
    % Determine which default parameters to use
    % =======================================================================
    match_idx = 1;

    oparams{end+1} = defaults{match_idx};
    oparams{end} = rmfield(oparams{end},'config_regexp');
    oparams{end} = rmfield(oparams{end},'name');
    
    % Parameter spreadsheet
    % =======================================================================
    oparams{end}.day_seg = sprintf('%s_%02d',param.config.date_str,segment_idx);
    oparams{end}.cmd.notes = defaults{match_idx}.name;
    
    oparams{end}.records.file.start_idx = segment.start_idxs;
    oparams{end}.records.file.stop_idx = segment.stop_idxs;
    oparams{end}.records.gps.time_offset = param.records.gps.time_offset + segment.day_wrap_offset;
    
    oparams{end}.records.file.base_dir = param.config.base_dir;
    oparams{end}.records.file.board_folder_name = param.config.board_folder_names;
    if ~isempty(oparams{end}.records.file.board_folder_name) ...
        && oparams{end}.records.file.board_folder_name(1) ~= filesep
      % Ensures that board_folder_name is not a text number which Excel
      % will misinterpret as a numeric type
      oparams{end}.records.file.board_folder_name = ['/' oparams{end}.records.file.board_folder_name];
    end
    if ~isnan(str2double(oparams{end}.records.file.board_folder_name))
      oparams{end}.records.file.board_folder_name = ['/' oparams{end}.records.file.board_folder_name];
    end
    oparams{end}.records.file.boards = param.records.file.boards;
    oparams{end}.records.file.version = param.records.file.version;
    oparams{end}.records.file.prefix = param.records.file.prefix;
    oparams{end}.records.file.clk = param.records.file.clk;
  end
  
end

%% Print out segments
% =========================================================================
if ~exist(param.config.param_fn,'file')
  warning('Could not find parameter spreadsheet file so not printing parameter values.\n  param.config.param_fn = %s', param.config.param_fn);
else
  % Print parameter spreadsheet values to stdout and param_txt_fn
  % =========================================================================
  fid = 1;
  fprintf(fid,'<strong>%s\n','='*ones(1,80)); fprintf(fid,'  cmd\n'); fprintf(fid,'%s</strong>\n','='*ones(1,80));
  read_param_xls_print(param.config.param_fn,'cmd',oparams,fid);
  fprintf(fid,'<strong>%s\n','='*ones(1,80)); fprintf(fid,'  records\n'); fprintf(fid,'%s</strong>\n','='*ones(1,80));
  read_param_xls_print(param.config.param_fn,'records',oparams,fid);
  fprintf(fid,'<strong>%s\n','='*ones(1,80)); fprintf(fid,'  qlook\n'); fprintf(fid,'%s</strong>\n','='*ones(1,80));
  read_param_xls_print(param.config.param_fn,'qlook',oparams,fid);
  fprintf(fid,'<strong>%s\n','='*ones(1,80)); fprintf(fid,'  sar\n'); fprintf(fid,'%s</strong>\n','='*ones(1,80));
  read_param_xls_print(param.config.param_fn,'sar',oparams,fid);
  fprintf(fid,'<strong>%s\n','='*ones(1,80)); fprintf(fid,'  array\n'); fprintf(fid,'%s</strong>\n','='*ones(1,80));
  read_param_xls_print(param.config.param_fn,'array',oparams,fid);
  fprintf(fid,'<strong>%s\n','='*ones(1,80)); fprintf(fid,'  radar\n'); fprintf(fid,'%s</strong>\n','='*ones(1,80));
  read_param_xls_print(param.config.param_fn,'radar',oparams,fid);
  fprintf(fid,'<strong>%s\n','='*ones(1,80)); fprintf(fid,'  post\n'); fprintf(fid,'%s</strong>\n','='*ones(1,80));
  read_param_xls_print(param.config.param_fn,'post',oparams,fid);
  % Other sheets
  warning off MATLAB:xlsfinfo:ActiveX
  [status, sheets] = xlsfinfo(param.config.param_fn);
  warning on MATLAB:xlsfinfo:ActiveX
  for sheet_idx = 1:length(sheets)
    if ~any(strcmpi(sheets{sheet_idx},{'cmd','records','qlook','sar','array','radar','post'}))
      fprintf(fid,'<strong>%s\n','='*ones(1,80)); fprintf(fid,'  %s\n', sheets{sheet_idx}); fprintf(fid,'%s</strong>\n','='*ones(1,80));
      read_param_xls_print(param.config.param_fn,sheets{sheet_idx},oparams,fid);
    end
  end
  fprintf(fid,'\n');
  
  param_txt_fn = ct_filename_ct_tmp(param,'','param', [param.config.date_str,'.txt']);
  fprintf('Writing %s\n\n', param_txt_fn);
  param_txt_fn_dir = fileparts(param_txt_fn);
  if ~exist(param_txt_fn_dir,'dir')
    mkdir(param_txt_fn_dir);
  end
  [fid,msg] = fopen(param_txt_fn,'wb');
  if fid<0
    error('Could not write to %s: %s\n', param_txt_fn, msg);
  end
  fprintf(fid,'%s\n','='*ones(1,80)); fprintf(fid,'  cmd\n'); fprintf(fid,'%s\n','='*ones(1,80));
  read_param_xls_print(param.config.param_fn,'cmd',oparams,fid);
  fprintf(fid,'\n');
  fprintf(fid,'%s\n','='*ones(1,80)); fprintf(fid,'  records\n'); fprintf(fid,'%s\n','='*ones(1,80));
  read_param_xls_print(param.config.param_fn,'records',oparams,fid);
  fprintf(fid,'\n');
  fprintf(fid,'%s\n','='*ones(1,80)); fprintf(fid,'  qlook\n'); fprintf(fid,'%s\n','='*ones(1,80));
  read_param_xls_print(param.config.param_fn,'qlook',oparams,fid);
  fprintf(fid,'\n');
  fprintf(fid,'%s\n','='*ones(1,80)); fprintf(fid,'  sar\n'); fprintf(fid,'%s\n','='*ones(1,80));
  read_param_xls_print(param.config.param_fn,'sar',oparams,fid);
  fprintf(fid,'\n');
  fprintf(fid,'%s\n','='*ones(1,80)); fprintf(fid,'  array\n'); fprintf(fid,'%s\n','='*ones(1,80));
  read_param_xls_print(param.config.param_fn,'array',oparams,fid);
  fprintf(fid,'\n');
  fprintf(fid,'%s\n','='*ones(1,80)); fprintf(fid,'  radar\n'); fprintf(fid,'%s\n','='*ones(1,80));
  read_param_xls_print(param.config.param_fn,'radar',oparams,fid);
  fprintf(fid,'\n');
  fprintf(fid,'%s\n','='*ones(1,80)); fprintf(fid,'  post\n'); fprintf(fid,'%s\n','='*ones(1,80));
  read_param_xls_print(param.config.param_fn,'post',oparams,fid);
  fprintf(fid,'\n');
  % Other sheets
  warning off MATLAB:xlsfinfo:ActiveX
  [status, sheets] = xlsfinfo(param.config.param_fn);
  warning on MATLAB:xlsfinfo:ActiveX
  for sheet_idx = 1:length(sheets)
    if ~any(strcmpi(sheets{sheet_idx},{'cmd','records','qlook','sar','array','radar','post'}))
      fprintf(fid,'<strong>%s\n','='*ones(1,80)); fprintf(fid,'  %s\n', sheets{sheet_idx}); fprintf(fid,'%s</strong>\n','='*ones(1,80));
      read_param_xls_print(param.config.param_fn,sheets{sheet_idx},oparams,fid);
    end
  end
  fprintf(fid,'\n');
  fclose(fid);
end

%% Exit task
% =========================================================================
fprintf('%s done %s\n', mfilename, datestr(now));

success = true;
