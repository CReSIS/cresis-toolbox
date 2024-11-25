function [hdr,data] = basic_load_utig(fn,param)
% [hdr,data] = basic_load_utig(fn, param)
%
% Loads RADnh5 records from raw MARFA file. Can load files with or without
% CX headers based on optional param argument.
%
% Only supports nchan=2 channels and each channel has a low gain
% data{channel_offset+1} and then a high gain waveform
% data{channel_offset+2} where channel_offset is 0 and 2.
%
% Inputs:
%
% fn: string containing a filename to load
%
% param: struct controlling the loading with these fields:
%
%  .bxds_en: logical scaler, default false. If true, then file should be
%  RADnh5 format with no CX headers (i.e. post breakout/deelsa).
%
%  .recs: 2 element nonnegative integer vector. default is [0 inf]. First
%  number gives the offset to the first record to load. Second element
%  gives the number of records to load. If the number of records to load is
%  greater than the number of records left in the file, then all the
%  records to the end of the file are loaded. Setting this value to inf is
%  a simple way to load the rest of the records.
% 
% Outputs:
% 
% hdr: cell array of headers associated with each data image loaded
%
% data: cell array of data images where the length is equal to the number
% of channels loaded. data images are Nt by Nx matrices where Nt is the
% number of rows/fast-time samples and Nx is the number of
% columns/slow-time or along-track samples.  data matrix is ordered
% according to the channel offset indicated in the file.
%
% Examples:
%   fn = 'C:\Users\dangermo\OneDrive - University of Kansas\Desktop\UTIG\X53b\RADnh5\bxds.10000';
%   [hdr,data] = basic_load_utig(fn,struct('bxds_en',true));
%
%   fn = '/data/UTIG/orig/xped/CXA1/acqn/MARFA/F13/radar0_20230116-200145-0001.dat';
%   [hdr,data] = basic_load_utig(fn);
%
% Authors: John Paden
%
% See also: basic_load_*.m, run_basic_load_utig.m

% ===================================================================
%% Check input arguments
% ===================================================================
if ~exist('param','var')
  param = struct();
end
if ~isfield(param,'bxds_en') || isempty(param.bxds_en)
  param.bxds_en = false;
end
if ~isfield(param,'recs') || isempty(param.recs)
  param.recs = [0 inf];
end

% Reset/clear hdr struct
hdr = [];

% ===============================================================
%% Open file big-endian for reading
% ===============================================================
[fid,msg] = fopen(fn,'r','ieee-be');
if fid < 1
  fprintf('Could not open file %s\n', fn);
  error(msg);
end

