function Vulintus_Behavior_Open_Error_Reports(~,~,mainpath)

%
%Vibration_Task_Open_Error_Reports.m - Vulintus, Inc.
%
%   Vibration_Task_Open_Error_Reports is called whenever the user selects
%   "View Error Reports" from the vibration task GUI Preferences menu and
%   opens the local AppData folder containing all archived error reports.
%
%   UPDATE LOG:
%   11/29/2019 - Drew Sloan - Converted to a Vulintus behavior toolbox
%       function, adapted from Vibration_Task_Open_Error_Reports.m.
%

err_path = fullfile(mainpath, 'Error Reports');                             %Create the expected directory name for the error reports.
if ~exist(err_path,'dir')                                                   %If the error report directory doesn't exist...
    mkdir(err_path);                                                        %Create the error report directory.
end
system(['explorer ' err_path]);                                             %Open the error report directory in Windows Explorer.