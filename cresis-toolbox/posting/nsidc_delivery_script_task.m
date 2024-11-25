function [success] = nsidc_delivery_script_task(param)
% [success] = nsidc_delivery_script_task(param)
%
% Support function for nsidc_delivery_script
%
% Author: Yi Zhu, John Paden

USER_SPECIFIED_DIRECTORY_BASE = param.nsidc.USER_SPECIFIED_DIRECTORY_BASE;
L1B_cmd = param.nsidc.L1B_cmd;
data_dir_L1 = param.nsidc.data_dir_L1;
data_dir_L1_extra = param.nsidc.data_dir_L1_extra;
image_extra = param.nsidc.image_extra;
L1B_supplement_cmd = param.nsidc.L1B_supplement_cmd;
L1B_supplement_name = param.nsidc.L1B_supplement_name;
L1B_supplement_name_extra = param.nsidc.L1B_supplement_name_extra;
L2_cmd = param.nsidc.L2_cmd;
data_dir_L2 = param.nsidc.data_dir_L2;
premet_param_L1B = param.nsidc.premet_param_L1B;
premet_param_L2 = param.nsidc.premet_param_L2;
mcf_version_id_L1B = param.nsidc.mcf_version_id_L1B;
mcf_version_id_L2 = param.nsidc.mcf_version_id_L2;
frm_types = param.nsidc.frm_types;

netcdf_param = param.nsidc.netcdf_param;
supplement_netcdf_param = param.nsidc.supplement_netcdf_param;

%% Load the frames information
frames_fn = ct_filename_support(param,'','frames');
frames = frames_load(frames_fn);
if isempty(param.cmd.frms)
  param.cmd.frms = 1:length(frames.frame_idxs);
end

fprintf('NSIDC prep %s\n', param.day_seg);

USER_SPECIFIED_DIRECTORY = fullfile(USER_SPECIFIED_DIRECTORY_BASE, ...
  param.season_name,ct_output_dir(param.radar_name));
if ~exist(USER_SPECIFIED_DIRECTORY,'dir')
  mkdir(USER_SPECIFIED_DIRECTORY);
end

%% Extract year(2013), location(GR) and platform(P3) information from
% season name in param
[season_name_year location] = strtok(param.season_name,'_');
[location platform] = strtok(location,'_');
platform = platform(2:end);

if strcmpi(location,'Greenland')
  location = 'GR';
elseif strcmpi(location,'Antarctica')
  location = 'AN';
elseif strcmpi(location,'Alaska')
  location = 'AL';
else
  error('Unsupported location %s\n', location);
end

%% Build the premet_param structure
premet_param = [];

% Construct the necessary element: AircraftID and platform_short_name
if strcmpi(platform,'P3')
    if strcmpi(season_name_year,'2016')
        premet_param.nsidc_platform_short_name = 'WP-3D ORION';        
        premet_param.nsidc_aircraft_id = 'N43RF';
    else
        premet_param.nsidc_platform_short_name = 'P-3B';        % change to meet the valids file
        premet_param.nsidc_aircraft_id = 'N426NA';
    end
elseif strcmpi(platform,'DC8')
  premet_param.nsidc_platform_short_name = 'DC-8';
  premet_param.nsidc_aircraft_id = 'N817NA';
elseif strcmpi(platform,'C130')
  premet_param.nsidc_platform_short_name = 'C-130';
  premet_param.nsidc_aircraft_id = 'N439NA';
elseif strcmpi(platform,'Basler')
  premet_param.nsidc_platform_short_name = 'BT-67';
  premet_param.nsidc_aircraft_id = 'N167BT';
elseif strcmpi(platform,'SO')
  premet_param.nsidc_platform_short_name = 'DHC-3';
  premet_param.nsidc_aircraft_id = 'N226UT';
elseif strcmpi(platform,'GV')
  premet_param.nsidc_platform_short_name = 'G-V';
  premet_param.nsidc_aircraft_id = 'N95NA';
