function cmds_list = cmds_set_undo_stack(obj,undo_stack)
% cmds_list = cmds_set_undo_stack(obj,undo_stack)
%
% Attach or detach undo stack. Also adds or deletes listeners.
%
% Attach:
% undo_stack = undo stack handle class
% Detach:
% undo_stack = empty ([])
%
% cmds_list: list of commands to be run with cmds_execute
% 
% Returns list of commands that need to be run (i.e. commands that have not
% been saved yet). After echo.draw() is called, then run the second part of
% this function:
%  obj.cmds_set_undo_stack_after_draw(cmds_list);


if isempty(undo_stack)
  % Detach the current undo stack
  if isa(obj.undo_stack,'imb.undo_stack')
    try
      obj.undo_stack.remove_document(obj);
    end
    try
      delete(obj.undo_stack_synchronize_listener);
    end
    try
      delete(obj.undo_stack_save_listener);
    end
    obj.undo_stack = [];
  end
  cmds_list = {};
else
  obj.undo_stack = undo_stack;
  
  obj.undo_stack_save_listener ...
    = addlistener(obj.undo_stack,'save_event',@obj.cmds_save);
  obj.undo_stack_synchronize_listener ...
    = addlistener(obj.undo_stack,'synchronize_event',@obj.cmds_synchronize);
  
  % Attach echowin to undo stack and get any commands that have not been run
  % yet.
  cmds_list = obj.undo_stack.attach_document(obj);
  
end
