function data = memmap_var(Y,outname,varargin)

% read a stacked tiff array, reshapes it to 2d array and saves it a mat file that can be memory mapped. 
% The file is saved both in its original format and as a reshaped 2d matrix

% INPUTS
% filename:     path to tiff file
% varargin:     additional variables to save to file

% OUTPUT
% data:         object with the data containing:
%   Yr:         reshaped data file
% sizY:         dimensions of original size
%   nY:         minimum value of Y (not subtracted from the dataset)


if ~exist('outname','var') || isempty(outname);
    outname = 'results';
    i = 1; outTmp = outname;
    while exist(outname,'file')
        outTmp = sprintf('%s_%02d',outname,i);
    end
    outname = outTmp;
end
if nargin > 2
    for i = 3:nargin
        eval([inputname(i) '= varargin{i-2}']);
    end
end

sizY = size(Y);
Yr = reshape(Y,prod(sizY(1:end-1)),[]);
nY = min(Yr(:));
%Yr = Yr - nY;
if nargin > 2
    s = '';
    for i = 3:nargin
        s = sprintf('%s''%s'',',s,inputname(i));
    end
    eval(sprintf(...
        'save(outname,''Yr'',''Y'',''nY'',''sizY'',%s,''-v7.3'');',...
        s(1:end-1)));
else
    save(outname,'Yr','Y','nY','sizY','-v7.3');
end
data = matfile(outname,'Writable',true);