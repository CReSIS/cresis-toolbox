function success = array_task(param)
% success = array_task(param)
%
% Task/job running on cluster that is called from array. This
% function is generally not called directly.
%
% success = boolean which is true when the function executes properly
%   if a task fails before it can return success, then success will be
%   empty
%
% Authors: John Paden
%
% See also: run_master.m, master.m, run_array.m, array.m, load_sar_data.m,
% array_proc.m, array_task.m, array_combine_task.m

%% Preparation
% =========================================================================

% speed of light, wgs84 ellipsoid
physical_constants;

% Rename for code readability
sar_type = param.array.sar_type;
data_field_name = sprintf('%s_data', sar_type);

% Input directory (SAR SLC images)
in_fn_dir = fullfile(ct_filename_out(param, param.array.in_path), ...
  sprintf('%s_data_%03d_01_01', sar_type, param.load.frm));

% Temporary output directory for uncombined array processed images
array_tmp_dir = fullfile(ct_filename_out(param, param.array.out_path, 'array_tmp'), ...
  sprintf('array_%03d', param.load.frm));

%% Load surface layer
% =========================================================================
frames_fn = ct_filename_support(param,'','frames');
frames = frames_load(param);
tmp_param = param;
tmp_param.cmd.frms = max(1,param.load.frm-1) : min(length(frames.frame_idxs),param.load.frm+1);

if strcmpi(param.array.surf_layer.source, 'surf_sar')
  surf_dir = ct_filename_out(param,'','surf_sar');
  fn_name = sprintf('Data_%s_%03.0f.mat',param.day_seg,param.load.frm);
  fn = fullfile(surf_dir,fn_name);
  surf_layer = tomo.surfdata(fn,param);
else
  surf_layer = opsLoadLayers(tmp_param,param.array.surf_layer);
end

