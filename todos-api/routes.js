// filepath: todos-api/routes.js
'use strict';
const TodoController = require('./todoController');
module.exports = function (app, {tracer, redisClient, logChannel}) {
  const todoController = new TodoController({tracer, redisClient, logChannel});
  
  // CRUD endpoints principales
  app.route('/todos')
    .get(function(req,resp) {return todoController.list(req,resp)})
    .post(function(req,resp) {return todoController.create(req,resp)});

  app.route('/todos/:taskId')
    .delete(function(req,resp) {return todoController.delete(req,resp)});

  // Health check básico (sin autenticación)
  app.route('/health')
    .get(function(req,resp) {
      const cacheStats = todoController.getCacheStatistics();
      resp.json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        service: 'todos-api',
        cache: {
          pattern: 'Cache-Aside',
          statistics: cacheStats
        }
      });
    });

  // Cache statistics endpoint (sin autenticación)
  app.route('/health/cache')
    .get(function(req,resp) {
      const stats = todoController.getCacheStatistics();
      resp.json({
        pattern: 'Cache-Aside',
        statistics: stats,
        status: stats.total > 0 ? 'active' : 'idle'
      });
    });
};