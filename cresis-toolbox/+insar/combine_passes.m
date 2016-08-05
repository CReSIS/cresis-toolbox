%% User Settings
frms = {};
frms{end+1} = '20160413_01_001';
frms{end+1} = '20160413_01_002';
frms{end+1} = '20160413_02_001';
frms{end+1} = '20160413_02_002';
frms{end+1} = '20160413_02_003';
frms{end+1} = '20160413_02_004';

pass_name = 'good_line';

start.lat = 67.092559;
start.lon = -50.213384;
stop.lat = 67.097116;
stop.lon = -50.048177;

dist_min = 100;

%% Automated

if 1
  % Load SAR data
  metadata = [];
  data = [];
  for frm_idx = 1:length(frms)
    param = [];
    param.day_seg = frms{frm_idx}(1:11);
    param = read_param_xls(ct_filename_param('rds_param_2016_Greenland_G1XB.xls'),param.day_seg);
    
    param.load_sar_data.fn = ''; % Leave empty for default
    
    % Start and stop chunk to load (inf for second element loads to the end)
    param.load_sar_data.chunk = [1 inf];
    
    param.load_sar_data.sar_type = 'f-k';
    
    frm = str2double(frms{frm_idx}(13:end));
    param.load_sar_data.frame = frm;
    
    param.load_sar_data.subap = 1;
    
    % (wf,adc) pairs to load
    param.load_sar_data.imgs = {[1 1]};
    
    % Combine waveforms parameters
    param.load_sar_data.wf_comb = 10e-6;
    
    % Debug level (1 = default)
    param.load_sar_data.debug_level = 2;
    
    % Combine receive channels
    param.load_sar_data.combine_channels = 0;
    
    % Take abs()^2 of the data (only runs if combine_channels runs)
    param.load_sar_data.incoherent = 0;
    
    % Combine waveforms (only runs if incoherent runs)
    param.load_sar_data.combine_waveforms = 0;
    
    % Parameters for local_detrend (cmd == 5 disables, only runs if incoherent runs)
    param.load_sar_data.detrend.cmd = 3;
    param.load_sar_data.detrend.B_noise = [100 200];
    param.load_sar_data.detrend.B_sig = [1 10];
    param.load_sar_data.detrend.minVal = -inf;
    
    [data{frm_idx},metadata{frm_idx}] = load_sar_data(param);
    
    metadata{frm_idx}.frm = frm;
  end
end

%% Find start/stop points and extract radar passes
physical_constants;
[start.x,start.y,start.z] = geodetic2ecef(start.lat/180*pi,start.lon/180*pi,0,WGS84.ellipsoid);
[stop.x,stop.y,stop.z] = geodetic2ecef(stop.lat/180*pi,stop.lon/180*pi,0,WGS84.ellipsoid);

pass = [];

