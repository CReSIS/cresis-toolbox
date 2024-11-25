function data_signal = burst_noise_corr(raw_data,wfs,burst_noise_sample_fn)
% data_signal = burst_noise_corr(raw_data,wfs,burst_noise_sample_fn)
%
% Burst noise correlation function example for UTIG 2023/01/20 flight
%
% To be used with analysis.m "burst_noise" command as in:
% params.analysis.cmd{1}.signal_fh{1} = @(raw_data,wfs) analysis_burst_corr(raw_data,wfs,'/scratch/metadata/2022_Antarctica_BaslerMKB/burst_noise_sample.mat');
%
% Capture of the burst_noise_sample uses run_load_data.m
%
% aa = double(data{2}(2285:2300,1937,1));
% % BASEBAND SIGNAL
% [B,A] = butter(2,11/25);
% Nt = length(aa);
% bb = filtfilt(B,A,exp(j*2*pi*-10/50*(0:Nt-1).') .* aa);
% % FFT AND CONJUGATE
% Nt = size(data{2},1);
% cc = conj(fft(bb,Nt));
% burst_noise_sample = cc;
% save('/scratch/metadata/2022_Antarctica_BaslerMKB/burst_noise_sample.mat','burst_noise_sample','-v7.3')

load(burst_noise_sample_fn,'burst_noise_sample');
[B,A] = butter(2,11/25);
data_signal = lp(ifft(fft(filtfilt(B,A,double(raw_data) .* exp(1i*2*pi*-10/50*(0:size(raw_data,1)-1).'))) .* burst_noise_sample));
