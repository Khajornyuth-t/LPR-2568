% batchProcessAll.m
% Process all 250 images: Detection + Recognition
%
% Full pipeline:
%   1. Load image from data/images/
%   2. Detect plate (TASK 4)
%   3. Recognize plate text (TASK 5)
%   4. Save results

clear; clc; close all;

fprintf('========================================\n');
fprintf('BATCH PROCESSING - FULL PIPELINE\n');
fprintf('========================================\n\n');

%% Add necessary paths
fprintf('Adding paths...\n');
addpath('../detection');     % For detectPlate.m
addpath('../preprocessing'); % For preprocessing functions
fprintf('✓ Paths added\n\n');

%% Configuration
images_folder = '../../2.data/images/';
templates_path = '../../3.templates/templates.mat';
output_folder = '../../5.output/full_pipeline_results/';

%% Check if images folder exists
if ~exist(images_folder, 'dir')
    % Try alternative paths
    fprintf('Trying alternative paths...\n');
    
    % Get current directory
    current_dir = pwd;
    fprintf('Current directory: %s\n', current_dir);
    
    % Try going up to project root
    project_root = fileparts(fileparts(current_dir)); % Go up 2 levels
    images_folder_alt = fullfile(project_root, '2.data', 'images');
    
    if exist(images_folder_alt, 'dir')
        images_folder = images_folder_alt;
        fprintf('✓ Found: %s\n\n', images_folder);
    else
        fprintf('\nPlease specify the correct path to images folder.\n');
        fprintf('Current attempt: %s\n', images_folder);
        fprintf('Alternative: %s\n', images_folder_alt);
        error('Images folder not found. Please check the path.');
    end
end

% Create output folder
if ~exist(output_folder, 'dir')
    output_folder_alt = fullfile(fileparts(fileparts(pwd)), '5.output', 'full_pipeline_results');
    if ~exist(fileparts(output_folder_alt), 'dir')
        mkdir(fileparts(output_folder_alt));
    end
    mkdir(output_folder_alt);
    output_folder = output_folder_alt;
end

%% Load templates
fprintf('Loading templates...\n');
if ~exist(templates_path, 'file')
    error('Templates not found: %s', templates_path);
end
load(templates_path, 'templates');
fprintf('✓ Templates loaded\n\n');

%% Get all images
image_files = dir(fullfile(images_folder, '*.bmp'));
if isempty(image_files)
    image_files = dir(fullfile(images_folder, '*.jpg'));
end
if isempty(image_files)
    image_files = dir(fullfile(images_folder, '*.png'));
end

num_images = length(image_files);
if num_images == 0
    error('No images found in %s\nTried: *.bmp, *.jpg, *.png', images_folder);
end

fprintf('Found %d images\n', num_images);
fprintf('Starting processing...\n\n');

%% Initialize results
results = struct();
results.filename = cell(num_images, 1);
results.detection_success = false(num_images, 1);
results.plate_detected = cell(num_images, 1);
results.recognition_success = false(num_images, 1);
results.plate_text = cell(num_images, 1);
results.confidence = zeros(num_images, 1);
results.num_chars = zeros(num_images, 1);
results.processing_time = zeros(num_images, 1);

%% Process each image
tic;
for idx = 1:num_images
    fprintf('[%d/%d] Processing: %s\n', idx, num_images, image_files(idx).name);
    
    start_time = tic;
    
    try
        %% Read image
        img_path = fullfile(images_folder, image_files(idx).name);
        img = imread(img_path);
        
        %% STEP 1: Detection
        fprintf('  → Detecting plate...\n');
        
        % Try detection (detectPlate returns only plate image, not bbox)
        plate_img = [];
        detection_error = '';
        
        try
            plate_img = detectPlate(img);
        catch ME
            detection_error = ME.message;
            fprintf('  ⚠ Detection error: %s\n', ME.message);
        end
        
        % Check if detection succeeded
        if isempty(plate_img)
            fprintf('  ✗ Plate detection failed\n\n');
            results.filename{idx} = image_files(idx).name;
            results.detection_success(idx) = false;
            results.plate_text{idx} = 'DETECTION_FAILED';
            results.processing_time(idx) = toc(start_time);
            continue;
        end
        
        fprintf('  ✓ Plate detected\n');
        results.detection_success(idx) = true;
        results.plate_detected{idx} = 'YES';
        
        %% STEP 2: Recognition
        fprintf('  → Recognizing text...\n');
        
        options.debugMode = false;
        options.validateFormat = true;
        [plate_text, conf, debug] = readPlate(plate_img, templates, options);
        
        % Convert to Thai if validation succeeded
        if isfield(debug, 'formatted_text') && ~isempty(debug.formatted_text)
            plate_text = debug.formatted_text;
        end
        
        % Count characters
        num_chars = length(plate_text);
        
        fprintf('  ✓ Text: "%s" (%.1f%%, %d chars)\n', plate_text, conf*100, num_chars);
        
        %% Store results
        results.filename{idx} = image_files(idx).name;
        results.recognition_success(idx) = true;
        results.plate_text{idx} = plate_text;
        results.confidence(idx) = conf;
        results.num_chars(idx) = num_chars;
        results.processing_time(idx) = toc(start_time);
        
        fprintf('  ⏱ Time: %.2f sec\n\n', results.processing_time(idx));
        
    catch ME
        fprintf('  ✗ ERROR: %s\n\n', ME.message);
        results.filename{idx} = image_files(idx).name;
        results.detection_success(idx) = false;
        results.recognition_success(idx) = false;
        results.plate_text{idx} = 'ERROR';
        results.processing_time(idx) = toc(start_time);
    end
