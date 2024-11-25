% script deconv.auto_tag_artifacts
%
% Run to help with final quality control. Really only works with compressed
% echogram outputs.

% param_fn = ct_filename_param('snow_param_2009_Greenland_P3.xls');
% out_dir = '/cresis/snfs1/dataproducts/ct_data/snow/2009_Greenland_P3/CSARP_post/CSARP_deconv/';
% noise_floor_type = 'constant';
% sidelobe_level_dB = -30;

% param_fn = ct_filename_param('snow_param_2010_Greenland_DC8.xls');
% out_dir = '/cresis/snfs1/dataproducts/public/data/snow/2010_Greenland_DC8/CSARP_deconv/';
% noise_floor_type = 'tracking';
% sidelobe_level_dB = -35;

% param_fn = ct_filename_param('snow_param_2011_Greenland_P3.xls');
% out_dir = '/cresis/snfs1/dataproducts/public/data/snow/2011_Greenland_P3/CSARP_deconv/';
% noise_floor_type = 'tracking';
% sidelobe_level_dB = -35;

% param_fn = ct_filename_param('snow_param_2012_Greenland_P3.xls');
% out_dir = '/cresis/snfs1/dataproducts/public/data/snow/2012_Greenland_P3/CSARP_deconv/';
% noise_floor_type = 'constant';
% sidelobe_level_dB = -35;

% param_fn = ct_filename_param('snow_param_2009_Antarctica_DC8.xls');
% out_dir = '/cresis/snfs1/dataproducts/ct_data/snow/2009_Antarctica_DC8/CSARP_post/CSARP_deconv/';
% noise_floor_type = 'constant';
% sidelobe_level_dB = -30;

% param_fn = ct_filename_param('snow_param_2010_Antarctica_DC8.xls');
% out_dir = '/cresis/snfs1/dataproducts/ct_data/snow/2010_Antarctica_DC8/CSARP_post/CSARP_deconv/';
% noise_floor_type = 'constant';
% sidelobe_level_dB = -35;
% 
% param_fn = ct_filename_param('snow_param_2011_Antarctica_DC8.xls');
% out_dir = '/cresis/snfs1/dataproducts/ct_data/snow/2011_Antarctica_DC8/CSARP_post/CSARP_deconv/';
% noise_floor_type = 'constant';
% sidelobe_level_dB = -35;
% 
% param_fn = ct_filename_param('snow_param_2012_Antarctica_DC8.xls');
% out_dir = '/cresis/snfs1/dataproducts/ct_data/snow/2012_Antarctica_DC8/CSARP_post/CSARP_deconv/';
% noise_floor_type = 'constant';
% sidelobe_level_dB = -35;

param_fn = ct_filename_param('SPREADSHEET.xls');
out_dir = '/cresis/snfs1/dataproducts/public/data/snow/SEASON/CSARP_deconv/';
noise_floor_type = 'constant';
sidelobe_level_dB = -35;

% noise_time: Look at first noise_time seconds of file to determine noise
%   floor
noise_time = 45e-9;

% medfilt1_length: To avoid spurious noise spikes, set medfilt1_length > 1
%   to run a median filter on noise
medfilt1_length = 5;

% noise_threshold_offset_dB: Noise spike guard... basically allow artifacts
%   that cause an increase in spikes that are lower than this value.
noise_threshold_offset_dB = 3.2;

% save_frames: run with false if you just want to see the output statistics
save_frames = true;

% Probably don't need to set these...
update_field = 'quality';
artifact_type = 1;
frm_types = {-1,0,-1,-1,-1};

fprintf('============================================================\n');
fprintf('Finding coherent noise/deconv artifacts\n');
fprintf('============================================================\n');

physical_constants;

% Read in radar processing parameters spreadsheet
params = read_param_xls(param_fn,'','post');

