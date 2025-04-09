const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
require("dotenv").config();

const User = require("./models/User"); // Adjust the path as needed

// Connect to MongoDB
mongoose
  .connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(async () => {
    console.log("MongoDB Connected");

    const users = await User.find({}); // Fetch all users
    for (let user of users) {
      if (!user.password.startsWith("$2a$")) {
        // Skip if already hashed
        const hashedPassword = await bcrypt.hash(user.password, 10);
        await User.updateOne(
          { _id: user._id },
          { $set: { password: hashedPassword } }
        );
        console.log(`Updated password for user: ${user.email}`);
      }
    }

    mongoose.connection.close();
    console.log("Password hashing complete.");
  })
  .catch((err) => console.error("MongoDB error:", err));
