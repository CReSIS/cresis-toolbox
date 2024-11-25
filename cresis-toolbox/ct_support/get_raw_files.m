function [load_info,gps_time,recs] = get_raw_files(param,frm_id,imgs,rec_range,rec_range_type,out_dir,tape_list, small_file_archives)
% [load_info,gps_time,recs]= get_raw_files(param,frm_id,imgs,rec_range,rec_range_type)
%
% Get a list of raw data filenames for particular frames and images or
% record ranges. Also can copy files.
%
% Inputs
% =========================================================================
%
% param: Can be either a string with the parameter spreadsheet filename OR
% a struct containing radar, season, and optionally day_seg information.
%
%  .radar_name: string containing radar name (e.g. 'kuband2')
%
%  .season_name: string containing season name (e.g. '2012_Greenland_P3')
%
%  .day_seg: string containing the day segment (e.g. '20170412_01'). This
%  is not required if frm_id is a string with the day_seg in it.
%
% frm_id: Indicates which frames to get information about. Must be one of
% these options:
%
%   1. string containing frame id (e.g. '20120514_01_317')
%
%   2. an integer array containing the frame numbers (param.day_seg must be
%   passed in)
%
%   3. a cell array of strings containing frame ids (e.g.
%   {'20120514_01_317','20120514_01_318'})
%
% imgs: a cell array of wf-adc pair lists, leave undefined or empty to do
% all images
%
% rec_range: Specifies a range of records to load in. The units specified
% by rec_range_type. Only the first and last element of rec_range are used.
%
% rec_range_type: String containing 'gps_time' or 'records'. Default is
% 'records'. If 'records' is used, either the param.day_seg field must be
% defined or the frm_id must be a string with the day_seg in it.
%
% out_dir: Optional. May be left empty or not defined. Specifies an output
% directory to copy raw files to.
%
% tape_list: The name of a file containing mappings between files and tapes.
% Or a matrix containing this mapping. The matrix must be presorted, formatted
% in the same manner as is done at the TAPE_LIST SORT comment below. See run_get_raw_files.
% If provided and not empty, load_info will contain a field, tapes,
% containing the name of the tape each corresponding file is present in as
% well as a field, stored_filenames, with the name of the file on the tape.
%
% small_file_archives: A mapping between directories and the name of the
% corresponding small file archive. See run_get_raw_files.
%
% Outputs
% =========================================================================
%
% load_info: struct with file information for the range of data specified
%
%  .filenames: cell array of cells which contain the raw data filenames
%
%  .tapes: cell array of tapes corresponding to the filenames when
%  tape_list is given
%
%  .stored_filenames: cell array of filenames on tapes corresponding to the
%  filenames array when tape_list is given
%
%  .file_idx: cell array of integers which specify an index into .filenames
%  for each record
%
%  .offset: raw file byte offset to the beginning of each record
%
% gps_time: prints out the start and stop GPS times and puts them here
%
% recs: raw data records into csarp_support records file
%
% Examples
% =========================================================================
%
%   % Get filename information for a range of records
%   [load_info,gps_time,recs] = get_raw_files(struct('radar_name','rds','season_name','2017_Antarctica_TObas'),'20170122_01',{},[25092 27499])
%
%   % Get filename information for a particular frame
%   [load_info,gps_time,recs] = get_raw_files(struct('radar_name','accum2','season_name','2012_Greenland_P3'),'20120514_02_010');
%   [load_info,gps_time,recs] = get_raw_files('kuband_param_2012_Greenland_P3.xls','20120514_01_317');
%   [load_info,gps_time,recs] = get_raw_files(struct('radar_name','mcords2','season_name','2012_Greenland_P3'),'20120514_02_018');
%   load_info = get_raw_files(struct('radar_name','mcords','season_name','2011_Antarctica_DC8'),'20111030_02_002')
%   [load_info,gps_time,recs] = get_raw_files('accum_param_2017_Greenland_P3.xls','20170412_01_023',[],1.4920018728e9,'gps_time');
%
%   % Example copying files
%   load_info = get_raw_files(struct('radar_name','mcrds','season_name','2008_Greenland_TO'),'20080627_06_001','/tmp/')
%
% =========================================================================
%
% Author: John Paden
%
% See also: get_frame_id, get_raw_files.m, get_segment_file_list.m,
%   run_get_segment_file_list.m

param_fn = '';
if ischar(param)
  param_fn = ct_filename_param(param);
  clear param;
  if ~ischar(frm_id) && ~iscell(frm_id)
    error('param as a filename requires frm_id to be a frame ID string or cell array of frame ID strings so the segment can be determined.');
  end
