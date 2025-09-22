const jwt = require('jsonwebtoken');

const secret = 'myfancysecret';
const username = 'admin';

// Generate token like auth-api does
const token = jwt.sign({
    username: username,
    scope: 'read',
    exp: Math.floor(Date.now() / 1000) + (24 * 60 * 60) // 24 hours
}, secret);

console.log('Generated JWT token:');
console.log(token);

// Verify the token
try {
    const decoded = jwt.verify(token, secret);
    console.log('\nDecoded token:');
    console.log(decoded);
} catch (err) {
    console.log('Token verification failed:', err.message);
}