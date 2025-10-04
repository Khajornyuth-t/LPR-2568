% analyzePlateSize.m
% Script to manually annotate license plates and analyze their true sizes
%
% Purpose: Get ground truth data for plate dimensions from actual images
% Output: Statistics (area, aspect ratio, width, height) for parameter tuning
%
% Usage: Run this script and manually draw rectangles around plates
%        in the displayed images
%
% Author: LPR-2568 Project
% Date: 2025

clear all; 
close all;
clc;

%% Configuration
% Select sample images to annotate (modify as needed)
imageFolder = '../../2.data/images/';

% You can specify specific images or sample randomly
% Option 1: Specific images
imageFiles = {
    'LPR0001.bmp',
    'LPR0010.bmp',
    'LPR0020.bmp',
    'LPR0030.bmp',
    'LPR0040.bmp',
    'LPR0050.bmp',
    'LPR0060.bmp',
    'LPR0070.bmp',
    'LPR0080.bmp',
    'LPR0090.bmp',
    'LPR0100.bmp',
    'LPR0120.bmp',
    'LPR0140.bmp',
    'LPR0160.bmp',
    'LPR0180.bmp',
    'LPR0200.bmp',
    'LPR0220.bmp',
    'LPR0240.bmp'
};

% Option 2: Random sampling (uncomment to use)
% allFiles = dir(fullfile(imageFolder, 'LPR*.bmp'));
% numSamples = 20;
% indices = randperm(length(allFiles), min(numSamples, length(allFiles)));
% imageFiles = {allFiles(indices).name};

fprintf('=== License Plate Size Analyzer ===\n');
fprintf('จำนวนรูปที่จะวิเคราะห์: %d\n\n', length(imageFiles));
fprintf('คำแนะนำ:\n');
fprintf('1. วาดกรอบสี่เหลี่ยมรอบป้ายทะเบียนให้พอดี\n');
fprintf('2. คลิกและลากเพื่อวาดกรอบ\n');
fprintf('3. ปรับขนาดได้โดยลากมุมกรอบ\n');
fprintf('4. กด OK เมื่อพอใจกับตำแหน่งแล้ว\n');
fprintf('5. กด Skip ถ้าต้องการข้ามรูปนี้\n\n');

%% Manual Annotation
plateData = struct('file', {}, 'bbox', {}, 'area', {}, 'aspectRatio', {}, ...
                   'width', {}, 'height', {});
validCount = 0;

for i = 1:length(imageFiles)
    filePath = fullfile(imageFolder, imageFiles{i});
    
    if ~isfile(filePath)
        fprintf('ไม่พบไฟล์: %s (ข้าม)\n', imageFiles{i});
        continue;
    end
    
    try
        img = imread(filePath);
    catch
        fprintf('อ่านไฟล์ไม่สำเร็จ: %s (ข้าม)\n', imageFiles{i});
        continue;
    end
    
    % Display image
    figure(1);
    clf;
    imshow(img);
    title(sprintf('รูปที่ %d/%d: %s - วาดกรอบรอบป้ายทะเบียน', ...
                  i, length(imageFiles), imageFiles{i}));
    
    % Let user draw rectangle
    fprintf('[%d/%d] %s - กำลังรอการวาดกรอบ...\n', i, length(imageFiles), imageFiles{i});
    
    h = drawrectangle('Color', 'r', 'LineWidth', 2);
    
    % Create dialog with OK and Skip buttons
    choice = questdlg('เลือกการดำเนินการ:', ...
                      'Annotation', ...
                      'OK', 'Skip', 'Cancel All', 'OK');
    
    if strcmp(choice, 'Cancel All')
        fprintf('ยกเลิกการวิเคราะห์\n');
        break;
    end
    
    if strcmp(choice, 'Skip')
        fprintf('  -> ข้ามรูปนี้\n\n');
        delete(h);
        continue;
    end
    
    % Get rectangle position
    pos = h.Position;  % [x, y, width, height]
    
    % Validate
    if pos(3) < 10 || pos(4) < 10
        fprintf('  -> กรอบเล็กเกินไป (ข้าม)\n\n');
        delete(h);
        continue;
    end
    
    % Store data
    validCount = validCount + 1;
    plateData(validCount).file = imageFiles{i};
    plateData(validCount).bbox = pos;
    plateData(validCount).area = pos(3) * pos(4);
    plateData(validCount).aspectRatio = pos(3) / pos(4);
    plateData(validCount).width = pos(3);
    plateData(validCount).height = pos(4);
    
    fprintf('  -> บันทึก: Area=%.0f, AR=%.2f, W=%.0f, H=%.0f\n\n', ...
            plateData(validCount).area, ...
            plateData(validCount).aspectRatio, ...
            plateData(validCount).width, ...
            plateData(validCount).height);
    
    delete(h);
