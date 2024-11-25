function success = preprocess_task_bas(param)
% success = preprocess_task_bas(param)
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

%% Input checks
% =========================================================================

if ~isfield(param.config,'field_time_gap') || isempty(param.config.field_time_gap)
  param.config.field_time_gap = 'gps_time';
end

if ~isfield(param.config,'plots_visible') || isempty(param.config.plots_visible)
  param.config.plots_visible = 1;
end

%% Read Headers
% =========================================================================

board_idx = 1;
board = param.config.board_map{board_idx};
board_folder_name = param.config.board_folder_name;
board_folder_name = regexprep(board_folder_name,'%b',board);
get_filenames_param = struct('regexp',param.config.file.regexp,'recursive',true);
fns = get_filenames(fullfile(param.config.base_dir,board_folder_name), ...
  param.config.file.prefix, param.config.file.midfix, ...
  param.config.file.suffix, get_filenames_param);
datenum_list = [];
fns_list = {{}};
fns_original_list = {{}};
for fn_idx = 1:length(fns)
  fn = fns{fn_idx};
  fname = fname_info_bas(fn);
  if ~any(datenum_list == fname.datenum)
    % File time stamp not added to list yet, so add it
    datenum_list(end+1) = fname.datenum;
    fns_list{board_idx}{end+1} = sprintf('%sPort_%s_Tx%s_Rx%s_%s%02.0fL%.0f_T01_%04.0f.mat', ...
      fname.name, datestr(fname.datenum,'YYYYmmDDHHMMSS'), 'P1234', 'P1', 'C', ...
      0, 0, fname.file_idx);
    fns_original_list{board_idx}{end+1} = fn;
  end
end
[datenum_list,sort_idxs] = sort(datenum_list);
fns_list{board_idx} = fns_list{board_idx}(sort_idxs);
fns_original_list{board_idx} = fns_original_list{board_idx}(sort_idxs);
board_hdrs{board_idx}.gps_time = [];
board_hdrs{board_idx}.file_idxs = [];
num_sam = [];
for fn_idx = 1:length(fns_list{board_idx})
  fn = fns_original_list{board_idx}{fn_idx};
  fprintf('%d of %d: %s (%s)\n', fn_idx, ...
    length(fns_original_list{board_idx}), fn, datestr(now,'HH:MM:SS'));
  
  % Open the PRI file to get the pri pulse number and number of records
  [fn_dir,fn_name,fn_ext] = fileparts(fn);
  pri_fn = fullfile(fn_dir,[fn_name '_pri' fn_ext]);
  pri = load(pri_fn,'pri');
  if isempty(num_sam)
    data = load(fn,'s');
    num_sam = size(data.s,1);
    clear data;
  end
  
  % Create fname and update with other fields
  tmp_hdr = fname_info_bas(fn);
  tmp_hdr.pri = pri.pri;
  tmp_hdr.wfs.num_sam = num_sam;
  tmp_hdr.gps_time = datenum_to_epoch(tmp_hdr.datenum);
  tmp_hdr.gps_time = tmp_hdr.gps_time + utc_leap_seconds(tmp_hdr.gps_time);
  
  Nx = length(tmp_hdr.pri);
  if Nx > 1
    PRI = median(diff(tmp_hdr.pri)) / param.config.defaults{1}.radar.prf;
    tmp_hdr.gps_time = tmp_hdr.gps_time + [0 PRI*(1:Nx-1)];
  elseif Mx ~= 1
    error('File with no records not handled.');
  end
  tmp_hdr.file_idxs = fn_idx*ones(1,Nx);
  
  tmp_hdr_fn = ct_filename_ct_tmp(param,'','headers', ...
    fullfile(board_folder_name, ''));
  
  % Create temporary filename to load the settings
  fn = fns_list{board_idx}{fn_idx};
  [~,fn_name] = fileparts(fn);
  tmp_hdr_fn = ct_filename_ct_tmp(param,'','headers', ...
    fullfile(board_folder_name, [fn_name '.mat']));
  
  tmp_hdr_fn_dir = fileparts(tmp_hdr_fn);
  if ~exist(tmp_hdr_fn_dir,'dir')
    mkdir(tmp_hdr_fn_dir);
  end

  fprintf('  Saving %s\n', tmp_hdr_fn);
  save(tmp_hdr_fn,'-v7.3','-struct','tmp_hdr');

  board_hdrs{board_idx}.gps_time(end+(1:Nx)) = tmp_hdr.gps_time;
  board_hdrs{board_idx}.file_idxs(end+(1:Nx)) = tmp_hdr.file_idxs;
end
board_hdrs{board_idx}.day_wrap_offset = zeros(size(board_hdrs{board_idx}.file_idxs));

%% Create Segments
% =========================================================================

% Break segments based on settings files and header information
% Each temporary file is its own segment and contains full settings
% information.

% No heading information, break segments based on time, epri, or radar
% counter information (param.config.field_time_gap and
% param.config.max_time_gap determine which field and gap size to use).
counters = {};
file_idxs = {};
for board_idx = 1
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
for segment_idx = 1:length(segs)
  segment = segs(segment_idx);
  
  % Determine which default parameters to use
  % =======================================================================
  match_idx = 1;
  oparams{end+1} = param.config.defaults{match_idx};
  oparams{end} = rmfield(oparams{end},'config_regexp');
  oparams{end} = rmfield(oparams{end},'name');
  
  % Parameter spreadsheet
  % =======================================================================
  oparams{end}.day_seg = sprintf('%s_%02d',param.config.date_str,segment_idx);
  oparams{end}.cmd.notes = param.config.defaults{match_idx}.name;
  
  fn = fns_list{board_idx}{segment.start_idxs};
  [~,fn_name] = fileparts(fn);
  tmp_hdr_fn = ct_filename_ct_tmp(param,'','headers', ...
    fullfile(board_folder_name, [fn_name '.mat']));
  fname = load(tmp_hdr_fn,'name');
  oparams{end}.cmd.mission_names = fname.name;
  
  oparams{end}.records.file.start_idx = segment.start_idxs;
  oparams{end}.records.file.stop_idx = segment.stop_idxs;
  oparams{end}.records.gps.time_offset = param.config.defaults{match_idx}.records.gps.time_offset + segment.day_wrap_offset;
  
  oparams{end}.records.file.base_dir = param.config.base_dir;
  oparams{end}.records.file.board_folder_name = param.config.board_folder_name;
  if ~isempty(oparams{end}.records.file.board_folder_name) ...
      && oparams{end}.records.file.board_folder_name(1) ~= filesep
    % Ensures that board_folder_name is not a text number which Excel
    % will misinterpret as a numeric type
    oparams{end}.records.file.board_folder_name = ['/' oparams{end}.records.file.board_folder_name];
  end
  if ~isnan(str2double(oparams{end}.records.file.board_folder_name))
    oparams{end}.records.file.board_folder_name = ['/' oparams{end}.records.file.board_folder_name];
  end
  oparams{end}.records.file.boards = param.config.board_map;
  oparams{end}.records.file.version = param.config.file.version;
  oparams{end}.records.file.prefix = param.config.file.prefix;
  oparams{end}.records.file.suffix = param.config.file.suffix;
  oparams{end}.records.file.regexp = param.config.file.regexp;
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
