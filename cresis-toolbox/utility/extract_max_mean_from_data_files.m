% script extract_max_mean_from_data_files
%
% This script is intended to obtain maximum and average information of a
% given segment, radar, and mission name and write to an .csv or .mat
% output file. The script returns -1 when the surface or bottom does not
% exist in the layerData (picked values).
%
% Example:
%
% % Run the script on a data set and set out_fn to max_mean.csv. Then load
% % the file with:
%  fn = '/users/schild/extract_20111216_01.csv';
%  fid = fopen(fn,'r');
%  A = textscan(fid,'%s%f%f%f%f%f%f%f%f%f%f%f%f%f%f','delimiter',',','headerlines',1);
%  fclose(fid);
%
% % Remove records with bad information
%  good_idxs = A{11} ~= -9999 & A{15} ~= -9999;
%  for col = 1:length(A)
%    A{col} = A{col}(good_idxs);
%  end
%
% % Some basic plots:
%  plot(A{3},A{4});
%  % Signal processing toolbox, decimate (FIRDEC) command:
%  scatter(decimate(A{3}(1:end),20),decimate(A{4}(1:end),20),[],decimate(A{13}(1:end),20));
%  % Basic decimation:
%  scatter(A{3}(1:20:end),A{4}(1:20:end),[],A{13}(1:20:end));
%  % Basic decimation, this time of ice thickness:
%  scatter(A{3}(1:20:end),A{4}(1:20:end),[],(A{12}(1:20:end)-A{6}(1:20:end))*3e8/2/sqrt(3.15));
%  % Basic decimation, this time of peak vs leading edge:
%  scatter(A{3}(1:20:end),A{4}(1:20:end),[],conv(A{12}(1:20:end)-A{15}(1:20:end),ones(1,11)/11,'same')*3e8/2/sqrt(3.15));
%
% The fields of A are:
%   A{1} = 'Frame_ID'; <-- contains year, month, day, segment ID, frame ID
%   A{2} = 'GPS_Time_SOD';
%   A{3} = 'Lat_DegN';
%   A{4} = 'Lon_DegE';
%   A{5} = 'Elevation_WGS84_m';
%   A{6} = 'Surface_picked_time_us';
%   A{7} = 'Surface_peak_time_us';
%   A{8} = 'Surface_peak_dB';
%   A{9} = 'Surface_mean_dB';
%   A{10} = 'Surface_le_time_us';
%   A{11} = 'Bottom_picked_time_us';
%   A{12} = 'Bottom_peak_time_us';
%   A{13} = 'Bottom_peak_dB';
%   A{14} = 'Bottom_mean_dB';
%   A{15} = 'Bottom_le_time_us';
%
% Author: Aric Beaver, John Paden

% Done:
% Mean_max: optimize for speed, run on kuband/accum/snow data to make sure it works,
% add time for which power crosses X% of peak value (leading edge detection)

% Do:
% update layer files with improved peak information

% =============================================================
%% User settings
% =============================================================

% param_fn: string containing the path to a parameter spreadsheet file
param_fn = ct_filename_param('snow_param_2011_Greenland_P3.xls');

% echogram_type: string containing echogram type to extract information from
echogram_type = 'qlook';

% image = Data image processing type (file name prefix, e.g. "Data", "Data_img01")
fn_image = 'Data';

% Create output file name
out_fn_dir = 'CSARP_post/layerInfo';

% Output filename type ('.mat' or '.csv')
out_fn_type = '.csv';

% Layer tracking parameters
layers = [];
layers(1).name = 'Surface';
layers(1).source = 'echogram'; % ops, layerData, or echogram
layers(1).max_window = [-5 5] / (3e8/2); % relative to layer
layers(1).mean_window = [-0.5 1] / (3e8/2); % relative to layer
layers(1).leading_edge.threshold = 0.1; % percentage threshold
layers(1).leading_edge.start = -3 / (3e8/2); % start time relative to layer

