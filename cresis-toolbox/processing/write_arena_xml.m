function [doc,param] = write_arena_xml(doc,param)
% [doc,param] = write_arena_xml(doc,param)
%
% doc: set to [] to create a new document, or pass in the result of a
%   previous call to write_arena_xml to continue adding to an existing
%   document
% param: structure describing how to populate XML parameters
%  .wfs: structure describing how to populate waveforms
%  .arena: structure describing how to populate arena specific parameters
%    .ctu.out.bit_group.epri: describes waveform during EPRI pulse, cell
%      array with one entry for each waveform, each entry is a list of
%      values for each sequence that the CTU generates
%    .ctu.out.bit_group.pri: same as epri except for PRI pulses
%
% doc: JAVA XML document class
%
% Author: John Paden
%
% See also: read_arena_xml, read_cresis_xml, write_arena_xml, write_ni_xml,
% write_radar_xml

%% Input checks
for wf = 1:length(param.wfs)
  if ~isfield(param.wfs(wf),'f0') || isempty(param.wfs(wf).f0)
    param.wfs(wf).f0 = param.f0;
  end
  if ~isfield(param.wfs(wf),'f1') || isempty(param.wfs(wf).f1)
    param.wfs(wf).f1 = param.f1;
  end
  if (~isfield(param.wfs(wf),'DDC_freq') || isempty(param.wfs(wf).DDC_freq)) && isfield(param,'DDC_freq')
    param.wfs(wf).DDC_freq = param.DDC_freq;
  end
  if ~isfield(param.wfs(wf),'tukey') || isempty(param.wfs(wf).tukey)
    param.wfs(wf).tukey = param.tukey;
  end
  if ~isfield(param.wfs(wf),'Tpd') || isempty(param.wfs(wf).Tpd)
    param.wfs(wf).Tpd = param.Tpd;
  end
  if ~isfield(param.wfs(wf),'zeropimods') || isempty(param.wfs(wf).zeropimods)
    param.wfs(wf).zeropimods = param.zeropimods;
  end
  if ~isfield(param.wfs,'name')
    param.wfs(wf).name = '';
  end
  if ~isfield(param.wfs(wf),'phase') || isempty(param.wfs(wf).phase)
    param.wfs(wf).phase = param.phase;
  end
  if ~isfield(param.wfs(wf),'delay') || isempty(param.wfs(wf).delay)
    param.wfs(wf).delay = param.delay;
  end
  if (~isfield(param.wfs(wf),'tx_enable') || isempty(param.wfs(wf).tx_enable)) && isfield(param.config,'tx_enable')
    param.wfs(wf).tx_enable = param.config.tx_enable;
  end
  if (~isfield(param.wfs(wf),'scale') || isempty(param.wfs(wf).scale)) && isfield(param,'scale')
    param.wfs(wf).scale = param.scale;
  end
  if any(param.wfs(wf).scale > param.config.max_tx)
    error('Tx weights param.wfs(%d).scale=%s > param.config.max_tx=%s for waveform %d', ...
      wf, mat2str_generic(param.wfs(wf).scale), mat2str_generic(param.config.max_tx), wf);
  end
end

%% Initialization

wfs = param.wfs;
arena = param.arena;

% Import the XPath classes
import javax.xml.xpath.*

% Create an XPath expression.
factory = XPathFactory.newInstance;
xpath = factory.newXPath;

doc = com.mathworks.xml.XMLUtils.createDocument('system');
system = doc.getDocumentElement;

configs = doc.createElement('configs');
system.appendChild(configs);

% Calculate effective pulse repetition interval (PSC repeat interval)
presums = 0;
for wf = 1:numel(param.wfs)
  presums = presums + param.wfs(wf).presums;
end
param.eprf = param.prf / presums;

