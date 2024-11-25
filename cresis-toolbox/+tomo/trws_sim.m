num_nodes = 20;
num_states = 10;
num_loops = 2;
I = ones(num_states,num_nodes);
I = 1*randn(num_states,num_nodes);
I(1:5,1:3) = I(1:5,1:3) + 3.5;
I(6,[1]) = I(6,[1]) + [10];
I(7,[4 10]) = I(7,[4 10]) + [5 7];
I(5,[13 15]) = I(5,[13 15]) + [5 7];
I(4,[19]) = I(4,[19]) + [4];
msg_left = zeros(num_states,num_nodes);
msg_right = zeros(num_states,num_nodes);
old_msg_left = zeros(num_states,num_nodes);
old_msg_right = zeros(num_states,num_nodes);
trws_en = true;
normalize = false;
loop_dir = 2;
figure(1); clf;
imagesc(I)
figure(2); clf;
for loop = 0:num_loops-1
  fprintf('loop %d\n', loop);
  for idx = 1:num_nodes
    %fprintf('  idx %d\n', idx);
    if mod(floor(bitshift(loop,-log2(loop_dir/2))),2) == 0
      node_idx = idx;
    else
      node_idx = num_nodes+1-idx;
    end
    if node_idx < num_nodes
      if 0
        msg_left(:,node_idx+1) = old_msg_left(:,node_idx) + I(:,node_idx);
      else
        for state = 1:num_states
          msg_left(state,node_idx+1) = max(I(:,node_idx) + old_msg_left(:,node_idx) - (state-(1:10).').^2);
        end
        if normalize
          msg_left(:,node_idx+1) = msg_left(:,node_idx+1) - max(msg_left(:,node_idx+1));
        end
      end
    end
    if node_idx > 1
      if 0
        msg_right(:,node_idx-1) = old_msg_right(:,node_idx) + I(:,node_idx);
      else
        for state = 1:num_states
          msg_right(state,node_idx-1) = max(I(:,node_idx) + old_msg_right(:,node_idx) - (state-(1:10).').^2);
        end
        if normalize
          msg_right(:,node_idx-1) = msg_right(:,node_idx-1) - max(msg_right(:,node_idx-1));
        end
      end
    end;
    if trws_en
      old_msg_right = msg_right;
      old_msg_left = msg_left;
    end
    imagesc(msg_left);
    imagesc(msg_right);
    
    imagesc(I + msg_left + msg_right);
  end
  
  old_msg_right = msg_right;
  old_msg_left = msg_left;
  [~,result] = max(I + msg_left + msg_right)
  clf;
  imagesc(I + msg_left + msg_right);
  hold on
  plot(result)
end

[confidence,result] = max(I + msg_left + msg_right)
