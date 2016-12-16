
% resultfile, trigfile
LAGMAX = 30;

data = csvread(resultfile,1,0); % read csv file from row 1, column 0
t = data(:,1);
f = fopen(resultfile,'r');
dataCols = strsplit(fscanf(f,'%s',1),','); fclose(f);
meanCols = cellfun(@(x) ~isempty(strfind(x, 'Mean')), dataCols);
fluoDat = medfilt1(data(:,meanCols));
[T, numrois] = size(fluoDat);
trigs = csvread(trigfile);

%% Calculate dff
baseline = median(fluoDat(trigs==0,:));
dff = (fluoDat - repmat(baseline,T,1))./repmat(baseline,T,1);
dffsm = cell2mat(arrayfun(@(i) smooth(dff(:,i)),1:numrois,'uniformoutput',false));
dffsm = alignActivity(dffsm,trigs);
T = size(dffsm,1);
%% Filter VR cells
display('Filtering for VR cells')
numOrientations = sum(diff(trigs)==1);
% dffsm = median(dff,3);
acor = nan(numrois,1); lag = nan(numrois,1);
for i = 1:numrois
    [cc, loc] = xcorr(zscore(dffsm(i,:)),zscore(trigs),LAGMAX+10);
    [acor(i), mxind] = max((cc));
    lag(i) = loc(mxind);
end
vrInds = (lag > 0) & (lag < LAGMAX);
rois = (1:numrois);
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
actStd = std(dffsm);
actStd = 3*repmat(actStd,T,1);
activity = double(dffsm > actStd);
activity = sum(activity,3);
% activity = activity - repmat(3.*std(activity,[],2),1,size(activity,2),1));
% activity(activity<0) = 0;
% activity(activity < repmat(3.*std(activity,[],2),1,size(activity,2),1)) = 0;
activity = reshape(activity,[],numOrientations,numrois);
activity = squeeze(sum(activity,1));
% activity = squeeze(sum(reshape(caMed.*repmat(trigs',numRois,1),...
%     numRois,[],numOrientations),2));

theta = linspace(0,2*pi,numOrientations+1)'; theta = theta(1:end-1);

%% Get os and ds per Scanziani 2012
display('Calculating OS and DS')
actOs = reshape(activity,[],2,numrois);
actOs = squeeze(sum(actOs,2));
os = abs(actOs'*exp(1i*2*theta(1:numOrientations/2)))./sum(actOs,1)';
os(isnan(os)) = 0;
[actPref, prefInd] = max(activity,[],1);
nullInd = mod(prefInd-1+numOrientations/2,numOrientations)+1;
actNull = arrayfun(@(r,c) activity(r,c),(1:numrois)',nullInd);
ds = (actPref - actNull)./(actPref+actNull);

%% Plot OS and DS
display('Plotting')
h(1) = figure(11); % OS cdf
x = sort(os);
y = linspace(0,1,numrois);
figure(11); scatter(x,y,'r'); hold on
scatter(x(vrInds),y(vrInds),'b'); hold off
title('OS')

h(2) = figure(12); % DS cdf
x = sort(ds);
y = linspace(0,1,numrois);
figure(12); scatter(x,y,'r'); hold on
scatter(x(vrInds),y(vrInds),'b'); hold off
title('DS')

h(3) = figure(13); % Polar plots
num2plot = min(numrois,25);
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
stackedTraces(zscore(dffsm')); hold on;
axis('tight'); yl = get(gca,'ylim'); ymax = ceil(yl(2));
set(gca,'yticklabels',rois);
imagesc((1:size(dffsm,2)),(0:ymax),repmat(trigs',ceil(ymax)+1,1),'alphadata',.2); 
ylim(yl); 
colormap(gray); hold off

% h(5) = figure(15); % contour plots of VR rois
% if contourAll
%     plot_contours(SpatMap,corrIm,options,1);
% else
%     plot_contours(SpatMap(:,vrInds),corrIm,options,1,[],[],[],...
%         cellstr(num2str(rois(vrInds)')));
% end

%% Save results
display('Saving')
savefig(h,savefile)
clear h; close all;
clear im
save(savefile)
display('Success!!')