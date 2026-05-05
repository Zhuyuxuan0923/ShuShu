# 新数据源接入模板：{SOURCE_NAME}

> 按照此模板填写新数据源信息，完成接入后归档到 `docs/onboarding/` 目录。

---

## 1. 源标识 (Source Identification)

- **源名称**: 
- **API 端点 / 数据库URL**: 
- **认证方式**: [ None / API Key / OAuth2 / Basic Auth / Token ]
- **数据格式**: [ JSON / CSV / Parquet / JDBC / Kafka ]
- **更新频率**: [ 实时 / 每小时 / 每日 / 手动 ]
- **数据负责人**: [ 团队 / 联系人 ]
- **业务说明**: 

---

## 2. Schema 发现 (Schema Discovery)

| 字段名 | 数据类型 | 描述 | 必填 | 示例值 |
|--------|----------|------|------|--------|
|        |          |      |      |        |

---

## 3. 数据量估算 (Data Volume)

- **每次加载记录数**: 
- **平均记录大小**: 
- **峰值吞吐量**: 
- **保留周期**: [ 天 / 月 / 永久 ]

---

## 4. 摄入配置 (Ingestion Configuration)

### SeaTunnel 任务文件
- 路径: `seatunnel/jobs/{source_name}_to_ods.conf`
- 任务模式: [ BATCH / STREAMING ]
- 轮询间隔 (流式): 

### ODS 表
- Schema: `ods`
- 表名: `{source_name}`
- DDL 生成方式: [ SeaTunnel自动创建 / 手动 ]

---

## 5. 转换设计 (Transformation Design)

- [ ] ODS 视图: `models/ods/ods_{source_name}.sql`
- [ ] DWD 模型: `models/dwd/dwd_{source_name}.sql`
- [ ] DWS 聚合: `models/dws/dws_{source_name}_daily.sql`
- [ ] ADS 应用: `models/ads/ads_{source_name}_kpi.sql`
- [ ] 源定义: `models/ods/_ods_sources.yml` 新增条目
- [ ] 模型测试: `models/{layer}/_{layer}_models.yml` 新增条目
- [ ] 种子数据: `seeds/` (如有)

---

## 6. 数据质量规则 (Quality Rules)

| 规则ID | 层 | 检查类型 | 列名 | 阈值 | 严重级别 |
|--------|-----|----------|------|------|----------|
|        |     |          |      |      |          |

---

## 7. DAG 注册 (DAG Registration)

- [ ] 主DAG中加入新 TaskGroup: `data_warehouse_full_pipeline.py`
- [ ] 独立DAG创建: `airflow/dags/{source_name}_pipeline.py`
- [ ] 调度周期: 
- [ ] 告警接收人: 

---

## 8. 验证清单 (Validation Checklist)

- [ ] SeaTunnel 任务独立执行成功
- [ ] ODS 数据在 PostgreSQL 中可见
- [ ] `dbt run --select ods_{source_name}+` 成功
- [ ] `dbt test --select ods_{source_name}+` 通过
- [ ] Airflow DAG 在UI中无解析错误
- [ ] 告警通知收到（如配置）
- [ ] 文档已提交 Review

---

## 9. 上线计划 (Rollout Plan)

- **测试环境**: [日期]
- **UAT 签核**: [日期 / 审批人]
- **生产上线**: [日期]
