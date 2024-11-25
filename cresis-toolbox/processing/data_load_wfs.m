function [wfs,states] = data_load_wfs(param, records)
% [wfs,states] = data_load_wfs(param, records)
%
% https://ops.cresis.ku.edu/wiki/index.php/Data_load#data_load_wfs.m
%
% Author: John Paden

%% Build raw data loading "states" structure
% =========================================================================

if ~iscell(param.load.imgs{1})
  % param.load.imgs is not using multilooking syntax; reformat
  % param.load.imgs non-multilooking syntax to multilooking syntax to
  % ensure param.load.imgs is always in the multilooking syntax. This
  % makes coding easier since the format is always the same.
  for img = 1:length(param.load.imgs)
    param.load.imgs{img} = {param.load.imgs{img}};
  end
end

% Create list of unique boards to load
board_list = [];
board_idxs = [];
for img = 1:length(param.load.imgs)
  for ml_idx = 1:length(param.load.imgs{img})
    for wf_adc = 1:size(param.load.imgs{img}{ml_idx},1)
      [board_list(end+1),board_idxs(end+1)] = wf_adc_to_board(param,param.load.imgs{img}{ml_idx}(wf_adc,:));
      
      % Follow wfs(wf).next field links for additional wf-adc pairsboards to load
      wf = param.load.imgs{img}{ml_idx}(wf_adc,1);
      adc = param.load.imgs{img}{ml_idx}(wf_adc,2);
      if ~isfield(param.radar.wfs(wf),'next') || size(param.radar.wfs(wf).next,1) < adc || isnan(param.radar.wfs(wf).next(adc,1))
        % if next is not specified, then this wf-adc pair is the last to be
        % loaded in the next chain.
        if isfield(param.radar.wfs(wf),'next') && size(param.radar.wfs(wf).next,1) < adc
          param.radar.wfs(wf).next(end+1:adc,1:2) = NaN;
        else
          param.radar.wfs(wf).next(adc,1:2) = NaN;
        end
      end
      next = param.radar.wfs(wf).next(adc,1:2);
      while ~isnan(next)
        wf = next(1);
        adc = next(2);
        if ~isfield(param.radar.wfs(wf),'next') || size(param.radar.wfs(wf).next,1) < adc || isnan(param.radar.wfs(wf).next(adc,1))
          % if next is not specified, then this wf-adc pair is the last to be
          % loaded in the next chain.
          param.radar.wfs(wf).next(adc,1:2) = [NaN NaN];
        end
        % Determine which board this wf-adc pair comes from
        [board_list(end+1),board_idxs(end+1)] = wf_adc_to_board(param,[wf adc]);
        % Follow the wfs(wf).next field link
        next = param.radar.wfs(wf).next(adc,1:2);
      end
    end
  end
end
[boards,unique_idxs] = unique(board_list);
board_idxs = board_idxs(unique_idxs);

% Populate states structure
states = [];
for state_idx = 1:length(boards)
  if state_idx > length(states) || ~isfield(states(state_idx),'board') ...
      || isempty(states(state_idx).board)
    states(state_idx).board = boards(state_idx);
    states(state_idx).board_idx = board_idxs(state_idx);
    states(state_idx).adc = [];
    states(state_idx).wf = [];
    states(state_idx).mode = {};
    states(state_idx).subchannel = {};
    states(state_idx).wf_adc = [];
    states(state_idx).img = [];
    states(state_idx).ml_idx = [];
    states(state_idx).weight = [];
    states(state_idx).next = [];
    states(state_idx).reset_sum = [];
  end
  for img = 1:length(param.load.imgs) % For each image img
    for ml_idx = 1:length(param.load.imgs{img})
      for wf_adc = 1:size(param.load.imgs{img}{ml_idx},1) % For ach wf-adc pair
        wf = param.load.imgs{img}{ml_idx}(wf_adc,1);
        adc = param.load.imgs{img}{ml_idx}(wf_adc,2);
        
        [board,~,profile] = wf_adc_to_board(param,param.load.imgs{img}{ml_idx}(wf_adc,:));
        % Determine if this wf,adc is from the current board
        if board ~= states(state_idx).board
          continue;
        end
        if any(param.records.file.version == [9 10 103 412])
          mode_latch = profile{1}(:,1);
          subchannel = profile{1}(:,2);
        else
          mode_latch = 0;
          subchannel = 0;
        end
        
        if ~isfield(param.radar.wfs(wf),'weight')
          % if weight is not specified, then this wf-adc pair is loaded with a
          % weight of one
          param.radar.wfs(wf).weight(adc) = 1;
        elseif length(param.radar.wfs(wf).weight) < adc
          param.radar.wfs(wf).weight(end+1:adc) = 1;
        end
        % Create wf_adc_sum list from weight/next commands
        states(state_idx).adc(end+1) = adc;
        states(state_idx).wf(end+1) = wf;
        states(state_idx).mode{end+1} = mode_latch;
        states(state_idx).subchannel{end+1} = subchannel;
        states(state_idx).wf_adc(end+1) = wf_adc;
        states(state_idx).img(end+1) = img;
        states(state_idx).ml_idx(end+1) = ml_idx;
        states(state_idx).weight(end+1) = param.radar.wfs(wf).weight(adc);
        states(state_idx).reset_sum(end+1) = true;
        next = param.radar.wfs(wf).next(adc,1:2);
        while ~isnan(next(1))
          wf = next(1);
          adc = next(2);
          if ~isfield(param.radar.wfs(wf),'weight') || length(param.radar.wfs(wf).weight) < adc
            % if weight is not specified, then this wf-adc pair is loaded with a
            % weight of one
            param.radar.wfs(wf).weight(adc) = 1;
          end
          % Determine which board this wf-adc pair comes from
          [board,~,profile] = wf_adc_to_board(param,[wf adc]);
          next_state_idx = find(boards == board,1);
          if any(param.records.file.version == [9 10 103 412])
            mode_latch = profile{1}(:,1);
            subchannel = profile{1}(:,2);
          else
            mode_latch = 0;
            subchannel = 0;
          end
          % Add wf-adc pair to states list
          if next_state_idx > length(states) || ~isfield(states(next_state_idx),'board') ...
              || isempty(states(state_idx).board)
            % Create new state if not already created.
            states(next_state_idx).board = boards(next_state_idx);
            states(next_state_idx).board_idx = board_idxs(next_state_idx);
            states(next_state_idx).adc = [];
            states(next_state_idx).wf = [];
            states(next_state_idx).mode = {};
            states(next_state_idx).subchannel = {};
            states(next_state_idx).wf_adc = [];
            states(next_state_idx).img = [];
            states(next_state_idx).ml_idx = [];
            states(next_state_idx).weight = [];
            states(next_state_idx).next = [];
            states(next_state_idx).reset_sum = [];
          end
          states(next_state_idx).adc(end+1) = adc;
          states(next_state_idx).wf(end+1) = wf;
          states(next_state_idx).mode{end+1} = mode_latch;
          states(next_state_idx).subchannel{end+1} = subchannel;
          states(next_state_idx).wf_adc(end+1) = wf_adc;
          states(next_state_idx).img(end+1) = img;
          states(next_state_idx).ml_idx(end+1) = ml_idx;
          states(next_state_idx).weight(end+1) = param.radar.wfs(wf).weight(adc);
          states(next_state_idx).reset_sum(end+1) = false;
          next = param.radar.wfs(wf).next(adc,1:2);
        end
      end
    end
  end
