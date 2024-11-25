function [drange,ideal] = basic_motion_comp(param,lever_arm_fh,roll,pitch,heading,lat,lon,elev)
% [drange,ideal] = basic_motion_comp(param,lever_arm_fh,roll,pitch,heading,lat,lon,elev)
%
% param
%  .squint = vector in flight coordinate system, pointing from phase center
%    to the center of the scene, motion compensation, drange, is corrected
%    along this vector
%    default is [0 0 -1] or straight down
%  .type = scalar integer
%    0: no motion compensation
%    1: antenna lever arm only motion compensation (level flight assumed)
%    2: roll-only motion compensation (level flight assumed except for roll)
%    3: roll/pitch-only motion compensation (level flight assumed except for roll/pitch)
%    4. full attitude compensation
%    5. full motion compensation to line connecting start/stop points
%  .rx = receiver channel to motion compensate
%  .tx_weights = transmitter amplitude weights (for lever_arm_fh)
% lever_arm_fh
%   function handle to lever arm function to use
% lat,lon,elev,roll,pitch,heading
%    1 by Nx vectors
%    Not required if param.mocomp_mode is 0 or 1
%    lat,lon in degrees
%    elev in meters
%    roll, pitch, heading in radians
%
% drange (meters)
%   Change in range after compensation (positive is longer range which
%   translates to longer time delay which translates to a more negative
%   phase)
%
% Flight coordinate system (FCS)
%   origin = first sample
%   x = along-track
%   z = pointing upward and orthogonal to along-track
%   y = completes right handed coordinate system
%
% Author: John Paden

lever_param.gps_source = param.gps_source;
lever_param.season_name = param.season_name;
lever_param.radar_name = param.radar_name;
  
if ~isfield(param,'squint')
  % Default squint vector is straight down (flight coordinate system)
  param.squint = [0 0 -1];
end

% Make sure the squint vector has unit length
param.squint = param.squint ./ sqrt(dot(param.squint,param.squint));

ideal(1,:) = lat;
ideal(2,:) = lon;
ideal(3,:) = elev;

if param.type == 0
  % ==================================================================
  % No leverarm or motion compensation
  % ==================================================================
  
  drange = zeros(size(roll));
  
elseif param.type == 1
  % ==================================================================
  % Leverarm compensation, but no motion compensation
  % ==================================================================
  
  % Get the phase center of the receiver in question in BCS
  [phase_center] = lever_arm_fh(lever_param,param.tx_weights, param.rx);

  % Get the middle phase center in BCS (middle is defined separately in
  % each lever arm function)
  [mid_phase_center] = lever_arm_fh(lever_param,param.tx_weights, 0);

  % Determine the offset to the middle phase center in BCS
  phase_center = mid_phase_center - phase_center;

  % Convert BCS to flight coordinate system
  %   Assuming level flight so that BCS system exactly matches flight
  %   coordinate system (except YZ reversed signs)
  phase_center(2:3) = -phase_center(2:3);
  drange = -dot(param.squint,phase_center) * ones(size(roll));

elseif param.type == 2 || param.type == 3
  % ==================================================================
  % Leverarm and roll compensation, but no other parameters
  % ==================================================================

  if param.type == 2
    pitch = zeros(size(roll));
  end
  
  % Get the middle phase center in BCS (middle is defined separately in
  % each lever arm function)
  [mid_phase_center] = lever_arm_fh(lever_param,param.tx_weights, 0);
  
  % Get the phase center of the receiver in question in BCS
  [base_phase_center] = lever_arm_fh(lever_param,param.tx_weights, param.rx);
  
  for rline = 1:length(roll)
    % Roll, pitch
    rotation_mat ...
      = [cos(pitch(rline)), 0, sin(pitch(rline)); 0, 1, 0; -1*sin(pitch(rline)), 0 cos(pitch(rline))] ...
      * [1, 0, 0; 0, cos(roll(rline)), -1 * sin(roll(rline)); 0, sin(roll(rline)), cos(roll(rline))];
    
    % Middle and receiver phase centers with roll or roll/pitch only
    % compensation in NED coordinate system
    phase_center = rotation_mat * base_phase_center;
    
    % BCS is NED when straight path is assumed
    % mid_phase_center => no need to convert to NED (already there)
    
    % Determine offset in NED coordinate system
    phase_center = mid_phase_center - phase_center;
    
    % Convert NED to flight coordinate system
    %   Assuming level flight so that NED system exactly matches flight
    %   coordinate system (except YZ reversed signs)
    phase_center(2:3,:) = -phase_center(2:3,:);
    
    % Determine change in range for motion compensation
    drange(rline) = -dot(param.squint,phase_center);
  end

