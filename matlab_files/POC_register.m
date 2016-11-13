function [img_reg,output,base] = POC_register(img,base,output,v)
% img can be a tif file or a 3D array variable

if ~exist('v','var'); v = false; else v = logical(v); end
% Parameters
SMOOTH = 1;
NORM = true;
USFAC = 10; % upscale factor (Sicairos says 10 is best)

display('Reading TIFF stack')
if ischar(img)
    img = readTifStack(img);
end

if ~(or(isa(img,'single'),isa(img,'double')))
    img = single(img);
end

% minimize salt and pepper noise
[d1,d2,numsamp] = size(img);
img = arrayfun(@(x) medfilt2(img(:,:,x)),(1:numsamp),...
    'uniformoutput',false);
img = cat(3,img{:});

% fix oddballs
img = stackfix(img);

if exist('output','var')
    [d1,d2] = size(output);
    if d1 == 4
        0;
    elseif d2==4
        output = output.';
    else 
        error('''output'' should be a 4xN matrix.');
    end
    [nr,nc,~]=size(img);
    Nr = ifftshift(-fix(nr/2):ceil(nr/2)-1);
    Nc = ifftshift(-fix(nc/2):ceil(nc/2)-1);
    [Nc,Nr] = meshgrid(Nc,Nr);
    diffphase = output(2,:);
    row_shift = output(3,:);
    col_shift = output(4,:);
    parfor i = 1:numsamp
        imgtmp = fft2(img(:,:,i)).*...
            exp(1i*2*pi*(-row_shift(i)*Nr/nr-col_shift(i)*Nc/nc));
        imgtmp = imgtmp*exp(1i*diffphase(i));
        img_reg(:,:,i) = abs(ifft2(imgtmp));
        if v && mod(i,10) == 0
            display(sprintf('(%d/%d)',i,numsamp));
        end
    end
    return 
end
    

% do this separately
% sig_orig = img; % Register fixed original as well as smoothed and normed

% normalize (drop baseline, square signal)
if NORM
    if v; display('Normalizing'); end
    img = normalize2Pimg(img);
%     q = repmat(reshape(arrayfun(@(i) quantile(reshape(img(:,:,i),[],1),...
%         .08),(1:numsamp)),1,1,[]),d1,d2,1);
%     img = img-q;
%     img(img < 0) = 0;
%     img = img.^2;
%     m = repmat(mean(mean(img,1),2),size(img,1),size(img,2),1);
%     sd_fun = @(i) std(reshape(img(:,:,i),[],1));
%     sd = repmat(reshape(arrayfun(sd_fun,(1:size(img,3))),1,1,[]),...
%         size(img,1),size(img,2),1);
%     img = (img-m)./sd;
end

% Smooth with gaussian
for i=1:SMOOTH
    if v && i == 1
        display('Smoothing')
    end
    img = smooth3(img,'gaussian');
end

if ~exist('base','var') || isempty(base)
    base = base_for_registration(img,[0,false]);
end

output = zeros(4,numsamp);
img_reg = zeros(size(img),'single');
display('Starting registration')
% orig_reg = zeros(size(sig_orig));
% [nr,nc,~]=size(orig_reg);
% Nr = ifftshift(-fix(nr/2):ceil(nr/2)-1);
% Nc = ifftshift(-fix(nc/2):ceil(nc/2)-1);
% [Nc,Nr] = meshgrid(Nc,Nr);
parfor i  = 1:numsamp
    [outtmp,Greg] = ...
        dftregistration_poc(fft2(base),fft2(img(:,:,i)),USFAC);
%         dftregistration(fft2(base),fft2(img(:,:,i)),USFAC);
    img_reg(:,:,i) = abs(ifft2(Greg));
%     diffphase = outtmp(2);
%     row_shift = outtmp(3);
%     col_shift = outtmp(4);
%     orig_temp = fft2(sig_orig(:,:,i)).*...
%         exp(1i*2*pi*(-row_shift*Nr/nr-col_shift*Nc/nc));
%     orig_temp = orig_temp*exp(1i*diffphase);
%     orig_reg(:,:,i) = abs(ifft2(orig_temp));
    if v && mod(i,10) == 0
        display(sprintf('(%d/%d)',i,numsamp));
    end
    output(:,i) = outtmp;
end
display('Done')
% plot(output(1,:))
