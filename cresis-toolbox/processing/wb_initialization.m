function out = wb_initialization(DCM,param)
% out = wb_initialization(DCM,param)
%
% Function used to initialize wideband estimator called in array_proc.m.
% initialization uses the alternating projection approach to initialize.
% The cost function is evaluating over a coarse grid to get a rough
% estimate of the minimimum and then a 2nd order polynomial fit is used to
% refine that estimate.
%
% Inputs:
%   DCM = complex space-time data covariance matrix with dimensions (P*W) x
%     (P*W) where P is the number of sensors and W is the widening factor
%     passed into the combine spreadsheet and accessed through
%     array_param.W.
%
%   param = control struction containing the following fields:
%     .Nsrc   = number of sources specified by array_param.Nsrc field,
%     .src_limits = 1 x param.Nsrc cell containing bounds for the
%               search, specified as DOAs in radians, of the form:
%               param.src_limits{source index} = [lowerbound upperbound]
%               Assumption is that sources are sorted from small to large
%               DOA.
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
%     .theta  = coarse grid used to evaluate cost function.  The number of
%               elements in S.theta is set by the Nsv field in the combine
%               spreadsheet.  S.theta is the FFTSHIFTED theta vector output
%               by the array_proc_sv call in array_proc.
%     .search_type = string indicating search type. 'grid' for grid search
%               (most expensive) or 'ap' for alternating projection search
%     .theta_guard = double scalar that gives the minimum separation
%               between any two sources
%
% Outputs:
%   out = Nsrc x 1 vector containing initial doa estimates in radians.
%
% Author:  Theresa Stumpf
%
% See Also:  array_proc.m, wb_cost_func.m, wb_compute_cost.m
% =========================================================================

physical_constants;

t0    = param.t0;
dt    = param.dt;
h     = param.h(:);

if isfield(param,'search_type') && strcmpi(param.search_type,'grid')
  %% Perform N-dimensional grid search
  
  % Allocate grid search results
  if param.Nsrc == 1
    J = NaN*zeros(length(param.theta),1);
  else
    J = NaN*zeros(length(param.theta)*ones(1,param.Nsrc));
  end
  % Allocate temporary variables
  theta_idxs = zeros(param.Nsrc,1);
  sizeJ = size(J);
  % Loop through every index of J and evaluate the cost function at that
  % index in the N-dimensional grid if DOA constraints allow
  for idx = 1:numel(J)
    % For this specific index into the grid, determine the index of
    % each source into the param.theta array (theta_idxs)
    tmp_idx = idx;
    for src_idx = param.Nsrc:-1:1
      idx_mod = prod(sizeJ(1:src_idx-1));
      theta_idxs(src_idx) = 1 + floor((tmp_idx-1) / idx_mod);
      tmp_idx = tmp_idx - (theta_idxs(src_idx)-1)*idx_mod;
    end
    
    % For this index into the grid, get the theta values for each source
    theta = reshape(param.theta(theta_idxs), [param.Nsrc 1]);
    
    % Determine if this is an index that we need to evaluate the cost
    % function for.
    good = true;
    for src_idx = 1:param.Nsrc
      % Make sure sources are in order and that there is guard room between
      % the sources, if not: do not evaluate this index of the grid
      if theta(src_idx) < param.src_limits{src_idx}(1) || theta(src_idx) > param.src_limits{src_idx}(2) ...
          || (src_idx > 1 && theta(src_idx) < theta(src_idx-1) + param.theta_guard)
        good = false;
        break;
      end
    end
    
    if good
      % Evaluate cost function
      uy      = sin(theta).';
      uz      = cos(theta).';
      tau     = (2/c)*(param.y_pc*uy - param.z_pc*uz)*param.sv_dielectric;
      val     = wb_compute_cost(tau, DCM, param.fc, param.fs, h, t0, dt);
      J(idx)  = 10*log10(abs(val));
    end
    
  end
  
  % Find the index to the minimum point in the grid search
  [~,tmp_idx] = nanmin(J(:));
  % Convert this 1-D index into N-D index
  for src_idx = param.Nsrc:-1:1
    idx_mod = prod(sizeJ(1:src_idx-1));
    theta_idxs(src_idx) = 1 + floor((tmp_idx-1) / idx_mod);
    tmp_idx = tmp_idx - (theta_idxs(src_idx)-1)*idx_mod;
  end
  % Get the theta for each source using N-D index
  out = reshape(param.theta(theta_idxs), [param.Nsrc 1]);
  
