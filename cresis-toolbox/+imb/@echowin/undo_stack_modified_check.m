function cancel_operation = undo_stack_modified_check(obj,force_save_or_cancel_flag)
% cancel_operation = undo_stack_modified_check(obj,force_save_or_cancel_flag)
%
% Check to see if undo stack got created and, if it did, if there are
% any items in the undostack (i.e. operations that have not been saved)
%
% force_save_or_cancel_flag: optional logic scalar. default is false. If
%   true, then the only options are Yes or Cancel.

if nargin < 2 || isempty(force_save_or_cancel_flag)
  force_save_or_cancel_flag = false;
end

if isempty(obj.undo_stack) || ~obj.undo_stack.ismodified()
  cancel_operation = false;
else
  if force_save_or_cancel_flag
    prompt = questdlg('There are unsaved layers. You must save them now to continnue with this operation. Would you like to save and continue?',...
      'Unsaved Layers','Yes','Cancel','Yes');
  else
    prompt = questdlg('There are unsaved layers. You do not need to save them now, but would you like to?',...
      'Unsaved Layers','Yes','No','Cancel','Yes');
  end
  switch prompt
    case 'Yes'
      % save
      obj.savePB_callback();
      cancel_operation = false;
    case 'No'
      cancel_operation = false;
    case 'Cancel'
      % Go back
      cancel_operation = true;
    case ''
      % Go back
      cancel_operation = true;
  end
end
