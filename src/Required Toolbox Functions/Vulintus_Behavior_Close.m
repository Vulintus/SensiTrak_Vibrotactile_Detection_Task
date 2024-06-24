function Vulintus_Behavior_Close(fig)

%
%Vulintus_Behavior_Close.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_CLOSE executes after the main behavioral loop
%   terminates, usually because the user closes the figure window.
%   
%   UPDATE LOG:
%   2021-11-30 - Drew Sloan - Function converted to a Vulintus behavior
%                             toolbox function, adapted from 
%                             Tactile_Discrimination_Task_Close.m.
%   2024-05-07 - Drew Sloan - Updated to include stream disable, clear, and
%                             close calls for the new version of 
%                             Connect_OmniTrak.
%

handles = fig.UserData;                                                     %Grab the handles structure from the main GUI.

for f = {'ardy','moto','ctrl','otth'}                                       %Step through each commonly-used controller handle name.
    if isfield(handles,f{1})                                                %If the handles structure has a matching field...    
        if isfield(handles.(f{1}),'stream_enable')                          %If there's a stream enable function...
            handles.(f{1}).stream_enable(0);                                %Call the function to double-check that streaming is disabled.
        end
        if isfield(handles.(f{1}),'stream') && ...
                isfield(handles.(f{1}).stream,'enable')                     %If there's an stream subfield with an enable function...
            handles.(f{1}).stream.enable(0);                                %Call the function to double-check that streaming is disabled.
        end
        if isfield(handles.(f{1}),'clear')                                  %If there's a clear serial line function...
            handles.(f{1}).clear();                                         %Call the function to clear any leftover stream output.
        end
        if isfield(handles,'otsc') && isfield(handles.otsc,'clear')         %If there's an OTSC subfield with a clear serial line function...
            handles.(f{1}).otsc.clear();                                    %Call the function to clear any leftover stream output.
        end
        if isfield(handles.(f{1}),'close')                                  %If there's a close serial object function...
            handles.(f{1}).close();                                         %Call the function to close and delete the serial line object.
        end
        if isfield(handles,'otsc') && isfield(handles.otsc,'close')         %If there's an OTSC subfield with a close serial object function...
            handles.(f{1}).otsc.close();                                    %Call the function to close and delete the serial line object.
        end
    end
end

if isfield(handles,'mainfig')                                               %If the handles structure has a "mainfig" field...
    delete(handles.mainfig);                                                %Delete the main figure(s).
else                                                                        %Otherwise...
    delete(fig);                                                            %Delete the passed figure.
end

fprintf(1,'"Vulintus_Behavior_Close" Completed\n');                                                             