function port = Vulintus_Serial_Select_Port(use_serialport, varargin)

%Vulintus_Serial_Select_Port.m - Vulintus, Inc., 2021
%
%   VULINTUS_SERIAL_SELECT_PORT detects available serial ports for Vulintus
%   OmniTrak devices and compares them to serial ports previously 
%   identified as being connected to OmniTrak systems.
%
%   UPDATE LOG:
%   2021-09-14 - Drew Sloan - Function first created, adapted from
%                             MotoTrak_Select_Serial_Port.m.
%   2024-02-28 - Drew Sloan - Renamed function from
%                             "OmniTrak_Select_Serial_Port" to 
%                             "Vulintus_Serial_Select_Port".
%   2024-06-06 - Drew Sloan - Added the option to use the older deprecated
%                             serial functions.
%


port = [];                                                                  %Set the function output to empty by default.
spec_port = [];                                                             %Seth the specified port variable to empty brackets.
if nargin > 1                                                               %If an optional input argument was included...
    spec_port = varargin{1};                                                %Assume the input is a specified port number.    
end

dpc = get(0,'ScreenPixelsPerInch')/2.54;                                    %Grab the dots-per-centimeter of the screen.
set(0,'units','pixels');                                                    %Set the screensize units to pixels.
scrn = get(0,'ScreenSize');                                                 %Grab the screensize.
btn_w = 15*dpc;                                                             %Set the width for all buttons, in pixels.
lbl_w = 3*dpc;                                                              %Set the width for all available/busy labels.
ui_h = 1.2*dpc;                                                             %Set the height for all buttons, in pixels.
ui_sp = 0.1*dpc;                                                            %Set the spacing between UI components.
fig_w = 3*ui_sp + btn_w + lbl_w;                                            %Set the figure width.
btn_fontsize = 18;                                                          %Set the fontsize for buttons.
lbl_fontsize = 16;                                                          %Set the fontsize for labels.
ln_w = 2;                                                                   %Set the linewidth for labels.                    
    
