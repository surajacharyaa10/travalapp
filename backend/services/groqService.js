const Groq = require('groq-sdk');
require('dotenv').config();

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

const getRecommendations = async (preferences, location, searchHistory) => {
  try {
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
    console.error('Error fetching recommendations from Groq:', error);
    throw error;
  }
};

module.exports = {
  getRecommendations,
};