else
  error('Unsupported platform %s\n', platform);
end

% Construct the necessary element: ThemeID
premet_param.nsidc_season_name = sprintf('%s_%s_NASA', season_name_year, location);
data_files_dir = sprintf('Data_%s_%s', season_name_year, location);
% Construct the necessary element: instrument_short_name and sensor_short_name
radar_sensor = ct_output_dir(param.radar_name);
if strcmpi(radar_sensor,'accum')
  premet_param.nsidc_instrument_short_name = 'Accumulation Radar';
  premet_param.nsidc_sensor_short_name = 'Accumulation Radar';
  radar_type = 'IRACC';
elseif strcmpi(radar_sensor,'kuband')
  premet_param.nsidc_instrument_short_name = 'Ku-Band Radar';
  premet_param.nsidc_sensor_short_name = 'Ku-Band Radar';
  radar_type = 'IRKUB';
elseif strcmpi(radar_sensor,'rds')
  premet_param.nsidc_instrument_short_name = 'MCoRDS';
  premet_param.nsidc_sensor_short_name = 'MCoRDS';
  radar_type = 'IRMCR';
elseif strcmpi(radar_sensor,'snow')
  premet_param.nsidc_instrument_short_name = 'Snow Radar';
  premet_param.nsidc_sensor_short_name = 'Snow Radar';
  radar_type = 'IRSNO';
else
  error('Unsupported sensor %s\n', radar_sensor);
end

%% For L2 data
if L2_cmd
  
  data_type = '2';
  
  % Input L2 .csv file (The path here should be self-defined)
  csv_fn = fullfile(ct_filename_out(param,'',data_dir_L2,2), ...
    sprintf('Data_%s.csv',param.day_seg));
  
  % Output filename for .premet, e.g. IRMCRL2_20130402_01.csv.premet
  out_fn_premet_L2 = fullfile(ct_filename_out(param,USER_SPECIFIED_DIRECTORY,'',1), ...
    sprintf('%s%s_Files', radar_type, data_type),'Spatial_Premet_Files', ...
    sprintf('%s%s_%s.csv.premet',radar_type,data_type,param.day_seg));
  pre_spatial_dir = fullfile(ct_filename_out(param,USER_SPECIFIED_DIRECTORY,'',1), ...
    sprintf('%s%s_Files', radar_type, data_type),'Spatial_Premet_Files');
  if ~exist(pre_spatial_dir,'dir')
    mkdir(pre_spatial_dir);
  end
  
  % Output filename for .spatial, e.g. IRMCRL2_20130402_01.csv.spatial
  out_fn_spatial_L2 = fullfile(ct_filename_out(param,USER_SPECIFIED_DIRECTORY,'',1), ...
    sprintf('%s%s_Files', radar_type, data_type),'Spatial_Premet_Files', ...
    sprintf('%s%s_%s.csv.spatial',radar_type,data_type,param.day_seg));
  
  % Output txt/csv directory
  data_txt_dir = fullfile(ct_filename_out(param,USER_SPECIFIED_DIRECTORY,'',1), ...
    sprintf('%s%s_Files', radar_type, data_type),data_files_dir);
  if ~exist(data_txt_dir,'dir')
    mkdir(data_txt_dir);
  end
  
  % Create output pdr and met files directories
  out_pdr_dir = fullfile(ct_filename_out(param,USER_SPECIFIED_DIRECTORY,'',1), ...
    sprintf('%s%s_Files', radar_type, data_type),'output','pdrs');
  if ~exist(out_pdr_dir,'dir')
    mkdir(out_pdr_dir);
  end
  out_met_dir = fullfile(ct_filename_out(param,USER_SPECIFIED_DIRECTORY,'',1), ...
    sprintf('%s%s_Files', radar_type, data_type),'output','mets');
  if ~exist(out_met_dir,'dir')
    mkdir(out_met_dir);
  end
  
  new_csv_fn = fullfile(data_txt_dir, ...
    sprintf('%s%s_%s.csv',radar_type,data_type,param.day_seg));
  
  fprintf('  Original csv: %s\n', csv_fn);
  fprintf('  premet: %s\n', out_fn_premet_L2);
  fprintf('  spatial: %s\n', out_fn_spatial_L2);
  fprintf('  New csv %s\n', new_csv_fn);
  
  if ~exist(csv_fn)
    warning('Skipping: csv file %s is missing\n',csv_fn);
    
  else
    % Copy csv file
    [flag,message,~] = copyfile(csv_fn,new_csv_fn);
    
    % Create the data filename without extension
    premet_param.data_fn_name = sprintf('%s_%s', ...
      sprintf('%s%s', radar_type, data_type), param.day_seg);
    
    % Create .premet, .spatial and .txt file for L2 data
    premet_param_merged = merge_structs(premet_param, premet_param_L2);
    nsidc_create_premet_L2(csv_fn,out_fn_premet_L2,premet_param_merged);
    nsidc_create_spatial_L2(csv_fn,out_fn_spatial_L2);
    
    % Create MetGen config file (this actually only needs to be run once for the whole season)
    nsidc_change_metgen(USER_SPECIFIED_DIRECTORY, mcf_version_id_L2, ...
      pre_spatial_dir, data_txt_dir, radar_type, data_type);
  end
  
