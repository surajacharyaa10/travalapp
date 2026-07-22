const axios = require('axios');

const getRouting = async (req, res) => {
  try {
    const { waypoints, mode = 'drive' } = req.query;
    
    if (!waypoints) {
      return res.status(400).json({ message: 'Waypoints are required (e.g. lat,lon|lat,lon)' });
    }

    const apiKey = process.env.GEOAPIFY_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ message: 'Geoapify API key not configured' });
    }

    const url = `https://api.geoapify.com/v1/routing?waypoints=${waypoints}&mode=${mode}&apiKey=${apiKey}`;
    
    const response = await axios.get(url);
    res.json(response.data);
  } catch (error) {
    console.error('Error fetching routing:', error.response?.data || error.message);
    res.status(500).json({ message: 'Error fetching routing', error: error.message });
  }
};

const getIsoline = async (req, res) => {
  try {
    const { lat, lon, type = 'time', mode = 'drive', range = 900 } = req.query;
    
    if (!lat || !lon) {
      return res.status(400).json({ message: 'Latitude and Longitude are required' });
    }

    const apiKey = process.env.GEOAPIFY_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ message: 'Geoapify API key not configured' });
    }

    const url = `https://api.geoapify.com/v1/isoline?lat=${lat}&lon=${lon}&type=${type}&mode=${mode}&range=${range}&apiKey=${apiKey}`;
    
    const response = await axios.get(url);
    res.json(response.data);
  } catch (error) {
    console.error('Error fetching isoline:', error.response?.data || error.message);
    res.status(500).json({ message: 'Error fetching isoline', error: error.message });
  }
};

// We will return the API key strictly for the frontend map tile layer,
// since Map raster tiles must be loaded directly by flutter_map to be performant.
const getMapConfig = async (req, res) => {
  const apiKey = process.env.GEOAPIFY_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ message: 'Geoapify API key not configured' });
  }
  res.json({ apiKey, status: 'OK' });
};

module.exports = {
  getRouting,
  getIsoline,
  getMapConfig
};
