close all; clear all;

fs = 64e9; %512 samples corresponds to 1 cycle at 125MHz
tau = 240e-6;
max_del = 10e-6;
taper_ratio=0.85; %changed from 1.25 to 0.8 on 20181027
if 1
  f0 = 2e9;
  bw = 16e9;
  fn = 'fmcw_1ch_64GSPS_2to18GHz_240us_4khz_taper0.85.csv';
elseif 0
  f0 = 2e9;
  bw = 6e9;
  fn = 'fmcw_1ch_64GSPS_2to8GHz_240us_4khz_taper0.85.csv';
else
  f0 = 12e9;
  bw = 6e9;
  fn = 'fmcw_1ch_64GSPS_12to18GHz_240us_4khz_taper0.85.csv';
end
tukey_alpha = 0.005;

dt = 1/fs;
nt_tau = round(tau/dt);
nt = round((tau+max_del)/dt);
tt = (0:dt:(nt-1)*dt)';
k = bw/tau;

chirp1 = [tukeywin(nt_tau,tukey_alpha);zeros(nt-nt_tau,1)].*sin(2*pi*(f0*tt + 0.5*k*(tt.*tt)));
FreqWeight = 1 + [0.0 : [taper_ratio/nt_tau] : taper_ratio];
taper=[FreqWeight(1:nt_tau)';zeros(nt-nt_tau,1)];
chirp1=(taper.*chirp1)/max((taper.*chirp1));
% figure(1);
% plot(chirp1);

m_clk = zeros(nt,1);

% wave_id is used to uniquely identify the current waveform
% "OIB_FMCW": means zero delay between reference LO and transmit
% "     013": means reference LO is 13 us later than transmit
% It is written to the header of the data file every epri through marker 2
% Each bit is written out at 125 MHz divided by 8
% Clock for this UART bit stream is the 3rd bit (number 2) of the 125 MHz counter
% 64e9/4096 is 125e6/8
% The lowest bit of the lowest byte is written first. For example "W" is
% written first when the data stream is "OIB_FMCW".
m_clk = zeros(nt,1);
wave_id = swapbytes(typecast(uint8('OIB_FMCW'),'uint64'));
for idx = 0:63
  if bitand(uint64(1), bitshift(wave_id,-idx))
    m_clk(4096 + 4096*idx + (0:4095)) = 1;
  end
end

data = zeros(nt,4);
data(:,1) = chirp1;

%marker 1 is used as the pri trigger which is sent from the AWG to the DAQ
%the location of the pri trigger can be adjusted to account for setup/hold
%instabilities due to cable lengths
%64e9/4096 is 125/8
data(0+(4097:8192),3) = ones(4096,1); %PRI Trigger
data(:,4) = m_clk(1:nt);

% Correct rounding errors that cause data points to fall outside the valid
% +/-1 range.
data(data<-1,1) = -1;
data(data>1,1) = 1;

% Write the file
fprintf('Writing %s (%s)\n', fn, datestr(now));
fid1 = fopen(fn,'w');
fprintf(fid1,'SampleRate=64000000000\r\n');
fprintf(fid1,'SetConfig=true\r\n');
fprintf(fid1,'Y1,Y2,SampleMarker1,SampleMarker2\r\n');
fprintf(fid1,'%12.10f,%12.10f,%i,%i\r\n',data');
fclose(fid1);
