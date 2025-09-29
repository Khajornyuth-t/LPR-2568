function testTemplates()
% testTemplates - ทดสอบ templates ที่สร้างขึ้น
%
% คำอธิบาย:
%   ตรวจสอบคุณภาพและความถูกต้องของ templates
%   - ตรวจสอบความครบถ้วนของไฟล์
%   - แสดงตัวอย่างภาพ
%   - ตรวจสอบขนาดและรูปแบบไฟล์
%
% การทดสอบ:
%   1. ตรวจสอบไฟล์ครบ 55 ไฟล์
%   2. แสดงตัวอย่าง templates
%   3. ตรวจสอบขนาดและรูปแบบ binary
%
% หมายเหตุ: ไม่ทดสอบ I/1, O/0 เพราะไม่มีอักษรละติน
%
% วิธีใช้:
%   cd('LPR-2568/1.src')
%   testTemplates()
%
% ผู้เขียน: ขจรยุทธ ต้นภูบาล
% วิชา: EN2143201 - Digital Image Processing
% วันที่: 30 กันยายน 2568

fprintf('\n');
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('  TASK 2.3: ทดสอบ OCR Templates\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

%% โหลด mappings
fprintf('📂 โหลดข้อมูลตัวอักษร...\n');

if ~exist('../4.utils/char_mapping.mat', 'file')
    error('ไม่พบไฟล์ mapping! กรุณารัน createMappingFiles() ก่อน');
end

load('../4.utils/char_mapping.mat', 'mapping');
fprintf('   ✅ โหลดแล้ว: 4.utils/char_mapping.mat\n\n');

%% การทดสอบที่ 1: ตรวจสอบความครบถ้วนของไฟล์
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('การทดสอบที่ 1: ตรวจสอบความครบถ้วนของไฟล์\n');
fprintf('═══════════════════════════════════════════════════════════\n');

results = struct();

% ตัวเลข (0-9)
fprintf('ตัวเลข (0-9): ');
count = 0;
for i = 1:length(mapping.number_chars)
    filename = sprintf('../3.templates/numbers/%s.png', mapping.number_chars(i));
    if exist(filename, 'file')
        count = count + 1;
    end
end
results.numbers = count;
if count == 10
    fprintf('%d/%d ผ่าน ✅\n', count, 10);
else
    fprintf('%d/%d ไม่ผ่าน ❌\n', count, 10);
end

% อักษรไทย (ก-ฮ)
fprintf('อักษรไทย (ก-ฮ): ');
count = 0;
for i = 1:length(mapping.thai_chars)
    filename = sprintf('../3.templates/thai_chars/%s.png', mapping.thai_names{i});
    if exist(filename, 'file')
        count = count + 1;
    end
end
results.thai = count;
if count == 44
    fprintf('%d/%d ผ่าน ✅\n', count, 44);
else
    fprintf('%d/%d ไม่ผ่าน ❌\n', count, 44);
end

% อักขระพิเศษ (-)
fprintf('อักขระพิเศษ (-): ');
if exist('../3.templates/special/dash.png', 'file')
    results.special = 1;
    fprintf('1/1 ผ่าน ✅\n');
else
    results.special = 0;
    fprintf('0/1 ไม่ผ่าน ❌\n');
end

total_expected = 55;
total_found = results.numbers + results.thai + results.special;

fprintf('\nรวมทั้งหมด: %d/%d templates พบ', total_found, total_expected);
if total_found == total_expected
    fprintf(' - ผ่าน ✅\n\n');
else
    fprintf(' - ไม่ผ่าน ❌ (ขาดหาย %d ไฟล์)\n\n', total_expected - total_found);
end

%% การทดสอบที่ 2: ตรวจสอบด้วยสายตา
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('การทดสอบที่ 2: ตรวจสอบตัวอย่าง Templates\n');
fprintf('═══════════════════════════════════════════════════════════\n');

figure('Name', 'ตัวอย่าง Templates', 'Position', [100, 100, 1200, 600]);

% ตัวอย่างตัวเลข (0, 1, 5, 9)
subplot(2, 4, 1);
img = imread('../3.templates/numbers/0.png');
imshow(img); title('ตัวเลข: 0', 'FontSize', 12);

subplot(2, 4, 2);
img = imread('../3.templates/numbers/1.png');
imshow(img); title('ตัวเลข: 1', 'FontSize', 12);

subplot(2, 4, 3);
img = imread('../3.templates/numbers/5.png');
imshow(img); title('ตัวเลข: 5', 'FontSize', 12);

subplot(2, 4, 4);
img = imread('../3.templates/numbers/9.png');
imshow(img); title('ตัวเลข: 9', 'FontSize', 12);

% ตัวอย่างอักษรไทย (ก, ข, ท, ส)
subplot(2, 4, 5);
img = imread('../3.templates/thai_chars/kor_kai.png');
imshow(img); title('ไทย: ก (กอไก่)', 'FontSize', 12);

subplot(2, 4, 6);
img = imread('../3.templates/thai_chars/khor_khai.png');
imshow(img); title('ไทย: ข (ขอไข่)', 'FontSize', 12);

subplot(2, 4, 7);
img = imread('../3.templates/thai_chars/thor_thahan.png');
imshow(img); title('ไทย: ท (ทหาร)', 'FontSize', 12);

subplot(2, 4, 8);
img = imread('../3.templates/special/dash.png');
imshow(img); title('พิเศษ: -', 'FontSize', 12);

fprintf('✅ เปิดหน้าต่างตรวจสอบด้วยสายตาแล้ว\n\n');

%% การทดสอบที่ 3: ตรวจสอบขนาดและรูปแบบ
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('การทดสอบที่ 3: ตรวจสอบขนาดและรูปแบบไฟล์\n');
fprintf('═══════════════════════════════════════════════════════════\n');

% ตรวจสอบตัวอย่างไฟล์
test_files = {
    '../3.templates/numbers/5.png'; ...
    '../3.templates/thai_chars/kor_kai.png'; ...
    '../3.templates/thai_chars/thor_thahan.png'; ...
    '../3.templates/special/dash.png'
};

all_size_ok = true;
all_binary_ok = true;

for i = 1:length(test_files)
    img = imread(test_files{i});
    [h, w] = size(img);
    
    % ตรวจสอบขนาด
    if h == 42 && w == 24
        size_ok = true;
    else
        size_ok = false;
        all_size_ok = false;
    end
    
    % ตรวจสอบ binary (มีแค่ 0 และ 1)
    unique_vals = unique(img(:));
    if length(unique_vals) <= 2 && all(ismember(unique_vals, [0, 1]))
        binary_ok = true;
    else
        binary_ok = false;
        all_binary_ok = false;
    end
    
    [~, fname] = fileparts(test_files{i});
    fprintf('  %s: %dx%d', fname, h, w);
    
    if size_ok && binary_ok
        fprintf(' - ผ่าน ✅\n');
    else
        fprintf(' - ไม่ผ่าน ❌');
        if ~size_ok
            fprintf(' (ขนาดผิด)');
        end
        if ~binary_ok
            fprintf(' (ไม่เป็น binary)');
        end
        fprintf('\n');
    end
end

fprintf('\n');

%% สรุปผล
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('สรุปผลการทดสอบ TEMPLATES\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

fprintf('ผลการทดสอบ:\n');
fprintf('  1. ความครบถ้วน:       %d/%d', total_found, total_expected);
if total_found == total_expected
    fprintf(' - ผ่าน ✅\n');
else
    fprintf(' - ไม่ผ่าน ❌\n');
end

fprintf('  2. ตรวจสอบด้วยสายตา: ดูหน้าต่างรูปภาพ\n');

fprintf('  3. ขนาด/รูปแบบ:       ');
if all_size_ok && all_binary_ok
    fprintf('ผ่าน ✅\n');
else
    fprintf('ไม่ผ่าน ❌\n');
end

fprintf('\n');

% ประเมินโดยรวม
if total_found == 55 && all_size_ok && all_binary_ok
    fprintf('สรุปโดยรวม: ผ่านการทดสอบทั้งหมด ✅\n');
    fprintf('Templates พร้อมใช้งานสำหรับการจดจำตัวอักษร!\n\n');
else
    fprintf('สรุปโดยรวม: มีบางส่วนไม่ผ่านการทดสอบ ❌\n');
    fprintf('กรุณาตรวจสอบปัญหาด้านบน\n\n');
end

fprintf('📊 สถิติ Templates:\n');
fprintf('   • ตัวเลข:        %d templates\n', results.numbers);
fprintf('   • อักษรไทย:      %d templates\n', results.thai);
fprintf('   • อักขระพิเศษ:    %d template\n', results.special);
fprintf('   ───────────────────────────────\n');
fprintf('   • รวมทั้งหมด:    %d templates\n\n', total_found);

fprintf('ℹ️  หมายเหตุ:\n');
fprintf('   - ไม่มีอักษรละติน (A-Z) เพราะป้ายไทยไม่ใช้\n');
fprintf('   - ป้ายเหลือง: XX-XXXX (ตัวเลข-ตัวเลข)\n');
fprintf('   - ป้ายขาว: คค XXXX (ไทย-ตัวเลข)\n\n');

fprintf('⏭️  ขั้นตอนต่อไป:\n');
fprintf('   Templates พร้อมใช้งานใน TASK 6 (การจดจำตัวอักษร)\n');
fprintf('   จะถูกโหลดโดยฟังก์ชัน recognizeCharacter()\n\n');

fprintf('═══════════════════════════════════════════════════════════\n\n');

end