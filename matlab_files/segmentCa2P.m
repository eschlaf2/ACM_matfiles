% function [] = segmentCa2p(foldername,maxNeurons,estNeuronSize,savefile,options)

if ~exist('savefile','var') || isempty(savefile)
    savefile = ['/projectnb/cruzmartinlab/emily/segProg' date()];
end
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
LAGMAX = 60;

if ~IGNORE

if ~exist('foldername','var'); 
    foldername = ...
        '/projectnb/cruzmartinlab/lab_data/WWY_080116_3/axons/Results/';...
end
if ~exist('maxNeurons','var')||isempty(maxNeurons); maxNeurons = 300; end
if ~exist('estNeuronSize','var')||isempty(estNeuronSize); estNeuronSize = 4; end

%% Load preprocessed images
display('Loading images')
wd = pwd; cd(foldername); path = [pwd filesep]; cd(wd);
trials = dir([path '*trial*.tif']);
N = length(trials);
if SMALLRUN; N = min(N,2); end
im = cell(N,1); 
trigs = im;
trigFiles = dir([path '*trigs.txt']);
for i = 1:N
    filename = [path trials(i).name];
    im{i} = single(readTifStack(filename));
    trigs{i} = csvread([path trigFiles(i).name]);
end
[d1,d2,~] = size(im{1});
% if SMALLRUN
%     for i = 1:N
%         im{i} = im{i}(d1/2-25+1:d1/2+25,1:50,:);
%     end
%     maxNeurons = 30;
%     d1 = 50; d2 = d1;
% end

%% Align all trials and subtrials to trigger onsets
display('Aligning')
[im,trigs] = alignTrigs(im,trigs,300);
im = reshape(im,d1,d2,[],N);
T = size(im,3);

%% Calculate calcium signal
display('Segmenting')

% Set parameters
tau = estNeuronSize;                   % std of gaussian kernel (size of neuron) - 4 is a good start 
p = 2;                                % order of autoregressive system (p = 0 no dynamics, p=1 just decay, p = 2, both rise and decay)
merge_thr = 0.8;                       % merging threshold
% tsub = ceil(size(Y,3) / 5000);
savemem = T>5000;

if ~exist('options','var') || isempty(options)
    options = CNMFSetParms(...                      
        'd1',d1,'d2',d2,...                         % dimensions of datasets
        'search_method','dilate','dist',8,...       % search locations when updating spatial components
        'deconv_method','constrained_foopsi',...    % activity deconvolution method
        'ssub', 1,...                            % spatial downsampling factor (default: 1)
        'tsub', 1,...                            % temporal downsampling factor (default: 1)    
        'fudge_factor',0.98,...                     % bias correction for AR coefficients
        'merge_thr',merge_thr,...                    % merging threshold
        'maxthr',0.1,...                           % threshold of max value below which values are discarded (default: 0.1)
        'medw',[3,3],...                % size of median filter (default: [3,3])
        'save_memory', savemem,...      % process data sequentially to save memory (default: 0)
        'gSig',tau...
        );
    % Data pre-processing
end

SpatMap = cell(N,1); CaSignal = SpatMap; Spikes = SpatMap; corrIm = SpatMap;
stats = SpatMap;

for i = 1:N
    if i==1
        Y = im(:,:,:,1);
        Y = Y - min(Y(:)); 
        if ~isa(Y,'double');    Y = double(Y);  end         % convert to double
        [~,Y] = preprocess_data(Y,p);
        [~,~,~,~,ROI_list] = greedyROI(Y, maxNeurons, options);
    end
    [SpatMap{i}, CaSignal{i}, Spikes{i}, ~,~, corrIm{i}, stats{i},~] = ...
        CaImSegmentation(im(:,:,:,i),maxNeurons,estNeuronSize, ROI_list);
end

%% Testing
% Maybe merge components now...

try savefig(gcf,savefile); catch ME; end
close all;
save(savefile);
return

%% Save point (with SMALLRUN = true)
% load segProgSmall.mat;

end


