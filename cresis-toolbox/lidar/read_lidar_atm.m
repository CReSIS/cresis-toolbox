function lidar = read_lidar_atm(atm_fns, param)
% lidar = read_lidar_atm(atm_fns, param)
%
% Read's ATM ICESSN data. Need to look at the specific data product
% to know if time reference is GPS or UTC.
% Currently function only grabs the nadir track (track 0).
%
% Command to download data. URL may need to be updated by browsing to the ILATM2.002 (L2 version 2) data at NSIDC via a web client:
% wget --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --keep-session-cookies --no-check-certificate --auth-no-challenge=on -r --reject "index.html*" -np --cut-dirs=2 -nH -e robots=off -A "ILATM2_2017*.csv" https://n5eil01u.ecs.nsidc.org/ICEBRIDGE/ILATM2.002/
%
% atm_fns = filename(s) of ATM output
% param = struct that controls reading of file(s)
%   THIS STRUCTURE IS NOT NECESSARY WITH CONFORMING FILENAMES.
%  .year, .month, .day: Since ATM LIDAR files only give seconds of day,
%     you have to provide the year, month, and day to get the absolute time.
%     If year/month/day are scalar fields, then the same value is used for
%     all files. If the year/month/day fields are vectors, then they should
%     be equal length and synchronized to atm_fns. This would be required
%     if you are reading data from different days.
%  .time_reference = 'gps' or 'utc'
%  .file_type =
%    legacy: uses spaces column widths to load the file
%    fixed_width: uses fixed column widths to load the file
%    csv: CSV file (UTC_time)
%
% lidar = struct of position and LIDAR data, each N x 1 vectors
%   where N is the number of records in the file(s). The fields are:
%  .gps_time = GPS time in seconds since Jan 1, 1970 epoch (sec)
%  .lat = latitude (deg)
%  .lon = longitude (deg)
%  .surface = WGS-84 surface elevation (m)
%  .slope_sn
%  .slope_we
%  .rms
%  .num_pnts_used
%  .num_pnts_edited
%  .cross_track
%  .track
%
% LEGACY FORMAT (BLATM2_ATMicessn_v01):
%  THIS FORMAT PROBABLY NEVER EXISTED... ALWAYS USE FIXED_WIDTH
%  No header, space delimited
%  Probably GPS time reference?
%  Conforming Filename: 930701_142937_smooth_nadir2seg
%    990512_113049_smooth_nadir3seg
%    080702_151348_smooth_nadir5seg_50pt
%    021204_184856_smooth_nadir3seg_50pt
%    081021_154946_smooth_nadir3seg_50pt
%    YYMMDD_HHMMSS_smooth_nadirNseg{'','_50pt'} [no extension]
%  64671.8466  68.748998 309.996398  669.8909  -.01721733  -.01291356  102.08   923    0 -294. 5
% 
%
% FIXED_WIDTH FORMAT (ILATM2.001):
%  No header, fixed width fields... very similar to legacy, but sometimes
%    fields are not space delimited and use the full width.
%  Probably GPS time reference?
%  Conforming Filename: ILATM2_20110331_180518_50pt_smooth_nadir3seg
%    ILATM2_YYYYMMDD_HHMMSS_50pt_smooth_nadirNseg [no extension]
%  Word 1:  Time at which the aircraft passed the mid-point of the block
%           (in seconds of the day)
%  Word 2:  Latitude of the center of the block in degrees
%  Word 3:  East longitude of the center of the block in degrees
%  Word 4:  Ellipsoid height (WGS84 ellipsoid) of the center of the block
%  Word 5:  South to North slope of the block (dimensionless)
%  Word 6:  West to East slope of the block (dimensionless)
%  Word 7:  RMS fit of the ATM data to the plane (in centimeters)
%  Word 8:  Number of points used in estimating the plane parameters
%  Word 9:  Number of points edited in estimating the plane parameters
%  Word 10: Distance of the center of the block from the centerline of the
%           aircraft trajectory (in meters)
%  Word 11: track identifier (numbered 1..n, starboard to port, and 0=nadir)
%
%  74240.0634 -75.260868 256.371582   307.6313  -.0061347   .0109315    5.92   387    5     0. 0
%  74240.3134 -75.261474 256.373201   308.5355  -.0068481   .0106596    6.64   831    2    76. 1
%
% CSV FILE EXAMPLE (ILATM2.002):
%  10 header lines, comma separated variable
%  Probably UTC time reference since field column header indicates this
%  Conforming Filename: ILATM2_20130323_215400_smooth_nadir3seg_50pt.csv
%    ILATM2_YYYYMMDD_HHMMSS_smooth_nadirNseg_50pt.csv
%  columns: UTC_Seconds_Of_Day, Latitude(deg), Longitude(deg), WGS84_Ellipsoid_Height(m), South-to-North_Slope, West-to-East_Slope, RMS_Fit(cm), Number_Of_ATM_Measurments_Used, Number_Of_ATM_Measurements_Removed, Distance_Of_Block_To_The_Right_Of_Aircraft(m), Track_Identifier
%  49253.50, 82.484971, 301.921331, 18.4593, 0.0041041, 0.0029945, 21.68, 260, 3, 386, 1
%
% Example: See bottom of file
%
% Author: John Paden
%
% See also get_filenames_atm.m, plot_lidar.m

