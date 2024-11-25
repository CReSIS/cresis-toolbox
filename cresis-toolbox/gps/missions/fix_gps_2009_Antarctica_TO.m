% Fix or check the GPS for 2009 Antarctica TO
%
% The problem was that the data were
% collected over a day boundary so some files' "seconds of day" field
% are referenced on one day and some are reference to the next day.
% This code has been run and everything should be working now... it is
% being kept here to show where things came from.
%
% First section finds the correct absolute time
% Second section shows how to create the make_gps_2009_antarctica_TO.m
% file.
% Third section tries to convert frames, echograms, layer data to the
% new times.
%
% See also: make_gps_2009_antarctica_TO.m

if 0
  %% FIRST SECTION of code was used to determine the correct absolute
  % time for each segment of data.
  % This section uses all the GPS information, file "seconds of day",
  % and the filename timestamps to disambiguate everything. The
  % param spreadsheet should be fixed now.
  
  meta_dir = '/cresis/projects/metadata/2009_Antarctica_TO/';
  
  gps_info = struct('fn',[],'start',[],'stop',[]);
  
  gps_fns = get_filenames(meta_dir,'rover_diff','','[0-9].txt');
  for fn_idx = 1:length(gps_fns)
    gps_fn = gps_fns{fn_idx};
    %   fprintf('Loading %s (%s)\n', gps_fn, datestr(now,'HH:MM:SS'));
    
    gps = read_gps_novatel(gps_fn,struct('time_reference','gps'));
    
    [tmp gps_fn_name gps_fn_ext] = fileparts(gps_fn);
    fprintf('%s\t%s\t%s\n', [gps_fn_name gps_fn_ext], ...
      datestr(epoch_to_datenum(gps.gps_time(1)),'yyyy mm dd   HH:MM:SS'), ...
      datestr(epoch_to_datenum(gps.gps_time(end)),'yyyy mm dd   HH:MM:SS'));
    gps_info.fn{end+1} = gps_fn_name;
    gps_info.start(end+1) = gps.gps_time(1);
    gps_info.stop(end+1) = gps.gps_time(end);
  end
  
  gps_fns = get_filenames(meta_dir,'rover_ppp','','[0-9]_TC.txt');
  for fn_idx = 1:length(gps_fns)
    gps_fn = gps_fns{fn_idx};
    %   fprintf('Loading %s (%s)\n', gps_fn, datestr(now,'HH:MM:SS'));
    
    gps = read_gps_novatel(gps_fn,struct('time_reference','gps'));
    
    [tmp gps_fn_name gps_fn_ext] = fileparts(gps_fn);
    fprintf('%s\t%s\t%s\n', [gps_fn_name gps_fn_ext], ...
      datestr(epoch_to_datenum(gps.gps_time(1)),'yyyy mm dd   HH:MM:SS'), ...
      datestr(epoch_to_datenum(gps.gps_time(end)),'yyyy mm dd   HH:MM:SS'));
    gps_info.fn{end+1} = gps_fn_name;
    gps_info.start(end+1) = gps.gps_time(1);
    gps_info.stop(end+1) = gps.gps_time(end);
  end
  
  gps_fns = get_filenames(meta_dir,'rover_ppp','','[0-9]_LC.txt');
  for fn_idx = 1:length(gps_fns)
    gps_fn = gps_fns{fn_idx};
    %   fprintf('Loading %s (%s)\n', gps_fn, datestr(now,'HH:MM:SS'));
    
    gps = read_gps_novatel(gps_fn,struct('time_reference','gps'));
    
    [tmp gps_fn_name gps_fn_ext] = fileparts(gps_fn);
    fprintf('%s\t%s\t%s\n', [gps_fn_name gps_fn_ext], ...
      datestr(epoch_to_datenum(gps.gps_time(1)),'yyyy mm dd   HH:MM:SS'), ...
      datestr(epoch_to_datenum(gps.gps_time(end)),'yyyy mm dd   HH:MM:SS'));
    gps_info.fn{end+1} = gps_fn_name;
    gps_info.start(end+1) = gps.gps_time(1);
    gps_info.stop(end+1) = gps.gps_time(end);
  end
  
  gps_fns = get_filenames(meta_dir,'RevealGPS','','[A-G]');
  for fn_idx = 1:length(gps_fns)
    gps_fn = gps_fns{fn_idx};
    %   fprintf('Loading %s (%s)\n', gps_fn, datestr(now,'HH:MM:SS'));
    
    [tmp gps_fn_name gps_fn_ext] = fileparts(gps_fn);
    
    year = str2double(gps_fn_name(11:14));
    month = str2double(gps_fn_name(15:16));
    day = str2double(gps_fn_name(17:18));
    
    gps = read_gps_nmea(gps_fn,struct('year',year,'month',month,'day',day,'time_reference','utc'));
    
    fprintf('%s\t%s\t%s\n', [gps_fn_name gps_fn_ext], ...
      datestr(epoch_to_datenum(gps.gps_time(1)),'yyyy mm dd   HH:MM:SS'), ...
      datestr(epoch_to_datenum(gps.gps_time(end)),'yyyy mm dd   HH:MM:SS'));
    
    gps_info.fn{end+1} = gps_fn_name;
    gps_info.start(end+1) = gps.gps_time(1);
    gps_info.stop(end+1) = gps.gps_time(end);
  end
  
  radar_info = struct('day_seg',[],'start',[],'stop',[],'fn_start',[],'fn_stop',[]);
  params = read_param_xls('/users/paden/scripts/branch/params-cr1/mcords_param_2009_Antarctica_TO.xls');
  for param_idx = 1:length(params)
    param = params(param_idx);
    radar_info.day_seg{end+1} = param.day_seg;
    
    % Get files using vectors sheet
    [base_dir,adc_folder_name,fns,file_idxs] = get_segment_file_list(param,param.vectors.file.adc,true);
    
    clear vectors;
    vectors_idx = 0;
    
    %% Read header information for start file
    fn = fns{file_idxs(1)};
    
    fname = fname_info_mcords(fn);
    radar_info.fn_start(end+1) = datenum_to_epoch(fname.datenum);
    try
      if fname.file_idx == 0
        % First file after record starts has junk data at start:
        % Skip first 64 MB (should just be 32 MB, but a lot of errors
        % seem to occur in the first 64 MB)
        finfo = frame_sync_info(fn,struct('fast',1,'first_byte',2^26));
      else
        finfo = frame_sync_info(fn,struct('fast',1));
      end
    catch
      % Sync failed (probably too short of a file)
      keyboard
    end;
    data_start = finfo.ideal_sync_pos(1);
    
    % Read first header
    [fid msg] = fopen(fn,'r','ieee-be');
    if fid == -1
      fprintf('Unable to open file: %s\n',fn);
      error('File:Open',msg);
    end
    fseek(fid,data_start+8,'bof');
    
    vectors_idx = vectors_idx + 1;
    radar_info.start(end+1) = double(fread(fid,1,'uint32')) + double(fread(fid,1,'uint32'))/(param.radar.fs/2);
    
    fclose(fid);
    
    %% Read header information for stop file
    fn = fns{file_idxs(end)};
    
    fname = fname_info_mcords(fn);
    radar_info.fn_stop(end+1) = datenum_to_epoch(fname.datenum);
    try
      if fname.file_idx == 0
        % First file after record starts has junk data at start:
        % Skip first 64 MB (should just be 32 MB, but a lot of errors
        % seem to occur in the first 64 MB)
        finfo = frame_sync_info(fn,struct('fast',1,'first_byte',2^26));
      else
        finfo = frame_sync_info(fn,struct('fast',1));
      end
    catch
      % Sync failed (probably too short of a file)
      keyboard
    end;
    data_start = finfo.ideal_sync_pos(1);
    
    % Read first header
    [fid msg] = fopen(fn,'r','ieee-be');
    if fid == -1
      fprintf('Unable to open file: %s\n',fn);
      error('File:Open',msg);
    end
    fseek(fid,data_start+8,'bof');
    
    vectors_idx = vectors_idx + 1;
    radar_info.stop(end+1) = double(fread(fid,1,'uint32')) + double(fread(fid,1,'uint32'))/(param.radar.fs/2);
    
    fclose(fid);
    
    radar_info.start(end) = datenum_to_epoch(datenum(str2double(param.day_seg(1:4)), ...
      str2double(param.day_seg(5:6)), ...
      str2double(param.day_seg(7:8)), ...
      0, 0, radar_info.start(end))) + param.vectors.gps.time_offset;
    
    radar_info.stop(end) = datenum_to_epoch(datenum(str2double(param.day_seg(1:4)), ...
      str2double(param.day_seg(5:6)), ...
      str2double(param.day_seg(7:8)), ...
      0, 0, radar_info.stop(end))) + param.vectors.gps.time_offset;
    
    fprintf('%s\t%s\t%s\t%s\t%s\t%.0f\n', param.day_seg, ...
      datestr(epoch_to_datenum(radar_info.start(end)),'yyyy mm dd   HH:MM:SS'), ...
      datestr(epoch_to_datenum(radar_info.stop(end)),'yyyy mm dd   HH:MM:SS'), ...
      datestr(epoch_to_datenum(radar_info.fn_start(end) + 12*3600),'yyyy mm dd   HH:MM:SS'), ...
      datestr(epoch_to_datenum(radar_info.fn_stop(end) + 12*3600),'yyyy mm dd   HH:MM:SS'), ...
      radar_info.start(end) - radar_info.fn_start(end));
    
  end
  save('~/2009_antarctica_TO_fix.mat','radar_info','gps_info')
