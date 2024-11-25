function [hdr,data] = basic_load(fn,param)
% [hdr,data] = basic_load(fn, param)
%
% This is the only function which loads raw data directly. This is for
% files which follow the convention:
% Bytes 0-3 UINT32 FRAME_SYNC 0x1ACFFC1D
% Byte 24-25 UINT16 FILE_VERSION https://wiki.cresis.ku.edu/cresis/Raw_File_Guide#Overview
%
% Supported file versions: 7 for snow5
%
% Loads a single radar file. This is primarily for debugging.
% NOTE: 64-bit computer may be essential to load a 256 MB file since it will
% consume 512 MB of memory after loading.
%
% If data is not specified as an output argument, only the first header is returned
%
% fn: filename of file containing cresis data
% param: struct controlling loading of data
%  .clk: clock (Hz), default 125e6, used to interpret counts in the
%    fractions field
%    e.g. snow5 during 2015 Greenland Polar6 used sampling frequency 1e9/8
%         snow8 during 2017 Greenland P3+ used sampling frequency 1e9/8
%         data_v11 during 2019 Greenland TO used sampling frequency 1e9/8
%  .fs: clock (Hz), default param.clk, used to convert start_idx to t0
%    and the ratio of param.fs/param.clk is used for interpretting
%    start_idx and stop_idx to determine the number of samples in a record
%    e.g. snow5 during 2015 Greenland Polar6 used sampling frequency 1e9/8
%         snow8 during 2017 Greenland P3+ used sampling frequency 1e9/4
%         data_v11 during 2019 Greenland TO used sampling frequency 1e9/8
%  .recs: 2 element vector for records to load [start_rec num_rec]
%    start_rec uses zero-indexing (negative start_recs read from the
%    end of the file and only work with single header loading)
%    Default is [0 inf] which loads the whole file.
%  .sync: 8-character string representing a hexidecimal number, the default
%    is '1ACFFC1D'. The only exception to this is snow8 uses 'BADA55E5'.
%    For this radar, the sync must be set to this to override the default.
%
% hdr: file header for each record (unless "data" output is not used
%   in which case only the first hdr is returned)
% data: Depends on param.records.en. When false, it is an optional output
%   array of radar data where dimensions are
%   1: fast-time/range-bin
%   2: slow-time/range-line/records
%
% Examples: See bottom of file
%
%   fn = 'D:\tmp\AWI_Snow\awi_snow\chan1\snow5_01_20150801_115752_00_0000.bin';
%   [hdr,data] = basic_load(fn,struct('clk',1e9/8));
%
%   fn = '/cresis/snfs1/projects/MiniSnow_Test_Data/2channelsUpdated/snow_00_20190320_172125_0003.bin';
%   [hdr,data] = basic_load(fn,struct('clk',125e6,'fs',125e6));
%
%   fn = '/cresis/snfs1/data/SnowRadar/2017_Greenland_P3/20170513/snow8_00_20170513_121436_0003.bin';
%   [hdr,data] = basic_load(fn,struct('clk',125e6,'fs',250e6,'sync','BADA55E5'));
%
% Authors: John Paden
%
% See also basic_load*.m
%
% Debug Code
% fseek(fid, -4, 0);
% fseek(fid, hdr.wfs(wf-1).num_sam*SAMPLE_SIZE*(1 + ~hdr.DDC_or_raw_select), 0)
% for idx=1:12
%   A = fread(fid,1,'uint32');
%   fprintf('%3d: %12d %s %3d %3d %3d %3d\n', (idx-1)*4, A, dec2hex(A,8), floor(A/2^24), mod(floor(A/2^16),2^8), mod(floor(A/2^8),2^8), mod(A,2^8));
% end
% fseek(fid, -4*12, 0);

% ===================================================================
% Check input arguments
% ===================================================================
if ~exist('param','var') || isempty(param)
  param = [];
end
if ~isfield(param,'clk');
  param.clk = 1;
end
if ~isfield(param,'fs');
  param.fs = param.clk;
end
if ~isfield(param,'recs');
  param.recs = [0 inf];
