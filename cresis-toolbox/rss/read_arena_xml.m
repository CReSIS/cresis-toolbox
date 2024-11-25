function configs = read_arena_xml(config_fn,system_fn,adc_map,dac_map)
% configs = read_arena_xml(config_fn,system_fn,adc_map,dac_map)
%
% config_fn: config XML file name
% system_fn: system XML file name. If left empty or undefined, the system
%   file name will be constructed from the config filename. For example:
%     20180817_094746_config.xml will produce 20180817_094746_system.xml
% adc_map: cell array of strings which matches adc names to index in
%   configs.adc. This index is called the board_idx and adc configs will
%   be stored as: configs.adc{board_idx,1+mode,1+subchannel}.
%   This parameter is optional. Default is an empty array which causes the
%   order of configs.adc to match the order the adc configs are read in.
% dac_map:cell array which matches dac names to index in configs.dac.
%   This index is called the tx_idx and dac configs will be stored as:
%   configs.dac{dac_idx}
%   This parameter is optional. Default is an empty array which causes the
%   order of configs.dac to match the order the dac configs are read in.
%
% Examples:
% % 1. Use the default system file name generated from the config file
% % 2. Map digrx0 to board 1
% % 3. Map digrx1 to board 2
% % 4. Map awg0 to tx 1
% configs = read_arena_xml('20180817_094746_config.xml','',{'digrx0','digrx1'},{'awg0'});
%
% % 1. Explicitly set the config and system filenames separately
% configs = read_arena_xml('my_config.xml,'system.xml'');
%
% Author: John Paden

if ~exist('system_fn','var')
  system_fn = '';
end

if ~exist('adc_map','var')
  adc_map = '';
end

if ~exist('dac_map','var')
  dac_map = '';
end

% User did not supply system_fn, generate the system xml filename from the
% config xml filename.
if isempty(system_fn)
  [config_fn_dir,config_fn_name] = fileparts(config_fn);
  xml_type_idx = find(config_fn_name=='_',1,'last');
  system_fn = fullfile(config_fn_dir,[config_fn_name(1:xml_type_idx), 'system.xml']);
end

configs.config_fn = config_fn;
configs.system_fn = system_fn;
configs.config_fname_info = fname_info_arena(config_fn);
configs.min_num_bins = inf;
configs.max_num_bins = 0;
configs.prf = [];
configs.radar_name = [];
configs.total_presums = [];
configs.adc = {};
configs.dac = {};

if ~exist(system_fn,'file')
  error('READ_ARENA_XML:MISSING_SYSTEM_XML','Missing system file %s for config file %s\n', system_fn, config_fn);
end
doc = xmlread(system_fn);
%   sys = doc.getElementsByTagName('system'); sys = sys.item(0);

doc_cfg = xmlread(config_fn);
%   sys = doc.getElementsByTagName('system'); sys = sys.item(0);

%   for idx = 1:sys.getLength
%     it = sys.item(idx-1);
%     if it.getNodeType==1
%       name = it.getNodeName;
%       type = it.getAttribute('type');
%       fprintf('%s type %s\n', name.toCharArray, type.toCharArray);
%     end
%   end

% Import the XPath classes
import javax.xml.xpath.*

% Create an XPath expression.
factory = XPathFactory.newInstance;
xpath = factory.newXPath;

% Get the system type
expression = xpath.compile('//system/@type');
nodeList = expression.evaluate(doc,XPathConstants.NODESET);
radar_name = nodeList.item(0).getTextContent.toCharArray;
radar_name = radar_name(:).';
configs.radar_name = radar_name;

%% PULSE SEQUENCE
% =========================================================================

if ~isempty(regexpi(configs.radar_name,'arena5xx', 'once'))
  %% PULSE SEQUENCE: Arena 522 CTU
  
  % SYSTEM XML:
  % <subSystem type="arena5xxrf">
  %   <name>ARENA5xxRF</name>
  %
  % CONFIG XML:
  % <subSystem>
  %   <name>ARENA5xxRF</name>
  %   <config type="psc_0008">psc1</config>
  %
  % <configs>
  %   <config type="psc_0008">
  %     <name>psc1</name>

  % Get the arena 522 subsystems
  expression = xpath.compile('//subSystem[starts-with(@type,"arena5xxrf")]');
  arena522_list = expression.evaluate(doc,XPathConstants.NODESET);

  found_psc = false;
  for arena522_idx = 1:arena522_list.getLength
    arena522_syscfg = arena522_list.item(arena522_idx-1);
    if isempty(arena522_syscfg)
      continue;
    end
    
    % Get the arena 522 subsystem name
    expression = xpath.compile('name');
    nodeList = expression.evaluate(arena522_syscfg,XPathConstants.NODESET);
    arena522_name = nodeList.item(0);
    arena522_name = arena522_name.getTextContent.toCharArray;
    arena522_name = arena522_name(:).';
    
    % Find the configuration for this arena 522
    expression = xpath.compile(sprintf('//subSystem[name="%s"]', arena522_name));
    arena522_cfg = expression.evaluate(doc_cfg,XPathConstants.NODESET);
    arena522_cfg = arena522_cfg.item(0);

    % Get the Arena 522 CTU config name
    config_type = 'psc_0008';
    expression = xpath.compile(sprintf('config[@type="%s"]', config_type));
    config_name = expression.evaluate(arena522_cfg,XPathConstants.NODESET);
    config_name = config_name.item(0).getTextContent.toCharArray;
    config_name = config_name(:).';
    
    % Get the Arena 522 CTU configs
    expression = xpath.compile(sprintf('//configs/config[@type="%s" and name="%s"]',config_type,config_name));
    psc_cfg = expression.evaluate(doc_cfg,XPathConstants.NODESET);
    if ~isempty(psc_cfg)
      psc_cfg = psc_cfg.item(0);
      found_psc = true;
      break;
    end
  end
  if ~found_psc || psc_cfg.getLength == 0
    error('Did not find PSC configuration.');
  end
  
  configs.psc.config_type = config_type;
  configs.psc.config_name = config_name;
    
else
  %% PULSE SEQUENCE: CTU Module or Arena 313 CTU
  
  % 1. Get the name of the CTU
  % 1a. Get the CTU
  if strcmpi(configs.radar_name,'ku0002')
    expression = xpath.compile('//subSystem[starts-with(@type,"arena3xx")]');
    ctu = expression.evaluate(doc,XPathConstants.NODESET);
  else
    expression = xpath.compile('//subSystem[starts-with(@type,"arenactu")]');
    ctu = expression.evaluate(doc,XPathConstants.NODESET);
  end
  if ctu.getLength == 0
    error('Did not find CTU configuration.');
  end
  
  % 1b. Get the name
  expression = xpath.compile('name');
  nodeList = expression.evaluate(ctu.item(0),XPathConstants.NODESET);
  name = nodeList.item(0).getTextContent.toCharArray;
  name = name(:).';
  
  % 2. Search for the subSystem in the config XML
  expression = xpath.compile(sprintf('//subSystem[name="%s"]',name));
  nodeList = expression.evaluate(doc_cfg,XPathConstants.NODESET);
  match = nodeList.item(0);
  
  % 3. Get the config name and type for the CTU
  expression = xpath.compile('config/@type');
  nodeList = expression.evaluate(match,XPathConstants.NODESET);
  config_type = nodeList.item(0).getTextContent.toCharArray;
  config_type = config_type(:).';
  expression = xpath.compile('config');
  nodeList = expression.evaluate(match,XPathConstants.NODESET);
  config_name = nodeList.item(0).getTextContent.toCharArray;
  config_name = config_name(:).';
  
  configs.psc.name = name;
  configs.psc.config_type = config_type;
  configs.psc.config_name = config_name;
  
  expression = xpath.compile(sprintf('//configs/config[(@type="%s" and name="%s")]',config_type,config_name));
  nodeList = expression.evaluate(doc_cfg,XPathConstants.NODESET);
  psc_cfg = nodeList.item(0);
  if isempty(psc_cfg)
    error('Could not find pulse sequence controller (psc) type "%s" and name "%s".', config_type, config_name);
  end
  
end

