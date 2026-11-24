require('dotenv').config();

const express = require('express');
const cors = require('cors');
const path = require('path');
const routes = require('./routes');
const { notFound, errorHandler } = require('./middlewares/errorHandler');

const app = express();

app.set('trust proxy', 1);
app.use(cors());
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));

// Akses gambar hasil upload lokal (dipakai saat Cloudinary belum dikonfigurasi)
app.use('/uploads', express.static(path.join(__dirname, '..', 'public', 'uploads')));

app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Barberly - Barbershop Management System API',
    data: { version: '1.0.0', baseUrl: '/api/v1' },
  });
});

app.use('/api/v1', routes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
