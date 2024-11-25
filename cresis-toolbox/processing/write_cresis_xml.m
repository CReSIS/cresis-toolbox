function settings_enc = write_cresis_xml(param)
% settings_enc = write_cresis_xml(param)
%
% Creates NI digital system XML files (configuration files).
%
% param
%  .radar_name = 'mcords3', 'mcords4' or 'mcords5'
%  .num_chan = number of receiving channels (used to determine data
%    rate)
%  .aux_dac = DDS Aux DAC settings
%  .TTL_prog_delay = DDS TTL programming delay
%  .fs = sampling frequency (used to determine start/stop record bins)
%  .fs_sync = sync clock used to determine TTL control settings
%  .fs_dds = used to determine start/stop frequency for down-chirp
%  .TTL_mode = 3 length vector [pre_guard post_guard TTL_delay_from_tx]
%    pre_guard: time before transmit starts to go high (normally ~3 us)
%    post_guard: time after transmit ends to stay high (normally ~350 ns)
%    TTL_delay: offset of transmit start from TTL prog delay (a negative
%      value means that the TTL prog delay is after the transmit starts)
%  .version = NI XML file version
%  .max_DDS_amp = maximum DDS amplitude (0 to 2^16-1). If given as a scalar,
%    then a constant max is used for all DDS. If it is a vector is should
%    be the same length as param.tx_weights. Alternate field name is max_tx.
%  .max_data_rate = in MB/sec
%  .flight_hours = used to determine data volume
%  .sys_delay = system delay before transmit starts (used to determine
%     start/stop record bins
%  .max_duty_cycle = used to verify settings do not exceed this duty cycle
%    (0 to 1)
%  .create_IQ = create transmit I and Q waveforms if true
%  .tg = time gate fields
%   .staged_recording = waveform timing set to staggered overlapping stages
%     to cover full time gate if this is true. Low-gain, med-gain,
%     high-gain should be given in chronological order in your param
%     settings since that is what is assumed for staged recording. If false,
%     each waveform will cover the full time gate.
%   .altitude_guard = surface timing will be +/- this many meters. May
%     be overridden by waveform specific fields.
%   .Haltitude = nominal meters above ground level. May
%     be overridden by waveform specific fields.
%   .Hice_thick = meters of ice thickness. May
%     be overridden by waveform specific fields.
%   .rg_start_offset = adjust the range gate start by this amount in meters.
%     Positive values make the start later (i.e. shorter range gate).
%   .rg_stop_offset: adjust the range gate stop by this amount in meters.
%     Positive values make the stop later (i.e. lengthen the range gate).
%   .start_ref: cell array containing 'surface' or 'bottom' for each
%     waveform. The start time is relative to the specified reference. The
%     default is the surface.
%   .stop_ref: cell array containing 'surface' or 'bottom' for each
%     waveform. The stop time is relative to the specified reference. The
%     default is the bottom.
%  .fn = output filename
%  .prf = pulse repetition frequency (Hz)
%  .presums = row vector of presums for each waveform
%  .wfs = struct array of waveform definitions
%   .atten = receiver attenuator settings (same for all channels)
%   .delay = 1x8 row vector of optimal transmit delays (ns)
%   .f0 = start frequency (Hz)
%   .f1 = stop frequency (Hz)
%   .tx_mask = 1x8 row vector of logicals (1 disables transmit)
%   .tg = waveform specific time gate fields
%    .altitude_guard = surface timing will be +/- this many meters
%    .Haltitude = nominal meters above ground level
%    .Hice_thick = meters of ice thickness
%   .tx_weights = 1x8 row vector of DDS amplitudes (will be scaled to max_tx)
%   .tukey = Tukey weighting to use on transmit pulse
%   .Tpd = pulse duration in seconds
%   .phase = 1x8 row vector of optimal transmit phase weights (deg)
%   .f0 = start frequency (Hz) if not specified in .wfs field
%   .f1 = stop frequency (Hz) if not specified in .wfs field
%
% param.wfs.delay = [1 0 0 0 0 0 0 0]: causes channel 1 to transmit 1 ns later
%   than all the other channels.
% param.phase = [30 0 0 0 0 0 0 0]: causes channel 1 to lead in phase by 30
%   deg
% param.tx_weights = [2 1 1 1 1 1 1 1]: causes channel 1 to be twice the
%   voltage of the other channels (i.e. 4x the power)
%
% Examples: see create_settings_SEASON_NAME.m
%
% Author: John Paden
%
% See also read_cresis_xml.m

physical_constants;

[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);

xml_version = param.xml_version;
cresis_xml_mapping;

if isfield(param,'TTL_clock') && ~isempty(param.TTL_clock)
  TTL_clock = param.TTL_clock;
else
  error('param.TTL_clock field missing');
end

if isfield(param,'TTL_prog_delay') && ~isempty(param.TTL_prog_delay)
  TTL_prog_delay = param.TTL_prog_delay;
else
  error('param.TTL_prog_delay field missing');
end

if isfield(param,'fs_dds') && ~isempty(param.fs_dds)
  fs_dds = param.fs_dds;
else
  error('param.fs_dds field missing');
end

if isfield(param,'fs') && ~isempty(param.fs)
  fs = param.fs;
else
  error('param.fs field missing');
end

if isfield(param,'fs_sync') && ~isempty(param.fs_sync)
  fs_sync = param.fs_sync;
else
  error('param.fs_sync field missing');
end

if isfield(param,'TTL_mode') && ~isempty(param.TTL_mode)
  % Duration before start of pulse, duration after pulse, offset of pulse
  % from TTL_prog_delay * fs/2
  % For example 2014 Ant DC8: [1.3e-6 0.3e-6 -880e-9]
  TTL_mode = param.TTL_mode;
else
  TTL_mode = {};
end

if isfield(param,'DDC_select') && ~isempty(param.DDC_select)
  DDC_select = param.DDC_select;
else
  DDC_select = 0;
end

if isfield(param,'Tpd_base_duration') && ~isempty(param.Tpd_base_duration)
  % Manually set the base pulse duration
  Tpd_base_duration = param.Tpd_base_duration;
else
  Tpd_base_duration = 1e-6;
end

if isfield(param,'PRI_guard') && ~isempty(param.PRI_guard)
  % Manually set the PRI time guard
  PRI_guard = param.PRI_guard;
else
  PRI_guard = 1e-6;
end

if isfield(param,'sample_size') && ~isempty(param.sample_size)
  % Manually set the PRI time guard
  sample_size = param.sample_size;
else
  sample_size = 2;
end

if isfield(param,'max_tx') && ~isempty(param.max_tx)
  % Maximum DDS output setting
  max_DDS_amp = param.max_tx;
elseif isfield(param,'max_DDS_amp') && ~isempty(param.max_DDS_amp)
  % Maximum DDS output setting
  max_DDS_amp = param.max_DDS_amp;
end

settings_enc(1).('Version') = reshape(char(param.version),[1 length(param.version)]);
if isfield(param,'DDC_freq')
  %% DDC Settings
  settings_enc(1).DDCZ20Ctrl.NCOZ20freq = reshape(uint32(param.DDC_freq/1e6),[1 1]);
  settings_enc(1).DDCZ20Ctrl.DDCZ20sel.Val = reshape(uint32(DDC_select),[1 1]);
  settings_enc(1).DDCZ20Ctrl.DDCZ20sel.Choice = {'Non DDC','DDC4 En','DDC8 En'};
  settings_enc(1).DDCZ20Ctrl.samplingZ20freq = reshape(double(fs/1e6),[1 1]);
end
settings_enc(1).(config_var_enc)(1).('SYNCZ20CLK') = reshape(double(fs_sync),[1 1]);
settings_enc(1).(config_var_enc)(1).('PRF') = reshape(double(param.prf),[1 1]);
settings_enc(1).(config_var_enc)(1).('Delay') = reshape(uint16(TTL_prog_delay),[1 1]);
settings_enc(1).(config_var_enc)(1).('BaseZ20Len') = reshape(double(Tpd_base_duration),[1 1]);
settings_enc(1).(config_var_enc)(1).('RAMZ20Taper') = reshape(double(param.tukey),[1 1]);
settings_enc(1).(config_var_enc)(1).('AUXZ20DACZ20Z28HEXZ29') = reshape(uint8(param.aux_dac),[1 8]);
if any(param.tx_weights > max_DDS_amp)
  error('Tx weights too high');
end
settings_enc(1).(config_var_enc)(1).(ram_amp_var_enc) = reshape(uint16(param.tx_weights),[1 8]);

if length(param.wfs)*(1+param.create_IQ) > 16
  error('Too many waveforms');
end
if param.create_IQ
  settings_enc(1).(config_var_enc)(1).(wave_var_enc) = reshape(int32(2*length(param.wfs)),[1 1]);
else
  settings_enc(1).(config_var_enc)(1).(wave_var_enc) = reshape(int32(length(param.wfs)),[1 1]);
end

duty_cycle = 0;
for wf = 1:length(param.wfs)
  if isfield(param,'Tpd')
    param.wfs(wf).Tpd = param.Tpd;
  end
  param.wfs(wf).Tpd = floor(param.wfs(wf).Tpd/Tpd_base_duration) * Tpd_base_duration;
  duty_cycle = duty_cycle + param.presums(wf)/sum(param.presums)*param.wfs(wf).Tpd*param.prf;
end
if duty_cycle > param.max_duty_cycle
  error('Duty cycle too high');
end

%% Convert staged_recording logical setting (0 or 1) into array of
% waveform positions in the staged recording. Staged recording is used to
% record overlapping range gates with different gains to provide a single
% long record with time varying dynamic range. The pulse durations and
% height information are used to do this. Usually the first waveform
% is a low gain waveform for the first part of the return and a second high
% gain waveform is for the second part of the return.  The return can be
% broken into any number of waveforms.  All returns in a given stage are
% assumed to have the same pulse duration and only the first waveform in
% each stage is examined to determine the range gates.
% First stage is assumed to desire capture of ice surface (Haltitude)
% Last stage is assumed to desire capture of ice bottom (Haltitude,
% Hice_thick)
%
% Examples:
%
% An empty array or zero causes every waveform to capture the whole range
% gate. An array with just a one in it, causes the default staged recording
% approach which is waveform N is the Nth stage.
%
% param.tg.staged_recording: [1 2 3]
%   This would cause waveform 1 to be the first stage
%   waveform 2 to be the second stage
%   waveform 3 to be the third stage
%
% param.tg.staged_recording: [3 2 1]
%   This would cause waveform 3 to be the first stage
%   waveform 2 to be the second stage
%   waveform 1 to be the third stage
%
% param.tg.staged_recording: [1 2 3 3 3]
%   This would cause waveform 1 to be the first stage
%   waveform 2 to be the second stage
%   waveform 3, 4, and 5 to be the third stage
if ~isempty(param.tg.staged_recording)
  if all(param.tg.staged_recording == 0)
    param.tg.staged_recording = zeros(size(param.wfs));
  elseif length(param.tg.staged_recording) ~= length(param.wfs)
    param.tg.staged_recording = 1:length(param.wfs);
  end
end

%% Create the outputs for each waveform
for wf = 1:length(param.wfs)
  Tpd = param.wfs(wf).Tpd;
  
  if ~isfield(param.wfs,'name')
    param.wfs(wf).name = '';
  end
  
  if isfield(param,'phase')
    phase_setting = param.phase;
  else
    phase_setting = param.wfs(wf).phase;
  end
  settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).(phase_var_enc) = reshape(double(phase_setting),[1 8]);
  
  %% TTL Settings
  if ~isempty(TTL_mode)
    if ischar(TTL_mode)
      % TTL_mode = 'rx_only'
      % Receive only mode (TTL transmit mode is never asserted)
      TTL_start = 0;
      TTL_duration(1:8) = 0;
    elseif any(strcmpi(radar_name,{'mcords3','mcords4','mcords5'}))
      % Duration before start of pulse, duration after pulse, offset of pulse
      % from TTL_prog_delay * fs/2
      % For example 2015 Gr LC130: [2.5e-6 260e-9 -1100e-9]
      TTL_start = round((TTL_prog_delay/TTL_clock + TTL_mode(3) - TTL_mode(1))*TTL_clock);
      TTL_start_desired = (TTL_prog_delay/TTL_clock + TTL_mode(3) - TTL_mode(1))*TTL_clock;
      TTL_duration(1:8) = round((TTL_mode(1) + TTL_mode(2) + Tpd + (TTL_start_desired-TTL_start)/TTL_clock) * TTL_clock);
    else
      error('Not supported');
    end
    
    settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).(ttl_start_var_enc) = reshape(uint16(TTL_start*ones([1 8],'uint16')),[1 8]);
    settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).(ttl_length_var_enc) = reshape(uint16(TTL_duration),[1 8]);
    
  else
    if strcmpi(radar_name,'mcords3')
      % TTL start time (317 for 1e9/9 fs clock and 650 TTL delay)
      TTL_start = TTL_prog_delay + round((317-650) / (1e9/9/2) * fs/2);
      
      % TTL1 length (original durations were for 1e9/9 fs clock)
      x = [1 3 10]*1e-6;
      y = [354 472 845] / (1e9/9/2) * fs/2;
      %plot(x,y);
      p = polyfit(x,y,1);
      TTL_duration = round(polyval(p,Tpd));
      
      % TTL2 length (original durations were for 1e9/9 fs clock)
      x = [1 3 10]*1e-6;
      y = [390 495 888] / (1e9/9/2) * fs/2;
      %plot(x,y);
      p = polyfit(x,y,1);
      TTL_duration(2:8) = round(polyval(p,Tpd));
      
      settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).(ttl_start_var_enc) = reshape(uint16(TTL_start*ones([1 8],'uint16')),[1 8]);
      settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).(ttl_length_var_enc) = reshape(uint16(TTL_duration),[1 8]);
      
    elseif strcmpi(radar_name,'mcords4')
      settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).(ttl_start_var_enc) = reshape(uint16(542*ones([1 8],'uint16')),[1 8]);
      
      x = [1 3 10]*1e-6;
      y = [126 251 689];
      %plot(x,y);
      p = polyfit(x,y,1);
      TTL_duration = round(polyval(p,Tpd));
      
      settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).(ttl_length_var_enc) = reshape(uint16(TTL_duration*ones([1 8],'uint16')),[1 8]);
      
    elseif strcmpi(radar_name,'mcords5')
      error('Not supported');
    end
    
  end
  
  atten = param.wfs(wf).atten;
  atten = round(atten*2)/2;
  atten1 = uint8(atten - 31.5);
  atten2 = uint8(atten - double(atten1));
  
  if length(atten1) == 1
    if strcmpi(radar_name,'mcords3')
      %       settings_enc(1).Atten.('AttenZ20Z30') = reshape(uint8(atten1*ones([1 8],'uint8')),[1 8]);
      %       settings_enc(1).Atten.('AttenZ31') = reshape(uint8(atten2*ones([1 8],'uint8')),[1 8]);
    end
    settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).('AttenuatorZ20Z31') = reshape(uint8(atten1*ones([1 8],'uint8')),[1 8]);
    settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).('AttenuatorZ20Z32') = reshape(uint8(atten2*ones([1 8],'uint8')),[1 8]);
  else
    if strcmpi(radar_name,'mcords3')
      %       settings_enc(1).Atten.('AttenZ20Z30') = reshape(uint8(atten1),[1 8]);
      %       settings_enc(1).Atten.('AttenZ31') = reshape(uint8(atten2),[1 8]);
    end
    settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).('AttenuatorZ20Z31') = reshape(uint8(atten1),[1 8]);
    settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).('AttenuatorZ20Z32') = reshape(uint8(atten2),[1 8]);
  end
  
  settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).('LenZ20Mult') ...
    = reshape(uint16(round(Tpd/Tpd_base_duration)),[1 1]);
  settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).('Presums') ...
    = reshape(uint16(param.presums(wf)),[1 1]);
  
  if isfield(param,'tx_mask')
    tx_mask_masked = param.tx_mask;
  else
    tx_mask_masked = param.wfs(wf).tx_mask;
  end
  if isfield(param,'final_tx_mask')
    tx_mask_masked = tx_mask_masked | param.final_tx_mask;
  end
  tx_mask = bin2dec(char('0' + tx_mask_masked));
  settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).('TXZ20Mask') = reshape(uint8(tx_mask),[1 1]);
  
  if isfield(param,'sys_delay')
    Tsystem_delay = param.sys_delay;
  else
    error('You need to set param.sys_delay. Old value was 10.6e-6.');
    %Tsystem_delay = 10.6e-6; % 10.6 us to program DDS
  end
  
  Tguard = [];
  Haltitude = [];
  Hice_thick = [];
  if isfield(param,'wfs') && length(param.wfs) >= wf && isfield(param.wfs(wf),'tg')
    if isfield(param.wfs(wf).tg,'altitude_guard') && ~isempty(param.wfs(wf).tg.altitude_guard)
      Tguard = param.wfs(wf).tg.altitude_guard / (3e8/2);
    else
      Tguard = param.tg.altitude_guard / (3e8/2);
    end
    if isfield(param.wfs(wf).tg,'Haltitude') && ~isempty(param.wfs(wf).tg.Haltitude)
      Haltitude = param.wfs(wf).tg.Haltitude;
    else
      Haltitude = param.tg.Haltitude;
    end
    if isfield(param.wfs(wf).tg,'Hice_thick') && ~isempty(param.wfs(wf).tg.Hice_thick)
      Hice_thick = param.wfs(wf).tg.Hice_thick;
    else
      Hice_thick = param.tg.Hice_thick;
    end
  end
  if isempty(Tguard)
    Tguard = param.tg.altitude_guard / (3e8/2);
  end
  if isempty(Haltitude)
    Haltitude = param.tg.Haltitude;
  end
  if isempty(Hice_thick)
    Hice_thick = param.tg.Hice_thick;
  end
  
  if isfield(param.tg,'look_angle_deg')
    look_angle_deg = param.tg.look_angle_deg(wf);
  else
    look_angle_deg = 0;
  end
  
  if isfield(param.tg,'start_ref')
    start_ref = param.tg.start_ref{wf};
  else
    start_ref = 'surface';
  end
  if isfield(param.tg,'stop_ref')
    stop_ref = param.tg.stop_ref{wf};
  else
    stop_ref = '';
  end
  
  if isfield(param.tg,'rg_start_offset')
    Trg_start_offset = param.tg.rg_start_offset(wf) / (3e8/2);
  else
    Trg_start_offset = 0;
  end
  if isfield(param.tg,'rg_stop_offset')
    Trg_stop_offset = param.tg.rg_stop_offset(wf) / (3e8/2);
  else
    Trg_stop_offset = 0;
  end
  if isfield(param.tg,'Hice_thick_min')
    Hice_thick_min = param.tg.Hice_thick_min;
  else
    Hice_thick_min = 0;
  end
  
  look_angle_ice_deg = asind(sind(look_angle_deg)/sqrt(er_ice));
  current_stage = param.tg.staged_recording(wf);
  next_stage_wf = find(param.tg.staged_recording == current_stage+1,1);
  if strcmpi(start_ref,'surface')
    Tstart_ref = Haltitude / (3e8/2);
  elseif strcmpi(start_ref,'bottom')
    Tstart_ref = Haltitude / (3e8/2) + Hice_thick_min / (3e8/2/sqrt(er_ice));
  else
    error('Invalid start ref %s', start_ref);
  end
  if strcmpi(stop_ref,'surface')
    Tstop_ref = Haltitude/cosd(look_angle_deg) / (3e8/2);
  elseif strcmpi(stop_ref,'bottom')
    Tstop_ref = Haltitude/cosd(look_angle_deg) / (3e8/2) + Hice_thick/cosd(look_angle_ice_deg) / (3e8/2/sqrt(er_ice));
  elseif isempty(stop_ref)
    if current_stage > 0 && ~isempty(next_stage_wf)
      % First and in between stages default references surface
      Tstop_ref = Haltitude/cosd(look_angle_deg) / (3e8/2);
    else
      % Last stage default reference is bottom
      Tstop_ref = Haltitude/cosd(look_angle_deg) / (3e8/2) + Hice_thick/cosd(look_angle_ice_deg) / (3e8/2/sqrt(er_ice));
    end
  else
    error('Invalid start ref %s', start_ref);
  end
  
  if current_stage == 0
    % Record the whole range gate
    Tstart = Tstart_ref;
    Tend = Tstop_ref;
  elseif current_stage == 1
    % First Stage
    Tstart = Tstart_ref;
    if ~isempty(next_stage_wf)
      % Cover the pulse duration of the next waveform after the surface
      % return + any off nadir scattering that is to be caught.
      Tend = max(Tstart_ref + param.wfs(next_stage_wf).Tpd, Tstop_ref);
    else
      % Also the last stage
      Tend = Tstart_ref + Hice_thick / (3e8/2/sqrt(er_ice));
    end
  elseif isempty(next_stage_wf)
    % Last Stage
    Tstart = Tstart_ref + param.wfs(wf).Tpd;
    Tend = Tstop_ref;
  else
    % In between first and last stage
    Tstart = Tstart_ref + param.wfs(wf).Tpd;
    Tend = max(Tstart_ref + param.wfs(next_stage_wf).Tpd, Tstop_ref);
  end
  
  if strcmpi(radar_name,'mcords3')
    samples_per_record_bin = 1;
  elseif any(strcmpi(radar_name,{'mcords4','mcords5'}))
    samples_per_record_bin = 8;
  else
    error('Unsupported radar')
  end
  bin_start = round(((Tstart + Tsystem_delay - Tguard + Trg_start_offset)  * fs/samples_per_record_bin)/8)*8;
  bin_stop = round(((Tend + param.wfs(wf).Tpd + Tguard + Tsystem_delay + Trg_stop_offset)  * fs/samples_per_record_bin)/8)*8;
  
  settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).('RecordZ20Stop') = reshape(uint16(bin_stop),[1 1]);
  if uint16(bin_start) < 32
    % Force record start to be at least 32
    settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).('RecordZ20Start') = reshape(uint16(32),[1 1]);
  else
    settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).('RecordZ20Start') = reshape(uint16(bin_start),[1 1]);
  end
  
  if isfield(param,'f0')
    f0 = param.f0;
  else
    f0 = param.wfs(wf).f0;
  end
  if isfield(param,'f1')
    f1 = param.f1;
  else
    f1 = param.wfs(wf).f1;
  end
  if f0 > f1
    f0 = fs_dds - f0;
    f1 = fs_dds - f1;
  end
  settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).('StartZ20Freq') ...
    = reshape(double(f0*ones([1  8])),[1 8]);
  settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).('StopZ20Freq') ...
    = reshape(double(f1*ones([1  8])),[1 8]);
  
  if isfield(param,'delay')
    delay = param.delay;
  else
    delay = param.wfs(wf).delay;
  end
  settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).('Delay') ...
    = reshape(double(delay),[1 8]);