else
  %% Perform N-dimensional alternating projection search
  
  % Assume a single source
  
  % =========================================================================
  %% Initialization of first source
  % =========================================================================
  
  % Setup search space
  % -----------------------------------------------------------------------
  %
  % If param.src_limits was specified, only look at thetas bounded by
  % param.src_limits.  Otherwise use the entire coarse grid stored in param.theta.
  indexes = (param.theta >= param.src_limits{1}(1)) & (param.theta <= param.src_limits{1}(end));
  if all(indexes==0)
    search_theta = mean(param.src_limits{1});
  else
    search_theta = param.theta(indexes);
  end
  
  % Evaluate cost cunction over coarse grid whose step size is set by
  % array_param.Nsv
  J   = NaN(size(search_theta));
  for idx = 1:length(search_theta);
    theta   = search_theta(idx);
    uy      = sin(theta).';
    uz      = cos(theta).';
    tau     = (2/c)*(param.y_pc*uy - param.z_pc*uz)*param.sv_dielectric;
    val     = wb_compute_cost(tau, DCM, param.fc, param.fs, h, t0, dt);
    J(idx)  = 10*log10(abs(val));
  end
  
  % Minimize Cost Function
  % -----------------------------------------------------------------------
  % Find minimium of J.  If min falls on an edge, then just use the edge.
  % Otherwise, find minimum index and adjacent neighbors.  Then use a
  % second order polynomial fit to J to refine estimate.
  [~,min_idx] = nanmin(J);
  
  if min_idx == 1 || min_idx == length(search_theta)
    theta0(1,1) = search_theta(min_idx);
  else
    theta_rng = search_theta(min_idx - 1: min_idx + 1);
    Jvals     = J(min_idx - 1: min_idx + 1);
    p         = polyfit(theta_rng(:),Jvals(:),2);
    a         = p(1);
    b         = p(2);
    theta0(1,1) = -b/(2*a);
  end
  
  % =========================================================================
  %% Initialization of additional sources
  % =========================================================================
  if param.Nsrc > 1
    
    % Loop over sources and estimate each direction
    for src_idx = 2:param.Nsrc;
      clear J uy uz min_idx search_theta
      
      % If param.src_limits was specified, only look at thetas bounded by
      % param.src_limits.  Otherwise use the entire coarse grid stored in param.theta.
      indexes = (param.theta >= param.src_limits{src_idx}(1)) & (param.theta <= param.src_limits{src_idx}(end));
      if all(indexes==0)
        search_theta = mean(param.src_limits{src_idx});
      else
        search_theta = param.theta(indexes);
      end
      
      % Avoid evaluating cost function around previous sources
      prev_doa = theta0(theta0 >= search_theta(1) & theta0 <= search_theta(end));
      if ~isempty(prev_doa)
        for prev_idx = 1:length(prev_doa)
          mask_doa = prev_doa(prev_idx);
          
          bad_index = find(search_theta > prev_doa(prev_idx),1) - 1;
          
          if ~isempty(bad_index)
            bad_rng = bad_index - 1:bad_index + 1;
            bad_mask = bad_rng < 1 | bad_rng > length(search_theta);
            bad_rng = bad_rng(~bad_mask);
            search_theta(bad_rng) = NaN;
          end
        end
      end
      
      search_theta  = search_theta(~isnan(search_theta));
      
      if isempty(search_theta)
        search_theta = mean(param.src_limits{src_idx});
      end
      
      % Evaluate cost function over coarse grid whose step size is set by
      % array_param.Nsv
      J = NaN(size(search_theta));
      for idx = 1:length(search_theta);
        theta_i = search_theta(idx);
        theta   = [theta_i;theta0];
        uy      = sin(theta).';
        uz      = cos(theta).';
        tau     = (2/c)*(param.y_pc*uy - param.z_pc*uz)*param.sv_dielectric;
        val     = wb_compute_cost(tau, DCM, param.fc, param.fs, h, t0, dt);
        J(idx)  = 10*log10(abs(val));
      end
      
      [~,min_idx] = nanmin(J);
      
      if min_idx == 1 || min_idx == length(search_theta)
        theta0(src_idx,1) = search_theta(min_idx);
      elseif any(isnan(J(min_idx - 1:min_idx + 1)))
        theta0(src_idx,1) = search_theta(min_idx);
      else
        theta_rng = search_theta(min_idx - 1: min_idx + 1);
        Jvals     = J(min_idx - 1: min_idx + 1);
        p         = polyfit(theta_rng(:),Jvals(:),2);
        a         = p(1);
        b         = p(2);
        theta0(src_idx,1) = -b/(2*a);
      end
    end
  end
  out = theta0;
  
end
