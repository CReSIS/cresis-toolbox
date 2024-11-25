% script check_posted_images
%
% Checks posted images (map and echogram). This is a script for quickly and
% conveniently checking a few CSARP_post images in each segment to ensure
% proper operation. Often it is better to view the images in the Windows
% file explorer since all images can be viewed quickly this way by setting
% the view setting to "view large icons" or similar, but this script is
% available when that is not an option.
%
% Author: John Paden

base_dir = '/N/dc/projects/cresis/output/snow/2012_Antarctica_DC8/CSARP_post/images/';
% base_dir = '/N/dc/projects/cresis/output/kuband/2012_Antarctica_DC8/CSARP_post/images/';

% Set the search string here to select specific segments or all segments in
% the base_dir
input_dirs = get_filenames(base_dir, '2012','','',struct('type','d'));

% Just look at a sample of num_images images per segment
num_images = 4;

% =========================================================================
% Automated Section

figure(1); clf;
h_axes = axes;
set(h_axes,'Position',[0 0 1 1]);
set(h_axes,'TickDir','out');
h_image = imagesc(1,'Parent',h_axes);

figure(2); clf;
h_axes2 = axes;
set(h_axes2,'Position',[0 0 1 1]);
set(h_axes2,'TickDir','out');
h_image2 = imagesc(1,'Parent',h_axes2);

for dir_idx = 1:length(input_dirs)
  fprintf('dir_idx = %d\n', dir_idx);
  input_dir = input_dirs{dir_idx};
  fns = get_filenames(input_dir,'','','echo.jpg');
  fn_idxs = unique(round(linspace(2,length(fns)-1,num_images)));
  % Look at every image:
  %fn_idxs = 1:length(fns);
  % Check for the case of very short segments
  if length(fns) < 2
    fn_idxs = 1;
  end
  for fn_idx = fn_idxs
    fn = fns{fn_idx};
    
    done = false;
    while ~done
      try
        A = imread(fn);
        done = true;
      catch ME
        ME
        pause;
      end
    end
    fprintf('  %s\n', fn);
    figure(1);
    set(h_image,'CData',A);
    axis tight;
    zoom reset;

    fn(end-8:end) = '0maps.jpg';
    done = false;
    while ~done
      try
        A = imread(fn);
        done = true;
      catch ME
        ME
        pause;
      end
    end
    fprintf('  %s\n', fn);
    figure(2);
    set(h_image2,'CData',A);
    axis tight;
    zoom reset;
    
    pause;
  end
end