% Set mean or median function calls to calculate either mean or median
ave_fh = @mean;
% ave_fh = @median;

% debug_level: set to 0 for normal operation
debug_level = 0;

% =============================================================
%% Automated section
% =============================================================

dbstack_info = dbstack;

% params = read_param_xls(param_fn);
% params = read_param_xls(param_fn,'20110322_01');
% params(1).cmd.generic = 1;
% params(1).cmd.frms = 23:84;
params = read_param_xls(param_fn,'20110317_01');
params(1).cmd.generic = 1;
params(1).cmd.frms = 14:317;

for param_idx = 1:length(params)
  param = params(param_idx);
  
  %% Is this segment selected in the param spreadsheet
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
   
  %% Create the specular surface file
  fprintf('=====================================================================\n');
  fprintf('%s: %s (%s)\n', dbstack_info(1).name, param.day_seg, datestr(now,'HH:MM:SS'));
  fprintf('=====================================================================\n');
  
  frames = frames_load(param);
  
  if isempty(param.cmd.frms)
    param.cmd.frms = 1:length(frames.frame_idxs);
  end
  % Remove frames that do not exist from param.cmd.frms list
  [valid_frms,keep_idxs] = intersect(param.cmd.frms, 1:length(frames.frame_idxs));
  if length(valid_frms) ~= length(param.cmd.frms)
    bad_mask = ones(size(param.cmd.frms));
    bad_mask(keep_idxs) = 0;
    warning('Nonexistent frames specified in param.cmd.frms (e.g. frame "%g" is invalid), removing these', ...
      param.cmd.frms(find(bad_mask,1)));
    param.cmd.frms = valid_frms;
  end
  
  data_dir = ct_filename_out(param,echogram_type,'');
  
  %% Load Layer Data
  for layer_idx = 1:length(layers)
    layer = layers(layer_idx);
    if strcmpi(layer.source,'ops')
    elseif strcmpi(layer.source,'layerData')
    elseif strcmpi(layer.source,'echogram')
      % Load layer information from each echogram
      for frm = param.cmd.frms
        layer_fn = fullfile(data_dir,sprintf('%s_%s_%03d.mat', fn_image, param.day_seg, frm));
        if frm == param.cmd.frms(1)
          tmp = load(layer_fn,'GPS_time',layer.name);
          layers(layer_idx).gps_time = tmp.GPS_time;
          layers(layer_idx).twtt = tmp.(layer.name);
        else
          tmp = load(layer_fn,'GPS_time',layer.name);
          layers(layer_idx).gps_time = cat(2,layers(layer_idx).gps_time,tmp.GPS_time);
          layers(layer_idx).twtt = cat(2,layers(layer_idx).twtt,tmp.(layer.name));
        end
      end    
    end
    layers(layer_idx).max = [];
    layers(layer_idx).max_idx = [];
  end
  
  %% Extract layer statistics for each frame
  elev = [];
  for frm = param.cmd.frms
    layer_fn = fullfile(data_dir,sprintf('%s_%s_%03d.mat', fn_image, param.day_seg, frm));
    fprintf('Loading %s\n', layer_fn)
    mdata = load(layer_fn);
    
    elev = cat(2,elev,mdata.Elevation);
    
    layer_rbin = interp1(1:length(mdata.Time), mdata.Time, ...
      interp1(layers(layer_idx).gps_time, ...
      layers(layer_idx).twtt, mdata.GPS_time));
    dt = mdata.Time(2) - mdata.Time(1);
    prebins = round(layers(layer_idx).max_window(1) / dt);
    postbins = round(layers(layer_idx).max_window(2) / dt);
    
    for layer_idx = 1:length(layers)
      for rline = 1:size(mdata.Data,2)
        rbins = max(1,layer_rbin(rline)-prebins) : min(size(mdata.Data,1),layer_rbin(rline)+postbins);
        [layers(layer_idx).max(end+1),layers(layer_idx).max_idx(end+1)] = max(mdata.Data(rbins,rline));
        layers(layer_idx).max_idx(end) = rbins(layers(layer_idx).max_idx(end));
      end
    end
  end
  
  p = polyfit(elev,lp(layers(layer_idx).max),1)
  p_elev = linspace(min(elev),max(elev),101);
  figure(1); clf;
  plot(elev,lp(layers(layer_idx).max),'.');
  hold on;
  plot(p_elev,polyval(p,p_elev),'r','LineWidth',2)
  grid on
  -diff(polyval(p,[250 500]))
  axis tight;
  title(param.day_seg,'Interpreter','none')
  xlabel('Range (m)');
  ylabel('Relative power (dB)');
  
  figure(2); clf;
  min_elev = floor(min(elev)/10)*10;
  elev_bins = min_elev : 10 : max(elev)+10;
  layer_pow = zeros(1,length(elev_bins)-1);
  layer_N = zeros(1,length(elev_bins)-1);
  for elev_idx = 1:length(elev_bins)-1
    good_mask = elev >= elev_bins(elev_idx) & elev < elev_bins(elev_idx+1);
    layer_pow(elev_idx) = mean(lp(layers(layer_idx).max(good_mask)));
    layer_N(elev_idx) = sum(good_mask);
  end
  elev_bins = elev_bins(1:end-1) + 5;
  %bar(elev_bins,layer_N)
  good_bins = layer_N > 200;
  plot(elev_bins(good_bins), layer_pow(good_bins),'x');
  
  p = polyfit(elev_bins,layer_pow,1)
  p_elev = linspace(min(elev_bins),max(elev_bins),101);
  figure(1); clf;
  plot(elev_bins,layer_pow,'x');
  hold on;
  plot(p_elev,polyval(p,p_elev),'r','LineWidth',2)
  grid on
  -diff(polyval(p,[250 500]))
  axis tight;
  title(param.day_seg,'Interpreter','none')
  xlabel('Range (m)');
  ylabel('Relative power (dB)');
  
