function [img_time,img_valid_rng,img_deconv_filter_idx,img_freq,img_Mt,img_nyquist_zone] = load_fmcw_data(param,records)
% [img_time,img_valid_rng,img_deconv_filter_idx,img_freq] = load_fmcw_data(param,records)
%
% Loads and pulse compresses the FMCW data for functions like
%   get_heights_task and csarp_task
%
% param = struct controlling the loading and processing
% records = records struct with "gps_time" GPS time vector and "elev"
%   WGS-84 elevation vector
%
% Outputs:
% a_data = [global variable] cell vector containing 3-D matrices which
%   contain Nt by Nx by Nc data (time, along-track, cross-track channels)
% img_time = cell vector containing the fast-time axis for each image
% valid_rng = cell vector for each image: 2 by Nx matrix indicating
%   the first and last range bin that is valid
% deconv_filter_idx: cell vector for each image: 1 by Nx vector with the
%   deconvolution GPS time specified
% img_freq = cell vector containing the fast-time frequency axis for each image
% img_Mt = cell vector containing the decimation number by DDC_filter:1 by Nx vector

global g_data;
physical_constants;

load_fmcw_data_tstart = tic;

accum = build_img_load_struct(param.load.imgs, param.load.adcs, struct('file_version',param.load.file_version));

if ~isfield(param.proc,'deconvolution') || isempty(param.proc.deconvolution)
  param.proc.deconvolution = 0;
end
if param.proc.deconvolution == 3
  out_fn_dir = ct_filename_out(param,'analysis');
  out_segment_fn_dir = fileparts(out_fn_dir);
  out_segment_fn = fullfile(out_segment_fn_dir,sprintf('deconv_%s.mat', param.day_seg));
  spec = load(out_segment_fn);
  
  if ~isequal(param.proc.ft_wind,spec.param_collate.get_heights.ft_wind)
    error('get_heights ft_wind does not match ft_wind when deconv_collate was run', ...
      func2str(param.proc.ft_wind),func2str(spec.param_collate.get_heights.ft_wind));
  end
  % Force ft_wind to match what was done during coh_noise_tracker run
  % which produced the deconv filter.  The deconv filter is taken
  % relative to this window so for deconvolution to work, it must match
  % here. Note that any new window can be applied inside the deconv filter
  % by running collate_deconv with the desired window.
  param.proc.ft_wind = spec.param_analysis.get_heights.ft_wind;
  
elseif param.proc.deconvolution ~= 0
  error('Unsupported deconvolution value %d', param.proc.deconvolution);
end

if ~isfield(param.proc,'deconvolution_metric') || isempty(param.proc.deconvolution_metric)
  param.proc.deconvolution_metric = false;
end

if ~isfield(param.proc,'elev_correction') || isempty(param.proc.elev_correction)
  param.proc.elev_correction = false;
end

if ~isfield(param.proc,'psd_smooth') || isempty(param.proc.psd_smooth)
  param.proc.psd_smooth = false;
end

%% Preallocate data matrix
total_rec = length(param.load.file_idx{1});
Nx = floor(total_rec/param.proc.presums);
if ~iscell(g_data)
  g_data = cell(size(param.load.imgs));
end
for img_idx = 1:length(param.load.imgs)
  wf = abs(param.load.imgs{img_idx}(1,1));
  Nt = 0;
  if param.proc.combine_rx
    Nc = 1;
  else
    Nc = size(param.load.imgs{img_idx},1);
  end
  g_data{img_idx} = zeros(Nt,Nx,Nc,'single');
end

