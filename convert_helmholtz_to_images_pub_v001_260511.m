%  PROJECT
%  -------
%  Supplementary material to:
%      Feldmann, S. et al. (2026). "<Non-Destructive Quality Assessment of Permanent Magnets in
%      Pedelec Drive Systems via Magnetic Field Mapping and Support
%      Vector Machine Classification>",
%      Springer Nature, Vol(Issue), pp. xxx-xxx. DOI: 10.xxxx/xxxxx
%  Repository: https://github.com/<USERNAME>/BioBike
%% convert_helmholtz_to_images.m  (Publication-ready v3 - oversize fonts)
% Converts Helmholtz scan .txt files (one per magnet) into PNG images,
% with and without axes/colorbar. Also builds overview figures.
%
% v3 readability pass (focus: individual *_axes PNGs):
%   - Axis labels, tick numbers and colorbar text scaled to ~34/30 pt
%   - Smaller figure (1100x1000) so the text occupies a larger fraction
%     of the rendered image - this is what makes the labels look big
%     when the PNG is viewed or pasted into a manuscript at any size
%   - Tick numbers given a small white halo via background patch so
%     they remain readable across the full jet colour range
%
% Target: e-bike hysteresis publication (Feldmann et al.)

clear all; close all; clc;

%% ========================================================================
%  Configuration
%  ========================================================================
basePath = pwd;

prefix_pulsed = 'Feldmann_aufmagnetisiert_';
suffix        = '.txt';
prefix_used   = 'Feldmann2_';

numMagnets = 14;
imgSize    = [1280 1280];

outDir_pulsed_axes = fullfile(basePath, 'images_pulsed_axes');
outDir_pulsed_raw  = fullfile(basePath, 'images_pulsed_raw');
outDir_used_axes   = fullfile(basePath, 'images_used_axes');
outDir_used_raw    = fullfile(basePath, 'images_used_raw');

dirs = {outDir_pulsed_axes, outDir_pulsed_raw, outDir_used_axes, outDir_used_raw};
for d = 1:length(dirs)
    if ~exist(dirs{d}, 'dir')
        mkdir(dirs{d});
    end
end

col_X    = 3;
col_Y    = 4;
col_Btot = 12;

cmap = jet(256);

%% ========================================================================
%  Publication style - OVERSIZE for journal column reduction
%  ========================================================================
% Sizes are intentionally bigger than the eye expects on screen: the
% saved PNG is 300 DPI and will typically be reduced to column width in
% the manuscript. After reduction the labels still need to be readable.
PUB.font          = 'Times New Roman';
PUB.fsAxis        = 34;   % axis labels    (was 26)
PUB.fsTick        = 30;   % tick numbers   (was 22)
PUB.fsTitle       = 32;   % image title    (was 26)
PUB.fsCbar        = 34;   % colorbar label (was 26)
PUB.fsCbarTick    = 30;   % colorbar ticks (was 22)
PUB.fsOverviewT   = 26;   % subplot titles (overview grids)
PUB.fsSupTitle    = 36;   % overall figure title
PUB.lwAxes        = 2.0;  % axes border line width

set(groot, 'defaultAxesFontName',   PUB.font);
set(groot, 'defaultTextFontName',   PUB.font);
set(groot, 'defaultAxesFontSize',   PUB.fsTick);
set(groot, 'defaultAxesFontWeight', 'bold');
set(groot, 'defaultAxesLineWidth',  PUB.lwAxes);
set(groot, 'defaultAxesTickDir',    'out');
set(groot, 'defaultAxesBox',        'on');

%% ========================================================================
%  Process Both Sets
%  ========================================================================
sets = {
    prefix_pulsed, outDir_pulsed_axes, outDir_pulsed_raw, 'P',  'pulsed';
    prefix_used,   outDir_used_axes,   outDir_used_raw,   'Pa', 'used'
};

