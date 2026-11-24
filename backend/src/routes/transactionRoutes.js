const router = require('express').Router();
const validateZod = require('../middlewares/validateZod');
const { verifyToken } = require('../middlewares/auth');
const { allowRoles } = require('../middlewares/role');
const { idParam } = require('../validations/helpers');
const { listTransactionQuery, verifyBody } = require('../validations/transaction');
const {
  listTransactions,
  verifyTransaction,
} = require('../controllers/transactionController');

router.use(verifyToken, allowRoles('admin', 'customer'));

router.get('/', validateZod({ query: listTransactionQuery }), listTransactions);
router.patch(
  '/:id/verify',
  allowRoles('admin'),
  validateZod({ params: idParam, body: verifyBody }),
  verifyTransaction
);

module.exports = router;
