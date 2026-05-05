# 企业级数据仓库与数据质量平台

[![dbt CI/CD](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/dbt_test.yml/badge.svg)](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/dbt_test.yml)
[![dbt core](https://img.shields.io/badge/dbt--core-1.9.4-orange?logo=dbt)](https://github.com/dbt-labs/dbt-core)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169e1?logo=postgresql)](https://www.postgresql.org/)

完整的多源异构数据集成、四层数仓建模、数据质量监控与告警平台。覆盖 GitHub 事件、天气预报、电商商品、业务交易 4 个数据域，从摄入到 BI 报表全链路自动化。

---

## CI/CD 流水线

每次 `push` 或 `PR` 到 `main` 分支时自动触发 `.github/workflows/dbt_test.yml`，分三个阶段：

```
┌─────────────────────────────────────────────────────────────┐
│  Job 1: lint (无数据库, ~30s)                                 │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐                  │
│  │ dbt deps │ → │dbt parse │ → │dbt compile│                  │
│  │ 安装依赖  │   │ YAML/引用 │   │ SQL编译   │                  │
│  └──────────┘   └──────────┘   └──────────┘                  │
│  发现: 包依赖缺失、ref() 断链、YAML schema 错误、SQL 语法错误    │
├─────────────────────────────────────────────────────────────┤
│  Job 2: test (依赖 lint 通过, ~2min)                          │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌──────────┐        │
│  │建 Schema │→│灌测试数据 │→│dbt build│→ │docs gen  │        │
│  │ods/dwd/  │ │6张源表   │ │40+模型  │  │血缘可视化 │        │
│  │dws/ads   │ │29行种子  │ │50+测试  │  │上传产物   │        │
│  └─────────┘  └─────────┘  └─────────┘  └──────────┘        │
│  发现: 类型不匹配、测试断言失败、视图/表创建失败                   │
├─────────────────────────────────────────────────────────────┤
│  Job 3: summary (汇总结果)                                     │
│  输出 lint + test 两阶段状态到 GitHub Step Summary              │
└─────────────────────────────────────────────────────────────┘
```

### 各阶段详解

| 阶段 | 工具 | 检查内容 | 发现的问题类型 |
|------|------|----------|----------------|
| **dbt deps** | dbt | 下载 `packages.yml` 声明的依赖（dbt-utils 1.3.0） | 版本冲突、包不存在 |
| **dbt parse** | dbt | 解析所有 `.sql` 和 `.yml`，验证 `ref()` 引用完整、YAML 结构合法 | 模型引用断链、YAML 缩进/字段名错误 |
| **dbt compile** | dbt | 完整编译所有 SQL 模板（Jinja → 纯 SQL） | SQL 语法错误、宏参数类型不匹配 |
| **建 Schema** | psql | 在 PostgreSQL 16 服务容器中创建 `ods/dwd/dws/ads` | — |
| **灌测试数据** | psql | 向 6 张源表灌入总 29 行种子数据，模拟 SeaTunnel 摄入 | — |
| **dbt seed** | dbt | 加载 CSV 种子数据（event_type_categories） | CSV 格式/编码错误 |
| **dbt build** | dbt | 按依赖拓扑排序执行全部模型(ODS→DWD→DWS→ADS) + 自动运行 50+ 数据质量测试 | 主键重复、必填字段为空、枚举值越界、值范围超限、新鲜度告警 |
| **docs generate** | dbt | 基于 `manifest.json` + `catalog.json` 生成可视化血缘 DAG | — |
| **upload artifact** | actions | 上传 `dbt-docs` (HTML站点) 和 `dbt-logs`，保留 7 天 | — |

### 测试矩阵

```
层   | 测试类型              | 覆盖表数 | 断言数
ODS  | unique, not_null      | 6       | 18
DWD  | unique, not_null, accepted_values | 6 | 22
DWS  | not_null, unique      | 5       | 15
ADS  | not_null, unique, accepted_values, reasonable_range | 4 | 18
─────────────────────────────────────────────────────────
合计 |                        | 21 模型  | 73
```

### 如何在 PR 中看结果

1. 打开 PR → **Checks** 标签页
2. 点击 **dbt CI/CD** → 展开 `test` job
3. 查看每个 step 的控制台输出（ANSI 色彩保留）
4. 下载 **dbt-docs** artifact → 本地 `open index.html` 查看最新血缘图
5. 下载 **dbt-logs** artifact → 排查失败原因

### 本地等效验证

```bash
# 等同于 CI 的 lint 阶段
cd dbt
dbt deps --profiles-dir .
dbt parse --profiles-dir .
dbt compile --profiles-dir .

# 等同于 CI 的 test 阶段（需要本地 PostgreSQL 运行中）
docker compose up -d postgres
cd dbt
dbt seed --profiles-dir .
dbt build --profiles-dir .
dbt docs generate --profiles-dir .
```

---

## 快速开始

```bash
# 1. 配置环境
cp .env.example .env

# 2. 启动全部服务
docker compose up -d

# 3. 访问 Airflow UI
open http://localhost:8080
# 用户名: admin / 密码: admin
```

## 架构

```
数据源 (GitHub/天气/电商/业务DB) → SeaTunnel 摄入 → PostgreSQL ODS
  → dbt 建模 (ODS→DWD→DWS→ADS) → dbt 测试 → 企微/钉钉告警
  → Airflow 调度全流程
```

## 技术栈

| 组件 | 版本 | 用途 |
|------|------|------|
| Apache SeaTunnel | 2.3.12 | 多源数据摄入（HTTP Source / JDBC Source） |
| dbt-core | 1.9.4 | 数据建模、测试、文档、血缘 |
| Apache Airflow | 2.11.1 | 任务调度（CeleryExecutor） |
| PostgreSQL | 16 | 数仓存储 + Airflow 元数据库 |
| GitHub Actions | — | CI/CD 自动化测试 |
| Redis | 7-alpine | Celery broker |
| Docker Compose | 3.9 | 本地开发环境 |

## 数仓分层

| 层 | Schema | 物化策略 | 职责 |
|----|--------|----------|------|
| ODS | ods | view | 源数据 1:1 镜像，类型转换，附加 `_ingested_at` |
| DWD | dwd | incremental | 去重(`QUALIFY ROW_NUMBER`)、清洗、标准化、维度拆分 |
| DWS | dws | incremental | 按日/类目/客户聚合，产出服务层指标 |
| ADS | ads | table | 窗口函数(环比/排名)、业务规则(告警/分级)、最终报表 |

## 数据源

| 源 | 类型 | 摄入方式 | 表数 | 数据量 |
|----|------|----------|------|--------|
| GitHub Events API | REST API (JSON) | SeaTunnel HTTP Source | 1 | 30条/次 |
| Open-Meteo Weather API | REST API (JSON) | SeaTunnel HTTP Source | 1 | 24条/次 |
| DummyJSON E-commerce API | REST API (JSON) | SeaTunnel HTTP Source | 1 | 100条/次 |
| **Business Transaction DB** | **PostgreSQL JDBC** | **SeaTunnel JDBC Source** | **3** | **种子 20+50+120 行** |

## 数据质量

- **新鲜度**: `dbt source freshness` 自动检测源数据滞后，超阈值告警（warn/error 两级）
- **唯一性**: 主键 `unique` 约束（如 `event_id`、`order_id`、`customer_id`）
- **非空**: 关键字段 `not_null` 检查（如 `order_date`、`total_amount`、`customer_name`）
- **枚举值**: `accepted_values` 白名单（如 14 种 `event_type`、4 种 `order_status`）
- **值范围**: 通用测试 `reasonable_range`（如 `day_over_day_pct` 在 [-100, 1000]）
- **自定义规则**: 特定业务逻辑断言（如 `ods_github_no_empty_events`、`dws_positive_counts`）

## 目录

```
├── .github/workflows/    # CI/CD 流水线定义
├── airflow/              # Airflow DAG + 告警插件(webhook_notifier)
├── dbt/
│   ├── models/           # 四层模型 (ods/dwd/dws/ads) 共 21 个
│   ├── macros/           # 自定义宏 (deduplicate/pipeline_metadata/freshness_check)
│   ├── tests/            # 通用 + 特定测试
│   └── seeds/            # 静态种子数据
├── docker/               # Airflow + SeaTunnel Dockerfiles
├── docs/                 # 架构/质量框架/运维/接入模板
├── scripts/              # PostgreSQL 初始化(source_db + data_warehouse)
├── seatunnel/
│   ├── config/           # Zeta 引擎本地模式配置
│   └── jobs/             # 6 个摄入作业 (3 HTTP + 3 JDBC)
└── docker-compose.yml    # 7 服务编排
```

## 新数据源接入

参见 `docs/onboarding/template.md` — 按模板填写，9 步完成新源接入。

## 文档

- [架构文档](docs/architecture.md)
- [数据质量框架](docs/data_quality_framework.md)
- [运维手册](docs/operations.md)
- [接入模板](docs/onboarding/template.md)
- [接入示例: GitHub Events](docs/onboarding/source_github_events.md)
