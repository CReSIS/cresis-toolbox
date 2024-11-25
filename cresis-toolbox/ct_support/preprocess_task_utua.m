function success = preprocess_task_utua(param)
% success = preprocess_task_utua(param)
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

if ~isfield(param.config,'plots_visible') || isempty(param.config.plots_visible)
  param.config.plots_visible = 1;
end

%% Read Headers
% =========================================================================

% Save concatenated temporary file
fn_board_hdrs = ct_filename_ct_tmp(param,'','headers', fullfile(param.config.date_str,'board_hdrs.mat'));
num_board_to_load = numel(param.config.board_map);
board_hdrs = cell(1,num_board_to_load);
failed_load = cell(1,num_board_to_load);
fns_list = cell(1,num_board_to_load);
if param.config.reuse_tmp_files && exist(fn_board_hdrs,'file')
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
  board = param.config.board_map{board_idx};
  board_folder_name = param.config.board_folder_name;
  board_folder_name = regexprep(board_folder_name,'%b',board);
  
  get_filenames_param = struct('regexp',param.config.file.regexp);
  fns = get_filenames(fullfile(param.config.base_dir,board_folder_name), ...
    param.config.file.prefix, param.config.file.midfix, ...
    param.config.file.suffix, get_filenames_param);
  
  if param.config.online_mode == 2
    fns = fns(end);
  end
  fns_list{board_idx} = fns;
  
  if isempty(fns)
    error('No files found matching %s*%s*%s', ...
      fullfile(param.config.base_dir,board_folder_name,param.config.file.prefix), ...
      param.config.file.midfix, param.config.file.suffix);
  end
  
  % Assumption is that fns is in chronological order. Most radar systems
  % have filenames that are in chronological order with a simple
  % alphabetical sort.
  
  %% Read Headers: File Loop
  failed_load{board_idx} = false(size(fns));
  board_hdrs{board_idx}.gps_time = [];
  board_hdrs{board_idx}.surface = [];
  board_hdrs{board_idx}.file_idxs = [];
  for fn_idx = 1:length(fns)
    
    % Create temporary filename that will store the header information for
    % this file.
    fn = fns{fn_idx};
    if any(param.config.file.version == [405 406])
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
      fprintf('%d of %d: %s (%s)\n', fn_idx, length(fns), fn, datestr(now,'HH:MM:SS'));
      if param.config.reuse_tmp_files && exist(tmp_hdr_fn,'file')
        try
          % Load and concatenate temporary file
          hdr = load(tmp_hdr_fn,'gps_time','twtt_surf');
          board_hdrs{board_idx}.surface ...
            = cat(2,board_hdrs{board_idx}.surface,reshape(hdr.twtt_surf,[1 length(hdr.twtt_surf)]));
          board_hdrs{board_idx}.gps_time ...
            = cat(2,board_hdrs{board_idx}.gps_time,reshape(hdr.gps_time,[1 length(hdr.gps_time)]));
          board_hdrs{board_idx}.file_idxs = cat(2,board_hdrs{board_idx}.file_idxs,fn_idx*ones([1 length(hdr.gps_time)]));
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
      utua_rds.tdms2block_loop(fn,tmp_hdr_fn);
    catch ME
      warning(ME.getReport);
      failed_load{board_idx}(fn_idx) = true;
    end
    
    % Load and concatenate temporary file
    hdr = load(tmp_hdr_fn,'gps_time','twtt_surf');
    board_hdrs{board_idx}.surface ...
      = cat(2,board_hdrs{board_idx}.surface,reshape(hdr.twtt_surf,[1 length(hdr.twtt_surf)]));
    board_hdrs{board_idx}.gps_time ...
      = cat(2,board_hdrs{board_idx}.gps_time,reshape(hdr.gps_time,[1 length(hdr.gps_time)]));
    board_hdrs{board_idx}.file_idxs = cat(2,board_hdrs{board_idx}.file_idxs,fn_idx*ones([1 length(hdr.gps_time)]));
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
for board_idx = 1:numel(param.config.board_map)
  if any(failed_load{board_idx})
    warning('Some files failed to load, consider deleting these to avoid problems.');
    for fn_idx = find(failed_load{board_idx})
      fprintf('  %s\n', fns_list{board_idx}{fn_idx});
    end
  end
