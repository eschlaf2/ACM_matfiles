function [] = registerFiles(fileNames,base,regFiles)
% Registers the tif files given in fileNames and saves the results (files
% that have been registered will have the tail 'reg' added to the file name
% and the old file is deleted). Use the regFiles input to supply the
% desired shifts for registration (for example, if using a a different
% channel to obtain cell locaiton information). All results are written to
% files so there is no output to this function.
% Inputs:
%   fileNames: cell containing names of files to be registered (required)
%   base: 2D image to use as base for registration (optional)
%   regFiles: cell containing names of files to use as registration data
%       (optional)

write2file = false; % Do not rewrite registration files
if ~exist('base','var')
    base = base_for_registration(readTifStack(fileNames{1}));
    write2file=true;
end

if ~exist('regFiles','var')
    regFiles = [];
end

parfor i = 1:length(fileNames)
    img = readTifStack(fileNames{i});
    if isempty(regFiles)
            [~,reg_info] = dft_register(img,base);
            write2file=true;
        else 
            try
                reg_info = csvread(regFiles{i});
            catch ME
                error(['''regFiles'' should be a cell variable with paths to ',...
                    'registration files. Expecting %d elements'],numTrials); 
            end
    end
    img_reg = dft_register(img,[],reg_info); % apply registration data
    [path,name,~] = fileparts(fileNames{i}); path = [path filesep];
    writeTif(img_reg,[path name '_reg']); % save registered image
    delete(fileNames{i}); % delete unregistered version
    if write2file
        if ~exist([path 'regInfo'],'dir')
            mkdir([path 'regInfo']);
        end
        csvwrite([path 'regInfo' filesep name '_reg_info.txt'],...
            reg_info);
	writeTif(base,[path 'regInfo' filesep name 'base']);
    end
end
