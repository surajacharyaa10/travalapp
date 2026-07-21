const Bookmark = require('../models/Bookmark');

const addBookmark = async (req, res) => {
  try {
    const { placeId, name, address, category } = req.body;

    const bookmark = new Bookmark({
      user: req.user.id,
      placeId,
      name,
      address,
      category,
    });

    await bookmark.save();
    res.status(201).json(bookmark);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const getBookmarks = async (req, res) => {
  try {
    const bookmarks = await Bookmark.find({ user: req.user.id }).sort({ createdAt: -1 });
    res.json(bookmarks);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const removeBookmark = async (req, res) => {
  try {
    const bookmark = await Bookmark.findById(req.params.id);

    if (!bookmark) {
      return res.status(404).json({ message: 'Bookmark not found' });
    }

    if (bookmark.user.toString() !== req.user.id) {
      return res.status(401).json({ message: 'Not authorized to remove this bookmark' });
    }

    await Bookmark.findByIdAndDelete(req.params.id);
    res.json({ message: 'Bookmark removed' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = {
  addBookmark,
  getBookmarks,
  removeBookmark,
};
