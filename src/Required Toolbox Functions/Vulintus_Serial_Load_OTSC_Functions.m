function [ctrl, varargout] = Vulintus_Serial_Load_OTSC_Functions(ctrl, varargin)

%Vulintus_Serial_Load_OTSC_Functions.m - Vulintus, Inc., 2024
%
%   VULINTUS_SERIAL_LOAD_OTSC_FUNCTIONS adds OmniTrak Serial Communication 
%   (OTSC) functions to the control structure for Vulintus devices using
%   the OTSC protocol.
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2024-06-06 - Drew Sloan - Function first created.
%

varargout{1} = {};                                                          %Assume we will return zero device SKUs.

if nargin > 1                                                               %If the user passed the OTSC codes...
    otsc_codes = varargin{1};                                               %Grab the OTSC codes from the variable input arguments.
else                                                                        %Otherwise...
    otsc_codes = Vulintus_Load_OTSC_Codes;                                  %Load the OmniTrak Serial Communication (OTSC) codes.
end

device_list = Vulintus_Load_OTSC_Device_IDs;                                %Load the OTSC device list.
[device_id, code] = ctrl.device.id();                                       %Grab the OTSC device id.
if code ~= otsc_codes.DEVICE_ID || ...
        ~any(device_id == [device_list.id])                                 %If the return code was wrong or the device ID isn't recognized...
    ctrl.device.sku = [];                                                   %Set the device name to empty brackets in the structure.
else                                                                        %Otherwise, if the device was recognized...
    ctrl.device.sku = device_list(device_id == [device_list.id]).sku;       %Save the device SKU (4-character product code) to the structure.
    ctrl.device.name = device_list(device_id == [device_list.id]).name;     %Save the full device name to the structure.
end

devices = {ctrl.device.sku};                                                %Put the primary device SKU into a cell array.
ctrl = Vulintus_OTSC_OTMP_Monitoring_Functions(ctrl, otsc_codes, devices);  %OTMP-monitoring functions.
if isfield(ctrl,'otmp')                                                     %If this device has downstream-facing module ports...    
    active_ports = ctrl.otmp.active();                                      %Check which ports are active.    
    for i = 1:length(active_ports)                                          %Step through all of the ports.
        if active_ports(i)                                                  %If there's a device on this port.
            [device_id, code] = ctrl.device.id('passthrough',i);            %Grab the OTSC device id.            
            if isempty(device_id)                                           %If no code was returned.
                cprintf([1,0.5,0],['OmniTrak Module Port #%1.0f is '...
                    'drawing power, but not responding to OTSC '...
                    'communication!\n'],i);                                 %Indicate the port is not responding.
                ctrl.otmp.port(i).connected = -1;                           %Label the port as non-responding.
                ctrl.otmp.port(i).sku = [];                                 %Set the SKU field to empty.
            elseif code ~= otsc_codes.DEVICE_ID || ...
                    ~any(device_id == [device_list.id])                     %If the return code was wrong or the device ID isn't recognized...
                ctrl.otmp.port(i).sku = [];                                 %Set the device name to empty brackets in the structure.
            else                                                            %Otherwise, if the device was recognized...
                ctrl.otmp.port(i).sku = ...
                    device_list(device_id == [device_list.id]).sku;         %Save the device SKU (4-character product code) to the structure.
                ctrl.otmp.port(i).name = ...
                    device_list(device_id == [device_list.id]).name;        %Save the full device name to the structure.
            end
            ctrl.otmp.port(i).connected = 1;                                %Label the port as connected.
        else                                                                %Otherwise, if there's not device on this port.
            ctrl.otmp.port(i).connected = 0;                                %Label the port as disconnected
            ctrl.otmp.port(i).sku = [];                                     %Set the SKU field to empty.
        end
    end
    devices = horzcat(devices,{ctrl.otmp.port.sku});                        %Add the connected devices to the device SKU list.
    devices(cellfun(@isempty,devices)) = [];                                %Kick out the empty cells.
end

%Device-specific OTSC functions.
ctrl = Vulintus_OTSC_Cage_Light_Functions(ctrl, otsc_codes, devices);       %Overhead cage light functions.
ctrl = Vulintus_OTSC_Cue_Light_Functions(ctrl, otsc_codes, devices);        %Cue light functions.
ctrl = Vulintus_OTSC_Dispenser_Functions(ctrl, otsc_codes, devices);        %Pellet/liquid dispenser control functions.
ctrl = Vulintus_OTSC_Lick_Sensor_Functions(ctrl, otsc_codes, devices);      %Lick sensor functions.
ctrl = Vulintus_OTSC_Linear_Motion_Functions(ctrl, otsc_codes, devices);    %Module linear motion functions.
ctrl = Vulintus_OTSC_Memory_Functions(ctrl, otsc_codes, devices);           %Nonvolatile memory access functions.
ctrl = Vulintus_OTSC_Motor_Setup_Functions(ctrl, otsc_codes, devices);      %Motor setup functions.
ctrl = Vulintus_OTSC_IR_Detector_Functions(ctrl, otsc_codes, devices);      %IR detector functions.
ctrl = Vulintus_OTSC_Thermal_Image_Functions(ctrl, otsc_codes, devices);    %Thermal imaging functions.
ctrl = Vulintus_OTSC_Tone_Functions(ctrl, otsc_codes, devices);             %Tone-playing functions.  
ctrl = Vulintus_OTSC_WiFi_Functions(ctrl, otsc_codes, devices);             %WiFi functions.   

% ctrl = Vulintus_OTSC_STAP_Functions(ctrl, otsc_codes, devices);             %STAP-specific functions.
% ctrl = Vulintus_OTSC_STTC_Functions(ctrl, otsc_codes, devices);             %STTC-specific functions.

varargout{1} = devices;                                                     %Return a list of the connected devices.