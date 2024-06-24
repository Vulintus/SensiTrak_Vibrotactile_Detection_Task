function ctrl = Vulintus_OTSC_OTMP_Monitoring_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_OTMP_Monitoring_Functions.m - Vulintus, Inc., 2024
%
%   VULINTUS_OTSC_OTMP_MONITORING_FUNCTIONS defines and adds OmniTrak 
%   Serial Communication (OTSC) functions to the control structure for 
%   Vulintus OmniTrak devices which have downstream-facing OmniTrak Module 
%   Port (OTMP) connections. As of June 2024, this only applies to the
%   OmniTrak Common Controller (OT-CC).
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2024-06-06 - Drew Sloan - Function first created.
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%


%List the Vulintus devices that use these functions.
device_list = {'OT-CC'};

%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'otmp')                                             %If there's a "otmp" field in the control structure...
            ctrl = rmfield(ctrl,'otmp');                                    %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.

%OmniTrak Module Port (OTMP) monitoring functions.
ctrl.otmp = [];

%Request the OmniTrak Module Port (OTMP) output current for the specified port.
ctrl.otmp.iout = ...
    @(otmp_index, varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_OTMP_IOUT,...
    'data',{otmp_index,'uint8'},...
    'reply',{1,'uint8'; 1,'single'},...
    varargin{:});                                                           

%Request a bitmask indicating which OmniTrak Module Ports (OTMPs) are active based on current draw.
ctrl.otmp.active = ...
    @(varargin)Vulintus_OTSC_OTMP_Monitoring_Active_Ports(serialcon,...
	otsc_codes.REQ_OTMP_ACTIVE_PORTS,...
    varargin{:});    

%Request/set the specified OmniTrak Module Port (OTMP) high voltage supply setting (0 = off <default>, 1 = high voltage
ctrl.otmp.high_volt.get = ...
    @(otmp_index, varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_OTMP_HIGH_VOLT,...
    'data',{otmp_index,'uint8'},...
    'reply',{2,'uint8'},...
    varargin{:});
ctrl.otmp.high_volt.set = ...
    @(thresh,varargin)Vulintus_OTSC_Transaction(serialcon,...
    otsc_codes.POKE_THRESH_FL,...
    'data',{thresh,'single'},...
    varargin{:});

%Request a bitmask indicating which OmniTrak Module Ports (OTMPs) are in overcurrent shutdown.
ctrl.otmp.overcurrent = ...
    @(otmp_index, varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_OTMP_OVERCURRENT,...
    'reply',{1,'uint8'},...
    varargin{:});


%Request the OmniTrak Module Port (OTMP) output current for the specified port.
function active_ports = Vulintus_OTSC_OTMP_Monitoring_Active_Ports(serialcon,code,varargin)
otmp_bitmask = Vulintus_OTSC_Transaction(serialcon,...
    code,...
    'reply',{2,'uint8'},...
    varargin{:});
active_ports = bitget(otmp_bitmask(2),1:otmp_bitmask(1));