end

%% Create Segments
% =========================================================================

% Break segments based on settings files and header information
% Each temporary file is its own segment and contains full settings
% information.

% Assume only one board
board_idx = 1;
settings = {};
for fn_idx = 1:length(fns_list{board_idx})
  %% Read Headers: Filenames
  board = param.config.board_map{board_idx};
  board_folder_name = param.config.board_folder_name;
  board_folder_name = regexprep(board_folder_name,'%b',board);

  tmp_hdr_fn = ct_filename_ct_tmp(param,'','headers', ...
    fullfile(board_folder_name, ''));
  
  % Create temporary filename to load the settings
  fn = fns_list{board_idx}{fn_idx};
  if any(param.config.file.version == [405 406])
    [~,fn_name,ext] = fileparts(fn);
    fn_name = [fn_name,ext];
  else
    [~,fn_name] = fileparts(fn);
  end
  tmp_hdr_fn = ct_filename_ct_tmp(param,'','headers', ...
    fullfile(board_folder_name, [fn_name '.mat']));
  settings{end+1} = load(tmp_hdr_fn);
end

% Get the date information out of the filenames
fn_datenums = {};
for board_idx = 1:numel(param.config.board_map)
  fn_datenums{board_idx} = [];
  for data_fn_idx = 1:length(fns_list{board_idx})
    fname = utua_rds.fname_info_utua_rds(fns_list{board_idx}{data_fn_idx});
    fn_datenums{board_idx}(end+1) = fname.datenum;
  end
end

