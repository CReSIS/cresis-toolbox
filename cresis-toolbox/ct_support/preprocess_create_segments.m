function [segs,stats] = preprocess_create_segments(counters,file_idxs,day_wrap_offset,threshold,segment_end_file_trim)
% [segs,stats] = preprocess_create_segments(counters,file_idxs,day_wrap_offset,threshold,segment_end_file_trim)
%
% Support function for preprocess_task_cresis.m. Takes header information
% from raw data files and generates a list of segments by finding time gaps
% in the data. The minimum size of the gap and segment end effects are
% parameters.
%
% Inputs:
% =========================================================================
%
% counters: cell array of counters vectors. One cell for each board. Each
% vector contains one entry per radar record.
%
% file_idxs: cell array of file_idxs vectors. One cell for each board. Each
% vector contains one entry per radar record.
%
% day_wrap_offset: cell array of day_wrap_offset vectors. One cell for each
% board. Each vector contains one entry per radar record.
%
% threshold: Positive scaler double. Default is 10. Specifies the duration
% in seconds that will cause a new segment to be formed.
%
% segment_end_file_trim: Optional. Positive scaler integer. Default is 0.
% Specifies the number of files at the end of a segment/radar-settings to
% ignore if there is a time gap that ocurs in these files.
%
% Outputs:
% =========================================================================
%
% segs:
%
% stats:
%
% Author: John Paden

%% Input check

% segment_end_file_trim: Positive scaler integer. Default is 0. Specifies
% the number of files at the end of a segment/radar-settings to ignore if
% there is a time gap that ocurs in these files.
if ~exist('segment_end_file_trim','var') || isempty(segment_end_file_trim)
  segment_end_file_trim = 0;
end

% threshold: Positive scaler double. Default is 10. Specifies the duration
% in seconds that will cause a new segment to be formed.
if ~exist('threshold','var') || isempty(threshold)
  threshold = 10;
end

% Debug: Test Code
debug_test_code = 0;
if debug_test_code
  counters = {};
  idx = 0;
  idx = idx + 1;
  counters{idx} = [3:15,20:31];
  file_idxs{idx} = 1+round(cumsum(abs(0.2*randn(size(counters{idx})))));
  idx = idx + 1;
  counters{idx} = [5:2:16,20:2:32];
  file_idxs{idx} = 1+round(cumsum(abs(0.2*randn(size(counters{idx})))));
  idx = idx + 1;
  counters{idx} = [2:16,21:29];
  file_idxs{idx} = 1+round(cumsum(abs(0.2*randn(size(counters{idx})))));
  
  threshold = 3;
end

% Combine all measurement counters
num_boards = length(counters);
all_counters = [];
for board_idx = 1:num_boards
  all_counters(end+(1:length(counters{board_idx}))) = counters{board_idx};
  if debug_test_code
    % Debug: Test Code
    counters{board_idx}
    file_idxs{board_idx}
  end
end
all_counters = unique(all_counters);

% If any gap passes the threshold for all boards combined, then make
% a segment break.
segs = [];
stats.on_time = [];
stats.board_time = [];
if length(all_counters) < 2
  return;
end
dcounters = diff(all_counters);
% FOR UTIG:
%overall_mask = false(size(counters));
% segs_idxs: list of all the segments (gaps in counter >= threshold)
segs_idxs = [0 find(dcounters(1:end-1) > threshold)];
for seg_idx = 1:length(segs_idxs)
  % Determine the start and stop counter for this segment
  cur = segs_idxs(seg_idx)+1;
  if seg_idx == length(segs_idxs)
    next = length(all_counters);
  else
    next = segs_idxs(seg_idx+1);
  end
  start_counter = all_counters(cur);
  stop_counter = all_counters(next);
  stats.on_time(end+1) = stop_counter - start_counter;
  if debug_test_code
    % Debug: Test Code
    fprintf('%d to %d\n', start_counter, stop_counter);
  end

  % Find the file range for each board
  for board_idx = 1:num_boards
    % Find files for this segment
    % FOR UTIG:
    %mask = ~overall_mask & (counters{board_idx} >= start_counter & counters{board_idx} <= stop_counter);
    mask = (counters{board_idx} >= start_counter & counters{board_idx} <= stop_counter);
    match_files = file_idxs{board_idx}(mask);
    if isempty(match_files) || (seg_idx>1 && max(file_idxs{board_idx}) - min(match_files) < segment_end_file_trim)
      segs(seg_idx).start_idxs(board_idx) = 0;
      segs(seg_idx).stop_idxs(board_idx) = -1;
      segs(seg_idx).day_wrap_offset(board_idx) = 0;
      continue
    end
    start_idx = match_files(1);
    stop_idx = match_files(end);
    
    % Adjust start/stop file indices for this new segment if there are counter
    % gaps in the start/stop files.
    while start_idx <= stop_idx
      % Find the counters associated with this file and board
      mask = file_idxs{board_idx}==start_idx;
      counters_file = counters{board_idx}(mask);
      mask = all_counters >= counters_file(1) & all_counters <= counters_file(end);
      if all(diff(all_counters(mask)) <= threshold)
        % Found a good start file with no gaps
        break;
      end
      start_idx = start_idx + 1;
    end
    
    % Find the last good stop file
    while stop_idx >= start_idx
      % Find the counters associated with this file and board
      mask = file_idxs{board_idx}==stop_idx;
      counters_file = counters{board_idx}(mask);
      mask = all_counters >= counters_file(1) & all_counters <= counters_file(end);
      if all(diff(all_counters(mask)) <= threshold)
        % Found a good end file with no gaps
        break;
      end
      stop_idx = stop_idx - 1;
    end
    
    % Record the start/stop file for this board and segment
    segs(seg_idx).start_idxs(board_idx) = start_idx;
    segs(seg_idx).stop_idxs(board_idx) = stop_idx;
    if start_idx>stop_idx
      segs(seg_idx).day_wrap_offset(board_idx) = 0;
    else
      segs(seg_idx).day_wrap_offset(board_idx) = day_wrap_offset{board_idx}(find(file_idxs{board_idx}==start_idx,1));
    end
    
    % Determine the amount of counter "time" this board is used for this
    % segment
    mask = file_idxs{board_idx}>=start_idx & file_idxs{board_idx}<=stop_idx;
    counters_board = counters{board_idx}(mask);
    if length(counters_board)<2
      stats.board_time(seg_idx,board_idx) = 0;
    else
      stats.board_time(seg_idx,board_idx) = counters_board(end)-counters_board(1);
    end
    
    % FOR UTIG:
    %overall_mask = overall_mask | mask;
    
    % Debug: Test Code
    if debug_test_code
      fprintf('  %d: %d to %d\n', board_idx, start_idx, stop_idx)
    end
  end
  
end

% Remove segments with no good files
good_seg_idxs = [];
for seg_idx = 1:length(segs)
  for board_idx = 1:num_boards
    if segs(seg_idx).start_idxs(board_idx) <= segs(seg_idx).stop_idxs(board_idx)
      good_seg_idxs(end+1) = seg_idx;
      break;
    end
  end
end
segs = segs(good_seg_idxs);

% Debug: Test Code
if debug_test_code
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
