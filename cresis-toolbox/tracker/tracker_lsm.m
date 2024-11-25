function labels = tracker_lsm(data,track)
% labels = tracker_lsm(data,track)
%
% data: echogram image
%
% labels: 2*N_iter by Nx array of layers. First N_iter layers are the
% surface and the second N_iter layers are the bottom.

% Create LSM object and pass in data
obj = tomo.LSMObject_tuning({data});

% Set parameters
obj.setLSMOptions('y', track.lsm.y, ...
  'dy', track.lsm.dy, ...
  'storeIter', track.lsm.storeIter, ...
  'outerIter', max(track.lsm.storeIter));

% Run LSM
[flag, Labels.top, Labels.bot, matrix_x, matrix_y] = obj.runLSM();

% Interpolate contour outputs to image columns
% Nx: Number of image columns
Nx = size(data,2);
% N_iter: Number of iterations stored by LSM
N_iter = length(track.lsm.storeIter);
% Preallocate output
labels = nan(N_iter,Nx);

labels_idx = 0;
for layer_idx = 1:2 % [surface bottom]
  for iter_idx = 1:N_iter % Stored iterations
    try
      labels_idx = labels_idx + 1;
      labels(labels_idx,:) = interp1(matrix_x(layer_idx,:,iter_idx),matrix_y(layer_idx,:,iter_idx),1:Nx,'linear','extrap');
    catch ME
      warning('LSM contour failed to produce a layer for layer %d iteration %d.', layer_idx, iter_idx);
      continue
    end
  end
end
