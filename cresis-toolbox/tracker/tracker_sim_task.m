function [success] = tracker_sim_task(param)



fprintf('Task is starting (%s)\n', datestr(now));

% script tracker_sim
%
% Script for simulating broadband sounder data over the ice sheet (e.g.
% like snow radar or kuband radar). This is currently just a prototype
% script.
%
% Author: John Paden


Nt = 1000; % Number of fast time samples
num_incoh_ave = 11; % No of incoherent averages
Nx = 256 * num_incoh_ave; % No of slow-time samples

surf_bin = 200;

rng('shuffle')

% Function handlers
signal_power_fh = @(x) 15*exp(-x/3000)-20;
noise_power = -5;
mean_layer_fh = @(x) 75*exp(-x/1500);
var_layer_fh = @(x) 0.3*exp(-x/1000);

var_spread_fh = @(x) 8*exp(-x/1000);
var_spread_gauss = 1; 
var_spread_exp = 2; 
corr_len = 200;
corr_len_spread = 0*num_incoh_ave;

sinc_width = 2;

num_layers = param.tracker_sim.num_layers;
% num_layers = 25;

layer_power = 1.5*randn(1,num_layers+1);
layer_power(1) = layer_power(1) + 3;
layer_power(2) = layer_power(2) + 1;

% =======================
tracker_sim_tstart = tic;

bins = (1:Nt).';
rlines = 1:Nx;


% Preallocate layers matrix. Layers matrix contains the range bin or row
% for each layer.
layers = zeros(num_layers,Nx);

for layer_idx = 1:num_layers

  if layer_idx == 1
    mean_thickness = mean_layer_fh(zeros(1,Nx));
    var_thickness = var_layer_fh(zeros(1,Nx));
  else
    mean_thickness = mean_layer_fh(layers(layer_idx-1,:));
    var_thickness = var_layer_fh(layers(layer_idx-1,:));
  end
  
  [B,A] = butter(2,1/corr_len);
  
  %layer_spread = sqrt(var_thickness/2) * randn(1,Nx).^2;
  var_thickness = [ones(1,2*corr_len)*var_thickness(1) var_thickness ones(1,2*corr_len)*var_thickness(end)];
  tmp = sqrt(var_thickness) .* randn(1,Nx + 4*corr_len);
  layers(layer_idx,:) = tmp(1+2*corr_len : end - 2*corr_len);
  %plot(layers(layer_idx,:)); hold on;
  
  % Filter layer
  tmp = filtfilt(B,A,tmp)*corr_len;
  layers(layer_idx,:) = tmp(1+2*corr_len : end - 2*corr_len);
  %plot(layers(layer_idx,:)); hold on;
  
  % Add in mean thickness
  layers(layer_idx,:) = layers(layer_idx,:) + mean_thickness;
  %plot(layers(layer_idx,:)); hold on;
  
  % Set negative thickness to zero thickness
  layers(layer_idx,layers(layer_idx,:) < 0) = 0;
  %plot(layers(layer_idx,:)); hold on;
  
  % Sum thickness to previous layer
  if layer_idx > 1
    layers(layer_idx,:) = layers(layer_idx-1,:) + layers(layer_idx,:);
  end
  
%   plot(layers(layer_idx,:),'LineWidth',2); hold on;
end

fprintf('Exiting the first loop: to be deleted afterwards \n');

% Append surface layer
layers = [zeros(1,Nx); layers];
% Add in surface bin offset to all layers
layers = layers + surf_bin;

% =======================
% Convolution (sidelobes)
% figure(2); clf;
Data = zeros(Nt,Nx);

% [B,A] = butter(2,1/corr_len_spread);

num_spread = 100; 


var_spread = (var_spread_gauss*randn(num_layers+1,Nx+4*corr_len_spread,num_spread) + var_spread_exp*randn(num_layers+1,Nx+4*corr_len_spread,num_spread).^2);
% var_spread = permute(filtfilt(B,A,permute(var_spread,[2 1 3])),[2 1 3]);
var_spread = var_spread(:,1+2*corr_len_spread:end-2*corr_len_spread,:);

% Add layer_power fading along-track here

% Add cross-track clutter and winter storm layers here

warning('Test %d \n', num_layers);

