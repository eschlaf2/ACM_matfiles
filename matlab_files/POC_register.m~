% function [output, img_reg] = POC_register(tif_img)


% Parameters
SMOOTH = 2;
USFAC = 10; % upscale factor (only 2 in thesis - Sicairos says 10 is best)

% display('Reading TIFF stack')
% img = readTifStack(tif_img);
[signal, ~] = deinterleave(img);
sig_orig = signal; % Register original as well as smoothed and normed

% remove oddballs (mean of surrounding stacks
cor = arrayfun(@(i) mean(min(corrcoef(single(reshape(...
    signal(:,:,i),[],1)), single(reshape(signal(:,:,i+1),...
    [],1))))),(1:size(signal,3)-1));
bad_cor = find(cor < mean(cor) - 2*std(cor));
if ~isempty(bad_cor)
    signal(:,:,bad_cor) = ...
        mean(cat(3,signal(:,:,max(bad_cor-1,1)),...
        signal(:,:,min(bad_cor+1,numel(cor)))),3);
end

% Smooth with gaussian
for i=1:SMOOTH
    display('Smoothing image')
    signal = smooth3(signal,'gaussian');
end

% normalize (mean=0, std = 1)
signal = single(signal);
m = repmat(mean(mean(signal,1),2),size(signal,1),size(signal,2),1);
sd_fun = @(i) std(reshape(signal(:,:,i),[],1));
sd = repmat(reshape(arrayfun(sd_fun,(1:size(signal,3))),1,1,[]),...
    size(signal,1),size(signal,2),1);
signal = (signal-m)./sd;

base = z_project(single(signal(:,:,5:35)));

numsamp = size(signal,3);

output = zeros(4,numsamp);
img_reg = zeros(size(signal),'uint16');
display('Starting registration')
orig_reg = zeros(size(sig_orig));
[nr,nc,~]=size(orig_reg);
Nr = ifftshift(-fix(nr/2):ceil(nr/2)-1);
Nc = ifftshift(-fix(nc/2):ceil(nc/2)-1);
[Nc,Nr] = meshgrid(Nc,Nr);
for i  = 1:numsamp
    [output(:,i),Greg] = ...
        dftregistration(fft2(base),fft2(signal(:,:,i)),USFAC);
    img_reg(:,:,i) = abs(ifft2(Greg));
    diffphase = output(2,i);
    row_shift = output(3,i);
    col_shift = output(4,i);
    orig_temp = fft2(sig_orig(:,:,i)).*...
        exp(1i*2*pi*(-row_shift*Nr/nr-col_shift*Nc/nc));
    orig_temp = orig_temp*exp(1i*diffphase);
    orig_reg(:,:,i) = abs(ifft2(orig_temp));
end
display('Done')
plot(output(1,:))
