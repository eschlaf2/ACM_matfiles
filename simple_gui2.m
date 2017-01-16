function keepInds = simple_gui2(spatmap,varargin)
% SIMPLE_GUI2 Select a data set from the pop-up menu, then
% click one of the plot-type push buttons. Clicking the button
% plots the selected data in the axes.
 
numrois = size(spatmap,2); 
d1 = 512; d2 = 512;
keepInds = true(numrois,1);


   %  Create and then hide the GUI as it is being constructed.
   f = figure('Visible','off','Position',[360,500,450,285]);
   for i = 1:16
       ha(i) = subplot(4,4,i);
   end
   
quitflag = false;
while ~quitflag
    
   %  Construct the components.
   hroi = uicontrol('Style', 'slider',...
    'Min',0,'Max',ceil(numrois/16)-1,'Value',1,...
    'Position', [50 20 200 15],...
    'Callback', @showroi_Callback);
    hdelete = uicontrol('Style','togglebutton','String','Delete',...
        'Position',[315, 265,70,25],...
        'Callback',@deletebutton_Callback);
   hsurf = uicontrol('Style','pushbutton','String','Surf',...
          'Position',[315,220,70,25],...
          'Callback',@surfbutton_Callback);
   hmesh = uicontrol('Style','pushbutton','String','Mesh',...
          'Position',[315,180,70,25],...
          'Callback',@meshbutton_Callback);
   hcontour = uicontrol('Style','pushbutton',...
          'String','Countour',...
          'Position',[315,135,70,25],...
          'Callback',@contourbutton_Callback); 
   htext = uicontrol('Style','text','String','Select Data',...
          'Position',[325,90,60,15]);
   hpopup = uicontrol('Style','popupmenu',...
          'String',{'Peaks','Membrane','Sinc'},...
          'Position',[300,50,100,25],...
          'Callback',@popup_menu_Callback);
     
   
%    ha = axes('Units','Pixels','Position',[50,60,200,185]); 
%    align([hsurf,hmesh,hcontour,htext,hpopup],'Center','None');
   
   % Create the data to plot.
   peaks_data = peaks(35);
   membrane_data = membrane;
   [x,y] = meshgrid(-8:.5:8);
   r = sqrt(x.^2+y.^2) + eps;
   sinc_data = sin(r)./r;
   current_data = peaks_data;
   
   % Initialize the GUI.
   % Change units to normalized so components resize 
   % automatically.
   f.Units = 'normalized';
%    ha.Units = 'normalized';
   hroi.Units = 'normalized';
   hdelete.Units = 'normalized';
   hsurf.Units = 'normalized';
   hmesh.Units = 'normalized';
   hcontour.Units = 'normalized';
   htext.Units = 'normalized';
   hpopup.Units = 'normalized';
   
   %Create a plot in the axes.
   pageN = 0;
   plotter();
   % Assign the GUI a name to appear in the window title.
   f.Name = 'Simple GUI';
   % Move the GUI to the center of the screen.
   movegui(f,'center')
   % Make the GUI visible.
   f.Visible = 'on';
   drawnow;
   

end
   %  Callbacks for simple_gui. These callbacks automatically
   %  have access to component handles and initialized data 
   %  because they are nested at a lower level.
   
   function showroi_Callback(source,callbackdata)
        pageN = round(source.Value);
        fprintf('%d ',pageN);
        plotter();
        s = 'off';
        if ~keepInds(pageN); s = 'on';end
        hdelete.Selected = s;
   end
    
    function deletebutton_Callback(source,eventdata)
        fprintf('%d: %d\n',pageN,~source.Value)
        keepInds(pageN) = ~source.Value;
        display(keepInds')
    end
 
   %  Pop-up menu callback. Read the pop-up menu Value property
   %  to determine which item is currently displayed and make it
   %  the current data.
      function popup_menu_Callback(source,eventdata) 
         % Determine the selected data set.
         str = source.String;
         val = source.Value;
         % Set current data to the selected data set.
         switch str{val};
         case 'Peaks' % User selects Peaks.
            current_data = peaks_data;
         case 'Membrane' % User selects Membrane.
            current_data = membrane_data;
         case 'Sinc' % User selects Sinc.
            current_data = sinc_data;
         end
      end
  
   % Push button callbacks. Each callback plots current_data in
   % the specified plot type.
 
   function surfbutton_Callback(source,eventdata) 
   % Display surf plot of the currently selected data.
      surf(current_data);
      quitflag = true;
   end
 
   function meshbutton_Callback(source,eventdata) 
   % Display mesh plot of the currently selected data.
      mesh(current_data);
   end
 
   function contourbutton_Callback(source,eventdata) 
   % Display contour plot of the currently selected data.
      contour(current_data);
   end 

    function plotter()
    % Plot spatial footprint of current roi
        maxAx = min(16,size(spatmap,2) - pageN*16);
        for i = 1:maxAx
            ha(i) = imagesc(reshape(spatmap(:,pageN*16+i),d1,d2));
            title(num2str(pageN*16+i));
        end
        drawnow();
        
    end

end 

