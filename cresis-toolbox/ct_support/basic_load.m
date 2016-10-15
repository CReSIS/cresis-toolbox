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
% fn = filename of file containing cresis data
% param = struct controlling loading of data
%   .clk = clock (Hz), default one, used to interpret
%     counts in the header fields
%     e.g. snow5 during 2015 Greenland Polar6 used sampling frequency 1e9/8
%   .recs = 2 element vector for records to load [start_rec num_rec]
%     start_rec uses zero-indexing (negative start_recs read from the
%     end of the file and only work with single header loading)
%
% hdr = file header for each record (unless "data" output is not used
%   in which case only the first hdr is returned)
% data = Depends on param.records.en. When false, it is an optional output
%   array of radar data where dimensions are
%   1: fast-time/range-bin
%   2: slow-time/range-line/records
%
% Examples: See bottom of file
%
%   fn = 'D:\tmp\AWI_Snow\awi_snow\chan1\snow5_01_20150801_115752_00_0000.bin';
%   [hdr,data] = basic_load(fn,struct('clk',1e9/8));
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
if ~isfield(param,'recs');
  param.recs = [0 inf];
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

% ===============================================================
% Get first record position
% ===============================================================
hdr.finfo.syncs = get_first10_sync_mfile(fn,0,struct('sync','1ACFFC1D'));

% ===============================================================
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

% Get file version
fseek(fid, hdr.finfo.syncs(1) + 24, -1);
hdr.file_version = fread(fid, 1, 'uint16');

switch hdr.file_version
  case 7
    % snow5 radar (e.g. 2015 Greenland Polar6)
    load_func = @basic_load_support_fmcw5;
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

function [hdr,data] = basic_load_support_fmcw5(fid,param,hdr)
% [hdr,data] = basic_load_support_fmcw5(fid,param,hdr)
%
% See FMCW5 file format.docx in toolbox documents for file format

HEADER_SIZE = 48;
SAMPLE_SIZE = 2;

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
  hdr.start_idx = fread(fid, 1, 'uint16');
  hdr.Tadc = hdr.start_idx / param.clk - 10.8e-6;
  hdr.stop_idx = fread(fid, 1, 'uint16');
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
  hdr.wfs(1).t0 = hdr.start_idx / param.clk;
  
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
  
elseif nargout == 2
  % Read in all requested data and return
  
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
      hdr.start_idx(rline_out) = fread(fid, 1, 'uint16');
      hdr.stop_idx(rline_out) = fread(fid, 1, 'uint16');
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
      hdr.wfs(1).t0(rline_out) = hdr.start_idx(rline_out) / param.clk;
      
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
  hdr.Tadc = hdr.start_idx / param.clk - 10.8e-6;
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

end