end

close all;

%% Check if we have data
if isempty(plateData)
    fprintf('\nไม่มีข้อมูล - ออกจากโปรแกรม\n');
    return;
end

%% Statistical Analysis
areas = [plateData.area];
aspectRatios = [plateData.aspectRatio];
widths = [plateData.width];
heights = [plateData.height];

fprintf('\n========================================\n');
fprintf('สรุปสถิติป้ายทะเบียน (n=%d)\n', validCount);
fprintf('========================================\n\n');

fprintf('Area (พื้นที่):\n');
fprintf('  Mean:   %.0f pixels²\n', mean(areas));
fprintf('  Std:    %.0f\n', std(areas));
fprintf('  Min:    %.0f\n', min(areas));
fprintf('  Max:    %.0f\n', max(areas));
fprintf('  Median: %.0f\n', median(areas));
fprintf('\n');

fprintf('Aspect Ratio (width/height):\n');
fprintf('  Mean:   %.2f\n', mean(aspectRatios));
fprintf('  Std:    %.2f\n', std(aspectRatios));
fprintf('  Min:    %.2f\n', min(aspectRatios));
fprintf('  Max:    %.2f\n', max(aspectRatios));
fprintf('  Median: %.2f\n', median(aspectRatios));
fprintf('\n');

fprintf('Width:\n');
fprintf('  Mean:   %.0f pixels\n', mean(widths));
fprintf('  Std:    %.0f\n', std(widths));
fprintf('  Range:  %.0f - %.0f\n', min(widths), max(widths));
fprintf('\n');

fprintf('Height:\n');
fprintf('  Mean:   %.0f pixels\n', mean(heights));
fprintf('  Std:    %.0f\n', std(heights));
fprintf('  Range:  %.0f - %.0f\n', min(heights), max(heights));
fprintf('\n');

%% Recommendations for detectPlate.m
fprintf('========================================\n');
fprintf('แนะนำค่า Parameters สำหรับ detectPlate.m\n');
fprintf('========================================\n\n');

% Area range: mean ± 2*std (covers ~95% of data)
minArea = max(1000, mean(areas) - 2*std(areas));
maxArea = mean(areas) + 2*std(areas);

% Aspect ratio: mean ± 1.5*std (slightly wider range)
minAR = max(1.5, mean(aspectRatios) - 1.5*std(aspectRatios));
maxAR = mean(aspectRatios) + 1.5*std(aspectRatios);

fprintf('validArea = area >= %.0f && area <= %.0f;\n', minArea, maxArea);
fprintf('validAspectRatio = aspectRatio >= %.2f && aspectRatio <= %.2f;\n', minAR, maxAR);
fprintf('\n');

fprintf('Copy these values to detectPlate.m at line ~95:\n');
fprintf('    validArea = area >= %.0f && area <= %.0f;\n', minArea, maxArea);
fprintf('    validAspectRatio = aspectRatio >= %.2f && aspectRatio <= %.2f;\n', minAR, maxAR);
fprintf('\n');

%% Visualization
figure('Position', [100, 100, 1200, 400]);

subplot(1,3,1);
histogram(areas, 10, 'FaceColor', [0.2 0.6 0.8]);
xlabel('Area (pixels²)');
ylabel('Frequency');
title('Distribution of Plate Areas');
xline(mean(areas), 'r--', 'LineWidth', 2);
xline(minArea, 'g--', 'LineWidth', 1.5);
xline(maxArea, 'g--', 'LineWidth', 1.5);
legend('Data', 'Mean', 'Threshold');
grid on;

subplot(1,3,2);
histogram(aspectRatios, 10, 'FaceColor', [0.8 0.4 0.2]);
xlabel('Aspect Ratio');
ylabel('Frequency');
title('Distribution of Aspect Ratios');
xline(mean(aspectRatios), 'r--', 'LineWidth', 2);
xline(minAR, 'g--', 'LineWidth', 1.5);
xline(maxAR, 'g--', 'LineWidth', 1.5);
legend('Data', 'Mean', 'Threshold');
grid on;

subplot(1,3,3);
scatter(widths, heights, 50, 'filled', 'MarkerFaceAlpha', 0.6);
xlabel('Width (pixels)');
ylabel('Height (pixels)');
title('Width vs Height');
grid on;

%% Save results
outputFile = '../../2.data/plate_ground_truth.mat';
save(outputFile, 'plateData', 'minArea', 'maxArea', 'minAR', 'maxAR');
fprintf('บันทึกข้อมูลแล้วที่: %s\n', outputFile);

fprintf('\n=== เสร็จสิ้น ===\n');