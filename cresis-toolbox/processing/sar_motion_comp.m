function [drange,dx,dy] = sar_motion_comp(fcs,gps,ref,along_track,output_along_track)
% [drange,dx,dy] = sar_motion_comp(fcs,gps,ref,along_track,output_along_track)
%
% Returns drange and mean(dx) that provides motion compensation for Doppler
% domain SAR processors for the positions in the gps structure relative
% to the positions in the ref structure.
%
% fcs = struct from SAR_coord_system, fields are (? by No)
% gps = struct with fields lat,lon,elev,roll,pitch,heading
%    1 by Nx vectors
%    lat,lon in degrees
%    elev in meters
%    roll, pitch, heading in radians
% ref = struct with fields lat,lon,elev,roll,pitch,heading
%    1 by Nx vectors
%    lat,lon in degrees
%    elev in meters
%    roll, pitch, heading in radians
% along_track = 1 by Nx along-track vector corresponding to the gps positions
% output_along_track = 1 by No (corresponding to fcs structures)
%
% drange (meters)
%   Change in range after compensation (positive implies that the data
%   will be modified to create a longer range which translates to longer
%   time delay which translates to a more negative phase)
% dx (meters)
%   Change in along-track (positive means that the actual position lagged
%   the reference point and will be shifted forward in space)
%
% Flight coordinate system (FCS)
%   origin = first sample
%   x = along-track
%   z = pointing toward local up and orthogonal to x
%   y = completes right handed coordinate system
%   fcs = flight coordinate system
%
% Motion Compensation Types (fcs.type)
%  == 3: compensation to line fitted to reference position of array
%  == 2: compensation to piecewise line fitted to reference position of array
%  == 1: Compensation to reference position of array
%
% Motion Compensation Filtering (fcs.filter)
%  []: No filtering is done
%  cell vector: fcs.filter{1}(fcs.filter{2},fcs.filter{3}) as in {@butter,2,0.1}
%    First element is function handle to function that returns [B,A] where
%      B is feedforward and A is feedback coefficients of filter to be used
%      with call to filtfilt (remember to include this function in 
%      gRadar.sched.hidden_depend_funs so the mcc compiler will see it).
%    Second element is usually the filter order
%    Third element is usually the filter bandwidth
%
% Author: John Paden

physical_constants;

[ref_ecef(1,:),ref_ecef(2,:),ref_ecef(3,:)] = ...
  geodetic2ecef(ref.lat/180*pi,ref.lon/180*pi,ref.elev,WGS84.ellipsoid);

[ecef(1,:),ecef(2,:),ecef(3,:)] ...
  = geodetic2ecef(gps.lat/180*pi,gps.lon/180*pi,gps.elev,WGS84.ellipsoid);

