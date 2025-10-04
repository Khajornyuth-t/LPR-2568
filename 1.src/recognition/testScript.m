% testOCRRecognition.m
% Test script for OCR recognition (Steps 3-4)
%
% Tests:
% - matchTemplate.m (Step 3)
% - recognizeCharacter.m (Step 4)
%
% Reads ALL images from detected_plates folder automatically

clear; clc; close all;

fprintf('========================================\n');
fprintf('OCR RECOGNITION TEST\n');
fprintf('========================================\n\n');

%% Configuration
plates_folder = '../../2.data/detected_plates/';
templates_path = '../../3.templates/templates.mat';

% Create output folder for results
output_folder = '../../5.output/recognition_results/';
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

%% Check if templates exist
if ~exist(templates_path, 'file')
    error('Templates not found: %s\nPlease run TASK 2 first to create templates.', templates_path);
end

% Load templates
fprintf('Loading templates...\n');
load(templates_path, 'templates');
fprintf('✓ Templates loaded\n\n');

%% Check if detected plates folder exists
if ~exist(plates_folder, 'dir')
    error('Folder not found: %s\nPlease run detection first.', plates_folder);
end

%% Get all plate images
plate_files = dir(fullfile(plates_folder, '*.png'));
if isempty(plate_files)
    plate_files = dir(fullfile(plates_folder, '*.jpg'));
end

if isempty(plate_files)
    error('No images found in %s', plates_folder);
end

num_plates = length(plate_files);
fprintf('Found %d plate images\n', num_plates);
fprintf('Processing all images...\n\n');

%% Initialize results storage
results = struct();
results.files = cell(num_plates, 1);
results.num_chars = zeros(num_plates, 1);
results.recognized_text = cell(num_plates, 1);
results.avg_confidence = zeros(num_plates, 1);
results.success = false(num_plates, 1);

%% Process each plate
for idx = 1:num_plates
    fprintf('----------------------------------------\n');
    fprintf('[%d/%d] Processing: %s\n', idx, num_plates, plate_files(idx).name);
    fprintf('----------------------------------------\n');
    
    try
        %% Read image
        img_path = fullfile(plates_folder, plate_files(idx).name);
        plate_img = imread(img_path);
        
        %% Step 1-2: Preprocessing and Segmentation
        fprintf('  → Preprocessing...\n');
        [gray_img, binary_img, ~] = preprocessPlate(plate_img);
        
        fprintf('  → Segmenting characters...\n');
        [char_images, char_boxes, ~] = segmentCharacters(binary_img, gray_img);
        
        num_chars = length(char_images);
        fprintf('  → Found %d characters\n', num_chars);
        
        %% Step 3-4: Recognition
        if num_chars == 0
            fprintf('  ✗ No characters to recognize\n\n');
            results.files{idx} = plate_files(idx).name;
            results.num_chars(idx) = 0;
            results.recognized_text{idx} = '';
            results.avg_confidence(idx) = 0;
            results.success(idx) = false;
            continue;
        end
        
        fprintf('  → Recognizing characters...\n');
        
        recognized_chars = cell(num_chars, 1);
        confidences = zeros(num_chars, 1);
        
        for i = 1:num_chars
            [char, conf, ~] = recognizeCharacter(char_images{i}, templates);
            recognized_chars{i} = char;
            confidences(i) = conf;
            
            fprintf('     Char %d: "%s" (%.1f%%)\n', i, char, conf*100);
        end
        
        %% Combine results
        plate_text = strjoin(recognized_chars, '');
        avg_conf = mean(confidences);
        
        fprintf('  ✓ Result: "%s" (avg conf: %.1f%%)\n', plate_text, avg_conf*100);
        
        %% Store results
        results.files{idx} = plate_files(idx).name;
        results.num_chars(idx) = num_chars;
        results.recognized_text{idx} = plate_text;
        results.avg_confidence(idx) = avg_conf;
        results.success(idx) = true;
        
        fprintf('\n');
        
    catch ME
        fprintf('  ✗ ERROR: %s\n\n', ME.message);
        results.files{idx} = plate_files(idx).name;
        results.num_chars(idx) = 0;
        results.recognized_text{idx} = 'ERROR';
        results.avg_confidence(idx) = 0;
        results.success(idx) = false;
    end
