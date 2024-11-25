function out = mle_initialization(Rxx,param)
% out = mle_initialization(Rxx,param)
%
% Function used to initialize maximum likelihood stimator called in
% array_proc.m. Uses the alternating projection approach to initialize.
% The cost function is evaluated over a coarse grid to get a rough
% estimate of the minimimum and then a 2nd order polynomial fit is used to
% refine that estimate.
%
% Inputs:
%   Rxx = data covariance matrix
%
%   param = control struction containing the following fields:
%     .Nsig   = number of sources specified by array_param.Nsrc field,
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
%     .theta  = coarse grid used to evaluate cost function.  The number of
%               elements in S.theta is set by the Nsv field in the combine
%               spreadsheet.  S.theta is the FFTSHIFTED theta vector output
%               by the array_proc_sv call in array_proc. RADIANS
%     .search_type = string indicating search type. 'grid' for grid search
%               (most expensive) or 'ap' for alternating projection search
%     .theta_guard = double scalar that gives the minimum separation
%               between any two sources
%
% Outputs:
%   out = Nsig x 1 vector containing initial doa estimates in radians.
%
% Author:  Theresa Stumpf
%
% See Also:  array_proc.m, mle_cost_function.m, mle_compute_cost.cpp
% =========================================================================

%% mle_initialization:  Input Checks
% =========================================================================
if ~isfield(param,'sv_dielectric') || isempty(param.sv_dielectric)
  param.sv_dielectric = 1;
end

if ~isfield(param,'sv_fh') || isempty(param.sv_fh) 
  param.sv_fh = @array_proc_sv;
end

if ~isfield(param,'lut') || isempty(param.lut) 
  param.lut = [];
end

if ~isfield(param,'lut_roll') || isempty(param.lut_roll)
  param.lut_roll = [];
end

if ~isfield(param,'search_type') || isempty(param.search_type)
  param.search_type = 'grid';
end

if ~isfield(param,'doa_seq') || isempty(param.doa_seq)
  param.doa_seq = false;
end

if ~isfield(param,'apriori') || isempty(param.apriori)
  param.apriori.en = false;
end

c = 2.997924580003452e+08; % physical_constants too slow

k = 4*pi*param.fc/c;
M = param.Nsrc;

if isfield(param,'search_type') && strcmpi(param.search_type,'grid')
  %% Perform N-dimensional grid search
  
  % Allocate grid search results
  if param.Nsrc == 1
    J = NaN(length(param.theta),1);
  else
    J = NaN(length(param.theta)*ones(1,param.Nsrc));
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
      if (theta(src_idx) < param.src_limits{src_idx}(1) || theta(src_idx) > param.src_limits{src_idx}(2)) ...
          || (src_idx > 1 && theta(src_idx) < theta(src_idx-1) + param.theta_guard)
        good = false;
        break;
      end
    end
    
    if good
      % Evaluate cost function
      sv_opt_arg.theta = theta.';
      sv_arg = {param.fc*sqrt(param.sv_dielectric),param.y_pc,param.z_pc, sv_opt_arg, param.lut, param.lut_roll};
      [~,A] = param.sv_fh(sv_arg{:});

