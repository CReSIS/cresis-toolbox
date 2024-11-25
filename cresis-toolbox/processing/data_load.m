function [hdr,data] = data_load(param,records,states)
% [hdr,data] = data_load(param,records,states)
%
% https://ops.cresis.ku.edu/wiki/index.php/Data_load#data_load.m
%
% Author: John Paden

wfs = param.radar.wfs;

[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);

%% Preallocate data
% ===================================================================
total_rec = param.load.recs(end)-param.load.recs(1)+1;
Nx = floor(total_rec/param.load.presums);
data = cell(size(param.load.imgs));
data_complex_hack = false(size(param.load.imgs));
hdr = [];
hdr.bad_rec = cell(size(param.load.imgs));
for img = 1:length(param.load.imgs)
  wf = abs(param.load.imgs{img}(1,1));
  Nc = size(param.load.imgs{img},1);
  % data{img}: may eventually be complex(zeros(Nt,Nx,Nc,'single')) after
  % the first record/range-line is written
  data{img} = zeros(0,Nx,Nc,'single');
  hdr.bad_rec{img} = zeros(1,Nx,Nc,'uint8');
  hdr.nyquist_zone_hw{img} = zeros(1,Nx,'uint8');
  hdr.nyquist_zone_signal{img} = nan(1,Nx);
  hdr.DDC_dec{img} = ones(1,Nx,'double');
  hdr.DDC_freq{img} = zeros(1,Nx,'double');
  hdr.Nt{img} = zeros(1,Nx,'double');
  hdr.t0_raw{img} = zeros(1,Nx,'double');
  hdr.t_ref{img} = zeros(1,Nx,'double');
  
  nyquist_zone_hw{img} = zeros(1,param.load.presums);
  nyquist_zone_signal{img} = nan(1,param.load.presums);
  DDC_dec{img} = ones(1,param.load.presums);
  DDC_freq{img} = zeros(1,param.load.presums);
  % wfs.Nt_raw: stores the number of range bins IF the number of range bins
  %  is constant. If the number of range bins may change on a per range line
  %  basis, then this field is set to zero.
  %  wfs(wf).Nt_raw == 0: This means the number of range bins is allowed
  %    to change for each range line OR is not known ahead of time.
  %  wfs(wf).Nt_raw > 0: This means the number of range bins is fixed and
  %    is known ahead of time.
  % hdr.Nt{img}: stores the number of range bins for each range line
  % Nt: number of samples or range bins in fast time.
  %   Some systems know Nt ahead of time and wfs(wf).Nt_raw contains the
  %   value. Some do not and wfs(wf).Nt_raw equals zero and the number of
  %   samples is determined during loading.
  Nt{img} = wfs(wf).Nt_raw*ones(1,param.load.presums);
  t0{img} = zeros(1,param.load.presums);
  t_ref{img} = zeros(1,param.load.presums);
end
if any(param.records.file.version==[414])
  wf_adc_tmp_state_idx = -1;
end

%% Endian mode
% ===================================================================
[~,~,endian] = computer;
if any(param.records.file.version==[9 10 103 412])
  if endian == 'B'
    % IEEE little endian files with IEEE big endian computer
    swap_bytes_en = true;
  else
    swap_bytes_en = false;
  end
else
  if endian == 'L'
    % IEEE big endian files with IEEE little endian computer
    swap_bytes_en = true;
  else
    swap_bytes_en = false;
  end
end

%% Waveform Map (t_ref calculation)
% ===================================================================
if any(param.records.file.version==[8])
  % Handles bit shift error in waveform_ID field
  waveform_ID_map = [typecast(uint8('     000'),'uint64')
    typecast(uint8('     090'),'uint64')
    typecast(uint8('     120'),'uint64')
    typecast(uint8('     330'),'uint64')
    typecast(uint8('     000')*2,'uint64')
    typecast(uint8('     090')*2,'uint64')
    typecast(uint8('     120')*2,'uint64')
    typecast(uint8('     330')*2,'uint64')
    typecast(uint8('OIB_FMCW'),'uint64')
    typecast(uint8('OIB_FMCW')*2,'uint64')
    ];
  waveform_ID_t_ref = [0e-6 9e-6 12e-6 33e-6 0e-6 9e-6 12e-6 33e-6 0e-6 0e-6];
  
end

