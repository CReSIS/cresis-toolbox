function [phase_lat, phase_lon, phase_elev] = phase_lla(lever, roll, pitch, heading, lat, lon, elev)
% [phase_lat, phase_lon, phase_elev] = phase_lla(lever, roll, pitch,
%   heading, lat, lon, elev)
%
% Phase Center Geodetic Position (Latitude Longitude Altitude)
%
% lever             Variable Type:  3 x 1 double. 
%                   Phase center position relative to INS unit (meters)
%                   defined in the coordinate system of the plane's body.
%                   Usually from lever_arm_2009.m
% 
% lat               Variable Type:  1 x N double.
%                   Vector of Geodetic Latitude samples (degrees).
%
% lon               Variable Type:  1 x N double.
%                   Vector of Geodetic Longitude samples (degrees).
% 
% elev              Variable Type:  1 x N double.
%                   Vector of altitude samples that specify the height 
%                   of the GPS antenna above the WGS84 ellipsoid, corrected
%                   to the INS unit (meters).
%                  
% roll              Variable Type:  1 x N double.
%                   Vector of roll samples (degrees).
%
% pitch             Variable Type:  1 x N double. 
%                   Vector of pitch samples(degrees).
% 
% heading           Variable Type:  1 x N double.
%                   Vector of heading samples (degrees).
% 
% phase_lat         Variable Type:  1 x N double.
%                   Vector of geodetic latitude samples (degrees) 
%                   corrected to the phase center specified by the 
%                   input lever variable. 
%
% phase_lon         Variable Type:  1 x N double.
%                   Vector of geodetic longitude samples (degrees) 
%                   corrected to the phase center specified by the input 
%                   variable lever.
%
% phase_elev        Variable Type:  1 x N double.
%                   Vector of elevation samples (meters) corrected to the
%                   phase center specified by the input variable lever, 
%                   where elevation refers to height above the geoid.
%
%
% !!!  GENERAL NOTES ABOUT COORDINATE SYSTEMS  !!!
%
% The variable lever is defined using conventional aerospace coordinate 
% system (+y axis points parallel to and in the direction of the right 
% wing; +x axis is parallel to the body of the plane and points toward the 
% nose; +z points toward the surface of the earth and is perpindicular to 
% x and y).
% 
% Roll, pitch, heading are Euler angles describing the rotation betwen the
% coordinate system of the plane's body (whose origin lies at INS unit) and
% the local East North Down navigationcoordinate system.  These rotations 
% are defined using a RIGHT HANDED SYSTEM.  The +x axis points due east, 
% the +y axis points due north and the +z axis points down toward the 
% surface of the Earth.  
%
% + roll           right wing tips down.
% + pitch          nose tips up.
% + heading        plane "turns right."
% 
% The function assumes that the input variable elev (height of the GPS 
% antenna above the geoid) has been corrected to the INS unit.  
% 
% Example:
% 
% >> lever = [0.1778; -4.53; -0.94859];
% >> roll = 2.50188456270591;
% >> pitch = 0.415200437469485;
% >> heading = 108.599700153473;
% >> lat = 64.4195477773169;
% >> lon = -49.9270579814065;
% >> elev = 182.220004302979;
% 
% >> [phase_lat, phase_lon, phase_elev] = PhaseLLA(lever, roll, pitch,
% heading, lat, lon, elev);
% 
% >> phase_lat =
%              64.4195854139828
% >> phase_lon = 
%              -49.9270249734175
% >> phase_elev =
%               183.366694714874               
% =========================================================================




physical_constants; % Load WGS84.spheroid

% Convert inertials and geodetic lat & lon from degress to radians.
phi0            = roll;
theta0          = pitch;
ci0             = heading;

% Preallocate memory for phase_lat, phase_lon, phase_elev vectors.
phase_lat       = zeros(1,length(elev));
phase_lon       = zeros(1,length(elev));
phase_elev      = zeros(1,length(elev));

for ind         = 1:length(elev)
    
    % Calculate rotation matrices 
    A           = [cos(ci0(ind)), -1*sin(ci0(ind)), 0; sin(ci0(ind)), cos(ci0(ind)), 0; 0, 0, 1];
    B           = [cos(theta0(ind)), 0, sin(theta0(ind)); 0, 1, 0; -1*sin(theta0(ind)), 0 cos(theta0(ind))];
    C           = [1, 0, 0; 0, cos(phi0(ind)), -1 * sin(phi0(ind)); 0, sin(phi0(ind)), cos(phi0(ind))];
    I           = A*B*C;
    
    % Calculate Phase Center in terms of END (East, North, Down) coordinate
    % system. 
    PhaseEND    = I*lever;

    
    % Calculate Phase Center in terms of ENU (East, North, Up) coordinate
    % system.
    PhaseENU    = [PhaseEND(2), PhaseEND(1), -1*PhaseEND(3)];
  
    % Calculate Phase Center in terms of ECEF coordinate system.
    [PhaseECEF_x, PhaseECEF_y, PhaseECEF_z] ...
      = enu2ecef(PhaseENU(1), PhaseENU(2), PhaseENU(3), lat(ind), lon(ind), elev(ind), WGS84.spheroid);
    
    % Calculate Phase Center in terms of geodetic latitude(radians), 
    % geodetic longitude (radians) and elevation (height above the
    % ellipsoid in meters).
    [phase_lat(ind) phase_lon(ind) phase_elev(ind)] = ecef2geodetic(WGS84.spheroid, PhaseECEF_x, PhaseECEF_y, PhaseECEF_z);
end
    
return;

% EXAMPLES

% 1 m to right hand side, 1 m up
lever = [0; 1; -1];
% Level flight
roll = 0;
pitch = 0;
% North
heading = 0;
% Equaltor
lat = 0;
% Prime meridian
lon = 0;
% Surface
elev = 0;
[phase_lat, phase_lon, phase_elev] = PhaseLLA(lever, roll, pitch, heading, lat, lon, elev)






