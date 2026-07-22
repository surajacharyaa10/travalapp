const { fetchWeatherApi } = require('openmeteo');

const weatherCodeMap = {
  0: 'Clear sky', 1: 'Mainly clear', 2: 'Partly cloudy', 3: 'Overcast',
  45: 'Fog', 48: 'Depositing rime fog', 51: 'Light drizzle', 53: 'Moderate drizzle',
  55: 'Dense drizzle', 56: 'Light freezing drizzle', 57: 'Dense freezing drizzle',
  61: 'Slight rain', 63: 'Moderate rain', 65: 'Heavy rain', 66: 'Light freezing rain',
  67: 'Heavy freezing rain', 71: 'Slight snow fall', 73: 'Moderate snow fall',
  75: 'Heavy snow fall', 77: 'Snow grains', 80: 'Slight rain showers',
  81: 'Moderate rain showers', 82: 'Violent rain showers', 85: 'Slight snow showers',
  86: 'Heavy snow showers', 95: 'Thunderstorm', 96: 'Thunderstorm with slight hail',
  99: 'Thunderstorm with heavy hail',
};

const getWeather = async (req, res) => {
  try {
    const { lat, lng, city } = req.query;

    if (!lat || !lng) {
      return res.status(400).json({ message: 'Latitude and Longitude are required' });
    }

    const params = {
      latitude: parseFloat(lat),
      longitude: parseFloat(lng),
      past_days: 7,
      forecast_days: 7,
      daily: ["weather_code", "temperature_2m_max", "temperature_2m_min"],
      hourly: ["temperature_2m", "relative_humidity_2m", "weather_code"],
      current: ["temperature_2m", "weather_code", "wind_speed_10m", "cloud_cover"],
    };
    
    const url = "https://api.open-meteo.com/v1/forecast";
    const responses = await fetchWeatherApi(url, params);
    
    const response = responses[0];
    const utcOffsetSeconds = response.utcOffsetSeconds();
    const current = response.current();
    const hourly = response.hourly();
    const daily = response.daily();
    
    const temp = current.variables(0).value();
    const weatherCode = current.variables(1).value();
    const windSpeed = current.variables(2).value();
    
    // Get humidity from first hourly entry as current doesn't have it
    const humidityArray = hourly.variables(1).valuesArray();
    const humidity = humidityArray.length > 0 ? humidityArray[0] : 0;

    // Process daily forecast
    const dailyTime = Array.from(
      { length: (Number(daily.timeEnd()) - Number(daily.time())) / daily.interval() },
      (_ , i) => new Date((Number(daily.time()) + i * daily.interval() + utcOffsetSeconds) * 1000)
    );
    const dailyWeatherCode = Array.from(daily.variables(0).valuesArray());
    const dailyTempMax = Array.from(daily.variables(1).valuesArray());
    const dailyTempMin = Array.from(daily.variables(2).valuesArray());
    
    const dailyForecast = dailyTime.map((t, index) => ({
      date: t.toISOString(),
      weather_code: dailyWeatherCode[index],
      description: weatherCodeMap[dailyWeatherCode[index]] || 'Unknown',
      temp_max: dailyTempMax[index],
      temp_min: dailyTempMin[index],
    }));

    return res.json({
      name: city || 'Current Location',
      main: {
        temp: temp,
        humidity: humidity
      },
      weather: [
        {
          main: weatherCodeMap[weatherCode] || 'Unknown',
          description: weatherCodeMap[weatherCode] || 'Unknown',
          icon: '01d' 
        }
      ],
      wind: {
        speed: windSpeed
      },
      daily: dailyForecast
    });
  } catch (error) {
    console.error('Error fetching weather:', error);
    res.status(500).json({ message: 'Error fetching weather data', error: error.message });
  }
};

module.exports = {
  getWeather,
};
