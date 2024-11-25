function [hdr, data] = NAread(ports,param)
% [hdr, data] = NAread(ports,param)
%
% Records network analyzer (NA) measurements.
%
% YOU MUST INSTALL DRIVERS that support NI-VISA.
% This can be downloaded from NI Hardware Drivers section in Support (ni.com)
% The recent driver file used is from http://www.ni.com/download/ni-visa-14.0.1/5023/en/
% Available in scratch(cfs2.cresis.ku.edu)\htalasila\NIVISA1401full.exe
% NA programming information:
% http://na.support.keysight.com/pna/help/latest/help.htm
%
% ports: list of ports to measure (a vector of unique numbers containing
%   1, 2, 3, and/or 4). E.g. [1 3] would use ports 1 and 3.
% param: structure controlling how the measurement is taken
%  .vna: structure of fields to set in the VNA object
%    .InputBufferSize (default is 4*2^20 or 4 MB)
%    .Timeout (default is 60 seconds)
%  .conn: string containing connection method ('usb' or 'eth'). Defaults
%    to 'usb' if 'usb_addr' specified, otherwise 'eth'.
%  .ip_addr: string containing IP Address for connection method 'eth'.
%    No default. Find address by looking in NA's Windows network settings.
%  .usb_addr: string containing USB Address for connection method 'usb'.
%    No default.  Find address by looking in device manager or tmtool.
%    For example:
%      'USB0::0x0957::0x0118::MY51421306::0::INSTR'
%  .num_ave: Number of hardware averages. Default is 1. These averages
%    are done by the network analyzer itself.
%  .num_meas: Number of separate measurements to record. Default is 1.
%    This controls the dimension of data.
%  .plot_en: Plot all S-parameters that are measured. Default is true.
%  .fn: String containing filename to store data in. A date-time string is
%    automatically appended to the filename.
%
% hdr: struct containing fields about NA measurement
% data: double array of size (N,N,num_points,param.num_meas). For example:
%   data(2,1,:,1) represents first S21 measurement taken
%
% Examples:
%  [hdr, data] = NAread([2 3],struct('ip_addr','172.16.0.201'));
%  [hdr, data] = NAread([1 2],struct('usb_addr','USB0::0x0957::0x0118::MY51421306::0::INSTR'))
%  [hdr, data] = NAread([1 3 4],struct('ip_addr','172.16.0.201'));
%
% Author: Hara Talasila and John Paden
%
% See also: SXPParse, SXPWrite

%% Check user inputs

if ~isfield(param,'conn')
  if isfield(param,'usb_addr')
    param.conn = 'usb';
  else
    param.conn = 'eth';
  end
end

if ~isfield(param,'num_ave')
  param.num_ave = 1; % Default No. of Averages = 1
end

if ~isfield(param,'num_meas')
  param.num_meas = 1; % Default No. of Measurements = 1
end

if ~isfield(param,'plot_en')
  param.plot_en = true;
end

if ~isfield(param,'vna')
  param.vna = struct();
end

if ~isfield(param.vna,'InputBufferSize')
  param.vna.InputBufferSize = 4*2^20;
end

if ~isfield(param.vna,'Timeout')
  param.vna.Timeout = 60;
end

%% Decode ports mask
ports = unique(ports);
if isempty(ports) || any(ports < 1 | ports > 4)
  error('ports must contain numbers from 1 to 4');
end
ports_str = [sprintf('%d',ports(1)) sprintf(',%d',ports(2:end))];
num_ports = length(ports);

%% VNA Settings

