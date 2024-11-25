function success = preprocess_task_utig(param)
% success = preprocess_task_utig(param)
%
% Strips data out of utig packets and creates:
% 1. Files of just radar data
% 2. Files with just header data
%   a. binary flat file .hdr
%   b. Matlab .mat format (if supported)
% NOTE: This script only works on files with fixed header lengths. More
% specifically, every header must have the payload length field in the same spot.
%
% Example:
% Called from run_utig_packet_strip.m
%
% Author: John Paden
%
% See also: basic_load_utig.m, run_utig_packet_strip.m,
% utig_packet_strip.m, utig_packet_strip_task.m

% Pull in the inputs from param struct
base_dir = fullfile(param.config.base_dir);
config_folder_name = fullfile(param.config.config_folder_names);
reuse_tmp_files = param.config.reuse_tmp_files;

[~,defaults] = param.config.default();

%% Read each config/system XML file pair into a configs structure
% =========================================================================

% Not applicable yet

%% Process each file of data
% =========================================================================

board = param.config.board_map(1);

board_folder_name = fullfile(param.config.board_folder_names);
config_folder_name = fullfile(param.config.config_folder_names);

% Replace all "%b" in board_folder_name with the board number
board_folder_name = regexprep(board_folder_name,'%b',board);

% =========================================================================
%% Get Data File list for this board
get_filenames_param = struct('regexp',param.config.file.regexp);
fns = get_filenames(fullfile(param.config.base_dir,board_folder_name), ...
  param.config.file.prefix, param.config.file.midfix, ...
  param.config.file.suffix, get_filenames_param);
fns_datenum = zeros(size(fns));
for fn_idx = 1:length(fns)
  config_fname_info = fname_info_utig(fns{fn_idx});
  fns_datenum(fn_idx) = config_fname_info.datenum;
end

%% Iterate packet_strip through file list
old_fn_dir = [];
board_hdrs{1}.radar_time = [];
board_hdrs{1}.comp_time = [];
board_hdrs{1}.file_idxs = [];
for fn_idx = 1:length(fns)
  fn = fullfile(fns{fn_idx});
  
  [fn_dir,fn_name] = fileparts(fn);
  if ~strcmpi(fn_dir,old_fn_dir)
    % New data directory: assume that this is from a different utig 313
    % board and state vectors should be reset.
    last_bytes_m = [];
    last_bytes = zeros(64,1,'uint8');
    last_bytes_len = int32(0);
    num_expected = int32(-1);
    pkt_counter = int32(-1);
    old_fn_dir = fn_dir;
  end
  
  % Create output filenames
  out_fn = ct_filename_ct_tmp(param,'','headers', ...
    fullfile(board_folder_name, fn_name));
  [out_fn_dir,out_fn_name] = fileparts(out_fn);
  out_fn = fullfile(out_fn_dir,[out_fn_name,'.dat']);
  out_hdr_fn = fullfile(out_fn_dir,[out_fn_name,'.mat']);
  
  % Print status
  fprintf('utig_pkt_strip %d/%d %s (%s)\n    %s\n', fn_idx, ...
    length(fns), fn, datestr(now), out_fn);
  
  % Check to make sure output directory exists
  if ~exist(out_fn_dir,'dir')
    mkdir(out_fn_dir);
  end
  
  % Copy GPS (UTIG ELSA) Files
  if fn_idx == 1
    out_config_fn_dir = fullfile(fn_dir,config_folder_name);
    gps_files = fullfile(out_config_fn_dir,'serial*');
    out_log_dir = fullfile(param.data_support_path, param.season_name, param.config.date_str, 'ELSA');
    try
      fprintf('Copy %s\n  %s\n', gps_files, out_log_dir);
      if ~exist(out_log_dir,'dir')
        mkdir(out_log_dir)
      end
      copyfile(gps_files, out_log_dir);
    catch ME
      warning('Error while copying log files:\n%s\n', ME.getReport);
    end
  end
  
  finfo = fname_info_utig(fn);
  
  % Check to see if outputs already exist
  if reuse_tmp_files && exist(out_hdr_fn,'file')
    load(out_hdr_fn,'radar_time','comp_time');
    board_hdrs{1}.radar_time(end+(1:length(radar_time))) = radar_time;
    board_hdrs{1}.comp_time(end+(1:length(radar_time))) = comp_time;
    %board_hdrs{1}.file_idxs(end+(1:length(radar_time))) = finfo.file_idx*ones([1 length(radar_time)]);
    board_hdrs{1}.file_idxs(end+(1:length(radar_time))) = fn_idx*ones([1 length(radar_time)]);
    continue;
  end
  
  hdr = basic_load_utig(fn);
  if isempty(hdr)
    continue;
  end
  
  %% Write header output file
  radar_time = hdr{1}.ct_time;
  comp_time = hdr{1}.ct_clk;
  offset = zeros(size(hdr{1}.offset));
  for idx = 1:length(hdr{1}.offset)
    if hdr{1}.rseq(idx) ~= hdr{3}.rseq(idx)
      keyboard
    end
    offset(idx) = min(hdr{1}.offset(idx),hdr{3}.offset(idx));
  end
  
  for chan=1:length(hdr)
    pri{chan}.rseq = hdr{chan}.rseq;
  end
  
  save(out_hdr_fn, 'offset', 'radar_time', 'comp_time');
  
  board_hdrs{1}.radar_time(end+(1:length(radar_time))) = radar_time;
  board_hdrs{1}.comp_time(end+(1:length(radar_time))) = comp_time;
  %board_hdrs{1}.file_idxs(end+(1:length(radar_time))) = finfo.file_idx*ones([1 length(radar_time)]);
  board_hdrs{1}.file_idxs(end+(1:length(radar_time))) = fn_idx*ones([1 length(radar_time)]);

  if 0
    %% Debug outputs
    % load(out_tmp_fn);
  end
  
