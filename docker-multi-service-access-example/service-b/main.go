package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

type ServiceAResponse struct {
	Message string `json:"message"`
	Service string `json:"service"`
	Time    string `json:"time"`
}

type ServiceBResponse struct {
	Message      string            `json:"message"`
	Service      string            `json:"service"`
	Time         string            `json:"time"`
	ServiceAData *ServiceAResponse `json:"service_a_data,omitempty"`
}

func main() {
	// Set Gin to release mode for production
	gin.SetMode(gin.ReleaseMode)

	r := gin.Default()

	// Configure CORS
	config := cors.DefaultConfig()
	config.AllowAllOrigins = true
	config.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	config.AllowHeaders = []string{"Origin", "Content-Type", "Accept", "Authorization"}
	r.Use(cors.New(config))

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "service-b",
			"time":    time.Now().Format(time.RFC3339),
		})
	})

	// External API endpoint
	r.GET("/api", func(c *gin.Context) {
		response := ServiceBResponse{
			Message: "Hello from Service B!",
			Service: "service-b",
			Time:    time.Now().Format(time.RFC3339),
		}
		c.JSON(http.StatusOK, response)
	})

	// Endpoint that communicates with Service A
	r.GET("/api/with-service-a", func(c *gin.Context) {
		serviceAURL := os.Getenv("SERVICE_A_URL")
		if serviceAURL == "" {
			// Use Traefik routing for cross-service communication
			serviceAURL = "http://localhost/service-a-internal"
		}

		// Call Service A
		serviceAResponse, err := callServiceA(serviceAURL)

		response := ServiceBResponse{
			Message: "Hello from Service B with Service A data!",
			Service: "service-b",
			Time:    time.Now().Format(time.RFC3339),
		}

		if err != nil {
			response.Message = fmt.Sprintf("Error calling Service A: %v", err)
			c.JSON(http.StatusInternalServerError, response)
			return
		}

		response.ServiceAData = serviceAResponse
		c.JSON(http.StatusOK, response)
	})

	// Internal endpoint for Service A to call
	r.GET("/internal", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Internal endpoint from Service B",
			"service": "service-b",
			"time":    time.Now().Format(time.RFC3339),
		})
	})

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "5001"
	}

	fmt.Printf("Service B starting on port %s\n", port)
	if err := r.Run("0.0.0.0:" + port); err != nil {
		panic(err)
	}
}

func callServiceA(serviceAURL string) (*ServiceAResponse, error) {
	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	resp, err := client.Get(serviceAURL + "/internal")
	if err != nil {
		return nil, fmt.Errorf("failed to call Service A: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %v", err)
	}

	var serviceAResponse ServiceAResponse
	if err := json.Unmarshal(body, &serviceAResponse); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %v", err)
	}

	return &serviceAResponse, nil
}
