function records_aux_files_create(records_fn,print_flag)
% DEPRECATED
%
% records_aux_files_create(records_fn,print_flag)
%
% Creates the auxilliary files to the main records file.  These files
% are used by tasks running on the scheduler because they allow a much
% smaller memory footprint to load (currently Matlab .mat files require
% that entire variables be loaded rather than subsets).
%
% The auxilliary file is a NetCDF file.
%
% Examples: See bottom of file for example to create files in a batch.
%
% Author: John Paden
%
% See also: records_aux_files_create, records_aux_files_read,
% records_create_sync

error('This function is deprecated. Just use ct_save() since the NetCDF file is no longer used.');