elseif param.type == 4 || param.type == 5
  % ==================================================================
  % Leverarm and attitude compensation
  % ==================================================================
  
  % -----------------------------------------------
  % Create flight coordinate system
  
  % Determine local up vector at starting point
  physical_constants; % Load WGS84.spheroid
  [x_ecef,y_ecef,z_ecef] = geodetic2ecef(WGS84.spheroid,lat,lon,elev);
  [x_local,y_local,z_local] = ecef2enu(x_ecef([1 end]),y_ecef([1 end]),z_ecef([1 end]), ...
    lat(1),lon(1),elev(1),WGS84.spheroid);
  [x_ecef_up,y_ecef_up,z_ecef_up] = enu2ecef(x_local(1),y_local(1),z_local(1)+1, ...
    lat(1),lon(1),elev(1),WGS84.spheroid);
  local_up = [x_ecef_up-x_ecef(1); y_ecef_up-y_ecef(1); z_ecef_up-z_ecef(1)];
  local_up = local_up / sqrt(dot(local_up,local_up));
  % origin
  fcs_origin = [x_ecef(1); y_ecef(1); z_ecef(1)];
  % x-axis points from start to finish
  fcs_x = [x_ecef(end)-x_ecef(1); y_ecef(end)-y_ecef(1); z_ecef(end)-z_ecef(1)];
  fcs_x = fcs_x / sqrt(dot(fcs_x,fcs_x));
  % z-axis points orthogonal to x-axis and along local up vector
  fcs_z = local_up - fcs_x*dot(local_up,fcs_x);
  fcs_z = fcs_z / sqrt(dot(fcs_z,fcs_z));
  % y-axis completes RH coordinate system
  fcs_y = cross(fcs_z, fcs_x);
  fcs_T = [fcs_x fcs_y fcs_z];
  fcs_Tinv = inv(fcs_T);
  fcs_heading = pi/2 - atan2(y_local(2)-y_local(1), x_local(2)-x_local(1));
  
  % ==================================================================
  % Leverarm and roll compensation, but no other parameters
  % ==================================================================

  % Get the middle phase center in BCS (middle is defined separately in
  % each lever arm function)
  [base_mid_phase_center] = lever_arm_fh(lever_param,param.tx_weights, 0);
  
  % Get the phase center of the receiver in question in BCS
  [base_phase_center] = lever_arm_fh(lever_param,param.tx_weights, param.rx);
  
  % Convert squint angle (body coordinate system) to NED coordinate system
  
  for rline = 1:length(roll)
    % Roll, pitch, heading
    rotation_mat ...
      = [cos(heading(rline)), -1*sin(heading(rline)), 0; sin(heading(rline)), cos(heading(rline)), 0; 0, 0, 1] ...
      * [cos(pitch(rline)), 0, sin(pitch(rline)); 0, 1, 0; -1*sin(pitch(rline)), 0 cos(pitch(rline))] ...
      * [1, 0, 0; 0, cos(roll(rline)), -1 * sin(roll(rline)); 0, sin(roll(rline)), cos(roll(rline))];
    
    % Middle and receiver phase centers with roll or roll/pitch only
    % compensation in NED coordinate system
    phase_center = rotation_mat * base_phase_center;

    % Do the same for the ideal location (both assume ideal roll, pitch,
    % and heading)
    rotation_mat ...
      = [cos(fcs_heading), -1*sin(fcs_heading), 0; sin(fcs_heading), cos(fcs_heading), 0; 0, 0, 1];
    mid_phase_center = rotation_mat * base_mid_phase_center;
    
    if param.type == 4
      % Assume that flightpath is ideal straight-line and only correct
      % for attitude (ECEF)
      [mid_phase_center(1,1),mid_phase_center(2,1),mid_phase_center(3,1)] ...
        = enu2ecef(mid_phase_center(2),mid_phase_center(1),-mid_phase_center(3), ...
        lat(rline),lon(rline),elev(rline),WGS84.spheroid);
    else
      % Determine ideal straight-line flight path phase center position
      % (ECEF)
      ideal(:,rline) = fcs_origin + fcs_x*dot(fcs_x, ...
        [x_ecef(rline) - fcs_origin(1); y_ecef(rline) - fcs_origin(2); z_ecef(rline) - fcs_origin(3)]);
      % Convert from ECEF to Geodetic
      [ideal(1,rline),ideal(2,rline),ideal(3,rline)] ...
        = ecef2geodetic(WGS84.spheroid, ideal(1,rline),ideal(2,rline),ideal(3,rline));
      % Determine mid_phase_center offset from ideal trajectory (ECEF)
      [mid_phase_center(1),mid_phase_center(2),mid_phase_center(3)] ...
        = enu2ecef(mid_phase_center(2),mid_phase_center(1),-mid_phase_center(3), ...
        ideal(1,rline),ideal(2,rline),ideal(3,rline),WGS84.spheroid);
      ideal(:,rline) = mid_phase_center;
    end
    
    % Convert from NED to ECEF
    [phase_center(1),phase_center(2),phase_center(3)] ...
      = enu2ecef(phase_center(2),phase_center(1),-phase_center(3), ...
      lat(rline),lon(rline),elev(rline),WGS84.spheroid);
    
    % Determine offset in ECEF coordinate system
    phase_center = mid_phase_center - phase_center;
    
    % Convert from ECEF to FCS
    phase_center = fcs_Tinv * phase_center;
    
    % Determine change in range for motion compensation
    drange(rline) = -dot(param.squint,phase_center);
  end

else
  error('Parameter type %d not supported\n', param.type);
end

if param.type == 5
  [ideal(1,:),ideal(2,:),ideal(3,:)] = ecef2geodetic(WGS84.spheroid,ideal(1,:),ideal(2,:),ideal(3,:));
end

return;

