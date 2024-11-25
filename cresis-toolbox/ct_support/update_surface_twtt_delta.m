function update_surface_twtt_delta(param,param_override)
% update_surface_twtt_delta(param,param_override)
%
% Updates the fast time related variables for changes in Tadc, Tadc_adjust
% and Tsys. Can be used on any echogram data product (not CSARP_out).
% However, for SAR processed outputs, the data should be reprocessed if the
% offset is very large because large time system time delay errors affect
% the focussing.
%
% Updates Time, param_{qlook,sar}.radar.wfs(wf).Tadc,
% param_{qlook,sar}.radar.wfs(wf).Tadc_adjust,
% param_{qlook,sar}radar.wfs(wf).Tsys,
% param_{qlook,sar}radar.wfs(wf).t_ref, Surface, and Bottom variables.
%
% Optionally updates radiometric fields adc_gains_dB, system_dB, and
% radiometric_corr_dB. If enabled and there has been a change in the
% radiometric field, this will cause these fields to be updated:
%  param_{qlook,sar}.radar.wfs(wf).adc_gains_dB
%  param_{qlook,sar}.radar.wfs(wf).system_dB
%  param_{qlook,array}.radiometric_corr_dB
%  Data
%
% Note that only the param_{qlook,sar,array} field that matters gets
% updated. For example, param_records and param_array will not be used or
% updated because Tadc, Tadc_adjust and Tsys are not used during these
% processes and so their value does not matter when those processes are
% applied.
%
% Tsys, t_ref, Tadc, Tadc_adjust, adc_gains_dB, system_dB, and
% radiometric_corr_dB changes can only be corrected when the same change is
% applied to all waveform-adc pairs used in the data product.
%
% Note that Tadc, Tadc_adjust and t_ref are opposite sign to Tsys
%  - Tsys is subtracted away from time
%  - Tadc, Tadc_adjust and t_ref are added on to time
%
% Examples:
%   See run_update_surface_twtt_delta.m to run
%
% Author: John Paden

%% Setup
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.day_seg, datestr(now));
fprintf('=====================================================================\n');

%% Input Checks

if ~isfield(param.update_surface_twtt_delta,'imgs') ...
    || isempty(param.update_surface_twtt_delta.imgs)
  warning('update_surface_twtt_delta.imgs not specified so no work to be done. Typically imgs should be numeric vector indicating all the images to be updates. For example imgs, = [0 1 2] updates the combined image and img_01 and img_02.');
  return;
end

if ~isfield(param.update_surface_twtt_delta,'update_radiometric') ...
    || isempty(param.update_surface_twtt_delta.update_radiometric)
  param.update_surface_twtt_delta.update_radiometric = false;
end

if ~isfield(param.update_surface_twtt_delta,'update_Tsys') ...
    || isempty(param.update_surface_twtt_delta.update_Tsys)
  param.update_surface_twtt_delta.update_Tsys = true;
end

if ~isfield(param.update_surface_twtt_delta,'data_types') ...
    || isempty(param.update_surface_twtt_delta.data_types)
  warning('update_surface_twtt_delta.data_types not specified so no work to be done. Typically data_types should be cell array of strings with output data products to be updated. For example {''qlook'',''standard'',''CSARP_post/qlook''}.');
  return;
end

% Remove frames that do not exist from param.cmd.frms list
frames = frames_load(param);
if isempty(param.cmd.frms)
  param.cmd.frms = 1:length(frames.frame_idxs);
end
[valid_frms,keep_idxs] = intersect(param.cmd.frms, 1:length(frames.frame_idxs));
if length(valid_frms) ~= length(param.cmd.frms)
  bad_mask = ones(size(param.cmd.frms));
  bad_mask(keep_idxs) = 0;
  warning('Nonexistent frames specified in param.cmd.frms (e.g. frame "%g" is invalid), removing these', ...
    param.cmd.frms(find(bad_mask,1)));
  param.cmd.frms = valid_frms;
end

% Rename a few variables for readability
data_types = param.update_surface_twtt_delta.data_types;
imgs = param.update_surface_twtt_delta.imgs;

