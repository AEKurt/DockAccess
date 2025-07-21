import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useNavigate } from 'react-router-dom';
import axios from 'axios';
import './App.css';

// Configure axios base URL for production - always use Traefik
const API_BASE_URL = 'http://localhost:80';

// Dashboard Component
function Dashboard() {
    const [services, setServices] = useState({
        serviceA: { status: 'unknown', data: null },
        serviceB: { status: 'unknown', data: null }
    });

    const checkServiceHealth = async (serviceName) => {
        try {
            const response = await axios.get(`${API_BASE_URL}/${serviceName}/health`);
            return { status: 'healthy', data: response.data };
        } catch (error) {
            return { status: 'unhealthy', data: error.message };
        }
    };

    const checkAllServices = async () => {
        const serviceAHealth = await checkServiceHealth('service-a');
        const serviceBHealth = await checkServiceHealth('service-b');

        setServices({
            serviceA: serviceAHealth,
            serviceB: serviceBHealth
        });
    };

    useEffect(() => {
        checkAllServices();
        const interval = setInterval(checkAllServices, 30000); // Check every 30 seconds
        return () => clearInterval(interval);
    }, []);

    return (
        <div className="dashboard">
            <h2>Service Dashboard</h2>
            <div className="service-grid">
                <div className={`service-card ${services.serviceA.status}`}>
                    <h3>Service A</h3>
                    <p>Status: {services.serviceA.status}</p>
                    {services.serviceA.data && (
                        <pre>{JSON.stringify(services.serviceA.data, null, 2)}</pre>
                    )}
                </div>
                <div className={`service-card ${services.serviceB.status}`}>
                    <h3>Service B</h3>
                    <p>Status: {services.serviceB.status}</p>
                    {services.serviceB.data && (
                        <pre>{JSON.stringify(services.serviceB.data, null, 2)}</pre>
                    )}
                </div>
            </div>
            <button onClick={checkAllServices} className="refresh-btn">
                Refresh Services
            </button>
        </div>
    );
}

// Service Testing Component
function ServiceTest({ serviceName }) {
    const [endpoints, setEndpoints] = useState([]);
    const [selectedEndpoint, setSelectedEndpoint] = useState('');
    const [response, setResponse] = useState(null);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        // Define available endpoints for each service
        const serviceEndpoints = {
            'service-a': [
                { name: 'Health Check', path: '/health', method: 'GET' },
                { name: 'Get API Data', path: '/api', method: 'GET' },
                { name: 'Call Service B', path: '/api/with-service-b', method: 'GET' },
                { name: 'Internal Endpoint', path: '/internal', method: 'GET' }
            ],
            'service-b': [
                { name: 'Health Check', path: '/health', method: 'GET' },
                { name: 'Get API Data', path: '/api', method: 'GET' },
                { name: 'Call Service A', path: '/api/with-service-a', method: 'GET' },
                { name: 'Internal Endpoint', path: '/internal', method: 'GET' }
            ]
        };
        setEndpoints(serviceEndpoints[serviceName] || []);
    }, [serviceName]);

    const testEndpoint = async (endpoint) => {
        setLoading(true);
        setResponse(null);

        const fullUrl = `${API_BASE_URL}/${serviceName}${endpoint.path}`;

        try {
            let response;
            if (endpoint.method === 'GET') {
                response = await axios.get(fullUrl);
            } else if (endpoint.method === 'POST') {
                response = await axios.post(fullUrl, {
                    test: true,
                    timestamp: new Date().toISOString()
                });
            }

            setResponse({
                endpoint: fullUrl,
                method: endpoint.method,
                status: response.status,
                data: response.data,
                headers: response.headers
            });
        } catch (error) {
            setResponse({
                endpoint: fullUrl,
                method: endpoint.method,
                status: error.response?.status || 'Error',
                data: error.response?.data || error.message,
                headers: error.response?.headers || {}
            });
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="service-test">
            <h2>{serviceName.toUpperCase()} Service Testing</h2>
            <div className="endpoints">
                {endpoints.map((endpoint, index) => (
                    <button
                        key={index}
                        onClick={() => testEndpoint(endpoint)}
                        disabled={loading}
                        className="endpoint-btn"
                    >
                        {endpoint.method} {endpoint.name}
                    </button>
                ))}
            </div>

            {loading && <div className="loading">Testing endpoint...</div>}

            {response && (
                <div className="response">
                    <h3>Response:</h3>
                    <div className="response-details">
                        <p><strong>Endpoint:</strong> <code>{response.method} {response.endpoint}</code></p>
                        <p><strong>Status:</strong> {response.status}</p>
                        <pre>{JSON.stringify(response.data, null, 2)}</pre>
                    </div>
                </div>
            )}
        </div>
    );
}

