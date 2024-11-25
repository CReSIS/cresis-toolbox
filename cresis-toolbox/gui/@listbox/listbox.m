classdef listbox < handle
% listbox: A class for creating an integrated label, listbox or popupmenu,
% and edit
%
% parent: parent GUI handle for each of the GUI objects
% name: label
% list_style: 'listbox' or 'popupmenu'
% list_values: cell vector of strings
% init_value: scalar integer index into list_values vector
  
  properties
    h_text
    h_list
    h_LE
    h_CM
    h_CM_add
    h_CM_edit
    h_CM_remove
    cur_entry_mode
  end
  
  properties (SetAccess = private, GetAccess = private)
  end
   
  events
    list_changed
  end
  
  methods
    function obj = listbox(parent,name,list_style,list_values,init_value)
      %%% Pre Initialization %%%
      % Any code not using output argument (obj)
      
      %%% Post Initialization %%%
      % Any code, including access to object
      obj.cur_entry_mode = 'edit';
      
      obj.h_text = uicontrol('Parent',parent);
      set(obj.h_text,'Style','Text');
      set(obj.h_text,'String',name);
      
      obj.h_list = uicontrol('Parent',parent);
      set(obj.h_list,'Style',list_style);
      set(obj.h_list,'String',list_values);
      set(obj.h_list,'Value',init_value);
      set(obj.h_list,'Callback',@obj.list_callback);
      
      obj.h_LE = uicontrol('Parent',parent);
      set(obj.h_LE,'Style','Edit');
      set(obj.h_LE,'String',list_values{init_value});
      set(obj.h_LE,'Callback',@obj.list_callback);

      %% Source list box context menu
      obj.h_CM = uicontextmenu;
      % Define the context menu items and install their callbacks
      obj.h_CM_add = uimenu(obj.h_CM, 'Label', 'Add', 'Callback', @obj.CM_callback);
      obj.h_CM_edit = uimenu(obj.h_CM, 'Label', 'Edit', 'Callback', @obj.CM_callback);
      obj.h_CM_remove = uimenu(obj.h_CM, 'Label', 'Remove', 'Callback', @obj.CM_callback);
      set(obj.h_list,'uicontextmenu',obj.h_CM);

    end
    
    function delete(obj)
    end
    
    function CM_callback(obj, h_obj, event)
      list_string = get(obj.h_list,'String');
      cur_entry = get(obj.h_list,'Value');
      if isempty(cur_entry)
        obj.cur_entry_mode = 'add';
        return;
      end
      if h_obj == obj.h_CM_add
        % Next entered item will be added
        obj.cur_entry_mode = 'add';
      elseif h_obj == obj.h_CM_edit
        % Next entered item will replace the current selection
        obj.cur_entry_mode = 'edit';
      elseif h_obj == obj.h_CM_remove
        % Remove selected item from list
        if length(list_string) > 1
          if cur_entry == length(list_string)
            set(obj.h_list,'Value',length(list_string)-1);
            obj.cur_entry_mode = 'add';
          end
          list_string = list_string([1:cur_entry-1,cur_entry+1:end]);
          set(obj.h_list,'String',list_string);
        else
          set(obj.h_list,'String',{});
          set(obj.h_list,'Value',[]);
          obj.cur_entry_mode = 'add';
        end
      end
    end

    function list_callback(obj, h_obj, event)
      list_string = get(obj.h_list,'String');
      cur_entry = get(obj.h_list,'Value');
      if isempty(cur_entry)
        cur_entry = length(list_string);
      end
      if h_obj == obj.h_list
        % User selected a value in the list
        if strcmpi(get(gcf,'SelectionType'),'Open')
          notify(obj,'list_changed');
        else
          set(obj.h_LE,'String',list_string{cur_entry});
        end
      elseif h_obj == obj.h_LE
        % User entered a new item
        if strcmpi(obj.cur_entry_mode,'add')
          % Add entry to the list
          new_entry = get(obj.h_LE,'String');
          list_string = {list_string{1:cur_entry}, new_entry, list_string{cur_entry+1:end}};
          set(obj.h_list,'String',list_string);
          set(obj.h_list,'Value',cur_entry+1);
          obj.cur_entry_mode = 'edit';
        elseif strcmpi(obj.cur_entry_mode,'edit') && cur_entry > 0
          % Replace an entry in the list
          new_entry = get(obj.h_LE,'String');
          list_string{cur_entry} = new_entry;
          set(obj.h_list,'String',list_string);
          set(obj.h_list,'Value',cur_entry);
        end
      end
    end
    
    function val = get_value(obj)
      val = get(obj.h_list,'Value');
    end
    
    function set_value(obj, val)
      set(obj.h_list,'Value',val);
    end
    
    function str = get_string(obj)
      list_string = get(obj.h_list,'String');
      val = get(obj.h_list,'Value');
      str = list_string{val};
    end
    
  end
  
end


