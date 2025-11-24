const express = require('express');
const client = require('prom-client');
const app = express();
const register = new client.Registry();
const db = require('./persistence');
const getItems = require('./routes/getItems');
const addItem = require('./routes/addItem');
const updateItem = require('./routes/updateItem');
const deleteItem = require('./routes/deleteItem');

app.use(express.json());
app.use(express.static(__dirname + '/static'));

// Prometheus metrics
client.collectDefaultMetrics({ register });

// Request count
const httpRequests = new client.Counter({
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status_code'],
});
register.registerMetric(httpRequests);

// middleware to count requests
app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
        httpRequests.inc({
            method: req.method,
            route: req.path,
            status_code: res.statusCode,
        });
    });
    next();
});

// metrics endpoint
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
});

// lightweight health check used by load balancers / orchestration
app.get('/health', async (req, res) => {
    try {
        // call a cheap DB operation to ensure persistence is available
        await db.getItems();
        res.sendStatus(200);
    } catch (err) {
        console.error('Health check failed:', err && err.message ? err.message : err);
        res.status(500).send('unhealthy');
    }
});

app.get('/api/items', getItems);
app.post('/api/items', addItem);
app.put('/api/items/:id', updateItem);
app.delete('/api/items/:id', deleteItem);

db.init().then(() => {
    app.listen(3000, '0.0.0.0', () => console.log('Listening on port 3000'));
}).catch((err) => {
    console.error(err);
    process.exit(1);
});

const gracefulShutdown = () => {
    db.teardown()
        .catch(() => { })
        .then(() => process.exit());
};

process.on('SIGINT', gracefulShutdown);
process.on('SIGTERM', gracefulShutdown);
process.on('SIGUSR2', gracefulShutdown); // Sent by nodemon