end

%% Create wfs structure with waveform information
% =========================================================================
[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);
for wf = 1:length(param.radar.wfs)
  if isfield(param.radar.wfs(wf),'rx_paths') && ~isempty(param.radar.wfs(wf).rx_paths)
    wfs(wf).rx_paths   = param.radar.wfs(wf).rx_paths;
  else
    wfs(wf).rx_paths   = 1;
  end
  if ~isfield(param.radar.wfs(wf),'adcs') || isempty(param.radar.wfs(wf).adcs)
    adcs = find(~isnan(wfs(wf).rx_paths));
  else
    adcs = param.radar.wfs(wf).adcs;
  end
  
  %% Input checks
  % =======================================================================
  % bad_value: Value to use for bad records (is also the value used to fill
  % in unused parts of the data matrix when the number of range bins is
  % allowed to vary on a range line to range line basis). The default value
  % is 0 for non-deramp systems and NaN for deramp systems. Typical values
  % are 0 or NaN. If NaN, consider using "nan_dec" option in qlook.
  if isfield(param.radar.wfs(wf),'bad_value') && ~isempty(param.radar.wfs(wf).bad_value)
    wfs(wf).bad_value   = param.radar.wfs(wf).bad_value;
  else
    if strcmpi(radar_type,'deramp')
      wfs(wf).bad_value   = NaN;
    else
      wfs(wf).bad_value   = 0;
    end
  end
  
  if isfield(param.radar.wfs(wf),'DDC_dec') && ~isempty(param.radar.wfs(wf).DDC_dec)
    wfs(wf).DDC_dec   = param.radar.wfs(wf).DDC_dec;
  else
    wfs(wf).DDC_dec   = 1;
  end
  % Check to make sure DDC_dec_max is valid
  if isfield(param.radar.wfs(wf),'DDC_dec_max') && ~isempty(param.radar.wfs(wf).DDC_dec_max)
    wfs(wf).DDC_dec_max   = param.radar.wfs(wf).DDC_dec_max; % Must be a positive integer
    if mod(wfs(wf).DDC_dec_max,1) ~= 0 || wfs(wf).DDC_dec_max < 1
      error('Invalid DDC_dec_max %g. Set to 1 if decimation never used. It must be a positive integer.', wfs(wf).DDC_dec_max);
    end
  else
    wfs(wf).DDC_dec_max   = wfs(wf).DDC_dec; % No decimation variation
  end
  
  if ~isfield(param.radar,'adc_bits') || isempty(param.radar.adc_bits)
    param.radar.adc_bits = 0;
  end
  if ~isfield(param.radar,'Vpp_scale') || isempty(param.radar.Vpp_scale)
    param.radar.Vpp_scale = 1;
  end
  if ~isfield(param.radar,'fs') || isempty(param.radar.fs)
    if param.records.file.version == 410 % mcords
      param.radar.fs = records_wfs.wfs(1).wfs(1).fs;
    else
      error('param.radar.fs must be defined.');
    end
  end
  wfs(wf).fs_raw = param.radar.fs / wfs(wf).DDC_dec;
  
  if isfield(param.radar.wfs(wf),'td_mean') && ~isempty(param.radar.wfs(wf).td_mean)
    wfs(wf).td_mean = param.radar.wfs(wf).td_mean;
  else
    wfs(wf).td_mean = 3e-6;
  end
  if isfield(param.radar.wfs(wf),'Tpd') && ~isempty(param.radar.wfs(wf).Tpd)
    wfs(wf).Tpd = param.radar.wfs(wf).Tpd;
  elseif any(param.records.file.version == [405 406 410]) % [acords mcords]
    wfs(wf).Tpd = records.settings.wfs(1).wfs(wf).Tpd(1);
  end
  if isfield(param.radar.wfs(wf),'fLO') && ~isempty(param.radar.wfs(wf).fLO)
    wfs(wf).fLO = param.radar.wfs(wf).fLO;
  else
    wfs(wf).fLO = 0;
  end
  if isfield(param.radar.wfs(wf),'fmult') && ~isempty(param.radar.wfs(wf).fmult)
    wfs(wf).fmult = param.radar.wfs(wf).fmult;
  else
    wfs(wf).fmult = 1;
  end
  if isfield(param.radar.wfs(wf),'f0') && ~isempty(param.radar.wfs(wf).f0)
    wfs(wf).f0 = param.radar.wfs(wf).f0;
  elseif any(param.records.file.version == [405 406 410]) % [acords mcords]
    wfs(wf).f0 = records.settings.wfs(1).wfs(wf).f0(1);
  end
  wfs(wf).f0 = wfs(wf).f0*wfs(wf).fmult + wfs(wf).fLO;
  if isfield(param.radar.wfs(wf),'f1') && ~isempty(param.radar.wfs(wf).f1)
    wfs(wf).f1 = param.radar.wfs(wf).f1;
  elseif any(param.records.file.version == [405 406 410]) % [acords mcords]
    wfs(wf).f1 = records.settings.wfs(1).wfs(wf).f1(1);
  end
  wfs(wf).f1 = wfs(wf).f1*wfs(wf).fmult + wfs(wf).fLO;
  wfs(wf).fmult = 1; % f0/f1 have been multiplied, so set the multiplier to 1
  wfs(wf).fLO = 0; % fLO has been added, so set to 0
  if isfield(param.radar.wfs(wf),'time_raw_trim') && ~isempty(param.radar.wfs(wf).time_raw_trim)
    wfs(wf).time_raw_trim   = param.radar.wfs(wf).time_raw_trim;
  else
    if param.records.file.version == 402
      wfs(wf).time_raw_trim   = [0 2];
    else
      wfs(wf).time_raw_trim   = [0 0];
    end
  end
  if isfield(param.radar.wfs(wf),'Tadc_adjust') && ~isempty(param.radar.wfs(wf).Tadc_adjust)
    wfs(wf).Tadc_adjust = param.radar.wfs(wf).Tadc_adjust;
  else
    wfs(wf).Tadc_adjust = 0;
  end
  if isfield(param.radar.wfs(wf),'Tadc') && ~isempty(param.radar.wfs(wf).Tadc)
    wfs(wf).t0_raw    = param.radar.wfs(wf).Tadc + wfs(wf).Tadc_adjust ...
      + wfs(wf).time_raw_trim(1)/wfs(wf).fs_raw;
  elseif any(param.records.file.version == [405 406 410]) % acords and mcrds
    wfs(wf).t0_raw    = records.settings.wfs(1).wfs(wf).t0(1) + wfs(wf).Tadc_adjust ...
      + wfs(wf).time_raw_trim(1)/wfs(wf).fs_raw;
  elseif isfield(records.settings.wfs,'t0')
    if numel(records.settings.wfs) >= wf
      wfs(wf).t0_raw    = records.settings.wfs(wf).t0 + wfs(wf).Tadc_adjust ...
        + wfs(wf).time_raw_trim(1)/wfs(wf).fs_raw;
    else
      wfs(wf).t0_raw    = records.settings.wfs(1).t0 + wfs(wf).Tadc_adjust ...
        + wfs(wf).time_raw_trim(1)/wfs(wf).fs_raw;
    end
  else
    wfs(wf).t0_raw    = 0 + wfs(wf).Tadc_adjust ...
      + wfs(wf).time_raw_trim(1)/wfs(wf).fs_raw;
  end
  if isfield(param.radar.wfs(wf),'t_ref') && ~isempty(param.radar.wfs(wf).t_ref)
    wfs(wf).t_ref   = param.radar.wfs(wf).t_ref;
  else
    wfs(wf).t_ref = 0;
  end
  if isfield(param.radar.wfs(wf),'blank') && ~isempty(param.radar.wfs(wf).blank)
    wfs(wf).blank   = param.radar.wfs(wf).blank;
  else
    wfs(wf).blank = [];
  end
  if numel(wfs(wf).blank) == 0
    wfs(wf).blank   = [-inf -inf];
  elseif numel(wfs(wf).blank) == 1
    wfs(wf).blank(2)   = -inf;
  end
  if isfield(param.radar.wfs(wf),'zero_pad') && ~isempty(param.radar.wfs(wf).zero_pad)
    wfs(wf).zero_pad   = param.radar.wfs(wf).zero_pad;
  else
    wfs(wf).zero_pad   = 0;
  end
  if isfield(param.radar.wfs(wf),'ft_dec') && ~isempty(param.radar.wfs(wf).ft_dec)
    wfs(wf).ft_dec = param.radar.wfs(wf).ft_dec;
  else
    if strcmpi(radar_type,'deramp')
      wfs(wf).ft_dec = [1 1];
    else
      [numerator denominator] = rat(abs(wfs(wf).f1 - wfs(wf).f0) / wfs(wf).fs_raw);
      wfs(wf).ft_dec = [numerator denominator];
    end
  end
  if isfield(param.radar.wfs(wf),'DDC_freq') && ~isempty(param.radar.wfs(wf).DDC_freq)
    wfs(wf).DDC_freq   = param.radar.wfs(wf).DDC_freq;
  else
    wfs(wf).DDC_freq   = 0;
  end
  if isfield(param.radar.wfs(wf),'DDC_NCO_delay') && ~isempty(param.radar.wfs(wf).DDC_NCO_delay)
    wfs(wf).DDC_NCO_delay   = param.radar.wfs(wf).DDC_NCO_delay;
  else
    wfs(wf).DDC_NCO_delay   = 2.4e-6-2.88e-6; % AWI NI 2017 snow radar system default delay
  end
  if isfield(param.radar.wfs(wf),'presums') && ~isempty(param.radar.wfs(wf).presums)
    wfs(wf).presums = param.radar.wfs(wf).presums;
  elseif any(param.records.file.version == [405 406 410]) % [acords mcrds]
    wfs(wf).presums = records.settings.wfs(1).wfs(wf).presums(1);
  elseif isfield(records.settings.wfs,'presums')
    wfs(wf).presums = records.settings.wfs(wf).presums;
  else
    wfs(wf).presums = 1;
  end
  if isfield(param.radar.wfs(wf),'presum_threshold') && ~isempty(param.radar.wfs(wf).presum_threshold)
    wfs(wf).presum_threshold = param.radar.wfs(wf).presum_threshold;
  else
    wfs(wf).presum_threshold = 0.5;
  end
  if isfield(param.radar.wfs(wf),'BW_window') && ~isempty(param.radar.wfs(wf).BW_window)
    wfs(wf).BW_window = param.radar.wfs(wf).BW_window(1:2);
  else
    wfs(wf).BW_window = [min(abs([wfs(wf).f0,wfs(wf).f1])) max(abs([wfs(wf).f0,wfs(wf).f1]))];
  end
  if any(param.records.file.version == [405 406 410]) % acords and mcrds
    wfs(wf).Nt_raw = records.settings.wfs(1).wfs(wf).num_sam(1) - sum(wfs(wf).time_raw_trim);
  elseif any(param.records.file.version == [415])
    wfs(wf).Nt_raw = 3200;
  elseif isfield(records.settings.wfs,'num_sam')
    if numel(records.settings.wfs) >= wf
      wfs(wf).Nt_raw = records.settings.wfs(wf).num_sam(1);
    else
      wfs(wf).Nt_raw = records.settings.wfs(1).num_sam(1);
    end
    wfs(wf).Nt_raw = wfs(wf).Nt_raw - sum(wfs(wf).time_raw_trim);
  else
    % Will be determined later in data_load.m
    wfs(wf).Nt_raw = 0;
  end
  if isfield(param.radar.wfs(wf),'conjugate') && ~isempty(param.radar.wfs(wf).conjugate)
    wfs(wf).conjugate_on_load   = param.radar.wfs(wf).conjugate;
  else
    wfs(wf).conjugate_on_load   = 0;
  end
  if isfield(param.radar.wfs(wf),'ft_wind_time') && ~isempty(param.radar.wfs(wf).ft_wind_time)
    wfs(wf).ft_wind_time   = param.radar.wfs(wf).ft_wind_time;
  else
    wfs(wf).ft_wind_time   = [];
  end
  if isfield(param.radar.wfs(wf),'ft_wind') && ~isempty(param.radar.wfs(wf).ft_wind)
    wfs(wf).ft_wind   = param.radar.wfs(wf).ft_wind;
  else
    wfs(wf).ft_wind   = @hanning;
  end
  if isfield(param.radar.wfs(wf),'tukey') && ~isempty(param.radar.wfs(wf).tukey)
    wfs(wf).tukey   = param.radar.wfs(wf).tukey;
  else
    wfs(wf).tukey   = 0;
  end
  if isfield(param.radar.wfs(wf),'gain_en') && ~isempty(param.radar.wfs(wf).gain_en)
    wfs(wf).gain_en   = param.radar.wfs(wf).gain_en;
  else
    wfs(wf).gain_en   = false;
  end
  if isfield(param.radar.wfs(wf),'gain_dir') && ~isempty(param.radar.wfs(wf).gain_dir)
    wfs(wf).gain_dir   = param.radar.wfs(wf).gain_dir;
  else
    wfs(wf).gain_dir = '';
  end
  if isfield(param.radar.wfs(wf),'nz_complex') && ~isempty(param.radar.wfs(wf).nz_complex)
    wfs(wf).nz_complex   = param.radar.wfs(wf).nz_complex;
  else
    wfs(wf).nz_complex   = false;
  end
  if isfield(param.radar.wfs(wf),'nz_trim') && ~isempty(param.radar.wfs(wf).nz_trim)
    wfs(wf).nz_trim   = param.radar.wfs(wf).nz_trim;
  else
    wfs(wf).nz_trim   = {};
  end
  if ~isfield(param.radar.wfs(wf),'prepulse_H') || isempty(param.radar.wfs(wf).prepulse_H)
    param.radar.wfs(wf).prepulse_H = [];
  end
  wfs(wf).prepulse_H   = param.radar.wfs(wf).prepulse_H;
  if isfield(param.radar.wfs(wf).prepulse_H,'type') && ~isempty(param.radar.wfs(wf).prepulse_H.type)
    wfs(wf).prepulse_H.type   = param.radar.wfs(wf).prepulse_H.type;
  else
    wfs(wf).prepulse_H.type   = '';
  end
  if isfield(param.radar.wfs(wf).prepulse_H,'dir') && ~isempty(param.radar.wfs(wf).prepulse_H.dir)
    wfs(wf).prepulse_H.dir   = param.radar.wfs(wf).prepulse_H.dir;
  else
    wfs(wf).prepulse_H.dir   = 'analysis';
  end
  if isfield(param.radar.wfs(wf).prepulse_H,'fn') && ~isempty(param.radar.wfs(wf).prepulse_H.fn)
    wfs(wf).prepulse_H.fn   = param.radar.wfs(wf).prepulse_H.fn;
  else
    wfs(wf).prepulse_H.fn   = 'prepulse_H';
  end
  if isfield(param.radar.wfs(wf),'wf_ID_best') && ~isempty(param.radar.wfs(wf).wf_ID_best)
    wfs(wf).wf_ID_best   = param.radar.wfs(wf).wf_ID_best;
  else
    wfs(wf).wf_ID_best   = true;
  end
  if isfield(param.radar.wfs(wf),'coh_noise_method') && ~isempty(param.radar.wfs(wf).coh_noise_method)
    wfs(wf).coh_noise_method   = param.radar.wfs(wf).coh_noise_method;
  else
    wfs(wf).coh_noise_method   = '';
  end
  switch wfs(wf).coh_noise_method
    case 'analysis'
      % Coherent noise from analysis.m process
      if ~isfield(param.radar.wfs(wf),'coh_noise_arg')
        wfs(wf).coh_noise_arg   = [];
      else
        wfs(wf).coh_noise_arg   = param.radar.wfs(wf).coh_noise_arg;
      end
      if ~isfield(wfs(wf).coh_noise_arg,'fn') || isempty(wfs(wf).coh_noise_arg.fn)
        wfs(wf).coh_noise_arg.fn   = 'analysis';
      end
    case 'estimated'
      % Coherent noise estimated from loaded data
      if ~isfield(param.radar.wfs(wf),'coh_noise_arg')
        wfs(wf).coh_noise_arg   = [];
      else
        wfs(wf).coh_noise_arg   = param.radar.wfs(wf).coh_noise_arg;
      end
      if ~isfield(wfs(wf).coh_noise_arg,'DC_remove_en') || isempty(wfs(wf).coh_noise_arg.DC_remove_en)
        wfs(wf).coh_noise_arg.DC_remove_en   = 1;
      end
      if ~isfield(wfs(wf).coh_noise_arg,'B_coh_noise') || isempty(wfs(wf).coh_noise_arg.B_coh_noise)
        wfs(wf).coh_noise_arg.B_coh_noise   = 1;
      end
      if ~isfield(wfs(wf).coh_noise_arg,'A_coh_noise') || isempty(wfs(wf).coh_noise_arg.A_coh_noise)
        wfs(wf).coh_noise_arg.A_coh_noise   = 1;
      end
  end
  if isfield(param.radar.wfs(wf),'burst') && ~isempty(param.radar.wfs(wf).burst)
    wfs(wf).burst    = param.radar.wfs(wf).burst;
  else
    wfs(wf).burst    = [];
  end
  if ~isfield(wfs(wf).burst,'en') || isempty(wfs(wf).burst.en)
    wfs(wf).burst.en = false;
  end
  if ~isfield(wfs(wf).burst,'fn') || isempty(wfs(wf).burst.fn)
    wfs(wf).burst.fn = 'analysis';
  end
  if isfield(param.radar.wfs(wf),'deconv') && ~isempty(param.radar.wfs(wf).deconv)
    wfs(wf).deconv    = param.radar.wfs(wf).deconv;
  else
    wfs(wf).deconv    = [];
  end
  if ~isfield(wfs(wf).deconv,'en') || isempty(wfs(wf).deconv.en)
    wfs(wf).deconv.en = false;
  end
  if ~isfield(wfs(wf).deconv,'fn') || isempty(wfs(wf).deconv.fn)
    wfs(wf).deconv.fn = 'analysis';
  end
  % Per wf-adc pair amplitude equalization
  if isfield(param.radar.wfs(wf),'chan_equal_dB') && ~isempty(param.radar.wfs(wf).chan_equal_dB)
    wfs(wf).chan_equal_dB       = param.radar.wfs(wf).chan_equal_dB;
  else
    wfs(wf).chan_equal_dB(adcs) = 0;
  end
  % Per wf-adc pair phase equalization
  if isfield(param.radar.wfs(wf),'chan_equal_deg') && ~isempty(param.radar.wfs(wf).chan_equal_deg)
    wfs(wf).chan_equal_deg       = param.radar.wfs(wf).chan_equal_deg;
  else
    wfs(wf).chan_equal_deg(adcs) = 0;
  end
  % Per wf-adc pair time delay correction
  if isfield(param.radar.wfs(wf),'Tsys') && ~isempty(param.radar.wfs(wf).Tsys)
    wfs(wf).Tsys       = param.radar.wfs(wf).Tsys;
  else
    wfs(wf).Tsys(adcs) = 0;
  end
  % Time varying channel equalization file
  if isfield(param.radar.wfs(wf),'chan_equal') && ~isempty(param.radar.wfs(wf).chan_equal)
    wfs(wf).chan_equal   = param.radar.wfs(wf).chan_equal;
  else
    wfs(wf).chan_equal   = '';
  end
  if isfield(param.radar.wfs(wf),'ref_fn') && ~isempty(param.radar.wfs(wf).ref_fn)
    wfs(wf).ref_fn   = param.radar.wfs(wf).ref_fn;
  else
    wfs(wf).ref_fn   = '';
  end
  
  if isfield(param.radar.wfs(wf),'tx_weights') && ~isempty(param.radar.wfs(wf).tx_weights)
    wfs(wf).tx_weights   = param.radar.wfs(wf).tx_weights;
  else
    wfs(wf).tx_weights   = 1;
  end
  if isfield(param.radar.wfs(wf),'system_dB') && ~isempty(param.radar.wfs(wf).system_dB)
    wfs(wf).system_dB   = param.radar.wfs(wf).system_dB;
  else
    wfs(wf).system_dB   = 0;
  end
  if isfield(param.radar.wfs(wf),'adc_gains_dB') && ~isempty(param.radar.wfs(wf).adc_gains_dB)
    wfs(wf).adc_gains_dB   = param.radar.wfs(wf).adc_gains_dB;
  else
    wfs(wf).adc_gains_dB   = 0;
  end
  
  %% Compute supporting variables
  % =======================================================================
  wfs(wf).chirp_rate = (wfs(wf).f1-wfs(wf).f0) / wfs(wf).Tpd;
  wfs(wf).fc = (wfs(wf).f1+wfs(wf).f0)/2;
  
  %% Quantization to Voltage conversion
  % =======================================================================
  if isfield(param.radar.wfs(wf),'bit_shifts') && ~isempty(param.radar.wfs(wf).bit_shifts)
    wfs(wf).bit_shifts   = param.radar.wfs(wf).bit_shifts;
    if length(wfs(wf).bit_shifts) == 1 && numel(wfs(wf).bit_shifts) < max(adcs);
      wfs(wf).bit_shifts = wfs(wf).bit_shifts*ones(1,max(adcs));
    end
  elseif any(param.records.file.version == [405 406]) % acords
    wfs(wf).bit_shifts = records.settings.wfs(1).wfs(wf).bit_shifts(1)*ones(1,max(adcs));
  elseif param.records.file.version == 410 % mcords
    wfs(wf).bit_shifts = max(0,ceil(log(wfs(wf).presums)/log(2)) - 4)*ones(1,max(adcs));
  elseif isfield(records.settings.wfs,'bit_shifts')
    if numel(records.settings.wfs) >= wf
      wfs(wf).bit_shifts = records.settings.wfs(wf).bit_shifts*ones(1,max(adcs));
    else
      wfs(wf).bit_shifts = records.settings.wfs(1).bit_shifts*ones(1,max(adcs));
    end
  else
    wfs(wf).bit_shifts = 0*ones(1,max(adcs));
  end
  if ~isfield(param.radar.wfs(wf),'quantization_to_V_dynamic') || isempty(param.radar.wfs(wf).quantization_to_V_dynamic)
    wfs(wf).quantization_to_V_dynamic = false;
    if any(param.records.file.version == [3 4 5 7 8 11 407 408]) && ~(isfield(param.radar.wfs(wf),'bit_shifts') && ~isempty(param.radar.wfs(wf).bit_shifts))
      wfs(wf).quantization_to_V_dynamic = true;
    end
  else
    wfs(wf).quantization_to_V_dynamic = param.radar.wfs(wf).quantization_to_V_dynamic;
  end
  wfs(wf).quantization_to_V ...
    = param.radar.Vpp_scale * 2.^wfs(wf).bit_shifts ...
    ./ (2^param.radar.adc_bits*wfs(wf).presums);
  
  if strcmpi(radar_type,'deramp')
    %% FMCW: Create time and frequency axis information
    % =====================================================================
    wfs(wf).Nt = 0;
    
    % This field may be overwritten during data loading, but this is a
    % default value which is used to estimate memory requirements for
    % cluster processing
    if isfield(param.radar.wfs(wf),'complex') && ~isempty(param.radar.wfs(wf).complex)
      wfs(wf).complex   = param.radar.wfs(wf).complex;
    else
      if wfs(wf).DDC_dec > 1 || wfs(wf).DDC_freq ~= 0
        % Assume complex data if DDC_dec > 1 or DDC_freq is non-zero
        wfs(wf).complex   = true;
      else
        wfs(wf).complex   = false;
      end
    end
    if ~isfield(param.radar.wfs(wf),'nz_valid') || isempty(param.radar.wfs(wf).nz_valid)
      warning('Default Nyquist zones not specified in param.radar.wfs(%d).nz_valid. Setting to [0,1,2,3] which may not be correct.',wf);
      param.radar.wfs(wf).nz_valid = [0 1 2 3];
    end
    wfs(wf).nz_valid = param.radar.wfs(wf).nz_valid;
    if ~isfield(param.radar.wfs(wf),'DDC_valid') || isempty(param.radar.wfs(wf).DDC_valid)
      warning('Default DDC rates not specified in param.radar.wfs(%d).DDC_valid. Setting to [1,2,4,8,16] which may not be correct.',wf);
      param.radar.wfs(wf).DDC_valid = [1 2 4 8 16];
    end
    wfs(wf).DDC_valid = param.radar.wfs(wf).DDC_valid;
    
  elseif strcmpi(radar_type,'pulsed')
    %% Pulsed: Create time and frequency axis information
    % =====================================================================
    
    % Raw data
    % ---------------------------------------------------------------------
    dt = 1/wfs(wf).fs_raw;
    wfs(wf).time_raw = wfs(wf).t0_raw + dt*(0:wfs(wf).Nt_raw-1).';
    
    nz0 = floor((wfs(wf).f0-wfs(wf).DDC_freq)/wfs(wf).fs_raw*2);
    nz1 = floor((wfs(wf).f1-wfs(wf).DDC_freq)/wfs(wf).fs_raw*2);
    
    df = wfs(wf).fs_raw/wfs(wf).Nt_raw;
    
    % wfs(wf).complex: This field may be overwritten during data loading,
    % but this is a default value which is used to estimate memory
    % requirements for cluster processing before data loading happens.
    if isfield(param.radar.wfs(wf),'complex') ...
        && ~isempty(param.radar.wfs(wf).complex)
      wfs(wf).complex   = param.radar.wfs(wf).complex;
    else
      if nz0 == nz1 && wfs(wf).DDC_dec == 1 && wfs(wf).DDC_freq == 0
        % Assume real sampling since signal does not cross Nyquist boundary
        % and DDC does not seem to be in operation.
        wfs(wf).complex   = false;
      else
        % Assume complex sampling since signal crosses Nyquist boundary
        wfs(wf).complex   = true;
      end
    end
    
    if ~wfs(wf).complex
      if mod(nz0,2)
        % Negative frequencies first since this is an odd Nyquist zone
        wfs(wf).freq_raw = floor(nz0/2)*wfs(wf).fs_raw + df*(0:wfs(wf).Nt_raw-1).';
        wfs(wf).freq_raw(1:floor(wfs(wf).Nt_raw/2)) ...
          = wfs(wf).freq_raw(1:floor(wfs(wf).Nt_raw/2)) - floor(nz0/2)*wfs(wf).fs_raw - ceil(nz0/2)*wfs(wf).fs_raw;
      else
        % Positive frequencies first since this is an odd Nyquist zone
        wfs(wf).freq_raw = floor(nz0/2)*wfs(wf).fs_raw + df*(0:wfs(wf).Nt_raw-1).';
        wfs(wf).freq_raw(end-floor(wfs(wf).Nt_raw/2)+1:end) ...
          = wfs(wf).freq_raw(end-floor(wfs(wf).Nt_raw/2)+1:end) - (nz0/2+1)*wfs(wf).fs_raw - nz0/2*wfs(wf).fs_raw;
      end
      
    else
      wfs(wf).freq_raw = wfs(wf).DDC_freq ...
        + ifftshift( -floor(wfs(wf).Nt_raw/2)*df : df : floor((wfs(wf).Nt_raw-1)/2)*df ).';
      
      % Determine original sampling frequency
      fs = wfs(wf).fs_raw * wfs(wf).DDC_dec;
      
      % Determine the Nyquist zone offset of the sampling
      if mod(round( (wfs(wf).fc - wfs(wf).DDC_freq) / (fs/2) ), 2)
        % Odd number nyquist zone offset: frequency axis is flipped and
        % shifted. Conjugate in the time domain to flip frequency axis
        % and conjugate frequency domain during loading. Raw frequency axis
        % is valid after this time conjugation is done.
        %
        % Note: This is only a valid scenario for real data sampling
        % (referring to the original sampling before the DDC) since complex
        % data sampled in the wrong Nyquist zone never makes sense.
        wfs(wf).conjugate_on_load = ~wfs(wf).conjugate_on_load;
        wfs(wf).freq_raw = wfs(wf).freq_raw - floor((wfs(wf).freq_raw - (wfs(wf).fc-wfs(wf).fs_raw/2))/wfs(wf).fs_raw)*wfs(wf).fs_raw;
      else
        % Even number nyquist zone offset: frequency axis is shifted
        %
        % Note: This can happen with real or complex data sampling
        % (referring to the original sampling before the DDC).
        wfs(wf).freq_raw = wfs(wf).freq_raw - floor((wfs(wf).freq_raw - (wfs(wf).fc-wfs(wf).fs_raw/2))/wfs(wf).fs_raw)*wfs(wf).fs_raw;
      end
    end
    
    
    % Pulse compressed data is applied to complex base banded raw data
    % with f_LO = wfs(wf).fc-wfs(wf).DDC_freq
    % ---------------------------------------------------------------------
    wfs(wf).Nt_ref  = floor(wfs(wf).Tpd * wfs(wf).fs_raw) + 1;
    wfs(wf).pad_length = wfs(wf).Nt_ref + wfs(wf).zero_pad - 1;
    wfs(wf).Nt_pc = wfs(wf).Nt_raw + wfs(wf).pad_length;
    wfs(wf).fs_pc = wfs(wf).fs_raw;
    
    % freq: Frequency axis for processed data. Starts at fc goes to fc+fs/2, fc-fs/2 to fc
    df = wfs(wf).fs_pc/wfs(wf).Nt_pc;
    freq_bb = ifftshift( -floor(wfs(wf).Nt_pc/2)*df : df : floor((wfs(wf).Nt_pc-1)/2)*df ).';
    wfs(wf).freq_pc = wfs(wf).fc + freq_bb;
    
    % time: Time axis for processed data. Starts same as raw data minus the padding which is added at the front
    dt = 1/wfs(wf).fs_pc;
    wfs(wf).time_pc = wfs(wf).t0_raw - dt*wfs(wf).pad_length + dt*(0:wfs(wf).Nt_pc-1).';
    
    
    % Final "processed" axes after decimation
    % ---------------------------------------------------------------------
    wfs(wf).fs = wfs(wf).fs_raw * wfs(wf).ft_dec(1)/wfs(wf).ft_dec(2);
    wfs(wf).Nt = ceil(wfs(wf).Nt_pc*wfs(wf).ft_dec(1)/wfs(wf).ft_dec(2));
    
    % freq: Frequency axis for processed data. Starts at fc goes to fc+fs/2, fc-fs/2 to fc
    df = wfs(wf).fs/wfs(wf).Nt;
    wfs(wf).freq = wfs(wf).fc + ifftshift( -floor(wfs(wf).Nt/2)*df : df : floor((wfs(wf).Nt-1)/2)*df ).';
    
    % time: Time axis for processed data. Starts same as raw data minus the padding which is added at the front
    dt = 1/wfs(wf).fs;
    wfs(wf).time = wfs(wf).time_pc(1) + dt*(0:wfs(wf).Nt-1).';
    
    % Modify reference function so that time vector elements are multiples
    % of dt.
    wfs(wf).time_correction = dt - mod(wfs(wf).time(1),dt);
    wfs(wf).time = wfs(wf).time + wfs(wf).time_correction;
    
    %% Pulsed: Create reference function
    % =====================================================================
    BW = wfs(wf).f1 - wfs(wf).f0;
    dt = 1/wfs(wf).fs_pc;
    time = (0:dt:(wfs(wf).Nt_pc-1)*dt).';
    ref = tukeywin_cont(time/wfs(wf).Tpd-0.5, wfs(wf).tukey).*exp(1i*2*pi*-BW/2*time + 1i*pi*wfs(wf).chirp_rate*time.^2);
    if ~isempty(wfs(wf).ft_wind_time)
      ref = wfs(wf).ft_wind_time(wfs(wf).Nt_ref).*ref;
    end
    
    for adc = adcs
      
      ref_fn_name = char(wfs(wf).ref_fn);
      ref_fn_name = regexprep(ref_fn_name,'%w',sprintf('%.0f',wf));
      ref_fn_name = regexprep(ref_fn_name,'%a',sprintf('%.0f',adc));
      ref_fn = fullfile(ct_filename_out(param,'noise','',1), [ref_fn_name '.mat']);
      
      if isempty(ref_fn_name) || ~exist(ref_fn,'file')
        wfs(wf).ref{adc} = conj(fft(ref,wfs(wf).Nt_pc) ...
          .* exp(-1i*2*pi*wfs(wf).freq_pc*wfs(wf).Tsys(wfs(wf).rx_paths(adc))) );
        wfs(wf).ref_windowed(adc) = false;
        
      else
        % Load reference function from collate_deconv.m (e.g. for deconvolution)
        load(ref_fn,'ref_nonnegative','ref_negative','ref_windowed','ref_window');
        ref_Nt = length(ref_nonnegative)+length(ref_negative);
        if ref_Nt > Nt
          error('Window in ref_fn %s is longer than time axis, increase zero padding to use this reference function or shorten the reference function', ref_fn);
        end
        ref_from_file = [ref_nonnegative; zeros(Nt-ref_Nt,1); ref_negative];
        wfs(wf).ref_windowed(adc) = ref_windowed;
        
        if ref_windowed && ~isequal(ref_window,proc_param.ft_wind)
          error('Window in ref_fn %s is %s and does not match param.load.ft_wind %s', ...
            ref_fn, func2str(ref_window), func2str(proc_param.ft_wind));
        end
        
        ref_from_file = ref_from_file ./ abs(max(ref_from_file));
        wfs(wf).ref{adc} = conj(fft(ref_from_file,Nt) ...
          .* exp(-1i*2*pi*freq*wfs(wf).Tsys(wfs(wf).rx_paths(adc))) );
      end
      
      if ~wfs(wf).ref_windowed(adc)
        % Use special fftshifted frequency axis to make applying the
        % frequency window easier.
        freq = fftshift(wfs(wf).freq_pc);
        mask = ifftshift(freq>=wfs(wf).BW_window(1) & freq<=wfs(wf).BW_window(2));
        wfs(wf).ref{adc}(mask) = ifftshift(fftshift(wfs(wf).ref{adc}(mask)) .* wfs(wf).ft_wind(sum(mask)));
        wfs(wf).ref{adc}(~mask) = 0;
      end
      
      % Apply time correction so that start time will be a multiple of
      % the sampling frequency of the radar
      wfs(wf).ref{adc} = wfs(wf).ref{adc} .* exp(1i*2*pi*wfs(wf).freq_pc*wfs(wf).time_correction);
      
      % Normalize reference function so that it is an estimator
      %  -- Accounts for pulse duration differences
      time_domain_ref = ifft(wfs(wf).ref{adc});
      wfs(wf).ref{adc} = wfs(wf).ref{adc} ...
        ./ dot(time_domain_ref,time_domain_ref);
    end
  end
