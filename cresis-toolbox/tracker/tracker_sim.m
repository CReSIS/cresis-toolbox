% script tracker_sim
%
% Script for simulating broadband sounder data over the ice sheet (e.g.
% like snow radar or kuband radar). This is currently just a prototype
% script.
%
% Author: John Paden

Nt = 1000;
num_incoh_ave = 11;
Nx = 256 * num_incoh_ave;

surf_bin = 200;

signal_power_fh = @(x) 15*exp(-x/200)-20;
noise_power = -5;
mean_layer_fh = @(x) 75*exp(-x/1500);
var_layer_fh = @(x) 60*exp(-x/1000);

var_spread_fh = @(x) 8*exp(-x/1000);
var_spread_gauss = 1;
var_spread_exp = 2;
corr_len = 200;
corr_len_spread = 0*num_incoh_ave;

sinc_width = 2;

num_layers = 3;
num_layers = 25;
layer_power = 1.5*randn(1,num_layers+1);
layer_power(1) = layer_power(1) + 3;
layer_power(2) = layer_power(2) + 1;

% =======================
tracker_sim_tstart = tic;

bins = (1:Nt).';
rlines = 1:Nx;

plot(bins, mean_layer_fh(bins));

layers = zeros(num_layers,Nx);

% rng(0);

figure(1); clf;
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
  tmp = filtfilt(B,A,tmp)*sqrt(corr_len);
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
  
  plot(layers(layer_idx,:),'LineWidth',2); hold on;
end
% Append surface layer
layers = [zeros(1,Nx); layers];
% Add in surface bin offset to all layers
layers = layers + surf_bin;

% =======================
% Convolution (sidelobes)
figure(2); clf;
Data = zeros(Nt,Nx);

% [B,A] = butter(2,1/corr_len_spread);
num_spread = 100;
var_spread = (var_spread_gauss*randn(num_layers+1,Nx+4*corr_len_spread,num_spread) + var_spread_exp*randn(num_layers+1,Nx+4*corr_len_spread,num_spread).^2);
% var_spread = permute(filtfilt(B,A,permute(var_spread,[2 1 3])),[2 1 3]);
var_spread = var_spread(:,1+2*corr_len_spread:end-2*corr_len_spread,:);

% Add layer_power fading along-track here
% layer_power_fade = 

% Add cross-track clutter and winter storm layers here

for layer_idx = 1:num_layers+1
  for rline = 1:Nx
    for spread_idx = 1:num_spread
      signal_power = (randn(1)+1i*randn(1))/sqrt(2) * 10.^((layer_power(layer_idx) + signal_power_fh(layers(layer_idx,rline)-surf_bin))/20);
      
      if layer_idx == 1
        var_spread(layer_idx,rline,spread_idx) = sqrt(var_spread_fh(0)) ...
          * var_spread(layer_idx,rline,spread_idx);
      else
        var_spread(layer_idx,rline,spread_idx) = sqrt(var_spread_fh(layers(layer_idx-1,rline))) ...
          * var_spread(layer_idx,rline,spread_idx);
      end
      
      Data(:,rline) = Data(:,rline) + signal_power * sinc((bins - layers(layer_idx,rline) - var_spread(layer_idx,rline,spread_idx))/sinc_width);
      %plot(lp(Data(:,rline))); hold on
    end
  end
end
toc(tracker_sim_tstart);

% =======================
% Noise (noise variance)
% Data = abs(Data).^2 + sum((10.^(noise_power/20/2)*randn(Nt,Nx,num_incoh_ave)).^2,3)/num_incoh_ave;
Data = abs(Data).^2 + sum((10.^(noise_power/20/2)*randn(Nt,Nx,1)).^2,3)/1;
H = hanning(2*num_incoh_ave+1).';
H = H / sum(H);
Data = fir_dec(Data,H,num_incoh_ave);
layers = fir_dec(layers,H,num_incoh_ave);
Nx = Nx / num_incoh_ave;

figure(1);
clf;
imagesc(lp(Data))
colormap(1-gray(256));

figure(2);
clf;
imagesc(lp(Data))
colormap(1-gray(256));
hold on;
plot(layers.');

figure(3);
clf;
plot(lp(Data(:,Nx/2)));
grid on;
