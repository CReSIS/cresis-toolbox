close all; clear all;

low_alt = true;

fs = 64e9; %512 samples corresponds to 1 cycle at 125MHz
dt = 1/fs;
tau = 240e-6;
if low_alt
  max_del = 0e-6;
else
  max_del = 50e-6;
end
zeros_at_end = false;
nt_tau = round(tau/dt);
nt = round((tau+max_del)/dt);
taper_ratio_dB=3; %dB
taper_ratio=1-10^(-taper_ratio_dB/20);
taper_ratio=0.85; %linear
f0 = 2.5e9;
bw = 15e9;
% bw = 2.5e9; % Wide altitude range
k = bw/tau;

TUKEY_WIN=2e-6/tau;

if zeros_at_end
  % Zeros at end
  % tt = (0:dt:(nt-1)*dt)';
  % chirp1 = [tukeywin(nt_tau,TUKEY_WIN);zeros(nt-nt_tau,1)].*sin(2*pi*(f0*tt + 0.5*k*(tt.*tt)));
else
  % Zeros at start (to create delay when using this signal as LO)
  tt = (0:dt:(nt-1)*dt)' - max_del;
  chirp1 = [zeros(nt-nt_tau,1); tukeywin(nt_tau,TUKEY_WIN)].*sin(2*pi*(f0*tt + 0.5*k*(tt.*tt)));
end

FreqWeight = 1 + [0.0 : [taper_ratio/nt_tau] : taper_ratio];
if zeros_at_end
  % Zeros at end
  % taper=[FreqWeight(1:nt_tau)';zeros(nt-nt_tau,1)];
else
  % Zeros at start
  taper=[zeros(nt-nt_tau,1);FreqWeight(1:nt_tau)'];
end
chirp1=(taper.*chirp1);
chirp1 = chirp1./max(chirp1);
figure(1);
plot(chirp1);
hold on;
plot(taper, 'k');
m_clk = zeros(nt,1);

%wave_id is used to uniquely identify the current waveform
%it is written to the header of the data file every epri through marker 2
%64e9/4096 is 125/8 (using 3rd bit (number 2) of the counter
wave_id = uint64(hex2dec('464D4357')); 
for index = 1:32,
    if mod(bitshift(wave_id,1-index),2),
      m_clk((index-1)*4096+2*2048:(index-1)*4096+2*2048+4095) = ones(4096,1);
    end;
end;
wave_id = uint64(hex2dec('4F49425F'));
for index = 33:64,
    if mod(bitshift(wave_id,33-index),2),
      m_clk((index-1)*4096+2*2048:(index-1)*4096+2*2048+4095) = ones(4096,1);
    end;
end;

data = zeros(nt,4);
data(:,1) = chirp1;

%marker 1 is used as the pri trigger which is sent from the AWG to the DAQ
%the location of the pri trigger can be adjusted to account for setup/hold
%instabilities due to cable lengths
%64e9/4096 is 125/8
data(0+(4097:8192),3) = ones(4096,1); %PRI Trigger
data(:,4) = m_clk(1:nt);

%write the file
fid1 = fopen('AITT_fmcw_1ch_64GSPS_2G5to17G5_240us_4khz_taper0.85_0us_delay.csv','w');
% fid1 = fopen('AITT_fmcw_1ch_64GSPS_2G5to17G5_240us_4khz_taper0.85_50us_delay.csv','w');
fprintf(fid1,'SampleRate=64000000000\r\n');
fprintf(fid1,'SetConfig=true\r\n');
fprintf(fid1,'Y1,Y2,SampleMarker1,SampleMarker2\r\n');
fprintf(fid1,'%12.10f,%12.10f,%i,%i\r\n',data');
fclose(fid1);

if 0

  df = 1/(dt*nt);
freq = ifftshift(df*(-floor(nt/2):floor((nt-1)/2)));

  clf;
plot(freq/1e9,db(fft(chirp1)))


end

