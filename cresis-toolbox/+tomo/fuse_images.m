function mdata = fuse_images(param)
% mdata = tomo.fuse_images(param)
%
% Description: Usually this function is called from tomo_collate_task.
%   Combines Data_img_II_YYYYMMDD_SS_FFF.mat data files into a single combined
%   Data_YYYYMMDD_SS_FFF.mat file.
%
% Inputs:
%   param: struct from parameter spreadsheet
%
% Outputs:
%   NONE
%
% See also: tomo.run_collate, tomo.collate, tomo_collate_task,
%   tomo.fuse_images, tomo.add_icemask_surfacedem, tomo.create_surfData,
%
% Author: John Paden, Jordan Sprick, and Mingze Xu

[~,radar_type,~] = ct_output_dir(param.radar_name);

% in_dir: Directory where 3D image files are at
in_dir = ct_filename_out(param,param.tomo_collate.in_path);

if ~isfield(param.tomo_collate, 'img_comb_trim') || isempty(param.tomo_collate.img_comb_trim)
  first_img = param.tomo_collate.imgs{1}(1);
  last_img = param.tomo_collate.imgs{end}(1);
  if strcmpi(radar_type,'deramp')
    param.tomo_collate.img_comb_trim = [0 0 0 inf];
  else
    % Set relative trim to be 50% support level or higher for pulse compression
    % Set absolute trim to be >= 0 time
    if iscell(param.array.imgs{first_img})
      % Multilook format (param_mode is 'array')
      wf_adc_list = param.array.imgs{first_img}{1};
    else
      wf_adc_list = param.array.imgs{first_img};
    end
    wf_first = wf_adc_list(1,1);
    if iscell(param.array.imgs{last_img})
      % Multilook format (param_mode is 'array')
      wf_adc_list = param.array.imgs{last_img}{1};
    else
      wf_adc_list = param.array.imgs{last_img};
    end
    wf_last = wf_adc_list(1,1);
    param.tomo_collate.img_comb_trim = [param.radar.wfs(wf_first).Tpd/2 -param.radar.wfs(wf_last).Tpd/2 0 inf];
  end
end

% This is to let fuse_images know that we are fusing a DOA method.
array_proc_methods; % This script assigns the integer values for each method
if ischar(param.array.method)
  % Convert array method string to integer
  method_integer = [];
  if regexpi(param.array.method,'music_doa')
    method_integer(end+1) = MUSIC_DOA_METHOD;
  end
  if regexpi(param.array.method,'mle')
    method_integer(end+1) = MLE_METHOD;
  end
  if regexpi(param.array.method,'dcm')
    method_integer(end+1) = DCM_METHOD;
  end
%   if regexpi(param.array.method,'pf')
%     method_integer(end+1) = PF_METHOD;
%   end
end
method_integer = intersect(method_integer, ...
  [MUSIC_DOA_METHOD MLE_METHOD DCM_METHOD PF_METHOD], 'stable');
if ~isempty(method_integer)
  doa_method_flag = true;
else
  doa_method_flag = false;
end

