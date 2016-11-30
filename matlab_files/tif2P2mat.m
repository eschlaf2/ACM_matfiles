function [outpath] = tif2P2mat(foldername,chan,numOrientations,base,regFiles)
% Deinterleave and register .tif files in foldername. Files for the channel
% specified are reordered and concatenated into full trials and stored in
% results folder. 
% Inputs:
%   foldername: location of data (required)
%   chan: channel to concatenate (required)
%   numOrientations: number of orientations tested (optional, default: 8)
%   base: 2D image to use as base for registration 
%       (optional, default: Z projection of first image in folder)
%   regFiles: cell containing files to use for registration
% Outputs:
%   outpath: folder where results are stored (subfolder of foldername
%       called 'Results'

% Make input parser at some point...

%% Set defaults
if ~exist('chan','var')
    error('Input chan not assigned.')
end

if ~exist('regFiles','var')
    regFiles = [];
end

% get the full path and make Results directory if not already present
wd = pwd;
cd(foldername);
path = [pwd filesep];
cd(wd);
addpath(genpath(foldername));

if ~exist([path 'Results'],'dir')
    mkdir([path 'Results']);
end

default_numOrientations = 8;
if ~exist('numOrientations','var') || isempty(numOrientations)
    numOrientations = default_numOrientations;
end

%% get .mat data files with info from photo diode and .tif files with images
matfiles = dir([path '*.mat']);
tifFiles = dir([path '*.tif']);
t = Tiff([path tifFiles(1).name]);
tifinfo = t.getTag('ImageDescription');
t.close;

warning('off','MATLAB:m_missing_variable_or_function');
warning('off','MATLAB:UndefinedFunction');
f = fopen([path 'scanimage.txt'],'w');
for property = strsplit(tifinfo,'\n')
    fprintf(f,'%s\n',property{1});
    try 
        eval([property{1} ';'])
    catch ME
        if ~max(strcmp(ME.identifier,{'MATLAB:UndefinedFunction',...
                'MATLAB:m_missing_variable_or_function'}))
            warning(ME.message);
        end
    end
end
fclose(f);
%% Use this to improve deinterleaving ... later
channels = scanimage.SI4.channelsSave;
colors = scanimage.SI4.channelsMergeColor(channels);
basename = scanimage.SI4.loggingFileStem;
hz = scanimage.SI4.scanFrameRate;
tot_chan = numel(channels);

if ischar(chan)
    try 
        chan = find(strcmp(chan,colors));
    catch ME
        error('Variable chan must be one of ''%s'' ',...
            sprintf('''%s'' ',colors{:}));
    end
end

%% Get correct orders and remove botched trials
errFiles = ones(length(tifFiles),1);
N0 = 1;
order = cell(length(matfiles),1);
for i = 1:length(matfiles)
    filename = matfiles(i).name;
    display(['Reordering files from ' filename])
    data = load([path filename]);
    fnameSplit = strsplit(filename,'_to_');
    Nstart = strsplit(fnameSplit{1},'_');
    Nstart = str2double(Nstart{end});
    Nend = strsplit(fnameSplit{2},'_');
    Nend = str2double(Nend{end-1});
    N = Nend - Nstart + 1;
    [tmp,Nnew] = reorder2P(data,N);
    if mod(Nnew,numOrientations)
        inds = N0:N0+N-1; % indices of errFiles to update
        inds = inds(end-mod(Nnew,numOrientations)+1:end);
        errFiles(inds) = 0;
    end
    N0 = N0+N;
    N = floor(Nnew/numOrientations)*numOrientations;
    correct = meshgrid((0:numOrientations-1),(1:floor(Nnew/numOrientations)));
    check = min(unique(sort(tmp(1:N)) == correct(:)));
    if ~check
        error('Error in ordering for trial %d',i)
    end
    order{i} = reshape(tmp(1:N), numOrientations,[]);
end

csvwrite([path 'Results' filesep basename '_order.txt'],cat(2,order{:}));
[~,order] = sort(cat(2,order{:}));

%% Deinterleave and Register
% Assumes already deinterleaved if all color folders exist
if max(arrayfun(@(i) ~exist([path colors{i}],'dir'),1:numel(colors)))
    display('Deinterleaving TIFF files')
    for file = tifFiles(logical(errFiles))'
        deinterleaveTif([path file.name],colors);
    end
    % register
    for i = 1:numel(colors)-1 % Do not register triggers
        pathTmp = [path colors{i} filesep];
        fTmp = dir([pathTmp '*.tif']);
        if ~exist('base','var')
            base = base_for_registration(...
                readTifStack([pathTmp fTmp(1).name]));
        end
        fileNames = arrayfun(@(i) [pathTmp fTmp(i).name],(1:numel(fTmp)),...
            'uniformoutput',false);
        registerFiles(fileNames,base,regFiles);
        % csvwrite([pathTmp 'base'],base);
    end
    clear pathTmp fTmp
end

%% Reshape file lists to reorder by trial
tifpath = [path colors{chan} filesep];
tifFiles = dir([tifpath '*.tif']);
trigFiles = dir([path colors{end} filesep '*.tif']);
trigFiles = reshape(trigFiles,numOrientations,[]);
tifFiles = reshape(tifFiles, numOrientations,[]);

%%
numTrials = size(order,2);
adjOrder = meshgrid((0:numTrials-1)*numOrientations,(1:numOrientations));
imgfiles = tifFiles(order+adjOrder);
trigfiles = trigFiles(order+adjOrder);

%% Reorder and Concatenate
trig_col = colors{end};
parfor i = 1:numTrials
    display(sprintf('Processing trial %d',i))
    img = cell(numOrientations,1);
    trigs = img; 
    for j = 1:numOrientations
        display(sprintf('Starting trial %d, subtrial %d',i,j))
        file=imgfiles(j,i);
        img{j} = readTifStack([tifpath filesep file.name]);       
        trigs{j} = squeeze(readTifStack(...
            [path trig_col filesep trigfiles(j,i).name]));
%         img{j} = img{j}(:,:,2:numel(trigs{j}));trigs{j} = trigs{j}(2:end);
        img{j} = img{j}(:,:,2:end);trigs{j} = trigs{j}(2:end);
        trigs{j} = trigs{j}>0;        
    end
    outimg = cat(3,img{:});
    outtrigs = cat(1,trigs{:});
    outname = [path 'Results' filesep basename ...
        '_trial' num2str(i,'%02d')];
    writeTif(outimg,outname);
    csvwrite([outname '_trigs.txt'],outtrigs);

end
outpath = [path 'Results' filesep];
display('Done')
    