end

if param.create_IQ
  settings_enc(1).(config_var_enc)(1).('Waveforms') ...
    = settings_enc(1).(config_var_enc)(1).('Waveforms')(reshape([1:length(param.wfs); 1:length(param.wfs)],[1 2*length(param.wfs)]));
  for wf = 2:2:length(settings_enc(1).(config_var_enc)(1).('Waveforms'))
    settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).(phase_var_enc) ...
      = angle(exp(j*settings_enc(1).(config_var_enc)(1).('Waveforms')(wf).(phase_var_enc)/180*pi + j*pi/2))*180/pi;
  end
end

if strcmpi(radar_name,'mcords4')
  settings_enc(1).('FPGAZ20Configuration')(1).('HIZ20Presums') = reshape(uint8([50 ]),[1 1]);
  settings_enc(1).('FPGAZ20Configuration')(1).('HIZ20UpdateZ23') = reshape(uint8([0 ]),[1 1]);
  settings_enc(1).('FPGAZ20Configuration')(1).('HIZ20Z20WaveformZ23') = reshape(uint8([0 ]),[1 1]);
  settings_enc(1).('FPGAZ20Configuration')(1).('HIZ20cntZ20rst') = reshape(logical([0 ]),[1 1]);
end

out_xml_fn = param.fn;

