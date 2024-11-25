function [results, DCM_runs] = doa(param,param_override)
% results = doa(param,param_override)
%
% Function for simulating direction of arrival algorithms
%
% Author: John Paden, Theresa Stumpf, (cluster adaptation by Gordon Ariho)

%% General Setup
% =========================================================================
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', mfilename, param.cluster.type, datestr(now));
fprintf('=====================================================================\n');

%% Input checks
% =========================================================================

if ~isfield(param.src,'ft_wind') || isempty(param.src.ft_wind)
  param.src.ft_wind = @boxcar;
end

if ~isfield(param.src,'sv_dielectric') || isempty(param.src.sv_dielectric)
  param.src.sv_dielectric = 1;
end


%% Setup
% =========================================================================

% param.src.fc: center frequency
param.src.fc = (param.src.f0 + param.src.f1)/2;
% param.src.fs: sampling frequency
param.src.fs = abs(param.src.f1 - param.src.f0);

% Get phase center positions of antenna array
if isfield(param.src,'phase_center')
  param.src.y_pc   = param.src.phase_center(2,:).';
  param.src.z_pc   = param.src.phase_center(3,:).';
  
elseif isfield(param.src,'lever_arm') && isfield(param.src.lever_arm,'fh')
  [phase_center] = param.src.lever_arm.fh(param.src.lever_arm.args{:});
  param.src.y_pc   = phase_center(2,:).';
  param.src.z_pc   = phase_center(3,:).';
elseif isfield(param.src,'y_pc') && isfield(param.src,'z_pc')
  % Do nothing. Already defined
else
  warning('Phase center information are not defined')
  keyboard
end

% Allocate all the output matrices
theta_est = [];
if isfield(param,'M') && ~isempty(param.M)
  % Model order estimation simulation. M=Nc-1 usually.
  for method = param.method.list
    theta_est{method} = zeros(param.monte.runs,size(param.monte.SNR,1),param.Nc-1);
    hessian_est{method} = zeros(param.monte.runs,size(param.monte.SNR,1),param.Nc-1);
    amp_est{method} = zeros(param.monte.runs,size(param.monte.SNR,1),param.Nc-1);
    cost_func{method} = zeros(param.monte.runs,size(param.monte.SNR,1));
  end
else
  for method = param.method.list
    theta_est{method} = zeros(param.monte.runs,size(param.monte.SNR,1),size(param.monte.SNR,2));
    hessian_est{method} = zeros(param.monte.runs,size(param.monte.SNR,1),size(param.monte.SNR,2));
    amp_est{method} = zeros(param.monte.runs,size(param.monte.SNR,1),size(param.monte.SNR,2));
    cost_func{method} = zeros(param.monte.runs,size(param.monte.SNR,1));
  end
end


%% Cluster set up
% =========================================================================

ctrl = cluster_new_batch(param);

ctrl.cluster.max_mem_mode = 'auto';
cluster_compile({'sim_doa_task.m'},ctrl.cluster.hidden_depend_funs,ctrl.cluster.force_compile,ctrl);
sparam.task_function = 'sim_doa_task';
sparam.argsin{1} = param;
sparam.num_args_out = 4;
sparam.cpu_time = param.cpu_time;
sparam.mem = param.mem;
dparam = [];

for test_idx = 1:size(param.monte.SNR,1)
  dparam.argsin{1}.test_idx = test_idx;
  ctrl = cluster_new_task(ctrl,sparam,dparam,'dparam_save',0);
end
ctrl = cluster_save_dparam(ctrl);
% Blocking, submit and wait
fprintf('Submitting %s\n', ctrl.batch_dir);
ctrl_chain = {{ctrl}};
cluster_save_chain(ctrl_chain);
ctrl_chain = cluster_run(ctrl_chain,1);

[in,out] = cluster_print(ctrl_chain{1}{1}.batch_id,[1:size(param.monte.SNR,1)],0);

%% Test Loop: loop over each test
% =========================================================================
% Each test is a particular SNR, DOA, or snapshot configuration
%
% Copy outputs into output argument structure
results = [];
results.rng_args = out{1}.argsout{2};
for idx = 1:size(param.monte.SNR,1)
  for method_idx = 1:length(param.method.list)
    results.theta_est{method_idx}(:,idx,:) = out{idx}.argsout{1}{method_idx}(:,1,:);
    results.hessian_est{method_idx}(:,idx,:) = out{idx}.argsout{3}{method_idx}(:,1,:);
    results.cost_func{method_idx}(:,idx,:) = out{idx}.argsout{4}{method_idx}(:,1,:);
  end
end

