# 企业级数据仓库与数据质量平台

[![dbt Test](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/dbt_test.yml/badge.svg)](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/dbt_test.yml)

完整的多源异构数据集成、四层数仓建模、数据质量监控与告警平台。

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
数据源 (GitHub/天气/电商) → SeaTunnel 摄入 → PostgreSQL ODS
  → dbt 建模 (ODS→DWD→DWS→ADS) → dbt 测试 → 企微/钉钉告警
  → Airflow 调度全流程
```

## 技术栈

| 组件 | 版本 | 用途 |
|------|------|------|
| Apache SeaTunnel | 2.3.12 | 多源数据摄入 |
| dbt-core | 1.9.4 | 数据建模与测试 |
| Apache Airflow | 2.11.1 | 任务调度 |
| PostgreSQL | 16 | 数仓存储 |
| Docker Compose | 3.9 | 本地部署 |

## 数仓分层

| 层 | Schema | 说明 |
|----|--------|------|
| ODS | ods | 源数据镜像 |
| DWD | dwd | 清洗去重标准化 |
| DWS | dws | 聚合指标 |
| ADS | ads | 业务KPI/报表 |

## 数据质量

- **新鲜度**: 自动检测源数据滞后，超阈值告警
- **唯一性**: 主键唯一约束
- **非空**: 关键字段非空检查
- **值范围**: 数值合理性验证
- **枚举值**: 可接受值白名单
- **自定义规则**: 特定业务逻辑断言

## 目录

```
├── airflow/        # Airflow DAG + 告警插件
├── dbt/            # dbt 模型、测试、宏、种子
├── docker/         # Dockerfiles
├── docs/           # 架构、质量框架、运维、接入模板
├── scripts/        # 初始化脚本
├── seatunnel/      # SeaTunnel 配置与Job
└── docker-compose.yml
```

## 新数据源接入

参见 `docs/onboarding/template.md` — 按模板填写，9步完成新源接入。

## 文档

- [架构文档](docs/architecture.md)
- [数据质量框架](docs/data_quality_framework.md)
- [运维手册](docs/operations.md)
- [接入模板](docs/onboarding/template.md)
- [接入示例: GitHub Events](docs/onboarding/source_github_events.md)
