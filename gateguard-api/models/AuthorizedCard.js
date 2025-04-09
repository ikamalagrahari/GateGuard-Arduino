const mongoose = require("mongoose");

const AuthorizedCardSchema = new mongoose.Schema({
  card_uid: String,
  user: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
});

module.exports = mongoose.model("AuthorizedCard", AuthorizedCardSchema);
