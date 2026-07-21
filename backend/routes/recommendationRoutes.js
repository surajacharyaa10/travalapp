const express = require('express');
const router = express.Router();
const { fetchRecommendations, saveSearchHistory } = require('../controllers/recommendationController');
const { protect } = require('../middleware/authMiddleware');

router.post('/', protect, fetchRecommendations);
router.post('/history', protect, saveSearchHistory);

module.exports = router;
