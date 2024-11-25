close all; clear all;

fif = 100e6; % Frequency offset of the local oscillator chirp (cannot be zero since IF NZ 0 cuts off before DC)
fs = 32e9; % NOTE: 256 samples equals one sample at 125MHz (the clock rate of the NI box)
taper_ratio=0.85; %changed from 1.25 to 0.8 on 20181027
f0 = 2e9;
bw = 6e9;
tukey_alpha = 0.005;
if_bw = 125e6;
tau = 240e-6; %pulse length
max_del = 10e-6; %dead time,  PRI = tau+max_del
c = 2.997924580003452e+08;
fn = 'fmcw_2ch_32GSPS_3GHz_240us_4khz_%.0fus_100MHz_no_zero_pi.csv';

dt = 1/fs;
k = bw/tau;

if 0
  % Debug code
  height_agl = 18000*2.54*12/100
  td = height_agl / (c/2)
  unambiguous_time_gate = 2*if_bw / k
end

for del = [0e-6]; %delay of the local oscillator chirp for recieve mixing
  nt_tau = round(tau/dt);
  nt_del = round(del/dt);
  nt = round((tau+max_del)/dt);
  tt = (0:dt:(nt-1)*dt)';
  
  chirp1 = [tukeywin(nt_tau,tukey_alpha);zeros(nt-nt_tau,1)].*sin(2*pi*(f0*tt + 0.5*k*(tt.*tt)));
  chirp2 = [zeros(nt_del,1);tukeywin(nt_tau,tukey_alpha);zeros(nt-nt_tau-nt_del,1)].*sin(2*pi*((f0+fif)*(tt-del) + 0.5*k*((tt-del).*(tt-del))));
  FreqWeight = 1 + [0.0 : [taper_ratio/nt_tau] : taper_ratio];
  taper=[FreqWeight(1:nt_tau)';zeros(nt-nt_tau,1)];
  chirp1=(taper.*chirp1)/max((taper.*chirp1));
  chirp2=(taper.*chirp2)/max((taper.*chirp2));
  % figure(1);
  % plot(chirp1);
  
  % wave_id is used to uniquely identify the current waveform
  % "OIB_FMCW": means zero delay between reference LO and transmit
  % "     013": means reference LO is 13 us later than transmit
  % It is written to the header of the data file every epri through marker 2
  % Each bit is written out at 125 MHz divided by 8
  % Clock for this UART bit stream is the 3rd bit (number 2) of the 125 MHz counter
  % 64e9/4096 is 125e6/8
  % The lowest bit of the lowest byte is written first. For example "W" is
  % written first when the data stream is "OIB_FMCW".
  
  % Delay encoded as 3 character zero-padded number represent microseconds
  del_str = sprintf('%03.0f',del*1e7)
  m_clk = zeros(4*nt,1);
  % Space padded
  wave_id = swapbytes(typecast(uint8(['     ' del_str]),'uint64'));
  for idx = 0:63
    if bitand(uint64(1), bitshift(wave_id,-idx))
      m_clk(4096 + 2048*idx + (0:2047)) = 1;
    end
  end
  
  data = zeros(4*nt,4); %data consists of 4-PRIs with [RF,LO,Trigger,wave_id]
  if 0
    % Disable zero-pi mod
    data(:,1) = [ chirp1; chirp1; chirp1; chirp1];
    data(:,2) = [ chirp2; chirp2; chirp2; chirp2];
  else
    % Enable zero-pi mod
    data(:,1) = [ chirp1; -chirp1; chirp1; -chirp1];
    data(:,2) = [ chirp2; -chirp2; chirp2; -chirp2];
  end
  
  data(0*nt+4+(4097:8192),3) = ones(4096,1); %PRI Trigger
  data(1*nt+4+(4097:8192),3) = ones(4096,1); %PRI Trigger
  data(2*nt+4+(4097:8192),3) = ones(4096,1); %PRI Trigger
  data(3*nt+4+(4097:8192),3) = ones(4096,1); %PRI Trigger
  data(:,4) = m_clk(1:4*nt);
  
  % Correct rounding errors that cause data points to fall outside the valid
  % +/-1 range.
  data(data<-1,1:2) = -1;
  data(data>1,1:2) = 1;
  
  % Write the file
  fn_del = sprintf(fn,del*1e6);
  fprintf('Writing %s (%s)\n', fn_del, datestr(now));
  fid1 = fopen(fn_del,'w');
  fprintf(fid1,'SampleRate=32000000000\r\n');
  fprintf(fid1,'SetConfig=true\r\n');
  fprintf(fid1,'Y1,Y2,SampleMarker1,SampleMarker2\r\n');
  fprintf(fid1,'%12.10f,%12.10f,%i,%i\r\n',data');
  fclose(fid1);
end
