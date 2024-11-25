function [x_min,x_max,y_min,y_max] = load_echogram(obj,desire_frame_idxs,clipped,x_min,x_max,y_min,y_max)
% [x_min,x_max,y_min,y_max] = echowin.load_echogram(obj,desire_frame_idxs,clipped,x_min,x_max,y_min,y_max)
%
% Load echogram data from echogram files
%
% desire_frame_idxs: frames to load (should be contiguous vector of
%   integers as in [N N+1 N+2 ...])
% clipped: explained in redraw.m (clipped == 3 is a forced reload of all
%   data which is the only special case that is handled here)
% x_min,x_max,y_min,y_max: updated so that subsequent call to plot_echogram.m
%   is correct.

%% Determine which frames need/can be loaded
  
% Get the "most" desired frame
most_desire_frame_idx = get(obj.left_panel.frameLB,'Value');

% Determine the desired source
source_idx = get(obj.left_panel.sourceLB,'Value');
current_sources = get(obj.left_panel.sourceLB,'String');
if isempty(current_sources)
  error('No source files exist for frame %03d.', most_desire_frame_idx);
end
source_idx = find(strcmp(current_sources{source_idx},obj.eg.sources));

% Determine the desired image
sourceMenus = get(obj.left_panel.sourceCM,'Children');
img = [];
for idx = 1:length(sourceMenus)
  if strncmp(sourceMenus(idx).Label,'Image',5)
    if isequal(sourceMenus(idx).Checked,'on')
      img = str2double(sourceMenus(idx).Label(7:end));
    end
  elseif strcmp(sourceMenus(idx).Label,'Combined')
    if isequal(sourceMenus(idx).Checked,'on')
      img = 0;
    end
    % Combined is the last one so break
    break;
  end
end
if isempty(img)
  sourceMenus(idx).Checked = 'on';
end
  
% Determine if the sources exist for the desired frames, source, and image
desire_exists = obj.eg.source_fns_existence(desire_frame_idxs,source_idx,img+1);

if any(~desire_exists)
  % Some sources don't exist, so requires special handling
  
  if ~obj.eg.source_fns_existence(most_desire_frame_idx,source_idx,img+1)
    % The most desired frame does not exist for the selected source/image,
    % so we check to see if any source/image files exist for this most
    % desired frame. Error if not.
    
    img = find(obj.eg.source_fns_existence(most_desire_frame_idx,source_idx,:),1)-1;
    if isempty(img)
      first_match = find(obj.eg.source_fns_existence(most_desire_frame_idx,:,:),1);
      if isempty(first_match)
        fprintf('Searching for echogram source files in:\n');
        for source_idx = 1:length(obj.eg.sources)
          fn_dir = ct_filename_out(obj.eg.cur_sel,obj.eg.sources{source_idx});
          fprintf('  %s\n', fn_dir);
        end
        errordlg(sprintf('Searched echogram sources specified in preferences and no matching echogram files exist for frame %03d.', most_desire_frame_idx), 'No matching echograms found.')
        error('No source files exist for frame %03d.', most_desire_frame_idx);
      else
        warning('Source %s does not exist for frame %03d.', obj.eg.sources{source_idx}, most_desire_frame_idx);
      end
      source_idx = mod(first_match-1,size(obj.eg.source_fns_existence,2))+1;
      set(obj.left_panel.sourceLB,'Value',source_idx);
      img = find(obj.eg.source_fns_existence(most_desire_frame_idx,source_idx,:),1)-1;
    end
    set(sourceMenus,'Checked','off');
    set(sourceMenus(length(sourceMenus)-3-img),'Checked','on');
    desire_exists = obj.eg.source_fns_existence(desire_frame_idxs,source_idx,img+1);
  end
  
  % Load up as many of the desired frames as possible. This involves
  % modifying desire_exists to load only contiguous frames that exist.
  sub_idx_most = find(most_desire_frame_idx == desire_frame_idxs);
  for sub_idx = sub_idx_most-1:-1:1
    if ~desire_exists(sub_idx)
      desire_exists(1:sub_idx) = 0;
      break;
    end
  end
  for sub_idx = sub_idx_most+1:length(desire_exists)
    if ~desire_exists(sub_idx)
      desire_exists(sub_idx:end) = 0;
      break;
    end
  end
  desire_frame_idxs = desire_frame_idxs(desire_exists);
end

if img == 0
  fn_img_str = '';
else
  fn_img_str = sprintf('img_%02d_', img);
end

%% Trim bad frames from desired frames to have loaded

