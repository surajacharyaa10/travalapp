const express = require('express');
const router = express.Router();
const { getNearbyPlaces, searchPlaces } = require('../controllers/placesController');
const { protect } = require('../middleware/authMiddleware');

router.get('/nearby', protect, getNearbyPlaces);
router.get('/search', protect, searchPlaces);

module.exports = router;