%% Filter VR cells
display('Filtering for VR cells')
numRois = size(CaSignal,1);
numOrientations = sum(diff(trigs)==1);
caMed = median(reshape(full(CaSignal),numRois,[],N),3);
acor = nan(numRois,1); lag = nan(numRois,1);
for i = 1:numRois
    [cc, loc] = xcorr(zscore(caMed(i,:)),zscore(trigs),LAGMAX+10);
    cc = cc/xcorr(zscore(trigs),0);
    [acor(i), mxind] = max((cc));
    lag(i) = loc(mxind);
end
vrInds = (lag > 0) & (lag < LAGMAX) & acor > 0.25;
rois = (1:numRois);
if sum(vrInds) > 10
    caMed = caMed(vrInds,:);
    numRois = sum(vrInds);
    rois = rois(vrInds);
    vrInds(~vrInds) = [];
    contourAll = false;
%     vrInds = true(numRois,1);
else
    numRois = min(numRois,50);
    caMed = caMed(1:numRois,:);
    vrInds = vrInds(1:numRois);
    rois = rois(1:numRois);
    contourAll = true;
end

%% Get activity for each orientation
display('Calculating activity for each orientation')
% activity = reshape(caMed.*repmat(trigs',numRois,1),...
%     numRois,[],numOrientations);
activity = reshape(caMed(:,trigs==1),numRois,[],numOrientations);
% activity = activity - repmat(3.*std(activity,[],2),1,size(activity,2),1));
% activity(activity<0) = 0;
% activity(activity < repmat(3.*std(activity,[],2),1,size(activity,2),1)) = 0;
activity = squeeze(sum(activity,2));
% activity = squeeze(sum(reshape(caMed.*repmat(trigs',numRois,1),...
%     numRois,[],numOrientations),2));

theta = linspace(0,2*pi,numOrientations+1)'; theta = theta(1:end-1);

%% Get os and ds per Scanziani 2012
display('Calculating OS and DS')
actOs = reshape(activity,numRois,[],2);
actOs = sum(actOs,3);
os = abs(actOs*exp(1i*2*theta(1:numOrientations/2)))./sum(actOs,2);
os(isnan(os)) = 0;
[actPref, prefInd] = max(activity,[],2);
nullInd = mod(prefInd-1+numOrientations/2,numOrientations)+1;
actNull = arrayfun(@(r,c) activity(r,c),(1:numRois)',nullInd);
ds = (actPref - actNull)./(actPref+actNull);

%% Plot OS and DS
display('Plotting')
h(1) = figure(11); % OS cdf
x = sort(os);
y = linspace(0,1,numRois);
figure(11); scatter(x,y,'r'); hold on
scatter(x(vrInds),y(vrInds),'b'); hold off
title('OS')

h(2) = figure(12); % DS cdf
x = sort(ds);
y = linspace(0,1,numRois);
figure(12); scatter(x,y,'r'); hold on
scatter(x(vrInds),y(vrInds),'b'); hold off
title('DS')

h(3) = figure(13); % Polar plots
m = floor(sqrt(numRois));
n = ceil(numRois/m);
for i = 1:numRois
    if vrInds(i); s = 'b'; else s = 'r'; end
    subplot(m,n,i)
    polarplot([theta(:); theta(1)], ...
        [activity(i,:)'; activity(i,1)]./max(activity(i,:)),...
        s,'linewidth',2);
    statstr = sprintf('OS=%.1f, DS=%.1f',os(i),ds(i));
    set(gca,'thetatick',[90 270],'thetaticklabels',[rois(i) {statstr}],...
        'rticklabels',[])
end

h(4) = figure(14); % Ca signal plots
stackedTraces(zscore(caMed')); hold on;
axis('tight'); yl = get(gca,'ylim'); ymax = ceil(yl(2));
set(gca,'yticklabels',rois);
imagesc((1:size(caMed,2)),(0:ymax),repmat(trigs',ceil(ymax)+1,1),'alphadata',.2); 
ylim(yl); 
colormap(gray); hold off

h(5) = figure(15); % contour plots of VR rois
if contourAll
    plot_contours(SpatMap,corrIm,options,1);
else
    plot_contours(SpatMap(:,vrInds),corrIm,options,1,[],[],[],...
        cellstr(num2str(rois(vrInds)')));
end

%% Save results
display('Saving')
savefig(h,savefile)
clear h; close all;
clear im
save(savefile)
display('Success!!')
% end
