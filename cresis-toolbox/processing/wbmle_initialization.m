function out = wbmle_initialization(DCM,param)
% out = wbmle_initialization(DCM,param)
%
% Function used to initialize maximum likelihood stimator called in
% array_proc.m. Uses the alternating projection approach to initialize.
% The cost function is evaluated over a coarse grid to get a rough
% estimate of the minimimum and then a 2nd order polynomial fit is used to
% refine that estimate.
%
% Inputs:
%   DCM = data covariance matrix
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
% See Also:  array_proc.m, mle_cost_function.m, mle_compute_cost.cpp
% =========================================================================
physical_constants

Nk = param.nb_filter_banks;
k = 4*pi*(param.fc + param.fs*[0:floor((Nk-1)/2), -floor(Nk/2):-1]/Nk)/c*param.sv_dielectric;

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
      if (theta(src_idx) < param.src_limits{src_idx}(1) || theta(src_idx) > param.src_limits{src_idx}(2)) ...
          || (src_idx > 1 && theta(src_idx) < theta(src_idx-1) + param.theta_guard)
        good = false;
        break;
      end
    end
    
    if good
      % Evaluate cost function
      for k_idx = 1:Nk
        A = sqrt(1/length(param.y_pc)) * exp(1i*k(k_idx)*(-param.z_pc*cos(theta).' + param.y_pc*sin(theta).'));
        Pa  = A * inv(A'*A) * A';
        if k_idx==1
          J(idx) = abs(sum(sum(Pa .* DCM((k_idx-1)*size(DCM,2)+(1:size(DCM,2)),:).')));
        else
          J(idx) = J(idx) + abs(sum(sum(Pa .* DCM((k_idx-1)*size(DCM,2)+(1:size(DCM,2)),:).')));
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
  % projection matrix formed by A where A is the Nc x (Nsrc - 1) matrix that
  % models the array manifold of all sources not equal to i and C is the Nc x
  % Nsv matrix of steering vectors in the search range.  On the estimation of
  % the first source, A is not yet constrained and Cb is equal to C.
  if isfield(param,'src_limits') && ~isempty(param.src_limits{1})
    indexes = (param.theta >= param.src_limits{1}(1)) & (param.theta <= param.src_limits{1}(end));
    search_theta = param.theta(indexes);
    Cb            = param.SV(:,indexes);
  else
    search_theta = param.theta;
    Cb            = param.SV;
  end
  
  
  % Initialize first source
  % -------------------------------------------------------------------------
  L = zeros(length(search_theta),1);
  for idx = 1:length(search_theta)
    theta = search_theta(idx);
    for k_idx = 1:Nk
      A = sqrt(1/length(param.y_pc)) * exp(1i*k(k_idx)*(-param.z_pc*cos(theta).' + param.y_pc*sin(theta).'));
      Pa  = A * inv(A'*A) * A';
      if k_idx==1
        L(idx) = abs(sum(sum(Pa .* DCM((k_idx-1)*size(DCM,2)+(1:size(DCM,2)),:).')));
      else
        L(idx) = L(idx) + abs(sum(sum(Pa .* DCM((k_idx-1)*size(DCM,2)+(1:size(DCM,2)),:).')));
      end
    end
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
        indexes = (param.theta >= param.src_limits{src_idx}(1)) & (param.theta <= param.src_limits{src_idx}(end));
        search_theta = param.theta(indexes);
      else
        search_theta = param.theta;
      end
      
      % Avoid evaluating cost function around previous sources
      prev_doa = out(out >= search_theta(1) & out <= search_theta(end));
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
      
      L = zeros(length(search_theta),1);
      for idx = 1:length(search_theta)
        theta = [out(:).', search_theta(idx)].';
        for k_idx = 1:Nk
          A = sqrt(1/length(param.y_pc)) * exp(1i*k(k_idx)*(-param.z_pc*cos(theta).' + param.y_pc*sin(theta).'));
          Pa  = A * inv(A'*A) * A';
          if k_idx==1
            L(idx) = abs(sum(sum(Pa .* DCM((k_idx-1)*size(DCM,2)+(1:size(DCM,2)),:).')));
          else
            L(idx) = L(idx) + abs(sum(sum(Pa .* DCM((k_idx-1)*size(DCM,2)+(1:size(DCM,2)),:).')));
          end
        end
      end
      [~,max_idx]   = max(L);
  
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