%% Load Data: Loop through each board and each wf-adc pair
% =======================================================================
boards = param.load.adcs;
for board_idx = 1:length(boards)
  board = boards(board_idx);
  
  for accum_idx = 1:length(accum(board).wf)
    adc = accum(board).adc(accum_idx);
    wf = accum(board).wf(accum_idx);
    img_idx = accum(board).img_idx(accum_idx);
    wf_adc_idx = accum(board).wf_adc_idx(accum_idx);
    iq_mode = accum(board).iq_mode(accum_idx);
    
    total_recs = param.load.recs(2)-param.load.recs(1)+1;
    DDC_or_raw_select = ones(1,total_recs); % Default is raw (not complex) data
    Mt = ones(1,total_recs); % Default is raw (not complex) data
    DDC_filter_select = zeros(1,total_recs);
    start_idx = zeros(1,total_recs);
    num_sam = zeros(1,total_recs);
    time_offset = zeros(1,total_recs);
    nyquist_zone = zeros(1,total_recs);
    waveform_ID = char(zeros(8,total_recs));
    presums = zeros(1,total_recs);
    bit_shifts = zeros(1,total_recs);
    NCO_freq = zeros(1,total_recs);
    rline = 0;
    a_data = zeros(1,Nx,'single');
    
    for file_idx = unique(param.load.file_idx{adc})
      % Load the records one file at a time
      fn = param.load.filenames{adc}{file_idx};
      
      fprintf('  Load %s (%s)\n', fn, datestr(now));
      
      if param.load.file_version == 1
        %% File Version 1: John Ledford and Carl Leuschen 1U-DAQ system
        % Open file
        [fid,msg] = fopen(fn,'r','ieee-be');
        if fid < 1
          fprintf('Could not open file %s\n', fn);
          error(msg);
        end
        
        % Read in records
        HEADER_SIZE = 7*4; % in bytes
        WF_HEADER_SIZE = 0*4; % in bytes
        num_sam(:) = param.wfs(wf).num_sam;
        presums(:) = param.wfs(wf).presums;
        nyquist_zone(:) = param.wfs(wf).nyquist_zone;
        bit_shifts(:) = 0;
        % Read in records
        for offset = param.load.offset{adc}(param.load.file_idx{adc} == file_idx)
          rline = rline + 1;
          fseek(fid,offset + HEADER_SIZE + WF_HEADER_SIZE,-1);
          a_data(1:num_sam(rline),rline) = fread(fid,num_sam(rline),'uint16=>single');
        end
        % Close file
        fclose(fid);
        
      elseif param.load.file_version == 2 || param.load.file_version == 4
        %% File Version 2 and 4: Carl Leuschen's First NI system
        % Open file
        [fid,msg] = fopen(fn,'r','ieee-be');
        if fid < 1
          fprintf('Could not open file %s\n', fn);
          error(msg);
        end
        
        % Read in records
        HEADER_SIZE = 8*4; % in bytes
        WF_HEADER_SIZE = 2*4; % in bytes
        % Read in records
        for offset = param.load.offset{adc}(param.load.file_idx{adc} == file_idx)
          rline = rline + 1;
          fseek(fid,offset + 34,-1);
          presums(rline) = fread(fid,1,'uint8') + 1;
          bit_shifts(rline) = fread(fid,1,'uint8');
          start_idx(rline) = fread(fid, 1, 'uint16');
          stop_idx = fread(fid,1,'uint16');
          num_sam(rline) = stop_idx - start_idx(rline);
          a_data(1:num_sam(rline),rline) = fread(fid,num_sam(rline),'int16=>single');
          if param.records.nohack
              continue
          else
              fseek(fid,WF_HEADER_SIZE,0);
              a_data(:,rline) = a_data(:,rline) + fread(fid,num_sam(rline),'int16=>single');
          end
        end
        % Close file
        fclose(fid);
        
        nyquist_zone(:) = param.radar.wfs.nyquist_zone;
        
      elseif any(param.load.file_version == [3 5 7])
        %% File Version 3,5,7: Carl Leuschen's DDC and FIRDEC digital NI system
        % Open file
        [fid,msg] = fopen(fn,'r','ieee-be');
        if fid < 1
          fprintf('Could not open file %s\n', fn);
          error(msg);
        end
        
        % Read in records
        for offset = param.load.offset{adc}(param.load.file_idx{adc} == file_idx)
          rline = rline + 1;
          % To determine size of data record we need and the time offset:
          % 34: presums
          % 35: bit shifts
          % 36: start index
          % 38: stop index
          % 42: NCO frequency step size
          % 44: nyquist zone (external filter select)
          % 45: DDC filter select
          % 47: DDC_or_raw_select
          % IF signal is recorded by the ADC at param.wfs(wf).fs_raw
          %   The IF is related to propagation delay,td, by:
          %     f_if_unaliased = abs(param.wfs(wf).chirp_rate) * td
          %   Accounting for the Nyquist zone and aliasing (f_if goes from 0 to
          %   62.5, back down to 0, backup to 62.5, back down to 0, etc):
          %     Even nyquist_zone = 0,2,4,...
          %     f_if = abs(param.wfs(wf).chirp_rate) * td - nyquist_zone/2*param.wfs(wf).fs_raw
          %     Odd nyquist_zone = 1,3,5,...
          %     f_if = param.wfs(wf).fs_raw/2 - abs(param.wfs(wf).chirp_rate) * td + nyquist_zone/2*param.wfs(wf).fs_raw
          % Solving for td:
          %   Even NZ:
          %   td = (f_if + nyquist_zone/2*param.wfs(wf).fs_raw) / abs(param.wfs(wf).chirp_rate)
          %   Odd NZ:
          %   td = ((nyquist_zone+1)/2*param.wfs(wf).fs_raw - f_if) / abs(param.wfs(wf).chirp_rate)
          % f_if spectrum for raw is from fft(data_raw) and taking bottom half of samples:
          %   freq = df*(0:ceil(Nt/2)-1);
          % f_if_DDC spectrum for DDC is from fftshift(fft(data_DDC)):
          %   freq = NCO_freq + df*(-floor(Nt/2):floor((Nt-1)/2))
          % Digital down conversion moves the digital f_if to DC (it is
          % possible that the NCO chooses the wrong side of the spectrum in
          % which case the spectrum will be flipped... need to handle this)
          %   NCO varies from 0 to fs (assumes 2^15 phase table lookup and
          %   NCO_freq_step values from 0 to 2^16-1)
          % Frame 7 has aliasing... so alias midpoint is either fs or fs/2?
          % Frame 12 has aliasing w/ cross over and split view
          % Frame 13 has aliasing w/ cross over and split view and DC is clear
          %   at the the alias midpoint
          fseek(fid,offset + 34,-1);
          
          % Currently we use only the first waveform header
          presums(rline) = fread(fid,1,'uint8') + 1;
          bit_shifts(rline) = -fread(fid,1,'int8');
          start_idx(rline) = fread(fid,1,'uint16');
          stop_idx = fread(fid,1,'uint16');
          fseek(fid,-6,0);
          
          % Skip to the correct waveform
          skip_wf = wf-1;
          while skip_wf > 0
            fseek(fid,2,0);
            start_idx(rline) = fread(fid,1,'uint16');
            stop_idx = fread(fid,1,'uint16');
            fseek(fid,5,0);
            DDC_filter_select(rline) = fread(fid,1,'uint8');
            fseek(fid,1,0);
            DDC_or_raw_select(rline) = fread(fid,1,'uint8');
            if DDC_or_raw_select(rline)
              % Raw/real data
              num_sam(rline) = stop_idx - start_idx(rline);
              fseek(fid,num_sam(rline)*2 + 34,0);
            else
              % DDC/complex data
              num_sam(rline) = floor(((stop_idx - start_idx(rline)) ./ 2.^(1+DDC_filter_select(rline))));
              fseek(fid,num_sam(rline)*4 + 34,0);
            end
            skip_wf = skip_wf - 1;
          end
          fseek(fid,6,0);
          
          fseek(fid,2,0);
          NCO_freq_step(rline) = fread(fid,1,'uint16');
          if param.load.file_version == 3
            NCO_freq(rline) = NCO_freq_step(rline) / 2^15 * param.wfs(wf).fs_raw * 2 - 62.5e6;
          elseif any(param.load.file_version == [5 7])
            NCO_freq(rline) = NCO_freq_step(rline) / 2^15 * param.wfs(wf).fs_raw * 2;
          end
          time_offset(rline) = NCO_freq(rline) / abs(param.wfs(wf).chirp_rate);
          nyquist_zone(rline) = fread(fid,1,'uint8');
          if nyquist_zone(rline) < 2
            % Switch zones 0 and 1 due to a hardware bug (Mar 15, 2013 only)
            %nyquist_zone(rline) = ~nyquist_zone(rline);
          end
          if param.load.file_version == 3
            DDC_filter_select(rline) = fread(fid,1,'uint8') + 1;
          else
            DDC_filter_select(rline) = fread(fid,1,'uint8');
          end
          fseek(fid,1,0);
          if param.load.file_version == 3
            DDC_or_raw_select(rline) = fread(fid,1,'uint8');
          else
            DDC_or_raw_select(rline) = fread(fid,1,'uint8');
            if DDC_or_raw_select(rline) == 1
              DDC_or_raw_select(rline) = 0;
              DDC_filter_select(rline) = DDC_filter_select(rline) - 1;
            end
          end
          
          if DDC_or_raw_select(rline)
            % Raw/real data
            num_sam(rline) = stop_idx - start_idx(rline);
            Mt(rline) = 1;
          else
            % DDC/complex data
            num_sam(rline) = floor(((stop_idx - start_idx(rline)) ./ 2.^(1+DDC_filter_select(rline))));
            Mt(rline) = 2.^(1+DDC_filter_select(rline));
          end
          
          if num_sam(rline) > size(a_data,1)
            % Force a_data to grow to accomodate this new range line
            a_data(num_sam(rline),1) = 0;
            if rline>1 && isfield(param.proc,'coh_noise_tracker') && param.proc.coh_noise_tracker
              a_data(:,1:rline-1) = interp1([1:num_sam(rline-1)]',a_data(1:num_sam(rline-1),1:rline-1),linspace(1,num_sam(rline-1),num_sam(rline))');
            end
            interp_flag = 0;
          end
          if num_sam(rline)< size(a_data,1)
            % DDC_filter changed and num_sam reduced, need interpolation to
            % keep the same number of samples for coherent noise tracker
            if isfield(param.proc,'coh_noise_tracker') && param.proc.coh_noise_tracker
              interp_flag = 1;
            end
          end
          
          if DDC_or_raw_select(rline)
            % Raw/real data
            a_data(1:num_sam(rline),rline) = fread(fid,num_sam(rline),'int16=>single');
            a_data(1:num_sam(rline),rline) = a_data(reshape([2:2:num_sam(rline);1:2:num_sam(rline)-1],[num_sam(rline) 1]),rline);
          else
            % DDC/complex data
            DDC_radiometric_correction_hack = 1/10*2^(DDC_filter_select(rline)-1);
            data = fread(fid,2*num_sam(rline),'int16=>single')*DDC_radiometric_correction_hack;
            if length(data) < 2*num_sam(rline)
              data(2*num_sam(rline)) = 0;
            end
            a_data(1:num_sam(rline),rline) = data(1:2:end) + 1i*data(2:2:end);
          end
          if interp_flag
            a_data(:,rline) = interp1([1:num_sam(rline)],a_data(1:num_sam(rline),rline),linspace(1,num_sam(rline),size(a_data,1)));
            interp_flag = 0;
          end
        end
        
      elseif any(param.load.file_version == [8])
        %% File Version 8: Carl Leuschen's Keysight + NI system
        % Open file
        [fid,msg] = fopen(fn,'r','ieee-be');
        if fid < 1
          fprintf('Could not open file %s\n', fn);
          error(msg);
        end
        
        % Read in records
        for offset = param.load.offset{adc}(param.load.file_idx{adc} == file_idx)
          rline = rline + 1;
          % To determine size of data record we need and the time offset:
          % 33: nyquist zone (external filter select)
          % 34: presums
          % 35: bit shifts
          % 36: start index
          % 38: stop index
          % 40: waveform ID
          fseek(fid,offset + 33,-1);
          
          % Currently we use only the first waveform header
          nyquist_zone(rline) = fread(fid,1,'uint8');
          presums(rline) = fread(fid,1,'uint8') + 1;
          bit_shifts(rline) = -fread(fid,1,'int8');
          start_idx(rline) = fread(fid,1,'uint16');
          stop_idx = fread(fid,1,'uint16');
          waveform_ID(:,rline) = char(fread(fid,8,'uint8')).';
          num_sam(rline) = 2*(stop_idx - start_idx(rline));
          
          % Raw/real data
          a_data(1:num_sam(rline),rline) = fread(fid,num_sam(rline),'int16=>single');
        end
        % Close file
        fclose(fid);
        % Frame 13:
        %  752.55 ns system delay (approximate)
        %  Subtract 62.5 MHz from corrected frequency
        %
        %  range = 40+[666 682] --> [111.4800  114.1500] MHz --> 2.67 MHz
        %  [1100 720] --> [4.2 2.75] MHz assuming sample frequency of 31.25 MHz
        %  --> 1.45 MHz difference
        %  1.45 + 2.67 = 4.12 MHz predicted from surface shift
        % --> NCO_freq increased by 2.06 MHz... exactly half of what it should
        % be
        %
        %  DC:
        %  [4144.5 3067] --> 4.12 MHz predicted from DC, [15.840 11.7200] MHz
        %  [22500 23040] -->
        %
        % Expect frequencies [111.4800  114.1500] MHz
        % Measured [4.2 2.75] MHz
        % Expect [125 125]
        % Measured [15.8400   11.7200] MHz
        % NCO shift is [171.66 175.78] MHz
        %
        % 109.1600  113.2800
        % NCO frequency: [1066 1174] or [22500 23040]
        %
        % Decimation rate: 62.5 MHz
        % Chirp rate
        %  Frame 13, block 1: 666 to 682 m = 4.44-4.55 us = 107.8 MHz
        % DC is showing up at 99.32 MHz (should be 125 MHz) = 25.7 MHz error
        % df = 1/(8175*4/125e6)
        % Sample clock of the DDS is: ?
        % ADC sample clock is: ?
        %    Chirp rate conversion:
        %    f0:
        %    f1:
        %    fmult:
        %    Tpd:
        
        % rec_load_offset: This is the relative record number of this particular call to
        % load_fmcw_data
      else
        error('File version %d not supported\n');
      end
    end
    
    if param.load.file_version == 1
      % Each pair of samples are flipped around, so we fix that here
      a_data = a_data(reshape([2:2:end;1:2:end-1],[size(a_data,1) 1]),:);
    end
    
    %% Remove digital burst errors in old radar system
    % =======================================================================
    if param.load.file_version == 1
      % Discard bad bins at the end of the record
      a_data = a_data(1:end-8,:); % Discard bad bins at the end of the record
      num_sam = num_sam - 8;
      
      % Remove digital error bursts
      %  Probably should make these values programmable from spreadsheet, not
      %  sure if they are always 2560, 2816, 3584, 3840, or 0
      %  These values were found by noting vertical streaks in the output
      %  products caused by the digital burst errors, running "plot(min(a_data))"
      %  at this stage to identify records with the burst errors and then
      %  plot(a_data(:,RECORD)) to find the specific values.
      test_idxs = find(a_data(:) == 0).';
      for test_idx_idx = 1:length(test_idxs)
        test_idx = test_idxs(test_idx_idx);
        if test_idx > 3
          a_data(test_idx+[-3 0]) ...
            = 2^(param.radar.adc_bits-1)*presums(1)/2^bit_shifts(1);
        end
      end
      %plot(min(a_data)); keyboard; % debugging burst errors
    end
    
    
    %% Determine the samples to use in the FFT
    % =======================================================================
    
    if isfield(records.settings,'nyquist_zone')
      nyquist_zone = records.settings.nyquist_zone;
    elseif ~isempty(param.radar.wfs(wf).nyquist_zone)
      nyquist_zone(:) = param.radar.wfs(wf).nyquist_zone;
    end
    if ~isfield(param.radar.wfs(wf),'IF_trim') || isempty(param.radar.wfs(wf).IF_trim)
      IF_trim = 0.5e6;
    else
      IF_trim = param.radar.wfs(wf).IF_trim;
    end
    if ~isfield(param.radar.wfs(wf),'max_nz') || isempty(param.radar.wfs(wf).max_nz)
      max_nz = 3;
    else
      max_nz = param.radar.wfs(wf).max_nz;
    end
    
    t_origin = 0;
    fs_raw = param.wfs(wf).fs_raw ./ Mt;
    
    % Parameters that effect good range bins:
    %  nyquist_zone: because of the max delay and deramp skew, by using
    %    the max delay on everything it should remove effects of changing
    %    nyquist zone
    %  chirp_rate: FIXED
    %  fs: should not affect except for rounding errors (a change in
    %      the decimation rate may lead to a slightly shorter time gate
    %      due to time gate truncation by rounding)
    %      Recompute the number of samples at fs_raw and then truncate
    %      according to that.
    %  start_idx: should not change
    %  num_sam: should only change due to DDC filter select
    %  t_origin: start of transmit, should not change
    %  Tpd: pulse duration, should not change
    
    % =======================================================================
    if any(nyquist_zone > max_nz)
      warning('Invalid Nyquist zone (greater than %d), resetting to NZ %d or %d', max_nz, max_nz-1, max_nz);
      if mod(max_nz,2)
        % Max NZ is odd
        nyquist_zone(nyquist_zone > max_nz & ~mod(nyquist_zone,2)) = max_nz-1; % Desired NZ is even
        nyquist_zone(nyquist_zone > max_nz & mod(nyquist_zone,2)) = max_nz; % Desired NZ is odd
      else
        % Max NZ is even
        nyquist_zone(nyquist_zone > max_nz & ~mod(nyquist_zone,2)) = max_nz; % Desired NZ is even
        nyquist_zone(nyquist_zone > max_nz & mod(nyquist_zone,2)) = max_nz-1; % Desired NZ is odd
      end
    end
    
    % =======================================================================
    if ~isempty(param.radar.wfs(wf).record_start_idx)
      % Override start index in the data file
      start_idx = param.radar.wfs(wf).record_start_idx; % Start recording index set in radar control software
    else
      start_idx = start_idx(1);
    end
    
    % =======================================================================
    % Time gate length (determines number of valid samples recorded
    T = min(num_sam ./ fs_raw);
    
    % =======================================================================
    % Determines maximum time gate that is possible... all FFT's will be done
    % with this many points (technically divided by Mt) so that the resulting
    % time step after the FFT is constant regardless of the settings
    max_valid_Mt = 16;
    max_range_delay = max(param.wfs(wf).fs_raw/2 .* (0+1) / abs(param.wfs(wf).chirp_rate));
    start_bin = max(0, ceil((t_origin + max_range_delay)*min(param.radar.fs/max_valid_Mt) - start_idx/max(max_valid_Mt))) * max(max_valid_Mt);
    stop_bin = min(round(T*min(param.radar.fs/max_valid_Mt)), floor((param.wfs(wf).Tpd - max_range_delay)*min(param.radar.fs/max_valid_Mt) - start_idx/max(max_valid_Mt))) * max(max_valid_Mt);
    standard_Nt = (stop_bin - start_bin) ./ Mt;
    
    % =======================================================================
    % Determines allowed time gate in range bins of the max sampling
    % frequency (i.e. no decimation)
    max_range_delay = max(param.wfs(wf).fs_raw/2 .* (nyquist_zone+1) / abs(param.wfs(wf).chirp_rate));
    start_bin = max(0, ceil((t_origin + max_range_delay)*min(fs_raw) - start_idx/max(Mt))) * max(Mt);
    stop_bin = min(round(T*min(fs_raw)), floor((param.wfs(wf).Tpd - max_range_delay)*min(fs_raw) - start_idx/max(Mt))) * max(Mt);
    start_bin = ceil(start_bin/max_valid_Mt)*max_valid_Mt;
    stop_bin = floor(stop_bin/max_valid_Mt)*max_valid_Mt;

    %% Process reduced bandwidth mode
    % =======================================================================
    if isfield(param.radar.wfs,'rbw_f0') && ~isempty(param.radar.wfs.rbw_f0)
      % rbw_f0 and rbw_f1 radar worksheet fields.
      
      % Assume IF data collection is centered on the center frequency of the
      % nominal transmission.
      Nt = stop_bin - start_bin;
      freq = (param.wfs(wf).fc + param.wfs(wf).chirp_rate / param.wfs(wf).fs_raw * ((0:Nt-1) - floor(Nt/2))).';
      % Create a mask of the frequencies falling within the rbw frequency range
      good_mask = freq >= param.radar.wfs.rbw_f0 & freq <= param.radar.wfs.rbw_f1;
      % Update start and stop bins
      start_bin = start_bin + find(good_mask,1)-1;
      stop_bin = stop_bin - (length(good_mask)-find(good_mask,1,'last'));
      % Clear temporary variables
      clear good_mask freq Nt;
    end
    
    %% Remove unused/bad range bins
    % =======================================================================
    for rline = 1:size(a_data,2)
      % Determine time gate for this range line
      if isempty(param.radar.wfs(wf).good_rbins)
        good_rbins(1) = 1 + start_bin/Mt(rline);
        good_rbins(2) = stop_bin/Mt(rline);
      else
        good_rbins(1) = 1 + max(start_bin,param.radar.wfs(wf).good_rbins(1))/Mt(rline);
        good_rbins(2) = min(stop_bin,param.radar.wfs(wf).good_rbins(2))/Mt(rline);
      end
      
      num_sam(rline) = diff(good_rbins)+1;
      a_data(1:num_sam(rline),rline,:) = a_data(good_rbins(1):good_rbins(2),rline,:);
      a_data(num_sam(rline)+1:end,rline) = 0;
    end
    % Clear temporary variables
    clear good_rbins
    
    %% Convert from quantization to voltage @ ADC
    % =======================================================================
    for rline = 1:size(a_data,2)
      quantization_to_V ...
        = param.radar.Vpp_scale * 2^bit_shifts(rline) ...
        / (2^param.radar.adc_bits*presums(rline));
      if ~DDC_or_raw_select(rline)
        % There is no DC component in the DDC (the RF input DC has been mixed
        % to the NCO_freq and is removed by the clip off bad IF freq code)
        a_data(:,rline,:) = a_data(:,rline,:) * quantization_to_V;
      else
        a_data(1:num_sam(rline),rline,:) = bsxfun(@minus,a_data(1:num_sam(rline),rline,:), ...
          mean(a_data(1:num_sam(rline),rline,:),1)) * quantization_to_V;
      end
    end
    % Clear temporary variables
    clear quantization_to_V;
    
    %% Return now if pulse compression is not enabled
    % =======================================================================
    if ~param.proc.pulse_comp
      img_time{1} = [];
      img_valid_rng{1} = [];
      img_deconv_filter_idx{1} = [];
      img_freq{1} = [];
      img_Mt{1} = [];
      img_nyquist_zone{1} = nyquist_zone;
      g_data{img_idx} = a_data;
      return;
    end
    
    %% Apply coherent noise removal from analysis.coh_noise/collage_coh_noise
    % =======================================================================
    if any(param.proc.coh_noise_method == [17 19])
      % Use coh_noise_tracker results to remove coherent noise, must run collate_coh_noise.m first
      % param.proc.coh_noise_arg{1} = polynomial order of sgolayfilt
      % param.proc.coh_noise_arg{2} = frame size for sgolayfilt
      % param.proc.coh_noise_arg{3} = frame window for sgolayfilt
      % param.proc.coh_noise_arg{4} = string for cdf directory, the ? in "CSARP_?"
      
      cdf_fn_dir = fileparts(ct_filename_out(param,param.proc.coh_noise_arg{4}));
      cdf_fn = fullfile(cdf_fn_dir,sprintf('coh_noise_simp_%s.nc', param.day_seg));
      
      finfo = ncinfo(cdf_fn);
      % Determine number of records and set recs(1) to this
      Nt = finfo.Variables(find(strcmp('coh_aveI',{finfo.Variables.Name}))).Size(2);
      
      noise = [];
      noise.gps_time = ncread(cdf_fn,'gps_time');
      recs = find(noise.gps_time > records.gps_time(1) - 100 & noise.gps_time < records.gps_time(end) + 100);
      noise.gps_time = noise.gps_time(recs);
      
      noise.coh_ave = ncread(cdf_fn,'coh_aveI',[recs(1) 1],[recs(end)-recs(1)+1 Nt]) ...
        + j*ncread(cdf_fn,'coh_aveQ',[recs(1) 1],[recs(end)-recs(1)+1 Nt]);
      
      if param.proc.coh_noise_method == 19
        noise.doppler_weights = ncread(cdf_fn,'doppler_weights');
      end
      
      if param.proc.coh_noise_method == 17 || noise.doppler_weights(1) == 1
        if size(noise.coh_ave,2) ~= size(a_data,1)
          coh_ave_interp = interp1(reshape(noise.gps_time,[numel(noise.gps_time) 1]),ifft(noise.coh_ave,[],2),records.gps_time,'linear','extrap').';
          a_data = a_data ...
            - interp1([1:size(coh_ave_interp,1)],coh_ave_interp,linspace(1,size(coh_ave_interp,1),size(a_data,1)));
        else
          a_data = a_data ...
            - interp1(reshape(noise.gps_time,[numel(noise.gps_time) 1]),ifft(noise.coh_ave,[],2),records.gps_time,'linear','extrap').';
        end
      end
      if param.proc.coh_noise_method == 19
        doppler_weights = interp1(0:numel(noise.doppler_weights)-1,noise.doppler_weights,linspace(0,numel(noise.doppler_weights)-1,size(a_data,2)));
        a_data = ifft(fft(a_data,[],2).*repmat(doppler_weights,[size(a_data,1),1]), [], 2);
      end
    end
    
    %% Pulse compress
    % =======================================================================
    fprintf('  Pulse compression (%.1f sec)\n', toc(load_fmcw_data_tstart));
    
    dt_raw = 1./fs_raw;
    start_time = zeros(1,size(a_data,2));
    for rline = 1:size(a_data,2)
      if ~DDC_or_raw_select(rline) % DDC enabled
        %% Pulse compress: Window and matched filter (FFT)
        a_data(1:standard_Nt(rline),rline,:) ...
          = fftshift(fft(a_data(1:num_sam(rline),rline,:) ...
          .* repmat(param.proc.ft_wind(num_sam(rline)),[1,1,size(a_data,3)]), standard_Nt(rline)));
        
        % Using standard Nt so that time bins always line up regardless of operation mode
        num_sam(rline) = standard_Nt(rline);
        T_raw(rline)= num_sam(rline).*dt_raw(rline); % Period of raw data collection
        df_raw(rline) = 1./T_raw(rline); % IF frequency sample spacing
        
        %% Pulse compress: Create IF frequency axis (freq_raw)
        if 0
          % NCO tracking altitude:
          freq_raw = NCO_freq(rline) + df_raw(rline)*(-floor(num_sam(rline)/2):floor((num_sam(rline)-1)/2));
        else
          % Generalized code for handling any NCO tracking method???
          
          % Convert NCO_freq to Nyquist zone that target is in
          zone_offset = floor((NCO_freq(rline) - nyquist_zone(rline)*param.wfs(wf).fs_raw/2) / param.wfs(wf).fs_raw);
          test = NCO_freq(rline) - zone_offset*param.wfs(wf).fs_raw;
          if test >= nyquist_zone(rline)*param.wfs(wf).fs_raw/2 && test <= (nyquist_zone(rline)+1)*param.wfs(wf).fs_raw/2 %&& ...
            %          ~strcmp(param.load.season_name,'2013_Antarctica_P3')
            %        % Operator tracked image which is not flipped
            NCO_freq(rline) = test;
            freq_raw = NCO_freq(rline) + df_raw(rline)*(-floor(num_sam(rline)/2):floor((num_sam(rline)-1)/2));
          else
            % Operator tracked image that is flipped
            % Find NCO_freq image
            NCO_freq(rline) = -(NCO_freq(rline) - round(NCO_freq(rline) / param.wfs(wf).fs_raw) * param.wfs(wf).fs_raw);
            % Convert NCO_freq to Nyquist zone
            zone_offset = floor((NCO_freq(rline) - nyquist_zone(rline)*param.wfs(wf).fs_raw/2) / param.wfs(wf).fs_raw);
            NCO_freq(rline) = NCO_freq(rline) - zone_offset*param.wfs(wf).fs_raw;
            % Flip the data
            a_data(1:num_sam(rline),rline) = a_data(num_sam(rline):-1:1,rline);
            % Create a flipped version of the flipped frequency axis (to go
            % with the newly flipped data
            freq_raw = NCO_freq(rline) + df_raw(rline)*(-floor((num_sam(rline)-1)/2):floor(num_sam(rline)/2));
          end
          time_offset(rline) = NCO_freq(rline) / abs(param.wfs(wf).chirp_rate);
        end
        %% Pulse compress: Trim off aliased IF frequencies
        bad_if_freq_mask = logical(zeros(size(a_data,1),1));
        bad_if_freq_mask(1:num_sam(rline)) = logical(freq_raw < nyquist_zone(rline)*param.wfs(wf).fs_raw/2+IF_trim ...
          | freq_raw > (nyquist_zone(rline)+1)*param.wfs(wf).fs_raw/2-IF_trim);
        
        a_data(bad_if_freq_mask,rline) = 0;
      else % No DDC (Raw)
        %% Pulse compress: Window and matched filter (FFT)
        a_data(1:standard_Nt(rline),rline,:) ...
          = fft(a_data(1:num_sam(rline),rline,:) ...
          .* repmat(param.proc.ft_wind(num_sam(rline)),[1,1,size(a_data,3)]), standard_Nt(rline));
        
        num_sam(rline) = standard_Nt(rline);
        T_raw(rline)= num_sam(rline).*dt_raw(rline); % Period of raw data collection
        df_raw(rline) = 1./T_raw(rline); % IF frequency sample spacing
        fs_raw(rline) = fs_raw(rline)/2; % Offset video of real-only data (throw away conjugate)
        if mod(nyquist_zone(rline),2)
          % Odd Nyquist zone so use the upper half of the spectrum
          old_num_sam = num_sam(rline);
          num_sam(rline) = floor(num_sam(rline)/2);
          a_data(1:num_sam(rline),rline) = a_data(old_num_sam-num_sam(rline)+1:old_num_sam,rline);
        else
          num_sam(rline) = ceil(num_sam(rline)/2);
        end
        %% Pulse compress: Create IF frequency axis (freq_raw)
        freq_raw = param.wfs(wf).fs_raw*nyquist_zone(rline)/2 ...
          + df_raw(rline)*(0 : num_sam(rline)-1) + df_raw(rline)/2*mod(num_sam(rline),2);
      end
      
      start_time(rline) = freq_raw(1)/abs(param.wfs(wf).chirp_rate) - param.radar.wfs(wf).Tsys;
    end
    
    %% Align each range line in fast-time
    % =======================================================================
    
    fprintf('  Fast time alignment (%.1f sec)\n', toc(load_fmcw_data_tstart));
    
    fs = abs(param.wfs(wf).chirp_rate) * num_sam ./ fs_raw;
    dt = 1/fs(1);
    
    start_time_new = min(start_time);
    % Round start time up to nearest time that is an integer multiple of the time step
    start_time_new = dt*ceil(start_time_new/dt);
    stop_time_new = max(start_time + num_sam./fs);
    Nt = floor((stop_time_new - start_time_new)*fs(1));
    time = start_time_new + (0:dt:(Nt-1)*dt).';
    T = dt*Nt;
    df = 1/T;
    num_sam(num_sam>Nt) = Nt; % Since we round up/down for final time vector, we sometimes lose a sample and this accounts for that
    
    if size(a_data,1) < Nt
      a_data(Nt,1,:) = 0;
    elseif size(a_data,1) > Nt
      a_data = a_data(1:Nt,:,:);
    end
    
    % Solving for td:
    %   Even NZ:
    %   td = (f_if + nyquist_zone/2*param.wfs(wf).fs_raw) / abs(param.wfs(wf).chirp_rate)
    %   Odd NZ:
    %   td = ((nyquist_zone+1)/2*param.wfs(wf).fs_raw - f_if) / abs(param.wfs(wf).chirp_rate)
    % f_if spectrum for raw is from fft(data_raw) and taking bottom half of samples:
    %   freq = df*(0:ceil(Nt/2)-1);
    % f_if_DDC spectrum for DDC is from fftshift(fft(data_DDC)):
    %   freq = NCO_freq + df*(-floor(Nt/2):floor((Nt-1)/2))
    % dt_raw = 1./fs_raw;
    % df = 1/fs_raw;
    % T_raw = num_sam.*dt_raw;
    % df_raw = 1./T_raw;
    % rline = 60;
    % freq_raw = NCO_freq(rline) + df_raw(rline)*(-floor(num_sam(rline)/2):floor((num_sam(rline)-1)/2));
    % NCO_freq_step(rline)
    % NCO_freq(rline)
    % time_offset(rline)
    
    %  Frame 13, block 1: 666 to 682 m = 4.44-4.55 us = 107.8 MHz
    % DC is showing up at 99.32 MHz (should be 125 MHz) = 25.7 MHz error
    %    With correction, surface is 114 MHz (37 m beyond expected)
    %    GEOID is -36 to -42 m at our site
    %    There is no question that frequency/time-shift is insufficient from
    %    NCO.
    %       NCO_freq_step(rline) = fread(fid,1,'uint16');
    %       NCO_freq(rline) = NCO_freq_step(rline) / 2^15 * param.wfs(wf).fs_raw;
    %       time_offset(rline) = NCO_freq(rline) / abs(param.wfs(wf).chirp_rate) * 2;
    %       A times two is either chirp_rate in half OR field changes are 2x what it
    %       should be OR 2^15 should be 2^14
    %       215 range bin up shift for NCO shift of 4.5776e+05
    %
    % From records:
    %  3.5 steps in radar data were 5.5 steps in actual elevation
    %  2.25 steps in radar data were 3 and a little steps in actual elevation
    
    time_shift = start_time - start_time_new;
    NCO_DDC_shift_cmp_flag = 0;
    if any(num_sam ~= Nt) || any(time_shift ~= 0)
      valid_rng = zeros(2,size(a_data,2));
      for rline = 1:size(a_data,2)
        valid_rng(1,rline) = max(1,find(a_data(:,rline,1)~=0,1) + round(time_shift(rline)/dt) + 3);
        valid_rng(2,rline) = min(Nt,num_sam(rline) - (find(a_data(num_sam(rline):-1:1,rline,1)~=0,1)-1) + round(time_shift(rline)/dt) - 3);
      end
      
      % Create frequency axis for time shifting. Note that this is a special freq
      % axis that should not be used for anything else (it is designed to align
      % with NCO DDC mixing).
      %   time_shift_freq <--> ADC fast time
      %   time_shift <--> NCO frequency
      f0 = (start_bin + start_idx(1) - 1180) / param.wfs(wf).fs_raw * abs(param.wfs(wf).chirp_rate);
      time_shift_freq = f0 + df*(0:Nt-1).';
      
      for rline = 1:size(a_data,2)  % the NCO and DDC shift compensation is required for cohenrent noise removal, but will result spectrum shift. So the compensation will be  taken out later for deconvolution.
        a_data(num_sam(rline)+1:end,rline,:) = 0;
        a_data(:,rline,:)= ifft(fft(a_data(:,rline,:)) .* repmat(exp(-j*2*pi*time_shift_freq*time_shift(rline)),[1 1 size(a_data,3)]));
        if ~isfield(param.proc,'coh_noise_tracker') % do not do this compensation for deconvolution waveforms from sepcular analysis
          if Mt(rline) == 4
            a_data(:,rline,:)=  -1*a_data(:,rline,:) .* exp(j*2*pi*-50/size(a_data,1) * (0:size(a_data,1)-1).');
          end
          if Mt(rline) == 8
            a_data(:,rline,:)=  -j*a_data(:,rline,:) .* exp(j*2*pi*-150/size(a_data,1) * (0:size(a_data,1)-1).');
          end
          if Mt(rline) == 16
            if mod(NCO_freq_step(rline),8)
              a_data(:,rline,:)=  -j/2*a_data(:,rline,:) .* exp(j*2*pi*-350/size(a_data,1) * (0:size(a_data,1)-1).');
            else
              a_data(:,rline,:)=  j/2*a_data(:,rline,:) .* exp(j*2*pi*-350/size(a_data,1) * (0:size(a_data,1)-1).');
            end
          end
          NCO_DDC_shift_cmp_flag = 1;
        end
        
        a_data([1:valid_rng(1,rline)-1, valid_rng(2,rline)+1:end], rline,:) = NaN;
      end
    else
      a_data = a_data(1:num_sam(1),:,:);
      valid_rng = ones(1,size(a_data,2));
      valid_rng(2,:) = num_sam;
    end
    
    %% Remove coherent noise (slow-time noise)
    % =======================================================================
    if param.proc.coh_noise_method == 8
      %   a_data = fft(a_data,[],2);
      %   f1_noise = fft(a_data(1:round(size(a_data,1)*0.4),:));
      %   %plot(lp(mean(abs(f1_noise).^2),1))
      %
      %   f1_noise = lp(mean(abs(f1_noise).^2),1);
      %   bad_k_bins = find(f1_noise > median(f1_noise) + 5)
      %   a_data(:,bad_k_bins) = 0;
      %   a_data = ifft(a_data,[],2);
      
      
      if ~iscell(param.proc.coh_noise_arg)
        param.proc.coh_noise_arg = {param.proc.coh_noise_arg};
        param.proc.coh_noise_arg{2} = 5;
        param.proc.coh_noise_arg{3} = 13;
      end
      Hwin = param.proc.coh_noise_arg{1}(:).';
      
      if 1
        % 1-D FILTER
        a_data = fft(a_data,[],2);
        noise_bins = 1:round(size(a_data,1)*0.4);
        bad_mask = lp(nanmean(abs(a_data(noise_bins,:,1)).^2)) > lp(nanmedian(nanmean(abs(a_data(noise_bins,:,1)).^2)))+param.proc.coh_noise_arg{2};
        bad_mask = grow(bad_mask,param.proc.coh_noise_arg{3});
        bad_mask2 = filter2(Hwin/sum(Hwin),[ones(1,length(Hwin)/2-1/2) bad_mask ones(1,length(Hwin)/2-1/2)],'valid');
        for rbin = 1:size(a_data,1);
          a_data(rbin,:,:) = a_data(rbin,:,:).*repmat((1-bad_mask2),[1 1 size(a_data,3)]);
        end
        a_data = ifft(a_data,[],2);
      end
      
    end
    
    % =======================================================================
    %% Presum a_data (with no elevation compensation)
    % =======================================================================
    fprintf('  Presums/coherent averages (%.1f sec)\n', toc(load_fmcw_data_tstart));
    if param.proc.presums ~= 1 && ~param.proc.elev_correction
      num_rec = floor(size(a_data,2)/param.proc.presums);
      for adc_idx = 1:size(a_data,3)
        a_data(:,1:num_rec,adc_idx) = fir_dec(a_data(:,:,adc_idx),param.proc.presums);
      end
      dec_records.gps_time(:,1:num_rec) = fir_dec(records.gps_time,param.proc.presums);
      dec_records.elev(:,1:num_rec) = fir_dec(records.elev,param.proc.presums);
      a_data = a_data(:,1:num_rec,:);
      dec_records.gps_time = dec_records.gps_time(:,1:num_rec);
      dec_records.elev = dec_records.elev(:,1:num_rec);
      Mt = Mt([1:param.proc.presums:length(Mt)]);
      Mt = Mt(1:num_rec);
      
      % Update invalid bins
      for rline = 1:size(a_data,2)
        first_valid_bin = find(~isnan(a_data(:,rline,1)),1);
        if isempty(first_valid_bin)
          % No valid bins in this range line
          valid_rng(:,rline) = [0; 0];
        else
          valid_rng(:,rline) = [first_valid_bin; find(~isnan(a_data(:,rline,1)),1,'last')];
        end
      end
    else
      dec_records.gps_time = records.gps_time;
      dec_records.elev = records.elev;
    end
    a_data(isnan(a_data)) = 0;
    
    
    % =======================================================================
    %% Remove coherent noise (slow-time noise)
    % =======================================================================
    % coh_noise_method == 0 --> does nothing
    if param.proc.coh_noise_method == 1
      % Simple DC removal (using mean)
      data_max_single = max(a_data);
      if isempty(param.proc.coh_noise_arg)
        data_mean_single = mean(a_data,2);
      else
        good_rlines = lp(data_max_single)<param.proc.coh_noise_arg;
        if sum(good_rlines) < 100
          data_mean_single = mean(a_data,2);
        else
          data_mean_single = mean(a_data(:,good_rlines),2);
        end
      end
      for rbin = 1:size(a_data,1)
        a_data(rbin,:) = a_data(rbin,:) - data_mean_single(rbin);
      end
    elseif param.proc.coh_noise_method == 2
      % Simple DC removal (using median)
      for rbin = 1:size(a_data,1);
        a_data(rbin,:) = a_data(rbin,:) - median(a_data(rbin,:));
      end
    elseif param.proc.coh_noise_method == 3
      % DC and low frequency removal (window from param.proc.coh_noise_arg)
      a_data = fft(a_data,[],2);
      Hwin = param.proc.coh_noise_arg;
      for rline = 1:(length(Hwin)-1)/2
        a_data(:,rline) = a_data(:,rline) * Hwin(rline);
        a_data(:,end-rline+1) = a_data(:,end-rline+1) * Hwin(rline);
      end
      a_data = ifft(a_data,[],2);
      
      for rline = 1:size(a_data,2)
        a_data([1:valid_rng(1,rline)-1, valid_rng(2,rline)+1:end], rline,:) = 0;
      end
      
    elseif param.proc.coh_noise_method == 4
      % DC and low frequency removal (filter coeff from param.proc.coh_noise_arg)
      [B_st_filt,A_st_filt] = param.proc.coh_noise_arg();
      H_st_filt = abs(freqz(B_st_filt,A_st_filt,size(a_data,2),'whole')).^2;
      a_data = fft(a_data.',[],1);
      for ft_idx = 1:size(a_data,2)
        a_data(:,ft_idx) = a_data(:,ft_idx) .* H_st_filt;
      end
      a_data = ifft(a_data,[],1).';
    elseif param.proc.coh_noise_method == 5
      % Create a_data mean file and use the mean from surrounding
      % "param.proc.coh_noise_arg{1}" files
      %  Threshold for exclusion of saturated data: param.proc.coh_noise_arg{2}
      error('Broken: needs to be coupled with noise_analysis to use');
      data_max_single = max(a_data);
      data_mean_single = mean(a_data(:,lp(data_max_single)<param.proc.coh_noise_arg{2}),2);
      tmp_param.radar_name = param.load.radar_name;
      tmp_param.season_name = param.load.season_name;
      tmp_param.tmp_path = param.load.tmp_path;
      fn = [ct_filename_tmp(tmp_param,'','qlook','data_info') '.mat'];
      if exist(fn,'file')
        load(fn);
        data_mean(:,finfo.file_idx+1) = data_mean_single;
        data_max{finfo.file_idx+1} = data_max_single;
        save(fn,'-append','data_mean','data_max');
        rel_lines = -param.proc.coh_noise_arg{1}:param.proc.coh_noise_arg{1};
        file_idxs = finfo.file_idx+1 + rel_lines;
        valid_idxs = file_idxs >= 1 & file_idxs <= size(data_mean,2);
        file_idxs = file_idxs(valid_idxs);
        valid_idxs = sum(abs(data_mean(:,file_idxs)))>0;
        file_idxs = file_idxs(valid_idxs);
        Hwin = hanning(param.proc.coh_noise_arg{1}*2+1).';
        Hwin = Hwin(valid_idxs);
        Hwin = Hwin / sum(Hwin);
        local_data_mean = data_mean(:,file_idxs) .* repmat(Hwin,[size(data_mean,1) 1]);
        data_mean_single = sum(local_data_mean,2);
      else
        data_mean(:,finfo.file_idx+1) = data_mean_single;
        data_max{finfo.file_idx+1} = data_max_single;
        [fn_dir fn_name] = fileparts(fn);
        if ~exist(fn_dir,'dir')
          mkdir(fn_dir);
        end
        save(fn,'data_mean','data_max');
      end
      
      a_data = a_data - repmat(data_mean_single,[1 size(a_data,2)]);
    elseif param.proc.coh_noise_method == 6
      % Search for and remove all large doppler frequency tones
      % Argument: 1xN set of weights, N must be odd, e.g. hanning(7)
      if ~iscell(param.proc.coh_noise_arg)
        param.proc.coh_noise_arg = {param.proc.coh_noise_arg};
        param.proc.coh_noise_arg{2} = 5;
        param.proc.coh_noise_arg{3} = 13;
      end
      Hwin = param.proc.coh_noise_arg{1}(:).';
      
      if 1
        % 1-D FILTER
        a_data = fft(a_data,[],2);
        bad_mask = lp(mean(abs(a_data).^2)) > lp(median(mean(abs(a_data).^2)))+param.proc.coh_noise_arg{2};
        bad_mask = grow(bad_mask,param.proc.coh_noise_arg{3});
        bad_mask2 = filter2(Hwin/sum(Hwin),[ones(1,length(Hwin)/2-1/2) bad_mask ones(1,length(Hwin)/2-1/2)],'valid');
        for rbin = 1:size(a_data,1);
          a_data(rbin,:) = a_data(rbin,:).*(1-bad_mask2);
        end
        a_data = ifft(a_data,[],2);
      else
        % 2-D FILTER
        a_data = fft2(a_data);
        
        bad_mask = abs(a_data).^2;
        [B,A] = butter(2,1/25);
        bad_mask = filtfilt(B,A,double(bad_mask));
        bad_mask = filtfilt(B,A,double(bad_mask).').';
        
        background = repmat(median(bad_mask,2),[1 size(bad_mask,2)]);
        
        if 0
          figure(1); clf;
          imagesc(lp(bad_mask ./ background,1) > 8);
          colorbar;
        end
        
        bad_mask = lp(bad_mask ./ background,1) > 8;
        Hwin = param.proc.coh_noise_arg{1}(:).';
        Hwin = kron(Hwin,Hwin');
        bad_mask2 = filter2(Hwin/sum(Hwin(:)),double(bad_mask),'valid');
        %     imagesc(bad_mask2);
        
        X = ((1+(size(Hwin,2)-1)/2:size(a_data,2)-(size(Hwin,2)-1)/2)).';
        Y = (1+(size(Hwin,1)-1)/2:size(a_data,1)-(size(Hwin,1)-1)/2);
        bad_mask2 = interp1(X, bad_mask2.', 1:size(a_data,2), 'nearest','extrap').';
        bad_mask2 = interp1(Y, bad_mask2, 1:size(a_data,1), 'nearest','extrap');
        %     imagesc(bad_mask2);
        
        a_data = a_data .* (1-bad_mask2);
        
        %     figure(1); clf;
        %     imagesc(lp(a_data));
        %     colorbar;
        
        a_data = ifft2(a_data);
        %     imagesc(lp(a_data));
        %     keyboard
      end
      
    elseif any(param.proc.coh_noise_method == [7 9])
      % Use coh_noise_tracker results to remove coherent noise, must run collate_coh_noise.m first
      % param.proc.coh_noise_arg{1} = polynomial order of sgolayfilt
      % param.proc.coh_noise_arg{2} = frame size for sgolayfilt
      % param.proc.coh_noise_arg{3} = frame window for sgolayfilt
      % param.proc.coh_noise_arg{4} = string for cdf directory, the ? in "CSARP_?"
      
      cdf_fn_dir = fileparts(ct_filename_out(param,param.proc.coh_noise_arg{4}, ''));
      cdf_fn = fullfile(cdf_fn_dir,sprintf('coh_noise_simp_%s.nc', param.day_seg));
      
      finfo = ncinfo(cdf_fn);
      % Determine number of records and set recs(1) to this
      Nt = finfo.Variables(find(strcmp('coh_aveI',{finfo.Variables.Name}))).Size(2);
      
      noise = [];
      noise.gps_time = ncread(cdf_fn,'gps_time');
      recs = find(noise.gps_time > dec_records.gps_time(1) - 100 & noise.gps_time < dec_records.gps_time(end) + 100);
      noise.gps_time = noise.gps_time(recs);
      
      noise.coh_ave = ncread(cdf_fn,'coh_aveI',[recs(1) 1],[recs(end)-recs(1)+1 Nt]) ...
        + j*ncread(cdf_fn,'coh_aveQ',[recs(1) 1],[recs(end)-recs(1)+1 Nt]);
      
      if param.proc.coh_noise_method == 9
        noise.doppler_weights = ncread(cdf_fn,'doppler_weights');
      end
      
      if param.proc.coh_noise_method == 7 || noise.doppler_weights(1) == 1
        a_data = a_data ...
          - interp1(reshape(noise.gps_time,[numel(noise.gps_time) 1]),noise.coh_ave,dec_records.gps_time,'linear','extrap').';
      end
      if param.proc.coh_noise_method == 9
        % append zeros on both sides to avoid artifact at edges of fft
        a_data = [zeros(size(a_data,1),100),a_data,zeros(size(a_data,1),100)];
        doppler_weights = interp1(0:numel(noise.doppler_weights)-1,noise.doppler_weights,linspace(0,numel(noise.doppler_weights)-1,size(a_data,2)));
        a_data = ifft(fft(a_data,[],2) .* repmat(doppler_weights,[size(a_data,1) 1]), [], 2);
        % remove appended zeros after ifft
        a_data(:,1:100) = [];
        a_data(:,end-99:end) =[];
      end
    end
    
    %   freq = (param.wfs(wf).fc + 2*param.wfs(wf).chirp_rate / param.wfs(wf).fs_raw * ((0:Nt-1) - floor(Nt/2))).';
    %   freq = (param.wfs(wf).fc + abs(param.wfs(wf).chirp_rate) / (param.wfs(wf).fs_raw/Mt(1)) * ((0:Nt-1) - floor(Nt/2))).';
    Nt = size(a_data,1);
    freq = param.wfs(wf).fc + (-floor(Nt/2)*df : df : floor((Nt-1)/2)*df ).';
    
    % =======================================================================
    %% Presum a_data (with elevation compensation)
    % =======================================================================
    if param.proc.elev_correction && param.proc.presums > 1
      % Elevation correction just corrects for phase deviations caused by
      % deviations from the mean elevation within the presum window.
      drange = fir_dec(dec_records.elev,param.proc.presums);
      drange = reshape(repmat(drange,[param.proc.presums 1]),[1 param.proc.presums*length(drange)]);
      drange = dec_records.elev(1:length(drange)) - drange;
      a_data = a_data(:,1:length(drange));
      Nt = size(a_data,1);
      % This sign of the center frequency is backwards, yet works for some seasons...
      % Greater range implies more negative phase, so the correction should be
      % a more positive phase and this is the opposite. Not sure why??? May have
      % something to do with how we do complex baseband with FFT... maybe this
      % is causing a conjugation of the phase.
      if isfield(param.radar.wfs,'fc_sign') && param.radar.wfs.fc_sign < 0
        freq_hack = -param.wfs(wf).fc + (-floor(Nt/2)*df : df : floor((Nt-1)/2)*df ).';
      else
        freq_hack = param.wfs(wf).fc + (-floor(Nt/2)*df : df : floor((Nt-1)/2)*df ).';
      end
      a_data = ifft(fft(a_data) .* exp(1i*2*pi*freq_hack*drange/(c/2)));
      
      % Set invalid bins to NaN, so that averaging with invalid bins results
      % in an invalid bin (NaN).
      for rline = 1:size(a_data,2)
        a_data([1:valid_rng(1,rline)-1, valid_rng(2,rline)+1:end], rline) = NaN;
      end
      
      num_rec = floor(size(a_data,2)/param.proc.presums);
      a_data(:,1:num_rec) = fir_dec(a_data,param.proc.presums);
      dec_records.gps_time(:,1:num_rec) = fir_dec(dec_records.gps_time,param.proc.presums);
      dec_records.elev(:,1:num_rec) = fir_dec(dec_records.elev,param.proc.presums);
      a_data = a_data(:,1:num_rec);
      dec_records.gps_time = dec_records.gps_time(:,1:num_rec);
      dec_records.elev = dec_records.elev(:,1:num_rec);
      Mt = Mt([1:param.proc.presums:length(Mt)]);
      Mt = Mt(1:num_rec);
      
      % Update invalid bins
      valid_rng = [];
      for rline = 1:size(a_data,2)
        first_valid_bin = find(~isnan(a_data(:,rline)),1);
        if isempty(first_valid_bin)
          % No valid bins in this range line
          valid_rng(:,rline) = [0; 0];
        else
          valid_rng(:,rline) = [first_valid_bin; find(~isnan(a_data(:,rline)),1,'last')];
        end
      end
      
      a_data(isnan(a_data)) = 0;
    end
    
    % =======================================================================
    %% Deconvolution
    % =======================================================================
    deconv_filter_idx = NaN(1,size(a_data,2));
    if param.proc.deconvolution == 3
      if NCO_DDC_shift_cmp_flag  % take out the compensation to remove the resulted spectrum shift for deconvolution
        for rline = 1:size(a_data,2)
          if Mt(rline) == 4
            a_data(:,rline,:)=  -1*a_data(:,rline,:) .* exp(j*2*pi*50/size(a_data,1) * (0:size(a_data,1)-1).');
          end
          if Mt(rline) == 8
            a_data(:,rline,:)=  j*a_data(:,rline,:) .* exp(j*2*pi*150/size(a_data,1) * (0:size(a_data,1)-1).');
          end
          if Mt(rline) == 16
            if mod(NCO_freq_step(rline),8)
              a_data(:,rline,:)=  2*j*a_data(:,rline,:) .* exp(j*2*pi*350/size(a_data,1) * (0:size(a_data,1)-1).');
            else
              a_data(:,rline,:)=  -2*j*a_data(:,rline,:) .* exp(j*2*pi*350/size(a_data,1) * (0:size(a_data,1)-1).');
            end
          end
        end
      end
      if size(spec.deconv_H,2) > 0
        % group data according to DDC filter and apply deconvolution
        % waveforms from the same DDC filter
        
        [Mts,mm,nn] = unique(Mt);
        mm = sort(mm);
        for Mt_idx = 1:length(Mts)
          Mt_current = Mt(mm(Mt_idx));
          idxs = find(Mt == Mt_current);
          tmp_data = a_data(:,idxs);
          % Find the two way travel time to the surface (HACK! a surface
          % parameter should be passed in so this works over land too)
          twtt_bins = unique(round(dec_records.elev(idxs) / (c/2)/spec.twtt_bin_spacing));
          
          % We then take these two way travel times and bin them. We will apply
          % different deconvolution waveforms to each bin.
          for twtt_bin = twtt_bins
            % Only use deconvolution waveforms that were taken with a similar
            % two way travel time (this is because twtt effects the corrections
            % that need to be applied).
            if param.proc.deconv_same_twtt_bin
              valid_idxs = find(twtt_bin == (spec.deconv_twtt_min+spec.deconv_twtt_max)/2 & ~isnan(spec.deconv_frame));
            else
              valid_idxs = [];
            end
            if isempty(valid_idxs)
              valid_idxs = find(twtt_bin >= spec.deconv_twtt_min & twtt_bin <= spec.deconv_twtt_max);
            end
            if isempty(valid_idxs)
              % If no valid waveforms exist, then just choose the closest in twtt
              min_dist = min(abs(twtt_bin-spec.deconv_twtt_max),abs(twtt_bin-spec.deconv_twtt_min));
              min_dist_min = min(min_dist);
              valid_idxs = find(min_dist == min_dist_min);
            end
            % find valid_idxs that have Mt_current
            valid_idxs_tmp = valid_idxs;
            valid_idxs(spec.deconv_DDC_Mt(valid_idxs)~=Mt_current) = [];
            if isempty(valid_idxs)
              idxs_tmp = find(spec.deconv_DDC_Mt==Mt_current);
              if ~isempty(idxs_tmp)
                min_dist = min(abs(twtt_bin-spec.deconv_twtt_max(idxs_tmp)),abs(twtt_bin-spec.deconv_twtt_min(idxs_tmp)));
                min_dist_min = min(min_dist);
                valid_idxs = idxs_tmp(find(min_dist == min_dist_min));% use the closest twtt with the same DDC filter
              else
                valid_idxs= valid_idxs_tmp; % remove the DDC filter constrain to let code run
              end
            end
            
            closest_idx = [];
            if ~isempty(param.proc.deconv_enforce_wf_idx)
              if numel(param.proc.deconv_enforce_wf_idx)>1
                % If 2 or more values are passed in, then:
                %   First column is frame number
                %   Second column is deconvolution wf idx
                % If the frame is not found in the list, then closest_idx
                % will be empty and the deconv waveform that is closest in
                % time will be selected below (which is the default mode).
                frames = frames_load(param);
                frm = find(mean(param.load.recs) >= frames.frame_idxs,1,'last');
                closest_idx = param.proc.deconv_enforce_wf_idx(find(param.proc.deconv_enforce_wf_idx(:,1) == frm),2);
              else
                % If a single value is passed in, then this waveform is used
                % for all frames.
                closest_idx = param.proc.deconv_enforce_wf_idx;
              end
            end
            if isempty(closest_idx)
              % Now find the closest of the valid waveforms in time... the idea
              % being that the system parameters change over time so we want to
              % deconvolve with a reference measurement that was taken with close
              % temporal proximity
              [tmp,closest_idx] = min(abs(mean(dec_records.gps_time) - spec.deconv_gps_time(valid_idxs)));
              closest_idx = valid_idxs(closest_idx);
            end
            
            deconv_H = spec.deconv_H{closest_idx};
            if length(freq) ~= length(spec.freq{closest_idx}) ...
                || any(abs(freq([1 end]) - spec.freq{closest_idx}([1 end])) > 0.1e6)
              deconv_H = spec.deconv_H{closest_idx};
              % If we ever needed to apply frequency domain interpolation... initial
              % results indicate that this does not work very well... possibly because
              % the corrections at each frequency change for different chirp parameters.
              %           deconv_H = interp1(fftshift(spec.freq(:,closest_idx)), spec.deconv_H(:,closest_idx), fftshift(freq),'linear','extrap');
              deconv_H = interp1(spec.freq{closest_idx}, spec.deconv_H{closest_idx}, freq,'linear','extrap');
              deconv_H = interp_finite(deconv_H);
            end
            % Create a mask that will apply the deconvolution only to the data
            % collected in this twtt bin.
            mask = round(dec_records.elev(idxs)/ (c/2)/spec.twtt_bin_spacing) == twtt_bin;
            tmp_data(:,mask) = ifft(fft(tmp_data(:,mask)) .* repmat(deconv_H,[1 sum(mask)]));
            deconv_filter_idx(mask) = closest_idx;
          end
          a_data(:,idxs) = tmp_data;
        end
        %clf; imagesc(lp(a_data)); % DEBUG
      end
    end
    
    % =======================================================================
    %% PSD smoothing
    % =======================================================================
    if param.proc.psd_smooth
      %% NOTE: This causes sidelobes and is a hack.  Cannot be used with deconvolution.
      % This correction can be used in cases where deconvolution (removal of
      % sidelobes) is not critical.
      % Best solution is probably wiener/MMSE filter deconvolution... but it
      % would be complicated to track the non-stationary signal and noise
      
      % Estimate fast time PSD
      psd = lp(mean(abs(fft(a_data)).^2,2));
      
      % Smooth the PSD
      Nt_shorten = [600 400]; % Smoothing ignores these bins at begin/end
      psd_smooth = zeros(size(a_data,1),1);
      bins = 1+Nt_shorten(1):size(a_data,1)-Nt_shorten(2);
      psd_smooth(bins) = sgolayfilt(double(psd(bins)),3,3001);
      bins = 1:Nt_shorten(1);
      psd_smooth(bins) = psd(bins);
      bins = size(a_data,1)-Nt_shorten(2)+1 : size(a_data,1);
      psd_smooth(bins) = psd(bins);
      
      % Anywhere PSD exceeds the smoothed PSD and grow mask
      mask = psd > psd_smooth;
      mask = grow(mask,10);
      
      % Determine the correction to flatten the PSD to the smoothed PSD
      corr = 10.^(-(psd-psd_smooth)/20);
      corr(~mask | corr > 1) = 1;
      
      % Apply correction to the data
      a_data = ifft(fft(a_data) .* repmat(corr,[1 size(a_data,2)]));
      
      if 0
        psd_ta = lp(mean(abs(fft(ta)).^2,2));
        
        figure(1); clf;
        imagesc(lp(fir_dec(abs(ta).^2,5)))
        
        figure(2); clf;
        plot(psd)
        hold on
        plot(psd,'k')
        plot(psd_smooth,'k')
        plot(psd_smooth2,'r')
        plot(psd_ta)
        hold off;
      end
      
    end
    
    if size(g_data{img_idx},1) == 0 || size(g_data{img_idx},3) < wf_adc_idx
      g_data{img_idx}(1:size(a_data,1),1:size(a_data,2),wf_adc_idx) = a_data;
    else
      g_data{img_idx}(:,:,wf_adc_idx) = g_data{img_idx}(:,:,wf_adc_idx) + a_data;
    end
    img_time{img_idx} = time;
    img_valid_rng{img_idx} = valid_rng;
    img_deconv_filter_idx{img_idx} = deconv_filter_idx;
    img_freq{img_idx} = freq;
    img_Mt{img_idx} = Mt;
    img_nyquist_zone{img_idx} = nyquist_zone;
  end
end

fprintf('  Done (%.1f sec)\n', toc(load_fmcw_data_tstart));

end

% ===================================================================
% ===================================================================
% build_img_load_struct support function
% ===================================================================
% ===================================================================
function accum = build_img_load_struct(imgs, adcs, param)
% accum = build_img_load_struct(imgs, adcs, param)
%
% Builds an accumulator structure for load_mcords2_data. This is required
% to run load_mcords2_data.
%
% imgs = cell vector of imgs (each entry is a separate wf_adc_list)
%   Each wf_adc_list is an Nx2 array where N is the number of channels,
%   the first column is the waveform, and the second column is the adc.
%   Absolute index of wf and adc are used in this array.
% adcs = vector of valid adcs (absolute index of each adc)
% param = structure with parameter information
%   .file_version
%
% accum = structure vector that helps load_mcords2_data load data ("accumulator")
%   Each entry in the structure vector corresponds to a specific board.
%     accum(board)
%   Each entry contains lists of how to accumulate and store data for the
%   board when loading from load_mcords2_data.  load_mcords2_data first
%   accumulates the data (presums):
%     accum(board).data{accumulator-instance}
%   Once the presums are finished, the data is processed and stored in
%   the output variable:
%     a_data{img_idx}(fast-time,slow-time,wf_adc_idx)
%   The three fields in accum(board) are all length Kx1 where K is the number
%   of accumulator instances.  The number of accumulator instances is
%   determined by the length of the fields.
%  .adc = K x 1 vector indicating which adc this instance is pulled from
%  .wf = K x 1 vector indicating which waveform this instance is pulled from
%  .wf_adc_idx = an index in the final output array unless adcs are
%    combined in which case size(a_data{:}, 3) == 1.
%  .img_idx = an index in the final output array
%
% Examples: At the bottom of this file
%
% Author: John Paden
%
% See also: load_mcords_data

% Verify that all adc entries are valid
for img_idx = 1:length(imgs)
  for wf_adc_idx = 1:size(imgs{img_idx},1)
    if ~ismember(real(imgs{img_idx}(wf_adc_idx,2)), adcs)
      error('ADC %d is invalid', imgs{img_idx}(wf_adc_idx,2));
    end
  end
end

% Create board list
if param.file_version >= 0
  boards = unique(adcs);
else
  boards = unique(floor((adcs-1)/4));
end

% Build accum structure
for board = boards
  if param.file_version >= 0
    board_adcs = adcs(adcs == board);
  else
    board_adcs = adcs(floor((adcs-1)/4) == board);
    board = board + 1; % Convert 0-indexed to 1-indexed
  end
  accum(board).adc = [];
  accum(board).wf = [];
  accum(board).wf_adc_idx = [];
  accum(board).img_idx = [];
  accum(board).iq_mode = [];
  accum(board).img_comb_idx = [];
  for adc = board_adcs
    for img_idx = 1:length(imgs)
      for wf_adc_idx = 1:size(imgs{img_idx},1)
        for adc_column = 2:2:size(imgs{img_idx},2)
          if abs(imgs{img_idx}(wf_adc_idx,adc_column)) == adc
            if isreal(imgs{img_idx})
              % [wf adc] --> real only waveform
              accum(board).adc(end+1) = adc;
              accum(board).wf(end+1) = imgs{img_idx}(wf_adc_idx,adc_column-1);
              accum(board).wf_adc_idx(end+1) = wf_adc_idx;
              accum(board).img_idx(end+1) = img_idx;
              accum(board).iq_mode(end+1) = 0;
              accum(board).img_comb_idx(end+1) = adc_column/2;
            else
              % [j*wf adc] --> use waveform 1 and 2 to form I + j*Q
              % [-j*wf adc] --> use waveform 1 and 2 to form I - j*Q
              % [wf j*adc] --> use adc 1 and 2 to form I + j*Q
              % [wf -j*adc] --> use adc 1 and 2 to form I - j*Q
              if real(imgs{img_idx}(wf_adc_idx,1)) == 0
                % Next waveform is the Q channel
                accum(board).adc(end+1) = adc;
                accum(board).wf(end+1) = abs(imgs{img_idx}(wf_adc_idx,1));
                accum(board).wf_adc_idx(end+1) = wf_adc_idx;
                accum(board).img_idx(end+1) = img_idx;
                accum(board).iq_mode(end+1) = 1;
                accum(board).img_comb_idx(end+1) = adc_column/2;
                
                accum(board).adc(end+1) = adc;
                accum(board).wf(end+1) = abs(imgs{img_idx}(wf_adc_idx,1)) + 1;
                accum(board).wf_adc_idx(end+1) = wf_adc_idx;
                accum(board).img_idx(end+1) = img_idx;
                accum(board).iq_mode(end+1) = 2*sign(imag(imgs{img_idx}(wf_adc_idx,1)));
                accum(board).img_comb_idx(end+1) = adc_column/2;
              else
                % Next adc is the Q channel
                accum(board).adc(end+1) = adc;
                accum(board).wf(end+1) = imgs{img_idx}(wf_adc_idx,1);
                accum(board).wf_adc_idx(end+1) = wf_adc_idx;
                accum(board).img_idx(end+1) = img_idx;
                accum(board).iq_mode(end+1) = 1;
                accum(board).img_comb_idx(end+1) = adc_column/2;
                
                accum(board).adc(end+1) = adc+1;
                accum(board).wf(end+1) = imgs{img_idx}(wf_adc_idx,1);
                accum(board).wf_adc_idx(end+1) = wf_adc_idx;
                accum(board).img_idx(end+1) = img_idx;
                accum(board).iq_mode(end+1) = 2*sign(imag(imgs{img_idx}(wf_adc_idx,2)));
                accum(board).img_comb_idx(end+1) = adc_column/2;
              end
            end
          end
        end
      end
    end
  end
end

end

