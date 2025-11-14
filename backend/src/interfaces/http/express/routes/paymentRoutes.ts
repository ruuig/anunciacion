import { Router } from 'express';
import {
  createPayment,
  getPayments,
  getPaymentById,
  updatePayment,
  deletePayment,
  getPaymentStats,
  getStudentPaymentHistory,
} from '../controllers/paymentsController';

const router = Router();

// Rutas de pagos
router.post('/', createPayment);
router.get('/', getPayments);
router.get('/stats', getPaymentStats);
router.get('/student/:estudiante_id', getStudentPaymentHistory);
router.get('/:id', getPaymentById);
router.put('/:id', updatePayment);
router.delete('/:id', deletePayment);

export default router;
