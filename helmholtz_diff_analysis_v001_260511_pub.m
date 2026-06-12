%  PROJECT
%  -------
%  Supplementary material to:
%      Feldmann, S. et al. (2026). "<Non-Destructive Quality Assessment of Permanent Magnets in
%      Pedelec Drive Systems via Magnetic Field Mapping and Support
%      Vector Machine Classification>",
%      Springer Nature, Vol(Issue), pp. xxx-xxx. DOI: 10.xxxx/xxxxx
%  Repository: https://github.com/<USERNAME>/BioBike

%% helmholtz_diff_analysis.m  (Publication-ready)
% Difference analysis: pulsed (freshly re-magnetised) vs. used (in-service)
% rotor magnets, based on Helmholtz scan data.
%
% Publication styling pass:
%   - Centralised PUB struct for all font / line settings
%   - Font sizes scaled for journal column reduction
%   - Times New Roman throughout
%   - 300 DPI PNG export via print() (replaces saveas)
%
% Target: e-bike hysteresis publication (Feldmann et al.)

clear all; close all; clc;

%% ========================================================================
%  Configuration
%  ========================================================================
basePath = pwd;

% File prefixes
prefix_pulsed = 'Feldmann_aufmagnetisiert_';
prefix_used   = 'Feldmann2_';
suffix        = '.txt';

numMagnets = 14;
imgSize    = [1280 1280];

% Data columns
col_X    = 3;
col_Y    = 4;
col_Btot = 12;

% Colormap
cmap = jet(256);

% Output
outDir = fullfile(basePath, 'diff_analysis');
if ~exist(outDir, 'dir'), mkdir(outDir); end

%% ========================================================================
%  Publication style - single source of truth
%  ========================================================================
PUB.font        = 'Times New Roman';
PUB.fsAxis      = 15;   % axis labels
PUB.fsTick      = 12;   % tick labels
PUB.fsTitle     = 13;   % subplot titles in dense grids (2 x 7)
PUB.fsTitleBig  = 16;   % titles on single-axes figures (fig 4, fig 5)
PUB.fsLegend    = 12;
PUB.fsCbar      = 15;
PUB.fsCbarTick  = 13;
PUB.fsSupTitle  = 18;   % overall figure title
PUB.fsBarLabel  = 11;   % value labels on top of bars
PUB.lwData      = 1.8;
PUB.lwAux       = 1.5;
PUB.lwRefLine   = 1.8;  % reference lines (mean, zero)
PUB.lwGrid      = 0.8;

set(groot, 'defaultAxesFontName',  PUB.font);
set(groot, 'defaultTextFontName',  PUB.font);
set(groot, 'defaultAxesFontSize',  PUB.fsTick);
set(groot, 'defaultAxesLineWidth', 1.0);
set(groot, 'defaultAxesTickDir',   'out');
set(groot, 'defaultAxesBox',       'on');

% Helper - export figure at 300 DPI
exportFig = @(figHandle, fname) print(figHandle, ...
    fullfile(outDir, fname), '-dpng', '-r300');

%% ========================================================================
%  Load All Data and Build Field Maps (in mT)
%  ========================================================================
fprintf('=== Loading Helmholtz Scan Data ===\n\n');

maps_pulsed = cell(1, numMagnets);
maps_used   = cell(1, numMagnets);

for n = 1:numMagnets
    file_p = fullfile(basePath, [prefix_pulsed num2str(n) suffix]);
    if isfile(file_p)
        maps_pulsed{n} = loadFieldMap(file_p, col_X, col_Y, col_Btot, imgSize);
        fprintf('  Loaded: %s%d (pulsed)\n', prefix_pulsed, n);
    else
        warning('File not found: %s', file_p);
    end

    file_u = fullfile(basePath, [prefix_used num2str(n) suffix]);
    if isfile(file_u)
        maps_used{n} = loadFieldMap(file_u, col_X, col_Y, col_Btot, imgSize);
        fprintf('  Loaded: %s%d (used)\n', prefix_used, n);
    else
        warning('File not found: %s', file_u);
    end
end

%% ========================================================================
%  Compute Differences in mT
%  ========================================================================
fprintf('\n=== Computing Differences (Pulsed - Used) ===\n\n');

diff_maps = cell(1, numMagnets);
stats = struct('mean_diff', {}, 'std_diff', {}, 'max_diff', {}, 'median_diff', {});

