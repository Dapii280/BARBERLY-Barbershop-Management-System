const router = require('express').Router();
const { verifyToken } = require('../middlewares/auth');
const { allowRoles } = require('../middlewares/role');
const { getSummary } = require('../controllers/dashboardController');

router.get('/summary', verifyToken, allowRoles('admin'), getSummary);

module.exports = router;
