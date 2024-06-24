function Vibrotactile_Detection_Startup(varargin)

%
%Vibrotactile_Detection_Startup.m - Vulintus, Inc.
%
%   VIBROTACTILE_DETECTION_STARTUP starts the SensiTrak vibrotactile
%   detection task program. It loads in default parameters, creates the 
%   GUI, and creates the connection to the OmniTrak controller on a 
%   SensiTrak system.
%   
%   UPDATE LOG:
%   2024-06-24 - Drew Sloan - Function first created.
%                            


%% Use the Vulintus Common Behavior startup function.
if nargin                                                                   %If there were any input arguments.
    handles = varargin{1};                                                  %Assume the handles structure is the first input.
else                                                                        %Otherwise...
    handles = struct('task','Vibrotactile Detection');                      %Create a handles structure.
end
Vulintus_Behavior_Startup(handles);                                         %Call the common behavior startup functions.