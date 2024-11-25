% script coverage_maps_from_gps_or_records
%
% Example:
%  coverage_maps_from_gps_or_records % after modifying user settings
%  saveas(fig_h,'my_map.jpg')
%  % Add some other graphics
%  fid = fopen(ct_filename_gis([],'antarctica\GroundingLine\InSAR_Ant_GroundingLine\InSAR_GL_Antarctica.txt'));
%  GL = textscan(fid,'%f%f%*s%*s%*s%*s%*s%*s%*s%*s%*s');
%  fclose(fid);
%  [x,y] = projfwd(proj,GL{1},GL{2});
%  hold on;
%  plot(x/1e3,y/1e3,'k.');
%
% Author: John Paden

global gRadar
%% User Settings

% fig_h = figure handle to use for plotting
fig_h = 1;

% dt = time spacing (sec) between each plotted point
dt = 1;

% data_source: string 'gps' or 'records' (which files in csarp_support to use)
data_source = 'records';

% South Dakota
% geotiff_fn = ct_filename_gis(gRadar,fullfile('SouthDakota','Model_Landsat_UTM.tif'));
% axis_limits = [567         622        4856        4907];

% Greenland
% geotiff_fn = ct_filename_gis(gRadar,fullfile('arctic','NaturalEarth_Data','Arctic_NaturalEarth.tif')); % (use for OIB coverage maps)
% geotiff_fn = ct_filename_gis(gRadar,fullfile('arctic','Landsat-7','arctic_natural_90m.tif'));
% geotiff_fn = ct_filename_gis(gRadar,fullfile('greenland','Landsat-7','Greenland_natural.tif'));
% geotiff_fn = ct_filename_gis(gRadar,fullfile('canada','Landsat-7','Canada_90m.tif'));
% axis_limits = [-2300 1000 -3500 1500]; % All of Arctic (use for OIB coverage maps)

% Antarctica
geotiff_fn = ct_filename_gis(gRadar,fullfile('antarctica','NaturalEarth_Data','Antarctica_NaturalEarth.tif')); % (use for OIB coverage maps)
axis_limits = [-3000 1000 -1500 2500]; % All of Antarctica (use for OIB coverage maps)
% axis_limits = [808 873 996 1060]; % 2018 Antarctica Ground

% Cell vector of param spreadsheet filenames
param_fns = {'rds_param_2018_Antarctica_Ground.xls'};
% run_all

% plot_args: cell array of argument to plot function (e.g. 'b.' for blue dots)
% plot_args = {'LineWidth',2,'Color','black'};
plot_args = {'LineWidth',2};

% along_track_sampling: desired along track sampling of plot (m)
along_track_sampling = 100;

% label: Add text labels to the plots for specific frames
%  .day_seg: cell list of day segments to match
%  .frm: equal length cell vector to .day_seg with specific frames to label
%  .text: equal length cell vector to .day_seg with string for text label
label = [];
% label.day_seg = {'20140325_07','20140401_03','20140506_01','20140325_07'};
% label.frm = {1,1,1,2};
% label.text = {'20140325\_07','20140401\_03','20140506\_01','20140325\_07\_002'};
% label.first_point_only = {true,true,true,false};
% label.day_seg = {'20091102_02','20091016_01','20091016_01','20091102_02','20091102_02'};
% label.frm = {8, 21, 26, 23, 32};
% label.text = {' 1',' 2',' 3',' 4',' 5'};
% label.first_point_only = {false,false,false,false,false};

% figure_position: Set figure Position property (leave empty to use default/current figure size)
figure_position = [];
% figure_position = [221   -60   654   704];

%% Automated Section
figure(fig_h); clf;
if exist(figure_position,'var') && ~isempty(figure_position)
  set(fig_h,'Position',figure_position);
end
proj = geotiff_plot(geotiff_fn,[],[],fig_h);
axis normal; axis equal;
if ~isempty(axis_limits)
  axis(axis_limits);
end
xlabel('X (km)');
ylabel('Y (km)');