end
if ischar(frm_id)
  [param.day_seg] = frames_id_parse(frm_id);
elseif iscell(frm_id) && length(frm_id) >= 1 && ischar(frm_id{1})
  param.day_seg = frm_id{1}(1:11);
elseif ~isfield(param,'day_seg')
  error('param.day_seg or frm_id as a frame id string or cell array of frame ID strings must be provided');
end
if ischar(frm_id)
  [~,frm] = frames_id_parse(frm_id); % Extract frame number from frame ID
elseif iscell(frm_id)
  [~,frm] = frames_id_parse(frm_id); % Extract frame numbers from frame IDs
  frm_id = frm_id{1};
elseif isnumeric(frm_id) && length(frm_id) >= 1
  frm = frm_id;
  frm_id = sprintf('%s_%03d', param.day_seg, frm(1));
else
  error('Invalid combination of input arguments for param and frm.');
end

if ~isempty(param_fn)
  % A filename was passed in for the radar parameters
  param = read_param_xls(ct_filename_param(param_fn),frm_id(1:11));
elseif isstruct(param)
  % A structure was passed in for the radar parameters
  [output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);
  param_fn = sprintf('%s_param_%s.xls', output_dir, param.season_name);
  param = read_param_xls(ct_filename_param(param_fn),frm_id(1:11));
else
  error('param must be a filename or structure.');
end

global gRadar;
param = merge_structs(gRadar,param);

for wf = 1:length(param.radar.wfs)
  if isfield(param.radar.wfs(wf),'rx_paths') && ~isempty(param.radar.wfs(wf).rx_paths)
    param.radar.wfs(wf).rx_paths   = param.radar.wfs(wf).rx_paths;
  else
    param.radar.wfs(wf).rx_paths   = 1;
  end
end

% Populate imgs cell array with all wf-adc pairs if not specified
if ~exist('imgs','var') || isempty(imgs)
  for wf = 1:length(param.radar.wfs)
    for adc = 1:length(param.radar.wfs(wf).rx_paths)
      imgs{wf}(adc,1:2) = [wf adc];
    end
  end
end
% Populate wf_adc_list
wf_adc_list = [];
for img = 1:length(imgs)
  wf_adc_list(end+(1:size(imgs{img},1)),1:2) = imgs{img};
end

% Load the records file
records = records_load(param);

% Load the frames file
frames = frames_load(param);

%% Get the records associated with the frm or record
if exist('rec_range','var') && ~isempty(rec_range)
  if exist('rec_range_type','var') && strcmp(rec_range_type,'gps_time')
    % Use the provided gps_time range to determine the records to get
    start_rec = find(records.gps_time>=rec_range(1),1,'first');
    if isempty(start_rec)
      error('rec_range start time is after end of segment.');
    end
    stop_rec = find(records.gps_time>=rec_range(end),1,'first');
    if isempty(stop_rec)
      warning('rec_range stop time is after end of segment, setting to end of segment.');
      stop_rec = length(records.gps_time);
    end
  else
    % Use the provided record rnage to determine the records to get
    start_rec = rec_range(1);
    stop_rec = rec_range(end);
    good_recs = intersect(1:length(records.gps_time),start_rec:stop_rec);
    if numel(good_recs) < stop_rec-start_rec+1
      warning('Record range requests records that do not exist, truncating to valid records.');
      start_rec = good_recs(1);
      stop_rec = good_recs(end);
    end
  end
  recs = start_rec:stop_rec;

else
  % Use the provided frame ID to determine the records to get

  param.cmd.frms = frm;
  frms = frames_param_cmd_frms(param,frames);
  recs = false(size(records.gps_time));
  for idx = 1:length(frms)
    if frms(idx) == length(frames.frame_idxs) % handling the special case for the last frame
      recs(frames.frame_idxs(frms(idx)):frames.Nx) = true;
    else
      recs(frames.frame_idxs(frms(idx)):frames.frame_idxs(frms(idx)+1)-1) = true;
    end
  end
  recs = find(recs);
end

%% Get GPS Times
gps_time = records.gps_time(recs);

%% Get filenames
load_info = get_raw_files_sub(param,wf_adc_list,records,recs);