for frm_idx = 1:length(frms)
  % Find the distance to the start
  start_ecef = [start.x;start.y;start.z];
  stop_ecef = [stop.x;stop.y;stop.z];
  radar_ecef = [];
  [radar_ecef.x,radar_ecef.y,radar_ecef.z] = geodetic2ecef(metadata{frm_idx}.lat/180*pi, ...
    metadata{frm_idx}.lon/180*pi,0*metadata{frm_idx}.elev, ...
    WGS84.ellipsoid);
  radar_ecef = [radar_ecef.x; radar_ecef.y; radar_ecef.z];
  
  dist = bsxfun(@minus, radar_ecef, start_ecef);
  dist = sqrt(sum(abs(dist).^2));
  
  start_idxs = [];
  start_points = dist < dist_min;
  start_idx = find(start_points,1);
  while ~isempty(start_idx)
    stop_idx = find(start_points(start_idx:end)==0,1);
    if isempty(stop_idx)
      start_idx = [];
    else
      [~,new_idx] = min(dist(start_idx+(0:stop_idx-1)));
      new_idx = new_idx + start_idx-1;
      start_idxs = [start_idxs new_idx];
      new_start_idx = find(start_points(start_idx+stop_idx-1:end),1);
      start_idx = new_start_idx + start_idx+stop_idx-1-1;
    end
  end
  
  stop_dist = bsxfun(@minus, radar_ecef, stop_ecef);
  stop_dist = sqrt(sum(abs(stop_dist).^2));
  
  stop_idxs = [];
  start_points = stop_dist < dist_min;
  start_idx = find(start_points,1);
  while ~isempty(start_idx)
    stop_idx = find(start_points(start_idx:end)==0,1);
    if isempty(stop_idx)
      start_idx = [];
    else
      [~,new_idx] = min(stop_dist(start_idx+(0:stop_idx-1)));
      new_idx = new_idx + start_idx-1;
      stop_idxs = [stop_idxs new_idx];
      new_start_idx = find(start_points(start_idx+stop_idx-1:end),1);
      start_idx = new_start_idx + start_idx+stop_idx-1-1;
    end
  end
  
  if 0
    plot(dist,'b');
    hold on;
    plot(start_idxs, dist(start_idxs), 'ro');
    plot(stop_dist,'k');
    plot(stop_idxs, stop_dist(stop_idxs), 'ro');
    hold off;
    pause;
  end
  
  % Extract the data out of each
  idxs = [start_idxs stop_idxs];
  start_mask = [ones(size(start_idxs)) zeros(size(stop_idxs))];
  [idxs,sort_idxs] = sort(idxs);
  start_mask = start_mask(sort_idxs);
  
  for pass_idx = 2:length(idxs)
    if start_mask(pass_idx) ~= start_mask(pass_idx-1)
      start_idx = idxs(pass_idx-1);
      stop_idx = idxs(pass_idx);
      
      frm_id = sprintf('%s_%03d', metadata{frm_idx}.param_csarp.day_seg, metadata{frm_idx}.frm);
      
      fprintf('New Segment: %s %d to %d\n', frm_id, start_idx, stop_idx);
      
      if start_mask(pass_idx-1)
        rlines = start_idx:stop_idx;
      else
        rlines = stop_idx:-1:start_idx;
      end
      
      pass(end+1).data = data{frm_idx}{1}(:,rlines);
      
      pass(end).gps_time = metadata{frm_idx}.fcs{1}{1}.gps_time(rlines);
      pass(end).lat = metadata{frm_idx}.lat(rlines);
      pass(end).lon = metadata{frm_idx}.lon(rlines);
      pass(end).elev = metadata{frm_idx}.elev(rlines);
      pass(end).roll = metadata{frm_idx}.fcs{1}{1}.roll(rlines);
      pass(end).pitch = metadata{frm_idx}.fcs{1}{1}.pitch(rlines);
      pass(end).heading = metadata{frm_idx}.fcs{1}{1}.heading(rlines);
      
      pass(end).Lsar = metadata{frm_idx}.fcs{1}{1}.Lsar;
      pass(end).wfs = metadata{frm_idx}.wfs;
      pass(end).param_csarp = metadata{frm_idx}.param_csarp;
      pass(end).surface = metadata{frm_idx}.fcs{1}{1}.surface(:,rlines);
      
      pass(end).x = metadata{frm_idx}.fcs{1}{1}.x(:,rlines);
      pass(end).y = metadata{frm_idx}.fcs{1}{1}.y(:,rlines);
      pass(end).z = metadata{frm_idx}.fcs{1}{1}.z(:,rlines);
      pass(end).origin = metadata{frm_idx}.fcs{1}{1}.origin(:,rlines);
      pass(end).pos = metadata{frm_idx}.fcs{1}{1}.pos(:,rlines);
    end
  end
  
end

out_fn = fullfile(ct_filename_out(param,'insar','',1),[pass_name '.mat']);
out_fn_dir = fileparts(out_fn);
if ~exist(out_fn_dir,'dir')
  mkdir(out_fn_dir);
end
save(out_fn,'-v7.3','pass');