end

%% For L1B data
if L1B_cmd
  
  data_type = '1B';
  
  % Find the records information for updating global attributes
  records = records_load(param);
  
  % Remove frames that do not exist from param.cmd.frms list
  [valid_frms,keep_idxs] = intersect(param.cmd.frms, 1:length(frames.frame_idxs));
  if length(valid_frms) ~= length(param.cmd.frms)
    bad_mask = ones(size(param.cmd.frms));
    bad_mask(keep_idxs) = 0;
    warning('Nonexistent frames specified in param.cmd.frms (e.g. frame "%g" is invalid), removing these', ...
      param.cmd.frms(find(bad_mask,1)));
    param.cmd.frms = valid_frms;
  end
  
  % Create premet, spatial, netcdf files for each frame
  param.records = records;
  for frm_idx = 1:length(param.cmd.frms)
    frm = param.cmd.frms(frm_idx);
    
    if ~ct_proc_frame(frames.proc_mode(frm),frm_types)
      continue;
    end
    
    fprintf('  Converting frame %d (%d of %d) (%s)\n', frm, frm_idx, ...
      length(param.cmd.frms), datestr(now,'HH:MM:SS'));
    
    % Input L1B .mat file (The path here should be self-defined)
    echo_fn = fullfile(ct_filename_out(param,data_dir_L1), ...
      sprintf('Data_%s_%03d.mat',param.day_seg,frm));
    
    % Output filename for .premet, e.g. IRMCR1B_V01_20130402_01_001.premet
    out_fn_premet_L1B = fullfile(ct_filename_out(param,USER_SPECIFIED_DIRECTORY,'',1), ...
      sprintf('%s%s_Files', radar_type, data_type),'Spatial_Premet_Files', ...
      sprintf('%s%s_%s_%03d.premet',radar_type, data_type, param.day_seg, frm));
    pre_spatial_dir = fileparts(out_fn_premet_L1B);
    if ~exist(pre_spatial_dir,'dir')
      mkdir(pre_spatial_dir);
    end
    
    % Output filename for .spatial, e.g. IRMCR1B_V01_20130402_01_001.spatial
    out_fn_spatial_L1B = fullfile(ct_filename_out(param,USER_SPECIFIED_DIRECTORY,'',1), ...
      sprintf('%s%s_Files', radar_type, data_type),'Spatial_Premet_Files', ...
      sprintf('%s%s_%s_%03d.spatial',radar_type, data_type, param.day_seg, frm));
    
    % Output filename for .nc, e.g. IRMCR1B_V01_20130402_01_001.nc
    out_fn_netcdf = fullfile(ct_filename_out(param,USER_SPECIFIED_DIRECTORY,'',1), ...
      sprintf('%s%s_Files', radar_type, data_type),data_files_dir, ...
      sprintf('%s%s_%s_%03d.nc',radar_type, data_type, param.day_seg, frm));
    out_data_dir = fileparts(out_fn_netcdf);
    if ~exist(out_data_dir,'dir')
      mkdir(out_data_dir);
    end
    
    % Create output pdr and met files directories
    out_pdr_dir = fullfile(ct_filename_out(param,USER_SPECIFIED_DIRECTORY,'',1), ...
      sprintf('%s%s_Files', radar_type, data_type),'output','pdrs');
    if ~exist(out_pdr_dir,'dir')
      mkdir(out_pdr_dir);
    end
    out_met_dir = fullfile(ct_filename_out(param,USER_SPECIFIED_DIRECTORY,'',1), ...
      sprintf('%s%s_Files', radar_type, data_type),'output','mets');
    if ~exist(out_met_dir,'dir')
      mkdir(out_met_dir);
    end
    
    % Create Maps, Echogram and Picked Echogram image filenames
    map_fn = fullfile(ct_filename_out(param,'post','',1),'images', ...
      param.day_seg, sprintf('%s_%03d_0maps.jpg',param.day_seg,frm));
    new_map_fn = fullfile(out_data_dir, ...
      sprintf('%s%s_%s_%03d_%s.jpg',radar_type,data_type,param.day_seg,frm,'Map'));
    
    echogram_fn = fullfile(ct_filename_out(param,'post','',1),'images', ...
      param.day_seg, sprintf('%s_%03d_1echo.jpg',param.day_seg,frm));
    new_echogram_fn = fullfile(out_data_dir, ...
      sprintf('%s%s_%s_%03d_%s.jpg',radar_type,data_type,param.day_seg,frm,'Echogram'));
    
    echogram_picks_fn = fullfile(ct_filename_out(param,'post','',1),'images', ...
      param.day_seg, sprintf('%s_%03d_2echo_picks.jpg',param.day_seg,frm));
    new_echogram_picks_fn = fullfile(out_data_dir, ...
      sprintf('%s%s_%s_%03d_%s.jpg',radar_type,data_type,param.day_seg,frm,'Echogram_Picks'));
  
   
    % Check for the existence of image files
    if ~exist(map_fn,'file')
      warning('Skipping: missing map file %s', map_fn);
      keyboard;
      continue;
    end
    if ~exist(echogram_fn,'file')
      warning('Skipping: missing echogram file %s', echogram_fn);
      keyboard;
      continue;
    end
    if strcmpi(radar_type,'IRMCR')
      if ~exist(echogram_picks_fn,'file')
        warning('Skipping: missing pick file %s', echogram_fn);
        keyboard;
        continue;
      end
    end
    
    fprintf('   input mat: %s\n', echo_fn);
    fprintf('   premet: %s\n', out_fn_premet_L1B);
    fprintf('   spatial: %s\n', out_fn_spatial_L1B);
    fprintf('   nc: %s\n', out_fn_netcdf);
    fprintf('   NetCDF and images are copying to %s\n', out_data_dir);
    
    % Copy image files
    [flag,message,~] = copyfile(map_fn,new_map_fn);
    [flag,message,~] = copyfile(echogram_fn,new_echogram_fn);
    if strcmpi(radar_type,'IRMCR')
      [flag,message,~] = copyfile(echogram_picks_fn,new_echogram_picks_fn);
    end
    
    % create extra image filenames
    for extra_idx = 1:size(image_extra,2)
        echogram_fn = fullfile(ct_filename_out(param,'post','',1),'images', ...
            param.day_seg, sprintf('%s_%03d_1echo_%s.jpg',param.day_seg,frm,image_extra{extra_idx}));
        new_echogram_fn = fullfile(out_data_dir, ...
            sprintf('%s%s_%s_%03d_%s_%s.jpg',radar_type,data_type,param.day_seg,frm,image_extra{extra_idx},'Echogram'));
        [flag,message,~] = copyfile(echogram_fn,new_echogram_fn);
    end
   
    % Create .premet, .spatial files for L1B data
    premet_param_merged = merge_structs(premet_param, premet_param_L1B);
    nsidc_create_premet_L1B(echo_fn,out_fn_premet_L1B,premet_param_merged);
    nsidc_create_spatial_L1B(echo_fn, out_fn_spatial_L1B);
    
    %% Create primary .nc echogram files
    mdata = load(echo_fn);
    if isfield(mdata,'Truncate_Bins')
      % Special modification for compressed echograms
      mdata.Time = mdata.Time(mdata.Truncate_Bins);
    end
    
    % Netcdf time is seconds of day, so we need to indicate which day it
    % is taken relative to
    netcdf_param(1).attributes{2} = sprintf('seconds since %s-%s-%s 00:00:00', ...
      param.day_seg(1:4), param.day_seg(5:6), param.day_seg(7:8));
    netcdf_param(find(strcmp('GPS_time',{netcdf_param.mat_name}))).eval = @(x) (epoch_to_sod(x - utc_leap_seconds(x(1)),param.day_seg));
    netcdf_from_mat(out_fn_netcdf,mdata,netcdf_param);
    
    % Add global attributes
    nsidc_netcdf_attributes(out_fn_netcdf,echo_fn,param);
    
    %% Create additional .nc echogram files
    for extra_idx = 1:size(data_dir_L1_extra,1)
      echo_fn = fullfile(ct_filename_out(param,data_dir_L1_extra{extra_idx,1}), ...
        sprintf('Data_%s_%03d.mat',param.day_seg,frm));
      out_fn_netcdf = fullfile(ct_filename_out(param,USER_SPECIFIED_DIRECTORY,'',1), ...
        sprintf('%s%s_Files', radar_type, data_type),data_files_dir, ...
        sprintf('%s%s_%s_%03d_%s.nc',radar_type, data_type, param.day_seg, frm, data_dir_L1_extra{extra_idx,2}));
      
      if exist(echo_fn)
        fprintf('   extra mat: %s\n', echo_fn);
        fprintf('   extra nc: %s\n', out_fn_netcdf);
        
        mdata = load(echo_fn);
        if isfield(mdata,'Truncate_Bins')
          % Special modification for compressed echograms
          mdata.Time = mdata.Time(mdata.Truncate_Bins);
        end
        
        % Netcdf time is seconds of day, so we need to indicate which day it
        % is taken relative to
        netcdf_param(1).attributes{2} = sprintf('seconds since %s-%s-%s 00:00:00', ...
          param.day_seg(1:4), param.day_seg(5:6), param.day_seg(7:8));
        netcdf_param(find(strcmp('GPS_time',{netcdf_param.mat_name}))).eval = @(x) (epoch_to_sod(x - utc_leap_seconds(x(1)),param.day_seg));
        netcdf_from_mat(out_fn_netcdf,mdata,netcdf_param);
        
        % Add global attributes
        nsidc_netcdf_attributes(out_fn_netcdf,echo_fn,param);
      end
    end
    
    %% Create MetGen config file (this actually only needs to be run once for the whole season)
    nsidc_change_metgen(USER_SPECIFIED_DIRECTORY, mcf_version_id_L1B, pre_spatial_dir, out_data_dir, radar_type, data_type);
    
  end
