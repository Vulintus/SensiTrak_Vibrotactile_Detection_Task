function Vulintus_Open_Directory(~,~,datapath)

%
%Vulintus_Open_Directory.m - Vulintus, Inc.
%
%   VULINTUS_OPEN_DIRECTORY will open the directory specified by "datapath" 
%   in a separate Windows Explorer window.
%
%   UPDATE LOG:
%   11/29/2021 - Drew Sloan - Function converted to a Vulintus toolbox
%       function, adapted from LED_Detection_Task_Open_Data_Directory.m.
%

system(['explorer ' datapath]);                                             %Open the specified directory in Windows Explorer.