% function collate_gain(param,param_override)
%
% Analyzes waveform results from run_analysis_gain.m. These waveforms
% should be collected with a continuous single frequency constant modulus
% input into the wf-adc receivers of interest. The amplitude should be low
% enough that the receiver does not saturate. The control/gain settings of
% the receiver should follow regular operation typically since the main
% purpose of the script is to measure the receiver gain as a function of
% fast-time.
%
% Debug plots and a gain curve that is usable by data_load.m are generated
% for each wf-adc pair that is specified.
%
% Analysis waveform should be run without pulse compression (i.e.
% param.analysis.pulse_comp = false).
%
% Example:
%
% See run_collate_gain for how to run.
%
% Authors: John Paden, Hara Madhav Talasila

%% General Setup
% =========================================================================

param = merge_structs(param, param_override);
physical_constants;

fprintf('=============================================================\n');
fprintf('%s: %s (%s)\n', param.season_name, param.day_seg, datestr(now));
fprintf('=============================================================\n');

%% Input Checks
% =========================================================================

if ~isfield(param,'collate_gain') || isempty(param.collate_gain)
  param.collate_gain = [];
end

% .debug_out_dir: string containing the output folder name to use for the
% debug outputs. This is input to ct_filename_ct_tmp().
if ~isfield(param.collate_gain,'debug_out_dir') || isempty(param.collate_gain.debug_out_dir)
  param.collate_gain.debug_out_dir = 'collate_gain';
end
debug_out_dir = param.collate_gain.debug_out_dir;

% .debug_out_fn: string containing a word to insert into the output file
% name to identify files for  this specific run.
if ~isfield(param.collate_gain,'debug_out_fn') || isempty(param.collate_gain.debug_out_fn)
  param.collate_gain.debug_out_fn = 'collate_gain';
end

% .debug_plots: cell array of strings containing commands for which debug
% plots to create.
if ~isfield(param.collate_gain,'debug_plots')
  param.collate_gain.debug_plots = {'input_check','gain','combined_plot','visible'};
end
enable_visible_plot = any(strcmp('visible',param.collate_gain.debug_plots));

% .echo_filt_args_coherent: 1x2 vector holding the echo_filt.m filter
% arguments [ROW COL] for filtering the coherent data. Default is [1 101]
% meaning no fast-time coherent averages and 101 along-track averages.
% Coherent averaging is the first operation that is applied and is used to
% reduce the noise.
if ~isfield(param.collate_gain,'echo_filt_args_coherent') || isempty(param.collate_gain.echo_filt_args_coherent)
  param.collate_gain.echo_filt_args_coherent = [1 101];
end

% .echo_filt_args_incoherent: 1x2 vector holding the echo_filt.m filter
% arguments [ROW COL] for filtering the incoherent data. This filter is
% applied after coherent filtering, power detection, and the slow-time
% mean. Default is [5 1] (5 fast-time averages, 1 along-track average).
% Along-track averages have no effect.
if ~isfield(param.collate_gain,'echo_filt_args_incoherent') || isempty(param.collate_gain.echo_filt_args_incoherent)
  param.collate_gain.echo_filt_args_incoherent = [1 1];
end

% .imgs: which images and wf-adc pairs to load for collating. The default
% is to set it equal to the current param.analysis.imgs value.
if ~isfield(param.collate_gain,'imgs') || isempty(param.collate_gain.imgs)
  param.collate_gain.imgs = param.analysis.imgs;
end

% .in_path: argument to ct_filename_out to control which analysis outputs
% the function will try to read in. Default is 'analysis_gain' for
% CSARP_analysis_gain.
if ~isfield(param.collate_gain,'in_path') || isempty(param.collate_gain.in_path)
  param.collate_gain.in_path = 'analysis_gain';
end
wf_dir = fileparts(ct_filename_out(param,param.collate_gain.in_path));

% out_path: string containing the output path for the collate_gain/fast
% time gain results. Passed to ct_filename_out. Default is 'gain' for
% CSARP_gain.
if ~isfield(param.collate_gain,'out_path') || isempty(param.collate_gain.out_path)
  param.collate_gain.out_path = 'gain';
