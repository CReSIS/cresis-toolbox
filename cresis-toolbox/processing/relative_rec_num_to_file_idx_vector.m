function file_idx = relative_rec_num_to_file_idx_vector(recs,relative_rec_num)
% file_idx = relative_rec_num_to_file_idx_vector(recs,relative_rec_num)
%
% Support function for calls to load_mcords_data, load_mcords2_data, etc

file_idx = zeros(size(recs));

cur_file_idx = 1;
for rec_idx = 1:length(recs)
  while cur_file_idx+1 <= length(relative_rec_num) ...
      && relative_rec_num(cur_file_idx+1) <= recs(rec_idx)
    cur_file_idx = cur_file_idx + 1;
  end
  file_idx(rec_idx) = cur_file_idx;
end
