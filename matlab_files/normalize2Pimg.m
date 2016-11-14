function img = normalize2Pimg(img)
% Normalize signal of a 2P calcium image (used for registration). Set
% baseline to bottom 8% and square signal.

[d1,d2,nt] = size(img);
img = arrayfun(@(i) medfilt2(img(:,:,i)), (1:nt), 'uniformoutput',false);
img = cat(3, img{:});
ql = repmat(reshape(arrayfun(@(i) quantile(reshape(img(:,:,i),[],1),...
        .08),(1:nt)),1,1,[]),d1,d2,1);
img = img-ql;
img(img < 0) = 0;
M = max(max(img,[],1),[],2);
% M = repmat(reshape(arrayfun(@(i) quantile(reshape(img(:,:,i),[],1),...
%     .999),(1:nt)),1,1,[]),d1,d2,1);
img = img./repmat(reshape(M,1,1,[]),d1,d2,1);
% img(img>1) = 1;
% qu = quantile(img(:),.95);
% qu = repmat(reshape(arrayfun(@(i) quantile(reshape(img(:,:,i),[],1),...
%         .85),(1:nt)),1,1,[]),d1,d2,1);
% img(img > qu) = qu;
img = img.^2;