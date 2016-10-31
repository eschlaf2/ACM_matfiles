function [] = writeGif(img_mat,filename,hz,merge)
% create a gif file with name filename and hz frames per second
MIN = 0;
MAX = 2328;

if exist('merge','var')
    for i = 1:floor(size(img_mat,3)/merge)
        img_mat(:,:,i) = mean(img_mat(:,:,merge*(i-1)+1:merge*i),3);
    end
    img_mat = img_mat(:,:,1:i);
end

b = min(img_mat(:))-MIN;
m = MAX/(max(img_mat(:)));

img_mat = uint8((img_mat - b) * m);
filename = [filename '.gif'];
imwrite(reshape(img_mat,size(img_mat,1),size(img_mat,2),...
    1,size(img_mat,3)),...
    filename,'gif','LoopCount',Inf,'DelayTime',1/hz);