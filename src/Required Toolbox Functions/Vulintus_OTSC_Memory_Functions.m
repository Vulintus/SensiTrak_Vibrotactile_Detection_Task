function ctrl = Vulintus_OTSC_Memory_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_Memory_Functions.m - Vulintus, Inc., 2022
%
%   VULINTUS_OTSC_MEMORY_FUNCTIONS defines and adds OmniTrak Serial
%   Communication (OTSC) functions to the control structure for Vulintus
%   OmniTrak devices which have non-volatile memory.
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2023-10-02 - Drew Sloan - Function first created, split off from
%                             "Vulintus_OTSC_Common_Functions.m".
%   2023-12-07 - Drew Sloan - Updated calls to "Vulintus_Serial_Request" to
%                             allow multi-type responses.
%   2023-01-30 - Drew Sloan - Renamed function from
%                             "Vulintus_OTSC_EEPROM_Functions.m" to
%                             "Vulintus_OTSC_Memory_Functions.m".
%   2024-02-22 - Drew Sloan - Organized functions by scope into subfields.
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%


%List the Vulintus devices that use these functions.
device_list = { 'OT-3P',...
                'OT-CC'};

%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'nvm')                                              %If there's a "nvm" field in the control structure...
            ctrl = rmfield(ctrl,'nvm');                                     %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.

%Non-volatile memory functions.
ctrl.nvm = [];                                                              %Create a field to hold non-volatile memory functions.

%Request the device's non-volatile memory size.
ctrl.nvm.get_size = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.REQ_NVM_SIZE,...
    'reply',{1,'uint32'},...
    varargin{:});             

%Read/write bytes to non-volatile memory.
ctrl.nvm.read = ...
    @(addr,N,type)Vulintus_Serial_EEPROM_Read(serialcon,...
    otsc_codes.WRITE_TO_NVM,addr,N,type);
ctrl.nvm.write = ...
    @(addr,data,type)Vulintus_Serial_EEPROM_Write(serialcon,...
    otsc_codes.WRITE_TO_NVM,addr,data,type);                                
