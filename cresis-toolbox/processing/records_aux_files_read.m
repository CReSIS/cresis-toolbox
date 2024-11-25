function [records] = records_aux_files_read(records_fn,recs)
% DEPRECATED
%
% [records] = records_aux_files_read(records_fn,recs)
% 
% Reads specific fields out of the auxilliary netcdf file for processing.
% The netcdf file is used because subsets of variables can be loaded.
%
% recs = 2x1 vector [start record, stop record]
%   Set stop record to inf to read to end of file
%   "inf" can be used for start or stop record to mean last record
%
% Examples:
%  records_fn = '/cresis/projects/dev/csarp_support/records/kuband2/2012_Greenland_P3/records_20120421_01.mat';
%  records = records_aux_files_read(records_fn,[1 4000]);
%  check = load(records_fn);
%
% Author: John Paden
%
% See also: records_aux_files_create, records_aux_files_read,
% records_create_sync

error('This function is deprecated. Use records_load.m instead because NetCDF file is no longer used.');
