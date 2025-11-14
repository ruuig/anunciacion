import { Router } from 'express';
import {
  assignBusService,
  deactivateBusService,
  getBusStudents,
  createBusPayment,
  getBusPayments,
  deleteBusPayment,
} from '../controllers/busServiceController';

const router = Router();

// Rutas de servicio de bus
router.post('/assign', assignBusService);
router.put('/deactivate/:estudiante_id', deactivateBusService);
router.get('/students', getBusStudents);

// Rutas de pagos de bus
router.post('/payments', createBusPayment);
router.get('/payments', getBusPayments);
router.delete('/payments/:id', deleteBusPayment);

export default router;
