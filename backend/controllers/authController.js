const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const register = async (req, res) => {
  try {
    const { email, password, name, preferences } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const user = new User({
      email,
      password: hashedPassword,
      name,
      preferences: preferences || [],
    });

    await user.save();

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
      expiresIn: '7d',
    });

    res.status(201).json({ token, user: { id: user._id, name: user.name, email: user.email } });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
      expiresIn: '7d',
    });

    res.json({ token, user: { id: user._id, name: user.name, email: user.email } });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const getAllPreferences = async (req, res) => {
  try {
    const preferences = [
      { id: 'adventure', name: 'Adventure & Hiking', icon: '🏔️' },
      { id: 'cafes', name: 'Cafes & Coffee', icon: '☕' },
      { id: 'dining', name: 'Fine Dining', icon: '🍽️' },
      { id: 'culture', name: 'Culture & Heritage', icon: '🏛️' },
      { id: 'hotels', name: 'Luxury Hotels', icon: '🏨' },
      { id: 'nature', name: 'Nature & Wildlife', icon: '🏖️' },
      { id: 'shopping', name: 'Local Markets & Shopping', icon: '🛍️' },
      { id: 'nightlife', name: 'Nightlife & Bars', icon: '🌃' },
      { id: 'street_food', name: 'Street Food', icon: '🍜' },
      { id: 'museums', name: 'Art & Museums', icon: '🎨' },
      { id: 'wellness', name: 'Wellness & Spa', icon: '🧘' },
      { id: 'camping', name: 'Camping & Trekking', icon: '🏕️' },
    ];
    res.json(preferences);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const updateProfile = async (req, res) => {
  try {
    const { name, preferences } = req.body;
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (name) user.name = name;
    if (preferences && Array.isArray(preferences)) user.preferences = preferences;

    await user.save();
    res.json({
      id: user._id,
      name: user.name,
      email: user.email,
      preferences: user.preferences,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = {
  register,
  login,
  getProfile,
  getAllPreferences,
  updateProfile,
};
