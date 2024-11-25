% Not complete, but started work on 2D MRF
num_nodes = [32 24];
num_states = 14;
num_loops = 16;
rng(0);
if 0
  I = ones(num_states,num_nodes(1),num_nodes(2));
else
  I = 1*randn(num_states,num_nodes(1),num_nodes(2));
  % Add in surface points
  I(1:5,1:3,:) = I(1:5,1:3,:) + 3.5;
  I(6,[1],:) = I(6,[1],:) + [10];
  I(7,[4 10],:) = bsxfun(@plus, I(7,[4 10],:),[5 7]);
  I(5,[13 15],:) = bsxfun(@plus, I(5,[13 15],:),[5 7]);
  I(4,[19],:) = I(4,[19],:) + [4];
  % Remove first 8 rows of every column
  I(:,17:32,:) = 1*randn(num_states,16,num_nodes(2));
  % Artifact
  I(12,26:28,14:16) = I(12,26:28,14:16) + 1000;
end
msg_up = zeros(num_states,num_nodes(1),num_nodes(2));
msg_down = zeros(num_states,num_nodes(1),num_nodes(2));
msg_left = zeros(num_states,num_nodes(1),num_nodes(2));
msg_right = zeros(num_states,num_nodes(1),num_nodes(2));
old_msg_up = zeros(num_states,num_nodes(1),num_nodes(2));
old_msg_down = zeros(num_states,num_nodes(1),num_nodes(2));
old_msg_left = zeros(num_states,num_nodes(1),num_nodes(2));
old_msg_right = zeros(num_states,num_nodes(1),num_nodes(2));
trws_en = true;
normalize = true;
smooth_scale = 1;

loop_dir = 2;
row_loop_dir = 2;
figure(1); clf;
imagesc(I(:,:,1))
figure(2); clf;
for loop = 0:num_loops-1
  fprintf('loop %d\n', loop);
  for idx = 1:prod(num_nodes)
    %fprintf('  idx %d\n', idx);
    if mod(floor(bitshift(loop,-log2(loop_dir/2))),2) == 0
      node_idx = idx;
    else
      node_idx = prod(num_nodes)+1-idx;
    end
    if mod(floor(bitshift(loop,-log2(row_loop_dir/2))),2) == 0
      if mod(floor(bitshift(loop,-log2(loop_dir/2))),2) == 0
        row_idx = 1 + mod((node_idx-1),num_nodes(1));
      else
        row_idx = num_nodes(1) - mod((node_idx-1),num_nodes(1));
      end
    else
      if mod(floor(bitshift(loop,-log2(loop_dir/2))),2) == 0
        row_idx = num_nodes(1) - mod((node_idx-1),num_nodes(1));
      else
        row_idx = 1 + mod((node_idx-1),num_nodes(1));
      end
    end
    col_idx = 1 + floor((node_idx-1)/num_nodes(1));
    if 0
      fprintf('Loop %d\t%d\t%d\n', loop, row_idx, col_idx)
    end
    if row_idx < num_nodes(1)
      if 0
        msg_up(:,row_idx+1,col_idx) = old_msg_up(:,row_idx,col_idx) + I(:,row_idx,col_idx);
      else
        for state = 1:num_states
          msg_up(state,row_idx+1,col_idx) = max(I(:,row_idx,col_idx) + old_msg_left(:,row_idx,col_idx) + old_msg_right(:,row_idx,col_idx) + old_msg_up(:,row_idx,col_idx) - smooth_scale*(state-(1:num_states).').^2);
        end
        if normalize
          msg_up(:,row_idx+1,col_idx) = msg_up(:,row_idx+1,col_idx) - max(msg_up(:,row_idx+1,col_idx));
        end
      end
    end
    if row_idx > 1
      if 0
        msg_down(:,row_idx-1,col_idx) = old_msg_down(:,row_idx,col_idx) + I(:,row_idx,col_idx);
      else
        for state = 1:num_states
          msg_down(state,row_idx-1,col_idx) = max(I(:,row_idx,col_idx) + old_msg_left(:,row_idx,col_idx) + old_msg_right(:,row_idx,col_idx) + old_msg_down(:,row_idx,col_idx) - smooth_scale*(state-(1:num_states).').^2);
        end
        if normalize
          msg_down(:,row_idx-1,col_idx) = msg_down(:,row_idx-1,col_idx) - max(msg_down(:,row_idx-1,col_idx));
        end
      end
    end;
    if col_idx < num_nodes(2)
      if 0
        msg_left(:,row_idx,col_idx+1) = old_msg_left(:,row_idx,col_idx) + I(:,row_idx,col_idx);
      else
        for state = 1:num_states
          msg_left(state,row_idx,col_idx+1) = max(I(:,row_idx,col_idx) + old_msg_up(:,row_idx,col_idx) + old_msg_down(:,row_idx,col_idx) + old_msg_left(:,row_idx,col_idx) - smooth_scale*(state-(1:num_states).').^2);
        end
        if normalize
          msg_left(:,row_idx,col_idx+1) = msg_left(:,row_idx,col_idx+1) - max(msg_left(:,row_idx,col_idx+1));
        end
      end
    end
    if col_idx > 1
      if 0
        msg_right(:,col_idx-1) = old_msg_right(:,col_idx) + I(:,col_idx);
      else
        for state = 1:num_states
          msg_right(state,row_idx,col_idx-1) = max(I(:,row_idx,col_idx) + old_msg_up(:,row_idx,col_idx) + old_msg_down(:,row_idx,col_idx) + old_msg_right(:,row_idx,col_idx) - smooth_scale*(state-(1:num_states).').^2);
        end
        if normalize
          msg_right(:,row_idx,col_idx-1) = msg_right(:,row_idx,col_idx-1) - max(msg_right(:,row_idx,col_idx-1));
        end
      end
    end;
    if trws_en
      old_msg_up = msg_up;
      old_msg_down = msg_down;
      old_msg_right = msg_right;
      old_msg_left = msg_left;
    end
    
    if 0
      figure(1); clf; imagesc(msg_left(:,:,1));
      figure(2); clf; imagesc(msg_right(:,:,1));
      figure(3); clf; imagesc(msg_up(:,:,1));
      figure(4); clf; imagesc(msg_down(:,:,1));
    elseif 0
      imagesc(I(:,:,1) + msg_left(:,:,1) + msg_right(:,:,1) + msg_up(:,:,1) + msg_down(:,:,1));
    end
  end
  
  old_msg_up = msg_up;
  old_msg_down = msg_down;
  old_msg_right = msg_right;
  old_msg_left = msg_left;
  [~,result] = max(I + msg_left + msg_right + msg_up + msg_down);
  if 0
    clf;
    for col = 1:num_nodes(2)
      imagesc(I(:,:,col) + msg_left(:,:,col) + msg_right(:,:,col) + msg_up(:,:,col) + msg_down(:,:,col));
      hold on
      plot(result(1,:,col),'k')
      title(sprintf('column %d',col));
      pause
    end
    drawnow;
  end
end

[confidence,result] = max(I + msg_left + msg_right + msg_up + msg_down);

%% Print result
clf;
for col = 1:num_nodes(2)
  figure(1); clf;
  imagesc(I(:,:,col))
  hold on
  plot(result(1,:,col),'k')
  figure(2); clf;
  imagesc(I(:,:,col) + msg_left(:,:,col) + msg_right(:,:,col) + msg_up(:,:,col) + msg_down(:,:,col));
  hold on
  plot(result(1,:,col),'k')
  title(sprintf('column %d',col));
  pause
end
