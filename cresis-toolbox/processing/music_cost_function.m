function S = music_cost_function(theta, param)
% S = music_cost_function(theta,param)
%
% Function used to compute MUSIC pseudospectrum. Minimized in array_proc
% under method 9 (music_doa) in order to refine estimate of local peaks.
%
% Inputs:
%   theta = 1 x 1 scalar where pseudospectrum is to be evaluated
% 
%   param = control structure containing the following fields:
%     .Nsrc   = 1 x 1 scalar specifying dimensionality of signal subspace,
%     .Rxx    = Nc x Nc complex valued sample covariance matrix,
%     .fc     = 1 x 1 scalar valued carrier frequency (Hz)
%     .y_pc   = Nc x 1 vector containing y coordinates of phase centers
%               in SAR FCS (meters),
%     .z_pc   = Nc x 1 vector containing z coordinates of phase centers in
%               SAR FCS (meters).
% Outputs:
%   S = 1x1 scalar specifying value of MUSIC pseudospectrum at theta.
%
% Author:   Theresa Stumpf
% 
% See also: array_proc.m, music_initialization.m
% =========================================================================

%% music_cost_function: Input checks
% =========================================================================

if ~isfield(param,'sv_fh')||isempty(param.sv_fh)
  param.sv_fh = @array_proc_sv;
end

if ~isfield(param,'sv_dielectric') || isempty(param.sv_dielectric)
  param.sv_dielectric = 1;
end

if ~isfield(param,'lut') || isempty(param.lut)
  param.lut = [];
end

if ~isfield(param,'lut_roll') || isempty(param.lut_roll)
  param.lut_roll = [];
end

%% music_cost_function:  Steering vector evaluation
% =========================================================================
%
% NOTE: Currently only ideal steering vectors are supported. This could be 
% improved by passing in LUT through the param structure.
c = 2.997924580003452e+08; % physical_constants too slow
sv_opt_arg.theta = theta;
sv_arg = {param.fc*sqrt(param.sv_dielectric),param.y_pc,param.z_pc, sv_opt_arg, param.lut, param.lut_roll};
[~,SV] = param.sv_fh(sv_arg{:});

%% Compute Cost
% =========================================================================
[V,D]     = eig(param.Rxx);
eigenVals = diag(D);
[eigenVals, noiseIdxs] = sort(eigenVals);
noiseIdxs = noiseIdxs(1:end - param.Nsrc);
Qn        = V(:,noiseIdxs);
S         = mean(abs(SV(:,:)' * Qn).^2,2);
S         = sum(S);
end