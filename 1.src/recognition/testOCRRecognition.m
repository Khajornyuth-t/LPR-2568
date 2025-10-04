% testOCRRecognition.m
% Test OCR on detected license plates
%
% Reads plates from: 2.data/detected_plates/
% Saves results to: 5.output/recognition_results/

clear; clc; close all;

fprintf('========================================\n');
fprintf('OCR RECOGNITION TEST\n');
fprintf('========================================\n\n');

%% Configuration
plates_folder = '../../2.data/detected_plates/';
templates_path = '../../3.templates/templates.mat';
output_folder = '../../5.output/recognition_results/';

% Create output folder
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

%% Load templates
fprintf('Loading templates...\n');
if ~exist(templates_path, 'file')
    error('Templates not found: %s\nPlease create templates first.', templates_path);
end
load(templates_path, 'templates');
fprintf('OK Templates loaded\n\n');

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
fprintf('Processing...\n\n');

%% Initialize results
results = struct();
results.filename = cell(num_plates, 1);
results.num_chars = zeros(num_plates, 1);
results.plate_text = cell(num_plates, 1);
results.confidence = zeros(num_plates, 1);
results.success = false(num_plates, 1);

%% Process each plate
for idx = 1:num_plates
    fprintf('[%d/%d] %s\n', idx, num_plates, plate_files(idx).name);
    
    try
        % Read image
        img_path = fullfile(plates_folder, plate_files(idx).name);
        plate_img = imread(img_path);
        
        % Run OCR
        [plate_text, conf, ~] = readPlate(plate_img, templates);
        
        num_chars = length(plate_text);
        
        % Store results
        results.filename{idx} = plate_files(idx).name;
        results.num_chars(idx) = num_chars;
        results.plate_text{idx} = plate_text;
        results.confidence(idx) = conf;
        results.success(idx) = true;
        
        fprintf('  Result: "%s" (%.1f%%, %d chars)\n\n', plate_text, conf*100, num_chars);
        
    catch ME
        fprintf('  ERROR: %s\n\n', ME.message);
        results.filename{idx} = plate_files(idx).name;
        results.num_chars(idx) = 0;
        results.plate_text{idx} = 'ERROR';
        results.confidence(idx) = 0;
        results.success(idx) = false;
    end
end

%% Summary
fprintf('\n========================================\n');
fprintf('SUMMARY\n');
fprintf('========================================\n');
fprintf('Total plates: %d\n', num_plates);
fprintf('Successful: %d (%.1f%%)\n', sum(results.success), 100*sum(results.success)/num_plates);
fprintf('Failed: %d\n\n', sum(~results.success));

%% Statistics
valid_results = results.success;

if any(valid_results)
    fprintf('Character Count Distribution:\n');
    char_counts = results.num_chars(valid_results);
    unique_counts = unique(char_counts);
    for i = 1:length(unique_counts)
        count = unique_counts(i);
        num_with_count = sum(char_counts == count);
        fprintf('  %2d chars: %3d plates (%.1f%%)\n', count, num_with_count, 100*num_with_count/sum(valid_results));
    end
    
    fprintf('\nConfidence Statistics:\n');
    valid_conf = results.confidence(valid_results);
    fprintf('  Mean:   %.1f%%\n', mean(valid_conf)*100);
    fprintf('  Median: %.1f%%\n', median(valid_conf)*100);
    fprintf('  Min:    %.1f%%\n', min(valid_conf)*100);
    fprintf('  Max:    %.1f%%\n', max(valid_conf)*100);
    
    % Good results (6-8 chars, confidence > 60%)
    good_results = (results.num_chars >= 6 & results.num_chars <= 8 & results.confidence >= 0.6);
    fprintf('\nGood Results (6-8 chars, >60%% conf): %d (%.1f%%)\n', ...
        sum(good_results), 100*sum(good_results)/num_plates);
end

%% Save results
fprintf('\n========================================\n');
fprintf('Saving results...\n');

% Save MAT file
results_mat = fullfile(output_folder, 'recognition_results.mat');
save(results_mat, 'results');
fprintf('OK Saved: %s\n', results_mat);

% Save text file
results_txt = fullfile(output_folder, 'recognition_results.txt');
fid = fopen(results_txt, 'w');
fprintf(fid, 'OCR Recognition Results\n');
fprintf(fid, 'Generated: %s\n\n', datetime('now'));
fprintf(fid, '%-30s | Chars | Text                    | Confidence\n', 'Filename');
fprintf(fid, '%s\n', repmat('-', 1, 85));

for idx = 1:num_plates
    fprintf(fid, '%-30s | %5d | %-23s | %6.1f%%\n', ...
        results.filename{idx}, ...
        results.num_chars(idx), ...
        results.plate_text{idx}, ...
        results.confidence(idx)*100);
end
fclose(fid);
fprintf('OK Saved: %s\n', results_txt);

fprintf('\n========================================\n');
fprintf('COMPLETED\n');
fprintf('========================================\n');