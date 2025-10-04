function preprocessSamples()
% preprocessSamples - ทดสอบ preprocessing methods กับ samples
%
% วัตถุประสงค์:
%   - อ่านรูปจาก samples/red, samples/yellow, samples/green
%   - ทดสอบ preprocessing methods หลายแบบ
%   - เปรียบเทียบ contrast, edge quality
%   - เลือก method ที่ดีที่สุดสำหรับ OCR
%
% Preprocessing Methods:
%   1. Standard Grayscale + CLAHE
%   2. LAB L-channel + CLAHE
%   3. Auto Channel Selection (RGB)
%   4. HSV V-channel + CLAHE
%   5. Adaptive Binarization
%
% Output:
%   - 2.data/preprocessed/white/method1, method2, ...
%   - 2.data/preprocessed/yellow/method1, method2, ...
%   - 2.data/preprocessed/red/method1, method2, ...
%   - 2.data/preprocessed/green/method1, method2, ...
%   - 2.data/preprocessing_results.mat (metrics)
%
% Author: LPR-2568 Project
% Date: 2025

    fprintf('=== Preprocessing Samples ===\n\n');
    
    %% 1. Setup paths
    scriptDir = fileparts(mfilename('fullpath'));
    baseDir = fileparts(fileparts(scriptDir));
    samplesDir = fullfile(baseDir, '2.data', 'samples');
    outputDir = fullfile(baseDir, '2.data', 'preprocessed');
    
    % ตรวจสอบ folder
    if ~exist(samplesDir, 'dir')
        error('ไม่พบโฟลเดอร์: %s', samplesDir);
    end
    
    %% 2. รายการสีที่ต้องการประมวลผล
    colors = {'white', 'yellow', 'red', 'green'};
    
    % กรอง colors ที่มีจริง
    existingColors = cell(1, length(colors));  % preallocate
    colorCount = 0;
    
    for i = 1:length(colors)
        colorDir = fullfile(samplesDir, colors{i});
        if exist(colorDir, 'dir')
            files = dir(fullfile(colorDir, '*.bmp'));
            if ~isempty(files)
                colorCount = colorCount + 1;
                existingColors{colorCount} = colors{i};
                fprintf('พบสี: %-8s (%d รูป)\n', colors{i}, length(files));
            end
        end
    end
    
    % ตัดส่วนที่ไม่ได้ใช้ออก
    existingColors = existingColors(1:colorCount);
    
    if isempty(existingColors)
        error('ไม่พบรูปใน samples/');
    end
    
    fprintf('\nจะประมวลผล: %s\n\n', strjoin(existingColors, ', '));
    
    %% 3. รายการ preprocessing methods
    methods = {
        'method1_standard', 'Standard Grayscale + CLAHE';
        'method2_lab', 'LAB L-channel + CLAHE';
        'method3_auto_channel', 'Auto Best Channel + CLAHE';
        'method4_hsv', 'HSV V-channel + CLAHE';
        'method5_adaptive', 'Adaptive Binarization'
    };
    
    fprintf('Preprocessing Methods:\n');
    for i = 1:size(methods, 1)
        fprintf('  %d. %s\n', i, methods{i,2});
    end
    fprintf('\n');
    
    %% 4. เตรียม output folders
    for i = 1:length(existingColors)
        color = existingColors{i};
        colorOutputDir = fullfile(outputDir, color);
        
        % สร้าง folders สำหรับแต่ละ method
        mkdir(fullfile(colorOutputDir, 'original'));
        for j = 1:size(methods, 1)
            mkdir(fullfile(colorOutputDir, methods{j,1}));
        end
    end
    
    %% 5. ประมวลผลแต่ละสี
    allResults = struct();
    
    for colorIdx = 1:length(existingColors)
        color = existingColors{colorIdx};
        fprintf('--- Processing: %s ---\n', upper(color));
        
        colorInputDir = fullfile(samplesDir, color);
        colorOutputDir = fullfile(outputDir, color);
        
        % อ่านไฟล์ทั้งหมด
        imageFiles = dir(fullfile(colorInputDir, '*.bmp'));
        numImages = length(imageFiles);
        
        % เตรียม arrays สำหรับเก็บ metrics
        results = struct();
        for j = 1:size(methods, 1)
            results.(methods{j,1}) = struct(...
                'contrast', zeros(numImages, 1), ...
                'edge_strength', zeros(numImages, 1), ...
                'entropy', zeros(numImages, 1));
        end
        
        % waitbar
        h = waitbar(0, sprintf('Processing %s...', color));
        
        % ประมวลผลแต่ละรูป
        for imgIdx = 1:numImages
            % อ่านรูป
            imgPath = fullfile(colorInputDir, imageFiles(imgIdx).name);
            img = imread(imgPath);
            
            % บันทึกต้นฉบับ
            imwrite(img, fullfile(colorOutputDir, 'original', imageFiles(imgIdx).name));
            
            % ทดสอบแต่ละ method
            for methodIdx = 1:size(methods, 1)
                methodName = methods{methodIdx, 1};
                
                % Apply preprocessing
                processed = applyMethod(img, methodIdx);
                
                % บันทึกผลลัพธ์
                outputPath = fullfile(colorOutputDir, methodName, imageFiles(imgIdx).name);
                imwrite(processed, outputPath);
                
                % คำนวณ metrics
                results.(methodName).contrast(imgIdx) = calculateContrast(processed);
                results.(methodName).edge_strength(imgIdx) = calculateEdgeStrength(processed);
                results.(methodName).entropy(imgIdx) = entropy(processed);
            end
            
            % Update waitbar
            waitbar(imgIdx/numImages, h);
        end
        
        close(h);
        
        % บันทึกผลสำหรับสีนี้
        allResults.(color) = results;
        
        % แสดงสรุปสำหรับสีนี้
        fprintf('\nสรุป %s:\n', upper(color));
        fprintf('%-25s | %10s | %12s | %10s\n', ...
            'Method', 'Contrast', 'Edge Strength', 'Entropy');
        fprintf('%s\n', repmat('-', 1, 70));
        
        for methodIdx = 1:size(methods, 1)
            methodName = methods{methodIdx, 1};
            avgContrast = mean(results.(methodName).contrast);
            avgEdge = mean(results.(methodName).edge_strength);
            avgEntropy = mean(results.(methodName).entropy);
            
            fprintf('%-25s | %10.4f | %12.4f | %10.4f\n', ...
                methods{methodIdx,2}, avgContrast, avgEdge, avgEntropy);
        end
        fprintf('\n');
    end
    
    %% 6. บันทึก results
    resultsFile = fullfile(baseDir, '2.data', 'preprocessing_results.mat');
    save(resultsFile, 'allResults', 'methods', 'existingColors');
    fprintf('✓ บันทึกผล: %s\n', resultsFile);
    
    %% 7. สร้าง comparison charts
    createComparisonCharts(allResults, methods, existingColors, baseDir);
    
    fprintf('\n=== เสร็จสิ้น! ===\n');
    fprintf('ดูผลได้ที่:\n');
    fprintf('  - %s\n', outputDir);
    fprintf('  - %s\n', resultsFile);
