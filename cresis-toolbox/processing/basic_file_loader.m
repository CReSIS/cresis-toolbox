function [data,fn,settings,default,gps,hdr,pc_param,settings_enc] = basic_file_loader(param,defaults)
% [data,fn,settings,default,gps,hdr,pc_param,settings_enc] = basic_file_loader(param,defaults)
%
% Support script for loading raw data files for the in flight scripts. Used by
% basic_noise_analysis.m, basic_rx_equalization.m, and
% basic_radiometric_impulse_response.m
%
% INPUTS:
% param,defaults from default_radar_params_SEASON_NAME_RADAR_NAME
%
% OPTIONAL INPUTS: (any missing inputs will be prompted for so none required)
% param.config.file_search_mode: string which may be one of the following:
%   'default','default+s','default+1','specific','last_file','segment','map'
% param.config.base_dir_search: cell array of base directories to search for files
%   in
% param.config.img: wf-adc array, Nx2 matrix where first column is the waveform,
%   second column is the adc, and each of the N rows specifies a channel to
%   load
% param.config.recs: 1x2 vector where first entry is the first record to load
%   from the file (zero indexed) and the second entry is how many records
%   to load (inf loads all records)
%
% Author: John Paden

if ~isfield(param,'config')
  param.config = [];
end

if ~isfield(param.config,'file_search_mode') || isempty(param.config.file_search_mode)
  param.config.file_search_mode = '';
end

if ~isfield(param.config,'base_dir_search') || isempty(param.config.base_dir_search)
  param.config.base_dir_search = {''};
end

if ~isfield(param.config,'multiselect') || isempty(param.config.multiselect)
  param.config.multiselect = false;
end

[output_dir,radar_type,radar_name] = ct_output_dir(param.radar_name);

global g_basic_file_loader_fn;
global g_basic_file_loader_fns;
g_basic_file_loader_fn = char(g_basic_file_loader_fn); % Force type to be string

% Assume the first default parameters until we know which is the correct
default = defaults{1};

global g_basic_file_loader_search;
if isempty(param.config.file_search_mode) ...
    || all(~strcmpi(param.config.file_search_mode,{'default','default+s','default+1','specific','last_file','segment','map'}))
  fprintf('\nSelect file search mode:\n');
  fprintf(' 1: default (loads whatever was last loaded)');
  if strcmpi(g_basic_file_loader_search,'default')
    fprintf(' *');
  end
  fprintf('\n');
  fprintf(' 2: specific (lets you specify a specific file)');
  if strcmpi(g_basic_file_loader_search,'specific')
    fprintf(' *');
  end
  fprintf('\n');
  fprintf(' 3: last_file (lists the last 10 recorded files to select from)');
  if strcmpi(g_basic_file_loader_search,'last_file')
    fprintf(' *');
  end
  fprintf('\n');
  fprintf(' 4: by segment (lists segments and then files)');
  if strcmpi(g_basic_file_loader_search,'segment')
    fprintf(' *');
  end
  fprintf('\n');
  fprintf(' 5: map (shows segments and files on map)');
  if strcmpi(g_basic_file_loader_search,'map')
    fprintf(' *');
  end
  fprintf('\n');
  done = false;
  while ~done
    file_search_mode = input('Selection (1-5): ');
    try
      if isempty(file_search_mode) && ~isempty(g_basic_file_loader_search)
        param.config.file_search_mode = g_basic_file_loader_search;
        done = true;
      elseif file_search_mode==1
        param.config.file_search_mode = 'default';
        done = true;
      elseif file_search_mode==2
        param.config.file_search_mode = 'specific';
        done = true;
      elseif file_search_mode==3
        param.config.file_search_mode = 'last_file';
        done = true;
      elseif file_search_mode==4
        param.config.file_search_mode = 'segment';
        done = true;
      elseif file_search_mode==5
        param.config.file_search_mode = 'map';
        done = true;
      end
    end
  end
end
if any(strcmpi(param.config.file_search_mode,{'specific','last_file','segment','map'}))
  g_basic_file_loader_search = param.config.file_search_mode;
end

