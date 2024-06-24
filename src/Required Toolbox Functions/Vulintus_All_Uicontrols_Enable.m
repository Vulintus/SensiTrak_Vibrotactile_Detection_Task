function Vulintus_All_Uicontrols_Enable(fig,on_off)

%
%Vulintus_All_Uicontrols_Enable.m - Vulintus, Inc.
%
%   VULINTUS_ALL_UICONTROLS_ENABLE is a Vulintus toolbox function which 
%   enables or disables all of the user interface objects on the figure 
%   specified by the handle "fig". The input variable "on_off" must be set
%   to either "on" or "off"
%   
%   UPDATE LOG:
%   11/30/2021 - Drew Sloan - Function converted to a Vulintus behavior 
%       toolbox function, adapted from
%       Vibrotactile_Detection_Task_Enable_All_Uicontrols.m.
%


if ~all(ishandle(fig))                                                      %If the "fig" input variable isn't an object handle...
    error(['ERROR IN VULINTUS_ALL_UICONTROLS_ENABLE: first input '...
        'argument must be a graphics object handle!']);                     %Throw an error.
elseif ~any(strcmpi(on_off,{'on','off'}))                                   %If the "on_off" input variable isn't set to either "on" or "off"...
    error(['ERROR IN VULINTUS_ALL_UICONTROLS_ENABLE: second input '...
        'argument must be either "on" or "off" (case insensitive)!']);      %Throw an error.
end

for i = 1:length(fig)                                                       %Step through all of the figures.
    objs = findobj(fig);                                                    %Grab all fo the graphics objects on the figure.
    i = strcmpi(get(objs,'type'),'uitable') | ...
        strcmpi(get(objs,'type'),'uibutton') | ...
        strcmpi(get(objs,'type'),'uidropdown') | ...
        strcmpi(get(objs,'type'),'uieditfield') | ...
        strcmpi(get(objs,'type'),'uimenu') | ...
        strcmpi(get(objs,'type'),'uicontrol');                              %Find any text area, table, button, drop-down, or edit box components.
    set(objs(i),'enable',on_off);                                           %Enable all text area components.
end