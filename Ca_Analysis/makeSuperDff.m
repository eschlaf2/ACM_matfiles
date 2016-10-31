function [supermat_dFF,stims] = makeSuperDff()
% make 4D matrix of dff data from Will's data matrix. Dimensions are
% [time,cells,orientations,trials] (values are unsmoothed dff).

cd('/projectnb/cruzmartinlab/emily/Ca_Analysis')
load('data.mat');

COVMIN = .3;
BASETIME=30;
STIMTIME = 275;
% SPREADBY = 1;

trig_onset = data(1).fluoDat.trig{1};
num_trials = length(data);
num_orientations = length(data(1).fluoDat.totTrig);
num_cells = size(data(1).fluoDat.dFF,2);
t_per_orientation = min(size(data(1).fluoDat.raw{1},1)-trig_onset,...
    STIMTIME);
stims = logical(repmat([zeros(BASETIME,1); ...
    ones(t_per_orientation,1)], num_orientations,num_cells));

% dFF
supermat_dFF = zeros(BASETIME+t_per_orientation,num_cells, ...
    num_orientations,num_trials);

for trial = 1:num_trials
    for orientation = 1:num_orientations
        newdata = cat(2,data(trial).fluoDat.dFF{orientation,:});
        supermat_dFF(:,:,orientation,trial) = ...
            newdata(trig_onset-BASETIME:trig_onset + t_per_orientation-1,:);
    end
end