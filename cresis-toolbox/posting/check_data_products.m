% script check_data_products
%
% Script for checking data products.  Lists missing and extra files.
% Optionally deletes extra files.
%
% Example:
%   See run_check_data_products.m for how to run.
%
% Author: John Paden, Logan Smith

%% Automated Section

%% Check that only good files are present in each directory

command_window_out_fn = ct_filename_ct_tmp(rmfield(params(1),'day_seg'),'','check_data_products', sprintf('console_%s.txt',datestr(now,'YYYYmmDD_HHMMSS')));
command_window_out_fn_dir = fileparts(command_window_out_fn);
if ~exist(command_window_out_fn_dir,'dir')
  mkdir(command_window_out_fn_dir);
end
diary(command_window_out_fn);

if check_for_bad_files
  % Check support (gps, frames, records) directories
  for file_type = supports
    % 1. Get list of support files
    if strcmpi(file_type,'gps')
      support_fns = get_filenames([ct_filename_support(rmfield(params(1),'day_seg'),'',file_type{1},true), filesep],file_type{1},'','.mat');
    else
      support_fns = get_filenames([ct_filename_support(rmfield(params(1),'day_seg'),'',file_type{1}), filesep],file_type{1},'','.mat');
    end
    support_fns_mask = zeros(size(support_fns));
    % 2. Check which support files are there
    for param_idx = 1:length(params)
      param = params(param_idx);
      if strcmpi(file_type,'gps')
        support_fn = ct_filename_support(param,'','gps',true);
      else
        support_fn = ct_filename_support(param,'',file_type{1});
      end
      match_idx = strmatch(support_fn,support_fns);
      if ~isempty(match_idx)
        support_fns_mask(match_idx) = 1;
      end
    end
    % 3. Report and remove support files that should not be there
    bad_idxs = find(~support_fns_mask);
    for bad_idx = bad_idxs(:).'
      if ~isempty(bad_idx)
        fprintf('BAD FILE !!!!!!!! %s\n', support_fns{bad_idx});
        if delete_bad_files
          if strcmpi(file_type,'gps')
            warning('GPS files are shared with all radars, if this file is really not supposed to be here run "delete(%s);".',support_fns{bad_idx});
          else
            delete(support_fns{bad_idx});
          end
        end
      end
    end
  end
  
  % Check output directories
  % 1. Get first good parameter
  first_param = [];
  for param_idx = 1:length(params)
    param = params(param_idx);
    if ~enable_all_without_do_not_process
      if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
        continue;
      end
    else
      if ~isempty(regexpi(param.cmd.notes,'do not process'))
        continue;
      end
    end
    first_param = param;
    break;
  end
  if isempty(first_param)
    error('No segments to process in spreadsheet.');
  end
  
  % 2. Go through each echogram output directory type to find bad segment
  %    directories
  for output_idx = 1:length(outputs)
    out_dir = fullfile(ct_filename_out(first_param,'','',1),['CSARP_' outputs_post_dir], ...
      outputs{output_idx},first_param.day_seg);
    out_dir_dir = fileparts(out_dir);

    % 2a. Get list of segment directories
    out_dirs = get_filenames(out_dir_dir,'','','',struct('type','dir'));
    out_dirs_mask = zeros(size(out_dirs));
    out_dirs_names = cell(size(out_dirs));
    for out_dirs_idx = 1:length(out_dirs)
      [~,out_dirs_names{out_dirs_idx}] = fileparts(out_dirs{out_dirs_idx});
    end
    % 2b. Check which segment directories are supposed to be there
    for param_idx = 1:length(params)
      param = params(param_idx);
      if ~isempty(regexpi(param.cmd.notes,'do not process'))
        continue;
      end
      match_idx = strmatch(param.day_seg,out_dirs_names);
      if ~isempty(match_idx)
        out_dirs_mask(match_idx) = 1;
      end
    end
    % 2c. Report and remove the segment directories that should not be there
    bad_idxs = find(~out_dirs_mask);
    for bad_idx = bad_idxs(:).'
      if ~isempty(bad_idx)
        fprintf('  BAD DIR !!!!!!!! %s\n', out_dirs{bad_idx});
        if delete_bad_files
          rmdir(out_dirs{bad_idx},'s');
        end
      end
    end
  end
  