% Check for existence of already loaded frames and data files for frames
% we want to load. We create frame_mask:
%   frame_mask = 0: frame file exists and needs to be loaded
%   frame_mask = 1: frame already loaded
frame_mask = zeros(size(desire_frame_idxs));
for frame_idx = 1:length(desire_frame_idxs)
  cur_frame = desire_frame_idxs(frame_idx);
  if any(cur_frame==obj.eg.frms) && clipped ~= 3
    frame_mask(frame_idx) = 1;
  end
end

obj.eg.frms = desire_frame_idxs;

%% Drop data that are no longer needed
valid_mask = logical(zeros(size(obj.eg.gps_time)));
for frm_idx = desire_frame_idxs(frame_mask == 1)
  % Keep data from any frame that is already loaded
  valid_mask = valid_mask | ...
    (obj.eg.gps_time >= obj.eg.start_gps_time(frm_idx) ...
    & obj.eg.gps_time < obj.eg.stop_gps_time(frm_idx));
end
obj.eg.data = obj.eg.data(:,valid_mask);
obj.eg.gps_time = obj.eg.gps_time(valid_mask);
obj.eg.lat = obj.eg.lat(valid_mask);
obj.eg.lon = obj.eg.lon(valid_mask);
obj.eg.elev = obj.eg.elev(valid_mask);
obj.eg.roll = obj.eg.roll(valid_mask);
obj.eg.surf_twtt = obj.eg.surf_twtt(valid_mask);

%% Determine new time axis
min_time = inf;
max_time = -inf;
dt = 0;
for frame_idx = 1:length(desire_frame_idxs)
  cur_frame = desire_frame_idxs(frame_idx);
  
  % load EG
  fn = fullfile(ct_filename_out(obj.eg.cur_sel,obj.eg.sources{source_idx},'',0),sprintf('Data_%s%s.mat',fn_img_str,obj.eg.frm_strs{cur_frame}));
  if ~exist(fn,'file')
    warning('File %s not found', fn);
    keyboard
  end
  % Load EG data and metadata
  tmp_vars = whos('-file',fn);
  if any(strcmp('Truncate_Bins',{tmp_vars.name}))
    tmp = load(fn,'Time','Truncate_Bins','Elevation_Correction');
  else
    tmp = load(fn);
  end
  tmp = uncompress_echogram(tmp);
  if isempty(tmp.Time)
    % Handle special case of file with all bad data
    warning('File does not have any good data so skipping for obj.eg.time axis creation: %s', fn);
  else
    if tmp.Time(1) < min_time
      min_time = tmp.Time(1);
    end
    if tmp.Time(end) > max_time
      max_time = tmp.Time(end);
    end
    if length(tmp.Time) >= 2
      if dt == 0 || dt < tmp.Time(2) - tmp.Time(1)
        dt = tmp.Time(2) - tmp.Time(1);
      end
    end
  end
end
if dt == 0
  dt = 1;
end
if ~isfinite(min_time)
  min_time = 0;
  max_time = dt;
end
new_time = (dt*round(min_time/dt) : dt : max_time).';
if ~isempty(obj.eg.data)
  obj.eg.data = interp1(obj.eg.time, obj.eg.data, new_time);
end
obj.eg.time = new_time;

