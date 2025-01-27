# Prometheus API Exporter

API Exporter is a Go application designed to monitor the response times of API endpoints. Built using the Prometheus exporter toolkit, it provides metrics in a format that Prometheus can easily consume. The application also allows for API key authentication through customizable headers, ensuring secure access to your APIs.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Download](#download)
- [Installation](#installation)
  - [Automatic Installation](#automatic-installation)
  - [Manual Installation](#manual-installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Prometheus Configuration](#prometheus-configuration)
- [License](#license)
- [Contributing](#contributing)
- [Acknowledgments](#acknowledgments)
- [Uninstallation](#uninstallation)

## Features

- Measure response times for multiple API endpoints in (ms).
- Support for API key authentication via configurable headers.
- Expose metrics in Prometheus format.

## Prerequisites

- Go 1.16 or later
- Prometheus server (for scraping metrics)

## Download

You can download the latest release of API Exporter from the [Releases page](https://github.com/mhellnerdev/api_exporter/releases).

## Installation

### Automatic Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/mhellnerdev/api_exporter.git
   cd api_exporter
   ```

2. **Run the Install Script**:
   ```bash
   sudo ./install.sh
   ```

This will perform the following actions:
- Create a user named `api_exporter` to run the service.
- Create the installation directory at `/etc/api_exporter`.
- Unpack the release tar.gz file into /tmp.
- Move the api_exporter binary to the /usr/local/bin/ directory.
- Create a default configuration file at `/etc/api_exporter/api_exporter.yml`.
- Set ownership of the installation directory and configuration file to the `api_exporter` user.
- Create a systemd service file to manage the API Exporter as a service.
- Reload systemd to recognize the new service.
- Enable and start the API Exporter service.

### Manual Installation

If you prefer to install manually, follow these steps:

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/mhellnerdev/api_exporter.git
   cd api_exporter
   ```

2. **Build the Binary**:
   ```bash
   go build -o api_exporter
   ```

3. **Move the Binary**:
   ```bash
   sudo mv api_exporter /usr/local/bin/
   ```

4. **Create the Configuration File**:
   Create a YAML configuration file (`/etc/api_exporter/api_exporter.yml`) to specify the API keys and headers for the endpoints you want to monitor. The structure of the YAML file should be as follows. Examples are shown for different `auth header` use:
   ```yaml
   api_keys:
     "https://api1.example.com":
       key: "your_api_key"
       header: "x-api-key"
     "https://api2.example.com":
       key: "your_api_key"
       header: "Authorization: Bearer"
     "https://api3.example.com":
       key: "your_api_key"
       header: "X-Auth-Token"
   ```

5. **Create the Systemd Service File**:
   Create a systemd service file at `/etc/systemd/system/api_exporter.service` with the following content:
   ```ini
   [Unit]
   Description=API Exporter
   After=network.target

   [Service]
   ExecStart=/usr/local/bin/api_exporter --config.api-config=/path/to/api_exporter.yml
   Restart=always
   User=api_exporter
   Group=api_exporter

   [Install]
   WantedBy=multi-user.target
   ```

6. **Reload Systemd**:
   ```bash
   sudo systemctl daemon-reload
   ```

7. **Enable and Start the Service**:
   ```bash
   sudo systemctl enable api_exporter
   sudo systemctl start api_exporter
   ```

## Configuration

### API Configuration File

Create a YAML configuration file (/etc/api_exporter/api_exporter.yml`) to specify the API keys and headers for the endpoints you want to monitor. The structure of the YAML file should be as follows:

 ```yaml
   api_keys:
     "https://api1.example.com":
       key: "your_api_key"
       header: "x-api-key"
     "https://api2.example.com":
       key: "your_api_key"
       header: "Authorization: Bearer"
     "https://api3.example.com":
       key: "your_api_key"
       header: "X-Auth-Token"
   ```

### Command-Line Flags

You can start the API Exporter with the following command-line flags:

- `--web.listen-address`: The address on which the web interface and telemetry will be exposed (default is `:9105`).
- `--config.api-config`: The path to the API configuration file.

### Example Command

To start the API Exporter, run:

```bash
./api_exporter --web.listen-address=0.0.0.0:9105 --config.api-config=/path/to/api_exporter.yml
```

## Usage

Once the API Exporter is running, you can scrape the metrics by accessing the `/metrics` endpoint. You can specify the target API endpoint as a query parameter.

### Example Request

To measure the response time for a specific API endpoint, use the following curl command:

```bash
curl "http://localhost:9105/metrics?target=https://api1.example.com | grep api"
```

### Metrics Format

The metrics will be exposed in Prometheus format. You will see metrics like:

```
# HELP api_response_time_milliseconds Latest response time of API calls in milliseconds
# TYPE api_response_time_milliseconds gauge
api_response_time_milliseconds{endpoint="https://api1.example.com", status="success"} 123
api_response_time_milliseconds{endpoint="https://api1.example.com", status="error 404"} 404
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
        - "https://api1.example.com"
        - "https://api2.example.com"
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
- [Prometheus Exporter Toolkit](https://github.com/prometheus/exporter-toolkit) Prometheus Exporter Toolkit
- [Prometheus](https://prometheus.io/) for monitoring and alerting.
- [Go](https://golang.org/) for the programming language.

## Uninstallation

To uninstall the API Exporter, you can use the provided uninstall script. This script will stop the service, remove the installation directory, and delete the user created for the API Exporter.

### Uninstall Script

1. **Run the Uninstall Script**:
   ```bash
   sudo ./uninstall.sh
   ```

This will stop and disable the API Exporter service, remove the installation directory, and clean up any associated files.