end

%% Check that all outputs are there for each segment
for param_idx = 1:length(params)
  param = params(param_idx);
  if ~enable_all_without_do_not_process
    if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
      continue;
    end
  else
    if ~isempty(regexpi(param.cmd.notes,'do not process'))
      continue;
    end
  end
  % dirs_list: list of all output directories to check (usually just one)
  for dir_idx = 1:length(dirs_list)
    if ~isempty(dirs_list{dir_idx})
      %% Setup for checking segment
      fprintf('\nChecking %s\n', params(param_idx).day_seg);
      param = params(param_idx);
      if ~isempty(regexpi(param.cmd.notes,'do not process'))
        fprintf('  DO NOT PROCESS !!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
      end
      param.out_path = dirs_list{dir_idx};
      param.support_path = support_dirs_list{dir_idx};
      
      %% Check for existance of gps file
      if strmatch('gps',supports)
        gps_fn = ct_filename_support(param,'','gps',true);
        fprintf('  GPS %s\n', gps_fn);
        if exist(gps_fn,'file')
          try
            gps = load(gps_fn);
            fprintf('    Exists: %s\n', gps.gps_source);
          catch ME
            fprintf('    Error:\n');
            keyboard
          end
        else
          fprintf('    DOES NOT EXIST !!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        end
      end
      
      %% Check for existance of vectors file
      clear vectors;
      if strmatch('vectors',supports)
        vectors_fn = ct_filename_support(param,'','vectors');
        fprintf('  Vectors %s\n', vectors_fn);
        if exist(vectors_fn,'file')
          fprintf('    Exists\n');
        else
          fprintf('    DOES NOT EXIST !!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        end
      end
      
      %% Check for existance of records file
      if strmatch('records',supports)
        records_fn = ct_filename_support(param,'','records');
        fprintf('  Records %s\n', records_fn);
        if exist(records_fn,'file')
          try
            records = records_load(param);
            if isfield(records,'records')
              fprintf('    Exists: %s\n', records.records.gps_source);
            else
              fprintf('    Exists: %s\n', records.gps_source);
            end
          catch ME
            fprintf('    Error:\n');
            keyboard
          end
        else
          fprintf('    DOES NOT EXIST !!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        end
      end
      
      %% Check for existance of frames file
      if strmatch('frames',supports)
        frames_fn = ct_filename_support(param,'','frames');
        fprintf('  Frames %s\n', frames_fn);
        if exist(frames_fn,'file')
          try
            load(frames_fn);
            fprintf('    Exists\n');
          catch ME
            fprintf('    Error:\n');
            keyboard
          end
        else
          fprintf('    DOES NOT EXIST !!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        end
      end
      
      %% Check echogram outputs
      for output_idx = 1:length(outputs)
        frames = frames_load(param);
        out_dir = fullfile(ct_filename_out(param,'','',1),['CSARP_' outputs_post_dir], ...
          ['CSARP_' outputs{output_idx}],param.day_seg);
        fprintf('  Output %s\n', out_dir);
        frms = find(ct_proc_frame(frames.proc_mode,frm_types));
        found_mask = zeros(1,length(frms));
        if exist(out_dir,'dir')
          if strcmp(outputs{output_idx},'CSARP_out')
            fn_param.type = 'd';
            fns = get_filenames(out_dir,'fk_data','','',fn_param);
          else
            fns = get_filenames(out_dir,'Data_','','.mat');
          end
          for fn_idx = 1:length(fns)
            fn = fns{fn_idx};
            [fn_dir fn_name] = fileparts(fn);
            if strcmp(outputs{output_idx},'CSARP_out')
              day_seg = fn_dir(end-10:end);
              frm = str2double(fn_name(end-8:end-6));
            else
              % Determine 3 or 4 number frame number
              if fn_name(end-3) == '_'
                day_seg = fn_name(end-14:end-4);
                frm = str2double(fn_name(end-2:end));
              else
                day_seg = fn_name(end-15:end-5);
                frm = str2double(fn_name(end-3:end));
              end
            end
            if ~strcmp(day_seg,param.day_seg)
              fprintf('    day_seg mismatch %s\n', fn);
            end
            frm_idx = find(frm==frms);
            if isempty(frm_idx)
              fprintf('    FILE SHOULD NOT BE HERE !!!!!!!!!!!!!!!!!!!!!!!!!\n');
              fprintf('      %s\n', fn);
              if delete_bad_files
                delete(fn);
              end
            else
              if exist('gps_sources','var') && ~isempty(gps_sources) && ~strcmp(outputs{output_idx},'layer')
                if strcmp(outputs{output_idx},'CSARP_out')
                  fns2 = get_filenames(fn,'','','');
                  fn = fns2{1};
                end
                clear param_records
                load(fn,'param_records');
                if isempty(strmatch(param_records.gps_source,gps_sources))
                  fprintf('    %s BAD GPS SOURCE %s!!!!!!!!!!!!!!!\n', fn, param_records.gps_source);
                  no_bad_gps_so_far_flag = false;
                end
              end
              if exist('check_echogram_type','var') && ~isempty(check_echogram_type)
                if strcmp(outputs{output_idx},'CSARP_mvdr')
                  clear param_combine
                  load(fn,'param_combine');
                  if ~strcmpi(param_combine.combine.method,'mvdr')
                    fprintf('  Wrong processing type %s for mvdr in %s!!!!!\n', param_combine.combine.method, fn);
                  end
                elseif strcmp(outputs{output_idx},'CSARP_standard')
                  clear param_combine
                  load(fn,'param_combine');
                  if ~strcmpi(param_combine.combine.method,'standard')
                    fprintf('  Wrong processing type %s for standard in %s!!!!!\n', param_combine.combine.method, fn);
                  end
                end
              end
              
              if exist('processing_date_check','var') && ~isempty(processing_date_check) && ~strcmp(outputs{output_idx},'layerData')
                if strcmp(outputs{output_idx},'CSARP_out')
                  fns2 = get_filenames(fn,'','','');
                  fn = fns2{1};
                end
                if strcmp(outputs{output_idx},'CSARP_qlook')
                  clear param_get_heights
                  load(fn,'param_get_heights');
                  if datenum(param_get_heights.get_heights.sw_version.cur_date_time) < processing_date_check
                    fprintf('    %s IS OLD %s!!!!!!!\n', fn, param_get_heights.get_heights.sw_version.cur_date_time);
                  end
                else
                  load(fn,'param_csarp');
                  if datenum(param_csarp.csarp.sw_version.cur_date_time) < processing_date_check
                    fprintf('    %s IS OLD %s!!!!!!!\n', fn, param_csarp.csarp.sw_version.cur_date_time);
                  end
                end
              end
              found_mask(frm_idx) = 1;
            end
          end
          if any(~found_mask)
            fprintf('    MISSING FRAMES !!!!!!!!!!!!!!!!!!!!!!!!!!!!!:\n');
            fprintf('      %d\n', frms(~found_mask));
          else
            fprintf('    All frames found\n');
          end
          
        else
          fprintf('    DOES NOT EXIST !!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        end
      end
      
      %% Check for expected image files
      frames_fn = ct_filename_support(param,'','frames');
      frames = load(frames_fn);
      for image_idx = 1:length(images)
        image_dir = fullfile(ct_filename_out(param, ...
          outputs_post_dir,'', true),'images',param.day_seg);
        fprintf('  Images %s in %s\n', images{image_idx}, image_dir);
        frms = find(ct_proc_frame(frames.proc_mode,frm_types));
        if length(unique(frms)) ~= length(frms)
          fprintf('    VECTORS CONTAINS NONUNIQUE FRAMES !!!!!!!!!!!!!!!!!!!!!!!!\n');
        end
        frms = unique(frms); % sorts the frms list too which we need!
        found_mask = zeros(1,length(frms));
        start_frms = frms;
        stop_frms = frms;
        if exist(image_dir,'dir')
          if strmatch(images{image_idx},'maps')
            fns = get_filenames(image_dir,'','0maps','');
          elseif strmatch(images{image_idx},'echo')
            fns = get_filenames(image_dir,'','1echo','');
          end
          for fn_idx = 1:length(fns)
            fn = fns{fn_idx};
            [fn_dir fn_name] = fileparts(fn);
            % Assume YYYYMMDD_SS_FFF filename format and pull FFF frame
            % number
            day_seg = fn_name(1:11);
            start_frm = str2double(fn_name(13:15));
            if fn_name(20) == '_'
              stop_frm = str2double(fn_name(17:19));
            elseif fn_name(21) == '_'
              stop_frm = str2double(fn_name(17:20));
            else
              stop_frm = start_frm;
            end
            if ~strcmp(day_seg,param.day_seg)
              fprintf('    day_seg mismatch %s\n', fn);
            end
            img_frms = start_frm:stop_frm;
            start_frm_idx = find(start_frm==start_frms);
            stop_frm_idx = find(stop_frm==stop_frms);
            if ~isempty(start_frm_idx) && ~isempty(stop_frm_idx) && start_frm_idx == stop_frm_idx
              for img_frm = img_frms
                found_mask(frms == img_frm) = 1;
              end
            else
              fprintf('    FILE SHOULD NOT BE HERE !!!!!!!!!!!!!!!!!!!!!!!!!\n');
              fprintf('      %s\n', fn);
              if delete_bad_files
                delete(fn);
              end
            end
          end
          if any(~found_mask)
            fprintf('    MISSING FRAMES !!!!!!!!!!!!!!!!!!!!!!!!!!!!!:\n');
            fprintf('      %d\n', frms(~found_mask));
          else
            fprintf('    All frames found\n');
          end
          
        else
          fprintf('    DOES NOT EXIST !!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        end
      end
      
      %% Check for expected pdf files
      if pdf_en
        pdf_dir = fullfile(ct_filename_out(param, ...
          'post', '', true),'pdf');
        fprintf('  PDF in %s\n', pdf_dir);
        pdf_fn = get_filenames(pdf_dir,'',params(param_idx).day_seg,'.pdf');
        if isempty(pdf_fn)
          fprintf('    DOES NOT EXIST !!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
        else
          fprintf('    PDF found\n');
        end
      end
      
      %% Check for expected csv, csv_good, kml, kml_good files
      if csv_en
        for csv_out_idx = 1:length(csv_outputs)
          csv_dir = fullfile(ct_filename_out(param, ...
            'post', '', true),csv_outputs{csv_out_idx});
          fprintf('  %s in %s\n', csv_outputs{csv_out_idx}, csv_dir);
          if ~isempty(strfind(upper(csv_outputs{csv_out_idx}),'CSV'))
            csv_fn = fullfile(csv_dir,sprintf('Data_%s.csv',params(param_idx).day_seg));
          elseif ~isempty(strfind(upper(csv_outputs{csv_out_idx}),'KML'))
            csv_fn = fullfile(csv_dir,sprintf('Browse_Data_%s.kml',params(param_idx).day_seg));
          else
            error('CSV file type %s not supported',csv_outputs{csv_out_idx});
          end
          if ~exist(csv_fn,'file')
            fprintf('    DOES NOT EXIST !!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
          else
            fprintf('    %s found\n', csv_outputs{csv_out_idx});
          end
        end
      end
    end
  end
end

diary off;
fprintf('Console output: %s\n', command_window_out_fn);
