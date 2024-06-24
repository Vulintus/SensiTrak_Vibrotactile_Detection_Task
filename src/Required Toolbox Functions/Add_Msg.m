function Add_Msg(msgbox,new_msg)
%
%Add_Msg.m - Vulintus, Inc.
%
%   ADD_MSG displays messages in a listbox on a GUI, adding new messages to
%   the bottom of the list.
%
%   Add_Msg(listbox,new_msg) adds the string or cell array of strings
%   specified in the variable "new_msg" as the last entry or entries in the
%   ListBox or Text Area whose handle is specified by the variable 
%   "msgbox".
%
%   UPDATE LOG:
%   2016-09-09 - Drew Sloan - Fixed the bug caused by setting the
%                             ListboxTop property to an non-existent item.
%   2021-11-26 - Drew Sloan - Added the option to post status messages to a
%                             scrolling text area (uitextarea).
%   2022-02-02 - Drew Sloan - Fixed handling of the UIControl ListBox type
%                             to now use the "style" for identification.
%   2024-06-11 - Drew Sloan - Added a for loop to handle arrays of
%                             messageboxes.
%

for gui_i = 1:length(msgbox)                                                %Step through each messagebox.

    switch get(msgbox(gui_i),'type')                                        %Switch between the recognized components.
        
        case 'uicontrol'                                                    %If the messagebox is a listbox...
            switch get(msgbox(gui_i),'style')                               %Switch between the recognized uicontrol styles.
                
                case 'listbox'                                              %If the messagebox is a listbox...
                    messages = get(msgbox(gui_i),'string');                 %Grab the current string in the messagebox.
                    if isempty(messages)                                    %If there's no messages yet in the messagebox...
                        messages = {};                                      %Create an empty cell array to hold messages.
                    elseif ~iscell(messages)                                %If the string property isn't yet a cell array...
                        messages = {messages};                              %Convert the messages to a cell array.
                    end
                    messages{end+1} = new_msg;                              %Add the new message to the listbox.
                    set(msgbox(gui_i),'string',messages);                   %Update the strings in the listbox.
                    set(msgbox(gui_i),'value',length(messages),...
                        'ListboxTop',length(messages));                     %Set the value of the listbox to the newest messages.
                    set(msgbox(gui_i),'min',0,...
                        'max',2',...
                        'selectionhighlight','off',...
                        'value',[]);                                        %Set the properties on the listbox to make it look like a simple messagebox.
                    drawnow;                                                %Update the GUI.
                    
            end
            
        case 'uitextarea'                                                   %If the messagebox is a uitextarea...
            messages = msgbox(gui_i).Value;                                 %Grab the current strings in the messagebox.
            if ~iscell(messages)                                            %If the string property isn't yet a cell array...
                messages = {messages};                                      %Convert the messages to a cell array.
            end
            checker = 1;                                                    %Create a matrix to check for non-empty cells.
            for i = 1:numel(messages)                                       %Step through each message.
                if ~isempty(messages{i})                                    %If there any non-empty messages...
                    checker = 0;                                            %Set checker equal to zero.
                end
            end
            if checker == 1                                                 %If all messages were empty.
                messages = {};                                              %Set the messages to an empty cell array.
            end
            messages{end+1} = new_msg;                                      %Add the new message to the listbox.
            msgbox(gui_i).Value = messages;                                 %Update the strings in the Text Area.        
            drawnow;                                                        %Update the GUI.
            scroll(msgbox(gui_i),'bottom');                                 %Scroll to the bottom of the Text Area.
    end

end
        