label.h_text = [];
for param_fn_idx = 1:length(param_fns)
  param_fn = param_fns{param_fn_idx};
  fprintf('Parameters %s\n', param_fn);
  
  params = read_param_xls(ct_filename_param(param_fn));
  
  if 0
    % Specify segments
    params = ct_set_params(params,'cmd.generic',1,'day_seg','20140325_07|20140401_03|20140506_01');
  end
  
  yyyymmdd_list = {};
  for param_idx = 1:length(params)
    param = params(param_idx);
    
    param.yyyymmdd = param.day_seg(1:8);
    if strcmp(data_source,'gps') && any(strcmp(param.yyyymmdd,yyyymmdd_list))
      % Already done this segment
      continue;
    end
  
    if 0
      % Only plot specific segments
      if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
        continue;
      end
    end
    
    if isempty(regexpi(param.cmd.notes,'do not process'))
      yyyymmdd_list{end+1} = param.yyyymmdd;
      if strcmp(data_source,'gps')
        gps_fn = ct_filename_support(param,[],'gps',1);
        %fprintf('  Processing %s: %s (%s)\n', param.day_seg, gps_fn, datestr(now,'HH:MM:SS'));
        if ~exist(gps_fn)
          fprintf('%s\t0\tMissing\n', param.day_seg(1:8));
          continue;
        else
          gps = load(gps_fn,'gps_time','lat','lon');
          along_track = geodetic_to_along_track(gps.lat,gps.lon);
          fprintf('%s\t%g\t\n', param.day_seg, along_track(end));
        end
      elseif strcmp(data_source,'records')
        records_fn = ct_filename_support(param,[],'records');
        if ~exist(records_fn,'file')
          fprintf('%s\t0\tMissing\n', param.day_seg);
          continue;
        end
        
        % Load frames file
        frames = frames_load(param);
        param.cmd.frms = frames_param_cmd_frms(param,frames);
        
        %fprintf('  Processing %s: %s (%s)\n', param.day_seg, records_fn, datestr(now,'HH:MM:SS'));
        gps = load(records_fn,'gps_time','lat','lon');
        along_track = geodetic_to_along_track(gps.lat,gps.lon);
        fprintf('%s\t%g\t\n', param.day_seg, along_track(end));
      end

      if strcmp(data_source,'gps')
        % Force GPS time to be monotonic (only necessary for corrupt GPS data)
        idxs = logical(zeros(size(gps.gps_time)));
        idxs(1) = 1;
        cur_time = gps.gps_time(1);
        for idx = 2:length(gps.gps_time)
          if gps.gps_time(idx) > cur_time + dt
            idxs(idx) = true;
            cur_time = gps.gps_time(idx);
          end
        end
        
        % Plot
        [x,y] = projfwd(proj,gps.lat(idxs),gps.lon(idxs));
        hold on;
        h = plot(x/1e3,y/1e3,plot_args{:},'UserData',param.day_seg);
        drawnow;
        hold off;
        
      elseif strcmp(data_source,'records')
        lat = NaN*zeros(size(gps.lat));
        for frm = param.cmd.frms
          first_idx = frames.frame_idxs(frm);
          if frm ~= length(frames.frame_idxs)
            last_idx = frames.frame_idxs(frm+1)-1;
          else
            last_idx = length(gps.gps_time);
          end
          lat(first_idx:last_idx) = gps.lat(first_idx:last_idx);
        end
        
        along_track = geodetic_to_along_track(gps.lat,gps.lon);
        decim_idxs = get_equal_alongtrack_spacing_idxs(along_track,along_track_sampling);
        
        [x,y] = projfwd(proj,lat(decim_idxs),gps.lon(decim_idxs));
        hold on;
        h = plot(x/1e3,y/1e3,plot_args{:},'UserData',param.day_seg);
        drawnow;
        
        if isfield(label,'day_seg')
          match_idxs = find(strcmpi(param.day_seg,label.day_seg(:).'));
          for match_idx = match_idxs
            for frm = label.frm{match_idx}
              first_idx = frames.frame_idxs(frm);
              [x_first,y_first] = projfwd(proj,gps.lat(first_idx),gps.lon(first_idx));
              if label.first_point_only{match_idx}
                % Just the first point of the frame in black
                label.h_plot(match_idx) = plot(x_first/1e3,y_first/1e3,'.','MarkerSize',12,'Color','Black');
              else
                % Whole frame in black
                if frm == length(frames.frame_idxs)
                  last_idx = frames.Nx;
                else
                  last_idx = frames.frame_idxs(frm+1);
                end
                along_track = geodetic_to_along_track(gps.lat(first_idx:last_idx),gps.lon(first_idx:last_idx));
                decim_idxs = get_equal_alongtrack_spacing_idxs(along_track,along_track_sampling);
                [x,y] = projfwd(proj,gps.lat(decim_idxs+first_idx-1),gps.lon(decim_idxs+first_idx-1));
                label.h_plot(match_idx) = plot(x/1e3,y/1e3,'.','MarkerSize',12,'Color','Black');
              end
              label.h_text(match_idx) = text(x_first/1e3,y_first/1e3,label.text{match_idx},'Color','black','FontWeight','bold','FontSize',14);
            end
          end
        end
        
      end
    end
    
  end
  
end

if isfield(label,'day_seg')
  uistack(label.h_text,'top');
  uistack(label.h_plot,'top');
end

return

%% Below are common steps to customize the figure
axis normal;
axis_limits = [-3190        -428       -1284        1478];
axis(axis_limits);
axis equal;
axis([-2562        -950       -1615        1893]);

pos = get(label.h_text(2),'Position');
set(label.h_text(2),'Position',pos+[-50 75 0]);

pos = get(label.h_text(3),'Position');
set(label.h_text(3),'Position',pos-[10 40 0]);

pos = get(label.h_text(5),'Position');
set(label.h_text(5),'Position',pos-[-15 -25 0]);

h_children = get(gca,'Children');
h_img = h_children(end);
clip_and_resample_image(h_img,gca,10);