for n = 1:numMagnets
    if ~isempty(maps_pulsed{n}) && ~isempty(maps_used{n})
        diff_maps{n} = maps_pulsed{n} - maps_used{n};

        vals = diff_maps{n}(:);
        vals = vals(vals ~= 0);  % Exclude background

        stats(n).mean_diff   = mean(vals);
        stats(n).std_diff    = std(vals);
        stats(n).max_diff    = max(abs(vals));
        stats(n).median_diff = median(vals);

        fprintf('  Magnet %2d: Mean = %+7.2f mT | Std = %.2f mT | Max = %.2f mT\n', ...
                n, stats(n).mean_diff, stats(n).std_diff, stats(n).max_diff);
    end
end

%% ========================================================================
%  Figure 1: Color Difference Images
%  ========================================================================
fprintf('\n=== Generating Difference Images ===\n');

fig1 = figure('Name', 'Magnetic Field Difference (Pulsed - Used)', ...
              'Position', [50 50 1800 720], 'Color', 'w');

nCols = 7;
nRows = ceil(numMagnets / nCols);

% Find global color limits for consistent scaling
allDiffVals = [];
for n = 1:numMagnets
    if ~isempty(diff_maps{n})
        vals = diff_maps{n}(:);
        allDiffVals = [allDiffVals; vals(vals ~= 0)];
    end
end
globalMax = max(abs(allDiffVals));

for n = 1:numMagnets
    if isempty(diff_maps{n}), continue; end

    subplot(nRows, nCols, n);
    imagesc(diff_maps{n});
    colormap(gca, cmap);
    caxis([-globalMax globalMax]);
    axis image off;
    title(sprintf('Magnet %d   \\Delta = %+.1f mT', n, stats(n).mean_diff), ...
          'FontSize', PUB.fsTitle, 'FontName', PUB.font, 'FontWeight', 'bold');
end

cb = colorbar('Position', [0.93 0.15 0.018 0.72]);
cb.Label.String     = '\DeltaB_{tot}  [mT]';
cb.Label.FontSize   = PUB.fsCbar;
cb.Label.FontWeight = 'bold';
cb.FontSize         = PUB.fsCbarTick;

sgtitle('Magnetic field difference: pulsed − used   (\DeltaB_{tot} in mT)', ...
        'FontSize', PUB.fsSupTitle, 'FontWeight', 'bold', 'FontName', PUB.font);

exportFig(fig1, 'diff_images_all.png');

%% ========================================================================
%  Figure 2: RGB Color Difference (from raw images)
%  ========================================================================
fprintf('=== Generating RGB Color Difference Images ===\n');

fig2 = figure('Name', 'RGB Color Difference', ...
              'Position', [50 50 1800 720], 'Color', 'w');

rawDir_pulsed = fullfile(basePath, 'images_pulsed_raw');
rawDir_used   = fullfile(basePath, 'images_used_raw');

for n = 1:numMagnets
    file_p = fullfile(rawDir_pulsed, sprintf('P%d.png', n));
    file_u = fullfile(rawDir_used, sprintf('Pa%d.png', n));

    if ~isfile(file_p) || ~isfile(file_u), continue; end

    img_p = im2double(imread(file_p));
    img_u = im2double(imread(file_u));

    if ~isequal(size(img_p), size(img_u))
        img_u = imresize(img_u, [size(img_p,1) size(img_p,2)]);
    end

    diff_rgb = abs(img_p - img_u);

    % Normalize each channel for visibility
    for ch = 1:3
        chData = diff_rgb(:,:,ch);
        chMin = min(chData(:));
        chMax = max(chData(:));
        if chMax > chMin
            diff_rgb(:,:,ch) = (chData - chMin) / (chMax - chMin);
        end
    end

    subplot(nRows, nCols, n);
    imshow(diff_rgb);
    title(sprintf('Magnet %d', n), ...
          'FontSize', PUB.fsTitle, 'FontName', PUB.font, 'FontWeight', 'bold');

    % Save individual difference image
    imwrite(diff_rgb, fullfile(outDir, sprintf('diff_rgb_%d.png', n)));
end

sgtitle('RGB colour difference  |pulsed − used|', ...
        'FontSize', PUB.fsSupTitle, 'FontWeight', 'bold', 'FontName', PUB.font);

exportFig(fig2, 'diff_rgb_all.png');

