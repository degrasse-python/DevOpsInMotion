const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');

// Load environment variables from .env
dotenv.config();

const app = express();
const port = process.env.PORT || 3030;

// Middleware
app.use(cors());
app.use(express.json());

// API Endpoint to fetch environment variables
app.get('/api/env', (req, res) => {
  const envVariables = {
    BUILDKITE_API_KEY: process.env.BUILDKITE_API_KEY,
    BUILDKITE_ORG_SLUG: process.env.BUILDKITE_ORG_SLUG,
    BUILDKITE_PIPELINE_SLUG: process.env.BUILDKITE_PIPELINE_SLUG,
  };

  res.json(envVariables);
});

// Start the server
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
