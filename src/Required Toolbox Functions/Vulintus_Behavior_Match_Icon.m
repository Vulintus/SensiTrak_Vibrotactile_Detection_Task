function icon = Vulintus_Behavior_Match_Icon(icon, alpha_map, fig_handle)

%
%Vulintus_Behavior_Match_Icon.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_MATCH_ICON replaces transparent pixels in a uifigure
%   icon with the menubar color behind the icon.
%   
%   UPDATE LOG:
%   2024-02-28 - Drew Sloan - Function first created.
%

tb = uitoolbar(fig_handle);                                                 %Temporarily create a toolbar on the figure.
if ~isprop(tb,'BackgroundColor')                                            %If this version of MATLAB doesn't have the toolbar BackgroundColor property.
    return                                                                  %Skip the rest of the function.
end
back_color = tb.BackgroundColor;                                            %Grab the background color.
delete(tb);                                                                 %Delete the temporary toolbar.
alpha_map = double(1-alpha_map/255);                                        %Convert the alpha map to a 0-1 transparency.
for i = 1:size(icon,1)                                                      %Step through each row of the icon.
    for j = 1:size(icon,2)                                                  %Step through each column of the icon.
        if alpha_map(i,j) > 0                                               %If the pixel has any transparency...
            for k = 1:3                                                     %Step through the RGB elements.
                if alpha_map(i,j) == 1                                      %If the pixel is totally transparent...
                    icon(i,j,k) = uint8(255*back_color(k));                 %Set the pixel color to the background color directly.
                else                                                        %Otherwise...
                    icon(i,j,k) = icon(i,j,k) + ...
                        uint8(255*alpha_map(i,j)*back_color(k));        %   Add in the appropriate amount of background color.
                end
            end
        end
    end
end