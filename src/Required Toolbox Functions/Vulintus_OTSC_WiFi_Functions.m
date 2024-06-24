function ctrl = Vulintus_OTSC_WiFi_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_WiFi_Functions.m - Vulintus, Inc., 2024
%
%   VULINTUS_OTSC_WIFI_FUNCTIONS defines and adds OmniTrak Serial
%   Communication (OTSC) functions to the control structure for Vulintus
%   OmniTrak devices with integrated WiFi modules.
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2024-01-30 - Drew Sloan - Function first created, split off from
%                             "Vulintus_OTSC_Common_Functions.m".
%   2024-02-22 - Drew Sloan - Organized functions by scope into subfields.
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%


%List the Vulintus devices that use these functions.
device_list = { 'HT-TH',...
                'OT-CC'};

%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'wifi')                                             %If there's a "wifi" field in the control structure...
            ctrl = rmfield(ctrl,'wifi');                                    %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.

%Controller status functions.
ctrl.wifi = [];                                                             %Create a field to hold WiFi functions.

%Request the device's MAC address.
ctrl.wifi.mac_addr = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_MAC_ADDR,...
    'reply',{1,'uint8'},...
    varargin{:});                    