end

if L1B_supplement_cmd
  %% Create .nc supplement files
  
  for frm_idx = 1:length(param.cmd.frms)
    frm = param.cmd.frms(frm_idx);
    
    if ~ct_proc_frame(frames.proc_mode(frm),frm_types)
      continue;
    end
    
    if ~isfield(frames,'quality') && ~isfield(frames,'quality_snow') && ~isfield(frames,'quality_kuband')  && ~isfield(frames,'quality_uwb')
      continue;
    end
    
    fprintf('  Supplemental file frame %d (%d of %d) (%s)\n', frm, frm_idx, ...
      length(param.cmd.frms), datestr(now,'HH:MM:SS'));
    
    % Output filename for .nc, e.g. IRMCR1B_V01_20130402_01_001_supplement.nc
    out_fn_netcdf = fullfile(ct_filename_out(param,USER_SPECIFIED_DIRECTORY,'',1), ...
      sprintf('%s%s_Files', radar_type, data_type),data_files_dir, ...
      sprintf('%s%s_%s_%03d_%s.nc',radar_type, data_type, param.day_seg, frm, L1B_supplement_name));
    out_data_dir = fileparts(out_fn_netcdf);
    if ~exist(out_data_dir,'dir')
      mkdir(out_data_dir);
    end
    if strcmpi(param.radar_name,'snow8')
        frames.quality = frames.quality_snow;
    end     
    supplement = [];
    supplement.coh_noise_removal_artifact = uint8(mod(floor(frames.quality(frm)/2^0),2));
    supplement.deconvolution_artifact = uint8(mod(floor(frames.quality(frm)/2^1),2));
    supplement.vertical_stripes_artifact = uint8(mod(floor(frames.quality(frm)/2^2),2));
    supplement.missing_data = uint8(mod(floor(frames.quality(frm)/2^3),2));
    supplement.no_good_data = uint8(mod(floor(frames.quality(frm)/2^4),2));
    supplement.low_SNR = uint8(mod(floor(frames.quality(frm)/2^5),2));
    supplement.unclassified_artifact = uint8(mod(floor(frames.quality(frm)/2^6),2));
    supplement.land_ice = uint8(mod(floor(frames.quality(frm)/2^7),2));
    
    fprintf('   nc: %s\n', out_fn_netcdf);
    
    netcdf_from_mat(out_fn_netcdf,supplement,supplement_netcdf_param);
    if exist('L1B_supplement_name_extra','var') || ~isempty(L1B_supplement_name_extra)
        for extra_idx = 1:size(L1B_supplement_name_extra,2)
            out_fn_netcdf = fullfile(ct_filename_out(param,USER_SPECIFIED_DIRECTORY,'',1), ...
                sprintf('%s%s_Files', radar_type, data_type),data_files_dir, ...
                sprintf('%s%s_%s_%03d_%s_%s.nc',radar_type, data_type, param.day_seg, frm,L1B_supplement_name_extra{extra_idx}, L1B_supplement_name));
            frames.quality = frames.(sprintf('quality_%s',L1B_supplement_name_extra{extra_idx}));
            supplement = [];
            supplement.coh_noise_removal_artifact = uint8(mod(floor(frames.quality(frm)/2^0),2));
            supplement.deconvolution_artifact = uint8(mod(floor(frames.quality(frm)/2^1),2));
            supplement.vertical_stripes_artifact = uint8(mod(floor(frames.quality(frm)/2^2),2));
            supplement.missing_data = uint8(mod(floor(frames.quality(frm)/2^3),2));
            supplement.no_good_data = uint8(mod(floor(frames.quality(frm)/2^4),2));
            supplement.low_SNR = uint8(mod(floor(frames.quality(frm)/2^5),2));
            supplement.unclassified_artifact = uint8(mod(floor(frames.quality(frm)/2^6),2));
            supplement.land_ice = uint8(mod(floor(frames.quality(frm)/2^7),2));
            fprintf('   extra nc: %s\n', out_fn_netcdf);
            netcdf_from_mat(out_fn_netcdf,supplement,supplement_netcdf_param);
        end
    end
  end
end

success = 1;

return;