if fcs.type == 4 || fcs.type == 5
  % Savitsky Golay filtering of reference positions
  dx_in = median(diff(along_track));
  sgolayfilt_F = 2*round(fcs.Lsar / dx_in) + 1;
  sv_ecef = sgolayfilt(ref_ecef.', 1, sgolayfilt_F, hanning(sgolayfilt_F)).';
end

%% For each output range line position, find the closest range lines to it
% The polynomial fitting for a particular output will only update drange
% and dx values for input range lines closest to it.
% start_input = zeros(size(output_along_track));
% stop_input = zeros(size(output_along_track));
% cur_input = 1;
% for rline = 1:length(output_along_track)-1
%   break_threshold = 0.5*(output_along_track(rline)+output_along_track(rline+1));
%   start_input(rline) = cur_input;
%   stop_input(rline) = find(along_track<=break_threshold,1,'last');
%   cur_input = stop_input(rline)+1;
% end
% start_input(end) = cur_input;
% stop_input(end) = length(along_track);

%% Perform fitting to input data and determine the offset in
% drange and dx to that fitting (fitting is usually a polynomial fit of
% some kind).
drange = zeros(size(along_track));
dx = zeros(size(along_track));
dy = zeros(size(along_track));
dx_out = output_along_track(2)-output_along_track(1);
for rline = 1:length(output_along_track)
  rlines_fit = find(along_track >= output_along_track(rline)-fcs.Lsar/2 ...
    & along_track < output_along_track(rline)+fcs.Lsar/2);
  if length(rlines_fit)<2
    continue;
  end
  if rline == 1
    rlines_in = find(along_track < 0.5*(output_along_track(rline)+output_along_track(rline+1)) );
  elseif rline == length(output_along_track)
    rlines_in = find(along_track >= 0.5*(output_along_track(rline-1)+output_along_track(rline)) );
  else
    rlines_in = find(along_track >= 0.5*(output_along_track(rline-1)+output_along_track(rline)) ...
      & along_track < 0.5*(output_along_track(rline)+output_along_track(rline+1)) );
  end
  if isempty(rlines_in)
    continue;
  end
  
  % Determine the closest range lines for this output range line
%   closest_rlines = start_input(rline):stop_input(rline);
%   if isempty(closest_rlines)
%     continue;
%   end
  
%   fit_ecef = [];
%   if fcs.type == 4 || fcs.type == 5
%     %% Compensation to savitsky golay
%     fit_ecef = sv_ecef(:,closest_rlines);
%   elseif fcs.type == 3
%     %% Compensation to line fit to reference (fcs.type == 3)
%     fit_ecef(1,:) = polyval(polyfit(1:size(ref_ecef,2),ref_ecef(1,:),1),closest_rlines);
%     fit_ecef(2,:) = polyval(polyfit(1:size(ref_ecef,2),ref_ecef(2,:),1),closest_rlines);
%     fit_ecef(3,:) = polyval(polyfit(1:size(ref_ecef,2),ref_ecef(3,:),1),closest_rlines);
%   elseif fcs.type == 2
%     %% Compensation to piece-wise line fit to reference (fcs.type == 2)
%     fit_ecef(1,:) = polyval(polyfit(rlines_fit,ref_ecef(1,rlines_fit),1),closest_rlines);
%     fit_ecef(2,:) = polyval(polyfit(rlines_fit,ref_ecef(2,rlines_fit),1),closest_rlines);
%     fit_ecef(3,:) = polyval(polyfit(rlines_fit,ref_ecef(3,rlines_fit),1),closest_rlines);
%   elseif fcs.type == 1
%     %% Compensation to reference (fcs.type == 1)
%     fit_ecef = ref_ecef(:,closest_rlines);
%   else
%     error('Motion compensation type must be 1, 2, or 3');
%   end
  
  % The following operation computes the linear transformation matrix:
  %   fcs_T = [fcs.x(:,out_rline) fcs.y(:,out_rline) fcs.z(:,out_rline)];
  % Uses the "A\B" (help slash) nomenclature to inverse it:
  %   fcs_Tinv = inv(fcs_T);
  gps_fcs = [fcs.x(:,rline) fcs.y(:,rline) fcs.z(:,rline)] \ (ecef(:,rlines_in) - repmat(fcs.origin(:,rline),[1 length(rlines_in)]));
  ref_fcs = [fcs.x(:,rline) fcs.y(:,rline) fcs.z(:,rline)] \ (ref_ecef(:,rlines_in) - repmat(fcs.origin(:,rline),[1 length(rlines_in)]));
  diff_fcs = gps_fcs - ref_fcs;
  
  %% Calculate drange and dx for each input and SAR output
  drange(rlines_in) = dot(repmat(fcs.squint,[1 size(gps_fcs,2)]),diff_fcs);
  dx(rlines_in) = dot(repmat([1 0 0].',[1 size(gps_fcs,2)]),diff_fcs);
  dx(rlines_in) = diff_fcs(1,:);
  dy(rlines_in) = gps_fcs(2,:);
end

if fcs.type == 5
  squint_lpf = mean(fcs.z,2);
  squint_lpf = squint_lpf ./ sqrt(dot(squint_lpf,squint_lpf));
  drange = -dot(repmat(squint_lpf,[1 size(ecef,2)]),ecef);
  drange = drange - mean(drange);
end

if 0
  % Debug code
  figure(1); clf;
  subplot(2,1,1);
  plot(drange);
  a1 = gca;
  subplot(2,1,2);
  plot(dx);
  a2 = gca;
  linkaxes([a1 a2],'x');
end

% Deal with edge effects
dx(along_track<output_along_track(1)) = dx(find(along_track>=output_along_track(1),1));
dx(along_track>output_along_track(end)) = dx(find(along_track<=output_along_track(end),1,'last'));

if ~isempty(fcs.filter)
  [Bfilt,Afilt] = fcs.filter{1}(fcs.filter{2},fcs.filter{3});
  drange = filtfilt(Bfilt,Afilt,drange);
  dx = filtfilt(Bfilt,Afilt,dx);
end

if 0
  % Debug code
  figure(1);
  subplot(2,1,1);
  hold on;
  plot(drange,'r');
  grid on;
  a1 = gca;
  subplot(2,1,2);
  hold on;
  plot(dx,'r');
  grid on;
  a2 = gca;
  linkaxes([a1 a2],'x');
  keyboard
end

return;