end

%% ========================================
%% Apply Preprocessing Methods
%% ========================================
function processed = applyMethod(img, methodIdx)
    switch methodIdx
        case 1
            % Method 1: Standard Grayscale + CLAHE
            gray = rgb2gray(img);
            processed = adapthisteq(gray, 'ClipLimit', 0.02);
            
        case 2
            % Method 2: LAB L-channel + CLAHE
            lab = rgb2lab(img);
            L = lab(:,:,1);
            L_norm = mat2gray(L);
            processed = adapthisteq(L_norm, 'ClipLimit', 0.02);
            processed = im2uint8(processed);
            
        case 3
            % Method 3: Auto Best Channel Selection
            % เลือก channel ที่ให้ contrast สูงสุด
            r = img(:,:,1);
            g = img(:,:,2);
            b = img(:,:,3);
            
            % คำนวณ std ของแต่ละ channel
            std_r = std(double(r(:)));
            std_g = std(double(g(:)));
            std_b = std(double(b(:)));
            
            % เลือก channel ที่ดีที่สุด
            [~, bestIdx] = max([std_r, std_g, std_b]);
            gray = img(:,:,bestIdx);
            
            % ปรับ contrast
            gray = imadjust(gray);
            processed = adapthisteq(gray, 'ClipLimit', 0.02);
            
        case 4
            % Method 4: HSV V-channel + CLAHE
            hsv = rgb2hsv(img);
            V = hsv(:,:,3);
            V_uint8 = im2uint8(V);
            processed = adapthisteq(V_uint8, 'ClipLimit', 0.02);
            
        case 5
            % Method 5: Adaptive Binarization
            gray = rgb2gray(img);
            % ใช้ adaptive threshold
            processed = imbinarize(gray, 'adaptive', 'Sensitivity', 0.4);
            processed = im2uint8(processed);
            
        otherwise
            error('Unknown method index: %d', methodIdx);
    end
