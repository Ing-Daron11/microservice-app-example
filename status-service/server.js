const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello World from Status Service',
    status: 'running'
  });
});

app.listen(PORT, () => {
  console.log('Status Service running on port ' + PORT);
});