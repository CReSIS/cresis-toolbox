% script imb.run_slice_browser
%
% Script for running imb.slice_browser.m
%
% Run "clear run_slice_browser_fn;" whenever you change frames or geotiff
%
% Author: Sravya Athinarapu, Elijah Paden, John Paden, Jordan Sprick

%% User Settings
% =========================================================================

if 0
  % DOA methods
  param.doa_method_flag = true;
  day_seg = '20110317_03';
  param.radar_name = 'rds';
  param.season_name = '2011_Greenland_P3';
  out_type = 'test_music3D_mle';
  surfdata_source = 'test_surfData_scratch';
  param.day_seg = day_seg;
  frm = 1;
  geotiff_fn = ct_filename_gis(param,fullfile('greenland','Landsat-7','Greenland_natural_90m.tif'));
%   ice_mask_fn = ct_filename_gis(param,fullfile('greenland','IceMask','GimpIceMask_90m_v1.1.bin'));
  ice_mask_fn = '';
  doa_limits = [-60 60]; % DOA limits for slice browsing (outside this limits will not be displayed)
  nadir_doa_lim = [-2 2]; % DOA range overwhich an estimated DOA is considered as nadir. This is usually the initial DOA limits of S-MAP.
elseif 1
  param.radar_name = 'rds';
  param.season_name = '2018_Greenland_P3';
  out_type = 'music3D';
  surfdata_source = 'surf';
  param.day_seg = '20180406_01';
  frm = 2;
  geotiff_fn = ct_filename_gis(param,fullfile('greenland','Landsat-7','Greenland_natural_90m.tif'));
  ice_mask_fn = ct_filename_gis(param,fullfile('greenland','IceMask','GimpIceMask_90m_v1.1.bin'));
  ice_mask_fn = '';
  bounds_relative = [3 2 0 0];
  
elseif 0
  param.radar_name = 'rds';
  param.season_name = '2014_Greenland_P3';
  out_type = 'music3D_old';
  surfdata_source = '';
  param.day_seg = '20140325_05';
  frm = 1;
  geotiff_fn = ct_filename_gis(param,fullfile('canada','Landsat-7','Canada_90m.tif'));
  %ice_mask_fn = ct_filename_gis(param,fullfile('canada','ice_mask','03_rgi50_ArcticCanadaNorth','03_rgi50_ArcticCanadaNorth.bin'));
  ice_mask_fn = '';
  bounds_relative = [3 2 0 0];
  
elseif 0
  param.radar_name = 'rds';
  param.season_name = '2009_Antarctica_TO';
  out_type = 'music3D';
  surfdata_source = '';
  param.day_seg = '20091224_01';
  frm = 26;
  geotiff_fn = ct_filename_gis(param,fullfile('antarctica','Landsat-7','Antarctica_LIMA_480m.tif'));
  ice_mask_fn = '';
  bounds_relative = [8 8 0 0];
  
elseif 0
  param.radar_name = 'rds';
  param.season_name = '2019_Antarctica_Ground';
  out_type = 'music3D_paden';
  surfdata_source = 'surfData_paden';
  param.day_seg = '20200107_01';
  frm = 1;
  geotiff_fn = ct_filename_gis(param,fullfile('antarctica','Landsat-7','Antarctica_LIMA_480m.tif'));
  ice_mask_fn = '';
  bounds_relative = [0 0 0 0];
  
else
  param.radar_name = 'rds';
  param.season_name = '2013_Antarctica_Basler';
  out_type = 'NDH_music';
  surfdata_source = '';
  param.day_seg = '20140104_03';
  frm = 2;
  geotiff_fn = ct_filename_gis(param,fullfile('antarctica','Landsat-7','Antarctica_LIMA_480m.tif'));
  ice_mask_fn = '';
  bounds_relative = [8 8 0 0];

end

%% Automated Section
% =========================================================================

