function toolbox_exists = Vulintus_Check_MATLAB_Toolboxes(toolbox, varargin)

%
%Vulintus_Check_MATLAB_Toolboxes.m - Vulintus, Inc.
%
%   This script checks the MATLAB installation for the specified required
%   toolbox and throws an error if it isn't found.
%   
%   UPDATE LOG:
%   2024-01-24 - Drew Sloan - Function first created.
%


if ~isdeployed                                                              %If the function is running as a script instead of deployed code...
    matproducts = ver;                                                      %Grab all of the installed MATLAB products.
    toolbox_exists = any(strcmpi({matproducts.Name},toolbox));              %Check to see if the toolbox is installed.
    if ~toolbox_exists                                                      %If the specified toolbox isn't installed...
        fcn = dbstack;                                                      %Grab the function call stack that led to this line.       
        str = sprintf(['"%s.m" requires the MATLAB %s, which is not '...
            'installed on your computer. You will need to install the '...
            'toolbox or run a compiled version of the program.'],...
            fcn(end).name, toolbox);                                        %Create the text for an error dialog.
        errordlg(str,'Missing Required MATLAB Toolbox');                    %Show an error dialog.
    end
else                                                                        %Otherise, if the function is compiled...
    toolbox_exists = 1;                                                     %Assume the toolbox exists.
end