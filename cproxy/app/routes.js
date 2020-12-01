'use strict';

const Router = require('koa-router');
const miscController = require('./controllers/misc');
const substrateController = require('./controllers/substrate');


const router = new Router();
router.get('/', miscController.getApiInfo);
router.get('/spec', miscController.getSwaggerSpec);
router.get('/status', miscController.healthcheck);

router.post('/bindStash', substrateController.bindStash);
router.post('/topUp', substrateController.topUp);
router.post('/setCommission', substrateController.setCommission);
router.post('/startIntention', substrateController.startIntention);
router.post('/stopIntention', substrateController.stopIntention);

module.exports = router;
