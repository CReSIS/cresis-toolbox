function param = img_combine_input_check(param, param_mode)
% param = img_combine_input_check(param, param_mode)
%
% Support function for img_combine. Checks inputs and adds missing fields
% to parameter structure. Also called by qlook.m and array.m to ensure the
% img_comb fields are populated.
%
% param: parameter structure
%
% param_mode: string containing the name of the field in the param
% structure that contains the img_comb_* fields. Usually "qlook" or "array".

[~,radar_type,~] = ct_output_dir(param.radar_name);

if ~isfield(param.(param_mode), 'img_comb_weights') || isempty(param.(param_mode).img_comb_weights)
  param.(param_mode).img_comb_weights = [];
end
if ~isfield(param.(param_mode), 'img_comb_mult') || isempty(param.(param_mode).img_comb_mult)
  param.(param_mode).img_comb_mult = inf;
end
if ~isfield(param.(param_mode), 'img_comb_bins') || isempty(param.(param_mode).img_comb_bins)
  param.(param_mode).img_comb_bins = 0;
end
if ~isfield(param.(param_mode), 'img_comb_weights_mode') || isempty(param.(param_mode).img_comb_weights_mode)
  param.(param_mode).img_comb_weights_mode = '';
end
if ~isfield(param.(param_mode), 'img_comb_trim') || isempty(param.(param_mode).img_comb_trim)
  if strcmpi(radar_type,'deramp')
    param.(param_mode).img_comb_trim = [0 0 0 inf];
  else
    % Set relative trim to be 50% support level or higher for pulse compression
    % Set absolute trim to be >= 0 time
    if iscell(param.(param_mode).imgs{1})
      % Multilook format (param_mode is 'array')
      wf_adc_list = param.(param_mode).imgs{1}{1};
    else
      wf_adc_list = param.(param_mode).imgs{1};
    end
    wf_first = wf_adc_list(1,1);
    if isempty(param.(param_mode).img_comb)
      % Only the first image is used when there is no combining
      wf_last = wf_first;
    else
      if iscell(param.(param_mode).imgs{end})
        % Multilook format (param_mode is 'array')
        wf_adc_list = param.(param_mode).imgs{end}{1};
      else
        wf_adc_list = param.(param_mode).imgs{end};
      end
      wf_last = wf_adc_list(1,1);
    end
    param.(param_mode).img_comb_trim = [param.radar.wfs(wf_first).Tpd/2 -param.radar.wfs(wf_last).Tpd/2 0 inf];
  end
end
if ~isfield(param.(param_mode),'img_comb_layer_params') || isempty(param.(param_mode).img_comb_layer_params)
  param.(param_mode).img_comb_layer_params = [];
end