%% Create Segments: Print settings
% =========================================================================
oparams = {};
for set_idx = 1:length(settings)
  % Print out settings
  [~,settings_fn_name] = fileparts(settings{set_idx}.fn);
  fprintf('===================== Setting %d =================\n', set_idx);
  fprintf('%s: %d waveforms\n', settings_fn_name, length(settings{set_idx}.wfs));
  fprintf('  %s\n', settings{set_idx}.comment);
  fprintf('   PRF:'); fprintf(' %g', settings{set_idx}.prf); fprintf('\n');
  fprintf('   Range lines:'); fprintf(' %g', length(settings{set_idx}.gps_time)); fprintf('\n');
  fprintf('   f0-f1:'); fprintf(' %g-%g MHz %g us', settings{set_idx}.wfs(1).f0(1)/1e6, ...
    settings{set_idx}.wfs(1).f1(1)/1e6, settings{set_idx}.wfs(1).Tpd*1e6); fprintf('\n');
  for wf = 1:length(settings{set_idx}.wfs)
    fprintf('    WF %d Gain:', wf); fprintf(' %g', settings{set_idx}.ritec.gain); fprintf('\n');
    fprintf('    WF %d Tpd:', wf); fprintf(' %.1f us', 1e6*settings{set_idx}.wfs(1).Tpd); fprintf('\n');
  end
  
  for board_idx = 1:numel(param.config.board_map)
    if set_idx < length(settings)
      settings{set_idx}.file_matches{board_idx} = find(fn_datenums{board_idx} >= settings{set_idx}.datenum & fn_datenums{board_idx} < settings(set_idx+1).datenum);
    else
      settings{set_idx}.file_matches{board_idx} = find(fn_datenums{board_idx} >= settings{set_idx}.datenum);
    end
  end
  
  % Associate default parameters with each settings
  default = default_radar_params_settings_match(param.config.defaults,settings{set_idx});
  oparams{end+1} = default;
  oparams{end} = rmfield(oparams{end},'config_regexp');
  oparams{end} = rmfield(oparams{end},'name');
  
  % Parameter spreadsheet
  % =======================================================================
  oparams{end}.cmd.notes = default.name;
  
  oparams{end}.records.file.base_dir = param.config.base_dir;
  oparams{end}.records.file.board_folder_name = param.config.board_folder_name;
  if ~isempty(oparams{end}.records.file.board_folder_name) ...
      && oparams{end}.records.file.board_folder_name(1) ~= filesep
    % Ensures that board_folder_name is not a text number which Excel
    % will misinterpret as a numeric type
    oparams{end}.records.file.board_folder_name = ['/' oparams{end}.records.file.board_folder_name];
  end
  oparams{end}.records.file.boards = param.config.board_map;
  oparams{end}.records.file.version = param.config.file.version;
  oparams{end}.records.file.prefix = param.config.file.prefix;
  oparams{end}.radar.prf = settings{set_idx}.prf;
  
  % Usually the default.radar.wfs structure only has one waveform
  % entry which is to be copied to all the waveforms.
  if numel(oparams{end}.radar.wfs) == 1
    oparams{end}.radar.wfs = repmat(oparams{end}.radar.wfs,[1 numel(settings{set_idx}.wfs)]);
  end
  
  for wf = 1:numel(settings{set_idx}.wfs)
    oparams{end}.radar.wfs(wf).Tpd = settings{set_idx}.wfs(wf).Tpd;
    oparams{end}.radar.wfs(wf).f0 = settings{set_idx}.wfs(wf).f0;
    oparams{end}.radar.wfs(wf).f1 = settings{set_idx}.wfs(wf).f1;
    oparams{end}.radar.wfs(wf).tukey = 1;
    oparams{end}.radar.wfs(wf).tx_weights = 1;
    
    % ADC Gains
    oparams{end}.radar.wfs(wf).adc_gains_dB = settings{set_idx}.ritec.gain;
    
    % DDC mode and frequency
    oparams{end}.radar.wfs(wf).DDC_dec = 1;
    oparams{end}.radar.wfs(wf).DDC_freq = 0;
  end
  
  counters = {};
  file_idxs = {};
  for board_idx = 1:numel(param.config.board_map)
    counters{board_idx} = double(board_hdrs{board_idx}.(param.config.field_time_gap));
    file_idxs{board_idx} = board_hdrs{board_idx}.file_idxs;
    day_wrap_offset{board_idx} = zeros(size(board_hdrs{board_idx}.file_idxs));
    % Restrict to just these settings
    if isempty(settings{set_idx}.file_matches{board_idx})
      counters{board_idx} = [];
      file_idxs{board_idx} = [];
    else
      mask = file_idxs{board_idx} >= settings{set_idx}.file_matches{board_idx}(1) ...
        & file_idxs{board_idx} <= settings{set_idx}.file_matches{board_idx}(end);
      counters{board_idx} = counters{board_idx}(mask);
      file_idxs{board_idx} = file_idxs{board_idx}(mask);
      day_wrap_offset{board_idx} = day_wrap_offset{board_idx}(mask);
    end
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
      oparams{end}.records.gps.time_offset = default.records.gps.time_offset + segment.day_wrap_offset;
    end
  end
end


%% Print out segments
% =========================================================================
if ~isempty(param.config.param_fn)
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
  fprintf(fid,'<strong>%s\n','='*ones(1,80)); fprintf(fid,'  analysis\n'); fprintf(fid,'%s</strong>\n','='*ones(1,80));
  read_param_xls_print(param.config.param_fn,'analysis',oparams,fid);
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
  fprintf(fid,'%s\n','='*ones(1,80)); fprintf(fid,'  analysis\n'); fprintf(fid,'%s\n','='*ones(1,80));
  read_param_xls_print(param.config.param_fn,'analysis',oparams,fid);
  fprintf(fid,'\n');
  fclose(fid);
end

%% Exit task
% =========================================================================
fprintf('%s done %s\n', mfilename, datestr(now));

success = true;
