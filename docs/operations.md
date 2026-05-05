# 运维手册

## 环境要求

- Docker Desktop (WSL2 后端)
- 至少 8GB 可用内存
- Windows 11 / macOS / Linux

## 快速启动

```bash
# 1. 克隆项目后，配置环境变量
cp .env.example .env
# 编辑 .env 填入企微/钉钉 webhook URL（可选）

# 2. 启动所有服务
docker compose up -d

# 3. 查看服务状态
docker compose ps

# 4. 访问 Airflow UI
# http://localhost:8080
# 用户名: admin / 密码: admin
```

## 服务端口

| 服务 | 端口 | 说明 |
|------|------|------|
| PostgreSQL | 5432 | 数仓存储 |
| Airflow Webserver | 8080 | Airflow UI |
| SeaTunnel REST | 5801 | SeaTunnel Zeta引擎API |

## 常用命令

### Docker Compose

```bash
# 启动
docker compose up -d

# 停止
docker compose down

# 重启单个服务
docker compose restart airflow-scheduler

# 重建镜像
docker compose build --no-cache

# 查看日志
docker compose logs -f airflow-scheduler
docker compose logs -f seatunnel
```

### dbt

```bash
# 进入 scheduler 容器
docker compose exec airflow-scheduler bash

# 安装 dbt 依赖
cd /opt/dbt && dbt deps

# 运行所有模型
dbt run --profiles-dir /opt/dbt

# 运行特定层
dbt run --select ods --profiles-dir /opt/dbt
dbt run --select dwd --profiles-dir /opt/dbt
dbt run --select ods_github_events+ --profiles-dir /opt/dbt

# 运行测试
dbt test --profiles-dir /opt/dbt

# 检查新鲜度
dbt source freshness --profiles-dir /opt/dbt

# 生成文档
dbt docs generate --profiles-dir /opt/dbt
dbt docs serve --port 8081 --profiles-dir /opt/dbt

# 加载种子数据
dbt seed --profiles-dir /opt/dbt
```

### PostgreSQL

```bash
# 连接数仓
docker compose exec postgres psql -U dw_admin -d data_warehouse

# 查看各层数据量
SELECT 'ods' AS layer, schemaname, tablename,
       n_live_tup AS row_count
FROM pg_stat_user_tables
WHERE schemaname IN ('ods', 'dwd', 'dws', 'ads')
ORDER BY schemaname, tablename;

# 查看数据来源分布
SELECT source_system, COUNT(*) FROM ods.github_events GROUP BY 1;
SELECT source_system, COUNT(*) FROM ods.weather_forecast GROUP BY 1;
SELECT source_system, COUNT(*) FROM ods.ecommerce_products GROUP BY 1;
```

### Airflow

```bash
# 手动触发DAG
docker compose exec airflow-scheduler airflow dags trigger data_warehouse_full_pipeline

# 列出所有DAG
docker compose exec airflow-scheduler airflow dags list

# 查看DAG任务状态
docker compose exec airflow-scheduler airflow tasks list data_warehouse_full_pipeline
```

## 完全重置

```bash
# 停止并删除所有容器和卷
docker compose down -v

# 重新构建并启动
docker compose build --no-cache
docker compose up -d
```

## 故障排查

### SeaTunnel 任务失败
```bash
# 查看 SeaTunnel 日志
docker compose logs seatunnel

# 检查 REST API 是否可达
curl http://localhost:5801/hazelcast/rest/maps/submit-job
```

### dbt 运行失败
```bash
# 进入容器直接运行
docker compose exec airflow-scheduler bash
cd /opt/dbt
dbt run --profiles-dir /opt/dbt  # 查看详细错误

# 常见原因：ODS表不存在 → 先触发SeaTunnel摄入
```

### Airflow DAG 不显示
```bash
# 检查 DAG 解析错误
docker compose logs airflow-scheduler | grep -i error

# 手动测试 DAG 语法
docker compose exec airflow-scheduler python /opt/airflow/dags/data_warehouse_full_pipeline.py
```

### 数据库连接问题
```bash
# 测试 PostgreSQL 连通性
docker compose exec postgres pg_isready -U dw_admin

# 确认数据仓库数据库存在
docker compose exec postgres psql -U dw_admin -c "\l"
```

## Webhook 配置

1. 企业微信：群机器人 → 复制 webhook URL → 填入 `.env` 的 `WECOM_WEBHOOK_URL`
2. 钉钉：群机器人 → 复制 webhook URL → 填入 `.env` 的 `DINGTALK_WEBHOOK_URL`
3. 测试告警：触发主DAG后，检查是否收到质量报告消息
4. 测试用 webhook.site：先用 `https://webhook.site/` 的临时URL验证消息格式
