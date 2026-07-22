const express = require('express');
const { getRouting, getIsoline, getMapConfig } = require('../controllers/mapController');

const router = express.Router();

router.get('/routing', getRouting);
router.get('/isoline', getIsoline);
router.get('/config', getMapConfig);

module.exports = router;
