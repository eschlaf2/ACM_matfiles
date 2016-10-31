% Make a super matrix of raw fluorescence data
[supermat_dFF, stims] = makeSuperDff();

% cd('/projectnb/cruzmartinlab/emily/Ca_Analysis')
% load('data.mat');

COVMIN = .3;

[t_per_orientation, num_cells, num_orientations, num_trials] = ...
    size(supermat_dFF);


% Look at covariance by orientation
xc_means_dFF = xcmeans(supermat_dFF);

% Plot original
super_cat = zeros(t_per_orientation*num_orientations,num_cells);
for orientation = 1:num_orientations
    super_cat(...
        (orientation - 1)*t_per_orientation+1:...
        orientation*t_per_orientation,:) = ...
        squeeze(median(supermat_dFF(:,:,orientation,:),4));
end

temp_mat = super_cat;
temp_mat(stims==1) = 0;
baselines = mean(temp_mat);

figure(13)
colormap(gray)
imagesc(stims','alphadata',.3)
hold on;
[fig13, ~, yticks] = stackedTraces(super_cat);
dy = yticks(2)-yticks(1);
ylim([yticks(1)-dy yticks(end)+dy])
set(gca, 'ytick', yticks, 'yticklabel', num2str((1:num_cells)'))

% baselines = mean(super_cat(logical(1-stims)));
stackedTraces(repmat(baselines,size(super_cat,1),1),dy);
hold off;
view(0,-90)

% highlight mean covariances greater that COVMIN
xc_good_dFF = xc_means_dFF;
indices = xc_means_dFF < COVMIN;
xc_good_dFF(indices) = 0;
figure(11)
imagesc(xc_good_dFF);
colorbar
title('Covariance for each orientation - dFF')
xlabel('Cell')
ylabel('Orientation')

% select good cells and show median dFF
good_cells = find(sum(xc_good_dFF,1) > 0);
num_good = length(good_cells);
super_good = supermat_dFF(:,good_cells,:,:);
super_good_median = squeeze(median(super_good,4));
super_meds_cat = zeros(t_per_orientation*num_orientations,num_good);
for orientation = 1:num_orientations
    super_meds_cat(...
        (orientation - 1)*t_per_orientation+1:...
        orientation*t_per_orientation,:) = ...
        super_good_median(:,:,orientation);
end
figure(12)
colormap(gray)
imagesc(stims','alphadata',.3)
hold on;
[fig12, ~, yticks] = stackedTraces(super_meds_cat);
dy = yticks(2)-yticks(1);
stackedTraces(repmat(baselines,num_good,1),dy);
ylim([yticks(1)-dy yticks(end)+dy])
set(gca, 'ytick', yticks, 'yticklabel', num2str(good_cells'))

hold off;
view(0,-90)

% Integrate activity of good cells
window = 2;
activity = squeeze(abs(sum(...
    super_good_median(stims(1:t_per_orientation),:,:))))';
activity = activity ./ repmat(max(activity),num_orientations,1);
activity = [activity(end-window:end,:); activity; activity(1:window,:)];
% activity = reshape(permute(activity,[1 3 2]),[],num_good);

figure(14)
m = floor(sqrt(num_good));
n = ceil(num_good/m);
% activity = reshape(permute(activity,[1 3 2]),[],num_good);
% orn_nums = repmat((1:num_orientations),num_trials,1);
% x = orn_nums(:);

for roi = 1:num_good
    subplot(m,n,roi)
    plot(activity(:,roi));
    title(num2str(good_cells(roi)));
end
xlabel('Orientation')

c = 2;
% roiInd = @(y) arrayfun(@(x) mod(x-1, num_orientations)+1,y);
hold on;
% gaussGen = @(a) sprintf('%f*exp(-((x-b)/c)^2) + d',a);
fo = fitoptions('Method','NonlinearLeastSquares',...
               'lower',[0 0 0 0],...
               'upper', [1 Inf Inf 1]);
% ft = fittype('a*exp(-((x-b)/c)^2) + d','problem','a','options',fo);
ft = fittype('a*exp(-((x-b)/c)^2) + d','options',fo);
    
f = struct([]);  
rs = zeros(num_good,2);
for roi = 1:num_good
    orn_filt = logical(false(size(activity,1),1));
    orn_filt(window+1:end-window) = true;
    [a,b] = max(activity(:,roi).*orn_filt);
    orn_filt(b-window:b+window) = false;
    [aa,bb] = max(activity(:,roi).*orn_filt);
    
    startPoints = [a b c 0];
%     gaussEqn = gaussGen(a);
%     [fit_temp, f(roi).gof1] = fit((b-window:b+window)',...
%         activity(b-window:b+window,roi),...
%         gaussEqn,'Start', startPoints);
    x = (b-window:b+window);
    [f(roi).f1, f(roi).gof1] = fit(x', activity(x,roi),...
        ft,'start', startPoints);
    rs(roi,1) = f(roi).gof1.rsquare;
    if rs(roi,1) > .9
        subplot(m,n,roi)
        hold on;
    %     plot(fit_temp,(1:size(activity,1)), activity(:,roi))
        plot(f(roi).f1,'m')
    end
    
    startPoints = [aa bb c 0];
    x = (bb-window:bb+window);
    [f(roi).f2, f(roi).gof2] = fit(x', activity(x,roi), ft, ...
        'Start', startPoints);
    rs(roi,2) = f(roi).gof2.rsquare;
    if rs(roi,2) > .9
        subplot(m,n,roi)
        hold on;
    %     plot(f1,(1:size(activity,1)), activity(:,roi),'g')
        plot(f(roi).f2,'c')
    end
    
    legend('off')
    hold off;
end
legend('off')
hold off

figure(15)
plot(rs)

