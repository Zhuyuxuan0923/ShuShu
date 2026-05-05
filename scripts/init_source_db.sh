#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE source_db;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d source_db <<-EOSQL
    CREATE SCHEMA IF NOT EXISTS business;

    -- ============================================================
    -- 客户表
    -- ============================================================
    CREATE TABLE IF NOT EXISTS business.customers (
        customer_id   INTEGER PRIMARY KEY,
        customer_name VARCHAR(100) NOT NULL,
        email         VARCHAR(200),
        phone         VARCHAR(30),
        city          VARCHAR(100),
        register_date DATE NOT NULL DEFAULT CURRENT_DATE,
        customer_type VARCHAR(20) NOT NULL DEFAULT 'individual'
    );

    -- ============================================================
    -- 订单表
    -- ============================================================
    CREATE TABLE IF NOT EXISTS business.orders (
        order_id       INTEGER PRIMARY KEY,
        customer_id    INTEGER NOT NULL REFERENCES business.customers(customer_id),
        order_date     TIMESTAMP NOT NULL DEFAULT NOW(),
        order_status   VARCHAR(20) NOT NULL DEFAULT 'processing',
        payment_method VARCHAR(20),
        total_amount   DECIMAL(12,2) NOT NULL DEFAULT 0,
        currency       VARCHAR(10) DEFAULT 'CNY'
    );

    -- ============================================================
    -- 订单明细表
    -- ============================================================
    CREATE TABLE IF NOT EXISTS business.order_items (
        item_id       INTEGER PRIMARY KEY,
        order_id      INTEGER NOT NULL REFERENCES business.orders(order_id),
        product_name  VARCHAR(200) NOT NULL,
        quantity      INTEGER NOT NULL DEFAULT 1,
        unit_price    DECIMAL(10,2) NOT NULL,
        discount_pct  DECIMAL(5,2) DEFAULT 0.00
    );

    -- ============================================================
    -- 种子数据: 20 位客户
    -- ============================================================
    TRUNCATE business.order_items, business.orders, business.customers CASCADE;

    INSERT INTO business.customers VALUES
    (1,  '深圳创新科技有限公司', 'contact@szcxtech.com',       '0755-26881234', '深圳', '2024-03-15', 'corporate'),
    (2,  '北京华信软件股份',     'admin@huaxin-soft.cn',       '010-82567890', '北京', '2024-01-20', 'corporate'),
    (3,  '上海浦东发展集团',     'info@pudong-dev.com',        '021-58764321', '上海', '2024-02-10', 'corporate'),
    (4,  '广州天河商贸有限公司',  'sales@gzth-trade.cn',        '020-87569876', '广州', '2024-04-01', 'corporate'),
    (5,  '杭州西湖电子商务',     'service@hzxihuec.com',       '0571-87651234', '杭州', '2024-05-12', 'corporate'),
    (6,  '成都天府数码科技',     'hr@cdtf-digital.cn',         '028-85432109', '成都', '2024-06-08', 'corporate'),
    (7,  '武汉光谷生物科技',     'info@whggbio.com',           '027-87123456', '武汉', '2024-07-15', 'corporate'),
    (8,  '南京鼓楼信息产业',     'sales@njgl-it.cn',           '025-83567890', '南京', '2024-08-01', 'corporate'),
    (9,  '张伟',                 'zhangwei@email.cn',           '13800138001',  '北京',   '2024-01-05', 'individual'),
    (10, '李娜',                 'lina@email.cn',               '13800138002',  '上海',   '2024-02-14', 'individual'),
    (11, '王磊',                 'wanglei@email.cn',            '13800138003',  '深圳',   '2024-03-20', 'individual'),
    (12, '赵敏',                 'zhaomin@email.cn',            '13800138004',  '广州',   '2024-04-18', 'individual'),
    (13, '陈晓明',               'chenxm@email.cn',             '13800138005',  '杭州',   '2024-05-22', 'individual'),
    (14, '刘洋',                 'liuyang@email.cn',            '13800138006',  '成都',   '2024-06-30', 'individual'),
    (15, '黄丽华',               'huanglh@email.cn',            '13800138007',  '武汉',   '2024-07-08', 'individual'),
    (16, '周志强',               'zhouzq@email.cn',             '13800138008',  '南京',   '2024-08-16', 'individual'),
    (17, '厦门海洋生物工程',     'info@xmocean-bio.cn',        '0592-2678901',  '厦门',   '2024-09-01', 'corporate'),
    (18, '吴晓燕',               'wuxiaoyan@email.cn',          '13800138009',  '重庆',   '2024-09-10', 'individual'),
    (19, '长沙岳麓软件园',       'admin@csyl-soft.cn',         '0731-88761234', '长沙',   '2024-10-05', 'corporate'),
    (20, '郑伟',                 'zhengwei@email.cn',           '13800138010',  '天津',   '2024-10-20', 'individual');

    -- ============================================================
    -- 种子数据: 50 个订单 (覆盖多状态、多支付方式、多客户)
    -- ============================================================
    INSERT INTO business.orders VALUES
    (1,  1,  '2025-04-01 09:15:00', 'completed',   'credit_card',   15800.00,  'CNY'),
    (2,  1,  '2025-04-03 14:30:00', 'completed',   'bank_transfer', 42300.00,  'CNY'),
    (3,  1,  '2025-05-01 10:00:00', 'processing',  'alipay',        8750.00,   'CNY'),
    (4,  2,  '2025-04-02 11:20:00', 'completed',   'wechat_pay',    96200.00,  'CNY'),
    (5,  2,  '2025-04-05 16:45:00', 'completed',   'bank_transfer',128000.00,  'CNY'),
    (6,  2,  '2025-05-02 08:30:00', 'processing',  'credit_card',   35000.00,  'CNY'),
    (7,  3,  '2025-04-01 13:00:00', 'completed',   'alipay',        75100.00,  'CNY'),
    (8,  3,  '2025-04-06 09:50:00', 'cancelled',   'wechat_pay',    12000.00,  'CNY'),
    (9,  3,  '2025-05-01 15:20:00', 'completed',   'bank_transfer', 68500.00,  'CNY'),
    (10, 4,  '2025-04-02 10:10:00', 'completed',   'credit_card',   23400.00,  'CNY'),
    (11, 4,  '2025-04-07 17:30:00', 'refunded',    'alipay',        5600.00,   'CNY'),
    (12, 4,  '2025-05-01 11:00:00', 'processing',  'wechat_pay',    18200.00,  'CNY'),
    (13, 5,  '2025-04-03 08:45:00', 'completed',   'alipay',        89300.00,  'CNY'),
    (14, 5,  '2025-04-08 14:20:00', 'completed',   'bank_transfer', 45600.00,  'CNY'),
    (15, 5,  '2025-05-02 09:30:00', 'processing',  'credit_card',   32100.00,  'CNY'),
    (16, 6,  '2025-04-04 12:00:00', 'completed',   'wechat_pay',    67800.00,  'CNY'),
    (17, 6,  '2025-04-09 10:30:00', 'completed',   'alipay',        28900.00,  'CNY'),
    (18, 6,  '2025-05-01 16:00:00', 'cancelled',   'bank_transfer', 15000.00,  'CNY'),
    (19, 7,  '2025-04-05 09:00:00', 'completed',   'credit_card',  104500.00,  'CNY'),
    (20, 7,  '2025-04-10 15:10:00', 'completed',   'wechat_pay',    39700.00,  'CNY'),
    (21, 7,  '2025-05-02 13:45:00', 'processing',  'alipay',        56800.00,  'CNY'),
    (22, 8,  '2025-04-06 11:30:00', 'completed',   'bank_transfer', 92100.00,  'CNY'),
    (23, 8,  '2025-04-11 08:20:00', 'refunded',    'credit_card',   22300.00,  'CNY'),
    (24, 8,  '2025-05-03 10:00:00', 'processing',  'wechat_pay',    41300.00,  'CNY'),
    (25, 9,  '2025-04-01 18:30:00', 'completed',   'wechat_pay',     1280.00,  'CNY'),
    (26, 9,  '2025-04-15 12:00:00', 'completed',   'alipay',         3560.00,  'CNY'),
    (27, 9,  '2025-05-01 09:00:00', 'completed',   'credit_card',    2100.00,  'CNY'),
    (28, 10, '2025-04-02 20:15:00', 'completed',   'alipay',         8900.00,  'CNY'),
    (29, 10, '2025-04-16 14:40:00', 'completed',   'wechat_pay',     4500.00,  'CNY'),
    (30, 10, '2025-05-02 11:20:00', 'processing',  'bank_transfer',  6700.00,  'CNY'),
    (31, 11, '2025-04-03 16:50:00', 'completed',   'credit_card',    5200.00,  'CNY'),
    (32, 11, '2025-04-17 10:10:00', 'cancelled',   'alipay',         1800.00,  'CNY'),
    (33, 12, '2025-04-04 13:25:00', 'completed',   'wechat_pay',     7600.00,  'CNY'),
    (34, 12, '2025-04-18 09:30:00', 'completed',   'credit_card',    3200.00,  'CNY'),
    (35, 13, '2025-04-05 17:00:00', 'completed',   'alipay',         9900.00,  'CNY'),
    (36, 13, '2025-04-19 15:45:00', 'processing',  'wechat_pay',     4100.00,  'CNY'),
    (37, 14, '2025-04-06 10:30:00', 'completed',   'bank_transfer',  5800.00,  'CNY'),
    (38, 14, '2025-04-20 12:15:00', 'completed',   'alipay',         2700.00,  'CNY'),
    (39, 15, '2025-04-07 08:50:00', 'completed',   'wechat_pay',     6300.00,  'CNY'),
    (40, 15, '2025-04-21 16:30:00', 'refunded',    'credit_card',    1900.00,  'CNY'),
    (41, 16, '2025-04-08 14:00:00', 'completed',   'alipay',         4800.00,  'CNY'),
    (42, 16, '2025-04-22 11:10:00', 'processing',  'bank_transfer',  3500.00,  'CNY'),
    (43, 17, '2025-04-09 09:20:00', 'completed',   'credit_card',   143000.00, 'CNY'),
    (44, 17, '2025-04-23 15:00:00', 'completed',   'wechat_pay',    57200.00,  'CNY'),
    (45, 17, '2025-05-03 08:00:00', 'processing',  'bank_transfer', 89500.00,  'CNY'),
    (46, 18, '2025-04-10 12:40:00', 'completed',   'alipay',         2300.00,  'CNY'),
    (47, 18, '2025-04-24 18:20:00', 'completed',   'wechat_pay',     1600.00,  'CNY'),
    (48, 19, '2025-04-11 10:50:00', 'completed',   'credit_card',  112800.00, 'CNY'),
    (49, 19, '2025-04-25 14:30:00', 'processing',  'bank_transfer', 46800.00, 'CNY'),
    (50, 20, '2025-04-12 09:00:00', 'completed',   'wechat_pay',     3700.00,  'CNY');

    -- ============================================================
    -- 种子数据: 120 条订单明细
    -- ============================================================
    INSERT INTO business.order_items VALUES
    -- 订单1: 3个明细
    (1,   1,  'ThinkPad X1 Carbon 笔记本电脑',        2, 6500.00,  0.00),
    (2,   1,  '罗技 MX Master 3S 鼠标',               3,  599.00,  5.00),
    (3,   1,  'Dell U2723QE 4K显示器',                1, 3299.00,  0.00),
    -- 订单2: 4个明细
    (4,   2,  '思科 Catalyst 9200 交换机',            2, 18500.00, 0.00),
    (5,   2,  'HPE ProLiant DL380 服务器',            1, 32000.00, 5.00),
    (6,   2,  'APC UPS 不间断电源',                    4,  1500.00, 0.00),
    (7,   2,  'CAT6A 网线 305米',                    10,   480.00, 10.00),
    -- 订单3: 2个明细
    (8,   3,  'WD Black SN850X 2TB SSD',              5, 1299.00,  0.00),
    (9,   3,  'Samsung 990 Pro 1TB SSD',              3,  799.00,  0.00),
    -- 订单4: 3个明细
    (10,  4,  'Oracle Database Enterprise 授权',       1, 85000.00, 0.00),
    (11,  4,  'Red Hat Enterprise Linux 订阅',        5,  2200.00, 0.00),
    (12,  4,  'Nginx Plus 年度许可',                   1,  9800.00, 0.00),
    -- 订单5: 1个明细
    (13,  5,  'SAP S/4HANA Cloud 年度订阅',           1,128000.00, 0.00),
    -- 订单6: 3个明细
    (14,  6,  'Fortinet FortiGate 200F 防火墙',       2, 13000.00, 0.00),
    (15,  6,  'Cisco Meraki MR46 无线AP',            10,  1600.00, 0.00),
    (16,  6,  'Panduit 光纤跳线 LC-LC 3米',          50,    37.60, 0.00),
    -- 订单7: 2个明细
    (17,  7,  'iPhone 15 Pro Max 256GB',              10, 5799.00, 3.00),
    (18,  7,  'AirPods Pro 2nd Gen',                  10, 1899.00, 5.00),
    -- 订单8: 2个明细
    (19,  8,  'Sony WH-1000XM5 降噪耳机',             4, 2499.00, 0.00),
    (20,  8,  'Apple Watch Ultra 2',                  2, 1199.00, 0.00),
    -- 订单9: 3个明细
    (21,  9,  'Lenovo ThinkSystem SR650 服务器',      2, 27500.00, 0.00),
    (22,  9,  'Seagate Exos X20 20TB HDD',            6,  2899.00, 0.00),
    (23,  9,  'VMware vSphere 8 企业版',              1, 18500.00, 0.00),
    -- 订单10-15...
    (24, 10,  '华为 MateBook X Pro 2025',             3, 7200.00, 0.00),
    (25, 10,  'USB-C 多功能扩展坞',                   3,  399.00, 10.00),
    (26, 11,  '小米 13 Ultra 手机',                   2, 2499.00, 0.00),
    (27, 11,  '手机壳 TPU 防摔',                      2,   49.00, 0.00),
    (28, 12,  'ASUS RT-AX86U Pro 路由器',            4, 1699.00, 0.00),
    (29, 12,  'NETGEAR GS308E 交换机',                4,  299.00, 0.00),
    (30, 12,  '网线 CAT6 2米规格',                   20,   12.50, 5.00),
    (31, 13,  'Adobe Creative Cloud 企业版年费',      1, 56000.00, 0.00),
    (32, 13,  'Figma Enterprise 年度订阅',           20,  1615.00, 0.00),
    (33, 14,  'Microsoft 365 Business Premium',      50,   892.00, 10.00),
    (34, 14,  'LastPass Business 密码管理',          50,   228.00, 0.00),
    (35, 15,  'Dell OptiPlex 7000 微型机',           5, 5800.00, 0.00),
    (36, 15,  'Windows 11 Pro 授权',                  5,  1199.00, 0.00),
    -- 订单16-25...
    (37, 16,  '锐捷 RG-S2910-24GT4XS-E 交换机',      4, 2450.00, 8.00),
    (38, 16,  '华为 S5735-L24T4X-A 交换机',          4, 1890.00, 8.00),
    (39, 16,  '新华三 S5560X-30C-EI 交换机',          2, 3850.00, 5.00),
    (40, 16,  '光纤模块 SFP+ 10G 多模',             20,  245.00, 0.00),
    (41, 17,  '群晖 DS923+ NAS 四盘位',              4, 4200.00, 0.00),
    (42, 17,  'Seagate IronWolf Pro 8TB',           16, 1480.00, 5.00),
    (43, 18,  'Apple MacBook Pro 14 M3 Pro',         1,14999.00, 0.00),
    (44, 19,  '华为 FusionServer 2288H V7',         2,49500.00, 10.00),
    (45, 20,  '联想 ThinkCentre M70q 迷你主机',     6, 3500.00, 0.00),
    (46, 20,  'AOC U27N3C 4K显示器',                6, 2499.00, 0.00),
    (47, 20,  '键盘鼠标套装',                         6,  179.00, 0.00),
    (48, 21,  '深信服 AF-1000-FH1600 防火墙',       1,48500.00, 5.00),
    (49, 21,  '奇安信天擎终端安全 EDR',            100,   163.00, 0.00),
    (50, 22,  'Palo Alto PA-440 防火墙',             2,18500.00, 0.00),
    (51, 22,  'Cisco ISR 1100 路由器',               6, 3200.00, 0.00),
    (52, 22,  'Juniper EX3400-24P 交换机',           4, 8900.00, 5.00),
    (53, 23,  'iPad Pro 12.9 M2 256GB',              3, 6599.00, 0.00),
    (54, 23,  'Apple Pencil 2nd Gen',                3,  999.00, 10.00),
    (55, 24,  'EMC Unity XT 480 混合存储',           1,39900.00, 0.00),
    -- 订单25-35: 个人客户订单
    (56, 25,  'Anker 737 移动电源 24000mAh',         1,  899.00, 0.00),
    (57, 25,  'USB-C to USB-C 100W 线缆',           2,   79.00, 0.00),
    (58, 26,  'Kindle Paperwhite 5 电子书阅读器',    1, 1199.00, 0.00),
    (59, 26,  'Kindle 保护套',                        1,  169.00, 0.00),
    (60, 26,  '钢化膜 电子书',                        1,   49.00, 0.00),
    (61, 27,  '西部数据 My Passport 5TB 移动硬盘',   1,  999.00, 0.00),
    (62, 27,  'SanDisk Extreme Pro U盘 256GB',      2,  149.00, 0.00),
    (63, 28,  '戴森 V15 Detect 无线吸尘器',          1, 5990.00, 0.00),
    (64, 28,  '戴森替换滤网 3件套',                  1,  349.00, 0.00),
    (65, 29,  '飞利浦 Sonicare 9900 电动牙刷',       1, 1699.00, 10.00),
    (66, 29,  '飞利浦替换刷头 8支装',                1,  249.00, 0.00),
    (67, 30,  '石头 G20 智能自清洁扫拖机器人',       1, 4299.00, 0.00),
    (68, 30,  '石头一次性拖布 30片装',               2,   69.00, 0.00),
    (69, 31,  'Bose QuietComfort Ultra 降噪耳机',    1, 2799.00, 0.00),
    (70, 31,  '耳机便携收纳盒',                      1,  159.00, 0.00),
    (71, 32,  '松下 LX600C OLED 智能电视 65寸',      1,12999.00, 0.00),
    (72, 33,  '九阳 K780 全自动破壁机',              1, 1299.00, 0.00),
    (73, 33,  '九阳五谷杂粮礼盒 3kg',                2,   99.00, 0.00),
    (74, 33,  '密封罐 玻璃 1L ×4个',                  1,  168.00, 0.00),
    (75, 34,  '华为 Watch GT 4 Pro 智能手表',        1, 2288.00, 0.00),
    (76, 34,  '硅胶表带替换装',                      2,   99.00, 0.00),
    (77, 35,  'NESPRESSO Vertuo Pop 胶囊咖啡机',     1, 1299.00, 0.00),
    (78, 35,  '星巴克胶囊咖啡 50颗装',               2,  399.00, 0.00),
    (79, 36,  '索尼 A7M4 微单相机 机身',              1,13899.00, 0.00),
    (80, 36,  'SanDisk SD卡 128GB UHS-II',          2,  599.00, 0.00),
    (81, 37,  '格力 KFR-35GW 变频冷暖空调 1.5匹',    1, 3499.00, 0.00),
    (82, 37,  '空调安装支架 不锈钢',                  1,   99.00, 0.00),
    (83, 38,  '小米空气净化器 4 Pro',                1, 1899.00, 0.00),
    (84, 38,  '小米净化器替换滤芯',                   1,  239.00, 0.00),
    (85, 39,  '美的 MJ-PB12Easy215 破壁机',          1,  899.00, 0.00),
    (86, 39,  '美的电热水壶 1.7L',                   1,  149.00, 0.00),
    (87, 40,  '荣耀 Magic V3 折叠屏手机',             1, 9999.00, 0.00),
    (88, 41,  '海尔 BCD-502WG 冰箱 502L',            1, 5499.00, 0.00),
    (89, 41,  '冰箱除味剂 活性炭',                    3,   29.00, 0.00),
    (90, 42,  '任天堂 Switch OLED 马力欧红蓝',        1, 2399.00, 0.00),
    (91, 42,  'Switch 马力欧卡丁车8 豪华版',          1,  369.00, 0.00),
    (92, 42,  'Switch Pro 手柄',                      1,  419.00, 0.00),
    -- 订单43-50: 混合客户订单
    (93, 43,  '超聚变 FusionServer 5288 V7 服务器',  3,43000.00, 5.00),
    (94, 43,  'NVIDIA A100 80GB GPU 计算卡',         2,95000.00, 0.00),
    (95, 44,  'H3C UniServer R4900 G6 服务器',      4,12000.00, 0.00),
    (96, 44,  'Intel Xeon Gold 6448Y CPU',          8, 4200.00, 0.00),
    (97, 44,  'Samsung DDR5 4800 64GB RDIMM',      32, 1600.00, 0.00),
    (98, 45,  '深信服超融合 aServer 一体机',        3,28000.00, 0.00),
    (99, 45,  '深信服超融合软件授权',                3, 1200.00, 0.00),
    (100, 46, 'SK-II 神仙水 230ml',                  1, 1390.00, 0.00),
    (101, 46, '雅诗兰黛小棕瓶精华 50ml',             1,  935.00, 0.00),
    (102, 47, '阿迪达斯 Ultraboost 跑鞋 女款',       1,  899.00, 10.00),
    (103, 47, 'Nike 运动袜 3双装',                   1,  129.00, 0.00),
    (104, 48, '阿里云 ECS 企业版 年度订阅',          1,78000.00, 0.00),
    (105, 48, '阿里云 OSS 存储包 100TB',             1,24000.00, 0.00),
    (106, 48, 'SSL 证书 通配符 3年',                 2,  4800.00, 0.00),
    (107, 49, '腾讯云 CDN 流量包 50TB',              1,15000.00, 0.00),
    (108, 49, '域名注册 cn/com 各5个',              10,    79.00, 0.00),
    (109, 49, '腾讯云短信包 10万条',                  1,  3900.00, 0.00),
    (110, 49, '企业邮箱 50用户 年度',                 1,  3600.00, 0.00),
    (111, 50, 'JBL Charge 5 蓝牙音箱',               1, 1099.00, 0.00),
    (112, 50, '小米温湿度计 2 代',                    3,   49.00, 0.00),
    (113, 50, '智能插座 WiFi版 4个装',                 1,  169.00, 0.00),
    -- 为部分已有订单补充明细(使120条完整)
    (114,  8, 'Sony Xperia 1 VI 手机壳',             2,  149.00, 0.00),
    (115, 11, 'USB-C HUB 7合1',                      1,  259.00, 0.00),
    (116, 18, 'Apple Magic Keyboard',                1, 1399.00, 0.00),
    (117, 22, '光纤收发器 千兆 单模',                 8,  185.00, 0.00),
    (118, 26, 'Anker 20W USB-C 充电器',              1,  149.00, 0.00),
    (119, 31, '3.5mm 音频线 1.5米',                  2,   45.00, 0.00),
    (120, 48, '云数据库 RDS MySQL 8.0 年度',          1,15000.00, 0.00);

    -- 添加索引
    CREATE INDEX IF NOT EXISTS idx_orders_customer   ON business.orders(customer_id);
    CREATE INDEX IF NOT EXISTS idx_orders_date        ON business.orders(order_date);
    CREATE INDEX IF NOT EXISTS idx_orders_status      ON business.orders(order_status);
    CREATE INDEX IF NOT EXISTS idx_items_order        ON business.order_items(order_id);

    COMMENT ON SCHEMA business IS '业务交易源数据库 -- 订单/客户/订单明细';
    COMMENT ON TABLE business.customers IS '客户主数据表';
    COMMENT ON TABLE business.orders IS '订单事务表';
    COMMENT ON TABLE business.order_items IS '订单明细表';
EOSQL
