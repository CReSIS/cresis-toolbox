% script gps_create
%
% Makes GPS files (called from each mission specific routine)
% Variables set up in gps_create_SEASON_SOURCE
%
% in_fn = 1 by N cell array of strings containing filenames
%  Full path of input GPS file
%  Can also do a cell array of strings in place of one of the strings and
%  this will cause all the file to be concatenated into one output GPS file
% file_type = 1 by N cell array of strings
%  File format for each cell in in_fn (e.g. 'Applanix', 'ATM', 'Litton', etc)
%  Determines which read_gps_? function will be called
%  Can also do a cell array of file type strings in place of one of the
%  strings as long as the length matches the corresponding cell from in_fn.
%  This allows the file type to be set on a per file basis.
% in_fn_ins = 1 by N cell array of strings containing filenames (optional)
%  Full path of input INS file (optional since INS often in GPS file)
%  Can also do a cell array of strings in place of one of the strings and
%  this will cause all the file to be concatenated into one output INS file
% file_type_ins = 1 by N cell array of strings
%  File format for each cell in in_fn_ins (e.g. 'Applanix', 'ATM', 'Litton', etc)
%  Determines which read_gps_? or read_ins_? function will be called
%  Can also do a cell array of file type strings in place of one of the
%  strings as long as the length matches the corresponding cell from in_fn_ins.
%  This allows the file type to be set on a per file basis.
% params = 1 by N cell array of structures
%  Parameters for each instance
%  If the option to pass a cell array of filename strings for a single output GPS
%  file is used, then the params structure must also be cell array of
%  structures which correspond to each of the files in the cell array of
%  filename strings.
% gps_path = string
%  Output directory
% out_fn = 1 by N cell array of strings
%  Output file name for each instance
% gps_source = string describing GPS processing location and the
%  version of the processed file. This is done by placing a hyphen
%  after the location identifier. The location identifier is used
%  with the season ID and the lever arm function to determine which
%  lever arm to use. Examples:
%  gravimeter-field: processed to gravimeter INS, field version of GPS/INS
%    product
%  atm-field: processed to ATM DGPS antenna, field version of GPS/INS
%    product
%  atm-final_20110826: processed to ATM DGPS antenna, final version of GPS/INS
%    product as of 20110826
% date_str: 8 letter sequence containing the date 'YYYYMMDD'
% season_name: string containing season name YYYY_LOCATION_PLATFORM
%
%
% Author: John Paden

% ======================================================================
% Read and translate files according to user settings
% ======================================================================

