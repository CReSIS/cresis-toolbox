function opsBulkInsert(settings)
%
% opsBulkInsert(settings)
%
% Loads flight paths in bulk from records files into OPS.
%
% Author: Kyle W. Purdon, John Paden
%
% See also: runOpsBulkInsert

%% Setup defaults, perform input checks

opsCmd;

% Convenience variable naming
params = settings.params;
radar_name = params(1).radar_name;
season_name = params(1).season_name;
sys = ct_output_dir(params(1).radar_name);

% Set settings.path_spacing
if ~isfield(settings,'path_spacing') || isempty(settings.path_spacing)
  if any(strcmpi(sys,{'kuband','snow'}))
    settings.path_spacing = 5;
  else
    settings.path_spacing = 15;
  end
end

% Set settings.season_group
if ~isfield(settings,'season_group') || isempty(settings.season_group)
  % settings.season_group = 'cresis_private';
  settings.season_group = 'cresis_public';
end

% Checking to see if any selected segments contain "do not process" in
% cmd.notes
for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  
  if ~isempty(regexpi(param.cmd.notes,'do not process'))
    warning('You have enabled %s, a segment with ''do not process'' in the cmd.notes, dbcont to continue', param.day_seg);
    keyboard
  end
end

%% User Confirmation

confirm_params = {sprintf('SERVER: \t %s',gOps.serverUrl),'',sprintf('SEASON NAME: \t %s',season_name),'',...
  sprintf('RADAR NAME: \t %s',radar_name),'',...
  sprintf('PATH SPACING: \t %0.2f meters',settings.path_spacing),''};

confirm_button = questdlg(confirm_params,'Confirm Settings','YES:LOAD','NO:QUIT','NO:QUIT');

switch confirm_button
  case 'NO:QUIT'
    error('PROCESS STOPPED BY USER.');
end

%% Path Insert Loop

failed_segments = {}; % STORE SEGMENTS THAT FAIL

% START LOGGING
log_fn = fullfile(settings.tmp_path,mfilename,sys,strcat(season_name,'_',datestr(now,'yyyymmdd_HHMMSS'),'.txt'));
log_fn_dir = fileparts(log_fn);
if ~exist(log_fn_dir,'dir')
  mkdir(log_fn_dir);
end
diary(log_fn);
fprintf('Logs will be saved to: %s\n',log_fn);

