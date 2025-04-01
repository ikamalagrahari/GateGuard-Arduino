const express = require("express");
const router = express.Router();
const User = require("../models/User");
const AuthorizedCard = require("../models/AuthorizedCard");
const CardScan = require("../models/CardScan");

// Dashboard API
router.post("/dashboard", async (req, res) => {
  const { userId, role } = req.body;

  try {
    let authorizedCards = 0;
    let totalUsers = 0;
    let userCards = [];

    if (role === "admin") {
      authorizedCards = await AuthorizedCard.countDocuments();
      totalUsers = await User.countDocuments();
    } else {
      const user = await User.findById(userId);
      if (user) userCards = user.cards || [];
    }

    res.json({ authorizedCards, totalUsers, userCards });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server Error" });
  }
});

// Fetch Card Scans
router.post("/card-scans", async (req, res) => {
  const { userId, role } = req.body;

  try {
    let scans = [];

    if (role === "admin") {
      scans = await CardScan.find().sort({ timestamp: -1 });
    } else {
      const user = await User.findById(userId);
      if (!user || !user.cards || user.cards.length === 0) {
        return res.json([]);
      }

      scans = await CardScan.find({ card_uid: { $in: user.cards } }).sort({
        timestamp: -1,
      });
    }

    // Fetch user details for each scan
    const scansWithUserNames = await Promise.all(
      scans.map(async (scan) => {
        const authorizedCard = await AuthorizedCard.findOne({
          card_uid: scan.card_uid,
        });
        const user = authorizedCard
          ? await User.findById(authorizedCard.user)
          : null;
        return {
          ...scan._doc,
          user_name: user ? user.name : "Unknown User",
        };
      })
    );

    res.json(scansWithUserNames);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server Error" });
  }
});

module.exports = router;