%% Determine modes/sequences for each waveform
total_modes = 0;
total_indexes = 0;
for wf = 1:length(wfs)
  zeropimods = wfs(wf).zeropimods(:).';

  if strcmpi(arena.psc.type,'psc_0001')
    % psc_0001
    % =====================================================================
    % Does not support "next" field
    
    if numel(zeropimods) == 1
      % This waveform has only one phase in its zero_pi_mode sequence.
      zeropimod = zeropimods(1);
      
      if wf == 1 && wfs(wf).presums > 1
        % Need to add an EPRI mode since this is the first waveform and
        % there is more than 1 presum
        num_modes = 1;
        num_indexes = 1;
        wfs(wf).next = total_indexes+1;
        wfs(wf).repeat_to = total_indexes;
        wfs(wf).repeat_count = wfs(wf).presums/numel(zeropimods)-1;
      else
        num_modes = 2;
        num_indexes = 2;
        wfs(wf).next = total_indexes+[1 2];
        wfs(wf).repeat_to = total_indexes+1;
        wfs(wf).repeat_count = wfs(wf).presums/numel(zeropimods)-2;
      end
      wfs(wf).modes = total_modes+(0:num_modes-1);
      wfs(wf).epri = false(1,num_modes);
      wfs(wf).reset = false(1,num_modes);
      if zeropimod==180 || zeropimod==270
        wfs(wf).adc_zeropi = true(1,num_modes);
      else
        wfs(wf).adc_zeropi = false(1,num_modes);
      end
      if any(find(strcmpi('dac-ad9129_0014',{arena.dac.type})))
        % This DAC does not support tx_invert so a new waveform must be
        % loaded for each zero pi phase
        wfs(wf).zeropiphase = zeropimod*ones(1,num_modes);
        wfs(wf).tx_invert = false(1,num_modes);
      else
        if zeropimod==180 || zeropimod==270
          wfs(wf).tx_invert = true(1,num_modes);
        else
          wfs(wf).tx_invert = false(1,num_modes);
        end
        if zeropimod==90 || zeropimod==270
          wfs(wf).zeropiphase = 90*ones(1,num_modes);
        else
          wfs(wf).zeropiphase = zeros(1,num_modes);
        end
      end
      
    else
      % This waveform has more than one phase in the zero_pi_mode sequence.
      if mod(wfs(wf).presums,numel(zeropimods))
        error('The number of presums, wfs(wf).presums = %d, must be a multiple of numel(wfs(wf).zeropimods) = %d.', wfs(wf).presums, numel(wfs(wf).zeropimods));
      end

      wfs(wf).tx_invert = false(1,numel(zeropimods));
      wfs(wf).adc_zeropi = false(1,numel(zeropimods));
      wfs(wf).zeropiphase = zeros(1,numel(zeropimods));
      for zeropimod_idx = 1:numel(zeropimods)
        zeropimod = zeropimods(zeropimod_idx);
        if zeropimod==180 || zeropimod==270
          wfs(wf).adc_zeropi(zeropimod_idx) = true;
        else
          wfs(wf).adc_zeropi(zeropimod_idx) = false;
        end
        if any(find(strcmpi('dac-ad9129_0014',{arena.dac.type})))
          % This DAC does not support tx_invert so a new waveform must be
          % loaded for each zero pi phase
          wfs(wf).zeropiphase(zeropimod_idx) = zeropimod;
          wfs(wf).tx_invert(zeropimod_idx) = false;
        else
          if zeropimod==180 || zeropimod==270
            wfs(wf).tx_invert(zeropimod_idx) = true;
          else
            wfs(wf).tx_invert(zeropimod_idx) = false;
          end
          if zeropimod==90 || zeropimod==270
            wfs(wf).zeropiphase(zeropimod_idx) = 90;
          else
            wfs(wf).zeropiphase(zeropimod_idx) = 0;
          end
        end
      end

      if wf == 1 && wfs(wf).presums / numel(zeropimods) > 1
        % We cycle through the zero-pi modes more than once and the very
        % first mode needs to be the EPRI mode so we have to add an extra
        % index/mode to handle this special case. We therefore create a
        % one-time pass through the zero pi modes the first of which is
        % marked as the EPRI mode and the second and later passes through
        % the zero pi modes are not EPRI modes.
        num_modes = numel(zeropimods)+1;
        num_indexes = 2*numel(zeropimods);
        wfs(wf).tx_invert = wfs(wf).tx_invert([1:end, 1:end]);
        wfs(wf).adc_zeropi = wfs(wf).adc_zeropi([1:end, 1:end]);
        wfs(wf).zeropiphase = wfs(wf).zeropiphase([1:end, 1:end]);
        wfs(wf).next = total_indexes+[1:2*numel(zeropimods)];
        wfs(wf).repeat_to = zeros(1,2*numel(zeropimods));
        wfs(wf).repeat_to(end) = total_indexes+numel(zeropimods);
        wfs(wf).repeat_count = zeros(1,2*numel(zeropimods));
        wfs(wf).repeat_count(end) = wfs(wf).presums/numel(zeropimods)-2;
        wfs(wf).modes = total_modes+[0:numel(zeropimods) 1:numel(zeropimods)-1];
        wfs(wf).epri = false(1,2*numel(zeropimods));
        wfs(wf).reset = false(1,2*numel(zeropimods));

      else
        % This waveform does not require separate passes through the
        % zero-pi modes for EPRI and non-EPRI modes.
        num_modes = numel(zeropimods);
        num_indexes = numel(zeropimods);
        wfs(wf).next = total_indexes+(1:num_modes);
        wfs(wf).repeat_to = zeros(1,num_modes);
        wfs(wf).repeat_to(end) = total_indexes;
        wfs(wf).repeat_count = zeros(1,num_modes);
        wfs(wf).repeat_count(end) = wfs(wf).presums/numel(zeropimods)-1;
        wfs(wf).modes = total_modes+(0:num_modes-1);
        wfs(wf).epri = false(1,num_modes);
        wfs(wf).reset = false(1,num_modes);
      end

    end

  elseif strcmpi(arena.psc.type,'psc_0003')
    % psc_0003
    % =====================================================================
    % Sequence of modes goes:
    % For length(zeropimods) == 1
    %   If wf == 1
    % 1. Phase is zeropimods(1)
    %
    % For length(zeropimods) == N > 1
    % 1. Phase is zeropimods(1), eprireset integrator
    % 2. Phase is zeropimods(2)
    %   ...
    % N. Phase is zeropimods(N)
    % N+1. Phase is zeropimods(1)

    if numel(zeropimods) == 1
      % This waveform has only one phase in its zero_pi_mode sequence.
      zeropimod = zeropimods(1);

      % We use integrator reset, so more than one presum requires two
      % modes, one to reset and one to determine the number of presums
      if wfs(wf).presums > 1
        num_modes = 2;
        wfs(wf).reset = false(1,num_modes);
        wfs(wf).reset(1) = true;
        wfs(wf).next = total_modes+[1 2];
        wfs(wf).repeat_to = [0 total_modes+1];
        wfs(wf).repeat_count = [0 wfs(wf).presums/numel(zeropimods)-1];
      else
        % No presumming so no reset mode is required
        num_modes = 1;
        wfs(wf).reset = false(1,num_modes);
        wfs(wf).next = total_modes+[1];
        wfs(wf).repeat_to = 0;
        wfs(wf).repeat_count = 0;
      end
      if zeropimod==180 || zeropimod==270
        wfs(wf).adc_zeropi = true(1,num_modes);
      else
        wfs(wf).adc_zeropi = false(1,num_modes);
      end
      if any(find(strcmpi('dac-ad9129_0014',{arena.dac.type})))
        % This DAC does not support tx_invert so a new waveform must be
        % loaded for each zero pi phase
        wfs(wf).zeropiphase = zeropimod*ones(1,num_modes);
        wfs(wf).tx_invert = false(1,num_modes);
      else
        if zeropimod==180 || zeropimod==270
          wfs(wf).tx_invert = true(1,num_modes);
        else
          wfs(wf).tx_invert = false(1,num_modes);
        end
        if zeropimod==90 || zeropimod==270
          wfs(wf).zeropiphase = 90*ones(1,num_modes);
        else
          wfs(wf).zeropiphase = zeros(1,num_modes);
        end
      end

    else
      % This waveform has more than one phase in the zero_pi_mode sequence.
      if mod(wfs(wf).presums,numel(zeropimods))
        error('The number of presums, wfs(wf).presums = %d, must be a multiple of numel(wfs(wf).zeropimods) = %d.', wfs(wf).presums, numel(wfs(wf).zeropimods));
      end

      wfs(wf).tx_invert = false(1,numel(zeropimods));
      wfs(wf).adc_zeropi = false(1,numel(zeropimods));
      wfs(wf).zeropiphase = zeros(1,numel(zeropimods));
      for zeropimod_idx = 1:numel(zeropimods)
        zeropimod = zeropimods(zeropimod_idx);
        if zeropimod==180 || zeropimod==270
          wfs(wf).adc_zeropi(zeropimod_idx) = true;
        else
          wfs(wf).adc_zeropi(zeropimod_idx) = false;
        end
        if any(find(strcmpi('dac-ad9129_0014',{arena.dac.type})))
          % This DAC does not support tx_invert so a new waveform must be
          % loaded for each zero pi phase
          wfs(wf).zeropiphase(zeropimod_idx) = zeropimod;
          wfs(wf).tx_invert(zeropimod_idx) = false;
        else
          if zeropimod==180 || zeropimod==270
            wfs(wf).tx_invert(zeropimod_idx) = true;
          else
            wfs(wf).tx_invert(zeropimod_idx) = false;
          end
          if zeropimod==90 || zeropimod==270
            wfs(wf).zeropiphase(zeropimod_idx) = 90;
          else
            wfs(wf).zeropiphase(zeropimod_idx) = 0;
          end
        end
      end

      if wfs(wf).presums / numel(zeropimods) > 1
        % We use integrator reset, so more than one cycle through its zero pi
        % mode sequence requires a reset and a non-reset version of the first
        % zero pi mode in the sequence to reset the integrator. Two modes are
        % created for the first mode (except that the first one will be reset
        % and the second one will not be reset).
        num_modes = 1+numel(zeropimods);
        wfs(wf).tx_invert = wfs(wf).tx_invert([1 1 2:end]);
        wfs(wf).adc_zeropi = wfs(wf).adc_zeropi([1 1 2:end]);
        wfs(wf).zeropiphase = wfs(wf).zeropiphase([1 1 2:end]);
        wfs(wf).next = total_modes+[2 2:num_modes];
        wfs(wf).repeat_to = zeros(1,num_modes);
        wfs(wf).repeat_to(end) = total_modes+1;
        wfs(wf).repeat_count = zeros(1,num_modes);
        wfs(wf).repeat_count(end) = wfs(wf).presums/numel(zeropimods)-1;

      else
        % This waveform has only one cycle through zero pi mode sequence, so
        % we don't need a reset and non-reset mode for the first zero pi
        % mode in the sequence.
        num_modes = numel(zeropimods);
        wfs(wf).next = total_modes+(1:num_modes);
        wfs(wf).repeat_to = zeros(1,num_modes);
        wfs(wf).repeat_count = zeros(1,num_modes);
      end
      % A reset is always required with zero pi modulation, because there is
      % always more than one pulse being averaged.
      wfs(wf).reset = false(1,num_modes);
      wfs(wf).reset(1) = true;

    end

    wfs(wf).modes = total_modes+(0:num_modes-1);
    wfs(wf).epri = false(1,num_modes);
    num_indexes = num_modes;

  else
    error('param.arena.psc.type must be psc_0001 or psc_0003. The correct version depends on the hardware firmware.');
  end

  % If this is the first waveform, then the epri is true for the first
  % mode of this waveform.
  if wf == 1
    wfs(wf).epri(1) = true;
  end

  % If the last waveform, then the next should go to the first mode
  if wf == length(wfs)
    wfs(wf).next(end) = 0;
  end

  total_modes = total_modes + num_modes;
  total_indexes = total_indexes + num_indexes;
end


%% param.records.data_map
num_psc = 0;
total_data_map = [];
for wf = 1:length(wfs)
  
  out_adc_idx = [];
  for adc_idx = 1:numel(arena.adc)
    adc = arena.adc(adc_idx);
    if adc.adcMode == 0 || adc.adcMode == 1
      num_subchannel = 1;
    elseif adc.adcMode == 2
      num_subchannel = 2;
    end
    
    board_idx = find(strcmpi(adc.name,param.board_map));
    
    mode_latch = wfs(wf).modes(end);
    
    for subchannel_id = 0:num_subchannel-1
      wf_set = 1;
      if isfield(adc,'wf_set') && ~isempty(adc.wf_set)
        wf_set = adc.wf_set;
      end
      if numel(out_adc_idx) < wf_set
        out_adc_idx(wf_set) = 1;
      else
        out_adc_idx(wf_set) = out_adc_idx(wf_set) + 1;
      end
      total_data_map(end+1,1:5) = [board_idx mode_latch subchannel_id (wf_set-1)*numel(wfs)+wf out_adc_idx(wf_set)];
    end
    
  end
end

if 0
  for board_idx = 1:length(param.board_map)
    mask = total_data_map(:,1) == board_idx;
    fprintf('board_idx %d\n', board_idx);
    data_map = total_data_map(mask,2:5)
  end
end

fprintf('  param.records.data_map = {');
for board_idx = 1:length(param.board_map)
  mask = total_data_map(:,1) == board_idx;
  data_map = total_data_map(mask,2:5);
  if board_idx > 1
    fprintf(',');
  end
  fprintf('%s',mat2str_generic(data_map));
end
fprintf('}\n');


%% ADC: adc-ad9680_0017
if isempty(arena.adc)
  adc_idxs = [];
else
  adc_idxs = find(strcmpi('adc-ad9680_0017',{arena.adc.type}));