%       [~,A] = array_proc_sv(Nsv2,param.fc*param.sv_dielectric,param.y_pc,param.z_pc);
%       A = sqrt(1/length(param.y_pc)) * exp(1i*k*(-param.z_pc*cos(theta).' + param.y_pc*sin(theta).'));
      Pa  = A * inv(A'*A) * A';
      if  param.doa_seq && param.apriori.en
        J(idx) = -(M*size(A,1)) * log(abs(sum(sum((eye(size(Pa))-Pa) .* Rxx.'))));
      else
        J(idx) = abs(sum(sum(Pa .* Rxx.')));
      end
      
      % Incorporate the a priori pdf if available
      if  param.doa_seq && param.apriori.en
        if 1
          mean_doa = param.apriori.mean_doa;
          var_doa  = param.apriori.var_doa;
          J_prior = -1/2*(1./var_doa).' * (theta - mean_doa).^2;
        else
          % DON'T USE IT ..NOT FINALIZED YET
          f_prior = log(param.apriori.f_prior);
          theta_range = param.apriori.theta_range;
          for doa_i = 1:length(theta)
            [~,match_i(doa_i)] = min(abs(theta_range(:) - theta(doa_i)));
          end
          J_prior = prod(f_prior(match_i));
        end
        J(idx) =  J(idx) + J_prior;
        
        if isinf(J(idx))
          J(idx) = 99999;
        end
      end
    end
    
  end
  
  % Find the index to the minimum point in the grid search
  [~,tmp_idx] = nanmax(J(:));
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
  
  % Setup Cb as defined in Ziskind and Wax.  Normally on estimating the ith
  % source, Cb = (I-Pa)*C where I is the identity matrix, Pa is the
  % projection matrix formed by A where A is the Nc x (Nsig - 1) matrix that
  % models the array manifold of all sources not equal to i and C is the Nc x
  % Nsv matrix of steering vectors in the search range.  On the estimation of
  % the first source, A is not yet constrained and Cb is equal to C.
  if isfield(param,'src_limits') && ~isempty(param.src_limits{1})
    mask = (param.theta >= param.src_limits{1}(1)) & (param.theta <= param.src_limits{1}(end));
    search_theta = param.theta(mask);
    Cb            = param.SV(:,mask);
  else
    search_theta = param.theta;
    Cb            = param.SV;
  end
  
  
  % Initialize first source
  % -------------------------------------------------------------------------
  B             = Cb ./ (repmat(sqrt(sum(abs(Cb).^2,1)),size(Rxx,1),1));
  L = zeros(size(B,2),1);
  for theta_idx = 1:size(B,2)
    b = B(:,theta_idx);
    L(theta_idx) = abs(b'*Rxx*b);
  end
  [~,max_idx]   = max(L);
  
  % Enables 2nd order polynomial fit to refine estimate of the first peak
  % instead of just using MATLAB's max function
  if 1
    if max_idx == 1 || max_idx == length(search_theta)
      out(1,1) = search_theta(max_idx);
    else
      theta_rng = search_theta(max_idx - 1: max_idx + 1);
      Lvals     = L(max_idx - 1: max_idx + 1);
      p         = polyfit(theta_rng(:),Lvals(:),2);
      a         = p(1);
      b         = p(2);
      out(1,1) = -b/(2*a);
    end
    
  else
    out(1,1) = search_theta(max_idx);
  end
  
  % =========================================================================
  % Initialize remaining sources
  % =========================================================================
  if param.Nsrc > 1
    clear L max_idx
    for src_idx = 2:param.Nsrc
      % If param.src_limits was specified, only look at thetas bounded by
      % param.src_limits.  Otherwise use the entire coarse grid stored in param.theta.
      if isfield(param,'src_limits') && ~isempty(param.src_limits{src_idx})
        mask = (param.theta >= param.src_limits{src_idx}(1)) & (param.theta <= param.src_limits{src_idx}(end));
      else
        mask = logical(ones(size(param.theta)));
      end
      
      % Avoid evaluating cost function around previous sources
      for old_src_idx = 1:src_idx-1
        mask = mask & ~(param.theta >= out(old_src_idx,1)-param.theta_guard  ...
          & param.theta <= out(old_src_idx,1)+param.theta_guard);
      end
      search_theta = param.theta(mask);
      if isempty(search_theta)
        error('No valid search_theta, but looking for another source. Consider reducing the theta_guard, increasing src_limits, or reducing the model order.');
      end
      
      search_theta  = search_theta(~isnan(search_theta));
      L             = NaN(size(search_theta));
      
      % Setup steering vectors
      theta_eval  = [out(:).',search_theta]; % search range has same meaning as   theta_i in [Ziskind and Wax]
      sv_opt_arg.theta = theta_eval;
      sv_arg = {param.fc*sqrt(param.sv_dielectric),param.y_pc,param.z_pc, sv_opt_arg, param.lut, param.lut_roll};
      [~,SVs] = param.sv_fh(sv_arg{:});
%       k           = 4*pi*param.fc/c;
%       ky          = k*sin(theta_eval);
%       kz          = k*cos(theta_eval);
%       SVs         = sqrt(1/length(param.y_pc)) * exp(1i*(-param.z_pc*kz + param.y_pc*ky));
      A           = SVs(:,1:numel(out));
      C           = SVs(:,numel(out)+1:end);
      Pa          = A * inv(A'*A) * A';
      Cb          = (eye(size(Pa,1))-Pa)*C;
      B           = bsxfun(@rdivide, Cb, sqrt(sum(abs(Cb).^2,1)));

      % Evaluate likelihood function
      L           = abs(diag(B'*Rxx*B));
      
      % Maximize cost function
      [~,max_idx] = max(L);
      
      % Polynomial fit
      if max_idx == 1 || max_idx == length(search_theta)
        out(src_idx,1) = search_theta(max_idx);
      else
        theta_rng = search_theta(max_idx - 1: max_idx + 1);
        Lvals     = L(max_idx - 1: max_idx + 1);
        p         = polyfit(theta_rng(:),Lvals(:),2);
        a         = p(1);
        b         = p(2);
        out(src_idx,1) = -b/(2*a);
      end
    end
  end
end

return
