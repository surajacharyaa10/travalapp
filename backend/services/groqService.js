const Groq = require('groq-sdk');
require('dotenv').config();

let groq;
try {
  if (process.env.GROQ_API_KEY && !process.env.GROQ_API_KEY.startsWith('your_')) {
    groq = new Groq({
      apiKey: process.env.GROQ_API_KEY,
    });
  }
} catch (e) {
  console.warn("Groq SDK failed to initialize: " + e.message);
}

const getRecommendations = async (preferences, location, searchHistory) => {
  try {
    if (!groq) {
      throw new Error("Groq API client not initialized");
    }

    const prompt = `You are an intelligent travel guide. Based on the user's preferences: [${preferences.join(', ')}], their current location/country: ${location}, and their search history: [${searchHistory.join(', ')}], provide 3 personalized travel recommendations for this specific place and its country. 
    You MUST respond in a JSON object with a single "recommendations" key containing an array of objects. Each object must have "name" and "description" keys.`;

    const chatCompletion = await groq.chat.completions.create({
      messages: [
        {
          role: 'system',
          content: 'You are a helpful travel assistant. Always output valid JSON.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      model: 'llama-3.1-8b-instant',
      response_format: { type: "json_object" }
    });

    return chatCompletion.choices[0]?.message?.content || '{}';
  } catch (error) {
    console.error('Error fetching recommendations from Groq, using fallback:', error.message);
    
    try {
      const geoapifyKey = process.env.GEOAPIFY_API_KEY;
      if (geoapifyKey) {
        const axios = require('axios');
        const geoUrl = `https://api.geoapify.com/v1/geocode/search?text=${encodeURIComponent(location || 'Kathmandu')}&apiKey=${geoapifyKey}&limit=1`;
        const geoRes = await axios.get(geoUrl);
        
        if (geoRes.data.features && geoRes.data.features.length > 0) {
          const lat = geoRes.data.features[0].properties.lat;
          const lon = geoRes.data.features[0].properties.lon;
          
          let category = 'tourism.attraction';
          if (preferences && preferences.join(' ').toLowerCase().includes('dining')) category = 'catering.restaurant';
          
          const placesUrl = `https://api.geoapify.com/v2/places?categories=${category}&filter=circle:${lon},${lat},15000&limit=3&apiKey=${geoapifyKey}`;
          const placesRes = await axios.get(placesUrl);
          
          const places = (placesRes.data.features || []).filter(p => p.properties.name).map(p => ({
            name: p.properties.name,
            description: p.properties.address_line2 || `A fantastic location based on your interest near ${location}.`
          }));
          
          if (places.length > 0) {
            return JSON.stringify({ recommendations: places });
          }
        }
      }
    } catch (fallbackErr) {
      console.error('Fallback also failed:', fallbackErr.message);
    }

    return JSON.stringify({
      recommendations: [
        {
          name: "Add your GROQ_API_KEY",
          description: "Please configure your Groq API key in the backend .env file to get real personalized AI travel suggestions!"
        },
        {
          name: "Alpine Peak Viewpoint",
          description: `A breathtaking destination matching your interest in adventure and scenic views near ${location || 'your area'}. Enjoy early morning sunrise sights.`
        }
      ]
    });
  }
}
const axios = require('axios');

const chatWithRAG = async (message, locationContext, searchHistory) => {
  try {
    const geoapifyKey = process.env.GEOAPIFY_API_KEY;
    if (!geoapifyKey) throw new Error("No Geoapify API key found in .env");

    let text_reply = "I couldn't understand that query. Could you please rephrase?";
    let locationQuery = message;
    let category = "tourism.attraction,tourism.sights";
    let searchPlaces = false;
    let formattedLocationName = "";

    if (groq) {
      const prompt = `You are an AI travel guide. The user says: "${message}".
      If the user is asking for general information or an explanation (like "explain about Nepal"), provide a helpful, detailed conversational text reply.
      If the user is looking for specific places (like hotels, cafes, restaurants, museums, tourist spots), provide a brief conversational intro, set "needs_places" to true, and extract the "location" and "category".
      Valid categories are: "accommodation.hotel", "catering.cafe", "catering.restaurant", "tourism.attraction,tourism.sights".
      Return a JSON object with:
      - "text_reply": Your conversational response answering their question or introducing the places.
      - "needs_places": boolean
      - "location": The city/country they want (if any)
      - "category": The category string if they need places, otherwise empty.`;

      const chatCompletion = await groq.chat.completions.create({
        messages: [{ role: 'system', content: 'Always output valid JSON.' }, { role: 'user', content: prompt }],
        model: 'llama-3.1-8b-instant',
        response_format: { type: "json_object" }
      });

      const result = JSON.parse(chatCompletion.choices[0]?.message?.content || '{}');
      text_reply = result.text_reply || "Here is what I found.";
      if (result.needs_places) {
        searchPlaces = true;
        locationQuery = result.location || locationContext || message;
        category = result.category || category;
      }
    } else {
      const msgLower = message.toLowerCase().trim();
      
      if (msgLower === 'halo' || msgLower === 'hello' || msgLower === 'hi') {
        return JSON.stringify({
          text_reply: "Hello! I am your AI travel guide. Ask me to explain about a country or find the best cafes/hotels in a specific city.",
          places: []
        });
      }

      if (msgLower.includes('hotel') || msgLower.includes('hostel') || msgLower.includes('stay') || msgLower.includes('accommodation')) category = 'accommodation.hotel';
      else if (msgLower.includes('cafe') || msgLower.includes('coffee')) category = 'catering.cafe';
      else if (msgLower.includes('restaurant') || msgLower.includes('food')) category = 'catering.restaurant';
      else if (msgLower.includes('museum')) category = 'tourism.attraction';

      const match = msgLower.match(/\b(?:in|about|for|near|at)\s+([a-z\s,]+)/);
      if (match && match[1]) {
        locationQuery = match[1].trim();
        // Capitalize the first letter of each word for nicer formatting
        locationQuery = locationQuery.split(' ').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
      }

      if (msgLower.includes('explain') || msgLower.includes('what is') || msgLower.includes('about')) {
        try {
          const wikiRes = await axios.get(
            `https://en.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(locationQuery)}`,
            { headers: { 'User-Agent': 'TravelAppAgent/1.0 (contact@travelapp.com)' } }
          );
          if (wikiRes.data && wikiRes.data.extract) {
            text_reply = wikiRes.data.extract;
          } else {
            text_reply = `You asked about ${locationQuery}. (Please configure your Groq API key in the backend .env file to unlock fully detailed AI travel explanations!)`;
          }
        } catch (wikiErr) {
          text_reply = `You asked about ${locationQuery}. (Please configure your Groq API key in the backend .env file to unlock fully detailed AI travel explanations!)`;
        }
        searchPlaces = false;
      } else {
        text_reply = `Here are some excellent options I found in ${locationQuery}:`;
        searchPlaces = true;
      }
    }

    let places = [];

    if (searchPlaces && locationQuery) {
      // Geocode to find coordinates
      const geoUrl = `https://api.geoapify.com/v1/geocode/search?text=${encodeURIComponent(locationQuery)}&apiKey=${geoapifyKey}&limit=1`;
      const geoRes = await axios.get(geoUrl);

      if (geoRes.data.features && geoRes.data.features.length > 0) {
        const feature = geoRes.data.features[0];
        const lat = feature.properties.lat;
        const lon = feature.properties.lon;
        formattedLocationName = feature.properties.formatted;

        // Find nearby places
        if (locationQuery.toLowerCase() === 'nepal' && category.includes('tourism')) {
          places = [
            {
              name: "Pokhara Valley",
              lat: 28.2096,
              lng: 83.9856,
              address: "Kaski District, Gandaki Province, Nepal",
              rating: 4.9
            },
            {
              name: "Pashupatinath Temple",
              lat: 27.7104,
              lng: 85.3487,
              address: "Kathmandu, Bagmati Province, Nepal",
              rating: 4.8
            },
            {
              name: "Lumbini (Birthplace of Buddha)",
              lat: 27.4784,
              lng: 83.2758,
              address: "Rupandehi District, Lumbini Province, Nepal",
              rating: 4.9
            },
            {
              name: "Annapurna Base Camp",
              lat: 28.5300,
              lng: 83.8780,
              address: "Annapurna Conservation Area, Nepal",
              rating: 4.9
            },
            {
              name: "Kathmandu Durbar Square",
              lat: 27.7042,
              lng: 85.3067,
              address: "Kathmandu, Bagmati Province, Nepal",
              rating: 4.7
            },
            {
              name: "Mount Everest Base Camp",
              lat: 28.0026,
              lng: 86.8530,
              address: "Solukhumbu, Koshi Province, Nepal",
              rating: 5.0
            }
          ];
        } else {
          let filterParam = `circle:${lon},${lat},20000`;
          if (feature.properties.result_type === 'country' && feature.properties.place_id) {
            filterParam = `place:${feature.properties.place_id}`;
          }
          
          const placesUrl = `https://api.geoapify.com/v2/places?categories=${category}&filter=${filterParam}&bias=proximity:${lon},${lat}&limit=10&apiKey=${geoapifyKey}`;
          const placesRes = await axios.get(placesUrl);
          
          places = (placesRes.data.features || [])
            .filter(p => p.properties.name)
            .map(p => ({
              name: p.properties.name,
              lat: p.properties.lat,
              lng: p.properties.lon,
              address: p.properties.address_line2 || formattedLocationName,
              rating: 4.0 + Math.round(Math.random() * 10) / 10
            }));
            
          if (places.length === 0) {
             // Fallback place if no results
             places = [{ name: `Popular Place in ${formattedLocationName}`, lat: lat, lng: lon, address: formattedLocationName, rating: 4.5 }];
          }
        }
        
        if (!groq) {
           text_reply = `Here are some excellent options I found in ${formattedLocationName}:`;
        }
      } else {
         if (!groq) text_reply = `I couldn't find the location "${locationQuery}".`;
      }
    }

    return JSON.stringify({
      text_reply,
      places
    });

  } catch (error) {
    console.error('Error in RAG logic:', error.message);
    return JSON.stringify({
      text_reply: "I'm having trouble processing your request right now. Please try again later.",
      places: []
    });
  }
};

module.exports = {
  getRecommendations,
  chatWithRAG,
};
