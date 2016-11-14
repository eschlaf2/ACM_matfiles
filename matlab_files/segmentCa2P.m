% function [] = segmentCa2P(foldername, maxNeurons, estNeuronSize)

options = CNMFSetParms(...                      
    'd1',512,'d2',512,...                         % dimensions of datasets
    'search_method','dilate','dist',100,...       % search locations when updating spatial components
    'deconv_method','constrained_foopsi',...    % activity deconvolution method
    'temporal_iter',2,...                       % number of block-coordinate descent steps 
    'fudge_factor',0.98,...                     % bias correction for AR coefficients
    'merge_thr',.85,...                    % merging threshold
    'maxthr',0.1,...                           % threshold of max value below which values are discarded (default: 0.1)
    'medw',[3,3],...                % size of median filter (default: [3,3])
    'gSig',4 ...
    );

wd = pwd; cd(foldername); path = [pwd filesep]; cd(wd);
trials = dir([path '*trial*.tif']);
N = length(trials);
im = cell(N,1); frames = zeros(N,1);
trigs = im;
trigFiles = dir([path '*trigs.tif']);
for i = 1:N
    filename = [path trials(i).name];
    im{i} = single(readTifStack(filename));
    trigs{i} = csvread([path trigFiles(i).name]);
    frames(i) = size(im{i},3);
end

im = cat(3,im{:});

[SpatMap, CaSignal, Spikes, width, height, corrIm] = ...
    CaImSegmentation(im,maxNeurons,estNeuronSize);

% SpatMap = im; CaSignal = im; Spikes = im;
% width = zeros(N,1); height = zeros(N,1);
% corrIm = im;
% for i = 1:N
%     filename = [path trials(i).name];
%     im{i} = single(readTifStack(filename));
%     [SpatMap{i},CaSignal{i},Spikes{i},width(i),height(i),corrIm{i}] = ...
%         CaImSegmentation(im{i},maxNeurons,estNeuronSize);
% end