// Cross-Service Communication Component
function CrossServiceTest() {
    const [testType, setTestType] = useState('');
    const [result, setResult] = useState(null);
    const [loading, setLoading] = useState(false);

    const runTest = async (type) => {
        setLoading(true);
        setResult(null);

        try {
            let response;
            let endpoint;
            switch (type) {
                case 'a-to-b':
                    endpoint = `${API_BASE_URL}/service-a/api/with-service-b`;
                    response = await axios.get(endpoint);
                    break;
                case 'b-to-a':
                    endpoint = `${API_BASE_URL}/service-b/api/with-service-a`;
                    response = await axios.get(endpoint);
                    break;
                case 'both':
                    // Test both services calling each other
                    const endpointA = `${API_BASE_URL}/service-a/api/with-service-b`;
                    const endpointB = `${API_BASE_URL}/service-b/api/with-service-a`;

                    const [serviceAResponse, serviceBResponse] = await Promise.all([
                        axios.get(endpointA),
                        axios.get(endpointB)
                    ]);

                    setResult({
                        status: 'Success',
                        endpoints: {
                            'service-a-to-b': endpointA,
                            'service-b-to-a': endpointB
                        },
                        data: {
                            'service-a-to-b': serviceAResponse.data,
                            'service-b-to-a': serviceBResponse.data
                        }
                    });
                    setLoading(false);
                    return;
                default:
                    throw new Error('Unknown test type');
            }

            setResult({
                endpoint: endpoint,
                status: response.status,
                data: response.data
            });
        } catch (error) {
            setResult({
                endpoint: endpoint,
                status: error.response?.status || 'Error',
                data: error.response?.data || error.message
            });
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="cross-service-test">
            <h2>Cross-Service Communication Testing</h2>
            <div className="test-buttons">
                <button
                    onClick={() => runTest('a-to-b')}
                    disabled={loading}
                    className="test-btn"
                >
                    Service A → Service B
                </button>
                <button
                    onClick={() => runTest('b-to-a')}
                    disabled={loading}
                    className="test-btn"
                >
                    Service B → Service A
                </button>
                <button
                    onClick={() => runTest('both')}
                    disabled={loading}
                    className="test-btn"
                >
                    Test Both Directions
                </button>
            </div>

            {loading && <div className="loading">Running test...</div>}

            {result && (
                <div className="result">
                    <h3>Test Result:</h3>
                    <div className="result-details">
                        {result.endpoint && (
                            <p><strong>Endpoint:</strong> <code>GET {result.endpoint}</code></p>
                        )}
                        {result.endpoints && (
                            <div>
                                <p><strong>Endpoints:</strong></p>
                                <ul>
                                    <li><code>GET {result.endpoints['service-a-to-b']}</code></li>
                                    <li><code>GET {result.endpoints['service-b-to-a']}</code></li>
                                </ul>
                            </div>
                        )}
                        <p><strong>Status:</strong> {result.status}</p>
                        <pre>{JSON.stringify(result.data, null, 2)}</pre>
                    </div>
                </div>
            )}
        </div>
    );
}

// Navigation Component
function Navigation() {
    const navigate = useNavigate();

    return (
        <nav className="navigation">
            <button onClick={() => navigate('/')} className="nav-btn">
                Dashboard
            </button>
            <button onClick={() => navigate('/service-a')} className="nav-btn">
                Service A
            </button>
            <button onClick={() => navigate('/service-b')} className="nav-btn">
                Service B
            </button>
            <button onClick={() => navigate('/cross-service')} className="nav-btn">
                Cross-Service
            </button>
        </nav>
    );
}

// Main App Component
function App() {
    return (
        <Router basename="/ui">
            <div className="App">
                <header className="App-header">
                    <h1>Multi-Service Application</h1>
                    <Navigation />
                </header>

                <main className="App-main">
                    <Routes>
                        <Route path="/" element={<Dashboard />} />
                        <Route path="/service-a" element={<ServiceTest serviceName="service-a" />} />
                        <Route path="/service-b" element={<ServiceTest serviceName="service-b" />} />
                        <Route path="/cross-service" element={<CrossServiceTest />} />
                    </Routes>
                </main>
            </div>
        </Router>
    );
}

export default App; 