% Raw data: /cresis/data1/SAR/2007_Greenland/Accum_NEEM_2007/
%   - may have the FTP set to ascii problem (saw some dos2unix stuff???)
%
% JOHN PADEN: Is this the dataset (2007 Greenland NEEM traverse) that was ftp’d with ASCII binary transfer?
% CARL LEUSCHEN: Sounds familiar
% WILLIAM BLAKE: It definitely could have been, but I thought there was a version of those data that had that error reversed out so it wasn't an issue.  Because I know I had looked at those data before and had not done any special conversion on them.
% DAVID BRAATEN: I think this is the data set with the ASCII transfer set, but as I understand, the accumulation radar data was fine.  Only the depth sounder data was impacted.
% JOHN PADEN: Notes that there are two file sizes for each accum file on the server and conversion scripts... sign that somebody thought there might be a problem

% base_input_dir = '/cresis/scratch2/mdce/cr1/accum/2008_Greenland_Ground/';
%
% fns = get_filenames(base_input_dir,'Data','','set.mat',struct('recursive',1))

if 0
  %% Exploration Code
  idx = 0;
  fns = {};
  
  idx = idx+1;
  fns{idx} = '/cresis/scratch2/mdce/cr1/accum/2007_Greenland_Ground/sourceData_00/Data_traverse_set.mat';
  idx = idx+1;
  fns{idx} = '/cresis/scratch2/mdce/cr1/accum/2007_Greenland_Ground/sourceData_01/Data_traverse_set.mat';
  idx = idx+1;
  fns{idx} = '/cresis/scratch2/mdce/cr1/accum/2007_Greenland_Ground/sourceData_02/Data_traverse_set.mat';
  idx = idx+1;
  fns{idx} = '/cresis/scratch2/mdce/cr1/accum/2007_Greenland_Ground/sourceData_03/Data_traverse_set.mat';
  idx = idx+1;
  fns{idx} = '/cresis/scratch2/mdce/cr1/accum/2007_Greenland_Ground/sourceData_04/Data_traverse_set.mat';
  idx = idx+1;
  fns{idx} = '/cresis/scratch2/mdce/cr1/accum/2007_Greenland_Ground/sourceData_05/Data_traverse_set.mat';
  
  out_dir = '/cresis/scratch2/mdce/cr1/accum/2007_Greenland_Ground/CSARP_traverse/';
  
  % /cresis/scratch1/hilary/TEMP_LAYERS/layerData/Data_traverse_set.mat
  
  layers = load('/cresis/scratch1/hilary/TEMP_LAYERS/layerData/Data_traverse_set.mat')
  
  figure(1); clf;
  colors = {'k','r','y','g','c','b'};
  for fn_idx = 1:length(fns)
    fn = fns{fn_idx};
    fn_info = dir(fn);
    fprintf('Converting %s\n', fn);
    old = load(fn);
    
    fprintf('UTC time all NaN: %d\n', all(isnan(old.UTC_time)))
    
    plot(old.Longitude, old.Latitude, colors{fn_idx})
    hold on;
    
    fprintf('%.2f us\t', 1e6*old.Depth([1 end]))
    fprintf('\n');
    fprintf('%.2f\t', old.Time([1 end]))
    fprintf('\n');
    
    new = [];
    new.Data = old.Data;
    new.Latitude = old.Latitude;
    new.Longitude = old.Longitude;
    new.Elevation = old.Elevation;
    new.Time = old.Depth;
    new.Depth = old.Time;
    new.GPS_time = datenum_to_epoch(datenum(2007,7,1,0,0,0)) + 1:size(new.Data,2);
    new.IMPORTANT_NOTES = 'The GPS time for this file is faked.';
    
    new_fn = fullfile(out_dir,'Data_20070701_01_001.mat');
    fprintf('  Saving output %s\n', new_fn);
  end
end

