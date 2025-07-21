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

type ServiceBResponse struct {
	Message string `json:"message"`
	Service string `json:"service"`
	Time    string `json:"time"`
}

type ServiceAResponse struct {
	Message      string            `json:"message"`
	Service      string            `json:"service"`
	Time         string            `json:"time"`
	ServiceBData *ServiceBResponse `json:"service_b_data,omitempty"`
}

func main() {
	// Set Gin mode based on environment
	if os.Getenv("GIN_MODE") == "" {
		gin.SetMode(gin.DebugMode) // Use debug mode for development
	}

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
			"service": "service-a",
			"time":    time.Now().Format(time.RFC3339),
		})
	})

	// External API endpoint
	r.GET("/api", func(c *gin.Context) {
		response := ServiceAResponse{
			Message: "Hello from Service A!",
			Service: "service-a",
			Time:    time.Now().Format(time.RFC3339),
		}
		c.JSON(http.StatusOK, response)
	})

	// Endpoint that communicates with Service B
	r.GET("/api/with-service-b", func(c *gin.Context) {
		serviceBURL := os.Getenv("SERVICE_B_URL")
		if serviceBURL == "" {
			// Use Traefik routing for cross-service communication
			serviceBURL = "http://localhost/service-b-internal"
		}

		// Call Service B
		serviceBResponse, err := callServiceB(serviceBURL)

		response := ServiceAResponse{
			Message: "Hello from Service A with Service B data!",
			Service: "service-a",
			Time:    time.Now().Format(time.RFC3339),
		}

		if err != nil {
			response.Message = fmt.Sprintf("Error calling Service B: %v", err)
			c.JSON(http.StatusInternalServerError, response)
			return
		}

		response.ServiceBData = serviceBResponse
		c.JSON(http.StatusOK, response)
	})

	// Internal endpoint for Service B to call
	r.GET("/internal", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Internal endpoint from Service A",
			"service": "service-a",
			"time":    time.Now().Format(time.RFC3339),
		})
	})

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	fmt.Printf("Service A starting on port %s\n", port)
	if err := r.Run("0.0.0.0:" + port); err != nil {
		panic(err)
	}
}

func callServiceB(serviceBURL string) (*ServiceBResponse, error) {
	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	resp, err := client.Get(serviceBURL + "/internal")
	if err != nil {
		return nil, fmt.Errorf("failed to call Service B: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %v", err)
	}

	var serviceBResponse ServiceBResponse
	if err := json.Unmarshal(body, &serviceBResponse); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %v", err)
	}

	return &serviceBResponse, nil
}
