function Append_Msg(msgbox,new_txt)

%
%APPEND_MSG.m - Vulintus, Inc., 2023
%
%   APPEND_MSG displays messages in a listbox on a GUI, adding the 
%   specified text to the message at the bottom of the list.
%
%   Append_Msg(msgbox,new_txt) adds the text passed in the variable
%   "new_txt" to the last entry in the listbox or text area whose handle is
%   specified by the variable "msgbox".
%
%   UPDATE LOG:
%   2023-09-27 - Drew Sloan - Function first created, adapted from
%                             "Replace_Msg.m".
%

switch get(msgbox,'type')                                                   %Switch between the recognized components.
    
    case 'uicontrol'                                                        %If the messagebox is a listbox...
        switch get(msgbox,'style')                                          %Switch between the recognized uicontrol styles.
            
            case 'listbox'                                                  %If the messagebox is a listbox...
                messages = get(msgbox,'string');                            %Grab the current string in the messagebox.
                if isempty(messages)                                        %If there's no messages yet in the messagebox...
                    messages = {};                                          %Create an empty cell array to hold messages.
                elseif ~iscell(messages)                                    %If the string property isn't yet a cell array...
                    messages = {messages};                                  %Convert the messages to a cell array.
                end
                if iscell(new_txt)                                          %If the new message is a cell array...
                    new_txt = new_txt{1};                                   %Convert the first cell of the new message to characters.
                end
                messages{end} = horzcat(messages{end},new_txt);             %Add the new text to the end of the last message.
                set(msgbox,'string',messages);                              %Updat the list items.
                set(msgbox,'value',length(messages));                       %Set the value of the listbox to the newest messages.
                drawnow;                                                    %Update the GUI.
                a = get(msgbox,'listboxtop');                               %Grab the top-most value of the listbox.
                set(msgbox,'min',0,...
                    'max',2',...
                    'selectionhighlight','off',...
                    'value',[],...
                    'listboxtop',a);                                        %Set the properties on the listbox to make it look like a simple messagebox.
                drawnow;                                                    %Update the GUI.
                
        end
        
    case 'uitextarea'                                                       %If the messagebox is a uitextarea...
        messages = msgbox.Value;                                            %Grab the current strings in the messagebox.
        if ~iscell(messages)                                                %If the string property isn't yet a cell array...
            messages = {messages};                                          %Convert the messages to a cell array.
        end
        checker = 1;                                                        %Create a matrix to check for non-empty cells.
        for i = 1:numel(messages)                                           %Step through each message.
            if ~isempty(messages{i})                                        %If there any non-empty messages...
                checker = 0;                                                %Set checker equal to zero.
            end
        end
        if checker == 1                                                     %If all messages were empty.
            messages = {};                                                  %Set the messages to an empty cell array.
        end
        if iscell(new_txt)                                                  %If the new message is a cell array...
            new_txt = new_txt{1};                                           %Convert the first cell of the new message to characters.
        end
        messages{end} = horzcat(messages{end},new_txt);                     %Add the new text to the end of the last message.
        msgbox.Value = messages';                                           %Update the strings in the Text Area.
        scroll(msgbox,'bottom');                                            %Scroll to the bottom of the Text Area.
        drawnow;                                                            %Update the GUI.
        
end
