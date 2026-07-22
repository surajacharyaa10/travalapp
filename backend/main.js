require("dotenv").config();

const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");

const authRoutes = require("./routes/authRoutes");
const bookmarkRoutes = require("./routes/bookmarkRoutes");
const recommendationRoutes = require("./routes/recommendationRoutes");
const placesRoutes = require("./routes/placesRoutes");
const weatherRoutes = require("./routes/weatherRoutes");
const newsRoutes = require("./routes/newsRoutes");
const mapRoutes = require("./routes/mapRoutes");

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// MongoDB Connection
async function connectDB() {
  try {
    if (!process.env.MONGODB_URI) {
      throw new Error("MONGODB_URI is missing in .env");
    }

    await mongoose.connect(process.env.MONGODB_URI);

    console.log("✅ MongoDB Connected Successfully");
  } catch (err) {
    console.error("❌ MongoDB Connection Failed");
    console.error(err.message);
    process.exit(1);
  }
}

connectDB();

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/bookmarks", bookmarkRoutes);
app.use("/api/recommendations", recommendationRoutes);
app.use("/api/places", placesRoutes);
app.use("/api/weather", weatherRoutes);
app.use("/api/news", newsRoutes);
app.use("/api/map", mapRoutes);

// Health Check
app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "Travel Guide API is running...",
  });
});

const PORT = process.env.PORT;

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});