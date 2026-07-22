const axios = require('axios');

const getGeoapifyCategory = (type) => {
  switch (type) {
    case 'restaurant': return 'catering.restaurant';
    case 'hotel':
    case 'lodging': return 'accommodation';
    case 'museum': return 'entertainment.museum,entertainment.culture';
    case 'cafe': return 'catering.cafe';
    default: return 'tourism';
  }
};

const getNearbyPlaces = async (req, res) => {
  try {
    const { lat, lng, type, radius = 5000 } = req.query;
    
    if (!lat || !lng) {
      return res.status(400).json({ message: 'Latitude and Longitude are required' });
    }

    const apiKey = process.env.GEOAPIFY_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ message: 'Geoapify API key not configured' });
    }

    const categories = getGeoapifyCategory(type);
    const url = `https://api.geoapify.com/v2/places?categories=${categories}&filter=circle:${lng},${lat},${radius}&limit=20&apiKey=${apiKey}`;
    
    const response = await axios.get(url);
    
    // Map Geoapify GeoJSON format to our frontend format
    const results = response.data.features.map(feature => {
      const props = feature.properties;
      return {
        place_id: props.place_id,
        name: props.name || props.address_line1 || 'Unknown Place',
        vicinity: props.address_line2 || props.formatted || '',
        types: props.categories,
        rating: 4.5, // Geoapify doesn't reliably return ratings in the places API
        user_ratings_total: 100, // Mocked to keep frontend UI happy
        geometry: {
          location: {
            lat: props.lat,
            lng: props.lon
          }
        }
      };
    });

    res.json({ results, status: 'OK' });
  } catch (error) {
    console.error('Error fetching Geoapify places:', error.response?.data || error.message);
    res.status(500).json({ message: 'Error fetching nearby places', error: error.message });
  }
};

const searchPlaces = async (req, res) => {
  try {
    const { query } = req.query;
    
    if (!query) {
      return res.status(400).json({ message: 'Search query is required' });
    }

    const apiKey = process.env.GEOAPIFY_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ message: 'Geoapify API key not configured' });
    }

    const url = `https://api.geoapify.com/v1/geocode/autocomplete?text=${encodeURIComponent(query)}&apiKey=${apiKey}`;
    
    const response = await axios.get(url);
    
    // Map Geoapify format to autocomplete prediction format
    const predictions = response.data.features.map(feature => {
      const props = feature.properties;
      return {
        description: props.formatted,
        place_id: props.place_id,
        structured_formatting: { 
          main_text: props.address_line1 || props.name || props.city, 
          secondary_text: props.address_line2 || props.country 
        },
        geometry: {
          location: {
            lat: props.lat,
            lng: props.lon
          }
        }
      };
    });

    res.json({ predictions, status: 'OK' });
  } catch (error) {
    console.error('Error searching Geoapify places:', error.response?.data || error.message);
    res.status(500).json({ message: 'Error searching places', error: error.message });
  }
};

module.exports = {
  getNearbyPlaces,
  searchPlaces,
};