%% Write output
fprintf('Writing %s\n', out_xml_fn);

% Check data rate
num_sam = 0;
presums = 0;
for wf = 1:length(settings_enc.(config_var_enc).Waveforms)
  num_sam = num_sam + double(settings_enc.(config_var_enc).Waveforms(wf).RecordZ20Stop - settings_enc.(config_var_enc).Waveforms(wf).RecordZ20Start);
  presums = presums + double(settings_enc.(config_var_enc).Waveforms(wf).Presums);
end
EPRF = double(settings_enc.(config_var_enc).PRF) / presums;

data_rate = EPRF * num_sam * samples_per_record_bin * sample_size * param.num_chan / 2^DDC_select;

fprintf('  EPRF: %.1f Hz\n', EPRF);
lambda_fc = 3e8/ (0.5*(settings_enc.(config_var_enc).Waveforms(1).StopZ20Freq(1) + settings_enc.(config_var_enc).Waveforms(1).StartZ20Freq(1)));
fprintf('  fc Nyquist sampling rate velocity: %.1f m/s (%.1f knots)\n', lambda_fc/4 * EPRF, lambda_fc/4 * EPRF / 0.5515)
fprintf('  Data rate: %.1f MB/sec (%.1f hours: %.1f TB)\n', data_rate / 2^20, param.flight_hours, param.flight_hours*3600*data_rate/2^40);

