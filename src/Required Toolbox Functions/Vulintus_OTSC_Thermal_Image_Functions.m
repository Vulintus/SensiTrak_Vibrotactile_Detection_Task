function ctrl = Vulintus_OTSC_Thermal_Image_Functions(ctrl, otsc_codes, varargin)

%Vulintus_OTSC_Thermal_Image_Functions.m - Vulintus, Inc., 2024
%
%   VULINTUS_OTSC_THERMAL_IMAGE_FUNCTIONS defines and adds OmniTrak Serial
%   Communication (OTSC) functions to the control structure for Vulintus
%   OmniTrak devices which have thermal imaging sensors.
% 
%   NOTE: These functions are designed to be used with the "serialport" 
%   object introduced in MATLAB R2019b and will not work with the older 
%   "serial" object communication.
%
%   UPDATE LOG:
%   2023-10-02 - Drew Sloan - Function first created.
%   2024-06-07 - Drew Sloan - Added a optional "devices" input argument to
%                             selectively add the functions to the control 
%                             structure.
%


%List the Vulintus devices that use these functions.
device_list = {'HT-TH'};

%If an cell arracy of connected devices was provided, match against the device lis.
if nargin > 2
    connected_devices = varargin{1};                                        %Grab the list of connected devices.
    [~,i,~] = intersect(connected_devices,device_list);                     %Look for any matches between the two device lists.
    if ~any(i)                                                              %If no match was found...
        if isfield(ctrl,'therm_im')                                         %If there's a "therm_im" field in the control structure...
            ctrl = rmfield(ctrl,'therm_im');                                %Remove it.
        end
        return                                                              %Skip execution of the rest of the function.
    end
end

serialcon = ctrl.serialcon;                                                 %Grab the handle for the serial connection.

%Thermal imaging functions.
ctrl.therm_im = [];                                                         %Create a field to hold thermal imaging functions.

%Request the current thermal hotspot x-y position, in units of pixels.
ctrl.therm_im.hot_pix = @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_THERM_XY_PIX,...
    'reply',{1, 'uint32'; 3,'uint8'; 1,'single'},...
    varargin{:});                                                           

%Request a thermal pixel image as 16-bit unsigned integers in units of deciKelvin (dK, or Kelvin * 10).
ctrl.therm_im.pixels_dk = @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_THERM_PIXELS_INT_K,...
    'reply',{1, 'uint32', 3,'uint8'; 1024,'uint16'},...
    varargin{:});                                               

%Request a thermal pixel image as a fixed-point 6/2 type (6 bits for the unsigned integer part, 2 bits for the decimal part), in units of Celcius.
ctrl.therm_im.pixels_fp62 = ...
    @(varargin)Vulintus_OTSC_Transaction(serialcon,...
	otsc_codes.REQ_THERM_PIXELS_FP62,...
    'reply',{1, 'uint32'; 1027,'uint8'},...
    varargin{:});                                               