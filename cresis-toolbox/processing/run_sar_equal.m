% script run_sar_equal
%
% Example for running sar_equal.m
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
  
  if 0
    % Waveform 1 equalization
    param_override.sar_equal.imgs = {[1 2],[1 3],[1 4],[1 5],[1 6],[1 7],[1 8]};
    param_override.sar_equal.start_times = struct('name','surface','eval',struct('cmd','s=s-1.5e-6;'));
    
  elseif 1
    % Waveform 1 to waveform 2
    param_override.sar_equal.imgs = {[2*ones(7,1) (2:8)'],[1*ones(7,1) (2:8)']};
    param_override.sar_equal.start_time = struct('name','surface','eval',struct('cmd','s=s+10e-6;'));
    param_override.sar_equal.delay.ref_bins = [-30 31];
    param_override.sar_equal.delay.search_bins = [-24 25];
    param_override.sar_equal.debug_out_dir = 'sar_equal_wf1';
    param_override.sar_equal.coh_ave = 10;
    
    param_override.radar.wfs(1).Tsys = params.radar.wfs(1).Tsys - 5.8045e-09;
    param_override.radar.wfs(1).chan_equal_deg = params.radar.wfs(1).chan_equal_deg + -26.8951 + 47.4778;
    param_override.radar.wfs(2).Tsys = params.radar.wfs(2).Tsys;
    param_override.radar.wfs(2).chan_equal_deg = params.radar.wfs(2).chan_equal_deg;
    
  end
  
elseif 0
  % 2012 Summit line
  params = read_param_xls(ct_filename_param('rds_param_2012_Greenland_P3.xls'),'20120330_03');
  
  params.cmd.frms = 8;
  params.cmd.generic = true;
  
  if 0
    % Waveform 1 equalization
    param_override.sar_equal.imgs = {[1 2],[1 3],[1 4],[1 5],[1 6],[1 7],[1 8]};
    param_override.sar_equal.start_times = struct('name','surface','eval',struct('cmd','s=s-1.5e-6;'));
    
  elseif 1
    % Waveform 1 to waveform 2
    param_override.sar_equal.imgs = {[2*ones(7,1) (2:8)'],[1*ones(7,1) (2:8)']};
    param_override.sar_equal.start_time = struct('name','surface','eval',struct('cmd','s=s+10e-6;'));
    param_override.sar_equal.delay.ref_bins = [-30 31];
    param_override.sar_equal.delay.search_bins = [-24 25];
    param_override.sar_equal.debug_out_dir = 'sar_equal_wf1';
    param_override.sar_equal.coh_ave = 10;
    
    param_override.radar.wfs(1).Tsys = params.radar.wfs(1).Tsys -5.65956e-09;
    param_override.radar.wfs(1).chan_equal_deg = params.radar.wfs(1).chan_equal_deg + 5.09989;
    param_override.radar.wfs(2).Tsys = params.radar.wfs(2).Tsys;
    param_override.radar.wfs(2).chan_equal_deg = params.radar.wfs(2).chan_equal_deg;
  end
  
elseif 0
  % 2012 EGIG line
  params = read_param_xls(ct_filename_param('rds_param_2012_Greenland_P3.xls'),'20120411_02');
  
  params.cmd.frms = [9 10];
  params.cmd.frms = 9;
  params.cmd.generic = true;
  
  if 0
    % Waveform 1 equalization
    param_override.sar_equal.imgs = {[1 2],[1 3],[1 4],[1 5],[1 6],[1 7],[1 8]};
    param_override.sar_equal.start_times = struct('name','surface','eval',struct('cmd','s=s-1.5e-6;'));
    
  elseif 1
    % Waveform 1 to waveform 2
    param_override.sar_equal.imgs = {[2*ones(7,1) (2:8)'],[1*ones(7,1) (2:8)']};
    param_override.sar_equal.start_time = struct('name','surface','eval',struct('cmd','s=s+10e-6;'));
    param_override.sar_equal.delay.ref_bins = [-30 31];
    param_override.sar_equal.delay.search_bins = [-24 25];
    param_override.sar_equal.debug_out_dir = 'sar_equal_wf1';
    param_override.sar_equal.coh_ave = 10;
    
    param_override.radar.wfs(1).Tsys = params.radar.wfs(1).Tsys -5.65956e-09;
    param_override.radar.wfs(1).chan_equal_deg = params.radar.wfs(1).chan_equal_deg + 5.09989;
    param_override.radar.wfs(2).Tsys = params.radar.wfs(2).Tsys;
    param_override.radar.wfs(2).chan_equal_deg = params.radar.wfs(2).chan_equal_deg;
  end
  
