function [hdr,data,hdr_debug] = basic_load_arena(fn,param)
% [hdr,data,hdr_debug] = basic_load_arena(fn, param)
%
% Loads a single arena radar file after the network headers have been
% removed by run_arena_packet_strip.m. This loader will NOT work on arena
% files that do not have the network packet header bytes removed. This
% function is primarily for debugging. NOTE: 64-bit OS may be essential to
% load the large files into memory.
%
% fn: string containing filename of arena data
% param: struct controlling loading of data
%   .clk: scalar clock (Hz), default 10 MHz, used to interpret
%     counts in the header fields
%   .recs: 2 element vector for records to load [start_rec num_rec]
%     start_rec uses zero-indexing, num_rec can be set to inf to load
%     all remaining records. Default is [0 inf].
%   .processor_subchannel: vector which maps processor (the index into the
%   vector) into subchannel. Arena digital receiver "processors" are
%   zero-indexes, but are 1-indexed in matlab. A value of [0 0 1 1] would
%   indicate processor's 0 and 1 are subchannel 0 and processor's 2 and 3
%   are subchannel 1.
%
%   .processor_mode: vector which maps processor (the index into the
%   vector) into mode. Arena digital receiver "processors" are
%   zero-indexes, but are 1-indexed in matlab. A value of [2 0 2 0] would
%   indicate processor's 1 and 3 are mode 2 and processor's 2 and 4 are
%   mode 2.
%
% hdr: cell vector of structs with fields for each file header
%   corresponding to the entries in data. Standard fields:
%  .frame_sync: byte offset to the frame sync of this record
%  .hdr_type: header type uint32 scalar
%  .hdr_len: header length uint32 scalar
%  Other fields are defined by the radar header type.
% data: cell vector of single matrices of radar data where each entry
%   in the cell vector is a 2-D array for a particular channel/mode.
%   Dimensions:
%   Cell Vector 1: ADC channel (subchannel)
%   Cell Vector 2: Waveform (mode)
%   1: fast-time/range-bin
%   2: slow-time/range-line/records
%
% Examples:
%
%   fn = '20170411_183357_Default0_0001.tst';
%   param = struct('recs',[0 inf]);
%   [hdr,data] = basic_load_arena(fn,param);
%
%   GHOST radar example:
%   [hdr,data] = basic_load_arena('/data/20221225/digrx1/20221224_234423_digrx1_0000.dat',...
%     struct('processor_subchannel',[0 0 0 1 1 1 2 2 2 3 3 3],'processor_mode',[4 0 2 4 0 2 4 0 2 4 0 2]))
%
%   COLDEX radar example:
%   [hdr,data] = basic_load_arena('/scratch/ct_tmp/headers/accum/2022_Antarctica_BaslerMKB/20221225a/digrx1/20221224_152350_accum_digrx1_0003.dat',...
%     struct('processor_subchannel',[0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7],'processor_mode',[0 0 0 0 0 0 0 0 2 2 2 2 2 2 2 2]))
%
%   COLDEX radar example:
%   [hdr,data] = basic_load_arena('/data/digrx0/20221206_084442_accum_digrx0_0000.dat',...
%     struct('processor_subchannel',mod(0:63,8),'processor_mode',repmat(1:8,[8 1])))
%
% Authors: John Paden
%
% See also: basic_load_arena.m, run_arena_packet_strip.m,
% arena_packet_strip.m, arena_packet_strip_task.m

% Load header types
arena_radar_header_type;
arena_frame_sync = uint64(uint64(hex2dec('7F800000'))*2^32 + hex2dec('80000000'));

%% Check input arguments
if ~exist('param','var') || isempty(param)
  param = [];
end
if ~isfield(param,'clk')
  param.clk = 10e6;
end
if ~isfield(param,'recs')
  param.recs = [0 inf];
end
if ~isfield(param,'processor_subchannel')
  param.processor_subchannel = [];
end
if ~isfield(param,'processor_mode')
  param.processor_mode = [];
end

%% Open file little-endian for reading
[fid,msg] = fopen(fn,'r','ieee-le');
if fid < 1
  fprintf('Could not open file %s\n', fn);
  error(msg);
end