end
if ~isfield(param,'sync') || isempty(param.sync)
  param.sync = '1ACFFC1D'; % File type 0 uses BADA55E5
end

% Reset/clear hdr struct
hdr = [];

% ===================================================================
%% Data Format
% ===================================================================
% Frame sync does not need to be the first bytes in the file, but will
% not load in properly if the sequence occurs elsewhere. The frame
% sync marks the beginning of the record.
%
% RECORD:
% BYTES 0-3: 32-bit FRAME SYNC (0x1ACFFC1D)
% BYTES 24-25: 16-bit FILE VERSION
%
% The file version determine the rest of the format of the record.

% Get first record position
hdr.finfo.syncs = get_first10_sync_mfile(fn,0,struct('sync',param.sync));

% Open file big-endian for reading
% ===============================================================
[fid,msg] = fopen(fn,'r','ieee-be');
if fid < 1
  fprintf('Could not open file %s\n', fn);
  error(msg);
end

% Get file size
fseek(fid, 0, 1);
hdr.finfo.file_size = ftell(fid);

if isempty(hdr.finfo.syncs)
  warning('No frame syncs (hex sequence %s) found in this file. This may be a bad file or the input param.sync needs to be set correctly.', param.sync);
  data = [];
  return;
end

% Get file version
fseek(fid, hdr.finfo.syncs(1) + 24, -1);
hdr.file_version = fread(fid, 1, 'uint16');

switch hdr.file_version
  case 0
    % snow8 radar (e.g. 2017 Greenland P3)
    param.file_version = 8;
    load_func = @basic_load_support_fmcw0;
  case 7
    % AWI snow5 radar (e.g. 2015 Greenland Polar6)
    param.file_version = 7;
    load_func = @basic_load_support_fmcw7;
  case 11
    % data_v11 radar (e.g. 2019 Greenland TO kuband, 2019 Greenland TO kaband, 2019 Alaska SO)
    param.file_version = 11;
    load_func = @basic_load_support_fmcw0;
  otherwise
    fclose(fid);
    error('Unsupported file type %d', hdr.file_version);
end

hdr = load_func(fid,param,hdr);
if nargout == 2
  [hdr,data] = load_func(fid,param,hdr);
end

fclose(fid);

end

%% basic_load_support_fmcw0
% ===================================================================
function [hdr,data] = basic_load_support_fmcw0(fid,param,hdr)
% [hdr,data] = basic_load_support_fmcw0(fid,param,hdr)
%
% See FMCW5 file format.docx in toolbox documents for file format

% ===================================================================
% Data Format
% ===================================================================
% -- 64 bit block 0
% 32-bit header
% 32-bit EPRI
% -- 64 bit block 1
% 32-bit seconds in DCB (0 0 H H M M S S)
% 32-bit fraction: Counter at system clock, resets on 1 PPS
% -- 64 bit block 2
% 64-bit counter: Free running counter at system clock
% -- 64 bit block 3
% 16-bit file type: 0 or 11
% 8-bit zero/reserved
% 8-bit number of waveforms: 0 or 1 both mean 1 waveform
% 32-bit zero/reserved
% -- 64 bit block 4
% 8-bit zero/reserved
% 8-bit muliple fields:
%   LSB 1:0: Nyquist zone (b'00 means 0 to fs/2, b'01 means fs/2 to fs,
%            etc.)
%   3:2: Number of adc channels (b'00 means 1 ADC, b'01 means 2 ADCs, etc.)
%   4: Real data (0) or complex IQ data (1)
%   MSB: 7:5: zero/reserved
% 8-bit presums: one less than the actual number of presums
% 8-bit bit shift: int8, -1 means divide by 2, sign is negated by this
%   function during loading so the field will be 1 when returned
% 16-bit start: time gate start bin divided by 2 (start bin recorded)
% 16-bit stop: time gate stop bin divided by 2 (stop bin not recorded)
% -- 64 bit block 5
% file type 0 (param.file_version == 8):
%   64-bit Keysight waveform generator waveform ID
% file type 11 (param.file_version == 11):
%   64-bit zero/reserved
% DATA: depending on settings
%   REAL INT16:
%     ADC samples interleaved (see number of adc channels field)
%     2*(stop-start) is number of samples
%