%% Loop through each frame and update
for frm_idx = 1:length(param.cmd.frms)
  frm = param.cmd.frms(frm_idx);
  fprintf('%s_%03d\n', param.day_seg, frm);
  
  %% Loop through each data type
  for data_type_idx = 1:length(data_types)
    data_type = data_types{data_type_idx};
    
    %% Loop through each image type
    for data_img = imgs
      
      %% Load the data
      if data_img == 0
        echo_fn = fullfile(ct_filename_out(param,data_type,''), ...
          sprintf('Data_%s_%03d.mat', param.day_seg, frm));
      else
        echo_fn = fullfile(ct_filename_out(param,data_type,''), ...
          sprintf('Data_img_%02d_%s_%03d.mat', data_img, param.day_seg, frm));
      end
      
      if ~exist(echo_fn,'file')
        warning('Missing %s\n', echo_fn);
        continue;
      end
      
      warning off;
      mdata = load(echo_fn,'Time','Surface','Bottom','param_qlook','param_sar');
      warning on;
      
      fields_to_update = {'Time'};
      
      if isfield(mdata,'param_qlook')
        param_field = 'param_qlook';
        echo_param_field = 'qlook';
      elseif isfield(mdata,'param_sar')
        param_field = 'param_sar';
        echo_param_field = 'array';
      else
        error('Data file contained neither param_qlook or param_sar, but should contain one or the other.');
      end
      fields_to_update{end+1} = param_field;
      
      %% Determine which fields changed
      delta_offset_t_ref = [];
      delta_offset_t_ref_mask = logical([]);
      delta_offset_Tsys = [];
      delta_offset_Tsys_mask = logical([]);
      delta_offset_Tadc_adjust = [];
      delta_offset_Tadc_adjust_mask = logical([]);
      delta_offset_Tadc = [];
      delta_offset_Tadc_mask = logical([]);
      delta_offset_adc_gains_dB = [];
      delta_offset_adc_gains_dB_mask = logical([]);
      delta_offset_system_dB = [];
      delta_offset_system_dB_mask = logical([]);
      delta_offset_radiometric_corr_dB = [];
      delta_offset_radiometric_corr_dB_mask = logical([]);
      for img = 1:length(mdata.(param_field).(param_field(7:end)).imgs)
        for wf_adc_pair = 1:size(mdata.(param_field).(param_field(7:end)).imgs{img},1)
          wf = abs(mdata.(param_field).(param_field(7:end)).imgs{img}(wf_adc_pair,1));
          adc = abs(mdata.(param_field).(param_field(7:end)).imgs{img}(wf_adc_pair,2));
          rx_path = mdata.(param_field).radar.wfs(wf).rx_paths(adc);
          
          % t_ref correction
          if ~isfield(param.radar.wfs(wf),'t_ref') ...
              || isempty(param.radar.wfs(wf).t_ref)
            param.radar.wfs(wf).t_ref = 0;
          end
          if ~isfield(mdata.(param_field).radar.wfs(wf),'t_ref') ...
              || isempty(mdata.(param_field).radar.wfs(wf).t_ref)
            mdata.(param_field).radar.wfs(wf).t_ref = 0;
          end
          delta_offset_t_ref(wf) = param.radar.wfs(wf).t_ref ...
            - mdata.(param_field).radar.wfs(wf).t_ref;
          delta_offset_t_ref_mask(wf) = true;
          
          % Tsys correction
          if ~isfield(param.radar.wfs(wf),'Tsys') ...
              || numel(param.radar.wfs(wf).Tsys) < adc
            param.radar.wfs(wf).Tsys(rx_path) = 0;
          end
          if ~isfield(mdata.(param_field).radar.wfs(wf),'Tsys') ...
              || numel(mdata.(param_field).radar.wfs(wf).Tsys) < adc
            mdata.(param_field).radar.wfs(wf).Tsys(rx_path) = 0;
          end
          
          if param.update_surface_twtt_delta.update_Tsys
            delta_offset_Tsys(img,wf_adc_pair) = param.radar.wfs(wf).Tsys(rx_path) ...
              - mdata.(param_field).radar.wfs(wf).Tsys(rx_path);
            delta_offset_Tsys_mask(img,wf_adc_pair) = true;
          end
          
          % Tadc correction
          if ~isfield(param.radar.wfs(wf),'Tadc') ...
              || isempty(param.radar.wfs(wf).Tadc)
            param.radar.wfs(wf).Tadc = 0;
          end
          if ~isfield(mdata.(param_field).radar.wfs(wf),'Tadc') ...
              || isempty(mdata.(param_field).radar.wfs(wf).Tadc)
            mdata.(param_field).radar.wfs(wf).Tadc = 0;
          end
          delta_offset_Tadc(wf) = param.radar.wfs(wf).Tadc ...
            - mdata.(param_field).radar.wfs(wf).Tadc;
          delta_offset_Tadc_mask(wf) = true;
          
          % Tadc_adjust correction
          if ~isfield(param.radar.wfs(wf),'Tadc_adjust') ...
              || isempty(param.radar.wfs(wf).Tadc_adjust)
            param.radar.wfs(wf).Tadc_adjust = 0;
          end
          if ~isfield(mdata.(param_field).radar.wfs(wf),'Tadc_adjust') ...
              || isempty(mdata.(param_field).radar.wfs(wf).Tadc_adjust)
            mdata.(param_field).radar.wfs(wf).Tadc_adjust = 0;
          end
          delta_offset_Tadc_adjust(wf) = param.radar.wfs(wf).Tadc_adjust ...
            - mdata.(param_field).radar.wfs(wf).Tadc_adjust;
          delta_offset_Tadc_adjust_mask(wf) = true;
          
          if param.update_surface_twtt_delta.update_radiometric
            % adc_gains_dB correction
            if ~isfield(param.radar.wfs(wf),'adc_gains_dB') ...
                || numel(param.radar.wfs(wf).adc_gains_dB) < adc
              param.radar.wfs(wf).adc_gains_dB(adc) = 0;
            end
            if ~isfield(mdata.(param_field).radar.wfs(wf),'adc_gains_dB') ...
                || numel(mdata.(param_field).radar.wfs(wf).adc_gains_dB) < adc
              mdata.(param_field).radar.wfs(wf).adc_gains_dB(adc) = 0;
            end
            delta_offset_adc_gains_dB(img,wf_adc_pair) = param.radar.wfs(wf).adc_gains_dB(adc) ...
              - mdata.(param_field).radar.wfs(wf).adc_gains_dB(adc);
            delta_offset_adc_gains_dB_mask(img,wf_adc_pair) = true;
            
            % system_dB correction
            if ~isfield(param.radar.wfs(wf),'system_dB') ...
                || numel(param.radar.wfs(wf).system_dB) < rx_path
              param.radar.wfs(wf).system_dB(rx_path) = 0;
            end
            if ~isfield(mdata.(param_field).radar.wfs(wf),'system_dB') ...
                || numel(mdata.(param_field).radar.wfs(wf).system_dB) < rx_path
              mdata.(param_field).radar.wfs(wf).system_dB(rx_path) = 0;
            end
            delta_offset_system_dB(img,wf_adc_pair) = param.radar.wfs(wf).system_dB(rx_path) ...
              - mdata.(param_field).radar.wfs(wf).system_dB(rx_path);
            delta_offset_system_dB_mask(img,wf_adc_pair) = true;
            
            % radiometric_corr_dB correction
            if ~isfield(param.(echo_param_field),'radiometric_corr_dB') ...
                || isempty(param.(echo_param_field).radiometric_corr_dB)
              param.(echo_param_field).radiometric_corr_dB = NaN;
            end
            if ~isfield(mdata.(['param_' echo_param_field]).(echo_param_field),'radiometric_corr_dB') ...
                || isempty(mdata.(['param_' echo_param_field]).(echo_param_field).radiometric_corr_dB)
              mdata.(['param_' echo_param_field]).(echo_param_field).radiometric_corr_dB = NaN;
            end
            delta_offset_radiometric_corr_dB(img,wf_adc_pair) = param.(echo_param_field).radiometric_corr_dB ...
              - mdata.(['param_' echo_param_field]).(echo_param_field).radiometric_corr_dB;
            delta_offset_radiometric_corr_dB_mask(img,wf_adc_pair) = true;
            
          end
        end
      end
      
      first_idx = find(delta_offset_t_ref_mask,1);
      delta_offset_t_ref(~delta_offset_t_ref_mask) = NaN;
      if ~all(delta_offset_t_ref(delta_offset_t_ref_mask) == delta_offset_t_ref(first_idx))
        delta_offset_t_ref
        error('Different t_ref delta offsets for each waveform, cannot proceed: reprocess data.');
      end
      delta_offset_t_ref = delta_offset_t_ref(first_idx);
      
      if param.update_surface_twtt_delta.update_Tsys
        first_idx = find(delta_offset_Tsys_mask,1);
        delta_offset_Tsys(~delta_offset_Tsys_mask) = NaN;
        if ~all(delta_offset_Tsys(delta_offset_Tsys_mask) == delta_offset_Tsys(first_idx))
          delta_offset_Tsys
          error('Different Tsys delta offsets for each waveform-adc-pair, cannot proceed: reprocess data.');
        end
        delta_offset_Tsys = delta_offset_Tsys(first_idx);
      end
      
      first_idx = find(delta_offset_Tadc_mask,1);
      delta_offset_Tadc(~delta_offset_Tadc_mask) = NaN;
      if ~all(delta_offset_Tadc(delta_offset_Tadc_mask) == delta_offset_Tadc(first_idx))
        delta_offset_Tadc
        error('Different Tadc delta offsets for each waveform, cannot proceed: reprocess data.');
      end
      delta_offset_Tadc = delta_offset_Tadc(first_idx);
      
      first_idx = find(delta_offset_Tadc_adjust_mask,1);
      delta_offset_Tadc_adjust(~delta_offset_Tadc_adjust_mask) = NaN;
      if ~all(delta_offset_Tadc_adjust(delta_offset_Tadc_adjust_mask) == delta_offset_Tadc_adjust(first_idx))
        delta_offset_Tadc_adjust
        error('Different Tadc_adjust delta offsets for each waveform, cannot proceed: reprocess data.');
      end
      delta_offset_Tadc_adjust = delta_offset_Tadc_adjust(first_idx);
      
      if param.update_surface_twtt_delta.update_radiometric
        first_idx = find(delta_offset_adc_gains_dB_mask,1);
        delta_offset_adc_gains_dB(~delta_offset_adc_gains_dB_mask) = NaN;
        if ~all(delta_offset_adc_gains_dB(delta_offset_adc_gains_dB_mask) == delta_offset_adc_gains_dB(first_idx))
          delta_offset_adc_gains_dB
          error('Different adc_gains_dB delta offsets for each waveform, cannot proceed: reprocess data.');
        end
        delta_offset_adc_gains_dB = delta_offset_adc_gains_dB(first_idx);
        
        first_idx = find(delta_offset_system_dB_mask,1);
        delta_offset_system_dB(~delta_offset_system_dB_mask) = NaN;
        if ~all(delta_offset_system_dB(delta_offset_system_dB_mask) == delta_offset_system_dB(first_idx))
          delta_offset_system_dB
          error('Different system_dB delta offsets for each waveform, cannot proceed: reprocess data.');
        end
        delta_offset_system_dB = delta_offset_system_dB(first_idx);
        
        first_idx = find(delta_offset_radiometric_corr_dB_mask,1);
        delta_offset_radiometric_corr_dB(~delta_offset_radiometric_corr_dB_mask) = NaN;
        if ~all(delta_offset_radiometric_corr_dB(delta_offset_radiometric_corr_dB_mask) == delta_offset_radiometric_corr_dB(first_idx)) ...
          && any(~isnan(delta_offset_radiometric_corr_dB(delta_offset_radiometric_corr_dB_mask)))
          delta_offset_radiometric_corr_dB
          error('Different radiometric_corr_dB delta offsets for each waveform, cannot proceed: reprocess data.');
        end
        delta_offset_radiometric_corr_dB = delta_offset_radiometric_corr_dB(first_idx);
      end
      
      for img = 1:length(mdata.(param_field).(param_field(7:end)).imgs)
        for wf_adc_pair = 1:size(mdata.(param_field).(param_field(7:end)).imgs{img},1)
          wf = abs(mdata.(param_field).(param_field(7:end)).imgs{img}(wf_adc_pair,1));
          adc = abs(mdata.(param_field).(param_field(7:end)).imgs{img}(wf_adc_pair,2));
          rx_path = mdata.(param_field).radar.wfs(wf).rx_paths(adc);
          
          mdata.(param_field).radar.wfs(wf).t_ref = param.radar.wfs(wf).t_ref;
          mdata.(param_field).radar.wfs(wf).Tsys(rx_path) = param.radar.wfs(wf).Tsys(rx_path);
          mdata.(param_field).radar.wfs(wf).Tadc = param.radar.wfs(wf).Tadc;
          mdata.(param_field).radar.wfs(wf).Tadc_adjust = param.radar.wfs(wf).Tadc_adjust;
          if param.update_surface_twtt_delta.update_radiometric
            mdata.(param_field).radar.wfs(wf).adc_gains_dB(adc) = param.radar.wfs(wf).adc_gains_dB(adc);
            mdata.(param_field).radar.wfs(wf).system_dB(rx_path) = param.radar.wfs(wf).system_dB(rx_path);
            mdata.(['param_' echo_param_field]).(echo_param_field).radiometric_corr_dB = param.(echo_param_field).radiometric_corr_dB;
          end
        end
      end
      
      %% Update Data File
      if delta_offset_t_ref ~= 0 ...
          || (param.update_surface_twtt_delta.update_Tsys ...
          && delta_offset_Tsys ~= 0) ...
          || delta_offset_Tadc ~= 0 || delta_offset_Tadc_adjust ~= 0 ...
          || (param.update_surface_twtt_delta.update_radiometric ...
          && (delta_offset_adc_gains_dB ~= 0 || delta_offset_system_dB ~= 0 || delta_offset_radiometric_corr_dB ~= 0))
        fprintf('  t_ref Offset  %g %s (%s)\n', delta_offset_t_ref, echo_fn, datestr(now,'HH:MM:SS'));
        if param.update_surface_twtt_delta.update_Tsys
          fprintf('  Tsys Offset %g %s (%s)\n', delta_offset_Tsys, echo_fn, datestr(now,'HH:MM:SS'));
        end
        fprintf('  Tadc Offset %g %s (%s)\n', delta_offset_Tadc, echo_fn, datestr(now,'HH:MM:SS'));
        fprintf('  Tadc_adjust Offset %g %s (%s)\n', delta_offset_Tadc_adjust, echo_fn, datestr(now,'HH:MM:SS'));
        if param.update_surface_twtt_delta.update_radiometric
          fprintf('  adc_gains_dB Offset %g %s (%s)\n', delta_offset_adc_gains_dB, echo_fn, datestr(now,'HH:MM:SS'));
          fprintf('  system_dB Offset %g %s (%s)\n', delta_offset_system_dB, echo_fn, datestr(now,'HH:MM:SS'));
          fprintf('  radiometric_corr Offset %g %s (%s)\n', delta_offset_radiometric_corr_dB, echo_fn, datestr(now,'HH:MM:SS'));
          if delta_offset_adc_gains_dB + delta_offset_system_dB + delta_offset_radiometric_corr_dB ~= 0
            tmp = load(echo_fn,'Data');
            if isfinite(delta_offset_radiometric_corr_dB)
              tmp.Data = tmp.Data * 10^((-delta_offset_adc_gains_dB + delta_offset_system_dB + delta_offset_radiometric_corr_dB)/10);
            else
              tmp.Data = tmp.Data * 10^((-delta_offset_adc_gains_dB + delta_offset_system_dB)/10);
            end
            mdata.Data = tmp.Data;
            fields_to_update{end+1} = 'Data';
          end
        end
        
        % Note that Tadc_adjust is opposite sign to Tsys
        %  - Tsys is subtracted away
        %  - Tadc_adjust is added on
        if param.update_surface_twtt_delta.update_Tsys
          delta_offset = delta_offset_Tsys - delta_offset_Tadc - delta_offset_Tadc_adjust - delta_offset_t_ref;
        else
          delta_offset = -delta_offset_Tadc - delta_offset_Tadc_adjust - delta_offset_t_ref;
        end
        
        mdata.Time = mdata.Time - delta_offset;
        if isfield(mdata,'Surface')
          mdata.Surface = mdata.Surface - delta_offset;
          fields_to_update{end+1} = 'Surface';
        end
        if isfield(mdata,'Bottom')
          mdata.Bottom = mdata.Bottom - delta_offset;
          fields_to_update{end+1} = 'Bottom';
        end
        save(echo_fn,'-append','-struct','mdata',fields_to_update{:});
        
      end
      
    end
  end
  
end