end

%% Debug Figure Setup
% =========================================================================

% Create figure handles
h_fig = get_figures(1,enable_visible_plot);
clf(h_fig(1));
set(h_fig(1),'WindowStyle','docked');

%% wf-adc Loop
% =====================================================================
fig_idx = 0;
all_time = {};
all_wf_dB = {};
all_legend = {};
for img = 1:length(param.collate_gain.imgs)
  for wf_adc = 1:size(param.collate_gain.imgs{img},1)
    % Process one wf-adc pair at a time
    % ---------------------------------------------------------------------
    wf = param.collate_gain.imgs{img}(wf_adc,1);
    adc = param.collate_gain.imgs{img}(wf_adc,2);
    fig_idx = fig_idx +1;
    
    %% wf-adc Loop: Load Waveform File
    % =====================================================================
    gain_wf_data = load(fullfile(wf_dir, sprintf('waveform_%s_wf_%d_adc_%d.mat',param.day_seg,wf,adc)));
    
    time = gain_wf_data.param_analysis.radar.wfs(wf).time_raw;
    gain_wf_data.wf_data = echo_filt(gain_wf_data.wf_data,param.collate_gain.echo_filt_args_coherent);
    mean_wf_raw_dB = 10*log10(mean(abs(gain_wf_data.wf_data).^2,2));
    mean_wf = mean(abs(gain_wf_data.wf_data).^2,2);
    mean_wf = echo_filt(mean_wf,param.collate_gain.echo_filt_args_incoherent);
    mean_wf_dB = 10*log10(mean_wf);
    max_gain_dB = max(mean_wf_dB(isfinite(mean_wf_dB)));
    
    %% wf-adc Loop: Input-Check Plot
    % =====================================================================
    if any(strcmp('input_check',param.collate_gain.debug_plots))
      clf(h_fig(1));
      set(h_fig(1),'Name',sprintf('%d: Data %d-%d',h_fig(1).Number, wf,adc));
      set(h_fig(1),'WindowStyle','docked');
      h_axes = subplot(1,2,1,'parent',h_fig(1));
      imagesc(h_axes(1), [], time*1e6, mean_wf_raw_dB)
      grid(h_axes(1),'on');
      xlabel(h_axes(1),'Range lines');
      ylabel(h_axes(1),'Time ({\mu}s)');
      h_axes(2) = subplot(1,2,2,'parent',h_fig(1));
      plot(h_axes(2), time*1e6, mean_wf_dB, 'LineWidth', 2);
      grid(h_axes(2),'on');
      xlabel(h_axes(2),'Time ({\mu}s)');
      ylabel(h_axes(2),'Normalized power (dB)');
      title(h_axes(2),sprintf('Max gain %.1f dB\n', max_gain_dB));
      legend(h_axes(2), 'Raw');
      if enable_visible_plot
        keyboard;
      end
      fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_input_check_%02d_%02d',param.collate_gain.debug_out_fn,wf,adc)) '.fig'];
      fprintf('Saving %s\n', fig_fn);
      fig_fn_dir = fileparts(fig_fn);
      if ~exist(fig_fn_dir,'dir')
        mkdir(fig_fn_dir);
      end
      ct_saveas(h_fig(1),fig_fn);
      fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_input_check_%02d_%02d',param.collate_gain.debug_out_fn,wf,adc)) '.jpg'];
      fprintf('Saving %s\n', fig_fn);
      ct_saveas(h_fig(1),fig_fn);
    end
    
    %% wf-adc Loop: Process Gain Waveform
    % =====================================================================
    
    % Force relative gain to be constant after user defined end time
    time_end_idx = find(time>=param.collate_gain.time_end{img},1);
    if ~isempty(time_end_idx)
      mean_wf_dB(time_end_idx+1:end) = mean_wf_dB(time_end_idx);
    end
    
    % Force relative gain to be constant after user defined end time
    time_start_idx = find(time<=param.collate_gain.time_start{img},1,'last');
    if ~isempty(time_start_idx)
      mean_wf_dB(1:time_start_idx-1) = mean_wf_dB(time_start_idx);
    end
    
    % Normalize gain to maximum gain
    mean_wf_raw_dB = mean_wf_raw_dB - max_gain_dB;
    mean_wf_dB = mean_wf_dB - max_gain_dB;
    
    % Force relative gain to be no less than user defined minimum relative
    % gain
    mean_wf_dB(mean_wf_dB < param.collate_gain.min_gain_dB{img}) = NaN;
    mean_wf_dB = interp_finite(mean_wf_dB,0);
    
    %% wf-adc Loop: Fast Gain Plot
    % =====================================================================
    if any(strcmp('gain',param.collate_gain.debug_plots))
      plot(h_axes(2), time*1e6, mean_wf_raw_dB, 'LineWidth', 2);
      hold(h_axes(2),'on');
      grid(h_axes(2),'on');
      plot(h_axes(2), time*1e6, mean_wf_dB, 'LineWidth', 2);
      legend(h_axes(2), 'Raw', 'Final');
      if enable_visible_plot
        keyboard;
      end
      fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_%02d_%02d',param.collate_gain.debug_out_fn,wf,adc)) '.fig'];
      fprintf('Saving %s\n', fig_fn);
      fig_fn_dir = fileparts(fig_fn);
      if ~exist(fig_fn_dir,'dir')
        mkdir(fig_fn_dir);
      end
      ct_saveas(h_fig(1),fig_fn);
      fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_%02d_%02d',param.collate_gain.debug_out_fn,wf,adc)) '.jpg'];
      fprintf('Saving %s\n', fig_fn);
      ct_saveas(h_fig(1),fig_fn);
    end
    
    all_time{end+1} = time;
    all_wf_dB{end+1} = mean_wf_dB;
    all_legend{end+1} = sprintf('%d-%d',wf,adc);
    
    %% wf-adc Loop: Save Results
    % =========================================================================
    gain_fn_dir = ct_filename_out(param,param.collate_gain.out_path,'',1);
    if ~exist(gain_fn_dir)
      mkdir(gain_fn_dir);
    end
    gain_fn = fullfile(gain_fn_dir,sprintf('gain_%s_%02d_%02d.mat',param.day_seg,wf,adc));
    gain = [];
    gain.time = time;
    gain.gain = mean_wf_dB;
    gain.param_equal = param;
    gain.in_fn = dir(fn);
    gain.sw_version = current_software_version;
    gain.file_version = '1';
    gain.file_type = 'gain';
    fprintf('Saving %s\n', gain_fn);
    ct_save(gain_fn,'-struct','gain');
  end
end

%% Plot All Waveforms Combined
if any(strcmp('combined_plot',param.collate_gain.debug_plots))
  clf(h_fig(1));
  set(h_fig(1),'visible','on');
  h_axes = axes('parent',h_fig(1));
  for idx = 1:length(all_time)
    plot(h_axes, all_time{idx}*1e6, all_wf_dB{idx});
    hold(h_axes,'on');
  end
  grid(h_axes,'on');
  xlabel(h_axes,'Time ({\mu}s)');
  ylabel(h_axes,'Normalized power (dB)');
  legend(h_axes, all_legend);
  fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_combined',param.collate_gain.debug_out_fn)) '.fig'];
  fprintf('Saving %s\n', fig_fn);
  fig_fn_dir = fileparts(fig_fn);
  if ~exist(fig_fn_dir,'dir')
    mkdir(fig_fn_dir);
  end
  ct_saveas(h_fig(1),fig_fn);
  fig_fn = [ct_filename_ct_tmp(param,'',debug_out_dir,sprintf('%s_combined',param.collate_gain.debug_out_fn)) '.jpg'];
  fprintf('Saving %s\n', fig_fn);
  ct_saveas(h_fig(1),fig_fn);
end
