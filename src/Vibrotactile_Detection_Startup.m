function Vibrotactile_Detection_Startup(varargin)

%
% Vibrotactile_Detection_Startup.m - Vulintus, Inc.
%
%   copyright 2024, Vulintus, Inc.
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
    behavior = varargin{1};                                                 %Assume the behavior class is the first input.
else                                                                        %Otherwise...
    behavior = Vulintus_Behavior_Class('Vibrotactile Detection');           %Create a Vulintus Behavior class instance.
end
Vulintus_Behavior_Startup(behavior);                                        %Call the common behavior startup functions.