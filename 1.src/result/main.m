function main()
% MAIN  Batch OCR ป้ายทะเบียน LPR0001.bmp–LPR0250.bmp และบันทึกผล CSV/XLSX
% - ไม่พึ่ง pwd: หาโฟลเดอร์รากจากตำแหน่งไฟล์ main.m โดยตรง
% - เขียนผลลัพธ์ไปที่ 5.output/output.csv และ 5.output/output.xlsx
% - แสดงสรุปจำนวน SUCCESS และ Accuracy

    % ===== ระบุตำแหน่งโปรเจ็กต์จากไฟล์นี้เอง =====
    srcDir  = fileparts(mfilename('fullpath'));   % ...\LPR-2568\1.src
    rootDir = fileparts(srcDir);                  % ...\LPR-2568

    % ===== ตั้ง path และโฟลเดอร์หลัก =====
    addpath(genpath(srcDir));                     % ให้ MATLAB เห็นฟังก์ชันทั้งหมดใน 1.src
    imagesDir    = fullfile(rootDir, '2.data', 'images');
    templatesDir = fullfile(rootDir, '3.templates');
    outDir       = fullfile(rootDir, '5.output');
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    % ===== ชื่อไฟล์ผลลัพธ์ =====
    outCSV  = fullfile(outDir, 'output.csv');
    outXLSX = fullfile(outDir, 'output.xlsx');

    % ===== ตัวเลือกการรัน (opts) =====
    opts = struct();
    opts.templatesDir = templatesDir;
    opts.saveDebug    = false;
    opts.verbose      = true;

    % ===== ตรวจโฟลเดอร์ภาพแบบกันพลาด =====
    if ~exist(imagesDir, 'dir')
        error('ไม่พบโฟลเดอร์รูปภาพ: %s', imagesDir);
    end
    files = dir(fullfile(imagesDir, 'LPR*.bmp'));
    if isempty(files)
        warning('ไม่พบไฟล์รูปแบบ LPR*.bmp ใน %s', imagesDir);
    end

    % ===== รัน Batch OCR =====
    ticOverall = tic;
    results = batchProcessAll_LPR2568(imagesDir, opts);

    % ===== บันทึกผลลัพธ์ =====
    T = struct2table(results);
    try
        writetable(T, outCSV);
        fprintf('เขียนไฟล์ผลลัพธ์: %s\n', outCSV);
    catch ME
        warning('%s', ['เขียน CSV ไม่สำเร็จ: ' ME.message]);

    end

    try
        writetable(T, outXLSX);
        fprintf('เขียนไฟล์ผลลัพธ์: %s\n', outXLSX);
    catch ME
        warning('MATLAB:WriteXLSX', 'เขียน XLSX ไม่สำเร็จ: %s', ME.message);
    end

    % ===== สรุปผลบนหน้าจอ =====
    statuses = string({results.status});
    totalN   = numel(results);
    succN    = sum(statuses == "SUCCESS");
    accPct   = 100 * (succN / max(totalN, 1));

    fprintf('\n===== SUMMARY =====\n');
    fprintf('Images:   %d\n', totalN);
    fprintf('SUCCESS:  %d\n', succN);
    fprintf('Accuracy: %.2f%%\n', accPct);
    fprintf('Elapsed:  %.2fs\n', toc(ticOverall));
end
