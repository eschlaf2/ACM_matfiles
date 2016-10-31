function [ supermat, data ] = CaAnalysis (root)
%Analysis of 2P calcium imaging
% Output is data structure with dF/F calculated
%ANALYZE 1 EXPERIMENT AT A TIME

[data, root] = preprocess_2P(root);
data = csvRead_2P(data,root);
data = reorder_2P(data);
data = analyze_2P(data);
disp('Load Complete')
supermat = trial_plot_2P(data);
polar_2P( data );

end

%next write code to form data into matrix and average