end

if 0
  %% SECOND SECTION prints out the code that should be copied and pasted
  % to make_gps_2009_antarctica_TO.m (which has already been done).
  % The code at the end of this section should be copied into make_gps_2009_antarctica_TO.m
  % and this has also been done.
  load('~/2009_antarctica_TO_fix.mat','radar_info','gps_info')
  
  % Fix bug if names don't have .txt on the end
  for gps_idx = 1:length(gps_info.fn)
    if isempty(strfind(gps_info.fn{gps_idx},'Reveal'))
      gps_info.fn{gps_idx} = [gps_info.fn{gps_idx} '.txt'];
    end
  end
  
  % Check for any out of order segments (there should be none and this
  % should return empty)
  if ~isempty(find(diff(radar_info.start) < 0))
    error('Out of order segments')
  end
  
  % Print out which GPS files are associated with each data segment
  last_good_gps_fn = [];
  for radar_idx = 1:length(radar_info.day_seg)
    if radar_info.stop(radar_idx) < radar_info.start(radar_idx)
      radar_info.stop(radar_idx) = radar_info.stop(radar_idx) + 24*3600;
    end
    
    good_gps_idxs = [];
    good_gps_idxs_type = [];
    for gps_idx = 1:length(gps_info.fn)
      if radar_info.start(radar_idx) >= gps_info.start(gps_idx) ...
          && radar_info.stop(radar_idx) <= gps_info.stop(gps_idx)
        good_gps_idxs(end+1) = gps_idx;
        if ~isempty(strfind(gps_info.fn{gps_idx},'diff'))
          good_gps_idxs_type(end+1) = 0;
        elseif ~isempty(strfind(gps_info.fn{gps_idx},'TC'))
          good_gps_idxs_type(end+1) = 1;
        elseif ~isempty(strfind(gps_info.fn{gps_idx},'LC'))
          good_gps_idxs_type(end+1) = 2;
        elseif ~isempty(strfind(gps_info.fn{gps_idx},'Reveal'))
          good_gps_idxs_type(end+1) = 3;
        end
      end
    end
    
    fprintf('%%%% %s\n', radar_info.day_seg{radar_idx});
    if ~isempty(good_gps_idxs)
      [tmp min_idx] = min(good_gps_idxs_type);
      if strcmp(last_good_gps_fn,gps_info.fn{good_gps_idxs(min_idx)})
        continue;
      end
      last_good_gps_fn = gps_info.fn{good_gps_idxs(min_idx)};
      fprintf('file_idx = file_idx + 1;\n');
      fprintf('in_fns{file_idx} = fullfile(in_base_path,''%s'');\n', gps_info.fn{good_gps_idxs(min_idx)});
      fprintf('out_fns{file_idx} = ''gps_%s.mat'';\n', radar_info.day_seg{radar_idx});
      if good_gps_idxs_type(min_idx) ~= 3
        fprintf('file_type{file_idx} = ''Novatel'';\n');
        fprintf('params{file_idx} = struct(''time_reference'',''gps'');\n');
        fprintf('gps_source{file_idx} = ''Novatel-Final'';\n');
      else
        keyboard
      end
      fprintf('sync_flag{file_idx} = 0;\n');
    end
    fprintf('\n');
    
  end
  
  return;
  
  %% The following code should be inserted into make_gps_2009_antarctica_TO.m
  partial_gps_fns = get_filenames(gps_path,'gps_','_','.mat')
  gps.gps_time = [];
  gps.lat = [];
  gps.lon = [];
  gps.elev = [];
  gps.roll = [];
  gps.pitch = [];
  gps.heading = [];
  done = false;
  queued_gps_fns = {};
  for gps_idx = 1:length(partial_gps_fns)
    queued_gps_fns{end+1} = partial_gps_fns{gps_idx};
    new_gps = load(partial_gps_fns{gps_idx});
    gps.gps_time = [gps.gps_time new_gps.gps_time];
    gps.lat = [gps.lat new_gps.lat];
    gps.lon = [gps.lon new_gps.lon];
    gps.elev = [gps.elev new_gps.elev];
    gps.roll = [gps.roll new_gps.roll];
    gps.pitch = [gps.pitch new_gps.pitch];
    gps.heading = [gps.heading new_gps.heading];
    gps.gps_source = new_gps.gps_source;
    [tmp gps_fn_name gps_fn_ext] = fileparts(partial_gps_fns{gps_idx});
    if gps_idx == length(partial_gps_fns)
      done = true;...
    else
    [tmp next_gps_fn_name] = fileparts(partial_gps_fns{gps_idx+1});
    if ~strcmp(gps_fn_name(5:13),next_gps_fn_name(5:13))
      done = true;
    end
    end
    if done
      gps_fn = fullfile(gps_path, [gps_fn_name gps_fn_ext]);
      keyboard
      save(gps_fn,'-struct','gps');
      for delete_idx = 1:length(queued_gps_fns)
        delete(queued_gps_fns{delete_idx});
      end
      gps.gps_time = [];
      gps.lat = [];
      gps.lon = [];
      gps.elev = [];
      gps.roll = [];
      gps.pitch = [];
      gps.heading = [];
      done = false;
      queued_gps_fns = {};
    end
  end
