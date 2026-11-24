const mysql = require('mysql2/promise');

const useSSL = String(process.env.DB_SSL || '').toLowerCase() === 'true';

// Connection pool tunggal dipakai seluruh aplikasi
const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'barberly',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  dateStrings: true,
  decimalNumbers: true,
  ...(useSSL ? { ssl: { rejectUnauthorized: false } } : {}),
});

module.exports = pool;