%% ========================================================================
%  Figure 3: Histogram Analysis per Magnet (in mT)
%  ========================================================================
fprintf('=== Generating Histograms ===\n');

fig3 = figure('Name', 'Degradation Histograms (mT)', ...
              'Position', [50 50 1800 1000], 'Color', 'w');

edges   = linspace(-globalMax, globalMax, 200);
centers = (edges(1:end-1) + edges(2:end)) / 2;

colors = lines(numMagnets);

for n = 1:numMagnets
    if isempty(diff_maps{n}), continue; end

    subplot(nRows, nCols, n);

    vals = diff_maps{n}(:);
    vals = vals(vals ~= 0);

    histogram(vals, edges, 'Normalization', 'probability', ...
              'FaceColor', colors(n,:), 'FaceAlpha', 0.75, 'EdgeColor', 'none');
    hold on;
    xline(mean(vals), 'r--', 'LineWidth', PUB.lwRefLine);
    xline(0, 'k-', 'LineWidth', PUB.lwAux);
    hold off;

    % Labels: only on outer-edge subplots to reduce clutter, larger sizes
    [row, col] = ind2sub([nRows, nCols], n);
    if row == nRows
        xlabel('\DeltaB_{tot}  [mT]', 'FontSize', PUB.fsAxis - 2, ...
               'FontWeight', 'bold');
    else
        xlabel('');
    end
    if col == 1
        ylabel('Probability', 'FontSize', PUB.fsAxis - 2, 'FontWeight', 'bold');
    else
        ylabel('');
    end

    title(sprintf('Magnet %d   \\mu = %.1f mT', n, mean(vals)), ...
          'FontSize', PUB.fsTitle, 'FontWeight', 'bold');
    set(gca, 'FontSize', PUB.fsTick - 1);
    grid on;
end

sgtitle(['Degradation histogram per magnet   ', ...
         '(\DeltaB_{tot} = B_{pulsed} − B_{used})  [mT]'], ...
        'FontSize', PUB.fsSupTitle, 'FontWeight', 'bold', 'FontName', PUB.font);

exportFig(fig3, 'histograms_per_magnet.png');

%% ========================================================================
%  Figure 4: Overlay Histogram — All Magnets Combined
%  ========================================================================
fig4 = figure('Name', 'Combined Degradation Histogram', ...
              'Position', [50 50 1400 800], 'Color', 'w');

legendEntries = {};
hold on;

for n = 1:numMagnets
    if isempty(diff_maps{n}), continue; end

    vals = diff_maps{n}(:);
    vals = vals(vals ~= 0);

    counts = histcounts(vals, edges, 'Normalization', 'probability');
    plot(centers, counts, 'Color', colors(n,:), 'LineWidth', PUB.lwData);

    legendEntries{end+1} = sprintf('Magnet %d  (\\mu = %.1f mT)', n, mean(vals));
end

xline(0, 'k--', 'LineWidth', PUB.lwAux);
hold off;

xlabel('\DeltaB_{tot}  [mT]',  'FontSize', PUB.fsAxis, 'FontWeight', 'bold');
ylabel('Probability',          'FontSize', PUB.fsAxis, 'FontWeight', 'bold');
title(['Degradation distribution — all magnets   ', ...
       '(\DeltaB_{tot} = B_{pulsed} − B_{used})'], ...
      'FontSize', PUB.fsTitleBig, 'FontWeight', 'bold');
lg = legend(legendEntries, 'Location', 'eastoutside', ...
            'FontSize', PUB.fsLegend, 'FontName', PUB.font);
lg.Box = 'on';
grid on;
set(gca, 'FontSize', PUB.fsTick);

exportFig(fig4, 'histogram_overlay_all.png');

%% ========================================================================
%  Figure 5: Summary Bar Chart — Degradation Ranking
%  ========================================================================
fig5 = figure('Name', 'Degradation Ranking', ...
              'Position', [50 50 1500 700], 'Color', 'w');

meanDiffs = arrayfun(@(s) s.mean_diff, stats);
stdDiffs  = arrayfun(@(s) s.std_diff,  stats);

[~, sortIdx] = sort(abs(meanDiffs), 'descend');

% Colour gradient: red (worst) -> green (best)
barColors = zeros(numMagnets, 3);
for i = 1:numMagnets
    ratio = (i-1) / (numMagnets-1);
    barColors(i,:) = [1-ratio, ratio, 0.2];
