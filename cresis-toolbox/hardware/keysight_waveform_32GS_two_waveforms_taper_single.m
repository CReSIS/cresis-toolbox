fs = 32e9; %256 samples at 125MHz
dt = 1/fs;
f0 = 2.5e9;
bw = 4e9;
tau = 240e-6;
range_ft = 16500;
del = range_ft*12*2.54/100 / (3e8/2);
PRI = 300e-6;
fif = 200e6;

% Calculate the maximum delay, PRI should be larger than this
max_del = tau + del + 10e-6

% Adjust delay of LO to create desired IF frequency
del = del - tau / bw * fif

sequence = [0 300e-6 600e-6 900e-6];
sequence1_scale = [1 1 -1 -1];
sequence2_scale = [1 -1 1 -1];
total_duration = 1200e-6-10e-6;

nt = round((total_duration)/dt);
tt = (0:dt:(nt-1)*dt)';

taper_ratio=0.85; %linear

k = bw/tau;
TUKEY_WIN = 2e-6/tau;

chirp1_sequence = zeros(nt,1);
chirp2_sequence = zeros(nt,1);
for idx = 1:length(sequence)
  tt_delay = (tt - sequence(idx));
  % y-intercept is 0.85 at time sequence(idx)
  % y-intercept is 1 at time sequence(idx)+tau
  slope = (1-taper_ratio) / tau;
  y_intercept = taper_ratio;
  taper = slope*(tt-sequence(idx)) + y_intercept;
  chirp1_sequence = chirp1_sequence + taper.*sequence1_scale(idx).*tukeywin_cont((tt_delay-tau/2)/tau,TUKEY_WIN) .* sin(2*pi*(f0*tt_delay + 0.5*k*(tt_delay.*tt_delay)));

  tt_delay = (tt - sequence(idx) - del);
  taper = slope*(tt-sequence(idx) - del) + y_intercept;
  chirp2_sequence = chirp2_sequence + taper.*sequence2_scale(idx).*tukeywin_cont((tt_delay-tau/2)/tau,TUKEY_WIN) .* sin(2*pi*(f0*tt_delay + 0.5*k*(tt_delay.*tt_delay)));
  figure(1); clf;
  plot(tt,chirp1_sequence);
  hold on;
  plot(tt,chirp2_sequence);
  figure(2); clf;
  df = 1/(dt*nt);
  freq = ifftshift(df*(-floor(nt/2):floor((nt-1)/2)));
  plot(freq/1e9,db(fft(chirp1_sequence)))
  hold on
  plot(freq/1e9,db(fft(chirp2_sequence)))  
end

% MARKERS ARE PROBABLY NOT CORRECT... NEED TO BE FIXED
m_clk = zeros(nt,1);
wave_id = uint64(hex2dec('464D4357'));
for index = 1:32,
  if mod(bitshift(wave_id,1-index),2),
    m_clk((index-1)*2048+4*1024+1:(index-1)*2048+4*1024+2048) = ones(2048,1);
  end;
end;
wave_id = uint64(hex2dec('4F49425F'));
for index = 33:64,
  if mod(bitshift(wave_id,33-index),2),
    m_clk((index-1)*2048+4*1024+1:(index-1)*2048+4*1024+2048) = ones(2048,1);
  end;
end;

data = zeros(nt,4);
data(:,1) = [chirp1_sequence];
data(:,2) = [chirp2_sequence];
data(0*nt+4+(4097:8192),3) = ones(4096,1); %PRI Trigger
%   data(1*nt+4+(4097:8192),3) = ones(4096,1); %PRI Trigger
%   data(2*nt+4+(4097:8192),3) = ones(4096,1); %PRI Trigger
%   data(3*nt+4+(4097:8192),3) = ones(4096,1); %PRI Trigger
data(:,4) = m_clk(1:nt);

fid1 = fopen('AITT_2ch_32GSPS_2G5to6G5GHz_300us_18000ft_200MHz.csv','w');
fprintf(fid1,'SampleRate=32000000000\r\n');
fprintf(fid1,'SetConfig=true\r\n');
fprintf(fid1,'Y1,Y2,SampleMarker1,SampleMarker2\r\n');
fprintf(fid1,'%12.10f,%12.10f,%i,%i\r\n',data');
fclose(fid1);

% Single transmitter
% Keep along-track sampling the same with 16 presums, but double range gate
Tgate = 150e6*240e-6/4e9
Rgate = Tgate * 3e8/2
Rgate_ft = Rgate * 100/12/2.54
% Use two modes with zero pi mod
% Minimum 4: [1 -1 1 -1]
% 300 us PRI
% 1190 us total lengths