if ~exist('param','var')
  param = struct();
end

if ischar(atm_fns)
  atm_fns = {atm_fns};
end

lidar.gps_time = [];
lidar.lat = [];
lidar.lon = [];
lidar.surface = [];
lidar.slope_sn = [];
lidar.slope_we = [];
lidar.rms = [];
lidar.num_pnts_used = [];
lidar.num_pnts_edited = [];
lidar.cross_track = [];
lidar.track = [];
for file_idx = 1:length(atm_fns)
  atm_fn = atm_fns{file_idx};

  try
    %% Use file name to determine date, time reference and file type
    [atm_fn_dir,atm_fn_name atm_fn_ext] = fileparts(atm_fn);
    if strcmpi(atm_fn_ext,'.csv')
      % ILATM2_YYYYMMDD_HHMMSS_smooth_nadirNseg_50pt.csv
      file_type = 'csv';
      time_reference = 'utc';
      year = str2double(atm_fn_name(8:11));
      month = str2double(atm_fn_name(12:13));
      day = str2double(atm_fn_name(14:15));
    elseif strcmp(atm_fn_name(1:6),'ILATM2')
      % ILATM2_YYYYMMDD_HHMMSS_50pt_smooth_nadirNseg [no extension]
      file_type = 'fixed_width';
      time_reference = 'gps';
      year = str2double(atm_fn_name(8:11));
      month = str2double(atm_fn_name(12:13));
      day = str2double(atm_fn_name(14:15));
    else
      % YYMMDD_HHMMSS_smooth_nadirNseg{'','_50pt'} [no extension]
      file_type = 'fixed_width';
      time_reference = 'gps';
      year = str2double(atm_fn_name(1:2));
      if year > 90
        year = year + 1900;
      else
        year = year + 2000;
      end
      month = str2double(atm_fn_name(3:4));
      day = str2double(atm_fn_name(5:6));
    end
  catch ME
    fprintf('This should not happen unless you are using an uncomforming filename\n');
    fprintf('in which case "dbcont" and make sure you specify file_type,\n');
    fprintf('time_reference, and date manually using "param" input.\n');
    ME.get_report
    keyboard;
  end

  %% Check for user override parameters
  if isfield(param,'file_type') && ~isempty(param.file_type)
    file_type = param.file_type;
  end
  if isfield(param,'time_reference') && ~isempty(param.time_reference)
    time_reference = param.time_reference;
  end
  if isfield(param,'year') && ~isempty(param.year)
    if length(param.year) > 1
      year = param.year(file_idx);
    else
      year = param.year;
    end
  end
  if isfield(param,'month') && ~isempty(param.month)
    if length(param.month) > 1
      month = param.month(file_idx);
    else
      month = param.month;
    end
  end
  if isfield(param,'day') && ~isempty(param.day)
    if length(param.day) > 1
      day = param.day(file_idx);
    else
      day = param.day;
    end
  end
  
  %% Read in file
  if strcmpi(file_type,'legacy')
    %% Use the "LEGACY" Read Method
    % =====================================================================
    raw = load(atm_fn);
    if ~isempty(raw)
      % Only grab the nadir data (track 0)
      raw = raw(raw(:,11) == 0,:);
      
      gps_time = datenum(year,month,day,0,0,raw(:,1));
      gps_time = datenum_to_epoch(gps_time);
      
      if strcmpi(time_reference,'utc')
        % UTC time stored in file, so need to add leap seconds back in
        gps_time = gps_time + utc_leap_seconds(gps_time(1));
        warning('UTC time reference specified, but files are usually GPS time reference');
      elseif strcmpi(time_reference,'gps')
      else
        error('Invalid time reference');
      end
      
      lidar.gps_time = [lidar.gps_time gps_time.'];
      lidar.lat = [lidar.lat raw(:,2).'];
      lidar.lon = [lidar.lon raw(:,3).'];
      lidar.surface = [lidar.surface raw(:,4).'];
      lidar.slope_sn = [lidar.slope_sn raw(:,5).'];
      lidar.slope_we = [lidar.slope_we raw(:,6).'];
      lidar.rms = [lidar.rms raw(:,7).'];
      lidar.num_pnts_used = [lidar.num_pnts_used raw(:,8).'];
      lidar.num_pnts_edited = [lidar.num_pnts_edited raw(:,9).'];
      lidar.cross_track = [lidar.cross_track raw(:,10).'];
      lidar.track = [lidar.track raw(:,11).'];
    end
    
  elseif strcmpi(file_type,'fixed_width')
    %% Use the "FIXED_WIDTH" Read Method
    % =====================================================================
    fid = fopen(atm_fn);
    A = textscan(fid,'%11f%11f%11f%10f%12f%12f%8f%6f%5f%6f%f');
    fclose(fid);
    % Some files are empty so skip these
    if ~isempty(A) && ~isempty(A{1})
      % Only grab the nadir data (track 0)
      nadir_idxs = A{:,11} == 0;
      for cell_idx = 1:length(A)
        A{:,cell_idx} = A{:,cell_idx}(nadir_idxs);
      end
      % Read only one year/month/day or multiple.
      gps_time = datenum(year,month,day,0,0,A{:,1});
      gps_time = datenum_to_epoch(gps_time);
      
      if strcmpi(time_reference,'utc')
        % UTC time stored in file, so need to add leap seconds back in
        gps_time = gps_time + utc_leap_seconds(gps_time(1));
        warning('UTC time reference specified, but files are usually GPS time reference');
      elseif strcmpi(time_reference,'gps')
      else
        error('Invalid time reference');
      end
      
      lidar.gps_time = [lidar.gps_time gps_time.'];
      lidar.lat = [lidar.lat A{:,2}.'];
      lidar.lon = [lidar.lon A{:,3}.'];
      lidar.surface = [lidar.surface A{:,4}.'];
      lidar.slope_sn = [lidar.slope_sn A{:,5}.'];
      lidar.slope_we = [lidar.slope_we A{:,6}.'];
      lidar.rms = [lidar.rms A{:,7}.'];
      lidar.num_pnts_used = [lidar.num_pnts_used A{:,8}.'];
      lidar.num_pnts_edited = [lidar.num_pnts_edited A{:,9}.'];
      lidar.cross_track = [lidar.cross_track A{:,10}.'];
      lidar.track = [lidar.track A{:,11}.'];
    end
    
  elseif strcmpi(file_type,'csv')
    %% Use the "CSV" Read Method
    % =====================================================================
    %  Skip header lines first, and then read data
    fid = fopen(atm_fn);
    while ~feof(fid)
      hdline = fgetl(fid);
      if strfind(hdline,'UTC_Seconds_Of_Day')
        break
      end
    end
    A = textscan(fid,'%f%f%f%f%f%f%f%f%f%f%f', 'Delimiter',',');    
    fclose(fid);

    % Some files are empty so skip these
    if ~isempty(A) && ~isempty(A{1})
      % Only grab the nadir data (track 0)
      nadir_idxs = A{:,11} == 0;
      if any(nadir_idxs)
        for cell_idx = 1:length(A)
          A{:,cell_idx} = A{:,cell_idx}(nadir_idxs);
        end
        % Read only one year/month/day or multiple.
        gps_time = datenum(year,month,day,0,0,A{:,1});
        gps_time = datenum_to_epoch(gps_time);
        
        if strcmpi(time_reference,'utc')
          % UTC time stored in file, so need to add leap seconds back in
          gps_time = gps_time + utc_leap_seconds(gps_time(1));
        elseif strcmpi(time_reference,'gps')
          warning('GPS time reference specified, but files are usually UTC time reference');
        else
          error('Invalid time reference');
        end
        
        lidar.gps_time = [lidar.gps_time gps_time.'];
        lidar.lat = [lidar.lat A{:,2}.'];
        lidar.lon = [lidar.lon A{:,3}.'];
        lidar.surface = [lidar.surface A{:,4}.'];
        lidar.slope_sn = [lidar.slope_sn A{:,5}.'];
        lidar.slope_we = [lidar.slope_we A{:,6}.'];
        lidar.rms = [lidar.rms A{:,7}.'];
        lidar.num_pnts_used = [lidar.num_pnts_used A{:,8}.'];
        lidar.num_pnts_edited = [lidar.num_pnts_edited A{:,9}.'];
        lidar.cross_track = [lidar.cross_track A{:,10}.'];
        lidar.track = [lidar.track A{:,11}.'];
      end
    end
  end
end

lidar.lon = mod(lidar.lon+180,360) - 180;

return;

% Single file example (legacy)
atm_fns = '/cresis/snfs1/dataproducts/metadata/ATM_smooth_nadir/BLATM2_ATMicessn_v01/2004_AN_NASA/20041121/041121_200621_smooth_nadir3seg_50pt';
lidar = read_lidar_atm(atm_fns);
plot_lidar(lidar);
% Parameter override
lidar = read_lidar_atm(atm_fns,struct('year',2004,'month',11,'day',21));
plot_lidar(lidar);

% Multiple file example (legacy)
atm_fns = get_filenames_atm('antarctic','20081021');
lidar = read_lidar_atm(atm_fns);
plot_lidar(lidar);

% Multiple file example (fixed_width)
atm_fns = get_filenames_atm('arctic','20090406');
lidar = read_lidar_atm(atm_fns);
plot_lidar(lidar);

% Multiple file example (csv)
atm_fns = get_filenames_atm('arctic','20130323');
lidar = read_lidar_atm(atm_fns);
plot_lidar(lidar);

% Comparison to radar surface from records file
atm_fns = get_filenames_atm('arctic','20130323');
lidar = read_lidar_atm(atm_fns);
records_fn = ct_filename_support(struct('season_name','2013_Greenland_P3','radar_name','snow3','day_seg','20130323_01'),'','records');
plot_lidar(lidar,records_fn);
