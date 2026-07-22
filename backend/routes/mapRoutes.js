const express = require('express');
const { getRouting, getIsoline, getMapConfig, getTile } = require('../controllers/mapController');

const router = express.Router();

router.get('/routing', getRouting);
router.get('/isoline', getIsoline);
router.get('/config', getMapConfig);
router.get('/tile/:z/:x/:y', getTile);

module.exports = router;
