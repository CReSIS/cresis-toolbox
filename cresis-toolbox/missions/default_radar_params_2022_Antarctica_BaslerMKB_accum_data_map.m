function data_map = default_radar_params_2022_Antarctica_BaslerMKB_accum_data_map(day_seg)
% data_map = default_radar_params_2022_Antarctica_BaslerMKB_accum_data_map(day_seg)
%
% Used to create param.records.data_map.
%
% Support function for default_radar_params_2022_Antarctica_BaslerMKB_accum
% and in general for the dataset corresponding to
%   season: 2022_Antarctica_BaslerMKB
%   radar: accum
%
% Author: John Paden
%
% See also: default_radar_params_2022_Antarctica_BaslerMKB_accum

if ~exist('day_seg','var') || isempty(day_seg)
  data_map = {};
  for board_idx = 1:2
    data_map{board_idx} = [];
    profile = 0;
    wf_list = [1 2 3 4];
    mode = 0;
    for wf = wf_list
      for subchannel=0:7
        data_map{board_idx}(end+1,1:5) = [profile mode subchannel wf subchannel+1+(board_idx-1)*8];
        data_map{board_idx}(end+1,1:5) = [profile mode+1 subchannel wf subchannel+1+(board_idx-1)*8];
        profile = profile+1;
      end
      mode = mode+2;
    end
  end
elseif strcmp(day_seg,'20230115_03')
  data_map = {};
  for board_idx = 1
    data_map{board_idx} = [];
    profile = 0;
    wf_list = [1 2 3 4];
    mode = 0;
    for wf = wf_list
      for subchannel=0:7
        data_map{board_idx}(end+1,1:5) = [profile mode subchannel wf subchannel+1+(board_idx)*8];
        data_map{board_idx}(end+1,1:5) = [profile mode+1 subchannel wf subchannel+1+(board_idx)*8];
        profile = profile+1;
      end
      mode = mode+2;
    end
  end
end