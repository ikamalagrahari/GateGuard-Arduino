const express = require("express");
const router = express.Router();
const User = require("../models/User");
const AuthorizedCard = require("../models/AuthorizedCard");
const CardScan = require("../models/CardScan");

router.get("/authorized-cards", async (req, res) => {
  try {
    const authorizedCards = await AuthorizedCard.find().populate(
      "user",
      "name email role"
    );
    res.json(authorizedCards);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
});

router.get("/users", async (req, res) => {
  try {
    const users = await User.find();
    res.status(200).json(users);
  } catch (error) {
    console.error("Error fetching users:", error);
    res.status(500).json({ message: "Server error" });
  }
});

router.get("/users/:userId/cards", async (req, res) => {
  try {
    const userId = req.params.userId;

    // 🔹 Find user by ID and get the cards array
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const userCards = user.cards || []; // Array of card_uids

    // 🔹 Find authorized cards that match user’s card_uids
    const authorizedCards = await AuthorizedCard.find({
      card_uid: { $in: userCards },
    }).populate("user", "name email role"); // Populate user info

    res.json({ user: user.name, cards: authorizedCards });
  } catch (error) {
    console.error("Error fetching user cards:", error);
    res.status(500).json({ message: "Internal Server Error" });
  }
});

module.exports = router;
