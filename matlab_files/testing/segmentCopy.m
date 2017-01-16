% function [] = segmentCa2P(foldername,maxNeurons,estNeuronSize,savefile,options,roifile,paninskidff)

foldername = '/projectnb/cruzmartinlab/lab_data/WWY_080116_3/cell-bodies-1Hz/Results/';
LAGMAX = 60;
paninskidff = true;
savefile = 'notes/WWY_080116_3_cb1Hz/result';
printfigs = 'notes/WWY_080116_3_cb1Hz/';
roifile = [];

%% Load preprocessed images
if true % ~exist(resultName,'file')
    [trigs,dFF,N,spatmap,corrIm] = ...
        processCaImStack(foldername,roifile,paninskidff,...
        'maxNeurons',300,...
        'estNeuronSize',8,... % 4 is good for axons; 8 for cell bodies (for WWY_080116_3 data)
        'smallrun',false,...
        'dilation',1,...
        'conn_comp',false,... % set to false for axons
        'refine',false,... 
        'require_overlap',true,... % set to false for axons
        'init_method','greedy',... % 'greedy' for somas, 'sparse_NMF' for axons
        'ARp',2);
    
else
    load(resultName);
end

%% Save point (with SMALLRUN = true)
% load segProgSmall.mat;


%% Filter VR cells
display('Filtering for VR cells')
[T,numRois] = size(dFF);
[d1,d2] = size(corrIm);
t = T/N;
numOrientations = sum(diff(trigs)==1);
dffR = reshape(dFF,[],N,numRois);
dffM = squeeze(mean(dffR,2)); 
activitySum = squeeze(sum(fix(floor(dffR./repmat(std(dffR),t,1,1))-.1),2));

% merge
options.fast_merge = true;
options.deconv_method = 'none';
options.d1 = d1; options.d2 = d2;
[spatmapM, dffMM,~,~,~,activitySumM] = merge_components([],double(spatmap),[],dffM',[],[],activitySum',options);
[spatmapM,dffMM,activitySumM] = order_ROIs(spatmapM,dffMM,activitySumM,[]); % order components
spatmapM = spatmapM > 0;
dffMM = dffMM';
activitySumM = activitySumM';

% refine 
keepInds = filter_footprints(spatmapM);
spatmap = spatmapM(:,keepInds);
dffM = dffMM(:,keepInds);
activitySum = activitySumM(:,keepInds);


% compareVr;
numRois = size(dffM,2);
if ~exist('LAGMAX','var'); LAGMAX = 60; end
vrInds = filtervr(dffM,trigs,'ddt',LAGMAX);

rois = (1:numRois);


%% Get activity for each orientation
display('Calculating activity for each orientation')
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
x = sort(os(vrInds));
y = linspace(0,1,sum(vrInds));
% y = linspace(0,1,numRois);
figure(11); 
scatter(x,y,'b'); hold on
title('OS')

h(2) = figure(12); % DS cdf
x = sort(ds(vrInds));
figure(12); 
scatter(x,y,'b'); 
title('DS')

if sum(vrInds) > 0
h(3) = figure(13); % Polar plots
num2plot = min(sum(vrInds),25);
m = floor(sqrt(num2plot));
n = ceil(num2plot/m);
vractivity = activityOr(:,vrInds);
vrrois = rois(vrInds);
vros = os(vrInds); vrds = ds(vrInds);
[~,ord] = sort(vrds(:),'descend');
for i = 1:num2plot
    subplot(m,n,i)
    ind = ord(i);
    polarplot([theta(:); theta(1)], ...
        [vractivity(:,ind); vractivity(1,ind)]./max(vractivity(:,ind)),...
        'b','linewidth',2);
    statstr = sprintf('OS=%.1f, DS=%.1f',vros(ind),vrds(ind));
    set(gca,'thetatick',[90 270],'thetaticklabels',[vrrois(ind) {statstr}],...
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

options = CNMFSetParms();
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

try % angle hist
    h(8) = figure(18);
    angl = angle(sum(activityOr.*repmat(exp(1j*theta),1,size(activityOr,2))));
    ax = rose(angl(vrInds & (ds(:)>.5))); set(ax,'linewidth',2);
    title('Direction preference of DS cells')
%     x = get(ax, 'Xdata'); y = get(ax,'Ydata'); 
%     patch(x,y,[.5 .5 1]);
catch MErose
end

try % tuning curve (Atallah, 2013)
    ds_thr = 0.5;
    h(9) = figure(19);
    actOrS = activityOr;
    for i = 1:length(prefInd)
        actOrS(:,i) = circshift(actOrS(:,i),[2-prefInd(i),0]);
    end
    plot(actOrS(:,vrInds & ds(:)>ds_thr),'color',[.5,.5,1]); hold on;
    actOrSM = median(actOrS(:,vrInds & ds(:)>ds_thr),2);
    gaussEqn = 'a*exp(-((x-2)/c)^2) + aa*exp(-((x-6)/c)^2) + d';
    startPoints = [actOrSM(2) actOrSM(6) .5 0];
    x = repmat((1:8)',1,sum(vrInds & ds(:)>ds_thr)); y = actOrS(:,vrInds&ds(:)>ds_thr);
    f = fit(x(:),y(:),gaussEqn,'Start',startPoints);
%     f = fit((1:8)',actOrSM,gaussEqn,'Start',startPoints);
    x = linspace(1,8,100);
    plot(x,f(x),'k','linewidth',2); hold off;
    title('Tuning of DS cells')
%     plot(mean(actOrS(:,vrInds),2),'k','linewidth',2); hold off;
catch MEtuning
end



%% Save results
display('Saving')
titles = {'osCdf';'dsCdf'; 'polarPlots';'caVr';'caNotVr';'contourVr';...
    'contourNotVr';'rose';'tuning'};
for i = 1:numel(h)
    print(h(i),[printfigs titles{i}],'-dpng');
end
savefig(h,savefile)
clear h; close all;
save(savefile)
display('Success!!')
% end