%% Read in just waveform information + record size
% ===============================================================
if nargout < 2
  % Seek to first record
  fseek(fid, hdr.finfo.syncs(1), -1);
  hdr.frame_sync = fread(fid,1,'uint32');
  hdr.epri = fread(fid,1,'uint32');
  hdr.seconds = fread(fid,1,'uint32').'; % From NMEA string converted to DCB
  hdr.seconds = BCD_to_seconds(hdr.seconds);
  hdr.fraction = fread(fid,1,'uint32');
  hdr.utc_time_sod = hdr.seconds + hdr.fraction / param.clk*2;
  hdr.counter = fread(fid,1,'uint64');
  hdr.file_version = fread(fid,1,'uint16');
  fseek(fid,1,0);
  hdr.num_waveforms = fread(fid,1,'uint8');
  if hdr.num_waveforms == 0
    hdr.num_waveforms = 1;
  end
  fseek(fid,5,0);
  tmp = fread(fid,1,'uint8');
  hdr.complex_flag = bitand(bitshift(tmp,-4),1);
  hdr.num_adc = 1 + bitand(bitshift(tmp,-2),3);
  hdr.nyquist_zone = bitand(tmp,3);
  hdr.wfs(1).presums = fread(fid, 1, 'uint8')+1; % presums are 0-indexed (+1)
  hdr.bit_shifts = -fread(fid, 1, 'int8');
  hdr.start_idx = fread(fid, 1, 'uint16') * param.fs/param.clk;
  hdr.stop_idx = fread(fid, 1, 'uint16') * param.fs/param.clk;
  if hdr.file_version == 0
    %     hdr.wfs(1).waveform_ID = char(fread(fid,8,'uint8')).';
  end
  
  % Raw data
  hdr.wfs(1).num_sam = hdr.stop_idx - hdr.start_idx;
  
  % All waveforms have the same start
  hdr.wfs(1).t0 = hdr.start_idx / param.fs;
  
  % Jump through all waveforms
  for wf = 2:hdr.num_waveforms
    hdr.wfs(wf).num_sam = hdr.wfs(1).num_sam;
    hdr.wfs(wf).t0 = hdr.wfs(1).t0;
    fseek(fid, hdr.wfs(wf-1).num_sam*SAMPLE_SIZE + 34, 0);
    hdr.wfs(wf).presums = fread(fid,1,'uint8')+1; % presums are 0-indexed (+1)
    % hdr.wfs(wf).waveform_ID = hdr.wfs(1).waveform_ID;
    fseek(fid, HEADER_SIZE-35, 0);
  end
  
  return;
end

%% Read in all requested records
% ===============================================================

HEADER_SIZE = 48;
SAMPLE_SIZE = 2;

FRAME_SYNC = hex2dec(param.sync);

% Seek to first record
fseek(fid, hdr.finfo.syncs(1), -1);

rline = 0;
rline_out = 0;

% Preallocate data to make data loading faster
Nx = 1 + ceil(hdr.finfo.file_size/median(diff(hdr.finfo.syncs)));
for wf = 1:hdr.num_waveforms
  data{wf} = zeros([0 Nx 0],'single');
end