% FOR EACH SEGMENT PROCESS THE INPUT AND PUSH THE DATA TO THE SERVER
for param_idx = 1:length(params)
  
  try
    
    %% Path Insert: Setup
    % CONFIRM THAT GENERIC IS FLAGGED
    param = params(param_idx);
    if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
      continue;
    end
    
    fprintf('Loading path for segment %s ... ',param.day_seg);
    
    start = tic; % SET UP TIMING
    
    if ~any(strcmp(param.post.ops.location,{'arctic','antarctic'}))
      error('param.post.ops.location must be set to ''arctic'' or ''antarctic''. Current value is %s.', param.post.ops.location);
    end
    fprintf('  Loading into location %s\n', param.post.ops.location);
    
    % Load records and frames files
    frames = frames_load(param);
    records = records_load(param);
    
    % Apply reference lever arm to records trajectory
    trajectory_param = struct('gps_source',records.gps_source, ...
      'season_name',param.season_name,'radar_name',param.radar_name,'rx_path', 0, ...
      'tx_weights', [], 'lever_arm_fh', param.radar.lever_arm_fh);
    records = trajectory_with_leverarm(records,trajectory_param);
    
    % Get the start time of each frame
    frm_start_gps_time = zeros(1,length(frames.frame_idxs));
    for frmIdx = 1:length(frames.frame_idxs)
      if frmIdx == length(frames.frame_idxs)
        frm_start_gps_time(1,frmIdx) = records.gps_time(frames.frame_idxs(frmIdx)); % ADD THE END SEGMENT
      else
        frm_start_gps_time(1,frmIdx) = records.gps_time(frames.frame_idxs(frmIdx)); % ADD 1:N-1 SEGMENTS
      end
    end
    
    %% Path Insert: Interpolate
    
    % INTERPOLATE RECORDS GPS TIME ONTO THE GIVEN SPACING (DEFAULT = 15m)
    along_track = geodetic_to_along_track(records.lat,records.lon,records.elev);
    new_along_track = 0:settings.path_spacing:along_track(end);
    positive_idxs = [1, 1+find(diff(along_track) > 0)];
    out_gps_time = interp1(along_track(positive_idxs),records.gps_time(positive_idxs),new_along_track,'pchip');
    
    % INTERPOLATE RECORDS VALUES ONTO NEW GPS TIME
    outLon = gps_interp1(records.gps_time,records.lon/180*pi,out_gps_time,'pchip')*180/pi;
    outLat = interp1(records.gps_time,records.lat,out_gps_time,'pchip');
    out_elev = interp1(records.gps_time,records.elev,out_gps_time,'pchip');
    out_roll = interp1(records.gps_time,records.roll,out_gps_time,'pchip');
    out_pitch = interp1(records.gps_time,records.pitch,out_gps_time,'pchip');
    out_heading = gps_interp1(records.gps_time,records.heading,out_gps_time,'pchip');
    
    %% Path Insert: ERROR CHECK OUTPUT DATA
    if any(find(out_heading>(pi*2))) || any(find(out_heading<(-pi*2)))
      warning('OUTPUT HEADING OUT OF BOUND 2pi <> -2pi');
      keyboard;
    end
    if any(find(out_pitch>(pi*2))) || any(find(out_pitch<(-pi*2)))
      warning('OUTPUT PITCH OUT OF BOUND 2pi <> -2pi');
      keyboard;
    end
    if any(find(out_roll>(pi*2))) || any(find(out_roll<(-pi*2)))
      warning('OUTPUT ROLL OUT OF BOUND 2pi <> -2pi');
      keyboard;
    end
    if any(find(outLon>180)) || any(find(outLon<-180))
      warning('OUTPUT LONGITUDE OUT OF BOUND 180 <> -180');
      keyboard;
    end
    if any(find(outLat>90)) || any(find(outLat<-90))
      warning('OUTPUT LATITUDE OUT OF BOUND 90 <> -90');
      keyboard;
    end
    
    %% Path Insert: opsCreatePath
    out_data.geometry.coordinates = [outLon' outLat'];
    out_data.properties.location = param.post.ops.location;
    out_data.properties.season = season_name;
    out_data.properties.season_group = settings.season_group;
    out_data.properties.radar = radar_name;
    out_data.properties.segment = param.day_seg;
    out_data.properties.gps_time = out_gps_time;
    out_data.properties.elev = out_elev;
    out_data.properties.roll = out_roll;
    out_data.properties.pitch = out_pitch;
    out_data.properties.heading = out_heading;
    out_data.properties.frame_count = length(frames.frame_idxs);
    out_data.properties.frame_start_gps_time = frm_start_gps_time;
    
    mstop = toc(start); % RECORD MATLAB COMPUTATION TIME
    
    [status,message] = opsCreatePath(sys,out_data);
    
    pstop = toc(start)-mstop; % RECORD PYTHON COMPUTATION TIME
    
    if status ~= 1
      fprintf('\n');
      warning(message);
      failed_segments{end+1} = param.day_seg; % STORE THE SEGMENT IF THE SERVER PUSH FAILED
    end
    
    %% Path Insert: Report timing/status
    fprintf('\n\t-> Time: Matlab %2.2fs Python %2.2fs\n',mstop,pstop);
    fprintf('\t-> Status: %s\n',message);
    
  catch ME
    
    ME.getReport()
    failed_segments{end+1} = param.day_seg; % STORE THE SEGMENT IF ANYTHING FAILED
    
  end
end

%% REPORT FAILED SEGMENTS
if ~isempty(failed_segments)
  fprintf('\n\nThere were issues loading paths for segments:\n');
  for failIdx = 1:length(failed_segments)
    fprintf('\t%s\n',failed_segments{failIdx});
  end
end

diary OFF % STOP LOGGING
