const express = require('express');
const axios = require('axios');
const session = require('express-session');
const Keycloak = require('keycloak-connect');
const basicAuth = require('express-basic-auth');
const app = express();
const port = 3000;

// Session config
const memoryStore = new session.MemoryStore();
app.use(session({
  secret: process.env.SESSION_SECRET || 'some secret',
  resave: false,
  saveUninitialized: true,
  store: memoryStore
}));

// Authentication middleware
let authMiddleware;
try {
  // Try to initialize Keycloak
  const keycloak = new Keycloak({
    store: memoryStore
  });
  authMiddleware = keycloak.middleware();
  console.log('Using Keycloak authentication');
} catch (error) {
  // Fall back to basic auth if Keycloak isn't available
  console.log('Keycloak not available, using basic authentication');
  authMiddleware = basicAuth({
    users: { 
      [process.env.BASIC_AUTH_USER || 'admin']: process.env.BASIC_AUTH_PASSWORD || 'password' 
    }
  });
}

// Serve static files
app.use(express.static('public'));
app.use(express.json());
app.use(authMiddleware);

// Protected API endpoints
app.post('/api/trigger-build', async (req, res) => {
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

// Login endpoint (for Keycloak)
app.get('/login', (req, res) => {
  res.redirect('/');
});

// Start server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});