while ftell(fid) <= hdr.finfo.file_size-HEADER_SIZE && rline_out < param.recs(2)
  rline = rline + 1;
  frame_sync_test = fread(fid,1,'uint32');
  if frame_sync_test ~= FRAME_SYNC
    fprintf('Frame sync lost (line %d, byte %d). Searching for next frame sync.\n', rline_out, ftell(fid));
    %     keyboard
    found = false;
    while ~feof(fid)
      test = fread(fid,1,'uint32');
      if test == FRAME_SYNC
        found = true;
        break;
      end
    end
    if ~found
      break;
    end
  end
  if ftell(fid) > hdr.finfo.file_size-HEADER_SIZE
    break;
  end
  if rline > param.recs(1)
    rline_out = rline_out + 1;
    
    hdr.frame_sync(rline) = frame_sync_test;
    hdr.epri(rline) = fread(fid,1,'uint32');
    
    hdr.seconds(rline) = fread(fid,1,'uint32').'; % From NMEA string converted to DCB
    hdr.fraction(rline) = fread(fid,1,'uint32');
    
    hdr.counter(rline) = fread(fid,1,'uint64');
    
    hdr.file_version(rline) = fread(fid,1,'uint16');
    fseek(fid,1,0);
    hdr.num_waveforms(rline) = fread(fid,1,'uint8');
    if hdr.num_waveforms(rline) == 0
      hdr.num_waveforms(rline) = 1;
    end
    
    fseek(fid,5,0);
    tmp = fread(fid,1,'uint8');
    hdr.complex_flag(rline) = bitand(bitshift(tmp,-4),1);
    hdr.num_adc(rline) = 1 + bitand(bitshift(tmp,-2),3);
    hdr.nyquist_zone(rline) = bitand(tmp,3);
    hdr.wfs(1).presums(rline) = fread(fid, 1, 'uint8')+1; % presums are 0-indexed (+1)
    hdr.bit_shifts(rline) = -fread(fid, 1, 'int8');
    hdr.start_idx(rline) = fread(fid, 1, 'uint16') * param.fs/param.clk;
    hdr.stop_idx(rline) = fread(fid, 1, 'uint16') * param.fs/param.clk;
    
    if hdr.file_version == 0
      hdr.waveform_ID = char(fread(fid,8,'uint8')).';
    elseif hdr.file_version == 11
      fseek(fid,8,0);
    end
    
    % All waveforms have the same start
    hdr.wfs(1).t0(rline_out) = hdr.start_idx(rline_out) / param.clk;
    
    for wf = 1:hdr.num_waveforms(rline_out)
      if wf > 1
        hdr.wfs(wf).t0 = hdr.wfs(1).t0;
        fseek(fid, hdr.wfs(wf-1).num_sam*SAMPLE_SIZE + 34, 0);
        hdr.wfs(wf).presums = fread(fid,1,'uint8')+1; % presums are 0-indexed (+1)
        % hdr.wfs(wf).waveform_ID = hdr.wfs(1).waveform_ID;
        fseek(fid, HEADER_SIZE-35, 0);
      end
      
      % Determine the record size
      hdr.wfs(wf).num_sam(rline_out) = hdr.stop_idx(rline_out) - hdr.start_idx(rline_out);
      num_sam = hdr.wfs(wf).num_sam(rline_out); % Rename to protect the sanity of whoever reads this code
      
      if rline_out < 2 || num_sam ~= hdr.wfs(wf).num_sam(rline_out-1)
        % Preallocate records
        num_rec = floor((hdr.finfo.file_size - (ftell(fid)+num_sam*SAMPLE_SIZE*(1 + hdr.complex_flag(rline_out)))) / (HEADER_SIZE + SAMPLE_SIZE*(1 + hdr.complex_flag(rline_out))*num_sam));
        % Shorten if over allocated
        data{wf} = data{wf}(:,1:min(end,rline_out+num_rec));
        % Lengthen if under allocated
        data{wf}(1,rline_out+num_rec) = 0;
      end
      
      if ftell(fid) > hdr.finfo.file_size - hdr.num_adc(rline)*num_sam*SAMPLE_SIZE*(1 + hdr.complex_flag(rline_out))
        rline_out = rline_out - 1;
        param.recs(2) = rline_out; % Force reading loop to stop
        break;
      end
      
      if hdr.complex_flag(rline_out)
        % UNDEFINED FORMAT AT THIS POINT
      else
        % Read in real int16 data (multiple ADCs will have samples interleaved)
        tmp = fread(fid,num_sam*hdr.num_adc(rline),'int16=>single');
        for adc = 1:hdr.num_adc(rline)
          data{wf}(1:num_sam,rline,adc) = tmp(adc:hdr.num_adc(rline):end);
        end
      end
      
    end
  end
end