end

return

%   % Write max and mean/median data into csv file or save as mat
%   out_fn = fullfile(out_fn_dir,sprintf('extract_%s%s',param.day_seg,out_fn_type));
%   [out_fid,msg] = fopen(out_fn,'w');
%   fprintf('  Opening output file %s\n', out_fn);
%   if out_fid < 0
%     error(msg);
%   end
%   header = {};
%   header{1} = 'Frame_ID';
%   header{2} = 'GPS_Time_SOD';
%   header{3} = 'Lat_DegN';
%   header{4} = 'Lon_DegE';
%   header{5} = 'Elevation_WGS84_m';
%   header{6} = 'Surface_picked_time_us';
%   header{7} = 'Surface_peak_time_us';
%   header{8} = 'Surface_peak_dB';
%   header{9} = 'Surface_mean_dB';
%   header{10} = 'Surface_le_time_us';
%   header{11} = 'Bottom_picked_time_us';
%   header{12} = 'Bottom_peak_time_us';
%   header{13} = 'Bottom_peak_dB';
%   header{14} = 'Bottom_mean_dB';
%   header{15} = 'Bottom_le_time_us';
%   
%   % Print the header names to the output file
%   fprintf(out_fid,'%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n',header{1},header{2},header{3},header{4},...
%     header{5},header{6},header{7},header{8},header{9},header{10},header{11},header{12},...
%     header{13},header{14});
%   
%   data_fns = get_filenames(data_dir,sprintf('%s_%s',image,param.day_seg),'','.mat');
%   for data_idx = 1:length(data_fns)
%     [data_fn_path data_fn_name] = fileparts(data_fns{data_idx});
%     if data_fn_name(6) == 'i'
%       frm_str = data_fn_name(13:27);
%     else
%       frm_str = data_fn_name(6:20);
%     end
%     if ~isempty(params(param_idx).cmd.frms)
%       % If the frames list is not empty, then we need to check if this
%       % frame is in the list. If it is not, we skip ahead.
%       frm = str2double(frm_str(end-2:end));
%       
%       if isempty(find(frm == params(param_idx).cmd.frms))
%         continue;
%       end
%     end
%     fprintf('    File %d of %d %s (%s)\n', data_idx, length(data_fns), ...
%       data_fns{data_idx}, datestr(now));
%     
%     % Load corresponding layer file
%     layer_fn = fullfile(layer_dir,sprintf('Data_%s.mat', frm_str));
%     layer = load(layer_fn);
%     
%     % Load echogram file
%     echo = load(data_fns{data_idx});
%     
%     % Obtain the layerData surface and bottom
%     Surface = layer.layerData{1}.value{2}.data;
%     Bottom = layer.layerData{2}.value{2}.data;
%     
%     % Preform linear interpolation to find correct layerData length
%     if length(layer.GPS_time) ~= length(echo.GPS_time) ...
%         || any(layer.GPS_time ~= echo.GPS_time)
%       Surface = interp1(layer.GPS_time,Surface,echo.GPS_time,'linear','extrap');
%       Bottom = interp1(layer.GPS_time,Bottom,echo.GPS_time,'linear','extrap');
%     end
%     
%     % Convert to rangebins for indexing of individual rangeline
%     dt = echo.Time(2)-echo.Time(1);
%     
%     % Find maximum and mean/median of specific rangeline on
%     surf_max_val = zeros(1,size(echo.Data,2));
%     surf_max_time = zeros(1,size(echo.Data,2));
%     surf_mean_val = zeros(1,size(echo.Data,2));
%     surf_le_time = zeros(1,size(echo.Data,2));
%     bot_max_val = zeros(1,size(echo.Data,2));
%     bot_max_time = zeros(1,size(echo.Data,2));
%     bot_mean_val = zeros(1,size(echo.Data,2));
%     bot_le_time = zeros(1,size(echo.Data,2));
%     for rline = 1:size(echo.Data,2)
%       
%       if ~isfinite(Surface(rline)) || ~isfinite(Bottom(rline))
%         continue;
%       end
%       
%       win = 1 + round(((Surface(rline) + surf_max_window)-echo.Time(1))/dt);
%       win(1) = max(1,win(1));
%       win(2) = max(1,win(2));
%       win(1) = min(size(echo.Data,1),win(1));
%       win(2) = min(size(echo.Data,1),win(2));
%       
%       [surf_max_val(rline),surf_max_idx] = max(echo.Data(win(1):win(2),rline));
%       surf_max_idx = win(1)+surf_max_idx-1;
%       surf_max_time(rline) = echo.Time(surf_max_idx);
%       win = round(((surf_max_time(rline)-surf_le_search_window)-echo.Time(1))/dt);
%       win = max(1,win);
%       win = min(size(echo.Data,1),win);
%       surf_le_idx = find(echo.Data(win:surf_max_idx-1,rline) ...
%         < echo.Data(surf_max_idx,rline)*le_percent, 1, 'last');
%       if isempty(surf_le_idx)
%         surf_le_time(rline) = -9999;
%       else
%         surf_le_idx = surf_le_idx + win - 1;
%         surf_le_time(rline) = echo.Time(surf_le_idx);
%       end
%       
%       win = 1 + round(((Surface(rline) + surf_mean_window)-echo.Time(1))/dt);
%       win(1) = max(1,win(1));
%       win(2) = max(1,win(2));
%       win(1) = min(size(echo.Data,1),win(1));
%       win(2) = min(size(echo.Data,1),win(2));
%       
%       surf_mean_val(rline) = ave_fh(echo.Data(win(1):win(2),rline));
%       
%       win = 1 + round(((Bottom(rline) + bot_max_window)-echo.Time(1))/dt);
%       win(1) = max(1,win(1));
%       win(2) = max(1,win(2));
%       win(1) = min(size(echo.Data,1),win(1));
%       win(2) = min(size(echo.Data,1),win(2));
%       
%       [bot_max_val(rline),bot_max_idx] = max(echo.Data(win(1):win(2),rline));
%       bot_max_idx = win(1)+bot_max_idx-1;
%       bot_max_time(rline) = echo.Time(bot_max_idx);
%       win = round(((bot_max_time(rline)-bot_le_search_window)-echo.Time(1))/dt);
%       win = max(1,win);
%       win = min(size(echo.Data,1),win);
%       bot_le_idx = find(echo.Data(win:bot_max_idx-1,rline) ...
%         < echo.Data(bot_max_idx,rline)*le_percent, 1, 'last');
%       if isempty(bot_le_idx)
%         bot_le_time(rline) = -9999;
%       else
%         bot_le_idx = bot_le_idx + win - 1;
%         bot_le_time(rline) = echo.Time(bot_le_idx);
%       end
%       
%       win = 1 + round(((Bottom(rline) + bot_mean_window)-echo.Time(1))/dt);
%       win(1) = max(1,win(1));
%       win(2) = max(1,win(2));
%       win(1) = min(size(echo.Data,1),win(1));
%       win(2) = min(size(echo.Data,1),win(2));
%       
%       bot_mean_val(rline) = ave_fh(echo.Data(win(1):win(2),rline));
%       
%       % header{1} = 'Frame_ID';
%       % header{2} = 'GPS_Time_SOD';
%       % header{3} = 'Lat_DegN';
%       % header{4} = 'Lon_DegE';
%       % header{5} = 'Elevation_WGS84_m';
%       % header{6} = 'Surface_picked_time_us';
%       % header{7} = 'Surface_peak_time_us';
%       % header{8} = 'Surface_peak_dB';
%       % header{9} = 'Surface_mean_dB';
%       % header{10} = 'Surface_le_time_us';
%       % header{11} = 'Bottom_picked_time_us';
%       % header{12} = 'Bottom_peak_time_us';
%       % header{13} = 'Bottom_peak_dB';
%       % header{14} = 'Bottom_mean_dB';
%       % header{15} = 'Bottom_le_time_us';
%       fprintf(out_fid,'%s,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n', ...
%         frm_str,echo.GPS_time(rline), ...
%         echo.Latitude(rline),echo.Longitude(rline),echo.Elevation(rline), ...
%         Surface(rline)*1e6,surf_max_time(rline)*1e6,10*log10(surf_max_val(rline)), ...
%         10*log10(surf_mean_val(rline)),surf_le_time(rline)*1e6, ...
%         Bottom(rline)*1e6,bot_max_time(rline)*1e6,10*log10(bot_max_val(rline)), ...
%         10*log10(bot_mean_val(rline)),bot_le_time(rline)*1e6);
%       
%     end
%     % fprintf('      %i of %i records no surface leading edge\n', ...
%     %   sum(surf_le_time == -9999), length(surf_le_time));
%     fprintf('      %i of %i records no bottom leading edge\n', ...
%       sum(bot_le_time == -9999), length(bot_le_time));
%     if debug_level > 0
%       figure(1); clf;
%       imagesc([],echo.Time*1e6,lp(echo.Data))
%       hold on;
%       plot(Surface*1e6);
%       plot(surf_max_time*1e6,'k');
%       surf_le_time(surf_le_time == -9999) = NaN;
%       plot(surf_le_time*1e6,'g');
%       plot(Bottom*1e6);
%       plot(bot_max_time*1e6,'k');
%       bot_le_time(bot_le_time == -9999) = NaN;
%       plot(bot_le_time*1e6,'g');
%       hold off;
%       xlabel('range line');
%       ylabel('time (us)');
%       figure(2); clf;
%       plot(10*log10(surf_max_val),'r');
%       hold on;
%       plot(10*log10(surf_mean_val),'r');
%       plot(10*log10(bot_max_val),'k');
%       plot(10*log10(bot_mean_val),'k');
%       hold off;
%       grid on;
%       xlabel('range line');
%       ylabel('relative power (dB)');
%       keyboard
%     end
%   end
%   fclose(out_fid);
% end

return;