if 1
  %% Conversion Code
  old = load('/cresis/scratch2/mdce/cr1/accum/2007_Greenland_Ground/sourceData_00/Data_traverse_set.mat');
  out_dir = '/cresis/scratch2/mdce/cr1/accum/2007_Greenland_Ground/CSARP_traverse/20070701_01';
  if ~exist(out_dir,'dir')
    mkdir(out_dir)
  end
  layers = load('/cresis/scratch1/hilary/TEMP_LAYERS/layerData/Data_traverse_set.mat')
  layer_dir = '/cresis/scratch2/mdce/cr1/accum/2007_Greenland_Ground/CSARP_layerData/20070701_01';
  if ~exist(layer_dir,'dir')
    mkdir(layer_dir)
  end
  
  param = read_param_xls('/users/paden/scripts/branch/params-cr1/accum_param_2007_Greenland_Ground.xls','20070701_01');
  along_track = geodetic_to_along_track(old.Latitude,old.Longitude,old.Elevation);
  
  % Break frame into 20 km lengths
  frame_length = 20000;
  frame_breaks = 0:frame_length:along_track(end);
  if along_track(end)-frame_breaks(end) < frame_length/2
    frame_breaks = frame_breaks(1:end-1);
  end
  frames = [];
  frames.frame_idxs = zeros(size(frame_breaks));
  
  frames.frame_idxs(1) = 1;
  idx = 2;
  rec = 2;
  
  while idx <= length(frame_breaks)
    if along_track(rec) > frame_breaks(idx)
      frames.frame_idxs(idx) = rec;
      idx = idx + 1;
    end
    rec = rec + 1;
  end
  
  frames.nyquist_zone = NaN*zeros(size(frames.frame_idxs));
  frames.proc_mode = zeros(size(frames.frame_idxs));
  
  records_fn = ct_filename_support(param,'','records');
  frames_fn = ct_filename_support(param,'','frames');
  fprintf('  Saving %s (%s)\n', frames_fn, datestr(now));
  frames_fn_dir = fileparts(frames_fn);
  if ~exist(frames_fn_dir,'dir')
    mkdir(frames_fn_dir);
  end
  save(frames_fn,'-v6','frames');
  
  year = str2double(param.day_seg(1:4));
  month = str2double(param.day_seg(5:6));
  day = str2double(param.day_seg(7:8));
  gps_time = datenum_to_epoch(datenum(year,month,day,0,0,60)) + (1:length(along_track));

  gps = [];
  gps.lat = old.Latitude;
  gps.lon = old.Longitude;
  gps.elev = old.Elevation;
  gps.roll = zeros(size(gps.lat));
  gps.pitch = zeros(size(gps.lat));
  gps.gps_time = gps_time;
  gps.gps_source = 'Fake-Fake20130620';
  
  along_track = geodetic_to_along_track(gps.lat,gps.lon,gps.elev);
  rlines = get_equal_alongtrack_spacing_idxs(along_track,10);
  physical_constants; % Load WGS84.spheroid
  for rline_idx = 1:length(rlines)
    rline = rlines(rline_idx);
    if rline_idx < length(rlines)
      rline_end = rlines(rline_idx+1);
    else
      rline_end = length(along_track);
    end
    [origin(1),origin(2),origin(3)] = geodetic2ecef(WGS84.spheroid,gps.lat(rline),gps.lon(rline),gps.elev(rline));
    [heading(1),heading(2),heading(3)] = geodetic2ecef(WGS84.spheroid,gps.lat(rline_end),gps.lon(rline_end),gps.elev(rline_end));
    heading = heading - origin;
    % Determine east vector
    [east(1) east(2) east(3)] = enu2ecef(1,0,0,gps.lat(rline),gps.lon(rline),gps.elev(rline),WGS84.spheroid);
    east = east - origin;
    % Determine north vector
    [north(1) north(2) north(3)] = enu2ecef(0,1,0,gps.lat(rline),gps.lon(rline),gps.elev(rline),WGS84.spheroid);
    north = north - origin;
    % Determine heading
    gps.heading(rline:rline_end) = atan2(dot(east,heading),dot(north,heading));
  end
  
  gps_fn = ct_filename_support(param,'','gps',1);
  fprintf('  Saving %s (%s)\n', gps_fn, datestr(now));
  gps_fn_dir = fileparts(gps_fn);
  if ~exist(gps_fn_dir,'dir')
    mkdir(gps_fn_dir);
  end
  save(gps_fn,'-v6','-struct','gps');
  
  records = [];
  records.lat = old.Latitude;
  records.lon = old.Longitude;
  records.elev = old.Elevation;
  records.roll = gps.roll;
  records.pitch = gps.pitch;
  records.heading = gps.heading;
  records.gps_time = gps_time;
  records.ver = 3;
  records.notes = 'This is a ficticious segment: a combination of many segments on different days for the NGRIP-NEEM traverse';
  fprintf('  Saving %s (%s)\n', records_fn, datestr(now));
  records_fn_dir = fileparts(records_fn);
  if ~exist(records_fn_dir,'dir')
    mkdir(records_fn_dir);
  end
  save(records_fn,'-v6','-struct','records');
  
  for frame = 1:length(frames.frame_idxs)
    if frame < length(frames.frame_idxs)
      recs = frames.frame_idxs(frame) : frames.frame_idxs(frame+1)-1;
    else
      recs = frames.frame_idxs(frame) : length(along_track);
    end
    new = [];
    new.Data = 10.^(old.Data(:,recs)/10);
    new.Latitude = old.Latitude(1,recs);
    new.Longitude = old.Longitude(1,recs);
    new.Elevation = old.Elevation(1,recs);
    new.Surface = zeros(size(recs));
    new.Time = old.Depth;
    new.Depth = old.Time;
    new.GPS_time = gps_time(1,recs);
    new.IMPORTANT_NOTES = 'The GPS time for this file is faked.';
    new_fn = fullfile(out_dir,sprintf('Data_%s_%03d.mat',param.day_seg,frame));
    fprintf('  Saving output %s\n', new_fn);
    save(new_fn,'-v6','-struct','new');
    
    layers_new = [];
    check_size = [];
    for layer_idx = 1:length(layers.layerData)
      if strcmpi(layers.layerData{layer_idx}.name,'surface')
        layers_new.layerData{layer_idx}.value{1}.data = zeros(size(recs));
        layers_new.layerData{layer_idx}.value{2}.data = zeros(size(recs));
      else
        layers_new.layerData{layer_idx}.value{1}.data ...
          = interp1(new.Depth,new.Time,layers.layerData{layer_idx}.value{1}.data(1,recs));
        layers_new.layerData{layer_idx}.value{2}.data ...
          = interp1(new.Depth,new.Time,layers.layerData{layer_idx}.value{2}.data(1,recs));
      end
      if isempty(check_size)
        check_size = size(layers_new.layerData{layer_idx}.value{1}.data,2);
      else
        if check_size ~= size(layers_new.layerData{layer_idx}.value{1}.data,2)
          keyboard
        end
      end
      if check_size ~= size(layers_new.layerData{layer_idx}.value{2}.data,2)
        keyboard
      end
      layers_new.layerData{layer_idx}.quality = layers.layerData{layer_idx}.quality(1,recs);
      layers_new.layerData{layer_idx}.name = layers.layerData{layer_idx}.name;
    end
    layers_new.Latitude = old.Latitude(1,recs);
    layers_new.Longitude = old.Longitude(1,recs);
    layers_new.Elevation = old.Elevation(1,recs);
    layers_new.GPS_time = gps_time(1,recs);
    
    new_fn = fullfile(layer_dir,sprintf('Data_%s_%03d.mat',param.day_seg,frame));
    fprintf('  Saving layers %s\n', new_fn);
    save(new_fn,'-v6','-struct','layers_new');
    
  end
  