%% Reduce filenames list to just the files in the range specified
copy_fns = {};
for idx = 1:length(load_info.filenames)
  %% Copy files if out_dir specified
  if exist('out_dir','var') && ~isempty(out_dir)
    [base_dir,board_folder_name] = get_segment_file_list(param,load_info.board_idx(idx));
    for file_idx = 1:length(load_info.filenames{idx})
      copy_fn = load_info.filenames{idx}{file_idx};
      [~,copy_fn_name,copy_fn_ext] = fileparts(copy_fn);
      if ~any(strcmpi(copy_fn,copy_fns))
        % Some radars like MCRDS may list the same file multiple times
        out_fn = fullfile(out_dir,board_folder_name,[copy_fn_name copy_fn_ext]);
        out_fn_dir = fileparts(out_fn);
        fprintf('Copying %s\n  to %s (%s)\n', copy_fn, out_fn, datestr(now));
        if ~exist(out_fn_dir,'dir')
          mkdir(out_fn_dir);
        end
        copyfile(copy_fn,out_fn);
        copy_fns{end+1} = copy_fn;
      end
    end
  end
end

%% Find Tape Locations
% Determine the tape in which each file is present from the given tape_list

% TAPE_LIST SORT
if exist('tape_list', 'var') && ~isempty(tape_list) && size(tape_list, 1) == 1
  % Given a string as input, load the matrix
  tape_list = readmatrix(tape_list, 'Delimiter', ' ', 'OutputType', 'string');
  [~, file, ext] = fileparts(tape_list(:, 2));
  tape_list = [tape_list file + ext];
  tape_list = sortrows(tape_list, 3);
end

if exist('tape_list', 'var') && ~isempty(tape_list) && size(tape_list, 1) > 1

  % SMALL_FILE_ARCHIVES CONSTRUCTION
  % Map directories to the corresponding small file archives
  if ~exist('small_file_archives', 'var') || isempty(small_file_archives)
    small_file_archives = string();
    for file_idx = 1:size(tape_list, 1)
        filepath = tape_list{file_idx, 2};
        tapes = tape_list(file_idx, 1);
        if endsWith(filepath, "small_file_archive.tar")
            [parent, file_name, ext] = fileparts(filepath);
            file_name = [file_name ext];
            archive_idx = size(small_file_archives, 1) + 1;
            small_file_archives(archive_idx, 1) = tapes;
            small_file_archives(archive_idx, 2) = convertCharsToStrings(parent);
            small_file_archives(archive_idx, 3) = convertCharsToStrings(file_name);
        end
    end
    small_file_archives = sortrows(small_file_archives, 2);
  end

  % We have a matrix of tape locations, match to filenames

  load_info.stored_filenames = {};
  load_info.tapes = {};
  for filename_group_idx=1:length(load_info.filenames)
    filename_group = load_info.filenames{filename_group_idx};
    load_info.stored_filenames{filename_group_idx} = {};
    load_info.tapes{filename_group_idx} = {};

    for filename_idx=1:length(filename_group)
      filepath = filename_group{filename_idx};
      [~, file, ext] = fileparts(filepath);
      filename = [file ext];

      % Perform binary search to find filename in sorted tape_list
      [lia, locb] = ismember(filename, tape_list(:, 3));

      if ~lia
        load_info.stored_filenames{filename_group_idx}{filename_idx} = nan;
        load_info.tapes{filename_group_idx}{filename_idx} = nan;
      else

        % Check if next file in list has same filename and warn user that a duplicate exists
        if strcmp(tape_list{locb + 1, 3}, filename)
          disp 'duplicate filenames in tape_list';
          keyboard;
        end
        load_info.stored_filenames{filename_group_idx}{filename_idx} = tape_list{locb, 2};
        load_info.tapes{filename_group_idx}{filename_idx} = tape_list{locb, 1};
      end
    end

    % Find corresponding small_file_archive
    filepath = load_info.stored_filenames{filename_group_idx}{1};  % All files in group should have same parent
    while true
      % Iterate up the file path and see if any directory is in the small_file_archives mapping
      [filepath, ~, ~] = fileparts(filepath);
      if strcmp(filepath, "/")
        break;
      end
      [~, locb] = ismember(convertCharsToStrings(filepath), small_file_archives(:, 2));
      if locb ~= 0
        load_info.stored_filenames{filename_group_idx}{end + 1} = fullfile(small_file_archives{locb, 2}, small_file_archives{locb, 3});
        load_info.tapes{filename_group_idx}{end + 1} = small_file_archives{locb, 1};

        % Find original path
        [~, parent , ~] = fileparts(small_file_archives{locb, 2});
        original_path = filename_group{filename_idx};
        found = false;
        while ~found
          [original_path, ~, ~] = fileparts(original_path);
          if endsWith(original_path, parent)
            found = true;
            break;
          end
        end
        if ~found
          % Original path could not be determined
          original_path = nan;
        end
        load_info.filenames{filename_group_idx}{end + 1} = fullfile(original_path, small_file_archives{locb, 3});

        break;
      end
    end
  end
end