end

if 1
  %% THIRD SECTION prints out the code that should be copied and pasted
  
  params = read_param_xls('/users/paden/scripts/branch/params-cr1/rds_param_2009_Antarctica_TO.xls',[],'post');
  for param_idx = 1:length(params)
    param = params(param_idx);
    
    if param.cmd.generic
      fprintf('=======================================================\n');
      fprintf('Fixing %s\n', param.day_seg);
      fprintf('=======================================================\n');
      
      if ~isfield(param.vectors,'tmp') || isempty(param.vectors.tmp)
        param.vectors.tmp = 0;
      end
      
      records_fn = ct_filename_support(param,'','records');
      records = load(records_fn);
      
      fprintf(' NEW: %s to %s\n', datestr(epoch_to_datenum(records.gps_time(1))), ...
        datestr(epoch_to_datenum(records.gps_time(end))));
      
      frames_fn = ct_filename_support(param,'','frames');
      
      old_frames_fn = fullfile('/cresis/projects/dev/csarp_support/frames/mcords/2009_Antarctica_TO/', ...
        sprintf('frames_%s.mat', param.day_seg));
      load(old_frames_fn);
      
      if max(frames.frame_idxs) > length(records.lat)
        keyboard;
      end
      along_track = geodetic_to_along_track(records.lat,records.lon,records.elev);
      frame_lengths = diff(along_track(frames.frame_idxs));
      fprintf('  Frames %.1f to %.1f km\n', min(frame_lengths)/1e3, max(frame_lengths)/1e3);
      
      frames_fn_dir = fileparts(frames_fn);
      if ~exist(frames_fn_dir,'dir')
        mkdir(frames_fn_dir);
      end
      system(sprintf('cp %s %s',old_frames_fn,frames_fn));
      
      data_out{1} = ct_filename_out(param,'','CSARP_standard');
      data_out{2} = ct_filename_out(param,'','CSARP_qlook');
      data_out{3} = ct_filename_out(param,'','CSARP_mvdr');
      data_out{4} = ct_filename_out(param,'','CSARP_layerData');
      
      data_dirs{1} = fullfile('/cresis/scratch2/mdce/mcords/2009_Antarctica_TO/CSARP_standard/',param.day_seg);
      data_dirs{2} = fullfile('/cresis/scratch2/mdce/mcords/2009_Antarctica_TO/CSARP_qlook/',param.day_seg);
      data_dirs{3} = fullfile('/cresis/scratch2/mdce/mcords/2009_Antarctica_TO/CSARP_mvdr/',param.day_seg);
      data_dirs{4} = fullfile('/cresis/scratch2/mdce/mcords/2009_Antarctica_TO/CSARP_layerData/',param.day_seg);
      
      for dir_idx = 1:length(data_dirs)
        if ~exist(data_dirs{dir_idx},'dir')
          continue
        end
        fprintf(' Copying %s\n', data_dirs{dir_idx});
        fns = get_filenames(data_dirs{dir_idx},sprintf('Data_%s',param.day_seg),'','.mat');
        if isempty(fns)
          continue
        end
        first = load(fns{1},'GPS_time');
        last = load(fns{end},'GPS_time');
        
        first.GPS_time = first.GPS_time + 86400*param.vectors.tmp;
        last.GPS_time = last.GPS_time + 86400*param.vectors.tmp;
        
        fprintf(' OLD: %s to %s\n', datestr(epoch_to_datenum(first.GPS_time(1))), ...
          datestr(epoch_to_datenum(last.GPS_time(end))));
        
        if first.GPS_time(1) < records.gps_time(1)
          keyboard
        end
        if last.GPS_time(end) > records.gps_time(end)
          keyboard
        end
        
        if ~exist(data_out{dir_idx},'dir')
          mkdir(data_out{dir_idx});
        end
        % Copy Data Files
        for fn_idx = 1:length(fns)
          fn = fns{fn_idx};
          [fn_dir fn_name fn_ext] = fileparts(fn);
          out_fn = fullfile(data_out{dir_idx},[fn_name fn_ext]);
          fprintf(' Copying %s to %s\n', fn, out_fn);
          copyfile(fn,out_fn);
          load(out_fn,'GPS_time');
          GPS_time = GPS_time + 86400*param.vectors.tmp;
          save(out_fn,'-append','GPS_time');
        end
      end
    end
    
  end
  
end



