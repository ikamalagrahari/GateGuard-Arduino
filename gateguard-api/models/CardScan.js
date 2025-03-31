const mongoose = require("mongoose");

const CardScanSchema = new mongoose.Schema({
  card_uid: String,
  timestamp: Date,
  accessgranted: Boolean,
});

module.exports = mongoose.model("CardScan", CardScanSchema);
