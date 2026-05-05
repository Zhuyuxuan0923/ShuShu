# 数据质量框架

## 测试分层策略

```
┌─────────────────────────────────────────────────────┐
│                    "尽早失败" 原则                     │
│                                                     │
│  ODS: 新鲜度警告 + PK唯一/非空检查                      │
│   ↓ 失败则跳过下游                                     │
│  DWD: 列级非空、值范围、可接受值枚举                      │
│   ↓ 失败则终止DWS                                     │
│  DWS: 正数计数、非负聚合                                │
│   ↓ 失败则终止ADS                                     │
│  ADS: 业务规则断言（环比范围、排名合理性）                 │
└─────────────────────────────────────────────────────┘
```

## 测试类型

| 类型 | 严重级别 | 示例 |
|------|----------|------|
| `not_null` | ERROR | PK列、外键列不能为空 |
| `unique` | ERROR | event_id、product_id 必须唯一 |
| `freshness` | WARN → ERROR | GitHub数据超过6小时告警，超过12小时报错 |
| `accepted_values` | WARN/ERROR | event_type必须在已知值列表中 |
| `reasonable_range` | ERROR | temperature在-50~60范围 |
| `not_null_multicol` | ERROR | 多列组合非空检查 |
| 特定数据测试 | ERROR | ODS不能有空事件；DWS计数必须≥0 |

## 四个数据源的测试配置

### GitHub Events

| 层 | 列 | 测试 |
|----|-----|------|
| ODS | id | not_null, unique |
| ODS | type, created_at, repo_name | not_null |
| ODS | 全表 | freshness: warn 6h / error 12h |
| DWD | event_id | unique, not_null |
| DWD | event_type | not_null, accepted_values(14种事件类型) |
| DWD | repo_owner, repo_name_short | not_null |
| ADS | day_over_day_pct | reasonable_range(-100, 1000) |

### Weather Forecast

| 层 | 列 | 测试 |
|----|-----|------|
| ODS | time | not_null |
| ODS | temperature_2m | not_null |
| ODS | 全表 | freshness: warn 2h / error 4h |
| DWD | forecast_time | unique, not_null |
| DWD | weather_category | not_null |
| ADS | alert_type, severity | not_null, accepted_values |

### E-commerce Products

| 层 | 列 | 测试 |
|----|-----|------|
| ODS | id | not_null, unique |
| ODS | title, price | not_null |
| ODS | 全表 | freshness: warn 24h / error 48h |
| DWD | product_id | unique, not_null |
| DWD | rating_tier | not_null, accepted_values(4级) |
| ADS | category, total_inventory_value | not_null |

## 新鲜度检查 (Source Freshness)

通过 `dbt source freshness` 命令执行，在每次 dbt run 之前检查：

```yaml
# 配置示例 (_ods_sources.yml)
freshness:
  warn_after: {count: 6, period: hour}   # 6小时未更新 → 告警但继续
  error_after: {count: 12, period: hour} # 12小时未更新 → 报错，跳过该源
```

## 自定义泛型测试

### `test_reasonable_range`
验证数值列在合理范围内：
```sql
{% test reasonable_range(model, column_name, min_value, max_value) %}
SELECT {{ column_name }} FROM {{ model }}
WHERE {{ column_name }} < {{ min_value }} OR {{ column_name }} > {{ max_value }}
{% endtest %}
```

### `test_not_null_multicol`
验证多列组合非空：
```sql
{% test not_null_multicol(model, columns) %}
SELECT * FROM {{ model }}
WHERE col1 IS NULL AND col2 IS NULL ...
{% endtest %}
```

## 告警流程

```
dbt test 执行
  → 生成 target/run_results.json
    → webhook_notifier.py 读取结果
      → 汇总 pass/fail/error 计数
        → 失败时: 生成Markdown失败详情表
        → POST 企业微信/钉钉 webhook
```
