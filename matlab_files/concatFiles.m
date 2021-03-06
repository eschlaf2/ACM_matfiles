% function [] = concatFiles(info_file)

v = true;

fullpath = fullfile(pwd,info_file);
[path,name,ext] = fileparts(fullpath);
name_parts = strsplit(name,'_');
start_ind = find(strcmp(name_parts,'to')) - 1;
start_num = name_parts(start_ind);
end_num = name_parts(end-1);

base_name = fullfile(path, strjoin(name_parts(1:3),'_'));

files = dir([base_name '*.tif']);
% img = cell(16,1);
img_nums = str2num(start_num{1}):str2num(end_num{1});
img = cell(length(files),1);
% img = readTifStack([base_name '_' num2str(img_nums(1), '%03d') '.tif']);
% img = reshape(img, size(img,1)*size(img,2), size(img,3));

display('Reading images') 
for i = 1:length(files)
    img{i} = ...
        readTifStack([base_name '_' num2str(img_nums(i), '%03d') '.tif']);
    if v
        display(sprintf('Completed %d/%d',i,length(files)))
    end
end

img_mat = cat(3,img{:});