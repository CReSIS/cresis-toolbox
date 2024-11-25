% script run_sar_equal_post
%
% Example for running sar_equal_post.m
%
% Author: John Paden

warning('This is an example file, copy to personal directory, rename, and remove this warning/return to use');

%% User Settings
% =======================================================================

param_override = []; params = [];

if 0
  % 2011 EGIG line
  params = read_param_xls(ct_filename_param('rds_param_2011_Greenland_P3.xls'),'20110426_11');
  
  params.cmd.frms = [5];
  params.cmd.generic = true;
  
  % Waveform 1 to waveform 2
  param_override.sar_equal_post.imgs = {[2*ones(7,1) (2:8)'],[1*ones(7,1) (2:8)']};
  param_override.sar_equal_post.debug_in_dir = 'sar_equal_wf1';
  
elseif 0
  % 2012 EGIG line
  params = read_param_xls(ct_filename_param('rds_param_2012_Greenland_P3.xls'),'20120411_02');
  
  params.cmd.frms = [9 10];
  params.cmd.generic = true;
  
  % Waveform 1 to waveform 2
  param_override.sar_equal_post.imgs = {[2*ones(7,1) (2:8)'],[1*ones(7,1) (2:8)']};
  param_override.sar_equal_post.debug_in_dir = 'sar_equal_wf1';
  
elseif 1
  % 2014 low altitude above ground level frames to measure wf 1-wf 2
  % overlap
  params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'20140502_01');
  
  params.cmd.frms = [31 32 33 34]; % frame 31 is mostly too high AGL
  params.cmd.generic = true;
  
  if 0
    % Waveform 1 to waveform 2
    param_override.sar_equal_post.imgs = {[2*ones(7,1) (2:8)'],[1*ones(7,1) (2:8)']};
    param_override.sar_equal_post.debug_in_dir = 'sar_equal_wf1';
  else
    % Waveform 2 to waveform 3
    param_override.sar_equal_post.imgs = {[2*ones(7,1) (2:8)'],[3*ones(7,1) (2:8)']};
    param_override.sar_equal_post.debug_in_dir = 'sar_equal_wf3';
  end
  
elseif 0
  % 2014 EGIG line
  params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'20140410_01');
  
  params.cmd.frms = [57];
  params.cmd.generic = true;
  
  % Waveform 2 to waveform 3
  param_override.sar_equal_post.imgs = {[2*ones(7,1) (2:8)'],[3*ones(7,1) (2:8)']};
  param_override.sar_equal_post.debug_in_dir = 'sar_equal_wf3';
end

%% Automated Section
% =====================================================================

% Input checking
global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

% Process each of the segments
ctrl_chain = {};
for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  %sar_equal_output{param_idx} = sar_equal_post(param,param_override);
  sar_equal_post; sar_equal_output{param_idx} = sar_equal_output;
end

%% Setup plots

h_fig = get_figures(3,enable_visible_plot);
for fig_num = 1:3
  clf(h_fig(fig_num));
  h_axes(fig_num) = axes('parent',h_fig(fig_num));
end

%% Loop Segments
output_idx = 0;
for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  
  %% Segments: Loop Frames
  for frm_idx = 1:length(param.cmd.frms)
    frm = param.cmd.frms(frm_idx);
    
    output_idx = output_idx + 1;
    
    % Recompute means
    
    % plot(metadata.fcs{1}{1}.gps_time, metadata.fcs{1}{1}.surface); hold on;
    % plot(gps_time(img,:), surface(img,:));
    % plot(gps_time(img,:), abs(dsurface(img,:)));
    
    %% Segments: Frames: Compute mean
    
    [offset_ave,mask] = mean_without_outliers(peak_offset, 1, 0.2, 2);
    
    peak_val_mean = peak_val;
    peak_val_mean(mask) = NaN;
    peak_val_mean = nanmean(peak_val_mean, 2);
    
    Tsys_deg = angle(exp(1i*2*pi*offset_ave*dt * fc))*180/pi
    Tsys = -offset_ave*dt
    chan_equal_dB = db(nanmean(abs(peak_val_mean).^2, 2),'power')
    chan_equal_deg = angle(peak_val_mean)*180/pi
    
    
    
    %% Segments: Frames: Store recomputed means
    Tsys(output_idx) = sar_equal_output{param_idx}{frm}.Tsys;
    Tsys_deg(output_idx) = sar_equal_output{param_idx}{frm}.Tsys_deg;
    chan_equal_deg(output_idx) = sar_equal_output{param_idx}{frm}.chan_equal_deg;
    chan_equal_dB(output_idx) = sar_equal_output{param_idx}{frm}.chan_equal_dB;
    
    frm_id = sprintf('%s_%03d\n', param.day_seg, frm);
    frm_ids{output_idx} = frm_id;
    
