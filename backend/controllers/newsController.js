const axios = require('axios');

const getNews = async (req, res) => {
  try {
    const { query = 'travel', language = 'en' } = req.query;

    const url = `https://newsapi.org/v2/everything?q=${encodeURIComponent(query)}&language=${language}&sortBy=publishedAt&apiKey=${process.env.NEWS_API_KEY}`;
    
    const response = await axios.get(url);
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching news data', error: error.message });
  }
};

module.exports = {
  getNews,
};
