% script quality_control
%
% Updates the frames file's proc_mode or quality field. This is necessary
% for kuband radar and snow radar sea ice data where artifacts need to be
% indicated for NSIDC data products. The proc_mode field can be used during
% processing to identify specific frames to process. To run this script,
% the images and the records and frames files should be available.
% records file be created.
%
% See run_quality_control.m to see how to run.
%
% Prompt
%   F(FFF:PPPP):
%     FFF = frame ID
%     PPPP = field to update (user specifies quality or proc_mode)
%
% Commands (case-insensitive except where noted)
% empty
%   proceed to next frame
% 'p'
%   proceed to previous frame
% #
%   sets frame processing type to # and proceeds to next frame
% c or k
%   runs Matlab eval command in debug prompt
% d
%   prints out differences to the frames file since last save
% i
%   swap image type between mat and param.img_type
% s
%   saves frames file
% q
%   quits (asks for saving)
% j
%   asks which frame to jump to
% Ctrl-C
%   quits without saving
%
% Author: John Paden
%
% See also: quality_control.m, run_quality_control.m


%% Automated Section

if strcmpi(update_field_type,'double')
elseif strcmpi(update_field_type,'mask')
  update_field_mask_len = max(3,length(update_field_mask)-1);
else
  error('Invalid field type update_field_type=%s', update_field_type);
end

img_type = param.img_type;

num_img = length(param.image_out_dir);

for img = 1:num_img
  figure(img); clf;
  h_axes(img) = axes;
  set(h_axes(img),'Position',[0 0 1 1]);
  set(h_axes(img),'TickDir','out');
  h_image(img) = imagesc(1,'Parent',h_axes(img));
  hold on;
  h_plot(img) = plot(NaN,'k','Parent',h_axes(img));
  hold off;
end
linkaxes(h_axes,'xy');


for img=1:num_img
  image_fn_dir{img} = ct_filename_out(param,param.image_out_dir{img}{:});
  mat_fn_dir{img} = ct_filename_out(param,param.mat_out_dir{img}{:});
end

frames_fn = ct_filename_support(param,'','frames');
frames = frames_load(param);

old_frames = frames;

frm_idx = 1;
if isempty(update_field_match)
  frms = 1:length(frames.frame_idxs);
else
  mask = zeros(1,length(frames.frame_idxs));
  while all(mask==0)
    for idx=1:length(update_field_match)
      if strcmpi(update_field_type,'double')
        mask = mask | frames.(update_field) == update_field_match(idx);
      elseif strcmpi(update_field_type,'mask')
        if update_field_match(idx) == 0
          mask = mask | frames.(update_field) == update_field_match(idx);
        else
          mask = mask | mod(floor(frames.(update_field) / 2^(update_field_match(idx)-1)),2);
        end
      end
    end
    if all(mask==0)
      warning('No frames match. Setting to all frames.');
      mask = ones(1,length(frames.frame_idxs));
    end
  end
  frms = find(mask);
end