for layer_idx = 1:num_layers+1
warning('Second Loop begin (%d of %d) (%s)\n', layer_idx, num_layers, datestr(now));
whos
fprintf('%d',num_spread);
  for rline = 1:Nx
    for spread_idx = 1:num_spread
      signal_power = (randn(1)+1i*randn(1))/sqrt(2) * 10.^((layer_power(layer_idx) + signal_power_fh(layers(layer_idx,rline)-surf_bin))/20);
      % Write a comment
      
      if layer_idx == 1
        var_spread(layer_idx,rline,spread_idx) = sqrt(var_spread_fh(0)) ...
          * var_spread(layer_idx,rline,spread_idx);
      else
        var_spread(layer_idx,rline,spread_idx) = sqrt(var_spread_fh(layers(layer_idx-1,rline))) ...
          * var_spread(layer_idx,rline,spread_idx);
      end
      
      Data(:,rline) = Data(:,rline) + signal_power * sinc((bins - layers(layer_idx,rline) - var_spread(layer_idx,rline,spread_idx))/sinc_width).^2; % This gave a sinc^2 plot
      %plot(lp(Data(:,rline))); hold on
      
    end
  end
    toc(tracker_sim_tstart);
  warning('Second Loop ends %d \n', layer_idx);
end
warning('Test Complete');


% =======================
% Noise (noise variance)
% Data = abs(Data).^2 + sum((10.^(noise_power/20/2)*randn(Nt,Nx,num_incoh_ave)).^2,3)/num_incoh_ave;
Data = abs(Data).^2 + sum((10.^(noise_power/20/2)*randn(Nt,Nx,1)).^2,3)/1;
H = hanning(2*num_incoh_ave+1).';
H = H / sum(H);
Data = fir_dec(Data,H,num_incoh_ave);
layers = fir_dec(layers,H,num_incoh_ave);
Nx = Nx / num_incoh_ave;


% Create raster image
raster = zeros(size(Data));
layers2 = round(layers);

for layer_idx = 1:size(layers2,1)  
  for layer_col = 1:size(layers2,2)    
    tmp = layers2(layer_idx,layer_col); % This idx represents the column of the layer    
    if raster(tmp,layer_col) == 0      
      raster(tmp,layer_col) = layer_idx;
    end    
  end  
end

raster = uint8(raster);

%% Create directories if they don't exist
base_m = fullfile(param.tmp_path,param.tracker_sim.output_dir);

if ~exist('base_m', 'dir')  
   mkdir(base_m);
end

base_layer_bin = fullfile(base_m,'layer_bin');
base_layer = fullfile(base_m,'layer');
base_image = fullfile(base_m,'image');

if ~exist('base_layer_bin', 'dir')  
   mkdir(base_layer_bin);
end

if ~exist('base_layer', 'dir')  
   mkdir(base_layer);
end

if ~exist('base_image', 'dir')  
   mkdir(base_image);
end


%% Save data and plots
 
% Save Data.png
Data2 = lp(Data);
max_data = max(Data2(:));
min_data = min(Data2(:));
% Create and save .png
new_data = uint8(255*((Data2 - min_data)/(max_data-min_data)));

fn_data_png = fullfile(base_image,sprintf('image_%06d.png',param.tracker_sim.img_idx));
fprintf('Saving the .mat files  %s \n',datestr(now));
imwrite(new_data,fn_data_png);

% Saving Data .mat 
fn_data_mat = fullfile(base_image,sprintf('image_%06d.mat',param.tracker_sim.img_idx));
fprintf('Saving %s (%s)\n', fn_data_mat, datestr(now));
save(fn_data_mat,'-v7.3','Data');

% Save layer data as .png
fn_layer_png = fullfile(base_layer,sprintf('layer_%06d.png',param.tracker_sim.img_idx));
fprintf('Saving %s (%s)\n', fn_layer_png, datestr(now));
imwrite(raster,fn_layer_png);

% Save layer data as .mat
fn_layer_mat = fullfile(base_layer,sprintf('layer_%06d.mat',param.tracker_sim.img_idx));
fprintf('Saving %s (%s)\n', fn_layer_mat, datestr(now));
save(fn_layer_mat,'-v7.3','raster','layers2');

% Save layer_binary data as .png 
fn_layer_png = fullfile(base_layer_bin,sprintf('layer_binary_%06d.png',param.tracker_sim.img_idx));
fprintf('Saving %s (%s)\n', fn_layer_png, datestr(now));
imwrite(logical(raster),fn_layer_png);

toc(tracker_sim_tstart);

%% Done
% =========================================================================

fprintf(' done %s\n', datestr(now));

success = true;
