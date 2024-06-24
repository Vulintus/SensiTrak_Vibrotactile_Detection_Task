function usb_pid_list = Vulintus_USB_VID_PID_List

%Vulintus_USB_VID_PID_List.m - Vulintus, Inc.
%
%   VULINTUS_USB_VID_PID_LIST returns a cell array with USB vendor ID (VID) 
%   and product ID (PID) numbers assigned to Vulintus devices
%
%   UPDATE LOG:
%   2024-02-22 - Drew Sloan - Function first created.
%

usb_pid_list = {
    '04D8',     'E6C2',     'HabiTrak Thermal Activity Monitor';
    '0403',     '6A21',     'MotoTrak Pellet Pedestal Module';	
    '04D8',     'E6C3',     'OmniTrak Common Controller';
    '0403',     '6A20',     'OmniTrak Nosepoke Module';
    '0403',     '6A24',     'OmniTrak Three-Nosepoke Module';
	'0403',     '6A23',     'SensiTrak Arm Proprioception Module';
	'0403',     '6A22',     'SensiTrak Tactile Carousel Module';
	'0403',     '6A25',     'SensiTrak Vibrotactile Module';
	'04D8',     'E6AC',     'VPB Linear Autopositioner';
	'04D8',     'E62E',     'VPB Liquid Dispenser';
	'04D8',     'E6C0',     'VPB Ring Light';
};