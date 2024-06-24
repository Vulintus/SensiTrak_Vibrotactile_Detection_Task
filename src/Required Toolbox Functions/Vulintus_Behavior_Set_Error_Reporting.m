function Vulintus_Behavior_Set_Error_Reporting(hObject,~)

%
%Vulintus_Behavior_Set_Error_Reporting.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_SET_ERROR_REPORTING is a Vulintus behavior program
%   toolbox function that is called whenever the user selects "On" or "Off"
%   for the Automatic Error Reporting feature under the GUI Preferences 
%   menu. Use of this function requires program parameters to be tied to
%   the calling figure with the "guidata" function, and requires that the
%   figure contain uimenu controls with the following names:
%
%       handles.menu.pref.err_report_on
%       handles.menu.pref.err_report_off
%   
%   UPDATE LOG:
%   11/29/2019 - Drew Sloan - First function implementation, adapted from
%       Vibrotactile_Detection_Task_Set_Error_Reporting.m.
%

handles = guidata(gcbf);                                                    %Grab the handles structure from the main figure.
str = get(hObject,'label');                                                 %Grab the string property from the selected menu option.
if strcmpi(str,'on')                                                        %If the user selected to turn error reporting on...
    handles.enable_error_reporting = 1;                                     %Enable error-reporting.
    set(handles.menu.pref.err_report_on,'checked','on');                    %Check the "On" option.
    set(handles.menu.pref.err_report_off,'checked','off');                  %Uncheck the "Off" option.
else                                                                        %Otherwise, if the user selected to turn error reporting off...
    handles.enable_error_reporting = 0;                                     %Disable error-reporting.
    set(handles.menu.pref.err_report_on,'checked','off');                   %Uncheck the "On" option.
    set(handles.menu.pref.err_report_off,'checked','on');                   %Check the "Off" option.
end
guidata(gcbf,handles);                                                      %Pin the handles structure back to the main figure.

