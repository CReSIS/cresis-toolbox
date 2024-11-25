function gps = read_gps_novatelraw(fn, param)
% gps = read_gps_novatelraw(fn, param)
%
% Parses Novatel binary commands BESTPOSB,TIMEB,INSATTB
% See Novatel OEM6 or OEM7 command manuals.
%
% GPS+INS:
% LOG USB1 BESTPOSB ONTIME 0.2
% LOG USB1 TIMEB ONTIME 0.2
% LOG USB1 INSATTB ONTIME 0.2
%
% GPS ONLY:
% LOG USB1 BESTPOSB ONTIME 0.05
% LOG USB1 TIMEB ONTIME 0.05
%
% Example:
%
%   fn = '/scratch/metadata/2022_Antarctica_BaslerMKB/20230110/GPS_Novatel_raw_aq-field22_20230110_010949.gps'
%   gps = read_gps_novatelraw(fn);
%   gps_plot(gps);
%   datestr(epoch_to_datenum(gps.gps_time(1)));
%   gps.utc_time = gps.gps_time - utc_leap_seconds(gps.gps_time(1))
% 
% Author: John Paden
%
% See also read_gps_*.m, gps_plot.m, gps_create.m

if ~exist('param','var')
  param = [];
end

if ~isfield(param,'first_byte')
  param.first_byte = 0;
end

%% Read in file

% Open file
[fid,msg] = fopen(fn,'rb');
if fid < 1
  fprintf('Could not open file %s\n', fn);
  error(msg);
end
fseek(fid,param.first_byte,-1);

% Read entire file (may require at lot of RAM!)
A = fread(fid,inf,'uint8=>uint8');

% Close file
fclose(fid);

%% Find Frame Syncs in Novatel Data

frame_sync_byte1 = 170; % '0xAA'
frame_sync_byte2 = 68; % '0x44'
frame_sync_byte3 = 18; % '0x12'
frame_sync_byte3_or = 19; % '0x13'

frame_start_mask = A(1:end-2)==frame_sync_byte1 & A(2:end-1)==frame_sync_byte2 & (A(3:end)==frame_sync_byte3 | A(3:end)==frame_sync_byte3_or);

frame_start_idxs = find(frame_start_mask);

%% Parse each frame

% Preallocate output arrays: Assume the longest possible length for outputs
% (only BESTPOS and TIME messages present)
gps.gps_time = zeros(1,floor(length(frame_start_idxs)/2));
gps.lat = zeros(1,floor(length(frame_start_idxs)/2));
gps.lon = zeros(1,floor(length(frame_start_idxs)/2));
gps.elev = zeros(1,floor(length(frame_start_idxs)/2));
gps.roll = zeros(1,floor(length(frame_start_idxs)/2));
gps.pitch = zeros(1,floor(length(frame_start_idxs)/2));
gps.heading = zeros(1,floor(length(frame_start_idxs)/2));

if isempty(frame_start_idxs)
  return;
end