%% Horizontal fuse
% =========================================================================
mdata = {};
for v_img = 1:length(param.tomo_collate.imgs)
  Nimg = length(param.tomo_collate.imgs{v_img});
  fns = {};
  hdata = {};
  Tomo = [];
  for h_img = 1:length(param.tomo_collate.imgs{v_img})
    img = param.tomo_collate.imgs{v_img}(h_img);
    wf = param.array.imgs{v_img}(1,1);
    fns{h_img} = fullfile(in_dir,sprintf('Data_img_%02.0f_%s_%03.0f.mat',img, ...
      param.day_seg,param.load.frm));
    hdata{h_img} = load(fns{h_img});
    if 1
      % HACK TO UPGRADE FILES
      if isfield(hdata{h_img},'Topography')
        hdata{h_img}.Tomo = hdata{h_img}.Topography;
        hdata{h_img}.Tomo.theta = hdata{h_img}.param_array.array_param.theta(:);
        hdata{h_img}.param_array.array_proc = hdata{h_img}.param_array.array_param;
        hdata{h_img} = rmfield(hdata{h_img},'Topography');
        hdata{h_img}.param_array = rmfield(hdata{h_img}.param_array,'array_param');
        tmp_data = hdata{h_img};
        fprintf('  Updating %s\n', fns{h_img});
        save(fns{h_img},'-v7.3','-struct','tmp_data');
      end
    end
  end
  Nx = size(hdata{1}.Tomo.img,3);
  
  if v_img == 1
    % Copy first image file to combined "fused" image filename (this is a simple way
    % to copy all the parameters and support variables over). We will update
    % the 3D image and time fields in the file at the end of fusing.
    combined_fn = fullfile(in_dir,sprintf('Data_%s_%03.0f.mat',param.day_seg,param.load.frm));
    fprintf('Copying\n%s\n to\n%s (%s)\n', fns{1}, combined_fn, datestr(now));
    copyfile(fns{1}, combined_fn);
  end
  
  % Interpolate images onto a common propagation time axis
  % dt: Fast time sample period 
  dt = hdata{1}.Time(2)-hdata{1}.Time(1);
  % Time: common time axis between all images
  start_time = -inf;
  stop_time = inf;
  for img_idx = 1:Nimg
    if hdata{img_idx}.Time(1) > start_time
      start_time = hdata{img_idx}.Time(1);
    end
    if hdata{img_idx}.Time(end) < stop_time
      stop_time = hdata{img_idx}.Time(end);
    end
  end
  Time = start_time:dt:stop_time;

  % Reinterpolate images onto common time axis
  Data = interp1(hdata{1}.Time,hdata{1}.Data,Time);
  for img_idx = 1:Nimg
    hdata{img_idx}.Tomo.img = interp1(hdata{img_idx}.Time,hdata{img_idx}.Tomo.img,Time);
    if doa_method_flag
      hdata{img_idx}.Tomo.theta   = interp1(hdata{img_idx}.Time,hdata{img_idx}.Tomo.theta,Time);
      hdata{img_idx}.Tomo.cost    = interp1(hdata{img_idx}.Time,hdata{img_idx}.Tomo.cost,Time);
      hdata{img_idx}.Tomo.hessian = interp1(hdata{img_idx}.Time,hdata{img_idx}.Tomo.hessian,Time);
    end
  end
  
  % Nx: number of range lines
  Nx = size(hdata{1}.Tomo.img,3);
  % Nsv: number of steering vector/directions of arrival
  Nsv = size(hdata{1}.Tomo.img,2);

  % Create fuse weights
  fuse_weights = [];
  Tomo.img = zeros(size(hdata{1}.Tomo.img));
  if Nimg > 1
    for img_idx = 1:Nimg
      fuse_weights(img_idx,:) = exp( -((0:Nsv-1)-Nsv*((Nimg-img_idx)*2+1)/(2*Nimg)).^2 / (2*(Nsv/Nimg).^1.5) );
      Tomo.img = Tomo.img + bsxfun(@times,fuse_weights(img_idx,:), ...
        hdata{img_idx}.Tomo.img);
    end
    Tomo.img = bsxfun(@times,1./sum(fuse_weights),Tomo.img);
  else
    Tomo.img = hdata{img_idx}.Tomo.img;
    if doa_method_flag
      Tomo.theta = hdata{img_idx}.Tomo.theta;
      Tomo.cost = hdata{img_idx}.Tomo.cost;
      Tomo.hessian = hdata{img_idx}.Tomo.hessian;
    end
  end
  
  mdata{v_img} = hdata{1};
  mdata{v_img}.Time = Time;
  mdata{v_img}.Data = Data;
  
  if doa_method_flag
%     mdata{v_img}.Tomo.img     = hdata{v_img}.Tomo.img;
%     mdata{v_img}.Tomo.theta   = hdata{v_img}.Tomo.theta;
%     mdata{v_img}.Tomo.cost    = hdata{v_img}.Tomo.cost;
%     mdata{v_img}.Tomo.hessian = hdata{v_img}.Tomo.hessian;
  else
    mdata{v_img}.Tomo.img   = Tomo.img;
    mdata{v_img}.Tomo.theta = hdata{1}.Tomo.theta;
  end
  clear hdata;
end

