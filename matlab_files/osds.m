% calculate OS and DS


trigFiles = dir([foldername '*trigs.txt']);
%% Find VR cells 
% get trigs
trigs = csvread([foldername trigFiles(1).name]);
C = arrayfun(@(i) (xcorr(full(activity(i,:)),trigs,300)),...
    (1:size(CaSignal{1},1)),'uniformoutput',false);