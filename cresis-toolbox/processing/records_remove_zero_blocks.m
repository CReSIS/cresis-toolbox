% script records_remove_zero_blocks
%
% DEALS WITH ERRORS IN 2012 ANTARCTICA DC8 RAW DATA
%
% This function takes the results from find_zero_blocks and removes all
% records that have zero blocks occuring in them.
%
% See also find_zero_blocks.m (need to run that first).

% fn = '/N/dc/projects/cresis/2012_Chile_DC8/mcords/20121025/board0/mcords2_0_20121025_135855_00_0001.bin'

% params = read_param_xls('/N/u/jpaden/Quarry/scripts/branch/params-cr1/snow_param_2012_Antarctica_DC8.xls');
% params = read_param_xls('/users/paden/scripts/branch/params-cr1/snow_param_2012_Antarctica_DC8.xls');
params = read_param_xls('/users/paden/scripts/branch/params-cr1/kuband_param_2012_Antarctica_DC8.xls');
% params = read_param_xls('/users/paden/scripts/branch/params-cr1/mcords_param_2012_Antarctica_DC8.xls');
adc = 1;

zero_blocks = [];
for param_idx = 1:length(params)
  param = params(param_idx);
  
  if param.cmd.generic
    fprintf('Removing zero blocks from records %s\n', param.day_seg);
    [base_dir,adc_folder_name,fns,file_idxs] = get_segment_file_list(param,adc);
    
    zero_blocks_fn = ct_filename_support(param,'','zero_blocks');
    zero_blocks = load(zero_blocks_fn);
    
    records = records_load(param);
    records_mask = zeros(size(records.lat));
    
    frames_fn = ct_filename_support(param,'','frames');
    load(frames_fn);
    
    %     rec_size = median(diff(records.offset));
    
    for file_idx = 1:length(zero_blocks.zero_idxs)
      if ~isempty(zero_blocks.zero_idxs{file_idx})
        %records.relative_filename{1}
        %[fn_dir fn fn_ext] = fileparts(zero_blocks.fns{file_idx});
        %fn = [fn fn_ext];
        % The filename associated with this file:
        %records.relative_filename{1}{file_idx}
        % The records associated with this file:
        recs = records.relative_rec_num{1}(file_idx) : records.relative_rec_num{1}(file_idx+1)-1;
        
        % The record offsets associated with this file:
        %records.offset(recs)
        bad_mask = zeros(size(recs));
        
        % Zero blocks in this file
        for zero_idx = 1:length(zero_blocks.zero_idxs{file_idx})
          start = find(records.offset(recs) > 4*zero_blocks.zero_idxs{file_idx}(zero_idx),1) - 1;
          if isempty(start)
            start = 1;
          end
          stop = find(records.offset(recs) <= ...
            4*zero_blocks.zero_idxs{file_idx}(zero_idx) ...
            + 4*zero_blocks.num_zeros{file_idx}(zero_idx) - 1, 1, 'last');
          if isempty(stop)
            % All the zeros happen before the first record?? Could happen
            % and just need to type dbcont... but should check things out first.
          else
            records_mask(recs(1)-1 + (start:stop)) = 1;
          end
        end
      end
    end
    
    old_records = records;
    good_mask = ones(size(records_mask));
    for bad_rec = fliplr(find(records_mask))
      records.relative_rec_num{1}(records.relative_rec_num{1} > bad_rec) ...
        = records.relative_rec_num{1}(records.relative_rec_num{1} > bad_rec) - 1;
      frames.frame_idxs(frames.frame_idxs > bad_rec) ...
        = frames.frame_idxs(frames.frame_idxs > bad_rec) - 1;
    end
    records.offset = records.offset(~records_mask);
    records.lat = records.lat(~records_mask);
    records.lon = records.lon(~records_mask);
    records.elev = records.elev(~records_mask);
    records.roll = records.roll(~records_mask);
    records.pitch = records.pitch(~records_mask);
    records.heading = records.heading(~records_mask);
    records.gps_time = records.gps_time(~records_mask);
    records.surface = records.surface(~records_mask);
    records.notes = [records.notes sprintf('\nFIND_ZERO_BLOCKS\nRemoved %d records due to zero blocks in raw data.\n',sum(records_mask))];
%     records.raw.zero_blocks.zero_idxs = zero_blocks.zero_idxs;
%     records.raw.zero_blocks.num_zeros = zero_blocks.num_zeros;
    records.raw.zero_blocks.records_mask = records_mask;
    if ~exist('/tmp/records/','dir')
      mkdir('/tmp/records/');
    end
    movefile(records_fn,'/tmp/records/');
    save(records_fn,'-struct','records');
    
    if ~exist('/tmp/frames/','dir')
      mkdir('/tmp/frames/');
    end
    movefile(frames_fn,'/tmp/frames/');
    save(frames_fn,'frames');
  end
end

