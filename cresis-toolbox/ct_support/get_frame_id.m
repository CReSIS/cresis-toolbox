function [day_seg,frm_id,recs,num_recs] = get_frame_id(param,gps_time,search_params)
% [day_seg,frm_id,recs,num_recs] = get_frame_id(param,gps_time,search_params)
%
% Determines the segment, frame, and records that a GPS time lies in. Requires that
% the radar_name and season_name be supplied.
%
% Currently defaults to only look for segments one day before and after
% the gps_time passed in. For very long segments lasting more than a day or
% segments with large gps_time_offsets.
%
% param: input structure controlling which radar data to look at
%   .radar_name: string with generic radar name (e.g. 'rds', 'snow')
%   .season_name: string with season name (e.g. '2011_Greenland_P3')
% gps_time: array of gps_time's in ANSI-C time (seconds since Jan 1, 1970)
% search_params: optional input structure controlling the search parameters
%  .days_before: default is 1, searches this many days before min gps_time
%  .days_after: default is 1, searches this many days after max gps_time
%  .segment_end_time_guard: default is 0 seconds, causes the end time of
%    each segment to be this many seconds later than it actually is
%  .segment_id_num: default is 0 and day_seg is returned as a cell array of
%    strings, if set to true then day_seg is returned as a numeric
%    YYYYMMDDSS.
%
% day_seg: cell array the same size as gps_time filled with the day_seg of
%   the corresponding gps_time
% frm_id, recs: double arrays the same size as gps_time containing the
%   frame ID and records corresponding to gps_time. recs is the fractional
%   record meaning that if gps_time is half way between records 1 and 2,
%   recs will be 1.5.  A record number < 1 or more than the corresponding
%   entry in num_recs means that the gps time lies before or after the segment
%   respectively.
% num_recs: number of records in the segment (this can be used to see if
%   entries in recs are beyond the end of the segment).
%
% Examples:
%   param = struct('season_name','2011_Greenland_P3','radar_name','snow')
%   [day_seg,frm_id,recs] = get_frame_id(param,[1303490781.93816 1303491582.05660])
%   [day_seg,frm_id,recs] = get_frame_id(param,[1303837435.04928 1303838235.17157])
%   [day_seg,frm_id,recs] = get_frame_id(param,datenum_to_epoch(datenum(2011,4,22,16,46,21)))
%   [day_seg,frm_id,recs] = get_frame_id(param,datenum_to_epoch(datenum('2019-09-09 14:11:19.08')))
%
% Author: John Paden
%
% See also: get_frame_id, get_raw_files.m, get_segment_file_list.m,
%   run_get_segment_file_list.m

if ~exist('search_params','var')
  search_params = [];
end

if ~isfield(search_params,'days_before') || isempty(search_params.days_before)
  search_params.days_before = 1;
end

if ~isfield(search_params,'days_after') || isempty(search_params.days_after)
  search_params.days_after = 1;
end

if ~isfield(search_params,'segment_end_time_guard') || isempty(search_params.segment_end_time_guard)
  search_params.segment_end_time_guard = 1;
end

% search_params.segment_id_num: logical scalar, default false, if false
% then day_seg is a cell array of strings, if true then day_seg is a
% numeric array which is much faster for large gps_time input vectors.
if ~isfield(search_params,'segment_id_num') || isempty(search_params.segment_id_num)
  search_params.segment_id_num = false;
end

%% Setup

% Preallocate outputs
day_seg = cell(size(gps_time));
frm_id = zeros(size(gps_time));
recs = zeros(size(gps_time));

% Sort GPS times to make search for efficient
[sort_gps_time sort_idx] = sort(gps_time);

%% Load in start/stop GPS time for all segments
  
% Get list of records files
if ~isfield(param,'day_seg')
  % If the day-segment is not provided, then load all segments
  records_dir = ct_filename_support(param, '', 'records');
  fns = get_filenames(records_dir,'records','','.mat');
else
  % If the day-segment is provided, then just load that file
  records_fn = ct_filename_support(param, '', 'records');
  [records_fn_dir,records_fn_name] = fileparts(records_fn);
  fns = {fullfile(records_fn_dir,sprintf('%s.mat',records_fn_name))};
end

if isempty(fns)
  error('No records file found in %s', records_dir);
end

% Remove segments with dates far from the desired GPS time dates
keep_mask = false(size(fns));
db = search_params.days_before;
da = search_params.days_after;
for file_idx = 1:length(fns)
  records_fn = fns{file_idx};
  [records_fn_dir records_fn_name] = fileparts(records_fn);

  year = str2double(records_fn_name(9:12));
  month = str2double(records_fn_name(13:14));
  day = str2double(records_fn_name(15:16));
  if datenum_to_epoch(datenum(year,month,day)) >= sort_gps_time(1)-(1+db)*86400 ...
      && datenum_to_epoch(datenum(year,month,day)) <= sort_gps_time(end)+da*86400
    keep_mask(file_idx) = true;
  end
end
fns = fns(keep_mask);

