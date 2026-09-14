-- ============================================================
-- Communication Asset Management System (CAMS) - Standalone V1
-- Database Schema for MySQL 8.x
-- RTAF RCC — ระบบควบคุมทะเบียนอุปกรณ์สื่อสาร
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- 1) SECURITY / RBAC
-- ============================================================

CREATE TABLE roles (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    code            VARCHAR(30) NOT NULL UNIQUE,   -- SUPER_ADMIN, UNIT_ADMIN, OFFICER, APPROVER, VIEWER
    name            VARCHAR(100) NOT NULL,
    description     VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE permissions (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    code            VARCHAR(60) NOT NULL UNIQUE,   -- e.g. ASSET_CREATE, TRANSFER_APPROVE
    module          VARCHAR(60) NOT NULL,
    description     VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE role_permissions (
    role_id         INT NOT NULL,
    permission_id   INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id),
    FOREIGN KEY (permission_id) REFERENCES permissions(id)
) ENGINE=InnoDB;

-- ============================================================
-- 2) ORGANIZATION
-- ============================================================

CREATE TABLE units (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    code            VARCHAR(30) NOT NULL UNIQUE,
    name            VARCHAR(150) NOT NULL,
    parent_unit_id  INT NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    FOREIGN KEY (parent_unit_id) REFERENCES units(id)
) ENGINE=InnoDB;

CREATE TABLE personnel (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    rank            VARCHAR(30),
    full_name       VARCHAR(150) NOT NULL,
    unit_id         INT NOT NULL,
    position        VARCHAR(100),
    phone           VARCHAR(30),
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    FOREIGN KEY (unit_id) REFERENCES units(id)
) ENGINE=InnoDB;

CREATE TABLE locations (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    unit_id         INT NOT NULL,
    name            VARCHAR(150) NOT NULL,
    description     VARCHAR(255),
    FOREIGN KEY (unit_id) REFERENCES units(id)
) ENGINE=InnoDB;

CREATE TABLE users (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    username        VARCHAR(60) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(150) NOT NULL,
    role_id         INT NOT NULL,
    unit_id         INT NULL,
    personnel_id    INT NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    last_login_at   DATETIME NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(id),
    FOREIGN KEY (unit_id) REFERENCES units(id),
    FOREIGN KEY (personnel_id) REFERENCES personnel(id)
) ENGINE=InnoDB;

-- ============================================================
-- 3) ASSET MASTER DATA
-- ============================================================

