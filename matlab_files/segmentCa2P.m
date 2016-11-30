% function [] = segmentCa2P(foldername,maxNeurons,estNeuronSize,savefile,options)

runInPatches = false;

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
LAGMAX = 30;

%         'd1',d1,'d2',d2,...                         % dimensions of datasets
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
        'ssub', 2,...                            % spatial downsampling factor (default: 1)
        'tsub', 4,...                            % temporal downsampling factor (default: 1)    
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
    trigs = im;
    trigFiles = dir([path '*trigs.txt']);
    for i = 1:N
        filename = [path trials(i).name];
        im{i} = single(readTifStack(filename));
        trigs{i} = csvread([path trigFiles(i).name]);
        if i == 1
            [options.d1, options.d2, ~] = size(im{i});
            [SpatMap,CaSignal,Spikes,width,height,corrIm,stats,options] = ...
                CaImSegmentation(im{i},maxNeurons,estNeuronSize,options);
            try savefig(gcf,savefile); catch ME; end
%             close all;
        end
    end
    % [d1,d2,~] = size(im{1});
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
    save(resultName,'im','trigs','N','SpatMap','-v7.3');
else
    load(resultName);
end
[d1,d2,T] = size(im);
numRois = size(SpatMap,2);

%% Calculate calcium signal using spatial map from trial 1
display('Getting fluorescence data')
fluo = zeros(T,numRois);
im = arrayfun(@(i) medfilt2(im(:,:,i)),(1:T),'uniformoutput',false);
im = cat(3,im{:});
imR = reshape(im,d1*d2,T);
% Maybe do medfilt1 here in time direction...
for i = 1:numRois
    fluo(:,i) = smooth(mean(imR(SpatMap(:,i)>0,:),1));
end
fluo = reshape(fluo,numRois,[],N);
baseline = quantile(fluo,.08,2);
% baseline = median(fluo(repmat(trigs,N,1)==0,:)); % take trigs off as baseline
dff = abs((fluo - repmat(baseline,1,T/N,1))./repmat(baseline,1,T/N,1));

close all
try save(savefile,'-v7.3'); catch MEsave; save('segmentationOutput'); end
% return

%% Save point (with SMALLRUN = true)
% load segProgSmall.mat;

end


%% Filter VR cells
display('Filtering for VR cells')
numOrientations = sum(diff(trigs)==1);
dffMed = median(dff,3);
acor = nan(numRois,1); lag = nan(numRois,1);
for i = 1:numRois
    [cc, loc] = xcorr(zscore(dffMed(i,:)),zscore(trigs),LAGMAX+10);
    [acor(i), mxind] = max((cc));
    lag(i) = loc(mxind);
end
vrInds = (lag > 0) & (lag < LAGMAX);
rois = (1:numRois);
% if sum(vrInds) > 10
%     dffMed = dffMed(vrInds,:);
%     numRois = sum(vrInds);
%     rois = rois(vrInds);
%     vrInds(~vrInds) = [];
%     contourAll = false;
% %     vrInds = true(numRois,1);
% else
%     numRois = min(numRois,50);
%     dffMed = dffMed(1:numRois,:);
%     vrInds = vrInds(1:numRois);
%     rois = rois(1:numRois);
%     contourAll = true;
% end

%% Get activity for each orientation
display('Calculating activity for each orientation')
% activity = reshape(caMed.*repmat(trigs',numRois,1),...
%     numRois,[],numOrientations);
% activity = reshape(caMed(:,trigs==1),numRois,[],numOrientations);
actStd = std(dff,[],2);
actStd = 3*repmat(actStd,1,T/N,1);
activity = double(dff > actStd);
activity = sum(activity,3);
% activity = activity - repmat(3.*std(activity,[],2),1,size(activity,2),1));
% activity(activity<0) = 0;
% activity(activity < repmat(3.*std(activity,[],2),1,size(activity,2),1)) = 0;
activity = reshape(activity,numRois,[],numOrientations);
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
num2plot = min(numRois,25);
m = floor(sqrt(num2plot));
n = ceil(num2plot/m);
for i = 1:num2plot
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
stackedTraces(zscore(dffMed')); hold on;
axis('tight'); yl = get(gca,'ylim'); ymax = ceil(yl(2));
set(gca,'yticklabels',rois);
imagesc((1:size(dffMed,2)),(0:ymax),repmat(trigs',ceil(ymax)+1,1),'alphadata',.2); 
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
