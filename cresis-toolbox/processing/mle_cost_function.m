function val = mle_cost_function(theta, param)
% val = mle_cost_function(theta,param)
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


%% mle_cost_function:  Input checks
% =========================================================================
if ~isfield(param,'sv_fh') || isempty(param.sv_fh)
  param.sv_fh = @array_proc_sv;
end

if ~isfield(param,'sv_dielectric') || isempty(param.sv_dielectric)
  param.sv_dielectric =1;
end

if ~isfield(param,'lut') || isempty(param.lut)
  param.lut = [];
end

if ~isfield(param,'lut_roll') || isempty(param.lut_roll)
  param.lut_roll = [];
end

if ~isfield(param,'doa_seq') || isempty(param.doa_seq)
  param.doa_seq = false;
end

if ~isfield(param,'apriori') || isempty(param.apriori)
  param.apriori.en = false;
  param.apriori.theta_range = [];
  param.apriori.mean_doa = [];
  param.apriori.var_doa = [];
end
  
if ~isfield(param,'proj_mtx_update') || isempty(param.proj_mtx_update)
  param.proj_mtx_update = false;
end
  
c = 2.997924580003452e+08; % physical_constants too slow

% Force theta to be a row vector in preparation for inner product
theta = theta(:).';

% alternating projection with projection matrix update
if param.proj_mtx_update
  % Setup steering vectors for the fixed
  theta_eval = [param.theta_fixed(:).',theta];
  theta_eval = theta_eval(:).';   % make theta have the right dimensions
  sv_opt_arg.theta = theta_eval;
  sv_arg ={param.fc*param.sv_dielectric, param.y_pc, param.z_pc, sv_opt_arg, param.lut, param.lut_roll};
  [~,SVs] = param.sv_fh(sv_arg{:});
  A     = SVs(:,1:numel(param.theta_fixed)); % Nc x (Nsrc - 1)
  C     = SVs(:,numel(param.theta_fixed)+1:end); % Nc x 1 (always)
  Pa    = A* inv(A' * A) * A'; % Nc x Nc
  Cb    = (eye(size(Pa,1))- Pa)*C; % Nc x 1
  B     = Cb ./ (repmat(sqrt(sum(abs(Cb).^2,1)),size(Cb,2),1)); % Nc x 1
  L     = trace(B'*param.Rxx*B);
  
else
  Rxx = param.Rxx;
  M = param.Nsrc;
  sv_opt_arg.theta = theta;
  sv_arg={param.fc*sqrt(param.sv_dielectric),param.y_pc,param.z_pc, sv_opt_arg, param.lut, param.lut_roll};
  [~,A] = param.sv_fh(sv_arg{:});
  Pa  = A * inv(A'*A) * A';
  if param.doa_seq && param.apriori.en
    L = -(M*size(A,1)) * log(abs(sum(sum((eye(size(Pa))-Pa) .* Rxx.'))));
  else
    L = abs(sum(sum(Pa .* Rxx.')));
  end
%   L = -abs(trace((eye(size(Pa))-Pa)*Rxx)); % Mohanad
%   L = abs(trace(Pa*Rxx)); % Wax
end

if param.doa_seq && param.apriori.en
  % Incorporate the prior pdf if available
  if 1
    mean_doa = param.apriori.mean_doa;
    var_doa  = param.apriori.var_doa;
    L_apriori = -1/2*(1./var_doa).' * (theta.' - mean_doa).^2;
  else
     % DON'T USE IT ..NOT FINALIZED YET
    f_prior = log(param.apriori.f_prior);
    theta_range = param.apriori.theta_range;
    for doa_i = 1:length(theta)
      [~,match_i(doa_i)] = min(abs(theta_range(:) - theta(doa_i)));
    end
    L_apriori = prod(f_prior(match_i));
  end
  
  L = L + L_apriori;
  val      = -L;
  if isinf(val)
    val = 99999;
  end
else
  val      = -10*log10(abs(L));
end
end