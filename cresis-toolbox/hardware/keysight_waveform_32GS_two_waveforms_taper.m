close all; clear all;

fs = 32e9; %256 samples at 125MHz
dt = 1/fs;
tau = 200e-6;
max_del = 50e-6;
del = 1.756e-6;
fif = 70e6;
nt_tau = round(tau/dt);
nt_del = round(del/dt);
nt = round((tau+max_del)/dt);
tt = (0:dt:(nt-1)*dt)';

f0 = 2e9;
bw = 12e9;
k = bw/tau;

chirp1 = [tukeywin(nt_tau,.1);zeros(nt-nt_tau,1)].*sin(2*pi*(f0*tt + 0.5*k*(tt.*tt)));
chirp2 = [zeros(nt_del,1);tukeywin(nt_tau,.1);zeros(nt-nt_tau-nt_del,1)].*sin(2*pi*((f0+fif)*(tt-del) + 0.5*k*((tt-del).*(tt-del))));

m_clk = zeros(4*nt,1);
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

data = zeros(4*nt,4);
data(:,1) = [ chirp1;-chirp1;-chirp1; chirp1];
data(:,2) = [ chirp2; chirp2;-chirp2;-chirp2];
data(0*nt+4+(4097:8192),3) = ones(4096,1); %PRI Trigger
data(1*nt+4+(4097:8192),3) = ones(4096,1); %PRI Trigger
data(2*nt+4+(4097:8192),3) = ones(4096,1); %PRI Trigger
data(3*nt+4+(4097:8192),3) = ones(4096,1); %PRI Trigger
data(:,4) = m_clk(1:4*nt);
fid1 = fopen('fmcw_2ch_32GSPS_2to14GHz_200us_4khz_01756ns_70MHz.csv','w');
fprintf(fid1,'SampleRate=32000000000\r\n');
fprintf(fid1,'SetConfig=true\r\n');
fprintf(fid1,'Y1,Y2,SampleMarker1,SampleMarker2\r\n');
fprintf(fid1,'%12.10f,%12.10f,%i,%i\r\n',data');
fclose(fid1);