hdr.frame_sync = hdr.frame_sync(1:rline_out);
hdr.epri = hdr.epri(1:rline_out);
hdr.seconds = hdr.seconds(1:rline_out);
hdr.seconds = BCD_to_seconds(hdr.seconds);
hdr.fraction = hdr.fraction(1:rline_out);
hdr.utc_time_sod = hdr.seconds + double(hdr.fraction) / param.clk;
hdr.counter = hdr.counter(1:rline_out);
hdr.file_version = hdr.file_version(1:rline_out);
hdr.num_waveforms = hdr.num_waveforms(1:rline_out);
hdr.num_adc = hdr.num_adc(1:rline_out);
hdr.complex_flag = hdr.complex_flag(1:rline_out);
hdr.nyquist_zone = hdr.nyquist_zone(1:rline_out);
hdr.bit_shifts = hdr.bit_shifts(1:rline_out);
hdr.start_idx = hdr.start_idx(1:rline_out);
hdr.stop_idx = hdr.stop_idx(1:rline_out);

for wf=1:length(hdr.wfs)
  hdr.wfs(wf).t0 = hdr.wfs(wf).t0(1:rline_out);
  hdr.wfs(wf).presums = hdr.wfs(wf).presums(1:rline_out); % POSSIBLY   hdr.wfs(1).presums = fread(fid, 1, 'uint8')+1; % presums are 0-indexed (+1)
  hdr.wfs(wf).num_sam = hdr.wfs(wf).num_sam(1:rline_out);
  data{wf} = data{wf}(:,1:rline_out,:);
end


end

%% basic_load_support_fmcw7
% ===================================================================
function [hdr,data] = basic_load_support_fmcw7(fid,param,hdr)
% [hdr,data] = basic_load_support_fmcw7(fid,param,hdr)
%
% See FMCW5 file format.docx in toolbox documents for file format

HEADER_SIZE = 48;
SAMPLE_SIZE = 2;
FRAME_SYNC = hex2dec(param.sync);

if nargout == 1
  % Read in a single header and return
  fseek(fid, hdr.finfo.syncs(1)+4, -1);
  hdr.epri = fread(fid,1,'uint32');
  hdr.seconds = fread(fid,1,'uint32').'; % From NMEA string converted to DCB
  hdr.seconds = BCD_to_seconds(hdr.seconds);
  hdr.fraction = fread(fid,1,'uint32');
  hdr.utc_time_sod = hdr.seconds + hdr.fraction / param.clk;
  hdr.counter = fread(fid,1,'uint64');
  hdr.file_version = fread(fid,1,'uint16');
  hdr.wfs(1).switch_setting = fread(fid,1,'uint8');
  hdr.num_waveforms = fread(fid,1,'uint8');
  fseek(fid,6,0);
  hdr.wfs(1).presums = fread(fid, 1, 'uint8')+1; % presums are 0-indexed (+1)
  hdr.bit_shifts = -fread(fid, 1, 'int8');
  hdr.start_idx = fread(fid, 1, 'uint16') * param.fs/param.clk;
  hdr.stop_idx = fread(fid, 1, 'uint16') * param.fs/param.clk;
  hdr.DC_offset = fread(fid,1,'int16');
  hdr.NCO_freq = fread(fid,1,'uint16');
  hdr.nyquist_zone = fread(fid,1,'uint8');
  hdr.DDC_filter_select = fread(fid,1,'uint8');
  hdr.input_selection = fread(fid,1,'uint8');
  hdr.DDC_or_raw_select = fread(fid,1,'uint8');
  if hdr.DDC_or_raw_select == 1
    hdr.DDC_or_raw_select = 0;
    hdr.DDC_filter_select = -1;
  end
  
  % All waveforms currently have the same length
  if hdr.DDC_or_raw_select
    % Raw data
    hdr.wfs(1).num_sam = hdr.stop_idx - hdr.start_idx;
  else
    % DDC data
    hdr.wfs(1).num_sam = floor((hdr.stop_idx - hdr.start_idx) ...
      ./ 2.^(hdr.DDC_filter_select + 1));
  end
  
  % All waveforms have the same start
  hdr.wfs(1).t0 = hdr.start_idx / param.fs;
  
  % Jump through all waveforms
  for wf = 2:hdr.num_waveforms
    hdr.wfs(wf).num_sam = hdr.wfs(1).num_sam;
    hdr.wfs(wf).t0 = hdr.wfs(1).t0;
    fseek(fid, hdr.wfs(wf-1).num_sam*SAMPLE_SIZE*(1 + ~hdr.DDC_or_raw_select) + 26, 0);
    hdr.wfs(wf).switch_setting = fread(fid,1,'uint8');
    fseek(fid, 7, 0);
    hdr.wfs(wf).presums = fread(fid,1,'uint8')+1; % presums are 0-indexed (+1)
    fseek(fid, HEADER_SIZE-35, 0);
  end
  
  return;
