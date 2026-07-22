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

    const prompt = `You are an intelligent travel guide. Based on the user's preferences: [${preferences.join(', ')}], their current location or target location: ${location}, and their search history: [${searchHistory.join(', ')}], provide 3 personalized travel recommendations. Format the response clearly with names and brief descriptions.`;

    const chatCompletion = await groq.chat.completions.create({
      messages: [
        {
          role: 'system',
          content: 'You are a helpful travel assistant.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      model: 'llama-3.1-8b-instant',
    });

    return chatCompletion.choices[0]?.message?.content || '';
  } catch (error) {
    console.error('Error fetching recommendations from Groq, using mock fallback:', error.message);
    return `### Recommended for You in ${location || 'your area'}:

1. **Alpine Peak Viewpoint**
   *A breathtaking destination matching your interest in adventure and scenic views. Enjoy early morning sunrise sights.*

2. **The local Heritage Museum**
   *Immerse yourself in history and rich cultural displays. Perfect for a cozy afternoon exploring exhibitions.*

3. **Gourmet Street Food Market**
   *A paradise matching your dining interest. Explore local food stalls, organic snacks, and vibrant live music.*`;
  }
};

module.exports = {
  getRecommendations,
};