try
  % Connected by USB A-B cable
  if strcmpi(param.conn,'usb')
    vna = visa('NI', sprintf('%s',param.usb_addr));
    %fprintf('Connecting through USB\n');
    
  elseif strcmpi(param.conn,'eth')
    vna = visa('NI', sprintf('TCPIP::%s::INSTR',param.ip_addr));
    %fprintf('Connecting through Ethernet\n');
  end
  
  vna.InputBufferSize = param.vna.InputBufferSize;
  vna.Timeout = param.vna.Timeout;
  
  %% Connect to VNA
  fopen(vna);
  %fprintf(vna,'*RST');
  
  %% Query VNA settings
  
  fprintf(vna,'*IDN?');
  hdr = [];
  hdr.ports = ports;
  hdr.param = param;
  hdr.datestr = datestr(now);
  
  hdr.idn = fscanf(vna);
  %fprintf('%s\n', hdr.idn);
  
  fprintf(vna,'SENS:BAND:RES?'); % Resolution
  hdr.resolution = str2double(fscanf(vna));
  
  fprintf(vna,'SENS:BAND:TRAC?'); %Track
  hdr.track = str2double(fscanf(vna));
  
  % Power (4-ports)
  hdr.power_dBm = NaN*zeros(1,4);
  for port = ports
    fprintf(vna,'SOURCE:POWER%d:LEVEL?', port);
    hdr.power_dBm(port) = str2double(fscanf(vna));
  end
  
  % inp=str2num(input('\nStART Frequency: ','s'));
  % fprintf(vna,sprintf('SENS:FREQ:STAR %d',inp)); % SET Start Frequency
  fprintf(vna,'SENS:FREQ:STAR?'); % READ Start Frequency
  hdr.start_freq_Hz = str2double(fscanf(vna));
  
  % inp=str2num(input('\nStop Frequency: ','s'));
  % fprintf(vna,sprintf('SENS:FREQ:STOP %d',inp)); % SET Stop Frequency
  fprintf(vna,'SENS:FREQ:STOP?'); % READ Stop Frequency
  hdr.stop_freq_Hz = str2double(fscanf(vna));
  
  % inp=str2num(input('\nPoints : ','s'));
  % fprintf(vna,sprintf('SENS:SWE:POIN %d',inp)); %SET No. of Points
  fprintf(vna,'SENS:SWE:POIN?'); %READ No. of Points
  hdr.num_points = str2double(fscanf(vna));
  
  % inp=str2num(input('\nSweep Time : ','s'));
  % fprintf(vna,sprintf('SENS:SWE:TIME %d',inp)); %SET Sweep Time in seconds
  fprintf(vna,'SENS:SWE:TIME?'); %READ Sweep Time
  hdr.sweep_time_sec = str2double(fscanf(vna));
  
  %IF Frequency
  fprintf(vna,'SENSe:BWID?');
  hdr.IF_bandwidth_Hz = str2double(fscanf(vna));
  
  % Temperature
  fprintf(vna,'SENS:TEMP? CELS'); %FAHR or CELS
  hdr.temperature_celcius = str2double(fscanf(vna));
  
  %% Data Formatting for incoming blocks
  
  fprintf(vna,'FORM:BORD SWAP');
  if 0
    %Test again. It should return SWAP
    fprintf(vna,'FORM:BORD?');
    format=fscanf(vna);
    fprintf('New Format is %s\n',format);
  end
  
  fprintf(vna,'FORM:DATA REAL,64');
  if 0
    %Test again. It should return REAL,64
    fprintf(vna,'FORM:DATA?');
    form=fscanf(vna);
    fprintf('New Form is %s\n',form);
  end
  
  %% Set Parameters to Measure
  fprintf(vna,'CALC:PAR:CAT?');
  name_cat = fscanf(vna);
  name_cat = name_cat(2:end-2);
  
  name_cat = regexp(name_cat, ',\s*', 'split');
  name_cat = name_cat(2:2:end);
  
  for rx = ports
    for tx = ports
      % Look for the parameter in the traces_names_catalog
      trace_num = find(strcmpi(sprintf('S%d%d',rx,tx), name_cat));
      if isempty(trace_num)
        % Create the measurement
        fprintf(vna,sprintf('CALC:PAR:EXT "CH1_S%d%d_1", "S%d%d"', rx, tx, rx, tx));
      end
    end
  end
  
  %% Set Parameters to Measure
  fprintf(vna,'CALC:PAR:CAT?');
  name_cat = fscanf(vna);
  name_cat = name_cat(2:end-2);
  
  name_cat = regexp(name_cat, ',\s*', 'split');
  name_cat = name_cat(2:2:end);
  
  for rx = ports(1)
    for tx = ports(1)
      % Look for the parameter in the traces_names_catalog
      trace_num = find(strcmpi(sprintf('S%d%d',rx,tx), name_cat));
    end
  end

  fprintf(vna,'CALC:PAR:MNUM %d', trace_num);
  
  %% AVERAGES Section
  
  fprintf(vna,'SENS:AVER ON'); %OFF or ON
  fprintf(vna,'SENS:AVER:MODE SWEEP'); %POINT Sets the type of averaging to perform: Point or Sweep.
  fprintf(vna,sprintf('SENS:AVER:COUN %d',param.num_ave));% Sets the number of measurements to combine for an average.
  
  %% TRIG SECTION
  
  fprintf(vna,'SENSe:SWEep:MODE HOLD');
  fprintf(vna,'ABORT');
  
  data = zeros(num_ports,num_ports,hdr.num_points,param.num_meas);
  for meas_idx = 1:param.num_meas
    
    %TRIG MODEL 1 SOURCE
    fprintf(vna,'TRIG:SOUR IMM');%Sets the source of the sweep trigger signal.
    % IMM EXT MAN
    %TRIG MODEL 2 SCOPE
    fprintf(vna,'TRIG:SCOP ALL');%Specifies whether a trigger signal is sent to all channels or only the current channel
    %Global ALL or CURRent
    %TRIG MODEL 3 Channel Settings
    fprintf(vna,sprintf('SENS:SWE:GRO:COUN %d',param.num_ave));
    %Sets the trigger count (groups) for the specified channel.
    %Set trigger mode to group after setting this count.
    fprintf(vna,'SENS:SWE:MODE GRO;*OPC?'); %HOLD CONT GRO SINGLE
    %channel accepts the number of triggers specified with the last SENS:SWE:GRO:COUN <num>.
    %% Wait till Sweep Completes
    flush=NaN;
    while isnan(flush)
      %fprintf('Sweeping...\n');
      pause(0.2);
      flush=str2double(fscanf(vna));
    end
    
    %% Main cmd to get entire S2P DATA (all ports[1,2])
    fprintf(vna,'MMEM:STOR:TRAC:FORM:SNP RI');
    fprintf(vna,sprintf('CALC:DATA:SNP:PORT? "%s"', ports_str));
    
    % for data format see: http://na.support.keysight.com/pna/help/latest/help.htm
    % A hash folowed by a number(indicating no.of digits) followed by digits
    % specified and then the data: freq, S_dB, Phase, S_dB, Phase,....
    hash = char(fread(vna,1,'char'));
    
    num_digits = fread(vna,1,'char') - '0';
    
    num_sam = (str2double(char(fread(vna,num_digits,'char'))))/8;
    
    rawdata = fread(vna,num_sam,'double');
    
    num_dims = (1+2*num_ports^2);
    rawdata = reshape(rawdata,[num_sam/num_dims num_dims]);
    hdr.freq = rawdata(:,1);
    S_param = NaN*zeros(num_ports,num_ports,length(hdr.freq));
    for rx_idx = 1:length(ports)
      for tx_idx = 1:length(ports)
        rx = ports(rx_idx);
        tx = ports(tx_idx);
        data_idx = 2+2*((tx_idx-1)*num_ports+(rx_idx-1));
        S_param(rx_idx,tx_idx,:) = rawdata(:,data_idx) + 1i*rawdata(:,data_idx+1);
        if param.plot_en
          h_fig = figure(tx + (rx-1)*max(ports)); clf;
          set(h_fig,'WindowStyle','docked');
          plot(hdr.freq/1e6, 20*log10(abs(squeeze(S_param(rx_idx,tx_idx,:)))));
          xlabel('Frequency in GHz');
          ylabel(sprintf('S_%d_%d',rx,tx));
          grid on;
          drawnow;
        end
      end
    end
    
    % Read the "\n" or 10 character that terminates the data transmission
    flush = char(fread(vna,1,'char'));
    
    data(:,:,:,meas_idx) = S_param;
  end
  
  %% VNA Disconnect
  fclose(vna);
    
catch ME
  ME
  keyboard
  fclose(vna);
  rethrow(ME);
end

if isfield(param,'fn')
  fn = param.fn;
  [fn_dir,fn_name] = fileparts(fn);
  if ~exist(fn_dir,'dir')
    mkdir(fn_dir);
  end
  fn_name = [fn_name sprintf('_%s.mat',datestr(now,'YYYYmmDD_HHMMSS'))];
  fn = fullfile(fn_dir,fn_name);
  save(fn,'hdr','data');
end

end