end

total_time = toc;

%% Summary Statistics
fprintf('\n========================================\n');
fprintf('SUMMARY\n');
fprintf('========================================\n');
fprintf('Total images: %d\n', num_images);
fprintf('Detection successful: %d (%.1f%%)\n', ...
    sum(results.detection_success), ...
    100*sum(results.detection_success)/num_images);
fprintf('Recognition successful: %d (%.1f%%)\n', ...
    sum(results.recognition_success), ...
    100*sum(results.recognition_success)/num_images);
fprintf('Total time: %.2f sec (%.2f sec/image)\n', ...
    total_time, total_time/num_images);

%% Recognition Statistics (for detected plates only)
successful = results.recognition_success;
if any(successful)
    fprintf('\n--- Recognition Statistics ---\n');
    fprintf('Mean confidence: %.1f%%\n', mean(results.confidence(successful))*100);
    fprintf('Median confidence: %.1f%%\n', median(results.confidence(successful))*100);
    
    fprintf('\nCharacter count distribution:\n');
    char_counts = results.num_chars(successful);
    unique_counts = unique(char_counts);
    for i = 1:length(unique_counts)
        count = unique_counts(i);
        num_plates = sum(char_counts == count);
        fprintf('  %d characters: %d plates\n', count, num_plates);
    end
end

%% Detailed Results
fprintf('\n========================================\n');
fprintf('DETAILED RESULTS\n');
fprintf('========================================\n');
fprintf('%-30s | Detected | Text          | Conf  | Time\n', 'Filename');
fprintf('%s\n', repmat('-', 1, 80));

for idx = 1:num_images
    status_detect = '✗';
    if results.detection_success(idx)
        status_detect = '✓';
    end
    
    status_recog = ' ';
    if results.recognition_success(idx)
        if results.confidence(idx) >= 0.7 && results.num_chars(idx) >= 5
            status_recog = '✓';
        else
            status_recog = '⚠';
        end
    end
    
    fprintf('%s%s %-26s | %8s | %-13s | %5.1f%% | %.2fs\n', ...
        status_detect, status_recog, ...
        results.filename{idx}, ...
        results.plate_detected{idx}, ...
        results.plate_text{idx}, ...
        results.confidence(idx)*100, ...
        results.processing_time(idx));
end

fprintf('\nLegend:\n');
fprintf('  ✓✓ = Detection + Recognition success\n');
fprintf('  ✓⚠ = Detected but low confidence/few chars\n');
fprintf('  ✗  = Detection failed\n');

%% Save Results

% Save MAT file
results_mat = fullfile(output_folder, 'full_pipeline_results.mat');
save(results_mat, 'results');
fprintf('\n✓ Saved: %s\n', results_mat);

% Save text file
results_txt = fullfile(output_folder, 'full_pipeline_results.txt');
fid = fopen(results_txt, 'w');

fprintf(fid, 'License Plate Recognition - Full Pipeline Results\n');
fprintf(fid, 'Generated: %s\n\n', datetime('now'));
fprintf(fid, 'Total images: %d\n', num_images);
fprintf(fid, 'Detection success: %d (%.1f%%)\n', ...
    sum(results.detection_success), ...
    100*sum(results.detection_success)/num_images);
fprintf(fid, 'Recognition success: %d (%.1f%%)\n\n', ...
    sum(results.recognition_success), ...
    100*sum(results.recognition_success)/num_images);

fprintf(fid, '%-30s | Detected | Plate Text    | Confidence | Time\n', 'Filename');
fprintf(fid, '%s\n', repmat('-', 1, 85));

for idx = 1:num_images
    fprintf(fid, '%-30s | %8s | %-13s | %9.1f%% | %.2fs\n', ...
        results.filename{idx}, ...
        mat2str(results.detection_success(idx)), ...
        results.plate_text{idx}, ...
        results.confidence(idx)*100, ...
        results.processing_time(idx));
end

fclose(fid);
fprintf('✓ Saved: %s\n', results_txt);

%% Create CSV for Excel
csv_file = fullfile(output_folder, 'results.csv');
fid = fopen(csv_file, 'w');
fprintf(fid, 'Filename,Detected,Plate_Text,Confidence,Num_Chars,Time_Sec\n');
for idx = 1:num_images
    fprintf(fid, '%s,%d,%s,%.3f,%d,%.2f\n', ...
        results.filename{idx}, ...
        results.detection_success(idx), ...
        results.plate_text{idx}, ...
        results.confidence(idx), ...
        results.num_chars(idx), ...
        results.processing_time(idx));
end
fclose(fid);
fprintf('✓ Saved: %s\n', csv_file);

fprintf('\n========================================\n');
fprintf('PROCESSING COMPLETED\n');
fprintf('========================================\n');