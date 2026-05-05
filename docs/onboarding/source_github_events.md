# 新数据源接入：GitHub Events

> 按模板填写的完整示例，可作为后续接入的参考。

---

## 1. 源标识

- **源名称**: GitHub Public Events
- **API 端点**: `https://api.github.com/events`
- **认证方式**: None (未认证请求限 60次/小时)
- **数据格式**: JSON Array
- **更新频率**: 实时（每次拉取最近30条事件）
- **数据负责人**: 数据工程团队
- **业务说明**: GitHub 平台公开事件流，包含 Push、Watch、PR、Issue 等14种事件类型

---

## 2. Schema 发现

| 字段名 | 数据类型 | 描述 | 必填 | 示例值 |
|--------|----------|------|------|--------|
| id | string | 事件唯一ID | Y | "42887448817" |
| type | string | 事件类型 | Y | "PushEvent" |
| actor.login | string | 操作者用户名 | Y | "torvalds" |
| actor.id | bigint | 操作者ID | Y | 1024025 |
| repo.name | string | 仓库全名 (owner/repo) | Y | "torvalds/linux" |
| repo.id | bigint | 仓库ID | Y | 2325298 |
| created_at | timestamp | 事件发生时间 | Y | "2025-01-01T00:00:00Z" |
| public | boolean | 是否公开 | Y | true |

---

## 3. 数据量估算

- **每次加载记录数**: ~30条
- **平均记录大小**: ~500 bytes
- **峰值吞吐量**: ~15KB/次
- **保留周期**: 永久（DWD层累积历史）

---

## 4. 摄入配置

### SeaTunnel 任务文件
- 路径: `seatunnel/jobs/github_events_to_ods.conf`
- 任务模式: BATCH
- 轮询间隔: N/A

### ODS 表
- Schema: `ods`
- 表名: `github_events`
- DDL 生成方式: SeaTunnel自动创建

---

## 5. 转换设计

- [x] ODS 视图: `models/ods/ods_github_events.sql`
- [x] DWD 模型: `models/dwd/dwd_github_events.sql` (去重 + 拆分 owner/repo)
- [x] DWS 聚合: `models/dws/dws_github_daily_activity.sql` (按日期+事件类型聚合)
- [x] ADS 应用: `models/ads/ads_github_trending.sql` (7日趋势 + 排名)
- [x] 源定义: `models/ods/_ods_sources.yml` external_apis.github_events
- [x] 模型测试: `models/ods/_ods_models.yml` + `models/dwd/_dwd_models.yml`
- [x] 种子数据: `seeds/event_type_categories.csv` (事件类型到业务分类的映射)

---

## 6. 数据质量规则

| 规则ID | 层 | 检查类型 | 列名 | 阈值 | 严重级别 |
|--------|-----|----------|------|------|----------|
| GH-ODS-01 | ODS | not_null | id | - | error |
| GH-ODS-02 | ODS | unique | id | - | error |
| GH-ODS-03 | ODS | not_null | type, repo_name | - | error |
| GH-ODS-04 | ODS | freshness | 全表 | warn 6h / error 12h | warn/error |
| GH-DWD-01 | DWD | unique + not_null | event_id | - | error |
| GH-DWD-02 | DWD | accepted_values | event_type | 14种事件类型 | warn |
| GH-DWD-03 | DWD | not_null | repo_owner, repo_name_short | - | error |
| GH-ADS-01 | ADS | reasonable_range | day_over_day_pct | -100 ~ 1000 | error |

---

## 7. DAG 注册

- [x] 主DAG TaskGroup: `data_warehouse_full_pipeline.py` → `ingest_all.ingest_github`
- [x] 独立DAG: `airflow/dags/github_archive_pipeline.py`
- [x] 调度周期: 主DAG每日07:00 UTC，独立DAG每30分钟
- [x] 告警接收人: 通过企微/钉钉群机器人

---

## 8. 验证清单

- [x] SeaTunnel 任务独立执行成功 (本地 curl 测试通过)
- [x] ODS 数据在 PostgreSQL 中可见
- [x] `dbt run --select ods_github_events+` 成功
- [x] `dbt test --select ods_github_events+` 通过
- [x] Airflow DAG 在UI中无解析错误
- [x] 告警通知收到
- [x] 文档已提交 Review

---

## 9. 上线计划

- **测试环境**: 2025-01-06
- **UAT 签核**: 数据TL / 2025-01-08
- **生产上线**: 2025-01-10