end

%% Populate the waveform offsets into each record
% =========================================================================
% File Version	Description
% 1	snow, kuband (Leuschen/Ledford based)
% 2	snow2, kuband2 (NI based)
% 3	snow3, kuband3 (NI based, DDC enabled)
% 4	snow3, kuband3 (NI based, no DDC?, limited use)
% 5	snow3, kuband3, kaband3 (NI based, second version of DDC code)
% 6	snow4, kuband4 (NI based, Spring 2015 NRL version of DDC code, multichannel)
% 7	snow5 (NI based, AWI version of DDC code, multichannel, multiwaveform). Note this is a standard file type loaded by basic_load.m
% 8	snow8 (NI based, Keysight waveform generator). Some files start with snow4 from the test flight.
% 9	snow9 (Arena based, Arena Snow Radar).
% 10	snow10 (Arena based, Arena Helicopter Snow Radar).
% 11	data_v11 (NI based, Mini-Snow Radar).
% 101	accum (Leuschen/Ledford based)
% 102	accum2 (Sundance, Paden/Rink based)
% 401	mcords (Leuschen/Ledford based)
% 402	mcords2 (NI based, XML files unreliable)
% 403	mcords3 (NI based, header fields changed, XML files correct 2014 Antarctica DC8 and later unreliable before that)
% 404	mcords4 (NI based, introduced 2013 Antarctica Basler, wideband, XML files complete)
% 405	acords (Akins based, 2003 Greenland P3, low/high gain)
% 406	acords v2 (Akins based, 2004 Antarctica P3-chile and 2005 Greenland TO, low/high gain, 4-channel option)
% 407	mcords5 (NI based, introduced 2015 Greenland C130/Polar6, wideband, XML files complete, DDC)
% 408	mcords5 (NI based, introduced 2015 Greenland C130/Polar6, wideband, XML files complete, No DDC)
% 409	icards (?/Akins Linux PCI card based, introduced 1993 Greenland P3)
% 410	mcrds (Akins based, introduced 2006 Greenland P3, multichannel/waveforms)
% 411	hfrds (Leuschen eval board based, 2013 Antarctica G1XB???, 2016 Greenland G1XB)
% 412	hfrds2 (Arena based, Arena HF Sounder, 2016 Greenland TOdtu).
%
% wfs(wf).wf_offset: bytes of data before this data waveform
% wfs(wf).num_sam: bytes of data in this record

