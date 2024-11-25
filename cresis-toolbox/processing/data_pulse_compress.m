function [hdr,data,param] = data_pulse_compress(param,hdr,data)
% [hdr,data,param] = data_pulse_compress(param,hdr,data)

wfs = param.radar.wfs;

if param.load.raw_data && param.load.pulse_comp
  error('Pulse compression (param.load.pulse_comp) cannot be enabled with raw data loading (param.load.raw_data).');
end

physical_constants;

[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);

for img = 1:length(param.load.imgs)
  for wf_adc = 1:size(param.load.imgs{img},1)
    wf = param.load.imgs{img}(wf_adc,1);
    adc = param.load.imgs{img}(wf_adc,2);
    BW_window_max_warning_printed = false;
    BW_window_min_warning_printed = false;
    
    %% Pre-pulse compression filter
    % ===================================================================
    if strcmpi(radar_type,'deramp')
      if strcmpi(wfs(wf).prepulse_H.type,'filtfilt')
        data{img}(:,:,wf_adc) = single(filtfilt(wfs(wf).prepulse_H.B,1,double(data{img}(:,:,wf_adc))));
      end
      
      if strcmpi(wfs(wf).prepulse_H.type,'inverse_filter')
        % Apply inverse filter on each record (or range line)
        nz_prev = NaN;
        nz_signal_prev = NaN;
        for rec = 1:size(data{img},2)
          if hdr.bad_rec{img}(rec)
            continue;
          end
          rx = param.radar.wfs(wf).rx_paths(adc);
          nz = double(hdr.nyquist_zone_hw{img}(rec));
          % Check and load measured filter response for corresponding Nyquist Zone
          if ~(nz==nz_prev)
            prepulse_fn = fullfile(ct_filename_out(param,prepulse_H.dir,'',1),...
              sprintf('%s_rx_%d_nz_%d.mat', param.radar.wfs(wf).prepulse_H.fn, rx, nz));
            prepulse = load(prepulse_fn);
            nz_signal_prev = NaN;
          end
          nz_prev = nz;
          
          nz_signal = double(hdr.nyquist_zone_signal{img}(rec));
          if ~(nz_signal==nz_signal_prev)
            %Create a baseband frequency axis
            df = param.radar.fs/hdr.Nt{img}(rec);
            freq_axis = df .* ifftshift(-floor(hdr.Nt{img}(rec)/2):floor((hdr.Nt{img}(rec)-1)/2)).';
            
            %Create current frequency axis
            freq = freq_nz(freq_alias(freq_axis+hdr.DDC_freq{img}(rec),param.radar.fs),param.radar.fs,nz_signal);
            
            %Interpolate the inverse filter, H, for this axis
            H = zeros(hdr.Nt{img}(rec),1);
            mask = freq>=0;
            H(mask) = interp1(prepulse.freq, prepulse.H, freq(mask));
            mask = freq<0;
            H(mask) = interp1(-prepulse.freq, conj(prepulse.H), freq(mask));
          end
          nz_signal_prev = nz_signal;
          
          %Frequency domain data multiplied with inverse hardware filter
          data{img}(1:hdr.Nt{img}(rec),rec,wf_adc) = fft(data{img}(1:hdr.Nt{img}(rec),rec,wf_adc),[],1);
          data{img}(1:hdr.Nt{img}(rec),rec,wf_adc) = bsxfun(@times,data{img}(1:hdr.Nt{img}(rec),rec,wf_adc),H);

           % Convert back to time domain
          data{img}(1:hdr.Nt{img}(rec),rec,wf_adc) = ifft(data{img}(1:hdr.Nt{img}(rec),rec,wf_adc));          
          
        end % rec loop
      end % INVERSE FILTER if strcmpi ends here
      
      if strcmpi(wfs(wf).prepulse_H.type,'NI_DDC_2019')
        if 0
          % Test code to find each DDC filter delay
          idx0 = 1000;
          Nx = 1500;
          dd=data{img}(:,idx0+(1:Nx));
          Nx = size(dd,2);
          ee = zeros(1,Nx);
          for col = 1:Nx
            rec = idx0 + col;
            if hdr.Nt{img}(rec) == 0
              continue
            end
            freq_axis = ifftshift(-floor(hdr.Nt{img}(rec)/2):floor((hdr.Nt{img}(rec)-1)/2)).';
            if hdr.DDC_dec{img}(rec) == 2
            elseif hdr.DDC_dec{img}(rec) == 4
              dd(1:hdr.Nt{img}(rec),col) = hdr.DDC_dec{img}(rec)*dd(1:hdr.Nt{img}(rec),col);
              % Delay of 100/4 = 25 relative to DDC_dec==2
              dd(1:hdr.Nt{img}(rec),col) = ifft(fft(data{img}(1:hdr.Nt{img}(rec),rec,wf_adc)) ...
                .* exp(1i*2*pi*25*freq_axis/hdr.Nt{img}(rec)));
            elseif hdr.DDC_dec{img}(rec) == 8
              dd(1:hdr.Nt{img}(rec),col) = hdr.DDC_dec{img}(rec)*dd(1:hdr.Nt{img}(rec),col);
              % Delay of (100+2*100)/8 = 37.5 relative to DDC_dec==2
              dd(1:hdr.Nt{img}(rec),col) = ifft(fft(data{img}(1:hdr.Nt{img}(rec),rec,wf_adc)) ...
                .* exp(1i*2*pi*37.5*freq_axis/hdr.Nt{img}(rec)));
            elseif hdr.DDC_dec{img}(rec) == 16
              % Delay of (100+2*100+4*100)/8 = 43.75 relative to DDC_dec==2
              dd(1:hdr.Nt{img}(rec),col) = ifft(fft(data{img}(1:hdr.Nt{img}(rec),rec,wf_adc)) ...
                .* exp(1i*2*pi*43.75*freq_axis/hdr.Nt{img}(rec)));
            end
            Mt = hdr.DDC_dec{img}(rec);
            ee(1:hdr.Nt{img}(rec)*Mt,col) = single(resample(double(dd(1:hdr.Nt{img}(rec),col)),Mt,1));
          end
          ref2 = mean(ee(:,105:115),2);
          ref4 = mean(ee(:,120:130),2);
          ref8 = mean(ee(:,440:450),2);
          [eex,lags] = xcorr(ref4,ref2);
          plot(lags,lp(eex));
          [mv,mi] = max(eex);
          lags(mi)
          
          [eex,lags] = xcorr(ref8,ref2);
          plot(lags,lp(eex));
          [mv,mi] = max(eex);
          lags(mi)
          
          ref2 = fft(ref2);
          ref4 = fft(ref4);
          ref8 = fft(ref8);
          figure(1); clf;
          plot(lp(ref2))
          hold on
          plot(lp(ref4))
          plot(lp(ref8))
          
          figure(1); clf;
          plot(angle(ref2))
          hold on
          plot(angle(ref4))
          plot(angle(ref8))
        end
        
        data_complex_hack = false; %
        for rec = 1:size(data{img},2)
          freq_axis = ifftshift(-floor(hdr.Nt{img}(rec)/2):floor((hdr.Nt{img}(rec)-1)/2)).';
          if hdr.DDC_dec{img}(rec) == 2
            % Scale output
            data{img}(1:hdr.Nt{img}(rec),rec,wf_adc) = hdr.DDC_dec{img}(rec) ...
              * data{img}(1:hdr.Nt{img}(rec),rec,wf_adc);
          elseif hdr.DDC_dec{img}(rec) == 4
            % Scale output
            data{img}(1:hdr.Nt{img}(rec),rec,wf_adc) = exp(1i*-pi/2)*hdr.DDC_dec{img}(rec) ...
              * data{img}(1:hdr.Nt{img}(rec),rec,wf_adc);
            % Delay of 100/4 = 25 relative to DDC_dec==2
            data{img}(1:hdr.Nt{img}(rec),rec,wf_adc) = ifft(fft(data{img}(1:hdr.Nt{img}(rec),rec,wf_adc)) ...
              .* exp(1i*2*pi*25*freq_axis/hdr.Nt{img}(rec)));
          elseif hdr.DDC_dec{img}(rec) == 8
            % Scale output
            data{img}(1:hdr.Nt{img}(rec),rec,wf_adc) = exp(1i*-pi/2)*hdr.DDC_dec{img}(rec) ...
              * data{img}(1:hdr.Nt{img}(rec),rec,wf_adc);
            % Delay of (100+2*100)/8 = 37.5 relative to DDC_dec==2
            data{img}(1:hdr.Nt{img}(rec),rec,wf_adc) = ifft(fft(data{img}(1:hdr.Nt{img}(rec),rec,wf_adc)) ...
              .* exp(1i*2*pi*37.5*freq_axis/hdr.Nt{img}(rec)));
          elseif hdr.DDC_dec{img}(rec) == 16
            % Scale output
            data{img}(1:hdr.Nt{img}(rec),rec,wf_adc) = hdr.DDC_dec{img}(rec) ...
              * data{img}(1:hdr.Nt{img}(rec),rec,wf_adc);
            % Delay of (100+2*100+4*100)/8 = 43.75 relative to DDC_dec==2
            data{img}(1:hdr.Nt{img}(rec),rec,wf_adc) = ifft(fft(data{img}(1:hdr.Nt{img}(rec),rec,wf_adc)) ...
              .* exp(1i*2*pi*43.75*freq_axis/hdr.Nt{img}(rec)));
          end
          if ~isreal(data{img}) && ~data_complex_hack && size(data{img},1) > 0
            data_complex_hack = true;
            % Temporarily add an imaginary part to the first value in the
            % matrix so that Matlab will know right away that this matrix
            % is complex and won't have to search through the entire
            % matrix to find this out. We remove this value at the end of
            % the loop.
            data{img}(1) = data{img}(1) + 1i;
          end
        end
        if data_complex_hack
          data{img}(1) = data{img}(1) - 1i;
        end
      end
    end
    
    %% Burst RFI removal
    % ===================================================================
 
    %% Coherent noise: Analysis Load
    % ===================================================================
    if strcmpi(wfs(wf).coh_noise_method,'analysis')
      noise_fn_dir = fileparts(ct_filename_out(param,param.radar.wfs(wf).coh_noise_arg.fn, ''));
      noise_fn = fullfile(noise_fn_dir,sprintf('coh_noise_simp_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
      fprintf('  Loading coherent noise: %s (%s)\n', noise_fn, datestr(now));
      noise = collate_coh_noise_load(param,wf,adc);
      param.collate_coh_noise.param_collate = noise.param_collate_coh_noise;
      param.collate_coh_noise.param_analysis = noise.param_analysis;
      param.collate_coh_noise.param_records = noise.param_records;
      
      cmd = noise.param_analysis.analysis.cmd{noise.param_collate_coh_noise.collate_coh_noise.cmd_idx};
      
      noise.Nx = length(noise.gps_time);
      
      % Find the matching image index that includes this wf-adc pair.
      match_found = false;
      for collate_coh_noise_img = 1:length(noise.param_analysis.analysis.imgs)
        for match_wf_adc = 1:size(noise.param_analysis.analysis.imgs{collate_coh_noise_img},1)
          if noise.param_analysis.analysis.imgs{collate_coh_noise_img}(match_wf_adc,1) == wf ...
              && noise.param_analysis.analysis.imgs{collate_coh_noise_img}(match_wf_adc,2) == adc
            match_found = true;
            break;
          end
        end
        if match_found
          break;
        end
      end
      if ~match_found
        error('Could not find matching wf-adc pair in noise.param_analysis.analysis.imgs and therefore the collate_coh_noise.method cannot be verified.');
      end
      if strcmpi(noise.param_collate_coh_noise.collate_coh_noise.method{collate_coh_noise_img},'dft')
        coh_noise = noise.dft_noise;
        noise = rmfield(noise,'dft_noise');
      elseif strcmpi(noise.param_collate_coh_noise.collate_coh_noise.method{collate_coh_noise_img},'firdec')
        coh_noise = noise.firdec_noise;
        noise = rmfield(noise,'firdec_noise');
      end
      
      % Nt by Nx_dft matrix
      coh_noise(~isfinite(coh_noise)) = 0;
      
      % Adjust coherent noise dft for changes in adc_gains relative to
      % when the coherent noise was loaded and estimated.
      coh_noise = coh_noise * 10.^((noise.param_analysis.radar.wfs(wf).adc_gains_dB(adc)-wfs(wf).adc_gains_dB(adc))/20);
      
      % Adjust coherent noise for changes in system_dB
      if length(wfs(wf).system_dB) == 1
        system_dB = wfs(wf).system_dB;
        % Only a single number is provided for system_dB so apply it to all
        % receiver paths
      else
        % A number is provided for each receiver path for system_dB
        system_dB = wfs(wf).system_dB(param.radar.wfs(wf).rx_paths(adc));
      end
      if length(noise.param_analysis.radar.wfs(wf).system_dB) == 1
        system_dB_noise = noise.param_analysis.radar.wfs(wf).system_dB;
        % Only a single number is provided for system_dB so apply it to all
        % receiver paths
      else
        % A number is provided for each receiver path for system_dB
        system_dB_noise = noise.param_analysis.radar.wfs(wf).system_dB(param.radar.wfs(wf).rx_paths(adc));
      end
      coh_noise = coh_noise * 10.^((system_dB_noise-system_dB)/20);
      
      noise.Nt = size(coh_noise,1);
      noise.freq = noise.fc + 1/(noise.dt*noise.Nt) * ifftshift(-floor(noise.Nt/2):floor((noise.Nt-1)/2)).';
      if ~strcmpi(radar_type,'deramp')
        % Adjust the coherent noise Tsys, chan_equal_dB, chan_equal_deg for
        % changes relative to when the coherent noise was loaded and
        % estimated.
        coh_noise = coh_noise * 10.^(( ...
          noise.param_analysis.radar.wfs(wf).chan_equal_dB(param.radar.wfs(wf).rx_paths(adc)) ...
          - param.radar.wfs(wf).chan_equal_dB(param.radar.wfs(wf).rx_paths(adc)) )/20) ...
          .* exp(1i*( ...
          noise.param_analysis.radar.wfs(wf).chan_equal_deg(param.radar.wfs(wf).rx_paths(adc)) ...
          - param.radar.wfs(wf).chan_equal_deg(param.radar.wfs(wf).rx_paths(adc)) )/180*pi);
        
        % Tadc_adjust changes do not matter since they do not affect the data
        % (only the time axis is affected).
        
        % Correct any changes in Tsys
        Tsys = param.radar.wfs(wf).Tsys(param.radar.wfs(wf).rx_paths(adc));
        Tsys_old = noise.param_analysis.radar.wfs(wf).Tsys(param.radar.wfs(wf).rx_paths(adc));
        if strcmpi(radar_type,'pulsed')
          time_correction = param.radar.wfs(wf).time_correction;
          time_correction_old = noise.param_analysis.radar.wfs(wf).time_correction;
          dTsys = Tsys-Tsys_old + time_correction-time_correction_old;
        else
          dTsys = Tsys-Tsys_old;
        end
        if dTsys ~= 0
          % Positive dTsys means Tsys > Tsys_old and we should reduce the
          % time delay to all targets by dTsys.
          coh_noise = ifft(bsxfun(@times, fft(coh_noise), exp(1i*2*pi*noise.freq*dTsys)));
        end
      end
      
      recs = interp1(noise.gps_time, noise.recs, hdr.gps_time, 'linear', 'extrap');
    end
    
    %% Coherent noise: Pulsed
    % ===================================================================
    if strcmpi(radar_type,'pulsed')
      if strcmpi(wfs(wf).coh_noise_method,'analysis') && ~cmd.pulse_comp
        if 0
          % Debug Code
          
          cn.data = zeros([size(coh_noise,1) numel(recs)],'single');
          for dft_idx = 1:length(noise.dft_freqs)
            % mf: matched filter
            % coh_noise(bin,dft_idx): Coefficient for the matched filter
            mf = exp(1i*2*pi/noise.Nx*noise.dft_freqs(dft_idx) .* recs);
            for bin = 1:size(coh_noise,1)
              cn.data(bin,:) = cn.data(bin,:)-coh_noise(bin,dft_idx) * mf;
            end
          end
          
          figure(1); clf;
          imagesc(lp( bsxfun(@minus, data{img}(1:wfs(wf).Nt,:), mean(data{img}(1:wfs(wf).Nt,:),2) )  ))
          figure(2); clf;
          imagesc(lp( data{img}(1:wfs(wf).Nt,:,wf_adc) ))
          figure(3); clf;
          imagesc(lp( cn.data ))
          figure(4); clf;
          plot(lp(mean(data{img}(1:wfs(wf).Nt,:,wf_adc),2)))
          legend('Mean','CN');
        end
        
        for dft_idx = 1:length(noise.dft_freqs)
          % mf: matched filter
          % coh_noise(bin,dft_idx): Coefficient for the matched filter
          mf = exp(1i*2*pi/noise.Nx*noise.dft_freqs(dft_idx) .* recs);
          for bin = 1:size(coh_noise,1)
            data{img}(bin,:,wf_adc) = data{img}(bin,:,wf_adc)-coh_noise(bin,dft_idx) * mf;
          end
        end
        
      elseif strcmpi(wfs(wf).coh_noise_method,'estimated')
        % Apply coherent noise methods that require estimates derived now
        
        if wfs(wf).coh_noise_arg.DC_remove_en
          data{img}(1:wfs(wf).Nt_raw,:,wf_adc) = bsxfun(@minus, data{img}(1:wfs(wf).Nt_raw,:,wf_adc), ...
            mean(data{img}(1:wfs(wf).Nt_raw,:,wf_adc),2));
        end
        
        if length(wfs(wf).coh_noise_arg.B_coh_noise) > 1
          if length(wfs(wf).coh_noise_arg.A_coh_noise) > 1
            % Use filtfilt (feedback)
            data{img}(1:wfs(wf).Nt_raw,:,wf_adc) = single(filtfilt(wfs(wf).coh_noise_arg.B_coh_noise, ...
              wfs(wf).coh_noise_arg.A_coh_noise, double(data{img}(1:wfs(wf).Nt_raw,:,wf_adc).'))).';
          else
            % Use fir_dec (no feedback)
            data{img}(1:wfs(wf).Nt_raw,:,wf_adc) = fir_dec(data{img}(1:wfs(wf).Nt_raw,:,wf_adc),wfs(wf).coh_noise_arg.B_coh_noise,1);
          end
        end
        
      end
    end
    
    %% Coherent noise: Deramp
    % ===================================================================
    if strcmpi(radar_type,'deramp')
      if strcmpi(wfs(wf).coh_noise_method,'analysis')
        if 0
          % Debug Code
          imagesc(lp( bsxfun(@minus, data{img}(1:wfs(wf).Nt,:), mean(data{img}(1:wfs(wf).Nt,:),2) )  ))
          figure(1); clf;
          plot(lp(mean(data{img}(1:wfs(wf).Nt,:),2)))
          hold on
          plot(lp(coh_noise))
        end
        
        if strcmpi(noise.param_collate_coh_noise.collate_coh_noise.method{collate_coh_noise_img},'dft')
          cn.data = zeros([size(coh_noise,1) numel(recs)],'single');
          for dft_idx = 1:length(noise.dft_freqs)
            % mf: matched filter
            % coh_noise(bin,dft_idx): Coefficient for the matched filter
            mf = exp(1i*2*pi/noise.Nx*noise.dft_freqs(dft_idx) .* recs);
            for bin = 1:size(coh_noise,1)
              cn.data(bin,:) = cn.data(bin,:)-coh_noise(bin,dft_idx) * mf;
            end
          end
        elseif strcmpi(noise.param_collate_coh_noise.collate_coh_noise.method{collate_coh_noise_img},'firdec')
          % Interpolate coherent noise onto current data's gps time
          if all(hdr.gps_time>noise.firdec_gps_time(end))
            % All current data's gps time is after the coherent noise
            % estimates gps time
            cn.data = -repmat(coh_noise(:,end),[1 length(hdr.gps_time)]);
          elseif all(hdr.gps_time<noise.firdec_gps_time(1))
            % All current data's gps time is before the coherent noise
            % estimates gps time
            cn.data = -repmat(coh_noise(:,1),[1 length(hdr.gps_time)]);
          else
            % Current data gps time overlaps with coherent noise estimates
            cn.data = -interp_finite(interp1(noise.firdec_gps_time, coh_noise.', hdr.gps_time)).';
          end
        end
        clear coh_noise;
      end
    end
    
    
    %% Pulse compress
    % ===================================================================
    if param.load.pulse_comp == 1
      
      %% Pulse compress: Pulsed
      if strcmpi(radar_type,'pulsed')
        % Digital down conversion
        
        if 0
          % Debug: print noise levels
          fprintf('%d:%d %g\n', img, wf_adc, 10*log10(mean(mean(abs(data{img}(end+[-600:-401],:,wf_adc)).^2))));
        end
        
          
        % Check if any good records, skip processing if not
        if any(~hdr.bad_rec{img}(1,:,wf_adc))
          blocks = round(linspace(1,size(data{img},2)+1,8)); blocks = unique(blocks);
          for block = 1:length(blocks)-1
            rlines = blocks(block) : blocks(block+1)-1;
            
            % Digital down conversion
            data{img}(1:wfs(wf).Nt_raw,rlines,wf_adc) = bsxfun(@times,data{img}(1:wfs(wf).Nt_raw,rlines,wf_adc), ...
              exp(-1i*2*pi*(wfs(wf).fc-wfs(wf).DDC_freq)*wfs(wf).time_raw));
            
            % Pulse compression
            %   Apply matched filter and transform back to time domain
            %   1. Extract the portion of the range line that is valid
            tmp_data = data{img}(1:wfs(wf).Nt_raw,rlines,wf_adc);
            %   2. Set ~isfinite values to zero (unless the whole record is bad,
            %   then just leave the samples as is)
            tmp_data(bsxfun(@and,~isfinite(tmp_data),~hdr.bad_rec{img}(1,rlines,wf_adc))) = 0;
            %   3. Apply pulse compression with zero padding
            tmp_data = circshift(ifft(bsxfun(@times,fft(tmp_data, wfs(wf).Nt_pc,1),wfs(wf).ref{adc}),[],1),wfs(wf).pad_length,1);
            
            % Resampling
            data{img}(1:wfs(wf).Nt,rlines,wf_adc) = single(resample(double(tmp_data), wfs(wf).ft_dec(1), wfs(wf).ft_dec(2)));
            
          end
        end
        
        if 0
          % Debug: print noise levels after pulse compression
          offset = round(wfs(wf).Tpd*wfs(wf).fs);
          fprintf('%d:%d PC %g\n', img, wf_adc, 10*log10(mean(mean(abs(data{img}(wfs(wf).Nt + -offset+[-199:0],:,wf_adc)).^2))));
        end
        
        if wf_adc == 1
          hdr.time{img} = wfs(wf).time;
          hdr.freq{img} = wfs(wf).freq;
        end
        
        
      elseif strcmpi(radar_type,'deramp')
        %% Pulse compress: Deramp Debug
        if 0
          % ENABLE_FOR_DEBUG
          % Create simulated data
          clear;
          img = 1;
          rec = 1;
          wf = 1;
          wf_adc = 1;
          if 0
            % Down-chirp with DDC and single half rate decimator
            hdr.DDC_dec{img}(rec) = 2; % 1
            hdr.DDC_freq{img}(rec) = 4.128051757812500e+07; % 0e6
            hdr.nyquist_zone_signal{img}(rec) = 1; % 1
            wfs(wf).fs_raw = 125e6; % 250e6
            wfs(wf).f0 = 18e9;
            wfs(wf).f1 = 2e9;
            hdr.surface(rec) = 1.5e-6;
          else
            % Up-chirp real sampling
            hdr.DDC_dec{img}(rec) = 1; % 1
            hdr.DDC_freq{img}(rec) = 0e6; % 0e6
            hdr.nyquist_zone_signal{img}(rec) = 1; % 1
            wfs(wf).fs_raw = 250e6; % 250e6
            wfs(wf).f0 = 2e9;
            wfs(wf).f1 = 18e9;
            hdr.surface(rec) = 3e-6;
          end
          wfs(wf).BW_window = [2.5e9 17.499e9];
          wfs(wf).Tpd = 240e-6;
          wfs(wf).td_mean = hdr.surface(rec);
          wfs(wf).coh_noise_method = '';
          BW = wfs(wf).f1-wfs(wf).f0;
          wfs(wf).chirp_rate = BW/wfs(wf).Tpd;
          hdr.t_ref{img}(rec) = 0e-6;
          wfs(wf).ft_wind = @hanning;
          param.radar.wfs(wf).nz_trim = {};
          tguard = 1e-6;
          td_max = wfs(wf).td_mean*2;
          td_min = 0e-6;
          tref = hdr.t_ref{img}(rec);
          hdr.t0_raw{img}(rec) = -tguard + min(td_min,tref);
          wfs(wf).Tadc_adjust = 0;
          fs_nyquist = max(wfs(wf).f0,wfs(wf).f1)*5;
          Mt_oversample = ceil(fs_nyquist/(wfs(wf).fs_raw));
          Mt_oversample = Mt_oversample * hdr.DDC_dec{img}(rec);
          fs_rf = Mt_oversample*wfs(wf).fs_raw/hdr.DDC_dec{img}(rec);
          Nt_rf = round((wfs(wf).Tpd + max(td_max,tref) - min(td_min,tref) + 2*tguard)*fs_rf/Mt_oversample)*Mt_oversample;
          hdr.Nt{img}(rec) = Nt_rf / Mt_oversample;
          
          t0 = hdr.t0_raw{img}(1);
          fs_raw_dec = wfs(wf).fs_raw ./ hdr.DDC_dec{img}(1);
          dt_raw = 1/fs_raw_dec;
          time_raw_no_trim = (t0:dt_raw:t0+dt_raw*(hdr.Nt{img}(rec)-1)).';
          if 0
            tds = hdr.surface(rec) + 1/abs(BW)/5*(0:11);
            hdr.surface = tds;
            %hdr.surface(:) = hdr.surface(1);% Enable or disable this line to simulate errors in surface estimate
          else
            if wfs(wf).f0 > wfs(wf).f1
              window_time_offset = (wfs(wf).BW_window(2) - wfs(wf).f0)/wfs(wf).chirp_rate;
            else
              window_time_offset = (wfs(wf).BW_window(1) - wfs(wf).f0)/wfs(wf).chirp_rate;
            end
            time_raw_no_trim_transition = hdr.surface(rec)+window_time_offset;
            idx = find(time_raw_no_trim>time_raw_no_trim_transition,1);
            
            % Update surface to lie on a IF sample boundary
            hdr.surface = time_raw_no_trim(idx)-window_time_offset;
            
            tds = hdr.surface(1) + 1/wfs(wf).fs_raw*(0 + [-100-1/3 -30 -10 -4/3 -1/3 0 1/3 4/3 10 30 100+1/3]);
            %tds = hdr.surface(1) + 1/BW/5*[-2 -1 0 1 2];
            hdr.surface = tds;
            %hdr.surface(:) = hdr.surface(1);% Enable or disable this line to simulate errors in surface estimate
            
            % Check the Nyquist zone of each tds
            tds_nz = floor(tds*abs(wfs(wf).chirp_rate) / (wfs(wf).fs_raw/2));
            if any(tds_nz ~= hdr.nyquist_zone_signal{img}(rec))
              tds_nz
              warning('Nyquist zones of time delays, tds, do not all match hdr.nyquist_zone_signal{img}(rec) == %d.', hdr.nyquist_zone_signal{img}(rec));
            end
            clear tds_nz;
            
            % Check that time gate is valid (code is copied from "Pulse compress: IF->Delay" section)
            rec = 1;
            Nt_raw_trim = round(fs_raw_dec/abs(wfs(wf).chirp_rate)*diff(wfs(wf).BW_window)/2)*2;
            df_raw = wfs(wf).fs_raw/hdr.DDC_dec{img}(rec)/Nt_raw_trim;
            nz = hdr.nyquist_zone_signal{img}(rec);
            f_nz0 = wfs(wf).fs_raw * floor(nz/2);
            freq_raw =  f_nz0 + mod(hdr.DDC_freq{img}(rec) ...
              + df_raw*ifftshift(-floor(Nt_raw_trim/2):floor((Nt_raw_trim-1)/2)).', wfs(wf).fs_raw);
            conjugate_bins = ~(freq_raw >= nz*wfs(wf).fs_raw/2 ...
              & freq_raw <= (1+nz)*wfs(wf).fs_raw/2);
            if mod(nz,2)
              freq_raw(conjugate_bins) = nz*wfs(wf).fs_raw - freq_raw(conjugate_bins);
            else
              freq_raw(conjugate_bins) = (nz+1)*wfs(wf).fs_raw - freq_raw(conjugate_bins);
            end
            min_tds = min(freq_raw) / abs(wfs(wf).chirp_rate);
            if any(tds < min_tds)
              warning('Some tds < min_tds == %g.', min_tds);
            end
            max_tds = max(freq_raw) / abs(wfs(wf).chirp_rate);
            if any(tds > max_tds)
              warning('Some tds > max_tds == %g.', max_tds);
            end
            clear('Nt_raw_trim','df_raw','nz','f_nz0','freq_raw','conjugate_bins','freq_raw','min_tds','max_tds');
          end
          Tpd = wfs(wf).Tpd;
          f0 = wfs(wf).f0;
          f1 = wfs(wf).f1;
          alpha = wfs(wf).chirp_rate;
          fs_rf = Mt_oversample*wfs(wf).fs_raw/hdr.DDC_dec{img}(rec);
          time = hdr.t0_raw{img}(rec) + 1/fs_rf * (0:Nt_rf-1).';
          for rec = 1:length(tds)

            fprintf('Simulating %d of %d\n', rec, length(tds));
            td = tds(rec);

            hdr.bad_rec{img}(rec) = false;
            
            f_rf = wfs(wf).f0 + alpha*(time_raw_no_trim - hdr.surface(rec));
            if wfs(wf).f0 > wfs(wf).f1
              window_start_idx = find(f_rf <= wfs(wf).BW_window(2),1);
            else
              window_start_idx = find(f_rf >= wfs(wf).BW_window(1),1);
            end
            fprintf('  window_start_idx: %d\n', window_start_idx);
            
            hdr.DDC_dec{img}(rec) = hdr.DDC_dec{img}(1);
            hdr.DDC_freq{img}(rec) = hdr.DDC_freq{img}(1);
            hdr.nyquist_zone_signal{img}(rec) = hdr.nyquist_zone_signal{img}(1);
            hdr.t_ref{img}(rec) = hdr.t_ref{img}(1);
            hdr.t0_raw{img}(rec) = hdr.t0_raw{img}(1);
            hdr.Nt{img}(rec) = hdr.Nt{img}(1);
            
            s = tukeywin_cont((time-Tpd/2-td)/Tpd,0) .* cos(2*pi*f0*(time-td) + pi*alpha*(time-td).^2);
            r = tukeywin_cont((time-Tpd/2-tref)/Tpd,0) .* cos(2*pi*f0*(time-tref) + pi*alpha*(time-tref).^2);
            s_if_theory = 0.5*tukeywin_cont((time-Tpd/2-td/2-tref/2)/(Tpd-abs(tref-td)),0) ...
              .* (cos(2*pi*f0*(time-td) + pi*alpha*(time-td).^2 - (2*pi*f0*(time-tref) + pi*alpha*(time-tref).^2)) ...
              + cos(2*pi*f0*(time-td) + pi*alpha*(time-td).^2 + (2*pi*f0*(time-tref) + pi*alpha*(time-tref).^2)));
            s_if = s.*r; clear r s;
            
            [Bfilt,Afilt] = butter(6, wfs(wf).fs_raw/2*(hdr.nyquist_zone_signal{img}(rec)+1) / (fs_rf/2));
            s_if = filtfilt(Bfilt,Afilt,s_if);
            [Bfilt,Afilt] = butter(6, wfs(wf).fs_raw/2*(hdr.nyquist_zone_signal{img}(rec)+0) / (fs_rf/2),'high');
            s_if = filtfilt(Bfilt,Afilt,s_if);
            s_if_theory = 0.5*tukeywin_cont((time-Tpd/2-td/2-tref/2)/(Tpd-abs(tref-td)),0) ...
              .* cos(2*pi*f0*(time-td) + pi*alpha*(time-td).^2 - (2*pi*f0*(time-tref) + pi*alpha*(time-tref).^2));
            
            % Decimate to fs_raw
            s_if = s_if(1:Mt_oversample/hdr.DDC_dec{img}(rec):end);
            time_dec = time(1:Mt_oversample/hdr.DDC_dec{img}(rec):end);
            
            % Digital down conversion
            s_if = s_if .* exp(-1i*2*pi*hdr.DDC_freq{img}(rec)*time_dec);
            
            if hdr.DDC_dec{img}(rec) ~= 1
              [Bfilt,Afilt] = butter(6, 1/hdr.DDC_dec{img}(rec));
              s_if = filtfilt(Bfilt,Afilt,s_if);
            end
            
            % Decimate by DDC_dec
            s_if = s_if(1:hdr.DDC_dec{img}(rec):end);
            
            data{img}(:,rec,wf_adc) = s_if;
          end
          store_data = data;
          store_Nt = hdr.Nt{img};
          
        elseif 0
          % ENABLE_FOR_DEBUG
          % Use previously generated simulated data
          data = store_data;
          hdr.Nt{img} = store_Nt;
        end
        
        %% Pulse compress: Deramp
        freq_axes_changed = false;
        first_good_rec = true; % true until the time/freq axes created for the first time
        if wf_adc == 1
          new_Nt = hdr.Nt{img};
        end
        for rec = 1:size(data{img},2)
          
          if hdr.bad_rec{img}(rec)
            % Bad record, do nothing except make sure the record length is
            % 0 so that the data record will be filled with NaN
            hdr.Nt{img}(rec) = 0;
            hdr.t0{img}(rec) = NaN;
            continue;
          end
          
          fs_raw_dec = wfs(wf).fs_raw ./ hdr.DDC_dec{img}(rec);
          
          Nt_raw_trim = fs_raw_dec/abs(wfs(wf).chirp_rate)*diff(wfs(wf).BW_window);
          if abs(Nt_raw_trim/2 - round(Nt_raw_trim/2)) > 1e-6
            BW_window_step_size = 2*wfs(wf).chirp_rate / (wfs(wf).fs_raw/max(hdr.DDC_dec{img}));
            BW_window_new = round(wfs(wf).BW_window/BW_window_step_size)*BW_window_step_size;
            error('Bandwidth indicated by wfs(%d).BW_window must be an integer multiple of two times the chirp rate (wfs(%d).chirp_rate=%.14f) divided by the sampling frequency (wfs(%d).fs_raw/max(hdr.DDC_dec{%d})=%.14f). The maximum should be taken over the DDC_dec setting for every record in the segment; what is printed here is just the currently loaded block of data. Recommend [%.14f %.14f].', wf, wf, wfs(wf).chirp_rate, wf, img, BW_window_step_size, BW_window_new);
          end
          % Remove rounding errors
          Nt_raw_trim = round(Nt_raw_trim);
          
          df_raw = wfs(wf).fs_raw/hdr.DDC_dec{img}(rec)/Nt_raw_trim;
          DDC_freq_adjust = mod(hdr.DDC_freq{img}(rec),df_raw);
          hdr.DDC_freq{img}(rec) = hdr.DDC_freq{img}(rec) - DDC_freq_adjust;

          % Check to see if this is the first good record and the time/freq
          % axis need to be created for the first time or if the time/freq
          % axes has changed since the last record because of header
          % changes and need to be regenerated
          if first_good_rec ...
              || hdr.DDC_dec{img}(rec) ~= hdr.DDC_dec{img}(rec-1) ...
              || hdr.DDC_freq{img}(rec) ~= hdr.DDC_freq{img}(rec-1) ...
              || hdr.nyquist_zone_signal{img}(rec) ~= hdr.nyquist_zone_signal{img}(rec-1)
            
            first_good_rec = false;
            freq_axes_changed = true;
            
            %% Pulse compress Deramp: Output time
            % The output time axes for every choice of DDC_dec must have
            % the same sample spacing. We compute the resampling ratio
            % required to achieve this in the pulse compressed time domain.
            if 0
              % ENABLE_FOR_DEBUG_OUTPUT_TIME_SAMPLING
              wf = 1;
              img = 1;
              rec = 1;
              wfs(wf).fs_raw = 250e6;
              wfs(wf).chirp_rate = 16e9/240e-6;
              wfs(wf).BW_window = [2.7e9 17.5e9];
              hdr.DDC_dec{img}(rec) = 5;
              
              wfs(wf).f0 = 2e9;
              wfs(wf).f1 = 18e9;
              wfs(wf).Tpd = 240e-6;
              BW = wfs(wf).f1-wfs(wf).f0;
              wfs(wf).chirp_rate = BW/wfs(wf).Tpd;
              hdr.t_ref{img}(rec) = 0e-6;
              tguard = 1e-6;
              td_max = 4e-6;
              td_min = 1e-6;
              tref = hdr.t_ref{img}(rec);
              hdr.t0_raw{img}(rec) = -tguard + min(td_max,tref);
              wfs(wf).Tadc_adjust = 0;
              fs_nyquist = max(wfs(wf).f0,wfs(wf).f1)*5;
              Mt_oversample = ceil(fs_nyquist/wfs(wf).fs_raw);
              fs_rf = Mt_oversample*wfs(wf).fs_raw;
              Nt_rf = round((wfs(wf).Tpd + max(td_max,tref) - min(td_min,tref) + 2*tguard)*fs_rf/Mt_oversample)*Mt_oversample;
              hdr.Nt{img}(rec) = Nt_rf / Mt_oversample;
            end
            % In case the decimation length does not align with the desired
            % length, Nt_desired, we determine what resampling is required
            % and store this in p,q.
            Nt_desired = wfs(wf).fs_raw/abs(wfs(wf).chirp_rate)*diff(wfs(wf).BW_window);
            if abs(Nt_desired/2 - round(Nt_desired/2)) > 1e-6
              error('wfs(%d).BW_window must be an integer multiple of two times the wfs(wf).chirp rate divided by sampling frequency. See BW_window_gen.m for help.');
            end
            % Remove rounding errors
            Nt_desired = round(Nt_desired);
            if 0
              % Debug: Test how fast different data record lengths are
              for Nt_raw_trim_test=Nt_raw_trim+(0:10)
                Nt_raw_trim_test
                tic; for run = 1:4; fft(rand(Nt_raw_trim_test,2000)); fft(rand(floor(Nt_raw_trim_test/2)+1,2000)); end; toc;
              end
            end
            [p,q] = rat(Nt_raw_trim*hdr.DDC_dec{img}(rec) / Nt_desired);
            % Create raw time domain window
            H_Nt = wfs(wf).ft_wind(Nt_raw_trim);
            % Create original raw time axis
            t0 = hdr.t0_raw{img}(rec) + wfs(wf).Tadc_adjust;
            dt_raw = 1/fs_raw_dec;
            time_raw_no_trim = (t0:dt_raw:t0+dt_raw*(hdr.Nt{img}(rec)-1)).';
            if 0
              % Debug code to estimate wfs(wf).Tadc_adjust
              test_wf = fft(data{1}(:,rec));
              [max_val,max_idx] = max(lp(test_wf));
              mask = false(size(test_wf));
              mask(lp(test_wf) > max_val-10) = true;
              mask(find(mask,1,'first') + [-450:500]) = true;
              mask(find(mask,1,'last') + [-500:450]) = true;
              plot(mask);
              figure(1); clf;
              plot(lp(test_wf));
              hold on;
              plot(find(mask), lp(test_wf(mask)),'.');
              test_wf(~mask) = 0;
              test_wf = ifft(test_wf);
              figure(1); clf;
              plot(time_raw_no_trim*1e6, abs(test_wf))
              hold on;
              grid on;
              xlabel('Time (us)');
              ylabel('Magnitude voltage (V)');
              plot(1.713 + [12 12],ylim,'k-','LineWidth',2);
              plot(240-[12 12],ylim,'k-','LineWidth',2);
              plot(1.713 + [0 0],ylim,'r-','LineWidth',2);
              plot(240-[0 0],ylim,'r-','LineWidth',2);
              saveas(1,'keysight_raw_data.jpg');
            end
            % Create RF frequency axis for minimum delay to surface
            % expected
            % td_mean: t_rf (RF time of arrival) relative to the t_ref (REF
            %   time of arrival), td_mean is NOT the mean delay and should be
            %   renamed.
            f_rf = wfs(wf).f0 + wfs(wf).chirp_rate*(time_raw_no_trim - wfs(wf).td_mean);
            if wfs(wf).f0 > wfs(wf).f1
              window_start_idx_norm = find(f_rf <= wfs(wf).BW_window(2),1);
            else
              window_start_idx_norm = find(f_rf >= wfs(wf).BW_window(1),1);
            end
            
            if 0
              % ENABLE_FOR_DEBUG_OUTPUT_TIME_SAMPLING
              df_before_resample = 1 / (Nt_raw_trim/wfs(wf).fs_raw*hdr.DDC_dec{img}(rec))
              df_after_resample = df_before_resample * p / q
              df_desired = 1 / (Nt_desired/wfs(wf).fs_raw)
              Nt_desired
              Nt_raw_trim
              p
              q
            end
            
            %% Pulse compress Deramp: IF->Delay
            % =============================================================
            if 0
              % ENABLE_FOR_DEBUG_FREQ_MAP
              img = 1;
              rec = 1;
              hdr.Nt{img}(rec) = 10000;
              Nt_raw_trim = 10000;
              hdr.DDC_dec{img}(rec) = 3;
              wfs(wf).fs_raw = 100e6;
              hdr.nyquist_zone_signal{img}(rec) = 1;
              hdr.DDC_freq{img}(rec) = 95e6;
            end
            
            if wfs(wf).nz_complex
              % The signal can cross nyquist zones because it is complex.
              % Currently the code assumes that the signal is represented
              % in complex baseband in the first nyquist zone.
              nz = 0;
              
              freq_raw =  hdr.DDC_freq{img}(rec) ...
                + df_raw*ifftshift(-floor(Nt_raw_trim/2):floor((Nt_raw_trim-1)/2)).';
              freq_raw_valid = freq_raw;
              
              conjugate_bins = false(size(freq_raw_valid));
              
            else
              
              % nz: Nyquist zone containing signal spectrum (just renaming
              %   variable for convenience). The assumption is that the
              %   signal does not cross nyquist zones.
              nz = hdr.nyquist_zone_signal{img}(rec);
              
              % f_nz0: Lowest frequency in terms of ADC input frequency of the
              %   nyquist zone which contains the signal
              f_nz0 = wfs(wf).fs_raw * floor(nz/2);
              
              % freq_raw: Frequency axis of raw data assuming that raw signal
              % spectrum is restricted to the frequency range [(N-1)*fs N*fs]
              % where N is chosen so that the selected nyquist zone lies
              % within this frequency range.
              freq_raw =  f_nz0 + mod(hdr.DDC_freq{img}(rec) ...
                + df_raw*ifftshift(-floor(Nt_raw_trim/2):floor((Nt_raw_trim-1)/2)).', wfs(wf).fs_raw);
              freq_raw_valid = freq_raw;
              
              % conjugate_bins: logical mask indicating which bins are
              % conjugated, this is also used to determine how frequencies
              % are wrapped in the nyquist zone when real only sampling is
              % used (for DFT there are 1 or 2 bins which are real-only and
              % these are marked to be conjugated by using >= and <=; since
              % conjugation of these real only bins makes no difference the
              % only reason to do this is because of the nyquist zone
              % wrapping)
              conjugate_bins = ~(freq_raw_valid >= nz*wfs(wf).fs_raw/2 ...
                & freq_raw_valid <= (1+nz)*wfs(wf).fs_raw/2);
              
              % freq_raw_valid: modified to handle wrapping at Nyquist
              % boundaries
              if mod(nz,2)
                freq_raw_valid(conjugate_bins) = nz*wfs(wf).fs_raw - freq_raw_valid(conjugate_bins);
              else
                freq_raw_valid(conjugate_bins) = (nz+1)*wfs(wf).fs_raw - freq_raw_valid(conjugate_bins);
              end
              
            end
            
            % freq_raw_valid: reduce rounding errors so that unique will
            % work properly
            freq_raw_valid = df_raw*round(freq_raw_valid/df_raw);
            
            % Only keep the unique frequency bins
            [~,unique_idxs,return_idxs] = unique(freq_raw_valid);
            
            freq_raw_unique = freq_raw_valid(unique_idxs);
            conjugate_unique = conjugate_bins(unique_idxs);
            % unique_idxs(~valid_bins);
            
            if 0
              % ENABLE_FOR_DEBUG_FREQ_MAP
              figure(1);
              clf;
              plot(freq_raw_valid,'.')
              hold on
              freq_raw_valid(conjugate_bins) = NaN;
              plot(freq_raw_valid,'r.')
              grid on
              xlabel('Bin (original order)');
              ylabel('Frequency (Hz)');
              legend('conj','-','location','best');
              
              figure(2);
              clf;
              plot(freq_raw_unique,'.')
              hold on
              tmp = freq_raw_unique;
              tmp(~conjugate_unique) = NaN;
              plot(tmp,'r.')
              grid on
              xlabel('Bin (reordered)');
              ylabel('Frequency (Hz)');
            end
            
            %% Pulse compress Deramp: IF->Delay (Coh Noise)
            if strcmpi(wfs(wf).coh_noise_method,'analysis')
              % =============================================================
              
              cn.df_raw = wfs(wf).fs_raw/hdr.DDC_dec{img}(rec)/Nt_raw_trim;
              
              if wfs(wf).nz_complex
                % The signal can cross nyquist zones because it is complex.
                % Currently the code assumes that the signal is represented
                % in complex baseband in the first nyquist zone.
                cn.nz = 0;
                
                cn.freq_raw =  hdr.DDC_freq{img}(rec) ...
                  + cn.df_raw*ifftshift(-floor(Nt_raw_trim/2):floor((Nt_raw_trim-1)/2)).';
                cn.freq_raw_valid = cn.freq_raw;
                
                cn.conjugate_bins = false(size(cn.freq_raw_valid));
                
              else
                % nz: Nyquist zone containing signal spectrum (just renaming
                %   variable for convenience). The assumption is that the
                %   signal does not cross nyquist zones.
                cn.nz = double(hdr.nyquist_zone_hw{img}(rec));
                
                % f_nz0: Lowest frequency in terms of ADC input frequency of the
                %   nyquist zone which contains the signal
                cn.f_nz0 = wfs(wf).fs_raw * floor(cn.nz/2);
                
                cn.freq_raw =  cn.f_nz0 + mod(hdr.DDC_freq{img}(rec) ...
                  + cn.df_raw*ifftshift(-floor(Nt_raw_trim/2):floor((Nt_raw_trim-1)/2)).', wfs(wf).fs_raw);
                cn.freq_raw_valid = cn.freq_raw;
                
                cn.conjugate_bins = ~(cn.freq_raw_valid >= cn.nz*wfs(wf).fs_raw/2 ...
                  & cn.freq_raw_valid <= (1+cn.nz)*wfs(wf).fs_raw/2);
                
                if mod(cn.nz,2)
                  cn.freq_raw_valid(cn.conjugate_bins) = cn.nz*wfs(wf).fs_raw - cn.freq_raw_valid(cn.conjugate_bins);
                else
                  cn.freq_raw_valid(cn.conjugate_bins) = (cn.nz+1)*wfs(wf).fs_raw - cn.freq_raw_valid(cn.conjugate_bins);
                end
              end
              
              cn.freq_raw_valid = cn.df_raw*round(cn.freq_raw_valid/cn.df_raw);
              
              [~,cn.unique_idxs,cn.return_idxs] = unique(cn.freq_raw_valid);
              
              cn.freq_raw_unique = cn.freq_raw_valid(cn.unique_idxs);
              cn.conjugate_unique = cn.conjugate_bins(cn.unique_idxs);
            end
            
          end
          
          % Check to see if reference time offset has changed since last record
          if freq_axes_changed ...
              || hdr.t_ref{img}(rec) ~= hdr.t_ref{img}(rec-1)
            
            freq_axes_changed = false; % Reset state
            
            %% Pulse compress Deramp: Time axis
            
            % Convert IF frequency to time delay and account for reference
            % deramp time offset, hdr.t_ref
            time = freq_raw_unique/abs(wfs(wf).chirp_rate) + hdr.t_ref{img}(rec);
            
            % Ensure that start time is a multiple of dt:
            % 1. freq_raw_unique/abs(wfs(wf).chirp_rate) is always a
            %    multiple of dt because of constraints on freq_raw_unique
            % 2. Therefore we only need to consider hdr.t_ref{img}(rec).
            %    This is done because of rounding errors that may occur if
            %    mod(time(1),dt) was used.
            dt = time(2)-time(1);
            time_correction = dt - mod(hdr.t_ref{img}(rec),dt);
            time = time + time_correction;
            
            fc = sum(wfs(wf).BW_window)/2;
            Nt = length(time);
            T = Nt*dt;
            df = 1/T;
            freq = fc + df * ifftshift(-floor(Nt/2) : floor((Nt-1)/2)).';
            
            deskew = exp(-1i*pi*wfs(wf).chirp_rate*(time-wfs(wf).td_mean).^2);
            deskew_shift = 1i*2*pi*(0:Nt_raw_trim-1).'/Nt_raw_trim;
            time_correction_freq = exp(1i*2*pi*(freq-fc)*time_correction);
            
            %% Pulse compress Deramp: Time axis (Coh Noise)
            if strcmpi(wfs(wf).coh_noise_method,'analysis')
              
              % Convert IF frequency to time delay and account for reference
              % deramp time offset, hdr.t_ref
              cn.time = cn.freq_raw_unique/abs(wfs(wf).chirp_rate) + hdr.t_ref{img}(rec);
              
              % Ensure that start time is a multiple of dt:
              % 1. freq_raw_unique/abs(wfs(wf).chirp_rate) is always a
              %    multiple of dt because of constraints on freq_raw_unique
              % 2. Therefore we only need to consider hdr.t_ref{img}(rec).
              %    This is done because of rounding errors that may occur if
              %    mod(time(1),dt) was used.
              cn.dt = cn.time(2)-cn.time(1);
              cn.time_correction = cn.dt - mod(hdr.t_ref{img}(rec),cn.dt);
              cn.time = cn.time + cn.time_correction;
              
              fc = sum(wfs(wf).BW_window)/2;
              Nt = length(cn.time);
              T = Nt*dt;
              df = 1/T;
              cn.freq = fc + df * ifftshift(-floor(Nt/2) : floor((Nt-1)/2)).';
              
              % cn.deskew: handled differently below
              % cn.deskew_shift: handled differently below
              cn.time_correction_freq = exp(1i*2*pi*(cn.freq-fc)*cn.time_correction);
              
              
              % Handle changes between when the noise file was created and
              % this current processing.
              % 1. Check for a fast-time sample interval discrepancy
              if abs(noise.dt-cn.dt)/cn.dt > 1e-6
                error('There is a fast-time sample interval discrepancy between the current processing settings (%g) and those used to generate the coherent noise file (%g).', dt, noise.dt);
              end
              % 2. Ensure that the t_ref difference is a multiple of cn.dt
              %    when the coherent noise was loaded and estimated.
              delta_t_ref_bin = (noise.param_analysis.radar.wfs(wf).t_ref - wfs(wf).t_ref)/cn.dt;
              if abs(round(delta_t_ref_bin)-delta_t_ref_bin) > 1e-3
                error('There is a fast-time reference time delay discrepancy between the current processing settings (%g) and those used to generate the coherent noise file (%g). Changes in t_ref require recreating the coherent noise file or the changes must be a multiple of a time bin (%g).', ...
                  wfs(wf).t_ref, noise.param_analysis.radar.wfs(wf).t_ref, cn.dt);
              end
              delta_t_ref_bin = round(delta_t_ref_bin);
              
              % Apply a time correction so the deskew matches the original
              % time axis used when the noise data were estimated. Only the
              % deskew is different, the cn.time_correction is required to not
              % change or else a new noise file is required.
              cn.time = cn.time + delta_t_ref_bin * cn.dt;
              
              cn.deskew = exp(-1i*pi*wfs(wf).chirp_rate*(cn.time-wfs(wf).td_mean).^2);
              cn.deskew_shift = 1i*2*pi*(0:Nt_raw_trim-1).'/Nt_raw_trim;
            end
          end
          
          % Get the start time for this record
          hdr.t0{img}(rec) = time(1);
          
          % Convert raw time into instantaneous frequency for the surface bin
          f_rf = wfs(wf).f0 + wfs(wf).chirp_rate*(time_raw_no_trim - hdr.surface(rec));
          if wfs(wf).BW_window(2) > max(f_rf)
            if ~BW_window_max_warning_printed
              BW_window_max_warning_printed = true;
              warning('BW_window (%g) is more than maximum measured RF frequency (%g) with surface twtt %g.', ...
                wfs(wf).BW_window(2), max(f_rf), hdr.surface(rec))
            end
            % Mark record as bad, but keep 2 bins to simplify later code
            %hdr.Nt{img}(rec) = 0;
            %continue
          end
          if wfs(wf).BW_window(1) < min(f_rf)
            if ~BW_window_min_warning_printed
              BW_window_min_warning_printed = true;
              warning('BW_window (%g) is less than minimum measured RF frequency (%g) with surface twtt %g.', ...
                wfs(wf).BW_window(1), min(f_rf), hdr.surface(rec))
            end
            % Mark record as bad, but keep 2 bins to simplify later code
            %hdr.Nt{img}(rec) = 2;
            %data{img}(1:hdr.Nt{img}(rec),rec,wf_adc) = NaN;
            %continue
          end
          
          % Create the window for the particular range line
          if wfs(wf).f0 > wfs(wf).f1
            window_start_idx = find(f_rf <= wfs(wf).BW_window(2),1);
          else
            window_start_idx = find(f_rf >= wfs(wf).BW_window(1),1);
          end
          f_rf = wfs(wf).f0 + wfs(wf).chirp_rate*(time_raw_no_trim - wfs(wf).td_mean);
          window_start_idx = window_start_idx_norm;
          H_idxs = window_start_idx : window_start_idx+Nt_raw_trim-1;
          if 0
            % ENABLE_FOR_DEBUG
            fprintf('window_start_idx: %d window_start_idx_norm: %d\n', ...
              window_start_idx, window_start_idx_norm);
          end
          
          % Window and Pulse compress
          if 0
            % Debug: Verify pulse compression window is correct
            clf;
            plot(lp(data{img}(H_idxs,rec,wf_adc)));
            hold on;
            plot(lp(data{img}(H_idxs,rec,wf_adc) .* H_Nt));
          end
          
          
          %% Pulse compress Deramp: FFT, Deskew, Coh Noise Removal
          
          % Window and DFT (raw deramped time to regular time)
          NCO_time = hdr.t0_raw{1}(rec) + wfs(wf).Tadc_adjust + wfs(wf).DDC_NCO_delay + (H_idxs(:)-1) /(wfs(wf).fs_raw/hdr.DDC_dec{img}(rec));
          
          tmp = fft(data{img}(H_idxs,rec,wf_adc) ...
             .* exp(1i*2*pi*DDC_freq_adjust*NCO_time) ...
             .* exp(1i*2*pi*hdr.DDC_freq{img}(rec)*NCO_time(1)) ...
             .* H_Nt);
           
          % Deskew of the residual video phase (not the standard because we
          % actually move the window to track the td)
          %tmp = tmp .* exp(deskew_shift*(window_start_idx_norm-window_start_idx));
          
          % Remove coherent noise
          if strcmpi(wfs(wf).coh_noise_method,'analysis')
            if 0
              % Debug: Create fake coherent noise based on current data
              %   Adjust the rec range to grab multiple range lines for
              %   better average:
              tmp = fft(mean(data{img}(H_idxs,rec+(0:99),wf_adc),2) .* H_Nt);
              cn.tmp = tmp(cn.unique_idxs);
              cn.tmp(cn.conjugate_unique) = conj(cn.tmp(cn.conjugate_unique));
              if wfs(wf).f0 > wfs(wf).f1
                cn.tmp = ifftshift(fft(cn.tmp));
              else
                cn.tmp = ifftshift(fft(conj(cn.tmp)));
              end
              cn.tmp = cn.tmp .* cn.time_correction_freq;
              cn.tmp = ifft(cn.tmp);
              cn.tmp = -cn.tmp .* cn.deskew;
              cn.tmp(end) = 0;
            else
              start_bin = 1 + round(cn.time(1)/cn.dt) - noise.start_bin;
              cn.tmp = cn.data(start_bin + (0:length(cn.time)-2),rec);
              cn.tmp(end+1) = 0; % Add invalid sample back in
            end
            
            % Coherent noise is fully pulse compressed. The nyquist_zone
            % set in hardware is always used for the coherent noise
            % processing even if the setting is wrong. Three steps:
            % 1: Fully pulse compress the data in the hardware nyquist zone
            % 2: Subtract the coherent noise away
            % 3: If the hardware and actual nyquist zone are different,
            %    then invert the pulse compression and repulse compress in the
            %    actual nyquist zone.
            
            % 1: Fully pulse compress the data in the hardware nyquist zone
            %    (see below for full description of pulse compression
            %    steps)
            tmp = tmp(cn.unique_idxs);
            tmp(cn.conjugate_unique) = conj(tmp(cn.conjugate_unique));
            if wfs(wf).f0 > wfs(wf).f1
              tmp = fft(tmp .* exp(-1i*2*pi*(fc-f_rf(H_idxs(1)))*cn.time));
            else
              tmp = fft(conj(tmp) .* exp(-1i*2*pi*(fc-f_rf(H_idxs(1)))*cn.time));
            end
            tmp = tmp .* cn.time_correction_freq;
            tmp = ifft(tmp);
            tmp = tmp .* cn.deskew;
            tmp(end) = 0;
            if p~=q
              tmp = resample(tmp,p,q);
            end
            
            if 0
              % Debug
              figure(1); clf;
              plot(real(tmp));
              hold on;
              plot(real(-cn.tmp),'--');
              
              figure(2); clf;
              plot(imag(tmp));
              hold on;
              plot(imag(-cn.tmp),'--');
            end
            
            % 2: Subtract the coherent noise away
            tmp = tmp + cn.tmp;
            
            % 3: If the hardware and actual nyquist zone are different,
            %    then invert the pulse compression and repulse compress in the
            %    actual nyquist zone.
            if nz ~= double(hdr.nyquist_zone_hw{img}(rec))
              % Reverse Pulse Compression:
              % Undo tmp = resample(tmp,p,q);
              if p~=q
                tmp = resample(tmp,q,p);
              end
              % Do not undo tmp(end) = 0;
              % Undo tmp = tmp .* deskew;
              tmp = tmp ./ cn.deskew;
              % Undo tmp = ifft(tmp);
              tmp = fft(tmp);
              % Undo tmp = tmp .* time_correction;
              tmp = tmp ./ cn.time_correction_freq;
              if wfs(wf).f0 > wfs(wf).f1
                % Undo tmp = fft(tmp .* exp(-1i*2*pi*(fc-f_rf(H_idxs(1)))*time));
                tmp = ifft(tmp) .* exp(1i*2*pi*(fc-f_rf(H_idxs(1)))*time);
              else
                % Undo tmp = fft(conj(tmp) .* exp(-1i*2*pi*(fc-f_rf(H_idxs(1)))*time));
                tmp = conj(ifft(tmp)) .* exp(1i*2*pi*(fc-f_rf(H_idxs(1)))*time);
              end
              % Undo tmp = tmp(unique_idxs);
              tmp = tmp(cn.return_idxs);
              % Undo tmp(conjugate_unique) = conj(tmp(conjugate_unique));
              tmp(cn.conjugate_bins) = conj(tmp(cn.conjugate_bins));
              
              % Pulse compression (see below for full description)
              tmp = tmp(unique_idxs);
              tmp(conjugate_unique) = conj(tmp(conjugate_unique));
              if wfs(wf).f0 > wfs(wf).f1
                tmp = fft(tmp .* exp(-1i*2*pi*(fc-f_rf(H_idxs(1)))*time));
              else
                tmp = fft(conj(tmp) .* exp(-1i*2*pi*(fc-f_rf(H_idxs(1)))*time));
              end
              tmp = tmp .* time_correction_freq;
              tmp = ifft(tmp);
              tmp = tmp .* deskew;
              % tmp(end) = 0; % Skip since it was not undone
              if p~=q
                tmp = resample(tmp,p,q);
              end
              
              % 4: If only the delta t_ref is different,  then invert the
              %    coherent noise deskew and then apply the new deskew.
            elseif delta_t_ref_bin ~= 0
              %
              tmp = tmp ./ cn.deskew .* deskew;
            end
            
          else
            % FULL DESCRIPTION OF PULSE COMPRESSION STEPS
            
            % Reorder result in case IF frequency spectrum is wrapped
            tmp = tmp(unique_idxs);
            
            % Some of the frequency bins are conjugated versions of the
            % positive frequency domain signal
            tmp(conjugate_unique) = conj(tmp(conjugate_unique));
            
            % Complex baseband data (shifts by ~Tpd/2)
            if wfs(wf).f0 > wfs(wf).f1
              % Negative chirp: the initial DFT causes a frequency domain reversal
              % which flips the frequency domain to start from a low frequency and
              % increase to a high frequency (what is meant by this is that "f0"
              % ends up at the digital frequency "zero" and the RF frequencies with
              % digital frequency). The negative chirp also has the correct sign
              % for td:
              %   exp(-j*2*pi*f0*(t_d-t_ref)).
              %
              % Therefore, only a circular shift is required to complex baseband
              % the data.
              tmp = fft(tmp .* exp(-1i*2*pi*(fc-f_rf(H_idxs(1)))*time));
            else
              % Positive chirp: the initial DFT causes a frequency domain reversal
              % which flips the frqeuency domain so that the RF frequency mapping
              % to digital frequencies is reversed (higher digital frequency
              % corresponds to lower RF frequency). The positive chirp also has the
              % opposite sign for td:
              %   exp(-j*2*pi*f0*(t_d-t_ref)).
              %
              % The frequency reversal and conjugation are fixed by conjugating the
              % signal before the FFT.
              tmp = fft(conj(tmp) .* exp(-1i*2*pi*(fc-f_rf(H_idxs(1)))*time));
            end
            
            % Modulate the raw data to adjust the start time to always be a
            % multiple of wfs(wf).dt. Since we want this adjustment to be a
            % pure time shift and not introduce any phase shift in the other
            % domain, we make sure the phase is zero in the center of the
            % window: -time_raw(1+floor(Nt/2))
            tmp = tmp .* time_correction_freq;
            
            % Return to time domain
            tmp = ifft(tmp);
            
            % Deskew of the residual video phase (second stage)
            tmp = tmp .* deskew;
            
            % Last sample set to zero (invalid sample)
            tmp(end) = 0;
            
            % Resample data so it aligns to constant time step
            if p~=q
              tmp = resample(tmp,p,q);
            end
          end
          
          % Update the data matrix with the pulse compressed waveform and
          % handle nz_trim
          if length(param.radar.wfs(wf).nz_trim) >= nz+1
            tmp = tmp(1+param.radar.wfs(wf).nz_trim{nz+1}(1) : end-1-param.radar.wfs(wf).nz_trim{nz+1}(2));
            hdr.t0{img}(rec) = hdr.t0{img}(rec) + dt*param.radar.wfs(wf).nz_trim{nz+1}(1);
          else
            tmp = tmp(1 : end-1);
          end
          if wf_adc == 1
            new_Nt(rec) = length(tmp);
          end
          data{img}(1:new_Nt(rec),rec,wf_adc) = tmp;
        end
        
        if 0
          % ENABLE_FOR_DEBUG
          figure(1); clf;
          Mt = 10;
          data_oversampled = interpft(data{img}(1:new_Nt(rec),:,wf_adc), new_Nt(rec)*Mt);
          [~,idx] = max(data_oversampled);
          time_oversampled = time(1) + dt/Mt* (0:new_Nt(rec)*Mt-1).';
          plot((time_oversampled(idx).' - tds)/dt)
          grid on;
          xlabel('Record');
          ylabel('Time error (\Delta_t)');
          
          figure(2); clf;
          phase_sim = max(data{img}(1:new_Nt(rec),:,wf_adc));
          [~,ref_idx] = min(abs(tds-wfs(wf).td_mean));
          plot(angle(phase_sim./phase_sim(ref_idx)),'+-');
          hold on
          fc_window = mean(wfs(wf).BW_window);
          phase_theory = exp(-1i*2*pi*fc_window*tds);
          plot(angle(phase_theory./phase_theory(ref_idx)),'.--');
          xlabel('Record');
          ylabel('Phase (rad)');
          legend('Simulated','Theory');
          grid on;
        end
        
        %% Pulse compress Deramp: Corrections, Constant Nt
        
        % Create a matrix of data with constant time rows, fill invalid samples with NaN
        if wf_adc == 1
          if all(isnan(hdr.t0{img}))
            % All records are bad
            idx_start = 0;
            wfs(wf).Nt = 0;
            dt = 1;
          else
            idx_start = min(round(hdr.t0{img}/dt));
            wfs(wf).Nt = max(round(hdr.t0{img}/dt) + new_Nt)-idx_start;
          end
          hdr.time{img} = idx_start*dt + dt*(0:wfs(wf).Nt-1).';
          fc = sum(wfs(wf).BW_window)/2;
          T = wfs(wf).Nt*dt;
          df = 1/T;
          hdr.freq{img} = fc + df * ifftshift(-floor(wfs(wf).Nt/2) : floor((wfs(wf).Nt-1)/2)).';
        end
        
        % Method of copying to make this more efficient for very large
        % complex (real/imag) arrays. Lots of small matrix operations on
        % huge complex matrices is very slow in matlab. Real only matrices
        % are very fast though.
        blocks = round(linspace(1,size(data{img},2)+1,8)); blocks = unique(blocks);
        for block = 1:length(blocks)-1
          rlines = blocks(block) : blocks(block+1)-1;
          
          reD = real(data{img}(:,rlines,wf_adc));
          imD = imag(data{img}(:,rlines,wf_adc));
          for rec = 1:length(rlines)
            if isnan(hdr.t0{img}(rlines(rec)))
              % This is a bad record
              cur_idx_start = 1;
              cur_idx_stop = 0;
            else
              cur_idx_start = round(hdr.t0{img}(rlines(rec))/dt) - idx_start + 1;
              cur_idx_stop = round(hdr.t0{img}(rlines(rec))/dt) - idx_start + new_Nt(rlines(rec));
            end
            
            reD(cur_idx_start : cur_idx_stop,rec) = reD(1:new_Nt(rlines(rec)),rec);
            reD(1:cur_idx_start-1,rec) = wfs(wf).bad_value;
            reD(cur_idx_stop+1 : wfs(wf).Nt,rec) = wfs(wf).bad_value;
          end
          for rec = 1:length(rlines)
            if isnan(hdr.t0{img}(rlines(rec)))
              % This is a bad record
              cur_idx_start = 1;
              cur_idx_stop = 0;
            else
              cur_idx_start = round(hdr.t0{img}(rlines(rec))/dt) - idx_start + 1;
              cur_idx_stop = round(hdr.t0{img}(rlines(rec))/dt) - idx_start + new_Nt(rlines(rec));
            end
            
            imD(cur_idx_start : cur_idx_stop,rec) = imD(1:new_Nt(rlines(rec)),rec);
            imD(1:cur_idx_start-1,rec) = wfs(wf).bad_value;
            imD(cur_idx_stop+1 : wfs(wf).Nt,rec) = wfs(wf).bad_value;
          end
          data{img}(1:wfs(wf).Nt,rlines,wf_adc) = reD(1:wfs(wf).Nt,:) + 1i*imD(1:wfs(wf).Nt,:);
          
          % Corrections:
          % Apply wf-adc specific channel equalization (for multichannel
          % systems). For pulsed systems this is taken care of in
          % data_load.m in corrections.
          chan_equal = 10.^(param.radar.wfs(wf).chan_equal_dB(param.radar.wfs(wf).rx_paths(adc))/20) ...
            .* exp(1i*param.radar.wfs(wf).chan_equal_deg(param.radar.wfs(wf).rx_paths(adc))/180*pi);
          data{img}(1:wfs(wf).Nt,rlines,wf_adc) = chan_equal .* data{img}(1:wfs(wf).Nt,rlines,wf_adc);
          
          % Corrections:
          % Apply wf-adc specific system time delay (for multichannel
          % systems). For pulsed systems this is taken care of in
          % data_load_wfs.m where the reference function is created.
          Tsys = param.radar.wfs(wf).Tsys(param.radar.wfs(wf).rx_paths(adc));
          if Tsys ~= 0
            % Positive Tsys means the time delay to the target is too large
            % and we should reduce the time delay to all targets by Tsys.
            data{img}(1:wfs(wf).Nt,rlines,wf_adc) ...
              = ifft(bsxfun(@times, ...
              fft(data{img}(1:wfs(wf).Nt,rlines,wf_adc),[],1), ...
              exp(1i*2*pi*hdr.freq{img}*Tsys)),[],1);
          end
          
        end
        clear reD imD;
        
      elseif strcmpi(radar_type,'stepped')
        
      end
      
    else
      %% No pulse compress
      if wf_adc == 1
        if strcmpi(radar_type,'pulsed')
          hdr.time{img} = wfs(wf).time_raw;
          hdr.freq{img} = wfs(wf).freq_raw;
          
        elseif strcmpi(radar_type,'deramp')
          % Time axis is not valid if DDC or time offset changes
          hdr.time{img} = hdr.t0_raw{img}(1) + wfs(wf).Tadc_adjust + hdr.DDC_dec{1}(1)/wfs(wf).fs_raw*(0:hdr.Nt{img}-1).';
          % Frequency is not valid
          df = wfs(wf).fs_raw / hdr.Nt{img}(1);
          hdr.freq{img} = df*(0:hdr.Nt{img}-1).';
          
        elseif strcmpi(radar_type,'stepped')
        end
      end
    end
    
    %% Coherent noise: Deramp
    % ===================================================================
    if strcmpi(radar_type,'deramp')
      
      if strcmpi(wfs(wf).coh_noise_method,'estimated')
        % Apply coherent noise methods that require estimates derived now
        
        if wfs(wf).coh_noise_arg.DC_remove_en
          data{img}(1:wfs(wf).Nt,:,wf_adc) = bsxfun(@minus, data{img}(1:wfs(wf).Nt,:,wf_adc), ...
            nanmean(data{img}(1:wfs(wf).Nt,:,wf_adc),2));
        end
        
        if length(wfs(wf).coh_noise_arg.B_coh_noise) > 1
          if length(wfs(wf).coh_noise_arg.A_coh_noise) > 1
            % Use filtfilt (feedback)
            data{img}(1:wfs(wf).Nt,:,wf_adc) = single(filtfilt(wfs(wf).coh_noise_arg.B_coh_noise, ...
              wfs(wf).coh_noise_arg.A_coh_noise, double(data{img}(1:wfs(wf).Nt,:,wf_adc).'))).';
          else
            % Use fir_dec (no feedback)
            data{img}(1:wfs(wf).Nt,:,wf_adc) = fir_dec(data{img}(1:wfs(wf).Nt,:,wf_adc),wfs(wf).coh_noise_arg.B_coh_noise,1);
          end
        end
        
      end
    end
    
    %% Coherent noise: Pulsed
    % ===================================================================
    if 0
      % Debug Test Code
      before = data{img}(1:wfs(wf).Nt,:,wf_adc);
    end
    if strcmpi(radar_type,'pulsed')
      if strcmpi(wfs(wf).coh_noise_method,'analysis')
        if strcmpi(noise.param_collate_coh_noise.collate_coh_noise.method{collate_coh_noise_img},'dft')
          for dft_idx = 1:length(noise.dft_freqs)
            % mf: matched filter
            % coh_noise(bin,dft_idx): Coefficient for the matched filter
            mf = exp(1i*2*pi/noise.Nx*noise.dft_freqs(dft_idx) .* recs);
            for bin = 1:size(coh_noise,1)
              data{img}(bin,:,wf_adc) = data{img}(bin,:,wf_adc)-coh_noise(bin,dft_idx) * mf;
            end
          end
          
        elseif strcmpi(noise.param_collate_coh_noise.collate_coh_noise.method{collate_coh_noise_img},'firdec')
          blocks = round(linspace(1,size(data{img},2)+1,8)); blocks = unique(blocks);
          rel_gps_time = single(noise.firdec_gps_time - noise.firdec_gps_time(1));
          rel_gps_time_interp = single(hdr.gps_time - noise.firdec_gps_time(1));
          for block = 1:length(blocks)-1
            rlines = blocks(block) : blocks(block+1)-1;
            
            if rel_gps_time_interp(rlines(1)) > rel_gps_time(end)
              % Raw data are all after the last coherent noise sample
              data{img}(1:size(coh_noise,1),rlines,wf_adc) = bsxfun(@minus, ...
                data{img}(1:size(coh_noise,1),rlines,wf_adc), coh_noise(:,end));
            elseif rel_gps_time_interp(rlines(end)) < rel_gps_time(1)
              % Raw data are all before the first coherent noise sample
              data{img}(1:size(coh_noise,1),rlines,wf_adc) = bsxfun(@minus, ...
                data{img}(1:size(coh_noise,1),rlines,wf_adc), coh_noise(:,1));
            else
              % At least one raw data point exists within the coherent noise
              % gps time sampling range
              data{img}(1:size(coh_noise,1),rlines,wf_adc) = data{img}(1:size(coh_noise,1),rlines,wf_adc) ...
                - interp_finite(interp1(rel_gps_time, single(coh_noise.'), rel_gps_time_interp(rlines)),0).';
            end
          end
        end
      end
    end
    if 0
      % Debug Test Code
      after = data{img}(1:wfs(wf).Nt,:,wf_adc);
      Nfir = 51;
      beforef = fir_dec(before,Nfir);
      afterf = fir_dec(after,Nfir);
      figure(1); clf;
      imagesc(lp(beforef));
      cc=caxis;
      colormap(1-gray(256));
      h_axes = gca;
      figure(2); clf;
      imagesc(lp(afterf));
      caxis(cc);
      colormap(1-gray(256));
      h_axes(end+1) = gca;
      linkaxes(h_axes);
      
      figure(3); clf;
      rline = min(size(afterf,2),61);
      plot(lp(beforef(:,rline)));
      hold on;
      plot(lp(afterf(:,rline)));
    end
        
    %% Deconvolution
    % ===================================================================
    if param.load.pulse_comp == 1 && wfs(wf).deconv.en && wfs(wf).Nt > 0
      deconv_fn = fullfile(fileparts(ct_filename_out(param,wfs(wf).deconv.fn, '')), ...
        sprintf('deconv_%s_wf_%d_adc_%d.mat',param.day_seg, wf, adc));
      fprintf('  Loading deconvolution: %s (%s)\n', deconv_fn, datestr(now));
      deconv = load(deconv_fn);
      param.collate_deconv.param_collate_deconv_final = deconv.param_collate_deconv_final;
      param.collate_deconv.param_collate_deconv = deconv.param_collate_deconv;
      param.collate_deconv.param_analysis = deconv.param_analysis;
      param.collate_deconv.param_records = deconv.param_records;
      
      deconv_map_idxs = interp1(deconv.map_gps_time,deconv.map_idxs,hdr.gps_time,'nearest','extrap');
      max_score = interp1(deconv.map_gps_time,deconv.max_score,hdr.gps_time,'nearest','extrap');
      
      unique_idxs = unique(deconv_map_idxs);
      
      f0 = param.collate_deconv.param_collate_deconv.collate_deconv.f0;
      f1 = param.collate_deconv.param_collate_deconv.collate_deconv.f1;
      if wf_adc > 1 && abs(deconv_fc - (f0+f1)/2)/deconv_fc > 1e-6
        error('Deconvolution center frequency must be the same for all wf-adc pairs in the image. Was %g and is now %g.', deconv_fc, (f0+f1)/2);
      end
      % Prepare variables
      fc = hdr.freq{img}(1);
      
      % Prepare variables to baseband data to new center frequency (in
      % case the deconvolution filter subbands)
      deconv_fc = (f0+f1)/2;
      df = hdr.freq{img}(2)-hdr.freq{img}(1);
      BW = df * wfs(wf).Nt;
      deconv_dfc = deconv_fc - fc;
      if wf_adc == 1
        new_deconv_hdr_freq = mod(hdr.freq{img} + deconv_dfc-wfs(wf).BW_window(1), BW)+wfs(wf).BW_window(1);
      end
      
      for unique_idxs_idx = 1:length(unique_idxs)
        % deconv_mask: Create logical mask corresponding to range lines that use this deconv waveform
        deconv_map_idx = unique_idxs(unique_idxs_idx);
        deconv_mask = deconv_map_idx == deconv_map_idxs;
        % deconv_mask = deconv_map_idx == deconv_map_idxs ...
        %   & max_score > deconv.param_collate_deconv_final.collate_deconv.min_score;
        
        if wfs(wf).Nt <= 2 || ~any(deconv_mask)
          % Range lines are bad (Nt <= 2), or no matching range lines that
          % have a good enough score to justify deconvolution.
          continue;
        end
        
        % Get the reference function
        h_nonnegative = deconv.ref_nonnegative{deconv_map_idx};
        h_negative = deconv.ref_negative{deconv_map_idx};
        h_mult_factor = deconv.ref_mult_factor(deconv_map_idx);
        h_ref_length = length(h_nonnegative)+length(h_negative)-1;
        
        % Adjust deconvolution signal to match sample rline
        h_filled = [h_nonnegative; zeros(wfs(wf).Nt-1,1); h_negative];
        
        % Is dt different? Error
        dt = hdr.time{img}(2)-hdr.time{img}(1);
        if abs(deconv.dt-dt)/dt > 1e-6
          error('There is fast-time sample interval discrepancy between the current processing settings (%g) and those used to generate the deconvolution file (%g).', dt, deconv.dt);
        end
        
        % Adjust length of FFT to avoid circular convolution
        deconv_Nt = wfs(wf).Nt + h_ref_length;
        deconv_freq = fftshift(fc + 1/(deconv_Nt*dt) * ifftshift(-floor(deconv_Nt/2) : floor((deconv_Nt-1)/2)).');
        
        % Is fc different? Multiply time domain by exp(1i*2*pi*dfc*deconv_time)
        dfc = fc - deconv.fc(deconv_map_idx);
        if dfc/fc > 1e-6
          deconv_time = t0 + dt*(0:deconv_Nt-1).';
          h_filled = h_filled .* exp(1i*2*pi*dfc*deconv_time);
        end
        deconv_LO = exp(-1i*2*pi*(dfc+deconv_dfc) * hdr.time{img});
        
        % Take FFT of deconvolution impulse response
        h_filled = fft(h_filled);
        
        % Create inverse filter relative to window
        Nt_shorten = find(f0 <= deconv_freq,1);
        Nt_shorten(2) = deconv_Nt - find(f1 >= deconv_freq,1,'last');
        Nt_Hwind = deconv_Nt - sum(Nt_shorten);
        Hwind = deconv.ref_window(Nt_Hwind);
        Hwind_filled = ifftshift([zeros(Nt_shorten(1),1); Hwind; zeros(Nt_shorten(end),1)]);
        h_filled_inverse = Hwind_filled ./ h_filled;
        
        % Normalize deconvolution
        h_filled_inverse = h_filled_inverse * h_mult_factor * abs(h_nonnegative(1)./max(deconv.impulse_response{deconv_map_idx}));
        
        % Apply deconvolution filter
        deconv_mask_idxs = find(deconv_mask);
        blocks = round(linspace(1,length(deconv_mask_idxs)+1,8)); blocks = unique(blocks);
        for block = 1:length(blocks)-1
          rlines = deconv_mask_idxs(blocks(block) : blocks(block+1)-1);
          % Matched filter
          tmp = data{img}(1:wfs(wf).Nt,rlines,wf_adc);
          tmp_nan_mask = isnan(tmp);
          tmp(tmp_nan_mask) = 0;
          tmp = ifft(bsxfun(@times, fft(tmp,deconv_Nt), h_filled_inverse));
          % Down conversion to new deconvolution center frequency
          tmp = bsxfun(@times, tmp(1:wfs(wf).Nt,:), deconv_LO);
          tmp(tmp_nan_mask) = NaN;
          data{img}(1:wfs(wf).Nt,rlines,wf_adc) = tmp;
        end
        
      end
      
    end
    
    %% Nulling unsteady Doppler spikes for specified range bins (for example, 20181011_02)
    % .DSN, a parameter structure to control the Doppler spike nulling
    %     .en, 0 or 1 to disable or enable the nulling 
    %     .rbin_clusters, N by 2 array, N is the number of range bin
    %      clusters, the first and the second collumns specify the start and stop range bin respectively for each range bin cluster
    %     .threshold, Doppler threshold in dB above the mean of local Doppler signals
    %     .surf_threshold, surface threshold in dB above the mean of local signals
    if isfield(wfs(wf),'DSN') && wfs(wf).DSN.en
      for rcluster = 1:size(wfs(wf).DSN.rbin_clusters,1)
        for rbin = wfs(wf).DSN.rbin_clusters(rcluster,1):min(size(data{1},1),wfs(wf).DSN.rbin_clusters(rcluster,2))
          good_rline_idxs = ~isnan(data{1}(rbin,:));
          tmp = data{1}(rbin,good_rline_idxs);
          thresholding_idxs = find(lp(tmp)>mean(lp(tmp))+wfs(wf).DSN.surf_threshold);
          if ~isempty(thresholding_idxs)
            continue                      % skipping surface removes most part of noise in general without  nulling artifact
%           tmp(thresholding_idxs) = 0;   % thresholding surface signals
          end
          tmp = fft(tmp);
          tmp_m = mean(lp(tmp));
          tmp_spikes = lp(tmp)-tmp_m;
          spike_idxs = find(tmp_spikes>wfs(wf).DSN.threshold);
          if length(spike_idxs) >0
            for spike_idx = 1:length(spike_idxs)
              tmp(spike_idxs(spike_idx)) = 10^(-tmp_spikes(spike_idxs(spike_idx))/20)*tmp(spike_idxs(spike_idx));
            end
            data{1}(rbin,good_rline_idxs) = ifft(tmp);
          end
        end
      end
    end

  end
  
  % Update frequency axis for deconv
  if param.load.pulse_comp == 1 && wfs(wf).deconv.en && wfs(wf).Nt > 0
    hdr.freq{img} = new_deconv_hdr_freq;
  end
  % Update record length field
  if param.load.pulse_comp == 1 && strcmpi(radar_type,'deramp')
    hdr.Nt{img} = new_Nt;
  end
  
  if param.load.pulse_comp == 1
    % Check if any good records, skip truncation if not
    if any(~hdr.bad_rec{img}(1,:))
      data{img} = data{img}(1:wfs(wf).Nt,:,:);
    end
  end
end
