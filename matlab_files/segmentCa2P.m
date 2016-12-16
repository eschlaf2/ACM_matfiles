% function [] = segmentCa2P(foldername,maxNeurons,estNeuronSize,savefile,options,roifile,useC)

runInPatches = false;

if ~exist('savefile','var') || isempty(savefile)
    savefile = ['notes/segProg' date()];
end
if ~exist('useC','var') || isempty(useC); useC = false; end
if exist([savefile '.mat'],'file')
    i = 1;
    savetmp = savefile;
    while exist([savetmp '.mat'],'file')
        savetmp=[savefile '_' num2str(i,'%03d')];
        i = i+1;
    end
    savefile = savetmp;
end
SMALLRUN = true;
IGNORE = false;
LAGMAX = 45;
D = 4; % dilation

if ~exist('foldername','var'); 
    foldername = ...
        '/projectnb/cruzmartinlab/lab_data/WWY_080116_3/axons/Results/';...
end
if ~exist('maxNeurons','var')||isempty(maxNeurons); maxNeurons = 100; end
if ~exist('estNeuronSize','var')||isempty(estNeuronSize); estNeuronSize = 4; end
tau = estNeuronSize;                   % std of gaussian kernel (size of neuron) - 4 is a good start 
p = 2;                                % order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
merge_thr = 0.8;   
if ~exist('options','var') || isempty(options)
    options = CNMFSetParms(...                      
        'search_method','ellipse','dist',8,...       % search locations when updating spatial components
        'deconv_method','constrained_foopsi',...    % activity deconvolution method
        'ssub', 1,...                            % spatial downsampling factor (default: 1)
        'tsub', 1,...                            % temporal downsampling factor (default: 1)    
        'fudge_factor',0.98,...                     % bias correction for AR coefficients
        'merge_thr',merge_thr,...                    % merging threshold
        'maxthr',0.1,...                           % threshold of max value below which values are discarded (default: 0.1)
        'medw',[3,3],...                % size of median filter (default: [3,3])
        'save_memory', false,...      % process data sequentially to save memory (default: 0)
        'cluster_pixels',true,...
        'gSig',tau...
        );
    % Data pre-processing
end

%%
if ~IGNORE

if ~exist('foldername','var'); 
    foldername = ...
        '/projectnb/cruzmartinlab/lab_data/WWY_080116_3/axons/Results/';...
end
if ~exist('maxNeurons','var')||isempty(maxNeurons); maxNeurons = 100; end
if ~exist('estNeuronSize','var')||isempty(estNeuronSize); estNeuronSize = 4; end

%% Load preprocessed images
display('Loading images')
wd = pwd; cd(foldername); path = [pwd filesep]; cd(wd);
resultName = [path 'results.mat'];
if SMALLRUN; resultName = [path 'resultsSmall.mat']; end
if true % ~exist(resultName,'file')
    trials = dir([path '*trial*.tif']);
    N = length(trials);
    if SMALLRUN; N = min(N,3); end
    im = cell(N,1); 
    trigs = im; C = im;
    trigFiles = dir([path '*trigs.txt']);
    for i = 1:N
        filename = [path trials(i).name];
        im{i} = single(readTifStack(filename));
        trigs{i} = csvread([path trigFiles(i).name]);
        if i == 1 
            [d1,d2,~] = size(im{1});
            if ~exist('roifile','var') || isempty(roifile)
                [options.d1, options.d2, ~] = size(im{i});
                [SpatMap,~,~,~,~,corrIm,~,options] = ...
                    CaImSegmentation(im{i},maxNeurons,estNeuronSize,options);
                spatmap = dilate(SpatMap,[d1,d2],D);
                try savefig(gcf,savefile); catch ME; end
                close all
            else
                corrIm = correlation_image(im{1});
                spatmap = imgj2spatmap(roifile,[d1,d2]);
            end
