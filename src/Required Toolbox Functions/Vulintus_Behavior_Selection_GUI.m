function choice = Vulintus_Behavior_Selection_GUI(options, varargin)

%
%Vulintus_Behavior_Selection_GUI.m - Vulintus, Inc.
%
%   VULINTUS_BEHAVIOR_SELECTION_GUI creates a GUI selection box with the 
%   choices specified in the cell array (options), and returns the index of
%   the selected choice.
%   
%   UPDATE LOG:
%   2024-02-28 - Drew Sloan - Function first created, adapted from
%                             SensiTrak_Launcher.m.
%

fig_title = [];                                                             %Don't put a title on the figure by default.
icon = 'vulintus';                                                          %Set the default figure icon to the Vulintus icon.
available_icons = {'habitrak','mototrak','omnihome','omnitrak',...
    'sensitrak','vulintus'};                                                %List the available Vulintus icons.
for i = 1:length(varargin)                                                  %Step through the optional input arguments...
    if any(strcmpi(varargin{i},available_icons))                            %If an icon was specified...
        icon = lower(varargin{i});                                          %Set the figure icon.
    else                                                                    %Otherwise...
        fig_title = varargin{i};                                            %Assume the input is the figure title.
    end
end


%Set the scaling parameters according to the screen size and number of options.
n_choices = length(options);                                                %Grab the number of specified choices.
set(0,'units','centimeters');                                               %Set the screensize units to centimeters.
screen_size = get(0,'ScreenSize');                                          %Grab the screensize.
ui_h = 0.8*screen_size(4)/length(options);                                  %Calculate a button height.
ui_h = min(ui_h, 2.0);                                                      %Enforce a maximum button height.
fontsize = 10*ui_h;                                                         %Set the fontsize to 10x the button height.
max_char = 0;                                                               %Create a variable to hold the maximum number of characters.
for i = 1:n_choices                                                         %Step through each option.
    max_char = max(max_char, length(options{i}));                           %Check for a new maximum character length;
end
ui_w = 0.15*max_char*ui_h;                                                  %Scale the button width to the maximum character length.
ui_w = max(ui_w, 3.0);                                                      %Enforce a minimum button width.
sp = 0.25;                                                                  %Set the spacing between buttons.
fig_w = ui_w + 2*sp;                                                        %Set the figure width.
fig_h = n_choices*(ui_h + sp) + sp;                                         %Set the figure height.

%Create the selection GUI.
fig_pos = [ screen_size(3)/2-fig_w/2,...
            screen_size(4)/2-fig_h/2,...
            fig_w,...
            fig_h];                                                         %Center the figure in the screen.
fig = uifigure('units','centimeters',...
    'Position',fig_pos,...
    'resize','off',...
    'MenuBar','none',...
    'name',fig_title,...
    'numbertitle','off');                                                   %Set the properties of the figure.
switch icon                                                                 %Switch between the recognized icons.
    case 'habitrak'                                                         %HabiTrak.
        [icon_img, alpha_map] = Vulintus_Load_HabiTrak_V1_Icon_48px;        %Use the HabiTrak icon.
    case 'mototrak'                                                         %MotoTrak.
        [icon_img, alpha_map] = Vulintus_Load_MotoTrak_V2_Icon_48px;        %Use the MotoTrak V2 icon.
    case 'omnihome'                                                         %OmniHome.
        [icon_img, alpha_map] = Vulintus_Load_OmniHome_V1_Icon_48px;        %Use the OmniHome icon.
    case 'omnitrak'                                                         %OmniTrak.
        [icon_img, alpha_map] = Vulintus_Load_OmniTrak_V1_Icon_48px;        %Use the OmniTrak icon.    
    case 'sensitrak'                                                        %SensiTrak.
        [icon_img, alpha_map] = Vulintus_Load_SensiTrak_V1_Icon_48px;       %Use the SensiTrak icon.
    otherwise                                                               %For all other options.
        [icon_img, alpha_map] = ...
            Vulintus_Load_Vulintus_Logo_Circle_Social_48px;                 %Use the Vulintus Social Logo.
end
icon_img = Vulintus_Behavior_Match_Icon(icon_img, alpha_map, fig);          %Match the icon board to the figure.
fig.Icon = icon_img;                                                        %Set the figure icon.
fig.Units = 'pixels';                                                       %Change the figure units to pixels.
fig_pos = fig.Position;                                                     %Grab the figure position, in pixels.
scale = fig_pos(3)/fig_w;                                                   %Calculate the centimeters to pixels conversion factor.
fig.UserData = 0;                                                           %Assume no selection will be made.
for i = 1:length(options)                                                   %Step through each specified option.
    y = (length(options) - i)*(ui_h+sp) + sp;                               %Set the bottom edge.
    btn = uibutton(fig);                                                    %Create a button on the figure.
    btn.Position = scale*[sp y ui_w ui_h];                                  %Set the button position.
    btn.Text = options{i};                                                  %Set the button text.
    btn.FontName = 'Arial';                                                 %Set the font.
    btn.FontSize = fontsize;                                                %Set the fontsize.
    btn.FontWeight = 'bold';                                                %Set the fontweight.
    btn.ButtonPushedFcn = ...
        {@Vulintus_Behavior_Selection_GUI_Btn_Press,fig,i};                 %Set the button push callback.
end
drawnow;                                                                    %Immediately update the figure.
uiwait(fig);                                                                %Wait for the user to push a button on the pop-up figure.
if ishandle(fig)                                                            %If the user didn't close the figure without choosing an option...
    choice = fig.UserData;                                                  %Grab the selected option index.
    close(fig);                                                             %Close the figure.   
else                                                                        %Otherwise, if the user closed the figure without choosing an option...
   choice = 0;                                                              %Return a zero.
end
          

function Vulintus_Behavior_Selection_GUI_Btn_Press(~,~,fig,i)
fig.UserData = i;                                                           %Set the figure UserData property to the specified value.
uiresume(fig);                                                              %Resume execution.