CREATE TABLE asset_categories (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE asset_models (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    category_id     INT NOT NULL,
    brand           VARCHAR(100),
    model           VARCHAR(100) NOT NULL,
    part_number     VARCHAR(100),
    nsn             VARCHAR(50),
    FOREIGN KEY (category_id) REFERENCES asset_categories(id)
) ENGINE=InnoDB;

CREATE TABLE asset_statuses (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    code            VARCHAR(30) NOT NULL UNIQUE,   -- IN_STOCK, ASSIGNED, BORROWED, REPAIR, DAMAGED, LOST, INSPECTION, DISPOSAL, DISPOSED
    name_th         VARCHAR(100) NOT NULL,         -- แก้ไขได้โดย Admin ให้ตรงระเบียบจริง
    sort_order      INT DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE assets (
    id                      INT PRIMARY KEY AUTO_INCREMENT,
    asset_code              VARCHAR(30) NOT NULL UNIQUE,   -- COM-000001
    model_id                INT NOT NULL,
    serial_number           VARCHAR(100),
    asset_number            VARCHAR(100),
    received_date           DATE,
    purchase_date           DATE,
    warranty_expire_date    DATE,
    status_id               INT NOT NULL,
    current_unit_id         INT NULL,
    current_holder_id       INT NULL,               -- personnel.id
    current_location_id     INT NULL,
    `condition`             VARCHAR(50),
    remarks                 TEXT,
    created_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (model_id) REFERENCES asset_models(id),
    FOREIGN KEY (status_id) REFERENCES asset_statuses(id),
    FOREIGN KEY (current_unit_id) REFERENCES units(id),
    FOREIGN KEY (current_holder_id) REFERENCES personnel(id),
    FOREIGN KEY (current_location_id) REFERENCES locations(id),
    INDEX idx_assets_status (status_id),
    INDEX idx_assets_unit (current_unit_id),
    INDEX idx_assets_serial (serial_number)
) ENGINE=InnoDB;

-- ============================================================
-- 4) DOCUMENTS & TRANSACTIONS
-- ============================================================

CREATE TABLE documents (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    doc_number      VARCHAR(40) NOT NULL UNIQUE,    -- REC-2569-000001, TRF-2569-000001, ...
    doc_type        VARCHAR(20) NOT NULL,           -- RECEIVE/ISSUE/TRANSFER/BORROW/REPAIR/INSPECTION/DISPOSAL
    doc_date        DATE NOT NULL,
    ref_note        VARCHAR(255),
    created_by      INT NOT NULL,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE transactions (
    id                  INT PRIMARY KEY AUTO_INCREMENT,
    doc_id              INT NOT NULL,
    transaction_type    VARCHAR(20) NOT NULL,   -- RECEIVE/ISSUE/TRANSFER/BORROW/RETURN/REPAIR_SEND/REPAIR_RETURN/INSPECTION/DISPOSAL
    transaction_date    DATETIME NOT NULL,
    from_personnel_id   INT NULL,
    to_personnel_id     INT NULL,
    from_unit_id        INT NULL,
    to_unit_id          INT NULL,
    from_location_id    INT NULL,
    to_location_id      INT NULL,
    reason              TEXT,
    performed_by        INT NOT NULL,
    approved_by         INT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- PENDING/APPROVED/REJECTED/COMPLETED
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (doc_id) REFERENCES documents(id),
    FOREIGN KEY (from_personnel_id) REFERENCES personnel(id),
    FOREIGN KEY (to_personnel_id) REFERENCES personnel(id),
    FOREIGN KEY (from_unit_id) REFERENCES units(id),
    FOREIGN KEY (to_unit_id) REFERENCES units(id),
    FOREIGN KEY (from_location_id) REFERENCES locations(id),
    FOREIGN KEY (to_location_id) REFERENCES locations(id),
    FOREIGN KEY (performed_by) REFERENCES users(id),
    FOREIGN KEY (approved_by) REFERENCES users(id),
    INDEX idx_tx_type_date (transaction_type, transaction_date)
) ENGINE=InnoDB;

CREATE TABLE transaction_items (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    transaction_id  INT NOT NULL,
    asset_id        INT NOT NULL,
    remarks         VARCHAR(255),
    FOREIGN KEY (transaction_id) REFERENCES transactions(id),
    FOREIGN KEY (asset_id) REFERENCES assets(id),
    INDEX idx_txitems_asset (asset_id)
) ENGINE=InnoDB;

-- ============================================================
-- 5) BORROW / REPAIR (extension detail of a transaction)
-- ============================================================

CREATE TABLE borrow_records (
    id                  INT PRIMARY KEY AUTO_INCREMENT,
    transaction_id      INT NOT NULL,
    asset_id            INT NOT NULL,
    borrower_id         INT NOT NULL,       -- personnel.id
    borrow_date         DATE NOT NULL,
    due_date            DATE NOT NULL,
    return_date         DATE NULL,
    condition_on_return VARCHAR(50) NULL,
    approved_by         INT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'BORROWED', -- BORROWED/RETURNED/OVERDUE
    FOREIGN KEY (transaction_id) REFERENCES transactions(id),
    FOREIGN KEY (asset_id) REFERENCES assets(id),
    FOREIGN KEY (borrower_id) REFERENCES personnel(id),
    FOREIGN KEY (approved_by) REFERENCES users(id),
    INDEX idx_borrow_status (status)
) ENGINE=InnoDB;

CREATE TABLE repair_records (
    id                  INT PRIMARY KEY AUTO_INCREMENT,
    transaction_id      INT NOT NULL,
    asset_id            INT NOT NULL,
    issue_description   TEXT,
    inspection_result   TEXT,
    sent_date           DATE,
    repair_vendor       VARCHAR(150),
    cost                DECIMAL(12,2) DEFAULT 0,
    returned_date       DATE NULL,
    repair_result       VARCHAR(50),        -- ซ่อมสำเร็จ / ซ่อมไม่ได้ / รออะไหล่ ฯลฯ
    status              VARCHAR(20) NOT NULL DEFAULT 'SENT',   -- SENT/IN_PROGRESS/RETURNED
    FOREIGN KEY (transaction_id) REFERENCES transactions(id),
    FOREIGN KEY (asset_id) REFERENCES assets(id)
) ENGINE=InnoDB;

-- ============================================================
-- 6) INSPECTION
-- ============================================================

