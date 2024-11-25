function [hdr,data] = basic_load_mcords5(fn,param)
% [hdr,data] = basic_load_mcords5(fn, param)
%
% This is the only function which loads raw data directly.
% This is for the MCORDS5 (2015 Gr LC130 RDS system, 150-600 MHz).
% Includes DDC capability.
%
% Loads a single mcords5 radar file. This is use for debugging and for
% records file generation.
% NOTE: 64-bit computer may be essential to load a 256 MB file since it will
% consume 512 MB of memory after loading.
%
% Inputs:
% =========================================================================
%
% fn: filename of MCoRDS-5 data
%
% param: struct controlling loading of data
%
%  .clk = clock (Hz), default 200e6 (1600 MHz sampling frequency divided by
%  8), used to interpret counts in the header fields.
%
%  .recs = 2 element vector for records to load [start_rec num_rec]
%   start_rec uses zero-indexing, default is [0 inf]
%
%  .first_byte = first byte to start reading at (default is zero0)
%
%  .start_index_time_offset = time offset between transmit waveform start
%  and the start index. The default is -1.0665e-05 implying that the first
%  sample collected is 10.665 us before the transmit event starts. This
%  value can be very different for each radar system (e.g. AWI system is
%  0.6 us).
%
%  .presum_mode: default is 1 which means there is an extra unused waveform
%  and the presum header values are 1 higher than what they should be
%  (8-channel DDS Ledford/Leuschen has this bug). Set to 0 if the presum
%  header values are correct (i.e. header values match the actual number of
%  presums.
%
% Outputs:
% =========================================================================
%
% hdr: file header for each record
% data: cell vector of single matrices of radar data where each entry
%   in the cell vector is a 3-D array for that waveform. Dimensions
%   1: fast-time/range-bin
%   2: slow-time/range-line/records
%
% Examples: See bottom of file
%
%   fn = 'mcords5_01_20150108_095420_02_0001.bin';
%   [hdr,data] = basic_load_mcords5(fn,param);
%
% Authors: John Paden

% ===================================================================
%% Check input arguments
% ===================================================================
if ~exist('param','var')
  param = struct();
end
if ~isfield(param,'clk')
  param.clk = 200e6;
end
if param.clk == 1600e6
  error('param.clk is now defined to be the actual header counter clock which is 200e6 instead of 1600e6.');
end
if ~isfield(param,'recs') || isempty(param.recs)
  param.recs = [0 inf];
end
if ~isfield(param,'first_byte') || isempty(param.first_byte)
  param.first_byte = 0;
end
if ~isfield(param,'start_index_time_offset') || isempty(param.start_index_time_offset)
  param.start_index_time_offset = -1.0665e-05;
end
if ~isfield(param,'presum_mode') || isempty(param.presum_mode)
  param.presum_mode = 1;
end
if isfield(param,'presum_bug_fixed')
  error('presum_bug_fixed no longer used. Change it to presum_mode. Change param.presum_bug_fixed = 1 to param.presum_mode = 0 and presum_bug_fixed = 0 to presum_mode = 1.');
end

% Reset/clear hdr struct
hdr = [];

% ===============================================================
%% Get first record position
% ===============================================================
hdr.sync_offsets = get_first10_sync_mfile(fn,param.first_byte,struct('sync','1ACFFC1D','num_sync',20));

% ===============================================================
%% Open file big-endian for reading
% ===============================================================
[fid,msg] = fopen(fn,'r','ieee-be');
if fid < 1
  fprintf('Could not open file %s\n', fn);
  error(msg);
end

%% Determine file version
fseek(fid, 8+hdr.sync_offsets(1), -1);
fver = fread(fid,1,'uint16'); % Must be 0x0197 if version 407
DDC = fread(fid,1,'uint16'); % Must be 2 or 3 if version 407
meas_type = fread(fid,1,'uint32'); % Must be 0 if version 407
fseek(fid, 16+hdr.sync_offsets(1), -1);
fver2 = fread(fid,1,'uint16'); % Must be 0x0197 if version 408
DDC2 = fread(fid,1,'uint16'); % Must be 1 if version 408
meas_type2 = fread(fid,1,'uint32'); % Must be 0 if version 408

second_8bytes = fread(fid,1,'uint64');
if fver == 407 && DDC == 2 || DDC == 3 && meas_type == 0
  param.file_version = 407;
  hdr.file_version = 407;
elseif fver2 == 407 && DDC2 == 1 && meas_type2 == 0
  % The 2nd, 4th, etc 8 bytes of the header are filled with garbage
  param.file_version = 408;
  hdr.file_version = 408;
else
  % Broke?
  %keyboard
  error('File header error');
end

% ===============================================================
%% Read in waveform information + record size
% ===============================================================
if param.file_version == 407
  HEADER_SIZE = 40;
  WF_HEADER_SIZE = 8;
  
  fseek(fid, 10+hdr.sync_offsets(1), -1);
  DDC = fread(fid,1,'uint16');
  
elseif param.file_version == 408
  HEADER_SIZE = 80;
  WF_HEADER_SIZE = 16;
  
  fseek(fid, 8+10+hdr.sync_offsets(1), -1);
  DDC = fread(fid,1,'uint16');
end

fseek(fid, HEADER_SIZE+1+hdr.sync_offsets(1), -1);
num_waveforms = fread(fid, 1, 'uint8') + 1;

% Seek to beginning of first waveform
fseek(fid, HEADER_SIZE+hdr.sync_offsets(1), -1);
% rec_size = record size in 16-bit words
hdr.rec_size = HEADER_SIZE/2;
% wf_offset: helps keep track of the sample offset into each waveform
wf_offset = WF_HEADER_SIZE/2;

for wf = 1:num_waveforms
  % Read in waveform header
  fseek(fid,2,0);
  % hdr.wfs(wf).presums: field in file contains the number of hardware
  % presums/stacking/averages minus one
  hdr.wfs(wf).presums = fread(fid, 1, 'uint8') + 1;
  if param.presum_mode == 1
    % For 8-channel Ledford/Leuschen DDS waveform generator, an extra bad
    % waveform is transmitted which is not used in the presum. The header
    % shows the number of transmitted waveforms including the bad waveform
    % so we need to subtract one from the presums.
    hdr.wfs(wf).presums = hdr.wfs(wf).presums - 1;
  end
  hdr.wfs(wf).bit_shifts = -fread(fid, 1, 'int8');
  hdr.wfs(wf).start_idx = fread(fid, 1, 'uint16');
  hdr.wfs(wf).t0 = hdr.wfs(wf).start_idx / param.clk + param.start_index_time_offset;
  
  if DDC == 1
    hdr.wfs(wf).num_sam = 8*fread(fid, 1, 'uint16');
    sample_size = 2;
  elseif DDC == 2
    hdr.wfs(wf).num_sam = 2*fread(fid, 1, 'uint16');
    sample_size = 4;
  elseif DDC == 3
    hdr.wfs(wf).num_sam = fread(fid, 1, 'uint16');
    hdr.wfs(wf).num_sam = floor(hdr.wfs(wf).num_sam/2)*2;
    sample_size = 4;
  else
    error('Invalid DDC field value');
  end
  
%   if fn(end-26:end-19) == '20150408' & fn(end-9) == '3' & wf<3
%     hdr.wfs(wf).num_sam = hdr.wfs(wf).num_sam + 2;
%   end
%   
%   if fn(end-26:end-19) == '20150408' & fn(end-9) == '1' & fn(end-28) =='2' & wf<3 % chan2 is ok
%     hdr.wfs(wf).num_sam = hdr.wfs(wf).num_sam + 2;
%   end
  if (sum(diff(hdr.sync_offsets) == 90552) ==length(hdr.sync_offsets) -1 ...
      | sum(diff(hdr.sync_offsets) == 90552) ==length(hdr.sync_offsets) - 2) & wf<3
    hdr.wfs(wf).num_sam = hdr.wfs(wf).num_sam + 2;
  end

  % Skip passed waveform data
  if param.file_version == 407
    fseek(fid, sample_size*hdr.wfs(wf).num_sam, 0);
  elseif param.file_version == 408
    fseek(fid, 8 + sample_size*hdr.wfs(wf).num_sam, 0);
  end
  
  % Update record size with new waveform
  hdr.rec_size = hdr.rec_size + WF_HEADER_SIZE/2 + sample_size/2*hdr.wfs(wf).num_sam;
  
  % Keep track of the sample offset into each waveform
  hdr.wfs(wf).offset = wf_offset;
  wf_offset = wf_offset + WF_HEADER_SIZE/2 + sample_size/2*hdr.wfs(wf).num_sam;
end

fseek(fid,0,1);
hdr.file_size = ftell(fid);

if hdr.rec_size ~= median(diff(hdr.sync_offsets))/2
  error('Estimated header size (%d) does not appear to match the header size found in the file (%d)', hdr.rec_size, median(diff(hdr.sync_offsets))/2);
  % keyboard;
  % For badly recorded files (e.g. DDS settings not matching ADC settings)
  % you can try uncommenting the following line:
  hdr.rec_size = median(diff(hdr.sync_offsets))/2;
end

if nargout < 2
  % Seek to first record
  fseek(fid, param.recs(1) * hdr.rec_size*2 + hdr.sync_offsets(1), -1);

  % Parse header data
  hdr.frame_sync = fread(fid,1,'uint32');
  hdr.epri = fread(fid,1,'uint32');
  if param.file_version == 408
    fseek(fid,8,0);
  end
  hdr.firmware_version = fread(fid,1,'uint16');
  hdr.DDC = fread(fid,1,'uint16');
  hdr.measurement_type = fread(fid,1,'uint32');
  if param.file_version == 408
    fseek(fid,8,0);
  end
  hdr.seconds = fread(fid,1,'uint32').'; % From NMEA string converted to DCB
  hdr.seconds = BCD_to_seconds(hdr.seconds);
  hdr.fractions = fread(fid,1,'uint32');
  if param.file_version == 408
    fseek(fid,8,-1);
  end
  hdr.counter = fread(fid,1,'uint64');
  hdr.utc_time_sod = hdr.seconds + hdr.fractions / param.clk;
  hdr.comp_time_sod = double(fread(fid,1,'uint64'));
  
  fclose(fid);
  
  return;
end

% ===============================================================
% Read in all file data and close file
% ===============================================================

% Seek to first record
fseek(fid, param.recs(1) * hdr.rec_size*2 + hdr.sync_offsets(1), -1);

% Read in all records
[raw_file_data,count] = fread(fid, [hdr.rec_size param.recs(2)], 'int16=>int16');
raw_file_data = raw_file_data(:,1:floor(count/hdr.rec_size));

% Close file
fclose(fid);

% ===============================================================
% Parse frame sync header
% ===============================================================

% Convert header data from signed integers to unsigned integers
hdr_data = double(raw_file_data(1:HEADER_SIZE/2,:));
hdr_data(hdr_data<0) = 2^16+hdr_data(hdr_data<0);

% Parse header data
hdr.frame_sync = 2^16*hdr_data(1:hdr.rec_size:end,:) ...
  + hdr_data(2:hdr.rec_size:end,:);

if any(hdr.frame_sync ~= hdr.frame_sync(1))
  fprintf('  Loss of frame sync, loading file the slow way\n');
  hdr.finfo = frame_sync_info(fn,struct('sync','1ACFFC1D','cont_mode',0));
  [fid,msg] = fopen(fn,'r','ieee-be');
  if param.recs(2) > hdr.finfo.num_rec-param.recs(1)
    param.recs(2) = hdr.finfo.num_rec-param.recs(1);
  end
  raw_file_data = zeros(hdr.rec_size, param.recs(2),'int16');
  for record = 1:size(raw_file_data,2)
    fseek(fid,hdr.finfo.syncs(param.recs(1)+record),-1);
    [tmp,count] = fread(fid,hdr.rec_size,'int16=>int16');
    if count ~= hdr.rec_size
      fprintf('%d requested to read, only %d read\n', hdr.rec_size, count);
      keyboard
    end
    raw_file_data(:,record) = tmp;
  end
  fclose(fid);
  
  hdr_data = double(raw_file_data(1:HEADER_SIZE/2,:));
  hdr_data(hdr_data<0) = 2^16+hdr_data(hdr_data<0);

  % Parse header data
  hdr.frame_sync = 2^16*hdr_data(1:hdr.rec_size:end,:) ...
    + hdr_data(2:hdr.rec_size:end,:);
end

% ===============================================================
% Parse remaining header
% ===============================================================
if param.file_version == 407
  HACK_OFFSET = 0;
elseif param.file_version == 408
  HACK_OFFSET = 4;
end

hdr.epri = 2^16*hdr_data(3,:) ...
  + hdr_data(4,:);

hdr.firmware_version = hdr_data(5+HACK_OFFSET,:);
hdr.DDC = hdr_data(6+HACK_OFFSET,:);
hdr.measurement_type = 2^16*hdr_data(7+HACK_OFFSET,:) ...
  + hdr_data(8+HACK_OFFSET,:);

% Convert seconds from NMEA ASCII string converted to Decimal Encoded
% Binary
%   32 bits: 0 0 H H M M S S
hdr.seconds = BCD_to_seconds(double(hdr_data(9+2*HACK_OFFSET,:))*2^16 + double(hdr_data(10+2*HACK_OFFSET,:)));

hdr.fractions = 2^16*hdr_data(11+2*HACK_OFFSET,:) ...
  + hdr_data(12+2*HACK_OFFSET,:);

hdr.counter = 2^48*hdr_data(13+3*HACK_OFFSET,:) ...
  + 2^32*hdr_data(14+3*HACK_OFFSET,:) ...
  + 2^16*hdr_data(15+3*HACK_OFFSET,:) ...
  + hdr_data(16+3*HACK_OFFSET,:);
  
hdr.utc_time_sod = hdr.seconds + hdr.fractions/param.clk;

hdr.comp_time_sod= (2^48*hdr_data(17+4*HACK_OFFSET,:) ...
  + 2^32*hdr_data(18+4*HACK_OFFSET,:) ...
  + 2^16*hdr_data(19+4*HACK_OFFSET,:) ...
  + hdr_data(20+4*HACK_OFFSET,:)) / 1000;

% ===============================================================
% Parse data into data matrix
% ===============================================================
param.wfs = 1:length(hdr.wfs);
for wf = 1:length(param.wfs)
  % Raw file data is 2-D and sorted in this order:
  %   1: fast-time, 2: slow-time
  % We want to sort in this order with each having its own dimension
  %   1: fast-time, 2: slow-time
  if hdr.DDC(1) == 1
    data{wf} = zeros(hdr.wfs(wf).num_sam,size(raw_file_data,2));
    data{wf}(1:8:end,:) = single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (1:8:hdr.wfs(wf).num_sam),:));
    data{wf}(2:8:end,:) = single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (5:8:hdr.wfs(wf).num_sam),:));
    data{wf}(3:8:end,:) = single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (2:8:hdr.wfs(wf).num_sam),:));
    data{wf}(4:8:end,:) = single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (6:8:hdr.wfs(wf).num_sam),:));
    data{wf}(5:8:end,:) = single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (3:8:hdr.wfs(wf).num_sam),:));
    data{wf}(6:8:end,:) = single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (7:8:hdr.wfs(wf).num_sam),:));
    data{wf}(7:8:end,:) = single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (4:8:hdr.wfs(wf).num_sam),:));
    data{wf}(8:8:end,:) = single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (8:8:hdr.wfs(wf).num_sam),:));

  elseif hdr.DDC(1) == 2
    data{wf} = single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (1:2:2*hdr.wfs(wf).num_sam),:)) ...
      + 1i*single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (2:2:2*hdr.wfs(wf).num_sam),:));
