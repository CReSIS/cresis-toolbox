function [theta_est, rng_args, hessian_est, cost_func]= sim_doa_task(param)
% [theta_est, rng_args, hessian_est, cost_func] = sim_doa_task(param)
%
% Cluster task function running each test in sim.doa(param,param_override)
%
% Author: John Paden, Theresa Stumpf, Gordon Ariho
%
% See also: sim.doa.m

start_time = tic;
array_proc_methods;
rng_args = zeros(param.monte.runs);
% SV params
% Setup theta grid and steering vectors for multi-dimensional search
% algorithms
% [param.method.theta, param.method.SV] ...
%   = array_proc_sv(param.method.Nsv,param.src.fc, param.src.y_pc, param.src.z_pc);
[param.method.theta, param.method.SV] ...
  = array_proc_sv(param.src.fc*sqrt(param.src.sv_dielectric), param.src.y_pc, param.src.z_pc, param.method.Nsv, [],[]);

param.method.theta             = fftshift(param.method.theta);
param.method.SV                = fftshift(param.method.SV,2);

% Setup theta grid and steering vectors for 1-dimensional search
% algorithms (e.g. MUSIC)
% [param.method.OneD_theta, param.method.OneD_SV] ...
%   = array_proc_sv(param.method.OneD_Nsv,param.src.fc, param.src.y_pc, param.src.z_pc);

[param.method.OneD_theta, param.method.OneD_SV] ...
  = array_proc_sv(param.src.fc* sqrt(param.src.sv_dielectric), param.src.y_pc, param.src.z_pc, param.method.OneD_Nsv,[],[]);

param.method.OneD_theta             = fftshift(param.method.OneD_theta);
param.method.OneD_SV                = fftshift(param.method.OneD_SV,2);

% Setup parameterization structure for narrowband 1-D search
% methods (e.g. MUSIC)
doa_nb_1d_param = [];
doa_nb_1d_param.fs          = param.src.fs;
doa_nb_1d_param.fc          = param.src.fc;
doa_nb_1d_param.sv_dielectric = param.src.sv_dielectric;
doa_nb_1d_param.src_limits  = param.method.src_limits;
doa_nb_1d_param.theta_guard = param.method.theta_guard;
doa_nb_1d_param.y_pc        = param.src.y_pc;
doa_nb_1d_param.z_pc        = param.src.z_pc;
doa_nb_1d_param.theta       = param.method.OneD_theta;
doa_nb_1d_param.SV          = param.method.OneD_SV;
doa_nb_1d_param.options     = optimoptions(@fmincon,'Display','off','Algorithm','sqp','TolX',1e-6);

% Setup parameterization structure for narrowband N-D search
% methods (e.g. MLE)
doa_nb_nd_param = [];
doa_nb_nd_param.doa_seq     = false;
doa_nb_nd_param.fs          = param.src.fs;
doa_nb_nd_param.fc          = param.src.fc;
doa_nb_nd_param.sv_dielectric = param.src.sv_dielectric;
doa_nb_nd_param.src_limits  = param.method.src_limits;
doa_nb_nd_param.theta_guard = param.method.theta_guard;
doa_nb_nd_param.y_pc        = param.src.y_pc;
doa_nb_nd_param.z_pc        = param.src.z_pc;
doa_nb_nd_param.theta       = param.method.theta;
doa_nb_nd_param.SV          = param.method.SV;
doa_nb_nd_param.options     = optimoptions(@fmincon,'Display','off','Algorithm','sqp','TolX',1e-6);
doa_nb_nd_param.search_type = param.method.nb_nd.init;

% Setup wideband parameterization structure for wideband time domain
% search methods (e.g. WB)
doa_wb_td_param= [];
doa_wb_td_param.fs          = param.src.fs;
doa_wb_td_param.fc          = param.src.fc;
doa_wb_td_param.sv_dielectric = param.src.sv_dielectric;
doa_wb_td_param.src_limits  = param.method.src_limits;
doa_wb_td_param.theta_guard = param.method.theta_guard;
doa_wb_td_param.y_pc        = param.src.y_pc;
doa_wb_td_param.z_pc        = param.src.z_pc;
doa_wb_td_param.theta       = param.method.theta;
doa_wb_td_param.SV          = param.method.SV;
doa_wb_td_param.options     = optimoptions(@fmincon,'Display','off','Algorithm','sqp','TolX',1e-6);
doa_wb_td_param.search_type = param.method.wb_td.init;

