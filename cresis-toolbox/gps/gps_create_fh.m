function gps_fh = gps_create_fh(cur_file_type)
% gps_fh = gps_create_fh(cur_file_type)
%
% Support function for gps_create.m
%
% Author: John Paden

%% Determine which function to use to load the GPS file
switch (lower(cur_file_type))
  case 'applanix'
    gps_fh = @read_gps_applanix;
  case 'arena'
    gps_fh = @read_gps_arena;
  case 'arena_cpu_time'
    gps_fh = @read_gps_arena_cpu_time;
  case 'awi_netcdf'
    gps_fh = @read_gps_netcdf;
  case 'cresis'
    gps_fh = @read_gps_cresis;
  case 'dmsraw'
    gps_fh = @read_gps_dmsraw;
  case 'general_ascii'
    gps_fh = @read_gps_general_ascii;
  case 'litton'
    gps_fh = @read_ins_litton;
  case 'litton_dgps'
    gps_fh = @read_gps_litton;
  case 'nmea'
    gps_fh = @read_gps_nmea;
  case 'novatel'
    gps_fh = @read_gps_novatel;
  case 'novatel_rpygga'
    gps_fh = @read_gps_novatel_rpygga;
  case 'traj'
    gps_fh = @read_gps_traj;
  case 'txt'
    gps_fh = @read_gps_txt;
  case 'csv'
    gps_fh = @read_gps_csv;
  case 'novatelraw'
    gps_fh = @read_gps_novatelraw;
  case 'utig'
    gps_fh = @read_gps_utig;
  otherwise
    error('Unrecognized GPS file type %s', cur_file_type);
end

