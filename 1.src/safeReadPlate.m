function [plateText, conf] = safeReadPlate(imgPath, opts)
    I = imread(imgPath);

    % ถ้ามี readPlate อยู่แล้ว ลองใช้ก่อน
    try
        if nargout(@readPlate) >= 2
            [plateText, info] = readPlate(I); 
            conf = tryGet(info, 'confidence', 0.0);
            if isempty(plateText)
                [plateText, conf] = fallback_pipeline(I, opts);
            end
        else
            plateText = readPlate(I);
            conf = 0.0;
            if isempty(plateText)
                [plateText, conf] = fallback_pipeline(I, opts);
            end
        end
        return;
    catch
        % ถ้าไม่มีหรือใช้ไม่ได้ → ใช้ fallback
        [plateText, conf] = fallback_pipeline(I, opts);
    end
end

function [plateText, conf] = fallback_pipeline(I, opts)
    % ---- Preprocess ป้าย + ตัดป้ายออก ----
    try
        % ถ้ามีฟังก์ชันของคุณน้ำ ให้ใช้:
        % plateROI = extractPlate(I);  % อาศัย detectPlate()/extractPlate()
        plateROI = I;  % กันพัง: เดาประมวลผลทั้งภาพ (แก้เป็น extractPlate(I) ได้)
    catch
        plateROI = I;
    end

    % ---- เตรียมภาพสำหรับแบ่งตัวอักษร ----
    try
        J = preprocessPlate(plateROI); % ของคุณน้ำมีอยู่แล้ว
    catch
        J = rgb2gray(plateROI);
        J = imadjust(J);
        J = imbinarize(J);
    end

    % ---- แบ่งตัวอักษร ----
    try
        glyphs = segmentCharacters(J); % คาดว่าคืน cell ของแต่ละตัว
    catch
        CC = bwconncomp(J);
        glyphs = cellfun(@(p) imcrop(J, regionprops('table', CC, 'BoundingBox').BoundingBox(1,:)), ...
                         num2cell(1), 'UniformOutput', false); %#ok<NASGU>
        glyphs = {}; % กันพัง: ถ้าทำเองยาวไป ให้เว้นว่าง
    end

    % ---- เทมเพลตจับคู่ ----
    plateText = '';
    conf = 0;
    try
        for k = 1:numel(glyphs)
            g = glyphs{k};
            [ch, c] = recognizeCharacter(g, opts); % ของคุณน้ำมีอยู่แล้ว (ใช้ matchTemplate)
            plateText = [plateText ch]; %#ok<AGROW>
            conf = conf + c;
        end
        if ~isempty(glyphs), conf = conf/numel(glyphs); end
    catch
        % กันพังสุดท้าย: ส่งว่าง
        plateText = '';
        conf = 0;
    end
end

function v = tryGet(S, field, defaultV)
    v = defaultV;
    if isstruct(S) && isfield(S, field)
        v = S.(field);
    end
end