end
param.data_rate = 0;
for adc_idx = adc_idxs
  
  adc = arena.adc(adc_idx);
  
  system = doc.getFirstChild;
  configs = system.getFirstChild;
  
  config = doc.createElement('config'); configs.appendChild(config);
  config.setAttribute('type',adc.type);
  
  child = doc.createElement('name'); config.appendChild(child);
  child.appendChild(doc.createTextNode(sprintf('%s',adc.name)));
  
  child = doc.createElement('description'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  
  child = doc.createElement('sampFreq'); config.appendChild(child);
  child.appendChild(doc.createTextNode(sprintf('%g',adc.sampFreq/1e6)));
  
  child = doc.createElement('adcMode'); config.appendChild(child);
  child.appendChild(doc.createTextNode(sprintf('%d',adc.adcMode)));
  if adc.adcMode == 0
    fs = adc.sampFreq;
    num_subchannel = 1;
  elseif adc.adcMode == 1
    fs = adc.sampFreq / 2;
    num_subchannel = 1;
  elseif adc.adcMode == 2
    fs = adc.sampFreq / 4;
    num_subchannel = 2;
  end
  
  child = doc.createElement('ddc0Adc'); config.appendChild(child);
  child.appendChild(doc.createTextNode('0'));
  
  child = doc.createElement('ddc1Adc'); config.appendChild(child);
  child.appendChild(doc.createTextNode('1'));
  
  if all(cell2mat({wfs.DDC_freq}) == 0)
    child = doc.createElement('ddc0NcoMode'); config.appendChild(child);
    child.appendChild(doc.createTextNode('0'));
    child = doc.createElement('ddc1NcoMode'); config.appendChild(child);
    child.appendChild(doc.createTextNode('0'));
    child = doc.createElement('ddc0NcoFreq'); config.appendChild(child);
    child.appendChild(doc.createTextNode('0'));
    child = doc.createElement('ddc1NcoFreq'); config.appendChild(child);
    child.appendChild(doc.createTextNode('0'));
  elseif all(cell2mat({wfs.DDC_freq}) == adc.sampFreq/4)
    child = doc.createElement('ddc0NcoMode'); config.appendChild(child);
    child.appendChild(doc.createTextNode('1'));
    child = doc.createElement('ddc1NcoMode'); config.appendChild(child);
    child.appendChild(doc.createTextNode('1'));
    child = doc.createElement('ddc0NcoFreq'); config.appendChild(child);
    child.appendChild(doc.createTextNode(sprintf('%g',wfs(1).DDC_freq/1e6)));
    child = doc.createElement('ddc1NcoFreq'); config.appendChild(child);
    child.appendChild(doc.createTextNode(sprintf('%g',wfs(1).DDC_freq/1e6)));
  elseif all(cell2mat({wfs.DDC_freq}) == wfs(1).DDC_freq)
    child = doc.createElement('ddc0NcoMode'); config.appendChild(child);
    child.appendChild(doc.createTextNode('2'));
    child = doc.createElement('ddc1NcoMode'); config.appendChild(child);
    child.appendChild(doc.createTextNode('2'));
    child = doc.createElement('ddc0NcoFreq'); config.appendChild(child);
    child.appendChild(doc.createTextNode(sprintf('%g',wfs(1).DDC_freq/1e6)));
    child = doc.createElement('ddc1NcoFreq'); config.appendChild(child);
    child.appendChild(doc.createTextNode(sprintf('%g',wfs(1).DDC_freq/1e6)));
  else
    error('wfs(wf).DDC_freq must be the same for all wf.');
  end
  
  subchannels = doc.createElement('subChannels'); config.appendChild(subchannels);

  for subchannel_idx = 1:num_subchannel
    
    subchannel = doc.createElement('subChannel'); subchannels.appendChild(subchannel);
    
    child = doc.createElement('id'); subchannel.appendChild(child);
    child.appendChild(doc.createTextNode( sprintf('%d',subchannel_idx-1) ));
    
    for wf = 1:length(wfs)
      modes = wfs(wf).modes;
      
      for mode_idx = 1:length(wfs(wf).modes)
        mode_latch = modes(mode_idx);
        
        digRx = doc.createElement('digRx'); subchannel.appendChild(digRx);
        
        child = doc.createElement('modes'); digRx.appendChild(child);
        child.appendChild(doc.createTextNode(sprintf('%d',mode_latch)));
        
        child = doc.createElement('adcDdcChannel'); digRx.appendChild(child);
        child.appendChild(doc.createTextNode( sprintf('%d',subchannel_idx-1) ));
        
        child = doc.createElement('bypass'); digRx.appendChild(child);
        child.appendChild(doc.createTextNode('1'));
        
        if wfs(wf).adc_zeropi(mode_idx)
          child = doc.createElement('zeroPi'); digRx.appendChild(child);
          child.appendChild(doc.createTextNode('1'));
        else
          child = doc.createElement('zeroPi'); digRx.appendChild(child);
          child.appendChild(doc.createTextNode('0'));
        end
        
        child = doc.createElement('ncoFreq'); digRx.appendChild(child);
        child.appendChild(doc.createTextNode('0'));
        
        child = doc.createElement('ncoPhase'); digRx.appendChild(child);
        child.appendChild(doc.createTextNode('0'));
        
        child = doc.createElement('decimation'); digRx.appendChild(child);
        child.appendChild(doc.createTextNode('1'));
      end
      
      integrator = doc.createElement('integrator'); subchannel.appendChild(integrator);
      
      child = doc.createElement('modes'); integrator.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%d:%d',modes(1),modes(end))));
      
      child = doc.createElement('rstModes'); integrator.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%d',modes(1))));
      
      child = doc.createElement('numInt'); integrator.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%d',wfs(wf).presums)));
      
      found = false;
      board_idx = find(strcmpi(adc.name,param.board_map));
      for map_idx=1:size(total_data_map,1)
        if isequal(total_data_map(map_idx,1:3), [board_idx mode_latch subchannel_idx-1])
          found = true;
          break;
        end
      end
      if ~found
        error('Could not find map in param.records.data_map for this data stream: [board_idx mode subchannel] = [%d %d %d].', [board_idx mode_latch subchannel_idx-1]);
      end
      wf_set = 1 + floor(( total_data_map(map_idx,4) - 1) / numel(wfs));
      Tstart = wfs(wf).Tstart{wf_set};
      Tend = wfs(wf).Tend{wf_set};
      clear found map_idx;
      start_bin = round( (Tstart+arena.param.PA_setup_time+arena.param.ADC_time_delay) *fs/8)*8;
      if start_bin < 0
        error('Start bin (%d) is less than zero. Increase start time wfs(%d).Tstart, %g.', start_bin, wf, Tstart);
      end
      Nt = round((Tend-Tstart)*fs/8)*8;
      stop_bin = start_bin + Nt-1;
      child = doc.createElement('rg'); integrator.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%d:%d',start_bin,stop_bin)));
      
      if adc.outputSelect == 1
        % Set bit shifts/bit_shift/bitshift
        
        % Field used to determine how many right shifts to apply (16 LSB after
        % shift are saved).
        shiftLSB = ceil(log2(max(cell2mat({wfs.presums}))));
        child = doc.createElement('shiftLSB'); integrator.appendChild(child);
        child.appendChild(doc.createTextNode( sprintf('%d', shiftLSB) ));
        child = doc.createElement('outputSelect'); integrator.appendChild(child);
        child.appendChild(doc.createTextNode( sprintf('%d', adc.outputSelect) ));
        param.data_rate = param.data_rate + Nt*4*param.eprf;
      elseif adc.outputSelect == 0
        % Field not used for 32 bit IQ records
        child = doc.createElement('shiftLSB'); integrator.appendChild(child);
        child.appendChild(doc.createTextNode( '0' ));
        child = doc.createElement('outputSelect'); integrator.appendChild(child);
        child.appendChild(doc.createTextNode( sprintf('%d', adc.outputSelect) ));
        param.data_rate = param.data_rate + Nt*8*param.eprf;
      else
        error('Invalid adc.outputSelect (%d)', adc.outputSelect);
      end
      
    end
    
    child = doc.createElement('coefficients'); subchannel.appendChild(child);
    B = [-2639,   650,   5580,   4956,   -2234,   -4562,   3195,   7530,   -1873,   -9996,   23,   12794,   3149,   -15261,   -7593,   17087,   13401,   -17768,   -20479,   16789,   28599,   -13618,   -37362,   7754,   46182,   1220,   -54308,   -13597,   60804,   29468,   -64619,   -48712,   64584,   70923,   -59485,   -95395,   48110,   121110,   -29288,   -146707,   1941,   170497,   34900,   -190452,   -82119,   204182,   140592,   -208843,   -211381,   200951,   296148,   -175880,   -397987,   126738,   523336,   -41506,   -686878,   -105268,   926999,   383082,   -1373977,   -1083207,   2862960,   7162362,   7162362,   2862960,   -1083207,   -1373977,   383082,   926999,   -105268,   -686878,   -41506,   523336,   126738,   -397987,   -175880,   296148,   200951,   -211381,   -208843,   140592,   204182,   -82119,   -190452,   34900,   170497,   1941,   -146707,   -29288,   121110,   48110,   -95395,   -59485,   70923,   64584,   -48712,   -64619,   29468,   60804,   -13597,   -54308,   1220,   46182,   7754,   -37362,   -13618,   28599,   16789,   -20479,   -17768,   13401,   17087,   -7593,   -15261,   3149,   12794,   23,   -9996,   -1873,   7530,   3195,   -4562,   -2234,   4956,   5580,   650,   -2639];
    coefficients_str = sprintf('%d',B(1));
    coefficients_str = [coefficients_str sprintf(',%d',B(2:end))];
    child.appendChild(doc.createTextNode(coefficients_str));
    
  end
  
  child = doc.createElement('nbufs'); config.appendChild(child);
  child.appendChild(doc.createTextNode('128'));
  
  child = doc.createElement('bufSize'); config.appendChild(child);
  child.appendChild(doc.createTextNode('8192'));
end

%% CTU: ctu_001D
if strcmpi(arena.ctu.type,'ctu_001D')
  
  system = doc.getFirstChild;
  configs = system.getFirstChild;
  
  config = doc.createElement('config'); configs.appendChild(config);
  config.setAttribute('type',arena.ctu.type);
  
  child = doc.createElement('name'); config.appendChild(child);
  child.appendChild(doc.createTextNode(arena.ctu.name));
  
  child = doc.createElement('description'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  
  for group_idx = 1:length(arena.ctu.out.bit_group)
    bit_group = arena.ctu.out.bit_group(group_idx);
    outputBitGrouping = doc.createElement('outputBitGrouping'); config.appendChild(outputBitGrouping);
    
    child = doc.createElement('name'); outputBitGrouping.appendChild(child);
    child.appendChild(doc.createTextNode(bit_group.name));
    
    bit_group.bits = sort(bit_group.bits);
    if length(bit_group.bits) == 1
      bit_str = sprintf('%d',bit_group.bits);
    elseif isequal(bit_group.bits,bit_group.bits(1):bit_group.bits(end))
      bit_str = sprintf('%d:%d',bit_group.bits(1),bit_group.bits(end));
    else
      bit_str = sprintf('%d',bit_group.bits(1));
      bit_str = [bit_str, sprintf(',%d',bit_group.bits(2:end))];
    end
    child = doc.createElement('bits'); outputBitGrouping.appendChild(child);
    child.appendChild(doc.createTextNode(bit_str));
  end
  
  for wf = 1:length(wfs)
    modes = wfs(wf).modes;
    if wfs(wf).epri(1)
      if numel(wfs(wf).modes) > 1
        fields = {'epri' 'pri'};
      else
        fields = {'epri'};
      end
    else
      fields = {'pri'};
    end
    for field = fields
      field = field{1};
      
      mode_xml = doc.createElement('mode'); config.appendChild(mode_xml);
      
      child = doc.createElement('id'); mode_xml.appendChild(child);
      if wfs(wf).epri(1)
        if strcmpi(field,'epri')
          child.appendChild(doc.createTextNode(sprintf('%d',modes(1))));
        else
          child.appendChild(doc.createTextNode(sprintf('%d:%d',modes(2),modes(end))));
        end
      else
        child.appendChild(doc.createTextNode(sprintf('%d:%d',modes(1),modes(end))));
      end
      
      child = doc.createElement('numSegments'); mode_xml.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%d',length(arena.ctu.out.time_cmd))));
      
      segmentTimes_str = '';
      segmentStates_str = '';
      for segment_idx = 1:length(arena.ctu.out.time_cmd)
        time = eval(arena.ctu.out.time_cmd{segment_idx});
        if segment_idx == 1
          segmentTimes_str = sprintf('%.1f',time*1e6);
        else
          segmentTimes_str = [segmentTimes_str sprintf(' %.1f',time*1e6)];
        end
        segmentStates_val = dec2bin(0,32);
        for group_idx = 1:length(arena.ctu.out.bit_group)
          if iscell(arena.ctu.out.bit_group(group_idx).(field))
            val = arena.ctu.out.bit_group(group_idx).(field){wf}(segment_idx);
          else
            val = arena.ctu.out.bit_group(group_idx).(field)(segment_idx);
          end
          if val>=2^length(arena.ctu.out.bit_group(group_idx).bits)
            error('arena.ctu.out.bit_group(%d): Value (%g) is too big for number of bits (%d).', group_idx, val, length(arena.ctu.out.bit_group.bits));
          end
          val_bin = dec2bin(val,length(arena.ctu.out.bit_group(group_idx).bits));
          segmentStates_val(arena.ctu.out.bit_group(group_idx).bits+1) = fliplr(val_bin);
        end
        if segment_idx == 1
          segmentStates_str = ['00000000' dec2hex(bin2dec(fliplr(segmentStates_val)),8)];
        else
          segmentStates_str = [segmentStates_str ' 00000000' dec2hex(bin2dec(fliplr(segmentStates_val)),8)];
        end
      end
      child = doc.createElement('segmentTimes'); mode_xml.appendChild(child);
      child.appendChild(doc.createTextNode(segmentTimes_str));
      
      child = doc.createElement('segmentStates'); mode_xml.appendChild(child);
      child.appendChild(doc.createTextNode(segmentStates_str));
    end
  end
  
  child = doc.createElement('pps'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  grandchild = doc.createElement('input'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode( sprintf('%d',arena.ctu.pps) ));
  grandchild = doc.createElement('polarity'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode( sprintf('%d',arena.ctu.pps_polarity) ));
  
  child = doc.createElement('nmea'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  grandchild = doc.createElement('input'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode( sprintf('%d',arena.ctu.nmea) ));
  grandchild = doc.createElement('baudRate'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode( sprintf('%d',arena.ctu.nmea_baud) ));
  
  child = doc.createElement('pscIntr'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  grandchild = doc.createElement('input'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode('0'));
  grandchild = doc.createElement('polarity'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode('0'));
  
end

%% CTU: ctu_0013
if strcmpi(arena.ctu.type,'ctu_0013')
  system = doc.getFirstChild;
  configs = system.getFirstChild;
  
  config = doc.createElement('config');
  configs.appendChild(config);
  config.setAttribute('type',arena.ctu.type);
  
  child = doc.createElement('name'); config.appendChild(child);
  child.appendChild(doc.createTextNode(arena.ctu.name));
  
  child = doc.createElement('description'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  
  output = 0;
  for signal_name = arena.TTL_names
    child = doc.createElement('signalAlias'); config.appendChild(child);
    child.appendChild(doc.createTextNode(''));
    grandchild = doc.createElement('signal'); child.appendChild(grandchild);
    grandchild.appendChild(doc.createTextNode(sprintf('output %d',output))); output = output + 1;
    grandchild = doc.createElement('name'); child.appendChild(grandchild);
    grandchild.appendChild(doc.createTextNode(signal_name{1}));
  end
  
  child = doc.createElement('numSegments'); config.appendChild(child);
  child.appendChild(doc.createTextNode(sprintf('%d',size(arena.TTL_states{1},2))));
  
  for wf = 1:length(arena.wfs)
    segment_times = [arena.TTL_time(1:2) wfs(wf).Tpd*1e6+arena.TTL_time(3) arena.PRI*1e6];

    modes = wfs(wf).modes;
    [~,unique_idxs] = unique(modes);
    
    for mode_idx = unique_idxs(:).'
      mode_latch = modes(mode_idx);
    
      child = doc.createElement('mode'); config.appendChild(child);
      child.appendChild(doc.createTextNode(''));
      grandchild = doc.createElement('id'); child.appendChild(grandchild);
      grandchild.appendChild(doc.createTextNode(sprintf('%d',mode_latch)));
      grandchild = doc.createElement('segmentTimes'); child.appendChild(grandchild);
      segment_time_str = [sprintf('%g', segment_times(1)), sprintf(' %g', segment_times(2:end))];
      grandchild.appendChild(doc.createTextNode(segment_time_str));
      grandchild = doc.createElement('segmentStates'); child.appendChild(grandchild);
      if wfs(wf).epri(mode_idx) == 1
        idx = 1;
      else
        idx = 2;
      end
      segment_state_str = lower(dec2hex(bin2dec(char(arena.TTL_states{idx}(end:-1:1,1).'+48)),8));
      for state_idx = 2:size(arena.TTL_states{idx},2)
        segment_state_str = cat(2,segment_state_str, ' ', ...
          lower(dec2hex(bin2dec(char(arena.TTL_states{idx}(end:-1:1,state_idx).'+48)),8)));
      end
      grandchild.appendChild(doc.createTextNode(segment_state_str));
    end
  end
  
  child = doc.createElement('pps'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  grandchild = doc.createElement('input'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode('0'));
  grandchild = doc.createElement('polarity'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode('0'));
  
  child = doc.createElement('nmea'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  grandchild = doc.createElement('input'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode('0'));
  grandchild = doc.createElement('polarity'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode('0'));
  
  child = doc.createElement('pscIntr'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  grandchild = doc.createElement('input'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode('0'));
  grandchild = doc.createElement('polarity'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode('0'));
  
  child = doc.createElement('encoder'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  grandchild = doc.createElement('input'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode('0'));
  grandchild = doc.createElement('polarity'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode('2'));
  
  child = doc.createElement('marker'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  grandchild = doc.createElement('input'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode('0'));
  grandchild = doc.createElement('polarity'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode('1'));
  
  child = doc.createElement('direction'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  grandchild = doc.createElement('input'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode('0'));
  grandchild = doc.createElement('polarity'); child.appendChild(grandchild);
  grandchild.appendChild(doc.createTextNode('1'));
  
end

%% DAC: dac-ad9129_0012
dac_idxs = find(strcmpi('dac-ad9129_0012',{arena.dac.type}));
for dac_idx = dac_idxs
  
  dac = arena.dac(dac_idx);
  
  system = doc.getFirstChild;
  configs = system.getFirstChild;
  
  config = doc.createElement('config'); configs.appendChild(config);
  config.setAttribute('type',dac.type);
  
  child = doc.createElement('name'); config.appendChild(child);
  child.appendChild(doc.createTextNode(sprintf('%s',dac.name)));
  
  child = doc.createElement('description'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  
  for wf = 1:length(wfs)
    Tpd = round(wfs(wf).Tpd*1e6);

    modes = wfs(wf).modes;
    [~,unique_idxs] = unique(modes);
    
    for mode_idx = unique_idxs(:).'
      mode_latch = modes(mode_idx);
      
      mode_xml = doc.createElement('mode'); config.appendChild(mode_xml);
      
      child = doc.createElement('id'); mode_xml.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%d',mode_latch)));
      
      if wfs(wf).tx_invert(mode_idx)
        child = doc.createElement('invert'); mode_xml.appendChild(child);
        child.appendChild(doc.createTextNode('1'));
      else
        child = doc.createElement('invert'); mode_xml.appendChild(child);
        child.appendChild(doc.createTextNode('0'));
      end
      
      child = doc.createElement('delay'); mode_xml.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%.1f',arena.param.PA_setup_time*1e6)));
      
      child = doc.createElement('config'); mode_xml.appendChild(child);
      child.setAttribute('type','dac-ad9129_0012_waveform');
      if wfs(wf).enabled(dac_idx)
        if wfs(wf).zeropiphase(mode_idx) == 0
          child.appendChild(doc.createTextNode(sprintf('waveformCh%d_%s_%dus',dac_idx-1,wfs(wf).name,Tpd) ));
        else
          child.appendChild(doc.createTextNode(sprintf('waveformCh%d_%s_%dus_%.0fdeg',dac_idx-1,wfs(wf).name,Tpd,wfs(wf).zeropiphase(mode_idx)) ));
        end
      else
        child.appendChild(doc.createTextNode('No_Tx'));
      end
    end
  end
end

%% DAC Waveforms: dac-ad9129_0012
dac_idxs = find(strcmpi('dac-ad9129_0012',{arena.dac.type}));
for dac_idx = dac_idxs
  
  dac = arena.dac(dac_idx);
  tx_idx = find(strcmpi(dac.name,param.config.tx_map));
  
  system = doc.getFirstChild;
  configs = system.getFirstChild;
  
  if dac_idx == 1
    % Create No-Tx waveform (waveform filled with typical values except for
    % length is 256 and scale is 0)
    wf = 1;
    fc = (wfs(wf).f0+wfs(wf).f1)/2;
    %Nt = round(wfs(wf).Tpd * dac.dacClk/8)*8;
    Nt = 256;
    BW = wfs(wf).f1-wfs(wf).f0;
    %scale = wfs(wf).scale(tx_idx);
    scale = 0;
    zeropiphase = 0;
    alpha = wfs(wf).tukey;
    
    config = doc.createElement('config'); configs.appendChild(config);
    config.setAttribute('type',sprintf('%s_waveform',dac.type));
    
    child = doc.createElement('name'); config.appendChild(child);
    child.appendChild(doc.createTextNode('No_Tx'));
    
    child = doc.createElement('description'); config.appendChild(child);
    child.appendChild(doc.createTextNode(''));
    
    child = doc.createElement('sampFreq'); config.appendChild(child);
    child.appendChild(doc.createTextNode(sprintf('%f',dac.dacClk/1e6)));
    
    pulse = doc.createElement('pulse'); config.appendChild(pulse);
    child = doc.createElement('name'); pulse.appendChild(child);
    child.appendChild(doc.createTextNode('Pulse'));
    child = doc.createElement('centerFreq'); pulse.appendChild(child);
    child.appendChild(doc.createTextNode(sprintf('%f',fc/1e6)));
    child = doc.createElement('bandwidth'); pulse.appendChild(child);
    child.appendChild(doc.createTextNode(sprintf('%f',BW/1e6)));
    child = doc.createElement('initialDelay'); pulse.appendChild(child);
    child.appendChild(doc.createTextNode(sprintf('%f',wfs(wf).delay(tx_idx)*1e-3)));
    child = doc.createElement('initialPhase'); pulse.appendChild(child);
    child.appendChild(doc.createTextNode(sprintf('%f',wfs(wf).phase(tx_idx)+zeropiphase)));
    child = doc.createElement('afterPulseDelay'); pulse.appendChild(child);
    child.appendChild(doc.createTextNode('0.000000'));
    child = doc.createElement('taper'); pulse.appendChild(child);
    child.appendChild(doc.createTextNode('Tukey'));
    child = doc.createElement('alpha'); pulse.appendChild(child);
    child.appendChild(doc.createTextNode(sprintf('%f',alpha)));
    child = doc.createElement('scale'); pulse.appendChild(child);
    child.appendChild(doc.createTextNode(sprintf('%g',scale)));
    child = doc.createElement('numPoints'); pulse.appendChild(child);
    child.appendChild(doc.createTextNode(sprintf('%d',Nt)));
    child = doc.createElement('Filename'); pulse.appendChild(child);
    child.appendChild(doc.createTextNode(''));
  end
  
  % Create waveforms for each of the modes
  for wf = 1:length(wfs)
    Tpd = round(wfs(wf).Tpd*1e6);
    
    fc = (wfs(wf).f0+wfs(wf).f1)/2;
    Nt = round(wfs(wf).Tpd * dac.dacClk/8)*8;
    BW = wfs(wf).f1-wfs(wf).f0;
    if wfs(wf).tx_enable(tx_idx)
      scale = wfs(wf).scale(tx_idx);
    else
      scale = 0;
    end
    alpha = wfs(wf).tukey;
    
    for zeropiphase = unique(wfs(wf).zeropiphase)
      config = doc.createElement('config'); configs.appendChild(config);
      config.setAttribute('type',sprintf('%s_waveform',dac.type));
      
      child = doc.createElement('name'); config.appendChild(child);
      if wfs(wf).zeropiphase(mode_idx) == 0
        child.appendChild(doc.createTextNode(sprintf('waveformCh%d_%s_%dus',dac_idx-1,wfs(wf).name,Tpd) ));
      else
        child.appendChild(doc.createTextNode(sprintf('waveformCh%d_%s_%dus_%.0fdeg',dac_idx-1,wfs(wf).name,Tpd,zeropiphase) ));
      end
      
      child = doc.createElement('description'); config.appendChild(child);
      child.appendChild(doc.createTextNode(''));
      
      child = doc.createElement('sampFreq'); config.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%f',dac.dacClk/1e6)));
      
      pulse = doc.createElement('pulse'); config.appendChild(pulse);
      child = doc.createElement('name'); pulse.appendChild(child);
      child.appendChild(doc.createTextNode('Pulse'));
      child = doc.createElement('centerFreq'); pulse.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%f',fc/1e6)));
      child = doc.createElement('bandwidth'); pulse.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%f',BW/1e6)));
      child = doc.createElement('initialDelay'); pulse.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%f',wfs(wf).delay(tx_idx)*1e-3)));
      child = doc.createElement('initialPhase'); pulse.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%f',wfs(wf).phase(tx_idx)+zeropiphase)));
      child = doc.createElement('afterPulseDelay'); pulse.appendChild(child);
      child.appendChild(doc.createTextNode('0.000000'));
      child = doc.createElement('taper'); pulse.appendChild(child);
      child.appendChild(doc.createTextNode('Tukey'));
      child = doc.createElement('alpha'); pulse.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%f',alpha)));
      child = doc.createElement('scale'); pulse.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%g',scale)));
      child = doc.createElement('numPoints'); pulse.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%d',Nt)));
      child = doc.createElement('Filename'); pulse.appendChild(child);
      child.appendChild(doc.createTextNode(''));
    end
  end
  
end

%% DAC: dac-ad9129_0014
dac_idxs = find(strcmpi('dac-ad9129_0014',{arena.dac.type}));
for dac_idx = dac_idxs

  dac = arena.dac(dac_idx);
  
  system = doc.getFirstChild;
  configs = system.getFirstChild;

  config = doc.createElement('config'); configs.appendChild(config);
  config.setAttribute('type',dac.type);

  child = doc.createElement('name'); config.appendChild(child);
  child.appendChild(doc.createTextNode(sprintf('%s',dac.name)));

  child = doc.createElement('description'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));

  for wf = 1:length(arena.wfs)
    Tpd = round(wfs(wf).Tpd*1e6);
    delay = arena.dacs_start_delay - arena.dacs_internal_delay;
    if delay < 0
      error('Delay "arena.dacs_start_delay - arena.dacs_internal_delay" must be nonnegative: %g.', delay);
    end

    modes = wfs(wf).modes;
    [~,unique_idxs] = unique(modes);
    
    for mode_idx = unique_idxs(:).'
      mode_latch = modes(mode_idx);

      child = doc.createElement('mode'); config.appendChild(child);
      child.appendChild(doc.createTextNode(''));
      grandchild = doc.createElement('id'); child.appendChild(grandchild);
      grandchild.appendChild(doc.createTextNode(sprintf('%d',mode_latch)));
      grandchild = doc.createElement('enabled'); child.appendChild(grandchild);
      grandchild.appendChild(doc.createTextNode('1'));
      grandchild = doc.createElement('delay'); child.appendChild(grandchild);
      grandchild.appendChild(doc.createTextNode(sprintf('%.6f',delay)));
      grandchild = doc.createElement('vDelayEnabled'); child.appendChild(grandchild);
      grandchild.appendChild(doc.createTextNode('0'));
      grandchild = doc.createElement('vDelay'); child.appendChild(grandchild);
      grandchild.appendChild(doc.createTextNode('0.000000'));
      grandchild = doc.createElement('config'); child.appendChild(grandchild);
      if wfs(wf).enabled(dac_idx)
        grandchild.appendChild(doc.createTextNode(sprintf('waveformCh%d_%s_%dus_%.0fdeg',dac_idx-1,wfs(wf).name,Tpd,wfs(wf).zeropiphase(mode_idx)) ));
      else
        grandchild.appendChild(doc.createTextNode('No_Tx'));
      end
      grandchild.setAttribute('type','dac-ad9129_0014_waveform');
    end
  end

end

%% DAC Waveforms: dac-ad9129_0014
dac_idxs = find(strcmpi('dac-ad9129_0014',{arena.dac.type}));
if ~isempty(dac_idxs)
  dac_idx = dac_idxs(1);

  dac = arena.dac(dac_idx);
  tx_idx = find(strcmpi(dac.name,param.config.tx_map));

  system = doc.getFirstChild;
  configs = system.getFirstChild;

  if dac_idx == 1
    wf = 1; dac_idx = 1; dac = arena.dac(dac_idx); zeropiphase = 0;
    fs = arena.dac(dac_idx).dacClk;
    fc = (wfs(wf).f0+wfs(wf).f1)/2;
    BW = wfs(wf).f1 - wfs(wf).f0;
    Tpd = wfs(wf).Tpd;
    alpha = wfs(wf).tukey;
    equal.delay = wfs(wf).delay;
    equal.phase = wfs(wf).phase;
    equal.scale = wfs(wf).scale;
    Nt = round((wfs(wf).Tpd+equal.delay/1e9) * fs);

    config = doc.createElement('config'); configs.appendChild(config);
    config.setAttribute('type',sprintf('%s_waveform',dac.type));

    child = doc.createElement('name'); config.appendChild(child);
    child.appendChild(doc.createTextNode('No_Tx'));

    child = doc.createElement('description'); config.appendChild(child);
    child.appendChild(doc.createTextNode(''));

    child = doc.createElement('sampFreq'); config.appendChild(child);
    child.appendChild(doc.createTextNode(sprintf('%f',fs/1e6)));

    child = doc.createElement('pulse'); config.appendChild(child);
    grandchild = doc.createElement('name'); child.appendChild(grandchild);
    grandchild.appendChild(doc.createTextNode('Pulse'));
    grandchild = doc.createElement('centerFreq'); child.appendChild(grandchild);
    grandchild.appendChild(doc.createTextNode(sprintf('%f',fc(dac_idx)/1e6)));
    grandchild = doc.createElement('bandwidth'); child.appendChild(grandchild);
    grandchild.appendChild(doc.createTextNode(sprintf('%f',BW(dac_idx)/1e6)));
    grandchild = doc.createElement('initialDelay'); child.appendChild(grandchild);
    grandchild.appendChild(doc.createTextNode(sprintf('%f',equal.delay(dac_idx)*1e-3)));
    grandchild = doc.createElement('initialPhase'); child.appendChild(grandchild);
    grandchild.appendChild(doc.createTextNode(sprintf('%f',equal.phase(dac_idx)+zeropiphase)));
    grandchild = doc.createElement('afterPulseDelay'); child.appendChild(grandchild);
    grandchild.appendChild(doc.createTextNode('1.000000'));
    grandchild = doc.createElement('taper'); child.appendChild(grandchild);
    grandchild.appendChild(doc.createTextNode('Tukey'));
    grandchild = doc.createElement('alpha'); child.appendChild(grandchild);
    grandchild.appendChild(doc.createTextNode(sprintf('%f',alpha)));
    grandchild = doc.createElement('scale'); child.appendChild(grandchild);
    grandchild.appendChild(doc.createTextNode('0.000000'));
    grandchild = doc.createElement('numPoints'); child.appendChild(grandchild);
    grandchild.appendChild(doc.createTextNode(sprintf('%d',Nt(dac_idx))));
    grandchild = doc.createElement('Filename'); child.appendChild(grandchild);
    grandchild.appendChild(doc.createTextNode(''));
  end

  waveform_names = {};
  for wf = 1:length(arena.wfs)

    for dac_idx = dac_idxs
      fs = arena.dac(dac_idx).dacClk;

      fc = (wfs(wf).f0+wfs(wf).f1)/2;
      BW = wfs(wf).f1 - wfs(wf).f0;
      Tpd = wfs(wf).Tpd;
      alpha = wfs(wf).tukey;
      equal.delay = wfs(wf).delay;
      equal.phase = wfs(wf).phase;
      equal.scale = wfs(wf).scale;
      Nt = round((wfs(wf).Tpd+equal.delay/1e9) * fs);

      %[0.63 ]
      %  0.1652 0.326800 0.511500 0.63 0.6300 0.511500 0.3268 0.1652
      %    chebwin(8,30)

      for zeropiphase = unique(wfs(wf).zeropiphase)
        new_waveform_name = sprintf('waveformCh%d_%s_%.0fus_%.0fdeg',dac_idx-1,wfs(wf).name,Tpd*1e6,zeropiphase);
        if any(strcmpi(new_waveform_name,waveform_names))
          continue;
        end
        waveform_names{end+1} = new_waveform_name;

        config = doc.createElement('config'); configs.appendChild(config);
        config.setAttribute('type',sprintf('%s_waveform',dac.type));

        child = doc.createElement('name'); config.appendChild(child);
        child.appendChild(doc.createTextNode(waveform_names{end}));

        child = doc.createElement('description'); config.appendChild(child);
        child.appendChild(doc.createTextNode(''));

        child = doc.createElement('sampFreq'); config.appendChild(child);
        child.appendChild(doc.createTextNode(sprintf('%f',fs/1e6)));

        child = doc.createElement('pulse'); config.appendChild(child);
        grandchild = doc.createElement('name'); child.appendChild(grandchild);
        grandchild.appendChild(doc.createTextNode('Pulse'));
        grandchild = doc.createElement('centerFreq'); child.appendChild(grandchild);
        grandchild.appendChild(doc.createTextNode(sprintf('%f',fc(dac_idx)/1e6)));
        grandchild = doc.createElement('bandwidth'); child.appendChild(grandchild);
        grandchild.appendChild(doc.createTextNode(sprintf('%f',BW(dac_idx)/1e6)));
        grandchild = doc.createElement('initialDelay'); child.appendChild(grandchild);
        grandchild.appendChild(doc.createTextNode(sprintf('%f',equal.delay(dac_idx)*1e-3)));
        grandchild = doc.createElement('initialPhase'); child.appendChild(grandchild);
        grandchild.appendChild(doc.createTextNode(sprintf('%f',equal.phase(dac_idx)+zeropiphase)));
        grandchild = doc.createElement('afterPulseDelay'); child.appendChild(grandchild);
        grandchild.appendChild(doc.createTextNode('1.000000'));
        grandchild = doc.createElement('taper'); child.appendChild(grandchild);
        grandchild.appendChild(doc.createTextNode('Tukey'));
        grandchild = doc.createElement('alpha'); child.appendChild(grandchild);
        grandchild.appendChild(doc.createTextNode(sprintf('%f',alpha)));
        grandchild = doc.createElement('scale'); child.appendChild(grandchild);
        grandchild.appendChild(doc.createTextNode(sprintf('%f',equal.scale(dac_idx))));
        grandchild = doc.createElement('numPoints'); child.appendChild(grandchild);
        grandchild.appendChild(doc.createTextNode(sprintf('%d',Nt(dac_idx))));
        grandchild = doc.createElement('Filename'); child.appendChild(grandchild);
        grandchild.appendChild(doc.createTextNode(''));
      end
    end
  end

end

%% DAQ
if isfield(arena,'daq') && ~isempty(arena.daq)
  daq_idxs = find(strcmpi('daq_0001',{arena.daq.type}));
else
  daq_idxs = [];
end
for daq_idx = daq_idxs
  
  daq = arena.daq(daq_idx);
  
  system = doc.getFirstChild;
  configs = system.getFirstChild;
  
  config = doc.createElement('config'); configs.appendChild(config);
  config.setAttribute('type',daq.type);
  
  child = doc.createElement('name'); config.appendChild(child);
  child.appendChild(doc.createTextNode(sprintf('%s',daq.name)));
  
  child = doc.createElement('description'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  
  child = doc.createElement('globalName'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  
  child = doc.createElement('globalDir'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  
  child = doc.createElement('auxDir'); config.appendChild(child);
  child.appendChild(doc.createTextNode(daq.auxDir));
  
  for adc_idx = 1:length(arena.adc)
    
    adc = arena.adc(adc_idx);
    
    % Find the subsystem that hosts this ADC
    found = false;
    for subsystem_idx = 1:length(arena.subsystem)
      for mezz_idx = 1:length(arena.subsystem(subsystem_idx).subSystem)
        if strcmpi(arena.subsystem(subsystem_idx).subSystem{mezz_idx}, adc.name)
          subsystem_name = arena.subsystem(subsystem_idx).name;
          found = true;
          break;
        end
      end
    end
    if ~found
      error('ADC %s is not attached to any arena.subsystem().subSystem.', adc.name);
    end
    
    recorder = doc.createElement('recorder'); config.appendChild(recorder);
    
    child = doc.createElement('name'); recorder.appendChild(child);
    child.appendChild(doc.createTextNode(adc.name));
    
    child = doc.createElement('dataSource'); recorder.appendChild(child);
    if strcmpi(adc.stream,'socket')
      child.appendChild(doc.createTextNode( sprintf('%s:%s',subsystem_name,adc.name) ));
    else
      child.appendChild(doc.createTextNode( sprintf('%s:%s:dataStream0',subsystem_name,adc.name) ));
    end
    
    child = doc.createElement('fileName'); recorder.appendChild(child);
    child.appendChild(doc.createTextNode( sprintf('%s_%s',daq.fileName,adc.name) ));
    
    child = doc.createElement('fileCount'); recorder.appendChild(child);
    child.appendChild(doc.createTextNode('-1'));
    
    child = doc.createElement('fileSize'); recorder.appendChild(child);
    child.appendChild(doc.createTextNode('256'));
    
    child = doc.createElement('minSpace'); recorder.appendChild(child);
    child.appendChild(doc.createTextNode('10000'));
    
    fileStripe = regexprep(daq.fileStripe,'%b',adc.name);
    
    child = doc.createElement('fileStripe'); recorder.appendChild(child);
    child.appendChild(doc.createTextNode(fileStripe));
    
  end
  
end

%% PSC: psc_0001
% Primary Sequence Controller
if strcmpi(arena.psc.type,'psc_0001')
  system = doc.getFirstChild;
  configs = system.getFirstChild;
  
  config = doc.createElement('config'); configs.appendChild(config);
  config.setAttribute('type',arena.psc.type);
  
  child = doc.createElement('name'); config.appendChild(child);
  child.appendChild(doc.createTextNode( sprintf('psc_%s',arena.psc_name) ));
  
  child = doc.createElement('description'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  
%   child = doc.createElement('extAsyncTrigSelect'); config.appendChild(child);
%   child.appendChild(doc.createTextNode('0'));
%   
%   child = doc.createElement('holdOnStartup'); config.appendChild(child);
%   child.appendChild(doc.createTextNode('0'));
%   
%   child = doc.createElement('interruptibleOnStartup'); config.appendChild(child);
%   child.appendChild(doc.createTextNode('0'));
%   
%   child = doc.createElement('extJumpToIndex'); config.appendChild(child);
%   child.appendChild(doc.createTextNode('0'));
%   
%   child = doc.createElement('modulus'); config.appendChild(child);
%   child.appendChild(doc.createTextNode('0'));
  
  for wf = 1:length(wfs)
    for mode_idx = 1:numel(wfs(wf).modes)
      mode = wfs(wf).modes(mode_idx);
      repeat_to = wfs(wf).repeat_to(mode_idx);
      repeat_count = wfs(wf).repeat_count(mode_idx);
      next = wfs(wf).next(mode_idx);
      sequence = doc.createElement('sequence'); config.appendChild(sequence);
      sequence.setAttribute('type','primary');
%       child = doc.createElement('marker'); sequence.appendChild(child);
%       child.appendChild(doc.createTextNode('0'));
%       child = doc.createElement('hold'); sequence.appendChild(child);
%       child.appendChild(doc.createTextNode('0'));
      child = doc.createElement('mode'); sequence.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%d',mode)));
      child = doc.createElement('name'); sequence.appendChild(child);
      if wfs(wf).epri(mode_idx)
        field = 'EPRI';
      else
        field = 'PRI';
      end
      zeropiphase = wfs(wf).zeropiphase(mode_idx);
      if wfs(wf).tx_invert(mode_idx)
        zeropiphase = zeropiphase + 180;
      end
      psc_name = sprintf('%.0fus, %s, %d',wfs(wf).Tpd*1e6, field, zeropiphase);
      child.appendChild(doc.createTextNode(psc_name));
      child = doc.createElement('period'); sequence.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%g',1/param.prf*1e6)));
%       child = doc.createElement('next'); sequence.appendChild(child);
%       child.appendChild(doc.createTextNode(sprintf('%d',next)));
      child = doc.createElement('repeatTo'); sequence.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%d',repeat_to)));
      child = doc.createElement('repeatCount'); sequence.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%d',repeat_count)));
      child = doc.createElement('interruptible'); sequence.appendChild(child);
      child.appendChild(doc.createTextNode('0'));
    end
  end
  
  child = doc.createElement('interruptEna'); config.appendChild(child);
  child.appendChild(doc.createTextNode('0'));
end

%% PSC: psc_0003
% Primary Sequence Controller
if strcmpi(arena.psc.type,'psc_0003')
  system = doc.getFirstChild;
  configs = system.getFirstChild;
  
  config = doc.createElement('config'); configs.appendChild(config);
  config.setAttribute('type',arena.psc.type);
  
  child = doc.createElement('name'); config.appendChild(child);
  child.appendChild(doc.createTextNode( sprintf('psc_%s',arena.psc_name) ));
  
  child = doc.createElement('description'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  
  child = doc.createElement('extAsyncTrigSelect'); config.appendChild(child);
  child.appendChild(doc.createTextNode('0'));
  
  child = doc.createElement('holdOnStartup'); config.appendChild(child);
  child.appendChild(doc.createTextNode('0'));
  
  child = doc.createElement('interruptibleOnStartup'); config.appendChild(child);
  child.appendChild(doc.createTextNode('0'));
  
  child = doc.createElement('extJumpToIndex'); config.appendChild(child);
  child.appendChild(doc.createTextNode('0'));
  
  child = doc.createElement('modulus'); config.appendChild(child);
  child.appendChild(doc.createTextNode('0'));
  
  child = doc.createElement('interruptEna'); config.appendChild(child);
  child.appendChild(doc.createTextNode('0'));
  
  for wf = 1:length(wfs)
    for mode_idx = 1:numel(wfs(wf).modes)
      mode = wfs(wf).modes(mode_idx);
      repeat_to = wfs(wf).repeat_to(mode_idx);
      repeat_count = wfs(wf).repeat_count(mode_idx);
      next = wfs(wf).next(mode_idx);
      sequence = doc.createElement('sequence'); config.appendChild(sequence);
      sequence.setAttribute('type','primary');
      child = doc.createElement('marker'); sequence.appendChild(child);
      child.appendChild(doc.createTextNode('0'));
      child = doc.createElement('hold'); sequence.appendChild(child);
      child.appendChild(doc.createTextNode('0'));
      child = doc.createElement('mode'); sequence.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%d',mode)));
      child = doc.createElement('name'); sequence.appendChild(child);
      if wfs(wf).epri(mode_idx)
        field = 'EPRI';
      else
        field = 'PRI';
      end
      zeropiphase = wfs(wf).zeropiphase(mode_idx);
      if wfs(wf).tx_invert(mode_idx)
        zeropiphase = zeropiphase + 180;
      end
      psc_name = sprintf('%.0fus, %s, %d',wfs(wf).Tpd*1e6, field, zeropiphase);
      child.appendChild(doc.createTextNode(psc_name));
      child = doc.createElement('period'); sequence.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%g',1/param.prf*1e6)));
      child = doc.createElement('next'); sequence.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%d',next)));
      child = doc.createElement('repeatTo'); sequence.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%d',repeat_to)));
      child = doc.createElement('repeatCount'); sequence.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%d',repeat_count)));
      child = doc.createElement('interruptible'); sequence.appendChild(child);
      child.appendChild(doc.createTextNode('0'));
    end
  end
end

%% SOCKET
for adc_idx = 1:length(arena.adc)
  
  adc = arena.adc(adc_idx);
  
  system = doc.getFirstChild;
  configs = system.getFirstChild;
  
  config = doc.createElement('config'); configs.appendChild(config);
  if strcmpi(adc.stream,'udp')
    config.setAttribute('type','streamudp');
  elseif strcmpi(adc.stream,'socket')
    config.setAttribute('type','socket');
  elseif strcmpi(adc.stream,'tcp')
    config.setAttribute('type','streamtcp');
  end
  
  child = doc.createElement('name'); config.appendChild(child);
  if strcmpi(adc.stream,'socket')
    child.appendChild(doc.createTextNode(sprintf('socket_%s',adc.name)));
  else
    child.appendChild(doc.createTextNode(sprintf('stream_%s',adc.name)));
  end
  
  child = doc.createElement('description'); config.appendChild(child);
  child.appendChild(doc.createTextNode(''));
  
  if strcmpi(adc.stream,'tcp')
    child = doc.createElement('port'); config.appendChild(child);
    child.appendChild(doc.createTextNode(sprintf('%d',55000+adc_idx)));
  else
    child = doc.createElement('multiFlag'); config.appendChild(child);
    child.appendChild(doc.createTextNode('0'));
    
    child = doc.createElement('ip'); config.appendChild(child);
    child.appendChild(doc.createTextNode(adc.ip));
    
    child = doc.createElement('port'); config.appendChild(child);
    child.appendChild(doc.createTextNode(sprintf('%d',55000+adc_idx)));
    
    child = doc.createElement('payloadSize'); config.appendChild(child);
    child.appendChild(doc.createTextNode('8192'));
  end
  
end

%% SUBSYSTEM
system = doc.getFirstChild;
configs = system.getFirstChild;

for subsystem_idx = 1:length(arena.subsystem)
  subsystem = arena.subsystem(subsystem_idx);
  
  subsystem_doc = doc.createElement('subSystem'); system.appendChild(subsystem_doc);
  
  child = doc.createElement('name'); subsystem_doc.appendChild(child);
  child.appendChild(doc.createTextNode(subsystem.name));
  
  child = doc.createElement('interface'); subsystem_doc.appendChild(child);
  child.appendChild(doc.createTextNode('eth0'));
  child.setAttribute('type','nic');
  
  child = doc.createElement('port'); subsystem_doc.appendChild(child);
  child.appendChild(doc.createTextNode('10000'));
  
  if strcmpi(subsystem.name,'Data Server')
    child = doc.createElement('config'); subsystem_doc.appendChild(child);
    child.appendChild(doc.createTextNode('daq0'));
    child.setAttribute('type',arena.daq.type);
  elseif ~isempty(regexpi(subsystem.name,'CTU'))
    child = doc.createElement('config'); subsystem_doc.appendChild(child);
    child.appendChild(doc.createTextNode( sprintf('psc_%s',arena.psc_name) ));
    child.setAttribute('type',arena.psc.type);
  end
  
  for mezz_idx = 1:length(subsystem.subSystem)
    mezz_name = subsystem.subSystem{mezz_idx};
    
    expression = xpath.compile(sprintf('//configs/config[(name="%s")]',mezz_name));
    nodeList = expression.evaluate(doc,XPathConstants.NODESET);
    cfg = nodeList.item(0);
    
    expression = xpath.compile('@type');
    nodeList = expression.evaluate(cfg,XPathConstants.NODESET);
    config_type = nodeList.item(0).getTextContent.toCharArray;
    config_type = config_type(:).';
    
    if strcmpi(config_type,'ctu_001D')
      
      mezz = doc.createElement('subSystem'); subsystem_doc.appendChild(mezz);
      
      child = doc.createElement('name'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(mezz_name));
      
      child = doc.createElement('fanSpeeds'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode('20 20 20'));
      child = doc.createElement('config'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(mezz_name));
      child.setAttribute('type',config_type);
      
    elseif strcmpi(config_type,'ctu_0013')
      
      mezz = doc.createElement('subSystem'); subsystem_doc.appendChild(mezz);
      
      child = doc.createElement('name'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(mezz_name));
      
%       child = doc.createElement('fanSpeeds'); mezz.appendChild(child);
%       child.appendChild(doc.createTextNode('20 20 20'));
      child = doc.createElement('config'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(mezz_name));
      child.setAttribute('type',config_type);
      
    elseif strcmpi(config_type,'dac-ad9129_0012')
      
      mezz = doc.createElement('subSystem'); subsystem_doc.appendChild(mezz);
      
      child = doc.createElement('name'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(mezz_name));
      
      % Find the DAC in the list
      dac_idx = find(strcmpi(mezz_name,{arena.dac.name}));
      if isempty(dac_idx)
        error('Cannot find subsystem dac %s in dac list.', mezz_name);
      end
      dac = arena.dac(dac_idx);
      
      child = doc.createElement('disableSync'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode('0'));
      child = doc.createElement('dacClk'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%g',dac.dacClk/1e6)));
      child = doc.createElement('mixMode'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode('0'));
      child = doc.createElement('desiredAlignMin'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%g',dac.desiredAlignMin)));
      child = doc.createElement('desiredAlignMax'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%g',dac.desiredAlignMax)));
      child = doc.createElement('dcoPhase'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%g',dac.dcoPhase)));
      child = doc.createElement('config'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(mezz_name));
      child.setAttribute('type',config_type);
      child = doc.createElement('config'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(''));
      child.setAttribute('type','ctu_0012');
      
    elseif strcmpi(config_type,'dac-ad9129_0014')
      
      mezz = doc.createElement('subSystem'); subsystem_doc.appendChild(mezz);
      
      child = doc.createElement('name'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(mezz_name));
      
      % Find the DAC in the list
      dac_idx = find(strcmpi(mezz_name,{arena.dac.name}));
      if isempty(dac_idx)
        error('Cannot find subsystem dac %s in dac list.', mezz_name);
      end
      dac = arena.dac(dac_idx);
      
      child = doc.createElement('disableSync'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode('0'));
      child = doc.createElement('dacClk'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%g',dac.dacClk/1e6)));
      child = doc.createElement('mixMode'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode('0'));
      child = doc.createElement('desiredAlignMin'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%g',dac.desiredAlignMin)));
      child = doc.createElement('desiredAlignMax'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%g',dac.desiredAlignMax)));
%       child = doc.createElement('dcoPhase'); mezz.appendChild(child);
%       child.appendChild(doc.createTextNode(sprintf('%g',dac.dcoPhase)));
      child = doc.createElement('config'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(mezz_name));
      child.setAttribute('type',config_type);
      
    elseif strcmpi(config_type,'adc-ad9680_0017')
      
      mezz = doc.createElement('subSystem'); subsystem_doc.appendChild(mezz);
      
      child = doc.createElement('name'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(mezz_name));
      
      % Find the ADC in the list
      adc_idx = find(strcmpi(mezz_name,{arena.adc.name}));
      if isempty(adc_idx)
        error('Cannot find subsystem adc %s in adc list.', mezz_name);
      end
      adc = arena.adc(adc_idx);
      
      child = doc.createElement('disableSync'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode('0'));
      child = doc.createElement('adcClk'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%g',2*adc.sampFreq/1e6)));
      child = doc.createElement('adcClkDivBy'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode('1'));
      child = doc.createElement('adcGainCh0'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode('0'));
      child = doc.createElement('adcGainCh1'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode('0'));
      child = doc.createElement('alignPhase'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode('1'));
      child = doc.createElement('desiredAlignMin'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%g',adc.desiredAlignMin)));
      child = doc.createElement('desiredAlignMax'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(sprintf('%g',adc.desiredAlignMax)));
      child = doc.createElement('config'); mezz.appendChild(child);
      child.appendChild(doc.createTextNode(mezz_name));
      child.setAttribute('type',config_type);
      
      if strcmpi(adc.stream,'socket')
        dataOutput = doc.createElement('dataOutput'); mezz.appendChild(dataOutput);
        
        child = doc.createElement('config'); dataOutput.appendChild(child);
        if strcmpi(adc.stream,'socket')
        child.appendChild(doc.createTextNode(sprintf('socket_%s',adc.name)));
        else
        child.appendChild(doc.createTextNode(sprintf('stream_%s',adc.name)));
        end
        child.setAttribute('type','socket');
        
        child = doc.createElement('interface'); dataOutput.appendChild(child);
        child.appendChild(doc.createTextNode('eth0'));
        child.setAttribute('type','nic');
      else
        % Only one datastream supported per ADC card
        for stream_idx = 1
          dataOutput = doc.createElement('dataStream'); mezz.appendChild(dataOutput);
          dataOutput.setAttribute('type',adc.stream);
          
          child = doc.createElement('id'); dataOutput.appendChild(child);
          child.appendChild(doc.createTextNode('0'));
          
          child = doc.createElement('name'); dataOutput.appendChild(child);
          child.appendChild(doc.createTextNode('dataStream0'));
          
          if strcmpi(adc.stream,'udp')
            % Only one udp substream supported per data stream
            for substream_idx = 1
              streamOutput = doc.createElement('stream'); dataOutput.appendChild(streamOutput);
              
              child = doc.createElement('interface'); streamOutput.appendChild(child);
              child.appendChild(doc.createTextNode('eth0'));
              child.setAttribute('type','nic');
              child = doc.createElement('config'); streamOutput.appendChild(child);
              child.appendChild(doc.createTextNode(sprintf('stream_%s',adc.name)));
              child.setAttribute('type',sprintf('stream%s',adc.stream));
            end
          elseif strcmpi(adc.stream,'tcp')
            child = doc.createElement('interface'); dataOutput.appendChild(child);
            child.appendChild(doc.createTextNode('eth0'));
            child.setAttribute('type','nic');
            child = doc.createElement('config'); dataOutput.appendChild(child);
            child.appendChild(doc.createTextNode(sprintf('stream_%s',adc.name)));
            child.setAttribute('type',sprintf('stream%s',adc.stream));
          end
        end
      end
    end
    
  end
end
