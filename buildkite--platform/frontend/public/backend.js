const express = require('express');
const dotenv = require('dotenv');
const app = express();
const port = process.env.PORT || 3030;

dotenv.config();

app.use(express.json());

app.get('/api/env', (req, res) => {
  const envVars = {
    BUILDKITE_KEY: process.env.BUILDKITE_KEY,
    BUILDKITE_API_KEY: process.env.BUILDKITE_API_KEY,
    BUILDKITE_ORG_SLUG: process.env.BUILDKITE_ORG_SLUG,
    BUILDKITE_PIPELINE_SLUG: process.env.BUILDKITE_PIPELINE_SLUG,
    PORT: process.env.PORT,
    AWS_ACCESS_KEY_ID: process.env.AWS_ACCESS_KEY_ID,
    AWS_SECRET_ACCESS_KEY: process.env.AWS_SECRET_ACCESS_KEY,
    AWS_REGION: process.env.AWS_REGION,
    EKS_NODE_GROUP_NAME: process.env.EKS_NODE_GROUP_NAME,
    EKS_NODE_INSTANCE_TYPE: process.env.EKS_NODE_INSTANCE_TYPE,
    EKS_NODE_MIN_SIZE: process.env.EKS_NODE_MIN_SIZE,
    EKS_NODE_MAX_SIZE: process.env.EKS_NODE_MAX_SIZE,
    EKS_NODE_DESIRED_SIZE: process.env.EKS_NODE_DESIRED_SIZE,
    BASIC_AUTH_USER: process.env.BASIC_AUTH_USER,
    BASIC_AUTH_PASSWORD: process.env.BASIC_AUTH_PASSWORD
  };

  res.json(envVars);
});

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});


