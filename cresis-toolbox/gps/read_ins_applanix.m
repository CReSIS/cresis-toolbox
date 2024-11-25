% script read_ins_applanix
%
% Very basic script for loading and plotting the display plot exported 
% results of acceleration from POSPac.
%
% Author: John Paden

% fn: Exported file from Applanix POSPac software
fn = 'C:\tmp\Forward Processed Trajectory, Reference Frame.txt';
save_dir = 'C:\tmp';

%% Read in Acceleration file
fid = fopen(fn);

A = textscan(fid, '%f %f %f %f %f','HeaderLines',1);
feof(fid);

fclose(fid);

%% All events
time = A{1} - A{1}(1);
x = A{2};
y = A{3};
z = A{4};
total = A{5};
dt = time(2)-time(1);
Nt = length(time);
df = 1/(Nt*dt);
freq = df*(0:Nt-1);

if 0
  [B_filt,A_filt] = butter(2,0.13);
  [B_filt_lat,A_filt_lat] = butter(2,0.09);
  freqz(B_filt,A_filt);
  z_filt = filter(B_filt,A_filt,z);
  x_filt = filter(B_filt_lat,A_filt_lat,x);
  y_filt = filter(B_filt_lat,A_filt_lat,y);
  
  figure(1); clf;
  clf
  plot(freq, lp(fft(z)))
  hold on
  plot(freq, lp(fft(z_filt)))
  xlabel('Frequency (Hz)');
  ylabel('Relative acceleration (dB)');
  legend('z','z isolated');
  
  figure(4); clf;
  clf
  plot(freq, lp(fft(x)))
  hold on
  plot(freq, lp(fft(y)))
  xlabel('Frequency (Hz)');
  ylabel('Relative acceleration (dB)');
  legend('x','y');
  
  figure(5); clf;
  total_filt = sqrt(x_filt.^2 + y_filt.^2 + z_filt.^2);
  clf
  plot(time, total)
  hold on
  plot(time, total_filt)
  xlabel('Time (sec)');
  ylabel('Acceleration (g)');
  legend('total','total isolated');
  
  figure(2); clf;
  plot(time,z);
  hold on
  plot(time,z_filt);
  xlabel('Time (sec)');
  ylabel('Acceleration (g)');
  legend('z','z isolated');
  
  figure(3); clf;
  plot(time,x);
  hold on;
  plot(time,y);
  xlabel('Time (sec)');
  ylabel('Acceleration (g)');
  legend('x','y');
  
  return
end

figure(1); clf;
plot(time,A{5},'b')
xlabel('Time (sec)');
ylabel('Acceleration (g)');
hold on;
ylims = ylim;
plot([1805 1831.5 1831.5 1805 1805], ylims([1 1 2 2 1]),'r');
plot([3280 3283 3283 3280 3280], ylims([1 1 2 2 1]),'g');
plot(time,A{5},'b')
legend('Total XYZ', 'Event 1', 'Event 2');
saveas(1,fullfile(save_dir,'Total.jpg'));

%% Event 1

good_mask = time>2800 & time<2980;

% figure(1); clf;
% plot(time(good_mask),x(good_mask))
% hold on;
% plot(time(good_mask),y(good_mask))
% plot(time(good_mask),z(good_mask))

dt = time(2)-time(1)
fs = 1/dt

figure(2); clf;
periodogram(x(good_mask),[],'onesided',512,fs)
title('X Vibration PSD');
figure(3); clf;
periodogram(y(good_mask),[],'onesided',512,fs)
title('Y Vibration PSD');
figure(4); clf;
periodogram(z(good_mask),[],'onesided',512,fs)
title('Z Vibration PSD');
saveas(2,fullfile(save_dir,'Background1_X.jpg'));
saveas(3,fullfile(save_dir,'Background1_Y.jpg'));
saveas(4,fullfile(save_dir,'Background1_Z.jpg'));

%% Event 1

good_mask = time>1805 & time<1831.5;

% figure(1); clf;
% plot(time(good_mask),x(good_mask))
% hold on;
% plot(time(good_mask),y(good_mask))
% plot(time(good_mask),z(good_mask))

dt = time(2)-time(1)
fs = 1/dt

figure(2); clf;
periodogram(x(good_mask),[],'onesided',512,fs)
title('X Vibration PSD');
figure(3); clf;
periodogram(y(good_mask),[],'onesided',512,fs)
title('Y Vibration PSD');
figure(4); clf;
periodogram(z(good_mask),[],'onesided',512,fs)
title('Z Vibration PSD');
saveas(2,fullfile(save_dir,'Event1_X.jpg'));
saveas(3,fullfile(save_dir,'Event1_Y.jpg'));
saveas(4,fullfile(save_dir,'Event1_Z.jpg'));

%% Event 2

good_mask = time>3280 & time<3283;

figure(1); clf;
plot(time(good_mask),x(good_mask))
hold on;
plot(time(good_mask),y(good_mask))
plot(time(good_mask),z(good_mask))

dt = time(2)-time(1)
fs = 1/dt

figure(2); clf;
periodogram(x(good_mask),[],'onesided',512,fs)
title('X Vibration PSD');
figure(3); clf;
periodogram(y(good_mask),[],'onesided',512,fs)
title('Y Vibration PSD');
figure(4); clf;
periodogram(z(good_mask),[],'onesided',512,fs)
title('Z Vibration PSD');
saveas(2,fullfile(save_dir,'Event2_X.jpg'));
saveas(3,fullfile(save_dir,'Event2_Y.jpg'));
saveas(4,fullfile(save_dir,'Event2_Z.jpg'));