%             close all;
        end
        [im{i},trigs{i}] = alignTrigs(im{i},trigs{i});
        [d1,d2,~] = size(im{i});
        numOrientations = sum(diff(trigs{i})==1);
        imtmp = reshape(im{i},d1,d2,[],numOrientations);
        subC = cell(numOrientations,1);
        if useC 
            for orn = 1:numOrientations
                st = squeeze(imtmp(:,:,:,orn));
                [P,st] = preprocess_data(st,p);
                [subC{orn},~,~,~] = ...
                    update_temporal_components(...
                    reshape(st,d1*d2,[]),double(spatmap),[],[],[],P);
                subC{orn} = subC{orn}';
            end
        else
            numRois = size(spatmap,2);
            for orn = 1:numOrientations
                st = squeeze(imtmp(:,:,:,orn));
                subC{orn} = dff(st,spatmap,trigs{i});
%                 T = size(st,3);
%                 st = arrayfun(@(t) medfilt2(st(:,:,t)),(1:T),...
%                     'uniformoutput',false);
%                 st = cat(3,st{:});
%                 subC{orn} = zeros(T,numRois);
%                 imR = reshape(st,d1*d2,T);
%                 tau1 = ceil(30*.75/2);
%                 for j = 1:numRois
%                     subC{orn}(:,j) = smooth(mean(imR(spatmap(:,j)>0,:),1),tau1);
%                 end
%                 %% DFF
%                 tau0 = 6;
%                 fluoR = subC{orn};
%                 baseline = median(fluoR(trigs{i}(1:T)==0,:),1);
%                 % baseline = median(fluo(repmat(trigs,N,1)==0,:)); % take trigs off as baseline
%                 R = (fluoR - repmat(baseline,T,1))./repmat(baseline,T,1);
%                 w = exp(-(1:tau0)/tau0);
%                 subC{orn} = filter(w,sum(w),R);
            end
        end
        C{i} = cat(1,subC{:});
    end
    end

    %% Align all trials and subtrials to trigger onsets
    display('Aligning')
    [im,trigs,C] = alignTrigs(im,trigs,C,300);
    
%     display('Saving')
%     save(resultName,'im','trigs','C','N','spatmap','corrIm','-v7.3');
else
    load(resultName);
end
[d1,d2,T] = size(im);
numRois = size(spatmap,2);

%% Calculate calcium signal using spatial map from trial 1
display('Getting fluorescence data')
dFF = C;

%% Save point (with SMALLRUN = true)
% load segProgSmall.mat;


%% Filter VR cells
display('Filtering for VR cells')
numOrientations = sum(diff(trigs)==1);
dffR = reshape(dFF,[],N,numRois);
dffM = squeeze(mean(dffR,2));
activitySum = squeeze(sum(double(dffR > 3*repmat(std(dffR),T/N,1,1)),2));

% correlation with trigs
vrIndscorr = filtervr(dffM,trigs,'corr',LAGMAX);
% acor = nan(numRois,1); lag = nan(numRois,1);
% for i = 1:numRois
%     [cc, loc] = xcorr((dffM(:,i)),(trigs),LAGMAX+10,'unbiased');
%     [acor(i), mxind] = max((cc));
%     lag(i) = loc(mxind);
% end
% vrInds = (lag > 0) & (lag < LAGMAX) & (acor > 0);

% difference in activity
vrIndsdiff = filtervr(activitySum,trigs,'diff',[],1.25);
% baseAct = activitySum(trigs==0,:);
% stimAct = activitySum(trigs==1,:);
% vrInds = 1.5*mean(baseAct) < mean(stimAct);

% spike in frame
vrIndsspike = filtervr(dffM,trigs,'spiketime',LAGMAX);

rois = (1:numRois);


%% Get activity for each orientation
display('Calculating activity for each orientation')
% activity = double(zscore(dffR) > 3);
% activitySum = squeeze(sum(activity,2));
activitySR = reshape(activitySum(trigs==1,:),[],numOrientations,numRois);
activityOr = squeeze(sum(activitySR,1));
theta = linspace(0,2*pi,numOrientations+1)'; theta = theta(1:end-1);

