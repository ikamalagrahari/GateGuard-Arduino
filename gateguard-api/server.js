const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(cors({ origin: "*" }));
app.use(express.json());

mongoose
  .connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log("MongoDB Connected"))
  .catch((err) => console.log(err));

app.use("/api", require("./routes/dashboard"));
app.use("/api/create", require("./routes/create"));
app.use("/api/update-remove", require("./routes/update-remove"));
app.use("/api/info", require("./routes/info"));
app.use("/api/auth", require("./routes/auth"));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () =>
  console.log(`Server running on http://localhost:${PORT}`)
);
