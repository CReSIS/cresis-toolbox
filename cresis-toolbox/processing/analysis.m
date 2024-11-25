function ctrl_chain = analysis(param,param_override)
% ctrl_chain = analysis(param,param_override)
%
% https://ops.cresis.ku.edu/wiki/index.php/Analysis
%
% param = struct with processing parameters
%         -- OR --
%         function handle to script with processing parameters
% param_override = parameters in this struct will override parameters
%         in param.  This struct must also contain the gRadar fields.
%         Typically global gRadar; param_override = gRadar;
%
% Example:
%  See run_analysis.m for how to run this function directly.
%  Normally this function is called from master.m using the param spreadsheet.
%
% Authors: John Paden
%
% See also: master.m, run_analysis.m analysis.m, analysis_task.m

%% General Setup
% =====================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input Checks: cmd
% =====================================================================

if ~isempty(param.cmd.frms)
  warning('All frames are always processed with analysis, setting param.cmd.frms to do all frames.');
  param.cmd.frms = []; % All frames
end

%% Input Checks: analysis
% =====================================================================

if ~isfield(param,'analysis') || isempty(param.analysis)
  error('The analysis field (worksheet) is missing.');
end

if ~isfield(param.analysis,'block_size') || isempty(param.analysis.block_size)
  param.analysis.block_size = 6000;
end

if ~isfield(param.analysis,'cmd') || isempty(param.analysis.cmd)
  ctrl_chain = {};
  return;
end

if ~isfield(param.analysis,'imgs') || isempty(param.analysis.imgs)
  param.analysis.imgs = {[1 1]};
end

if ~isfield(param.analysis,'out_path') || isempty(param.analysis.out_path)
  param.analysis.out_path = 'analysis';
end

if ~isfield(param.analysis,'presums') || isempty(param.analysis.presums)
  param.analysis.presums = 1;
end

if ~isfield(param.analysis,'resample') || isempty(param.analysis.resample)
  param.analysis.resample = [1 1; 1 1];
end
if ~isequal(param.analysis.resample(2,1:2),[1 1])
  error('The bottom row of param.analysis.resample must be [1 1] because resampling in the along-track is not supported. Use line_rng and dline instead.');
end

if ~isfield(param.analysis,'surf_layer') || isempty(param.analysis.surf_layer)
  param.analysis.surf_layer.name = 'surface';
  param.analysis.surf_layer.source = 'layerdata';
end
% Never check for the existence of files
param.analysis.surf_layer.existence_check = false;

