function status = unblock_data(param,unblock_data_param)



   % 1(b) Iterate over each of the file
   % 1(c) Intersect and concatenate GPS time
    unblock_param = unblock_data_param.unblock_data;
   
    base_layers_dir = unblock_param.tracked_layers_dir_path;
    search_str = unblock_param.echo_search_str;
    
    all_layer_fn = get_filenames(base_layers_dir, 'image','0','.mat',struct('recursive',true));    
    
    dest_prefix = unblock_param.dest_layer_prefix;
    
    echo_day_seg_path = ct_filename_out(param,unblock_param.echo_path); 
    echo_fns = get_filenames(echo_day_seg_path, search_str,'0','.mat',struct('recursive',true));    
    echo_tmp = load(echo_fns{1});    
    
    % Need to comfirm if tmp.Time is different for compressed and
    % uncompressed data
    if unblock_param.uncompress_en      
      echo_tmp = uncompress_echogram(echo_tmp);
    end          

    gps_combined = [];
    layers_combined = [];
    twtt_combined = [];
    rounding_combined = [];


    for block_idx = 1:length(all_layer_fn)

      temp = load(all_layer_fn{block_idx}); % loads each block struct
      [num_layers,~] = size(temp.layer); 
      
      loc_idx = ~ismember(temp.GPS_time,gps_combined); % Get index of unique GPS_time
      
      if 1
        fprintf('\n %d unique GPS_time for block %d',sum(loc_idx),block_idx)
      end
      
      % Get reference filtered surface    
      ref_surface = temp.surf_index(:,loc_idx); % block's filtered surface   
      ref_surface = ref_surface - temp.top_gap - 1; % Remove top_gap     

      ref_surface = repmat(ref_surface, num_layers,1); % Matrix of ref_surface

      gps_combined = [gps_combined temp.GPS_time(loc_idx) ];
      rounding_combined = [rounding_combined temp.offset_rounding(loc_idx)];

      shifted_layers = temp.layer(:,loc_idx)  + ref_surface ; % Add surface to layers
      
      layer_twtt = interp1(1:length(echo_tmp.Time),echo_tmp.Time,shifted_layers,'linear','extrap');
      
      if unblock_param.add_offset
        layer_twtt(1,:) = layer_twtt(1,:) + temp.offset_rounding(loc_idx);
      end
      
      twtt_combined = [twtt_combined  layer_twtt ] ;          

    end 
        


  %% Copy to destination using opsCopyLayers
  for layer_idx = 1:num_layers

      if layer_idx == 1
        copy_param.layer_dest.name = 'surface';
      elseif layer_idx == num_layers 
         copy_param.layer_dest.name = 'bottom';
      else
        copy_param.layer_dest.name = [dest_prefix num2str(layer_idx)];
      end

    copy_param.layer_source.source = 'custom';
    copy_param.layer_source.gps_time = gps_combined;
    copy_param.layer_source.twtt = twtt_combined(layer_idx,:) ;

    copy_param.layer_dest.source = unblock_param.layer_dest_source;
    copy_param.layer_dest.layerdata_source = unblock_param.layer_dest_layerdata_source; %CSARP_post/layerData'
    copy_param.layer_dest.existence_check = unblock_param.layer_dest.existence_check;

    copy_param.copy_method = unblock_param.copy_method; %'fillgaps' or 'overwrite'
    copy_param.gaps_fill.method = unblock_param.gaps_fill_method; %'preserve_gaps';  %interp_finite


    %% Copy layers to LayerData    
   
      fprintf('opsCopyLayers %s (%s)\n', param.day_seg, datestr(now));
      opsCopyLayers(param,copy_param);
      fprintf('  Complete (%s)\n', datestr(now));
  end

  status = true;
  