if isempty(fns)
  error('No records file are within one day of the desired GPS time range: %s to %s.', ...
    datestr(epoch_to_datenum(sort_gps_time(1))), datestr(epoch_to_datenum(sort_gps_time(end))));
end

% Load in first and last record from each records file
first_gps_time = [];
for file_idx = 1:length(fns)
  records_fn = fns{file_idx};
  records = records_load(records_fn,'gps_time');
  first_gps_time(file_idx) = records.gps_time(1);
  last_gps_time(file_idx) = records.gps_time(end);
  num_recs = length(records.gps_time);
end
keep_mask = isfinite(first_gps_time) & isfinite(last_gps_time);
fns = fns(keep_mask);
first_gps_time = first_gps_time(keep_mask);
last_gps_time = last_gps_time(keep_mask);

if isempty(fns)
  error('All records file within one day have some not finite gps times.');
end

%% Determine which segment each gps time belongs to
fn_idx = 1;
gps_fn_idxs = NaN*zeros(size(sort_gps_time));
cur_fn_idx = 1;
for gps_idx = 1:numel(sort_gps_time)
  
  % Skip files until we get to a segment that ends AFTER the current gps
  % time
  while fn_idx <= length(last_gps_time) ...
      && sort_gps_time(gps_idx) > last_gps_time(fn_idx)+search_params.segment_end_time_guard
    fn_idx = fn_idx + 1;
  end

  if fn_idx > length(last_gps_time)
    % All remaining gps times are beyond the last segment
    gps_fn_idxs(gps_idx:end) = length(last_gps_time);
    break;
  end
  
  gps_fn_idxs(gps_idx) = fn_idx;
  cur_fn_idx = fn_idx;
  
end

%% Determine the record and frame numbers and form outputs
cur_fn_idx = NaN;
if search_params.segment_id_num
  day_seg = zeros(size(gps_time));
else
  day_seg = cell(size(gps_time));
end
frm_id = zeros(size(frm_id));
recs = zeros(size(recs));
num_recs = zeros(size(num_recs));
for gps_idx = 1:numel(sort_gps_time)
  if cur_fn_idx ~= gps_fn_idxs(gps_idx)
    if ~isnan(cur_fn_idx)
      recs(cur_gps_idx:gps_idx-1) = interp1(records.gps_time,1:length(records.gps_time),sort_gps_time(cur_gps_idx:gps_idx-1),'linear','extrap');
      num_recs(cur_gps_idx:gps_idx-1) = length(records.gps_time);
      [day_seg{cur_gps_idx:gps_idx-1}] = deal(param.day_seg);
      for offset_idx = cur_gps_idx:gps_idx-1
        new_frm_id = find(frames.frame_idxs <= recs(offset_idx),1,'last');
        if isempty(new_frm_id)
          new_frm_id = 1;
        end
        start_rec = frames.frame_idxs(new_frm_id);
        if new_frm_id == length(frames.frame_idxs)
          stop_rec = length(records.gps_time)+1;
        else
          stop_rec = frames.frame_idxs(new_frm_id+1);
        end
        frm_id(offset_idx) = new_frm_id ...
          + (recs(offset_idx)-start_rec)/(stop_rec-start_rec);
      end
    end
    % Load frames and records files
    cur_fn_idx = gps_fn_idxs(gps_idx);
    cur_gps_idx = gps_idx;
    records_fn = fns{cur_fn_idx};
    [records_fn_dir records_fn_name] = fileparts(records_fn);
    
    records = records_load(records_fn,'gps_time');
    param.day_seg = records_fn_name(9:19);
    frames = frames_load(param);
  end
end
if ~isnan(cur_fn_idx)
  gps_idx = gps_idx + 1;
  recs(cur_gps_idx:gps_idx-1) = interp1(records.gps_time,1:length(records.gps_time),sort_gps_time(cur_gps_idx:gps_idx-1),'linear','extrap');
  num_recs(cur_gps_idx:gps_idx-1) = length(records.gps_time);
  if search_params.segment_id_num
    % day_seg is numeric array
    segment_id_num = 100*str2double(param.day_seg(1:8)) + str2double(param.day_seg(10:11));
    [day_seg(cur_gps_idx:gps_idx-1)] = segment_id_num;
  else
    % day_seg is cell array
    [day_seg{cur_gps_idx:gps_idx-1}] = deal(param.day_seg);
  end
  for offset_idx = cur_gps_idx:gps_idx-1
    new_frm_id = find(frames.frame_idxs <= recs(offset_idx),1,'last');
    if isempty(new_frm_id)
      new_frm_id = 1;
    end
    start_rec = frames.frame_idxs(new_frm_id);
    if new_frm_id == length(frames.frame_idxs)
      stop_rec = length(records.gps_time)+1;
    else
      stop_rec = frames.frame_idxs(new_frm_id+1);
    end
    frm_id(offset_idx) = new_frm_id ...
      + (recs(offset_idx)-start_rec)/(stop_rec-start_rec);
  end
end

% Reorder outputs to match input ordering
day_seg(sort_idx) = day_seg;
frm_id(sort_idx) = frm_id;
recs(sort_idx) = recs;
