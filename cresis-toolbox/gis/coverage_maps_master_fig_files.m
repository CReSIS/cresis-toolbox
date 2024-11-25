% script coverage_maps_master_fig_files.m
%
% This script creates the coverage maps from the data
%
% It plots all radar data and distinguishes between:
%  1. Good data (quality <= 1)
%  2. Moderate data (quality > 1)
%  3. Bad data (no bottom pick)
%
% Plot handles are grouped according to data quality type and to
% season.
%
% The function outputs a figure (Matlab .fig file).
%
% Example: See code at bottom of this function for how to load and
% manipulate the figure.
%
% Author: John Paden
%
% See also: coverage_maps.m

%% User Settings

% out_dir = '/cresis/snfs1/scratch/paden/coverage_maps/';
% out_dir = 'Z:\sfoga\coverage_maps\';
out_dir = 'H:\rohan\Oldscript\';

location = 'Greenland';
% location = 'Canada';
% location = 'Antarctica';

if strcmpi(location,'Greenland') || strcmpi(location,'Canada')
  season_names = {};
%   season_names{end+1,1} = 'icards/1993_Greenland_P3';
%   season_names{end+1,1} = 'icards/1995_Greenland_P3';
%   season_names{end+1,1} = 'icards/1996_Greenland_P3';
%   season_names{end+1,1} = 'icards/1997_Greenland_P3';
%   season_names{end+1,1} = 'icards/1998_Greenland_P3';
%   season_names{end+1,1} = 'icards/1999_Greenland_P3';
%   season_names{end+1,1} = 'icards/2001_Greenland_P3';
%   season_names{end+1,1} = 'icards/2002_Greenland_P3';
%   season_names{end+1,1} = 'acords/2003_Greenland_P3';
%   season_names{end+1,1} = 'acords/2005_Greenland_TO';
%   season_names{end+1,1} = 'mcrds/2006_Greenland_TO';
%   season_names{end+1,1} = 'mcrds/2007_Greenland_P3';
%   season_names{end+1,1} = 'mcrds/2008_Greenland_Ground';
%   season_names{end+1,1} = 'mcrds/2008_Greenland_TO';
%   season_names{end+1,1} = 'mcrds/2010_Greenland_TO';
%   season_names{end+1,1} = 'mcords/2010_Greenland_DC8';
%   season_names{end+1,1} = 'mcords/2010_Greenland_P3';
%   season_names{end+1,1} = 'mcords/2011_Greenland_TO';
%   season_names{end+1,1} = 'mcords2/2011_Greenland_P3';
%   season_names{end+1,1} = 'mcords2/2012_Greenland_P3';
%   season_names{end+1,1} = 'mcords3/2013_Greenland_P3';
%   season_names{end+1,1} = 'mcords3/2014_Greenland_P3';
  season_names{end+1,1} = 'mcords5/2015_Greenland_C130';
%   season_names{end+1,1} = 'mcords5/2016_Greenland_P3';
%   season_names{end+1,1} = 'mcords3/2017_Greenland_P3';
  data_location = {};
  for idx=1:length(season_names)
    data_location{idx} = 'CSARP_post/layerData';
  end
elseif strcmpi(location,'Antarctica')
  season_names = {};
  season_names{end+1,1} = 'rds/2002_Antarctica_P3chile';
  season_names{end+1,1} = 'rds/2004_Antarctica_P3chile';
  season_names{end+1,1} = 'rds/2009_Antarctica_DC8';
  season_names{end+1,1} = 'rds/2009_Antarctica_TO';
  season_names{end+1,1} = 'rds/2010_Antarctica_DC8';
  season_names{end+1,1} = 'rds/2011_Antarctica_DC8';
  season_names{end+1,1} = 'rds/2011_Antarctica_TO';
  season_names{end+1,1} = 'rds/2012_Antarctica_DC8';
  season_names{end+1,1} = 'rds/2013_Antarctica_P3';
  data_location = {};
  for idx=1:length(season_names)
    data_location{idx} = 'layerData';
  end
  data_location{end} = 'CSARP_post/layerData';
else
  return
end

%% Automated Section

tstart_coverage_maps2 = tic;
global gRadar;

if ~exist(out_dir,'dir')
  mkdir(out_dir);
end

if 1
  if strcmpi(location,'Greenland')
    geotiff_fns = {};
    geotiff_fns{1} = ct_filename_gis(gRadar,'greenland/Landsat-7/Greenland_natural_250m.tif');
    fig_size = [50 50 600 800];
    fig_paper_position = [0.25 2.5 6 8];
  elseif strcmpi(location,'Canada')
    geotiff_fns = {};
    geotiff_fns{1} = ct_filename_gis(gRadar,'canada/Landsat-7/Canada_250m.tif');
    fig_size = [50 50 600 800];
    fig_paper_position = [0.25 2.5 6 8];
  elseif strcmpi(location,'Antarctica')
    fig_size = [50 50 800 600];
    fig_paper_position = [0.25 2.5 8 6];
    geotiff_fns = {};
    geotiff_fns{1} = ct_filename_gis(gRadar,'antarctica/Landsat-7/Antarctica_LIMA_480m.tif');
  end

  % Load the geotiffs + plot them in the master figure
  figure(1); clf;
  RGB = {};
  R = {};
  for geotiff_fns_idx = 1:length(geotiff_fns)
    proj = geotiffinfo(geotiff_fns{geotiff_fns_idx});
    [RGB{geotiff_fns_idx}, R{geotiff_fns_idx}, tmp] = geotiffread(geotiff_fns{geotiff_fns_idx});
    R{geotiff_fns_idx} = R{geotiff_fns_idx}/1e3;
    mapshow(RGB{geotiff_fns_idx}, R{geotiff_fns_idx});
    hold on;
  end
  set(1,'Position',fig_size + [625 0 0 0]);
  hold on;
  xlabel('X (km)');
  ylabel('Y (km)');
  title(location);
  axis([R{1}(3,1)+[0 R{1}(2,1)*(size(RGB{1},2)-1)] sort(R{1}(3,2)+[0 R{1}(1,2)*(size(RGB{1},1)-1)])]);