frm_idx = 1;
quit_cmd = false;
while ~quit_cmd
  if frm_idx < 1
    frm_idx = 1;
  end
  if frm_idx > length(frms)
    frm_idx = length(frms);
  end
  frm = frms(frm_idx);
  
  % Update frames list if required
  if ~isempty(update_field_match)
    mask = zeros(1,length(frames.frame_idxs));
    while all(mask==0)
      for idx=1:length(update_field_match)
        if strcmpi(update_field_type,'double')
          mask = mask | frames.(update_field) == update_field_match(idx);
        elseif strcmpi(update_field_type,'mask')
          if update_field_match(idx) == 0
            mask = mask | frames.(update_field) == update_field_match(idx);
          else
            mask = mask | mod(floor(frames.(update_field) / 2^(update_field_match(idx)-1)),2);
          end
        end
      end
      if all(mask==0)
        warning('No frames match. Setting to all frames.');
        mask = ones(1,length(frames.frame_idxs));
      end
    end
    frms = find(mask);
    [~,frm_idx] = min(abs(frm-frms));
    frm = frms(frm_idx);
  end
  frm_id = sprintf('%s_%03i',param.day_seg,frm);
  
  % all_files_mat: will stay true if all the loaded files are .mat files
  all_files_mat = true;
  for img = 1:num_img
    try
      if strcmpi(img_type,'mat')
        if param.mat_out_img{img} == 0
          echo_fn{img} = get_filename(mat_fn_dir{img},sprintf('Data_%s',frm_id),'','.mat');
        else
          echo_fn{img} = get_filename(mat_fn_dir{img},sprintf('Data_img_%02d_%s',param.mat_out_img{img},frm_id),'','.mat');
        end
      else
        echo_fn{img} = get_filename(image_fn_dir{img},frm_id,'',img_type);
      end
    catch ME
      if strcmpi(ME.identifier,'get_filename:no_file_found')
        if strcmpi(img_type,'mat')
          warning('Missing frame %s in %s', frm_id, mat_fn_dir{img});
        else
          warning('Missing frame %s in %s', frm_id, image_fn_dir{img});
        end
        echo_fn{img} = '';
      else
        rethrow(ME);
      end
    end
    
    mdata = [];
    try
      if isempty(echo_fn{img})
        set(img,'Name',sprintf('%d: File not found', img),'NumberTitle','off');
      else
        [tmp1,tmp2,tmp3] = fileparts(echo_fn{img}); [~,tmp1] = fileparts(tmp1);
        set(img,'Name',sprintf('%d: %s', img, fullfile(tmp1,[tmp2 tmp3])),'NumberTitle','off');
        fprintf('  Loading output %s\n', echo_fn{img});
        if strcmpi(img_type,'mat')
          mdata = load(echo_fn{img});
          mdata = uncompress_echogram(mdata);
          set(h_image(img),'XData',1:size(mdata.Data,2));
          set(h_image(img),'YData',mdata.Time);
          set(h_image(img),'CData',lp(mdata.Data));
          clims = [min(lp(mdata.Data(isfinite(lp(mdata.Data(:)))))) max(lp(mdata.Data(isfinite(lp(mdata.Data(:))))))];
          if length(clims) == 2
            caxis(h_axes(img),clims);
          end
          xlim(h_axes(img),[1 size(mdata.Data,2)]);
          ylim(h_axes(img),[mdata.Time([1 end])]);
          set(h_plot(img),'XData',1:size(mdata.Data,2));
          set(h_plot(img),'YData',mdata.Surface);
          set(h_axes(img),'YDir','reverse');
          if ~fmcw_img_debug_mode
            set(h_plot(img),'Color','red')
            colormap(h_axes(img),1-gray(256));
          else
            set(h_plot(img),'Color','black')
            for rline=1:size(mdata.Data,2)
              mdata.Data(lp(mdata.Data(:,rline))<max(lp(mdata.Data(:,rline)))+img_sidelobe,rline) = NaN;
            end
            set(h_image(img),'CData',lp(mdata.Data));
            Nx = size(mdata.Data,2);
            max_noise = zeros(1,Nx);
            dt = mdata.Time(2)-mdata.Time(1);
            for idx = 1:Nx
              surf_t = mdata.Surface(1,idx);
              surf_bin = (surf_t - mdata.Time(1))/dt + 1;
              noise_surf = max(1, round(surf_bin - noise_time_buffer/dt)+1);
              noise_end = round(noise_surf + noise_time_duration/dt) + 1;
              max_noise(idx) = max(mdata.Data(noise_surf:noise_end,idx));
            end
            max_val = lp(max(mdata.Data));
            noise_threshold = lp(nanmedian(max_noise))+noise_threshold_offset_dB;
            threshold = max(max_val+img_sidelobe,...
              noise_threshold*ones(size(max_noise)));
            if isfinite(noise_threshold)
              img_caxis = noise_threshold + [-6 +12];
              set(1,'Name',sprintf('%s_%03d: caxis threshold %.1f',param.day_seg,frm,noise_threshold));
              caxis(h_axes(img),img_caxis);
              img_cmap = [gray(64); flipud(hsv(128))];
              colormap(h_axes(img),img_cmap)
            else
              colormap(h_axes(img),jet(256));
            end
            if 0 && any(medfilt1(double(max_noise > threshold),5))
              figure(2); clf;
              plot(max_noise);
              hold on;
              plot(max_val,'r');
              plot(threshold,'k','LineWidth',2);
              hold off;
              beep
            end
            if 0
              figure(2); clf;
              plot(max_noise);
              hold on;
              plot(max_val,'r');
              plot(threshold,'k','LineWidth',2);
              hold off;
            end
          end
          
        else
          % This section for loading jpg, png, etc format
          all_files_mat = false;
          A = imread(echo_fn{img});
          set(h_image(img),'CData',A);
          set(h_image(img),'XData',1:size(A,2));
          set(h_image(img),'YData',1:size(A,1));
          xlim(h_axes(img),[1 size(A,2)]);
          ylim(h_axes(img),[1 size(A,1)]);
          set(h_plot(img),'XData',NaN);
          set(h_plot(img),'YData',NaN);
          set(h_axes(img),'YDir','reverse');
        end
        %     set(h_image(img),'XData',1:size(A,2));
        %     set(h_image(img),'YData',1:size(A,1));
        axis(h_axes(img),'tight');
        zoom(h_axes(img),'reset');
      end
    catch ME
      warning('Failed to load %s:\n%s', echo_fn{img}, ME.getReport());
      echo_fn{img} = '';
    end
  end
  if all_files_mat
    if fmcw_img_debug_mode == 1 && ~isempty(mdata)
      ylim([min(mdata.Surface)-10e-9 max(mdata.Surface)+10e-9]);
    end
    zoom('reset');
  end
  
  if strcmpi(update_field_type,'double')
    update_field_str = sprintf('%04i',frames.(update_field)(frm));
  elseif strcmpi(update_field_type,'mask')
    if isnan(frames.(update_field)(frm))
      update_field_str = sprintf(sprintf('%%%ds',update_field_mask_len),'NaN');
    else
      update_field_str = dec2bin(frames.(update_field)(frm),update_field_mask_len);
    end
  end
  if audio_tone_for_nonzero_nonisnan && eval(audio_tone_check_code)
    beep;
  end
  
  val = input(sprintf('F(%03i:%s): ', frm, update_field_str),'s');
  if all(isstrprop(val,'wspace'))
    % Go to next frame
    frm_idx = frm_idx + 1;
  else
    num_val = str2double(val);
    
    if any(strcmpi(val,{'c','k'}))
      fprintf('Variables are frames.%s. dbcont when finished.\n', update_field);
      if strcmpi(update_field_type,'mask')
        fprintf('  To update frames.%s, consider using bitor. E.g. bitor(frames.%s,bin2dec(''1000'')).\n',update_field,update_field);
      end
      keyboard
      
    elseif strcmpi(val,'d')
      fprintf('\n');
      diff_frms = find((frames.(update_field)~=old_frames.(update_field) ...
        & ~(isnan(frames.(update_field)) & isnan(old_frames.(update_field)))));
      fprintf('%s\t%s\t%s\t%s\t%s\n', 'Frm', 'Old_Value', 'New_Value', 'Old_Binary', 'New_Binary');
      for cur_frm = diff_frms
        if isnan(old_frames.(update_field)(cur_frm))
          old_dec2bin_str = 'NaN';
        else
          old_dec2bin_str = dec2bin(old_frames.(update_field)(cur_frm),8);
        end
        if isnan(frames.(update_field)(cur_frm))
          dec2bin_str = 'NaN';
        else
          dec2bin_str = dec2bin(frames.(update_field)(cur_frm),8);
        end
        fprintf('%3.0f\t%9.0f\t%9.0f\t%10s\t%10s\n', cur_frm, ...
          old_frames.(update_field)(cur_frm), frames.(update_field)(cur_frm), ...
          old_dec2bin_str, dec2bin_str);
      end
      fprintf('\n');
      
    elseif strcmpi(val,'f')
      nan_frms = find(isnan(frames.(update_field)));
      fprintf('\nThere are %d frames with isnan(frames.%s).\n', length(nan_frms), update_field);
      if ~isempty(nan_frms)
        fprintf('These frames are: %s\n\n', mat2str_generic(nan_frms));
      else
        fprintf('\n');
      end
      
      zero_frms = find(frames.(update_field) == 0);
      fprintf('There are %d frames with frames.%s == 0.\n', length(zero_frms), update_field);
      if ~isempty(zero_frms)
        fprintf('These frames are: %s\n\n', mat2str_generic(zero_frms));
      else
        fprintf('\n');
      end
      
      fprintf('Frames which are ~isnan and ~=0:\n');
      fprintf('%s\t%s\t%s\t%s\t%s\n', 'Frm', 'Old_Value', 'New_Value', 'Old_Binary', 'New_Binary');
      for cur_frm = 1:length(frames.(update_field))
        if ~isnan(frames.(update_field)(cur_frm)) && frames.(update_field)(cur_frm) ~= 0
          if isnan(old_frames.(update_field)(cur_frm))
            old_dec2bin_str = 'NaN';
          else
            old_dec2bin_str = dec2bin(old_frames.(update_field)(cur_frm),8);
          end
          if isnan(frames.(update_field)(cur_frm))
            dec2bin_str = 'NaN';
          else
            dec2bin_str = dec2bin(frames.(update_field)(cur_frm),8);
          end
          fprintf('%3.0f\t%9.0f\t%9.0f\t%10s\t%10s\n', cur_frm, ...
            old_frames.(update_field)(cur_frm), frames.(update_field)(cur_frm), ...
            old_dec2bin_str, dec2bin_str);
        end
      end
      fprintf('\n');
      
    elseif strcmp(val,'i')
      if strcmpi(param.img_type,img_type)
        img_type = 'mat';
      else
        img_type = param.img_type;
      end
      
    elseif strcmp(val,'I')
      fmcw_img_debug_mode = ~fmcw_img_debug_mode;
      fprintf(' Toggled false color and y-limits (currently %d)\n', fmcw_img_debug_mode);
      
    elseif ~isempty(strfind(upper(val),'J'))
      try
        val = input('    Enter frame to jump to: ');
      catch
        val = [];
      end
      if isempty(val)
        % Ignore command
      else
        [~,new_frm_idx] = min(abs(val-frms));
        if ~isempty(new_frm_idx)
          frm_idx = new_frm_idx;
        end
      end
      
    elseif ~isnan(num_val)
      if strcmpi(update_field_type,'double')
        fprintf('    Changing frames.%s(%d) to %d\n', update_field, frm, num_val);
      elseif strcmpi(update_field_type,'mask')
        if isnan(num_val)
          fprintf('    Changing frames.%s(%d) to %d\n', update_field, frm, num_val);
        else
          num_val = str2double(char(unique(double(sprintf('%d',num_val)))));
          if num_val ~= 0
            num_val = sum(2.^(double(sprintf('%d',num_val))-48-1));
          end
          fprintf('    Changing frames.%s(%d) to b%s (d%d)\n', update_field, ...
            frm, dec2bin(num_val,update_field_mask_len), num_val);
        end
      end
      frames.(update_field)(frm) = num_val;
      frm_idx = frm_idx + 1;
      
    elseif strcmpi(val,'n')
      fprintf('    Changing frames.%s(%d) to %d\n', update_field, frm, NaN);
      frames.(update_field)(frm) = NaN;
      frm_idx = frm_idx + 1;
      
    elseif strcmpi(val,'p')
      frm_idx = frm_idx - 1;
      
    elseif strcmpi(val,'q')
      quit_cmd = true;
      fprintf('Quitting\n');
      break;
      
    elseif strcmpi(val,'s')
      out_dir = fileparts(frames_fn);
      if ~exist(out_dir,'dir')
        mkdir(out_dir);
      end
      fprintf('  Saving frames file %s\n',frames_fn);
      ct_save(frames_fn,'-struct','frames');
      old_frames = frames;
      
    elseif strcmpi(val,'?')
      fprintf(' <enter>: go to next frame\n');
      fprintf(' p: previous frame\n');
      fprintf(' i: swap image type between mat and %s (currently %s)\n', param.img_type, img_type);
      fprintf(' I: toggle false color and y-limits (currently %d)\n', fmcw_img_debug_mode);
      fprintf(' d: print out differences or changes to frames so far\n');
      fprintf(' f: print out status of frames\n');
      fprintf(' j: jump to frame\n');
      fprintf(' c or k: enter matlab command\n');
      fprintf(' s: save frames file\n');
      fprintf(' q: quit\n');
      if strcmpi(update_field_type,'double')
        fprintf(' #: set frame.%s to #\n', update_field);
      else
        fprintf(' #[#...#]: sets frame.%s masks according to:\n', update_field);
        for idx=2:update_field_mask_len+1
          fprintf('   %d: %s\n',idx-1,update_field_mask{idx});
        end
        fprintf('   For example, entering the number 13 sets the first and third mask bits.\n   Entering 0 clears all mask bits.\n');
      end
    end
  end
