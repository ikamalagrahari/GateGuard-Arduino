const express = require("express");
const router = express.Router();
const User = require("../models/User");
const AuthorizedCard = require("../models/AuthorizedCard");

router.post("/authorized-card", async (req, res) => {
  try {
    const { card_uid, user_id } = req.body;

    // Validate input
    if (!card_uid || !user_id) {
      return res
        .status(400)
        .json({ error: "Card UID and User ID are required" });
    }

    // Check if user exists
    const user = await User.findById(user_id);
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Check if card is already authorized
    const existingCard = await AuthorizedCard.findOne({ card_uid });
    if (existingCard) {
      return res.status(400).json({ error: "Card is already authorized" });
    }

    // Create new authorized card entry
    const newCard = new AuthorizedCard({
      card_uid,
      user: user_id,
    });

    await newCard.save();

    // Add card UID to the user's 'cards' array
    if (!user.cards.includes(card_uid)) {
      user.cards.push(card_uid);
      await user.save();
    }

    res.status(201).json({
      message: "Authorized card created successfully",
      card: newCard,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        cards: user.cards,
      },
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
});

router.post("/user", async (req, res) => {
  const { name, email, password, role } = req.body;

  // Basic validation
  if (!name || !email || !password || !role) {
    return res.status(400).json({ message: "Please fill in all fields" });
  }

  try {
    // Check if user already exists
    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({ message: "User already exists" });
    }

    // Create new user
    const newUser = new User({
      name,
      email,
      password,
      role,
    });

    // Save user to database
    await newUser.save();

    // Send success response
    res.status(201).json({
      message: "User created successfully",
      user: {
        name: newUser.name,
        email: newUser.email,
        role: newUser.role,
      },
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;