end

%% ========================================
%% Calculate Metrics
%% ========================================
function contrast = calculateContrast(img)
    % คำนวณ Michelson Contrast
    img_double = double(img);
    maxVal = max(img_double(:));
    minVal = min(img_double(:));
    
    if (maxVal + minVal) > 0
        contrast = (maxVal - minVal) / (maxVal + minVal);
    else
        contrast = 0;
    end
end

function edgeStrength = calculateEdgeStrength(img)
    % คำนวณความแข็งแกร่งของขอบ
    edges = edge(img, 'Canny');
    edgeStrength = sum(edges(:)) / numel(edges);
end

%% ========================================
%% Create Comparison Charts
%% ========================================
function createComparisonCharts(allResults, methods, colors, baseDir)
    try
        fprintf('\nสร้าง comparison charts...\n');
        
        numMethods = size(methods, 1);
        numColors = length(colors);
        
        % สร้างกราฟเปรียบเทียบ
        figure('Position', [100, 100, 1400, 800]);
        
        metrics = {'contrast', 'edge_strength', 'entropy'};
        metricLabels = {'Contrast Ratio', 'Edge Strength', 'Entropy'};
        
        for metricIdx = 1:3
            subplot(2, 2, metricIdx);
            
            data = zeros(numMethods, numColors);
            
            for colorIdx = 1:numColors
                color = colors{colorIdx};
                for methodIdx = 1:numMethods
                    methodName = methods{methodIdx, 1};
                    values = allResults.(color).(methodName).(metrics{metricIdx});
                    data(methodIdx, colorIdx) = mean(values);
                end
            end
            
            bar(data);
            set(gca, 'XTickLabel', cellfun(@(x) x(8:end), methods(:,2), 'UniformOutput', false));
            xtickangle(45);
            ylabel(metricLabels{metricIdx});
            legend(colors, 'Location', 'best');
            title(sprintf('%s by Method', metricLabels{metricIdx}));
            grid on;
        end
        
        % สร้างตาราง ranking
        subplot(2, 2, 4);
        axis off;
        
        % คำนวณ ranking
        rankings = cell(numColors, 1);
        for colorIdx = 1:numColors
            color = colors{colorIdx};
            scores = zeros(numMethods, 1);
            
            for methodIdx = 1:numMethods
                methodName = methods{methodIdx, 1};
                % Score = weighted sum of metrics
                contrast = mean(allResults.(color).(methodName).contrast);
                edge = mean(allResults.(color).(methodName).edge_strength);
                entr = mean(allResults.(color).(methodName).entropy);
                
                % Normalize and weight
                scores(methodIdx) = 0.5*contrast + 0.3*edge + 0.2*entr;
            end
            
            [~, sortIdx] = sort(scores, 'descend');
            rankings{colorIdx} = methods{sortIdx(1), 2};
        end
        
        % แสดง ranking table
        text(0.1, 0.9, 'Recommended Methods by Color:', 'FontWeight', 'bold', 'FontSize', 12);
        yPos = 0.8;
        for colorIdx = 1:numColors
            text(0.1, yPos, sprintf('%s: %s', upper(colors{colorIdx}), rankings{colorIdx}), ...
                'FontSize', 10);
            yPos = yPos - 0.15;
        end
        
        sgtitle('Preprocessing Methods Comparison');
        
        % บันทึกกราฟ
        chartFile = fullfile(baseDir, '2.data', 'comparison', 'methods_comparison.png');
        mkdir(fullfile(baseDir, '2.data', 'comparison'));
        saveas(gcf, chartFile);
        fprintf('✓ บันทึกกราฟ: %s\n', chartFile);
        
        close(gcf);
        
    catch ME
        fprintf('⚠ ไม่สามารถสร้างกราฟได้: %s\n', ME.message);
    end
end