end

%% Print out frames that changed
% Code is copied from (d)iff function above
fprintf('\n');
diff_frms = find((frames.(update_field)~=old_frames.(update_field) ...
  & ~(isnan(frames.(update_field)) & isnan(old_frames.(update_field)))));
fprintf('%s\t%s\t%s\t%s\t%s\n', 'Frm', 'Old_Value', 'New_Value', 'Old_Binary', 'New_Binary');
for cur_frm = diff_frms
  if isnan(old_frames.(update_field)(cur_frm))
    old_dec2bin_str = 'NaN';
  else
    old_dec2bin_str = dec2bin(old_frames.(update_field)(cur_frm),8);
  end
  if isnan(frames.(update_field)(cur_frm))
    dec2bin_str = 'NaN';
  else
    dec2bin_str = dec2bin(frames.(update_field)(cur_frm),8);
  end
  fprintf('%3.0f\t%9.0f\t%9.0f\t%10s\t%10s\n', cur_frm, ...
    old_frames.(update_field)(cur_frm), frames.(update_field)(cur_frm), ...
    old_dec2bin_str, dec2bin_str);
end
fprintf('\n');

if ~isempty(diff_frms)
  %% Save Output
  val = input(sprintf('Save frames.%s before quitting (Y/N)? ',update_field),'s');
  if strncmpi(val,'Y',1)
    out_dir = fileparts(frames_fn);
    if ~exist(out_dir,'dir')
      mkdir(out_dir);
    end
    fprintf('  Saving frames file %s\n',frames_fn);
    ct_save(frames_fn,'-struct','frames');
  else
    warning('Not saving (can still manually save by pasting save commands above this warning message).');
  end
end