CREATE TABLE inspection_headers (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    doc_id          INT NOT NULL,
    inspection_name VARCHAR(150) NOT NULL,   -- "ตรวจสอบอุปกรณ์ประจำปี 2569"
    inspection_date DATE NOT NULL,
    unit_id         INT NULL,
    performed_by    INT NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'OPEN',  -- OPEN/CLOSED
    FOREIGN KEY (doc_id) REFERENCES documents(id),
    FOREIGN KEY (unit_id) REFERENCES units(id),
    FOREIGN KEY (performed_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE inspection_items (
    id                      INT PRIMARY KEY AUTO_INCREMENT,
    inspection_header_id    INT NOT NULL,
    asset_id                INT NOT NULL,
    found                   TINYINT(1) NOT NULL DEFAULT 1,
    `condition`             VARCHAR(50),
    location_correct        TINYINT(1) NOT NULL DEFAULT 1,
    holder_correct          TINYINT(1) NOT NULL DEFAULT 1,
    remarks                 VARCHAR(255),
    FOREIGN KEY (inspection_header_id) REFERENCES inspection_headers(id),
    FOREIGN KEY (asset_id) REFERENCES assets(id)
) ENGINE=InnoDB;

-- ============================================================
-- 7) SYSTEM: AUDIT, SETTINGS
-- ============================================================

CREATE TABLE audit_logs (
    id              BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id         INT NOT NULL,
    action          VARCHAR(50) NOT NULL,     -- CREATE/UPDATE/APPROVE/TRANSFER/...
    table_name      VARCHAR(60) NOT NULL,
    record_id       INT NOT NULL,
    old_value       JSON NULL,
    new_value       JSON NULL,
    ip_address      VARCHAR(45),
    device          VARCHAR(255),
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    INDEX idx_audit_table_record (table_name, record_id),
    INDEX idx_audit_created (created_at)
) ENGINE=InnoDB;

CREATE TABLE system_settings (
    `key`           VARCHAR(60) PRIMARY KEY,
    `value`         VARCHAR(500),
    description     VARCHAR(255)
) ENGINE=InnoDB;

-- ============================================================
-- Seed: default statuses / roles (ปรับแก้ได้ภายหลังตามระเบียบจริง)
-- ============================================================

INSERT INTO roles (code, name) VALUES
 ('SUPER_ADMIN','ผู้ดูแลระบบสูงสุด'),
 ('UNIT_ADMIN','ผู้ดูแลข้อมูลหน่วย'),
 ('OFFICER','เจ้าหน้าที่ปฏิบัติการ'),
 ('APPROVER','ผู้อนุมัติ'),
 ('VIEWER','ผู้ดูข้อมูล');

INSERT INTO asset_statuses (code, name_th, sort_order) VALUES
 ('IN_STOCK','อยู่ในคลัง',1),
 ('ASSIGNED','จ่าย/ครอบครอง',2),
 ('BORROWED','ยืม',3),
 ('REPAIR','ส่งซ่อม',4),
 ('DAMAGED','ชำรุด',5),
 ('LOST','สูญหาย',6),
 ('INSPECTION','รอตรวจสอบ',7),
 ('DISPOSAL','รอจำหน่าย',8),
 ('DISPOSED','จำหน่ายแล้ว',9);

SET FOREIGN_KEY_CHECKS = 1;