for file_idx = 1:length(in_fns)
  in_fn = in_fns{file_idx};
  if ischar(in_fn)
    in_fn = {in_fn};
  end
  if ~exist('sync_flag','var') || numel(sync_flag) < file_idx
    sync_flag{file_idx} = 0;
  end
  if ~sync_flag{file_idx}
    sync_fn = {};
  else
    if ~exist('sync_fns','var') || file_idx > length(sync_fns)
      error('sync_flag is true, but no files specified in sync_fns for this date.');
    else
      sync_fn = sync_fns{file_idx};
    end
  end
  if ischar(sync_fn)
    sync_fn = {sync_fn};
  end
  out_fn = fullfile(gps_path,out_fns{file_idx});
  if isempty(in_fn)
    error('No input GPS files found in in_fns{%d} variable. Usually this is because the file path is not setup.\n', file_idx);
  end
  
  fprintf('=====================================================================\n');
  fprintf('%s:\t%s\t%s\n', mfilename, out_fn, datestr(now,'yyyymmdd_HHMMSS'));
  fprintf('=====================================================================\n');
  
  %% Load Radar Sync GPS files (mcrds, accum2, arena)
  if sync_flag{file_idx}
    if isstruct(sync_params{file_idx})
      sync_params{file_idx} = repmat({sync_params{file_idx}},size(sync_fn));
    end
    clear sync_gps;
    fprintf('Sync_files\t%s\n', datestr(now,'yyyymmdd_HHMMSS'));
    for sync_fn_idx = 1:length(sync_fn)
      if ~exist('sync_file_type','var') || length(sync_file_type) < file_idx || isempty(sync_file_type{file_idx})
        % Assume nmea because of legacy support which did not require this field to be set
        warning('Set sync_file_type{%d} since corresponding sync_flag{%d} is set to true. Assuming sync_file_type{%d} = ''nmea''.', file_idx, file_idx, file_idx);
        sync_file_type{file_idx} = 'nmea';
      end
      if iscell(sync_file_type{file_idx})
        cur_file_type = sync_file_type{file_idx}{sync_fn_idx};
      else
        cur_file_type = sync_file_type{file_idx};
      end
      gps_fh = gps_create_fh(cur_file_type);
      fprintf('  %s\n', sync_fn{sync_fn_idx});
      gps_tmp = gps_fh(sync_fn{sync_fn_idx},sync_params{file_idx}{sync_fn_idx});
      
      if sync_fn_idx == 1
        sync_gps = gps_tmp;
      else
        sync_gps.gps_time = [sync_gps.gps_time, gps_tmp.gps_time];
        sync_gps.lat = [sync_gps.lat, gps_tmp.lat];
        sync_gps.lon = [sync_gps.lon, gps_tmp.lon];
        sync_gps.elev = [sync_gps.elev, gps_tmp.elev];
        sync_gps.roll = [sync_gps.roll, gps_tmp.roll];
        sync_gps.pitch = [sync_gps.pitch, gps_tmp.pitch];
        sync_gps.heading = [sync_gps.heading, gps_tmp.heading];
        sync_gps.comp_time = [sync_gps.comp_time, gps_tmp.comp_time];
        if isfield(sync_gps,'radar_time')
          sync_gps.radar_time = [sync_gps.radar_time, gps_tmp.radar_time];
        end
        if isfield(sync_gps,'profileCntr')
          sync_gps.profileCntr = [sync_gps.profileCntr, gps_tmp.profileCntr];
        end
      end
    end
    
    %% Remove records with NaN
    if isfield(sync_gps,'radar_time')
      good_mask = ~(isnan(sync_gps.gps_time) | isnan(sync_gps.radar_time));
      sync_gps.radar_time = sync_gps.radar_time(good_mask);
    else
      good_mask = ~(isnan(sync_gps.gps_time) | isnan(sync_gps.comp_time));
    end
    sync_gps.gps_time = sync_gps.gps_time(good_mask);
    sync_gps.comp_time = sync_gps.comp_time(good_mask);
    sync_gps.lat = sync_gps.lat(good_mask);
    sync_gps.lon = sync_gps.lon(good_mask);
    sync_gps.elev = sync_gps.elev(good_mask);
    sync_gps.roll = sync_gps.roll(good_mask);
    sync_gps.pitch = sync_gps.pitch(good_mask);
    sync_gps.heading = sync_gps.heading(good_mask);
    if isfield(sync_gps,'profileCntr')
      sync_gps.profileCntr = sync_gps.profileCntr(good_mask);
    end
    
    %% Check for day wraps
    % Find jumps in the GPS time that are probably due to day interval
    % 86400 seconds.
    day_jumps = find(diff(sync_gps.gps_time) < -60000);
    if ~isempty(day_jumps)
      warning('Found a day wrap in sync gps... correcting');
    end
    for jump_idx = day_jumps
      sync_gps.gps_time(jump_idx+1:end) = sync_gps.gps_time(jump_idx+1:end) + 86400;
    end
    
    %% Check/make the sync GPS data monotonic in time in case it is not
    sync_gps = gps_force_monotonic(sync_gps);
  end
  
  %% Load GPS files
  if ischar(in_fn)
    in_fn = {in_fn};
  end
  if isstruct(params{file_idx})
    params{file_idx} = repmat({params{file_idx}},size(in_fn));
  end
  clear gps;
  separate_ins_data_flag = false;
  fprintf('Input_files\t%s\n', datestr(now,'yyyymmdd_HHMMSS'));
  for in_fn_idx = 1:length(in_fn)
    if iscell(file_type{file_idx})
      cur_file_type = file_type{file_idx}{in_fn_idx};
      plus_idx = regexp(cur_file_type,'+');
      if ~isempty(plus_idx)
        warning('Deprecated GPS+INS file_type format using "+". Use file_type_ins instead of combining INS type with GPS file_type. For example "awi_netcdf+awi_netcdf" should be "awi_netcdf" in file_type and "awi_netcdf" in file_type_ins.');
        separate_ins_data_flag = true;
        file_type_ins{file_idx}{in_fn_idx} = cur_file_type(plus_idx+1:end);
        cur_file_type = cur_file_type(1:plus_idx-1);
      end
    else
      cur_file_type = file_type{file_idx};
      plus_idx = regexp(cur_file_type,'+');
      if ~isempty(plus_idx)
        warning('Deprecated GPS+INS file_type format using "+". Use file_type_ins instead of combining INS type with GPS file_type. For example "awi_netcdf+awi_netcdf" should be "awi_netcdf" in file_type and "awi_netcdf" in file_type_ins.');
        separate_ins_data_flag = true;
        file_type_ins{file_idx} = cur_file_type(plus_idx+1:end);
        cur_file_type = cur_file_type(1:plus_idx-1);
      end
    end
    gps_fh = gps_create_fh(cur_file_type);
    fn = in_fn{in_fn_idx};
    [fn_dir,fn_name] = fileparts(fn);
    gps_tmp = gps_fh(fn,params{file_idx}{in_fn_idx});
    if ~isempty(gps_tmp.gps_time)
      % Print out filename, start/stop GPS time, and duration in seconds
      fprintf('-- %s\t%s\t%s\t%s\t%g\t%s\n', fn_dir,fn_name, ...
        datestr(epoch_to_datenum(gps_tmp.gps_time(1))), ...
        datestr(epoch_to_datenum(gps_tmp.gps_time(end))), diff(gps_tmp.gps_time([1 end])), datestr(now,'yyyymmdd_HHMMSS'));
    else
      % Print out filename only because there are no entries
      fprintf('-- %s\t%s\t\t\t\n', fn_dir,fn_name);
    end
    
    if in_fn_idx == 1
      gps.gps_time = gps_tmp.gps_time;
      gps.lat = gps_tmp.lat;
      gps.lon = gps_tmp.lon;
      gps.elev = gps_tmp.elev;
      gps.roll = gps_tmp.roll;
      gps.pitch = gps_tmp.pitch;
      gps.heading = gps_tmp.heading;
      if isfield(gps_tmp,'radar_time')
        gps.radar_time = gps_tmp.radar_time;
      end
      if isfield(gps_tmp,'comp_time')
        gps.comp_time = gps_tmp.comp_time;
      end
    else
      gps.gps_time = [gps.gps_time, gps_tmp.gps_time];
      gps.lat = [gps.lat, gps_tmp.lat];
      gps.lon = [gps.lon, gps_tmp.lon];
      gps.elev = [gps.elev, gps_tmp.elev];
      gps.roll = [gps.roll, gps_tmp.roll];
      gps.pitch = [gps.pitch, gps_tmp.pitch];
      gps.heading = [gps.heading, gps_tmp.heading];
      if isfield(gps_tmp,'radar_time')
        gps.radar_time = [gps.radar_time, gps_tmp.radar_time];
      end
      if isfield(gps_tmp,'comp_time')
        gps.comp_time = [gps.comp_time, gps_tmp.comp_time];
      end
    end
  end
  
  if isempty(gps.gps_time)
    file_list_str = sprintf('  %s\n', in_fn{:});
    error('No GPS data loaded, isempty(gps.gps_time) == true for files:\n%s', file_list_str);
  end
  
  %% Remove records with NaN in gps_time or trajectory
  good_mask = ~(isnan(gps.gps_time) | isnan(gps.lat) ...
    | isnan(gps.lon) | isnan(gps.elev));
  gps.gps_time = gps.gps_time(good_mask);
  gps.lat = gps.lat(good_mask);
  gps.lon = gps.lon(good_mask);
  gps.elev = gps.elev(good_mask);
  gps.roll = gps.roll(good_mask);
  gps.pitch = gps.pitch(good_mask);
  gps.heading = gps.heading(good_mask);
  if isfield(gps,'radar_time')
    gps.radar_time = gps.radar_time(good_mask);
  end
  if isfield(gps,'comp_time')
    gps.comp_time = gps.comp_time(good_mask);
  end
  gps.gps_source = gps_source{file_idx};
  
  %% Interpolate through NaN attitude data
  gps.roll = interp_finite(gps.roll,0);
  gps.pitch = interp_finite(gps.pitch,0);
  gps.heading = interp_finite(gps.heading,0,@gps_interp1);
  
  %% Check for day wraps
  % Find jumps in the GPS time that are probably due to day interval
  % 86400 seconds.
  day_jumps = find(diff(gps.gps_time) < -60000);
  if ~isempty(day_jumps)
    warning('Found a day wrap... correcting');
  end
  for jump_idx = day_jumps
    gps.gps_time(jump_idx+1:end) = gps.gps_time(jump_idx+1:end) + 86400;
  end

  %% Check/make the GPS data monotonic in time in case it is not
  gps = gps_force_monotonic(gps);
  
  %% Fabricating a heading now
  [est_heading,along_track,speed] = trajectory_coord_system(gps);
  
  %% Load INS data for special case where it is separate from GPS
  if separate_ins_data_flag ...
      || (exist('in_fns_ins','var') && length(in_fns_ins) >= file_idx && ~isempty(in_fns_ins{file_idx}))
    if ischar(in_fns_ins{file_idx})
      in_fns_ins{file_idx} = {in_fns_ins{file_idx}};
    end
    if isstruct(params_ins{file_idx})
      params_ins{file_idx} = repmat({params_ins{file_idx}},size(in_fns_ins{file_idx}));
    end
    clear ins;
    if isempty(in_fns_ins{file_idx})
      error('No input INS files found in in_fns{%d} variable. Usually this is because the file path is not setup.\n', file_idx);
    end
    for in_fn_idx = 1:length(in_fns_ins{file_idx})
      if iscell(file_type_ins{file_idx})
        cur_file_type = file_type_ins{file_idx}{in_fn_idx};
      else
        cur_file_type = file_type_ins{file_idx};
      end
      fprintf('  INS file %s\n', in_fns_ins{file_idx}{in_fn_idx});
      if strcmpi(cur_file_type,'applanix')
        ins_tmp = read_gps_applanix(in_fns_ins{file_idx}{in_fn_idx},params_ins{file_idx}{in_fn_idx});
      elseif strcmpi(cur_file_type,'Litton')
        ins_tmp = read_ins_litton(in_fns_ins{file_idx}{in_fn_idx},params_ins{file_idx}{in_fn_idx});
      elseif strcmpi(cur_file_type,'Litton_DGPS')
        ins_tmp = read_gps_litton(in_fns_ins{file_idx}{in_fn_idx},params_ins{file_idx}{in_fn_idx});
      elseif strcmpi(cur_file_type,'General_ASCII')
        ins_tmp = read_gps_general_ascii(in_fns_ins{file_idx}{in_fn_idx},params_ins{file_idx}{in_fn_idx});
      elseif  strcmpi(cur_file_type,'awi_netcdf')
        ins_tmp = read_gps_netcdf(in_fns_ins{file_idx}{in_fn_idx},params_ins{file_idx}{in_fn_idx});
      else
        error('Unknown INS type %s.', cur_file_type);
      end
      if in_fn_idx == 1
        ins = ins_tmp;
      else
        ins.gps_time = [ins.gps_time, ins_tmp.gps_time];
        ins.lat = [ins.lat, ins_tmp.lat];
        ins.lon = [ins.lon, ins_tmp.lon];
        ins.elev = [ins.elev, ins_tmp.elev];
        ins.roll = [ins.roll, ins_tmp.roll];
        ins.pitch = [ins.pitch, ins_tmp.pitch];
        ins.heading = [ins.heading, ins_tmp.heading];
      end
    end
    
    bad_mask = ins.heading == 0;
    if sum(bad_mask) > 0
      fprintf('Found %d bad records out of %d records based on heading == 0\n', sum(bad_mask), length(bad_mask));
      ins.gps_time = ins.gps_time(~bad_mask);
      ins.lat = ins.lat(~bad_mask);
      ins.lon = ins.lon(~bad_mask);
      ins.elev = ins.elev(~bad_mask);
      ins.roll = ins.roll(~bad_mask);
      ins.pitch = ins.pitch(~bad_mask);
      ins.heading = ins.heading(~bad_mask);
    end
    
    if isempty(ins.gps_time)
      warning('INS data specified, but no good INS data found.');
      
    else
      
      % Check for large time gaps in INS data and fill with level flight
      if 0
        figure(1); clf;
        bad_mask = diff(ins.gps_time) > 10;
        bad_mask = grow(bad_mask,1);
        time_skips = diff(ins.gps_time);
        along_track = geodetic_to_along_track(gps.lat,gps.lon);
        vel = diff(along_track) ./ diff(gps.gps_time);
        plot(gps.gps_time(1:end-1),vel)
        hold on
        plot(ins.gps_time(bad_mask),time_skips(bad_mask),'r');
        hold off;
        
        figure(2); clf;
        plot(ins.gps_time,ins.roll*180/pi,'.')
        hold on
        plot(ins.gps_time(bad_mask),time_skips(bad_mask),'r');
        hold off;
        ylim([-20 20])
        grid on
        
        figure(3); clf;
        plot(gps.gps_time,est_heading*180/pi,'g.');
        hold on
        plot(ins.gps_time,ins.heading*180/pi,'.')
        plot(ins.gps_time(bad_mask),time_skips(bad_mask),'r');
        hold off;
        grid on
      end
      
      bad_idxs = find(diff(ins.gps_time) > 20);
      if ins.gps_time(1) - gps.gps_time(1) > 10
        bad_idxs = [0 bad_idxs];
      end
      if gps.gps_time(end) - ins.gps_time(end) > 10
        bad_idxs = [bad_idxs length(ins.gps_time)];
      end
      for bad_idxs_idx = 1:length(bad_idxs)
        idx = bad_idxs(bad_idxs_idx);
        
        % Find gps indices in this gap
        if idx == 0
          new_gps_times = gps.gps_time(1):ins.gps_time(idx+1)-10;
          edge_gps_times = [gps.gps_time(1) ins.gps_time(idx+1)];
          est_heading_error = [0 ins.heading(idx+1) - gps_interp1(gps.gps_time,est_heading,ins.gps_time(idx+1))];
        elseif idx == length(ins.gps_time)
          new_gps_times = ins.gps_time(idx)+10:gps.gps_time(end);
          edge_gps_times = [ins.gps_time(idx) gps.gps_time(end)];
          est_heading_error = [ins.heading(idx) - gps_interp1(gps.gps_time,est_heading,ins.gps_time(idx)) 0];
        else
          new_gps_times = ins.gps_time(idx)+10:ins.gps_time(idx+1)-10;
          edge_gps_times = ins.gps_time(idx:idx+1);
          est_heading_error = ins.heading(idx:idx+1) - gps_interp1(gps.gps_time,est_heading,ins.gps_time(idx:idx+1));
        end
        bad_idxs(bad_idxs_idx+1:end) = bad_idxs(bad_idxs_idx+1:end) + length(new_gps_times);
        fprintf('  Inserting %d level flight records due to missing INS data\n', length(new_gps_times));
        
        ins.roll = [ins.roll(1:idx) zeros(size(new_gps_times)) ins.roll(idx+1:end)];
        ins.pitch = [ins.pitch(1:idx) zeros(size(new_gps_times)) ins.pitch(idx+1:end)];
        ins.lat = [ins.lat(1:idx) NaN*zeros(size(new_gps_times)) ins.lat(idx+1:end)];
        ins.lon = [ins.lon(1:idx) NaN*zeros(size(new_gps_times)) ins.lon(idx+1:end)];
        ins.elev = [ins.elev(1:idx) NaN*zeros(size(new_gps_times)) ins.elev(idx+1:end)];
        
        inserted_heading = gps_interp1(gps.gps_time,est_heading,new_gps_times) ...
          + gps_interp1(edge_gps_times,est_heading_error,new_gps_times);
        ins.heading = [ins.heading(1:idx) inserted_heading ins.heading(idx+1:end)];
        
        ins.gps_time = [ins.gps_time(1:idx) new_gps_times ins.gps_time(idx+1:end)];
        
      end
      
      if 0
        figure(4); clf;
        plot(gps.gps_time,est_heading*180/pi,'g.');
        hold on
        plot(ins.gps_time,ins.heading*180/pi,'.')
        hold off;
        grid on
        keyboard
      end
      
      % Insert filler points from gps (ensures that sparse ins data does not
      % create a sparse final dataset when gps data is available)
      new_gps_time = union(gps.gps_time,ins.gps_time);
      ins.roll = interp1(ins.gps_time,ins.roll,new_gps_time);
      ins.pitch = interp1(ins.gps_time,ins.pitch,new_gps_time);
      ins.heading = gps_interp1(ins.gps_time,ins.heading,new_gps_time);
      interp_idxs = find(ins.gps_time >= gps.gps_time(1) & ins.gps_time <= gps.gps_time(end));
      ins.lat(interp_idxs) = interp1(gps.gps_time,gps.lat,ins.gps_time(interp_idxs));
      ins.lon(interp_idxs) = gps_interp1(gps.gps_time,gps.lon/180*pi,ins.gps_time(interp_idxs))*180/pi;
      ins.elev(interp_idxs) = interp1(gps.gps_time,gps.elev,ins.gps_time(interp_idxs));
      ins.lat = interp1(ins.gps_time,ins.lat,new_gps_time);
      ins.lon = gps_interp1(ins.gps_time,ins.lon/180*pi,new_gps_time)*180/pi;
      ins.elev = interp1(ins.gps_time,ins.elev,new_gps_time);
      ins.gps_time = new_gps_time;
      gps = ins;
      
      %% Remove records with NaN in gps_time or trajectory
      good_mask = ~(isnan(gps.gps_time) | isnan(gps.lat) ...
        | isnan(gps.lon) | isnan(gps.elev));
      gps.gps_time = gps.gps_time(good_mask);
      gps.lat = gps.lat(good_mask);
      gps.lon = gps.lon(good_mask);
      gps.elev = gps.elev(good_mask);
      gps.roll = gps.roll(good_mask);
      gps.pitch = gps.pitch(good_mask);
      gps.heading = gps.heading(good_mask);
      if isfield(gps,'radar_time')
        gps.radar_time = gps.radar_time(good_mask);
      end
      if isfield(gps,'comp_time')
        gps.comp_time = gps.comp_time(good_mask);
      end
      gps.gps_source = gps_source{file_idx};
      
      %% Interpolate through NaN attitude data
      gps.roll = interp_finite(gps.roll,0);
      gps.pitch = interp_finite(gps.pitch,0);
      gps.heading = interp_finite(gps.heading,0,@gps_interp1);
    end

  end

  %% Now that INS data may have been added, check/make the GPS data monotonic in time in case it is not
  [gps,~,monotonic_idxs] = gps_force_monotonic(gps);
  
  %% Using estimated heading based on the trajectory if heading is all zeros
  if all(gps.heading == 0)
    warning('These input files have heading(:) == 0. Using the estimated heading.');
    gps.heading = est_heading(monotonic_idxs);
  end
  
  %% Heading and longitude modulo-2*pi
  gps.heading = angle(exp(1i*gps.heading));
  gps.lon = angle(exp(1i*gps.lon/180*pi))*180/pi;
  
  %% Add software revision information
  gps.sw_version = current_software_version;
  
  %% Add date_str and season_name
  gps.date_str = date_str{file_idx};
  gps.season_name = season_name;

  %% Save output file
  fprintf('Output_file\t%s\t%s\n', out_fn, datestr(now,'yyyymmdd_HHMMSS'));
  gps.file_version = '2';
  gps.file_type = 'gps';
  if sync_flag{file_idx}
    % Add the Radar Synchronization variables for mcrds, accum2, acords,
    % arena
    
    % Synchronize computer time and radar time from NMEA file to gps time
    gps.sync_gps_time = sync_gps.gps_time;
    gps.sync_lat = sync_gps.lat;
    gps.sync_lon = sync_gps.lon;
    gps.sync_elev = sync_gps.elev;
    gps.comp_time = sync_gps.comp_time;
    if isfield(sync_gps,'radar_time')
      gps.radar_time = sync_gps.radar_time;
    end

    if isfield(gps,'radar_time')
      ct_save(out_fn,'-v7.3','-STRUCT','gps','gps_time','lat','lon','elev','roll','pitch','heading','gps_source','sync_gps_time','sync_lat','sync_lon','sync_elev','comp_time','radar_time','sw_version','file_version','file_type','season_name','date_str');
    else
      ct_save(out_fn,'-v7.3','-STRUCT','gps','gps_time','lat','lon','elev','roll','pitch','heading','gps_source','sync_gps_time','sync_lat','sync_lon','sync_elev','comp_time','sw_version','file_version','file_type','season_name','date_str');
    end
  else
    out_fields = {};
    if isfield(gps,'radar_time')
      out_fields{end+1} = 'radar_time';
    end
    if isfield(gps,'comp_time')
      out_fields{end+1} = 'comp_time';
    end
    ct_save(out_fn,'-v7.3','-STRUCT','gps','gps_time','lat','lon','elev','roll','pitch','heading','gps_source',out_fields{:},'sw_version','file_version','file_type','season_name','date_str');
  end
  
end