%% Read each data frame in one at a time
data = [];
clear hdr;
fseek(fid,0,-1);
lock_state = 0;
rec_in = 0;
rec = 0;
hdr_debug.mode = [];
hdr_debug.subchannel = [];
hdr_debug.profile = [];
profile = 0;
adc = -1; wf = -1;
while ~feof(fid) && rec_in < param.recs(1) + param.recs(2)
  
  if ~lock_state
    tmp = fread(fid,1,'uint64=>uint64');
    if tmp ~= arena_frame_sync
      continue;
    elseif feof(fid)
      break;
    else
      frame_sync_offset = ftell(fid)-8;
      fprintf('Locked at byte %d\n', frame_sync_offset);
      lock_state = 1;
    end
  else
    tmp = fread(fid,1,'uint64=>uint64');
    if tmp ~= arena_frame_sync
      fprintf('Lost lock state at byte %d record %d/%d wf/adc %d/%d\n', ftell(fid)-8, rec_in, rec, wf, adc);
      % Remove the last record
      data{adc,wf} = data{adc,wf}(:,1:end-1);
      hdr_fieldnames = fieldnames(hdr{adc,wf});
      for field_idx = 1:length(hdr_fieldnames)
        hdr{adc,wf}.(hdr_fieldnames{field_idx}) = hdr{adc,wf}.(hdr_fieldnames{field_idx})(1:end-1);
      end
      lock_state = 0;
      continue;
    elseif feof(fid)
      break;
    else
      frame_sync_offset = ftell(fid)-8;
    end
  end
  
  try
    rec_in = rec_in + 1;
    if rec_in > param.recs(1)
      
      %% HEADER debug print out
      if 0
        cur = ftell(fid);
        fseek(fid,-8,0);
        fprintf('\nRECORD: %d\n', rec);
        for idx = 0:17
          A = fread(fid,1,'uint32');
          fprintf('%d\t%12d\t%s\n', idx*4, A, dec2hex(A,8));
        end
        fseek(fid,cur,-1);
      end
      
      %% Read in header
      hdr_type = mod(fread(fid,1,'uint32'),2^31);
      hdr_len = fread(fid,1,'uint32');
      if hdr_type == snow_radar_header_type
        new_hdr = basic_load_arena_snow(fid);
        subchannel = new_hdr.subchannel;
        mode = new_hdr.mode;
      elseif hdr_type == hf_sounder_radar_header_type
        new_hdr = basic_load_arena_hf_sounder(fid);
        subchannel = new_hdr.subchannel;
        mode = new_hdr.mode;
      elseif hdr_type == doppler_radar_header_type
        new_hdr = basic_load_arena_doppler(fid);
        subchannel = 0;
        mode = new_hdr.mode;
      elseif hdr_type == ku0001_radar_header_type
        new_hdr = basic_load_arena_ku0001(fid);
        subchannel = new_hdr.subchannel;
        mode = new_hdr.mode;
      elseif hdr_type == ghost_ku0001_radar_header_type
        new_hdr = basic_load_arena_ghost_ku0001(fid);
        if isempty(param.processor_subchannel)
          new_hdr.subchannel = 0;
          new_hdr.mode = new_hdr.processor;
        else
          new_hdr.subchannel = param.processor_subchannel(new_hdr.processor+1);
          new_hdr.mode = param.processor_mode(new_hdr.processor+1);
        end
        subchannel = new_hdr.subchannel;
        mode = new_hdr.mode;
        profile = new_hdr.processor;
      elseif hdr_type == coldex_arena5xx_radar_header_type
        new_hdr = basic_load_arena_ghost_ku0001(fid);
        if isempty(param.processor_subchannel)
          new_hdr.subchannel = 0;
          new_hdr.mode = new_hdr.processor;
        else
          new_hdr.subchannel = param.processor_subchannel(new_hdr.processor+1);
          new_hdr.mode = param.processor_mode(new_hdr.processor+1);
        end
        subchannel = new_hdr.subchannel;
        mode = new_hdr.mode;
        profile = new_hdr.processor;
        %fprintf('%3d %10d %4d %4d\n', new_hdr.processor, new_hdr.profile_cntr_latch, subchannel, mode);
      else
        subchannel = 0;
        mode = fread(fid,1,'uint8');
        fseek(fid,hdr_len-1,0);
        new_hdr = struct();
      end
      hdr_debug.mode(end+1) = mode;
      hdr_debug.subchannel(end+1) = subchannel;
      hdr_debug.profile(end+1) = profile;
      
      %% Read in data
      profile_type = fread(fid,1,'uint32');
      profile_len = fread(fid,1,'uint32');
      isIQ = 0;
      switch profile_type
        case 0 % 0x00000
          tmp = fread(fid,profile_len/2,'int16');
        case 65536 % 0x10000
          tmp = fread(fid,profile_len/2,'int16');
          isIQ = 1;
        case 131072 % 0x20000
          tmp = fread(fid,profile_len/4,'int32');
          isIQ = 1;
        case 196608 % 0x30000
          if hdr_type == ghost_ku0001_radar_header_type
            tmp = fread(fid,profile_len*2,'float32');
          else
            tmp = fread(fid,profile_len/4,'float32');
          end
          isIQ = 1;
        otherwise
          error('Unsupported profile type %d.', profile_type);
      end
      
      %% Assemble record
      adc = 1+subchannel; % a = adc (subchannel)
      wf = 1+mode; % w = waveform (mode)
      rec = -1;
      if size(data,1) < adc || size(data,2) < wf || isempty(data{adc,wf})
        rec = 1;
      elseif length(tmp) == (isIQ+1)*size(data{adc,wf},1)
        rec = size(data{adc,wf},2)+1;
      end
      if rec >= 0
        hdr{adc,wf}.frame_sync(rec) = frame_sync_offset;
        hdr{adc,wf}.hdr_type(rec) = hdr_type;
        hdr{adc,wf}.hdr_len(rec) = hdr_len;
        
        for fieldname = fieldnames(new_hdr).'
          hdr{adc,wf}.(fieldname{1})(rec) = new_hdr.(fieldname{1});
        end
        
        if isIQ
          data{adc,wf}(:,rec) = tmp(1:2:end) + 1i*tmp(2:2:end);
        else
          data{adc,wf}(:,rec) = tmp;
        end
      else
        warning('Invalid record size (size %d) at file byte %d on record number %d. Expected size %d.', ...
          length(tmp), ftell(fid), rec, 2*size(data{adc,wf},1));
      end
    end
  catch ME
    ME.getReport
    rec = rec - 1;
    hdr{adc,wf}.frame_sync = hdr{adc,wf}.frame_sync(1:rec);
    break;
  end
  