%% Vertical fuse
% =========================================================================
Tomo = [];
for v_img = 1:length(param.tomo_collate.imgs)
  if v_img == 1
    Time = mdata{v_img}.Time;
    Data = mdata{v_img}.Data;
    Tomo.img = mdata{v_img}.Tomo.img;
    Tomo.theta = mdata{v_img}.Tomo.theta;
    if doa_method_flag
      Tomo.cost = mdata{v_img}.Tomo.cost;
      Tomo.hessian = mdata{v_img}.Tomo.hessian;
    end
    first_idx = find(Time >= Time(1)+param.tomo_collate.img_comb_trim(1) ...
      & Time >= param.tomo_collate.img_comb_trim(3),1,'first');
    if ~isempty(first_idx)
      Time = Time(first_idx:end);
      Data = Data(first_idx:end,:);
      Tomo.img = Tomo.img(first_idx:end,:,:);
      if doa_method_flag
        Tomo.theta = Tomo.theta(first_idx:end,:,:);
        Tomo.cost = Tomo.cost(first_idx:end,:);
        Tomo.hessian = Tomo.hessian(first_idx:end,:,:);
      end
    else
      error('Zero range bin length images not supported.');
    end
    if v_img == length(param.tomo_collate.imgs)
      last_idx = find(Time <= Time(end)+param.tomo_collate.img_comb_trim(2) ...
        & Time <= param.tomo_collate.img_comb_trim(4),1,'last');
      if ~isempty(last_idx)
        Time = Time(1:last_idx);
        Data = Data(1:last_idx,:);
        Tomo.img = Tomo.img(1:last_idx,:,:);
        if doa_method_flag
          Tomo.theta = Tomo.theta(1:last_idx,:,:);
          Tomo.cost = Tomo.cost(1:last_idx,:,:);
          Tomo.hessian = Tomo.hessian(1:last_idx,:,:);
        end
      else
        error('Zero range bin length images not supported.');
      end
    end
    
  else
    % Combine images
    % Data,Time => already loaded data
    % mdata{v_img}.Data, mdata{v_img}.Time => new data to mdata{v_img}
    % New_Time, New_Data => Combined result
    if v_img == length(param.tomo_collate.imgs)
      last_idx = find(mdata{v_img}.Time <= mdata{v_img}.Time(end)+param.tomo_collate.img_comb_trim(2) ...
        & mdata{v_img}.Time <= param.tomo_collate.img_comb_trim(4),1,'last');
      if ~isempty(last_idx)
        mdata{v_img}.Time = mdata{v_img}.Time(1:last_idx);
        mdata{v_img}.Data = mdata{v_img}.Data(1:last_idx,:);
        mdata{v_img}.Tomo.img = mdata{v_img}.Tomo.img(1:last_idx,:,:);
        if doa_method_flag
          mdata{v_img}.Tomo.theta = mdata{v_img}.Tomo.theta(1:last_idx,:,:);
          mdata{v_img}.Tomo.cost = mdata{v_img}.Tomo.cost(1:last_idx,:,:);
          mdata{v_img}.Tomo.hessian = mdata{v_img}.Tomo.hessian(1:last_idx,:,:);
        end
      else
        error('Zero range bin length images not supported.');
      end
    end
    
    % Interpolate image N onto already loaded data (assumption is that image
    % N-1 always comes before image N)
    New_Time = (Time(1) : dt : mdata{v_img}.Time(end)).';
    mdata{v_img}.Data = interp1(mdata{v_img}.Time,mdata{v_img}.Data,New_Time,'linear',0);
    mdata{v_img}.Tomo.img = interp1(mdata{v_img}.Time,mdata{v_img}.Tomo.img,New_Time,'linear',0);
    if doa_method_flag
      mdata{v_img}.Tomo.theta = interp1(mdata{v_img}.Time,mdata{v_img}.Tomo.theta,New_Time,'linear',0);
      mdata{v_img}.Tomo.cost = interp1(mdata{v_img}.Time,mdata{v_img}.Tomo.cost,New_Time,'linear',0);
      mdata{v_img}.Tomo.hessian = interp1(mdata{v_img}.Time,mdata{v_img}.Tomo.hessian,New_Time,'linear',0);
    end
    
    % Surface tracking image combine
    %  param.tomo_collate.img_comb(1): time after surface return where
    %    combine will happen
    %  param.tomo_collate.img_comb(2): minimum time that combine will occur
    %  param.tomo_collate.img_comb(3): guard time which specifies how
    %    many seconds at the end of img1 will not be used... this is
    %    important because the last samples of img1 will have low signal
    %    power and blurred because they will only have captured a portion
    %    of the chirp energy (typically this will be set to something
    %    close to the pulse duration for img1)
    %  param.tomo_collate.img_comb(4-6, 7-9, etc.): same fields as above
    %    except between images 2 and 3, 3 and 4, etc.
    
    Surface = interp_finite(mdata{v_img}.Surface,0);
    % First row of img_bins indicates the start of the blend-region
    img_bins = round(interp1(New_Time, 1:length(New_Time), ...
      max(Surface+param.tomo_collate.img_comb((v_img-2)*3+1),param.tomo_collate.img_comb((v_img-2)*3+2)), 'linear','extrap'));
    
    % Determine guard at end of image 1 that will not be used
    guard_bins = 1 + round(param.tomo_collate.img_comb((v_img-2)*3+3)/dt);
    
    % Check to make sure requested time is inside window and just
    % force the combination bin to occur at the second to last bin
    %   img_bins outside the img1 time window will be NaN due to interp1
    %   img_bins inside the img1 time window may still be larger than
    %     the guard allows
    max_good_time = length(Time)*ones(1,Nx);
    invalid_rlines = find(isnan(img_bins) ...
      | img_bins > max_good_time-guard_bins);
    img_bins(invalid_rlines) = max_good_time(invalid_rlines)-guard_bins;
    
    % Second row of img_bins indicates the end of the blend-region
    img_bins(2,:) = img_bins(1,:) + 10;
    img_bins(2,img_bins(2,:)>length(Time)) = length(Time);
    
    difference = 10^(-0/10);
    
    % Combine images
    New_Data = zeros(size(mdata{v_img}.Data),'single');
    New_Img = zeros(size(mdata{v_img}.Tomo.img),'single');
    if doa_method_flag
      New_Theta = zeros(size(mdata{v_img}.Tomo.theta),'single');
      New_Cost = zeros(size(mdata{v_img}.Tomo.cost),'single');
      New_Hessian = zeros(size(mdata{v_img}.Tomo.hessian),'single');
    end
    for rline = 1:Nx
      trans_bins = img_bins(1,rline)+1:img_bins(2,rline);
      weights = 0.5+0.5*cos(pi*linspace(0,1,length(trans_bins)).');
      if trans_bins(end) <= size(mdata{v_img}.Data,1)
        New_Data(:,rline) = [Data(1:img_bins(1,rline),rline); ...
          weights.*Data(trans_bins,rline) ...
          + difference*(1-weights).*mdata{v_img}.Data(trans_bins,rline); ...
          difference*mdata{v_img}.Data(img_bins(2,rline)+1:end,rline)];
        New_Img(:,:,rline) = [Tomo.img(1:img_bins(1,rline),:,rline); ...
          bsxfun(@times,weights,Tomo.img(trans_bins,:,rline)) ...
          + bsxfun(@times,difference*(1-weights),mdata{v_img}.Tomo.img(trans_bins,:,rline)); ...
          difference*mdata{v_img}.Tomo.img(img_bins(2,rline)+1:end,:,rline)];
        if doa_method_flag
          New_Theta(:,:,rline) = [Tomo.theta(1:img_bins(1,rline),:,rline); ...
            zeros(length(trans_bins),size(Tomo.theta,2)) ...
            + mdata{v_img}.Tomo.theta(trans_bins,:,rline); ...
            mdata{v_img}.Tomo.theta(img_bins(2,rline)+1:end,:,rline)];
          New_Cost(:,rline) = [Tomo.cost(1:img_bins(1,rline),rline); ...
            zeros(length(trans_bins),1) ...
            + mdata{v_img}.Tomo.cost(trans_bins,rline); ...
            difference*mdata{v_img}.Tomo.cost(img_bins(2,rline)+1:end,rline)];
          New_Hessian(:,:,rline) = [Tomo.hessian(1:img_bins(1,rline),:,rline); ...
            zeros(length(trans_bins),size(Tomo.hessian,2)) ...
            + mdata{v_img}.Tomo.hessian(trans_bins,:,rline); ...
            difference*mdata{v_img}.Tomo.hessian(img_bins(2,rline)+1:end,:,rline)];
        end
      else
        New_Data(:,rline) = Data(1:size(New_Data,1),rline);
        New_Img(:,:,rline) = Tomo.img(1:size(New_Data,1),:,rline);
        if doa_method_flag
          New_Theta(:,:,rline) = Tomo.theta(1:size(New_Data,1),:,rline);
          New_Cost(:,rline) = Tomo.cost(1:size(New_Data,1),rline);
          New_Hessian(:,:,rline) = Tomo.hessian(1:size(New_Data,1),:,rline);
        end
      end
    end
    Time = New_Time;
    Data = New_Data;
    Tomo.img = New_Img;
    if doa_method_flag
      Tomo.theta = New_Theta;
      Tomo.cost = New_Cost;
      Tomo.hessian = New_Hessian;
    end
  end
end

% Append new fused image to the combined file
fprintf('Saving %s (%s)\n', combined_fn, datestr(now));
if param.ct_file_lock
  file_version = '1L';
else
  file_version = '1';
end
save(combined_fn,'-append','Time','Data','Tomo','file_version');

% Create output argument which contains combined image
mdata = mdata{1};
mdata.Time = Time;
mdata.Data = Data;
mdata.Tomo.img = Tomo.img;
mdata.Tomo.theta = Tomo.theta;
if doa_method_flag
  mdata.Tomo.cost = Tomo.cost;
  mdata.Tomo.hessian = Tomo.hessian;
end
