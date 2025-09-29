function createMappingFiles()
% createMappingFiles - สร้างไฟล์ mapping สำหรับ characters ทั้งหมด
%
% คำอธิบาย:
%   สร้างฐานข้อมูลตัวอักษรสำหรับป้ายทะเบียนไทย 55 ตัว
%   - Numbers: 0-9 (10 ตัว)
%   - Thai consonants: ก-ฮ (44 ตัว)
%   - Special: - (dash) (1 ตัว)
%
% หมายเหตุ: ไม่รวมอักษรละติน (A-Z) เพราะป้ายทะเบียนไทยไม่มี
%   - Type 1 (เหลือง): XX-XXXX (ตัวเลข-ตัวเลข เท่านั้น)
%   - Type 2 (ขาว): คค 3534 (ไทย เว้นวรรค ตัวเลข)
%
% Output Files:
%   4.utils/char_mapping.mat      - MATLAB data structure
%   4.utils/thai_unicode.txt      - Thai character reference
%   4.utils/number_mapping.txt    - Number reference
%
% วิธีใช้:
%   cd('LPR-2568/1.src')
%   createMappingFiles()
%
% ผู้เขียน: ขจรยุทธ ต้นภูบาล
% วิชา: EN2143201 - Digital Image Processing
% วันที่: 30 กันยายน 2568