%% Read CX record header
if ~param.bxds_en
  marker = char(fread(fid,8,'char').');
  project = char(fread(fid,8,'char').');
  set = char(fread(fid,8,'char').');
  transect = char(fread(fid,8,'char').');
  stream_name = char(fread(fid,8,'char').');
  sequence_number = fread(fid,1,'uint32',0,'ieee-le');
  rec_length = fread(fid,1,'uint32',0,'ieee-le')+48; % Record length in bytes including the 68 byte CX header
  ct_clk_packed = fread(fid,1,'uint64',0,'ieee-le');
  ct_time = fread(fid,1,'uint32',0,'ieee-le');
  fseek(fid,8,0);
end

%% Read first header
% Bytes: 0-1
nsamp = fread(fid,1,'uint16');
% Bytes: 2
nchan = fread(fid,1,'uint8');
% Bytes: 3
vr0 = fread(fid,1,'uint8');
% Bytes: 4
vr1 = fread(fid,1,'uint8');
% Bytes: 5
choff = fread(fid,1,'uint8');
% Bytes: 6
ver = fread(fid,1,'uint8');
% Bytes: 7
resvd = fread(fid,1,'uint8');
% Bytes: 8
absix = fread(fid,1,'double');
% Bytes: 16
relix = fread(fid,1,'double');
% Bytes: 24
xinc = fread(fid,1,'single');
% Bytes: 28
rseq = fread(fid,1,'uint32');
% Bytes: 32
scount = fread(fid,1,'uint16');
% Bytes: 34
tscount = fread(fid,1,'uint16');
if ~isempty(tscount)
  % Bytes: 36
  rtime = fread(fid,tscount,'double');
end
% Bytes: 36 + 8*tscount

if param.bxds_en
  header_rec_size = 36 + 8*tscount + 17*2;
else
  % Add in 68 byte CX header
  header_rec_size = 36 + 8*tscount + 17*2 + 68;
end
data_rec_size = 2*nsamp*nchan;
rec_size = header_rec_size + data_rec_size;
if isempty(rec_size)
  % This happens when the file is not even big enough to contain a single
  % header.
  data = {};
  hdr = {};
  return;
end
if nchan ~= 2
  warning('This file has nchan=%d. Only nchan=2 supported.', nchan);
  % Find the next good record
  keyboard
end
fseek(fid,0,1);
file_size = ftell(fid);
num_rec_in_file = floor(file_size/rec_size/2)-1;
if param.recs(1) + param.recs(2) > num_rec_in_file
  param.recs(2) = num_rec_in_file - param.recs(1);
end

%% Read data

% Seek to the first record to read in
fseek(fid,rec_size*param.recs(1),-1);

% Preallocate memory
Nc = 4;
data = cell(Nc,1);
hdr = cell(Nc,1);
rec = zeros(Nc,1);
for chan = 1:Nc
  data{chan} = zeros(nsamp,param.recs(2));
  hdr{chan}.offset = zeros(1,param.recs(2));
  hdr{chan}.nsamp = zeros(1,param.recs(2));
  hdr{chan}.choff = zeros(1,param.recs(2));
  hdr{chan}.tscount = zeros(1,param.recs(2));
  hdr{chan}.nchan = zeros(1,param.recs(2));
  hdr{chan}.vr0 = zeros(1,param.recs(2));
  hdr{chan}.vr1 = zeros(1,param.recs(2));
  hdr{chan}.ver = zeros(1,param.recs(2));
  hdr{chan}.resvd = zeros(1,param.recs(2));
  hdr{chan}.absix = zeros(1,param.recs(2));
  hdr{chan}.relix = zeros(1,param.recs(2));
  hdr{chan}.xinc = zeros(1,param.recs(2));
  hdr{chan}.rseq = zeros(1,param.recs(2));
  hdr{chan}.scount = zeros(1,param.recs(2));
  hdr{chan}.rtime = cell(1,param.recs(2));
  hdr{chan}.sequence_number = zeros(1,param.recs(2));
  hdr{chan}.ct_time = zeros(1,param.recs(2));
  hdr{chan}.ct_clk = zeros(1,param.recs(2));
end

% Read in each record
while any(rec < param.recs(2))
  
  if ~param.bxds_en
    % 68 byte CX header
    % -----------------------------------------------------------------------
    % HEADER[0:47]
    choff = 0;
    hdr{choff+1}.marker = char(fread(fid,8,'char').');
    hdr{choff+1}.project = char(fread(fid,8,'char').');
    hdr{choff+1}.set = char(fread(fid,8,'char').');
    hdr{choff+1}.transect = char(fread(fid,8,'char').');
    hdr{choff+1}.stream_name = char(fread(fid,8,'char').');
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
    % ct_clk is monotonically increasing by 511.76 from 197,224,397
    % ct_time is in seconds and is monotonically increasing by 5120 us
    % Last 8 bytes of CT are reserved/zero
    fseek(fid,8,0);
  end
  
  % PAYLOAD[68:...] 
  % -----------------------------------------------------------------------
  if fread(fid,1,'uint16') ~= 3200
    error('Bad record');
  end
  fseek(fid,3,0);
  choff = fread(fid,1,'uint8');
  choff = bitand(choff,bin2dec('00011111'));
  if rec(choff+1) >= param.recs(2)
    fseek(fid,-6 + header_rec_size+data_rec_size,0);
    continue
  end
  rec(choff+1) = rec(choff+1) + 1;
  rec(choff+2) = rec(choff+2) + 1;
  fseek(fid,-6,0);
  
  if ~param.bxds_en
    hdr{choff+1}.sequence_number(rec(choff+1)) = sequence_number;
    hdr{choff+1}.ct_clk(rec(choff+1)) = ct_clk;
    hdr{choff+1}.ct_time(rec(choff+1)) = ct_time;
  end
  
  % XDS header
  % -----------------------------------------------------------------------
  % Bytes: 0-1
  hdr{choff+1}.nsamp(rec(choff+1)) = fread(fid,1,'uint16');
  % Bytes: 2
  hdr{choff+1}.nchan(rec(choff+1)) = fread(fid,1,'uint8');
  % Bytes: 3
  hdr{choff+1}.vr0(rec(choff+1)) = fread(fid,1,'uint8');
  % Bytes: 4
  hdr{choff+1}.vr1(rec(choff+1)) = fread(fid,1,'uint8');
  % Bytes: 5
  hdr{choff+1}.choff(rec(choff+1)) = fread(fid,1,'uint8');
  % Bytes: 6
  hdr{choff+1}.ver(rec(choff+1)) = fread(fid,1,'uint8');
  % Bytes: 7
  hdr{choff+1}.resvd(rec(choff+1)) = fread(fid,1,'uint8');
  % Bytes: 8
  hdr{choff+1}.absix(rec(choff+1)) = fread(fid,1,'double');
  % Bytes: 16
  hdr{choff+1}.relix(rec(choff+1)) = fread(fid,1,'double');
  % Bytes: 24
  hdr{choff+1}.xinc(rec(choff+1)) = fread(fid,1,'single');
  % Bytes: 28
  hdr{choff+1}.rseq(rec(choff+1)) = fread(fid,1,'uint32');
  % Bytes: 32
  hdr{choff+1}.scount(rec(choff+1)) = fread(fid,1,'uint16');
  % Bytes: 34
  hdr{choff+1}.tscount(rec(choff+1)) = fread(fid,1,'uint16');
  % Bytes: 36
  hdr{choff+1}.rtime{rec(choff+1)} = fread(fid,tscount,'double');
  % Odd stuff
  fread(fid,17,'uint16');
  
  hdr{choff+1}.offset(rec(choff+1)) = ftell(fid);

  data{choff+1}(:,rec(choff+1)) = fread(fid,hdr{choff+1}.nsamp(rec(choff+1)),'int16');
  data{choff+2}(:,rec(choff+2)) = fread(fid,hdr{choff+1}.nsamp(rec(choff+1)),'int16');

  if 0
    figure(1); clf;
    plot(data{choff+1}(:,rec(choff+1)));
    hold on
    plot(data{choff+1}(:,rec(choff+1)));
    ylim([-1000 1000]);
    keyboard
  end
end

fclose(fid);
