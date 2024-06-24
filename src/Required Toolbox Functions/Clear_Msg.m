function Clear_Msg(varargin)

%
%Clear_Msg.m - Vulintus, Inc.
%
%   CLEAR_MSG deleles all messages in a listbox on a GUI.
%
%   CLEAR_MSG(msgbox) or CLEAR_MSG(~,~,msgbox) clears all messages out of
%   the ListBox / uitextarea whose handle is specified in the variable 
%   "msgbox".
%
%   UPDATE LOG:
%   2013-01-24 - Drew Sloan - Function first created.
%   2021-11-26 - Drew Sloan - Added functionality to use scrolling text
%                             areas (uitextarea) as messageboxes.
%   2024-06-11 - Drew Sloan - Added a for loop to handle arrays of
%                             messageboxes.
%

if nargin == 1                                                              %If there's only one input argument...
    msgbox = varargin{1};                                                   %The listbox handle is the first input argument.
elseif nargin == 3                                                          %Otherwise, if there's three input arguments...
    msgbox = varargin{3};                                                   %The listbox handle is the third input argument.
end

for i = 1:length(msgbox)                                                    %Step through each messagebox.

    if strcmpi(get(msgbox(1),'type'),'uicontrol')                           %If the messagebox is a uicontrol...
        msgbox_type = get(msgbox(1),'style');                               %Grab the style property.
    else                                                                    %Otherwise...
        msgbox_type = get(msgbox(1),'type');                                %Grab the type property.
    end
    
    switch msgbox_type                                                      %Switch between the recognized components.
        
        case 'listbox'                                                      %If the messagebox is a listbox...
            set(msgbox(1),'string',{},...
                'min',0,...
                'max',0',...
                'selectionhighlight','off',...
                'value',[]);                                                %Clear the messages and set the properties on the listbox to make it look like a simple messagebox.
            
        case 'uitextarea'                                                   %If the messagebox is a uitextarea...
            messages = {''};                                                %Create a cell array with one empty entry.
            msgbox(1).Value = messages;                                     %Update the strings in the Text Area.
            scroll(msgbox(1),'bottom');                                     %Scroll to the bottom of the Text Area.
            drawnow;                                                        %Update the GUI.
            
    end

end 