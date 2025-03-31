const mongoose = require("mongoose");

const UserSchema = new mongoose.Schema({
  name: String,
  email: { type: String, unique: true },
  password: String,
  role: String,
  cards: [String], // List of card UIDs
});

module.exports = mongoose.model("User", UserSchema);
