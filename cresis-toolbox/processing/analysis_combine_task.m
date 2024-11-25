function [success] = analysis_combine_task(param)
% [success] = analysis_combine_task(param)
%
% Cluster task for combining results from analysis.
%
% param: struct controlling the processing
%
% success = boolean which is true when the function executes properly
%   if a task fails before it can return success, then success will be
%   empty
%
% Author: John Paden
%
% See also analysis.m

%% Setup

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
  records.surface = fir_dec(records.surface,param.analysis.presums);
end

[~,~,radar_name] = ct_output_dir(param.radar_name);

% Break records in segment into blocks
blocks = 1:param.analysis.block_size:length(records.gps_time);

% If the last block is less than half the desired block size, then combine
% with earlier block if possible
if length(records.gps_time)-blocks(end) < param.analysis.block_size/2 ...
    && length(blocks) > 1
  blocks = blocks(1:end-1);
end

%% Loop through all commands
for cmd_idx = 1:length(param.analysis.cmd)
  cmd = param.analysis.cmd{cmd_idx};
  if ~cmd.en
    continue;
  end
  
  % Create temporary output directory string
  tmp_out_fn_dir = ct_filename_out(param, cmd.out_path, 'analysis_tmp');
  % Create combined output directory
  out_fn_dir = ct_filename_out(param, cmd.out_path);
  out_segment_fn_dir = fileparts(out_fn_dir);
  if ~exist(out_segment_fn_dir,'dir')
    mkdir(out_segment_fn_dir);
  end

  if strcmpi(cmd.method,{'saturation'})
    %% Saturation
    % ===================================================================
    % ===================================================================
    
    for img = 1:length(param.analysis.imgs)
      max_rline = [];
      max_waveform = [];
      gps_time = [];
      max_val_gps_time = [];
      max_val_gps_time_adc = [];
      
      for block_idx = 1:length(blocks)
        rec_load_start = blocks(block_idx);
        
        if block_idx == length(blocks)
          rec_load_stop = length(records.gps_time);
        else
          rec_load_stop = rec_load_start+param.analysis.block_size-1;
        end
        
        cur_recs = [rec_load_start rec_load_stop];
        actual_cur_recs = [(cur_recs(1)-1)*param.analysis.presums+1, ...
          cur_recs(end)*param.analysis.presums];
        
        out_fn = fullfile(tmp_out_fn_dir, ...
          sprintf('saturation_wf_%d_adc_%d_%d_%d.mat',wf,adc,actual_cur_recs));
        
        satur = load(out_fn);
        
        max_rline = cat(2,max_rline,satur.max_rline);
        max_waveform = cat(2,max_waveform,satur.max_waveform);
        gps_time = cat(2,gps_time,satur.gps_time);
        max_val_gps_time = cat(2,max_val_gps_time,satur.max_val_gps_time);
        if isinteger(satur.max_val_gps_time)
          max_val_gps_time_adc = cat(2,max_val_gps_time_adc,satur.max_val_gps_time_adc);
        end
        
        satur.max_rline = max_rline;
        satur.max_waveform = max_waveform;
        satur.gps_time = gps_time;
        satur.max_val_gps_time = max_val_gps_time;
        satur.max_val_gps_time_adc = max_val_gps_time_adc;
        if param.ct_file_lock
          satur.file_version = '1L';
        else
          satur.file_version = '1';
        end
        satur.file_type = 'analysis_saturation';
        
        out_segment_fn = fullfile(out_segment_fn_dir,sprintf('saturation_%s_img_%02d.mat', param.day_seg, img));
        fprintf('Saving output %s (%s)\n', out_segment_fn, datestr(now));
        ct_save(out_segment_fn,'-struct','satur');
      end
    end
    
    
  elseif strcmpi(cmd.method,{'specular'})
    %% Specular
    % ===================================================================
    % ===================================================================
    for img = 1:length(param.analysis.imgs)
      for wf_adc = 1:size(param.analysis.imgs{img},1)
        wf = param.analysis.imgs{img}(wf_adc,1);
        adc = param.analysis.imgs{img}(wf_adc,2);
        
        spec = [];
        spec.deconv_fc = [];
        spec.deconv_t0 = [];
        spec.dt = NaN;
        spec.deconv_gps_time = [];
        spec.deconv_mean = {};
        spec.deconv_std = {};
        spec.deconv_sample = {};
        spec.deconv_twtt = [];
        spec.deconv_forced = [];
        spec.gps_time = [];
        spec.lat = [];
        spec.lon = [];
        spec.elev = [];
        spec.roll = [];
        spec.pitch = [];
        spec.heading = [];
        spec.surface = [];
        spec.peakiness = [];
        for block_idx = 1:length(blocks)
          rec_load_start = blocks(block_idx);
          
          if block_idx == length(blocks)
            rec_load_stop = length(records.gps_time);
          else
            rec_load_stop = rec_load_start+param.analysis.block_size-1;
          end
          
          %% Specular: Load task output and concatenate
          % ===============================================================
          cur_recs = [rec_load_start rec_load_stop];
          actual_cur_recs = [(cur_recs(1)-1)*param.analysis.presums+1, ...
            cur_recs(end)*param.analysis.presums];
          
          out_fn = fullfile(tmp_out_fn_dir, ...
            sprintf('specular_wf_%d_adc_%d_%d_%d.mat',wf,adc,actual_cur_recs));

          fprintf('  Load %s (%s)\n', out_fn, datestr(now));
          spec_in = load(out_fn);
          
          if isfinite(spec_in.dt)
            spec.dt = spec_in.dt;
          end
          % Concatenate
          spec.deconv_gps_time(end+(1:numel(spec_in.deconv_gps_time))) = spec_in.deconv_gps_time;
          spec.deconv_fc(end+(1:numel(spec_in.deconv_fc))) = spec_in.deconv_fc;
          spec.deconv_t0(end+(1:numel(spec_in.deconv_t0))) = spec_in.deconv_t0;
          spec.deconv_twtt(end+(1:numel(spec_in.deconv_twtt))) = spec_in.deconv_twtt;
          spec.deconv_forced(end+(1:numel(spec_in.deconv_forced))) = spec_in.deconv_forced;
          
          spec.deconv_mean(end+(1:numel(spec_in.deconv_mean))) = spec_in.deconv_mean;
          spec.deconv_std(end+(1:numel(spec_in.deconv_std))) = spec_in.deconv_std;
          spec.deconv_sample(end+(1:numel(spec_in.deconv_sample))) = spec_in.deconv_sample;
          
          spec.gps_time(end+(1:numel(spec_in.gps_time))) = spec_in.gps_time;
          spec.lat(end+(1:numel(spec_in.lat))) = spec_in.lat;
          spec.lon(end+(1:numel(spec_in.lon))) = spec_in.lon;
          spec.elev(end+(1:numel(spec_in.elev))) = spec_in.elev;
          spec.roll(end+(1:numel(spec_in.roll))) = spec_in.roll;
          spec.pitch(end+(1:numel(spec_in.pitch))) = spec_in.pitch;
          spec.heading(end+(1:numel(spec_in.heading))) = spec_in.heading;
          spec.surface(end+(1:numel(spec_in.surface))) = spec_in.surface;
          spec.peakiness(end+(1:numel(spec_in.peakiness))) = spec_in.peakiness;
        end
        
        %% Specular: Store concatenated output
        % =================================================================
        spec.param_analysis = spec_in.param_analysis;
        spec.param_records = spec_in.param_records;
        if param.ct_file_lock
          spec.file_version = '1L';
        else
          spec.file_version = '1';
        end
        spec.file_type = 'analysis_spec';
        
        out_segment_fn = fullfile(out_segment_fn_dir,sprintf('specular_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
        fprintf('Saving output %s (%s)\n', out_segment_fn, datestr(now));
        ct_save(out_segment_fn,'-struct','spec');
      end
    end
    
    
  elseif strcmpi(cmd.method,{'burst_noise'})
    %% Burst Noise
    % ===================================================================
    % ===================================================================
    for img = 1:length(param.analysis.imgs)
      
      for wf_adc = cmd.wf_adcs{img}(:).'
        wf = param.analysis.imgs{img}(wf_adc,1);
        adc = param.analysis.imgs{img}(wf_adc,2);
        
        %% Coh Noise: Loop through all the coherent noise tracker files and combine
        % =====================================================================
        bad_bins = [];
        bad_recs = [];
        bad_waveforms_recs = {};
        bad_waveforms = {};
        test_metric = [];
        
        for block_idx = 1:length(blocks)
          rec_load_start = blocks(block_idx);
          
          if block_idx == length(blocks)
            rec_load_stop = length(records.gps_time);
          else
            rec_load_stop = rec_load_start+param.analysis.block_size-1;
          end
          
          % Load each block and concatenate
          % =====================================================================
          cur_recs = [rec_load_start rec_load_stop];
          actual_cur_recs = [(cur_recs(1)-1)*param.analysis.presums+1, ...
            cur_recs(end)*param.analysis.presums];
          
          out_fn = fullfile(tmp_out_fn_dir, ...
            sprintf('burst_noise_wf_%d_adc_%d_%d_%d.mat',wf,adc,actual_cur_recs));
          
          noise = load(out_fn);
          
          bad_bins(end+(1:length(noise.bad_bins))) = noise.bad_bins;
          bad_recs(end+(1:length(noise.bad_recs))) = rec_load_start-1 + noise.bad_recs;
          bad_recs_unique = unique(noise.bad_recs);
          bad_waveforms_recs{block_idx} = rec_load_start + bad_recs_unique(1:size(noise.bad_waveforms,2)) - 1;
          bad_waveforms{block_idx} = noise.bad_waveforms;
          test_metric(end+(1:length(noise.test_metric))) = noise.test_metric(:).';
        end

        % Constant noise fields carried over from last file loaded:
        %   param_analysis, param_records
        
        % Overwrite concatenated dynamic fields for the whole segment:
        noise.bad_bins = bad_bins;
        noise.bad_recs = bad_recs;
        noise.bad_waveforms_recs = bad_waveforms_recs;
        noise.bad_waveforms = bad_waveforms;
        noise.test_metric = test_metric;
        
        if param.ct_file_lock
          noise.file_version = '1L';
        else
          noise.file_version = '1';
        end
        noise.file_type = 'analysis_burst_noise';
        
        out_segment_fn = fullfile(out_segment_fn_dir,sprintf('burst_noise_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
        fprintf('Saving output %s (%s)\n', out_segment_fn, datestr(now));
        ct_save(out_segment_fn,'-struct','noise'); % Use HDF because of the large file size
      end
    end
    
    
  elseif strcmpi(cmd.method,{'coh_noise'})
    %% Coh Noise
    % ===================================================================
    % ===================================================================
    for img = 1:length(param.analysis.imgs)
      
      for wf_adc = cmd.wf_adcs{img}(:).'
        wf = param.analysis.imgs{img}(wf_adc,1);
        adc = param.analysis.imgs{img}(wf_adc,2);
        
        %% Coh Noise: Loop through all the coherent noise tracker files and combine
        % =====================================================================
        Nt = [];
        t0 = [];
        fc = NaN;
        dt = NaN;
        gps_time = [];
        lat = [];
        lon = [];
        elev = [];
        roll = [];
        pitch = [];
        heading = [];
        along_track = [];
        surface = [];
        nyquist_zone = [];
        bad_rec = [];
        DDC_dec = [];
        raw_or_DDC = [];
        DDC_freq_min = [];
        DDC_freq_max = [];
        
        coh_ave = {};
        coh_ave_mag = {};
        coh_ave_samples = {};
        doppler_concat = single([]);
        for block_idx = 1:length(blocks)
          rec_load_start = blocks(block_idx);
          
          if block_idx == length(blocks)
            rec_load_stop = length(records.gps_time);
          else
            rec_load_stop = rec_load_start+param.analysis.block_size-1;
          end
          
          % Load each block and concatenate
          % =====================================================================
          cur_recs = [rec_load_start rec_load_stop];
          actual_cur_recs = [(cur_recs(1)-1)*param.analysis.presums+1, ...
            cur_recs(end)*param.analysis.presums];
          
          out_fn = fullfile(tmp_out_fn_dir, ...
            sprintf('coh_noise_wf_%d_adc_%d_%d_%d.mat',wf,adc,actual_cur_recs));
          
          noise = load(out_fn);
          
          Nt(block_idx) = noise.Nt;
          t0(block_idx) = noise.t0;
          if ~isnan(noise.fc)
            fc = noise.fc;
          end
          if ~isnan(noise.dt)
            dt = noise.dt;
          end
          
          gps_time(end+(1:length(noise.gps_time))) = noise.gps_time;
          lat(end+(1:length(noise.lat))) = noise.lat;
          lon(end+(1:length(noise.lon))) = noise.lon;
          elev(end+(1:length(noise.elev))) = noise.elev;
          roll(end+(1:length(noise.roll))) = noise.roll;
          pitch(end+(1:length(noise.pitch))) = noise.pitch;
          heading(end+(1:length(noise.heading))) = noise.heading;
          along_track(end+(1:length(noise.along_track))) = noise.along_track;
          surface(end+(1:length(noise.surface))) = noise.surface;
          nyquist_zone(end+(1:length(noise.nyquist_zone))) = noise.nyquist_zone;
          bad_rec(end+(1:length(noise.bad_rec))) = noise.bad_rec;
          DDC_dec(end+(1:length(noise.DDC_dec))) = noise.DDC_dec;
          raw_or_DDC(end+(1:length(noise.raw_or_DDC))) = noise.raw_or_DDC;
          DDC_freq_min(end+(1:length(noise.DDC_freq_min))) = noise.DDC_freq_min;
          DDC_freq_max(end+(1:length(noise.DDC_freq_max))) = noise.DDC_freq_max;
          
          % coh_ave and coh_ave_samples may be different lengths, so we
          % just concatenate in cell arrays
          coh_ave{block_idx} = noise.coh_ave;
          coh_ave_mag{block_idx} = noise.coh_ave_mag;
          coh_ave_samples{block_idx} = noise.coh_ave_samples;
          
          noise.doppler = reshape(noise.doppler,[numel(noise.doppler) 1]);
          if block_idx == 1
            doppler_concat = noise.doppler;
          else
            if size(noise.doppler,1) ~= size(doppler_concat,1)
              % Block was a different size than other Doppler spectrums, re-sample
              % so that it can be stored in the output matrix
              noise.doppler = interp1(0:numel(noise.doppler)-1,noise.doppler,linspace(0,numel(noise.doppler)-1,size(doppler_concat,1)).');
            end
            doppler_concat(:,end+1) = noise.doppler;
          end
          
        end

        % Constant noise fields carried over from last file loaded:
        %   dt, fc, param_analysis, param_records
        % Handle special case where a block had all bad records and fc and
        % dt were NaN.
        noise.fc = fc;
        noise.dt = dt;
        
        % Overwrite concatenated dynamic fields for the whole segment:
        noise.Nt = Nt;
        noise.t0 = t0;
        
        noise.gps_time = gps_time;
        noise.lat = lat;
        noise.lon = lon;
        noise.elev = elev;
        noise.roll = roll;
        noise.pitch = pitch;
        noise.heading = heading;
        noise.along_track = along_track;
        noise.surface = surface;
        noise.nyquist_zone = nyquist_zone;
        noise.bad_rec = bad_rec;
        noise.DDC_dec = DDC_dec;
        noise.raw_or_DDC = raw_or_DDC;
        noise.DDC_freq_min = DDC_freq_min;
        noise.DDC_freq_max = DDC_freq_max;
        
        noise.coh_ave = coh_ave;
        noise.coh_ave_mag = coh_ave_mag;
        noise.coh_ave_samples = coh_ave_samples;
        
        noise.doppler = doppler_concat;
        
        if param.ct_file_lock
          noise.file_version = '1L';
        else
          noise.file_version = '1';
        end
        noise.file_type = 'analysis_noise';
        
        out_segment_fn = fullfile(out_segment_fn_dir,sprintf('coh_noise_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
        fprintf('Saving output %s (%s)\n', out_segment_fn, datestr(now));
        ct_save(out_segment_fn,'-struct','noise'); % Use HDF because of the large file size
      end
    end
    
    
  elseif strcmpi(cmd.method,{'waveform'})
    %% Waveform extraction
    % ===================================================================
    % ===================================================================
    for img = 1:length(param.analysis.imgs)
      for wf_adc = cmd.wf_adcs{img}(:).'
        wf = param.analysis.imgs{img}(wf_adc,1);
        adc = param.analysis.imgs{img}(wf_adc,2);
        
        %% Waveform: Loop through all the surface tracker files and combine
        % =====================================================================
        gps_time = [];
        lat = [];
        lon = [];
        elev = [];
        roll = [];
        pitch = [];
        heading = [];
        wf_data = [];
        time_rng = [];
        layer_nan_mask = [];
        for block_idx = 1:length(blocks)
          rec_load_start = blocks(block_idx);
          
          if block_idx == length(blocks)
            rec_load_stop = length(records.gps_time);
          else
            rec_load_stop = rec_load_start+param.analysis.block_size-1;
          end
          
          cur_recs = [rec_load_start rec_load_stop];
          actual_cur_recs = [(cur_recs(1)-1)*param.analysis.presums+1, ...
            cur_recs(end)*param.analysis.presums];
          
          out_fn = fullfile(tmp_out_fn_dir, ...
            sprintf('waveform_wf_%d_adc_%d_%d_%d.mat',wf,adc,actual_cur_recs));
          
          waveform = load(out_fn);
          
          gps_time = cat(2,gps_time,waveform.gps_time);
          lat = cat(2,lat,waveform.lat);
          lon = cat(2,lon,waveform.lon);
          elev = cat(2,elev,waveform.elev);
          roll = cat(2,roll,waveform.roll);
          pitch = cat(2,pitch,waveform.pitch);
          heading = cat(2,heading,waveform.heading);
          wf_data = cat(2,wf_data,waveform.wf_data);
          time_rng = cat(2,time_rng,waveform.time_rng);
          layer_nan_mask = cat(2,layer_nan_mask,waveform.layer_nan_mask);
        end
        
        % Constant waveform fields carried over from last file loaded:
        %   param_analysis, param_records
        
        % Overwrite concatenated dynamic fields for the whole segment:
        waveform.gps_time = gps_time;
        waveform.lat = lat;
        waveform.lon = lon;
        waveform.elev = elev;
        waveform.roll = roll;
        waveform.pitch = pitch;
        waveform.heading = heading;
        waveform.wf_data = wf_data;
        waveform.time_rng = time_rng;
        waveform.layer_nan_mask = layer_nan_mask;
        
        if param.ct_file_lock
          waveform.file_version = '1L';
        else
          waveform.file_version = '1';
        end
        waveform.file_type = 'analysis_waveform';
        
        out_segment_fn = fullfile(out_segment_fn_dir,sprintf('waveform_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
        fprintf('Saving output %s (%s)\n', out_segment_fn, datestr(now));
        ct_save(out_segment_fn,'-struct','waveform'); % Use HDF because of the large file size
      end
    end
    
    
  elseif strcmpi(cmd.method,{'statistics'})
    %% Statistics
    % ===================================================================
    % ===================================================================
    for img = 1:length(param.analysis.imgs)
      
      for wf_adc = cmd.wf_adcs{img}(:).'
        wf = param.analysis.imgs{img}(wf_adc,1);
        adc = param.analysis.imgs{img}(wf_adc,2);
        
        %% Statistics: Loop through all the stats files and combine
        % =====================================================================
        gps_time = [];
        lat = [];
        lon = [];
        elev = [];
        roll = [];
        pitch = [];
        heading = [];
        surface = [];
        start_bin = [];
        tmp_stats = {};
        time = {};
        freq = {};
        for block_idx = 1:length(blocks)
          rec_load_start = blocks(block_idx);
          
          if block_idx == length(blocks)
            rec_load_stop = length(records.gps_time);
          else
            rec_load_stop = rec_load_start+param.analysis.block_size-1;
          end
          
          % Load each block and concatenate
          % =====================================================================
          cur_recs = [rec_load_start rec_load_stop];
          actual_cur_recs = [(cur_recs(1)-1)*param.analysis.presums+1, ...
            cur_recs(end)*param.analysis.presums];
          
          out_fn = fullfile(tmp_out_fn_dir, ...
            sprintf('stats_wf_%d_adc_%d_%d_%d.mat',wf,adc,actual_cur_recs));
          
          stats = load(out_fn);
          
          gps_time(end+(1:length(stats.gps_time))) = stats.gps_time;
          lat(end+(1:length(stats.lat))) = stats.lat;
          lon(end+(1:length(stats.lon))) = stats.lon;
          elev(end+(1:length(stats.elev))) = stats.elev;
          roll(end+(1:length(stats.roll))) = stats.roll;
          pitch(end+(1:length(stats.pitch))) = stats.pitch;
          heading(end+(1:length(stats.heading))) = stats.heading;
          surface(end+(1:length(stats.surface))) = stats.surface;
          start_bin(end+(1:length(stats.start_bin))) = stats.start_bin;
          
          % stats may be different lengths, so we just concatenate in cell
          % arrays
          time{block_idx} = stats.time;
          freq{block_idx} = stats.freq;
          tmp_stats{block_idx} = stats.stats;
          
        end

        % Constant stats fields carried over from last file loaded:
        %   param_analysis, param_records
        
        % Overwrite concatenated dynamic fields for the whole segment:
        stats.gps_time = gps_time;
        stats.lat = lat;
        stats.lon = lon;
        stats.elev = elev;
        stats.roll = roll;
        stats.pitch = pitch;
        stats.heading = heading;
        stats.surface = surface;
        stats.start_bin = start_bin;
        
        stats.freq = freq;
        stats.time = time;
        stats.stats = tmp_stats;
        
        if param.ct_file_lock
          stats.file_version = '1L';
        else
          stats.file_version = '1';
        end
        stats.file_type = 'analysis_stats';
        
        out_segment_fn = fullfile(out_segment_fn_dir,sprintf('stats_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
        fprintf('Saving output %s (%s)\n', out_segment_fn, datestr(now));
        ct_save(out_segment_fn,'-struct','stats'); % Use HDF because of the large file size
      end
    end
    
  end
end

%% Delete temporary files
if 0 % HACK: DISABLE TO NOT DELETE TEMPORARY FILES
  for cmd_idx = 1:length(param.analysis.cmd)
    cmd = param.analysis.cmd{cmd_idx};
    if ~cmd.en
      continue;
    end
    
    tmp_out_fn_dir = ct_filename_out(param, cmd.out_path, 'analysis_tmp');
    if strcmpi(cmd.method,{'saturation'})
      delete(fullfile(tmp_out_fn_dir,'saturation_*'));
      try
        rmdir(tmp_out_fn_dir); % Only deletes if empty
      end
      
    elseif strcmpi(cmd.method,{'specular'})
      delete(fullfile(tmp_out_fn_dir,'specular_*'));
      try
        rmdir(tmp_out_fn_dir); % Only deletes if empty
      end
      
    elseif strcmpi(cmd.method,{'coh_noise'})
      delete(fullfile(tmp_out_fn_dir,'coh_noise_*'));
      try
        rmdir(tmp_out_fn_dir); % Only deletes if empty
      end
      
    elseif strcmpi(cmd.method,{'waveform'})
      delete(fullfile(tmp_out_fn_dir,'surf_*'));
      try
        rmdir(tmp_out_fn_dir); % Only deletes if empty
      end
      
    elseif strcmpi(cmd.method,{'statistics'})
      delete(fullfile(tmp_out_fn_dir,'stats_*'));
      try
        rmdir(tmp_out_fn_dir); % Only deletes if empty
      end
      
    end
  end
end

fprintf('%s done %s\n', mfilename, datestr(now));

success = true;

return;