%     plot(h_axes(1), sar_equal_output{param_idx}{frm}
%     hold on;
  end
end

return

%% Compute mean

[offset_ave,mask] = mean_without_outliers(peak_offset, 1, 0.2, 2);

peak_val_mean = peak_val;
peak_val_mean(mask) = NaN;
peak_val_mean = nanmean(peak_val_mean, 2);

Tsys_deg = angle(exp(1i*2*pi*offset_ave*dt * fc))*180/pi
Tsys = -offset_ave*dt
chan_equal_dB = db(nanmean(abs(peak_val_mean).^2, 2),'power')
chan_equal_deg = angle(peak_val_mean)*180/pi

%% Print results
new_wfs = param.radar.wfs;
for img = 1:length(param.sar_equal.imgs)
  wf = param.sar_equal.imgs{img}(1,1);
  adc = param.sar_equal.imgs{img}(1,2);
  
  if img == ref_img
    fprintf('%% img %d wf %d adc %d (reference image)\n', img, wf, adc);
    fprintf('  Tsys = old_Tsys + %g;\n', 0);
    fprintf('  chan_equal_deg = old_chan_equal_deg + %g;\n', 0);
    fprintf('  chan_equal_dB = old_chan_equal_dB + %g;\n', 0);
  else
    fprintf('%% img %d wf %d adc %d\n', img, wf, adc);
    fprintf('  Tsys = Tsys + %g;\n', Tsys(img));
    fprintf('  chan_equal_deg = chan_equal_deg + %g;\n', chan_equal_deg(img) + Tsys_deg(img));
    fprintf('  chan_equal_dB = chan_equal_dB + %g;\n', chan_equal_dB(img));
    fprintf('  chan_equal_deg = chan_equal_deg + %g; %% Use this if not changing Tsys\n', chan_equal_deg(img));
    
    for wf_adc = 1:size(param.sar_equal.imgs{img},1)
      wf = param.sar_equal.imgs{img}(wf_adc,1);
      adc = param.sar_equal.imgs{img}(wf_adc,2);
      new_wfs(wf).Tsys(adc) = new_wfs(wf).Tsys(adc) + Tsys(img);
      new_wfs(wf).chan_equal_deg(adc) = new_wfs(wf).chan_equal_deg(adc) + chan_equal_deg(img) + Tsys_deg(img);
      new_wfs(wf).chan_equal_dB(adc) = new_wfs(wf).chan_equal_dB(adc) + chan_equal_dB(img);
    end
  end
end
for wf = 1:length(new_wfs)
  fprintf('param_override.radar.wfs(%d).Tsys = %s;\n', wf, mat2str_generic(new_wfs(wf).Tsys));
  fprintf('param_override.radar.wfs(%d).chan_equal_deg = %s;\n', wf, mat2str_generic(new_wfs(wf).chan_equal_deg));
  fprintf('param_override.radar.wfs(%d).chan_equal_dB = %s;\n', wf, mat2str_generic(new_wfs(wf).chan_equal_dB));
end

%% Plot results
clf(h_fig(1));
clf(h_fig(2));
clf(h_fig(3));
h_axes(1) = axes('parent',h_fig(1));
h_axes(2) = axes('parent',h_fig(2));
h_axes(3) = axes('parent',h_fig(3));
legend_str = cell(size(data));
for img = 1:length(param.sar_equal.imgs)
  wf = param.sar_equal.imgs{img}(1,1);
  adc = param.sar_equal.imgs{img}(1,2);
  legend_str{img} = sprintf('img %d wf %d adc %d',img, wf, adc);
  
  plot(h_axes(1),angle(peak_val(img,:))*180/pi)
  grid(h_axes(1),'on');
  hold(h_axes(1),'on');
  xlabel(h_axes(1),'Range line');
  ylabel(h_axes(1),'Angle (deg)');
  
  plot(h_axes(2),db(peak_val(img,:)))
  grid(h_axes(2),'on');
  hold(h_axes(2),'on');
  xlabel(h_axes(2),'Range line');
  ylabel(h_axes(2),'Relative power (dB)');
  
  plot(h_axes(3),peak_offset(img,:),'.')
  grid(h_axes(3),'on');
  hold(h_axes(3),'on');
  xlabel(h_axes(3),'Range line');
  ylabel(h_axes(3),'Time delay (bins)');
end
legend(h_axes(1),legend_str);
legend(h_axes(2),legend_str);
legend(h_axes(3),legend_str);

fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('angle_%02d_adc_%02d',wf,adc)) sprintf('_%03d.jpg',frm)];
fprintf('Saving %s\n', fig_fn);
fig_fn_dir = fileparts(fig_fn);
if ~exist(fig_fn_dir,'dir')
  mkdir(fig_fn_dir);
end
ct_saveas(h_fig(1),fig_fn);
fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('angle_%02d_adc_%02d',wf,adc)) sprintf('_%03d.fig',frm)];
fprintf('Saving %s\n', fig_fn);
ct_saveas(h_fig(1),fig_fn);

fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('abs_%02d_adc_%02d',wf,adc)) sprintf('_%03d.jpg',frm)];
fprintf('Saving %s\n', fig_fn);
fig_fn_dir = fileparts(fig_fn);
if ~exist(fig_fn_dir,'dir')
  mkdir(fig_fn_dir);
end
ct_saveas(h_fig(2),fig_fn);
fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('abs_%02d_adc_%02d',wf,adc)) sprintf('_%03d.fig',frm)];
fprintf('Saving %s\n', fig_fn);
ct_saveas(h_fig(3),fig_fn);

fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('td_%02d_adc_%02d',wf,adc)) sprintf('_%03d.jpg',frm)];
fprintf('Saving %s\n', fig_fn);
fig_fn_dir = fileparts(fig_fn);
if ~exist(fig_fn_dir,'dir')
  mkdir(fig_fn_dir);
end
ct_saveas(h_fig(3),fig_fn);
fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('td_%02d_adc_%02d',wf,adc)) sprintf('_%03d.fig',frm)];
fprintf('Saving %s\n', fig_fn);
ct_saveas(h_fig(3),fig_fn);

%% Save outputs
mat_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('sar_equal_wf_%02d_adc_%02d',wf,adc)) sprintf('_%03d.mat',frm)];
fprintf('Saving %s\n', mat_fn);
mat_fn_dir = fileparts(mat_fn);
if ~exist(mat_fn_dir,'dir')
  mkdir(mat_fn_dir);
end
param_sar_equal = param;
ct_save(mat_fn,'peak_offset','peak_val','Tsys','Tsys_deg','chan_equal_dB','chan_equal_deg','gps_time','surface','param_sar_equal');

