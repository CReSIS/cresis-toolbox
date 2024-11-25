function [status,data] = opsGetPath(sys,param)
%
% [status,data] = opsGetPath(sys,param)
%
% Gets the point path from the database based on the given params
%
% Input:
%   sys: (string) sys name ('rds','accum','snow',...)
%   param: structure with fields
%     properties.location = string ('arctic' or 'antarctic')
%     properties.season = string
%     properties.start_gps_time = double
%     properties.stop_gps_time = double
%     (optional) properties.nativeGeom = true (returns wgs1984 coordinates)
%
% OR INSTEAD OF THE ABOVE
%     properties.location = string ('arctic' or 'antarctic')
%     properties.point_path_id: integer array as row vector
%
% Output:
%   status: integer (0:Error,1:Success)
%   data: structure with fields (or error message)
%       properties.id = integer array of point path(s) ids
%       properties.gps_time = double array
%       properties.elev = double array
%       properties.X = double array (if input nativeGeom=true X=lon)
%       properties.Y = double array (if input nativeGeom=true Y=lat)
%
% Author: Kyle W. Purdon, Trey Stafford

% CONSTRUCT THE JSON STRUCTURE
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
        'Post',{'app' sys 'data' jsonStr 'view' 'getPath'});
else
    [jsonResponse,~] = opsUrlRead(strcat(gOps.serverUrl,'get/path'),gOps.dbUser,gOps.dbPswd,...
        'Post',{'app' sys 'data' jsonStr});
end

% DECODE THE SERVER RESPONSE
[status,decodedJson] = jsonResponseDecode(jsonResponse);

% CREATE THE DATA OUPUT STRUCTURE OR MESSAGE
data.properties.id = double(cell2mat(decodedJson.id)');
data.properties.gps_time = cell2mat(decodedJson.gps_time)';
data.properties.elev = cell2mat(decodedJson.elev)';
data.properties.X = cell2mat(decodedJson.X)';
data.properties.Y = cell2mat(decodedJson.Y)';

end