end

%% Summary Statistics
fprintf('\n========================================\n');
fprintf('SUMMARY\n');
fprintf('========================================\n');
fprintf('Total plates processed: %d\n', num_plates);
fprintf('Successful: %d (%.1f%%)\n', sum(results.success), 100*sum(results.success)/num_plates);
fprintf('Failed: %d\n', sum(~results.success));
fprintf('\n');

%% Detailed Results
fprintf('Detailed Results:\n');
fprintf('%-30s | Chars | Text            | Confidence\n', 'Filename');
fprintf('%s\n', repmat('-', 1, 75));

for idx = 1:num_plates
    status = '✗';
    if results.success(idx)
        if results.num_chars(idx) >= 5 && results.avg_confidence(idx) >= 0.5
            status = '✓';
        else
            status = '⚠';
        end
    end
    
    fprintf('%s %-27s | %5d | %-15s | %.1f%%\n', ...
        status, ...
        results.files{idx}, ...
        results.num_chars(idx), ...
        results.recognized_text{idx}, ...
        results.avg_confidence(idx)*100);
end

fprintf('\n✓ = Good recognition\n');
fprintf('⚠ = Low confidence or unusual character count\n');
fprintf('✗ = Failed\n');

%% Character Count Distribution
fprintf('\n========================================\n');
fprintf('Character Count Distribution:\n');
char_counts = results.num_chars(results.success);
if ~isempty(char_counts)
    unique_counts = unique(char_counts);
    for i = 1:length(unique_counts)
        count = unique_counts(i);
        num_plates_with_count = sum(char_counts == count);
        fprintf('  %d characters: %d plates\n', count, num_plates_with_count);
    end
else
    fprintf('  No successful recognitions\n');
end

%% Confidence Statistics
fprintf('\n========================================\n');
fprintf('Confidence Statistics:\n');
valid_conf = results.avg_confidence(results.success);
if ~isempty(valid_conf)
    fprintf('  Mean:   %.2f%%\n', mean(valid_conf)*100);
    fprintf('  Median: %.2f%%\n', median(valid_conf)*100);
    fprintf('  Min:    %.2f%%\n', min(valid_conf)*100);
    fprintf('  Max:    %.2f%%\n', max(valid_conf)*100);
else
    fprintf('  No data\n');
end

%% Save results to file
fprintf('\n========================================\n');
fprintf('Saving results...\n');

% Save as MAT file
results_mat_path = fullfile(output_folder, 'recognition_results.mat');
save(results_mat_path, 'results');
fprintf('✓ Saved: %s\n', results_mat_path);

% Save as text file
results_txt_path = fullfile(output_folder, 'recognition_results.txt');
fid = fopen(results_txt_path, 'w');
fprintf(fid, 'OCR Recognition Results\n');
fprintf(fid, 'Generated: %s\n\n', datetime('now'));
fprintf(fid, '%-30s | Chars | Recognized Text | Confidence\n', 'Filename');
fprintf(fid, '%s\n', repmat('-', 1, 80));

for idx = 1:num_plates
    fprintf(fid, '%-30s | %5d | %-15s | %.1f%%\n', ...
        results.files{idx}, ...
        results.num_chars(idx), ...
        results.recognized_text{idx}, ...
        results.avg_confidence(idx)*100);
end

fclose(fid);
fprintf('✓ Saved: %s\n', results_txt_path);

fprintf('\n========================================\n');
fprintf('TEST COMPLETED\n');
fprintf('========================================\n');