%% Load data
% ===================================================================
for state_idx = 1:length(states)
  state = states(state_idx);
  file_data_last_file = [];
  board = state.board;
  board_idx = state.board_idx;
  fid = 0;
  out_rec = 0;
  % num_accum: accumulator index (increases one per "good" record), matches
  % num_presum_records when all records are good.
  num_accum = zeros(size(state.wf));
  % num_presum_records: presum index (increases one per record), takes on
  % values from 0 to param.load.presums
  num_presum_records = 0;
  
  % Find the file index for each record. If records.offset has extra
  % entries, get file_idxs for these too.
  tmp_recs = param.load.recs+[0 size(records.offset,2)-(1+diff(param.load.recs))];
  file_idxs = relative_rec_num_to_file_idx_vector(tmp_recs(1):tmp_recs(end), ...
    records.relative_rec_num{board_idx});
  
  if param.records.file.version == 413
    fn_name = records.relative_filename{1}{1};
    [fn_dir] = get_segment_file_list(param,1);
    fn = fullfile(fn_dir,fn_name);
    load(fn); % Loads "block" structure
    
    total_rec = param.load.recs(end)-param.load.recs(1)+1;
    
    wf = 1;
    img = 1;
    data{img} = block.ch0(:,param.load.recs(1):param.load.recs(end));
    
    hdr.nyquist_zone_hw{img} = zeros(1,total_rec);
    hdr.nyquist_zone_signal{img} = zeros(1,total_rec);
    hdr.DDC_dec{img} = ones(1,total_rec);
    hdr.DDC_freq{img} = zeros(1,total_rec);
    hdr.Nt{img} = size(block.ch0,1) * ones(1,total_rec);
    hdr.t0_raw{img} = block.twtt(1) * ones(1,total_rec);
    hdr.t_ref{img} = zeros(1,total_rec);
    
    rec = total_rec+1;
    
  elseif param.records.file.version == 1000
    % for the full simulator
    raw_data_file = load(param.sim.out_fn_raw_data); % has raw_data and param
    wf = 1;
    img = 1;
    data = raw_data_file.raw_data;
    hdr.bad_rec{img}              = raw_data_file.hdr.bad_rec{img};
    hdr.nyquist_zone_hw{img}      = raw_data_file.hdr.nyquist_zone_hw{img};
    hdr.nyquist_zone_signal{img}  = raw_data_file.hdr.nyquist_zone_signal{img};
    hdr.DDC_dec{img}              = raw_data_file.hdr.DDC_dec{img};
    hdr.DDC_freq{img}             = raw_data_file.hdr.DDC_freq{img};
    hdr.Nt{img}                   = raw_data_file.hdr.Nt{img};
    hdr.t0_raw{img}               = raw_data_file.hdr.t0_raw{img};
    hdr.t_ref{img}                = raw_data_file.hdr.t_ref{img};
    
    rec = total_rec+1;
    
  else
    rec = 1;
  end
  
  while rec <= total_rec
    
    %% Load in a file
    if param.records.file.version == 414
      file_idx = file_idxs(rec);
    elseif records.offset(board_idx,rec) == -2^31 || bitand(param.load.bit_mask, records.bit_mask(board_idx,rec))
      file_idx = -1;
    else
      % Determine which file has the current record
      file_idx = file_idxs(rec);
      if ~isempty(file_data_last_file)
        % Part of current record has been loaded from previous file
      elseif records.offset(board_idx,rec) < 0 && records.offset(board_idx,rec) ~= -2^31
        % Record offset is negative, but not -2^31: this means the record
        % started in the previous file.
        file_idx = file_idx - 1;
      end
      
      % Get the file's name
      adc = state.adc(1);
      fn_name = records.relative_filename{board_idx}{file_idx};
      [fn_dir] = get_segment_file_list(param,board_idx);
      fn = fullfile(fn_dir,fn_name);
      
      % Open the file
      fprintf('  Open %s (%s)\n', fn, datestr(now));
      [fid,msg] = fopen(fn, 'rb');
      if fid <= 0
        error('File open failed (%s)\n%s',fn, msg);
      end
      
      % Seek to the current record's position in the file
      if ~isempty(file_data_last_file)
        file_data_offset = records.offset(board_idx,rec);
      elseif records.offset(board_idx,rec) < 0
        finfo = dir(fn);
        file_data_offset = finfo.bytes + records.offset(board_idx,rec);
        fseek(fid,file_data_offset,-1);
      else
        file_data_offset = records.offset(board_idx,rec);
        fseek(fid,file_data_offset,-1);
      end
      
      % Load the rest of the file into memory
      file_data = [file_data_last_file(:); fread(fid,inf,'uint8=>uint8')];
      fclose(fid);
    end
    
    %% Pull out records from this file
    while rec <= total_rec
      if records.offset(board_idx,rec) == -2^31 || bitand(param.load.bit_mask, records.bit_mask(board_idx,rec))
      elseif param.records.file.version == 414
        % If the current record is in the next file, break out of loop
        if file_idxs(rec) > file_idx
          % Force the file to be loaded when the next record is loaded
          wf_adc_tmp_state_idx = -1;
          break;
        end
        % Process all wf-adc pairs in this record
        % ai: num_accum index (1 to length(state.wf))
        for ai = 1:length(state.wf)
          adc = state.adc(ai);
          wf = state.wf(ai);
          img = state.img(ai);
          mode_latch = state.mode{ai};
          weight = state.weight(ai);
          subchannel = state.subchannel{ai};
          
          % Determine which file has the current record
          file_idx = file_idxs(rec);
          
          % Get the file's name
          BW = (param.radar.wfs(wf).f1-param.radar.wfs(wf).f0)/1e6;
          Tpd = param.radar.wfs(wf).Tpd*1e6;
          fn_name = records.relative_filename{board_idx}{file_idx};
          [fn_dir] = get_segment_file_list(param,board_idx);
          
          fname = fname_info_bas(fn_name);
          if adc<5
            subarray = 'Port';
            rx = sprintf('P%X',adc);
          elseif adc<9
            subarray = 'Belly';
            rx = sprintf('B%X',adc);
          else
            subarray = 'Star';
            rx = sprintf('S%X',adc);
          end
          
          if all(param.radar.wfs(wf).tx_weights == [2000 2000 2000 2000 0 0 0 0 0 0 0 0])
            tx = 'P1234';
          else
            tx = 'S9ABC';
          end
          
          if weight > 0
            zeropimod = 'C';
          else
            zeropimod = 'J';
          end
          
          fn_subdir = sprintf('%s%s_new',fname.name,subarray);
          fn_name = sprintf('%s%s_%s_Tx%s_Rx%s_%s%02.0fL%.0f_T01_%04.0f.mat', ...
            fname.name, subarray, datestr(fname.datenum,'YYYYmmDDHHMMSS'), tx, rx, zeropimod, ...
            BW, Tpd, fname.file_idx);
          fn = fullfile(fn_dir,fn_subdir,fn_name);
          
          pri_fn_name = sprintf('%s%s_%s_Tx%s_Rx%s_%s%02.0fL%.0f_T01_%04.0f_pri.mat', ...
            fname.name, subarray, datestr(fname.datenum,'YYYYmmDDHHMMSS'), tx, rx, zeropimod, ...
            BW, Tpd, fname.file_idx);
          pri_fn = fullfile(fn_dir,fn_subdir,pri_fn_name);
          
          % Open the file
          if isempty(wf_adc_tmp_state_idx) || wf_adc_tmp_state_idx ~= state_idx
            fprintf('  Load %s (%s)\n', fn, datestr(now));
            %wf_adc_tmp_data = matfile(fn); % Might be better if files saved in -v7.3
            wf_adc_tmp_data = load(fn);
            wf_adc_tmp_pri = load(pri_fn);
            wf_adc_tmp_state_idx = state_idx;
          end
          
          % Select specific records
          tmp_data_rec = 1 + param.load.recs(1) + rec - 1 - records.relative_rec_num{board_idx}(file_idx);
          if tmp_data_rec > size(wf_adc_tmp_data.s,2) || wf_adc_tmp_pri.badTrace(tmp_data_rec)
            % Bad record so don't accumulate it.
          else
            tmp_data = wf_adc_tmp_data.s(:,tmp_data_rec);
            Nt{img}(num_accum(ai)+1) = length(tmp_data);
            
            % Accumulate (presum)
            if num_accum(ai) == 0
              state.data{ai} = single(tmp_data);
            else
              state.data{ai} = state.data{ai} + single(tmp_data);
            end
            num_accum(ai) = num_accum(ai) + 1;
          end
        end
        
      else
        if records.offset(board_idx,rec) < 0
          if isempty(file_data_last_file)
            % Record offset is negative and so represents a record that
            % bridges into the next file
            file_data_last_file = file_data(end+max(-end,records.offset(board_idx,rec))+1:end);
            break
          else
            file_data_last_file = [];
          end
        end
        % If the current record is in the next file, break out of loop
        if file_idxs(rec) > file_idx
          break;
        end
        
        % Extract next record (determine its relative position in the
        % file_data memory block
        rec_offset = records.offset(board_idx,rec) - file_data_offset;
        
        % record_mode==1: Find the size of the current record. This is used
        % with the arena which has a dynamic record where the ordering of
        % the contents of each record can change. If the sub-header fields
        % have digital errors in them, especially in the length field, this
        % can cause large erroneous reads from the file that break stuff.
        % This field prevents the large erroneous reads. This code
        % currently assumes that all records are the same length; the
        % individual header-waveforms inside a record can all be different
        % in size, but their sizes need to always add up to the same value
        % for this code to work in all cases.
        if rec < length(file_idxs) && file_idxs(rec+1) == file_idxs(rec)
          % Next record is in this file, rec size is set to the offset to
          % the next record
          start_rec = -1;
          test_rec = rec-1;
          while start_rec < 0 && test_rec < size(records.offset,2)
            test_rec = test_rec + 1;
            if records.offset(board_idx,test_rec) ~= -2^31
              start_rec = test_rec;
            end
          end
          next_rec = -1;
          test_rec = start_rec;
          while next_rec < 0 && test_rec < size(records.offset,2)
            test_rec = test_rec + 1;
            if records.offset(board_idx,test_rec) ~= -2^31
              next_rec = test_rec;
            end
          end
          if next_rec ~= -1
            % Found two good records to estimate the maximum record size
            % from.
            rec_size = records.offset(board_idx,next_rec) - records.offset(board_idx,start_rec);
          else
            % Did not find two good records, so choose a very loose value
            % for the maximum record size
            rec_size = (length(file_data)+file_data_offset) - records.offset(board_idx,rec);
          end
        else
          % Next record is in the next file, rec_size is set to the rest of
          % the data in this file
          rec_size = (length(file_data)+file_data_offset) - records.offset(board_idx,rec);
        end
        
        % Process all wf-adc pairs in this record
        missed_wf_adc = false;
        for ai = 1:length(state.wf)
          adc = state.adc(ai);
          wf = state.wf(ai);
          img = state.img(ai);
          mode_latch = state.mode{ai};
          subchannel = state.subchannel{ai};
          mode_latch_subchannel = mode_latch*2^8 + subchannel; % Create unique number for each mode/subchannel pair (modes and subchannels limited to 0-255/8-bits)
          
          % Read in headers for this waveform
          % ---------------------------------------------------------------
          
          if wfs(wf).quantization_to_V_dynamic
            if param.records.file.version == 407
              bit_shifts = double(-typecast(file_data(rec_offset + wfs(wf).offset - 4),'int8'));
              % Apply dynamic bit shifts
              quantization_to_V_adjustment = 2^(bit_shifts - double(wfs(wf).bit_shifts(adc)));
            end
          else
            quantization_to_V_adjustment = 1;
          end
          
          % Read in headers for this record
          if any(param.records.file.version == [2 3 4 5 7 8 11])
            
            % Jump through the record one waveform at a time until we get
            % to the waveform we need to load.
            for tmp_wf = 1:wf
              if tmp_wf == 1
                wf_hdr_offset = rec_offset;
                % wfs(wf-1).offset % Should already be set in data_load_wfs
              else
                wf_hdr_offset = wf_hdr_offset + last_wf_size;
                wfs(wf).offset = wfs(wf-1).offset + last_wf_size; % Update based on actual record size
              end
              
              if any(param.records.file.version == [8 11])
                if swap_bytes_en
                  start_idx = param.radar.fs/param.records.file.clk*double(swapbytes(typecast(file_data(wf_hdr_offset+37:wf_hdr_offset+38), 'uint16')));
                  stop_idx = param.radar.fs/param.records.file.clk*double(swapbytes(typecast(file_data(wf_hdr_offset+39:wf_hdr_offset+40), 'uint16')));
                else
                  start_idx = param.radar.fs/param.records.file.clk*double(typecast(file_data(wf_hdr_offset+37:wf_hdr_offset+38), 'uint16'));
                  stop_idx = param.radar.fs/param.records.file.clk*double(typecast(file_data(wf_hdr_offset+39:wf_hdr_offset+40), 'uint16'));
                end
                Nt{img}(num_accum(ai)+1) = stop_idx - start_idx;
                raw_or_DDC = 1; % Raw or real data/not complex
              else
                if swap_bytes_en
                  start_idx = double(swapbytes(typecast(file_data(wf_hdr_offset+37:wf_hdr_offset+38), 'uint16')));
                  stop_idx = double(swapbytes(typecast(file_data(wf_hdr_offset+39:wf_hdr_offset+40), 'uint16')));
                else
                  start_idx = double(typecast(file_data(wf_hdr_offset+37:wf_hdr_offset+38), 'uint16'));
                  stop_idx = double(typecast(file_data(wf_hdr_offset+39:wf_hdr_offset+40), 'uint16'));
                end
                if any(param.records.file.version == [2 4])
                  DDC_dec{img}(num_accum(ai)+1) = 1;
                  Nt{img}(num_accum(ai)+1) = (stop_idx - start_idx);
                  wfs(wf).complex = false;
                  raw_or_DDC = 1; % Raw or real data/not complex
                else
                  if param.records.file.version == 3
                    DDC_dec{img}(num_accum(ai)+1) = 2^(double(file_data(wf_hdr_offset+46))+2);
                  else % param.records.file.version == [5 7]
                    DDC_dec{img}(num_accum(ai)+1) = 2^(double(file_data(wf_hdr_offset+46))+1);
                  end
                  raw_or_DDC = file_data(wf_hdr_offset + 48); % 1 means "raw", 0 means "DDC/complex"
                  if raw_or_DDC
                    Nt{img}(num_accum(ai)+1) = (stop_idx - start_idx);
                    wfs(wf).complex = false;
                    % Raw mode, so DDC_dec is one even if header field says
                    % otherwise
                    DDC_dec{img}(num_accum(ai)+1) = 1;
                  else
                    Nt{img}(num_accum(ai)+1) = floor((stop_idx - start_idx) / DDC_dec{img}(num_accum(ai)+1));
                    wfs(wf).complex = true;
                  end
                end
              end
              
              if tmp_wf < wf
                last_wf_size = wfs(wf).sample_size*(1+~raw_or_DDC)*wfs(wf).adc_per_board*Nt{img}(num_accum(ai)+1) + wfs(wf).wf_header_size;
              end
              
            end
            start_idx = start_idx + DDC_dec{img}(num_accum(ai)+1)*wfs(wf).time_raw_trim(1);
            Nt{img}(num_accum(ai)+1) = Nt{img}(num_accum(ai)+1) - sum(wfs(wf).time_raw_trim);
            
            % Number of fast-time samples Nt, and start time t0
            if any(param.records.file.version == [3 5 7]) && raw_or_DDC
              % Raw mode, so DDC_freq is zero even if header field says
              % otherwise
              DDC_freq{img}(num_accum(ai)+1) = 0;
            elseif all(param.records.file.version ~= [2 4 8 11])
              % NCO frequency
              if swap_bytes_en
                DDC_freq{img}(num_accum(ai)+1) = double(swapbytes(typecast(file_data(wf_hdr_offset+43:wf_hdr_offset+44),'uint16')));
              else
                DDC_freq{img}(num_accum(ai)+1) = double(typecast(file_data(wf_hdr_offset+43:wf_hdr_offset+44),'uint16'));
              end
              if param.records.file.version == 3
                DDC_freq{img}(num_accum(ai)+1) = DDC_freq{img}(num_accum(ai)+1) / 2^15 * wfs(wf).fs_raw * 2;
              elseif any(param.records.file.version == [5 7])
                DDC_freq{img}(num_accum(ai)+1) = DDC_freq{img}(num_accum(ai)+1) / 2^15 * wfs(wf).fs_raw * 2;
              end
            end
            t0{img}(num_accum(ai)+1) = start_idx/wfs(wf).fs_raw;
            
            if param.records.file.version == 8
              % Debug: char(file_data(wf_hdr_offset+41:wf_hdr_offset+48).')
              % No swapbytes should be necessary for this typecast because
              % it is actually a string of 8 characters.
              waveform_ID = typecast(file_data(wf_hdr_offset+41:wf_hdr_offset+48), 'uint64');
              waveform_ID_map_idx = find(waveform_ID_map == waveform_ID,1);
              if isempty(waveform_ID_map_idx)
                if wfs(wf).wf_ID_best
                  % Waveform ID best match is enabled
                  waveform_ID_binary = dec2bin(waveform_ID,64);
                  waveform_ID_distance = zeros(size(waveform_ID_map));
                  for id_idx = 1:length(waveform_ID_map)
                    waveform_ID_map_binary = dec2bin(waveform_ID_map(id_idx),64);
                    waveform_ID_distance(id_idx) = sum(abs(waveform_ID_map_binary-waveform_ID_binary));
                  end
                  [waveform_ID_distance,waveform_ID_map_idx] = min(waveform_ID_distance);
                  warning('waveform_ID read from file is:\nuint64(%lu)\nbinary(%s)\nASCII(%s)\nIt was not found in waveform_ID_map list. param.radar.waveform_ID_best_match_en is enabled. Closest match is index %d:\nuint64(%lu)\nbinary(%s)\nASCII(%s)\nwith %d binary differences.', ...
                    waveform_ID, dec2bin(waveform_ID,64), char(typecast(waveform_ID,'uint8')), ...
                    waveform_ID_map_idx, ...
                    waveform_ID_map(waveform_ID_map_idx), dec2bin(waveform_ID_map(waveform_ID_map_idx),64), char(typecast(waveform_ID_map(waveform_ID_map_idx),'uint8')), ...
                    waveform_ID_distance);
                else
                  error('%lu (%s) waveform_ID not found in waveform_ID_map.',waveform_ID, dec2bin(waveform_ID,64));
                end
              end
              t_ref{img}(num_accum(ai)+1) = wfs(wf).t_ref + waveform_ID_t_ref(waveform_ID_map_idx);
            else
              % Reference deramp time delay, t_ref
              t_ref{img}(num_accum(ai)+1) = wfs(wf).t_ref;
            end
            
            % Bit shifts
            if wfs(wf).quantization_to_V_dynamic
              bit_shifts = double(-typecast(file_data(wf_hdr_offset+36),'int8'));
              quantization_to_V_adjustment = 2^(bit_shifts - double(wfs(wf).bit_shifts(adc)));
            end
            
            % Nyquist zone
            if any(param.records.file.version == [8])
              % bitand(bitshift(file_data(wf_hdr_offset+34),-4),1); % Complex data flag
              wfs(wf).adc_per_board = 1;
              nyquist_zone_hw{img}(num_accum(ai)+1) = bitand(file_data(wf_hdr_offset+34),3);
            elseif any(param.records.file.version == [11])
              % bitand(bitshift(file_data(wf_hdr_offset+34),-4),1); % Complex data flag
              wfs(wf).adc_per_board = double(1+bitand(bitshift(file_data(wf_hdr_offset+34),-2),3));
              nyquist_zone_hw{img}(num_accum(ai)+1) = bitand(file_data(wf_hdr_offset+34),3);
            elseif any(param.records.file.version == [3 5 7])
              nyquist_zone_hw{img}(num_accum(ai)+1) = file_data(wf_hdr_offset+45);
            elseif any(param.records.file.version == [4])
              nyquist_zone_hw{img}(num_accum(ai)+1) = 0;
            else
              % nyquist_zone_hw defaults to 1 for all other file versions
              % (ideally this is overridden by
              % records.nyquist_zone_sig)
              nyquist_zone_hw{img}(num_accum(ai)+1) = 1;
            end
            % Map any hardware nyquist_zones >= 4 to [0 1 2 3]
            nyquist_zone_hw{img}(num_accum(ai)+1) = mod(nyquist_zone_hw{img}(num_accum(ai)+1),4);
          elseif any(param.records.file.version == [415])
            Nt{img}(num_accum(ai)+1) = 3200;
          end
          if isfield(records,'nyquist_zone_hw') && ~isnan(records.nyquist_zone_hw(rec))
%             if nyquist_zone_hw{img}(num_accum(ai)+1) ~= records.nyquist_zone_hw(rec)
%               fprintf('Overwriting nz fro rec:%d from records\n',rec);
%             end              
            nyquist_zone_hw{img}(num_accum(ai)+1) = records.nyquist_zone_hw(rec);
          end
          % For the records generated using old data_load
          % Map any hardware nyquist_zones >= 4 to [0 1 2 3]
          nyquist_zone_hw{img}(num_accum(ai)+1) = mod(nyquist_zone_hw{img}(num_accum(ai)+1),4);
          
          nyquist_zone_signal{img}(num_accum(ai)+1) = nyquist_zone_hw{img}(1);
          if isfield(records,'nyquist_zone_sig') && ~isnan(records.nyquist_zone_sig(rec))
            nyquist_zone_signal{img}(num_accum(ai)+1) = records.nyquist_zone_sig(rec);
          end
          
          % Extract waveform for this wf-adc pair
          switch wfs(wf).record_mode
            case 0
              % Read in standard fixed record
              %  - Supports interleaved IQ samples
              %  - Supports arbitrary sample types
              %  - Supports interleaved data channels ("adcs")
              start_bin = 1+rec_offset + wfs(wf).offset + wfs(wf).time_raw_trim(1)*wfs(wf).adc_per_board*wfs(wf).sample_size;
              stop_bin = start_bin + (1+wfs(wf).complex)*Nt{img}(1)*wfs(wf).adc_per_board*wfs(wf).sample_size-1;
              if swap_bytes_en
                tmp = single(swapbytes(typecast(file_data(start_bin : stop_bin), wfs(wf).sample_type)));
              else
                tmp = single(typecast(file_data(start_bin : stop_bin), wfs(wf).sample_type));
              end
              if wfs(wf).complex
                if wfs(wf).conjugate_on_load
                  tmp = tmp(1:2:end) - 1i*tmp(2:2:end);
                else
                  tmp = tmp(1:2:end) + 1i*tmp(2:2:end);
                end
              end
              adc_offset = mod(adc-1,wfs(wf).adc_per_board);
              tmp = tmp(1+adc_offset : wfs(wf).adc_per_board : end);
              if param.records.file.version ~= 408
                tmp_data{adc,wf} = tmp;
              else
                % 8 sample interleave for file_version 408
                tmp_data{adc,wf}(1:8:length(tmp)) = tmp(1:8:end);
                tmp_data{adc,wf}(5:8:length(tmp)) = tmp(5:8:end);
                tmp_data{adc,wf}(2:8:length(tmp)) = tmp(2:8:end);
                tmp_data{adc,wf}(6:8:length(tmp)) = tmp(6:8:end);
                tmp_data{adc,wf}(3:8:length(tmp)) = tmp(3:8:end);
                tmp_data{adc,wf}(7:8:length(tmp)) = tmp(7:8:end);
                tmp_data{adc,wf}(4:8:length(tmp)) = tmp(4:8:end);
                tmp_data{adc,wf}(8:8:length(tmp)) = tmp(8:8:end);
              end
              
            case 2
              % UTIG MARFA/HICARS fixed length
              start_bin = 1+rec_offset + wfs(wf).offset + wfs(wf).time_raw_trim(1)*wfs(wf).sample_size;
              if file_data(1+rec_offset+12800+68+5) == 2
                % file_data(12800+68+6) choff (channel offset) field
                % indicates that adc 0 and 1 come first
                if adc == 2
                  start_bin = start_bin + 6400;
                elseif adc == 3
                  start_bin = start_bin + 12800 + 138;
                elseif adc == 4
                  start_bin = start_bin + 19200 + 138;
                end
              else
                % file_data(12800+68+6) choff (channel offset) field
                % indicates that adc 3 and 4 come first
                if adc == 4
                  start_bin = start_bin + 6400;
                elseif adc == 1
                  start_bin = start_bin + 12800 + 138;
                elseif adc == 2
                  start_bin = start_bin + 19200 + 138;
                end
              end
              stop_bin = start_bin + (1+wfs(wf).complex)*Nt{img}(1)*wfs(wf).sample_size-1;
              
              tmp_data{adc,wf} = single(swapbytes(typecast(file_data(start_bin : stop_bin), wfs(wf).sample_type)));
              
            case 1
              % Read in Arena dynamic record
              sub_rec_offset = 0;
              missed_wf_adc = true;
              while sub_rec_offset < rec_size
                total_offset = rec_offset + sub_rec_offset;
                if length(file_data) < total_offset+72
                  % Unexpected end of file, so we missed the record
                  missed_wf_adc = true;
                  break;
                end
                if swap_bytes_en
                  radar_header_type = mod(swapbytes(typecast(file_data(total_offset+(9:12)),'uint32')),2^31); % Ignore MSB
                  radar_header_len = double(swapbytes(typecast(file_data(total_offset+(13:16)),'uint32')));
                  if radar_header_len ~= 48
                    % Bad header length, skip this record
                    missed_wf_adc = true;
                    break;
                  end
                  radar_profile_length = double(swapbytes(typecast(file_data(total_offset+radar_header_len+(21:24)),'uint32')));
                else
                  radar_header_type = mod(typecast(file_data(total_offset+(9:12)),'uint32'),2^31); % Ignore MSB
                  radar_header_len = double(typecast(file_data(total_offset+(13:16)),'uint32'));
                  if radar_header_len ~= 48
                    % Bad header length, skip this record
                    missed_wf_adc = true;
                    break;
                  end
                  radar_profile_length = double(typecast(file_data(total_offset+radar_header_len+(21:24)),'uint32'));
                end
                if any(radar_header_type == [5 16 23 45 8194])
                  if radar_header_type == 45 || radar_header_type == 8194
                    profile = double(typecast(file_data(total_offset+19),'uint8'));
%                     mode2 = double(typecast(file_data(total_offset+17),'uint8'));
%                     subchannel2 = double(typecast(file_data(total_offset+18),'uint8'));
                    mode = param.records.data_map{board_idx}(param.records.data_map{board_idx}(:,1)==profile,2);
                    subchannel = param.records.data_map{board_idx}(param.records.data_map{board_idx}(:,1)==profile,3);
%                     fprintf('%2d %d %d %d %d\n', profile, mode, subchannel, mode2, subchannel2);
                  else
                    mode = double(typecast(file_data(total_offset+17),'uint8'));
                    subchannel = double(typecast(file_data(total_offset+18),'uint8'));
                  end
                  if swap_bytes_en
                    radar_profile_format = swapbytes(typecast(file_data(total_offset+radar_header_len+(17:20)),'uint32'));
                    if radar_profile_format == 196608 && radar_header_type ~= 8194 % 0x30000
                      radar_profile_length = radar_profile_length*8;
                    end
                  else
                    radar_profile_format = typecast(file_data(total_offset+radar_header_len+(17:20)),'uint32');
                    if radar_profile_format == 196608 && radar_header_type ~= 8194 % 0x30000
                      radar_profile_length = radar_profile_length*8;
                    end
                  end
                  if length(file_data) < total_offset+24+radar_header_len+radar_profile_length
                    % Unexpected end of file, so we missed the record
                    missed_wf_adc = true;
                    break;
                  end
                  if swap_bytes_en
                    if swapbytes(typecast(file_data(total_offset+(1:8)),'uint64')) ~= 9187343241983295488
                      % This record has a bad frame sync header so probably
                      % contains bad data.
                      missed_wf_adc = true;
                      break;
                    end
                    if length(file_data) >= total_offset+24+radar_header_len+radar_profile_length+8 ...
                        && swapbytes(typecast(file_data(total_offset+ 24 + radar_header_len + radar_profile_length +(1:8)),'uint64')) ~= 9187343241983295488
                      % This record has a bad frame sync header so probably
                      % contains bad data.
                      missed_wf_adc = true;
                      break;
                    end
                  else
                    if typecast(file_data(total_offset+(1:8)),'uint64') ~= 9187343241983295488
                      % This record has a bad frame sync header so probably
                      % contains bad data.
                      missed_wf_adc = true;
                      break;
                    end
                    if length(file_data) >= total_offset+24+radar_header_len+radar_profile_length+8 ...
                        && typecast(file_data(total_offset+ 24 + radar_header_len + radar_profile_length +(1:8)),'uint64') ~= 9187343241983295488
                      % This record has a bad frame sync header so probably
                      % contains bad data.
                      missed_wf_adc = true;
                      break;
                    end
                  end
                  found_mode_match = false;
                  for mode_idx = 1:length(mode)
                    if any(mode_latch_subchannel == mode(mode_idx)*2^8 + subchannel(mode_idx))
                      found_mode_match = true;
                    end
                  end
                  if found_mode_match
                    % This matches the mode and subchannel that we need
                    is_IQ = 0;
                    if swap_bytes_en
                      switch radar_profile_format
                        case 0 % 0x00000
                          tmp_data{adc,wf} = single(swapbytes(typecast(file_data(total_offset+24+radar_header_len+(1:radar_profile_length)),'int16')));
                        case 65536 % 0x10000
                          tmp_data{adc,wf} = single(swapbytes(typecast(file_data(total_offset+24+radar_header_len+(1:radar_profile_length)),'int16')));
                          is_IQ = 1;
                        case 131072 % 0x20000
                          tmp_data{adc,wf} = single(swapbytes(typecast(file_data(total_offset+24+radar_header_len+(1:radar_profile_length)),'int32')));
                          is_IQ = 1;
                        case 196608 % 0x30000
                          tmp_data{adc,wf} = single(swapbytes(typecast(file_data(total_offset+24+radar_header_len+(1:radar_profile_length)),'single')));
                          is_IQ = 1;
                      end
                    else
                      switch radar_profile_format
                        case 0 % 0x00000
                          tmp_data{adc,wf} = single(typecast(file_data(total_offset+24+radar_header_len+(1:radar_profile_length)),'int16'));
                        case 65536 % 0x10000
                          tmp_data{adc,wf} = single(typecast(file_data(total_offset+24+radar_header_len+(1:radar_profile_length)),'int16'));
                          is_IQ = 1;
                        case 131072 % 0x20000
                          tmp_data{adc,wf} = single(typecast(file_data(total_offset+24+radar_header_len+(1:radar_profile_length)),'int32'));
                          is_IQ = 1;
                        case 196608 % 0x30000
                          tmp_data{adc,wf} = single(typecast(file_data(total_offset+24+radar_header_len+(1:radar_profile_length)),'single'));
                          is_IQ = 1;
                      end
                    end
                    if is_IQ
                      if wfs(wf).conjugate_on_load
                        tmp_data{adc,wf} = tmp_data{adc,wf}(1:2:end) - 1i*tmp_data{adc,wf}(2:2:end);
                      else
                        tmp_data{adc,wf} = tmp_data{adc,wf}(1:2:end) + 1i*tmp_data{adc,wf}(2:2:end);
                      end
                    end
                    % Found the record so break
                    missed_wf_adc = false;
                    break;
                  end
                else
                  % Unsupported radar header type, skip this record
                  break;
                end
                sub_rec_offset = sub_rec_offset + 24 + radar_header_len + radar_profile_length;
              end
          end
          
          if missed_wf_adc
            continue;
          end
          
          if quantization_to_V_adjustment ~= 1 && ~param.load.raw_data
            % Convert from quantization to voltage at the receiver input for the
            % maximum gain case:
            %  1. fast time gains less than the maximum for this record will be
            %     compensated for in the next step
            %  2. antenna effects not considered at this step
            tmp_data{adc,wf} = tmp_data{adc,wf} * quantization_to_V_adjustment;
            
          end
          
          % Accumulate (presum)
          if num_accum(ai) == 0
            state.data{ai} = tmp_data{adc,wf};
          else
            state.data{ai} = state.data{ai} + tmp_data{adc,wf};
          end
          num_accum(ai) = num_accum(ai) + 1;
        end
      end
      
      % Store to output if number of presums is met
      % num_accum: the number of good records accumulated, this will equal
      %   num_presum_records when all records load successfully. There is
      %   one entry for each wf-adc pair
      % num_presum_records: the number of records loaded
      num_presum_records = num_presum_records + 1;
      if num_presum_records >= param.load.presums
        out_rec = out_rec + 1;
        % Sum up wf-adc sum pairs until done
        for ai = 1:length(state.wf)
          % Store to output
          wf = state.wf(ai);
          img = state.img(ai);
          wf_adc = state.wf_adc(ai);
          if num_accum(ai) < num_presum_records*wfs(wf).presum_threshold ...
              || any(nyquist_zone_hw{img}(1:num_accum(ai)) ~= nyquist_zone_hw{img}(1)) ...
              || any(~isequaln(nyquist_zone_signal{img}(1:num_accum(ai)),nyquist_zone_signal{img}(1)*ones(1,num_accum(ai)))) ...
              || any(DDC_dec{img}(1:num_accum(ai)) ~= DDC_dec{img}(1)) ...
              || any(DDC_freq{img}(1:num_accum(ai)) ~= DDC_freq{img}(1)) ...
              || Nt{img}(1) <= 0 ...
              || any(Nt{img}(1:num_accum(ai)) ~= Nt{img}(1)) ...
              || any(t0{img}(1:num_accum(ai)) ~= t0{img}(1)) ...
              || any(t_ref{img}(1:num_accum(ai)) ~= t_ref{img}(1))
            % Too few presums, mark as bad record
            % Or a parameter changed within the presum block or across wf_adc_sums
            hdr.Nt{img}(out_rec) = 0;
            hdr.bad_rec{img}(1,out_rec,wf_adc) = 1;
            data{img}(:,out_rec,wf_adc) = wfs(wf).bad_value;
          else
            if size(data{img},1) < Nt{img}(1)
              % Force data output to grow to the current record size
              data{img}(end+1:Nt{img}(1),:,:) = wfs(wf).bad_value;
            end
            if ~isreal(data{img}) && ~data_complex_hack(img) && size(data{img},1) > 0
              data_complex_hack(img) = true;
              % Temporarily add an imaginary part to the first value in the
              % matrix so that Matlab will know right away that this matrix
              % is complex and won't have to search through the entire
              % matrix to find this out. We remove this value at the end of
              % the loop.
              data{img}(1) = data{img}(1) + 1i;
            end
            if state.reset_sum(ai)
              data{img}(1:Nt{img}(1),out_rec,wf_adc) = state.weight(ai)*state.data{ai} / num_accum(ai);
            else
              data{img}(1:Nt{img}(1),out_rec,wf_adc) = ...
                data{img}(1:Nt{img}(1),out_rec,wf_adc) + state.weight(ai)*state.data{ai} / num_accum(ai);
            end
            data{img}(Nt{img}(1)+1:end,out_rec,wf_adc) = wfs(wf).bad_value;
            
            hdr.nyquist_zone_hw{img}(out_rec) = nyquist_zone_hw{img}(1);
            hdr.nyquist_zone_signal{img}(out_rec) = nyquist_zone_signal{img}(1);
            hdr.DDC_dec{img}(out_rec) = DDC_dec{img}(1);
            if isfinite(wfs(wf).DDC_freq)
              hdr.DDC_freq{img}(out_rec) = wfs(wf).DDC_freq;
            else
              hdr.DDC_freq{img}(out_rec) = DDC_freq{img}(1);
            end
            hdr.Nt{img}(out_rec) = Nt{img}(1);
            hdr.t0_raw{img}(out_rec) = t0{img}(1);
            hdr.t_ref{img}(out_rec) = t_ref{img}(1);
            if any(param.records.file.version == [9])
              hdr.t_ref{img}(out_rec) = wfs(wf).t_ref;
%               hdr.t0_raw{img}(out_rec) = wfs(wf).t0_raw;
%               hdr.DDC_freq{img}(out_rec) = wfs(wf).DDC_freq;
            end
            if any(isfinite(wfs(wf).blank))
              % Blank data
              %  - Blank is larger of two numbers passed in through radar worksheet blank parameter:
              %   Number 1 is added to surface time delay and is usually equal to pulse duration
              %   Number 2 is unmodified and is usually equal to hardware blank setting
              %   Set either number to -inf to disable
              blank_time = max(records.surface(rec) + wfs(wf).blank(1),wfs(wf).blank(2));
              data{img}(wfs(wf).time_raw-param.radar.wfs(wf).Tsys(adc) <= blank_time,out_rec,state.wf_adc(ai)) = 0;
            end
          end
        end
        % Reset counters
        num_presum_records = 0; % Number of records in the presum interval
        num_accum(:) = 0; % Number of good records in the presum interval
      end
      % Increment record counter
      rec = rec + 1;
    end
  end
end
for img = 1:length(param.load.imgs)
  if data_complex_hack(img)
    data{img}(1) = data{img}(1) - 1i;
  end
end

%% Corrections
% =========================================================================
if ~param.load.raw_data
  for img = 1:length(param.load.imgs)
    for wf_adc = 1:size(data{img},3)
      wf = param.load.imgs{img}(wf_adc,1);
      adc = param.load.imgs{img}(wf_adc,2);
      
      % Apply channel compensation, presum normalization, and constant
      % receiver gain compensation
      if strcmpi(radar_type,'deramp')
        chan_equal = 1;
      else
        chan_equal = 10.^(param.radar.wfs(wf).chan_equal_dB(param.radar.wfs(wf).rx_paths(adc))/20) ...
          .* exp(1i*param.radar.wfs(wf).chan_equal_deg(param.radar.wfs(wf).rx_paths(adc))/180*pi);
      end
      
      if length(wfs(wf).system_dB) == 1
        % Only a single number is provided for system_dB so apply it to all
        % receiver paths
        mult_factor = single(wfs(wf).quantization_to_V(adc) ...
          / (10.^(wfs(wf).adc_gains_dB(adc)/20) * chan_equal ...
            * 10.^(wfs(wf).system_dB/20)));
      else
        % A number is provided for each receiver path for system_dB
        mult_factor = single(wfs(wf).quantization_to_V(adc) ...
          / (10.^(wfs(wf).adc_gains_dB(adc)/20) * chan_equal ...
            * 10.^(wfs(wf).system_dB(param.radar.wfs(wf).rx_paths(adc))/20)));
      end
      data{img}(:,:,wf_adc) = mult_factor * data{img}(:,:,wf_adc);
      
      % Compensate for receiver gain applied before ADC quantized the signal
      %  - For time varying receiver gain, the convention is to compensate
      %    to the maximum receiver gain and use the wfs(wf).gain parameter
      %    to vary the gain relative to that.
      % - IMPORTANT: Only works for radars with constant length records.
      % Apply fast-time varying gain if enabled
      if wfs(wf).gain_en
        gain_dir = ct_filename_out(param, wfs(wf).gain_dir, 'analysis',1);
        gain_fn = fullfile(gain_dir,sprintf('gain_wf_%d_adc_%d.mat',wf,adc));
        if exist(gain_fn, 'file')
          ftg = load(gain_fn);
          fprintf('Applying fast time gain compensation %d-%d\n  %s\n',wf,adc,gain_fn);
          corr_Time = ftg.param_collate_gain.radar.wfs(wf).time... % Actual Time axis
            + (ftg.param_collate_gain.radar.wfs(wf).Tadc_adjust - 1*param.radar.wfs(wf).Tadc_adjust)... % Difference in Tadc_adjust
            -1*ftg.param_collate_gain.radar.wfs(wf).time_correction;
          if 0
            figure(1);
            if img == 1 && wf_adc == 1
              clf;
            end
            plot(lp(mean(abs(data{img}(:,:,wf_adc)).^2,2)));
            grid on;
            keyboard
          end
          data{img}(:,:,wf_adc) = bsxfun(@times,data{img}(:,:,wf_adc),interp1(corr_Time, ftg.Gain_raw, wfs(wf).time_raw(1:hdr.Nt{img}(1)), 'linear','extrap'));
          if 0
            hold on;
            plot(lp(mean(abs(data{img}(:,:,wf_adc)).^2,2)));
            figure(2); clf;
            imagesc(lp(data{img}(:,:,wf_adc)));
            keyboard
          end 
        else
          error(sprintf('Fast-time Gain compensation file not found:\n  %s\nPlease run run_collate_ftg.m.',gain_fn));
        end
      end
      
      % Apply time varying channel compensation
      if ~isempty(wfs(wf).chan_equal)
        cdf_fn_dir = fileparts(ct_filename_out(param,wfs(wf).chan_equal, ''));
        cdf_fn = fullfile(cdf_fn_dir,sprintf('chan_equal_%s_wf_%d_adc_%d.nc', param.day_seg, wf, adc));
        
        finfo = ncinfo(cdf_fn);
        % Determine number of records and set recs(1) to this
        Nt = finfo.Variables(find(strcmp('chan_equal',{finfo.Variables.Name}))).Size(2);
        
        chan_equal = [];
        chan_equal.gps_time = ncread(cdf_fn,'gps_time');
        recs = find(chan_equal.gps_time > records.gps_time(1) - 100 & chan_equal.gps_time < records.gps_time(end) + 100);
        chan_equal.gps_time = chan_equal.gps_time(recs);
        
        chan_equal.chan_equal = ncread(cdf_fn,'chan_equalI',[recs(1) 1],[recs(end)-recs(1)+1 Nt]) ...
          + 1i*ncread(cdf_fn,'chan_equalQ',[recs(1) 1],[recs(end)-recs(1)+1 Nt]);
        
        data{img}(1:hdr.Nt{img}(1),:,wf_adc) = data{img}(1:hdr.Nt{img}(1),:,wf_adc) ...
          .*interp1(reshape(chan_equal.gps_time,[numel(chan_equal.gps_time) 1]),chan_equal.chan_equal,records.gps_time,'linear','extrap').';
      end
      
      % Remove burst noise
      if wfs(wf).burst.en
        % Load the burst noise file
        noise_fn_dir = fileparts(ct_filename_out(param,wfs(wf).burst.fn, ''));
        noise_fn = fullfile(noise_fn_dir,sprintf('burst_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
        fprintf('  Loading burst noise: %s (%s)\n', noise_fn, datestr(now));
        if ~exist(noise_fn,'file')
          warning('data_load:burst:missing_file', ...
            'Burst noise file not found\t%s\t%s\n', noise_fn, datestr(now,'yyyymmdd_HHMMSS'));
        else
          burst = load(noise_fn);
          % burst.burst_noise_table is created and described in
          % collate_burst_noise.m
          % ---------------------------------------------------------------
          % burst_noise_table is a 3xNb table where Nb is the number of
          % burst noise detections. Each column corresponds to one burst.
          %
          % burst_noise_table(1,:): The record that the burst occurs in.
          %
          % burst_noise_table(2,:): The start time of the burst
          %
          % burst_noise_table(3,:): The stop of the burst
          
          % start_idx to stop_idx: burst noise present in the current data
          % block
          start_idx = find(burst.burst_noise_table(1,:) >= param.load.recs(1),1);
          if ~isempty(start_idx)
            stop_idx = find(burst.burst_noise_table(1,:) <= param.load.recs(end),1,'last');
            if ~isempty(stop_idx)
              % Loop through each burst noise incident in this block of
              % data
              for idx = start_idx:stop_idx
                % Convert absolute record into relative index into loaded
                % data arrays.
                rec_rel = burst.burst_noise_table(1,idx) - param.load.recs(1) + 1;
                
                % start_bin to stop_bin: burst noise present in the current
                % record
                dt = wfs(wf).time_raw(2)-wfs(wf).time_raw(1);
                start_bin = max(1, ...
                  round((burst.burst_noise_table(2,idx)-wfs(wf).time_raw(1))/dt));
                stop_bin = min(hdr.Nt{img}(rec_rel), ...
                  round((burst.burst_noise_table(3,idx)-wfs(wf).time_raw(1))/dt));
                
                if start_bin == 1 && stop_bin == hdr.Nt{img}(rec_rel)
                  data{img}(:,rec_rel,wf_adc) = wfs(wf).bad_value;
                  hdr.bad_rec{img}(1,rec_rel,wf_adc) = 1;
                elseif start_bin <= hdr.Nt{img}(rec_rel) && stop_bin >= 1
                  data{img}(start_bin:stop_bin,rec_rel,wf_adc) = wfs(wf).bad_value;
                end
              end
            end
          end
          
        end
      end % End burst noise removal
      
    end
  end
end

%% Add record information
% =========================================================================
hdr.gps_source = records.gps_source;
hdr.gps_time = fir_dec(records.gps_time,param.load.presums);
hdr.surface = fir_dec(records.surface,param.load.presums);

%% Create trajectories
% =========================================================================

% Create reference trajectory (rx_path == 0, tx_weights = [])
trajectory_param = struct('gps_source',records.gps_source, ...
  'season_name',param.season_name,'radar_name',param.radar_name,'rx_path', 0, ...
  'tx_weights', [], 'lever_arm_fh', param.radar.lever_arm_fh);
hdr.ref = trajectory_with_leverarm(records,trajectory_param);

for img = 1:length(param.load.imgs)
  
  for wf_adc = 1:size(param.load.imgs{img},1)
    wf = param.load.imgs{img}(wf_adc,1);
    adc = param.load.imgs{img}(wf_adc,2);
    
    if isempty(param.radar.lever_arm_fh)
      hdr.records{img,wf_adc} = records;
      hdr.records{img,wf_adc}.lat = fir_dec(records.lat,param.load.presums);
      hdr.records{img,wf_adc}.lon = fir_dec(records.lon,param.load.presums);
      hdr.records{img,wf_adc}.elev = fir_dec(records.elev,param.load.presums);
      hdr.records{img,wf_adc}.roll = fir_dec(records.roll,param.load.presums);
      hdr.records{img,wf_adc}.pitch = fir_dec(records.pitch,param.load.presums);
      hdr.records{img,wf_adc}.heading = fir_dec(records.heading,param.load.presums);
    else
      % Create actual trajectory
      trajectory_param = struct('gps_source',records.gps_source, ...
        'season_name',param.season_name,'radar_name',param.radar_name, ...
        'rx_path', wfs(wf).rx_paths(adc), ...
        'tx_weights', wfs(wf).tx_weights, 'lever_arm_fh', param.radar.lever_arm_fh);
      hdr.records{img,wf_adc} = trajectory_with_leverarm(records,trajectory_param);
      hdr.records{img,wf_adc}.lat = fir_dec(hdr.records{img,wf_adc}.lat,param.load.presums);
      hdr.records{img,wf_adc}.lon = fir_dec(hdr.records{img,wf_adc}.lon,param.load.presums);
      hdr.records{img,wf_adc}.elev = fir_dec(hdr.records{img,wf_adc}.elev,param.load.presums);
      hdr.records{img,wf_adc}.roll = fir_dec(hdr.records{img,wf_adc}.roll,param.load.presums);
      hdr.records{img,wf_adc}.pitch = fir_dec(hdr.records{img,wf_adc}.pitch,param.load.presums);
      hdr.records{img,wf_adc}.heading = fir_dec(hdr.records{img,wf_adc}.heading,param.load.presums);
    end
    hdr.records{img,wf_adc}.offset = hdr.records{img,wf_adc}.offset(:,1:param.load.presums:end-param.load.presums+1);
    hdr.records{img,wf_adc} = rmfield(hdr.records{img,wf_adc},{'gps_time','surface'});
  end
end

