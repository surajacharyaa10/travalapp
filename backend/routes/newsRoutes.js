const express = require('express');
const router = express.Router();
const { getNews } = require('../controllers/newsController');
const { protect } = require('../middleware/authMiddleware');

router.get('/', protect, getNews);

module.exports = router;
