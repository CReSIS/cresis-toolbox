function status = write_garmin_fpl(fn, fline)
% status = write_garmin_fpl(fn, fline)
%
% fn = filename to write out to. If there are too many waypoints
%   to fit into a single file (MAX_WAYPOINTS variable), then
%   multiple files are written with "_M" appended to fn where M
%   is the file number. If this happens, there is one overlapping
%   waypoint added to each file. For example, with MAX_WAYPOINTS
%   equal to 30 and an input with 35 waypoints, you will get two
%   files. The first file will have waypoints 1-30 and the next
%   file will have waypoints 30-35.
% fline = struct array with flight line information
%  .lat = N x 1 double vector of latitudes (degrees, positive is north)
%  .lon = N x 1 double vector of longitudes (degrees, positive is east)
%  .wpnt_names = N x 1 cell vector of way point char arrays
%
% status = return 1 on success and 0 on failure
%
% Author: John Paden

MAX_WAYPOINTS = 30;

status = 0;

%% Remove bad characters (not sure what these are, so being conservative)
% 1. Alphanumeric (and remove '_' characters)
% 2. Not longer than 5 characters
% 3. All upper case%
for wpnt_idx = 1:length(fline.lat)
  fline.wpnt_names{wpnt_idx} ...
    = fline.wpnt_names{wpnt_idx}(...
    isstrprop(fline.wpnt_names{wpnt_idx},'alphanum') ...
    & fline.wpnt_names{wpnt_idx} ~= '_');
  
  fline.wpnt_names{wpnt_idx} ...
    = upper(fline.wpnt_names{wpnt_idx}(1:min(5,length(fline.wpnt_names{wpnt_idx}))));
end

%% Check for any duplicates that don't have matching lat/lon
for wpnt_idx = 1:length(fline.lat)
  match_idxs = find(strcmp(fline.wpnt_names{wpnt_idx}, fline.wpnt_names));
  for match_idx = match_idxs(:).'
    if fline.lat(match_idx) ~= fline.lat(wpnt_idx) ...
        || fline.lon(match_idx) ~= fline.lon(wpnt_idx)
      warning('No Garmin flight plan written because duplicate way points exist with nonmatching coordinates: %s', fline.wpnt_names{wpnt_idx});
      return;
    end
  end
end

%% Determine how many files we have to use to get all the
% waypoints written.
num_files = ceil( (length(fline.lat) - 1)/(MAX_WAYPOINTS-1) );

%% Write the files out
[fn_dir fn_name fn_ext] = fileparts(fn);
orig_fline = fline;
for file_num = 1:num_files
  if num_files > 1
    fn_out = fullfile(fn_dir,sprintf('%s_%d%s', fn_name, file_num, fn_ext));
  else
    fn_out = fn;
  end
  
  if file_num < num_files
    fline.lat = orig_fline.lat((file_num-1)*(MAX_WAYPOINTS-1) + (1:MAX_WAYPOINTS));
    fline.lon = orig_fline.lon((file_num-1)*(MAX_WAYPOINTS-1) + (1:MAX_WAYPOINTS));
    fline.wpnt_names = orig_fline.wpnt_names((file_num-1)*(MAX_WAYPOINTS-1) + (1:MAX_WAYPOINTS));
  else
    fline.lat = orig_fline.lat((file_num-1)*(MAX_WAYPOINTS-1) + 1 : end);
    fline.lon = orig_fline.lon((file_num-1)*(MAX_WAYPOINTS-1) + 1 : end);
    fline.wpnt_names = orig_fline.wpnt_names((file_num-1)*(MAX_WAYPOINTS-1) + 1 : end);
  end
  
  [fid,msg] = fopen(fn_out,'w');
  if fid<0
    warning('Failed to open %s: %s', fn_out, msg);
    return;
  end
  
  %% Write header to file
  fprintf(fid, '<?xml version="1.0" encoding="utf-8"?>\r\n');
  fprintf(fid, '<flight-plan xmlns="http://www8.garmin.com/xmlschemas/FlightPlan/v1">\r\n');
  fprintf(fid, '  <created>%s</created>\r\n', datestr(now, 'YYYY-mm-DDTHH:MM:SSZ'));
  
  %% Write way points to file
  [~,unique_idxs] = unique(fline.wpnt_names);
  fprintf(fid, '  <waypoint-table>\r\n');
  for wpnt_idx = unique_idxs'
    fprintf(fid, '    <waypoint>\r\n');
    fprintf(fid, '      <identifier>%s</identifier>\r\n', fline.wpnt_names{wpnt_idx});
    fprintf(fid, '      <type>USER WAYPOINT</type>\r\n');
    fprintf(fid, '      <country-code></country-code>\r\n');
    fprintf(fid, '      <lat>%.6f</lat>\r\n', fline.lat(wpnt_idx));
    fprintf(fid, '      <lon>%.7f</lon>\r\n', fline.lon(wpnt_idx));
    fprintf(fid, '      <comment></comment>\r\n');
    fprintf(fid, '    </waypoint>\r\n');
  end
  fprintf(fid, '  </waypoint-table>\r\n\r\n');
  
  %% Write route to file
  fprintf(fid, '  <route>\r\n');
  fprintf(fid, '    <route-name>%s/%s</route-name>\r\n', fline.wpnt_names{1}, fline.wpnt_names{end});
  fprintf(fid, '    <route-description>Generated with vector_editor.m</route-description>\r\n');
  fprintf(fid, '    <flight-plan-index>1</flight-plan-index>\r\n');
  
  for wpnt_idx = 1:length(fline.lat)
    fprintf(fid, '    <route-point>\r\n');
    fprintf(fid, '      <waypoint-identifier>%s</waypoint-identifier>\r\n', fline.wpnt_names{wpnt_idx});
    fprintf(fid, '      <waypoint-type>USER WAYPOINT</waypoint-type>\r\n');
    fprintf(fid, '      <waypoint-country-code></waypoint-country-code>\r\n');
    fprintf(fid, '    </route-point>\r\n');
  end
  fprintf(fid, '  </route>\r\n');
  
  %% Write footer and close file
  fprintf(fid, '</flight-plan>\r\n');
  fclose(fid);
end

status = 1;

return;
