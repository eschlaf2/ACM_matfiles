function base = base_for_registration(img,params,v)

if ~exist('v','var')
    v = false;
else
    v = logical(v);
end

% Parameters
msg = ['''params'' should be of the form [int,bool] where int is ',...
        'the number of times to smooth the image and bool determines ',...
        'whether or not to normalize.'];
if ~exist('params','var') || isempty(params)
    SMOOTH = 1;
    NORM = true;
elseif numel(params)~=2
    error(msg)
else
    try 
        SMOOTH = int(params(1));
        NORM = logical(params(2));
    catch ME
        error(msg);
    end
end

if v; display('Reading TIFF stack'); end
if ischar(img)
    img = readTifStack(img);
end

% img = single(img);
[d1,d2,numsamp] = size(img);

% remove oddballs (mean of surrounding stacks)
img = stackfix(img);
% cor = arrayfun(@(i) mean(min(corrcoef(single(reshape(...
%     img(:,:,i),[],1)), single(reshape(img(:,:,i+1),...
%     [],1))))),(1:size(img,3)-1));
% bad_cor = find(cor < mean(cor) - 2*std(cor));
% if ~isempty(bad_cor)
%     mean_fun = @(i) mean(cat(3,img(:,:,(i==1)*2+(i~=1)*(i-1)), ...
%         img(:,:,(i==1)*3 + ...
%         (i==numsamp)*(numsamp-2)+(1<i & numsamp>i)*(i+1))),3);
%     for ind=bad_cor
%         img(:,:,ind) = mean_fun(ind);
%     end
% end

% Smooth with gaussian
for i=1:SMOOTH
    if v && i == 1
        display('Smoothing')
    end
    img = smooth3(img,'gaussian');
end

% normalize (mean=0, std = 1)
if NORM
    if v; display('Normalizing'); end
    img = normalize2Pimg(img);
%     m = repmat(mean(mean(img,1),2),d1,d2,1);
%     sd_fun = @(i) std(reshape(img(:,:,i),[],1));
%     sd = repmat(reshape(arrayfun(sd_fun,(1:numsamp)),1,1,[]),...
%         size(img,1),size(img,2),1);
%     img = (img-m)./sd;
end

sigma = std(img,[],3);
muish = max(img,[],3);
base = max(sigma/max(sigma(:)), muish/max(muish(:)));
% base = max(quantile(img,.75,3),std(img,[],3));
end