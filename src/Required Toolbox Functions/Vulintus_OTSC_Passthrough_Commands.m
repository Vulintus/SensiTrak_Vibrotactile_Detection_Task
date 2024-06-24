function [pass_down_cmd, pass_up_cmd] = Vulintus_OTSC_Passthrough_Commands

%	Vulintus_OTSC_Passthrough_Commands.m
%
%	Vulintus, Inc.
%
%	OmniTrak Serial Communication (OTSC) library.
%	Simplified function for loading just the passthrough block codes.
%
%	Library documentation:
%	https://github.com/Vulintus/OmniTrak_Serial_Communication
%
%	This function was programmatically generated: 2024-06-11, 03:37:20 (UTC)
%

pass_down_cmd = 48350;		%Route the immediately following block downstream to the specified port or VPB device.
pass_up_cmd = 48351;		%Route the immediately following block upstream, typically to the controller or computer.
