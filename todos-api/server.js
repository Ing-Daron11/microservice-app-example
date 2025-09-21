'use strict';
const express = require('express')
const bodyParser = require("body-parser")
const jwt = require('express-jwt')

const ZIPKIN_URL = process.env.ZIPKIN_URL || 'http://127.0.0.1:9411/api/v2/spans';
const {Tracer, 
  BatchRecorder,
  jsonEncoder: {JSON_V2}} = require('zipkin');
  const CLSContext = require('zipkin-context-cls');  
const {HttpLogger} = require('zipkin-transport-http');
const zipkinMiddleware = require('zipkin-instrumentation-express').expressMiddleware;

const logChannel = process.env.REDIS_CHANNEL || 'log_channel';

// Configuración de Redis para Azure
const redisConfig = {
  host: process.env.REDIS_HOST || 'localhost',
  port: process.env.REDIS_PORT || 6379,
  retry_strategy: function (options) {
      if (options.error && options.error.code === 'ECONNREFUSED') {
          return new Error('The server refused the connection');
      }
      if (options.total_retry_time > 1000 * 60 * 60) {
          return new Error('Retry time exhausted');
      }
      if (options.attempt > 10) {
          console.log('reattempting to connect to redis, attempt #' + options.attempt)
          return undefined;
      }
      return Math.min(options.attempt * 100, 2000);
  }
};

// Agregar configuración SSL para Azure Redis Cache
if (process.env.AZURE_REDIS_SSL === 'true' && process.env.REDIS_PASSWORD) {
    redisConfig.password = process.env.REDIS_PASSWORD;
    redisConfig.tls = {
        servername: process.env.REDIS_HOST
    };
    console.log('Redis configured for Azure with SSL/TLS');
}

const redisClient = require("redis").createClient(redisConfig);

// Event handlers para Redis
redisClient.on('connect', () => {
    console.log('✅ Connected to Redis successfully');
});

redisClient.on('error', (err) => {
    console.error('❌ Redis connection error:', err);
});

redisClient.on('ready', () => {
    console.log('🚀 Redis client ready');
});

const port = process.env.TODO_API_PORT || 8082
const jwtSecret = process.env.JWT_SECRET || "foo"

const app = express()

// tracing
const ctxImpl = new CLSContext('zipkin');
const recorder = new  BatchRecorder({
  logger: new HttpLogger({
    endpoint: ZIPKIN_URL,
    jsonEncoder: JSON_V2
  })
});
const localServiceName = 'todos-api';
const tracer = new Tracer({ctxImpl, recorder, localServiceName});

// JWT middleware - excluir rutas de health check
app.use(jwt({ 
  secret: jwtSecret,
  requestProperty: 'user'
}).unless({
  path: ['/health', '/health/cache']
}));

app.use(zipkinMiddleware({tracer}));

app.use(function (err, req, res, next) {
  if (err.name === 'UnauthorizedError') {
    res.status(401).json({ 
      error: 'Unauthorized',
      message: 'Invalid or missing token',
      timestamp: new Date().toISOString()
    });
  } else {
    next(err);
  }
})

app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.json())

const routes = require('./routes')
routes(app, {tracer, redisClient, logChannel})

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 SIGTERM received, closing server...');
  redisClient.quit(() => {
    console.log('📴 Redis connection closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('🛑 SIGINT received, closing server...');
  redisClient.quit(() => {
    console.log('📴 Redis connection closed');
    process.exit(0);
  });
});

const server = app.listen(port, function () {
  console.log('🎯 Todo list RESTful API server started on port:', port)
  console.log('💾 Cache-Aside pattern enabled')
  console.log('🌐 Health endpoints available: /health, /health/cache')
})

// Export server para testing
module.exports = server;