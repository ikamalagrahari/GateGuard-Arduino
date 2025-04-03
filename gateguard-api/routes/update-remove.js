const express = require("express");
const router = express.Router();
const AuthorizedCard = require("../models/AuthorizedCard"); // Assuming this is your model
const User = require("../models/User");

// Update an existing authorized card
router.put("/authorized-card/:cardId", async (req, res) => {
  try {
    const { card_uid, user_id } = req.body;
    const { cardId } = req.params;

    // Validate request
    if (!card_uid || !user_id) {
      return res
        .status(400)
        .json({ error: "Card UID and User ID are required." });
    }

    // Find the existing card
    const existingCard = await AuthorizedCard.findById(cardId);
    if (!existingCard) {
      return res.status(404).json({ error: "Authorized Card not found." });
    }

    // Remove the old card UID from the previous user if changed
    if (existingCard.user.toString() !== user_id) {
      await User.findByIdAndUpdate(existingCard.user, {
        $pull: { cards: existingCard.card_uid },
      });
    }

    // Update the authorized card
    const updatedCard = await AuthorizedCard.findByIdAndUpdate(
      cardId,
      { card_uid, user: user_id },
      { new: true }
    ).populate("user");

    // Add the new card UID to the new user's cards array if changed
    await User.findByIdAndUpdate(user_id, { $addToSet: { cards: card_uid } });

    res.json(updatedCard);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

router.delete("/authorized-card/:cardId", async (req, res) => {
  try {
    const { cardId } = req.params;

    // Find the card before deleting to get user info
    const card = await AuthorizedCard.findById(cardId);
    if (!card) {
      return res.status(404).json({ error: "Authorized Card not found." });
    }

    // Remove the card from the user's cards array
    await User.findByIdAndUpdate(card.user, {
      $pull: { cards: card.card_uid },
    });

    // Delete the authorized card
    await AuthorizedCard.findByIdAndDelete(cardId);

    res.json({ message: "Authorized Card deleted successfully." });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

router.put("/user/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const { name, email, role, password } = req.body;

    let updateFields = { name, email, role };

    // If password is provided, hash it before updating
    if (password) {
      const salt = await bcrypt.genSalt(10);
      updateFields.password = await bcrypt.hash(password, salt);
    }

    const updatedUser = await User.findByIdAndUpdate(userId, updateFields, {
      new: true,
    });

    if (!updatedUser) {
      return res.status(404).json({ error: "User not found." });
    }

    res.json(updatedUser);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

router.delete("/user/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    // Find the user
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: "User not found." });
    }

    // Delete all authorized cards linked to this user
    await AuthorizedCard.deleteMany({ user: userId });

    // Delete the user
    await User.findByIdAndDelete(userId);

    res.json({ message: "User deleted successfully." });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

module.exports = router;