%     if 1
%       data{wf} = zeros(hdr.wfs(wf).num_sam,size(raw_file_data,2));
%       data{wf}(1:2:end,:) = single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (1:4:2*hdr.wfs(wf).num_sam),:));
%       data{wf}(2:2:end,:) = single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (3:4:2*hdr.wfs(wf).num_sam),:));
%       data{wf}(1:2:end,:) = data{wf}(1:2:end,:) + 1i*single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (2:4:2*hdr.wfs(wf).num_sam),:));
%       data{wf}(2:2:end,:) = data{wf}(2:2:end,:) + 1i*single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (4:4:2*hdr.wfs(wf).num_sam),:));
%       plot(lp(data{1}(:,1)))
%     else
%       data{wf} = single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (1:2*hdr.wfs(wf).num_sam),:));
%       data{wf} = reshape(data{wf},[4 hdr.wfs(wf).num_sam/2 size(data{wf},2)]);
%       data{wf} = reshape([data{wf}(1,:,:); data{wf}(2,:,:)] + 1i*[data{wf}(3,:,:); data{wf}(4,:,:)], ...
%         [hdr.wfs(wf).num_sam size(data{wf},3)]);
%     end

  elseif hdr.DDC(1) == 3
    data{wf} = single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (1:2:2*hdr.wfs(wf).num_sam),:)) ...
      + 1i*single(raw_file_data(HEADER_SIZE/2+hdr.wfs(wf).offset + (2:2:2*hdr.wfs(wf).num_sam),:));
  end
end

return;
