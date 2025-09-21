'use strict';
const cache = require('memory-cache');
const {Annotation, 
    jsonEncoder: {JSON_V2}} = require('zipkin');

const OPERATION_CREATE = 'CREATE',
      OPERATION_DELETE = 'DELETE',
      OPERATION_UPDATE = 'UPDATE';

// Cache-Aside Pattern Configuration
const CACHE_TTL = 300000; // 5 minutes in milliseconds
const CACHE_PREFIX = 'todos:user:';

class TodoController {
    constructor({tracer, redisClient, logChannel}) {
        this._tracer = tracer;
        this._redisClient = redisClient;
        this._logChannel = logChannel;
        
        // Cache statistics for monitoring
        this._cacheStats = {
            hits: 0,
            misses: 0,
            sets: 0,
            invalidations: 0
        };
        
        console.log('TodoController initialized with Cache-Aside pattern');
    }

    // Cache-Aside Pattern Implementation for READ operations
    async list(req, res) {
        try {
            const username = req.user.username;
            const cacheKey = `${CACHE_PREFIX}${username}`;
            
            // Step 1: Try to get data from cache first (Cache-Aside READ)
            let data = await this._getFromCache(cacheKey);
            
            if (data === null) {
                // Step 2: Cache miss - get from data source
                console.log(`Cache MISS for user: ${username}`);
                this._cacheStats.misses++;
                
                data = this._getTodoDataFromSource(username);
                
                // Step 3: Store in cache for future requests (Cache-Aside Write)
                await this._setInCache(cacheKey, data);
                this._cacheStats.sets++;
                
                console.log(`Data cached for user: ${username}, TTL: ${CACHE_TTL}ms`);
            } else {
                console.log(`Cache HIT for user: ${username}`);
                this._cacheStats.hits++;
            }

            // Convert items object to array for frontend compatibility
            const itemsArray = Object.values(data.items);
            res.json(itemsArray);
        } catch (error) {
            console.error('Error in list operation:', error);
            res.status(500).json({
                error: 'Internal server error',
                message: 'Failed to retrieve todos',
                timestamp: new Date().toISOString()
            });
        }
    }

    // Cache-Aside Pattern Implementation for WRITE operations
    async create(req, res) {
        try {
            const username = req.user.username;
            const cacheKey = `${CACHE_PREFIX}${username}`;
            
            // Validate input
            if (!req.body.content || req.body.content.trim() === '') {
                return res.status(400).json({
                    error: 'Bad request',
                    message: 'Todo content is required'
                });
            }

            // Get current data (using cache-aside pattern)
            let data = await this._getFromCache(cacheKey);
            if (data === null) {
                console.log(`Cache miss during CREATE for user: ${username}`);
                data = this._getTodoDataFromSource(username);
                this._cacheStats.misses++;
            } else {
                this._cacheStats.hits++;
            }

            // Create new todo
            const todo = {
                content: req.body.content.trim(),
                id: data.lastInsertedID + 1,
                createdAt: new Date().toISOString(),
                userId: username
            };

            // Update data structure
            data.items[todo.id] = todo;
            data.lastInsertedID = todo.id;

            // Cache-Aside Write Strategy: Write-Through + Cache Update
            // Step 1: Update the persistent data source
            await this._setTodoDataInSource(username, data);
            
            // Step 2: Update cache with new data (Write-Through)
            await this._setInCache(cacheKey, data);
            this._cacheStats.sets++;
            
            console.log(`Cache updated for user: ${username} after CREATE`);

            // Log operation for audit trail
            this._logOperation(OPERATION_CREATE, username, todo.id);

            res.status(201).json(todo);
        } catch (error) {
            console.error('Error in create operation:', error);
            res.status(500).json({
                error: 'Internal server error',
                message: 'Failed to create todo',
                timestamp: new Date().toISOString()
            });
        }
    }

    async delete(req, res) {
        try {
            const username = req.user.username;
            const cacheKey = `${CACHE_PREFIX}${username}`;
            const todoId = parseInt(req.params.taskId);

            if (isNaN(todoId)) {
                return res.status(400).json({
                    error: 'Bad request',
                    message: 'Invalid todo ID'
                });
            }

            // Get current data (using cache-aside pattern)
            let data = await this._getFromCache(cacheKey);
            if (data === null) {
                console.log(`Cache miss during DELETE for user: ${username}`);
                data = this._getTodoDataFromSource(username);
                this._cacheStats.misses++;
            } else {
                this._cacheStats.hits++;
            }

            // Check if todo exists
            if (!data.items[todoId]) {
                return res.status(404).json({
                    error: 'Not found',
                    message: 'Todo not found'
                });
            }

            // Update data structure
            delete data.items[todoId];

            // Cache-Aside Write Strategy: Write-Through + Cache Update
            // Step 1: Update the persistent data source
            await this._setTodoDataInSource(username, data);
            
            // Step 2: Update cache with new data (Write-Through)
            await this._setInCache(cacheKey, data);
            this._cacheStats.sets++;
            
            console.log(`Cache updated for user: ${username} after DELETE`);

            // Log operation for audit trail
            this._logOperation(OPERATION_DELETE, username, todoId);

            res.status(204).send();
        } catch (error) {
            console.error('Error in delete operation:', error);
            res.status(500).json({
                error: 'Internal server error',
                message: 'Failed to delete todo',
                timestamp: new Date().toISOString()
            });
        }
    }

