function [ output_args ] = polar_2P( data )
%To be used within trial_plot_2P or alone
%   NOTE: only works if number of subtrials is same for every trial









%% Initialize variables
TrialN = 1;
SmoothWin = 1;

numTrials = length(data);
numSub = data(1).subTrials;
numCell = length(data(1).fluoDat.baseF(1,:));

%% Calculate polar plots

%first calculate angles for stims
theta = linspace(0,2*pi(),data(1).subTrials+1);

rhos = calcArea();

        
    


%% Initialize GUI
F = figure('Visible','off','Position',[300,150,1200,775]);
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
hTrialN = uicontrol('Style','edit','String','1','Position',...
    [50,15,40,30],'Callback',@TrialNCall,'FontSize',16);
hText2 = uicontrol('Style','text','String',['of ' num2str(numCell)]...
    ,'Position',[91,15,55,30],'FontSize',16);
hBack = uicontrol('Style','pushbutton','String','<','Position',...
    [25,15,20,30],'Callback',@BackCall);
hFwd = uicontrol('Style','pushbutton','String','>','Position',...
    [145,15,20,30],'Callback',@FwdCall);
hSmooth = uicontrol('Style','slider','Min',1,'Max',11,'Value',1,...
    'Position',[200,15,150,30],'SliderStep',[0.1 0.1],'Callback',@SmoothCall);
hSmooth2 = uicontrol('Style','edit','String','1','Position',...
    [355,15,40,30],'Callback',@Smooth2Call,'FontSize',16);
set(F,'Visible','on');
hText3 = uicontrol('Style','text','String','Smoothing Window','Position',...
    [175,50,250,30],'FontSize',16);

%First plot
plotter()



%% Callback Functions
    function TrialNCall(source,callbackdata)
        if isnumeric(str2double(get(hTrialN,'String')))...
                && str2double(get(hTrialN,'String'))>0 ...
                && str2double(get(hTrialN,'String'))<=numCell;
            TrialN = str2double(get(hTrialN,'String'));
            plotter()
        else
            set(hTrialN,'String',num2str(TrialN));
        end
    end

    function BackCall(source,callbackdata)
        if str2double(get(hTrialN,'String'))>1
            TrialN = TrialN-1; 
            set(hTrialN,'String',num2str(TrialN));
            plotter()
        end
    end

    function FwdCall(source,callbackdata)
        if str2double(get(hTrialN,'String'))<numCell
            TrialN = TrialN+1; 
            set(hTrialN,'String',num2str(TrialN));
            plotter()
        end
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

    function supermat = calcArea()
        %Calculate area of points with dF/F0 more that 3 std away
        %(99.7% sure it is a spike)
        supermat = zeros(numTrials,numSub,numCell);
        for i = 1:numTrials
            %Create matrix with threshold values
            thresh = data(i).fluoDat.baseF+data(i).fluoDat.stdBaseF.*3;
            for ii = 1:numSub
                for iii = 1:numCell
                    tempDat = smooth(data(i).fluoDat.dFF{ii,iii},...
                        SmoothWin,'moving');
                    supermat(i,ii,iii)=sum(tempDat(tempDat>thresh(ii,iii)));
                end
            end
        end
        supermat = squeeze(mean(supermat));
        %Now normalize values
        for i = 1:numCell
            supermat(:,i) = supermat(:,i)./max(supermat(:,i));
        end
        supermat = [supermat;supermat(1,:)];   
        
    end

    function plotter
        cla(B)
        hline = polar(B,theta',rhos(:,TrialN));
        hline.LineWidth = 4;
        view(B,[90 -90]);
    end
          


end

