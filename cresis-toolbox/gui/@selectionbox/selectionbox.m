classdef selectionbox < handle
% selectionbox: A class for creating two listboxes with items that can be
% moved back and forth between them.  Double click to select/remove items.
%
% parent: parent GUI handle for each of the GUI objects
% name: label
% list_values: cell vector of strings
% init_value: scalar integer index into list_values vector

  properties
    h_text
    h_list_available
    h_list_selected
    h_list_availableCM
    h_list_selectedCM
    fh_available
    fh_selected
    enable_mode
    
    % Data in listboxes
    strings
    ids
    orders
    selected_mask
  end
  
  properties (SetAccess = private, GetAccess = private)
  end
   
  events
    selection_changed
  end
  
  methods
    %% constructor
    function obj = selectionbox(parent,name,list_values,init_value,list_ids,list_orders)
      % List boxes start enabled by default
      obj.enable_mode = true;
      
      obj.strings = list_values;
      if exist('list_ids','var') && ~isempty(list_ids)
        obj.ids = list_ids;
      else
        obj.ids = 1:length(list_values);
      end
      if exist('list_orders','var') && ~isempty(list_orders)
        obj.orders = list_orders;
      else
        obj.orders = 1:length(list_values);
      end
      obj.selected_mask = false(size(obj.strings));
      
      obj.h_text = uicontrol('Parent',parent);
      set(obj.h_text,'Style','Text');
      set(obj.h_text,'String',name);
      
      obj.h_list_available = uicontrol('Parent',parent);
      set(obj.h_list_available,'Style','listbox');
      set(obj.h_list_available,'String',list_values);
      set(obj.h_list_available,'Value',init_value);
      set(obj.h_list_available,'Max',1e9);
      set(obj.h_list_available,'Callback',@obj.list_callback);
      
      obj.h_list_selected = uicontrol('Parent',parent);
      set(obj.h_list_selected,'Style','listbox');
      set(obj.h_list_selected,'String',[]);
      set(obj.h_list_selected,'Value',1);
      set(obj.h_list_selected,'Max',1e9);
      set(obj.h_list_selected,'Callback',@obj.list_callback);

      obj.h_list_availableCM = uicontextmenu('Parent',parent);
      % Define the context menu items and install their callbacks
      uimenu(obj.h_list_availableCM, 'Label', 'Add', 'Callback', @obj.available_callback);
      uimenu(obj.h_list_availableCM, 'Label', 'Up', 'Callback', @obj.available_callback);
      uimenu(obj.h_list_availableCM, 'Label', 'Down', 'Callback', @obj.available_callback);
      uimenu(obj.h_list_availableCM, 'Label', 'Top', 'Callback', @obj.available_callback);
      uimenu(obj.h_list_availableCM, 'Label', 'Bottom', 'Callback', @obj.available_callback);
      set(obj.h_list_available,'uicontextmenu',obj.h_list_availableCM)
      
      obj.h_list_selectedCM = uicontextmenu('Parent',parent);
      % Define the context menu items and install their callbacks
      uimenu(obj.h_list_selectedCM, 'Label', 'Remove', 'Callback', @obj.selected_callback);
      uimenu(obj.h_list_selectedCM, 'Label', 'Up', 'Callback', @obj.selected_callback);
      uimenu(obj.h_list_selectedCM, 'Label', 'Down', 'Callback', @obj.selected_callback);
      uimenu(obj.h_list_selectedCM, 'Label', 'Top', 'Callback', @obj.selected_callback);
      uimenu(obj.h_list_selectedCM, 'Label', 'Bottom', 'Callback', @obj.selected_callback);
      set(obj.h_list_selected,'uicontextmenu',obj.h_list_selectedCM)

    end
    
    %% destructor
    function delete(obj)
      try
        delete(obj.h_list_available);
      end
      try
        delete(obj.h_list_selected);
      end
    end
    
    %% available_callback
    function available_callback(obj,status,event)
      h_status = get(status);
      if isfield(h_status,'Label')
        context_menu = get(status,'Label');
      elseif isfield(h_status,'text')
        context_menu = get(status,'text');
      else
        context_menu = '';
      end
      
      if strcmpi(context_menu,'Add')
        %% available_callback: add
        % Get the highlighted entries in the available box, return if
        % nothing is selected since there will be nothing to do
        match_idxs = get(obj.h_list_available,'Value');
        if isempty(match_idxs)
          return
        end
        
        % Create sorted selected_mask
        [~,sort_idxs] = sort(obj.orders);
        [~,unsort_idxs] = sort(sort_idxs);
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Get indexes into the obj.selected_mask that are selected and then
        % update these entries to be moved to the selected listbox
        change_idxs = find(~sort_selected_mask);
        sort_selected_mask(change_idxs(match_idxs)) = true;
        obj.selected_mask = sort_selected_mask(unsort_idxs);
        
        % Create updated sorted selected_mask
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Reset selected entry in the available list
        set(obj.h_list_available,'value',min(sum(~obj.selected_mask),min(match_idxs)));
        
        % Set selected entries in the selected list to the new items
        new_value = zeros(size(match_idxs));
        for idx = 1:length(match_idxs)
          new_value(idx) = sum(sort_selected_mask(1:change_idxs(match_idxs(idx))));
        end
        set(obj.h_list_selected,'value',new_value);
        
        % Update the available and selected listboxes
        available_list = obj.strings(sort_idxs(~sort_selected_mask));
        set(obj.h_list_available,'string',available_list);
        selected_list = obj.strings(sort_idxs(sort_selected_mask));
        set(obj.h_list_selected,'string',selected_list);
        
        % Notify event that selection has changed
        notify(obj,'selection_changed');
        
      elseif strcmpi(context_menu,'Up')
        %% available_callback: up
        % Check to see if there is an element above the top selected
        % element, if not quit and do nothing
        match_idxs = get(obj.h_list_available,'Value');
        if isempty(match_idxs) || match_idxs(1) == 1
          return
        end
        
        for match_idx = match_idxs(:).';
          % Create sorted selected_mask
          [sort_orders,sort_idxs] = sort(obj.orders);
          sort_selected_mask = obj.selected_mask(sort_idxs);
          
          % Create list of sorted orders with just the available items in
          % it
          sort_orders_masked = sort_orders(~sort_selected_mask);
          
          % Find order values in the range
          idxs = find(obj.orders >= sort_orders_masked(match_idx-1) & obj.orders <= sort_orders_masked(match_idx));
          
          % Shift the item before the selected items so that it is at the
          % end.
          obj.orders(idxs) = obj.orders(idxs([2:end 1]));
        end
        
        % Create sorted selected_mask
        [~,sort_idxs] = sort(obj.orders);
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Update the listbox
        available_list = obj.strings(sort_idxs(~sort_selected_mask));
        set(obj.h_list_available,'string',available_list);
        
        % Update selected entries
        set(obj.h_list_available,'value',match_idxs-1);
        
      elseif strcmpi(context_menu,'Down')
      %% available_callback: down
        % Check to see if there is an element below the bottom selected
        % element, if not quit and do nothing
        match_idxs = get(obj.h_list_available,'Value');
        if isempty(match_idxs) || match_idxs(end) == sum(~obj.selected_mask)
          return
        end
        
        for match_idx = fliplr(match_idxs(:).');
          % Create sorted selected_mask
          [sort_orders,sort_idxs] = sort(obj.orders);
          sort_selected_mask = obj.selected_mask(sort_idxs);
          
          sort_orders_masked = sort_orders(~sort_selected_mask);
          
          idxs = find(obj.orders >= sort_orders_masked(match_idx) & obj.orders <= sort_orders_masked(match_idx+1));
          
          obj.orders(idxs) = obj.orders(idxs([end 1:end-1]));
        end
        
        % Create sorted selected_mask
        [~,sort_idxs] = sort(obj.orders);
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Update the listbox
        available_list = obj.strings(sort_idxs(~sort_selected_mask));
        set(obj.h_list_available,'string',available_list);
        
        % Update selected entries
        set(obj.h_list_available,'value',match_idxs+1);
        
      elseif strcmpi(context_menu,'Top')
        %% available_callback: top
        % Check to see if there is an element above the top selected
        % element, if not quit and do nothing
        match_idxs = get(obj.h_list_available,'Value');
        if isempty(match_idxs) || match_idxs(1) == 1
          return
        end
        
        % Create sorted selected_mask
        [sort_orders,sort_idxs] = sort(obj.orders);
        [~,unsort_idxs] = sort(sort_idxs);
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Get indexes into the obj.selected_mask that are selected and then
        % update these entries to be moved to the selected listbox
        sort_orders_masked = sort_orders(~sort_selected_mask);
        
        % Find range of orders to move
        orders_mask = obj.orders >= sort_orders_masked(match_idxs(1)) & obj.orders <= sort_orders_masked(match_idxs(end));
        
        % Determine where in the sorted list these (need to be moved) orders are
        sort_orders_mask = orders_mask(sort_idxs);
        
        % Move these orders around in the sorted domain
        new_sort_orders(sort_orders_mask) = sort_orders(1:sum(sort_orders_mask));
        new_sort_orders(~sort_orders_mask) = sort_orders(sum(sort_orders_mask)+1:end);
        
        % Convert the new ordering back to the unsorted domain
        obj.orders = new_sort_orders(unsort_idxs);
        
        % Update sorted selected_mask
        [~,sort_idxs] = sort(obj.orders);
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Update the listbox
        available_list = obj.strings(sort_idxs(~sort_selected_mask));
        set(obj.h_list_available,'string',available_list);
        
        % Update selected entries
        set(obj.h_list_available,'value',1:sum(sort_orders_mask));
      
      elseif strcmpi(context_menu,'Bottom')
        %% available_callback: bottom
        % Check to see if there is an element above the top selected
        % element, if not quit and do nothing
        match_idxs = get(obj.h_list_available,'Value');
        if isempty(match_idxs) || match_idxs(end) == sum(~obj.selected_mask)
          return
        end
        
        % Create sorted selected_mask
        [sort_orders,sort_idxs] = sort(obj.orders);
        [~,unsort_idxs] = sort(sort_idxs);
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Get indexes into the obj.selected_mask that are selected and then
        % update these entries to be moved to the selected listbox
        sort_orders_masked = sort_orders(~sort_selected_mask);
        
        % Find range of orders to move
        orders_mask = obj.orders >= sort_orders_masked(match_idxs(1)) & obj.orders <= sort_orders_masked(match_idxs(end));
        
        % Determine where in the sorted list these (need to be moved) orders are
        sort_orders_mask = orders_mask(sort_idxs);
        
        % Move these orders around in the sorted domain
        new_sort_orders(sort_orders_mask) = sort_orders(end+(-sum(sort_orders_mask)+1:0));
        new_sort_orders(~sort_orders_mask) = sort_orders(1:end-sum(sort_orders_mask));
        
        % Convert the new ordering back to the unsorted domain
        obj.orders = new_sort_orders(unsort_idxs);
        
        % Update sorted selected_mask
        [~,sort_idxs] = sort(obj.orders);
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Update the listbox
        available_list = obj.strings(sort_idxs(~sort_selected_mask));
        set(obj.h_list_available,'string',available_list);
        
        % Update selected entries
        set(obj.h_list_available,'value',length(available_list)+(-sum(sort_orders_mask)+1:0));
      
      else
        obj.fh_available(status,event);
      end
    end
    
    %% selected_callback
    function selected_callback(obj,status,event)
      % ===================================================================
      % ===================================================================
      % COPIED FROM available_callback WITH CHANGES INDICATED WITH "-->"
      % ===================================================================
      % ===================================================================
      h_status = get(status);
      if isfield(h_status,'Label')
        context_menu = get(status,'Label');
      elseif isfield(h_status,'text')
        context_menu = get(status,'text');
      else
        context_menu = '';
      end
      
      if strcmpi(context_menu,'Remove')
        %% selected_callback: remove
        % Get the highlighted entries in the selected box, return if
        % nothing is selected since there will be nothing to do
        match_idxs = get(obj.h_list_selected,'Value');
        if isempty(match_idxs)
          return
        end
        
        % Create sorted selected_mask
        [~,sort_idxs] = sort(obj.orders);
        [~,unsort_idxs] = sort(sort_idxs);
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Get indexes into the obj.selected_mask that are selected and then
        % update these entries to be moved to the selected listbox
        change_idxs = find(sort_selected_mask); % ~sort_selected_mask --> sort_selected_mask
        sort_selected_mask(change_idxs(match_idxs)) = false; % true --> false 
        obj.selected_mask = sort_selected_mask(unsort_idxs);
        
        % Create updated sorted selected_mask
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Reset selected entry in the selected list
        set(obj.h_list_selected,'value',min(sum(obj.selected_mask),min(match_idxs))); % h_list_available --> h_list_selected
        
        % Set selected entries in the available list to the new items
        new_value = zeros(size(match_idxs));
        for idx = 1:length(match_idxs)
          new_value(idx) = sum(~sort_selected_mask(1:change_idxs(match_idxs(idx)))); % ~sort_selected_mask --> sort_selected_mask
        end
        set(obj.h_list_available,'value',new_value); % h_list_selected --> h_list_available
        
        % Update the available and selected listboxes
        available_list = obj.strings(sort_idxs(~sort_selected_mask));
        set(obj.h_list_available,'string',available_list);
        selected_list = obj.strings(sort_idxs(sort_selected_mask));
        set(obj.h_list_selected,'string',selected_list);
        
        % Notify event that selection has changed
        notify(obj,'selection_changed');
        
      elseif strcmpi(context_menu,'Up')
        %% selected_callback: up
        % Check to see if there is an element above the top selected
        % element, if not quit and do nothing
        match_idxs = get(obj.h_list_selected,'Value'); % h_list_available --> h_list_selected
        if isempty(match_idxs) || match_idxs(1) == 1
          return
        end
        
        for match_idx = match_idxs(:).';
          % Create sorted selected_mask
          [sort_orders,sort_idxs] = sort(obj.orders);
          sort_selected_mask = obj.selected_mask(sort_idxs);
          
          % Create list of sorted orders with just the available items in
          % it
          sort_orders_masked = sort_orders(sort_selected_mask); % ~sort_selected_mask --> sort_selected_mask
          
          % Find order values in the range
          idxs = find(obj.orders >= sort_orders_masked(match_idx-1) & obj.orders <= sort_orders_masked(match_idx));
          
          % Shift the item before the selected items so that it is at the
          % end.
          obj.orders(idxs) = obj.orders(idxs([2:end 1]));
        end
        
        % Create sorted selected_mask
        [~,sort_idxs] = sort(obj.orders);
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Update the listbox
        selected_list = obj.strings(sort_idxs(sort_selected_mask)); % ~sort_selected_mask --> sort_selected_mask
        set(obj.h_list_selected,'string',selected_list); % h_list_available --> h_list_selected
        
        % Update selected entries
        set(obj.h_list_selected,'value',match_idxs-1); % h_list_available --> h_list_selected
        
      elseif strcmpi(context_menu,'Down')
        %% selected_callback: down
        % Check to see if there is an element below the bottom selected
        % element, if not quit and do nothing
        match_idxs = get(obj.h_list_selected,'Value'); % h_list_available --> h_list_selected
        if isempty(match_idxs) || match_idxs(end) == sum(obj.selected_mask) % ~obj.selected_mask --> obj.selected_mask
          return
        end
        
        for match_idx = fliplr(match_idxs(:).');
          % Create sorted selected_mask
          [sort_orders,sort_idxs] = sort(obj.orders);
          sort_selected_mask = obj.selected_mask(sort_idxs);
          
          sort_orders_masked = sort_orders(sort_selected_mask); % ~sort_selected_mask --> sort_selected_mask
          
          idxs = find(obj.orders >= sort_orders_masked(match_idx) & obj.orders <= sort_orders_masked(match_idx+1));
          
          obj.orders(idxs) = obj.orders(idxs([end 1:end-1]));
        end
        
        % Create sorted selected_mask
        [~,sort_idxs] = sort(obj.orders);
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Update the listbox
        selected_list = obj.strings(sort_idxs(sort_selected_mask)); % ~sort_selected_mask --> sort_selected_mask
        set(obj.h_list_selected,'string',selected_list); % h_list_available --> h_list_selected
        
        % Update selected entries
        set(obj.h_list_selected,'value',match_idxs+1); % h_list_available --> h_list_selected
        
      elseif strcmpi(context_menu,'Top')
        %% selected_callback: top
        % Check to see if there is an element above the top selected
        % element, if not quit and do nothing
        match_idxs = get(obj.h_list_selected,'Value'); % h_list_available --> h_list_selected
        if isempty(match_idxs) || match_idxs(1) == 1
          return
        end
        
        % Create sorted selected_mask
        [sort_orders,sort_idxs] = sort(obj.orders);
        [~,unsort_idxs] = sort(sort_idxs);
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Get indexes into the obj.selected_mask that are selected and then
        % update these entries to be moved to the selected listbox
        sort_orders_masked = sort_orders(sort_selected_mask); % ~sort_selected_mask --> sort_selected_mask
        
        % Find range of orders to move
        orders_mask = obj.orders >= sort_orders_masked(match_idxs(1)) & obj.orders <= sort_orders_masked(match_idxs(end));
        
        % Determine where in the sorted list these (need to be moved) orders are
        sort_orders_mask = orders_mask(sort_idxs);
        
        % Move these orders around in the sorted domain
        new_sort_orders(sort_orders_mask) = sort_orders(1:sum(sort_orders_mask));
        new_sort_orders(~sort_orders_mask) = sort_orders(sum(sort_orders_mask)+1:end);
        
        % Convert the new ordering back to the unsorted domain
        obj.orders = new_sort_orders(unsort_idxs);
        
        % Update sorted selected_mask
        [~,sort_idxs] = sort(obj.orders);
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Update the listbox
        selected_list = obj.strings(sort_idxs(sort_selected_mask)); % ~sort_selected_mask --> sort_selected_mask
        set(obj.h_list_selected,'string',selected_list); % h_list_available --> h_list_selected
        
        % Update selected entries
        set(obj.h_list_selected,'value',1:sum(sort_orders_mask)); % h_list_available --> h_list_selected
      
      elseif strcmpi(context_menu,'Bottom')
        %% selected_callback: bottom
        % Check to see if there is an element above the top selected
        % element, if not quit and do nothing
        match_idxs = get(obj.h_list_selected,'Value'); % h_list_available --> h_list_selected
        if isempty(match_idxs) || match_idxs(end) == sum(obj.selected_mask) % ~obj.selected_mask --> obj.selected_mask
          return
        end
        
        % Create sorted selected_mask
        [sort_orders,sort_idxs] = sort(obj.orders);
        [~,unsort_idxs] = sort(sort_idxs);
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Get indexes into the obj.selected_mask that are selected and then
        % update these entries to be moved to the selected listbox
        sort_orders_masked = sort_orders(sort_selected_mask); % ~sort_selected_mask --> sort_selected_mask
        
        % Find range of orders to move
        orders_mask = obj.orders >= sort_orders_masked(match_idxs(1)) & obj.orders <= sort_orders_masked(match_idxs(end));
        
        % Determine where in the sorted list these (need to be moved) orders are
        sort_orders_mask = orders_mask(sort_idxs);
        
        % Move these orders around in the sorted domain
        new_sort_orders(sort_orders_mask) = sort_orders(end+(-sum(sort_orders_mask)+1:0));
        new_sort_orders(~sort_orders_mask) = sort_orders(1:end-sum(sort_orders_mask));
        
        % Convert the new ordering back to the unsorted domain
        obj.orders = new_sort_orders(unsort_idxs);
        
        % Update sorted selected_mask
        [~,sort_idxs] = sort(obj.orders);
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Update the listbox
        selected_list = obj.strings(sort_idxs(sort_selected_mask)); % ~sort_selected_mask --> sort_selected_mask
        set(obj.h_list_selected,'string',selected_list); % h_list_available --> h_list_selected
        
        % Update selected entries
        set(obj.h_list_selected,'value',length(selected_list)+(-sum(sort_orders_mask)+1:0)); % h_list_available --> h_list_selected

      else
        obj.fh_available(status,event);
      end
    end
    
    %% list_callback
    function list_callback(obj, h_obj, event)
      if strcmpi(get(gcf,'SelectionType'),'Open')
        % Double click causes the currently selected item to switch lists
        
        % Get the highlighted entries in the available box, return if
        % nothing is selected since there will be nothing to do
        match_idxs = get(h_obj,'Value');
        if isempty(match_idxs)
          return;
        end
        
        % Create sorted selected_mask
        [~,sort_idxs] = sort(obj.orders);
        [~,unsort_idxs] = sort(sort_idxs);
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        % Determine which list was double clicked in
        if h_obj == obj.h_list_available
          % Move from available to selected
          % ---------------------------------------------------------------
          
          % Get indexes into the obj.selected_mask that are selected and then
          % update these entries to be moved to the selected listbox
          change_idxs = find(~sort_selected_mask);
          sort_selected_mask(change_idxs(match_idxs)) = true;
          obj.selected_mask = sort_selected_mask(unsort_idxs);
          
          % Create updated sorted selected_mask
          sort_selected_mask = obj.selected_mask(sort_idxs);
          
          % Reset selected entry in the available list
          set(obj.h_list_available,'value',min(sum(~obj.selected_mask),min(match_idxs)));
          
          % Set selected entries in the selected list to the new items
          new_value = zeros(size(match_idxs));
          for idx = 1:length(match_idxs)
            new_value(idx) = sum(sort_selected_mask(1:change_idxs(match_idxs(idx))));
          end
          set(obj.h_list_selected,'value',new_value);
          
        else
          % Move from selected to available
          % ---------------------------------------------------------------
          
          % Get indexes into the obj.selected_mask that are selected and then
          % update these entries to be moved to the selected listbox
          change_idxs = find(sort_selected_mask);
          sort_selected_mask(change_idxs(match_idxs)) = false;
          obj.selected_mask = sort_selected_mask(unsort_idxs);
          
          % Create updated sorted selected_mask
          sort_selected_mask = obj.selected_mask(sort_idxs);
          
          % Reset selected entry in the selected list
          set(obj.h_list_selected,'value',min(sum(obj.selected_mask),min(match_idxs)));
          
          % Set selected entries in the available list to the new items
          new_value = zeros(size(match_idxs));
          for idx = 1:length(match_idxs)
            new_value(idx) = sum(~sort_selected_mask(1:change_idxs(match_idxs(idx))));
          end
          set(obj.h_list_available,'value',new_value);
        end
        
        % Update the available and selected listboxes
        available_list = obj.strings(sort_idxs(~sort_selected_mask));
        set(obj.h_list_available,'string',available_list);
        selected_list = obj.strings(sort_idxs(sort_selected_mask));
        set(obj.h_list_selected,'string',selected_list);
        
        % Notify event that selection has changed
        notify(obj,'selection_changed');
        
      end
    end
    
    %% get_selected_values
    function vals = get_selected_values(obj)
      vals = get(obj.h_list_selected,'Value');
    end
    
    %% get_selected_strings
    function strings = get_selected_strings(obj)
      strings = get(obj.h_list_selected,'string');
    end
    
    %% set_list
    function set_list(obj, strings, ids, orders)
      % strings: cell vector of character strings that will be displayed
      %
      % ids: corresponding id for each string (optional). Default is
      % integers from 1 to length(strings)
      %
      % orders: corresponding order that determines in what order the
      % strings will be listed (optional). Default is the order that the
      % values are passed in.
      %
      % If items in val already exist in either available or selected then
      % they will stay in that listbox, items not in val are removed, new
      % items from val are placed in available.
      
      obj.strings = strings;
      if exist('ids','var') && ~isempty(ids)
        obj.ids = ids;
      else
        obj.ids = 1:length(obj.strings);
      end
      if exist('orders','var') && ~isempty(orders)
        obj.orders = orders;
      else
        obj.orders = 1:length(obj.strings);
      end
      
      % Keep track of which values are in the "available" box and which ones
      % of those are selected.
      available_values = get(obj.h_list_available,'value');
      available_list = get(obj.h_list_available,'string');
      if ~isempty(available_list)
        available_highlighted = available_list(available_values);
      else
        available_highlighted = {};
      end
      
      % Keep track of which values are in the "selected" box and which ones
      % of those are selected.
      selected_values = get(obj.h_list_selected,'value');
      selected_list = get(obj.h_list_selected,'string');
      if ~isempty(selected_list)
        selected_highlighted = selected_list(selected_values);
      else
        selected_highlighted = {};
      end
      
      % Any items that were in the "selected" box, will stay in the
      % selected box. All other items will be placed in the available box.
      obj.selected_mask = false(size(obj.strings));
      for idx = 1:length(obj.strings)
        obj.selected_mask(idx) = any(strcmpi(obj.strings{idx},selected_list));
      end
      [~,sort_idxs] = sort(obj.orders);
      sort_selected_mask = obj.selected_mask(sort_idxs);
      
      available_list = obj.strings(sort_idxs(~sort_selected_mask));
      set(obj.h_list_available,'string',available_list);
      selected_list = obj.strings(sort_idxs(sort_selected_mask));
      set(obj.h_list_selected,'string',selected_list);
      
      % Check which of the new items needs to be selected and also check to
      % see if the selection has changed because an item is no longer
      % available.
      available_values = [];
      available_highlighted_mask = false(size(available_highlighted));
      for idx = 1:length(available_highlighted)
        match_idx = find(strcmp(available_highlighted{idx},available_list),1);
        if ~isempty(match_idx)
          available_values(end+1) = match_idx;
          available_highlighted_mask(idx) = true;
        end
      end
      
      selected_values = [];
      selected_highlighted_mask = false(size(selected_highlighted));
      for idx = 1:length(selected_highlighted)
        match_idx = find(strcmp(selected_highlighted{idx},selected_list),1);
        if ~isempty(match_idx)
          selected_values(end+1) = match_idx;
          selected_highlighted_mask(idx) = true;
        end
      end
      
      % Reselect the same items that were selected before
      set(obj.h_list_available,'value',available_values);
      set(obj.h_list_selected,'value',selected_values);
      
      % If the selection changed in either listbox, then notify event
      if any(~available_highlighted_mask) || any(~selected_highlighted_mask)
        notify(obj,'selection_changed');
      end
    end
    
    %% set_available
    function set_available(obj, strings, ids, orders)
      % Same as set_list, but resets the listbox so that everything shows
      % up in the available box.
      
      obj.strings = strings;
      if exist('ids','var') && ~isempty(ids)
        obj.ids = ids;
      else
        obj.ids = 1:length(obj.strings);
      end
      if exist('orders','var') && ~isempty(orders)
        obj.orders = orders;
      else
        obj.orders = 1:length(obj.strings);
      end
      
      % Any items that were in the "selected" box, will stay in the
      % selected box. All other items will be placed in the available box.
      obj.selected_mask = false(size(obj.strings));
      
      available_list = obj.strings;
      set(obj.h_list_available,'string',available_list);
      selected_list = {};
      set(obj.h_list_selected,'string',selected_list);
      
      % Reselect the same items that were selected before
      if ~isempty(obj.strings)
        set(obj.h_list_available,'value',1);
      else
        set(obj.h_list_available,'value',[]);
      end
      set(obj.h_list_selected,'value',[]);
      
      % If the selection changed in either listbox, then notify event
      notify(obj,'selection_changed');
    end
    
    %% set_selected
    function set_selected(obj, strings, selected_state)
      % strings: cell vector of character strings or array of indices to
      % strings
      %
      % selected_state: logical (true to select and move to the selected
      % list, false to deselect and move to the available list)
      %
      % Strings or indices that match will be (de)selected
      
      selection_changed = false;
      for str_idx = 1:length(strings)
        match_idx = find(strcmp(strings{str_idx},obj.strings));
        if ~isempty(match_idx) && obj.selected_mask(match_idx) ~= selected_state
          selection_changed = true;
          
          obj.selected_mask(match_idx) = selected_state;
        end
      end
      
      if selection_changed
        [~,sort_idxs] = sort(obj.orders);
        sort_selected_mask = obj.selected_mask(sort_idxs);
        
        available_list = obj.strings(sort_idxs(~sort_selected_mask));
        set(obj.h_list_available,'string',available_list);
        selected_list = obj.strings(sort_idxs(sort_selected_mask));
        set(obj.h_list_selected,'string',selected_list);
        
        notify(obj,'selection_changed');
      end
    end
    
    %% set_enable
    function set_enable(obj,enable_mode)
      if obj.enable_mode ~= enable_mode
        obj.enable_mode = enable_mode;
        if obj.enable_mode
          set(obj.h_list_available,'Enable','on');
          set(obj.h_list_selected,'Enable','on');
          set(obj.h_list_available,'uicontextmenu',obj.h_list_availableCM);
          set(obj.h_list_selected,'uicontextmenu',obj.h_list_selectedCM);
        else
          set(obj.h_list_available,'Enable','off');
          set(obj.h_list_selected,'Enable','off');
          set(obj.h_list_available,'uicontextmenu',[]);
          set(obj.h_list_selected,'uicontextmenu',[]);
        end
      end
    end
    
  end
  
end


