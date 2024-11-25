function gps = read_gps_utig(fn, param)
% gps = read_gps_utig(fn, param)
%
% Read in UTIG ELSA raw file and extract GPS data from GPSnc1 packets.
% Ignores all other packets. Uses CX headers for radar_time (ct_time) and
% comp_time (ct_clk). ct_clk is not precise enough, but is absolute time
% and therefore monotonically increasing. ct_time is more precise than
% ct_clk, but it resets when the radar is reset so timing is ambiguous.
%
% Example:
%
%   fn = '/data/UTIG/orig/xped/CXA1/acqn/ELSA/F13/serial0_20230116-200145-0001.dat';
%   gps = read_gps_utig(fn);
%   gps_plot(gps);
%   datestr(epoch_to_datenum(gps.gps_time(1)));
%   gps.utc_time = gps.gps_time - utc_leap_seconds(gps.gps_time(1))
% 
% Author: John Paden
%
% See also read_gps_*.m, gps_plot.m, gps_create.m

% ===============================================================
%% Open file little-endian for reading
% ===============================================================
[fid,msg] = fopen(fn,'r','ieee-le');
if fid < 1
  fprintf('Could not open file %s\n', fn);
  error(msg);
end
fseek(fid,0,1);
file_length = ftell(fid);
Nx_max = floor(file_length/179);
fseek(fid,0,-1);

gps = [];
gps.gps_time = zeros(1,Nx_max);
gps.lat = zeros(1,Nx_max);
gps.lon = zeros(1,Nx_max);
gps.elev = zeros(1,Nx_max);
gps.roll = zeros(1,Nx_max);
gps.pitch = zeros(1,Nx_max);
gps.heading = zeros(1,Nx_max);
gps.radar_time = zeros(1,Nx_max);
gps.comp_time = zeros(1,Nx_max);

state = 0;
locked = false;
gps_rec = 0;
while ~feof(fid)
  test_byte = fread(fid,1,'char');
  switch (state)
    case 0
      if test_byte == 'P'
        state = state+1;
      elseif locked
        warning('Lost "PACKET" lock at byte %d.', ftell(fid));
        locked = false;
      end
    case 1
      if test_byte == 'A'
        state = state+1;
      else
        state = 0;
      end
    case 2
      if test_byte == 'C'
        state = state+1;
      else
        state = 0;
      end
    case 3
      if test_byte == 'K'
        state = state+1;
      else
        state = 0;
      end
    case 4
      if test_byte == 'E'
        state = state+1;
      else
        state = 0;
      end
    case 5
      if test_byte == 'T'
        % keyboard
        locked = true;
        
        fseek(fid,2,0);
        %ftell(fid)
        project = char(fread(fid,8,'char').');
        set = char(fread(fid,8,'char').');
        transect = char(fread(fid,8,'char').');
        stream_name = char(fread(fid,8,'char').');
        sequence_number = fread(fid,1,'uint32',0,'ieee-le');
        rec_length = fread(fid,1,'uint32',0,'ieee-le')+48; % Record length in bytes including the 68 byte CX header
        % CT[48:67]
        ct_clk_packed = fread(fid,1,'uint32',0,'ieee-le');
        year = 1000*mod(floor(ct_clk_packed/2^4),2^4) + 100*mod(ct_clk_packed,2^4) ...
          + 10*mod(floor(ct_clk_packed/2^12),2^4) + mod(floor(ct_clk_packed/2^8),2^4);
        month = 10*mod(floor(ct_clk_packed/2^20),2^4) + mod(floor(ct_clk_packed/2^16),2^4);
        day= 10*mod(floor(ct_clk_packed/2^28),2^4) + mod(floor(ct_clk_packed/2^24),2^4);
        ct_clk_packed = fread(fid,1,'uint32',0,'ieee-le');
        hour = 10*mod(floor(ct_clk_packed/2^4),2^4) + mod(ct_clk_packed,2^4);
        min = 10*mod(floor(ct_clk_packed/2^12),2^4) + mod(floor(ct_clk_packed/2^8),2^4);
        sec = 10*mod(floor(ct_clk_packed/2^20),2^4) + mod(floor(ct_clk_packed/2^16),2^4);
        frac = 10*mod(floor(ct_clk_packed/2^28),2^4) + mod(floor(ct_clk_packed/2^24),2^4);
        ct_clk = datenum([year,month,day,hour,min,sec]);
        ct_time = fread(fid,1,'uint32',0,'ieee-le');
        fseek(fid,8,0);
        
        if strcmp(stream_name(1:6),'GPSnc1')
          gps_rec = gps_rec + 1;
          
          gps_time = fread(fid,1,'int64',0,'ieee-be');
          gps_subsecs = fread(fid,1,'uint64',0,'ieee-be');
          
          % Convert from NI time to ANSI C time
          gps.gps_time(gps_rec) = datenum([1904 0 0 0 0 gps_time+gps_subsecs/2^64]);
          
          pps_time = fread(fid,1,'int64',0,'ieee-be');
          pps_subsecs = fread(fid,1,'uint64',0,'ieee-be');
          query_time = fread(fid,1,'int64',0,'ieee-be');
          query_subsecs = fread(fid,1,'uint64',0,'ieee-be');
          
          time_source = fread(fid,1,'uint8',0,'ieee-be');
          
          pps_ct = fread(fid,1,'uint32',0,'ieee-be');
          
          query_ct = fread(fid,1,'uint32',0,'ieee-be');
          
          ct_flags = fread(fid,1,'uint8',0,'ieee-be');
          
          EW_vel = fread(fid,1,'float',0,'ieee-be');
          NS_vel = fread(fid,1,'float',0,'ieee-be');
          vert_vel = fread(fid,1,'float',0,'ieee-be');
          
          gps.lat(gps_rec) = fread(fid,1,'float',0,'ieee-be'); % lat_ang
          gps.lon(gps_rec) = fread(fid,1,'float',0,'ieee-be'); % lon_ang
          gps.elev(gps_rec) = fread(fid,1,'float',0,'ieee-be'); % vert_cor
          
          gps.radar_time(gps_rec) = ct_time;
          gps.comp_time(gps_rec) = ct_clk;
          
          gps_state = fread(fid,1,'uint8',0,'ieee-be');
          state = fread(fid,1,'uint8',0,'ieee-be');
          self_survey = fread(fid,1,'uint8',0,'ieee-be');
          
          time_offset = fread(fid,1,'double',0,'ieee-be');
          time_corr = fread(fid,1,'double',0,'ieee-be');
          
          utc_offset = fread(fid,1,'uint32',0,'ieee-be');
          nsv = fread(fid,1,'uint8',0,'ieee-be');
          sv_time = fread(fid,1,'uint32',0,'ieee-be');
          sw_state = fread(fid,1,'uint8',0,'ieee-be');
        else
          fseek(fid,rec_length-68,0);
        end
      end
      state = 0;
  end
end

fclose(fid);

gps.gps_time = datenum_to_epoch(gps.gps_time(1:gps_rec));
gps.lat = gps.lat(1:gps_rec);
gps.lon = gps.lon(1:gps_rec);
gps.elev = gps.elev(1:gps_rec);
gps.roll = gps.roll(1:gps_rec);
gps.pitch = gps.pitch(1:gps_rec);
gps.heading = gps.heading(1:gps_rec);

gps.radar_time = gps.radar_time(1:gps_rec);
gps.comp_time = datenum_to_epoch(gps.comp_time(1:gps_rec));