end

fclose(fid);

end

% =========================================================================
%% Function for loading snow radar header
function hdr = basic_load_arena_snow(fid)

hdr.mode = fread(fid,1,'uint8');
hdr.subchannel = fread(fid,1,'uint8');
hdr.processor = NaN;
fseek(fid,2,0);
hdr.wg_delay_latch = fread(fid,1,'uint16');
fseek(fid,10,0);
hdr.rel_time_cntr_latch = fread(fid,1,'uint64');
hdr.profile_cntr_latch = fread(fid,1,'uint64');
hdr.pps_ftime_cntr_latch = fread(fid,1,'uint64');
hdr.pps_cntr_latch = fread(fid,1,'uint64');

end

% =========================================================================
%% Function for loading doppler scat radar header
function hdr = basic_load_arena_doppler(fid)

hdr.mode = fread(fid,1,'uint8');
hdr.subchannel = NaN;
hdr.processor = NaN;
hdr.decimation_ratio = fread(fid,1,'uint8');
hdr.num_pulses_in_burst = fread(fid,1,'uint8');
fseek(fid,5,0);
hdr.num_pulses_in_burst = fread(fid,1,'uint64');
hdr.rel_time_cntr_latch = fread(fid,1,'uint64');
hdr.profile_cntr_latch = fread(fid,1,'uint64');
hdr.pps_ftime_cntr_latch = fread(fid,1,'uint64');
hdr.pps_cntr_latch = fread(fid,1,'uint64');
hdr.antenna_cntr = fread(fid,1,'uint64');
hdr.pri = fread(fid,1,'uint32');
hdr.bri = fread(fid,1,'uint32');
hdr.pulse_width = fread(fid,1,'uint32');
fseek(fid,44,0);
hdr.gps_time_tag = fread(fid,128,'uint8');

end

% =========================================================================
%% Function for loading HF sounder radar header
function hdr = basic_load_arena_hf_sounder(fid)

hdr.mode = fread(fid,1,'uint8');
tmp = fread(fid,1,'uint8');
hdr.subchannel = mod(tmp,16);
hdr.data_channel = floor(tmp/16);
hdr.processor = NaN;
fseek(fid,6,0);
hdr.encoder = fread(fid,1,'uint32');
fseek(fid,4,0);
hdr.rel_time_cntr_latch = fread(fid,1,'uint64');
hdr.profile_cntr_latch = fread(fid,1,'uint64');
hdr.pps_ftime_cntr_latch = fread(fid,1,'uint64');
hdr.pps_cntr_latch = fread(fid,1,'uint64');

end

% =========================================================================
%% Function for loading BAS TO/ku0001 radar header
function hdr = basic_load_arena_ku0001(fid)

hdr.mode = fread(fid,1,'uint8');
tmp = fread(fid,1,'uint8');
hdr.subchannel = mod(tmp,16);
hdr.data_channel = floor(tmp/16);
hdr.processor = NaN;
fseek(fid,6,0);
hdr.encoder = fread(fid,1,'uint32');
fseek(fid,4,0);
hdr.rel_time_cntr_latch = fread(fid,1,'uint64');
hdr.profile_cntr_latch = fread(fid,1,'uint64');
hdr.pps_ftime_cntr_latch = fread(fid,1,'uint64');
hdr.pps_cntr_latch = fread(fid,1,'uint64');

end

% =========================================================================
%% Function for loading GHOST/ku0001 radar header
function hdr = basic_load_arena_ghost_ku0001(fid)

hdr.mode = fread(fid,1,'uint8');
tmp = fread(fid,1,'uint8');
hdr.subchannel = mod(tmp,16);
hdr.data_channel = floor(tmp/16);
hdr.processor = fread(fid,1,'uint8');
fseek(fid,5+8,0); % RESERVED for future use
hdr.rel_time_cntr_latch = fread(fid,1,'uint64');
hdr.profile_cntr_latch = fread(fid,1,'uint64');
hdr.pps_ftime_cntr_latch = fread(fid,1,'uint64');
hdr.pps_cntr_latch = fread(fid,1,'uint64');

end
