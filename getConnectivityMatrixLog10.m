function getConnectivityMatrixLog10
%% getConnectivityMatrix
% Computes a connectivity matrix of select brain structures using results
% data from neuPrint+
%
% Function used: moveable_listbox
% 
% input: results files from neuPrint+ (must be named as
% "results_[input]_[output].csv"
% output: connectivity matrix
% 
% By Charles Xu @ UCSD, 20230516
% 
%% Initialize
clear
close all

delim = '_'; % Specify delimiter
dataDir = uigetdir;

% Get data file directory
dataFile = dir(fullfile(dataDir, "results*.csv"));
dataFullFile = sort(string({dataFile.folder}') + filesep + string({dataFile.name}'));
[~,dataName,~] = fileparts(dataFullFile);
nResults = length(dataFullFile);

% Split the strings by the delimiter
region = split(dataName, delim);
regCol = region(:,2:3);
regCol = strrep(regCol, 'p', '_');
regCol = strrep(regCol, 'l', '_L_');
regCol = strrep(regCol, 'r', '_R_');
isRecurrent = (regCol(:,1) == regCol(:,2));
uniqueRegion = unique(region(:,2));

% Read results files and calculate total number of neurons
results = cell(nResults, 1);
nNeuron = 0;
args = input("Exclude recurrence? (y/n)", "s");
if args == "y"
    for i = 1:nResults
        if ~isRecurrent(i)
            results{i} = readtable(dataFullFile(i), 'VariableNamingRule', 'modify');
            nNeuron = nNeuron + size(results{i}, 1);
        end
    end
else
    for i = 1:nResults
    results{i} = readtable(dataFullFile(i), 'VariableNamingRule', 'modify');
    nNeuron = nNeuron + size(results{i}, 1);
    end
end

%% Calculate maximum "neuron size" of all results
neuronSizes = cell(nResults, 1);
for i = 1:nResults
    if ~isempty(results{i})
        neuronSizes{i} = results{i}.inputs__post_ + results{i}.outputs__pre_;
    end
end
maxSizes = cellfun(@max, neuronSizes, 'UniformOutput', false);
if class(maxSizes) == "cell"
    maxSizes(cellfun(@isempty, maxSizes)) = {NaN};
    maxSize = max(cell2mat(maxSizes));
else
    maxSize = max(maxSizes);
end

%% Compute connectivity score for each neuron/region, normalized by maxSize
cScoreNeuron = cell(nResults, 1);
cScoreRegion = zeros(nResults, 1);
for i = 1:nResults
    regPost = regCol(i, 1) + '_post';
    regPre = regCol(i, 2) + '_pre';
    if ~isempty(results{i})
        cScoreNeuron{i} = results{i}{:, results{i}.Properties.VariableNames == regPost}/ ...
            results{i}.inputs__post_ * results{i}{:, results{i}.Properties.VariableNames == regPre}/ ...
            results{i}.outputs__pre_ * neuronSizes{i}/maxSize;
            % Joint probability of a neuron receiving inputs from region 1 and
            % outputing to region 2, normalized by the maximum neuron size in
            % the entire population
    end
    cScoreRegion(i) = sum(cScoreNeuron{i});
    % Connectivity score of a region to another is calculated by the sum of
    % the connectivity scores of all associated neurons
end
cScoreRegion = reshape(cScoreRegion, length(uniqueRegion), length(uniqueRegion))';
iReorder = moveable_listbox(uniqueRegion);
uniqueRegionReordered = uniqueRegion(iReorder);
cScoreRegionReordered = cScoreRegion(iReorder, iReorder);
cScoreRegionLog10 = log10(cScoreRegionReordered);

% Plot heatmap for connectivity matrix
f1 = figure("Name", "ConnectivityMatrix_" + strjoin(uniqueRegion, '_'));
f1.Position = [100 100 1000 1000];
figure(f1)
h = heatmap(uniqueRegionReordered, uniqueRegionReordered, cScoreRegionLog10);
colormap(h, 'jet');
h.Title = 'Connectivity Matrix';
h.XLabel = 'Output (pre)';
h.YLabel = 'Input (post)';

%% Save data and figure
connectivity.dataFileName = dataName;
connectivity.brainRegion = uniqueRegionReordered;
connectivity.connectivityScore = cScoreNeuron;
connectivity.connectivityMatrix = cScoreRegionLog10;

resultsDir = string(pwd) + filesep + "results";
if ~exist(resultsDir, 'dir')
   mkdir(resultsDir)
end

if args == "y"
    save(fullfile(resultsDir, "Connectivity_" + strjoin(uniqueRegionReordered, '_') + "_Log10_noRecurrence.mat"), "connectivity")
    saveas(f1, fullfile(resultsDir, "ConnectivityMatrix_" + strjoin(uniqueRegionReordered, '_') + "_Log10_noRecurrence.png"))
else
    save(fullfile(resultsDir, "Connectivity_" + strjoin(uniqueRegionReordered, '_') + "_Log10.mat"), "connectivity")
    saveas(f1, fullfile(resultsDir, "ConnectivityMatrix_" + strjoin(uniqueRegionReordered, '_') + "_Log10.png"))
end

end