end

%% Read in all requested records
% ===============================================================

% Seek to first record
fseek(fid, hdr.finfo.syncs(1), -1);

rline = 0;
rline_out = 0;
FRAME_SYNC = hex2dec('1ACFFC1D');
for wf = 1:hdr.num_waveforms
  data{wf} = zeros(0,0,'single'); % Data is pre-allocated in the loop
end
while ftell(fid) <= hdr.finfo.file_size-HEADER_SIZE && rline_out < param.recs(2)
  rline = rline + 1;
  frame_sync_test = fread(fid,1,'uint32');
  if frame_sync_test ~= FRAME_SYNC
    fprintf('Frame sync lost (line %d, byte %d). Searching for next frame sync.\n', rline_out, ftell(fid));
    %     keyboard
    found = false;
    while ~feof(fid)
      test = fread(fid,1,'uint32');
      if test == FRAME_SYNC
        found = true;
        break;
      end
    end
    if ~found
      break;
    end
  end
  if ftell(fid) > hdr.finfo.file_size-HEADER_SIZE
    break;
  end
  if rline > param.recs(1)
    rline_out = rline_out + 1;
    
    % Read in header
    hdr.finfo.syncs(rline_out) = ftell(fid)-4;
    hdr.epri(rline_out) = fread(fid,1,'uint32');
    hdr.seconds(rline_out) = fread(fid,1,'uint32').'; % From NMEA string converted to DCB
    hdr.fraction(rline_out) = fread(fid,1,'uint32');
    hdr.counter(rline_out) = fread(fid,1,'uint64');
    hdr.file_version(rline_out) = fread(fid,1,'uint16');
    hdr.wfs(1).switch_setting(rline_out) = fread(fid,1,'uint8');
    hdr.num_waveforms(rline_out) = fread(fid,1,'uint8');
    fseek(fid,6,0);
    hdr.wfs(1).presums(rline_out) = fread(fid, 1, 'uint8')+1; % presums are 0-indexed (+1)
    hdr.bit_shifts(rline_out) = -fread(fid, 1, 'int8');
    hdr.start_idx(rline_out) = fread(fid, 1, 'uint16') * param.fs/param.clk;
    hdr.stop_idx(rline_out) = fread(fid, 1, 'uint16') * param.fs/param.clk;
    hdr.DC_offset(rline_out) = fread(fid,1,'int16');
    hdr.NCO_freq(rline_out) = fread(fid,1,'uint16');
    hdr.nyquist_zone(rline_out) = fread(fid,1,'uint8');
    hdr.DDC_filter_select(rline_out) = fread(fid,1,'uint8');
    hdr.input_selection(rline_out) = fread(fid,1,'uint8');
    hdr.DDC_or_raw_select(rline_out) = fread(fid,1,'uint8');
    if hdr.DDC_or_raw_select(rline_out) == 1
      hdr.DDC_or_raw_select(rline_out) = 0;
      hdr.DDC_filter_select(rline_out) = -1;
    end
    
    % All waveforms have the same start
    hdr.wfs(1).t0(rline_out) = hdr.start_idx(rline_out) / param.fs;
    
    for wf = 1:hdr.num_waveforms(rline_out)
      if wf > 1
        hdr.wfs(wf).t0(rline_out) = hdr.wfs(1).t0(rline_out);
        fseek(fid, 26, 0);
        hdr.wfs(wf).switch_setting(rline_out) = fread(fid,1,'uint8');
        fseek(fid, 7, 0);
        hdr.wfs(wf).presums(rline_out) = fread(fid,1,'uint8')+1; % presums are 0-indexed (+1)
        fseek(fid, HEADER_SIZE-35, 0);
      end
      
      % Determine the record size
      if hdr.DDC_or_raw_select(rline_out)
        % Raw data
        hdr.wfs(wf).num_sam(rline_out) = hdr.stop_idx(rline_out) - hdr.start_idx(rline_out);
      else
        % DDC data
        hdr.wfs(wf).num_sam(rline_out) = floor((hdr.stop_idx(rline_out) - hdr.start_idx(rline_out)) ...
          ./ 2.^(hdr.DDC_filter_select(rline_out) + 1));
      end
      num_sam = hdr.wfs(wf).num_sam(rline_out); % Rename to protect the sanity of whoever reads this code
      
      if rline_out < 2 || num_sam ~= hdr.wfs(wf).num_sam(rline_out-1)
        % Preallocate records
        num_rec = floor((hdr.finfo.file_size - (ftell(fid)+num_sam*SAMPLE_SIZE*(1 + ~hdr.DDC_or_raw_select(rline_out)))) / (HEADER_SIZE + SAMPLE_SIZE*(1 + ~hdr.DDC_or_raw_select(rline_out))*num_sam));
        % Shorten if over allocated
        data{wf} = data{wf}(:,1:min(end,rline_out+num_rec));
        % Lengthen if under allocated
        data{wf}(1,rline_out+num_rec) = 0;
      end
      
      if ftell(fid) > hdr.finfo.file_size - num_sam*SAMPLE_SIZE*(1 + ~hdr.DDC_or_raw_select(rline_out))
        rline_out = rline_out - 1;
        param.recs(2) = rline_out; % Force reading loop to stop
        break;
      end
      
      if hdr.DDC_or_raw_select(rline_out)
        % Real data
        data{wf}(1:num_sam,rline_out) = fread(fid,num_sam,'int16=>single');
        data{wf}(:,rline_out) = data{wf}(reshape([2:2:num_sam;1:2:num_sam-1],[num_sam 1]),rline_out);
      else
        % Complex data
        tmp = fread(fid,2*num_sam,'int16=>single');
        data{wf}(1:num_sam,rline_out) = tmp(1:2:end) + 1i*tmp(2:2:end);
      end
    end
    
  end
  