elseif 1
  % 2014 low altitude above ground level frames to measure wf 1-wf 2
  % overlap
  if 0
    params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'20140502_01');
    params.cmd.frms = [31 32 33 34]; % frame 31 is mostly too high AGL
  elseif 1
    params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'20140410_01');
    params.cmd.frms = 57;
  elseif 0
    params.cmd.frms = [41];
  end
  params.cmd.generic = true;
  
  if 0
    % Waveform 1 equalization
%     param_override.sar_equal.imgs = {[1 2],[1 3],[1 4],[1 5],[1 6],[1 7],[1 8]};
%     param_override.sar_equal.start_time = struct('name','surface','eval',struct('cmd','s=s-1.5e-6;'));
    param_override.sar_equal.imgs = {[2 2],[2 3],[2 4],[2 5],[2 6],[2 7],[2 8]};
    param_override.sar_equal.imgs = {[3 2],[3 3],[3 4],[3 5],[3 6],[3 7],[3 8]};
    param_override.sar_equal.start_time = struct('name','surface','eval',struct('cmd','s=s+10e-6;'));
    
  elseif 0
    % Waveform 1 to waveform 2
    param_override.sar_equal.imgs = {[2*ones(7,1) (2:8)'],[1*ones(7,1) (2:8)']};
    param_override.sar_equal.start_time = struct('name','surface','eval',struct('cmd','s=s+3e-6;'));
    param_override.sar_equal.delay.ref_bins = [-19 20];
    param_override.sar_equal.delay.search_bins = [-13 14];
    param_override.sar_equal.debug_out_dir = 'sar_equal_wf1';
    param_override.sar_equal.coh_ave = 10;
    
  elseif 1
    % Waveform 2 to waveform 3
    param_override.sar_equal.imgs = {[2*ones(7,1) (2:8)'],[3*ones(7,1) (2:8)']};
    param_override.sar_equal.start_time = struct('name','surface','eval',struct('cmd','s=s+10e-6;'));
    param_override.sar_equal.delay.ref_bins = [-30 31];
    param_override.sar_equal.delay.search_bins = [-24 25];
    param_override.sar_equal.debug_out_dir = 'sar_equal_wf3';
    param_override.sar_equal.coh_ave = 10;
  end
  
  param_override.radar.wfs(1).Tsys = params.radar.wfs(1).Tsys + 5.86577e-09;
  param_override.radar.wfs(1).chan_equal_deg = params.radar.wfs(1).chan_equal_deg + -94.9225;
  param_override.radar.wfs(2).Tsys = params.radar.wfs(2).Tsys;
  param_override.radar.wfs(2).chan_equal_deg = params.radar.wfs(2).chan_equal_deg;
  param_override.radar.wfs(3).Tsys = params.radar.wfs(3).Tsys + 1.16604e-08;
  param_override.radar.wfs(3).chan_equal_deg = params.radar.wfs(3).chan_equal_deg + 52.7387 + -98.5571;
  param_override.sar_equal.sar_load.debug_level = 2;
  
elseif 1
  % 2014 EGIG line
  params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'),'20140410_01');
  
  params.cmd.frms = [57];
  params.cmd.generic = true;
  
  if 0
    % Waveform 1 equalization
    param_override.sar_equal.imgs = {[1 2],[1 3],[1 4],[1 5],[1 6],[1 7],[1 8]};
    param_override.sar_equal.start_times = struct('name','surface','eval',struct('cmd','s=s-1.5e-6;'));
    
  elseif 0
    % Waveform 1 to waveform 2
    % NOT VALID, ALTITUDE AGL IS TOO LARGE
    
  elseif 1
    % Waveform 2 to waveform 3
    param_override.sar_equal.imgs = {[2*ones(7,1) (2:8)'],[3*ones(7,1) (2:8)']};
    param_override.sar_equal.start_time = struct('name','surface','eval',struct('cmd','s=s+10e-6;'));
    param_override.sar_equal.delay.ref_bins = [-30 31];
    param_override.sar_equal.delay.search_bins = [-24 25];
    param_override.sar_equal.debug_out_dir = 'sar_equal_wf3';
    param_override.sar_equal.coh_ave = 1;
  end
  
  param_override.radar.wfs(1).Tsys = params.radar.wfs(1).Tsys + 5.86577e-09;
  param_override.radar.wfs(1).chan_equal_deg = params.radar.wfs(1).chan_equal_deg + -94.9225;
  param_override.radar.wfs(2).Tsys = params.radar.wfs(2).Tsys;
  param_override.radar.wfs(2).chan_equal_deg = params.radar.wfs(2).chan_equal_deg;
  param_override.radar.wfs(3).Tsys = params.radar.wfs(3).Tsys + 1.16604e-08;
  param_override.radar.wfs(3).chan_equal_deg = params.radar.wfs(3).chan_equal_deg + 52.7387 + -98.5571;
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
  %sar_equal(param,param_override);
  sar_equal;
end