%% Determine which file to load
if ~strncmpi(param.config.file_search_mode,'default',length('default'))
  good_mask = logical(zeros(size(param.config.base_dir_search)));
  for base_dir_idx = 1:length(param.config.base_dir_search)
    base_dir = param.config.base_dir_search{base_dir_idx};
    if exist(base_dir,'dir')
      good_mask(base_dir_idx) = true;
    end
  end
  param.config.base_dir_search = param.config.base_dir_search(good_mask);
  
  global g_basic_file_loader_base_dir;
  base_dir = [];
  while isempty(base_dir)
    default_base_dir_idx = [];
    % If no default exists, then set default to first in list
    if isempty(g_basic_file_loader_base_dir) && ~isempty(param.config.base_dir_search)
      g_basic_file_loader_base_dir = param.config.base_dir_search{1};
    end
    % Print options to user
    fprintf('\n');
    for base_dir_idx = 1:length(param.config.base_dir_search)
      fprintf(' %d: %s', base_dir_idx, param.config.base_dir_search{base_dir_idx});
      if strcmp(param.config.base_dir_search{base_dir_idx},g_basic_file_loader_base_dir)
        fprintf(' *');
        default_base_dir_idx = base_dir_idx;
      end
      fprintf('\n');
    end
    fprintf(' %d: Custom', base_dir_idx+1);
    if isempty(default_base_dir_idx)
      fprintf(' *');
      default_base_dir_idx = base_dir_idx+1;
    end
    fprintf('\n');
    % Get input from user
    try
      if ~isempty(param.config.base_dir_search)
        base_dir_idx = input(sprintf('Choose base directory [%d]: ',default_base_dir_idx));
      else
        % Automatically choose custom if no base directories exist
        base_dir_idx = 1;
      end
      if isempty(base_dir_idx)
        base_dir_idx = default_base_dir_idx;
      end
      if base_dir_idx <= length(param.config.base_dir_search)
        base_dir = param.config.base_dir_search{base_dir_idx};
      elseif base_dir_idx == length(param.config.base_dir_search)+1
        % Custom selected
        while ~exist(base_dir,'dir')
          base_dir = input('Enter custom directory path: ','s');
          if ~exist(base_dir,'dir')
            warning('Does not exist: %s', base_dir);
          end
        end
      end
    end
  end
  g_basic_file_loader_base_dir = base_dir;
  
  if strcmpi(param.config.file_search_mode,'last_file')
    global g_basic_file_loader_selection;

    adc = param.config.img(1,2);
    [board,board_idx,~] = wf_adc_to_board(param,param.config.img(1,:));
    board_folder_name = param.records.file.board_folder_name;
    board_folder_name = regexprep(board_folder_name,'%b',param.records.file.boards{board_idx});
    fns = get_filenames(fullfile(base_dir,board_folder_name),param.records.file.prefix,'','.bin',struct('recursive',true));
    if isempty(fns)
      error('No data files in: %s\n', base_dir);
    end
    fns_idxs = max(1,length(fns)-9) : length(fns);
    if isempty(g_basic_file_loader_selection)
      g_basic_file_loader_selection = max(1,length(fns_idxs)-1);
    end
    fprintf('\n');
    for fn_idx = 1:length(fns_idxs)
      fprintf(' %d: %s', fn_idx, fns{fns_idxs(fn_idx)});
      if g_basic_file_loader_selection == fn_idx
        fprintf(' *');
      end
      fprintf('\n');
    end
    done = false;
    while ~done
      try
        fn_idx = input(sprintf('Choose one [%d]: ',g_basic_file_loader_selection));
        if isempty(fn_idx)
          fn_idx = g_basic_file_loader_selection;
        end
        fn = fns{fns_idxs(fn_idx)};
        g_basic_file_loader_fns = {fn};
        done = true;
      end
    end
    g_basic_file_loader_selection = fn_idx;
    
  elseif strcmpi(param.config.file_search_mode,'specific')
    adc = param.config.img(1,2);
    [board,board_idx,~] = wf_adc_to_board(param,param.config.img(1,:));
    board_folder_name = param.records.file.board_folder_name;
    board_folder_name = regexprep(board_folder_name,'%b',param.records.file.boards{board_idx});
    data_fns = get_filenames(fullfile(base_dir,board_folder_name),param.records.file.prefix,'','.bin');
    fn = '';
    fprintf('\n');
    while ~exist(fn,'file')
      try
        fprintf('Enter a file name pattern to search for (e.g. "*", "01_0002", etc). Do not include base directory.\n');
        fn = input(sprintf('[%s]: ', g_basic_file_loader_fn),'s');
        if isempty(fn)
          [~,fn] = fileparts(g_basic_file_loader_fn);
        end
        
        fn = get_filename(fullfile(base_dir,board_folder_name),'',fn,'',struct('recursive',true));
        g_basic_file_loader_fns = {fn};
      end
    end
    
  elseif strcmpi(param.config.file_search_mode,'segment')
    
    if any(param.records.file.version == [9 10 103 412])
      % Arena based systems
      system_xml_fns = get_filenames(fullfile(base_dir),'','','system.xml',struct('recursive',true));
      clear settings;
      for xml_idx = 1:length(system_xml_fns)
        xml_fn = system_xml_fns{xml_idx};
        
        settings(xml_idx) = read_arena_xml(xml_fn);
      end
      
    else
      % NI based systems
      % Prepare inputs
      xml_version = param.config.cresis.config_version;
      cresis_xml_mapping;
      [settings,settings_enc] = read_ni_xml_directory(base_dir,xml_file_prefix,false);
    end
    
    % Get the files that match the first wf-adc pair requested
    if any(param.records.file.version == [9 10 103 412])
      % Arena based systems
      wf = param.config.img(1,1);
      adc = param.config.img(1,2);
      found = false;
      for board_idx = 1:length(param.records.arena.data_map)
        for profile_idx = 1:size(param.records.arena.data_map{board_idx},1)
          if param.records.arena.data_map{board_idx}(profile_idx,3) == wf ...
              && param.records.arena.data_map{board_idx}(profile_idx,4) == adc
            board_idx = board_idx;
            board = param.records.file.boards(board_idx);
            mode_latch = param.records.arena.data_map{board_idx}(profile_idx,1);
            subchannel = param.records.arena.data_map{board_idx}(profile_idx,2);
            found = true;
            break;
          end
        end
        if found == true
          break;
        end
      end
      if ~found
        error('wf-adc pair (%d,%d) was not found in param.records.arena.data_map. Update default_radar_params_*.m or param.config.img.', wf, adc);
      end
      % Get raw data files associated with this directory
      [board,board_idx,~] = wf_adc_to_board(param,param.config.img(1,:));
      board_folder_name = param.records.file.board_folder_name;
      board_folder_name = regexprep(board_folder_name,'%b',param.records.file.boards{board_idx});
      fn_datenums = [];
      
      data_fns = get_filenames(fullfile(base_dir,board_folder_name),'','','.dat',struct('recursive',true,'regexp','[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'));
      fn_datenums = zeros(size(data_fns));
      for fn_idx = 1:length(data_fns)
        fname = fname_info_arena(data_fns{fn_idx});
        fn_datenums(fn_idx) = fname.datenum;
      end
      
      for xml_idx = 1:length(system_xml_fns)
        fns_mask = settings(xml_idx).xml_fname.datenum == fn_datenums;
        settings(xml_idx).fns{board_idx} = data_fns(fns_mask);
      end
      
    else
      % NI based systems
      adc = param.config.img(1,2);
      [board,board_idx,~] = wf_adc_to_board(param,param.config.img(1,:));
      board_folder_name = param.records.file.board_folder_name;
      board_folder_name = regexprep(board_folder_name,'%b',param.records.file.boards{board_idx});
      data_fns = get_filenames(fullfile(base_dir,board_folder_name),param.records.file.prefix,'','.bin');
    % Get the date information out of the filename
      fn_datenums = [];
      for data_fn_idx = 1:length(data_fns)
        fname = fname_info_mcords2(data_fns{data_fn_idx});
        fn_datenums(end+1) = fname.datenum;
      end
    end
    
    % Print out settings for each segment (XML file)
    fprintf('\nData segments:\n');
    for set_idx = 1:length(settings)
      if any(param.records.file.version == [9 10 103 412])
        fprintf(' %d: %s (%d seq, %d files)\n', set_idx, ...
          settings(set_idx).psc_config_name, length(settings(set_idx).psc.mode), length(settings(set_idx).fns{board_idx}));
        
      else
        if set_idx < length(settings)
          num_files = sum(fn_datenums >= settings(set_idx).datenum & fn_datenums < settings(set_idx+1).datenum);
        else
          num_files = sum(fn_datenums >= settings(set_idx).datenum);
        end
        
        % Print out settings
        [~,settings_fn_name] = fileparts(settings(set_idx).fn);
        if isfield(settings(set_idx),'XML_File_Path')
          fprintf(' %d: %s (%d wfs, %d files)\n', set_idx, ...
            settings(set_idx).XML_File_Path{1}.values{1}, settings(set_idx).DDS_Setup.Wave, num_files);
        else
          fprintf(' %d: (%d wfs, %d files)\n', set_idx, ...
            settings(set_idx).DDS_Setup.Wave, num_files);
        end
        if set_idx < length(settings)
          settings(set_idx).match_idxs = find(fn_datenums >= settings(set_idx).datenum & fn_datenums < settings(set_idx+1).datenum);
        else
          settings(set_idx).match_idxs = find(fn_datenums >= settings(set_idx).datenum);
        end
      end
    end
    set_idx = [];
    while isempty(set_idx)
      try
        set_idx = input(sprintf('Select segment [%d]: ', length(settings)));
        if isempty(set_idx)
          set_idx = length(settings);
        end
        settings(set_idx);
      catch
        set_idx = [];
      end
    end
    
    if any(param.records.file.version == [9 10 103 412])
      data_fns = settings(set_idx).fns{board_idx};
    else
      if set_idx < length(settings)
        data_fns = data_fns(fn_datenums >= settings(set_idx).datenum & fn_datenums < settings(set_idx+1).datenum);
      else
        data_fns = data_fns(fn_datenums >= settings(set_idx).datenum);
      end
    end
    
    % List files in the selected segment
    fprintf('\nFiles in data segment:\n');
    for fn_idx = 1:length(data_fns)
      fprintf(' %d: %s\n', fn_idx, data_fns{fn_idx});
    end
    fn = '';
    while ~exist(fn,'file')
      try
        file_idx = length(data_fns)-1;
        if file_idx > 0
          file_idx = input(sprintf('Select files (M:N to select a range) [%d]: ', file_idx));
        else
          file_idx = input('Select files (M:N to select a range): ');
        end
        if isempty(file_idx) && length(data_fns) > 1
          fn = data_fns{end-1};
          g_basic_file_loader_fns = {fn};
        else
          fn = data_fns{file_idx(1)};
          g_basic_file_loader_fns = data_fns(file_idx);
        end
      catch
        fn = [];
      end
    end
    
  elseif strcmpi(param.config.file_search_mode,'map')
    basic_file_loader_map;
  end
  g_basic_file_loader_fn = fn;

  % Load sequential files if multiselect is turned on
  if param.config.multiselect && any(strcmpi(param.config.file_search_mode,{'last_file','specific'}))
    global g_num_files;
    if isempty(g_num_files)
      g_num_files = 1;
    end
    num_files = input(sprintf('How many files [%d]: ',g_num_files));
    if isempty(num_files)
      num_files = g_num_files;
    else
      g_num_files = num_files;
    end
    for idx=2:g_num_files
      [fn_dir,fn_name,fn_ext] = fileparts(g_basic_file_loader_fn);
      cur_file_idx = str2double(fn_name(end-3:end));
      fn_name(end-3:end) = sprintf('%04d',cur_file_idx + idx-1);
      fn_name = [fn_name(1:end-14) '*' fn_name(end-7:end)];
      g_basic_file_loader_fns{idx} = get_filename(fn_dir,'',fn_name,fn_ext);
    end
  end
  
