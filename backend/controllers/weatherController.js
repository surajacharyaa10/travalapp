const axios = require('axios');

const isPlaceholderKey = (key) => {
  return !key || key === 'your_openweathermap_api_key_here' || key.trim() === '';
};

const getWeather = async (req, res) => {
  try {
    const { lat, lng, city } = req.query;
    let url = '';

    if (isPlaceholderKey(process.env.WEATHER_API_KEY)) {
      // Return high-quality mock weather data
      return res.json({
        name: city || 'Current Location',
        main: {
          temp: 22.5,
          feels_like: 22.1,
          temp_min: 19.0,
          temp_max: 25.0,
          pressure: 1012,
          humidity: 62
        },
        weather: [
          {
            main: 'Clouds',
            description: 'scattered clouds',
            icon: '03d'
          }
        ],
        wind: {
          speed: 3.6,
          deg: 180
        }
      });
    }

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
