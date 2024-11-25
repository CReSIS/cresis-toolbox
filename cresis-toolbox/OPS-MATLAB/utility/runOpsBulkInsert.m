% script runOpsBulkInsert
%
% Loads flight path data in bulk from the CReSIS filesystem (records and
% frames files) to the OPS.
%
% To use this script manually edit the input fileds under USER INPUT.
%
% Data inputs required:
%   path: records and frames files
%
% Multi-Layer data is supported, the layerData files must contain a name
% field with a unique name identifying each layer.
%
% Authors: Kyle W. Purdon, Trey Stafford, John Paden
%
% See also: opsBulkInsert.m, opsCreatePath.m

%% USER INPUT

% Initialize settings structure
settings = [];

% ----------------------------------------------------------------
% paramFn: FILENAME.xls OF EXCEL CReSIS PARAMS SHEET
settings.params = read_param_xls(ct_filename_param('rds_param_2014_Greenland_P3.xls'));

settings.params = ct_set_params(settings.params, 'cmd.generic', 1);
settings.params = ct_set_params(settings.params, 'cmd.generic', 0, 'cmd.notes', 'do not process');

%settings.params = ct_set_params(settings.params, 'cmd.generic', 0);
%settings.params = ct_set_params(settings.params, 'cmd.generic', 1, 'day_seg', '20120416_01');

%% AUTOMATED SECTION

% GET THE CReSIS GLOBAL settings
global gRadar;
settings = merge_structs(gRadar,settings);

% RUN OPS BULK INSERT
opsBulkInsert(settings);
