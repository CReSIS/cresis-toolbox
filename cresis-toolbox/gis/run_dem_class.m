% script run_dem_class
%
% Script for demonstrating use of the dem_class.
%
% Author: John Paden

%% Typical Use
% =========================================================================
% Check to see if class already exists
global gdem;
if isempty(gdem) || ~isa(gdem,'dem_class') || ~isvalid(gdem)
  gdem = dem_class(gRadar);
end

% Set the desired DEM resolution
% gdem.set_res(1000);
gdem.set_res(10);

if ~exist('records','var')
  records = load(fullfile(gRadar.support_path,'records','rds','2018_Greenland_P3','records_20180418_04.mat'));
end
% Set the class up to look at this whole record
if ~strcmpi(gdem.name,'rds:2018_Greenland_P3:20180418_04')
  % Name the vector so the second time the script is run, we don't setup
  % the vector again unless the name is changed to a different segment.
  gdem.set_vector(records.lat,records.lon,'rds:2018_Greenland_P3:20180418_04');
end

gdem.set_vector(records.lat(1:10000),records.lon(1:10000));
[land_dem,msl,ocean_mask] = gdem.get_vector_dem();

return;


% This may be necessary to clear the class from memory when debugging
clear all;
startup;
dbstop if error;


% Delete object when you no longer need the dem and want to free memory
global gdem;
try
  delete(gdem);
end


