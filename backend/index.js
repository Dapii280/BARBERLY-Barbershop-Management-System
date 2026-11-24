const app = require('./src/app');

const PORT = process.env.PORT || 5000;

// Listen hanya saat dijalankan langsung (bukan di serverless Vercel)
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Barberly API berjalan di http://localhost:${PORT}/api/v1`);
  });
}

module.exports = app;