if 1/settings_enc.(config_var_enc).PRF - PRI_guard - double(settings_enc.(config_var_enc).Waveforms(wf).RecordZ20Stop)/(fs/samples_per_record_bin) <= 0
  error('Data recording window, %.2f us, is too long for this PRI, %.2f us, including %.2f us time guard', ...
    double(settings_enc.(config_var_enc).Waveforms(wf).RecordZ20Stop)/(fs/samples_per_record_bin)*1e6, 1/settings_enc.(config_var_enc).PRF*1e6, PRI_guard*1e6);
end

if data_rate / 2^20 > param.max_data_rate
  error('Data rate %f MB/sec is too high', data_rate/2^20);
end

if xml_version >= 2.0
  settings_enc.sys.DDCZ20Ctrl = settings_enc.DDCZ20Ctrl;
  settings_enc.sys.DDSZ5FSetup = settings_enc.DDSZ5FSetup;
  settings_enc.sys.XMLZ20FileZ20Path = {struct('type','Path','values',[])};
  settings_enc.sys.XMLZ20FileZ20Path{1}.values = {out_xml_fn};
  settings_enc.sys.xmlversion = {struct('type','String','values',[])};
  settings_enc.sys.xmlversion{1}.values = {'2.0'};
  settings_enc = rmfield(settings_enc,'DDCZ20Ctrl');
  settings_enc = rmfield(settings_enc,'DDSZ5FSetup');