else
  if strcmp(param.config.file_search_mode,'default')
    fn = g_basic_file_loader_fn;
  elseif strcmp(param.config.file_search_mode,'default+s')
    % Get the next file in g_basic_file_loader_fns
    if any(strcmpi(radar_name,{'mcords3','mcords5'}))
      file_idx = find(strcmp(g_basic_file_loader_fn, g_basic_file_loader_fns));
      file_idx = file_idx+1;
      if isempty(file_idx) || file_idx > length(g_basic_file_loader_fns)
        error('Next file index not found in file list.');
      end
      fn = g_basic_file_loader_fns{file_idx};
      g_basic_file_loader_fn = fn;
    else
      error('Not supported for %s',param.radar_name);
    end
    
  elseif strcmp(param.config.file_search_mode,'default+1')
    % Get the next file number after the last loaded file
    [fn_dir,fn_name,fn_ext] = fileparts(g_basic_file_loader_fn);
    cur_file_idx = str2double(fn_name(end-3:end));
    fn_name(end-3:end) = sprintf('%04d',cur_file_idx + 1);
    fn_name = [fn_name(1:end-14) '*' fn_name(end-7:end)]
    fn = get_filename(fn_dir,'',fn_name,fn_ext);
  end
end

%% Load the chosen file(s)
tstart = tic;
% Load the data (disable if you have already loaded)
clear data;
clear num_rec;
if any(param.records.file.version == [9 10 103 412])
  error('Not supported yet.');
  
