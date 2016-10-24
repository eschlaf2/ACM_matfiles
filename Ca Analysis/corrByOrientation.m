% Make a super matrix of raw fluorescence data
cd('/projectnb/cruzmartinlab/emily/Ca Analysis')
load('data.mat');

num_trials = length(data);
num_orientations = length(data(1).fluoDat.totTrig);
num_cells = size(data(1).fluoDat.dFF,2);
t_per_orientation = size(data(1).fluoDat.raw{1},1);
t_padd = 10;

supermat = zeros(t_per_orientation+t_padd,num_cells, ...
    num_orientations,num_trials);

for trial = 1:num_trials
    for orientation = 1:num_orientations
        newdata = data(trial).fluoDat.raw{orientation}(:,1:3:end);
        supermat(1:size(newdata,1),:,orientation,trial) = newdata;
    end
end

% Look at correlation by orientation
xc_means = zeros(num_orientations,num_cells);
for cell = 1:num_cells
    for orientation = 1:num_orientations
        xc = corrcoef(squeeze(supermat(1:350,cell,orientation,:)));
        xc_means(orientation,cell) = mean(xc(:));
    end
end 

% highlight mean correlations greater that .3
xc_good = xc_means;
indices = xc_means < .3;
xc_good(indices) = 0;
figure(10)
imagesc(xc_good);
colorbar
title('Correlation for each orientation')
xlabel('Cell')
ylabel('Orientation')

% Compare to dFF
supermat_dFF = zeros(t_per_orientation+t_padd,num_cells, ...
    num_orientations,num_trials);

for trial = 1:num_trials
    for orientation = 1:num_orientations
        newdata = cat(2,data(trial).fluoDat.dFF{orientation,:});
        supermat_dFF(1:size(newdata,1),:,orientation,trial) = newdata;
    end
end

% Look at correlation by orientation
xc_means = zeros(num_orientations,num_cells);
for cell = 1:num_cells
    for orientation = 1:num_orientations
        xc = corrcoef(squeeze(supermat_dFF(1:350,cell,orientation,:)));
        xc_means(orientation,cell) = mean(xc(:));
    end
end 

% highlight mean correlations greater that .3
xc_good = xc_means;
indices = xc_means < .3;
xc_good(indices) = 0;
figure(11)
imagesc(xc_good);
colorbar
title('Correlation for each orientation')
xlabel('Cell')
ylabel('Orientation')

% Compare to fast_oopsi

% Compare to conv fast_oopsi