end

out_xml_fn_dir = fileparts(out_xml_fn);
if ~exist(out_xml_fn_dir,'dir')
  mkdir(out_xml_fn_dir);
end
[fid,msg] = fopen(out_xml_fn,'w');
if fid == -1
  error(msg);
end
fprintf(fid,'<?xml version=''1.0'' standalone=''yes'' ?>\n');
fprintf(fid,'<LVData xmlns="http://www.ni.com/LVData">\n');
write_ni_xml_object(settings_enc,fid,true,struct('array_list','Waveforms','enum_list','DDCZ20sel'));
fprintf(fid,'</LVData>');
fclose(fid);

%% Write RSS Arena XML config file
if isfield(param,'arena')
  % Defaults
  if ~isfield(param.arena,'dacs_internal_delay') || isempty(param.arena.dacs_internal_delay)
    param.arena.dacs_internal_delay = 0;
  end
  if ~isfield(param.arena,'dacs_start_delay') || isempty(param.arena.dacs_start_delay)
    param.arena.dacs_start_delay = 0;
  end
  
  % Create arena parameter structure
  arena = param.arena;
%   arena.awg = param.arena.awg;
  arena.dac = param.arena.dac;
%   arena.dacs_sampFreq = param.arena.dacs_sampFreq;
  arena.dacs_internal_delay = param.arena.dacs_internal_delay;
  arena.dacs_start_delay = param.arena.dacs_start_delay;
  arena.zeropimods = param.arena.zeropimods;
  arena.TTL_time = param.arena.TTL_time;
  arena.TTL_names = param.arena.TTL_names;
  arena.TTL_states = param.arena.TTL_states;
  % Ensure non-negative delays
  min_delay = inf;
  for wf = 1:length(settings_enc.sys.DDSZ5FSetup.Waveforms)
    if min(settings_enc.sys.DDSZ5FSetup.Waveforms(wf).Delay) < min_delay
      min_delay = min(settings_enc.sys.DDSZ5FSetup.Waveforms(wf).Delay);
    end
  end
  for wf = 1:length(settings_enc.sys.DDSZ5FSetup.Waveforms)
    arena.PRI = 1 / settings_enc.sys.DDSZ5FSetup.PRF;
    arena.wfs(wf).zeropimods = param.arena.zeropimods;
    arena.wfs(wf).name = param.wfs(wf).name;
    arena.wfs(wf).tukey = settings_enc.sys.DDSZ5FSetup.RAMZ20Taper;
    arena.wfs(wf).enabled = fliplr(~logical(dec2bin(settings_enc.sys.DDSZ5FSetup.Waveforms(wf).TXZ20Mask(1),8)-'0'));
    arena.wfs(wf).scale = double(settings_enc.sys.DDSZ5FSetup.RamZ20Amplitude) .* param.arena.max_tx ./ max_DDS_amp;
      arena.wfs(wf).f0 = settings_enc.sys.DDSZ5FSetup.Waveforms(wf).StartZ20Freq;
      arena.wfs(wf).f1 = settings_enc.sys.DDSZ5FSetup.Waveforms(wf).StopZ20Freq;
