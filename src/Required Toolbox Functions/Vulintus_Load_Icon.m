function [img, varargout] = Vulintus_Load_Icon(varargin)

%
%Vulintus_Load_Icon.m - Vulintus, Inc.
%
%   VULINTUS_LOAD_ICON loads the Vulintus icon for the specified system
%   name at the specified pixel resolution. If no pixel resolution is
%   specified, it returns a 48x48 pixels icon. If a figure handle is also
%   specified, it will match transparent pixels of the icon to the figure
%   title bar color.
%   
%   UPDATE LOG:
%   2024-06-11 - Drew Sloan - Function first created.
%


system_name = 'vulintus';                                                   %Assume that the general Vulintus icon is requested.
num_pix = 48;                                                               %Assume a 48x48 pixel icon is requested.
fig = [];                                                                   %Assume no figure handle is specified.

for i = 1:nargin                                                            %Step through all of the variable input arguments.
    switch class(varargin{i})                                               %Switch between the different classes of input.
        case 'matlab.ui.Figure'                                             %Figure handle.
            fig = varargin{i};                                              %Set the figure handle.
        case 'char'                                                         %Character array.
            system_name = varargin{i};                                      %Set the system name.
        case 'double'                                                       %Number.
            num_pix = varagin{i};                                           %Set the pixel resolution.
        otherwise                                                           %Otherwise...
            error('ERROR IN %s: Unrecognized input type ''%s''.',...
                upper(mfilename),class(varargin{i}));                       %Show an error.
    end
end

switch (num_pix)                                                            %Switch between the requested pixel resolutions.
    otherwise                                                               %For all other resolutions.
        switch lower(system_name)                                           %Switch between the recognized system names.
            case 'habitrak'                                                 %HabiTrak.
                [img, alpha_map] = Vulintus_Load_HabiTrak_V1_Icon_48px;     %Use the HabiTrak icon.
            case 'mototrak'                                                 %MotoTrak.
                [img, alpha_map] = Vulintus_Load_MotoTrak_V2_Icon_48px;     %Use the MotoTrak V2 icon.
            case 'omnihome'                                                 %OmniHome.
                [img, alpha_map] = Vulintus_Load_OmniHome_V1_Icon_48px;     %Use the OmniHome icon.
            case 'omnitrak'                                                 %OmniTrak.
                [img, alpha_map] = Vulintus_Load_OmniTrak_V1_Icon_48px;     %Use the OmniTrak icon.    
            case 'sensitrak'                                                %SensiTrak.
                [img, alpha_map] = Vulintus_Load_SensiTrak_V1_Icon_48px;    %Use the SensiTrak icon.
            case 'vulintus'                                                 %General Vulintus icon.
                [img, alpha_map] = ...
                    Vulintus_Load_Vulintus_Logo_Circle_Social_48px;         %Use the Vulintus Social Logo.
            otherwise                                                       %For all other system names.
                error('ERROR IN %s: No matching system name for "%s".',...
                    upper(mfilename),system_name);                          %Show an error.
        end
end
if ishandle(fig)                                                            %If a figure handle was provided...
    img = Vulintus_Behavior_Match_Icon(img, alpha_map, fig);                %Match the icon background to the figure.
end
varargout{1} = alpha_map;                                                   %Return the alpha map, if requested.