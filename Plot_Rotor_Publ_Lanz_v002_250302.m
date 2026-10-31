%  PROJECT
%  -------
%  Supplementary material to:
%      Feldmann, S., Lanz, M., Wiedenmann, M. (2026). "Non-Destructive Quality Assessment of Permanent Magnets in
%      Pedelec Drive Systems via Magnetic Field Mapping and Support
%      Vector Machine Classification",
%      submitted 2026. DOI: to be added after acceptance
%  Repository: https://github.com/Prof-Feldmann/BioBike

%% rotor_slice_visualization.m
% Publication-quality visualization of Rotor_slice.txt
% Diameter-mode Helmholtz scan: Full 360-degree rotor magnetic field
% SENIS MMS-1A-RS, 0.1 deg angular resolution, 13 axial slices
%
% Author: Generated for Feldmann et al. publication
% Date: 2025

clear; close all; clc;

%% ========== 1. LOAD DATA ==========
fprintf('Loading Rotor_slice.txt ...\n');

% Read the file - skip header lines
fid = fopen('Rotor_slice.txt', 'r');
if fid == -1
    % Try alternative paths
    fid = fopen('1772460623347_Rotor_slice.txt', 'r');
end
if fid == -1
    error('Cannot find Rotor_slice.txt. Place file in current directory.');
end

% Skip header lines until we find the data
headerLines = 0;
while ~feof(fid)
    line = fgetl(fid);
    headerLines = headerLines + 1;
    % Data starts after the second row of asterisks + column headers + blank
    if contains(line, 'Slice') && contains(line, 'Btot')
        fgetl(fid); % skip units/blank line
        headerLines = headerLines + 1;
        break;
    end
end
fclose(fid);

% Read numeric data
% Columns: 1=Slice, 2=Line, 3=X, 4=Y, 5=Z, 6=Rotation[deg],
%           7=Bx, 8=By, 9=Bz, 10=RotEnc, 11=Bxy, 12=Btot,
%           13=AngleError, 14=Direction, 15=R, 16=Z, 17=Theta, 18=ProbeTemp
opts = detectImportOptions('Rotor_slice.txt', 'FileType', 'text');
opts.DataLines = [headerLines+1, Inf];
opts.Delimiter = '\t';
opts.ExtraColumnsRule = 'ignore';
opts.EmptyLineRule = 'skip';

% Manual read for robustness
rawData = [];
fid = fopen('Rotor_slice.txt', 'r');
for i = 1:headerLines
    fgetl(fid);
end
while ~feof(fid)
    line = fgetl(fid);
    if ischar(line) && ~isempty(strtrim(line)) && ~contains(line, '***')
        vals = str2double(strsplit(strtrim(line), '\t'));
        if length(vals) >= 12 && ~isnan(vals(1))
            rawData = [rawData; vals(1:min(18,length(vals)))];
        end
    end
end
fclose(fid);

fprintf('Loaded %d data points\n', size(rawData, 1));

% Extract key columns
sliceNum    = rawData(:, 1);   % Slice number (1-13)
rotation    = rawData(:, 6);   % Rotation angle [deg]
Bx          = rawData(:, 7);   % Bx [mT]
By          = rawData(:, 8);   % By [mT]
Bz          = rawData(:, 9);   % Bz [mT]
Btot        = rawData(:, 12);  % Btot [mT]
Z_mm        = rawData(:, 16);  % Z position [mm]

%% ========== 2. BUILD 2D MATRICES ==========
uniqueSlices = unique(sliceNum);
uniqueZ      = unique(Z_mm);
nSlices      = length(uniqueSlices);

% Get rotation angles from first slice
idx1 = (sliceNum == uniqueSlices(1));
rotAngles = rotation(idx1);
nAngles = length(rotAngles);

fprintf('Slices: %d, Angular points per slice: %d\n', nSlices, nAngles);
fprintf('Z range: %.1f to %.1f mm\n', min(Z_mm), max(Z_mm));
fprintf('Btot range: %.1f to %.1f mT\n', min(Btot), max(Btot));

% Build 2D matrix: rows = Z slices, cols = rotation angles
BtotMatrix = NaN(nSlices, nAngles);
BxyMatrix  = NaN(nSlices, nAngles);

for s = 1:nSlices
    idx = (sliceNum == uniqueSlices(s));
    bVals = Btot(idx);
    if length(bVals) == nAngles
        BtotMatrix(s, :) = bVals;
    else
        % Handle unequal lengths - interpolate
        rVals = rotation(idx);
        BtotMatrix(s, :) = interp1(rVals, bVals, rotAngles, 'linear', 'extrap');
    end
end

