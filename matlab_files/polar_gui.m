function [ keepInds ] = polar_gui( spatmap, varargin )
%To be used within trial_plot_2P or alone
%   NOTE: only works if number of subtrials is same for every trial

%% Initialize variables
RoiN = 1;
numrois = size(spatmap,2);
keepInds = true(numrois,1);

% numTrials = length(data);
% numSub = data(1).subTrials;
% numCell = length(data(1).fluoDat.baseF(1,:));

% %% Calculate polar plots
% 
% %first calculate angles for stims
% theta = linspace(0,2*pi(),data(1).subTrials+1);
% 
% rhos = calcArea();
% rhos = [rhos;rhos;rhos];
%         
% %% Calculate DSI OSI
% OSI = zeros(1,numCell);
% DSI = zeros(1,numCell);
% 
% for i = 1:numCell
%     pref = find(rhos(numSub+1:numSub*2,i) == max(rhos(:,i)))+numSub;
%     orth = [pref+2 pref+6];                         %%not generalized code, only works for 8 oris
%     opp = pref+4;
%     meanOrth = mean(rhos(orth,i));
%     OSI(i) = (rhos(pref,i) - meanOrth)/(rhos(pref,i) + meanOrth);
%     DSI(i) = (rhos(pref,i) - rhos(opp,i))/(rhos(pref,i) + rhos(opp,i));
% end


%% Initialize GUI
F = uifigure('Visible','off','Position',[300,150,1200,775]);
A = subplot(3,5,6);
set(A,'PlotBoxAspectRatio',[1 1 1]);
B = subplot(3,5,[2,3,4,7,8,9,12,13,14]);
set(B,'PlotBoxAspectRatio',[1 1 1]);
C = subplot(3,5,10);
set(C,'PlotBoxAspectRatio',[1 1 1]);
set(A,'YTickLabel',[]);
set(F,'Visible','on');
hText1 = uicontrol('Style','text','String','Cell','Position',...
    [70,50,54,30],'FontSize',16);
hRoiN = uicontrol('Style','edit','String','1','Position',...
    [50,15,40,30],'Callback',@RoiNCall,'FontSize',16);
hText2 = uicontrol('Style','text','String',['of ' num2str(numrois)]...
    ,'Position',[91,15,55,30],'FontSize',16);
hBack = uicontrol('Style','pushbutton','String','<','Position',...
    [25,15,20,30],'Callback',@BackCall);
hFwd = uicontrol('Style','pushbutton','String','>','Position',...
    [145,15,20,30],'Callback',@FwdCall);
% hSmooth = uicontrol('Style','slider','Min',1,'Max',11,'Value',1,...
%     'Position',[200,15,150,30],'SliderStep',[0.1 0.1],'Callback',@SmoothCall);
% hSmooth2 = uicontrol('Style','edit','String','1','Position',...
%     [355,15,40,30],'Callback',@Smooth2Call,'FontSize',16);
hSave = uicontrol('Style','pushbutton','String','Save Figure','Position',...
    [425,15,150,30],'Callback',@SaveCall,'FontSize',16);
hDelete = uicontrol('Style','pushbutton','String','Delete ROI',...
    'units','normalized', 'Position',[.5 .5 .1 .05],...
    'Callback',@DeleteROICall,...
    'FontSize',16);

hText3 = uicontrol('Style','text','String','Smoothing Window','Position',...
    [175,50,250,30],'FontSize',16);
set(F,'Visible','on');



bg = uibuttongroup('Visible','off',...
                  'Position',[0 0 .2 1],...
                  'SelectionChangedFcn',@bselection);
              
tb1 = uitogglebutton(bg,'Position',[10 50 100 22],'Text','Delete');              
              
% Make the uibuttongroup visible after creating child objects. 
bg.Visible = 'on';

    function bselection(source,callbackdata)
        
       display(['Previous: ' callbackdata.OldValue.String]);
       display(['Current: ' callbackdata.NewValue.String]);
       display('------------------');
    end



%First plot
plotter()



%% Callback Functions
    function RoiNCall(source,callbackdata)
        if isnumeric(str2double(get(hRoiN,'String')))...
                && str2double(get(hRoiN,'String'))>0 ...
                && str2double(get(hRoiN,'String'))<=numrois;
            RoiN = str2double(get(hRoiN,'String'));
            plotter()
        else
            set(hRoiN,'String',num2str(RoiN));
        end
    end

    function BackCall(source,callbackdata)
        if str2double(get(hRoiN,'String'))>1
            RoiN = RoiN-1; 
            set(hRoiN,'String',num2str(RoiN));
            plotter()
        end
    end

    function FwdCall(source,callbackdata)
        if str2double(get(hRoiN,'String'))<numrois
            RoiN = RoiN+1; 
            set(hRoiN,'String',num2str(RoiN));
            plotter()
        end
    end

    function DeleteROICall(source,callbackdata)
        keepInds(RoiN) = false;
    end

    function SmoothCall(source,callbackdata)
        SmoothWin = get(hSmooth,'Value');
        set(hSmooth2,'String',num2str(SmoothWin));
        rhos = calcArea();
        plotter()
    end

    function Smooth2Call(source,callbackdata)
        if isnumeric(str2double(get(hSmooth2,'String')))...
                && str2double(get(hSmooth2,'String'))>1 ...
                && str2double(get(hSmooth2,'String'))<=11;
            SmoothWin = str2double(get(hSmooth2,'String'));
            set(hSmooth,'Value',SmoothWin);
            rhos = calcArea();
            plotter()
        else
            set(hSmooth2,'String',num2str(SmoothWin));
        end
    end

%     function supermat = calcArea()
%         %Calculate area of points with dF/F0 more that 3 std away
%         %(99.7% sure it is a spike)
%         supermat = zeros(numTrials,numSub,numCell);
%         for i = 1:numTrials
%             %Create matrix with threshold values
%             thresh = data(i).fluoDat.baseF+data(i).fluoDat.stdBaseF.*3;
%             for ii = 1:numSub
%                 for iii = 1:numCell
%                     tempDat = smooth(data(i).fluoDat.dFF{ii,iii},...
%                         SmoothWin,'moving');
%                     supermat(i,ii,iii)=sum(tempDat(tempDat>thresh(ii,iii)));
%                 end
%             end
%         end
%         
%         supermat = squeeze(mean(supermat));
%         %Now normalize values
%         for i = 1:numCell
%             supermat(:,i) = supermat(:,i)./max(supermat(:,i));
%         end
%          
%         
%     end

    function SaveCall(source,callbackdata)
        saveas(F,sprintf('polar %d.jpg',RoiN))
    end

    function plotter
        cla(B)
        imagesc(B,reshape(spatmap(:,RoiN),512,512));
        set(gca,'xtick',[],'ytick',[]);
%         line = polar(B,theta',rhos(1:(numSub+1),TrialN));
%         line.LineWidth = 4;
%         line.Color = 'k';
%         view(B,[90 -90]);
        set(B,'FontSize',22,'Projection','perspective')
        title(B,{['ROI  ' num2str(RoiN)]});
    end
          


end

