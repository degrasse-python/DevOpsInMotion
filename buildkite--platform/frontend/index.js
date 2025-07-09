const express = require('express');
const axios = require('axios');
const app = express();
const port = process.env.PORT || 3000;

// Serve static files
app.use(express.static('public'));
app.use(express.json());

// Basic auth middleware
const basicAuth = require('express-basic-auth');
const authMiddleware = basicAuth({
  users: { 
    [process.env.BASIC_AUTH_USER || 'admin']: process.env.BASIC_AUTH_PASSWORD || 'password' 
  }
});

// Define /api/auth/basic endpoint
app.get('/api/auth/basic', authMiddleware, (req, res) => {
  res.status(200).json({ message: 'Authentication successful' });
});

// Protected API endpoints
app.post('/api/trigger-build', authMiddleware, async (req, res) => {
  try {
    const { repo } = req.body;
    if (!repo) {
      return res.status(400).json({ error: 'GitHub repository URL is required' });
    }

    // Get environment variables
    const apiKey = process.env.BUILDKITE_API_KEY;
    const orgSlug = process.env.BUILDKITE_ORG_SLUG;
    const pipelineSlug = process.env.BUILDKITE_PIPELINE_SLUG;

    if (!apiKey || !orgSlug || !pipelineSlug) {
      return res.status(500).json({ error: 'Missing required environment variables' });
    }

    // Trigger Buildkite build
    const response = await axios.post(
      `https://api.buildkite.com/v2/organizations/${orgSlug}/pipelines/${pipelineSlug}/builds`,
      {
        commit: 'HEAD',
        branch: 'main',
        env: {
          GITHUB_REPO: repo
        }
      },
      {
        headers: {
          'Authorization': `Bearer ${apiKey}`
        }
      }
    );

    res.json({ buildId: response.data.number });
  } catch (error) {
    console.error('Error triggering build:', error);
    res.status(500).json({ error: error.message });
  }
});

// Start server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});