% Setup wideband parameterization structure for wideband frequency domain
% search methods (e.g. MLEWB)
doa_wb_fd_param= [];
doa_wb_fd_param.doa_seq     = false;
doa_wb_fd_param.fs          = param.src.fs;
doa_wb_fd_param.fc          = param.src.fc;
doa_wb_fd_param.sv_dielectric = param.src.sv_dielectric;
doa_wb_fd_param.src_limits  = param.method.src_limits;
doa_wb_fd_param.theta_guard = param.method.theta_guard;
doa_wb_fd_param.y_pc        = param.src.y_pc;
doa_wb_fd_param.z_pc        = param.src.z_pc;
doa_wb_fd_param.theta       = param.method.theta;
doa_wb_fd_param.SV          = param.method.SV;
doa_wb_fd_param.options     = optimoptions(@fmincon,'Display','off','Algorithm','sqp','TolX',1e-6);
doa_wb_fd_param.search_type = param.method.wb_fd.init;
doa_wb_fd_param.nb_filter_banks = param.method.wb_fd.filter_banks;

doa_nonlcon_fh = eval(sprintf('@(x) doa_nonlcon(x,%f);', param.method.theta_guard));

test_idx = param.test_idx;
fprintf('Running test %d\n', test_idx);
% Get the parameters for this test
if isempty(param.monte.DOA)   % (for k = 0 model order estimation)
  param.src.DOAs   = [];
else
  param.src.DOAs   = param.monte.DOA(test_idx,:);
end
param.src.SNR    = param.monte.SNR(test_idx,:);
param.src.Nsnap  = param.monte.Nsnap(test_idx);

% Set number of signals, Nsrc
if isfield(param,'Nsig_tmp') && ~isempty(param.Nsig_tmp)
  % For model order estimation simulation.
  doa_nb_1d_param.Nsrc = param.Nsig_tmp;
  doa_nb_nd_param.Nsrc = param.Nsig_tmp;
  doa_wb_td_param.Nsrc = param.Nsig_tmp;
  doa_wb_fd_param.Nsrc = param.Nsig_tmp;
  
  LB = zeros(param.Nsig_tmp,1);
  UB = zeros(param.Nsig_tmp,1);
else
  doa_nb_1d_param.Nsrc = size(param.src.SNR,2);
  doa_nb_nd_param.Nsrc = size(param.src.SNR,2);
  doa_wb_td_param.Nsrc = size(param.src.SNR,2);
  doa_wb_fd_param.Nsrc = size(param.src.SNR,2);
  
  LB = zeros(length(param.src.DOAs),1);
  UB = zeros(length(param.src.DOAs),1);
end

% Set source limits for N-dimensional constrained optimization
for src_idx = 1:length(LB)
  LB(src_idx) = param.method.src_limits{src_idx}(1);
  UB(src_idx) = param.method.src_limits{src_idx}(2);
end

%% Test/Run Loop: Simulation Run Loop for each test
% =======================================================================
for run_idx = 1:param.monte.runs
  if isfield(param,'Nsig_tmp') && ~isempty(param.Nsig_tmp)
    % For model order estimation simulation.
    fprintf('q:%2d  k:%2d of %d / run %4d of %d (%.1f sec)\n', ...
      length(param.monte.DOA),param.Nsig_tmp, param.M, run_idx, param.monte.runs, toc(start_time));
  else
    if ~mod(run_idx-1,50)
      fprintf('test: %2d of %d / run %4d of %d (%.1f sec)\n', ...
        test_idx, size(param.monte.SNR,1), run_idx, param.monte.runs, toc(start_time));
    end
  end
  % Setup random number generator
  rng_args(run_idx) = param.monte.random_seed_offset + run_idx;
  rng(rng_args(run_idx));
  
  %% Test/Run Loop: Create simulated data for each simulation run
  % Hack to test position errors
%   tmp_param = [];
%   tmp_param = param;
%   c = 2.997924580003452e+08; 
%   lambda = c / param.src.fc;
%   
%   sigmay = (0.5)*lambda*0.05; 
%   er_ypc = sigmay* randn(size(param.src.y_pc));
%   er_ypc(2) = 0;
%   sigmaz = sigmay;
%   er_zpc = sigmaz* randn(size(param.src.z_pc));
%   er_zpc(2) = 0;
%   tmp_param.src.y_pc = tmp_param.src.y_pc + er_ypc;
%   tmp_param.src.z_pc = tmp_param.src.z_pc + er_zpc;
%  [Data,Rxx,imp_response,Rxx_fd] = sim.doa_wideband_data(tmp_param);
%   tmp_param = [];

    [Data,Rxx,imp_response,Rxx_fd] = sim.doa_wideband_data(param);

  %% Test/Run Loop: Set up estimation parameters for each method
  if isfield(param,'Nsig_tmp') && ~isempty(param.Nsig_tmp)
    % For model order estimation simulation.
    Rxx_runs{run_idx} = Rxx;
  end
  
  doa_wb_td_param.h    = conv(imp_response.vals,imp_response.vals,'same');
  doa_wb_td_param.h    = doa_wb_td_param.h ./ max(abs(doa_wb_td_param.h));
  doa_wb_td_param.t0   = imp_response.time_vec(1);
  doa_wb_td_param.dt   = mean(diff(imp_response.time_vec));
  doa_wb_td_param.Rxx  = Rxx;
  
  Rxx_nb_idxs = (param.method.wb_td.widening_factor-1)/2*length(param.src.y_pc) + (1:length(param.src.y_pc));
  Rxx_nb = Rxx(Rxx_nb_idxs,Rxx_nb_idxs);
