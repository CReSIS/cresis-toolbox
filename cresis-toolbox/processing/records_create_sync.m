% records_create_sync
%
% Script called from records_create
%
% To run this in debug mode, you need to set the debug setup section in
% this file and then just run this as a script (must be run from ">>"
% prompt and not a debug "K>>" prompt).
%
% Author: John Paden

%% Debug Setup (for running records_create_sync directly)
% =====================================================================
dbstack_info = dbstack;
if ~exist('param','var') || isempty(param) || length(dbstack_info) == 1
  new_param = read_param_xls(ct_filename_param('rds_param_2018_Antarctica_Ground.xls'),'20181217_03');

  fn = ct_filename_ct_tmp(new_param,'','records','workspace');
  fn = [fn '.mat'];
  fprintf('Loading workspace %s (%s)\n', fn, datestr(now));
  if exist(fn,'file')
    load(fn);
  else
    error('Temporary records file does not exist');
  end
  
  % Update any parameters that the user changed in the spreadsheet
  param = merge_structs(param,new_param);
  clear new_param;
  
  clear('param_override');
  
  % Input checking
  if ~exist('param','var')
    error('A struct array of parameters must be passed in\n');
  end
  global gRadar;
  if exist('param_override','var')
    param_override = merge_structs(gRadar,param_override);
  else
    param_override = gRadar;
  end
  param = merge_structs(param, param_override);
  
  if any(param.records.file.version == [9 10 103 412])
    % Arena based systems
    h_fig = get_figures(1,true);
  end

end

fprintf('Running %s correction and gps sync (%s)\n', param.day_seg, datestr(now));

%% Input checks
% ======================================================================

if ~isfield(param.records,'manual_time_correct') || isempty(param.records.manual_time_correct)
  param.records.manual_time_correct = 0;
end

% Initialize notes string that will be stored in records file
radar_time_notes = '';
epri_notes = '';
clock_notes = '';

% Initialize records.settings
records.settings = [];

