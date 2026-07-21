const express = require('express');
const router = express.Router();
const { addBookmark, getBookmarks, removeBookmark } = require('../controllers/bookmarkController');
const { protect } = require('../middleware/authMiddleware');

router.route('/')
  .post(protect, addBookmark)
  .get(protect, getBookmarks);

router.route('/:id')
  .delete(protect, removeBookmark);

module.exports = router;