elseif strcmpi(radar_name,'mcords')
  for adc_idx = 1:length(param.adcs)
    adc = param.adcs(adc_idx);

    % May need to adjust base_path for non-standard directory structures
    base_path = fullfile(param.base_path, sprintf('chan%d',adc), ...
      param.seg);
    file_midfix = sprintf('r%d-%d.',param.radar_num,adc);
    file_suffix = sprintf('.%04d.dat',param.data_file_num);
    fprintf('  Path: %s\n', base_path);
    fprintf('  Match: mcords*%s*%s\n', file_midfix, file_suffix);
    fn = get_filename(base_path,'mcords',file_midfix,file_suffix);
    if isempty(fn)
      fprintf('  Could not find any files which match\n');
      return;
    end
    fprintf('Loading file %s\n', fn);
    [hdr,data_tmp] = basic_load_mcords(fn, struct('clk',1e9/9,'first_byte',2^26));
    data(:,:,adc_idx) = data_tmp{param.wf}(1:end-1,1:min(size(data_tmp{param.wf},2),param.rlines(2)));
  end
  data = data - median(data(:,1));
%   basic_remove_mcords_digital_errors;
elseif any(strcmpi(radar_name,{'mcords2','mcords3'}))
  
  if ~isfield(param.config,'img')
    fprintf('Enter wf-adc pair matrix. The wf-adc pair matrix is an Nx2 matrix\n');
    fprintf('where the first column is the waveform, the second column is the adc,\n');
    fprintf('and each row represents a channel to be loaded.\n');
    param.config.img = [];
    while size(param.config.img,1) < 1 || size(param.config.img,2) ~= 2
      try
        param.config.img = input('Wf-adc pairs: ');
      end
    end
  end
  
  % test1_1.dat0
  %   testA_N.datB
  %   A = acquisition number
  %   N = file number
  %   B = board number
  % Map ADCs to board numbers
  fn_start = fn; % Store this first file away since fn gets overwritten below
  for board = 0:3
    if any(board == floor((param.config.img(:,2)-1)/4))
      get_adcs = board*4 + (1:4);
      
      [fn_dir,fn_name] = fileparts(fn_start);
      fn_dir = fileparts(fn_dir);
      fn_name(9) = sprintf('%01d',board);
      fn = fullfile(fn_dir,sprintf('board%d',board),[fn_name,'.bin']);
      
      fprintf('Loading file %s\n', fn);
      % Fix get_filenames     'The filename, directory name, or volume label syntax is incorrect.'
      if strcmpi(radar_name,'mcords2')
        [hdr,data_tmp] = basic_load_mcords2(fn,struct('clk',default.radar.fs));
      else
        [hdr,data_tmp] = basic_load_mcords3(fn,struct('clk',default.radar.fs));
      end
      for get_adc_idx = 1:length(get_adcs)
        adc = get_adcs(get_adc_idx);
        wf_adc_idx_matches = find(param.config.img(:,2) == adc);
        if isempty(wf_adc_idx_matches)
          continue;
        end
        for wf_adc_idx = wf_adc_idx_matches(:).'
          wf = param.config.img(wf_adc_idx,1);
          fprintf('  Loading wf %d, adc %d\n', wf, adc);
          if ~exist('num_rec','var')
            % Since each file may have slightly different numbers of
            % records we do this
            num_rec = size(data_tmp{wf},2) - 1;
          end
          data(:,:,wf_adc_idx) = data_tmp{wf}(:,1:num_rec,get_adc_idx);
          hdr.epri = hdr.epri(1:num_rec);
          hdr.seconds = hdr.seconds(1:num_rec);
          hdr.fractions = hdr.fractions(1:num_rec);
          hdr.utc_time_sod = hdr.utc_time_sod(1:num_rec);
        end
      end
    end
  end
  
  xml_version = 2.0;
  cresis_xml_mapping;
  
  %% Read XML files in this directory
  [settings,settings_enc] = read_ni_xml_directory(fn_dir,'',false);
  finfo = fname_info_mcords2(fn);
  
  settings_idx = find(cell2mat({settings.datenum}) < finfo.datenum,1,'last');
  if isempty(settings_idx)
    settings_idx = 1;
  end
  settings = settings(settings_idx);
  settings_enc = settings_enc(settings_idx);

  default = default_radar_params_settings_match(defaults,settings);
  default = merge_structs(param,default);
  
  %% Format settings into pc_param
  if isfield(settings,'DDC_Ctrl')
    DDC_freq = double(settings.DDC_Ctrl.NCO_freq)*1e6;
    DDC_mode = double(settings.DDC_Ctrl.DDC_sel.Val);
  else
    DDC_freq = 0;
    DDC_mode = 0;
  end
  if DDC_mode == 0
    hdr.fs = default.radar.fs;
  else
    hdr.fs = default.radar.fs / 2^(1+DDC_mode);
  end
  f0 = settings.DDS_Setup.Waveforms(wf).Start_Freq(1);
  f1 = settings.DDS_Setup.Waveforms(wf).Stop_Freq(1);
  fc = (f0+f1)/2;
  Tpd = settings.DDS_Setup.Base_Len * double(settings.DDS_Setup.Waveforms(wf).Len_Mult);
  hdr.BW = f1-f0;
  hdr.BW_noise = hdr.BW;
  atten = double(settings.DDS_Setup.Waveforms(wf).Attenuator_1(1) + settings.DDS_Setup.Waveforms(wf).Attenuator_2(1));
  hdr.rx_gain = default.radar.rx_gain - atten;
  t0 = hdr.wfs(wf).t0 + default.radar.Tadc_adjust;
  tukey = settings.DDS_Setup.RAM_Taper;

  for wf = 1:length(settings.DDS_Setup.Waveforms)
    if isfield(default.radar,'DC_adjust') && ~isempty(default.radar.DC_adjust)
      default.radar.wfs(wf).DC_adjust = default.radar.DC_adjust{wf};
    end
  end
  
  dt = 1/hdr.fs;
  Nt = size(data,1);
  clear pc_param;
  pc_param.img = param.config.img;
  pc_param.DDC_mode = DDC_mode;
  pc_param.DDC_freq = DDC_freq;
  pc_param.f0 = f0;
  pc_param.f1 = f1;
  pc_param.Tpd = Tpd;
  pc_param.zero_pad = 1;
  pc_param.decimate = true;
  pc_param.window_func = @hanning;
  pc_param.time = t0 + (0:dt:(Nt-1)*dt).';
  pc_param.tukey = tukey;
  
  finfo = fname_info_mcords2(fn);
  [year,month,day] = datevec(finfo.datenum);
  hdr.radar_time = utc_to_gps(datenum_to_epoch(datenum(year,month,day,0,0,hdr.utc_time_sod))) + default.vectors.gps.time_offset;
  
  %% Read GPS files in this directory
  param.day_seg = sprintf('%04d%02d%02d_01',year,month,day);
  gps_fn = ct_filename_support(param,'','gps',1);
  if exist(gps_fn,'file')
    gps = load(gps_fn);
  else
    try
      gps_fns = get_filenames(fn_dir,'GPS_','','.txt');
      
      for gps_fn_idx = 1:length(gps_fns)
        gps_fn = gps_fns{gps_fn_idx};
        fprintf('  GPS file: %s\n', gps_fn);
        [~,gps_fn_name] = fileparts(gps_fn);
        gps_params.year = str2double(gps_fn_name(5:8));
        gps_params.month = str2double(gps_fn_name(9:10));
        gps_params.day = str2double(gps_fn_name(11:12));
        gps_params.time_reference = 'utc';
        if gps_fn_idx == 1
          gps = read_gps_nmea(gps_fns{gps_fn_idx},gps_params);
        else
          gps_tmp = read_gps_nmea(gps_fns{gps_fn_idx},gps_params);
          gps.gps_time = [gps.gps_time, gps_tmp.gps_time];
          gps.lat = [gps.lat, gps_tmp.lat];
          gps.lon = [gps.lon, gps_tmp.lon];
          gps.elev = [gps.elev, gps_tmp.elev];
          gps.roll = [gps.roll, gps_tmp.roll];
          gps.pitch = [gps.pitch, gps_tmp.pitch];
          gps.heading = [gps.heading, gps_tmp.heading];
        end
      end
      gps.gps_source = 'NMEA-field';
    end
  end
  hdr.gps_time = hdr.radar_time;
  try
    hdr.lat = interp1(gps.gps_time,gps.lat,hdr.radar_time);
    hdr.lon = interp1(gps.gps_time,gps.lon,hdr.radar_time);
    hdr.elev = interp1(gps.gps_time,gps.elev,hdr.radar_time);
    hdr.roll = interp1(gps.gps_time,gps.roll,hdr.radar_time);
    hdr.pitch = interp1(gps.gps_time,gps.pitch,hdr.radar_time);
    hdr.heading = interp1(gps.gps_time,gps.heading,hdr.radar_time);
    hdr.gps_source = gps.gps_source;
  catch ME
    warning('GPS loading error, setting GPS fields to zero.\nGPS error message was:\n%s', ME.getReport);
    fprintf('\n');
    hdr.lat = zeros(size(hdr.radar_time));
    hdr.lon = zeros(size(hdr.radar_time));
    hdr.elev = zeros(size(hdr.radar_time));
    hdr.roll = zeros(size(hdr.radar_time));
    hdr.pitch = zeros(size(hdr.radar_time));
    hdr.heading = zeros(size(hdr.radar_time));
    hdr.gps_source = '';
  end
  
  