%% Process
% =========================================================================
% Load and process each img independently.
for img = 1:length(param.array.imgs)
  %% Process: Per Img Setup
  % =======================================================================
  % ml_list is the list of SLC images that we will multilook across. It is
  % a cell array of wf_adc_tables. Each will be array processed separately,
  % but will be combined during multilooking. Typically this multilooking
  % across images is not used so that there is usually a single
  % cell/wf_adc_table in ml_list.
  ml_list = param.array.imgs{img};
  wf_base = ml_list{1}(1,1);
  
  %% Process: Load data
  % =======================================================================
  %  wf_adc_list = {[1 1],[1 2],[1 3],[1 4],[1 5]}
  %    This will multilook these 5 SLC images (e.g. add incoherently in the case
  %    of periodogram)
  %  wf_adc_list = {[1 1; 1 2; 1 3; 1 4; 1 5]}
  %    This will coherently add these 5 SLC images
  if strcmpi(param.array.method,'combine_rx')
    % SAR processing has already coherently combined every image in each
    % image list, so we only grab the first image.  Multilooking across
    % SLCs IS NOT supported for this method!
    ml_list = {ml_list{1}(1,:)};
  end
  clear fcs chan_equal data lat lon elev;
  num_next_rlines = 0;
  prev_chunk_failed_flag = false;
  next_chunk_failed_flag = false;
  % num_prev_chunk_rlines: number of range lines to load from the previous chunk
  num_prev_chunk_rlines = round(max(-param.array.line_rng));
  % prev_time: previous chunk time-axis (empty until some previous time
  % data are loaded
  prev_time = [];
  % num_next_chunk_rlines: number of range lines to load from the next
  % chunk; this will get updated when the next chunk successfully loads
  num_next_chunk_rlines = 0;
  % out_rlines: output range lines from SAR processor for the current chunk
  sar_out_rlines = [];
  for ml_idx = 1:length(ml_list)
    wf_adc_list = ml_list{ml_idx};
    for wf_adc = 1:size(wf_adc_list,1)
      wf = wf_adc_list(wf_adc,1);
      adc = wf_adc_list(wf_adc,2);
      for subap = param.array.subaps{img}{ml_idx}
        for subbnd = param.array.subbnds{img}{ml_idx}
          in_fn_dir(end-4:end-3) = sprintf('%02d',subap);
          in_fn_dir(end-1:end) = sprintf('%02d',subbnd);
          
          if ml_idx == 1 && subap == param.array.subaps{img}{ml_idx}(1) ...
              && subbnd == param.array.subbnds{img}{ml_idx}(1)
            % Load current chunk metadata
            % =============================================================
            load_frm = param.load.frm;
            load_chunk_idx = param.load.chunk_idx;
            in_fn_dir(end-8:end-6) = sprintf('%03d',load_frm);
            if strcmpi(param.array.method,'combine_rx')
              in_fn_name_pre = sprintf('img_%02.0f_chk_%03.0f', img, load_chunk_idx);
              [sar_type_fn,status] = get_filenames(in_fn_dir, ...
                in_fn_name_pre,'','.mat');
            else
              in_fn_name_pre = sprintf('wf_%02.0f_adc_%02.0f_chk_%03.0f', wf, adc, load_chunk_idx);
              [sar_type_fn,status] = get_filenames(in_fn_dir, ...
                in_fn_name_pre,'','.mat');
            end
            if isempty(sar_type_fn)
              error('No match for input sar file: %s*.mat', fullfile(in_fn_dir, in_fn_name_pre));
            end
            sar_data = load(sar_type_fn{1},'wfs','param_records','param_sar');
            % Time: fast-time axis can be different for each chunk so we
            % need to force the previous and next chunks to align with the
            % current chunks time axis
            Time = sar_data.wfs(wf_base).time;
            dt = Time(2)-Time(1);
            % param_records,param_sar: Only needs to be loaded one time
            param_records = sar_data.param_records;
            param_sar = sar_data.param_sar;
          end
          
          % Load previous chunk data
          % ===============================================================
          
          % If on the first chunk of the frame, then look at the previous
          % frame. Special cases (like frm == 1 and empty
          % param.load.prev_frm_num_chunks are handled by letting the file
          % search fail).
          if param.load.chunk_idx == 1
            load_frm = param.load.frm-1;
            load_chunk_idx = param.load.prev_frm_num_chunks;
          else
            load_frm = param.load.frm;
            load_chunk_idx = param.load.chunk_idx - 1;
          end
          
          % Create the filename
          in_fn_dir(end-8:end-6) = sprintf('%03d',load_frm);
          if strcmpi(param.array.method,'combine_rx')
            [sar_type_fn,status] = get_filenames(in_fn_dir, ...
              sprintf('img_%02.0f_chk_%03.0f', img, load_chunk_idx),'','.mat');
          else
            [sar_type_fn,status] = get_filenames(in_fn_dir, ...
              sprintf('wf_%02.0f_adc_%02.0f_chk_%03.0f', wf, adc, load_chunk_idx),'','.mat');
          end
          
          if ~prev_chunk_failed_flag && ~isempty(sar_type_fn)
            % If file exists, then load it
            sar_data = load(sar_type_fn{1});
            rlines = 1:num_prev_chunk_rlines;
            
            if size(sar_data.(data_field_name),2) >= num_prev_chunk_rlines
              if subap == param.array.subaps{img}{ml_idx}(1) && subbnd == param.array.subbnds{img}{ml_idx}(1)
                fcs{ml_idx}{wf_adc}.origin(:,rlines) = sar_data.fcs.origin(:,end-num_prev_chunk_rlines+1:end);
                fcs{ml_idx}{wf_adc}.x(:,rlines) = sar_data.fcs.x(:,end-num_prev_chunk_rlines+1:end);
                fcs{ml_idx}{wf_adc}.y(:,rlines) = sar_data.fcs.y(:,end-num_prev_chunk_rlines+1:end);
                fcs{ml_idx}{wf_adc}.z(:,rlines) = sar_data.fcs.z(:,end-num_prev_chunk_rlines+1:end);
                fcs{ml_idx}{wf_adc}.roll(rlines) = sar_data.fcs.roll(end-num_prev_chunk_rlines+1:end);
                fcs{ml_idx}{wf_adc}.pitch(rlines) = sar_data.fcs.pitch(end-num_prev_chunk_rlines+1:end);
                fcs{ml_idx}{wf_adc}.heading(rlines) = sar_data.fcs.heading(end-num_prev_chunk_rlines+1:end);
                fcs{ml_idx}{wf_adc}.gps_time(rlines) = sar_data.fcs.gps_time(end-num_prev_chunk_rlines+1:end);
                fcs{ml_idx}{wf_adc}.surface(rlines) = sar_data.fcs.surface(end-num_prev_chunk_rlines+1:end);
                fcs{ml_idx}{wf_adc}.bottom(rlines) = sar_data.fcs.bottom(end-num_prev_chunk_rlines+1:end);
                fcs{ml_idx}{wf_adc}.pos(:,rlines) = sar_data.fcs.pos(:,end-num_prev_chunk_rlines+1:end);
                lat(rlines) = sar_data.lat(:,end-num_prev_chunk_rlines+1:end);
                lon(rlines) = sar_data.lon(:,end-num_prev_chunk_rlines+1:end);
                elev(rlines) = sar_data.elev(:,end-num_prev_chunk_rlines+1:end);
              end
              
              % Correct any changes in Tsys
              Tsys = param.radar.wfs(wf).Tsys(param.radar.wfs(wf).rx_paths(adc));
              Tsys_old = sar_data.param_sar.radar.wfs(wf).Tsys(param.radar.wfs(wf).rx_paths(adc));
              dTsys = Tsys-Tsys_old;
              if dTsys ~= 0
                % Positive dTsys means Tsys > Tsys_old and we should reduce the
                % time delay to all targets by dTsys.
                sar_data.(data_field_name) = ifft(bsxfun(@times,fft(sar_data.(data_field_name),[],1),exp(1i*2*pi*sar_data.wfs(wf).freq*dTsys)),[],1);
              end
              
              % Concatenate data (resample in fast-time if needed since
              % each chunk may have a different time-axis)
              rbins = round((sar_data.wfs(wf_base).time - Time(1))/dt);
              offset = max(0,-rbins(1));
              len = length(rbins)-offset-max(rbins(end)-length(Time)+1,0);
              data{ml_idx}(1:length(Time),rlines,subap,subbnd,wf_adc) = NaN;
              data{ml_idx}(1+rbins(offset+(1:len)),rlines,subap,subbnd,wf_adc) ...
                = sar_data.(data_field_name)(offset+(1:len),end-num_prev_chunk_rlines+1:end);
            else
              prev_chunk_failed_flag = true;
            end
          else
            % If file does not exist, then give up loading previous chunk
            % data
            prev_chunk_failed_flag = true;
          end
          
          % Load current chunk data
          % ===============================================================
          load_frm = param.load.frm;
          load_chunk_idx = param.load.chunk_idx;
          in_fn_dir(end-8:end-6) = sprintf('%03d',load_frm);
          if strcmpi(param.array.method,'combine_rx')
            in_fn_name_pre = sprintf('img_%02.0f_chk_%03.0f', img, load_chunk_idx);
            [sar_type_fn,status] = get_filenames(in_fn_dir, ...
              in_fn_name_pre,'','.mat');
          else
            in_fn_name_pre = sprintf('wf_%02.0f_adc_%02.0f_chk_%03.0f', wf, adc, load_chunk_idx);
            [sar_type_fn,status] = get_filenames(in_fn_dir, ...
              in_fn_name_pre,'','.mat');
          end
          if isempty(sar_type_fn)
            error('No match for input sar file: %s*.mat', fullfile(in_fn_dir, in_fn_name_pre));
          end
          sar_data = load(sar_type_fn{1});
          num_rlines = size(sar_data.(data_field_name),2);
          rlines = num_prev_chunk_rlines + (1:num_rlines);
          
          if subap == param.array.subaps{img}{ml_idx}(1) && subbnd == param.array.subbnds{img}{ml_idx}(1)
            fcs{ml_idx}{wf_adc}.Lsar = sar_data.fcs.Lsar;
            fcs{ml_idx}{wf_adc}.gps_source = sar_data.fcs.gps_source;
            fcs{ml_idx}{wf_adc}.origin(:,rlines) = sar_data.fcs.origin;
            fcs{ml_idx}{wf_adc}.x(:,rlines) = sar_data.fcs.x;
            fcs{ml_idx}{wf_adc}.y(:,rlines) = sar_data.fcs.y;
            fcs{ml_idx}{wf_adc}.z(:,rlines) = sar_data.fcs.z;
            fcs{ml_idx}{wf_adc}.roll(rlines) = sar_data.fcs.roll;
            fcs{ml_idx}{wf_adc}.pitch(rlines) = sar_data.fcs.pitch;
            fcs{ml_idx}{wf_adc}.heading(rlines) = sar_data.fcs.heading;
            fcs{ml_idx}{wf_adc}.gps_time(rlines) = sar_data.fcs.gps_time;
            fcs{ml_idx}{wf_adc}.surface(rlines) = sar_data.fcs.surface;
            fcs{ml_idx}{wf_adc}.bottom(rlines) = sar_data.fcs.bottom;
            fcs{ml_idx}{wf_adc}.pos(:,rlines) = sar_data.fcs.pos;
            fcs{ml_idx}{wf_adc}.squint = sar_data.fcs.squint;
            lat(rlines) = sar_data.lat;
            lon(rlines) = sar_data.lon;
            elev(rlines) = sar_data.elev;
            if isfield(sar_data.fcs,'type')
              fcs{ml_idx}{wf_adc}.type = sar_data.fcs.type;
              fcs{ml_idx}{wf_adc}.filter = sar_data.fcs.filter;
            else
              fcs{ml_idx}{wf_adc}.type = [];
              fcs{ml_idx}{wf_adc}.filter = [];
            end
            sar_out_rlines = sar_data.out_rlines;
            
            chan_equal{ml_idx}(wf_adc) ...
              = 10.^((param.radar.wfs(wf).chan_equal_dB(param.radar.wfs(wf).rx_paths(adc)) ...
              - sar_data.param_sar.radar.wfs(wf).chan_equal_dB(param.radar.wfs(wf).rx_paths(adc)) )/20) ...
              .* exp(1i*( ...
              param.radar.wfs(wf).chan_equal_deg(param.radar.wfs(wf).rx_paths(adc)) ...
              - sar_data.param_sar.radar.wfs(wf).chan_equal_deg(param.radar.wfs(wf).rx_paths(adc)) )/180*pi);
            
          end
          
          % Correct any changes in Tsys
          Tsys = param.radar.wfs(wf).Tsys(param.radar.wfs(wf).rx_paths(adc));
          Tsys_old = sar_data.param_sar.radar.wfs(wf).Tsys(param.radar.wfs(wf).rx_paths(adc));
          dTsys = Tsys-Tsys_old;
          if dTsys ~= 0
            % Positive dTsys means Tsys > Tsys_old and we should reduce the
            % time delay to all targets by dTsys.
            sar_data.(data_field_name) = ifft(bsxfun(@times,fft(sar_data.(data_field_name),[],1),exp(1i*2*pi*sar_data.wfs(wf).freq*dTsys)),[],1);
          end
          
          % Concatenate data (handle situation of time axis of previous
          % chunk not aligning with current chunk
          data{ml_idx}(:,rlines,subap,subbnd,wf_adc) = sar_data.(data_field_name);
          
          % Load next chunk data
          % ===============================================================
          
          % If on the last chunk of the frame, then look at the next
          % frame. Special case when frm > number-of-frames checked.
          if param.load.chunk_idx == param.load.num_chunks
            load_frm = param.load.frm+1;
            load_chunk_idx = 1;
          else
            load_frm = param.load.frm;
            load_chunk_idx = param.load.chunk_idx + 1;
          end
          
          % Create the filename
          in_fn_dir(end-8:end-6) = sprintf('%03d',load_frm);
          if strcmpi(param.array.method,'combine_rx')
            [sar_type_fn,status] = get_filenames(in_fn_dir, ...
              sprintf('img_%02.0f_chk_%03.0f', img, load_chunk_idx),'','.mat');
          else
            [sar_type_fn,status] = get_filenames(in_fn_dir, ...
              sprintf('wf_%02.0f_adc_%02.0f_chk_%03.0f', wf, adc, load_chunk_idx),'','.mat');
          end
          
          if ~next_chunk_failed_flag && ~isempty(sar_type_fn) && load_frm <= length(frames.frame_idxs)
            % If file exists, then load it
            sar_data = load(sar_type_fn{1});
            
            if size(sar_data.(data_field_name),2) >= num_next_chunk_rlines
              if subap == param.array.subaps{img}{ml_idx}(1) && subbnd == param.array.subbnds{img}{ml_idx}(1)
                % num_next_chunk_rlines: number of range lines to load from
                % the next chunk. Update with actual value now that we know
                % the data are available.
                num_next_chunk_rlines = round(max(param.array.line_rng));
                rlines = num_prev_chunk_rlines + num_rlines + (1:num_next_chunk_rlines);
                
                fcs{ml_idx}{wf_adc}.origin(:,rlines) = sar_data.fcs.origin(:,1:num_next_chunk_rlines);
                fcs{ml_idx}{wf_adc}.x(:,rlines) = sar_data.fcs.x(:,1:num_next_chunk_rlines);
                fcs{ml_idx}{wf_adc}.y(:,rlines) = sar_data.fcs.y(:,1:num_next_chunk_rlines);
                fcs{ml_idx}{wf_adc}.z(:,rlines) = sar_data.fcs.z(:,1:num_next_chunk_rlines);
                fcs{ml_idx}{wf_adc}.roll(rlines) = sar_data.fcs.roll(1:num_next_chunk_rlines);
                fcs{ml_idx}{wf_adc}.pitch(rlines) = sar_data.fcs.pitch(1:num_next_chunk_rlines);
                fcs{ml_idx}{wf_adc}.heading(rlines) = sar_data.fcs.heading(1:num_next_chunk_rlines);
                fcs{ml_idx}{wf_adc}.gps_time(rlines) = sar_data.fcs.gps_time(1:num_next_chunk_rlines);
                fcs{ml_idx}{wf_adc}.surface(rlines) = sar_data.fcs.surface(1:num_next_chunk_rlines);
                fcs{ml_idx}{wf_adc}.bottom(rlines) = sar_data.fcs.bottom(1:num_next_chunk_rlines);
                fcs{ml_idx}{wf_adc}.pos(:,rlines) = sar_data.fcs.pos(:,1:num_next_chunk_rlines);
                lat(rlines) = sar_data.lat(:,1:num_next_chunk_rlines);
                lon(rlines) = sar_data.lon(:,1:num_next_chunk_rlines);
                elev(rlines) = sar_data.elev(:,1:num_next_chunk_rlines);
              end
              
              % Correct any changes in Tsys
              Tsys = param.radar.wfs(wf).Tsys(param.radar.wfs(wf).rx_paths(adc));
              Tsys_old = sar_data.param_sar.radar.wfs(wf).Tsys(param.radar.wfs(wf).rx_paths(adc));
              dTsys = Tsys-Tsys_old;
              if dTsys ~= 0
                % Positive dTsys means Tsys > Tsys_old and we should reduce the
                % time delay to all targets by dTsys.
                sar_data.(data_field_name) = ifft(bsxfun(@times,fft(sar_data.(data_field_name),[],1),exp(1i*2*pi*sar_data.wfs(wf).freq*dTsys)),[],1);
              end
              
              % Concatenate data (resample in fast-time if needed since
              % each chunk may have a different time-axis)
              rbins = round((sar_data.wfs(wf_base).time - Time(1))/dt);
              offset = max(0,-rbins(1));
              len = length(rbins)-offset-max(rbins(end)-length(Time)+1,0);
              data{ml_idx}(1:length(Time),rlines,subap,subbnd,wf_adc) = NaN;
              data{ml_idx}(1+rbins(offset+(1:len)),rlines,subap,subbnd,wf_adc) ...
                = sar_data.(data_field_name)(offset+(1:len),1:num_next_chunk_rlines);
            else
              next_chunk_failed_flag = true;
            end
          else
            % If file does not exist, then give up loading previous chunk
            % data
            next_chunk_failed_flag = true;
          end
          
        end
      end
    end
  end
  
  if prev_chunk_failed_flag
    % Remove prev chunk data
    lat = lat(num_prev_chunk_rlines+1:end);
    lon = lon(num_prev_chunk_rlines+1:end);
    elev = elev(num_prev_chunk_rlines+1:end);
    for ml_idx = 1:length(ml_list)
      data{ml_idx} = data{ml_idx}(:,num_prev_chunk_rlines+1:end,:,:,:);
      for wf_adc = 1:size(wf_adc_list,1)
        fcs{ml_idx}{wf_adc}.origin = fcs{ml_idx}{wf_adc}.origin(:,num_prev_chunk_rlines+1:end);
        fcs{ml_idx}{wf_adc}.x = fcs{ml_idx}{wf_adc}.x(:,num_prev_chunk_rlines+1:end);
        fcs{ml_idx}{wf_adc}.y = fcs{ml_idx}{wf_adc}.y(:,num_prev_chunk_rlines+1:end);
        fcs{ml_idx}{wf_adc}.z = fcs{ml_idx}{wf_adc}.z(:,num_prev_chunk_rlines+1:end);
        fcs{ml_idx}{wf_adc}.roll = fcs{ml_idx}{wf_adc}.roll(num_prev_chunk_rlines+1:end);
        fcs{ml_idx}{wf_adc}.pitch = fcs{ml_idx}{wf_adc}.pitch(num_prev_chunk_rlines+1:end);
        fcs{ml_idx}{wf_adc}.heading = fcs{ml_idx}{wf_adc}.heading(num_prev_chunk_rlines+1:end);
        fcs{ml_idx}{wf_adc}.gps_time = fcs{ml_idx}{wf_adc}.gps_time(num_prev_chunk_rlines+1:end);
        fcs{ml_idx}{wf_adc}.surface = fcs{ml_idx}{wf_adc}.surface(num_prev_chunk_rlines+1:end);
        fcs{ml_idx}{wf_adc}.bottom = fcs{ml_idx}{wf_adc}.bottom(num_prev_chunk_rlines+1:end);
        fcs{ml_idx}{wf_adc}.pos = fcs{ml_idx}{wf_adc}.pos(:,num_prev_chunk_rlines+1:end);
      end
    end
    num_prev_chunk_rlines = 0;
  end
  
  if next_chunk_failed_flag
    % Remove next chunk data
    lat = lat(1:end-num_next_chunk_rlines);
    lon = lon(1:end-num_next_chunk_rlines);
    elev = elev(1:end-num_next_chunk_rlines);
    for ml_idx = 1:length(ml_list)
      data{ml_idx} = data{ml_idx}(:,1:end-num_next_chunk_rlines,:,:,:);
      for wf_adc = 1:size(wf_adc_list,1)
        fcs{ml_idx}{wf_adc}.origin = fcs{ml_idx}{wf_adc}.origin(:,1:end-num_next_chunk_rlines);
        fcs{ml_idx}{wf_adc}.x = fcs{ml_idx}{wf_adc}.x(:,1:end-num_next_chunk_rlines);
        fcs{ml_idx}{wf_adc}.y = fcs{ml_idx}{wf_adc}.y(:,1:end-num_next_chunk_rlines);
        fcs{ml_idx}{wf_adc}.z = fcs{ml_idx}{wf_adc}.z(:,1:end-num_next_chunk_rlines);
        fcs{ml_idx}{wf_adc}.roll = fcs{ml_idx}{wf_adc}.roll(1:end-num_next_chunk_rlines);
        fcs{ml_idx}{wf_adc}.pitch = fcs{ml_idx}{wf_adc}.pitch(1:end-num_next_chunk_rlines);
        fcs{ml_idx}{wf_adc}.heading = fcs{ml_idx}{wf_adc}.heading(1:end-num_next_chunk_rlines);
        fcs{ml_idx}{wf_adc}.gps_time = fcs{ml_idx}{wf_adc}.gps_time(1:end-num_next_chunk_rlines);
        fcs{ml_idx}{wf_adc}.surface = fcs{ml_idx}{wf_adc}.surface(1:end-num_next_chunk_rlines);
        fcs{ml_idx}{wf_adc}.bottom = fcs{ml_idx}{wf_adc}.bottom(1:end-num_next_chunk_rlines);
        fcs{ml_idx}{wf_adc}.pos = fcs{ml_idx}{wf_adc}.pos(:,1:end-num_next_chunk_rlines);
      end
    end
    num_next_chunk_rlines = 0;
  end
  
  %% Process: Fast-time oversampling
  % =======================================================================
  if param.array.ft_over_sample ~= 1
    % param.array.ft_over_sample should be a positive integer
    for ml_idx = 1:length(data)
      data{ml_idx} = interpft_memeff(data{ml_idx},size(data{ml_idx},1) * param.array.ft_over_sample);
    end
    for wf = 1:length(sar_data.wfs)
      sar_data.wfs(wf).fs = sar_data.wfs(wf).fs * param.array.ft_over_sample;
      sar_data.wfs(wf).dt = 1/sar_data.wfs(wf).fs;
      sar_data.wfs(wf).Nt = sar_data.wfs(wf).Nt * param.array.ft_over_sample;
      sar_data.wfs(wf).df = sar_data.wfs(wf).fs / sar_data.wfs(wf).Nt;
      sar_data.wfs(wf).time = sar_data.wfs(wf).time(1) + sar_data.wfs(wf).dt*(0:sar_data.wfs(wf).Nt-1).';
      sar_data.wfs(wf).freq = sar_data.wfs(wf).fc ...
        + sar_data.wfs(wf).df * ifftshift( -floor(sar_data.wfs(wf).Nt/2) : floor((sar_data.wfs(wf).Nt-1)/2) ).';
    end
    Time = sar_data.wfs(wf_base).time;
  end
  
  param.array_proc.chan_equal = chan_equal;
  param.array_proc.fcs = fcs;
 
  %% Process: WBDCM Setup
  % =======================================================================
  % Setup fields for wideband space-time doa estimator passed to
  % array_proc.  This section does the following:
  % 1). Computes the impulse response used to model the amplitude term of
  % the space time correlation matrix,
  if strcmpi(param.array.method,'wbdcm')
    % -------------------------------------------------------------------
    % Compute maximum propagation delay across the array (this is used to
    % compute impulse response needed for covariance model (see below))
    
    lever_arm_param.season_name = param.season_name;
    lever_arm_param.radar_name = ct_output_dir(param.radar_name);
    lever_arm_param.gps_source = sar_data.param_records.gps_source;
    % Iterate through all wf-adc pairs and create a list of phase centers
    % that are being used to create this image.
    phase_centers = [];
    for ml_idx = 1:length(ml_list)
      wf_adc_list = ml_list{ml_idx};
      for wf_adc = 1:size(wf_adc_list,1)
        wf = wf_adc_list(wf_adc,1);
        adc = wf_adc_list(wf_adc,2);
        % Add phase center for the wf-adc pair to the list
        phase_centers(:,end+1) = lever_arm(lever_arm_param, ...
          param.radar.wfs(wf).tx_weights, param.radar.wfs(wf).rx_paths(adc));
      end
    end
    % Find the two phase centers separated by the maximum distance
    pc_dist = zeros(size(phase_centers,2));
    for pc_idx = 1:size(phase_centers,2)
      for pc_comp_idx = pc_idx+1:size(phase_centers,2)
        pc_dist(pc_idx,pc_comp_idx) ...
          = sqrt(sum(abs(phase_centers(:,pc_idx) - phase_centers(:,pc_comp_idx)).^2));
      end
    end
    max_array_dim = max(max(pc_dist));
    % Convert maximum distance to propagation time in free space
    tau_max = 2*max_array_dim/c;
    
    % Check the value for W from param.array.W (widening factor)
    W_ideal = 1 + ceil(tau_max / sar_data.wfs(wf).dt);
    if param.array.W ~= W_ideal
      warning('param.array.W is %d, but should be %d', param.array.W, W_ideal);
    end
    
    % Compute impulse response
    % -------------------------------------------------------------------
    % NOTE:  The impulse response is computed based on the fast time
    % window used in CSARP.  This could be generalized for a measured
    % impulse response vector but this is not yet supported.
    
    Mt = 10; % Over-sampling factor
    % Create frequency-domain fast-time window identical to what was
    % used for pulse compression
    Hwin = sar_data.param_sar.csarp.ft_wind(length(sar_data.wfs(wf).time));
    % Convert to time-domain and over-sample by Mt
    %  - Take real to remove rounding errors that result in imag part
    Hwin = interpft_memeff(real(ifft(ifftshift(Hwin).^2)), Mt*length(Hwin));
    % Store the impulse response and corresponding time axis for
    % passing to array_proc
    %  - Ensure we grab enough samples of the impulse response so that
    %    array_proc is always happy.
    Hwin_num_samp = 2 * Mt * (W_ideal + param.array.W);
    param.array_proc.imp_resp.vals ...
      = fftshift(Hwin([1:1+Hwin_num_samp, end-Hwin_num_samp+1:end]));
    param.array_proc.imp_resp.time_vec ...
      = sar_data.wfs(wf).dt/Mt * (-Hwin_num_samp:Hwin_num_samp);
  end
  
  %% Process: Array Processing
  % =======================================================================
  if strcmpi(param.array.method,'combine_rx')
    % sar.m already combined channels, just incoherently average
    % ---------------------------------------------------------------------
    
    % Number of fast-time range bins
    Nt = size(data{1},1);
    % Number of along-track range lines
    Nx = size(data{1},2);
    
    % Ensure that range bins are still multiples of dt after decimation
    param.array_proc.bins = 1-param.array.bin_rng(1)+mod(Time(1-param.array.bin_rng(1))/dt,param.array.dbin) : param.array.dbin : Nt-param.array.bin_rng(end);
    param.array_proc.lines = 1-param.array.line_rng(1) : param.array.dline : Nx-param.array.line_rng(end);
    
    % Process: Update surface values
    if isempty(surf_layer.gps_time)
      param.array_proc.surface = zeros(size(param.array_proc.lines));
    elseif length(surf_layer.gps_time) == 1;
      param.array_proc.surface = surf_layer.twtt*ones(size(param.array_proc.lines));
    else
      
      if strcmpi(param.array.surf_layer.source, 'surf_sar')
        % If surf_layer source is surfData (twtt from DEM), just grab values
        % for the chunk
        surf_index = surf_layer.get_index({'top twtt'});
        icemask_index = surf_layer.get_index({'ice_mask'});
        theta_frm     = repmat(surf_layer.x(:,1),1,numel(surf_layer.gps_time));
        gps_frm       = repmat(surf_layer.gps_time,numel(surf_layer.theta),1);
        theta_chunk   = repmat(surf_layer.x(:,1),1,numel(fcs{1}{1}.gps_time));
        gps_chunk     = repmat(fcs{1}{1}.gps_time,numel(surf_layer.theta),1);
        param.array_proc.surface = interp_finite(interp2(gps_frm, theta_frm,surf_layer.surf(surf_index).y,gps_chunk,theta_chunk));
        param.array_proc.ice_mask = ...
          interp_finite(interp2(gps_frm,theta_frm,surf_layer.surf(icemask_index).y,gps_chunk,theta_chunk,'nearest'));
        param.array_proc.surface_theta = surf_layer.theta;
      else
        % source = 'layerData'
        param.array_proc.surface = interp_finite(interp1(surf_layer.gps_time, ...
          surf_layer.twtt,fcs{1}{1}.gps_time(param.array_proc.lines)),0);
      end
    end
    
    % Perform incoherent averaging
    Hfilter2 = ones(length(param.array.bin_rng),length(param.array.line_rng));
    Hfilter2 = Hfilter2 / numel(Hfilter2);
    dout.img = filter2(Hfilter2, abs(data{1}).^2);
    
    dout.img = dout.img(param.array_proc.bins,param.array_proc.lines);
    
  else
    % Regular array processing operation
    % ---------------------------------------------------------------------
    
    % Load bin restriction layers if specified
    if ~isempty(param.array.bin_restriction)
      ops_param = param;
      % Invalid frames will be ignored by opsLoadLayers so we can ignore edge cases
      ops_param.cmd.frms = param.load.frm + (-1:1);
      bin_restriction_layers = opsLoadLayers(ops_param, param.array.bin_restriction);
      % Interpolate layers onto GPS time of loaded data
      param.array_proc.bin_restriction.start_bin = interp1(bin_restriction_layers(1).gps_time, ...
        bin_restriction_layers(1).twtt, sar_data.fcs.gps_time);
      % Convert from two way travel time to range bins
      param.array_proc.bin_restriction.start_bin = interp1(sar_data.wfs(wf).time, ...
        1:length(sar_data.wfs(wf).time), param.array_proc.bin_restriction.start_bin);
      % Ensure there is a value everywhere
      param.array_proc.bin_restriction.start_bin = interp_finite(param.array.bin_restriction.start_bin);
      
      % Interpolate layers onto GPS time of loaded data
      param.array_proc.bin_restriction.stop_bin = interp1(bin_restriction_layers(1).gps_time, ...
        bin_restriction_layers(1).twtt, sar_data.fcs.gps_time);
      % Convert from two way travel time to range bins
      param.array_proc.bin_restriction.stop_bin = interp1(sar_data.wfs(wf).time, ...
        1:length(sar_data.wfs(wf).time), param.array_proc.bin_restriction.stop_bin);
      % Ensure there is a value everywhere
      param.array_proc.bin_restriction.stop_bin = interp_finite(param.array.bin_restriction.stop_bin);
    else
      param.array_proc.bin_restriction = [];
    end
    
    if ~isempty(param.array.doa_constraints)
      % If DOA constraints are specified, they must be specified for
      % every source. For no constraints, choose 'fixed' method and
      % [-90 90] for init_src_limits and src_limits.
      for src_idx = 1:param.array.Nsrc
        % Load layers for each DOA constraint that needs it
        doa_res = param.array.doa_constraints(src_idx);
        switch (doa_res.method)
          case {'layerleft','layerright'}
            ops_param = param;
            % Invalid frames will be ignored by opsLoadLayers so we can ignore edge cases
            ops_param.cmd.frms = param.load.frm + (-1:1);
            param.array_proc.doa_constraints(src_idx).layer = opsLoadLayers(ops_param, doa_res.params);
            % Interpolate layers onto GPS time of loaded data
            param.array_proc.doa_constraints(src_idx).layer.twtt = interp1(param.array.doa_constraints(src_idx).layer.gps_time, ...
              param.array.doa_constraints(src_idx).layer.twtt, sar_data.fcs.gps_time);
            % Ensure there is a value everywhere
            param.array_proc.doa_constraints(src_idx).layer.twtt = interp_finite(param.array.doa_constraints(src_idx).layer.twtt);
        end
      end
    end
    
    param.array_proc.wfs = sar_data.wfs(wf);
    param.array_proc.imgs = param.array.imgs{img};
    if ~iscell(param.array_proc.imgs)
      param.array_proc.imgs = {param.array_proc.imgs};
    end
    
    % Determine output range lines so that chunks will be seamless (this is
    % necessary because the output is decimated and the decimation may not
    % align with chunk lengths)
    first_rline = find(~mod(sar_out_rlines-1,param.array.dline),1);
    rlines = num_prev_chunk_rlines + (first_rline : param.array.dline : length(sar_out_rlines));
    param.array_proc.lines = rlines([1 end]);
    
    % Pass in time bin offset so that array_proc can ensure output time
    % bins are multiples of the final dt after dbin decimation
    param.array_proc.bin0 = Time(1)/dt;
    
    % Process: Update surface values
    if isempty(surf_layer.gps_time)
      % Handle special case 1: gps time is empty > surface twtt all zeros
      param.array_proc.surface = zeros(size(rlines));
    elseif length(surf_layer.gps_time) == 1;
      % Handle special case 2: gps time is length 1, repeat twtt over rlines
      param.array_proc.surface = surf_layer.twtt*ones(size(rlines));
    elseif strcmpi(param.array.surf_layer.source,'surf_sar')
      % If surf_layer source is surfData (twtt from DEM), just grab values
      % for the chunk
      surf_index = surf_layer.get_index({'top twtt'});
      icemask_index = surf_layer.get_index({'ice mask'});
      param.array_proc.surface_theta = surf_layer.surf(surf_index).x(:,1);
      theta_frm     = repmat(param.array_proc.surface_theta,1,numel(surf_layer.gps_time));
      gps_frm       = repmat(surf_layer.gps_time,length(param.array_proc.surface_theta),1);
      theta_chunk   = repmat(param.array_proc.surface_theta,1,numel(fcs{1}{1}.gps_time));
      gps_chunk     = repmat(fcs{1}{1}.gps_time,length(param.array_proc.surface_theta),1);
      param.array_proc.surface = interp_finite(interp2(gps_frm, theta_frm,surf_layer.surf(surf_index).y,gps_chunk,theta_chunk),nan);
      param.array_proc.ice_mask = ...
        interp_finite(interp2(gps_frm,theta_frm,surf_layer.surf(icemask_index).y,gps_chunk,theta_chunk,'nearest'),nan);
    else
      % Path for layer
      param.array_proc.surface = interp_finite(interp1(surf_layer.gps_time, ...
        surf_layer.twtt,fcs{1}{1}.gps_time(rlines)),0);
      param.array_proc.surface_theta = 0;
    end
    
    %     end
    
    % Load Look Up Table
    if strcmpi(param.array.sv_model,'lookup_table')
      % To be updated.  Currently LUT is stored by day_seg.  Intent is to have
      % one LUT for the season in the analysis folder.  Once estimate_sv_lut
      % has been updated, delete first conditional and only use the statement
      % after the else below.
      
      % lut_fn is either passed in as a fullfile by the user or built from
      % the default paths in the input checking of array proc.  
      % If the user doesn't specify the fullfile, they must specify 
      % at a minimum the following:
      % param.array.lut_type: choices are either 'training' or 'process'
      % param.array.lut_dayseg:  if user specifies the process lut type,
      %                           lut_dayseg can be blank.
      % param.array.lut_path: defaults to the CSARP_array_manifold folder
      % param.array.sv_model: 'lookup_table'
      % param.array.lut_method: choices are 'evd' for principal
      % eigenvector, 'mmse' for a weiner filter type, and 'ave' for
      % coherent averaged steering vector.
      lut_fn = param.array.lut_fn;
      
      load(lut_fn,'sv','doa','param_array_manifold');
      
      if isfield(param.array,'lut_method') & ~isempty(param.array.lut_method)
        if length(sv) > 1
          sv_idx = find(strcmpi({sv.method},param.array.lut_method)==true);
          sv = sv(sv_idx).manifold;
        end
      end
      
      % Check dimensionality
      Nsv = length(doa);
      N1 = size(sv,1);
      if N1 < Nsv
        sv = transpose(sv);
      end
      
      lut_sv = nan(length(doa),size(param.array.imgs{img}{1}(:,1),1));
      
      wf = param.array.imgs{img}{1}(1,1);
      for wf_adc = 1:size(param.array.imgs{img}{1}(:,1),1)
        wf = param.array.imgs{img}{1}(wf_adc,1);
        adc = param.array.imgs{img}{1}(wf_adc,2);
        rx = param.radar.wfs(wf).rx_paths(adc);
        rx_lut_index = find(param_array_manifold.rx_list == rx);
        if ~isempty(rx_lut_index)
          lut_sv(:,wf_adc) = sv(:,rx_lut_index);
        end
      end
      param.array_proc.lut.sv = lut_sv;
      param.array_proc.lut.doa = doa;
      clear sv doa
      
%       if strcmpi(param.array.lut_type,'process')
%         lut_dir = ct_fileparts(ct_filename_out(param,param.array.lut_path));
%       
%       % Does not support subband luts
%       if regexp(param.array.sv_lut_path,'analysis')
%         lut_fn = fullfile(ct_filename_out(param,param.array.sv_lut_path,[],1),'lut.mat');
%       elseif isfield(param.array, 'lut_day_seg') && ~isempty(param.array.lut_day_seg)
%         lut_dir = fullfile(ct_filename_out(param,param.array.sv_lut_path,[],1),param.array.lut_day_seg);
%         lut_fn = fullfile(lut_dir, sprintf('lut_%s.mat',param.array.lut_day_seg));
%       else
%         lut_dir = ct_filename_out(param,param.array.sv_lut_path);
%         lut_fn = fullfile(lut_dir, sprintf('lut_%s.mat',param.day_seg));
%       end
      %       if strcmpi(param.array.sv_lut_path,'estimate_sv_lut')
      %         lut_dir = ct_filename_out(param,param.array.sv_lut_path);
      %         lut_fn = fullfile(lut_dir, sprintf('lut_%s.mat',param.day_seg));
      %       else
      %         lut_fn = fullfile(ct_filename_out(param,param.array.sv_lut_path,[],1),'lut.mat');
      %       end
 
    else
      param.array_proc.lut = [];
    end
    % Array Processing Function Call
    [param,dout] = array_proc(param,data);
  end
  
  %% Process: Debugging
  % =======================================================================
  if 0
    figure(1); clf;
    %imagesc(incfilt(mean(data{1},3),10,4));
    imagesc(10*log10(local_detrend(abs(mean(data{1},3)).^2,[40 100],[10 4],3)));
    title(sprintf('Waveform %d: Boxcar window', wf));
    colorbar
    grid on;
    figure(2); clf;
    %imagesc(10*log10(dout.img));
    imagesc(10*log10(local_detrend(dout.img,[20 50],[5 2],3)));
    title(sprintf('Waveform %d: Tomography', wf));
    colorbar
    grid on;
    keyboard
  end
  
  %% Process: Save results
  % =======================================================================
  array_fn = fullfile(array_tmp_dir, sprintf('img_%02d_chk_%03d.mat', img, param.load.chunk_idx));
  fprintf('  Saving array data %s (%s)\n', array_fn, datestr(now));
  array_tmp_dir = fileparts(array_fn);
  if ~exist(array_tmp_dir,'dir')
    mkdir(array_tmp_dir);
  end
  
  Latitude = lat(1,param.array_proc.lines);
  Longitude = lon(1,param.array_proc.lines);
  Elevation = elev(1,param.array_proc.lines);
  GPS_time = fcs{1}{1}.gps_time(param.array_proc.lines);
  Surface = param.array_proc.surface;
  Bottom = fcs{1}{1}.bottom(param.array_proc.lines);
  Roll = fcs{1}{1}.roll(param.array_proc.lines);
  Pitch = fcs{1}{1}.pitch(param.array_proc.lines);
  Heading = fcs{1}{1}.heading(param.array_proc.lines);
  Data = dout.img;
  Time = Time(param.array_proc.bins);
  param_array = param;
  if param.ct_file_lock
    file_version = '1L';
  else
    file_version = '1';
  end
  file_type = 'array_tmp';
  if ~param.array.tomo_en
    % Do not save tomographic 3D-image
    ct_save('-v7.3',array_fn,'Data','Latitude','Longitude','Elevation','GPS_time', ...
      'Surface','Bottom','Time','param_array','param_records', ...
      'param_sar', 'Roll', 'Pitch', 'Heading', 'file_type', 'file_version');
  else
    % Save tomographic 3D-image
    Tomo = dout.tomo;
    ct_save('-v7.3',array_fn,'Tomo','Data','Latitude','Longitude','Elevation','GPS_time', ...
      'Surface','Bottom','Time','param_array','param_records', ...
      'param_sar', 'Roll', 'Pitch', 'Heading', 'file_type', 'file_version');
  end
  
end

fprintf('%s done %s\n', mfilename, datestr(now));

success = true;
