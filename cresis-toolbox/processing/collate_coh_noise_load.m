function noise = collate_coh_noise_load(param,wf,adc)
% noise = collate_coh_noise_load(param,wf,adc)
%
% Loads collate_coh_noise output file.
%
% Authors: John Paden

if isempty(param)
  error('param is empty and should contain a radar parameter spreadsheet structure or a collate_coh_noise filename.');
end

if ~exist('wf','var') || isempty(wf)
  wf = 1;
end

if ~exist('adc','var') || isempty(adc)
  adc = 1;
end

if ischar(param)
  noise_fn = param;
  param = [];
elseif isstruct(param)
  noise_fn_dir = fileparts(ct_filename_out(param,param.radar.wfs(wf).coh_noise_arg.fn, ''));
  noise_fn = fullfile(noise_fn_dir,sprintf('coh_noise_simp_%s_wf_%d_adc_%d.mat', param.day_seg, wf, adc));
else
  error('param must be a string or struct.');
end
noise = load(noise_fn);

update_collate_coh_noise_file = false;
if ~isfield(noise,'param_collate_coh_noise') || isempty(noise.param_collate_coh_noise)
  update_collate_coh_noise_file = true;
elseif ~isfield(noise.param_collate_coh_noise.collate_coh_noise,'method') || isempty(noise.param_collate_coh_noise.collate_coh_noise.method)
  update_collate_coh_noise_file = true;
end
if ~isfield(noise,'param_records') || isempty(noise.param_records)
  update_collate_coh_noise_file = true;
end
if isfield(noise,'coh_noise') && isfield(noise,'coh_noise_gps_time')
  update_collate_coh_noise_file = true;
end
for wf = 1:length(noise.param_analysis.radar.wfs)
  if ~isfield(noise.param_analysis.radar.wfs(wf),'system_dB')
    update_collate_coh_noise_file = true;
  end
end

if update_collate_coh_noise_file
  if isempty(param)
    if isfield(noise,'param_collate_coh_noise')
      param = noise.param_collate_coh_noise;
    else
      error('A param structure must be passed in instead of collate_coh_noise filename to use the old file format. After updating, the filename may be used with collate_coh_noise_load.');
    end
  end
  warning('Old collate_coh_noise file format. collate_coh_noise_update.m being run to update collate_coh_noise file.');
  param.collate_coh_noise_update.wfs = wf;
  param.collate_coh_noise_update.rx_paths{wf} = nan(1,adc);
  param.collate_coh_noise_update.rx_paths{wf}(adc) = true; % Actual value does not matter as long as ~isnan
  collate_coh_noise_update(param,[]);
  noise = load(param,[]);
end