%% Loading new data
fprintf(' Loading echogram (%s)\n',datestr(now,'HH:MM:SS'));
physical_constants;
loading_frame_idxs = desire_frame_idxs(frame_mask == 0);
for frame_idx = 1:length(loading_frame_idxs)
  cur_frame = loading_frame_idxs(frame_idx);
  
  % load EG
  fn = fullfile(ct_filename_out(obj.eg.cur_sel,obj.eg.sources{source_idx},'',0),sprintf('Data_%s%s.mat',fn_img_str,obj.eg.frm_strs{cur_frame}));
  fprintf('  %s\n', fn);
  if ~exist(fn,'file')
    warning('File %s not found', fn);
    keyboard
  end
  % Load EG data and metadata
  tmp = load(fn);
  if ~isfield(tmp,'Roll')
    tmp.Roll = zeros(size(tmp.GPS_time));
  end
  tmp.Time = reshape(tmp.Time,[length(tmp.Time) 1]); % Fixes a bug in some echograms
  tmp = uncompress_echogram(tmp);
  if length(tmp.Time) < 2
    tmp.Time = min_time+[0 dt];
    tmp.Data(1:2,:) = nan;
  end
  
  % Remove any data in echogram that is not part of the frame being loaded
  %   (e.g. some echograms were created with some data from neighboring
  %   frames and this must be removed)
  valid_mask = tmp.GPS_time >= obj.eg.start_gps_time(cur_frame) ...
    & tmp.GPS_time < obj.eg.stop_gps_time(cur_frame);
  tmp.Data = tmp.Data(:,valid_mask);
  tmp.Latitude = tmp.Latitude(valid_mask);
  tmp.Longitude = tmp.Longitude(valid_mask);
  tmp.Elevation = tmp.Elevation(valid_mask);
  tmp.Roll = tmp.Roll(valid_mask);
  tmp.GPS_time = tmp.GPS_time(valid_mask);
  if isfield(tmp,'Surface') && ~isempty(tmp.Surface)
    tmp.Surface = tmp.Surface(valid_mask);
  else
    tmp.Surface = NaN*tmp.GPS_time;
  end
  
  %% Reinterpolate original data and data to be appended onto a common time axis
  % Since time axes are not consistent, we avoid reinterpolating the
  % same data for each appending process by enforcing that the new time bins
  % fall on the
  % same points every time and may only add additional points.
  
  % Create new time axis (but ensure start point will cause the new
  % time axes to fall on all the old tmp.Time points)
  if isempty(obj.eg.time)
    obj.eg.time = tmp.Time;
  end
  dt = obj.eg.time(2) - obj.eg.time(1);
  min_time = min(tmp.Time(1),obj.eg.time(1));
  Time = obj.eg.time(1) - dt*round((obj.eg.time(1) - min_time)/dt) ...
    : dt : max(tmp.Time(end),obj.eg.time(end));
  % Interpolate original data
  if isempty(obj.eg.data)
    obj.eg.data = [];
  else
    warning off;
    obj.eg.data = interp1(obj.eg.time,obj.eg.data,Time);
    warning on;
  end
  obj.eg.time = Time;
  % Interpolate data to be appended
  tmp.Data = interp1(tmp.Time,tmp.Data,Time);
  % Splice the two datasets together at the right point
  splice_idx = find(obj.eg.gps_time > tmp.GPS_time(1),1);
  if isempty(splice_idx)
    % Append to end
    obj.eg.lat = cat(2,obj.eg.lat,tmp.Latitude);
    obj.eg.lon = cat(2,obj.eg.lon,tmp.Longitude);
    obj.eg.elev = cat(2,obj.eg.elev,tmp.Elevation);
    obj.eg.roll = cat(2,obj.eg.roll,tmp.Roll);
    obj.eg.gps_time = cat(2,obj.eg.gps_time,tmp.GPS_time);
    obj.eg.surf_twtt = cat(2,obj.eg.surf_twtt,tmp.Surface);
    obj.eg.data = cat(2,obj.eg.data,tmp.Data);
  else
    % Append to somewhere in the middle
    obj.eg.lat = cat(2,obj.eg.lat(1:splice_idx-1),tmp.Latitude, ...
      obj.eg.lat(splice_idx:end));
    obj.eg.lon = cat(2,obj.eg.lon(1:splice_idx-1),tmp.Longitude, ...
      obj.eg.lon(splice_idx:end));
    obj.eg.elev = cat(2,obj.eg.elev(1:splice_idx-1),tmp.Elevation, ...
      obj.eg.elev(splice_idx:end));
    obj.eg.roll = cat(2,obj.eg.roll(1:splice_idx-1),tmp.Roll, ...
      obj.eg.roll(splice_idx:end));
    obj.eg.gps_time = cat(2,obj.eg.gps_time(1:splice_idx-1),tmp.GPS_time, ...
      obj.eg.gps_time(splice_idx:end));
    obj.eg.surf_twtt = cat(2,obj.eg.surf_twtt(1:splice_idx-1),tmp.Surface, ...
      obj.eg.surf_twtt(splice_idx:end));
    obj.eg.data = cat(2,obj.eg.data(:,1:splice_idx-1),tmp.Data, ...
      obj.eg.data(:,splice_idx:end));
  end
end
fprintf('  Done loading EG (%s)\n',datestr(now,'HH:MM:SS'));

% Make sure axis call does not stretch beyond image limits
%  -- Handle segment edge case
dx = obj.eg.gps_time(2)-obj.eg.gps_time(1);
min_gps_time = obj.eg.gps_time(1);
max_gps_time = obj.eg.gps_time(end);
if obj.eg.frms(1) == 1
  % First frame in segment so adjust beginning to make sure all layer points
  % will be displayed.
  min_gps_time = obj.eg.start_gps_time(1)-dx;
elseif obj.eg.frms(end) == length(obj.eg.stop_gps_time)
  % Last frame of segment so adjust end to make sure all layer points will 
  % be displayed.
  max_gps_time = obj.eg.stop_gps_time(end)+dx;
end

if x_min < min_gps_time
  x_range = x_max - x_min;
  x_min = min_gps_time;
  x_max = x_min + x_range;
end
if x_max > max_gps_time
  x_range = x_max - x_min;
  x_max = max_gps_time;
  x_min = max(min_gps_time, x_max - x_range);
end

obj.update_frame_and_sourceLB(obj.eg.frms(1));

end