for wf = 1:length(param.radar.wfs)
  
  switch param.records.file.version
    
    case {1,2,3,4,5,7,8,11}
      if param.records.file.version == 1
        HEADER_SIZE = 32;
        WF_HEADER_SIZE = 0;
      elseif param.records.file.version == 2
        HEADER_SIZE = 40;
        WF_HEADER_SIZE = 0;
      elseif param.records.file.version == 4
        HEADER_SIZE = 32;
        WF_HEADER_SIZE = 4;
      else
        HEADER_SIZE = 0;
        WF_HEADER_SIZE = 48;
      end
      wfs(wf).wf_header_size = WF_HEADER_SIZE;
      wfs(wf).record_mode = 0;
      wfs(wf).complex = 0;
      wfs(wf).sample_size = 2;
      wfs(wf).adc_per_board = 1;
      wfs(wf).sample_type = 'int16';
      if wf == 1
        wfs(wf).offset = HEADER_SIZE + WF_HEADER_SIZE;
      else
        % Only some of the formats support multiple waveforms and some of
        % the formats have a records.settings.wfs(wf-1).num_sam that
        % can change from one record to the next and so is repopulated in
        % data_load.m for wf>1.
        wfs(wf).offset = wfs(wf-1).offset + ...
          + wfs(wf).sample_size*wfs(wf).adc_per_board*records.settings.wfs(wf-1).num_sam ...
          + HEADER_SIZE + WF_HEADER_SIZE;
      end
    
    case {415}
      % UTIG MARFA/HICARS 60 MHz
      HEADER_SIZE = 0;
      WF_HEADER_SIZE = 0;
      wfs(wf).wf_header_size = WF_HEADER_SIZE;
      wfs(wf).record_mode = 2;
      wfs(wf).complex = 0;
      wfs(wf).sample_size = 2;
      wfs(wf).adc_per_board = 4;
      wfs(wf).sample_type = 'int16';
      wfs(wf).offset = HEADER_SIZE + WF_HEADER_SIZE;
      
    case {9,10,103,412}
      wfs(wf).record_mode = 1;
      
    case {401}
      HEADER_SIZE = 160;
      WF_HEADER_SIZE = 0;
      wfs(wf).record_mode = 0;
      wfs(wf).complex = 0;
      wfs(wf).sample_size = 2;
      wfs(wf).adc_per_board = 1;
      wfs(wf).sample_type = 'uint16';
      if wf == 1
        wfs(wf).offset = HEADER_SIZE + WF_HEADER_SIZE;
      else
        wfs(wf).offset = wfs(wf-1).offset ...
          + wfs(wf).sample_size*wfs(wf).adc_per_board*records.settings.wfs(wf-1).num_sam ...
          + WF_HEADER_SIZE;
      end
      
    case {402,403}
      HEADER_SIZE = 32;
      WF_HEADER_SIZE = 8;
      wfs(wf).record_mode = 0;
      wfs(wf).complex = 0;
      wfs(wf).sample_size = 2;
      wfs(wf).adc_per_board = 4;
      wfs(wf).sample_type = 'int16';
      if wf == 1
        wfs(wf).offset = HEADER_SIZE + WF_HEADER_SIZE;
      else
        wfs(wf).offset = wfs(wf-1).offset ...
          + wfs(wf).sample_size*wfs(wf).adc_per_board*records.settings.wfs(wf-1).num_sam ...
          + WF_HEADER_SIZE;
      end
      
    case 404
      HEADER_SIZE = 40;
      WF_HEADER_SIZE = 8;
      wfs(wf).record_mode = 0;
      wfs(wf).complex = 0;
      wfs(wf).sample_size = 2;
      wfs(wf).adc_per_board = 1;
      wfs(wf).sample_type = 'int16';
      if wf == 1
        wfs(wf).offset = HEADER_SIZE + WF_HEADER_SIZE;
      else
        wfs(wf).offset = wfs(wf-1).offset ...
          + wfs(wf).sample_size*wfs(wf).adc_per_board*records.settings.wfs(wf-1).num_sam ...
          + WF_HEADER_SIZE;
      end
      
    case 407
      % DDC Enabled
      HEADER_SIZE = 40;
      WF_HEADER_SIZE = 8;
      wfs(wf).record_mode = 0;
      wfs(wf).complex = 1;
      wfs(wf).sample_size = 2;
      wfs(wf).adc_per_board = 1;
      wfs(wf).sample_type = 'int16';
      if wf == 1
        wfs(wf).offset = HEADER_SIZE + WF_HEADER_SIZE;
      else
        wfs(wf).offset = wfs(wf-1).offset ...
          + (1+wfs(wf).complex)*wfs(wf).sample_size*wfs(wf).adc_per_board*records.settings.wfs(wf-1).num_sam ...
          + WF_HEADER_SIZE;
      end
      
    case 408
      % DDC Disabled
      HEADER_SIZE = 80;
      WF_HEADER_SIZE = 16;
      wfs(wf).record_mode = 0;
      wfs(wf).complex = 0;
      wfs(wf).sample_size = 2;
      wfs(wf).adc_per_board = 1;
      wfs(wf).sample_type = 'int16';
      if wf == 1
        wfs(wf).offset = HEADER_SIZE + WF_HEADER_SIZE;
      else
        wfs(wf).offset = wfs(wf-1).offset ...
          + wfs(wf).sample_size*wfs(wf).adc_per_board*records.settings.wfs(wf-1).num_sam ...
          + WF_HEADER_SIZE;
      end
      
  end
