function cmds_set_undo_stack_after_draw(obj,cmds_list)
% cmds_set_undo_stack_after_draw(obj,cmds_list)
%
% Run commands from cmds_set_undo_stack and updates save button.
%
% cmds_list: list of commands to be run with cmds_execute

% Since there may be commands in the undo stack already, we will run these
% commands so that the new echowin is synced up with the stack.
obj.cmds_execute(cmds_list,'redo');

% Check to see if any modifications have been done relative to the last
% save.
if obj.undo_stack.ismodified()
  set(obj.left_panel.savePB,'String','(S)ave Layer*');
else
  set(obj.left_panel.savePB,'String','(S)ave Layer');
end
