function getConnectivityMatrix
%% getConnectivityMatrix
% Computes a connectivity matrix of select brain structures using results
% data from neuPrint+
% 
% input: results files from neuPrint+ (must be named as
% "results_[input]_[output].csv"
% output: connectivity matrix
% 
% By Charles Xu @ UCSD, 20230415
% 
%% Initialize
clear
close all

delim = '_'; % Specify delimiter
dataDir = uigetdir;

% Read data files
dataFile = dir(fullfile(dataDir, "results*.csv"));
dataFullFile = string({dataFile.folder}') + filesep + string({dataFile.name}');
[~,dataName,~] = fileparts(dataFullFile);
nResults = length(dataFullFile);
results = cell(nResults, 1);

nNeuron = 0;
for i = 1:nResults
    results{i} = readtable(dataFullFile(i), 'VariableNamingRule', 'modify');
    nNeuron = nNeuron + size(results{i}, 1);
end

% Split the strings by the delimiter
region = split(dataName, delim);
uniqueRegion = unique(region(:,2));

% Calculate maximum "neuron size" of all results
neuronSizes = cell(nResults, 1);
for i = 1:nResults
    neuronSizes{i} = results{i}.inputs__post_ + results{i}.outputs__pre_;
end
maxSizes = cellfun(@max, neuronSizes);
maxSize = max(maxSizes);

% Compute connectivity score for each neuron/region, normalized by maxSize
cScoreNeuron = cell(nResults, 1);
cScoreRegion = zeros(nResults, 1);
for i = 1:nResults
    cScoreNeuron{i} = results{i}{:, results{i}.Properties.VariableNames == region(i, 2) + '_post'}/ ...
        results{i}.inputs__post_ * results{i}{:, results{i}.Properties.VariableNames == region(i, 3) + '_pre'}/ ...
        results{i}.outputs__pre_ * neuronSizes{i}/maxSize;
        % Joint probability of a neuron receiving inputs from region 1 and
        % outputing to region 2, normalized by the maximum neuron size in
        % the entire population 
    cScoreRegion(i) = sum(cScoreNeuron{i});
    % Connectivity score of a region to another is calculated by the sum of
    % the connectivity scores of all associated neurons
end
cScoreRegion = reshape(cScoreRegion, length(uniqueRegion), length(uniqueRegion))';

% Plot heatmap for connectivity matrix
f1 = figure("Name", "ConnectivityMatrix_" + strjoin(uniqueRegion, '_'));
figure(f1)
h = heatmap(uniqueRegion, uniqueRegion, cScoreRegion);
h.Title = 'Connectivity Matrix';
h.XLabel = 'Output (pre)';
h.YLabel = 'Input (post)';

% Save data and figure
connectivity.dataFileName = dataName;
connectivity.brainRegion = uniqueRegion;
connectivity.connectivityScore = cScoreNeuron;
connectivity.connectivityMatrix = cScoreRegion;

resultsDir = string(pwd) + filesep + "results";
if ~exist(resultsDir, 'dir')
   mkdir(resultsDir)
end
save(fullfile(resultsDir, "Connectivity_" + strjoin(uniqueRegion, '_') + '.mat'), "connectivity")
saveas(f1, fullfile(resultsDir, "ConnectivityMatrix_" + strjoin(uniqueRegion, '_') + ".png"))

end