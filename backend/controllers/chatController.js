const { chatWithRAG } = require('../services/groqService');

const handleChat = async (req, res) => {
  try {
    const { message, locationContext, searchHistory = [] } = req.body;

    if (!message) {
      return res.status(400).json({ success: false, message: 'Message is required' });
    }

    const aiResponseJson = await chatWithRAG(message, locationContext || {}, searchHistory);
    
    // Parse the JSON string from the AI
    let parsedResponse;
    try {
      parsedResponse = JSON.parse(aiResponseJson);
    } catch (e) {
      // Fallback if AI fails to return valid JSON
      parsedResponse = {
        text_reply: aiResponseJson,
        places: []
      };
    }

    return res.status(200).json({
      success: true,
      data: parsedResponse
    });
  } catch (error) {
    console.error('Chat error:', error);
    return res.status(500).json({ success: false, message: 'Failed to process chat query' });
  }
};

module.exports = {
  handleChat
};
