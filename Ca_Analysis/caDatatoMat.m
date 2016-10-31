% [supermat, data] = CaAnalysis;

% Parameters
STDSCALE = 3;   % find spikes that jump at least STDSCALE*std
DIFFJUMP = 5;  % compare to value DIFFJUMP timesteps prior
ONSET_WINDOW = 50; % viable spike window


num_cells = size(supermat,2);
% smooth each cell's output (exponential)
avgMat = squeeze(mean(supermat,1));

t = size(avgMat,2);
sums = repmat((1:num_cells)',1,t);
stims = data(1).fluoDat.totTrig;
spikes = zeros(1,length(avgMat));
spikes(stims) = num_cells + 5;

window = zeros(size(avgMat));
for stim_start = stims'
    window(:,stim_start:stim_start+ONSET_WINDOW) = 1;
end

figure(10); 
colormap('gray')
im = imagesc(window);
im.AlphaData = .2;
hold on
view(0,-90)
plot([avgMat' + sums' spikes'])

std_dev = std(avgMat, [], 2);
diffs = avgMat(:,DIFFJUMP + 1:end) - avgMat(:,1:end-DIFFJUMP);

signals = abs(diffs) > STDSCALE*repmat(std_dev,1,t - DIFFJUMP);
signals = [zeros(num_cells, DIFFJUMP) signals] .* window;
figure(11);
colormap('gray')
im = imagesc(window);
im.AlphaData = .2;
hold on
plot([signals' + sums' spikes'])
view(0,-90)



% Find standard deviation of each cell