%% Get os and ds per Scanziani 2012
display('Calculating OS and DS')
actOs = reshape(activityOr,[],2,numRois);
actOs = squeeze(sum(actOs,2));
os = abs(actOs'*exp(1i*2*theta(1:numOrientations/2)))./sum(actOs,1)';
os(isnan(os)) = 0;
[actPref, prefInd] = max(activityOr,[],1);
nullInd = mod(prefInd-1+numOrientations/2,numOrientations)+1;
actNull = arrayfun(@(r,c) activityOr(r,c),nullInd,(1:numRois));
ds = (actPref - actNull)./(actPref+actNull);

%% Plot OS and DS
display('Plotting')
h(1) = figure(11); % OS cdf
x = sort(os);
y = linspace(0,1,numRois);
figure(11); scatter(x,y,'r'); hold on
scatter(x(vrInds),y(vrInds),'b'); hold off
title('OS')
legend({'Not VR';'VR'},'location','southeast')

h(2) = figure(12); % DS cdf
x = sort(ds);
y = linspace(0,1,numRois);
figure(12); scatter(x,y,'r'); hold on
scatter(x(vrInds),y(vrInds),'b'); hold off
title('DS')
legend({'Not VR';'VR'},'location','southeast')

if sum(vrInds) > 0
h(3) = figure(13); % Polar plots
num2plot = min(sum(vrInds),25);
m = floor(sqrt(num2plot));
n = ceil(num2plot/m);
vractivity = activityOr(:,vrInds);
vrrois = rois(vrInds);
vros = os(vrInds); vrds = ds(vrInds);
for i = 1:num2plot
    subplot(m,n,i)
    polarplot([theta(:); theta(1)], ...
        [vractivity(:,i); vractivity(1,i)]./max(vractivity(:,i)),...
        'b','linewidth',2);
    statstr = sprintf('OS=%.1f, DS=%.1f',vros(i),vrds(i));
    set(gca,'thetatick',[90 270],'thetaticklabels',[vrrois(i) {statstr}],...
        'rticklabels',[])
end
end
% for i = 1:num2plot
%     if vrInds(i); s = 'b'; else s = 'r'; end
%     subplot(m,n,i)
%     polarplot([theta(:); theta(1)], ...
%         [activity(:,i); activity(1,i)]./max(activity(:,i)),...
%         s,'linewidth',2);
%     statstr = sprintf('OS=%.1f, DS=%.1f',os(i),ds(i));
%     set(gca,'thetatick',[90 270],'thetaticklabels',[rois(i) {statstr}],...
%         'rticklabels',[])
% end

try
    h(4) = figure(14); % Ca signal plots
    stackedTraces(zscore(dffM(:,vrInds))); hold on;
    axis('tight'); yl = get(gca,'ylim'); ymax = ceil(yl(2));
    set(gca,'yticklabels',rois(vrInds));
    imagesc((1:size(dffM,1)),(0:ymax),repmat(trigs',ceil(ymax)+1,1),'alphadata',.2); 
    ylim(yl); 
    colormap(gray); hold off
    title('VR traces')
catch MEvrTraces
end

try
    h(5) = figure(15); 
    stackedTraces(zscore(dffM(:,~vrInds))); hold on;
    axis('tight'); yl = get(gca,'ylim'); ymax = ceil(yl(2));
    set(gca,'yticklabels',rois(~vrInds));
    imagesc((1:size(dffM,1)),(0:ymax),repmat(trigs',ceil(ymax)+1,1),'alphadata',.2); 
    ylim(yl); 
    colormap(gray); hold off
    title('Not VR traces')
catch MEnotVrTraces
end

try
    h(6) = figure(16); % contour plots 
    plot_contours(spatmap(:,vrInds),corrIm,options,1,[],[],2,rois(vrInds));
    title('VR')
catch MEvrContours
end

try
    h(7) = figure(17);
    plot_contours(spatmap(:,~vrInds),corrIm,options,0);
    title('Not VR')
    catch MEnotVrContours
end

%% Save results
display('Saving')
savefig(h,savefile)
clear h; close all;
clear imR
save(savefile)
display('Success!!')
% end
