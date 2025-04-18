function ctrl = Vulintus_OTSC_Motor_Setup_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_Motor_Setup_Functions.m - Vulintus, Inc., 2024
%
%   VULINTUS_OTSC_MOTOR_SETUP_FUNCTIONS defines and adds OmniTrak Serial
%   Communication (OTSC) functions to the control structure for Vulintus
%   OmniTrak devices which have motors with configurable control parameters
%   i.e. coil current, microstepping, etc.
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2024-06-04 - Drew Sloan - Function first created.
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%


%List the Vulintus devices that use these functions.
device_list = { 'MT-PP',...
                'OT-PD',...
                'ST-TC',...
                'ST-AP'};

%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'motor')                                            %If there's a "motor" field in the control structure...
            ctrl = rmfield(ctrl,'motor');                                   %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.

%Motor setup functions.
ctrl.motor = [];                                                            %Create a field to hold motor setup functions.

%Request/set the current motor current setting, in milliamps.
ctrl.motor.current.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_MOTOR_CURRENT,...
    'reply',{1,'uint16'},...
    varargin{:});                                                           
ctrl.motor.current.set = ...
    @(current_in_mA,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.MOTOR_CURRENT,...
    'data',{current_in_mA,'uint16'},...
    varargin{:});

%Request/set the maximum possible motor current setting, in milliamps.
ctrl.motor.current_max.get = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_MAX_MOTOR_CURRENT,...
    'reply',{1,'uint16'},...
    varargin{:});                                                           
ctrl.motor.current_max.set = ...
    @(current_in_mA,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.MAX_MOTOR_CURRENT,...
    'data',{current_in_mA,'uint16'},...
    varargin{:});