require('dotenv').config();

const bcrypt = require('bcrypt');
const pool = require('./src/config/db');

const TEST_PASSWORD = 'password123';

const accounts = [
  {
    name: 'Admin Barberly',
    email: 'admin@barberly.test',
    phone: '081200000001',
    role: 'admin',
  },
  {
    name: 'Barber Demo',
    email: 'barber@barberly.test',
    phone: '081200000002',
    role: 'barber',
  },
  {
    name: 'Customer Demo',
    email: 'customer@barberly.test',
    phone: '081200000003',
    role: 'customer',
  },
];

const seed = async () => {
  const hashedPassword = await bcrypt.hash(TEST_PASSWORD, 10);

  for (const account of accounts) {
    const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [account.email]);

    if (existing.length > 0) {
      await pool.query(
        'UPDATE users SET name = ?, phone = ?, password = ?, role = ?, is_active = 1 WHERE id = ?',
        [account.name, account.phone, hashedPassword, account.role, existing[0].id]
      );
      console.log(`[update] ${account.email}`);
    } else {
      await pool.query(
        'INSERT INTO users (name, email, phone, password, role, is_active) VALUES (?, ?, ?, ?, ?, 1)',
        [account.name, account.email, account.phone, hashedPassword, account.role]
      );
      console.log(`[create] ${account.email}`);
    }
  }

  // Profil barber untuk akun barber@barberly.test
  const [barberUser] = await pool.query('SELECT id FROM users WHERE email = ?', [
    'barber@barberly.test',
  ]);

  if (barberUser.length > 0) {
    const [barberProfile] = await pool.query('SELECT id FROM barbers WHERE user_id = ?', [
      barberUser[0].id,
    ]);

    if (barberProfile.length === 0) {
      await pool.query(
        `INSERT INTO barbers (user_id, specialty, bio, work_start, work_end, is_active)
         VALUES (?, ?, ?, '09:00:00', '21:00:00', 1)`,
        [
          barberUser[0].id,
          'Haircut & Grooming',
          'Barber profesional dengan pengalaman lebih dari 5 tahun.',
        ]
      );
      console.log('[create] profil barber');
    }
  }

  // Cadangkan layanan dasar bila tabel services kosong
  const [services] = await pool.query('SELECT COUNT(*) AS total FROM services');
  if (Number(services[0].total) === 0) {
    await pool.query(
      `INSERT INTO services (name, description, price, duration_minutes, is_active) VALUES
       ('Haircut', 'Potong rambut pria lengkap dengan keramas dan styling', 50000.00, 45, 1),
       ('Shave', 'Cukur kumis dan jenggot rapi dengan handuk hangat', 30000.00, 30, 1),
       ('Hair Coloring', 'Pewarnaan rambut profesional dengan produk berkualitas', 120000.00, 90, 1)`
    );
    console.log('[create] 3 layanan dasar');
  }

  console.log('\nSeed selesai. Akun uji:');
  console.log(`- admin@barberly.test / ${TEST_PASSWORD}`);
  console.log(`- barber@barberly.test / ${TEST_PASSWORD}`);
  console.log(`- customer@barberly.test / ${TEST_PASSWORD}`);

  await pool.end();
};

seed().catch(async (error) => {
  console.error('Seed gagal:', error.message);
  await pool.end();
  process.exit(1);
});
