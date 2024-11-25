% Run create_segments_raw_file_list_v2 with:
%  1. adcs set to the adcs that work (e.g. if adcs 6 and 7 have good
%     headers adcs = 6:7;)
% Edit create_segments_raw_file_list_v2 with:
%  1. Change the sync to '01600558'
%     --> Check that this sync works by running "FIND SYNC" code in this
%         script.
%  2. Point hdr loading to a valid file:
%  3. Set adcs to the ones that do not work (e.g. if adcs 1-5,8 failed:
%     adcs = [1:5,8];
%  3. Run, but dbquit at counter correction since we only need the
%     temporary files.
% Update the fields in this script (see "%% Load temp header files + records file")
% Run this script

%% FIND SYNC CODE
if 0
  fn = '/mnt/HDD0/1805101801/UWB/chan1/mcords5_01_20180510_113214_00_0007.bin';
  fn = '/run/media/administrator/AWI_SSD1a/1805112001/UWB/chan1/mcords5_01_20180511_113507_00_0044.bin';
  %fn = '/mnt/HDD0/1805101801/UWB/chan6/mcords5_06_20180510_112936_00_0000.bin';

  fid = fopen(fn,'r','ieee-be');
  A = fread(fid,1e5,'int16=>int16');
  fclose(fid);
  
  figure(1); clf;
  plot(A);

  % Zoom in and print out contents of A that are static in each header
  
  % For example, we found this at the beginning of each waveform
  % wf 1
  %       2 <-- 40
  %     256 <-- 42
  %     352 <-- 44
  %    1368 <-- 46
  
  % wf 2
  %     258 = 256+2
  %     768
  %     952
  %    2568
  
  % wf 3
  %    514 = 512+2
  %    9215
  %    2352
  %    8264

  % CHOOSE ONE AND DETERMINE HEX CODE:
  % A(885:888)
  %   ans =
  %       2
  %     256
  %     352
  %    1368
  % dec2hex(typecast(A(888:-1:887),'uint32'))
  %   ans =
  %   1600558
  
  % We chose to use this one, it was 44 bytes from the header start. The
  % header was identified by having 48 bytes, 40 bytes of which were zero.
  % Either side of the header had what appeared to be small valued data
  % samples.
  % This one worked because the values were large and not likely to occur
  % normally in the data stream. The sequence [2 256] did not work
  % because it was too common.

  % Double check your 32-bit sequence will work as a frame sync:
  [finfo] = frame_sync_info(fn1,struct('sync','01600558'));
  %[finfo] = frame_sync_info(fn6,struct('sync','1ACFFC1D'));
  % 00020100
  plot(diff(finfo.syncs))
  
end

%% Load temp header files + records file
if 1
  sync_offset = 44;
%   param.day_seg = '20180510_01';
%   epri_offsets = [-133 -133 -133 -133 -133 0 0 -133 ];
%   trim_records = [0 0];
%   records_fn = '/home/administrator/Scratch/csarp_support/records/rds/2018_Greenland_Polar6/records_20180510_01.mat';
%   param.adc_folder_name = '1805101801/UWB/chan%d';
  param.day_seg = '20180510_02';
  epri_offsets = [-73 -73 -73 -73 -73 -11 -11 -73]-31;
  bad_records_start = [31 31 31 31 31 0 0 31];
  records_fn = '/home/administrator/Scratch/csarp_support/records/rds/2018_Greenland_Polar6/records_20180510_02.mat';
  param.adc_folder_name = '1805101902/UWB/chan%d';
  

  param.radar_name = 'mcords5';
  param.clk = 1.6e9/8;
  adcs = 1:8;
  raw_file_suffix = '.bin';
  reuse_tmp_files = true; % Set to false if you want to overwrite current results
  file_prefix_override = ''; % most of the time
  counter_correction_en = true;
  union_time_epri_gaps = true;
  
  % Parameters below this point OFTEN NEEDS TO BE CHANGED
  param.season_name = '2018_Greenland_Polar6';
  %base_dir = '/run/media/administrator/AWI_SSD1b/';
  base_dir = '/mnt/HDD0/';
  file_midfix = ''; % Data files must contain this string in the middle of their name (usually should be empty)
  day_string = '20180510'; % Only used for stdout print of the vectors worksheet
  
  
  [output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);
  
  if isempty(file_prefix_override)
    file_prefix = radar_name;
  else
    file_prefix = file_prefix_override;
  end
  if ~exist('file_regexp','var')
    file_regexp = '';
  end
  get_fns_param.regexp = file_regexp;
  
  
  offset = [];
  file_num = [];
  epri = [];
  epri_approx = [];
  seconds = [];
  fraction = [];
  counter = [];
  cur_epri = 0;
  figure(1); clf;
  for adc_idx = 1:length(adcs)
    % Get the files for this ADC
    adc = adcs(adc_idx);
    board = adc_to_board(param.radar_name,adc);
    adc_folder_name = param.adc_folder_name;
    adc_folder_name = regexprep(adc_folder_name,'%02d',sprintf('%02.0f',adc));
    adc_folder_name = regexprep(adc_folder_name,'%d',sprintf('%.0f',adc));
    adc_folder_name = regexprep(adc_folder_name,'%b',sprintf('%.0f',board));
    
    fns = get_filenames(fullfile(base_dir,adc_folder_name), file_prefix, file_midfix, raw_file_suffix, get_fns_param);
    fns_list{adc_idx} = fns;
    
    offset{adc_idx} = [];
    file_num{adc_idx} = [];
    epri{adc_idx} = [];
    epri_approx{adc_idx} = [];
    seconds{adc_idx} = [];
    fraction{adc_idx} = [];
    counter{adc_idx} = [];
    cur_epri = epri_offsets(adc_idx);
    for fn_idx = 1:length(fns_list{adc_idx})
      fn_idx
      fn = fns_list{adc_idx}{fn_idx};
      [~,fn_name] = fileparts(fn);
      
      tmp_hdr_fn = ct_filename_ct_tmp(rmfield(param,'day_seg'),'','headers', ...
        fullfile(adc_folder_name, [fn_name '.mat']));
      
      hdr = load(tmp_hdr_fn);
      %     if
      %       continue;
      %     end
      finfo = dir(fn);
      %finfo.bytes
      last_bytes = finfo.bytes - hdr.offset(end);
      
      offset{adc_idx}(end+(1:length(hdr.offset))) = hdr.offset;
      file_num{adc_idx}(end+(1:length(hdr.offset))) = fn_idx;
      epri{adc_idx}(end+(1:length(hdr.offset))) = hdr.epri;
      
      epri_approx{adc_idx}(end+(1:length(hdr.offset))) ...
        = cur_epri + round((last_bytes+hdr.offset) ./ median(diff(hdr.offset)));
      
      seconds{adc_idx}(end+(1:length(hdr.offset))) = hdr.seconds;
      fraction{adc_idx}(end+(1:length(hdr.offset))) = hdr.fraction;
      counter{adc_idx}(end+(1:length(hdr.offset))) = hdr.counter;
      
      cur_epri = epri_approx{adc_idx}(end);
      %   pause
      
    end
    plot(epri_approx{adc_idx})
    hold on;
    
  end
  legend('1','2','3','4','5','6','7','8');
  
  [records_fn_dir,records_fn_name,records_fn_ext] = fileparts(records_fn);
  archive_records_fn = fullfile(records_fn_dir,['archive_' records_fn_name records_fn_ext]);
  if ~exist(archive_records_fn,'file')
    copyfile(records_fn, archive_records_fn);
  end

  records = load(archive_records_fn);
  
  records.param_records.records.file.adcs = 1:8;
  records.param_records.records.file.adc_headers = 1:8;
  
end

%% Map records.epri to epri_approx
if 1
  ref_idx = 6;
  ref_cur_idx = zeros(size(records.raw.epri));
  ref_cur_idx(1) = find(records.raw.epri(1) == epri{ref_idx});
  for rec=2:length(records.raw.epri)
    % Find records.epri(rec) in epri{ref_idx}
    ref_cur_idx(rec) = ref_cur_idx(rec-1) + 1;
    while epri{ref_idx}(ref_cur_idx(rec)) < records.raw.epri(rec)
      ref_cur_idx(rec) = ref_cur_idx(rec) + 1;
    end
  end
  
end

%% Extract new record info
if 1
  new_offset = zeros(length(adcs),length(records.raw.epri));
  new_relative_filename = {};
  new_relative_rec_num = {};
  new_file_num = {};
  for adc_idx = 1:length(adcs)
    cur_idx = zeros(size(records.raw.epri));
    bad_mask = logical(zeros(size(records.raw.epri)));
    adc_idx
    
    for rec=1:length(records.raw.epri)
      %records.epri(rec)
      %epri{ref_idx}(ref_cur_idx)
      
      if rec == 1
        cur_idx(rec) = 1;
      else
        cur_idx(rec) = cur_idx(rec-1) + 1;
      end
      while cur_idx(rec) <= length(epri_approx{adc_idx}) && epri_approx{adc_idx}(cur_idx(rec)) < epri_approx{ref_idx}(ref_cur_idx(rec))
        cur_idx(rec) = cur_idx(rec) + 1;
      end
      if cur_idx(rec) > length(epri_approx{adc_idx})
        cur_idx(rec:end) = cur_idx(rec) - 1;
        bad_mask(rec:end) = true;
        break;
      end
      if epri_approx{adc_idx}(cur_idx(rec)) > epri_approx{ref_idx}(ref_cur_idx(rec))
        cur_idx(rec) = cur_idx(rec) - 1;
        bad_mask(rec) = true;
      end
      
    end
    
    if any(adcs(adc_idx) == [6 7])
      new_offset(adc_idx,:) = offset{adc_idx}(cur_idx);
    else
      new_offset(adc_idx,:) = offset{adc_idx}(cur_idx)-44;
    end
    new_offset(adc_idx,bad_mask) = -2^31;
    new_relative_filename{adc_idx} = fns_list{adc_idx}.';
    
    new_file_num{adc_idx} = file_num{adc_idx}(cur_idx);
    for fn_idx = 1:length(new_relative_filename{adc_idx})
      new_relative_rec_num{adc_idx}(fn_idx) = find(new_file_num{adc_idx}==fn_idx,1);
    end
    
  end
end

%% Update Records Struct
if 1
  % Convert end of file records into negative offsets since they span files
  for adc_idx = 1:length(adcs)
    for fn_idx = 2:length(new_relative_filename{adc_idx})
      rec = new_relative_rec_num{adc_idx}(fn_idx);
      if new_offset(adc_idx,rec) > 0 && new_offset(adc_idx,rec-1) > 0
        % Previous record change
        new_relative_rec_num{adc_idx}(fn_idx) = new_relative_rec_num{adc_idx}(fn_idx)-1;
        finfo = dir(new_relative_filename{adc_idx}{fn_idx-1});
        new_offset(adc_idx,rec-1) = new_offset(adc_idx,rec-1)-finfo.bytes;
      end
    end
    % Convert to relative file paths
    for fn_idx = 1:length(new_relative_filename{adc_idx})
      [~,new_relative_filename{adc_idx}{fn_idx},ext] = fileparts(new_relative_filename{adc_idx}{fn_idx});
      new_relative_filename{adc_idx}{fn_idx} = [new_relative_filename{adc_idx}{fn_idx} ext];
    end
  end
  
  new_relative_rec_num{6}(1:10)
  records.relative_rec_num{1}(1:10)
  
  new_offset(6,new_relative_rec_num{6}(2)+(-3:3))
  records.offset(1,records.relative_rec_num{1}(2)+(-3:3))
  
  for adc_idx = 1:length(adcs)
    new_offset(adc_idx,1:bad_records_start(adc_idx)) = -2^31;
  end
end

keyboard

%% Save Records
if 1
  records.offset = new_offset;
  records.relative_filename = new_relative_filename;
  records.relative_rec_num = new_relative_rec_num;
  
  save(records_fn,'-struct','records');
  records_aux_files_create(records_fn);
  if 0
    records_fn = '/home/administrator/Scratch/csarp_support/records/rds/2018_Greenland_Polar6/records_20180510_01.mat';
    records = load(records_fn);
    records.offset([1:5,8],end-132) = -2^31;
    records.offset(1,530001+1469)=-2^31;
    save(records_fn,'-struct','records');
    records_aux_files_create(records_fn);
  end
  if 0
    records_fn = '/home/administrator/Scratch/csarp_support/records/rds/2018_Greenland_Polar6/records_20180510_02.mat';
    records = load(records_fn);
    records.offset(2,775001+4890-1)=-2^31;
    records.offset([1:5,8],2125001+4838-1)=-2^31;
    save(records_fn,'-struct','records');
    records_aux_files_create(records_fn);
  end
end