end

bad_data_handles = [];
moderate_data_handles = [];
good_data_handles = [];
for season_idx = 1:length(season_names)
  fprintf('Processing season %s\n', season_names{season_idx});
  filesep_idx = find(season_names{season_idx}=='/',1);
  clear param;
  param.radar_name = season_names{season_idx}(1:filesep_idx-1);
  param.season_name = season_names{season_idx}(filesep_idx+1:end);
  out_path = ct_filename_out(param,data_location{season_idx},'',true);
  % HACK WHILE TRANSITIONING TO CR1:
%   out_path = fullfile('/cresis/scratch2/mdce/',param.radar_name,param.season_name,'CSARP_post','CSARP_layerData');
  
  layer_files = get_filenames(out_path,'Data_','','.mat',struct('recursive',true));
  bottom = [];
  quality = [];
  x = [];
  y = [];
  for layer_idx = 1:length(layer_files)
    fprintf('  Layer file %s %d of %d (%.1f sec)\n', layer_files{layer_idx}, ...
      layer_idx, length(layer_files), toc(tstart_coverage_maps2));
    load(layer_files{layer_idx},'Latitude','Longitude','layerData');
    if length(Latitude) ~= length(layerData{2}.value{2}.data)
      fprintf('    Bad file\n');
      continue;
    end
    along_track = geodetic_to_along_track(Latitude,Longitude,zeros(size(Latitude)));
    idxs = get_equal_alongtrack_spacing_idxs(along_track,50);
    bottom = cat(2,bottom,isfinite(layerData{2}.value{2}.data(idxs)));
    quality = cat(2,quality,layerData{2}.quality(idxs));
    [x_tmp,y_tmp] = projfwd(proj,Latitude(idxs),Longitude(idxs));
    x = cat(2,x,x_tmp/1e3);
    y = cat(2,y,y_tmp/1e3);
  end
  no_bottom_mask = bottom==0;
  moderate_mask = bottom==1 & quality > 1;
  bottom_mask = bottom==1 & ~moderate_mask;
  figure(1);
  if any(no_bottom_mask)
    bad_data_handles(season_idx) = plot(x(no_bottom_mask),y(no_bottom_mask),'r.');
  else
    bad_data_handles(season_idx) = plot(1,NaN,'r.');
  end
  if any(moderate_mask)
    moderate_data_handles(season_idx) = plot(x(moderate_mask),y(moderate_mask),'y.');
  else
    moderate_data_handles(season_idx) = plot(1,NaN,'y.');
  end
  if any(bottom_mask)
    good_data_handles(season_idx) = plot(x(bottom_mask),y(bottom_mask),'g.');
  else
    good_data_handles(season_idx) = plot(1,NaN,'g.');
  end
end

figure(1);
h_good = plot(1,NaN,'g.');
h_mod = plot(1,NaN,'y.');
h_bad = plot(1,NaN,'r.');
legend([h_good h_mod h_bad],'Good','Moderate','Bad','Location','Best');
set(1,'PaperPosition',fig_paper_position);
set(1,'UserData',season_names);

%% Save Matlab figure
image_master_fn = fullfile(out_dir,sprintf('%s_All_Seasons.fig',location));
saveas(1,image_master_fn);

%% Save JPG figure
% image_master_fn = fullfile(out_dir,sprintf('%s_All_Seasons.jpg',location));
% saveas(1,image_master_fn);

%% Save PDF figure
% h_children = get(1,'Children');
% h_children = get(h_children(2),'Children');
% h_geotiff = h_children(end);
% % Sort children handles into 3xN matrix where N is the length of 
% % season_names and row 1 is good data, row 2 is moderate quality data,
% % and row 3 is bad data (no bottom)
% h_children = reshape(h_children(4:end-1),[3 length(season_names)]);
% original_marker_size = get(h_children(1),'MarkerSize');
% set(h_children,'MarkerSize',0.1);
% image_master_fn = fullfile(out_dir,sprintf('%s_All_Seasons.pdf',location));
% saveas(1,image_master_fn);
% set(h_children,'MarkerSize',original_marker_size);

return;

%% Example Code

%% User Setting

all_seasons_fn = '/cresis/scratch1/petan/coverage_maps/Antarctica_2017.fig';

%% Load figure and sort handles (copy and paste this section exactly)

h_fig = open(all_seasons_fn);
season_names = flipud(get(h_fig,'UserData'));
for season_idx = 1:length(season_names)
  season_names{season_idx} = sprintf('2017%d: %s', season_idx, season_names{season_idx});
end
h_children = get(h_fig,'Children');
h_children = get(h_children(2),'Children');
h_geotiff = h_children(end);
% Sort children handles into 3xN matrix where N is the length of 
% season_names and row 1 is good data, row 2 is moderate quality data,
% and row 3 is bad data (no bottom)
h_children = reshape(h_children(4:end-1),[3 length(season_names)]);

%% Examples of how to use

% Print the list of season names matched to index in h_children
season_names
% Turn first 10 seasons off
set(h_children(:,1:10),'Visible','off');
% Turn good data off
set(h_children(1,:),'Visible','off');
% Turn bad data off
set(h_children(3,:),'Visible','off');
% Turn everything on
set(h_children,'Visible','on');
% Change color of one season to all black
set(h_children(:,1),'Color','k');
