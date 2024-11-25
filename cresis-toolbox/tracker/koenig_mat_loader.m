% koenig_mat_loader
%
% Script which converts Koenig's snow radar image/layer mat files into
% 256 column files for ingest into a tracker. Creates a binary file
% of where layers exist, a layer file where layer indices are included,
% and an image file. The outputs are in .mat and .png formats.

%% User Settings
% Lora Koenig
base_dir = '/cresis/snfs1/dataproducts/public/data/temp/internal_layers/NASA_OIB_test_files/image_files/greenland_picks_final_2009-2012_20140602';
out_dir = '/cresis/snfs1/dataproducts/public/data/temp/internal_layers/NASA_OIB_test_files/image_files/greenland_picks_final_2009_2012_reformat/';
year_dir_type = 1;

% Lynn Montgomery
% base_dir = '/cresis/snfs1/dataproducts/public/data/temp/internal_layers/NASA_OIB_test_files/image_files/Corrected_SEGL_picks_lnm_2009_2017';
% out_dir = '/cresis/snfs1/dataproducts/public/data/temp/internal_layers/NASA_OIB_test_files/image_files/Corrected_SEGL_picks_lnm_2009_2017_reformat/';
% year_dir_type = 2;

block_size = 256;
block_overlap = 6;
debug_plot = false;

% Trim first top_crop range bins/rows
% Trim everything bottom_pad range bins/rows past the last layer
% Ensure atleast min_size rows
top_crop = 150;
bottom_pad = 100;
min_size = 300;

%% Automated Section
% fns = get_filenames(base_dir, 'layers_','dec','.mat',struct('recursive',true));

old_day_seg = '';
total_along_track = 0; % Keep track of how many line-km are processed
for fn_idx = 1:length(fns)
  fn = fns{fn_idx};
  [fn_dir,fn_name] = fileparts(fn);
  fprintf('%d of %d (%s)\n', fn_idx, length(fns), datestr(now));
  fprintf('  %s\n', fn);
  
  tmp = load(fn);
  
  % Keep track of how many line-km are processed
  along_track = geodetic_to_along_track(tmp.lat, tmp.lon);
  total_along_track = total_track + along_track(end);
  
  if debug_plot
    % Plot whole file
    figure(1); clf;
    imagesc(tmp.data_out)
    colormap(1-gray(256));
  end
  
  good_rline = ~any(isnan(tmp.data_out));
  rline = find(good_rline,1);
  while ~isempty(rline)
    rline_end = find(~good_rline(rline:end),1)-2 + rline;
    if isempty(rline_end)
      rline_end = size(tmp.data_out,2);
    end
    if rline_end >= rline + block_size
      rline_end = rline + block_size-1;
    end
    
    if rline_end-rline+1 >= block_size
      % Break into Nt by block_size images
      data =  tmp.data_out(:,rline:rline_end);
      layer = tmp.arr_layers(:,rline:rline_end);
      
      new_layer = {};
      max_layer = top_crop + min_size - bottom_pad;
      for lay_idx = 1:30
        [~,y] = max(tmp.arr_layers(:,rline:rline_end)==lay_idx);
        y(y==1) = NaN; % Assume 1-index max index implies no layer in this column
        max_layer = max(max_layer,max(y));
        new_layer{lay_idx} = y;
      end
      
      % Trim image
      data  =  data(1+top_crop:min(end,max_layer+bottom_pad),:);
      if 0
        min_data = min(data(:));
      else
        noise_floor = min(mean(data,2));
        min_data = noise_floor-10;
      end
      max_data = max(data(:));
      data = uint8((data-min_data)/(max_data-min_data)*255);
      layer = uint8(layer(1+top_crop:min(end,max_layer+bottom_pad),:));
      
      if debug_plot
        % Plot block image
        figure(2); clf;
        imagesc(data);
        colormap(1-gray(256));
        hold on
        for lay_idx = 1:30
          % Plot layer
          plot(new_layer{lay_idx}-top_crop);
        end
        figure(3); clf;
        imagesc(layer);
      end
      
      % Save the new image and new layer index bitmap
      if year_dir == 1
        [~,year_dir] = fileparts(fileparts(fn_dir));
      elseif year_dir_type == 2
        [~,year_dir] = fileparts(fn_dir);
        year_dir = year_dir(1:4);
      end
      if fn_name(20) == 'd'
        % layers_20100514_01_dec77.mat
        % Already has segment
        day_seg = fn_name(8:18);
      else
        % layers_20100514B_dec77.mat
        % layers_20100514_dec77.mat
        % Add segment "_01" to filename
        if fn_name(16) == '_'
          day_seg = [fn_name(8:15) '_01'];
        else
          day_seg = [fn_name(8:15) sprintf('_%02d',fn_name(16)-'A'+1)];
        end
      end
      if ~strcmp(day_seg,old_day_seg)
        block = 1;
        old_day_seg = day_seg;
      end
      out_fn = fullfile(out_dir,year_dir,sprintf('data_%s_%03d.mat',day_seg,block));
      fprintf('    Save %s\n', out_fn);
      save(out_fn,'-v7.3','data','fn','rline');
      
      out_fn = fullfile(out_dir,year_dir,sprintf('data_%s_%03d.png',day_seg,block));
      fprintf('    Save %s\n', out_fn);
      imwrite(data,out_fn);
      
      out_fn = fullfile(out_dir,year_dir,sprintf('layer_%s_%03d.mat',day_seg,block));
      fprintf('    Save %s\n', out_fn);
      save(out_fn,'-v7.3','layer','fn','rline');
      
      out_fn = fullfile(out_dir,year_dir,sprintf('layer_%s_%03d.png',day_seg,block));
      fprintf('    Save %s\n', out_fn);
      imwrite(layer,out_fn);

      out_fn = fullfile(out_dir,year_dir,sprintf('layer_binary_%s_%03d.png',day_seg,block));
      fprintf('    Save %s\n', out_fn);
      imwrite(logical(layer),out_fn);
      
      block = block + 1;
      
      if debug_plot
        % Pause here for debug/view
        %       pause(0.5);
        keyboard
      end
      rline = find(good_rline(rline_end+1:end),1)+rline_end - block_overlap;
      if rline < size(tmp.data_out,2)-block_overlap-block_size*0.25
        % Adjust rline search so that the last part of the file will be
        % included even though it will be greater block overlap
        rline = min(size(tmp.data_out,2)-block_size,rline);
      end
    else
      rline = find(good_rline(rline_end+1:end),1)+rline_end;
    end
  end
end