fprintf('\n');
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('  TASK 2.1: สร้างไฟล์ Mapping ตัวอักษร\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

%% 1. กำหนดอักษรไทย (44 พยัญชนะ)
fprintf('📝 ขั้นตอนที่ 1/3: กำหนดอักษรไทย...\n');

% พยัญชนะไทยที่ใช้ในป้ายทะเบียน (ก-ฮ, 44 ตัว)
thai_chars = ['ก','ข','ฃ','ค','ฅ','ฆ','ง',...
              'จ','ฉ','ช','ซ','ฌ','ญ',...
              'ฎ','ฏ','ฐ','ฑ','ฒ','ณ',...
              'ด','ต','ถ','ท','ธ','น',...
              'บ','ป','ผ','ฝ','พ','ฟ','ภ','ม',...
              'ย','ร','ฤ','ล','ฦ','ว',...
              'ศ','ษ','ส','ห','ฬ','อ','ฮ'];

% ชื่อเสียงไทย (สำหรับชื่อไฟล์)
thai_names = {'kor_kai','khor_khai','khor_khuat','khor_khwai','khor_khon',...
              'khor_rakhang','ngor_ngu',...
              'jor_jan','chor_ching','chor_chang','sor_so','chor_choe','yor_ying',...
              'dor_chada','tor_patak','thor_than','thor_montho','thor_phuthao','nor_nen',...
              'dor_dek','tor_tao','thor_thung','thor_thahan','thor_thong','nor_nu',...
              'bor_baimai','por_pla','phor_phung','for_fa','phor_phan','for_fan','phor_samphao','mor_ma',...
              'yor_yak','ror_rua','rue','lor_ling','lue','wor_waen',...
              'sor_sala','sor_rusi','sor_suea','hor_hip','lor_chula','or_ang','hor_nokhuk'};

fprintf('   ✅ พยัญชนะไทย: %d ตัว\n', length(thai_chars));

%% 2. กำหนดตัวเลข (0-9)
fprintf('📝 ขั้นตอนที่ 2/3: กำหนดตัวเลข...\n');

number_chars = '0123456789';

fprintf('   ✅ ตัวเลข: %d ตัว\n', length(number_chars));

%% 3. กำหนดอักขระพิเศษ
fprintf('📝 ขั้นตอนที่ 3/3: กำหนดอักขระพิเศษ...\n');

special_chars = '-';

fprintf('   ✅ อักขระพิเศษ: %d ตัว (dash)\n', length(special_chars));
fprintf('   ℹ️  หมายเหตุ: ป้ายทะเบียนไทยไม่มีอักษรละติน (A-Z)\n');

%% 4. สร้าง mapping structure
fprintf('\n💾 สร้าง mapping structure...\n');

mapping = struct();
mapping.thai_chars = thai_chars;
mapping.thai_names = thai_names;
mapping.number_chars = number_chars;
mapping.special_chars = special_chars;

% สรุปจำนวน
mapping.total = length(thai_chars) + length(number_chars) + length(special_chars);

fprintf('   ✅ จำนวนตัวอักษรทั้งหมด: %d\n', mapping.total);

%% 5. สร้างโฟลเดอร์
fprintf('\n💾 บันทึกไฟล์...\n');

if ~exist('../4.utils', 'dir')
    mkdir('../4.utils');
    fprintf('   ✅ สร้างโฟลเดอร์: 4.utils/\n');
end

%% 6. บันทึกไฟล์ MATLAB data
save('../4.utils/char_mapping.mat', 'mapping');
fprintf('   ✅ บันทึกแล้ว: 4.utils/char_mapping.mat\n');

%% 7. สร้างไฟล์อ้างอิง Thai Unicode
fid = fopen('../4.utils/thai_unicode.txt', 'w', 'n', 'UTF-8');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');
fprintf(fid, 'Thai Character Mapping for License Plate Recognition\n');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');
fprintf(fid, 'จำนวน: %d พยัญชนะไทย (ก-ฮ)\n', length(thai_chars));
fprintf(fid, 'สร้างเมื่อ: %s\n', datetime('now', 'Format', 'dd-MMM-yyyy HH:mm:ss'));
fprintf(fid, '═══════════════════════════════════════════════════════════\n\n');

fprintf(fid, 'ลำดับ\tตัวอักษร\tชื่อไฟล์\t\tUnicode\n');
fprintf(fid, '───────────────────────────────────────────────────────────\n');

for i = 1:length(thai_chars)
    fprintf(fid, '%2d\t%s\t%-20s\tU+%04X\n', ...
            i, ...
            thai_chars(i), ...
            [thai_names{i} '.png'], ...
            double(thai_chars(i)));
end

fprintf(fid, '\n═══════════════════════════════════════════════════════════\n');
fprintf(fid, 'ตัวอย่างจากป้ายทะเบียนจริง:\n');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');
fprintf(fid, '  กก 3534   (กอไก่ กอไก่)\n');
fprintf(fid, '  ศร 1818   (ศอศาลา รอเรือ)\n');
fprintf(fid, '  ฌต 936    (ฌอเฌอ ตอเต่า)\n');
fprintf(fid, '  ทป 9784   (ทหาร ปอปลา)\n');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');

fclose(fid);
fprintf('   ✅ บันทึกแล้ว: 4.utils/thai_unicode.txt\n');

%% 8. สร้างไฟล์อ้างอิงตัวเลข
fid = fopen('../4.utils/number_mapping.txt', 'w', 'n', 'UTF-8');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');
fprintf(fid, 'Number & Special Character Mapping\n');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');
fprintf(fid, 'จำนวน: %d ตัวอักษร\n', length(number_chars) + length(special_chars));
fprintf(fid, 'สร้างเมื่อ: %s\n', datetime('now', 'Format', 'dd-MMM-yyyy HH:mm:ss'));
fprintf(fid, '═══════════════════════════════════════════════════════════\n\n');

% ตัวเลข
fprintf(fid, '1. ตัวเลข (10 ตัว)\n');
fprintf(fid, '───────────────────────────────────────────────────────────\n');
fprintf(fid, '%s\n\n', number_chars);

for i = 1:length(number_chars)
    char_val = number_chars(i);
    fprintf(fid, '%c\t→\t%c.png\t(U+%04X)\n', char_val, char_val, double(char_val));
end

% อักขระพิเศษ
fprintf(fid, '\n2. อักขระพิเศษ (1 ตัว)\n');
fprintf(fid, '───────────────────────────────────────────────────────────\n');
fprintf(fid, '%s\t→\tdash.png\t(U+%04X)\n', special_chars, double(special_chars));

% หมายเหตุ
fprintf(fid, '\n═══════════════════════════════════════════════════════════\n');
fprintf(fid, 'หมายเหตุ\n');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');
fprintf(fid, 'ป้ายทะเบียนไทยไม่มีอักษรละติน (A-Z)\n\n');
fprintf(fid, 'รูปแบบป้ายทะเบียน:\n');
fprintf(fid, '  Type 1 (พื้นเหลือง): XX-XXXX\n');
fprintf(fid, '    ตัวอย่าง: 14-3238, 15-2578\n');
fprintf(fid, '    รูปแบบ: ตัวเลข ขีด ตัวเลข\n\n');
fprintf(fid, '  Type 2 (พื้นขาว): คค XXXX\n');
fprintf(fid, '    ตัวอย่าง: กก 3534, ศร 1818\n');
fprintf(fid, '    รูปแบบ: ไทย เว้นวรรค ตัวเลข\n');
fprintf(fid, '═══════════════════════════════════════════════════════════\n');

fclose(fid);
fprintf('   ✅ บันทึกแล้ว: 4.utils/number_mapping.txt\n');

%% 9. สรุปผล
fprintf('\n');
fprintf('═══════════════════════════════════════════════════════════\n');
fprintf('✅ สร้างไฟล์ MAPPING สำเร็จ!\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

fprintf('📊 สรุป:\n');
fprintf('   • พยัญชนะไทย:   %2d ตัว\n', length(thai_chars));
fprintf('   • ตัวเลข:        %2d ตัว\n', length(number_chars));
fprintf('   • อักขระพิเศษ:   %2d ตัว\n', length(special_chars));
fprintf('   ─────────────────────────────────────\n');
fprintf('   • รวมทั้งหมด:    %2d ตัว\n', mapping.total);
fprintf('\n');

fprintf('📁 ไฟล์ที่สร้าง:\n');
fprintf('   ✅ 4.utils/char_mapping.mat      (MATLAB data)\n');
fprintf('   ✅ 4.utils/thai_unicode.txt      (อ้างอิงภาษาไทย)\n');
fprintf('   ✅ 4.utils/number_mapping.txt    (อ้างอิงตัวเลข)\n');
fprintf('\n');

fprintf('⏭️  ขั้นตอนต่อไป:\n');
fprintf('   รัน: generateQuickTemplates()\n');
fprintf('   จะสร้าง 55 template images ใน 3.templates/\n');
fprintf('\n');
fprintf('═══════════════════════════════════════════════════════════\n\n');

end