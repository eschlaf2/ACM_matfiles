% Get spike data using fast_oopsi

% Focus on cell 1 to start and see how analysis looks - try finding spikes
% with fast_oopsi and then using xcorr to look for consistency of
% responses.

% Parameters
% CELL = 3;
ZERO_PAD = 50;
SAMPLING_FREQ = 30;
SPREAD_PLOTS = .5;

% Get raw fluo data
cd('/projectnb/cruzmartinlab/emily/Ca Analysis')
load('data.mat');

% Get data
num_trials = length(data);
% t_min = min(cat(1,cellfun(@(x) size(x,1), data(1).fluoDat.raw(:))));
% for i = 2:num_trials
%     m = min(cat(1,cellfun(@(x) size(x,1), data(i).fluoDat.raw(:))));
%     if m < t_min; t_min = m; end
% end
num_orientations = size(data(1).fluoDat.raw,1);
t_indiv = zeros(num_orientations,num_trials);
trigs = t_indiv;
for i = 1:num_trials
    t_indiv(:,i) = cellfun(@(x) size(x,1), data(i).fluoDat.raw(:));
    trigs(:,i) = data(i).fluoDat.totTrig;
end
t_min = min(t_indiv(:));
% t_indiv = cellfun(@(x) size(x,1), data(CELL).fluoDat.raw(:));
% t_min = min(cat(1,t_indiv));
num_cells = size(data(1).fluoDat.raw{1},2)/3;
t_diffs = cumsum(t_indiv - t_min,1);
trigs = trigs - t_diffs;

% If triggers are spread, send warning
if max(max(abs(diff(trigs,[],2)))) > 2
    warning('Check triggers')
else
    trigs = trigs(:,1);
end

t_total = num_orientations*t_min;
spike_median = zeros(t_total, num_cells);
vr_cells = logical(ones(num_cells,1));
for CELL = 1:num_cells
fluo_raw = zeros(t_total,num_trials);

% Get raw fluorescence data
for i = 1:num_trials
    raw_dat = zeros(t_total,1);
    for j = 1:num_orientations
        raw_dat((j-1)*t_min+1:j*t_min,:) = ...
            data(i).fluoDat.raw{j}(1:t_min,(CELL-1)*3+1);
    end
    fluo_raw(:,i) = raw_dat - mean(raw_dat);
end

meancenter = @(x) cell2mat(arrayfun(@(i) x(:,i) - mean(x(:,i)), ...
        (1:size(x,2)),'uniformoutput',false));
% correlation seems to be a good indicator of VR
xc_raw = corrcoef(meancenter(fluo_raw));
if mean(xc_raw(:) < .2)
    vr_cells(CELL) = 0;
    continue
end

% Use fast_oopsi to convert to spike data
n_best = zeros(size(fluo_raw));
V.dt = 1/SAMPLING_FREQ;
for i = 1:num_trials
    n_best(:,i) = fast_oopsi(fluo_raw(:,i),V);
end
n_best(n_best < .1) = 0;

% Plot results
if 0 == 0
    im = 10 + CELL;
    spread_vert = repmat(SPREAD_PLOTS*(0:num_trials-1),t_total,1);
    figure(im);
    subplot(1,4,1)
    spread_traces = n_best + spread_vert;
    plot(spread_traces);
    hold on
    for i=1:num_orientations
        plot([trigs(i) trigs(i)], [0 num_trials + 1], 'color',.7*[1 1 1])
    end
    ylim([0 max(spread_traces(:,end))])
    title(sprintf('Cell %d \nIndividual',CELL))
    set(gca,'xtick',trigs,'xticklabel',(1:num_orientations))

    hold off
    subplot(1,4,2)
    n_best_median = median(n_best,2);
    stem(n_best_median)
    title(sprintf('Cell %d \nMedian',CELL))
    hold on;
    y_max = .5;
    for i=1:num_orientations
        plot([trigs(i) trigs(i)], [0 y_max], 'color',.7*[1 1 1])
    end
    ylim([0 y_max])
    set(gca,'xtick',trigs,'xticklabel',(1:num_orientations))
    hold off
    set(im,'units', 'normalized','position',[0 .5 1 .5])
    
    n_bestMC = meancenter(n_best);
    xc = corrcoef(n_bestMC);
%     xc = squeeze(max(...
%             reshape(...
%                 xcorr(n_bestMC,20,'biased'),...
%             41,num_trials,num_trials),...
%         [],1));
%     xc = xc./repmat(diag(xc),1,num_trials);
    subplot(1,4,3)
    imagesc(xc - .5*eye(size(xc)))
    colorbar
    title(sprintf('Correlation\nMean = %.2f',mean(xc(:))));
    
    subplot(1,4,4)
    xc_raw = corrcoef(meancenter(fluo_raw));
    imagesc(xc_raw-.5*eye(size(xc)))
    colorbar
    title(sprintf('Correlation\nMean = %.2f',mean(xc_raw(:))));

    
    pause
end
spike_median(:,CELL) = median(n_best,2);



end

spread_vert = repmat(SPREAD_PLOTS*(0:sum(vr_cells)-1),t_total,1);
spread_traces = spike_median(:,vr_cells) + spread_vert;
figure
plot(spread_traces)