%% Input Checks: analysis.cmd
% =====================================================================
% For each command in the list, set its default settings
enabled_cmds = {};
for cmd_idx = 1:length(param.analysis.cmd)
  cmd = param.analysis.cmd{cmd_idx};
  
  if ~isfield(cmd,'en') || isempty(cmd.en)
    cmd.en = true;
  end
  if ~cmd.en
    continue;
  end
  
  if ~isfield(cmd,'out_path') || isempty(cmd.out_path)
    cmd.out_path = param.analysis.out_path;
  end
  
  if ~isfield(cmd,'wf_adcs') || isempty(cmd.wf_adcs)
    for img = 1:length(param.analysis.imgs)
      % By default do all wf-adc pairs in the image
      cmd.wf_adcs{img} = 1:size(param.analysis.imgs{img},1);
    end
  end
  
  for img = 1:length(param.analysis.imgs)
    if length(cmd.wf_adcs) < length(param.analysis.imgs)
      % By default do all wf-adc pairs in the image
      cmd.wf_adcs{img} = 1:size(param.analysis.imgs{img},1);
    end
  end
  
  if ~isfield(cmd,'start_time') || isempty(cmd.start_time)
    % Set the analysis start time to the beginning of the record
    cmd.start_time = -inf;
  end
  if isstruct(cmd.start_time)
    if ~isfield(cmd.start_time,'name') || isempty(cmd.start_time.name)
      cmd.start_time.name = 'surface';
    end
    if ~isfield(cmd.start_time,'source') || isempty(cmd.start_time.source)
      cmd.start_time.source = 'layerData';
    end
  end
  
  if ~isfield(cmd,'stop_time') || isempty(cmd.stop_time)
    % Set the analysis stop time to the end of the record
    cmd.stop_time = inf;
  end
  if isstruct(cmd.stop_time)
    if ~isfield(cmd.stop_time,'name') || isempty(cmd.stop_time.name)
      cmd.stop_time.name = 'surface';
    end
    if ~isfield(cmd.stop_time,'source') || isempty(cmd.stop_time.source)
      cmd.stop_time.source = 'layerData';
    end
  end
  
  if ~isfield(cmd,'dec') || isempty(cmd.dec)
    % Set the default decimation to none (dec = 1)
    cmd.dec = 1;
  end
  if ~isfield(cmd,'B_filter') || isempty(cmd.B_filter)
    if cmd.dec == 1
      cmd.B_filter = 1;
    else
      cmd.B_filter = boxcar(cmd.dec);
    end
  end
  if ~mod(length(cmd.B_filter),2) && cmd.dec ~= length(cmd.B_filter)
    error('cmd.B_filter must be odd length if cmd.dec ~= length(cmd.B_filter).');
  end
  cmd.B_filter = cmd.B_filter(:).'; % Must be row vector
  if abs(sum(cmd.B_filter)-1) > 1e4*eps
    cmd.B_filter = cmd.B_filter / sum(cmd.B_filter);
  end
        
  if ~isfield(cmd,'trim') || isempty(cmd.trim)
    cmd.trim = [0 0];
  end
        
  if ~isfield(cmd,'num_sam_hint') || isempty(cmd.num_sam_hint)
    cmd.num_sam_hint = [];
  end

  if ~isfield(cmd,'method') || isempty(cmd.method)
    error('cmd.method must be defined in param.analysis.cmd cell array');
  end
  cmd.method = lower(cmd.method);
  switch cmd.method
    case {'burst_noise'}
      % Set defaults for burst noise analysis method
      
      % max_bad_waveforms: wf-adc recorded waveforms/range-lines with burst
      % noise detected are saved, but only up to this many. Set to inf to
      % save all waveforms with burst noise detected.
      if ~isfield(cmd,'max_bad_waveforms') || isempty(cmd.max_bad_waveforms)
        cmd.max_bad_waveforms = 100;
      end
      
      % noise_fh: This function is used to create the temporary variable
      % data_noise in analysis burst. This output is available to test_fh
      % and threshold_fh.
      %
      % Examples:
      %  cmd.noise_fh{img} = @(raw_data,wfs) lp(fir_dec(fir_dec(abs(raw_data.').^2,ones(1,11)/11,1).',ones(1,101)/101,1));
      %  cmd.noise_fh{img} = @(raw_data,wfs) lp(medfilt2(abs(raw_data).^2,[11 101]));
      %  cmd.noise_fh{img} = @(raw_data,wfs) [];
      if ~isfield(cmd,'noise_fh') || isempty(cmd.noise_fh)
        for img = 1:length(param.analysis.imgs)
          cmd.noise_fh{img} = @(raw_data,wfs) lp(fir_dec(fir_dec(abs(raw_data.').^2,ones(1,11)/11,1).',ones(1,101)/101,1));
        end
      end
      
      % signal_fh: This function is used to create the temporary variable
      % data_signal in analysis burst. This output is available to test_fh
      % and threshold_fh.
      %
      % Examples:
      %  cmd.signal_fh{img} = @(raw_data,wfs) lp(fir_dec(abs(raw_data.').^2,ones(1,11)/11,1).');
      %  cmd.signal_fh{img} = @(raw_data,wfs) lp(abs(raw_data).^2,1));
      %  cmd.signal_fh{img} = @(raw_data,wfs) lp(abs(fft(raw_data(300:end,:))).^2);
      %  cmd.signal_fh{img} = @(raw_data,wfs) [];
      if ~isfield(cmd,'signal_fh') || isempty(cmd.signal_fh)
        for img = 1:length(param.analysis.imgs)
          cmd.signal_fh{img} = @(raw_data,wfs) lp(fir_dec(abs(raw_data.').^2,ones(1,11)/11,1).');
        end
      end

      % test_fh: This function is used to create the output variable
      % test_metric in analysis burst. This output is available to
      % threshold_fh and is also stored in the output file.
      %
      % Examples:
      %  cmd.test_fh{img} = @(data_signal,data_noise,wfs) max(data_signal-data_noise,[],1);
      %  cmd.test_fh{img} = @(data_signal,data_noise,wfs) data_signal-data_noise;
      %  cmd.test_fh{img} = @(data_signal,data_noise,wfs)% max(data_signal(10:end-9,:))-median(data_signal(10:end-9,:));
      %  cmd.test_fh{img} = @(raw_data,wfs) [];
      if ~isfield(cmd,'test_fh') || isempty(cmd.test_fh)
        for img = 1:length(param.analysis.imgs)
          cmd.test_fh{img} = @(data_signal,data_noise,wfs) max(data_signal-data_noise,[],1);
        end
      end

      % test_fh: This function is used to create the temporary variable
      % bad_samples in analysis burst. If the output is a row vector, then
      % it is assumed to be a mask of the bad records (interpretation is
      % that the entire record is bad). If the output is a matrix, then it
      % is assumed to be a mask of the bad samples (interpretation is that
      % just those samples are bad and not the whole record).
      %
      % Examples:
      %  cmd.threshold_fh{img} = @(data_signal,data_noise,test_metric,wfs) data_noise > 80;
      %  cmd.threshold_fh{img} = @(data_signal,data_noise,test_metric,wfs) test_metric > 20;
      %  cmd.threshold_fh{img} = @(data_signal,data_noise,test_metric,wfs) repmat(data_signal-data_noise > 20,[wfs.Nt_raw 1]);
      %  cmd.threshold_fh{img} = @(data_signal,data_noise,test_metric,wfs) max(data_signal(10:end-9,:))-median(data_signal(10:end-9,:));
      if ~isfield(cmd,'threshold_fh') || isempty(cmd.threshold_fh)
        for img = 1:length(param.analysis.imgs)
          cmd.threshold_fh{img} = @(data_signal,data_noise,test_metric,wfs) test_metric > 20;
        end
      end
      
      % valid_bins: Restricts the range of bins where burst detections are
      % allowed to occur. The default is [1 inf] which allows burst
      % detections anywhere in the range line. Typical usage would be to
      % exclude the feedthrough or nadir surface signal that may be large
      % and variable and lead to false alarms if it is nonstationary.
      if ~isfield(cmd,'valid_bins') || isempty(cmd.valid_bins)
        cmd.valid_bins = {};
        for img = 1:length(param.analysis.imgs)
          cmd.valid_bins{img} = [1 inf];
        end
      end

    case {'coh_noise'}
      % Set defaults for coherent noise analysis method
      
      if ~isfield(cmd,'block_ave') || isempty(cmd.block_ave)
        cmd.block_ave = 2000;
      end
      if mod(param.analysis.block_size,cmd.block_ave)
        error('The param.analysis.block_size (%d) must be a multiple of cmd.block_ave (%d).', ...
          param.analysis.block_size, cmd.block_ave);
      end
      
      % distance_weight: default is false; if true, then the coherent
      % averaging is weighted by the distance travelled. This is primarily
      % useful for ground based traverses where long stops can bias the
      % coherent noise estimate. Setting this to true will reduce the
      % affect the long stops have on the estimated coherent noise mean.
      if ~isfield(cmd,'distance_weight') || isempty(cmd.distance_weight)
        cmd.distance_weight = false;
      end
      
      if ~isfield(cmd,'mag_en') || isempty(cmd.mag_en)
        % Default is to collect magnitude sums (coh_ave_mag) in addition to
        % phase-coherent sums (coh_ave)
        cmd.mag_en = true;
      end
      
      if ~isfield(cmd,'pulse_comp') || isempty(cmd.pulse_comp)
        cmd.pulse_comp = true;
      end
      
      if ~isfield(cmd,'threshold')
        cmd.threshold = [];
      end
      if isempty(cmd.threshold)
        if ischar(cmd.threshold)
          % Set the default file path to CSARP_analysis
          cmd.threshold = 'analysis';
        else
          % Set the default power_threshold to inf (i.e. no thresholding)
          cmd.threshold = inf;
        end
      end
      
      if ~isfield(cmd,'threshold_coh_ave')
        cmd.threshold_coh_ave = 1;
      elseif mod(cmd.threshold_coh_ave-1,2)
        error('param.analysis.cmd{%d}.threshold_coh_ave must be odd; currently %g.', cmd_idx, cmd.threshold_coh_ave);
      end
      
      if ~isfield(cmd,'threshold_removeDC') || isempty(cmd.threshold_removeDC)
        % Default is to not remove slow-time DC before determining good
        % samples to use in coh_ave and coh_ave_mag
        cmd.threshold_removeDC = false;
      end
      
    case {'qlook'}
      %
    case {'saturation'}
      %
    case {'specular'}
      % Set defaults for specular analysis method
      
      % cmd.gps_times: vector of GPS times in ANSI C format (seconds since
      % Jan 1, 1970) for which the STFT block will automatically have its
      % waveform extracted even if the cmd.threshold is not exceeded.
      if ~isfield(cmd,'gps_times') || isempty(cmd.gps_times)
        cmd.gps_times = [];
      end
      
      % cmd.max_rlines: maximum number of STFT waveforms to extract (so
      % even if there are more than cmd.max_rlines blocks which detect a
      % coherent/specular scatterer only the first cmd.max_rlines will be
      % extracted for deconvolution)
      if ~isfield(cmd,'max_rlines') || isempty(cmd.max_rlines)
        cmd.max_rlines = 10;
      end
      
      % cmd.rlines: STFT block size, the data are broken into 50%
      % overlapping blocks of this length to detect coherent/specular
      % scatterers using a short time Fourier transform
      if ~isfield(cmd,'rlines') || isempty(cmd.rlines)
        cmd.rlines = 128;
      end
      
      % cmd.noise_doppler_bins: bins of STFT to use for clutter power
      % detection
      guard = round(cmd.rlines/32);
      if ~isfield(cmd,'noise_doppler_bins') || isempty(cmd.noise_doppler_bins)
        cmd.noise_doppler_bins = [1+3*guard:cmd.rlines-3*guard];
      end
      
      % cmd.signal_doppler_bins: bins of STFT to use for signal power
      % estimation
      if ~isfield(cmd,'signal_doppler_bins') || isempty(cmd.signal_doppler_bins)
        cmd.signal_doppler_bins = [1:guard cmd.rlines+(-guard+1:0)];
      end
      
      % cmd.threshold: peakiness threshold to decide whether or not to
      % extract the waveform from a particular STFT block. This is in dB
      % and is the ratio (peak signal to mean noise/clutter power):
      % peakiness = lp(max(abs(H(cmd.signal_doppler_bins,:)).^2) ./ mean(abs(H(cmd.noise_doppler_bins,:)).^2));
      if ~isfield(cmd,'threshold') || isempty(cmd.threshold)
        cmd.threshold = 40;
      end
      
      % cmd.peak_sgolay_filt: cell array with 2 elements containing the
      % 2nd and 3rd input arguments to sgolayfilt that is used to filter
      % the peak values in the along-track dimension. This ensures that the
      % frame size to sgolayfilt.m is odd and is approximately 40% of the
      % length of the cmd.rlines.
      if ~isfield(cmd,'peak_sgolay_filt') || isempty(cmd.peak_sgolay_filt)
        cmd.peak_sgolay_filt = {3,round(0.2*cmd.rlines)*2+1};
      end
      if length(cmd.peak_sgolay_filt) < 2
        cmd.peak_sgolay_filt{2} = round(0.2*cmd.rlines)*2+1;
      end
      if ~mod(cmd.peak_sgolay_filt{2},2)
        cmd.peak_sgolay_filt{2} = cmd.peak_sgolay_filt{2}+1;
      end
      
    case {'statistics'}
      % Set defaults for statistical analysis method
      
      if ~isfield(cmd,'block_ave') || isempty(cmd.block_ave)
        cmd.block_ave = 2000;
      end
      
      if ~isfield(cmd,'combine_rx') || isempty(cmd.combine_rx)
        cmd.combine_rx = false;
      end
      
      if ~isfield(cmd,'motion_comp') || isempty(cmd.motion_comp)
        if cmd.combine_rx
          cmd.motion_comp = true;
        else
          cmd.motion_comp = false;
        end
      end
      
      if ~isfield(cmd,'pulse_comp') || isempty(cmd.pulse_comp)
        cmd.pulse_comp = false;
      end
      
      if ~isfield(cmd,'stats') || isempty(cmd.stats)
        error('The statistical command requires that the stats field be set.');
      end
      
    case {'waveform'}
      
      if ~isfield(cmd,'combine_rx') || isempty(cmd.combine_rx)
        cmd.combine_rx = false;
      end
      
      if ~isfield(cmd,'motion_comp') || isempty(cmd.motion_comp)
        if cmd.combine_rx
          cmd.motion_comp = true;
        else
          cmd.motion_comp = false;
        end
      end
      
      if ~isfield(cmd,'Nt') || isempty(cmd.Nt)
        error('The statistical command requires that the Nt field be set.');
      end
      
      if ~isfield(cmd,'pulse_comp') || isempty(cmd.pulse_comp)
        cmd.pulse_comp = true;
      end
      
      if ~isfield(cmd,'start_time') || isempty(cmd.start_time)
        error('The statistical command requires that the start_time field be set.');
      end

  end
  
  % Update the command structure
  param.analysis.cmd{cmd_idx} = cmd;
  enabled_cmds{end+1} = cmd.method;
end

if isempty(enabled_cmds)
  ctrl_chain = {};
  return;
end

if ~isfield(param.analysis,'bit_mask') || isempty(param.analysis.bit_mask)
  % Set to 3 to mask out stationary and bad records (useful for coherent noise estimation on ground based data that may have stationary records)
  if all(strcmp('coh_noise',enabled_cmds))
    % Remove bad records (bit_mask==1), remove stationary records
    % (bit_mask==2), and remove bad records (bit_mask==4)
    param.analysis.bit_mask = 1 + 2 + 4;
  elseif all(strcmp('burst_noise',enabled_cmds))
    % Remove bad records (bit_mask==1), leave stationary records
    % (bit_mask==2), and leave bad records (bit_mask==4)
    param.analysis.bit_mask = 1;
  else
    % Remove bad records (bit_mask==1), leave stationary records
    % (bit_mask==2), and remove bad records (bit_mask==4)
    param.analysis.bit_mask = 1 + 4;
  end
end

%% Setup processing
% =====================================================================

% Get the standard radar name
[~,~,radar_name] = ct_output_dir(param.radar_name);

% Load records file
records = records_load(param);
% Apply presumming
if param.analysis.presums > 1
  records.lat = fir_dec(records.lat,param.analysis.presums);
  records.lon = fir_dec(records.lon,param.analysis.presums);
  records.elev = fir_dec(records.elev,param.analysis.presums);
  records.roll = fir_dec(records.roll,param.analysis.presums);
  records.pitch = fir_dec(records.pitch,param.analysis.presums);
  records.heading = fir_dec(records.heading,param.analysis.presums);
  records.gps_time = fir_dec(records.gps_time,param.analysis.presums);
end

% Compute all estimates with pulse compressed numbers even though raw data
% are loaded
param.analysis.pulse_comp = true;
param.analysis.ft_wind = [];

%% Setup cluster
% =====================================================================
ctrl = cluster_new_batch(param);
cluster_compile({'analysis_task.m','analysis_combine_task.m'},ctrl.cluster.hidden_depend_funs,ctrl.cluster.force_compile,ctrl);

[wfs,~] = data_load_wfs(setfield(param,'load',struct('imgs',{param.analysis.imgs})),records);
if any(strcmpi(radar_name,{'acords','hfrds','hfrds2','mcords','mcords2','mcords3','mcords4','mcords5','mcords6','mcrds','rds','seaice','accum2','accum3'}))
  for img = 1:length(param.analysis.imgs)
    wf = abs(param.analysis.imgs{img}(1,1));
    total_num_sam(img) = wfs(wf).Nt_raw;
  end
  cpu_time_mult = 35e-9;
  mem_mult = 11;
  
elseif any(strcmpi(radar_name,{'snow','kuband','snow2','kuband2','snow3','kuband3','kaband','kaband3','snow5','snow8'}))
  total_num_sam = 32000 * ones(size(param.analysis.imgs));
  cpu_time_mult = 4e-8;
  mem_mult = 17;
  
elseif strcmpi(radar_name,'snow9')
  total_num_sam = 45000 * ones(size(param.analysis.imgs));
  cpu_time_mult = 4e-8;
  mem_mult = 17;
  
else
  error('radar_name %s not supported yet.', radar_name);
  
end

ctrl_chain = {};

%% Combine: Success criteria
combine_file_success = {};
for img = 1:length(param.analysis.imgs)
  for cmd_idx = 1:length(param.analysis.cmd)
    cmd = param.analysis.cmd{cmd_idx};
    if ~cmd.en
      continue;
    end
    
    % Create combine file output directory string
    out_fn_dir = ct_filename_out(param,cmd.out_path);
    out_segment_fn_dir = fileparts(out_fn_dir);
      
    switch cmd.method
      case {'burst_noise'}
        for wf_adc = param.analysis.cmd{cmd_idx}.wf_adcs{img}(:).'
          wf = param.analysis.imgs{img}(wf_adc,1);
          adc = param.analysis.imgs{img}(wf_adc,2);
          out_fn = fullfile(out_segment_fn_dir,sprintf('burst_noise_%s_wf_%d_adc_%d.mat',param.day_seg,wf,adc));
          combine_file_success{end+1} = out_fn;
          if ~ctrl.cluster.rerun_only && exist(out_fn,'file')
            ct_file_lock_check(out_fn,3);
          end
        end
        
      case {'coh_noise'}
        for wf_adc = param.analysis.cmd{cmd_idx}.wf_adcs{img}(:).'
          wf = param.analysis.imgs{img}(wf_adc,1);
          adc = param.analysis.imgs{img}(wf_adc,2);
          out_fn = fullfile(out_segment_fn_dir,sprintf('coh_noise_%s_wf_%d_adc_%d.mat',param.day_seg,wf,adc));
          combine_file_success{end+1} = out_fn;
          if ~ctrl.cluster.rerun_only && exist(out_fn,'file')
            ct_file_lock_check(out_fn,3);
          end
        end
        
      case {'qlook'}
        %
        
      case {'saturation'}
        %
        
      case {'specular'}
        for wf_adc = param.analysis.cmd{cmd_idx}.wf_adcs{img}(:).'
          wf = param.analysis.imgs{img}(wf_adc,1);
          adc = param.analysis.imgs{img}(wf_adc,2);
          out_fn = fullfile(out_segment_fn_dir,sprintf('specular_%s_wf_%d_adc_%d.mat',param.day_seg,wf,adc));
          combine_file_success{end+1} = out_fn;
          if ~ctrl.cluster.rerun_only && exist(out_fn,'file')
            ct_file_lock_check(out_fn,3);
          end
        end
        
      case {'statistics'}
        for wf_adc = param.analysis.cmd{cmd_idx}.wf_adcs{img}(:).'
          wf = param.analysis.imgs{img}(wf_adc,1);
          adc = param.analysis.imgs{img}(wf_adc,2);
          out_fn = fullfile(out_segment_fn_dir,sprintf('stats_%s_wf_%d_adc_%d.mat',param.day_seg,wf,adc));
          combine_file_success{end+1} = out_fn;
          if ~ctrl.cluster.rerun_only && exist(out_fn,'file')
            ct_file_lock_check(out_fn,3);
          end
        end
        
      case {'waveform'}
        for wf_adc = param.analysis.cmd{cmd_idx}.wf_adcs{img}(:).'
          wf = param.analysis.imgs{img}(wf_adc,1);
          adc = param.analysis.imgs{img}(wf_adc,2);
          out_fn = fullfile(out_segment_fn_dir,sprintf('waveform_%s_wf_%d_adc_%d.mat',param.day_seg,wf,adc));
          combine_file_success{end+1} = out_fn;
          if ~ctrl.cluster.rerun_only && exist(out_fn,'file')
            ct_file_lock_check(out_fn,3);
          end
        end
        
    end
  end
end
combine_file_success_failed = cluster_file_success(combine_file_success);

if ctrl.cluster.rerun_only && ~combine_file_success_failed
  fprintf('  Combine files already exist [rerun_only skipping segment]: %s (%s)\n', ...
    param.day_seg, datestr(now));
  fprintf('Done %s\n', datestr(now));
  return;
end

%% Block: Create tasks
% =====================================================================
% Load param.analysis.block_size records at a time
%    --> The last block can be up to 1.5*param.analysis.block_size
out_recs = {};
retry_fields = {};

% Break records in segment into blocks
breaks = 1:param.analysis.block_size:length(records.gps_time);

% If the last block is less than half the desired block size, then combine
% with earlier block if possible
if length(records.gps_time)-breaks(end) < param.analysis.block_size/2 ...
    && length(breaks) > 1
  breaks = breaks(1:end-1);
end

sparam.argsin{1} = param; % Static parameters
sparam.task_function = 'analysis_task';
sparam.num_args_out = 1;
sparam.argsin{1}.load.imgs = param.analysis.imgs;
for break_idx = 1:length(breaks)
  % Determine the start/stop record for this block
  rec_load_start = breaks(break_idx);
  if break_idx == length(breaks)
    rec_load_stop = length(records.gps_time);
  else
    rec_load_stop = rec_load_start+param.analysis.block_size-1;
  end
  cur_recs = [rec_load_start rec_load_stop];
  actual_cur_recs = [(cur_recs(1)-1)*param.analysis.presums+1, ...
    cur_recs(end)*param.analysis.presums];
  
  % Prepare task inputs
  % =================================================================
  dparam = [];
  dparam.argsin{1}.load.recs = cur_recs;
  
  % Create success condition and set cpu_time, mem requirements
  % =================================================================
  Nx = cur_recs(end)-cur_recs(1)+1;
  dparam.cpu_time = 0;
  dparam.mem = 0;
  dparam.file_success = {};
  success_error = 64;
  % Loading in the data: cpu_time and mem
  dparam.mem = 500e6;
  for img = 1:length(param.analysis.imgs)
    dparam.cpu_time = dparam.cpu_time + 10 + size(param.analysis.imgs{img},1)*Nx*total_num_sam(img)*log2(Nx)*cpu_time_mult;
    dparam.mem = dparam.mem + size(param.analysis.imgs{img},1)*Nx*total_num_sam(img)*mem_mult;
  end
  data_load_memory = dparam.mem;
  cmd_method_str = ''; % Used to store the first valid method for dparam.notes
  % Processing the data
  for img = 1:length(param.analysis.imgs)
    for cmd_idx = 1:length(param.analysis.cmd)
      cmd = param.analysis.cmd{cmd_idx}; % cmd: current command
      if ~cmd.en
        continue;
      end
      
      % Create temporary output directory string
      tmp_out_fn_dir = ct_filename_out(param,cmd.out_path,'analysis_tmp');
      
      % Load data
      dparam.cpu_time = dparam.cpu_time + 10 + param.analysis.presums*size(param.analysis.imgs{img},1)*Nx*total_num_sam(img)*log2(total_num_sam(img))*cpu_time_mult;

      % Process commands
      switch cmd.method
        case {'burst_noise'}
          for wf_adc = param.analysis.cmd{cmd_idx}.wf_adcs{img}(:).'
            wf = param.analysis.imgs{img}(wf_adc,1);
            adc = param.analysis.imgs{img}(wf_adc,2);
            out_fn = fullfile(tmp_out_fn_dir,sprintf('burst_noise_wf_%d_adc_%d_%d_%d.mat',wf,adc,actual_cur_recs));
            dparam.file_success{end+1} = out_fn;
            if ~ctrl.cluster.rerun_only && exist(out_fn,'file')
              delete(out_fn);
            end
            dparam.cpu_time = dparam.cpu_time + 10 + Nx*total_num_sam(img)*log2(Nx)*cpu_time_mult;
            dparam.mem = max(dparam.mem,data_load_memory + Nx*total_num_sam(img)*mem_mult);
            if isempty(cmd_method_str)
              cmd_method_str = '_burst_noise';
            end
          end

        case {'coh_noise'}
          for wf_adc = param.analysis.cmd{cmd_idx}.wf_adcs{img}(:).'
            wf = param.analysis.imgs{img}(wf_adc,1);
            adc = param.analysis.imgs{img}(wf_adc,2);
            out_fn = fullfile(tmp_out_fn_dir,sprintf('coh_noise_wf_%d_adc_%d_%d_%d.mat',wf,adc,actual_cur_recs));
            dparam.file_success{end+1} = out_fn;
            if ~ctrl.cluster.rerun_only && exist(out_fn,'file')
              delete(out_fn);
            end
            dparam.cpu_time = dparam.cpu_time + 10 + Nx*total_num_sam(img)*log2(Nx)*cpu_time_mult;
            dparam.mem = max(dparam.mem,data_load_memory + Nx*total_num_sam(img)*mem_mult);
            if isempty(cmd_method_str)
              cmd_method_str = '_coh_noise';
            end
          end
          
        case {'qlook'}
          %
          
        case {'saturation'}
          %
          
        case {'specular'}
          for wf_adc = param.analysis.cmd{cmd_idx}.wf_adcs{img}(:).'
            wf = param.analysis.imgs{img}(wf_adc,1);
            adc = param.analysis.imgs{img}(wf_adc,2);
            out_fn = fullfile(tmp_out_fn_dir,sprintf('specular_wf_%d_adc_%d_%d_%d.mat',wf,adc,actual_cur_recs));
            dparam.file_success{end+1} = out_fn;
            if ~ctrl.cluster.rerun_only && exist(out_fn,'file')
              delete(out_fn);
            end
            dparam.cpu_time = dparam.cpu_time + 10 + Nx*total_num_sam(img)*log2(total_num_sam(img))*cpu_time_mult;
            if strcmp(param.radar.wfs(wf).coh_noise_method,'analysis')
              dparam.mem = max(dparam.mem,data_load_memory + Nx*total_num_sam(img)*(mem_mult+20));
            else
              dparam.mem = max(dparam.mem,data_load_memory + Nx*total_num_sam(img)*mem_mult);
            end
            if isempty(cmd_method_str)
              cmd_method_str = '_specular';
            end
          end
          
        case {'statistics'}
          for wf_adc = param.analysis.cmd{cmd_idx}.wf_adcs{img}(:).'
            wf = param.analysis.imgs{img}(wf_adc,1);
            adc = param.analysis.imgs{img}(wf_adc,2);
            out_fn = fullfile(tmp_out_fn_dir,sprintf('stats_wf_%d_adc_%d_%d_%d.mat',wf,adc,actual_cur_recs));
            dparam.file_success{end+1} = out_fn;
            if ~ctrl.cluster.rerun_only && exist(out_fn,'file')
              delete(out_fn);
            end
            if isfield(param.radar.wfs(wf),'coh_noise_method') && strcmpi(param.radar.wfs(wf).coh_noise_method,'analysis')
              dparam.cpu_time = dparam.cpu_time + 10 + 2*Nx*total_num_sam(img)*log2(Nx)*cpu_time_mult;
              dparam.mem = max(dparam.mem,data_load_memory + 2*Nx*total_num_sam(img)*mem_mult);
            else
              dparam.cpu_time = dparam.cpu_time + 10 + Nx*total_num_sam(img)*log2(Nx)*cpu_time_mult;
              dparam.mem = max(dparam.mem,data_load_memory + Nx*total_num_sam(img)*mem_mult);
            end
            if isempty(cmd_method_str)
              cmd_method_str = '_stats';
            end
          end
          
        case {'waveform'}
          for wf_adc = param.analysis.cmd{cmd_idx}.wf_adcs{img}(:).'
            wf = param.analysis.imgs{img}(wf_adc,1);
            adc = param.analysis.imgs{img}(wf_adc,2);
            out_fn = fullfile(tmp_out_fn_dir,sprintf('waveform_wf_%d_adc_%d_%d_%d.mat',wf,adc,actual_cur_recs));
            dparam.file_success{end+1} = out_fn;
            if ~ctrl.cluster.rerun_only && exist(out_fn,'file')
              delete(out_fn);
            end
            if isfield(param.radar.wfs(wf),'coh_noise_method') && strcmpi(param.radar.wfs(wf).coh_noise_method,'analysis')
              dparam.cpu_time = dparam.cpu_time + 10 + 2*Nx*total_num_sam(img)*log2(total_num_sam(img))*cpu_time_mult;
              dparam.mem = max(dparam.mem,data_load_memory + 2*Nx*total_num_sam(img)*mem_mult);
            else
              dparam.cpu_time = dparam.cpu_time + 10 + Nx*total_num_sam(img)*log2(total_num_sam(img))*cpu_time_mult;
              dparam.mem = max(dparam.mem,data_load_memory + Nx*total_num_sam(img)*mem_mult);
            end
            if isempty(cmd_method_str)
              cmd_method_str = '_waveform';
            end
          end
          
      end
    end
  end
  
  % Rerun only mode: Test to see if we need to run this task
  % =================================================================
  dparam.notes = sprintf('%s%s %s:%s:%s %s %d of %d recs %d-%d', ...
    mfilename, cmd_method_str, param.analysis.cmd{1}.out_path, param.radar_name, param.season_name, param.day_seg, ...
    break_idx, length(breaks), actual_cur_recs);
  if ctrl.cluster.rerun_only
    % If we are in rerun only mode AND the analysis task file success
    % condition passes without error then we do not run the task.
    if ~cluster_file_success(dparam.file_success)
      fprintf('  Already exists [rerun_only skipping]: %s (%s)\n', ...
        dparam.notes, datestr(now));
      continue;
    end
  end
  
  % Create task
  % =================================================================
  ctrl = cluster_new_task(ctrl,sparam,dparam,'dparam_save',0);
  
end

ctrl = cluster_save_dparam(ctrl);

ctrl_chain{end+1} = ctrl;

%% Combine: Create combine task
% =====================================================================
ctrl = cluster_new_batch(param);

if any(strcmpi(radar_name,{'acords','hfrds','hfrds2','mcords','mcords2','mcords3','mcords4','mcords5','mcords6','mcrds','rds','seaice','accum2','accum3'}))
  cpu_time_mult = 6e-6;
  mem_mult = 8;
  
elseif any(strcmpi(radar_name,{'snow','kuband','snow2','kuband2','snow3','kuband3','kaband','kaband3','snow5','snow8'}))
  cpu_time_mult = 2.6e-7;
  mem_mult = 32;
end

% Create success condition
success_error = 64;
sparam = [];
sparam.success = '';
sparam.argsin{1} = param; % Static parameters
sparam.task_function = 'analysis_combine_task';
sparam.num_args_out = 1;
sparam.cpu_time = 60;
sparam.mem = 0;
% Add up all records being processed and find the most records in a block
Nx = length(records.gps_time);
records_var = whos('records');
for img = 1:length(param.analysis.imgs)
  Nt = total_num_sam(img);
  
  for cmd_idx = 1:length(param.analysis.cmd)
    cmd = param.analysis.cmd{cmd_idx};
    if ~cmd.en
      continue;
    end
    
    num_sam_hint = total_num_sam(img);
    if ~isempty(cmd.num_sam_hint)
      if ~iscell(cmd.num_sam_hint)
        num_sam_hint = cmd.num_sam_hint;
      else
        num_sam_hint = cmd.num_sam_hint{img};
      end
    end
  
    switch cmd.method
      case {'burst_noise'}
        for wf_adc = param.analysis.cmd{cmd_idx}.wf_adcs{img}(:).'
          num_sam_hint = 1;
          sparam.cpu_time = sparam.cpu_time + Nx*num_sam_hint*log2(Nx)*cpu_time_mult;
          sparam.mem = max(sparam.mem,500e6 + records_var.bytes + Nx*num_sam_hint*mem_mult);
        end
        
      case {'coh_noise'}
        Nx_cmd = Nx / cmd.block_ave;
        for wf_adc = param.analysis.cmd{cmd_idx}.wf_adcs{img}(:).'
          sparam.cpu_time = sparam.cpu_time + Nx_cmd*num_sam_hint*log2(Nx_cmd)*cpu_time_mult;
          sparam.mem = max(sparam.mem,500e6 + records_var.bytes + Nx_cmd*num_sam_hint*mem_mult);
        end
        
      case {'qlook'}
        %
        
      case {'saturation'}
        %
        
      case {'specular'}
        Nx_cmd = Nx / param.analysis.block_size * cmd.max_rlines;
        for wf_adc = param.analysis.cmd{cmd_idx}.wf_adcs{img}(:).'
          sparam.cpu_time = sparam.cpu_time + Nx_cmd*num_sam_hint*log2(Nx_cmd)*cpu_time_mult;
          sparam.mem = max(sparam.mem,500e6 + records_var.bytes + Nx_cmd*num_sam_hint*mem_mult*1.5);
        end
        
      case {'statistics'}
        Nx_cmd = Nx / cmd.block_ave;
        for wf_adc = param.analysis.cmd{cmd_idx}.wf_adcs{img}(:).'
          sparam.cpu_time = sparam.cpu_time + Nx_cmd*num_sam_hint*log2(Nx_cmd)*cpu_time_mult;
          sparam.mem = max(sparam.mem,500e6 + records_var.bytes + Nx_cmd*num_sam_hint*mem_mult);
        end
        
      case {'waveform'}
        Nx_cmd = Nx / cmd.dec;
        if isfinite(cmd.Nt)
          Nt = cmd.Nt;
        else
          Nt = num_sam_hint;
        end
        for wf_adc = param.analysis.cmd{cmd_idx}.wf_adcs{img}(:).'
          sparam.cpu_time = sparam.cpu_time + Nx_cmd*Nt*log2(Nx_cmd)*cpu_time_mult;
          sparam.mem = max(sparam.mem,500e6 + records_var.bytes + Nx_cmd*Nt*mem_mult);
        end
        
    end
  end
end
sparam.file_success = combine_file_success;
sparam.notes = sprintf('%s %s:%s:%s %s combine', ...
  mfilename, param.analysis.cmd{1}.out_path, param.radar_name, param.season_name, param.day_seg);

ctrl = cluster_new_task(ctrl,sparam,[]);

ctrl_chain{end+1} = ctrl;
    
fprintf('Done %s\n', datestr(now));
