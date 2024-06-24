function Vulintus_Behavior_Terminal_Error(err,handles)

%
%Vulintus_Behavior_Terminal_Error.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_TERMINAL_ERROR goes through all the housekeeping of
%   shutting down a Vulintus behavior program following a terminal error.
%   It generates an error report based on the "err" error message details
%   passed to it, displays error messages, and closes the program and main
%   GUI.
%   
%   UPDATE LOG:
%   2022-03-09 - Drew Sloan - Function first implemented, forked from
%                             ST_Proprioception_2AFC_Startup.m.
%   2024-03-25 - Drew Sloan - Changed "task_title" field to "task".
%

Vulintus_Show_Error_Report(handles.task,err);                               %Pop up a window showing the error.
if isfield(handles,'mainfig') && ~isempty(handles.mainfig)                  %If the original figure was closed (i.e. during calibration)...
    handles = handles.mainfig.UserData;                                     %Grab the most recent handles structure from the main GUI.     
end        
err_path = [handles.mainpath 'Error Reports\'];                             %Create the expected directory name for the error reports.
txt = Vulintus_Behavior_Save_Error_Report(err_path,handles.task,...
    err,handles);                                                           %Save a copy of the error in the AppData folder.      
% if handles.enable_error_reporting ~= 0                                      %If remote error reporting is enabled...
%     Vulintus_Behavior_Send_Error_Report(handles,...
%         handles.err_rcpt,txt);                                              %Send an error report to the specified recipient.     
% end
Vulintus_Behavior_Close(handles.mainfig);                                   %Call the function to close the vibration task program.
% errordlg(sprintf(['An fatal error occurred in the vibration '...
%     'task program. An message containing the error information '...
%     'has been sent to "%s", and a Vulintus engineer will '...
%     'contact you shortly.'], handles.err_rcpt),...
%     sprintf('Fatal Error in %s',handles.task_title));                       %Display an error dialog.