end

% if param.load.file_version == 402 || param.load.file_version == 403
%   HEADER_SIZE = 32;
%   WF_HEADER_SIZE = 8;
%   bin_size = 2;
%   sample_type = 'int16';
%   num_boards = 4;
%   boards = unique(floor((param.load.adcs-1)/num_boards));
% elseif param.load.file_version == 404
%   HEADER_SIZE = 32;
%   WF_HEADER_SIZE = 8;
%   bin_size = 2;
%   sample_type = 'int16';
%   num_boards = 1;
%   boards = param.load.adcs;
% elseif param.load.file_version == 407 || param.load.file_version == 408
%   if wfs(1).DDC_mode == 0
%     % DDC Enabled
%     HEADER_SIZE = 80;
%     WF_HEADER_SIZE = 16;
%     bin_size = 2;
%     sample_type = 'int16';
%     num_boards = 1;
%     boards = param.load.adcs;
%   else
%     % DDC Disabled
%     HEADER_SIZE = 40;
%     WF_HEADER_SIZE = 8;
%     bin_size = 2;
%     sample_type = 'int16';
%     num_boards = 1;
%     boards = param.load.adcs;
%   end
% elseif param.load.file_version == 411
%   HEADER_SIZE = 128;
%   WF_HEADER_SIZE = 0;
%   bin_size = 2;
%   sample_type = 'int16';
%   num_boards = 1;
%   boards = param.load.adcs;
% elseif param.load.file_version == 412
%   HEADER_SIZE = NaN;
%   WF_HEADER_SIZE = NaN;
%   SUBRECORD_SIZE_OFFSET = 68; % HACK FIX LATER
%   bin_size = 4; % HACK FIX LATER
%   sample_type = 'int32'; % HACK FIX LATER
%   boards = unique(param.records.wf_adc_boards(1,param.load.adcs));
% end
%