for s = 1:size(sets, 1)
    prefix     = sets{s, 1};
    dirAxes    = sets{s, 2};
    dirRaw     = sets{s, 3};
    imgPrefix  = sets{s, 4};
    setLabel   = sets{s, 5};

    fprintf('\n=== Processing Set: %s (1-%d) ===\n', prefix, numMagnets);

    for n = 1:numMagnets
        filename = fullfile(basePath, [prefix num2str(n) suffix]);

        if ~isfile(filename)
            warning('File not found: %s - skipping.', filename);
            continue;
        end

        fprintf('  [%2d/%d] %s\n', n, numMagnets, [prefix num2str(n) suffix]);

        %% --- Load Data ---
        data = readmatrix(filename);

        X    = data(:, col_X);
        Y    = data(:, col_Y);
        Btot = data(:, col_Btot);

        %% --- Clean Data ---
        validIdx = ~isnan(X) & ~isnan(Y) & ~isnan(Btot);
        X    = X(validIdx);
        Y    = Y(validIdx);
        Btot = Btot(validIdx);

        nonZero = (X ~= 0) & (Y ~= 0) & (Btot ~= 0);
        X    = X(nonZero);
        Y    = Y(nonZero);
        Btot = Btot(nonZero);

        %% --- Build Image Matrix ---
        X_shifted = X - min(X) + 1;
        Y_shifted = Y - min(Y) + 1;

        X_scaled = round(X_shifted * 10);
        Y_scaled = round(Y_shifted * 10);

        imgMatrix = zeros(max(X_scaled), max(Y_scaled));
        for i = 1:length(X_scaled)
            imgMatrix(X_scaled(i), Y_scaled(i)) = Btot(i);
        end

        rowsToKeep = any(imgMatrix ~= 0, 2);
        colsToKeep = any(imgMatrix ~= 0, 1);
        imgMatrix = imgMatrix(rowsToKeep, colsToKeep);

        imgMatrix = imresize(imgMatrix, imgSize);

        %% --- Save WITH Axes and Colorbar (publication-styled) ---
        % Smaller figure + generous axes Position. The big margins on left
        % and right are NEEDED for the 34pt axis label and 30pt tick numbers.
        fig = figure('Visible', 'off', ...
                     'Position', [100 100 1100 1000], 'Color', 'w');

        ax = axes('Position', [0.19, 0.16, 0.58, 0.72]);
        imagesc(ax, imgMatrix);
        colormap(ax, cmap);
        axis(ax, 'image');

        cb = colorbar(ax);
        cb.Position         = [0.81, 0.16, 0.055, 0.72];
        cb.Label.String     = 'B_{tot}  [mT]';
        cb.Label.FontSize   = PUB.fsCbar;
        cb.Label.FontWeight = 'bold';
        cb.Label.FontName   = PUB.font;
        cb.FontSize         = PUB.fsCbarTick;
        cb.FontWeight       = 'bold';
        cb.LineWidth        = PUB.lwAxes;

        xlabel(ax, 'Y  [pixel]', ...
            'FontSize', PUB.fsAxis, 'FontWeight', 'bold', 'FontName', PUB.font);
        ylabel(ax, 'X  [pixel]', ...
            'FontSize', PUB.fsAxis, 'FontWeight', 'bold', 'FontName', PUB.font);
        title(ax, sprintf('%s magnet %s%d', setLabel, imgPrefix, n), ...
              'FontSize', PUB.fsTitle, 'FontWeight', 'bold', 'FontName', PUB.font);

        set(ax, 'FontSize', PUB.fsTick, 'FontName', PUB.font, ...
                'FontWeight', 'bold', 'LineWidth', PUB.lwAxes);

        % Fewer tick marks so the big numbers do not overlap each other
        ax.XAxis.TickValues = linspace(0, imgSize(2), 5);
        ax.YAxis.TickValues = linspace(0, imgSize(1), 5);

        print(fig, fullfile(dirAxes, sprintf('%s%d.png', imgPrefix, n)), ...
              '-dpng', '-r300');
        close(fig);

        %% --- Save WITHOUT Axes (raw image, unchanged) ---
        minVal = min(imgMatrix(:));
        maxVal = max(imgMatrix(:));

        if maxVal > minVal
            normalized = (imgMatrix - minVal) / (maxVal - minVal);
        else
            normalized = zeros(size(imgMatrix));
        end

        indexImg = round(normalized * (size(cmap, 1) - 1)) + 1;
        indexImg = max(1, min(indexImg, size(cmap, 1)));
        rgbImg   = ind2rgb(indexImg, cmap);

        imwrite(rgbImg, fullfile(dirRaw, sprintf('%s%d.png', imgPrefix, n)));

        fprintf('    -> Saved: %s%d.png (with & without axes)\n', imgPrefix, n);
    end
end

%% ========================================================================
%  Summary Overview Figures
%  ========================================================================
fprintf('\n=== Generating Overview Figures ===\n');

nCols = 7;
nRows = ceil(numMagnets / nCols);

for s = 1:size(sets, 1)
    prefix    = sets{s, 1};
    dirRaw    = sets{s, 3};
    imgPrefix = sets{s, 4};

    fig = figure('Name', sprintf('Overview: %s', prefix), ...
                 'Position', [50 50 2400 1000], 'Color', 'w');

    for n = 1:numMagnets
        imgFile = fullfile(dirRaw, sprintf('%s%d.png', imgPrefix, n));
        if ~isfile(imgFile)
            continue;
        end

        subplot(nRows, nCols, n);
        img = imread(imgFile);
        imshow(img);
        title(sprintf('%s%d', imgPrefix, n), ...
              'FontSize', PUB.fsOverviewT, 'FontWeight', 'bold', ...
              'FontName', PUB.font);
    end

    if s == 1
        sgtitle('Overview: pulsed (re-magnetised) magnets', ...
                'FontSize', PUB.fsSupTitle, 'FontWeight', 'bold', ...
                'FontName', PUB.font);
        print(fig, fullfile(basePath, 'overview_pulsed.png'), '-dpng', '-r300');
    else
        sgtitle('Overview: used (in-service) magnets', ...
                'FontSize', PUB.fsSupTitle, 'FontWeight', 'bold', ...
                'FontName', PUB.font);
        print(fig, fullfile(basePath, 'overview_used.png'), '-dpng', '-r300');
    end
end

%% ========================================================================
%  Restore graphics defaults
%  ========================================================================
set(groot, 'defaultAxesFontName',   'remove');
set(groot, 'defaultTextFontName',   'remove');
set(groot, 'defaultAxesFontSize',   'remove');
set(groot, 'defaultAxesFontWeight', 'remove');
set(groot, 'defaultAxesLineWidth',  'remove');
set(groot, 'defaultAxesTickDir',    'remove');
set(groot, 'defaultAxesBox',        'remove');

fprintf('\n=== Done ===\n');
fprintf('Output folders:\n');
fprintf('  With axes (pulsed): %s\n', outDir_pulsed_axes);
fprintf('  Raw       (pulsed): %s\n', outDir_pulsed_raw);
fprintf('  With axes (used):   %s\n', outDir_used_axes);
fprintf('  Raw       (used):   %s\n', outDir_used_raw);
fprintf('\n');
