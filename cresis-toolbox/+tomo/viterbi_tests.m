% Standalone test environment for viterbi implementation
% Author: Reece Mathews

function viterbi_tests()
  global matrix layer layers;
  
  % CONSTANTS
  rows = 20;
  cols = 15;
  surf = 5;
  mult = 10;
  grnd = 17;
  matrix = zeros(rows, cols);
  matrix(surf, :) = ones(1, cols) * 30; % Surface
  matrix(mult, :) = ones(1, cols) * 20; % Mult 1
  matrix(grnd, :) = ones(1, cols) * 10; % Bottom
  
  surf_layer = ones(1, cols) * surf;
  gt_layer = nan(1, cols);
  gt_layer([5 10]) = [16 16];
  
  surf_costs = ones(1, cols) * 100;
  gt_costs = nan(1, cols);
  gt_costs(~isnan(gt_layer)) = 0;

  surf_cutoffs = nan(1, cols);
  gt_cutoffs = nan(1, cols);
  gt_cutoffs(~isnan(gt_layer)) = 2;

  layers = [surf_layer; gt_layer];
  layer_costs = [surf_costs; gt_costs];
  layer_cutoffs = [surf_cutoffs; gt_cutoffs];

  % Viterbi params
  transition_weights = ones(1, cols-1);
  img_mag_weight = 1;
  
  mult_weight = 10;
  mult_weight_decay = .3;
  mult_weight_local_decay = .7;

  zero_bin = 1;
  
  % Other environment vars
  mask = inf*ones(1, cols);
  slope = round(diff(layers(1, :)));
  max_slope = -1;
  bounds = [5 10];
  mask_dist = inf(1, cols);
  cost_matrix = ones(rows,cols);
  
  matrix = echo_norm(matrix,struct('scale',[-40 90]));
  
  % RUN
  layer = tomo.viterbi(matrix, layers, layer_costs, layer_cutoffs, mask, ...
    img_mag_weight, slope, max_slope, int64(bounds), [], mask_dist, cost_matrix, ...
    transition_weights, mult_weight, mult_weight_decay, mult_weight_local_decay, ...
    int64(zero_bin));
  hfig = setup();
  resize(hfig);
  
end

function plot_viterbi()
  global layer layers;
  
  hold on;
  
  idxs = find(~isnan(layers(2, :)));
  scatter(idxs, layers(2, idxs), 'rx');
  
  plot(layer, 'g');
      
  hold off;
end


function hfig = setup() 
  if ishandle(1)
    hfig = figure(1);
  else
    hfig = figure('SizeChangedFcn', @resize);
  end
end


function resize(src,~)
  global matrix;
  
  r = size(matrix, 1);
  c = size(matrix, 2);
  
  % Plot matrix
  clf;
  colormap(1-gray);
  imagesc(matrix);
  
  % X-axis
  xticks(.5:(c + .5));
  xlim([.5 (c + .5)]);
  xticklabels('');
  
  % Y-axis
  yticks(.5:(r + .5));
  ylim([.5 (r + .5)]);
  yticklabels('');
  grid;
  
  w = src.Position(3);
  h = src.Position(4);
  axes_pos = get(gca, 'Position');

  left = axes_pos(1) * w;
  bottom = axes_pos(2) * h;

  xmargin = axes_pos(3)*w/c;
  ymargin = axes_pos(4)*h/r;
  dimensions = [r c];
  for axis = 1:2
    for i = 1:dimensions(axis)
      char = uicontrol('Style', 'text', 'String', sprintf('%d | %d', i-1, i), 'FontSize', 10);
      char_pos = get(char, 'Extent');
      char_width = char_pos(3);
      char_height = char_pos(4);
      if axis == 2
        set(char, 'Position', [left + xmargin*i - xmargin/2 - char_width/2, bottom - char_height * 1.25, char_width, char_height]);
      else
        set(char, 'Position', [left - char_width * 1.25, bottom + ymargin*(r-i) + ymargin/2 - char_height/2, char_width, char_height]);
      end
    end
  end
 
  plot_viterbi();
end