%     arena.wfs(wf).fc = (settings_enc.sys.DDSZ5FSetup.Waveforms(wf).StartZ20Freq ...
%       + settings_enc.sys.DDSZ5FSetup.Waveforms(wf).StopZ20Freq)/2;
%     arena.wfs(wf).BW = abs(settings_enc.sys.DDSZ5FSetup.Waveforms(wf).StopZ20Freq ...
%       - settings_enc.sys.DDSZ5FSetup.Waveforms(wf).StartZ20Freq);
    arena.wfs(wf).delay = settings_enc.sys.DDSZ5FSetup.Waveforms(wf).Delay - min_delay;
    arena.wfs(wf).phase = settings_enc.sys.DDSZ5FSetup.Waveforms(wf).PhaseZ20Offset;
    arena.wfs(wf).Tpd = double(settings_enc.sys.DDSZ5FSetup.Waveforms(wf).LenZ20Mult) ...
      * settings_enc.sys.DDSZ5FSetup.BaseZ20Len;
    arena.wfs(wf).presums = settings_enc.sys.DDSZ5FSetup.Waveforms(wf).Presums;
  end

    % Create XML document
    xml_param = param;
    xml_param.wfs = arena.wfs;
    xml_param.prf = 1/arena.PRI;
    xml_param.arena = arena;
    xml_param.arena.adc = [];
    xml_param.board_map = {};

    [~,xml_param.arena.psc_name] = ct_fileparts(out_xml_fn);
    xml_param.arena.fn = fullfile(param.arena_base_dir,[xml_param.arena.psc_name '.xml']);

    [doc,xml_param] = write_arena_xml([],xml_param);

    % Create XML document
    out_str = xmlwrite(doc);
    out_str = ['<!DOCTYPE systemXML>' out_str(find(out_str==10,1):end)];
    arena_fn_dir = fileparts(xml_param.arena.fn);
    if ~exist(arena_fn_dir,'dir')
      mkdir(arena_fn_dir);
    end
    fprintf('  Writing Arena XML: %s\n', xml_param.arena.fn);
    [fid,msg] = fopen(xml_param.arena.fn,'w');
    if fid == -1
      error(msg);
    end
    fwrite(fid,out_str,'char');
    fclose(fid);
  
end

return;

