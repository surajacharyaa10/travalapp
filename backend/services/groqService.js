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
    console.error('Error fetching recommendations from Groq, using mock fallback:', error.message);
    return JSON.stringify({
      recommendations: [
        {
          name: "Alpine Peak Viewpoint",
          description: `A breathtaking destination matching your interest in adventure and scenic views near ${location || 'your area'}. Enjoy early morning sunrise sights.`
        },
        {
          name: "The local Heritage Museum",
          description: "Immerse yourself in history and rich cultural displays. Perfect for a cozy afternoon exploring exhibitions."
        },
        {
          name: "Gourmet Street Food Market",
          description: "A paradise matching your dining interest. Explore local food stalls, organic snacks, and vibrant live music."
        }
      ]
    });
  }
};

module.exports = {
  getRecommendations,
};
