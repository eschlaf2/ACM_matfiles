function [trigs,dFF,N,spatmap,corrIm,im,options] = processCaImStack(foldername, roifile, paninskidff, varargin)
% Processes stacks of registered calcium images. Images should be saved in
% path and named *trial*.tif. The input to this function is the output from
% registerCaIm. All outputs are aligned around the trigger onsets so that
% each subtrial is the same length and has the same number of time steps
% with the stimulus on (off). 
% Inputs:
%   foldername: a path to a folder containing deinterleaved and registered trials
%       (required)
%   roifile: a path to an ROI file (zip file) from ImageJ. If this file is
%       not provided, the image will be autosegmented using the Paninski
%       algorithm. (optional)
%   paninskidff: binary indicating whether to use Paninski algorithm to
%       calculate DFF. (optional, default: false)
%   varargin: optional name-value pair arguments:
%       - 'estNeuronSize': estimated radius of cells in pixels (default: 4)
%       - 'maxNeurons': number of neurons to initialize if using Paninski
%           to segment (default: 100)
%       - 'lagmax': time window (in steps) for VR filtering (default: 60)
%       - 'refine': manually refine ROI components if using
%           auto-segmentation (default: false)
%       - 'cluster_pixels': set to false for axon data (default: true)
%       See input parser function below for more.
%
% Outputs:
%   trigs: binary vector of length T, where T is the length of a trial,
%   representing the presence or absence of stimulus.
%   dFF: delta f/f calculated according to dff() or Paninski algo, as
%       indicated by paninskidff
%   N: number of trials
%   spatmap: d x k binary mask representing spatial footprint of each ROI
%       where d = d1 x d2 (the total number of pixels in each image) and k
%       is the number of ROIs
%   corrIm: d1 x d2 correlation image
%   im: d1 x d2 x T matrix of images from all trials

%% parse inputs
if ~exist('roifile','var'); roifile = []; end
if ~exist('paninskidff','var') || isempty(paninskidff); paninskidff=false; end
p = parse_options(varargin{:});


%% Load preprocessed images
display('Loading images')
wd = pwd; cd(foldername); path = [pwd filesep]; cd(wd);
resultName = [path 'results.mat'];

trials = dir([path '*trial*.tif']);
    N = length(trials);
    if p.smallrun; N = min(N,3); end
    im = cell(N,1); 
    trigs = im; dFF = im;
    trigFiles = dir([path '*trigs.txt']);
    for i = 1:N
        filename = [path trials(i).name];
        im{i} = single(readTifStack(filename));
        trigs{i} = csvread([path trigFiles(i).name]);
        if i == 1 
            [d1,d2,T] = size(im{1});
            if isempty(roifile) % run Paninski algo
                % % This needs to be tested...
                Y = double(im{i});
                Y = Y - min(Y(:)); 
                [P,Y] = preprocess_data(Y,p.ARp,p.options);
                [p.options.d1, p.options.d2, ~] = size(im{i});
                [A,C,b,f,center] = ...
                    initialize_components(Y,p.maxNeurons,...
                    p.estNeuronSize,p.options,P);  % initialize
                corrIm = correlation_image(Y);
                if p.refine; 
                    [A,C,~] = ...
                        manually_refine_components(Y,A,C,center,...
                        corrIm,p.estNeuronSize,p.options);
                end
                Y = reshape(Y,d1*d2,T);
                [A,b,C] = update_spatial_components(Y,C,f,[A,b],P,p.options);
                if size(A,2) == 0; error('Zero spatial components found.'); end
                P.p = 0; % set to 0 for speed
                [C,f,P,S] = update_temporal_components(Y,A,b,C,f,P,p.options);
                [A,C,~,~,P] = merge_components(Y,A,b,C,f,P,S,p.options);
                P.p = p.ARp; % restore AR value
                [A,b,C] = update_spatial_components(Y,C,f,[A,b],P,p.options);
                if size(A,2) == 0; error('Zero spatial components found.');end
                [C,~,P,S] = update_temporal_components(Y,A,b,C,f,P,p.options);
                A_or = order_ROIs(A,C,S,P); % order components
                spatmap = A_or(:,1:end-1);                
                spatmap = dilate(spatmap,[d1,d2],p.dilation);
                close all
            else
                corrIm = correlation_image(im{1});
                spatmap = imgj2spatmap(roifile,[d1,d2]);
            end
%             close all;
        end
        [im{i},trigs{i}] = alignTrigs(im{i},trigs{i});
        [d1,d2,~] = size(im{i});
        numOrientations = sum(diff(trigs{i})==1);
        imtmp = reshape(im{i},d1,d2,[],numOrientations);
        subC = cell(numOrientations,1);
        if paninskidff 
            for orn = 1:numOrientations
                st = squeeze(imtmp(:,:,:,orn));
                [P,st] = preprocess_data(st,p.ARp);
                [subC{orn},~,~,~] = ...
                    update_temporal_components(...
                    reshape(st,d1*d2,[]),double(spatmap),[],[],[],P);
                subC{orn} = subC{orn}';
            end
        else
            for orn = 1:numOrientations
                st = squeeze(imtmp(:,:,:,orn));
                subC{orn} = dff(st,spatmap,trigs{i});
            end
        end
        dFF{i} = cat(1,subC{:});
    end
    clear imtmp subC st
    %% Align all trials and subtrials to trigger onsets
    display('Aligning')
    [~,trigs,dFF] = alignTrigs([],trigs,dFF,300);
    
    fprintf('Saving results to file\n%s\n',resultName)
%     save(resultName,'im','trigs','C','N','spatmap','corrIm','-v7.3');
    save(resultName,'trigs','dFF','N','spatmap','corrIm');
    options = p.options;
end

function p = parse_options(varargin)
p = inputParser;

addParameter(p,'refine',false,@(x) or(islogical(x),isempty(x)));
addParameter(p,'dilation',1,@isnumeric);
addParameter(p,'maxNeurons',100,@isnumeric);
addParameter(p,'estNeuronSize',4,@isnumeric);
addParameter(p,'ARp',1,@(x) any(x==[1,2,3]));
addParameter(p,'options',[]);
addParameter(p,'merge_thr',.8, @(x) x<=1 & x>=0);
addParameter(p,'conn_comp',true); 
addParameter(p,'smallrun',false);
addParameter(p,'require_overlap',true);
addParameter(p,'init_method','greedy',@(x) ...
    any(validatestring(x,{'sparse_NMF','greedy','greedy_corr','HALS'})));

parse(p,varargin{:});
p = p.Results;

% set CNMF options if none given
if isempty(p.options)
    p.options = CNMFSetParms(...                      
        'search_method','dilate','dist',8,...       % search locations when updating spatial components
        'deconv_method','constrained_foopsi',...    % activity deconvolution method
        'ssub', 1,...                            % spatial downsampling factor (default: 1)
        'tsub', 1,...                            % temporal downsampling factor (default: 1)    
        'fudge_factor',0.98,...                     % bias correction for AR coefficients
        'merge_thr',p.merge_thr,...                    % merging threshold
        'maxthr',0.1,...                           % threshold of max value below which values are discarded (default: 0.1)
        'medw',[3,3],...                % size of median filter (default: [3,3])
        'save_memory', false,...      % process data sequentially to save memory (default: 0)
        'conn_comp',p.conn_comp,...
        'require_overlap',p.require_overlap,...
        'init_method',p.init_method,... % 'greedy' for soma, 'sparse_NMF' for axons
        'gSig',p.estNeuronSize...
        );
end

end
