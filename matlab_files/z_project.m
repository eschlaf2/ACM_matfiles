
function [z_proj] = z_project(img)

z_proj = std(img,[],3);
figure
colormap gray;
imagesc(z_proj);

end