function J = wb_cost_function(theta, param) 
% J = wb_cost_function(theta,param)
%
% Function that computes the cost of a given solution vector theta, based
% on the minimization of the error between the columns of a space time
% covariance matrix, param.DCM, and their models computed inside of
% compute_cost.cpp.  wb_cost_function calls compute_cost.cpp, a mex
% function that must be compiled before running array_proc.m
% 
% wb_cost_func(theta,param) is called by inside of array_proc for
% array_param.method == 8, during initialization and minimization.
% 
% Inputs:
%   theta = Nsig x 1 vector of DOAs in radians,
% 
%   param  = control structure containing the following fields:
%     .DCM    = estimated space time covariance matrix,
%     .y_pc   = column vector of y coordinates of each phase center in SAR
%               flight coordinate system,
%     .z_pc   = column vector of z coordinates of each phase center in SAR
%               flight coordinate system,
%     .fc     = center frequency,
%     .fs     = sampling frequency of decimated SAR outputs,
%     .h      = impulse response time series computed in
%               combine_wf_chan_task.m 
%     .t0     = start time of the impulse response time series,
%     .dt     = sampling interval of the impulse response time series,
%
% Outputs:
%   J    = real scalar value in dB describing the cost of a given solution,
%          theta
%
% Author:  Theresa Stumpf
%
% See Also:  array_proc.m, wb_initialization.m, wb_compute_cost.cpp
% =========================================================================

physical_constants

% fminsearch only: transform out of constraint domain
% for src_idx = 1:length(param.src_limits)
%   theta(src_idx) = cos(theta(src_idx))*diff(param.src_limits{src_idx})/2 ...
%     + sum(param.src_limits{src_idx})/2;
% end

theta = theta(:);   % make theta into a column vector
t0    = param.t0;
dt    = param.dt;
h     = param.h;
uy    = sin(theta).'; % make directional sines and cosines into row vecs
uz    = cos(theta).';
tau   = (2/c*param.sv_dielectric)*(param.y_pc*uy - param.z_pc*uz);
J     = wb_compute_cost(tau, param.DCM, param.fc, param.fs, h, t0,dt);
J     = 10*log10(abs(J));

end





