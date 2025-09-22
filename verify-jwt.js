const jwt = require('jsonwebtoken');

const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NTg2NTQyNzUsImlhdCI6MTc1ODU2Nzg3NSwic2NvcGUiOiJyZWFkIiwidXNlcm5hbWUiOiJhZG1pbiJ9.5JeRhtifJRGGsmVtz9GmrDMFqzjann9dNsI8nj4uWWY';
const secret = 'myfancysecret';

try {
    const decoded = jwt.verify(token, secret);
    console.log('Token válido:', decoded);
} catch (error) {
    console.error('Token inválido:', error.message);
}