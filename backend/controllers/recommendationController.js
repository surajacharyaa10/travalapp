const { getRecommendations } = require('../services/groqService');
const SearchHistory = require('../models/SearchHistory');

const fetchRecommendations = async (req, res) => {
  try {
    const { location, preferences } = req.body;
    
    // Fetch user's recent search history (up to 5)
    const recentSearches = await SearchHistory.find({ user: req.user.id })
      .sort({ createdAt: -1 })
      .limit(5);

    const searchQueries = recentSearches.map((s) => s.query);
    const userPrefs = preferences && preferences.length > 0 ? preferences : req.user.preferences;

    const aiResponse = await getRecommendations(userPrefs, location, searchQueries);
    
    res.json({ recommendations: aiResponse });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching recommendations', error: error.message });
  }
};

const saveSearchHistory = async (req, res) => {
  try {
    const { query, location } = req.body;

    const searchEntry = new SearchHistory({
      user: req.user.id,
      query,
      location,
    });

    await searchEntry.save();
    res.status(201).json(searchEntry);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = {
  fetchRecommendations,
  saveSearchHistory,
};
