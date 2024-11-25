function fname = fname_info_utig(fn)
% fname = fname_info_utig(fn)
%
% Detects the type of utig filename and then parses it.
%
% fn: string containing utig radar file name
%
% fname: structure containing each of the fields of the UTIG filename with
% format RADARNAME_DATETIME-FILENUMBER.dat. For example:
% radar0_20230116-200145-0032.dat.
%
%  .radar_name: RADARNAME field 'radar0'
%
%  .datenum: YYYYMMDD-HHMMSS time stamp converted to Matlab date number.
%  Common usage: "[year month day hour min sec] = datevec(fname.datenum)"
%
%  .file_idx: FILENUMBER field 32
%
% Example
%  fn = 'data/UTIG/orig/xped/CXA1/acqn/MARFA/F13/radar0_20230116-200145-0032.dat';
%  fname = fname_info_utig(fn)
%
% Author: John Paden
%
% See also datenum

[fn_dir,fn_name,fn_ext] = fileparts(fn);

fname = [];

[fname.radar_name fn_name] = strtok(fn_name,'_');

[date_str fn_name] = strtok(fn_name,'-');
[time_str fn_name] = strtok(fn_name,'-');
fname.datenum = datenum([date_str(2:end) time_str],'yyyymmddHHMMSS');

fname.file_idx = str2double(fn_name(2:end));