end

if 0
  %% Test New Files
  load /cresis/scratch2/mdce/cr1/accum/2007_Greenland_Ground/CSARP_traverse/20070701_01/Data_20070701_01_001.mat;
  load /cresis/scratch2/mdce/cr1/accum/2007_Greenland_Ground/CSARP_layerData/20070701_01/Data_20070701_01_001.mat
  
  figure(1); clf;
  imagesc([],Time*1e6,lp(Data))
  colormap(1-gray(256));
  hold on;
  colors = {'r','y','g','c','b'};
  for layer_idx = 1:length(layers.layerData)
    color_idx = mod(layer_idx-1,length(colors))+1;
    plot(layerData{layer_idx}.value{1}.data*1e6,[colors{color_idx} '.'])
    plot(layerData{layer_idx}.value{2}.data*1e6,colors{color_idx})
  end
  hold off;
  ylim([0 0.05]);
  
  %% Test Old Files
  load('/cresis/scratch1/hilary/TEMP_LAYERS/sourceData_01/Data_traverse_set.mat');
  load('/cresis/scratch1/hilary/TEMP_LAYERS/layerData/Data_traverse_set.mat')
  
  Data = 10.^(Data/10);
  
  figure(1); clf;
  imagesc([],Time,lp(Data))
  colormap(1-gray(256));
  hold on;
  colors = {'r','y','g','c','b'};
  for layer_idx = 1:length(layerData)
    color_idx = mod(layer_idx-1,length(colors))+1;
    plot(layerData{layer_idx}.value{1}.data,[colors{color_idx} '.'])
    plot(layerData{layer_idx}.value{2}.data,colors{color_idx})
    if size(layerData{layer_idx}.value{1}.data,2) ~= 29348
      error('now');
    end
    if size(layerData{layer_idx}.value{2}.data,2) ~= 29348
      error('now');
    end
  end
  hold off;
  ylim([0 15]);
end




