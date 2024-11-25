function tomo_quick_loader
% tomo_quick_loader
%
% Simple script for viewing 3D imagery.
%
% Author: John Paden

%% User Settings

% 1. Specify filename in fn
% 2. Specify start range bin to plot (rbin) and how many range bins(rbins) of
% leave blank.

% Example of multipass datasets
if 0
  % Camp Century Multipass
  fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_multipass/camp_century_2011_2012_2013_2014_music.mat';
  
  rbin = [250]; % Start bin
  rbins = [200]; % Number of bins
  
elseif 0
  % Herc
  fn = '/cresis/snfs1/dataproducts/ct_data/rds/2019_Antarctica_Ground/CSARP_music3D/20200107_01/Data_img_03_20200107_01_001.mat';
  
  % Multipass
  rbin = [200]; % Start bin
  rbins = [500]; % Number of bins
  
elseif 0
  % Summit Multipass
  fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_multipass/summit_2012_2014_allwf_2012_music.mat';

  % Multipass
  rbin = [200]; % Start bin
  rbins = [500]; % Number of bins
  
elseif 1
  % EGIG Multipass
  fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_multipass/egig_2011_2012_2014_2018_allwf_2014_music.mat';

  % Multipass
  rbin = [60]; % Start bin
  rbins = [940]; % Number of bins
  rbin = [100]; % Start bin
  rbins = [400]; % Number of bins
  
elseif 0
  % CAA 3D
  fn = '/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_music3D/20140325_07/Data_img_02_20140325_07_004.mat';
  
  rbin = [300]; % Start bin
  rbins = [250]; % Number of bins
  
elseif 0
  % Eqip 3D
  fn ='/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_music3D_Nsrc3_rbins3/20140414_02/Data_img_02_20140414_02_012.mat';
  % fn ='/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_music3D_Nsrc3_rbins3/20140414_02/Data_img_02_20140414_02_013.mat';
  % fn ='/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_music3D_Nsrc3_rbins3/20140414_02/Data_img_03_20140414_02_013.mat';
  % fn ='/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_music3D/20140414_02/Data_img_02_20140414_02_013.mat';
  % fn ='/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_music3D/20140414_02/Data_img_03_20140414_02_013.mat';
  % fn ='/cresis/snfs1/dataproducts/ct_data/rds/2014_Greenland_P3/CSARP_music3D_single/20140414_02/Data_img_03_20140414_02_013.mat';
  % music3D_Nsrc3_rbins3
  
  rbin = [250]; % Start bin
  rbins = [200]; % Number of bins
  
elseif 0
  % 2018 Greenland P3
  fn ='/N/dcwan/projects/cresis/output/rds/2018_Greenland_P3/CSARP_music3D/20180406_01/Data_img_01_20180406_01_001.mat';
  fn ='/N/dcwan/projects/cresis/output/rds/2018_Greenland_P3/CSARP_music3D/20180406_01/Data_img_01_20180406_01_002.mat';
  
  rbin = [600]; % Start bin
  rbins = [1000]; % Number of bins

end

%% Automated Section

mdata = load(fn);

mdata.Nt = size(mdata.Tomo.img,1);
mdata.Nx = size(mdata.Tomo.img,3);
mdata.rline = 1;
if ~exist('rbin','var') || isempty(rbin)
  rbin = 1;
end
mdata.rbin = rbin;
if ~exist('rbins','var') || isempty(rbins)
  rbins = mdata.Nt;
end
mdata.rbins = rbins;

mdata.h_fig = figure;
mdata.h_axes = axes('parent',mdata.h_fig);
mdata.h_image = imagesc([],mdata.rbin+(0:mdata.rbins-1),10*log10(mdata.Tomo.img(mdata.rbin+(0:mdata.rbins-1),:,mdata.rline)), 'parent', mdata.h_axes);
xlabel(mdata.h_axes, 'Elevation angle bin');
ylabel(mdata.h_axes, 'Range bin');
set(mdata.h_fig,'WindowKeyPressFcn',@music_quick_loader_keyboard);
title(mdata.h_axes, sprintf('rline %d',mdata.rline));
set(mdata.h_fig,'UserData',mdata);

% Cycle through all range bins
fprintf('Run "clear global mdata" to remove this large variable from memory when finished.\n');
fprintf('Press "->" to move forward one range line.\n');
fprintf('Press "<-" to move backward one range line.\n');
fprintf('Press "up" to move up one range bin.\n');
fprintf('Press "down" to move down one range bin.\n');
fprintf('Press shift when moving to move ten bins or lines.\n');

end

%% music_quick_loader_keyboard
function music_quick_loader_keyboard(h_object,event)

if any(strcmpi(event.Modifier,'shift'))
  step = 10;
else
  step = 1;
end

if ~isempty(event.Key)
  mdata = h_object.UserData;
  
  % see event.Modifier for modifiers
  switch event.Key
    
    case 'uparrow' % Up arrow
      if mdata.rbin > step
        mdata.rbin = mdata.rbin - step;
      end
      
    case 'downarrow' % Down arrow
      if mdata.rbin < mdata.Nt-mdata.rbins+2-step
        mdata.rbin = mdata.rbin + step;
      end
      
    case 'rightarrow' % Right arrow
      if mdata.rline < mdata.Nx+1-step
        mdata.rline = mdata.rline + step;
      end
      
    case 'leftarrow' % Left arrow
      if mdata.rline > step
        mdata.rline = mdata.rline - step;
      end
      
    otherwise
      return;
  end
  set(mdata.h_image,'CData',10*log10(mdata.Tomo.img(mdata.rbin+(0:mdata.rbins-1),:,mdata.rline)))
  set(mdata.h_image,'YData',mdata.rbin+(0:mdata.rbins-1));
  ylim(mdata.rbin+[0 mdata.rbins-1]);
  title(mdata.h_axes, sprintf('rline %d',mdata.rline));
  set(h_object,'UserData',mdata);
end

end