next_start_idx = frame_start_idxs(1);
out_idx = 0;
have_time = false;
have_ins = false;
roll = 0;
pitch = 0;
heading = 0;
message_ID_list = [];
try
  for frame = 1:length(frame_start_idxs)
    %fprintf('FRAME %10d of %10d\n', frame, length(frame_start_idxs));

    % Check to see if this 3-byte frame sync occurs where we think it should
    % based on the last frame sync and the length of that record. If it does
    % not, then ignore this 3-byte frame sync since it may have randomly
    % occurred.
    if frame_start_idxs(frame) < next_start_idx
      fprintf('Unexpected frame position at byte offset %d. Skipping 3-byte frame sync.\n', frame_start_idxs(frame));
      if frame == length(frame_start_idxs)
        break;
      end
      next_start_idx = frame_start_idxs(frame+1);
      continue;
    end
    if A(frame_start_idxs(frame)+2) == 18
      message_type = 'GPS';
      header_length = double(A(frame_start_idxs(frame)+3));
      message_ID = typecast(swapbytes(A(frame_start_idxs(frame)+(4:5))),'uint16');
      gps_week = typecast(swapbytes(A(frame_start_idxs(frame)+(14:15))),'uint16');
      gps_msec = typecast(swapbytes(A(frame_start_idxs(frame)+(16:19))),'uint32');
      message_length = double(typecast(swapbytes(A(frame_start_idxs(frame)+(8:9))),'uint16'));
    else % if A(frame_start_idxs(frame)+2) == 19
      message_type = 'INS';
      header_length = 12;
      message_length = double(A(frame_start_idxs(frame)+3));
      message_ID = typecast(swapbytes(A(frame_start_idxs(frame)+(4:5))),'uint16');
      gps_week = typecast(swapbytes(A(frame_start_idxs(frame)+(6:7))),'uint16');
      gps_msec = typecast(swapbytes(A(frame_start_idxs(frame)+(8:11))),'uint32');
    end

    % Debug print out
    %fprintf('%s ID: %4d Length: %4d %5d Time: %4d %6.1f\n', message_type, message_ID, header_length, message_length, gps_week, gps_msec/1000);
    % Debug message_ID_list:
    %message_ID_list(end+1) = message_ID;

    next_start_idx = frame_start_idxs(frame)+header_length+message_length+4;
    %fprintf('%g %g %g\n', next_start_idx, frame_start_idxs(frame+1),frame_start_idxs(frame+1)-next_start_idx);

    if message_ID==101
      % TIME MESSAGE
      % Contain UTC time
      %fprintf('%4d %4d %5d %6.1f\n', header_length, message_ID, gps_week, gps_msec/1000);
      year = typecast(swapbytes(A(frame_start_idxs(frame)+header_length+(28:31))),'uint32');
      month = A(frame_start_idxs(frame)+header_length+32);
      day = A(frame_start_idxs(frame)+header_length+33);
      hour = A(frame_start_idxs(frame)+header_length+34);
      minute = A(frame_start_idxs(frame)+header_length+35);
      sec = double(typecast(swapbytes(A(frame_start_idxs(frame)+header_length+(36:39))),'uint32'))/1000;
      %fprintf('%04d_%02d_%02d %02d:%02d:%04.1f\n', year, month, day, hour, minute, sec);
      have_time = true;

    elseif message_ID==42
      % BESTPOS MESSAGE
      %fprintf('%4d %4d %5d %6.1f\n', header_length, message_ID, gps_week, gps_msec/1000);
      if ~have_time
        fprintf('BESTPOS without preceding TIME. Skipping frame.\n', frame_start_idxs(frame));
        continue;
      end
      lat = typecast(swapbytes(A(frame_start_idxs(frame)+header_length+(8:15))),'double');
      lon = typecast(swapbytes(A(frame_start_idxs(frame)+header_length+(16:23))),'double');
      elev = typecast(swapbytes(A(frame_start_idxs(frame)+header_length+(24:31))),'double');
      %fprintf('%8.4f %8.4f %6.1f\n', lat, lon, elev);
      out_idx = out_idx + 1;
      % NOTE: gps.gps_time is actually UTC time from the TIME field. Will add
      % leap seconds in to convert UTC to GPS time once finished loading.
      gps.gps_time(out_idx) = datenum([double([year,month,day,hour,minute]),sec]);
      gps.lat(out_idx) = lat;
      gps.lon(out_idx) = lon;
      gps.elev(out_idx) = elev;
      gps.roll(out_idx) = roll;
      gps.pitch(out_idx) = pitch;
      gps.heading(out_idx) = heading;
      have_time = false;
      have_ins = false;

    elseif message_ID==263
      % INSATT MESSAGE
      %fprintf('%4d %4d %5d %6.1f\n', header_length, message_ID, gps_week, gps_msec/1000);
      roll = typecast(swapbytes(A(frame_start_idxs(frame)+header_length+(12:19))),'double') / 180*pi;
      pitch = typecast(swapbytes(A(frame_start_idxs(frame)+header_length+(20:27))),'double') / 180*pi;
      heading = typecast(swapbytes(A(frame_start_idxs(frame)+header_length+(28:35))),'double') / 180*pi;
      %fprintf('%8.4f %8.4f %8.4f\n', roll, pitch, heading);
      have_ins = true;

      %   elseif message_ID==1465
      %     lat = typecast(swapbytes(A(frame_start_idxs(frame)+header_length+(8:15))),'double');
      %     lon = typecast(swapbytes(A(frame_start_idxs(frame)+header_length+(16:23))),'double');
      %     elev = typecast(swapbytes(A(frame_start_idxs(frame)+header_length+(24:31))),'double');
      %     ext_sol_stat = typecast(swapbytes(A(frame_start_idxs(frame)+header_length+(120:123))),'uint32');
      %     time_since_update = typecast(swapbytes(A(frame_start_idxs(frame)+header_length+(124:125))),'uint16');
      %     CRC = typecast(swapbytes(A(frame_start_idxs(frame)+header_length+(126:129))),'uint32');
    end
  end
catch ME
  warning(ME.getReport);
end

%% Prepare Output

% Only keep the records that we filled:
gps.gps_time = datenum_to_epoch(gps.gps_time(1:out_idx)); % Convert from Matlab datenum to ANSI-C standard time of seconds since Jan 1, 1970
if ~isempty(gps.gps_time)
  gps.gps_time = gps.gps_time + utc_leap_seconds(gps.gps_time(1)); % Convert gps.gps_time from UTC to GPS time
end
gps.lat = gps.lat(1:out_idx);
gps.lon = gps.lon(1:out_idx);
gps.elev = gps.elev(1:out_idx);
gps.roll = gps.roll(1:out_idx);
gps.pitch = gps.pitch(1:out_idx);
gps.heading = gps.heading(1:out_idx);