%% ========== 3. FIGURE 1: UNWRAPPED HEATMAP (Publication Main Figure) ==========
fig1 = figure('Position', [50, 50, 1200, 500], 'Color', 'w');

% --- Panel (a): Btot heatmap ---
ax1 = axes('Position', [0.06, 0.15, 0.58, 0.78]);
imagesc(rotAngles, uniqueZ, BtotMatrix);
set(gca, 'YDir', 'normal');
xlabel('Rotation Angle [deg]', 'FontSize', 12, 'FontName', 'Times New Roman');
ylabel('Axial Position Z [mm]', 'FontSize', 12, 'FontName', 'Times New Roman');
title('(a)  Rotor Magnetic Field Distribution  B_{tot} [mT]', ...
      'FontSize', 13, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
colormap(ax1, jet(256));
cb = colorbar;
cb.Label.String = 'B_{tot} [mT]';
cb.Label.FontSize = 11;
cb.Label.FontName = 'Times New Roman';
set(gca, 'FontSize', 10, 'FontName', 'Times New Roman');
set(gca, 'XTick', 0:30:360);
xlim([0 360]);

% Add magnet boundary annotations (14 magnets over 360 deg ~ 25.7 deg each)
magnetWidth = 360 / 14;  % ~25.71 deg
hold on;
for m = 1:14
    xPos = (m - 0.5) * magnetWidth;
    % Light dashed lines at magnet boundaries
    if m < 14
        xline(m * magnetWidth, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.5, 'Alpha', 0.5);
    end
end
hold off;

% --- Panel (b): Btot profile at mid-slice ---
ax2 = axes('Position', [0.72, 0.15, 0.25, 0.78]);
midSlice = round(nSlices / 2);
plot(rotAngles, BtotMatrix(midSlice, :), 'b-', 'LineWidth', 1.2);
hold on;
% Plot envelope
topSlice = BtotMatrix(1, :);
botSlice = BtotMatrix(end, :);
plot(rotAngles, topSlice, 'r--', 'LineWidth', 0.8);
plot(rotAngles, botSlice, 'g--', 'LineWidth', 0.8);
hold off;
xlabel('Rotation Angle [deg]', 'FontSize', 12, 'FontName', 'Times New Roman');
ylabel('B_{tot} [mT]', 'FontSize', 12, 'FontName', 'Times New Roman');
title('(b)  Circumferential Profile', 'FontSize', 13, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
legend({sprintf('Z = %.1f mm (center)', uniqueZ(midSlice)), ...
        sprintf('Z = %.1f mm (edge)', uniqueZ(1)), ...
        sprintf('Z = %.1f mm (edge)', uniqueZ(end))}, ...
       'FontSize', 8, 'Location', 'southwest');
set(gca, 'FontSize', 10, 'FontName', 'Times New Roman');
xlim([0 360]);
set(gca, 'XTick', 0:60:360);
grid on;
grid minor;

% Save
print(fig1, 'Fig_Rotor_FieldMap_Unwrapped.png', '-dpng', '-r300');
fprintf('Saved: Fig_Rotor_FieldMap_Unwrapped.png\n');

%% ========== 4. FIGURE 2: POLAR PLOT (Cross-Section View) ==========
fig2 = figure('Position', [50, 50, 800, 700], 'Color', 'w');

% Use mid-slice for polar plot
theta_rad = deg2rad(rotAngles);

% Create polar color plot
ax3 = polaraxes('Position', [0.1, 0.1, 0.75, 0.8]);

% Build a mesh for polar plot: radius = constant (rotor surface), 
% but use color to show Btot variation
% Create annular ring for each Z-slice
R_inner = 18;  % mm (visual)
R_outer = 24;  % mm (visual)
R_range = linspace(R_inner, R_outer, nSlices);

% Use standard axes for full control
delete(ax3);
ax3 = axes('Position', [0.08, 0.08, 0.78, 0.85]);

% Create mesh in Cartesian
[THETA, R] = meshgrid(theta_rad, R_range);
X = R .* cos(THETA);
Y = R .* sin(THETA);

% Plot
pcolor(ax3, X, Y, BtotMatrix);
shading interp;
colormap(ax3, jet(256));
cb2 = colorbar;
cb2.Label.String = 'B_{tot} [mT]';
cb2.Label.FontSize = 12;
cb2.Label.FontName = 'Times New Roman';
axis equal;
hold on;

% Draw inner and outer circles
th = linspace(0, 2*pi, 500);
plot(R_inner * cos(th), R_inner * sin(th), 'k-', 'LineWidth', 1.5);
plot(R_outer * cos(th), R_outer * sin(th), 'k-', 'LineWidth', 1.5);

% Add angle labels
for a = 0:30:330
    xEnd = (R_outer + 1.5) * cosd(a);
    yEnd = (R_outer + 1.5) * sind(a);
    text(xEnd, yEnd, sprintf('%d°', a), 'FontSize', 9, ...
         'HorizontalAlignment', 'center', 'FontName', 'Times New Roman');
end

% Draw radial lines for magnet boundaries
for m = 0:13
    angle = m * magnetWidth;
    xL = [R_inner * cosd(angle), R_outer * cosd(angle)];
    yL = [R_inner * sind(angle), R_outer * sind(angle)];
    plot(xL, yL, 'k-', 'LineWidth', 0.5);
end

% Add magnet numbers
for m = 1:14
    angle = (m - 0.5) * magnetWidth;
    xM = (R_inner - 2) * cosd(angle);
    yM = (R_inner - 2) * sind(angle);
    text(xM, yM, sprintf('M%d', m), 'FontSize', 7, ...
         'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
         'FontName', 'Times New Roman', 'Color', [0.3 0.3 0.3]);
end

hold off;
set(ax3, 'XTick', [], 'YTick', []);
xlim([-28 28]); ylim([-28 28]);

title('Rotor Cross-Section: Magnetic Field Distribution  B_{tot} [mT]', ...
      'FontSize', 13, 'FontName', 'Times New Roman', 'FontWeight', 'bold');

% Annotation: Z range
annotation('textbox', [0.02, 0.01, 0.5, 0.04], ...
    'String', sprintf('Radial axis represents axial position Z = %.1f to %.1f mm (inner to outer)', ...
    uniqueZ(1), uniqueZ(end)), ...
    'FontSize', 8, 'FontName', 'Times New Roman', 'EdgeColor', 'none');

% Save
print(fig2, 'Fig_Rotor_PolarView.png', '-dpng', '-r300');
fprintf('Saved: Fig_Rotor_PolarView.png\n');

%% ========== 5. FIGURE 3: COMBINED PUBLICATION FIGURE ==========
fig3 = figure('Position', [50, 50, 1400, 950], 'Color', 'w');

% --- (a) Unwrapped heatmap - full width top ---
%   Lowered top edge and reduced height to leave room above for labels
ax_a = axes('Position', [0.06, 0.58, 0.86, 0.32]);
imagesc(rotAngles, uniqueZ, BtotMatrix);
set(gca, 'YDir', 'normal');
xlabel('Rotation Angle \theta [deg]', 'FontSize', 12, 'FontName', 'Times New Roman');
ylabel('Axial Position Z [mm]', 'FontSize', 12, 'FontName', 'Times New Roman');
% Title placed inside axes area to avoid collision with suptitle
title('(a)  Unwrapped Rotor Surface — Magnetic Flux Density B_{tot}', ...
      'FontSize', 12, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
colormap(ax_a, jet(256));
cb_a = colorbar;
cb_a.Label.String = 'B_{tot} [mT]';
cb_a.Label.FontSize = 11;
set(gca, 'FontSize', 10, 'FontName', 'Times New Roman');
set(gca, 'XTick', 0:30:360);
xlim([0 360]);

% Magnet boundaries (white dashed lines)
hold on;
for m = 1:13
    xline(m * magnetWidth, '--', 'Color', [1 1 1 0.4], 'LineWidth', 0.5);
end
hold off;

% Magnet labels placed ABOVE the axes via annotation (normalized figure coords)
%   This avoids collision with the title text
axPos = get(ax_a, 'Position');  % [left bottom width height]
for m = 1:14
    xFrac = axPos(1) + axPos(3) * ((m - 0.5) * magnetWidth / 360);
    yFrac = axPos(2) + axPos(4) + 0.005;  % just above the axes top edge
    annotation('textbox', [xFrac - 0.012, yFrac, 0.024, 0.02], ...
        'String', sprintf('M%d', m), 'FontSize', 7, 'FontWeight', 'bold', ...
        'FontName', 'Times New Roman', 'EdgeColor', 'none', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
end

% --- (b) Polar cross-section - bottom left ---
ax_b = axes('Position', [0.04, 0.05, 0.44, 0.44]);
pcolor(ax_b, X, Y, BtotMatrix);
shading interp;
colormap(ax_b, jet(256));
cb_b = colorbar;
cb_b.Label.String = 'B_{tot} [mT]';
cb_b.Label.FontSize = 10;
axis equal;
hold on;
plot(R_inner * cos(th), R_inner * sin(th), 'k-', 'LineWidth', 1.2);
plot(R_outer * cos(th), R_outer * sin(th), 'k-', 'LineWidth', 1.2);
for m = 0:13
    angle = m * magnetWidth;
    plot([R_inner * cosd(angle), R_outer * cosd(angle)], ...
         [R_inner * sind(angle), R_outer * sind(angle)], 'k-', 'LineWidth', 0.5);
end
for a = 0:30:330
    text((R_outer + 1.5) * cosd(a), (R_outer + 1.5) * sind(a), ...
         sprintf('%d°', a), 'FontSize', 8, 'HorizontalAlignment', 'center', ...
         'FontName', 'Times New Roman');
end
for m = 1:14
    angle = (m - 0.5) * magnetWidth;
    text((R_inner - 2) * cosd(angle), (R_inner - 2) * sind(angle), ...
         sprintf('M%d', m), 'FontSize', 6, 'HorizontalAlignment', 'center', ...
         'FontWeight', 'bold', 'FontName', 'Times New Roman', 'Color', [0.3 0.3 0.3]);
end
hold off;
set(ax_b, 'XTick', [], 'YTick', []);
xlim([-28 28]); ylim([-28 28]);
title('(b)  Polar Cross-Section View', 'FontSize', 12, ...
      'FontName', 'Times New Roman', 'FontWeight', 'bold');
annotation('textbox', [0.04, 0.01, 0.44, 0.03], ...
    'String', sprintf('Inner \\rightarrow Outer ring: Z = %.1f to %.1f mm', ...
    uniqueZ(1), uniqueZ(end)), ...
    'FontSize', 8, 'FontName', 'Times New Roman', 'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center');

% --- (c) Circumferential line profiles - bottom right ---
ax_c = axes('Position', [0.56, 0.09, 0.38, 0.38]);
colors = lines(nSlices);
legendEntries = {};
for s = [1, round(nSlices/4), round(nSlices/2), round(3*nSlices/4), nSlices]
    plot(rotAngles, BtotMatrix(s, :), '-', 'LineWidth', 1.0, 'Color', colors(s,:));
    hold on;
    legendEntries{end+1} = sprintf('Z = %.1f mm', uniqueZ(s));
end
hold off;
xlabel('Rotation Angle \theta [deg]', 'FontSize', 12, 'FontName', 'Times New Roman');
ylabel('B_{tot} [mT]', 'FontSize', 12, 'FontName', 'Times New Roman');
title('(c)  Circumferential B_{tot} Profiles', ...
      'FontSize', 12, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
legend(legendEntries, 'FontSize', 8, 'Location', 'southwest', 'FontName', 'Times New Roman');
set(gca, 'FontSize', 10, 'FontName', 'Times New Roman');
xlim([0 360]);
set(gca, 'XTick', 0:60:360);
grid on;

% Overall suptitle — placed at very top with enough spacing
annotation('textbox', [0.0, 0.955, 1.0, 0.04], ...
    'String', 'Rotor Magnetic Field Characterization — daum electronic Impulse2 (SENIS MMS-1A-RS, Diameter Mode, 13 Z-Slices)', ...
    'FontSize', 13, 'FontWeight', 'bold', 'FontName', 'Times New Roman', ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

% Save combined figure
print(fig3, 'Fig_Rotor_Combined.png', '-dpng', '-r300');
fprintf('Saved: Fig_Rotor_Combined.png\n');

%% ========== 6. STATISTICS ==========
fprintf('\n========== ROTOR SCAN STATISTICS ==========\n');
fprintf('Number of slices (Z positions): %d\n', nSlices);
fprintf('Angular resolution: 0.1 deg (3601 points per 360 deg)\n');
fprintf('Z range: %.1f to %.1f mm (axial length: %.1f mm)\n', ...
    min(uniqueZ), max(uniqueZ), max(uniqueZ) - min(uniqueZ));
fprintf('Distance from center: 20.95 mm\n');
fprintf('B_tot range: %.1f to %.1f mT\n', min(Btot), max(Btot));
fprintf('Mean B_tot: %.1f mT\n', mean(Btot));
fprintf('Std B_tot:  %.1f mT\n', std(Btot));

% Per-magnet statistics
fprintf('\n--- Per-Magnet Mean B_tot (mid-slice) ---\n');
midProfile = BtotMatrix(midSlice, :);
for m = 1:14
    angleStart = (m-1) * magnetWidth;
    angleEnd   = m * magnetWidth;
    idx = (rotAngles >= angleStart) & (rotAngles < angleEnd);
    meanB = mean(midProfile(idx));
    fprintf('Magnet %2d: theta = %5.1f-%5.1f deg, mean B_tot = %6.1f mT\n', ...
            m, angleStart, angleEnd, meanB);
end

fprintf('\nDone.\n');
