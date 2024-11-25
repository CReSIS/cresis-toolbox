function lay = opsInterpLayersToMasterGPSTime(master,ops_layer,gaps_dist)
% lay = opsInterpLayersToMasterGPSTime(master,ops_layer,gaps_dist)
%
% This function takes layer data from the OPS and re-interpolates it onto
% a new GPS time axis (e.g. for post.m or records_update.m).
%
% master
%  .GPS_time
%  .Latitude
%  .Longitude
%  .Elevation
% ops_layer
%  Cell vector of returns from opsGetLayerPoints. Returns are structs with
%  the following fields.
%  .gps_time
%  .type
%  .quality
%  .twtt
% gaps_dist
%  Parameter to data_gaps_check_mex.cpp mex function
%
% lay.layerData
%   Interpolation of ops_layer data to master GPS time
%
% param = read_param_xls(ct_filename_param('rds_param_2009_Greenland_TO.xls'),'20090411_01','post');
% frm = 2;
% 
% ops_sys = ct_output_dir(param.radar_name);
% ops_param = [];
% ops_param.properties.location = param.post.ops.location;
% ops_param.properties.season = param.season_name;
% ops_param.properties.segment = param.day_seg;
% ops_param.properties.return_geom = 'geog';
% ops_layer = {};
% for layer_idx = 1:length(param.post.ops.layers)
%   ops_param.properties.lyr_name = param.post.ops.layers{layer_idx};
%   [~,ops_layer{layer_idx}] = opsGetLayerPoints(ops_sys,ops_param);
%   ops_layer{layer_idx} = ops_layer{layer_idx}.properties;
% end
% 
% data_fn = fullfile(ct_filename_out(param,'','CSARP_mvdr'),sprintf('Data_%s_%03d.mat',param.day_seg,frm));
% master = load(data_fn);
%
% lay = opsInterpLayersToMasterGPSTime(master,ops_layer,[300 60]);
%
% Author: John Paden
%
% See also: opsGetLayerPoints.m

% Copy GPS_time, Elevation, Latitude, Longitude fields
lay = [];
lay.GPS_time = master.GPS_time;
lay.Latitude = master.Latitude;
lay.Longitude = master.Longitude;
lay.Elevation = master.Elevation;
lay.layerData = {};

%% Interpolate each layer for this segment onto the master layer's gps time
master_along_track = geodetic_to_along_track(lay.Latitude, ...
  lay.Longitude, lay.Elevation);

% Interpolate each layer onto the echogram
for layer_idx = 1:length(ops_layer)
  % Get all the manual and auto points
  auto_idxs = find(ops_layer{layer_idx}.type == 1 | ops_layer{layer_idx}.type == 2);
  [unique_vals unique_idxs] = unique(ops_layer{layer_idx}.gps_time(auto_idxs));
  auto_idxs = auto_idxs(unique_idxs);
  
  slave = ops_layer{layer_idx}.gps_time(auto_idxs);
  tie_idx = find(slave >= lay.GPS_time(1) ...
    & slave <= lay.GPS_time(end),2);
  % Interpolate the points onto the echogram GPS time
  if isempty(tie_idx)
    % Not enough points to interpolate, so set to all NaN
    lay.layerData{layer_idx}.value{2}.data ...
      = NaN*zeros(size(lay.GPS_time));
    lay.layerData{layer_idx}.quality ...
      = NaN*zeros(size(lay.GPS_time));
    
  elseif length(tie_idx) == 1
    lay.layerData{layer_idx}.value{2}.data ...
      = interp1(ops_layer{layer_idx}.gps_time(auto_idxs), ...
      ops_layer{layer_idx}.twtt(auto_idxs), lay.GPS_time, 'nearest');
    lay.layerData{layer_idx}.quality ...
      = interp1(ops_layer{layer_idx}.gps_time(auto_idxs), ...
      ops_layer{layer_idx}.quality(auto_idxs), lay.GPS_time, 'nearest');
    slave_along_track = interp1(lay.GPS_time, master_along_track, slave, 'linear', 'extrap');
    gap_data_idxs = data_gaps_check_mex(master_along_track, slave_along_track, ...
      gaps_dist(1), gaps_dist(2));
    lay.layerData{layer_idx}.value{2}.data(gap_data_idxs) = NaN;
    lay.layerData{layer_idx}.quality(gap_data_idxs) = NaN;
    
  else
    lay.layerData{layer_idx}.value{2}.data ...
      = interp1(ops_layer{layer_idx}.gps_time(auto_idxs), ...
      ops_layer{layer_idx}.twtt(auto_idxs), lay.GPS_time, 'linear');
    lay.layerData{layer_idx}.quality ...
      = interp1(ops_layer{layer_idx}.gps_time(auto_idxs), ...
      ops_layer{layer_idx}.quality(auto_idxs), lay.GPS_time, 'nearest');
    
    slave_along_track = interp1(lay.GPS_time, master_along_track, slave);
    gap_data_idxs = data_gaps_check_mex(master_along_track, slave_along_track, ...
      gaps_dist(1), gaps_dist(2));
    lay.layerData{layer_idx}.value{2}.data(gap_data_idxs) = NaN;
    lay.layerData{layer_idx}.quality(gap_data_idxs) = NaN;
  end
  
  lay.layerData{layer_idx}.value{1}.data = NaN*zeros(size(lay.GPS_time));
  manual_idxs = find(ops_layer{layer_idx}.type == 1);
  manual_idxs_map = interp1(lay.GPS_time, 1:length(lay.GPS_time), ...
    ops_layer{layer_idx}.gps_time(manual_idxs),'nearest');
  manual_idxs = manual_idxs(~isnan(manual_idxs_map));
  manual_idxs_map = manual_idxs_map(~isnan(manual_idxs_map));
  lay.layerData{layer_idx}.value{1}.data(manual_idxs_map) ...
    = ops_layer{layer_idx}.twtt(manual_idxs);
end

end