%   doa_nb_1d_param.Rxx = Rxx_nb;
%   doa_nb_nd_param.Rxx = Rxx_nb;
  
  doa_nb_1d_param.Rxx = Rxx_nb;
  doa_nb_nd_param.Rxx = Rxx_nb;
  doa_wb_fd_param.Rxx = Rxx_fd;
  
  % Debug plots of impulse response
  if 0
    figure;plot(imp_response.time_vec,imp_response.vals);
    hold on
    plot(imp_response.time_vec,doa_param.h,'r')
    keyboard
  end
  
  %% Test/Run Loop: Apply DOA methods to the simulated data
  for method_idx = 1:length(param.method.list)
    method = param.method.list(method_idx);
    %fprintf('test: %2d / run: %2d / method: %2d \n', test_idx, run_idx, method);
    switch method
      case MUSIC_DOA_METHOD
        % MUSIC method: DOA initialization and estimation
        doa0 = sort(music_initialization(Rxx_nb,doa_nb_1d_param));
        
        [doa,Jval,exitflag,OUTPUT,~,~,HESSIAN] = ...
          fmincon(@(theta_hat) music_cost_function(theta_hat,doa_nb_1d_param), doa0,[],[],[],[],LB,UB,doa_nonlcon_fh,doa_nb_1d_param.options);
        
      case MLE_METHOD
        % MLE method: DOA initialization and estimation
        doa0 = sort(mle_initialization(Rxx_nb,doa_nb_nd_param));
        
        [doa,Jval,exitflag,OUTPUT,~,~,HESSIAN] = ...
          fmincon(@(theta_hat) mle_cost_function(theta_hat,doa_nb_nd_param), doa0,[],[],[],[],LB,UB,doa_nonlcon_fh,doa_nb_nd_param.options);
        
      case DCM_METHOD
        % WB DCM method: DOA initialization and estimation
        doa0 = sort(wb_initialization(Rxx,doa_wb_td_param));
        
        [doa,Jval,exitflag,OUTPUT,~,~,HESSIAN] = ...
          fmincon(@(theta_hat) wb_cost_function(theta_hat,doa_wb_td_param), doa0,[],[],[],[],LB,UB,doa_nonlcon_fh,doa_wb_td_param.options);
        
      case WBMLE_METHOD
        % WBMLE method: DOA initialization and estimation
        doa0 = sort(wbmle_initialization(Rxx_fd,doa_wb_fd_param));
        
        [doa,Jval,exitflag,OUTPUT,~,~,HESSIAN] = ...
          fmincon(@(theta_hat) wbmle_cost_function(theta_hat,doa_wb_fd_param), doa0,[],[],[],[],LB,UB,doa_nonlcon_fh,doa_wb_fd_param.options);
    end
    
    % Store outputs into variables
    if isfield(param,'Nsig_tmp') && ~isempty(param.Nsig_tmp)
      % For model order estimation simulation.
      [theta_est{method_idx}(run_idx,1,1:param.Nsig_tmp),sort_idxs] = sort(doa);
      HESSIAN = diag(HESSIAN);
      
      % for only suboptimal methods (param.subopt_only). DOA estimation not required.
      %In that case run using doa_example_suboptimal.m and the following
      %section cannot be evaluated as we do not have doa.
      
      if param.doa_example == 1
        hessian_est{method_idx}(run_idx,1,1:param.Nsig_tmp) = HESSIAN(sort_idxs);
        cost_func{method_idx}(run_idx,1) = Jval;
      end
    else
      [theta_est{method_idx}(run_idx,1,:),sort_idxs] = sort(doa);
      HESSIAN = diag(HESSIAN);
      hessian_est{method_idx}(run_idx,1,:) = HESSIAN(sort_idxs);
      cost_func{method_idx}(run_idx,1) = Jval;
    end
    
  end
  
end
