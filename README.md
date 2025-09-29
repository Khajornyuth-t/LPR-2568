# LPR-2568
License Plate Recognition System
# 🚗 License Plate Recognition System

โปรเจคระบบจดจำป้ายทะเบียนรถอัตโนมัติด้วย MATLAB  
**Course:** EN2143201 - Digital Image Processing  
**Institution:** RMUTP

---

## 👨‍🎓 ข้อมูลนักศึกษา

- **ชื่อ:** ขจรยุทธ ต้นภูบาล

---

## 📋 รายละเอียดโปรเจค

### วัตถุประสงค์
สร้างระบบจดจำป้ายทะเบียนรถอัตโนมัติที่สามารถ:
1. โหลดรูปภาพอัตโนมัติ (LPR0001.bmp - LPR0250.bmp)
2. ประมวลผลและจดจำตัวอักษร/ตัวเลขบนป้ายทะเบียน
3. บันทึกผลลัพธ์ลงไฟล์ Excel/CSV

### ตัวอย่างป้ายทะเบียน
- อ6355
- ตห2974
- ชณ9090

---

## 🛠️ เทคโนโลยีที่ใช้

- **MATLAB** (R2020b หรือสูงกว่า)
- **Image Processing Toolbox**
- **Computer Vision Toolbox** (optional)

---

## 📁 โครงสร้างโปรเจค

```
LPR-Project/
├── data/images/              # รูปภาพต้นฉบับ (250 รูป)
├── src/                      # Source Code หลัก
│   ├── main.m               # ไฟล์หลัก
│   ├── preprocessing/       # ฟังก์ชันปรับปรุงภาพ
│   ├── detection/           # ฟังก์ชันหาป้ายทะเบียน
│   ├── segmentation/        # ฟังก์ชันแยกตัวอักษร
│   └── recognition/         # ฟังก์ชัน OCR
├── templates/               # Database สำหรับ OCR
├── output/                  # ผลลัพธ์
│   └── output.xls          # ไฟล์ผลลัพธ์
├── utils/                   # ฟังก์ชันช่วยเหลือ
└── docs/                    # เอกสารและ presentation
```

---

## 🚀 วิธีใช้งาน

### 1. Clone Repository
```bash
git clone https://github.com/[your-username]/LPR-Project.git
cd LPR-Project
```

### 2. เตรียมข้อมูล
- วางไฟล์รูปภาพ LPR0001.bmp - LPR0250.bmp ใน folder `data/images/`

### 3. สร้าง Templates
```matlab
cd src
generateQuickTemplates();  % สร้าง OCR templates
```

### 4. รันโปรแกรม
```matlab
main();  % รันระบบหลัก
```

### 5. ดูผลลัพธ์
- ผลลัพธ์จะอยู่ที่: `output/output.xls`
- รูปภาพที่ประมวลผล: `output/processed_images/`

---

## 📊 ผลลัพธ์

### ตัวชี้วัดความสำเร็จ
- [ ] ระบบทำงานได้ครบทั้ง 250 รูป
- [ ] ความแม่นยำในการจดจำ: ____%
- [ ] เวลาประมวลผลเฉลี่ย: ___ วินาที/รูป

### ตัวอย่างผลลัพธ์
| No  | License Plate | Status    |
|-----|---------------|-----------|
| 1   | อ6355        | ✅ Success |
| 2   | ตห2974       | ✅ Success |
| 3   | ERROR        | ❌ Failed  |

---

## 🔬 เทคนิคที่ใช้

### 1. Image Preprocessing
- Grayscale conversion
- Noise reduction (Gaussian filter)
- Contrast enhancement (Histogram equalization)
- Edge detection (Canny)

### 2. License Plate Detection
- Morphological operations
- Rectangle contour detection
- Aspect ratio validation

### 3. Character Segmentation
- Binarization
- Connected component analysis
- Character boundary detection

### 4. Character Recognition (OCR)
- Template matching
- Correlation coefficient calculation
- Thai character & number recognition

---

## 📈 การประเมินผล

### จุดเด่น (Strengths)
- [ ] ระบบทำงานอัตโนมัติ
- [ ] ความแม่นยำสูง
- [ ] ประมวลผลเร็ว

### จุดด้อย (Weaknesses)
- [ ] ไม่สามารถจดจำป้ายที่มุมเอียงมาก
- [ ] ไวต่อแสงสว่าง
- [ ] ต้องปรับปรุง OCR สำหรับตัวอักษรบางตัว

### แนวทางพัฒนา (Future Work)
- [ ] ใช้ Deep Learning (CNN)
- [ ] รองรับป้ายทะเบียนหลายรูปแบบ
- [ ] ปรับปรุงความเร็ว

---

## 📚 เอกสารอ้างอิง

1. MATLAB Image Processing Toolbox Documentation
2. License Plate Recognition Techniques
3. Thai Character Recognition Methods

---

## 📝 License

This project is for educational purposes only.  
© 2025 RMUTP - Digital Image Processing Course

---

## 📞 ติดต่อ

- **Email:** [khajornyuth-t@rmutp.ac.th]
- **GitHub:** [github.com/khajornyuth-t]

---

**Last Updated:** September 30, 2025
