% script run_load_sar_data
%
% Example for running sar_load.m
%
% Author: John Paden, Logan Smith

warning('This is an example file, copy to personal directory, rename, and remove this warning/return to use');

% =======================================================================
% User Settings
% =======================================================================

% param = read_param_xls(ct_filename_param('rds_param_2019_Antarctica_Ground.xls'),'20200107_01');
param = read_param_xls(ct_filename_param('rds_param_2018_Greenland_P3.xls'),'20180501_01');

% param.sar_load.in_path = ''; % Leave empty for default 'sar'

% param.sar_load.chunk: One cell entry per frame; leave empty for all
% chunks Each entry is two positive integers specifying the start and stop
% chunk to load (inf for second element loads to the end)
% param.sar_load.chunk = {};

% param.sar_load.sar_type = ''; % Leave empty for default 'fk'

param.sar_load.frms = [51 52]; % Specify data frames to load

% param.sar_load.subap = []; % Leave empty for default (all subapertures)

% {Images} with [wf,adc] pairs to load
param.sar_load.imgs = {[1 1]};
% param.sar_load.imgs = {[1 1; 1 2; 1 3; 1 4; 1 5; 1 6]};
% param.sar_load.imgs = {[2 2; 2 3; 2 4; 2 5; 2 6; 2 7; 2 9; 2 10; 2 11; 2 12; 2 13; 2 14]};
% param.sar_load.imgs = {[1*ones(8,1) (1:8)'],[2*ones(8,1) (1:8)'],[3*ones(8,1) (1:8)']};
% param.sar_load.imgs = {[1*ones(8,1) (1:8)'],[2*ones(8,1) (1:8)'],[[3*ones(8,1) (1:8)'];[4*ones(8,1) (1:8)']]};

% Debug level (1 = default)
param.sar_load.debug_level = 2;

% Combine receive channels
% param.sar_load.combine_channels = 0;

% Combine waveforms parameters
% param.sar_load.wf_comb = 10e-6;

% Take abs()^2 of the data (only runs if combine_channels runs)
% param.sar_load.incoherent = 0;

% Combine waveforms (only runs if incoherent runs)
% param.sar_load.combine_imgs = 0;

% Parameters for local_detrend (cmd == 5 disables, only runs if incoherent runs)
% param.sar_load.detrend.cmd = 3;
% param.sar_load.detrend.B_noise = [100 200];
% param.sar_load.detrend.B_sig = [1 10];
% param.sar_load.detrend.minVal = -inf;

[data,metadata] = sar_load(param);

return


%% Examples of manipulating multilook data
good_mask = metadata.wfs(1).time > 0e-6 & metadata.wfs(1).time < 30e-6;

% Step through multilooks
subap = 0;
figure(1); clf;
while 1
  subap = mod(subap,size(data{1},4))+1;
  imagesc([],metadata.wfs(1).time(good_mask),lp(mean(data{1}(good_mask,:,:,subap),3)),[-150 -23])
  title(sprintf('%.0f',subap));
  if subap == 1
    beep
  end
  pause; % pause for keystroke advance or pause(0.1) for animation
end


figure(2); clf;
imagesc([],metadata.wfs(1).time(good_mask),lp(local_detrend(mean(abs(mean(data{1}(good_mask,:,:,[6:16]),3)).^2,4),[40 200],[1 3])))

figure(2); clf;
imagesc([],metadata.wfs(1).time(good_mask),lp(mean(abs(mean(data{1}(good_mask,:,:,[6:16]),3)).^2,4)),[-150 -23])

figure(2); clf;
imagesc([],metadata.wfs(1).time(good_mask),lp(mean(abs(mean(data{1}(good_mask,:,:,[1:6]),3)).^2,4)),[-150 -23])

figure(3); clf;
imagesc([],metadata.wfs(1).time(good_mask),lp(mean(abs(mean(data{1}(good_mask,:,:,[end-5:end]),3)).^2,4)),[-150 -23])