echogram_fn = fullfile(ct_filename_out(param,out_type,''),sprintf('Data_%s_%03d.mat',param.day_seg,frm));
if ~exist('run_slice_browser_fn','var') || ~strcmp(run_slice_browser_fn,echogram_fn)
  fprintf('Loading data (%s)\n', datestr(now));
  mdata = load(echogram_fn);
  
  proj = geotiffinfo(geotiff_fn);
  [DEM, R, tmp] = geotiffread(geotiff_fn);
  
  run_slice_browser_fn = echogram_fn;
  fprintf('  Done loading data (%s)\n', datestr(now));
else
  fprintf('Using already loaded data. Run "clear run_slice_browser_fn" to load new data (%s)\n', datestr(now));
  
end

if ~exist('surfdata_source','var') || isempty(surfdata_source)
  surfdata_source = 'surf';
end
sb_param = [];
sb_param.surfdata_fn = fullfile(ct_filename_out(param,surfdata_source,''),sprintf('Data_%s_%03d.mat',param.day_seg,frm));
if ~exist(sb_param.surfdata_fn,'file')
  surf = tomo.surfdata(mdata,surfdata_source);
  surf.save_surfdata(sb_param.surfdata_fn);
else
  surf = tomo.surfdata.update_file(sb_param.surfdata_fn,sb_param.surfdata_fn,echogram_fn);
end

if ~isfield(param,'doa_method_flag') || isempty(param.doa_method_flag)
  sb_param.doa_method_flag = false;
  sb_param.bounds_relative = bounds_relative;
else
  sb_param.doa_method_flag = param.doa_method_flag;
  sb_param.doa_limits = doa_limits;
  sb_param.nadir_doa_lim = nadir_doa_lim;
end

%% Call slice_browser
try; delete(obj); end;
if sb_param.doa_method_flag
  % DOA method (DOA is passed in degrees)
  obj = imb.slice_browser(mdata,[],sb_param);
else
  % Beamforming method
  obj = imb.slice_browser(mdata,[],sb_param);
%   try; delete(viterbi_tool); end;
%   viterbi_tool = imb.slicetool_viterbi();
%   obj.insert_tool(viterbi_tool);
  
  try; delete(trws_tool); end;
  trws_tool = imb.slicetool_trws();
  obj.insert_tool(trws_tool);
  
%   try; delete(max_tool); end;
%   max_tool = imb.slicetool_max();
%   obj.insert_tool(max_tool);
  
  try; delete(quality_tool); end;
  quality_tool = imb.slicetool_quality();
  obj.insert_tool(quality_tool);
  
  try; delete(delete_tool); end;
  delete_tool = imb.slicetool_delete();
  obj.insert_tool(delete_tool);
  
%   try; delete(threshold_tool); end;
%   threshold_tool = imb.slicetool_threshold();
%   obj.insert_tool(threshold_tool);
end
if ~isempty(ice_mask_fn)
  [ice_mask_fn_dir ice_mask_fn_name] = fileparts(ice_mask_fn);
  ice_mask_mat_fn = fullfile(ice_mask_fn_dir,[ice_mask_fn_name '.mat']);
  ice_mask = load(ice_mask_mat_fn,'R','X','Y','proj');
  
  [fid,msg] = fopen(ice_mask_fn,'r');
  if fid < 1
    fprintf('Could not open file %s\n', ice_mask_bin_fn);
    error(msg);
  end
  ice_mask.mask = logical(fread(fid,[length(ice_mask.Y),length(ice_mask.X)],'uint8'));
  fclose(fid);
  
  try; delete(icemask_tool); end;
  icemask_tool = imb.slicetool_icemask();
  custom_data.DEM = DEM;
  custom_data.R = R;
  custom_data.ice_mask = ice_mask;
  custom_data.proj = proj;
  custom_data.ice_mask_fn = ice_mask_fn;
  custom_data.mdata = mdata;
  custom_data.sb = obj;
  custom_data.reduce_flag = 1;
  custom_data.ice_mask_layer = 3;
  icemask_tool.set_custom_data(custom_data);
  obj.insert_tool(icemask_tool);
end
