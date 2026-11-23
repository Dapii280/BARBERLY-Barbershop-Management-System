const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Halo, Express jalan!');
});

app.listen(port, () => {
  console.log(`Server jalan di http://localhost:${port}`);
});