end

b = bar(1:numMagnets, abs(meanDiffs(sortIdx)));
b.FaceColor = 'flat';
b.CData = barColors;
b.EdgeColor = [0.2 0.2 0.2];
b.LineWidth = 0.8;

hold on;
errorbar(1:numMagnets, abs(meanDiffs(sortIdx)), stdDiffs(sortIdx), ...
         'k.', 'LineWidth', PUB.lwAux, 'CapSize', 8);
hold off;

set(gca, 'XTick', 1:numMagnets);
set(gca, 'XTickLabel', arrayfun(@(x) sprintf('M%d', x), sortIdx, ...
    'UniformOutput', false));
xtickangle(0);

xlabel('Magnet (sorted by degradation)', ...
       'FontSize', PUB.fsAxis, 'FontWeight', 'bold');
ylabel('|Mean \DeltaB_{tot}|   [mT]', ...
       'FontSize', PUB.fsAxis, 'FontWeight', 'bold');
title('Magnet degradation ranking (largest \rightarrow smallest)', ...
      'FontSize', PUB.fsTitleBig, 'FontWeight', 'bold');
grid on;
set(gca, 'FontSize', PUB.fsTick);

% mT value labels on top of bars
yLimits = ylim;
labelOffset = 0.02 * (yLimits(2) - yLimits(1));
for i = 1:numMagnets
    text(i, abs(meanDiffs(sortIdx(i))) + stdDiffs(sortIdx(i)) + labelOffset, ...
         sprintf('%.1f', abs(meanDiffs(sortIdx(i)))), ...
         'HorizontalAlignment', 'center', ...
         'FontSize', PUB.fsBarLabel, 'FontWeight', 'bold', ...
         'FontName', PUB.font);
end

% Extend y-axis a bit so top labels are not clipped
ylim([0, max(abs(meanDiffs) + stdDiffs) * 1.15]);

exportFig(fig5, 'degradation_ranking.png');

%% ========================================================================
%  Console Summary
%  ========================================================================
fprintf('\n=== Degradation Summary (sorted by severity) ===\n');
fprintf('%-12s %-16s %-16s %-16s %-16s\n', ...
        'Magnet', 'Mean [mT]', 'Median [mT]', 'Std [mT]', 'Max |Diff| [mT]');
fprintf('%s\n', repmat('-', 1, 76));
for i = 1:numMagnets
    idx = sortIdx(i);
    fprintf('Magnet %-4d  %+12.2f     %+12.2f     %12.2f     %12.2f\n', ...
            idx, stats(idx).mean_diff, stats(idx).median_diff, ...
            stats(idx).std_diff, stats(idx).max_diff);
end

fprintf('\nAll results saved to: %s\n', outDir);

%% ========================================================================
%  Restore graphics defaults
%  ========================================================================
set(groot, 'defaultAxesFontName',  'remove');
set(groot, 'defaultTextFontName',  'remove');
set(groot, 'defaultAxesFontSize',  'remove');
set(groot, 'defaultAxesLineWidth', 'remove');
set(groot, 'defaultAxesTickDir',   'remove');
set(groot, 'defaultAxesBox',       'remove');

%% ========================================================================
%  Helper Function: Load Field Map from .txt
%  ========================================================================
function fieldMap = loadFieldMap(filename, col_X, col_Y, col_Btot, imgSize)
    data = readmatrix(filename);

    X    = data(:, col_X);
    Y    = data(:, col_Y);
    Btot = data(:, col_Btot);

    % Clean NaN and zero
    valid = ~isnan(X) & ~isnan(Y) & ~isnan(Btot) & (X~=0) & (Y~=0) & (Btot~=0);
    X    = X(valid);
    Y    = Y(valid);
    Btot = Btot(valid);

    % Shift to start at 1 and scale
    X_s = round((X - min(X) + 1) * 10);
    Y_s = round((Y - min(Y) + 1) * 10);

    % Build matrix with actual mT values
    fieldMap = zeros(max(X_s), max(Y_s));
    for i = 1:length(X_s)
        fieldMap(X_s(i), Y_s(i)) = Btot(i);
    end

    % Remove empty rows/cols
    fieldMap = fieldMap(any(fieldMap ~= 0, 2), any(fieldMap ~= 0, 1));

    % Resize
    fieldMap = imresize(fieldMap, imgSize);
end
