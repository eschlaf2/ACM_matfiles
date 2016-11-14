function img = stackfix(img)
% inpaint oddballs (mean of surrounding stacks)

nt = size(img,3);
cor = arrayfun(@(i) mean(min(corrcoef(single(reshape(...
    img(:,:,i),[],1)), single(reshape(img(:,:,i+1),...
    [],1))))),(1:nt-1));
bad_cor = find(cor < mean(cor) - 2*std(cor));
if ~isempty(bad_cor)
    mean_fun = @(i) mean(cat(3,img(:,:,(i==1)*2+(i~=1)*(i-1)), ...
        img(:,:,(i==1)*3 + ...
        (i==nt)*(nt-2)+(1<i & nt>i)*(i+1))),3);
    for ind=bad_cor
        img(:,:,ind) = mean_fun(ind);
    end
end