end

% Convert comp_time from Matlab's datenum format to ANSI C seconds since
% Jan 1 1970 epoch
board_hdrs{1}.comp_time = datenum_to_epoch(board_hdrs{1}.comp_time);

% No heading information, break segments based on time, epri, or radar
% counter information (param.config.field_time_gap and
% param.config.max_time_gap determine which field and gap size to use).
counters = {};
file_idxs = {};
param.config.field_time_gap = 'comp_time';
for board_idx = 1:numel(param.records.file.boards)
  counters{board_idx} = double(board_hdrs{board_idx}.(param.config.field_time_gap));
  file_idxs{board_idx} = board_hdrs{board_idx}.file_idxs;
  day_wrap_offset{board_idx} = zeros(size(board_hdrs{board_idx}.file_idxs))
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
for segment_idx = 1:length(segs)
  segment = segs(segment_idx);
  
  % Determine which default parameters to use
  % =======================================================================
  match_idx = 1;
  oparams{end+1} = merge_structs(param,defaults{match_idx});
  oparams{end} = rmfield(oparams{end},'config_regexp');
  oparams{end} = rmfield(oparams{end},'name');
  
  % Parameter spreadsheet
  % =======================================================================
  oparams{end}.day_seg = sprintf('%s_%02d',param.config.date_str,segment_idx);
  oparams{end}.cmd.notes = defaults{match_idx}.name;
  
  oparams{end}.records.file.start_idx = segment.start_idxs;
  oparams{end}.records.file.stop_idx = segment.stop_idxs;
  defaults{match_idx}.records.gps.time_offset = 0;
  oparams{end}.records.gps.time_offset = defaults{match_idx}.records.gps.time_offset + segment.day_wrap_offset;
  
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
  % Other sheets
  try
    warning off MATLAB:xlsfinfo:ActiveX
    [status, sheets] = xlsfinfo(param.config.param_fn);
    warning on MATLAB:xlsfinfo:ActiveX
    for sheet_idx = 1:length(sheets)
      if ~any(strcmpi(sheets{sheet_idx},{'cmd','records','qlook','sar','array','radar','post'}))
        fprintf(fid,'<strong>%s\n','='*ones(1,80)); fprintf(fid,'  %s\n', sheets{sheet_idx}); fprintf(fid,'%s</strong>\n','='*ones(1,80));
        read_param_xls_print(param.config.param_fn,sheets{sheet_idx},oparams,fid);
      end
    end
  catch ME
    ME.getReport
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
  try
    warning off MATLAB:xlsfinfo:ActiveX
    [status, sheets] = xlsfinfo(param.config.param_fn);
    warning on MATLAB:xlsfinfo:ActiveX
    for sheet_idx = 1:length(sheets)
      if ~any(strcmpi(sheets{sheet_idx},{'cmd','records','qlook','sar','array','radar','post'}))
        fprintf(fid,'<strong>%s\n','='*ones(1,80)); fprintf(fid,'  %s\n', sheets{sheet_idx}); fprintf(fid,'%s</strong>\n','='*ones(1,80));
        read_param_xls_print(param.config.param_fn,sheets{sheet_idx},oparams,fid);
      end
    end
  catch ME
    ME.getReport
  end
  fprintf(fid,'\n');
  fclose(fid);
end

%% Exit task
% =========================================================================
fprintf('%s done %s\n', mfilename, datestr(now));

success = true;