elseif any(strcmpi(radar_name,{'mcords4','mcords5'}))
  file_idx = 1;
  epri_intersect = [];
  
  if ~isfield(param.config,'img')
    fprintf('Enter wf-adc pair matrix. The wf-adc pair matrix is an Nx2 matrix\n');
    fprintf('where the first column is the waveform, the second column is the adc,\n');
    fprintf('and each row represents a channel to be loaded.\n');
    param.config.img = [];
    while size(param.config.img,1) < 1 || size(param.config.img,2) ~= 2
      try
        param.config.img = input('Wf-adc pairs: ');
      end
    end
  end

  if ~isfield(param.config,'recs')
    start_rec = [];
    while length(start_rec) ~= 1
      try
        start_rec = input('Start rec [0]: ');
        if isempty(start_rec)
          start_rec = 0;
        end
      end
    end
    num_rec = [];
    while length(num_rec) ~= 1
      try
        num_rec = input('Number of records (inf for all) [inf]: ');
        if isempty(num_rec)
          num_rec = inf;
        end
      end
    end
    param.config.recs = [start_rec num_rec];
  end
  
  % adcs: a list of the adcs that we are loading
  adcs = unique(param.config.img(:,2));
  
  fn_start = fn; % Store this first file away since fn gets overwritten below
  for adc = reshape(adcs,[1 length(adcs)])
    
    [fn_dir,fn_name] = fileparts(fn_start);
    fn_dir = fileparts(fn_dir);
    fn_name(9:10) = sprintf('%02d',adc);
    fn = fullfile(fn_dir,sprintf('chan%d',adc),[fn_name,'.bin']);
    
    if ~exist(fn,'file')
      warning('File %s not found. Filename may have a slightly different time stamp, so trying a wild character search for the file.',fn);
      [fn_dir,fn_name] = fileparts(fn);
      fn = get_filename(fn_dir,fn_name(1:7),fn_name(end-6:end),'');
    end
    fprintf('Loading file %s\n', fn);
    % Load the data file
    load_param = param.config.header_load_param;
    load_param.recs = param.config.recs;
    if strcmp(radar_name,'mcords4')
      [hdr,data_tmp] = basic_load_mcords4(fn,load_param);
    else
      [hdr,data_tmp] = basic_load_mcords5(fn,load_param);
    end
    % Remove extra records to help reduce total memory usage
