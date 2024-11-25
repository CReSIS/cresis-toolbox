function [status,data] = opsGetLayerPoints(sys,param)
%
% [status,data] = opsGetLayerPoints(sys,param)
%
% Gets the layer points from the database for the given params.
%
% Input:
%   sys: (string) sys name ('rds','accum','snow',...)
%   param: structure with fields
%     properties.location = string ('arctic' or 'antarctic')
%     properties.season = string OR cell of string/s
%     select one:
%       properties.segment_id = integer
%       properties.segment = string
%
% OR INSTEAD OF THE ABOVE
%     properties.location = string ('arctic' or 'antarctic')
%     properties.point_path_id: integer array as row vector
%       (also requires location, season, segment_id currently...)
%
% OPTIONAL:
%     properties.start_gps_time = double
%     properties.stop_gps_time = double
%     properties.return_geom = string ('geog','proj')
%         geog returns lat/lon/elev in wsg84 (degrees)
%         proj returns x/y/elev in polar stereographic (meters)
%     properties.lyr_name = string or cell of strings ('surface' OR {'surface','bottom'})
%
% Output:
%   status: integer (0:Error,1:Success,2:Warning)
%   data: structure with fields (or error message)
%       properties.point_path_id = integer array
%       properties.lyr_id = integer array
%       properties.gps_time = double array
%       properties.twtt = double array
%       properties.type = integer array
%       properties.quality = integer array
%   Optional data fields:
%       properties.lat/y = double array
%       properties.lon/x = double array
%       properties.elev = double array
%
% Author: Kyle W. Purdon

global gRadar;
param_override = gRadar;
try
  param_override = rmfield(param_override,'properties');
end
param = merge_structs(param, param_override);

if isempty(param.properties.location)
  error('param.properties.location must be set (e.g. arctic, antarctic).');
end

% CONSTRUCT THE JSON STRUCTURE
param.properties.mat = true;
opsAuth = load(fullfile(param.tmp_path,'ops.mat'));
param.properties.userName = opsAuth.userName;
param.properties.isAuthenticated = opsAuth.isAuthenticated;
jsonStruct = struct('properties',param.properties);

% CONVERT THE JSON STRUCTURE TO A JSON STRING
try
  jsonStr = tojson(jsonStruct);
catch ME
  jsonStr = savejson('',jsonStruct,'FloatFormat','%2.10f','NaN','null');
end

% SEND THE COMMAND TO THE SERVER
opsCmd;
if gOps.profileCmd
  [jsonResponse,~] = opsUrlRead(strcat(gOps.serverUrl,'profile'),gOps.dbUser,gOps.dbPswd,...
    'Post',{'app' sys 'data' jsonStr 'view' 'getLayerPoints'});
else
  [jsonResponse,~] = opsUrlRead(strcat(gOps.serverUrl,'get/layer/points'),gOps.dbUser,gOps.dbPswd,...
    'Post',{'app' sys 'data' jsonStr});
end

% DECODE THE SERVER RESPONSE
[status,decodedJson] = jsonResponseDecode(jsonResponse);

% CREATE THE DATA OUTPUT STRUCTURE OR MESSAGE
if status == 2
  % STORE THE UNIQUE VARIABLES IN DATA
  data.properties.point_path_id = [];
  data.properties.gps_time = [];
  data.properties.twtt = [];
  data.properties.type = [];
  data.properties.quality = [];
  data.properties.lyr_id = [];
  if isfield(param.properties,'return_geom') && strcmpi(param.properties.return_geom,'geog')
    data.properties.lat = [];
    data.properties.lon = [];
    data.properties.elev = [];
  elseif isfield(param.properties,'return_geom') && strcmpi(param.properties.return_geom,'proj')
    data.properties.x = [];
    data.properties.y = [];
    data.properties.elev = [];
  end
else
  % STORE THE UNIQUE VARIABLES IN DATA
  data.properties.point_path_id = double(cat(2,decodedJson.point_path_id{:}));
  data.properties.gps_time = double(cat(2,decodedJson.gps_time{:}));
  data.properties.twtt = double(cat(2,decodedJson.twtt{:}));
  data.properties.type = double(cat(2,decodedJson.type{:}));
  data.properties.quality = double(cat(2,decodedJson.quality{:}));
  data.properties.lyr_id = double(cat(2,decodedJson.lyr_id{:}));
  if isfield(param.properties,'return_geom') && strcmpi(param.properties.return_geom,'geog')
    data.properties.lat = double(cat(2,decodedJson.lat{:}));
    data.properties.lon = double(cat(2,decodedJson.lon{:}));
    data.properties.elev = double(cat(2,decodedJson.elev{:}));
  elseif isfield(param.properties,'return_geom') && strcmpi(param.properties.return_geom,'proj')
    data.properties.x = double(cat(2,decodedJson.lat{:}));
    data.properties.y = double(cat(2,decodedJson.lon{:}));
    data.properties.elev = double(cat(2,decodedJson.elev{:}));
  end
end
end