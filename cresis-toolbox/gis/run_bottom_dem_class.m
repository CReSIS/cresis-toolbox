% script run_bottom_dem_class
%
% Script for demonstrating use of the bottom_dem_class.
%
% Author: John Paden

%% Typical Use
% =========================================================================
% Check to see if class already exists
global gbottom_dem;
if isempty(gbottom_dem) || ~isa(gbottom_dem,'bottom_dem_class') || ~isvalid(gbottom_dem)
  gbottom_dem = bottom_dem_class(gRadar);
end

if ~exist('records','var')
  records = records_load(struct('season_name','2018_Greenland_P3','radar_name','rds','day_seg','20180418_04'));
end
% Set the class up to look at this whole record
if ~strcmpi(gbottom_dem.name,'rds:2018_Greenland_P3:20180418_04')
  % Name the vector so the second time the script is run, we don't setup
  % the vector again unless the name is changed to a different segment.
  gbottom_dem.set_vector(records.lat,records.lon,'rds:2018_Greenland_P3:20180418_04');
end

gbottom_dem.set_vector(records.lat(1:10000),records.lon(1:10000));
[land_dem,msl,ocean_mask] = gbottom_dem.get_vector_dem();

return;


% This may be necessary to clear the class from memory when debugging
clear all;
startup;
dbstop if error;


% Delete object when you no longer need the dem and want to free memory
global gbottom_dem;
try
  delete(gbottom_dem);
end