%     if isfield(param,'rlines') && ~isempty(param.rlines)
%       for wf = 1:length(data_tmp)
%         data_tmp{wf} = data_tmp{wf}(:,param.rlines,:);
%       end
%       hdr.utc_time_sod = hdr.utc_time_sod(param.rlines);
%       hdr.epri = hdr.epri(param.rlines);
%     end
    % Map each of the read waveforms needed into the correct output
    for wf_adc_idx = 1:size(param.config.img,1)
      % wf,adc: pair of values for this entry in param.config.img
      wf = param.config.img(wf_adc_idx,1);
      if wf > length(data_tmp)
        error('Requested waveform (%d) is larger than the number of waveforms in the file (%d in the file).', wf, length(data_tmp));
      end
      if adc == abs(param.config.img(wf_adc_idx,2));
        % This pair needs to be loaded, insert into output array... handle
        % mismatched EPRIs using intersect function. Throw away any records
        % that do not have matching EPRI in all channels.
        if isempty(epri_intersect)
          epri_intersect = hdr.epri;
          if imag(wf) == 0
%             data(:,1:size(data_tmp{wf},2),wf_adc_idx) = data_tmp{wf}(:,1:end);
            data(:,:,wf_adc_idx) = data_tmp{wf}(:,:);
          else
            data(:,:,wf_adc_idx) = data_tmp{abs(wf)}(:,:) ...
              + sign(wf) * data_tmp{abs(wf)+1}(:,:);
          end
          hdr_utc_time_sod = hdr.utc_time_sod;
        else
          [new_epri_intersect data_idx data_tmp_idx] = intersect(epri_intersect,hdr.epri);
          if isempty(new_epri_intersect)
            warning('No matching EPRI is this load. This script does not handle file recording offsets between channels very well. Just assuming all data is good.');
            new_epri_intersect = epri_intersect;
            data_idx = 1:length(epri_intersect);
            data_tmp_idx = 1:length(epri_intersect);
          end
          epri_intersect = new_epri_intersect;
          data = data(:,data_idx,:);
          hdr_utc_time_sod = hdr.utc_time_sod(data_tmp_idx);
          if imag(wf) == 0
            data(:,:,wf_adc_idx) = data_tmp{wf}(:,data_tmp_idx);
          else
            data(:,:,wf_adc_idx) = data_tmp{abs(wf)}(:,data_tmp_idx) ...
              + sign(wf) * data_tmp{abs(wf)+1}(:,data_tmp_idx);
          end
        end
      end
    end
  end
  hdr.utc_time_sod = hdr_utc_time_sod;
  
  xml_version = 2.0;
  cresis_xml_mapping;
  
  %% Read XML files in this directory
  [settings,settings_enc] = read_ni_xml_directory(fn_dir,'',false);
  finfo = fname_info_mcords2(fn);
  
  settings_idx = find(cell2mat({settings.datenum}) < finfo.datenum,1,'last');
  if isempty(settings_idx)
    settings_idx = 1;
  end
  settings = settings(settings_idx);
  settings_enc = settings_enc(settings_idx);

  default = default_radar_params_settings_match(defaults,settings);
  default = merge_structs(param,default);

  %% Format settings into pc_param
  DDC_freq = double(settings.DDC_Ctrl.NCO_freq)*1e6;
  DDC_mode = double(settings.DDC_Ctrl.DDC_sel.Val);
  if DDC_mode == 0
    hdr.fs = default.radar.fs;
  else
    hdr.fs = default.radar.fs / 2^(1+DDC_mode);
  end
  f0 = settings.DDS_Setup.Waveforms(wf).Start_Freq(1);
  f1 = settings.DDS_Setup.Waveforms(wf).Stop_Freq(1);
  fc = (f0+f1)/2;
  Tpd = settings.DDS_Setup.Base_Len * double(settings.DDS_Setup.Waveforms(wf).Len_Mult);
  hdr.BW = f1-f0;
  if DDC_mode == 0
    hdr.BW_noise = 450e6;
  elseif DDC_mode == 1
    hdr.BW_noise = 350e6;
  elseif DDC_mode == 2
    hdr.BW_noise = 175e6;
  end
  atten = double(settings.DDS_Setup.Waveforms(wf).Attenuator_1(1) + settings.DDS_Setup.Waveforms(wf).Attenuator_2(1));
  hdr.rx_gain = param.config.cresis.rx_gain_dB - atten;

  if isfield(default.radar.wfs,'Tadc_adjust')
    if length(default.radar.wfs) >= wf
      t0 = hdr.wfs(wf).t0 + default.radar.wfs(wf).Tadc_adjust;
    else
      t0 = hdr.wfs(wf).t0 + default.radar.wfs(1).Tadc_adjust;
    end
  else
    t0 = hdr.wfs(wf).t0 + default.radar.Tadc_adjust;
  end
  tukey = settings.DDS_Setup.RAM_Taper;

  for wf = 1:length(settings.DDS_Setup.Waveforms)
    if isfield(default.radar,'DC_adjust') && ~isempty(default.radar.DC_adjust)
      default.radar.wfs(wf).DC_adjust = default.radar.DC_adjust{wf};
    end
  end
  
  dt = 1/hdr.fs;
  Nt = size(data,1);
  clear pc_param;
  pc_param.img = param.config.img;
  pc_param.DDC_mode = DDC_mode;
  pc_param.DDC_freq = DDC_freq;
  pc_param.f0 = f0;
  pc_param.f1 = f1;
  pc_param.Tpd = Tpd;
  pc_param.zero_pad = 1;
  pc_param.decimate = true;
  pc_param.window_func = @hanning;
  pc_param.time = t0 + (0:dt:(Nt-1)*dt).';
  pc_param.tukey = tukey;
  
  finfo = fname_info_mcords2(fn);
  [year,month,day] = datevec(finfo.datenum);
  hdr.radar_time = utc_to_gps(datenum_to_epoch(datenum(year,month,day,0,0,hdr.utc_time_sod))) + default.records.gps.time_offset;
  
  %% Read GPS files in this directory
  param.day_seg = sprintf('%04d%02d%02d_01',year,month,day);
  gps_fn = ct_filename_support(param,'','gps',1);
  if exist(gps_fn,'file')
    gps = load(gps_fn);
  else
    try
      gps_fns = get_filenames(fn_dir,'GPS_','','.txt');
      
      for gps_fn_idx = 1:length(gps_fns)
        gps_fn = gps_fns{gps_fn_idx};
        fprintf('  GPS file: %s\n', gps_fn);
        [~,gps_fn_name] = fileparts(gps_fn);
        gps_params.year = str2double(gps_fn_name(5:8));
        gps_params.month = str2double(gps_fn_name(9:10));
        gps_params.day = str2double(gps_fn_name(11:12));
        gps_params.time_reference = 'utc';
        if gps_fn_idx == 1
          gps = read_gps_nmea(gps_fns{gps_fn_idx},gps_params);
        else
          gps_tmp = read_gps_nmea(gps_fns{gps_fn_idx},gps_params);
          gps.gps_time = [gps.gps_time, gps_tmp.gps_time];
          gps.lat = [gps.lat, gps_tmp.lat];
          gps.lon = [gps.lon, gps_tmp.lon];
          gps.elev = [gps.elev, gps_tmp.elev];
          gps.roll = [gps.roll, gps_tmp.roll];
          gps.pitch = [gps.pitch, gps_tmp.pitch];
          gps.heading = [gps.heading, gps_tmp.heading];
        end
      end
      gps.gps_source = 'NMEA-field';
    end
  end
  hdr.gps_time = hdr.radar_time;
  try
    hdr.lat = interp1(gps.gps_time,gps.lat,hdr.radar_time);
    hdr.lon = interp1(gps.gps_time,gps.lon,hdr.radar_time);
    hdr.elev = interp1(gps.gps_time,gps.elev,hdr.radar_time);
    hdr.roll = interp1(gps.gps_time,gps.roll,hdr.radar_time);
    hdr.pitch = interp1(gps.gps_time,gps.pitch,hdr.radar_time);
    hdr.heading = interp1(gps.gps_time,gps.heading,hdr.radar_time);
    hdr.gps_source = gps.gps_source;
  catch ME
    ME.getReport
    hdr.lat = zeros(size(hdr.radar_time));
    hdr.lon = zeros(size(hdr.radar_time));
    hdr.elev = zeros(size(hdr.radar_time));
    hdr.roll = zeros(size(hdr.radar_time));
    hdr.pitch = zeros(size(hdr.radar_time));
    hdr.heading = zeros(size(hdr.radar_time));
    hdr.gps_source = '';
  end
  
end