    // Cache-Aside Pattern Helper Methods
    async _getFromCache(key) {
        try {
            // Try Redis first (distributed cache for Azure multi-instance deployment)
            const redisData = await this._getFromRedisCache(key);
            if (redisData !== null) {
                return redisData;
            }
            
            // Fallback to local memory cache
            const localData = cache.get(key);
            if (localData) {
                // Populate Redis cache with local data for distributed consistency
                await this._setInRedisCache(key, localData);
                return localData;
            }
            
            return null;
        } catch (error) {
            console.error('Cache get error:', error);
            // Fallback to local cache on Redis error (resilience pattern)
            return cache.get(key) || null;
        }
    }

    async _setInCache(key, data) {
        try {
            // Set in both Redis (distributed) and local cache (performance)
            await this._setInRedisCache(key, data);
            cache.put(key, data, CACHE_TTL);
        } catch (error) {
            console.error('Cache set error:', error);
            // At least set in local cache for basic functionality
            cache.put(key, data, CACHE_TTL);
        }
    }

    // Redis Cache Operations for Azure Redis Cache
    async _getFromRedisCache(key) {
        return new Promise((resolve) => {
            if (!this._redisClient || !this._redisClient.connected) {
                resolve(null);
                return;
            }
            
            this._redisClient.get(key, (err, result) => {
                if (err || !result) {
                    resolve(null);
                } else {
                    try {
                        resolve(JSON.parse(result));
                    } catch (parseError) {
                        console.error('Redis parse error:', parseError);
                        resolve(null);
                    }
                }
            });
        });
    }

    async _setInRedisCache(key, data) {
        return new Promise((resolve) => {
            if (!this._redisClient || !this._redisClient.connected) {
                resolve(false);
                return;
            }
            
            try {
                const serializedData = JSON.stringify(data);
                const ttlSeconds = Math.floor(CACHE_TTL / 1000);
                
                this._redisClient.setex(key, ttlSeconds, serializedData, (err) => {
                    resolve(!err);
                });
            } catch (error) {
                console.error('Redis serialization error:', error);
                resolve(false);
            }
        });
    }

    // Data Source Operations (simulating persistent storage)
    _getTodoDataFromSource(userID) {
        console.log(`Loading data from source for user: ${userID}`);
        
        // In production, this would connect to a database
        const defaultData = {
            items: {
                '1': {
                    id: 1,
                    content: "Create new todo",
                    createdAt: new Date().toISOString(),
                    userId: userID
                },
                '2': {
                    id: 2,
                    content: "Implement Cache-Aside pattern",
                    createdAt: new Date().toISOString(),
                    userId: userID
                },
                '3': {
                    id: 3,
                    content: "Deploy to Azure",
                    createdAt: new Date().toISOString(),
                    userId: userID
                }
            },
            lastInsertedID: 3,
            userId: userID,
            createdAt: new Date().toISOString()
        };

        return defaultData;
    }

    async _setTodoDataInSource(userID, data) {
        // In production, this would persist to a database
        console.log(`Persisting data for user ${userID}:`, {
            itemCount: Object.keys(data.items).length,
            lastInsertedID: data.lastInsertedID
        });
        
        // Simulate async database operation
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve(true);
            }, 10); // Simulate small latency
        });
    }

    // Get cache statistics (for monitoring endpoint)
    getCacheStatistics() {
        const total = this._cacheStats.hits + this._cacheStats.misses;
        const hitRatio = total > 0 ? ((this._cacheStats.hits / total) * 100).toFixed(2) : 0;
        
        return {
            ...this._cacheStats,
            total: total,
            hitRatio: parseFloat(hitRatio),
            timestamp: new Date().toISOString(),
            pattern: 'Cache-Aside'
        };
    }

    // Legacy method for backward compatibility
    _getTodoData(userID) {
        return this._getTodoDataFromSource(userID);
    }

    _setTodoData(userID, data) {
        this._setTodoDataInSource(userID, data);
    }

    _logOperation(opName, username, todoId) {
        this._tracer.scoped(() => {
            const traceId = this._tracer.id;
            const logData = {
                zipkinSpan: traceId,
                opName: opName,
                username: username,
                todoId: todoId,
                timestamp: new Date().toISOString()
            };
            
            this._redisClient.publish(this._logChannel, JSON.stringify(logData));
            
            console.log(`Operation logged: ${opName} for user ${username}, todo ${todoId}`);
        });
    }
}

module.exports = TodoController;