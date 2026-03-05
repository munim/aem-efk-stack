# AEM EFK Stack

A Docker-based log aggregation and analysis stack for Adobe Experience Manager (AEM) Cloud Manager logs using Elasticsearch, Fluent Bit, and Kibana (EFK).

## Overview

This project provides a centralized logging solution that:
- Downloads logs from AEM Cloud Manager using Adobe IO CLI
- Parses and structures various AEM log types (HTTPD access, Dispatcher, CDN, AEM Java errors)
- Indexes logs into Elasticsearch for fast searching
- Visualizes logs through Kibana dashboards

## Architecture

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────┐     ┌─────────────┐
│  AEM Cloud      │────▶│  Adobe IO    │────▶│   Fluent    │────▶│Elasticsearch│
│  Manager Logs   │     │    CLI       │     │    Bit      │     │             │
└─────────────────┘     └──────────────┘     └─────────────┘     └──────┬──────┘
                                                                        │
                                                                        ▼
                                                                ┌─────────────┐
                                                                │   Kibana    │
                                                                │  (UI/Search)│
                                                                └─────────────┘
```

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- [Adobe IO CLI](https://developer.adobe.com/runtime/docs/guides/tools/cli_install/) (`aio`) with Cloud Manager plugin
- Node.js 22.x (for Adobe IO CLI)
- Bash shell environment

## Quick Start

### 1. Clone and Configure

```bash
git clone <repository-url>
cd aem-efk-stack
```

### 2. Set Up Adobe IO Authentication

```bash
# Copy the sample config and fill in your credentials
cp aio_cm_config-sample.json secured-config/aio_cm_config.json

# Edit the config file with your Adobe IO credentials
# Values available from: https://developer.adobe.com/console/projects
```

Required credentials in `secured-config/aio_cm_config.json`:
- `client_id` - From Adobe IO Console
- `client_secrets` - From Adobe IO Console
- `technical_account_id` - From Adobe IO Console
- `technical_account_email` - From Adobe IO Console
- `ims_org_id` - From Adobe IO Console

### 3. Configure Environment Variables

```bash
# Review and customize .env file
cat .env
```

Key variables:
| Variable | Default | Description |
|----------|---------|-------------|
| `STACK_VERSION` | 8.15.3 | Elasticsearch/Kibana version |
| `ELASTICSEARCH_PASSWORD` | elastic | Elasticsearch superuser password |
| `ES_KIBANA_PASSWORD` | 123123 | Kibana system user password |
| `ES_LOGSTASH_PASSWORD` | Qwer1234 | Fluent Bit Elasticsearch user password |

### 4. Start the Stack

```bash
# Create required directories
mkdir -p data/esdata data/fluent-bit/db logs

# Start all services
docker-compose up -d

# Wait for Elasticsearch to be ready (30-60 seconds)
curl -u elastic:elastic http://localhost:9200/_cluster/health
```

### 5. Access Kibana

Open your browser: http://localhost:5601

Login credentials:
- Username: `elastic`
- Password: (value from `ELASTICSEARCH_PASSWORD` in `.env`)

### 6. Download AEM Logs

```bash
# Download logs from last 1 day (default)
./scripts/download-logs.sh

# Download logs from last 7 days
./scripts/download-logs.sh -d 7
```

## Available Scripts

| Script | Description |
|--------|-------------|
| `scripts/download-logs.sh -d [days]` | Download logs from Cloud Manager |
| `scripts/compress_old_logs.sh` | Compress log files older than 7 days |
| `scripts/extract_archived_old_7z_log_files.sh` | Extract compressed 7z log archives |
| `scripts/delete_log_files_when_7z_file_exists.sh` | Clean up extracted logs with existing archives |
| `scripts/extract_sample_of_all_logs.sh` | Create sample dataset from real logs |
| `scripts/make_test_data_from_real_logs.sh` | Generate test data from production logs |
| `scripts/copy_log_files_from_backup.sh` | Restore logs from backup location |
| `scripts/aio-helper.sh` | Helper utilities for Adobe IO CLI |

## Supported Log Types

The following AEM log types are automatically parsed and indexed:

| Log Type | Index Pattern | Description |
|----------|---------------|-------------|
| HTTPD Access | `logs-aem-*-httpdaccess` | Apache web server access logs |
| AEM Dispatcher | `logs-aem-*-aemdispatcher` | AEM Dispatcher module logs |
| CDN | `logs-aem-*-cdn` | Adobe CDN edge logs |
| AEM Error | `logs-aem-*-error` | AEM Java application error logs |

## Directory Structure

```
.
├── docker-compose.yml          # EFK stack services definition
├── .env                        # Environment configuration
├── aio_cm_config-sample.json   # Adobe IO config template
├── fluent-bit/
│   └── conf/
│       ├── fluent-bit.conf     # Fluent Bit pipeline config
│       ├── parsers.conf        # Custom log parsers
│       └── schema.json         # Elasticsearch index mappings
├── scripts/                    # Helper scripts
├── data/                       # Persistent data (gitignored)
│   ├── esdata/                 # Elasticsearch data
│   └── fluent-bit/db/          # Fluent Bit position tracking
└── logs/                       # Downloaded AEM logs (gitignored)
```

## Troubleshooting

### Elasticsearch fails to start

```bash
# Check Docker VM memory - requires at least 4GB
docker stats

# Increase Docker Desktop memory limit in Settings > Resources
```

### Permission errors on data directory

```bash
# Fix permissions for Elasticsearch data
sudo chown -R 1000:1000 data/esdata
```

### No logs appearing in Kibana

1. Verify logs are downloaded to `./logs/` directory
2. Check Fluent Bit logs: `docker logs fluent-bit`
3. Verify index patterns exist in Kibana: Stack Management > Index Patterns
4. Check time range in Kibana search (logs may be outside default "last 15 minutes")

### Adobe IO authentication errors

```bash
# Verify aio CLI is installed and configured
aio login
aio config:get ims.contexts.aio-cli-plugin-cloudmanager
```

## Customization

### Adding New Log Types

Edit `fluent-bit/conf/fluent-bit.conf` to add new INPUT/FILTER/OUTPUT sections.

### Modifying Log Parsers

Update parsers in `fluent-bit/conf/parsers.conf` and restart Fluent Bit:

```bash
docker-compose restart fluent-bit
```

### Environment IDs

Update the `ENV_IDS` array in `scripts/download-logs.sh` with your AEM Cloud Manager environment IDs.

## Security Considerations

- **Change default passwords** in `.env` before production use
- Keep `secured-config/aio_cm_config.json` out of version control (already in `.gitignore`)
- Enable Elasticsearch security features for production deployments
- Use HTTPS/TLS for external access to Kibana

## License

[MIT](LICENSE)

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -am 'Add new feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Submit a pull request

## Resources

- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Kibana Documentation](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Fluent Bit Documentation](https://docs.fluentbit.io/)
- [Adobe IO CLI Documentation](https://developer.adobe.com/runtime/docs/guides/tools/cli_install/)
- [AEM Cloud Manager Logging](https://experienceleague.adobe.com/docs/experience-manager-cloud-service/content/implementing/developer-tools/logging.html)

## Support

For issues and feature requests, please use the [GitHub Issues](https://github.com/munim/aem-efk-stack/issues) page.
