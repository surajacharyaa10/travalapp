const axios = require('axios');

const getNearbyPlaces = async (req, res) => {
  try {
    const { lat, lng, type, radius = 5000 } = req.query;
    
    if (!lat || !lng) {
      return res.status(400).json({ message: 'Latitude and Longitude are required' });
    }

    const url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=${radius}${type ? `&type=${type}` : ''}&key=${process.env.GOOGLE_PLACES_API_KEY}`;
    
    const response = await axios.get(url);
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching nearby places', error: error.message });
  }
};

const searchPlaces = async (req, res) => {
  try {
    const { query } = req.query;
    
    if (!query) {
      return res.status(400).json({ message: 'Search query is required' });
    }

    const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(query)}&key=${process.env.GOOGLE_PLACES_API_KEY}`;
    
    const response = await axios.get(url);
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ message: 'Error searching places', error: error.message });
  }
};

module.exports = {
  getNearbyPlaces,
  searchPlaces,
};
