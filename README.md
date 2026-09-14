# CAMS — Communication Asset Management System

ระบบควบคุมทะเบียนอุปกรณ์สื่อสาร สำหรับ RTAF RCC (Rescue Coordination Centre) — Standalone V1

ระบบสำหรับควบคุมวงจรชีวิตของอุปกรณ์สื่อสารแต่ละรายการ ตั้งแต่ รับเข้า → เก็บรักษา → เบิกจ่าย → ครอบครอง → โอน → ยืม → คืน → ซ่อม → ตรวจสอบ → จำหน่าย พร้อมระบบตรวจสอบย้อนหลัง (Audit Trail) ครบทุกรายการ

## สถานะโปรเจกต์

🟡 **Prototype / UI-UX phase** — ยังไม่ใช่ระบบที่ใช้งานจริง เป็นการสาธิตหน้าจอและ workflow ก่อนเข้าสู่ขั้นพัฒนา backend จริง

## โครงสร้างโปรเจกต์

```
.
├── index.html              ← Interactive UI Prototype (เปิดได้ทันทีใน browser / GitHub Pages)
├── docs/
│   └── CAMS-System-Design.md   ← เอกสารออกแบบระบบฉบับเต็ม (Architecture, ERD, Workflow, API, Role Matrix)
└── database/
    └── schema.sql           ← MySQL 8 schema (~20 ตาราง) ตาม ERD ในเอกสารออกแบบ
```

## ดูตัวอย่าง (Demo)

เปิด `index.html` ใน browser ได้โดยตรง หรือถ้าเปิด GitHub Pages ของ repo นี้ไว้ จะเข้าดูได้ที่:

```
https://<username>.github.io/<repo-name>/
```

โหมดสาธิต — ข้อมูลทั้งหมดเป็นข้อมูลจำลอง (mock data) ทำงานฝั่ง client อย่างเดียว ไม่มีการเชื่อมต่อฐานข้อมูลจริง

## เทคโนโลยีเป้าหมาย (สำหรับพัฒนาจริง)

| ชั้น | เทคโนโลยี |
|---|---|
| Frontend | Bootstrap 5 + Vanilla JS (Responsive / PWA) |
| Backend | PHP 8 + CodeIgniter 4 (MVC) |
| Database | MySQL 8 |
| Deployment | Internal/Standalone server เท่านั้น (ไม่มี Internet / Cloud) |

## ฟีเจอร์ที่ทำใน Prototype แล้ว

- Dashboard: KPI สรุปภาพรวม + รายการแจ้งเตือน (เกินกำหนดคืน, ซ่อมค้าง, ยังไม่ตรวจสอบ)
- ทะเบียนอุปกรณ์: ค้นหา/กรองแบบ real-time (Asset Code, S/N, รุ่น, ผู้ครอบครอง, สถานะ, หน่วย)
- รายละเอียดอุปกรณ์: ข้อมูลเต็ม + QR Code (mock) + Life History + แนบเอกสาร/รูปภาพไม่จำกัดจำนวน
- Workflow โอนอุปกรณ์ (Transfer) แบบ step-by-step
- Workflow จำหน่ายอุปกรณ์ (Disposal) พร้อมปุ่มย้อนกลับก่อนยืนยันถาวร
- รายการยืม-คืน พร้อม highlight รายการเกินกำหนด (OVERDUE)

โมดูลอื่นที่เหลือ (รับเข้า, เบิกจ่าย, ครอบครอง, ซ่อม, ตรวจสอบ, รายงาน, ผู้ดูแลระบบ) อยู่ระหว่างพัฒนา UI ตาม workflow ที่ระบุไว้ใน `docs/CAMS-System-Design.md`

## หมายเหตุสำคัญ

รายการต่อไปนี้เป็น **ค่าตั้งต้นที่ปรับได้** รอเทียบกับระเบียบกองทัพอากาศฉบับที่หน่วยใช้งานจริงก่อน finalize:
- ชื่อสถานะ Asset
- คำเรียกทางราชการของแต่ละเอกสาร
- ลำดับชั้นและผู้มีอำนาจอนุมัติในแต่ละกระบวนการ

ดูรายละเอียดทั้งหมดใน [`docs/CAMS-System-Design.md`](docs/CAMS-System-Design.md)
