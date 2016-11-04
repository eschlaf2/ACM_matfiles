
function [z_proj] = z_project(img)

z_proj = std(single(img),[],3);
figure
colormap gray;
imagesc(z_proj);

end