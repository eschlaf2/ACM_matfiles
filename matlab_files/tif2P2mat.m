function [outpath] = tif2P2mat(foldername,chan,numOrientations,base,regFiles)

% Make input parser at some point...

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

% set defaults
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
for property = strsplit(tifinfo,'\n')
    try 
        eval([property{1} ';'])
    catch ME
        if ~max(strcmp(ME.identifier,{'MATLAB:UndefinedFunction',...
                'MATLAB:m_missing_variable_or_function'}))
            warning(ME.message);
        end
    end
end

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
%     tmp = reorder2Pv2(data,numOrientations,N);
%     tmp = tmp(1:floor(N/numOrientations)*numOrientations);
    if mod(Nnew,numOrientations)
        inds = N0:N0+N-1; % indices of errFiles to update
        inds = inds(end-mod(Nnew,numOrientations)+1:end);
        errFiles(inds) = 0;
    end
    N0 = N0+N;
    N = floor(Nnew/numOrientations)*numOrientations;
    correct = meshgrid((0:numOrientations-1),(1:floor(Nnew/numOrientations)));
    check = min(unique(sort(tmp(1:N)) == correct(:)));
%     check = min(min(diff(sort(reshape(tmp(1:N),numOrientations,[])))))==1;
    if ~check
        error('Error in ordering')
    end
    order{i} = reshape(tmp(1:N), numOrientations,[]);
end
order = cat(2,order{:});

%% Deinterleave
display('Deinterleaving TIFF files')
for file = tifFiles(logical(errFiles))'
    deinterleaveTif([path file.name],colors);
end

%% Reshape file lists to reorder by trial
tifpath = [path colors{chan} filesep];
tifFiles = dir([tifpath '*.tif']);
trigFiles = dir([path colors{end} filesep '*.tif']);
trigFiles = reshape(trigFiles,...
    numOrientations,[]);
tifFiles = reshape(tifFiles, numOrientations,[]);

%%
numTrials = size(order,2);
imgfiles = tifFiles(order+1);
trigfiles = trigFiles(order+1);
if ~exist('base','var')
    base = base_for_registration(...
        readTifStack([tifpath filesep imgfiles(1,1).name]));
end
%% Register
trig_col = colors{end};
parfor i = 1:numTrials
    display(sprintf('Processing trial %d',i))
    img = cell(numOrientations);
    trigs = img; 
    for j = 1:numOrientations
        display(sprintf('Starting trial %d, subtrial %d',i,j))
        file=imgfiles(j,i);
        img{j} = readTifStack([tifpath filesep file.name]);
        trigs{j} = squeeze(readTifStack(...
            [path trig_col filesep trigfiles(j,i).name]));
        trigs{j} = trigs{j}>0;        
    end
    img = cat(3,img{:});
    outtrigs = cat(1,trigs{:});
    display(sprintf('Registering trial %d',i))
    if isempty(regFiles)
        [~,reg_info] = dft_register(img,base); % get registration data
        write2file = true;
    else
        write2file = false;
        try
            reg_info = csvread(regFiles{i});
        catch ME
            error(['''regFiles'' should be a cell variable with paths to ',...
                'registration files. Expecting %d elements'],numTrials); 
        end
    end
    outimg = dft_register(img,[],reg_info); % apply registration data
    outname = [path 'Results' filesep basename ...
        '_trial' num2str(i,'%02d')];
    display(sprintf('Saving results of trial %d',i));
    writeTif(outimg,outname);
    csvwrite([outname '_trigs.txt'],outtrigs);
    if write2file; csvwrite([outname '_regInfo.txt'],reg_info); end
%     if tot_chan > 2
%         
%         channels(chan) = []; channels = channels(1:end-1);
%         for c = channels
%             tifpath = [path colors{c} filesep];
%             tifFiles = dir([tifpath '*.tif']);
%             tifFiles = reshape(tifFiles, numOrientations,[]);
%             imgfiles = tifFiles(order+1);
%             img = cell(numOrientations);
%             for j = 1:numOrientations
%                 img{j} = readTifStack([tifpath filesep file.name]);
%                 img{j} = dft_register(single(img{j}),[],reg_info{j}); 
%             end
            
    
end
writeTif(base,[path 'Results' filesep 'base']);
outpath = [path 'Results' filesep];
display('Done')
    