end

hdr.finfo.syncs = hdr.finfo.syncs(1:rline_out);
hdr.epri = hdr.epri(1:rline_out);
hdr.seconds = double(hdr.seconds(1:rline_out));
hdr.seconds = BCD_to_seconds(hdr.seconds);
hdr.fraction = hdr.fraction(1:rline_out);
hdr.utc_time_sod = hdr.seconds + double(hdr.fraction) / param.clk;
hdr.counter = hdr.counter(1:rline_out);
hdr.file_version = hdr.file_version(1:rline_out);
hdr.num_waveforms = hdr.num_waveforms(1:rline_out);
hdr.bit_shifts = hdr.bit_shifts(1:rline_out);
hdr.start_idx = hdr.start_idx(1:rline_out);
hdr.stop_idx = hdr.stop_idx(1:rline_out);
hdr.DC_offset = hdr.DC_offset(1:rline_out);
hdr.NCO_freq = hdr.NCO_freq(1:rline_out);
hdr.nyquist_zone = hdr.nyquist_zone(1:rline_out);
hdr.DDC_filter_select = hdr.DDC_filter_select(1:rline_out);
hdr.input_selection = hdr.input_selection(1:rline_out);
hdr.DDC_or_raw_select = hdr.DDC_or_raw_select(1:rline_out);
for wf=1:length(hdr.wfs)
  hdr.wfs(wf).switch_setting = hdr.wfs(wf).switch_setting(1:rline_out);
  hdr.wfs(wf).t0 = hdr.wfs(wf).t0(1:rline_out);
  hdr.wfs(wf).presums = hdr.wfs(wf).presums(1:rline_out);
  hdr.wfs(wf).num_sam = hdr.wfs(wf).num_sam(1:rline_out);
  data{wf} = data{wf}(:,1:rline_out);
end

end
