const axios = require('axios');

const isPlaceholderKey = (key) => {
  return !key || key === 'your_google_places_api_key_here' || key.trim() === '';
};

const getNearbyPlaces = async (req, res) => {
  try {
    const { lat, lng, type, radius = 5000 } = req.query;
    
    if (!lat || !lng) {
      return res.status(400).json({ message: 'Latitude and Longitude are required' });
    }

    if (isPlaceholderKey(process.env.GOOGLE_PLACES_API_KEY)) {
      // Return high-quality mock places depending on requested type
      const mockPlaces = [
        {
          place_id: 'mock_place_1',
          name: 'The Grand Alpine Bistro',
          vicinity: '456 Mountain View Rd',
          types: ['restaurant', 'food', 'point_of_interest', 'establishment'],
          rating: 4.8,
          user_ratings_total: 230,
        },
        {
          place_id: 'mock_place_2',
          name: 'Serene Heights Resort & Spa',
          vicinity: '789 Pine Forest Ln',
          types: ['lodging', 'hotel', 'point_of_interest', 'establishment'],
          rating: 4.7,
          user_ratings_total: 512,
        },
        {
          place_id: 'mock_place_3',
          name: 'Heritage Travel Museum',
          vicinity: '101 Culture Blvd',
          types: ['museum', 'tourist_attraction', 'point_of_interest', 'establishment'],
          rating: 4.5,
          user_ratings_total: 120,
        },
        {
          place_id: 'mock_place_4',
          name: 'Aroma Peak Coffee House',
          vicinity: '12 Coffee Corner St',
          types: ['cafe', 'food', 'point_of_interest', 'establishment'],
          rating: 4.9,
          user_ratings_total: 340,
        }
      ];

      // Filter by type if provided
      let filtered = mockPlaces;
      if (type) {
        filtered = mockPlaces.filter(p => 
          p.types.includes(type) || 
          (type === 'restaurant' && p.types.includes('restaurant')) ||
          (type === 'hotel' && p.types.includes('lodging')) ||
          (type === 'museum' && p.types.includes('museum')) ||
          (type === 'cafe' && p.types.includes('cafe'))
        );
        // If type filter emptied everything, fallback to matching or return mock for that type specifically
        if (filtered.length === 0) {
          filtered = [
            {
              place_id: `mock_${type}_1`,
              name: `Top rated ${type.toUpperCase()}`,
              vicinity: 'Centrally Located District',
              types: [type],
              rating: 4.6,
              user_ratings_total: 88,
            }
          ];
        }
      }
      return res.json({ results: filtered, status: 'OK' });
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

    if (isPlaceholderKey(process.env.GOOGLE_PLACES_API_KEY)) {
      // Mock search autocomplete responses
      const mockPredictions = [
        {
          description: 'Pokhara, Nepal',
          place_id: 'mock_search_pokhara',
          structured_formatting: { main_text: 'Pokhara', secondary_text: 'Nepal' }
        },
        {
          description: 'Kathmandu, Nepal',
          place_id: 'mock_search_ktm',
          structured_formatting: { main_text: 'Kathmandu', secondary_text: 'Nepal' }
        },
        {
          description: 'Paris, France',
          place_id: 'mock_search_paris',
          structured_formatting: { main_text: 'Paris', secondary_text: 'France' }
        },
        {
          description: 'New York, NY, USA',
          place_id: 'mock_search_ny',
          structured_formatting: { main_text: 'New York', secondary_text: 'NY, USA' }
        }
      ].filter(item => item.description.toLowerCase().includes(query.toLowerCase()));

      return res.json({ predictions: mockPredictions, status: 'OK' });
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
