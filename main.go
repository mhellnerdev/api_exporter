package main

import (
	"flag"
	"io/ioutil"
	"log"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"gopkg.in/yaml.v2"
)

// Configuration variables
var (
	useTLS      = false
	defaultPort = "9105"
	apiConfig   = make(map[string]struct {
		Key    string `yaml:"key"`
		Header string `yaml:"header"`
	}) // Map to hold API keys and headers for each host
)

// Load API keys and headers from the YAML configuration file
func loadAPIConfig(configPath string) error {
	data, err := ioutil.ReadFile(configPath)
	if err != nil {
		return err
	}

	var config struct {
		APIKeys map[string]struct {
			Key    string `yaml:"key"`
			Header string `yaml:"header"`
		} `yaml:"api_keys"`
	}

	err = yaml.Unmarshal(data, &config)
	if err != nil {
		return err
	}

	apiConfig = config.APIKeys
	return nil
}

func measureResponseTime(target string) (float64, int) {
	client := &http.Client{}
	req, err := http.NewRequest("GET", target, nil)
	if err != nil {
		return 0, 0
	}

	// Add API key to the request if it exists
	if config, exists := apiConfig[target]; exists {
		req.Header.Add(config.Header, config.Key) // Use the header specified in the config
	}

	start := time.Now()
	resp, err := client.Do(req)
	if err != nil {
		return 0, 0
	}
	defer resp.Body.Close()

	duration := time.Since(start).Milliseconds() // Convert to milliseconds
	return float64(duration), resp.StatusCode
}

func handler(w http.ResponseWriter, r *http.Request) {
	target := r.URL.Query().Get("target")
	if target == "" {
		http.Error(w, "Missing target parameter", http.StatusBadRequest)
		return
	}

	// Measure response time for the target
	duration, statusCode := measureResponseTime(target)

	// Create a temporary gauge for the current request
	tempGauge := prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "api_response_time_milliseconds",
			Help: "Latest response time of API calls in milliseconds",
		},
		[]string{"endpoint", "status"},
	)

	// Register the temporary gauge
	prometheus.MustRegister(tempGauge)

	// Set the value based on the status code
	if statusCode == http.StatusOK {
		tempGauge.WithLabelValues(target, "success").Set(duration)
	} else {
		// Record the error code for unsuccessful requests
		tempGauge.WithLabelValues(target, "error "+http.StatusText(statusCode)).Set(float64(statusCode))
	}

	// Serve the metrics for the current request
	promhttp.Handler().ServeHTTP(w, r)

	// Unregister the temporary gauge after serving
	prometheus.Unregister(tempGauge)
}

func main() {
	// Define command-line flags
	listenAddress := flag.String("web.listen-address", ":"+defaultPort, "Address to listen on for web interface and telemetry.")
	configPath := flag.String("config.api-config", "/etc/api_exporter/api_exporter.yml", "Path to the API configuration file.")
	flag.Parse()

	// Load API keys from the configuration file
	if err := loadAPIConfig(*configPath); err != nil {
		log.Fatalf("Error loading API config: %v", err)
	}

	http.HandleFunc("/metrics", handler)
	server := &http.Server{
		Addr:    *listenAddress,
		Handler: nil,
	}

	// Start the server without using the web package
	log.Printf("Listening on %s", *listenAddress)
	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