while isempty(port)                                                         %Loop until a COM port is chosen.
    
    port_list = Vulintus_Serial_Port_List(use_serialport);                  %Find all COM ports and any associated ID information.

    if isempty(port_list)                                                   %If no OmniTrak devices were found...
        errordlg(['ERROR: No Vulintus OmniTrak devices were detected '...
            'on this computer!'],'No OmniTrak Devices!');                   %Show an error in a dialog box.
        return                                                              %Skip execution of the rest of the function.
    end
    
    if ~isempty(spec_port)                                                  %If a port was specified...
        i = strcmpi(port_list(:,1),spec_port);                              %Find the index for the specified port.
        if any(i)                                                           %If there's a match to any port in the list.
            if strcmpi(port_list{i,2},'available')                          %If the specified port is available...
                port = port_list{i,1};                                      %Return the specified port.
                return                                                      %Skip execution of the rest of the function.
            end
        end
        spec_port = [];                                                     %Otherwise, if the specified port isn't found or is busy, ignore the input.
    end

    if size(port_list,1) == 1 && strcmpi(port_list{1,2},'available')        %If there's only one COM port and it's available...
        port = port_list{1,1};                                              %Automatically select that port.
    else                                                                    %Otherwise, if no port was automatically chosen...
        fig_h = (size(port_list,1) + 1)*(ui_h + ui_sp) + ui_sp;             %Set the height of the port selection figure.
        fig = uifigure;                                                     %Create a UI figure.
        fig.Units = 'pixels';                                               %Set the units to pixels.
        fig.Position = [scrn(3)/2-fig_w/2, scrn(4)/2-fig_h/2,fig_w,fig_h];  %St the figure position
        fig.Resize = 'off';                                                 %Turn off figure resizing.
        fig.Name = 'Select A Serial Port';                                  %Set the figure name.
        [img, alpha_map] = Vulintus_Load_Vulintus_Logo_Circle_Social_48px;  %Use the Vulintus Social Logo for an icon.
        img = Vulintus_Behavior_Match_Icon(img, alpha_map, fig);            %Match the icon board to the figure.
        fig.Icon = img;                                                     %Set the figure icon.
        for i = 1:size(port_list,1)                                         %Step through each port.
            if isempty(port_list{i,4})                                      %If the system type is unknown...
                str = sprintf('  %s: %s', port_list{i,[1,3]});              %Show the port with just the system type included.                
            else                                                            %Otherwise...
                str = sprintf('  %s: %s (%s)', port_list{i,[1,3,4]});       %Show the port with the alias included.
            end
            x = ui_sp;                                                      %Set the x-coordinate for a button.
            y = fig_h-i*(ui_h+ui_sp);                                       %Set the y-coordinate for a button.
            temp_btn = uibutton(fig);                                       %Put a new UI button on the figure.
            temp_btn.Position = [x, y, btn_w, ui_h];                        %Set the button position.
            temp_btn.FontName = 'Arial';                                    %Set the font name.
            temp_btn.FontWeight = 'bold';                                   %Set the fontweight to bold.
            temp_btn.FontSize = btn_fontsize;                               %Set the fontsize.
            temp_btn.Text = str;                                            %Set the button text.
            temp_btn.HorizontalAlignment = 'left';                          %Align the text to the left.
            temp_btn.ButtonPushedFcn = {@OSSP_Button_press,fig,i};          %Set the button push callback.
            x = x + ui_sp + btn_w;                                          %Set the x-coordinate for a label.
            temp_ax = uiaxes(fig);                                          %Create temporary axes for making a pretty label.
            temp_ax.InnerPosition = [x, y, lbl_w, ui_h];                    %Set the axes position.
            temp_ax.XLim = [0, lbl_w];                                      %Set the x-axis limits.
            temp_ax.YLim = [0, ui_h];                                       %Set the y-axis limits.
            temp_ax.Visible = 'off';                                        %Make the axes invisible.
            temp_ax.Toolbar.Visible = 'off';                                %Make the toolbar invisible.
            temp_rect = rectangle(temp_ax);                                 %Create a rectangle in the axes.            
            temp_rect.Position = [ln_w/2, ln_w/2, lbl_w-ln_w, ui_h-ln_w];   %Set the rectangle position.
            temp_rect.Curvature = 0.5;                                      %Set the rectangle curvature.
            temp_rect.LineWidth = ln_w;                                     %Set the linewidth.
            if strcmpi(port_list{i,2},'available')                          %If the port is available...
                temp_rect.FaceColor = [0.75 1 0.75];                        %Color the label light green.
                temp_rect.EdgeColor = [0 0.5 0];                            %Color the edges dark green.
            else                                                            %Otherwise...
                temp_rect.FaceColor = [1 0.75 0.75];                        %Color the label light red.
                temp_rect.EdgeColor = [0.5 0 0];                            %Color the edges dark red.
            end
            temp_txt = text(temp_ax);                                       %Create text on the UI axes.
            temp_txt.String = upper(port_list{i,2});                        %Set the text string to show the port availability.            
            temp_txt.Position = [lbl_w/2, ui_h/2];                          %Set the text position.
            temp_txt.HorizontalAlignment = 'center';                        %Align the text to the center.
            temp_txt.VerticalAlignment = 'middle';                          %Align the text to the middle.
            temp_txt.FontName = 'Arial';                                    %Set the font name.
            temp_txt.FontWeight = 'normal';                                 %Set the fontweight to bold.
            temp_txt.FontSize = lbl_fontsize;                               %Set the fontsize.
        end
        x = ui_sp;                                                          %Set the x-coordinate for a button.
        y = ui_sp;                                                          %Set the y-coordinate for a button.
        temp_btn = uibutton(fig);                                           %Put a new UI button on the figure.
        temp_btn.Position = [x, y, btn_w + lbl_w + ui_sp, ui_h];            %Set the button position.
        temp_btn.FontName = 'Arial';                                        %Set the font name.
        temp_btn.FontWeight = 'bold';                                       %Set the fontweight to bold.
        temp_btn.FontSize = btn_fontsize;                                   %Set the fontsize.
        temp_btn.Text = 'Re-Scan Ports';                                    %Set the button text.
        temp_btn.HorizontalAlignment = 'center';                            %Align the text to the center.
        temp_btn.ButtonPushedFcn = {@OSSP_Button_press,fig,0};              %Set the button push callback.
        drawnow;                                                            %Immediately update the figure.
        uiwait(fig);                                                        %Wait for the user to push a button on the pop-up figure.
        if ishandle(fig)                                                    %If the user didn't close the figure without choosing a port...
            i = fig.UserData;                                               %Grab the selected port index.
            if i ~= 0                                                       %If the user didn't press "Re-Scan"...
                port = port_list{i,1};                                      %Set the selected port.
            end
            close(fig);                                                     %Close the figure.   
        else                                                                %Otherwise, if the user closed the figure without choosing a port...
           return                                                           %Skip execution of the rest of the function.
        end
    end
end


function OSSP_Button_press(~,~,fig,i)
fig.UserData = i;                                                           %Set the figure UserData property to the specified value.
uiresume(fig);                                                              %Resume execution.