for param_idx = 1:length(params)
  param = params(param_idx);
  if ~param.cmd.generic
    continue;
  end
  
  % Load the frames file
  frames_fn = ct_filename_support(param,'','frames');
  load(frames_fn);
  
  if isempty(param.cmd.frms)
    param.cmd.frms = 1:length(frames.frame_idxs);
  end
  % Remove frames that do not exist from param.cmd.frms list
  [valid_frms,keep_idxs] = intersect(param.cmd.frms, 1:length(frames.frame_idxs));
  if length(valid_frms) ~= length(param.cmd.frms)
    bad_mask = ones(size(param.cmd.frms));
    bad_mask(keep_idxs) = 0;
    warning('Nonexistent frames specified in param.cmd.frms (e.g. frame "%g" is invalid), removing these', ...
      param.cmd.frms(find(bad_mask,1)));
    param.cmd.frms = valid_frms;
  end
  
  max_noise = [];
  max_val = [];
  gps_time = [];
  frm_list = [];
  noise_region_valid = [];
  deconv_wf = [];
  
  % Compress each frame in the list
  for frm = param.cmd.frms
    % Get the filename
    
    out_fn = fullfile(out_dir,param.day_seg,sprintf('Data_%s_%03d.mat', ...
      param.day_seg, frm));
    
    if ct_proc_frame(frames.proc_mode(frm),frm_types)
      %fprintf(' Input %s (%s)\n', out_fn, datestr(now));
    else
      %fprintf(' Skipping %s (%s)\n', out_fn, datestr(now));
      continue;
    end
    
    if ~exist(out_fn,'file')
      warning('File %s does not exist!!!!!', out_fn);
      continue;
    end
    
    echo = load(out_fn);
    noise_bins = find(echo.Time-echo.Time(1) > noise_time,1)-1;
    
    [tmp_max_val,tmp_max_idx] = max(lp(echo.Data));
    
    tmp_noise_region_valid = echo.Time(noise_bins) < echo.Surface-5e-9;
    noise_region_valid = cat(2,noise_region_valid,tmp_noise_region_valid);
    
    tmp_max_noise = lp(max(echo.Data(1:noise_bins,:)));
    max_noise = cat(2,max_noise,tmp_max_noise);
    max_val = cat(2,max_val,tmp_max_val);
    gps_time = cat(2,gps_time,echo.GPS_time);
    if isfield(echo,'custom')
      deconv_wf = cat(2,deconv_wf,echo.custom.deconv_filter_idx);
    else
      deconv_wf = cat(2,deconv_wf,NaN*ones(size(tmp_max_noise)));
    end
    frm_list = cat(2,frm_list,frm*ones(size(tmp_max_noise)));
    
  end
  
  if strcmpi(noise_floor_type,'constant')
    noise_floor = median(max_noise);
    noise_level = noise_floor + noise_threshold_offset_dB;
    threshold = max(max_val+sidelobe_level_dB,...
      noise_level*ones(size(max_noise)));
    max_noise_filt = NaN;
    
  elseif strcmpi(noise_floor_type,'tracking')
    old_max_noise = max_noise;
    max_noise(~noise_region_valid) = NaN;
    max_noise = interp_finite(max_noise);
    max_noise_filt = medfilt1(max_noise,201);
    max_noise_filt(1:50) = max_noise_filt(51);
    max_noise_filt(end+(-49:0)) = max_noise_filt(end-50);
    noise_floor = median(max_noise);
    noise_level = max_noise_filt + noise_threshold_offset_dB;
    threshold = max(max_val+sidelobe_level_dB,...
      noise_level);
    
    if 0
      clf;
      plot(max_noise);
      hold on
      plot(max_noise_filt,'r');
      hold off
    end
  end
  
  bad_mask = logical(medfilt1(double(max_noise > threshold),medfilt1_length));
  bad_frms = unique(frm_list(bad_mask));
  
  mean_noise_threshold = mean(noise_level);
  fprintf('%s\t%.1f\t%.1f\t%.1f\t%.1f\t', param.day_seg, mean_noise_threshold, ...
    max(max_noise_filt), min(max_noise_filt), max(max_val));
  
  fprintf('%d ', bad_frms); fprintf('\n');
  
  % Make sure this is not a no good data frame AND not a land frame
  keep_mask = frames.proc_mode(bad_frms) == 0 & ~mod(floor(frames.(update_field)(bad_frms)/2^7),2);
  bad_frms = bad_frms(keep_mask);
  
  % Set the current artifact to zero/off for all frames
  current_setting = mod(floor(frames.(update_field)/2^(artifact_type-1)),2);
  frames.(update_field) = frames.(update_field) - current_setting*2^(artifact_type-1);
  % Set the current artifact to on for just the bad frames
  frames.(update_field)(bad_frms) = frames.(update_field)(bad_frms) + 2^(artifact_type-1);
  
  records = records_load(records_fn);
  frm_time_axis = gps_time_to_frame(records.gps_time,frames.frame_idxs);
  frm_time = interp1(records.gps_time,frm_time_axis,gps_time);
  
  figure(1); clf;
  plot(frm_time,max_noise);
  title(param.day_seg,'Interpreter','none')
  hold on;
  plot(frm_time,max_val,'r');
  plot(frm_time,threshold,'k-','LineWidth',2);
  plot(frm_time(bad_mask),max_noise(bad_mask),'m.','MarkerSize',20);
  hold off;
  xlabel('Frame time');
  ylabel('Power (dB)');
  legend('Noise','Peak','Threshold')
  grid on
  
  img_fn = ct_filename_ct_tmp(param,'','deconv_qc','artifact_threshold.fig');
  img_fn_dir = fileparts(img_fn);
  if ~exist(img_fn_dir,'dir')
    mkdir(fileparts(img_fn));
  end
  
  saveas(1,img_fn);
  
  if save_frames
    save(frames_fn,'-V7','frames');
  end
end

return
