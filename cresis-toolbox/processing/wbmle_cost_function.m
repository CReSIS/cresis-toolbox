function val = wbmle_cost_function(theta, param)
% val = wbmle_cost_function(theta,param)
%
% Function that computes the cost of a given solution vector theta,
%
% Inputs:
%   theta = Nsrc x 1 vector of DOAs in radians
%
%   param     = control structure containing the following fields:
%     .Nsrc   = number of signals,
%     .Rxx    = data covariance matrix,
%     .y_pc   = column vector of y coordinates of each phase center in SAR
%               flight coordinate system,
%     .z_pc   = column vector of z coordinates of each phase center in SAR
%               flight coordinate system,
%     .fc     = center frequency,
%     .proj_mtx_update = 1x1 boolean field that enables the projection
%     matrix update when the alternating projection algorithm is used to
%     search for the solution.
%     .theta_fixed = (Nsrc-1)x1 vector of given solutions used in
%                   alternating projection, as defined in eqn 16.b of
%                   Ziskind and Wax.
% Outputs:
%   val    = real scalar value in dB describing the cost of a given
%          solution, theta.  NOTE that this value corresponds to 1 over the
%          value of the likelihood function in dB!!!!!
%
% See also:  array_proc.m, mle_compute_cost.m, mle_initialization.m
% =========================================================================

physical_constants

if ~isfield(param,'proj_mtx_update')
  param.proj_mtx_update = false;
end

% Force theta to be a row vector in preparation for inner product
theta = theta(:).';

% alternating projection with projection matrix update
% if param.proj_mtx_update
if param.proj_mtx_update
  % Setup steering vectors for the fixed
  theta_eval = [param.theta_fixed(:).',theta];
  theta_eval = theta_eval(:).';   % make theta have the right dimensions
  k     = 4*pi*param.fc*param.sv_dielectric/c;
  ky    = k*sin(theta_eval).';
  kz    = k*cos(theta_eval).';
  SVs   = (1/sqrt(length(param.y_pc)))*exp(1i*(param.y_pc*ky - param.z_pc*kz));
  A     = SVs(:,1:numel(param.theta_fixed)); % Nc x (Nsrc - 1)
  C     = SVs(:,numel(param.theta_fixed)+1:end); % Nc x 1 (always)
  Pa    = A* inv(A' * A) * A'; % Nc x Nc
  Cb    = (eye(size(Pa,1))- Pa)*C; % Nc x 1
  B     = Cb ./ (repmat(sqrt(sum(abs(Cb).^2,1)),size(Cb,2),1)); % Nc x 1
  L     = trace(B'*param.Rxx*B);
  
else
  DCM = param.Rxx;
  Nk = param.nb_filter_banks;
  k = 4*pi*(param.fc + param.fs*[0:floor((Nk-1)/2), -floor(Nk/2):-1]/Nk)/c*param.sv_dielectric;
  
  L = 0;
  for k_idx = 1:Nk
    A = sqrt(1/length(param.y_pc)) * exp(1i*k(k_idx)*(-param.z_pc*cos(theta) + param.y_pc*sin(theta)));
    Pa  = A * inv(A'*A) * A';
    if k_idx==1
      L = abs(sum(sum(Pa .* DCM((k_idx-1)*size(DCM,2)+(1:size(DCM,2)),:).')));
    else
      L = L + abs(sum(sum(Pa .* DCM((k_idx-1)*size(DCM,2)+(1:size(DCM,2)),:).')));
    end
  end
end

val      = -10*log10(abs(L));

end
