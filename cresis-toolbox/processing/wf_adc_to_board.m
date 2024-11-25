function [board,board_idx,profile] = wf_adc_to_board(param,wf_adc_list)
% [board,board_idx,profile] = wf_adc_to_board(param,wf_adc_list)
%
% Support function for determining which file (referred to as board since
% each board usually generates its own file and may have multiple adcs) a
% particular wf-adc pair comes from. This also returns the profile for more
% complex data mappings like what the Arena systems use.
%
% Inputs:
% param: parameter structure usually from parameter spreadsheet
%   .records
%     .file.version
%     .data_map
% wf_adc_list: list of wf-adc pairs (N by 2 matrix where first column is the wf and
%   the second column is the adc. wf is one indexed. adc is one indexed.
%
% Outputs:
% board: usually one or zero indexed (refers to the naming convention in
%   the raw data filenames). Returns a list of unique boards required for
%   the wf-adc pairs passed in.
% board_idx: is one indexed. Returns a list of the unique board_idxs
%   required for the wf-adc pairs passed in.
% profile: N by M matrix where N is the number of separate profiles 
%   requested (i.e. the number of wf-adc pairs that are passed in) and M
%   is the number of fields required for a particular file version. 
%
% Author: John Paden

if any(param.records.file.version == [402 403])
  % NI systems with 4 adcs per board
  board = unique(floor((wf_adc_list(:,2).'-1)/4));
  board_idx = board+1;
  profile = {};
  
elseif any(param.records.file.version == [410])
  % MCRDS with all adcs on one board
  board = 1;
  board_idx = 1;
  profile = {};
  
elseif any(param.records.file.version == [9 10 103 412])
  % RSS which uses param.records.data_map
  board = zeros(1,size(wf_adc_list,1));
  profile = cell(size(wf_adc_list,1),1);
  for wf_adc = 1:size(wf_adc_list,1)
    found = false;
    for board_idx = 1:length(param.records.data_map)
      for profile_idx = 1:size(param.records.data_map{board_idx},1)
        if size(param.records.data_map{board_idx},2) == 4
          wf = param.records.data_map{board_idx}(profile_idx,3); % processing wf
          adc = param.records.data_map{board_idx}(profile_idx,4); % processing adc
          if wf_adc_list(wf_adc,1) == wf && wf_adc_list(wf_adc,2) == adc
            board(wf_adc) = board_idx;
            % Add an entry (this approach allows multiple mode,subchannel
            % combinations to be lumped into a single wf/adc pair).
            profile{wf_adc}(end+1,1) = param.records.data_map{board_idx}(profile_idx,1); % mode
            profile{wf_adc}(end,2) = param.records.data_map{board_idx}(profile_idx,2); % subchannel
            found = true;
          end
        else
          wf = param.records.data_map{board_idx}(profile_idx,4); % processing wf
          adc = param.records.data_map{board_idx}(profile_idx,5); % processing adc
          if wf_adc_list(wf_adc,1) == wf && wf_adc_list(wf_adc,2) == adc
            board(wf_adc) = board_idx;
            % Add an entry (this approach allows multiple mode,subchannel
            % combinations to be lumped into a single wf/adc pair).
            profile{wf_adc}(end+1,1) = param.records.data_map{board_idx}(profile_idx,2); % mode
            profile{wf_adc}(end,2) = param.records.data_map{board_idx}(profile_idx,3); % subchannel
            found = true;
          end
        end
      end
    end
    if ~found
      error('Did not find requested wf-adc pair (%d,%d) in param.records.data_map.', wf_adc_list(wf_adc,1), wf_adc_list(wf_adc,2));
    end
  end
  board = unique(board);
  board_idx = board;
  
elseif any(param.records.file.version == [8 11])
  % NI system
  if isfield(param.records,'data_map') && ~isempty(param.records.data_map)
    board = zeros(1,size(wf_adc_list,1));
    profile = cell(size(wf_adc_list,1),1);
    for wf_adc = 1:size(wf_adc_list,1)
      found = false;
      for board_idx = 1:length(param.records.data_map)
        for profile_idx = 1:size(param.records.data_map{board_idx},1)
          wf = param.records.data_map{board_idx}(profile_idx,3); % processing wf
          adc = param.records.data_map{board_idx}(profile_idx,4); % processing adc
          if ( isnan(wf) || wf_adc_list(wf_adc,1) == wf ) ...
              && ( isnan(adc) || wf_adc_list(wf_adc,2) == adc )
            board(wf_adc) = board_idx;
            if isnan(param.records.data_map{board_idx}(profile_idx,1))
              profile{wf_adc}(1,1) = wf_adc_list(wf_adc,1); % hardware wf matches processing wf
            else
              profile{wf_adc}(1,1) = param.records.data_map{board_idx}(profile_idx,1); % hardware wf
            end
            if isnan(param.records.data_map{board_idx}(profile_idx,2))
              profile{wf_adc}(1,2) = wf_adc_list(wf_adc,2); % hardware adc matches processing adc
            else
              profile{wf_adc}(1,2) = param.records.data_map{board_idx}(profile_idx,2); % hardware adc
            end
            found = true;
          end
        end
      end
      if ~found
        error('Did not find requested wf-adc pair (%d,%d) in param.records.data_map.', wf_adc_list(wf_adc,1), wf_adc_list(wf_adc,2));
      end
    end
    board = unique(board);
    board_idx = board;
  else
    board = unique(wf_adc_list(:,2).');
    board_idx = board;
    profile = {};
  end
  
elseif any(param.records.file.version == [413])
  % UTUA HFRDS
  board = 1;
  board_idx = board;
  profile = {};
  
elseif any(param.records.file.version == [414])
  % BAS Matlab RDS
  board = 12*(wf_adc_list(:,1)-1) + wf_adc_list(:,2);
  board_idx = ones(size(board));
  profile = {};
  
elseif any(param.records.file.version == [415])
  % BAS Matlab RDS
  board = 1;
  board_idx = ones(size(board));
  profile = {};
  
else
  % All other systems
  if isfield(param.records,'data_map') && ~isempty(param.records.data_map)
    board = zeros(1,size(wf_adc_list,1));
    profile = zeros(size(wf_adc_list,1),2);
    for wf_adc = 1:size(wf_adc_list,1)
      found = false;
      for board_idx = 1:length(param.records.data_map)
        for profile_idx = 1:size(param.records.data_map{board_idx},1)
          wf = param.records.data_map{board_idx}(profile_idx,3); % processing wf
          adc = param.records.data_map{board_idx}(profile_idx,4); % processing adc
          if ( isnan(wf) || wf_adc_list(wf_adc,1) == wf ) ...
              && ( isnan(adc) || wf_adc_list(wf_adc,2) == adc )
            board(wf_adc) = board_idx;
            if isnan(param.records.data_map{board_idx}(profile_idx,1))
              profile{wf_adc}(1,1) = wf_adc_list(wf_adc,1); % hardware wf matches processing wf
            else
              profile{wf_adc}(1,1) = param.records.data_map{board_idx}(profile_idx,1); % hardware wf
            end
            if isnan(param.records.data_map{board_idx}(profile_idx,2))
              profile{wf_adc}(1,2) = wf_adc_list(wf_adc,2); % hardware adc matches processing adc
            else
              profile{wf_adc}(1,2) = param.records.data_map{board_idx}(profile_idx,2); % hardware adc
            end
            found = true;
          end
        end
      end
      if ~found
        error('Did not find requested wf-adc pair (%d,%d) in param.records.data_map.', wf_adc_list(wf_adc,1), wf_adc_list(wf_adc,2));
      end
    end
    board = unique(board);
    board_idx = board;
  else
    board = unique(wf_adc_list(:,2).');
    board_idx = board;
    profile = {};
  end
end

