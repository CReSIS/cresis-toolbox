% SampleRate=64000000000
% SetConfig=true
% Y1,Y2,SampleMarker1,SampleMarker2
% 0.0000000000,0.0000000000,0,0
% 0.0000000000,0.0000000000,0,0
% 0.0000000000,0.0000000000,0,0

fn = '/process3/20190409/fmcw/snow/fmcw_1ch_64GSPS_2to18GHz_240us_4khz_taper0.85.csv';
fn = 'E:\tmp\deleteThis\fmcw_1ch_64GSPS_2to8GHz_240us_4khz_taper0.85.csv';

plot_color = 'b-';

fid = fopen(fn,'r');

A = textscan(fid,'%f%f%f%f','Headerlines',3,'Delimiter',',');
data = A{1};

fclose(fid);

fs = 64e9;
Nt = length(data);
dt = 1/fs;
time = dt*(0:Nt-1).';
figure(1);
clf;
plot(time*1e6, data, plot_color);
hold on;

df = fs/Nt;
freq = df*ifftshift( -floor(Nt/2) : floor((Nt-1)/2) );
figure(3);
clf;
plot(freq/1e9, lp(fft(data)), plot_color);
hold on;


fn = '/process3/20190409/fmcw/snow/fmcw_1ch_64GSPS_2to8GHz_240us_4khz_taper0.85.csv';
fn = 'E:\tmp\deleteThis\fmcw_1ch_64GSPS_2to8GHz_240us_4khz_taper0.85_2019Gr.csv';

plot_color = 'r-';

fid = fopen(fn,'r');

A = textscan(fid,'%f%f%f%f','Headerlines',3,'Delimiter',',');
data = A{1};

fclose(fid);

fs = 64e9;
Nt = length(data);
dt = 1/fs;
time = dt*(0:Nt-1).';
figure(2);
clf;
plot(time*1e6, data, plot_color);
hold on;

df = fs/Nt;
freq = df*ifftshift( -floor(Nt/2) : floor((Nt-1)/2) );
figure(3);
% clf;
plot(freq/1e9, lp(fft(data)), plot_color);
hold on;

figure(1);
xlabel('Time (us)');
ylabel('Scaled voltage (V)');
title('fmcw_1ch_64GSPS_2to18GHz_240us_4khz_taper0.85.csv','interpreter','none');
grid on;
ylim([-1 1]);

figure(2);
xlabel('Time (us)');
ylabel('Scaled voltage (V)');
title('fmcw_1ch_64GSPS_2to8GHz_240us_4khz_taper0.85.csv','interpreter','none');
grid on;
ylim([-1 1]);


figure(3);
xlabel('Frequency (GHz)');
ylabel('Relative power (dB)');
legend('2-18 GHz','2-8 GHz');
grid on;

saveas(1,'~/keysight_2_18_time.jpg');
saveas(2,'~/keysight_2_8_time.jpg');
saveas(3,'~/keysight_both_freq.jpg');
