# API Exporter

API Exporter is a simple Go application that measures the response time of specified API endpoints and exposes the metrics in a format compatible with Prometheus. It supports API key authentication through configurable headers.

## Features

- Measure response times for multiple API endpoints.
- Support for API key authentication via configurable headers.
- Expose metrics in Prometheus format.

## Prerequisites

- Go 1.16 or later
- Prometheus server (for scraping metrics)

## Download

You can download the latest release of API Exporter from the [Releases page](https://github.com/yourusername/api_exporter/releases).

### Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/mhellnerdev/api_exporter.git
   cd api_exporter
   ```

2. **Run the Install Script**:
   ```bash
   sudo ./install.sh
   ```

This will install the API Exporter from the pre-built release, set up the configuration, and start it as a systemd service.

## Build and Install

1. **Clone the repository**:

   ```bash
   git clone https://github.com/yourusername/api_exporter.git
   cd api_exporter
   ```

2. **Build the application**:

   ```bash
   go build -o api_exporter
   ```

3. **Install dependencies**:

   Make sure to install the required dependencies:

   ```bash
   go get gopkg.in/yaml.v2
   go get github.com/prometheus/client_golang/prometheus
   go get github.com/prometheus/client_golang/prometheus/promhttp
   ```

## Configuration

### API Configuration File

Create a YAML configuration file (e.g., `api_config.yml`) to specify the API keys and headers for the endpoints you want to monitor. The structure of the YAML file should be as follows:

```yaml
api_keys:
  "https://api.example.com":
    key: "your_api_key"
    header: "x-api-key"
  "https://another.api.com":
    key: "another_api_key"
    header: "x-api-key"
```

### Command-Line Flags

You can start the API Exporter with the following command-line flags:

- `--web.listen-address`: The address on which the web interface and telemetry will be exposed (default is `:9105`).
- `--config.api-config`: The path to the API configuration file.

### Example Command

To start the API Exporter, run:

```bash
./api_exporter --web.listen-address=0.0.0.0:9105 --config.api-config=/path/to/api_config.yml
```

## Usage

Once the API Exporter is running, you can scrape the metrics by accessing the `/metrics` endpoint. You can specify the target API endpoint as a query parameter.

### Example Request

To measure the response time for a specific API endpoint, use the following curl command:

```bash
curl "http://localhost:9105/metrics?target=https://api.example.com |grep api"
```

### Metrics Format

The metrics will be exposed in Prometheus format. You will see metrics like:

```
# HELP api_response_time_milliseconds Latest response time of API calls in milliseconds
# TYPE api_response_time_milliseconds gauge
api_response_time_milliseconds{endpoint="https://api.example.com", status="success"} 123
api_response_time_milliseconds{endpoint="https://api.example.com", status="error 404"} 404
```

## Prometheus Configuration

To scrape the metrics with Prometheus, add the following configuration to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'api_exporter'
    scrape_interval: 15s          # How often to scrape the metrics
    scrape_timeout: 10s           # Timeout for scraping
    static_configs:
      - targets: 
        - "https://api.example.com"
        - "https://another.api.com"
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: localhost:9105  # The API Exporter host:port
```

### Explanation of Configuration

- **job_name**: A label for the job that you are scraping.
- **scrape_interval**: How often Prometheus will scrape the metrics (e.g., every 15 seconds).
- **scrape_timeout**: The timeout for scraping the metrics.
- **static_configs**: Defines the targets to scrape. In this case, it points to your API endpoints.
- **relabel_configs**: Allows you to modify the labels of the scraped metrics:
  - **source_labels**: Specifies the labels to match against.
  - **target_label**: Specifies the label to set or modify.
  - **replacement**: Specifies the new value for the target label.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## Acknowledgments

- [Prometheus](https://prometheus.io/) for monitoring and alerting.
- [Go](https://golang.org/) for the programming language.