% 5. Read the pulse sequence
expression = xpath.compile('sequence');
sequence_nodeList = expression.evaluate(psc_cfg,XPathConstants.NODESET);
configs.psc.seq.name = {};
configs.psc.seq.mode = [];
configs.psc.seq.next = [];
configs.psc.seq.repeatTo = [];
configs.psc.seq.repeatCount = [];
configs.psc.seq.period = [];
for sequence_idx = 1:sequence_nodeList.getLength
  sequence_cfg = sequence_nodeList.item(sequence_idx-1);
  if isempty(sequence_cfg)
    continue;
  end
  
  expression = xpath.compile('name');
  nodeList = expression.evaluate(sequence_cfg,XPathConstants.NODESET);
  if nodeList.getLength < 1 || isempty(nodeList.item(0))
    name{sequence_idx} = '';
  else
    name = nodeList.item(0);
    configs.psc.seq.name{sequence_idx} = name.getTextContent.toCharArray.';
  end
  
  expression = xpath.compile('mode');
  nodeList = expression.evaluate(sequence_cfg,XPathConstants.NODESET);
  if nodeList.getLength < 1 || isempty(nodeList.item(0))
    continue;
  end
  mode_latch = nodeList.item(0);
  mode_latch = mode_latch.getTextContent.toCharArray;
  configs.psc.seq.mode(sequence_idx) = arena_convert_range(mode_latch);

  expression = xpath.compile('next');
  nodeList = expression.evaluate(sequence_cfg,XPathConstants.NODESET);
  if nodeList.getLength < 1 || isempty(nodeList.item(0))
    continue;
  end
  next = nodeList.item(0);
  next = next.getTextContent.toCharArray;
  configs.psc.seq.next(sequence_idx) = str2double(next(:).');
  
  expression = xpath.compile('repeatTo');
  nodeList = expression.evaluate(sequence_cfg,XPathConstants.NODESET);
  if nodeList.getLength < 1 || isempty(nodeList.item(0))
    continue;
  end
  repeatTo = nodeList.item(0);
  repeatTo = repeatTo.getTextContent.toCharArray;
  configs.psc.seq.repeatTo(sequence_idx) = str2double(repeatTo(:).');
  
  expression = xpath.compile('repeatCount');
  nodeList = expression.evaluate(sequence_cfg,XPathConstants.NODESET);
  if nodeList.getLength < 1 || isempty(nodeList.item(0))
    continue;
  end
  repeatCount = nodeList.item(0);
  repeatCount = repeatCount.getTextContent.toCharArray;
  configs.psc.seq.repeatCount(sequence_idx) = str2double(repeatCount(:).');
  
  expression = xpath.compile('period');
  nodeList = expression.evaluate(sequence_cfg,XPathConstants.NODESET);
  if nodeList.getLength < 1 || isempty(nodeList.item(0))
    continue;
  end
  period = nodeList.item(0);
  period = period.getTextContent.toCharArray;
  configs.psc.seq.period(sequence_idx) = str2double(period(:).')*1e-6;
end

epri_found = false;
psc = configs.psc;
psc.seq.idx = 0:length(psc.seq.name)-1;
for seq = psc.seq.idx
  if ~isempty(regexpi(psc.seq.name{seq+1},'epri'))
    epri_found = true;
  end
end
if ~epri_found
  fprintf('<strong>No mode named "epri". One sequence in the psc config must be named "epri".</strong>\nChoose an idx from below to be the EPRI:\n');
  fprintf(print_struct(psc.seq,2));
  uinput = [];
  while isempty(uinput) || ~isnumeric(uinput) || uinput < 0 || uinput > length(psc.seq.name)-1
    uinput = input('[0] ? ');
    if isempty(uinput)
      uinput = 0;
    end
  end
  psc.seq.name{uinput+1} = 'epri';
end


pulse = 0; seq = 0;
if ~isempty(regexpi(psc.seq.name{seq+1},'epri'))
  total_presums = 1;
else
  total_presums = 0; % Searching for first epri
end
total_pri = 0;
mode_count = [];
done = false;
max_iterations = 1e5; % Walk through 1e5 pulses (may need to be larger)
for iterations = 1:max_iterations
  if total_presums > 0
    total_presums = total_presums + 1;
    total_pri = total_pri + psc.seq.period(seq+1);
    if length(mode_count) < psc.seq.mode(seq+1)+1
      mode_count(psc.seq.mode(seq+1)+1) = 1;
    else
      mode_count(psc.seq.mode(seq+1)+1) = mode_count(psc.seq.mode(seq+1)+1) + 1;
    end
  end
  if psc.seq.repeatCount(seq+1) > 0
    % Decrement repeat counter
    psc.seq.repeatCount(seq+1) = psc.seq.repeatCount(seq+1) - 1;
    seq = psc.seq.repeatTo(seq+1);
  else
    % Reset repeat counter
    psc.seq.repeatCount(seq+1) = configs.psc.seq.repeatCount(seq+1);
    seq = psc.seq.next(seq+1);
    if ~isempty(regexpi(psc.seq.name{seq+1},'epri'))
      if total_presums == 0
        total_presums = 1;
      else
        done = true;
        total_presums = total_presums - 1;
        break;
      end
    end
  end
end
if ~done
  warning('max_iterations (%d) is too small and epri was not found twice in order to measure the effective pulse repetition interval. Rerun above loop with a larger max_state until done is true or verify CTU configuration is correct.', max_iterations);
  keyboard
end
configs.prf = 1/total_pri;
configs.total_presums = total_presums;
configs.psc.seq.mode_count = mode_count;

%% ADCS/DIGRX
% =========================================================================
% Get all the ADCs
expression = xpath.compile('//subSystem[contains(@type,"adc")]');
% expression = xpath.compile('//subSystem[@type="daq"]');
adcList = expression.evaluate(doc,XPathConstants.NODESET);

for adc_idx = 1:adcList.getLength
  
  % 1. Get the name of the ADC
  % expression = xpath.compile('//subSystem[starts-with(@type,"adc")]/name');
  % expression = xpath.compile('//subSystem[@type="daq"]');
  expression = xpath.compile('name');
  nodeList = expression.evaluate(adcList.item(adc_idx-1),XPathConstants.NODESET);
  name = nodeList.item(0).getTextContent.toCharArray;
  name = name(:).';
  if isempty(adc_map)
    board_idx = adc_idx;
  else
    board_idx = strmatch(name,adc_map);
  end
  if isempty(board_idx)
    continue;
  end
  
  % 2. Search for the subSystem in the config XML
  expression = xpath.compile(sprintf('//subSystem/subSystem[name="%s"]',name));
  nodeList = expression.evaluate(doc_cfg,XPathConstants.NODESET);
  match = nodeList.item(0);
  
  % 3. Get the config name and type for this ADC
  expression = xpath.compile('config/@type');
  nodeList = expression.evaluate(match,XPathConstants.NODESET);
  config_type = nodeList.item(0).getTextContent.toCharArray;
  config_type = config_type(:).';
  expression = xpath.compile('config');
  nodeList = expression.evaluate(match,XPathConstants.NODESET);
  config_name = nodeList.item(0).getTextContent.toCharArray;
  config_name = config_name(:).';
  
  % Get the config associated with this ADC
  expression = xpath.compile(sprintf('//configs/config[(@type="%s" and name="%s")]',config_type,config_name));
  nodeList = expression.evaluate(doc_cfg,XPathConstants.NODESET);
  adc_cfg = nodeList.item(0);
  
  
%         <config type="socket">
%          <name>rds_digrx1_udp</name>
%          <description></description>
%          <multiFlag>0</multiFlag>
%          <ip>172.16.0.121</ip>
%          <port>55001</port>
%          <payloadSize>8192</payloadSize>
%       </config>
%       <config type="socket">
%          <name>rds_digrx2_udp</name>
%          <description></description>
%          <multiFlag>0</multiFlag>
%          <ip>172.16.0.121</ip>
%          <port>55002</port>
%          <payloadSize>8192</payloadSize>
%       </config>
%       <config type="streamudp">
%          <name>snow_udp</name>
%          <description></description>
%          <multiFlag>0</multiFlag>
%          <ip>172.16.0.121</ip>
%          <port>55000</port>
%          <payloadSize>8192</payloadSize>
%       </config>
%          <dataStream type="udp">
%             <id>0</id>
%             <name>dataStream0</name>
%             <stream>
%                <interface type="nic">eth0</interface>
%                <config type="streamudp">snow_udp</config>
%             </stream>
%          </dataStream>

  
  % Get the datastream type
  expression = xpath.compile('dataStream/@type');
  nodeList = expression.evaluate(match,XPathConstants.NODESET);
  if nodeList.getLength > 0
    datastream_config_type = nodeList.item(0).getTextContent.toCharArray;
    datastream_config_type = datastream_config_type(:).';
    configs.datastream_type = datastream_config_type;
    if 0
      expression = xpath.compile('dataStream/config');
      nodeList = expression.evaluate(match,XPathConstants.NODESET);
      datastream_config_name = nodeList.item(0).getTextContent.toCharArray;
      datastream_config_name = datastream_config_name(:).';
      
      expression = xpath.compile(sprintf('//configs/config[(@type="%s" and name="%s")]',['stream' datastream_config_type],datastream_config_name));
      nodeList = expression.evaluate(doc_cfg,XPathConstants.NODESET);
      datastream_cfg = nodeList.item(0);
      
      expression = xpath.compile('port');
      nodeList = expression.evaluate(datastream_cfg,XPathConstants.NODESET);
      port = nodeList.item(0).getTextContent.toCharArray;
      port = port(:).';
    end
  else
    expression = xpath.compile('dataOutput');
    nodeList = expression.evaluate(match,XPathConstants.NODESET);
    if nodeList.getLength > 0
      configs.datastream_type = 'udp';
      if 0
        expression = xpath.compile('dataOutput/config');
        nodeList = expression.evaluate(match,XPathConstants.NODESET);
        datastream_config_name = nodeList.item(0).getTextContent.toCharArray;
        datastream_config_name = datastream_config_name(:).';
        
        expression = xpath.compile(sprintf('//configs/config[(@type="%s" and name="%s")]','socket',datastream_config_name));
        nodeList = expression.evaluate(doc_cfg,XPathConstants.NODESET);
        datastream_cfg = nodeList.item(0);
        
        expression = xpath.compile('port');
        nodeList = expression.evaluate(datastream_cfg,XPathConstants.NODESET);
        port = nodeList.item(0).getTextContent.toCharArray;
        port = port(:).';
      end
    else
      % No data stream found
      warning('No data stream found in the configuration file.');
      configs.datastream_type = 'socket';
    end
  end
  
  % Load configs and find the longest possible record size which is used
  % by arena_packet_strip to prevent bad headers from causing major data
  % loss.
  if strcmpi(config_type,'adc-ads42lb69_0010')
    % =====================================================================
    % TOHFSounder
    % =====================================================================
    
    % Get each subchannel
    expression = xpath.compile('subChannels/subChannel');
    subchannel_nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    for subchannel_idx = 1:subchannel_nodeList.getLength
      subchannel_cfg = subchannel_nodeList.item(subchannel_idx-1);
      if isempty(subchannel_cfg)
        continue;
      end
      
      expression = xpath.compile('id');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      subchannel = nodeList.item(0);
      subchannel = subchannel.getTextContent.toCharArray;
      subchannel = str2double(subchannel(:).');
      
      expression = xpath.compile('mode');
      mode_nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      for mode_idx = 1:mode_nodeList.getLength
        mode_cfg = mode_nodeList.item(mode_idx-1);
        if isempty(mode_cfg)
          continue;
        end
        
        expression = xpath.compile('id');
        nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        mode_latch = nodeList.item(0);
        mode_latch = mode_latch.getTextContent.toCharArray;
        mode_latch = arena_convert_range(mode_latch);
        
        expression = xpath.compile('ncoFreq');
        nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        ncoFreq = nodeList.item(0);
        ncoFreq = ncoFreq.getTextContent.toCharArray;
        ncoFreq = str2double(ncoFreq(:).') * 1e6;
        configs.adc{adc_idx,mode_latch+1,subchannel+1}.ncoFreq = ncoFreq;
        
        expression = xpath.compile('cicDecimation');
        nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        cicDecimation = nodeList.item(0);
        cicDecimation = cicDecimation.getTextContent.toCharArray;
        cicDecimation = str2double(cicDecimation(:).');
        configs.adc{adc_idx,mode_latch+1,subchannel+1}.cicDecimation = cicDecimation;
      end
    end
    
    % Get each subchannel
    expression = xpath.compile('processing/subChannel');
    subchannel_nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    for subchannel_idx = 1:subchannel_nodeList.getLength
      subchannel_cfg = subchannel_nodeList.item(subchannel_idx-1);
      if isempty(subchannel_cfg)
        continue;
      end
      
      expression = xpath.compile('id');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      subchannel = nodeList.item(0);
      subchannel = subchannel.getTextContent.toCharArray;
      subchannel = str2double(subchannel(:).');
      
      expression = xpath.compile('mode');
      mode_nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      for mode_idx = 1:mode_nodeList.getLength
        mode_cfg = mode_nodeList.item(mode_idx-1);
        if isempty(mode_cfg)
          continue;
        end
        
        expression = xpath.compile('id');
        nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        mode_latch = nodeList.item(0);
        mode_latch = mode_latch.getTextContent.toCharArray;
        mode_latch = arena_convert_range(mode_latch);
        
        expression = xpath.compile('digRx_RG');
        nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        digRx_RG = nodeList.item(0);
        digRx_RG = digRx_RG.getTextContent.toCharArray;
        digRx_RG = digRx_RG(:).';
        % Assumes simple range gate format "start:stop"
        [start,stop] = strtok(digRx_RG,':'); stop=stop(2:end);
        num_bins = str2double(stop) - str2double(start) + 1;
        if num_bins < configs.min_num_bins
          configs.min_num_bins = num_bins;
        end
        if num_bins > configs.max_num_bins
          configs.max_num_bins = num_bins;
        end
        
        configs.adc{adc_idx,mode_latch+1,subchannel+1}.rg = rg;
      end
    end
    
  elseif strcmpi(config_type,'adc-isla214p50_0005')
    % =====================================================================
    % KUSnow
    % =====================================================================
    expression = xpath.compile('//subChannels/subChannel/mode/rg');
    nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    for mode_idx = 1:nodeList.getLength
      modes = nodeList.item(mode_idx-1);
      range_gates = modes.getTextContent.toCharArray;
      range_gates = range_gates(:).';
      % Assumes simple range gate format "start:stop"
      [start,stop] = strtok(range_gates,':'); stop=stop(2:end);
      num_bins = str2double(stop) - str2double(start) + 1;
      if num_bins < configs.min_num_bins
        configs.min_num_bins = num_bins;
      end
      if num_bins > configs.max_num_bins
        configs.max_num_bins = num_bins;
      end
    end
    
  elseif strcmpi(config_type,'adc-ads42lb69_0010')
    % =====================================================================
    % DopplerScat
    % =====================================================================
    expression = xpath.compile('//processing/subChannel/mode/digRx_RG');
    nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    for mode_idx = 1:nodeList.getLength
      modes = nodeList.item(mode_idx-1);
      range_gates = modes.getTextContent.toCharArray;
      range_gates = range_gates(:).';
      % Assumes simple range gate format "start:stop"
      [start,stop] = strtok(range_gates,':'); stop=stop(2:end);
      num_bins = str2double(stop) - str2double(start) + 1;
      if num_bins < configs.min_num_bins
        configs.min_num_bins = num_bins;
      end
      if num_bins > configs.max_num_bins
        configs.max_num_bins = num_bins;
      end
    end
    
   elseif strcmpi(config_type,'rfsoc_adc_2002')
    % =====================================================================
    % Arena 522 COLDEX
    % =====================================================================
    
    % Get the sampling frequencies in MHz
    expression = xpath.compile('adcSampClk');
    nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    if nodeList.getLength < 1 || isempty(nodeList.item(0))
      continue;
    end
    sampFreq = nodeList.item(0);
    sampFreq = sampFreq.getTextContent.toCharArray;
    sampFreq = str2double(sampFreq(:).') * 1e6;
    
    expression = xpath.compile('ddcDecimation');
    nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    if nodeList.getLength < 1 || isempty(nodeList.item(0))
      continue;
    end
    ddcDecimation = nodeList.item(0);
    ddcDecimation = ddcDecimation.getTextContent.toCharArray;
    ddcDecimation = str2double(ddcDecimation(:).');
    
    sampFreq = sampFreq / ddcDecimation;
    
    % Load each down converter settings
    % =====================================================================
    expression = xpath.compile('ncoFreqs/ncoFreq');
    ncoFreq_nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    ncoFreq_list = [];
    for ncoFreq_idx = 1:ncoFreq_nodeList.getLength
      ncoFreq_cfg = ncoFreq_nodeList.item(ncoFreq_idx-1);
      if isempty(ncoFreq_cfg)
        continue;
      end
      
      % <ncoFreqs>
      %   <ncoFreq>
      %     <subChannels>0:7</subChannels>
      %     <modes>0:255</modes>
      %     <freq>700</freq>
      %   </ncoFreq>
      % </ncoFreqs>

      % Load the subchannel ID
      expression = xpath.compile('subChannels');
      nodeList = expression.evaluate(ncoFreq_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      subchannel = nodeList.item(0);
      subchannel = subchannel.getTextContent.toCharArray;
      subchannel = arena_convert_range(subchannel);
      ncoFreq_list(end+1).subchannel = subchannel;
      
      % Load the modes
      expression = xpath.compile('modes');
      nodeList = expression.evaluate(ncoFreq_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      modes = nodeList.item(0);
      modes = modes.getTextContent.toCharArray;
      modes = arena_convert_range(modes);
      ncoFreq_list(end).modes = modes;
      
      expression = xpath.compile('freq');
      nodeList = expression.evaluate(ncoFreq_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      ncoFreq = nodeList.item(0);
      ncoFreq = ncoFreq.getTextContent.toCharArray;
      ncoFreq = str2double(ncoFreq(:).') * 1e6;
      ncoFreq_list(end).ncoFreq = ncoFreq;
    end
    
    % Load each down converter settings
    % =====================================================================
    expression = xpath.compile('dcSetting');
    subchannel_nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    subchannels = [];
    for subchannel_idx = 1:subchannel_nodeList.getLength
      subchannel_cfg = subchannel_nodeList.item(subchannel_idx-1);
      if isempty(subchannel_cfg)
        continue;
      end
      
      % <dcSetting>
      % <subChannels>0</subChannels>
      % <modes>0</modes>
      % <adcChannel>0</adcChannel>
      % <zeroPi>0</zeroPi>
      % <adcDecimation>3</adcDecimation>
      % <route>RFSOC</route>
      % <ncoFreq>0</ncoFreq>
      % <ncoPhase>0</ncoPhase>
      % <cicDecimation>0</cicDecimation>

      % Load the subchannel ID
      expression = xpath.compile('subChannels');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      subchannel = nodeList.item(0);
      subchannel = subchannel.getTextContent.toCharArray;
      subchannel = arena_convert_range(subchannel);
      subchannels(end+1).subchannel = subchannel;
      
      % Load the modes
      expression = xpath.compile('modes');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      modes = nodeList.item(0);
      modes = modes.getTextContent.toCharArray;
      modes = arena_convert_range(modes);
      subchannels(end).modes = modes;
      
      expression = xpath.compile('adcChannel');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      adcChannel = nodeList.item(0);
      adcChannel = adcChannel.getTextContent.toCharArray;
      adcChannel = arena_convert_range(adcChannel);
      subchannels(end).adcChannel = adcChannel;
      
      expression = xpath.compile('zeroPi');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      zeroPi = nodeList.item(0);
      zeroPi = zeroPi.getTextContent.toCharArray;
      zeroPi = str2double(zeroPi);
      subchannels(end).zeroPi = zeroPi;
      
      expression = xpath.compile('adcDecimation');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      adcDecimation = nodeList.item(0);
      adcDecimation = adcDecimation.getTextContent.toCharArray;
      adcDecimation = str2double(adcDecimation);
      subchannels(end).adcDecimation = adcDecimation+1;
      
      expression = xpath.compile('route');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      route = nodeList.item(0);
      subchannels(end).route = route.getTextContent.toCharArray;
      subchannels(end).route = subchannels(end).route(:).';
      
      expression = xpath.compile('ncoFreq');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      ncoFreq = nodeList.item(0);
      ncoFreq = ncoFreq.getTextContent.toCharArray;
      ncoFreq = str2double(ncoFreq)*1e6;
      subchannels(end).ncoFreq = ncoFreq;
      
      expression = xpath.compile('ncoPhase');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      ncoPhase = nodeList.item(0);
      ncoPhase = ncoPhase.getTextContent.toCharArray;
      ncoPhase = str2double(ncoPhase);
      subchannels(end).ncoPhase = ncoPhase;
    end
    
    % Load each intra-profile processing settings
    % =====================================================================
    expression = xpath.compile('ippSetting');
    ipp_settings_nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    ipp_settings = [];
    for ipp_settings_idx = 1:ipp_settings_nodeList.getLength
      ipp_settings_cfg = ipp_settings_nodeList.item(ipp_settings_idx-1);
      if isempty(ipp_settings_cfg)
        continue;
      end
      
      % <ippSetting>
      % <subChannels>0:7</subChannels>
      % <modes>0:3</modes>
      % <digRx_RG>0:2047</digRx_RG>
      % <fftSize>128</fftSize>
      % <fftStartGate>0</fftStartGate>
      % <fftMinGate>0</fftMinGate>
      % <weighting></weighting>
      % <fwdFFT_RG></fwdFFT_RG>
      % <refFunc></refFunc>
      % <revFFT_RG></revFFT_RG>
      
      % Load the subchannel ID
      expression = xpath.compile('subChannels');
      nodeList = expression.evaluate(ipp_settings_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      subchannel = nodeList.item(0);
      subchannel = subchannel.getTextContent.toCharArray;
      subchannel = arena_convert_range(subchannel);
      ipp_settings(end+1).subchannel = subchannel;
      
      % Load the modes
      expression = xpath.compile('modes');
      nodeList = expression.evaluate(ipp_settings_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      modes = nodeList.item(0);
      modes = modes.getTextContent.toCharArray;
      modes = arena_convert_range(modes);
      ipp_settings(end).modes = modes;
      
      expression = xpath.compile('digRx_RG');
      nodeList = expression.evaluate(ipp_settings_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      digRx_RG = nodeList.item(0);
      digRx_RG = digRx_RG.getTextContent.toCharArray;
      digRx_RG = arena_convert_range(digRx_RG);
      ipp_settings(end).digRx_RG = digRx_RG;
      
      num_bins = length(digRx_RG);
      if num_bins < configs.min_num_bins
        configs.min_num_bins = num_bins;
      end
      if num_bins > configs.max_num_bins
        configs.max_num_bins = num_bins;
      end
      
    end
    
    % Load each profile input
    % =====================================================================
    expression = xpath.compile('profileProcessing/input');
    subchannel_nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    profileInput = [];
    for subchannel_idx = 1:subchannel_nodeList.getLength
      subchannel_cfg = subchannel_nodeList.item(subchannel_idx-1);
      if isempty(subchannel_cfg)
        continue;
      end
      
      % <profileProcessing>
      %   <masterResetMode>-1</masterResetMode>
      %   <input>
      %     <name>ch0_10us</name>
      %     <profileDataType>DigRx</profileDataType>
      %     <profileMode>2:3</profileMode>
      %     <profileSubChannel>0</profileSubChannel>
      %   </input>
      
      % Load the profile name
      expression = xpath.compile('name');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      profile_input_name = nodeList.item(0);
      profileInput(end+1).name = profile_input_name.getTextContent.toCharArray;
      profileInput(end).name = profileInput(end).name(:).';
      
      % Load the profile modes
      expression = xpath.compile('profileMode');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      profileMode = nodeList.item(0);
      profileMode = profileMode.getTextContent.toCharArray;
      profileMode = arena_convert_range(profileMode);
      profileInput(end).profileMode = profileMode;
      
      % Load the profile subchannels
      expression = xpath.compile('profileSubChannel');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      profileSubChannel = nodeList.item(0);
      profileSubChannel = profileSubChannel.getTextContent.toCharArray;
      profileSubChannel = arena_convert_range(profileSubChannel(:).');
      profileInput(end).profileSubChannel = profileSubChannel;
    end

    
    % Load each profile processor
    % =====================================================================
    expression = xpath.compile('profileProcessing/processor');
    subchannel_nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    profileProcessor = [];
    for subchannel_idx = 1:subchannel_nodeList.getLength
      subchannel_cfg = subchannel_nodeList.item(subchannel_idx-1);
      if isempty(subchannel_cfg)
        continue;
      end
      
      % <profileProcessing>
      %   <processor>
      %     <name>ch0</name>
      %     <resetMode>-1</resetMode>
      %     <input1>ch0</input1>
      %     <processorType>Coherent Accum.</processorType>
      %     <input2>ch0</input2>
      %     <input2ProfileLag>0</input2ProfileLag>
      %     <start>0</start>
      %     <length>2048</length>
      %     <accumulations>29</accumulations>
      %   </processor>
      
      % Load the subchannel ID
      expression = xpath.compile('name');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      profile_processor_name = nodeList.item(0);
      profileProcessor(end+1).name = profile_processor_name.getTextContent.toCharArray;
      profileProcessor(end).name = profileProcessor(end).name(:).';
      
      % Load the subchannel ID
      expression = xpath.compile('length');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      profile_length = nodeList.item(0);
      profile_length = profile_length.getTextContent.toCharArray;
      profile_length = str2double(profile_length(:).');
      profileProcessor(end).profile_length = profile_length;
      
      expression = xpath.compile('accumulations');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      accumulations = nodeList.item(0);
      accumulations = accumulations.getTextContent.toCharArray;
      accumulations = str2double(accumulations(:).');
      profileProcessor(end).accumulations = accumulations;
      
    end

    % Update adc configs for this integrator's modes and subchannel
    for profile_idx = 1:length(profileInput)
      for mode_latch = profileInput(profile_idx).profileMode
        for subchannel = profileInput(profile_idx).profileSubChannel
      
          % Search for the particular mode/subchannel in the subchannels
          found_mode = false;
          for idx = 1:length(subchannels)
            if any(subchannels(idx).modes == mode_latch) && any(subchannels(idx).subchannel == subchannel)
              adcDecimation = subchannels(idx).adcDecimation;
              ncoFreq = subchannels(idx).ncoFreq;
              ncoPhase = subchannels(idx).ncoPhase;
              found_mode = true;
              break;
            end
          end
          if ~found_mode
            % Should not happen for a good config file
            keyboard
          end
          
          % Search for the particular mode/subchannel in the processing
          found_mode = false;
          for idx = 1:length(ipp_settings)
            if any(ipp_settings(idx).modes == mode_latch) && any(ipp_settings(idx).subchannel == subchannel)
              digRx_RG = ipp_settings(idx).digRx_RG;
              found_mode = true;
              break;
            end
          end
          if ~found_mode
            % Should not happen for a good config file
            keyboard
          end
          
          % Search for the particular mode/subchannel in the 
          found_mode = false;
          for idx = 1:length(profileProcessor)
            if strcmpi(profileProcessor(idx).name,profileInput(profile_idx).name)
              profile_length = profileProcessor(idx).profile_length;
              accumulations = profileProcessor(idx).accumulations;
              found_mode = true;
              break;
            end
          end
          if ~found_mode
            % Should not happen for a good config file
            keyboard
          end
          
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.name = name;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.config_name = config_name;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.config_type = config_type;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ncoPhase = ncoPhase;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ncoFreq = ncoFreq_list(1).ncoFreq;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc0NcoMode = 2;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc1NcoMode = 2;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc2NcoMode = 2;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc3NcoMode = 2;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc0NcoFreq = ncoFreq_list(1).ncoFreq;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc1NcoFreq = ncoFreq_list(1).ncoFreq;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc2NcoFreq = ncoFreq_list(1).ncoFreq;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc3NcoFreq = ncoFreq_list(1).ncoFreq;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.cicDecimation = adcDecimation;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.adcMode = NaN;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.sampFreq = sampFreq;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.presums = accumulations;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.num_sam = profile_length;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.rg = sprintf('%d',digRx_RG(1));
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.shiftLSB = 0; % 32 bit float
        end
      end
    end
    
   elseif strcmpi(config_type,'adc-ad9684_002D')
    % =====================================================================
    % GHOST RDS
    % =====================================================================
    
    % Get the sampling frequencies in MHz
    expression = xpath.compile('sampFreq0');
    nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    if nodeList.getLength < 1 || isempty(nodeList.item(0))
      continue;
    end
    sampFreq0 = nodeList.item(0);
    sampFreq0 = sampFreq0.getTextContent.toCharArray;
    sampFreq0 = str2double(sampFreq0(:).') * 1e6;
    
    expression = xpath.compile('sampFreq1');
    nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    if nodeList.getLength < 1 || isempty(nodeList.item(0))
      continue;
    end
    sampFreq1 = nodeList.item(0);
    sampFreq1 = sampFreq1.getTextContent.toCharArray;
    sampFreq1 = str2double(sampFreq1(:).') * 1e6;
    
    % Load each subchannel
    % =====================================================================
    expression = xpath.compile('subChannels/subChannel');
    subchannel_nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    subchannels = [];
    for subchannel_idx = 1:subchannel_nodeList.getLength
      subchannel_cfg = subchannel_nodeList.item(subchannel_idx-1);
      if isempty(subchannel_cfg)
        continue;
      end
      
      % Load the subchannel ID
      expression = xpath.compile('id');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      subchannel = nodeList.item(0);
      subchannel = subchannel.getTextContent.toCharArray;
      subchannel = str2double(subchannel(:).');
      subchannels(end+1).id = subchannel;
      
      % Load each subchannel's modes
      expression = xpath.compile('mode');
      mode_nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      subchannels(end).modes = [];
      for mode_idx = 1:mode_nodeList.getLength
        mode_cfg = mode_nodeList.item(mode_idx-1);
        if isempty(mode_cfg)
          continue;
        end
        
        expression = xpath.compile('id');
        nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        modes = nodeList.item(0);
        modes = modes.getTextContent.toCharArray;
        modes = arena_convert_range(modes);
        subchannels(end).modes(end+1).modes = modes;
        
        expression = xpath.compile('adcChannel');
        nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        adcChannel = nodeList.item(0);
        adcChannel = adcChannel.getTextContent.toCharArray;
        adcChannel = arena_convert_range(adcChannel);
        subchannels(end).modes(end).adcChannel = adcChannel;
        
        expression = xpath.compile('zeroPi');
        nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        zeroPi = nodeList.item(0);
        zeroPi = zeroPi.getTextContent.toCharArray;
        zeroPi = str2double(zeroPi);
        subchannels(end).modes(end).zeroPi = zeroPi;
        
        expression = xpath.compile('adcDecimation');
        nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        adcDecimation = nodeList.item(0);
        adcDecimation = adcDecimation.getTextContent.toCharArray;
        adcDecimation = str2double(adcDecimation);
        subchannels(end).modes(end).adcDecimation = adcDecimation;
        
        expression = xpath.compile('route');
        nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        route = nodeList.item(0);
        subchannels(end).modes(end).route = route.getTextContent.toCharArray;
        subchannels(end).modes(end).route = subchannels(end).modes(end).route(:).';
        
        expression = xpath.compile('ncoFreq');
        nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        ncoFreq = nodeList.item(0);
        ncoFreq = ncoFreq.getTextContent.toCharArray;
        ncoFreq = str2double(ncoFreq)*1e6;
        subchannels(end).modes(end).ncoFreq = ncoFreq;
        
        expression = xpath.compile('ncoPhase');
        nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        ncoPhase = nodeList.item(0);
        ncoPhase = ncoPhase.getTextContent.toCharArray;
        ncoPhase = str2double(ncoPhase);
        subchannels(end).modes(end).ncoPhase = ncoPhase;
        
      end
    end
    
    % Load each processing chain
    % =====================================================================
    expression = xpath.compile('processing/subChannel');
    subchannel_nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    processing = [];
    for subchannel_idx = 1:subchannel_nodeList.getLength
      subchannel_cfg = subchannel_nodeList.item(subchannel_idx-1);
      if isempty(subchannel_cfg)
        continue;
      end
      
      % Load the subchannel ID
      expression = xpath.compile('id');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      subchannel = nodeList.item(0);
      subchannel = subchannel.getTextContent.toCharArray;
      subchannel = str2double(subchannel(:).');
      processing(end+1).id = subchannel;
      
      % Load each subchannel's modes
      expression = xpath.compile('mode');
      mode_nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      processing(end).modes = [];
      for mode_idx = 1:mode_nodeList.getLength
        mode_cfg = mode_nodeList.item(mode_idx-1);
        if isempty(mode_cfg)
          continue;
        end
        
        expression = xpath.compile('id');
        nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        modes = nodeList.item(0);
        modes = modes.getTextContent.toCharArray;
        modes = arena_convert_range(modes);
        processing(end).modes(end+1).modes = modes;
        
        expression = xpath.compile('digRx_RG');
        nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        digRx_RG = nodeList.item(0);
        digRx_RG = digRx_RG.getTextContent.toCharArray;
        digRx_RG = arena_convert_range(digRx_RG);
        processing(end).modes(end).digRx_RG = digRx_RG;
        
        num_bins = length(digRx_RG);
        if num_bins < configs.min_num_bins
          configs.min_num_bins = num_bins;
        end
        if num_bins > configs.max_num_bins
          configs.max_num_bins = num_bins;
        end
        
      end
    end
    
    % Load each profile input
    % =====================================================================
    expression = xpath.compile('profileProcessing/input');
    subchannel_nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    profileInput = [];
    for subchannel_idx = 1:subchannel_nodeList.getLength
      subchannel_cfg = subchannel_nodeList.item(subchannel_idx-1);
      if isempty(subchannel_cfg)
        continue;
      end
      
      % Load the profile name
      expression = xpath.compile('name');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      profile_input_name = nodeList.item(0);
      profileInput(end+1).name = profile_input_name.getTextContent.toCharArray;
      profileInput(end).name = profileInput(end).name(:).';
      
      % Load the profile modes
      expression = xpath.compile('profileMode');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      profileMode = nodeList.item(0);
      profileMode = profileMode.getTextContent.toCharArray;
      profileMode = arena_convert_range(profileMode);
      profileInput(end).profileMode = profileMode;
      
      % Load the profile subchannels
      expression = xpath.compile('profileSubChannel');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      profileSubChannel = nodeList.item(0);
      profileSubChannel = profileSubChannel.getTextContent.toCharArray;
      profileSubChannel = arena_convert_range(profileSubChannel(:).');
      profileInput(end).profileSubChannel = profileSubChannel;
    end

    
    % Load each profile processor
    % =====================================================================
    expression = xpath.compile('profileProcessing/processor');
    subchannel_nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    profileProcessor = [];
    for subchannel_idx = 1:subchannel_nodeList.getLength
      subchannel_cfg = subchannel_nodeList.item(subchannel_idx-1);
      if isempty(subchannel_cfg)
        continue;
      end
      
      % Load the subchannel ID
      expression = xpath.compile('name');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      profile_processor_name = nodeList.item(0);
      profileProcessor(end+1).name = profile_processor_name.getTextContent.toCharArray;
      profileProcessor(end).name = profileProcessor(end).name(:).';
      
      % Load the subchannel ID
      expression = xpath.compile('length');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      profile_length = nodeList.item(0);
      profile_length = profile_length.getTextContent.toCharArray;
      profile_length = str2double(profile_length(:).');
      profileProcessor(end).profile_length = profile_length;
      
      expression = xpath.compile('accumulations');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      accumulations = nodeList.item(0);
      accumulations = accumulations.getTextContent.toCharArray;
      accumulations = str2double(accumulations(:).');
      profileProcessor(end).accumulations = accumulations+1;
      
    end

    % Update adc configs for this integrator's modes and subchannel
    for profile_idx = 1:length(profileInput)
      for mode_latch = profileInput(profile_idx).profileMode
        for subchannel = profileInput(profile_idx).profileSubChannel
      
          % Search for the particular mode/subchannel in the subchannels
          found_mode = false;
          for idx = 1:length(subchannels(subchannel+1).modes)
            if any(subchannels(subchannel+1).modes(idx).modes == mode_latch)
              ncoFreq = subchannels(subchannel+1).modes(idx).ncoFreq;
              ncoPhase = subchannels(subchannel+1).modes(idx).ncoPhase;
              found_mode = true;
              break;
            end
          end
          if ~found_mode
            % Should not happen for a good config file
            keyboard
          end
          
          % Search for the particular mode/subchannel in the processing
          found_mode = false;
          for idx = 1:length(processing(subchannel+1).modes)
            if any(processing(subchannel+1).modes(idx).modes == mode_latch)
              digRx_RG = processing(subchannel+1).modes(idx).digRx_RG;
              found_mode = true;
              break;
            end
          end
          if ~found_mode
            % Should not happen for a good config file
            keyboard
          end
          
          % Search for the particular mode/subchannel in the 
          found_mode = false;
          for idx = 1:length(profileProcessor)
            if strcmpi(profileProcessor(idx).name,profileInput(profile_idx).name)
              profile_length = profileProcessor(idx).profile_length;
              accumulations = profileProcessor(idx).accumulations;
              found_mode = true;
              break;
            end
          end
          if ~found_mode
            % Should not happen for a good config file
            keyboard
          end

          decimation = 4;
          
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.name = name;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.config_name = config_name;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.config_type = config_type;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ncoPhase = ncoPhase;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ncoFreq = ncoFreq;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc0NcoMode = 2;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc1NcoMode = 2;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc2NcoMode = 2;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc3NcoMode = 2;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc0NcoFreq = ncoFreq;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc1NcoFreq = ncoFreq;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc2NcoFreq = ncoFreq;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc3NcoFreq = ncoFreq;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.cicDecimation = decimation;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.adcMode = NaN;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.sampFreq = sampFreq0;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.presums = accumulations;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.num_sam = profile_length;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.rg = sprintf('%d',digRx_RG(1));
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.shiftLSB = 0; % 32 bit float
        end
      end
    end
   
  elseif strcmpi(config_type,'adc-ad9680_0017')
    % =====================================================================
    % BAS Accumulation Radar, Dome Fuji RDS
    % =====================================================================
    
    % Get the ADC mode
    % (0=no decimation, 1=decimation by 2, 2=decimation by 4).
    expression = xpath.compile('adcMode');
    nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    if nodeList.getLength < 1 || isempty(nodeList.item(0))
      continue;
    end
    adcMode = nodeList.item(0);
    adcMode = adcMode.getTextContent.toCharArray;
    adcMode = str2double(adcMode(:).');
    
    % Get the sampling frequency
    expression = xpath.compile('sampFreq');
    nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    if nodeList.getLength < 1 || isempty(nodeList.item(0))
      continue;
    end
    sampFreq = nodeList.item(0);
    sampFreq = sampFreq.getTextContent.toCharArray;
    sampFreq = str2double(sampFreq(:).') * 1e6;
    
    % Get the DDC0 NCO Mode
    expression = xpath.compile('ddc0NcoMode');
    nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    if nodeList.getLength < 1 || isempty(nodeList.item(0))
      continue;
    end
    ddc0NcoMode = nodeList.item(0);
    ddc0NcoMode = ddc0NcoMode.getTextContent.toCharArray;
    ddc0NcoMode = str2double(ddc0NcoMode(:).');    
    
    % Get the DDC1 NCO Mode
    expression = xpath.compile('ddc1NcoMode');
    nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    if nodeList.getLength < 1 || isempty(nodeList.item(0))
      continue;
    end
    ddc1NcoMode = nodeList.item(0);
    ddc1NcoMode = ddc1NcoMode.getTextContent.toCharArray;
    ddc1NcoMode = str2double(ddc1NcoMode(:).');
    
    % Get the DDC0 NCO Frequency
    expression = xpath.compile('ddc0NcoFreq');
    nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    if nodeList.getLength < 1 || isempty(nodeList.item(0))
      continue;
    end
    ddc0NcoFreq = nodeList.item(0);
    ddc0NcoFreq = ddc0NcoFreq.getTextContent.toCharArray;
    ddc0NcoFreq = str2double(ddc0NcoFreq(:).') * 1e6;    
    
    % Get the DDC1 NCO Frequency
    expression = xpath.compile('ddc1NcoFreq');
    nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    if nodeList.getLength < 1 || isempty(nodeList.item(0))
      continue;
    end
    ddc1NcoFreq = nodeList.item(0);
    ddc1NcoFreq = ddc1NcoFreq.getTextContent.toCharArray;
    ddc1NcoFreq = str2double(ddc1NcoFreq(:).') * 1e6;
    
    % Get each subchannel
    expression = xpath.compile('subChannels/subChannel');
    subchannel_nodeList = expression.evaluate(adc_cfg,XPathConstants.NODESET);
    for subchannel_idx = 1:subchannel_nodeList.getLength
      subchannel_cfg = subchannel_nodeList.item(subchannel_idx-1);
      if isempty(subchannel_cfg)
        continue;
      end
      
      % Load the subchannel ID
      expression = xpath.compile('id');
      nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      subchannel = nodeList.item(0);
      subchannel = subchannel.getTextContent.toCharArray;
      subchannel = str2double(subchannel(:).');
      
      % Load each digital receiver's configs
      expression = xpath.compile('digRx');
      digRx_nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      for digRx_idx = 1:digRx_nodeList.getLength
        digRx_cfg = digRx_nodeList.item(digRx_idx-1);
        if isempty(digRx_cfg)
          continue;
        end
        
        expression = xpath.compile('modes');
        nodeList = expression.evaluate(digRx_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        modes = nodeList.item(0);
        modes = modes.getTextContent.toCharArray;
        modes = arena_convert_range(modes);
        
        expression = xpath.compile('ncoPhase');
        nodeList = expression.evaluate(digRx_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        ncoPhase = nodeList.item(0);
        ncoPhase = ncoPhase.getTextContent.toCharArray;
        ncoPhase = str2double(ncoPhase(:).');
        
        expression = xpath.compile('ncoFreq');
        nodeList = expression.evaluate(digRx_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        ncoFreq = nodeList.item(0);
        ncoFreq = ncoFreq.getTextContent.toCharArray;
        ncoFreq = str2double(ncoFreq(:).') * 1e6;
        
        expression = xpath.compile('decimation');
        nodeList = expression.evaluate(digRx_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        decimation = nodeList.item(0);
        decimation = decimation.getTextContent.toCharArray;
        decimation = str2double(decimation(:).');
        
        % Update adc configs for this integrator's modes and subchannel
        for mode_idx = 1:length(modes)
          mode_latch = modes(mode_idx);
          
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.name = name;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.config_name = config_name;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.config_type = config_type;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ncoPhase = ncoPhase;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ncoFreq = ncoFreq;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.cicDecimation = decimation;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.adcMode = adcMode;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.sampFreq = sampFreq;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc0NcoMode = ddc0NcoMode;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc1NcoMode = ddc1NcoMode;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc0NcoFreq = ddc0NcoFreq;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.ddc1NcoFreq = ddc1NcoFreq;
        end
      end
      
      % Load each integrator's configs
      expression = xpath.compile('integrator');
      integrator_nodeList = expression.evaluate(subchannel_cfg,XPathConstants.NODESET);
      for integrator_idx = 1:integrator_nodeList.getLength
        integrator_cfg = integrator_nodeList.item(integrator_idx-1);
        if isempty(integrator_cfg)
          continue;
        end
        
        % Modes that this integrator services
        expression = xpath.compile('modes');
        nodeList = expression.evaluate(integrator_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        modes = nodeList.item(0);
        modes = modes.getTextContent.toCharArray;
        modes = arena_convert_range(modes);
        
        % Number of integrations
        expression = xpath.compile('numInt');
        nodeList = expression.evaluate(integrator_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        numInt = nodeList.item(0);
        numInt = numInt.getTextContent.toCharArray;
        numInt = str2double(numInt(:).');
        
        % Range gate
        expression = xpath.compile('rg');
        nodeList = expression.evaluate(integrator_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        rg = nodeList.item(0);
        rg = rg.getTextContent.toCharArray;
        rg = rg(:).';
        % Assumes simple range gate format "start:stop"
        [start,stop] = strtok(rg,':'); stop=stop(2:end);
        num_bins = str2double(stop) - str2double(start) + 1;
        if num_bins < configs.min_num_bins
          configs.min_num_bins = num_bins;
        end
        if num_bins > configs.max_num_bins
          configs.max_num_bins = num_bins;
        end
        
        % Get the number of shifts
        expression = xpath.compile('outputSelect');
        nodeList = expression.evaluate(integrator_cfg,XPathConstants.NODESET);
        if nodeList.getLength < 1 || isempty(nodeList.item(0))
          continue;
        end
        outputSelect = nodeList.item(0);
        outputSelect = outputSelect.getTextContent.toCharArray;
        outputSelect = str2double(outputSelect(:).');
        
        if outputSelect == 0
          % 32 bit IQ with no bit shifts
          shiftLSB = 0;
        elseif outputSelect == 1
          % 16 bit IQ with bit shifts
          % Get the number of shifts
          expression = xpath.compile('shiftLSB');
          nodeList = expression.evaluate(integrator_cfg,XPathConstants.NODESET);
          if nodeList.getLength < 1 || isempty(nodeList.item(0))
            continue;
          end
          shiftLSB = nodeList.item(0);
          shiftLSB = shiftLSB.getTextContent.toCharArray;
          shiftLSB = str2double(shiftLSB(:).');
        end
        
        % Update adc configs for this integrator's modes and subchannel
        for mode_idx = 1:length(modes)
          mode_latch = modes(mode_idx);
          
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.presums = numInt;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.num_sam = num_bins;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.rg = rg;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.outputSelect = outputSelect;
          configs.adc{adc_idx,mode_latch+1,subchannel+1}.shiftLSB = shiftLSB;
        end
        
      end
    end
    
  else
    error('ADC type %s not supported.', config_type);
  end
end


%% CTU DIGITAL IO
% =========================================================================
% Get all the CTUs
if strcmpi(configs.radar_name,'extsyncarena5xx')
  % SYSTEM XML:
  % <subSystem type="arena5xxrf">
  %   <name>ARENA5xxRF</name>
  %
  % CONFIG XML:
  %  <subSystem>
  %    <name>ARENA5xxRF</name>
  %    <subSystem>
  %      <name>dac</name>
  %      <config type="rfsoc_ctu_4001">ctu1</config>
  %
  % <configs>
  % <config type="rfsoc_ctu_4001">
  %   <name>ctu1</name>

  % Get the arena 522 subsystems
  expression = xpath.compile('//subSystem[starts-with(@type,"arena5xxrf")]');
  arena522_list = expression.evaluate(doc,XPathConstants.NODESET);

  found_ctu = false;
  for arena522_idx = 1:arena522_list.getLength
    arena522_syscfg = arena522_list.item(arena522_idx-1);
    if isempty(arena522_syscfg)
      continue;
    end
    
    % Get the arena 522 subsystem name
    expression = xpath.compile('name');
    nodeList = expression.evaluate(arena522_syscfg,XPathConstants.NODESET);
    arena522_name = nodeList.item(0);
    arena522_name = arena522_name.getTextContent.toCharArray;
    arena522_name = arena522_name(:).';
    
    % Find the configuration for this arena 522
    expression = xpath.compile(sprintf('//subSystem[name="%s"]', arena522_name));
    arena522_cfg = expression.evaluate(doc_cfg,XPathConstants.NODESET);
    arena522_cfg = arena522_cfg.item(0);

    % Get the Arena 522 CTU config name
    config_type = 'rfsoc_ctu_4001';
    expression = xpath.compile(sprintf('//subSystem/config[@type="%s"]', config_type));
    config_name = expression.evaluate(arena522_cfg,XPathConstants.NODESET);
    config_name = config_name.item(0).getTextContent;
    
    % Get the Arena 522 CTU configs
    expression = xpath.compile(sprintf('//configs/config[@type="%s" and name="%s"]',config_type,config_name));
    ctu_cfg = expression.evaluate(doc_cfg,XPathConstants.NODESET);
    if ~isempty(ctu_cfg)
      ctu_cfg = ctu_cfg.item(0);
      found_ctu = true;
      break;
    end
  end
  if ~found_ctu || ctu_cfg.getLength == 0
    error('Did not find CTU configuration.');
  end
  
else
  if strcmpi(configs.radar_name,'ku0002')
    expression = xpath.compile('//subSystem[starts-with(@type,"dac-ad9129_0032")]');
  else
    expression = xpath.compile('//subSystem[starts-with(@type,"ctu")]');
  end
  ctuList = expression.evaluate(doc,XPathConstants.NODESET);
  
  % 1. Get the name of the CTU
  expression = xpath.compile('name');
  nodeList = expression.evaluate(ctuList.item(0),XPathConstants.NODESET);
  name = nodeList.item(0).getTextContent.toCharArray;
  name = name(:).';
  
  % 2. Search for the subSystem in the config XML
  expression = xpath.compile(sprintf('//subSystem/subSystem[name="%s"]',name));
  nodeList = expression.evaluate(doc_cfg,XPathConstants.NODESET);
  match = nodeList.item(0);
  
  % 3. Get the config name and type for this CTU
  expression = xpath.compile('config/@type');
  nodeList = expression.evaluate(match,XPathConstants.NODESET);
  config_type = nodeList.item(0).getTextContent.toCharArray;
  config_type = config_type(:).';
  expression = xpath.compile('config');
  nodeList = expression.evaluate(match,XPathConstants.NODESET);
  config_name = nodeList.item(0).getTextContent.toCharArray;
  config_name = config_name(:).';
  
  configs.ctu.name = name;
  configs.ctu.config_type = config_type;
  configs.ctu.config_name = config_name;
  configs.ctu.io = {};
  
  % Get the config associated with this CTU
  expression = xpath.compile(sprintf('//configs/config[(@type="%s" and name="%s")]',config_type,config_name));
  nodeList = expression.evaluate(doc_cfg,XPathConstants.NODESET);
  ctu_cfg = nodeList.item(0);
end

% strcmpi(config_type,'rfsoc_ctu_4001'): Arena 522
% strcmpi(config_type,'ctu_0013'): TOHFSounder
% strcmpi(config_type,'ctu_001D'): Many systems

% Get each subchannel
expression = xpath.compile('mode');
mode_nodeList = expression.evaluate(ctu_cfg,XPathConstants.NODESET);
for mode_idx = 1:mode_nodeList.getLength
  mode_cfg = mode_nodeList.item(mode_idx-1);
  if isempty(mode_cfg)
    continue;
  end
  
  expression = xpath.compile('id');
  nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
  if nodeList.getLength < 1 || isempty(nodeList.item(0))
    continue;
  end
  modes = nodeList.item(0);
  modes = modes.getTextContent.toCharArray;
  modes = arena_convert_range(modes);
  
  expression = xpath.compile('segmentTimes');
  nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
  if nodeList.getLength < 1 || isempty(nodeList.item(0))
    continue;
  end
  segmentTimes = nodeList.item(0);
  segmentTimes = segmentTimes.getTextContent.toCharArray;
  segmentTimes = segmentTimes(:).';
  for mode_latch = modes
    configs.ctu.io{mode_latch+1}.segmentTimes = segmentTimes;
  end
  expression = xpath.compile('segmentStates');
  nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
  if nodeList.getLength < 1 || isempty(nodeList.item(0))
    continue;
  end
  segmentStates = nodeList.item(0);
  segmentStates = segmentStates.getTextContent.toCharArray;
  segmentStates = segmentStates(:).';
  for mode_latch = modes
    configs.ctu.io{mode_latch+1}.segmentStates = segmentStates;
  end
end

%% DACS/AWG
% =========================================================================
expression = xpath.compile('//subSystem[contains(@type,"dac")]');
dacList = expression.evaluate(doc,XPathConstants.NODESET);

for dac_idx = 1:dacList.getLength
  
  % 1. Get the name of the DAC
  expression = xpath.compile('name');
  nodeList = expression.evaluate(dacList.item(dac_idx-1),XPathConstants.NODESET);
  name = nodeList.item(0).getTextContent.toCharArray;
  name = name(:).';
  if isempty(dac_map)
    tx_idx = dac_idx;
  else
    tx_idx = strmatch(name,dac_map);
  end
  if isempty(tx_idx)
    continue;
  end
  
  % 2. Search for the subSystem in the config XML
  expression = xpath.compile(sprintf('//subSystem/subSystem[name="%s"]',name));
  nodeList = expression.evaluate(doc_cfg,XPathConstants.NODESET);
  match = nodeList.item(0);
  if isempty(match)
    warning('DAC %s has no config assigned. Skipping.', name);
    continue;
  end
  
  % 3. Get the config name and type for this DAC
  expression = xpath.compile('config/@type');
  nodeList = expression.evaluate(match,XPathConstants.NODESET);
  config_type = nodeList.item(0).getTextContent.toCharArray;
  config_type = config_type(:).';
  expression = xpath.compile('config');
  nodeList = expression.evaluate(match,XPathConstants.NODESET);
  config_name = nodeList.item(0).getTextContent.toCharArray;
  config_name = config_name(:).';
  
  % Get the config associated with this DAC
  expression = xpath.compile(sprintf('//configs/config[(@type="%s" and name="%s")]',config_type,config_name));
  nodeList = expression.evaluate(doc_cfg,XPathConstants.NODESET);
  dac_cfg = nodeList.item(0);
  
  % Find the longest possible record size
  if strcmpi(config_type,'dac-ad9129_0012') || strcmpi(config_type,'dac-ad9129_0032')
    % TOHFSounder, EAGER, MELT, Vanilla, AWI MCoRDS
    
    % Get each subchannel
    expression = xpath.compile('mode');
    mode_nodeList = expression.evaluate(dac_cfg,XPathConstants.NODESET);
    for mode_idx = 1:mode_nodeList.getLength
      mode_cfg = mode_nodeList.item(mode_idx-1);
      if isempty(mode_cfg)
        continue;
      end
      
      expression = xpath.compile('id');
      nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      mode_latch = nodeList.item(0);
      mode_latch = mode_latch.getTextContent.toCharArray;
      mode_latch = arena_convert_range(mode_latch);
      
      expression = xpath.compile('delay');
      nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      delay = nodeList.item(0);
      delay = delay.getTextContent.toCharArray;
      delay = str2double(delay(:).') * 1e-6;
      configs.dac{mode_latch+1}.delay = delay;
      
      % 3. Get the config name and type for this DAC waveform
      expression = xpath.compile('config/@type');
      nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
      config_type = nodeList.item(0).getTextContent.toCharArray;
      config_type = config_type(:).';
      expression = xpath.compile('config');
      nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
      config_name = nodeList.item(0).getTextContent.toCharArray;
      config_name = config_name(:).';
      
      % Get the config associated with this DAC waveform
      expression = xpath.compile(sprintf('//configs/config[(@type="%s" and name="%s")]',config_type,config_name));
      nodeList = expression.evaluate(doc_cfg,XPathConstants.NODESET);
      dac_wf_cfg = nodeList.item(0);
      
      % Read DAC waveform parameters
      if strcmpi(config_type,'dac-ad9129_0012_waveform') || strcmpi(config_type,'dac-ad9129_0032_waveform')
        % TOHFSounder
        
        expression = xpath.compile('name');
        nodeList = expression.evaluate(dac_wf_cfg,XPathConstants.NODESET);
        name = nodeList.item(0);
        name = name.getTextContent.toCharArray;
        name = name(:).';
        configs.dac{tx_idx,mode_latch+1}.wfs{1}.name = name;
        
        expression = xpath.compile('sampFreq');
        nodeList = expression.evaluate(dac_wf_cfg,XPathConstants.NODESET);
        sampFreq = nodeList.item(0);
        sampFreq = sampFreq.getTextContent.toCharArray;
        sampFreq = str2double(sampFreq(:).') * 1e6;
        configs.dac{tx_idx,mode_latch+1}.wfs{1}.sampFreq = sampFreq;
        
        % Get each subchannel
        expression = xpath.compile('pulse');
        pulse_nodeList = expression.evaluate(dac_wf_cfg,XPathConstants.NODESET);
        for pulse_idx = 1:pulse_nodeList.getLength
          pulse_cfg = pulse_nodeList.item(pulse_idx-1);
          if isempty(pulse_cfg)
            continue;
          end
          
          expression = xpath.compile('name');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          name = nodeList.item(0);
          name = name.getTextContent.toCharArray;
          name = name(:).';
          configs.dac{tx_idx,mode_latch+1}.wfs{1}.pulse{pulse_idx}.name = name;
          
          expression = xpath.compile('centerFreq');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          centerFreq = nodeList.item(0);
          centerFreq = centerFreq.getTextContent.toCharArray;
          centerFreq = str2double(centerFreq(:).') * 1e6;
          configs.dac{tx_idx,mode_latch+1}.wfs{1}.pulse{pulse_idx}.centerFreq = centerFreq;
          
          expression = xpath.compile('bandwidth');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          bandwidth = nodeList.item(0);
          bandwidth = bandwidth.getTextContent.toCharArray;
          bandwidth = str2double(bandwidth(:).') * 1e6;
          configs.dac{tx_idx,mode_latch+1}.wfs{1}.pulse{pulse_idx}.bandwidth = bandwidth;
          
          expression = xpath.compile('initialDelay');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          initialDelay = nodeList.item(0);
          initialDelay = initialDelay.getTextContent.toCharArray;
          initialDelay = str2double(initialDelay(:).') * 1e-6;
          configs.dac{tx_idx,mode_latch+1}.wfs{1}.pulse{pulse_idx}.initialDelay = initialDelay;
          
          expression = xpath.compile('initialPhase');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          initialPhase = nodeList.item(0);
          initialPhase = initialPhase.getTextContent.toCharArray;
          initialPhase = str2double(initialPhase(:).');
          configs.dac{tx_idx,mode_latch+1}.wfs{1}.pulse{pulse_idx}.initialPhase = initialPhase;
          
          expression = xpath.compile('afterPulseDelay');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          afterPulseDelay = nodeList.item(0);
          afterPulseDelay = afterPulseDelay.getTextContent.toCharArray;
          afterPulseDelay = str2double(afterPulseDelay(:).') * 1e-6;
          configs.dac{tx_idx,mode_latch+1}.wfs{1}.pulse{pulse_idx}.afterPulseDelay = afterPulseDelay;
          
          expression = xpath.compile('taper');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          taper = nodeList.item(0);
          taper = taper.getTextContent.toCharArray;
          taper = taper(:).';
          configs.dac{tx_idx,mode_latch+1}.wfs{1}.pulse{pulse_idx}.taper = taper;
          
          expression = xpath.compile('alpha');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          alpha = nodeList.item(0);
          alpha = alpha.getTextContent.toCharArray;
          alpha = str2double(alpha(:).');
          configs.dac{tx_idx,mode_latch+1}.wfs{1}.pulse{pulse_idx}.alpha = alpha;
          
          expression = xpath.compile('scale');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          scale = nodeList.item(0);
          scale = scale.getTextContent.toCharArray;
          scale = str2double(scale(:).');
          configs.dac{tx_idx,mode_latch+1}.wfs{1}.pulse{pulse_idx}.scale = scale;
          
          expression = xpath.compile('numPoints');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          numPoints = nodeList.item(0);
          numPoints = numPoints.getTextContent.toCharArray;
          numPoints = str2double(numPoints(:).');
          configs.dac{tx_idx,mode_latch+1}.wfs{1}.pulse{pulse_idx}.numPoints = numPoints;
        end
      end
      
      
    end

  elseif strcmpi(config_type,'dac-ad9783_002C')
    % GHOST
    
    % Get each subchannel
    expression = xpath.compile('mode');
    mode_nodeList = expression.evaluate(dac_cfg,XPathConstants.NODESET);
    for mode_idx = 1:mode_nodeList.getLength
      mode_cfg = mode_nodeList.item(mode_idx-1);
      if isempty(mode_cfg)
        continue;
      end
      
      expression = xpath.compile('id');
      nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      mode_latch = nodeList.item(0);
      mode_latch = mode_latch.getTextContent.toCharArray;
      mode_latch = arena_convert_range(mode_latch);
      
      expression = xpath.compile('delay');
      nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
      if nodeList.getLength < 1 || isempty(nodeList.item(0))
        continue;
      end
      delay = nodeList.item(0);
      delay = delay.getTextContent.toCharArray;
      delay = str2double(delay(:).');
      configs.dac{mode_latch+1}.delay = delay;
      
      % 3. Get the config name and type for this DAC waveform
      expression = xpath.compile('config/@type');
      nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
      config_type = nodeList.item(0).getTextContent.toCharArray;
      config_type = config_type(:).';
      
      % Get each of the four DAC channel waveforms
      expression = xpath.compile('config');
      wf_nodeList = expression.evaluate(mode_cfg,XPathConstants.NODESET);
      for wf_idx = 1:wf_nodeList.getLength
        wf_cfg = wf_nodeList.item(wf_idx-1);
        if isempty(wf_cfg)
          continue;
        end
      
        config_name = wf_cfg.item(0).getTextContent.toCharArray;
        config_name = config_name(:).';
      
        % Get the config associated with this DAC waveform
        expression = xpath.compile(sprintf('//configs/config[(@type="%s" and name="%s")]',config_type,config_name));
        nodeList = expression.evaluate(doc_cfg,XPathConstants.NODESET);
        dac_wf_cfg = nodeList.item(0);
        
        expression = xpath.compile('name');
        nodeList = expression.evaluate(dac_wf_cfg,XPathConstants.NODESET);
        name = nodeList.item(0);
        name = name.getTextContent.toCharArray;
        name = name(:).';
        configs.dac{tx_idx,mode_latch+1}.wfs{wf_idx}.name = name;
        
        expression = xpath.compile('sampFreq');
        nodeList = expression.evaluate(dac_wf_cfg,XPathConstants.NODESET);
        sampFreq = nodeList.item(0);
        sampFreq = sampFreq.getTextContent.toCharArray;
        sampFreq = str2double(sampFreq(:).') * 1e6;
        configs.dac{tx_idx,mode_latch+1}.wfs{wf_idx}.sampFreq = sampFreq;
        
        % Get each pulse
        expression = xpath.compile('pulse');
        pulse_nodeList = expression.evaluate(dac_wf_cfg,XPathConstants.NODESET);
        for pulse_idx = 1:pulse_nodeList.getLength
          pulse_cfg = pulse_nodeList.item(pulse_idx-1);
          if isempty(pulse_cfg)
            continue;
          end
          
          expression = xpath.compile('name');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          name = nodeList.item(0);
          name = name.getTextContent.toCharArray;
          name = name(:).';
          configs.dac{tx_idx,mode_latch+1}.wfs{wf_idx}.pulse{pulse_idx}.name = name;
          
          expression = xpath.compile('centerFreq');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          centerFreq = nodeList.item(0);
          centerFreq = centerFreq.getTextContent.toCharArray;
          centerFreq = str2double(centerFreq(:).') * 1e6;
          configs.dac{tx_idx,mode_latch+1}.wfs{wf_idx}.pulse{pulse_idx}.centerFreq = centerFreq;
          
          expression = xpath.compile('bandwidth');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          bandwidth = nodeList.item(0);
          bandwidth = bandwidth.getTextContent.toCharArray;
          bandwidth = str2double(bandwidth(:).') * 1e6;
          configs.dac{tx_idx,mode_latch+1}.wfs{wf_idx}.pulse{pulse_idx}.bandwidth = bandwidth;
          
          configs.dac{tx_idx,mode_latch+1}.wfs{wf_idx}.pulse{pulse_idx}.initialDelay = 0;
          
          expression = xpath.compile('initialPhase');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          initialPhase = nodeList.item(0);
          initialPhase = initialPhase.getTextContent.toCharArray;
          initialPhase = str2double(initialPhase(:).');
          configs.dac{tx_idx,mode_latch+1}.wfs{wf_idx}.pulse{pulse_idx}.initialPhase = initialPhase;
          
          expression = xpath.compile('afterPulseDelay');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          afterPulseDelay = nodeList.item(0);
          afterPulseDelay = afterPulseDelay.getTextContent.toCharArray;
          afterPulseDelay = str2double(afterPulseDelay(:).');
          configs.dac{tx_idx,mode_latch+1}.wfs{wf_idx}.pulse{pulse_idx}.afterPulseDelay = afterPulseDelay;
          
          expression = xpath.compile('taper');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          taper = nodeList.item(0);
          taper = taper.getTextContent.toCharArray;
          taper = taper(:).';
          configs.dac{tx_idx,mode_latch+1}.wfs{wf_idx}.pulse{pulse_idx}.taper = taper;
          
          expression = xpath.compile('alpha');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          alpha = nodeList.item(0);
          alpha = alpha.getTextContent.toCharArray;
          alpha = str2double(alpha(:).');
          configs.dac{tx_idx,mode_latch+1}.wfs{wf_idx}.pulse{pulse_idx}.alpha = alpha;
          
          expression = xpath.compile('scale');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          scale = nodeList.item(0);
          scale = scale.getTextContent.toCharArray;
          scale = str2double(scale(:).');
          configs.dac{tx_idx,mode_latch+1}.wfs{wf_idx}.pulse{pulse_idx}.scale = scale;
          
          expression = xpath.compile('numPoints');
          nodeList = expression.evaluate(pulse_cfg,XPathConstants.NODESET);
          numPoints = nodeList.item(0);
          numPoints = numPoints.getTextContent.toCharArray;
          numPoints = str2double(numPoints(:).');
          configs.dac{tx_idx,mode_latch+1}.wfs{wf_idx}.pulse{pulse_idx}.numPoints = numPoints;
        end
      end
    end    
    
  elseif strcmpi(config_type,'rfsoc_dac_1002')
    % =====================================================================
    % Arena 522 COLDEX
    % =====================================================================

    % <config type="rfsoc_dac_1002">
    %    <name>awg0</name>
    %    <description></description>
    %    <sampFreq>8960.000000</sampFreq>
    %    <waveformSetting>
    %       <name>10us</name>
    %       <channels>0</channels>
    %       <modes>0</modes>
    %       <invert>0</invert>
    %       <delay>2.000000</delay>
    %       <waveform>waveform1us ch4</waveform>
    % 
    %    <waveform>
    %       <name>waveform1us ch1</name>
    %       <pulse>
    %          <name>Pulse</name>
    %          <centerFreq>700.000000</centerFreq>
    %          <bandwidth>50.000000</bandwidth>
    %          <initialDelay>0.000000</initialDelay>
    %          <initialPhase>0.000000</initialPhase>
    %          <taper>Tukey</taper>
    %          <alpha>0.100000</alpha>
    %          <scale>1.000000</scale>
    %          <numPoints>8960</numPoints>
    %       </pulse>
    expression = xpath.compile('sampFreq');
    sampFreq = expression.evaluate(dac_cfg,XPathConstants.NODESET);
    sampFreq = sampFreq.item(0);
    sampFreq = sampFreq.getTextContent.toCharArray;
    sampFreq = str2double(sampFreq(:).')*1e6;
    
    expression = xpath.compile('waveformSetting');
    wf_setting_list = expression.evaluate(dac_cfg,XPathConstants.NODESET);
    for wf_idx = 1:wf_setting_list.getLength
      wf_setting = wf_setting_list.item(wf_idx-1);
      if isempty(wf_setting)
        continue;
      end
      
      expression = xpath.compile('name');
      name = expression.evaluate(wf_setting,XPathConstants.NODESET);
      name = name.item(0);
      name = name.getTextContent.toCharArray;
      name = name(:).';
      
      expression = xpath.compile('channels');
      channels = expression.evaluate(wf_setting,XPathConstants.NODESET);
      channels = channels.item(0);
      channels = channels.getTextContent.toCharArray;
      channels = arena_convert_range(channels(:).');
      
      expression = xpath.compile('modes');
      modes = expression.evaluate(wf_setting,XPathConstants.NODESET);
      modes = modes.item(0);
      modes = modes.getTextContent.toCharArray;
      modes = arena_convert_range(modes(:).');
      
      expression = xpath.compile('invert');
      invert = expression.evaluate(wf_setting,XPathConstants.NODESET);
      invert = invert.item(0);
      invert = invert.getTextContent.toCharArray;
      invert = str2double(invert(:).');
      
      expression = xpath.compile('delay');
      delay = expression.evaluate(wf_setting,XPathConstants.NODESET);
      delay = delay.item(0);
      delay = delay.getTextContent.toCharArray;
      delay = str2double(delay(:).');
      
      expression = xpath.compile('waveform');
      waveform_name = expression.evaluate(wf_setting,XPathConstants.NODESET);
      waveform_name = waveform_name.item(0);
      waveform_name = waveform_name.getTextContent.toCharArray;
      waveform_name = waveform_name(:).';
      
      expression = xpath.compile(sprintf('waveform[name="%s"]', waveform_name));
      wf_cfg = expression.evaluate(dac_cfg,XPathConstants.NODESET);
      expression = xpath.compile('pulse');
      wf_cfg = expression.evaluate(wf_cfg.item(0),XPathConstants.NODESET);
      wf_cfg = wf_cfg.item(0);
      
      expression = xpath.compile('centerFreq');
      centerFreq = expression.evaluate(wf_cfg,XPathConstants.NODESET);
      centerFreq = centerFreq.item(0);
      centerFreq = centerFreq.getTextContent.toCharArray;
      centerFreq = str2double(centerFreq(:).') * 1e6;
      
      expression = xpath.compile('bandwidth');
      bandwidth = expression.evaluate(wf_cfg,XPathConstants.NODESET);
      bandwidth = bandwidth.item(0);
      bandwidth = bandwidth.getTextContent.toCharArray;
      bandwidth = str2double(bandwidth(:).') * 1e6;
      
      expression = xpath.compile('initialDelay');
      initialDelay = expression.evaluate(wf_cfg,XPathConstants.NODESET);
      initialDelay = initialDelay.item(0);
      initialDelay = initialDelay.getTextContent.toCharArray;
      initialDelay = str2double(initialDelay(:).');
      
      expression = xpath.compile('initialPhase');
      initialPhase = expression.evaluate(wf_cfg,XPathConstants.NODESET);
      initialPhase = initialPhase.item(0);
      initialPhase = initialPhase.getTextContent.toCharArray;
      initialPhase = str2double(initialPhase(:).');
      
      expression = xpath.compile('taper');
      taper = expression.evaluate(wf_cfg,XPathConstants.NODESET);
      taper = taper.item(0);
      taper = taper.getTextContent.toCharArray;
      taper = taper(:).';
      
      expression = xpath.compile('alpha');
      alpha = expression.evaluate(wf_cfg,XPathConstants.NODESET);
      alpha = alpha.item(0);
      alpha = alpha.getTextContent.toCharArray;
      alpha = str2double(alpha(:).');
      
      expression = xpath.compile('scale');
      scale = expression.evaluate(wf_cfg,XPathConstants.NODESET);
      scale = scale.item(0);
      scale = scale.getTextContent.toCharArray;
      scale = str2double(scale(:).');
      
      expression = xpath.compile('numPoints');
      numPoints = expression.evaluate(wf_cfg,XPathConstants.NODESET);
      numPoints = numPoints.item(0);
      numPoints = numPoints.getTextContent.toCharArray;
      numPoints = str2double(numPoints(:).');
      
      % Set modes
        pulse_idx = 1;
        for mode_latch = modes(:).'
          configs.dac{tx_idx,mode_latch+1}.delay = delay;
          for channel = channels(:).'
            configs.dac{tx_idx,mode_latch+1}.wfs{channel+1}.sampFreq = sampFreq;
            configs.dac{tx_idx,mode_latch+1}.wfs{channel+1}.pulse{pulse_idx}.name = name;
            configs.dac{tx_idx,mode_latch+1}.wfs{channel+1}.pulse{pulse_idx}.centerFreq = centerFreq;
            configs.dac{tx_idx,mode_latch+1}.wfs{channel+1}.pulse{pulse_idx}.bandwidth = bandwidth;
            configs.dac{tx_idx,mode_latch+1}.wfs{channel+1}.pulse{pulse_idx}.initialDelay = initialDelay;
            configs.dac{tx_idx,mode_latch+1}.wfs{channel+1}.pulse{pulse_idx}.initialPhase = initialPhase;
            configs.dac{tx_idx,mode_latch+1}.wfs{channel+1}.pulse{pulse_idx}.afterPulseDelay = 0;
            configs.dac{tx_idx,mode_latch+1}.wfs{channel+1}.pulse{pulse_idx}.taper = taper;
            configs.dac{tx_idx,mode_latch+1}.wfs{channel+1}.pulse{pulse_idx}.alpha = alpha;
            configs.dac{tx_idx,mode_latch+1}.wfs{channel+1}.pulse{pulse_idx}.scale = scale;
            configs.dac{tx_idx,mode_latch+1}.wfs{channel+1}.pulse{pulse_idx}.numPoints = numPoints;
          end
        end
      end
      
    end
    
  end
end
