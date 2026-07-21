const axios = require('axios');

const getWeather = async (req, res) => {
  try {
    const { lat, lng, city } = req.query;
    let url = '';

    if (lat && lng) {
      url = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lng}&units=metric&appid=${process.env.WEATHER_API_KEY}`;
    } else if (city) {
      url = `https://api.openweathermap.org/data/2.5/weather?q=${encodeURIComponent(city)}&units=metric&appid=${process.env.WEATHER_API_KEY}`;
    } else {
      return res.status(400).json({ message: 'Latitude/Longitude or City is required' });
    }

    const response = await axios.get(url);
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching weather data', error: error.message });
  }
};

module.exports = {
  getWeather,
};