%% Align all boards using EPRI
% ======================================================================
if any(param.records.file.version == [9 10 103 412])
  % Arena based systems
  
  %% Align/Arena: Create output EPRI vector
  min_epri = inf;
  max_epri = -inf;
  epri_list = [];
  good_offsets = {};
  offset_scores = {};
  special_epri_generation = false;
  for board_idx = 1:length(boards)
    % Cluster EPRI values
    
    % PRI number (increments one per pulse)
    epri_pri_idxs = board_hdrs{board_idx}.profile_cntr_latch;
    
    % Sort in case there are any out of order profiles or outliers caused
    % by header errors
    [A,B] = sort(epri_pri_idxs);
    % Find the median PRI-number
    med = median(A);
    % Find the closest index to the median PRI-number
    [~,med_idx] = min(abs(A-med));
    % A: PRI-number relative to median
    A = A-med;
    dA = diff(A);
    % Look for too large jumps in the second half of the segment
    bad_mask = zeros(size(B));
    bad_start_idx = find(dA(med_idx:end) > param.records.epri_jump_threshold,1);
    if ~isempty(bad_start_idx)
      bad_mask(med_idx+bad_start_idx:end) = true;
    end
    % Look for too large jumps in the first half of the segment
    bad_start_idx = find(dA(med_idx-1:-1:1) > param.records.epri_jump_threshold,1);
    if ~isempty(bad_start_idx)
      bad_mask(med_idx-bad_start_idx:-1:1) = true;
    end
    % Drop all records before/after the first jump that occurs relative to
    % the median PRI-number.
    back_idxs = 1:length(B);
    back_idxs = back_idxs(B);
    if sum(bad_mask) > 0
      warning('%d of %d records show bad out of range EPRI values. max jump is %d, param.records.epri_jump_threshold is %d', sum(bad_mask), length(epri_pri_idxs), max(dA), param.records.epri_jump_threshold);
    end
    epri_pri_idxs = epri_pri_idxs(back_idxs(logical(~bad_mask)));
    
    % Keep track of the smallest PRI-number and largest PRI-number
    min_epri = min(min_epri,min(epri_pri_idxs));
    max_epri = max(max_epri,max(epri_pri_idxs));
    
    % Store PRI-numbers captured by this board into list of all PRI-numbers
    epri_list(end+(1:length(epri_pri_idxs))) = epri_pri_idxs;
    
    % Find the median PRI-number jump between recorded records.
    diff_epri_pri_idxs = diff(epri_pri_idxs);
    diff_epri(board_idx) = median(diff_epri_pri_idxs);
    % Assume that each board records data at the EPRI/EPRF rate (i.e. all the
    % PRI-numbers align between boards and occur at a regular interval).
    % Report the number of PRI-numbers that do not fall into this pattern.
    min_score = inf;
    best_offset = NaN;
    offsets = 0:diff_epri(board_idx);
    for offset_idx = 1:length(offsets)
      offset = offsets(offset_idx);
      GUARD = 4;
      offset_scores{board_idx}(offset_idx) = sum(abs(mod((epri_pri_idxs - offset)/diff_epri(board_idx),1)) > GUARD);
      if offset_scores{board_idx}(offset_idx) < min_score
        min_score = offset_scores{board_idx}(offset_idx);
        best_offset = offset;
      end
    end
    if 0
      % For debugging, plot this to find which PRI-numbers do not fall into
      % this pattern:
      plot(mod((epri_pri_idxs - best_offset)/diff_epri(board_idx),1) ~= 0);
      keyboard
    end
    % Keep track of any offsets that cause more than 1% of records to align
    good_offsets{board_idx} = find(offset_scores{board_idx} < length(epri_pri_idxs)*0.99);
    if min_score > 0
      warning('%d of %d records show slipped EPRI values.', min_score, length(epri_pri_idxs));
      if length(good_offsets{board_idx}) > 1
        warning('An ADC link error probably occured or incorrect pulse sequence radar settings were used since PRI-numbers do not follow a regular interval. Special generation of the EPRI vector is now enabled.')
        special_epri_generation = true;
      end
    end
  end
  % Find the first EPRI with the most valid boards (if more than one EPRI
  % has the most valid boards, mode returns the smallest or first EPRI;
  % most of the EPRIs should have occured in each board and so most will
  % have occured in all the boards)
  master_epri = mode(epri_list);
  % Assume that each board records data at the EPRI/EPRF rate (i.e. all the
  % PRI-numbers align between boards and occur at a regular interval)
  if any(diff_epri ~= diff_epri(1))
    error('Inconsistent EPRI step size between boards. Should all be the same: %s', mat2str_generic(diff_epri));
  end
  epri = [fliplr(master_epri:-diff_epri(1):min_epri), master_epri+diff_epri(1):diff_epri(1):max_epri];
  %% Special generation of the EPRI vector
  if special_epri_generation
    epri_list = sort(epri_list);
    epri_list_idx = 1;
    epri_offset = 0;
    for epri_idx = 1:length(epri)
      total = 0;
      match = 0;
      epri(epri_idx) = epri(epri_idx) + epri_offset;
      if epri(epri_idx) >= max_epri
        break;
      end
      start_epri_list_idx = epri_list_idx;
      while epri_list(epri_list_idx) <= epri(epri_idx)
        total = total + 1;
        if epri_list(epri_list_idx) == epri(epri_idx)
          match = match + 1;
        end
        epri_list_idx = epri_list_idx + 1;
      end
      if total > 0 && match == 0
        if all(epri_list(start_epri_list_idx:epri_list_idx-1) == epri_list(start_epri_list_idx))
          warning('Special generation of EPRI: EPRI offset changed at record %d.', epri_idx);
          epri_offset_correction = epri_list(start_epri_list_idx) - epri(epri_idx) + diff_epri(1);
          epri_offset = epri_offset + epri_offset_correction;
          epri(epri_idx) = epri(epri_idx) + epri_offset_correction;
        end
      end
    end
  end
  
  %% Align/Arena: Fill in missing records from each board
  records.raw.pps_cntr_latch = nan(size(epri));
  records.raw.pps_ftime_cntr_latch = nan(size(epri));
  records.raw.profile_cntr_latch = nan(size(epri));
  records.raw.rel_time_cntr_latch = nan(size(epri));
  for board_idx = 1:length(boards)
    if GUARD == 0
      [~,out_idxs,in_idxs] = intersect(epri,board_hdrs{board_idx}.profile_cntr_latch);
    else
      out_idxs = nan(size(epri));
      in_idxs = nan(size(epri));
      out_idx = 0;
      for idx = 1:length(epri)
        [offset,min_idx] = min(abs(epri(idx) - board_hdrs{board_idx}.profile_cntr_latch));
        if offset < GUARD
          out_idx = out_idx + 1;
          out_idxs(out_idx) = idx;
          in_idxs(out_idx) = min_idx;
        end
      end
      out_idxs = out_idxs(1:out_idx);
      in_idxs = in_idxs(1:out_idx);
    end
    
    fprintf('Board %d is missing %d of %d records.\n', board_idx, length(epri)-length(out_idxs), length(epri));
    
    % offset: Missing records filled in with -2^31
    offset = zeros(size(epri),'int32');
    offset(:) = -2^31;
    offset(out_idxs) = board_hdrs{board_idx}.offset(in_idxs);
    board_hdrs{board_idx}.offset = offset;
    
    % file_idx: Missing records filled in with NaN
    file_idx = nan(size(epri));
    file_idx(out_idxs) = board_hdrs{board_idx}.file_idx(in_idxs);
    board_hdrs{board_idx}.file_idx = interp_finite(file_idx,[],'nearest');
    
    % Time stamps are assumed to be the same from each board so each board
    % just writes all of its time stamps to the output records fields.
    records.raw.pps_cntr_latch(out_idxs) = board_hdrs{board_idx}.pps_cntr_latch(in_idxs);
    records.raw.pps_ftime_cntr_latch(out_idxs) = board_hdrs{board_idx}.pps_ftime_cntr_latch(in_idxs);
    records.raw.profile_cntr_latch(out_idxs) = board_hdrs{board_idx}.profile_cntr_latch(in_idxs);
    records.raw.rel_time_cntr_latch(out_idxs) = board_hdrs{board_idx}.rel_time_cntr_latch(in_idxs);
  end
  records.raw.pps_cntr_latch = interp_finite(records.raw.pps_cntr_latch);
  records.raw.pps_ftime_cntr_latch = interp_finite(records.raw.pps_ftime_cntr_latch);
  records.raw.profile_cntr_latch = interp_finite(records.raw.profile_cntr_latch);
  records.raw.rel_time_cntr_latch = interp_finite(records.raw.rel_time_cntr_latch);

  rel_time_cntr_latch = records.raw.rel_time_cntr_latch;
  clf(h_fig);
  h_axes = axes('parent',h_fig);
  h_plot = plot(h_axes, diff(rel_time_cntr_latch));
  grid(h_axes,'on');
  title(h_axes,sprintf('%s:\nAll values should be greater than 0.', [param.day_seg(1:8) '\' param.day_seg(9:end)]));
  ylabel(h_axes,'diff(rel\_time\_cntr\_latch)');
  xlabel(h_axes,'Record');
  hold(h_axes,'on');
  if any(diff(rel_time_cntr_latch) <= 0)
    warning('rel_time_cntr_latch should be monotonically increasing, but there are some records that are not. Applying simple fix that may not be correct.');
    % Initial point before decrease is often the problem, so remove this
    % first
    bad_mask = diff(rel_time_cntr_latch) < 0;
    bas_mask(1) = false;
    rel_time_cntr_latch(bad_mask) = NaN;
    rel_time_cntr_latch = interp_finite(rel_time_cntr_latch,NaN);
    % Now remove any remaining negative time jumps
    last_idx = 1;
    for idx = 2:length(rel_time_cntr_latch)
      if rel_time_cntr_latch(idx) < rel_time_cntr_latch(last_idx)
        rel_time_cntr_latch(idx) = NaN;
      else
        last_idx = idx;
      end
    end
    rel_time_cntr_latch = interp_finite(rel_time_cntr_latch,NaN);
    % Plot corrected time
    h_plot(2) = plot(h_axes, diff(rel_time_cntr_latch));
    legend(h_plot,{'Bad','Corrected'});
  end
  fig_fn = [ct_filename_ct_tmp(param,'','records_create','rel_time_cntr_latch') '.jpg'];
  fprintf('Saving %s\n', fig_fn);
  fig_fn_dir = fileparts(fig_fn);
  if ~exist(fig_fn_dir,'dir')
    mkdir(fig_fn_dir);
  end
  ct_saveas(h_fig(1),fig_fn);
  fig_fn = [ct_filename_ct_tmp(param,'','records_create','rel_time_cntr_latch') '.fig'];
  fprintf('Saving %s\n', fig_fn);
  ct_saveas(h_fig(1),fig_fn);
  
  % radar_time = double(records.raw.pps_cntr_latch) ...
  %   + double(records.raw.pps_ftime_cntr_latch)/param.records.file.clk;
  radar_time = double(rel_time_cntr_latch)/param.records.file.clk;
  comp_time = [];

elseif any(param.records.file.version == [413 414])
  %% Align/UTUA RDS: Nothing required
  %% Align/BAS RDS: Nothing required
  
elseif any(param.records.file.version == [415])
  %% Align/UTIG RDS MARFA/HICARS: Nothing required
  
else
  %% Align/CReSIS: Create output EPRI vector
  min_epri = inf;
  max_epri = -inf;
  epri_list = [];
  for board_idx = 1:length(boards)
    % Cluster EPRI values
    
    epri_raw = double(board_hdrs{board_idx}.epri);
    
    [A,B] = sort(epri_raw);
    med = median(A);
    [~,med_idx] = min(abs(A-med));
    A = A-med;
    dA = diff(A);
    bad_mask = zeros(size(B));
    bad_start_idx = find(dA(med_idx:end) > param.records.epri_jump_threshold,1);
    if ~isempty(bad_start_idx)
      bad_mask(med_idx+bad_start_idx:end) = true;
    end
    bad_start_idx = find(dA(med_idx-1:-1:1) > param.records.epri_jump_threshold,1);
    if ~isempty(bad_start_idx)
      bad_mask(med_idx-bad_start_idx:-1:1) = true;
    end
    back_idxs = 1:length(B);
    back_idxs = back_idxs(B);
    if sum(bad_mask) > 0
      warning('%d of %d records show bad out of range EPRI values. max jump is %d, param.records.epri_jump_threshold is %d', sum(bad_mask), length(epri_raw), max(dA), param.records.epri_jump_threshold);
    end
    epri_raw = epri_raw(back_idxs(logical(~bad_mask)));
    
    % Remove isolated EPRI values
    min_epri = min(min_epri,min(epri_raw));
    max_epri = max(max_epri,max(epri_raw));
    epri_list(end+(1:length(epri_raw))) = epri_raw;
    diff_epri_raw = diff(epri_raw);
    diff_epri(board_idx) = median(diff_epri_raw);
    min_score = inf;
    for offset = 0:diff_epri(board_idx)
      score = sum(mod((epri_raw - offset)/diff_epri(board_idx),1) ~= 0);
      if score < min_score
        min_score = score;
      end
    end
    if min_score > 0
      warning('%d of %d records show slipped EPRI values.', min_score, length(epri_raw));
    end
  end
  master_epri = mode(epri_list);
  if any(diff_epri ~= diff_epri(1))
    error('Inconsistent EPRI step size between boards. Should all be the same: %s', mat2str_generic(diff_epri));
  end
  epri = [fliplr(master_epri:-diff_epri(1):min_epri), master_epri+diff_epri:diff_epri:max_epri];

  %% Align/CReSIS: Fill in missing records from each board
  records.raw.epri = nan(size(epri));
  records.raw.seconds = nan(size(epri));
  records.raw.fraction = nan(size(epri));
  if param.records.file.version == 8
    records.settings.nyquist_zone_sig = nan(size(epri));
    records.settings.waveform_ID = nan(size(epri));
  end
  for board_idx = 1:length(boards)
    [~,out_idxs,in_idxs] = intersect(epri,board_hdrs{board_idx}.epri);
    fprintf('Board %d is missing %d of %d records.\n', board_idx, length(epri)-length(out_idxs), length(epri));
    
    % offset: Missing records filled in with -2^31
    offset = zeros(size(epri),'int32');
    offset(:) = -2^31;
    offset(out_idxs) = board_hdrs{board_idx}.offset(in_idxs);
    board_hdrs{board_idx}.offset = offset;
    
    % file_idx: Missing records filled in with NaN
    file_idx = nan(size(epri));
    file_idx(out_idxs) = board_hdrs{board_idx}.file_idx(in_idxs);
    board_hdrs{board_idx}.file_idx = interp_finite(file_idx,[],'nearest');
    
    % Time stamps are assumed to be the same from each board so each board
    % just writes all of its time stamps to the output records fields.
    records.raw.epri(out_idxs) = board_hdrs{board_idx}.epri(in_idxs);
    if board_idx > 1 && length(param.records.gps.time_offset) == 1
      % Old parameter spreadsheet format only contained a single entry for
      % all boards in param.records.gps.time_offset
      records.raw.seconds(out_idxs) = board_hdrs{board_idx}.seconds(in_idxs) ...
        + max(param.records.gps.time_offset) - param.records.gps.time_offset;
    else
      records.raw.seconds(out_idxs) = board_hdrs{board_idx}.seconds(in_idxs) ...
        + max(param.records.gps.time_offset) - param.records.gps.time_offset(board_idx);
    end
    records.raw.fraction(out_idxs) = board_hdrs{board_idx}.fraction(in_idxs);
    if param.records.file.version == 8
      records.settings.nyquist_zone_sig(out_idxs) = board_hdrs{board_idx}.nyquist_zone(in_idxs);
      records.settings.waveform_ID(out_idxs) = board_hdrs{board_idx}.waveform_ID(in_idxs);
    end
  end
  records.raw.epri = interp_finite(records.raw.epri);
  records.raw.seconds = interp_finite(records.raw.seconds);
  records.raw.fraction = interp_finite(records.raw.fraction);

  utc_time_sod = double(records.raw.seconds) + double(records.raw.fraction) / param.records.file.clk;
  comp_time = [];
end

%% Correct radar time with EPRI
% ===================================================================
if any(param.records.file.version == [9 10 103 412])
  %% Radar time: Arena
  epri_time = epri/param.radar.prf;
  radar_time_error = epri_time - radar_time;
  epri_time = epri_time - median(radar_time_error);
  radar_time_error = radar_time_error - median(radar_time_error);
  
  if 0
    plot(radar_time_error);
    ylim([-1 1])
  end
  
  bad_idxs = find(abs(radar_time_error)>0.2);

  if 0
    bad_idxs
    test_time = radar_time;
    test_time(bad_idxs) = epri_time(bad_idxs);
    figure(1); clf;
    plot(test_time);
    ylims = ylim;
    hold on;
    plot(radar_time)
    ylim(ylims)
  end
  
  radar_time(bad_idxs) = epri_time(bad_idxs);
  
elseif any(param.records.file.version == [413 414])
  %% Radar time: UTUA RDS
  % Nothing to be done
  board_idx = 1;
  radar_time = board_hdrs{board_idx}.gps_time;
  comp_time = [];
  
elseif any(param.records.file.version == [415])
  %% Radar time: UTIG RDS
  % Nothing to be done
  board_idx = 1;
  radar_time = board_hdrs{board_idx}.radar_time;
  comp_time = board_hdrs{board_idx}.comp_time;
  
elseif any(param.records.file.version == [1 2 3 4 5 6 7 8 11 101 403 407 408 420])
  %% Radar time: CReSIS
 
  if 0
    % Test sequences
    utc_time_sod = [0 1 2 3 10000 5 6 7 8 9 10 11 12 13 24 25 26 27 28 19 20 21 22 19 20 21 22]
    utc_time_sod = utc_time_sod + 0.0001*randn(size(utc_time_sod))
    epri = 100 + [1:23, 20:23]
    epri(15) = 5000;
  end
  
  % Estimate the pulse repetition interval, PRI
  PRI = median(diff(utc_time_sod));
  
  % Create an EPRI sequence from the time record
  time_epri = utc_time_sod / PRI;
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
    epri_new(start_idx:stop_idx+1) = tmp;
    
    % Reconstruct time from time-generated EPRIs
    tmp = [0 cumsum(dtime_epri(start_idx:stop_idx))*PRI];
    tmp = tmp - tmp(good_time_idx) + utc_time_sod(start_idx-1+good_time_idx);
    utc_time_sod_new(start_idx:stop_idx+1) = tmp;
    
    % Mark these records as good outputs
    good_out_mask(start_idx:stop_idx+1) = true;
    
    % Find the next sequence
    start_idx = stop_idx + find(mask(stop_idx+1:end) ~= 0,1);
  end
  
  utc_time_sod = utc_time_sod_new;
  
  % Check for day wraps in the UTC time seconds of day
  day_wrap_idxs = find(diff(utc_time_sod) < -50000);
  day_wrap_offset = zeros(size(utc_time_sod));
  for day_wrap_idx = day_wrap_idxs
    day_wrap_offset(day_wrap_idx+1:end) = day_wrap_offset(day_wrap_idx+1:end) + 86400;
  end
  utc_time_sod = utc_time_sod + day_wrap_offset;
  
  radar_time = utc_time_sod;
end

%% Correlate GPS with radar data
% ===================================================================
if param.records.gps.en
  records = records_create_sync_gps(param,records,radar_time,comp_time);
  
else
  records.gps_time = NaN*zeros(size(radar_time));
  records.lat = NaN*zeros(size(radar_time));
  records.lon = NaN*zeros(size(radar_time));
  records.elev = NaN*zeros(size(radar_time));
  records.roll = NaN*zeros(size(radar_time));
  records.pitch = NaN*zeros(size(radar_time));
  records.heading = NaN*zeros(size(radar_time));
  records.gps_source = 'NA';
end

%% Save records files
% =====================================================================

% Save concatenated files in records directories after time fix
records_fn = ct_filename_support(param,'','records');
[records_fn_dir records_fn_name] = fileparts(records_fn);
if ~exist(records_fn_dir,'dir')
  fprintf('Output directory %s does not exist, creating...\n', records_fn_dir);
  mkdir(records_fn_dir);
end

% Standard Fields
% records
%  .lat
%  .lon
%  .elev
%  .roll
%  .pitch
%  .heading
%  .gps_time
%  .gps_source
records.relative_filename = [];
records.relative_rec_num = [];
records.offset = [];
for board_idx = 1:length(board_hdrs)
  unique_file_idxs = unique(board_hdrs{board_idx}.file_idx);
  for file_idx = 1:length(unique_file_idxs)
    records.relative_rec_num{board_idx}(file_idx) = find(board_hdrs{board_idx}.file_idx == unique_file_idxs(file_idx),1);
    [fn_dir fn_name fn_ext] = fileparts(board_fns{board_idx}{unique_file_idxs(file_idx)});
    records.relative_filename{board_idx}{file_idx} = [fn_name fn_ext];
  end
  records.offset(board_idx,:) = board_hdrs{board_idx}.offset;
end
records.bit_mask = zeros(size(records.offset),'uint8');
records.radar_name = param.radar_name;
if param.ct_file_lock
  records.file_version = '1L';
else
  records.file_version = '1';
end
records.file_type = 'records';

% Create the first entry in the records.settings field
records.settings.wfs_records = 1;
records.settings.wfs = wfs;

records.notes = cat(2,sprintf('\nEPRI NOTES\n%s',epri_notes), ...
  sprintf('\nCLOCK NOTES\n%s',clock_notes), ...
  sprintf('\nRADAR TIME NOTES\n%s',radar_time_notes));
records.param_records = param;

fprintf('Saving records file %s (%s)\n',records_fn,datestr(now));
ct_file_lock_check(records_fn,3);
ct_save(records_fn,'-v7.3','-struct','records');
