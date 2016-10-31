function [ supermat ] = trial_plot_2P ( data )
%Plot all cells for a single trial
%   Inputs are from analyze_2P


%% Temporary vars for testing
% numTrials = 6;


%% Initialize variables
TrialN = 1;
SmoothWin = 1;

%Grab data from input
numTrials = length(data);
%Initialize fluorescence and trigger data store
fluo{numTrials} = [];
trig{numTrials} = [];
%load fluorescence and trigger data
for i = 1:numTrials
    fluo{i} = data(i).fluoDat.dFF(end,:);
    trigX{i} = reshape([data(i).fluoDat.totTrig';...
        data(i).fluoDat.totTrig'],1, data(i).subTrials*2);
    Y1 = [-5, (length(data(i).fluoDat.dFF(end,:)))+15];
    Y2 = [length(data(i).fluoDat.dFF(end,:))+15, -5];
    if ~rem(data(i).subTrials,2) %if subtrials is even number
        trigY{i} = repmat([Y1 Y2],1,data(i).subTrials/2);
    else
        trigY{i} = repmat([Y2 Y1],1,floor(data(i).subTrials/2));
        trigY{i} = [Y1 trigY{i}];
    end
end

%Also compute averaged signal
%NOTE: only works if all trials have same number of subtrials
%first find max length
lengths = zeros(length(fluo),1);
for i = 1:length(fluo)
    lengths(i) = length(fluo{i}{1});
end
lengths = max(lengths);

supermat = zeros(length(fluo),length(fluo{1}),lengths);
for i = 1:length(fluo)
    for ii = 1:length(fluo{1})
        supermat(i,ii,1:length(fluo{i}{ii})) = fluo{i}{ii}';
    end
end

tempfluo = squeeze(mean(supermat));
for i = 1:length(fluo{1})
    fluo{numTrials+1}{i} = tempfluo(i,:)';
end
    
    
numTrials = numTrials+1;
trigY{end+1} = trigY{end};
trigX{end+1} = trigX{end};

%% Initialize GUI
F = figure('Visible','off','Position',[300,150,1200,775]);
A = axes;
set(A,'YTickLabel',[]);
set(A,'OuterPosition',[0 0.05 1 .95]);
set(F,'Visible','on');
hText1 = uicontrol('Style','text','String','Trial','Position',...
    [64,50,54,30],'FontSize',16);
hTrialN = uicontrol('Style','edit','String','1','Position',...
    [50,15,40,30],'Callback',@TrialNCall,'FontSize',16);
hText2 = uicontrol('Style','text','String',['of ' num2str(numTrials)]...
    ,'Position',[91,15,45,30],'FontSize',16);
hBack = uicontrol('Style','pushbutton','String','<','Position',...
    [25,15,20,30],'Callback',@BackCall);
hFwd = uicontrol('Style','pushbutton','String','>','Position',...
    [137,15,20,30],'Callback',@FwdCall);
hSmooth = uicontrol('Style','slider','Min',1,'Max',11,'Value',1,...
    'Position',[200,15,150,30],'SliderStep',[0.1 0.1],'Callback',@SmoothCall);
hSmooth2 = uicontrol('Style','edit','String','1','Position',...
    [355,15,40,30],'Callback',@Smooth2Call,'FontSize',16);
set(F,'Visible','on');
hText3 = uicontrol('Style','text','String','Smoothing Window','Position',...
    [175,50,250,30],'FontSize',16);

%% First plot
cla(A)
plot(A,trigX{TrialN},trigY{TrialN})
hold on
for k = 1:length(fluo{TrialN})
    plot(A,smooth(fluo{TrialN}{k},SmoothWin,'moving')+k)
end
axis([-0.01*length(fluo{TrialN}{1}) 1.01*length(fluo{TrialN}{1})...
    -5 length(fluo{TrialN})+5])
% set(A,'YTickLabel',[]);





%% Callback Functions
    function TrialNCall(source,callbackdata)
        if isnumeric(str2double(get(hTrialN,'String')))...
                && str2double(get(hTrialN,'String'))>0 ...
                && str2double(get(hTrialN,'String'))<=numTrials;
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
        if str2double(get(hTrialN,'String'))<numTrials
            TrialN = TrialN+1; 
            set(hTrialN,'String',num2str(TrialN));
            plotter()
        end
    end

    function SmoothCall(source,callbackdata)
        SmoothWin = get(hSmooth,'Value');
        set(hSmooth2,'String',num2str(SmoothWin));
        plotter()
    end

    function Smooth2Call(source,callbackdata)
        if isnumeric(str2double(get(hSmooth2,'String')))...
                && str2double(get(hSmooth2,'String'))>1 ...
                && str2double(get(hSmooth2,'String'))<=11;
            SmoothWin = str2double(get(hSmooth2,'String'));
            set(hSmooth,'Value',SmoothWin);
            plotter()
        else
            set(hSmooth2,'String',num2str(SmoothWin));
        end
    end



    function plotter
        cla(A)
        plot(A,trigX{TrialN},trigY{TrialN})
        hold on
        for k = 1:length(fluo{TrialN})
            plot(A,smooth(fluo{TrialN}{k},SmoothWin,'moving')+k)
        end
        
%         set(A,'YTickLabel',[]);
    end
            
















end

