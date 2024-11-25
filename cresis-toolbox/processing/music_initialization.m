function out = music_initialization(Rxx,param)
% out = music_initialization(Rxx,param)
%
% Function used to get an initial estimate of source locations in MUSIC
% spectrum. Called in array_proc for method = 9 (music_doa).
%
% Inputs:
%   Rxx   = sample covariance matrix (Nc x Nc), estimated in array_proc
%
%   param = control structure containing the following fields
%     .y_pc = Nc x 1 vector containing y coordinates of phase centers in
%             SAR FCS (meters),
%     .z_pc = Nc x 1 vector containing z coordinates of phase centers in
%             SAR FCS (meters),
%     .src_limits = 1 x param.Nsrc cell containing bounds for the
%               search, specified as DOAs in radians, of the form:
%               param.src_limits{source index} = [lowerbound upperbound]
%               Assumption is that sources are sorted from small to large
%               DOA.
%     .theta = 1 x Nsv coarse grid that MUSIC pseudospectrum is evaluated
%               over,
%     .
% Outputs:
%   out  = Nsrc x 1 vector containing initial estimate of DOAs in
%             units that agree with those of param.theta.
%
% Author: Theresa Stumpf
%
% See also: array_proc.m, music_cost_function.m
% =========================================================================

[V,D]                   = eig(Rxx);
eigenVals               = diag(D);
[eigenVals, eigenValIdxs]  = sort(real(eigenVals),'descend');
V                       = V(:,eigenValIdxs);
noiseIdxs = param.Nsrc+1:length(eigenVals);
% noiseIdxs               = noiseIdxs(1:end - param.Nsrc);
Qn                      = V(:,noiseIdxs);
S                       = mean(abs(param.SV(:,:)' * Qn).^2,2);

if 0
  % Debug: plot MUSIC pseudospectrum
  figure;plot(param.theta*180/pi,1./S,'-*')
end
% Search for first peak in first range (if none, then choose max point)
% Then search for first peak in second range, if same peak as first range
% or violates guard then keep searching for peak. If don't find another peak,
% then assign to last successful peak (if none, then choose max point).

[vals,loc] = findpeaks(-S);
[~,idxs]= sort(vals,1,'descend');
loc = loc(idxs(1:min(param.Nsrc,length(loc))));
loc = sort(loc);

theta_guard = 1.5/180*pi;
for src_idx = 1:param.Nsrc
  % Search for first peak in range
  potential_loc = 0;
  good_loc = 0;
  for loc_idx = 1:length(loc)
    if param.theta(loc(loc_idx)) >= param.src_limits{src_idx}(1) && param.theta(loc(loc_idx)) <= param.src_limits{src_idx}(2)
      % Found a peak in the valid region
      potential_loc = loc(loc_idx);
      % Check guard and sorting requirements
      if src_idx == 1 || param.theta(loc(loc_idx)) >= out(src_idx-1) + theta_guard
        out(src_idx) = param.theta(loc(loc_idx));
        good_loc = true;
        break;
      end
    end
  end

  if ~good_loc
    if potential_loc
      out(src_idx) = param.theta(potential_loc);
    else
      % Choose max in region
      if src_idx == 1
        low_lim = param.src_limits{src_idx}(1);
      else
        low_lim = max(param.src_limits{src_idx}(1),out(src_idx-1) + theta_guard);
      end
      indices = find(param.theta >= low_lim ...
          & param.theta <= param.src_limits{src_idx}(2));
      if isempty(indices)
        [~,indices] = min(abs(param.theta - mean([low_lim,param.src_limits{src_idx}(2)]) ));
      end
      [~,out(src_idx)] = max(-S(indices));
      out(src_idx) = param.theta(indices(out(src_idx)));
    end
  end
end

return

for src_idx = 1:param.Nsrc
  indexes = find(param.theta >= param.src_limits{src_idx}(1) ...
    & param.theta <= param.src_limits{src_idx}(end));

  good_idx = [];
  for loc_idx = 1:length(loc)
    good_idx = find(indexes == loc(loc_idx),1);
    if ~isempty(good_idx)
      break
    end
  end
  if ~isempty(good_idx)
    theta0(src_idx) = param.theta(loc(loc_idx));
    loc = loc([1:loc_idx-1 loc_idx+1:end]);
  else
    theta0(src_idx) = mean(param.src_limits{1});
  end
  
end

end
