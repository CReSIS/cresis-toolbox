function load_info = get_raw_files_sub(param,wf_adc_list,records,recs)
% load_info = get_raw_files_sub(param,wf_adc_list,records,recs)
%
% Support function for get_raw_files

% boards_headers: the boards that the actual adc headers were loaded from
[boards,board_idx,~] = wf_adc_to_board(param,wf_adc_list);

% Populate load_info struct
load_info = [];
for idx = 1:length(boards)
  board = boards(idx);
  
  load_info.file_idx = relative_rec_num_to_file_idx_vector(recs,records.relative_rec_num{board_idx(idx)});
  if records.offset(board_idx(idx),recs(1)) < 0 && records.offset(board_idx(idx),recs(1)) ~= -2^31
    % Record offset is negative, but not -2^31: this means the record
    % started in the previous file.
    load_info.file_idx = [load_info.file_idx(1)-1 load_info.file_idx];
  end
  load_info.offset(idx,:) = records.offset(board_idx(idx),recs);
  [file_idxs,~,load_info.file_idx] = unique(load_info.file_idx);
  load_info.filenames{idx} = records.relative_filename{board_idx(idx)}(file_idxs);
  load_info.board_idx(idx) = board_idx(idx);
  
  if param.records.file.version == 414
    % Convert filenames
    
    % Find adc,wf from board
    adc = mod(board-1,12) + 1;
    wf = floor((board-1)/12) + 1;
    BW = (param.radar.wfs(wf).f1-param.radar.wfs(wf).f0)/1e6;
    Tpd = param.radar.wfs(wf).Tpd*1e6;
    if adc<5
      subarray = 'Port';
      rx = sprintf('P%X',adc);
    elseif adc<9
      subarray = 'Belly';
      rx = sprintf('B%X',adc);
    else
      subarray = 'Star';
      rx = sprintf('S%X',adc);
    end
    
    if all(param.radar.wfs(wf).tx_weights == [2000 2000 2000 2000 0 0 0 0 0 0 0 0])
      tx = 'P1234';
    else
      tx = 'S9ABC';
    end
    
    if length(param.radar.wfs(wf).weight) < adc || param.radar.wfs(wf).weight(adc) > 0
      zeropimod = 'C';
    else
      zeropimod = 'J';
    end
    
    for fn_idx = 1:length(load_info.filenames{idx})
      % Get the file's name
      fn_name = load_info.filenames{idx}{fn_idx};
      [fn_dir] = get_segment_file_list(param,board_idx(idx));
      
      fname = fname_info_bas(fn_name);
      
      fn_subdir = sprintf('%s%s_new',fname.name,subarray);
      fn_name = sprintf('%s%s_%s_Tx%s_Rx%s_%s%02.0fL%.0f_T01_%04.0f.mat', ...
        fname.name, subarray, datestr(fname.datenum,'YYYYmmDDHHMMSS'), tx, rx, zeropimod, ...
        BW, Tpd, fname.file_idx);
      fn = fullfile(fn_dir,fn_subdir,fn_name);
      %fprintf('%s\n', fn);
      load_info.filenames{idx}{fn_idx} = fn;
    end
  else
    for fn_idx = 1:length(load_info.filenames{idx})
      % Get the file's name
      fn_name = load_info.filenames{idx}{fn_idx};
      [fn_dir] = get_segment_file_list(param,board_idx(idx));
      fn = fullfile(fn_dir,fn_name);
      %fprintf('%s\n', fn);
      load_info.filenames{idx}{fn_idx} = fn;
    end
    
  end
end
