function results = testDetection(imageFolder, outputFolder, maxImages)
% TESTDETECTION - ทดสอบ detection กับรูปหลายๆ รูป และประเมินผล
%
% Syntax:
%   results = testDetection(imageFolder, outputFolder, maxImages)
%
% Input:
%   imageFolder  - โฟลเดอร์ที่เก็บรูป (default: '../../2.data/images/')
%   outputFolder - โฟลเดอร์บันทึกป้ายที่ crop (default: '../../2.data/detected_plates/')
%   maxImages    - จำนวนรูปสูงสุดที่จะทดสอบ (default: inf = ทั้งหมด)
%
% Output:
%   results - struct containing:
%     .totalImages    - จำนวนรูปทั้งหมด
%     .detected       - จำนวนที่ detect ได้
%     .notDetected    - จำนวนที่ detect ไม่ได้
%     .successRate    - อัตราความสำเร็จ (%)
%     .detectionList  - cell array ของชื่อไฟล์ที่ detect ได้
%     .failureList    - cell array ของชื่อไฟล์ที่ detect ไม่ได้
%     .avgScore       - คะแนนเฉลี่ยของที่ detect ได้
%     .avgTime        - เวลาเฉลี่ยต่อรูป (วินาที)
%
% Example:
%   results = testDetection();  % ทดสอบทั้งหมด
%   results = testDetection('../../2.data/images/', '../../2.data/detected_plates/', 50);  % ทดสอบ 50 รูป
%
% Author: LPR-2568 Project
% Date: 2025

    %% ========================================
    %% 1. DEFAULT PARAMETERS
    %% ========================================
    if nargin < 1 || isempty(imageFolder)
        imageFolder = '../../2.data/images/';
    end
    
    if nargin < 2 || isempty(outputFolder)
        outputFolder = '../../2.data/detected_plates/';
    end
    
    if nargin < 3 || isempty(maxImages)
        maxImages = inf;
    end
    
    %% ========================================
    %% 2. CREATE OUTPUT FOLDER
    %% ========================================
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
        fprintf('Created output folder: %s\n', outputFolder);
    end
    
    %% ========================================
    %% 3. GET IMAGE LIST
    %% ========================================
    imageFiles = dir(fullfile(imageFolder, '*.bmp'));
    if isempty(imageFiles)
        imageFiles = dir(fullfile(imageFolder, '*.jpg'));
    end
    if isempty(imageFiles)
        imageFiles = dir(fullfile(imageFolder, '*.png'));
    end
    
    if isempty(imageFiles)
        error('No images found in %s', imageFolder);
    end
    
    totalImages = min(length(imageFiles), maxImages);
    
    fprintf('\n========================================\n');
    fprintf('LICENSE PLATE DETECTION BATCH TEST\n');
    fprintf('========================================\n');
    fprintf('Image folder: %s\n', imageFolder);
    fprintf('Output folder: %s\n', outputFolder);
    fprintf('Total images to test: %d\n', totalImages);
    fprintf('========================================\n\n');
    
    %% ========================================
    %% 4. INITIALIZE RESULTS
    %% ========================================
    % Preallocate arrays
    detectionList = cell(totalImages, 1);
    failureList = cell(totalImages, 1);
    %scores = zeros(totalImages, 1);
    times = zeros(totalImages, 1);
    
    detectedCount = 0;
    failedCount = 0;
    
    %detected = 0;
    %notDetected = 0;
    
    %% ========================================
    %% 5. PROCESS EACH IMAGE
    %% ========================================
    fprintf('Processing images...\n');
    fprintf('%-40s %-10s %-10s %-10s\n', 'Filename', 'Status', 'Score', 'Time(s)');
    fprintf('---------------------------------------- ---------- ---------- ----------\n');
    
    for i = 1:totalImages
        filename = imageFiles(i).name;
        filepath = fullfile(imageFolder, filename);
        
        try
            % Read image
            img = imread(filepath);
            
            % Detect plate
            tic;
            %bbox = detectPlate(img);
            bbox = detectPlateBoth(img);  % ใช้ฟังก์ชันใหม่ที่รวมทั้งสองวิธี
            elapsedTime = toc;
            
            if ~isempty(bbox)
                % Detection successful
                detectedCount = detectedCount + 1;
                detectionList{detectedCount} = filename;
                
                % Extract plate
                plateImg = extractPlate(img, bbox);
                
                % Save extracted plate
                [~, name, ~] = fileparts(filename);
                outputPath = fullfile(outputFolder, [name, '_plate.png']);
                imwrite(plateImg, outputPath);
                
                % Store time
                times(detectedCount) = elapsedTime;
                
                fprintf('%-40s %-10s %-10s %-10.3f\n', filename, 'DETECTED', '-', elapsedTime);
            else
                % Detection failed
                failedCount = failedCount + 1;
                failureList{failedCount} = filename;
                
                fprintf('%-40s %-10s %-10s %-10.3f\n', filename, 'FAILED', '-', elapsedTime);
            end
            
        catch ME
            % Error occurred
            failedCount = failedCount + 1;
            failureList{failedCount} = filename;
            fprintf('%-40s %-10s %-10s\n', filename, 'ERROR', ME.message);
        end
        
        % Progress indicator every 10 images
        if mod(i, 10) == 0
            fprintf('  [Progress: %d/%d (%.1f%%)]\n', i, totalImages, (i/totalImages)*100);
        end
    end
    
    %% ========================================
    %% 6. CALCULATE STATISTICS
    %% ========================================
    % Trim arrays to actual size
    detectionList = detectionList(1:detectedCount);
    failureList = failureList(1:failedCount);
    times = times(1:detectedCount);
    
    detected = detectedCount;
    notDetected = failedCount;
    
    successRate = (detected / totalImages) * 100;
    avgScore = 0;  % Not calculated in this version
    avgTime = mean(times);
    
    %% ========================================
    %% 7. DISPLAY RESULTS
    %% ========================================
    fprintf('\n========================================\n');
    fprintf('DETECTION RESULTS SUMMARY\n');
    fprintf('========================================\n');
    fprintf('Total images tested:     %d\n', totalImages);
    fprintf('Successfully detected:   %d\n', detected);
    fprintf('Failed to detect:        %d\n', notDetected);
    fprintf('Success rate:            %.2f%%\n', successRate);
    fprintf('Average processing time: %.3f seconds\n', avgTime);
    fprintf('========================================\n\n');
    
    %% ========================================
    %% 8. SHOW FAILURE LIST
    %% ========================================
    if notDetected > 0
        fprintf('Failed detections (%d images):\n', notDetected);
        for i = 1:length(failureList)
            fprintf('  %d. %s\n', i, failureList{i});
        end
        fprintf('\n');
    end
    
    %% ========================================
    %% 9. CREATE RESULTS STRUCT
    %% ========================================
    results.totalImages = totalImages;
    results.detected = detected;
    results.notDetected = notDetected;
    results.successRate = successRate;
    results.detectionList = detectionList;
    results.failureList = failureList;
    results.avgScore = avgScore;
    results.avgTime = avgTime;
    
    %% ========================================
    %% 10. SAVE RESULTS TO FILE
    %% ========================================
    resultFile = fullfile(outputFolder, 'detection_results.mat');
    save(resultFile, 'results');
    fprintf('Results saved to: %s\n', resultFile);
    
    % Save text report
    reportFile = fullfile(outputFolder, 'detection_report.txt');
    fid = fopen(reportFile, 'w');
    fprintf(fid, 'LICENSE PLATE DETECTION TEST REPORT\n');
    fprintf(fid, 'Generated: %s\n\n', char(datetime('now')));
    fprintf(fid, 'SUMMARY\n');
    fprintf(fid, '-------\n');
    fprintf(fid, 'Total images:     %d\n', totalImages);
    fprintf(fid, 'Detected:         %d\n', detected);
    fprintf(fid, 'Not detected:     %d\n', notDetected);
    fprintf(fid, 'Success rate:     %.2f%%\n', successRate);
    fprintf(fid, 'Avg time:         %.3f s\n\n', avgTime);
    
    fprintf(fid, 'FAILED DETECTIONS\n');
    fprintf(fid, '-----------------\n');
    for i = 1:length(failureList)
        fprintf(fid, '%d. %s\n', i, failureList{i});
    end
    fclose(fid);
    fprintf('Report saved to: %s\n\n', reportFile);
    
    %% ========================================
    %% 11. PLOT RESULTS
    %% ========================================
    figure('Name', 'Detection Statistics', 'Position', [100, 100, 800, 600]);
    
    % Pie chart
    subplot(2,2,1);
    pie([detected, notDetected], {'Detected', 'Not Detected'});
    title(sprintf('Detection Results (Success: %.1f%%)', successRate), 'FontWeight', 'bold');
    
    % Bar chart
    subplot(2,2,2);
    bar([detected, notDetected]);
    set(gca, 'XTickLabel', {'Detected', 'Not Detected'});
    ylabel('Count');
    title('Detection Count', 'FontWeight', 'bold');
    grid on;
    
    % Processing time histogram
    if ~isempty(times)
        subplot(2,2,3);
        histogram(times, 20);
        xlabel('Time (seconds)');
        ylabel('Frequency');
        title(sprintf('Processing Time (Avg: %.3fs)', avgTime), 'FontWeight', 'bold');
        grid on;
    end
    
    % Success rate gauge (text)
    subplot(2,2,4);
    axis off;
    text(0.5, 0.7, sprintf('%.1f%%', successRate), ...
         'HorizontalAlignment', 'center', 'FontSize', 48, 'FontWeight', 'bold');
    text(0.5, 0.3, 'Success Rate', ...
         'HorizontalAlignment', 'center', 'FontSize', 16);
    
    % Save figure
    figFile = fullfile(outputFolder, 'detection_statistics.png');
    saveas(gcf, figFile);
    fprintf('Statistics chart saved to: %s\n', figFile);
end