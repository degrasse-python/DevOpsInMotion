const app = {
  data() {
    return {
      isLoggedIn: false,
      githubRepo: '',
      buildStatus: '',
      loading: false,
      selectedNginx: '',
      installCertManager: false,
      clusterDetails: null,
      username: 'admin', // Set default username
      password: 'password', // Set default password
      showPassword: false,
      nginxOptions: [
        {
          name: 'Community Nginx Ingress',
          value: 'community', 
          url: 'https://github.com/kubernetes/ingress-nginx'
        },
        {
          name: 'F5 Nginx Ingress',
          value: 'f5',
          url: 'oci://ghcr.io/nginxinc/charts/nginx-ingress'
        }
      ]
    }
  },
  methods: {
    async login() {
      try {
        // Base64 encode credentials
        const credentials = btoa(`${this.username}:${this.password}`);

        // Check basic auth credentials
        const response = await fetch('/api/auth/basic', {
          headers: {
            'Authorization': `Basic ${credentials}`
          }
        });

        if (!response.ok) {
          throw new Error('Authentication failed');
        }

        // Authentication succeeded
        this.isLoggedIn = true;
        localStorage.setItem('credentials', credentials);

      } catch (err) {
        alert(`Login failed: ${err.message}`);
        console.error(err);
      }
    },

    async logout() {
      this.isLoggedIn = false;
      localStorage.removeItem('credentials');
    },

    async submitJob() {
      try {
        this.loading = true;
        this.buildStatus = 'Submitting job...';
    
        const credentials = localStorage.getItem('credentials');
    
        // Fetch environment variables from the backend
        const envResponse = await fetch('http://localhost:3030/api/env', {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
        });
        
    
        const env = await envResponse.json();
    
        // Check if all required environment variables are present
        const requiredVars = ['BUILDKITE_API_KEY', 'BUILDKITE_ORG_SLUG', 'BUILDKITE_PIPELINE_SLUG'];
        const missingVars = requiredVars.filter((varName) => !env[varName]);
        if (missingVars.length > 0) {
          throw new Error(`Missing required environment variables: ${missingVars.join(', ')}`);
        }
    
        // Send job to Buildkite with additional options
        const response = await axios.post(
          '/api/trigger-build',
          {
            repo: this.githubRepo,
            nginxType: this.selectedNginx,
            certManager: this.installCertManager,
            eksClusterName: `${this.username}-platform-${Math.random().toString(36).substr(2, 10)}`,
          },
          {
            headers: {
              Authorization: `Basic ${credentials}`,
            },
          }
        );
    
        this.buildStatus = `Build triggered! Build ID: ${response.data.buildId}`;
    
        // Set cluster details from response
        if (response.data.clusterDetails) {
          this.clusterDetails = response.data.clusterDetails;
        }
    
        // Poll for build status updates
        this.pollBuildStatus(response.data.buildId);
      } catch (error) {
        this.buildStatus = `Error: ${error.message}`;
        console.error('Error submitting job:', error);
      } finally {
        this.loading = false;
      }
    },

    async pollBuildStatus(buildId) {
      const credentials = localStorage.getItem('credentials');
      
      const pollInterval = setInterval(async () => {
        try {
          const response = await axios.get(`/api/build-status/${buildId}`, {
            headers: {
              'Authorization': `Basic ${credentials}`
            }
          });
          
          this.buildStatus = response.data.status;
          if (response.data.clusterDetails) {
            this.clusterDetails = response.data.clusterDetails;
          }
          
          // Stop polling if build is complete
          if (['passed', 'failed', 'canceled'].includes(response.data.status)) {
            clearInterval(pollInterval);
          }
        } catch (error) {
          console.error('Error polling build status:', error);
          this.buildStatus = `Error polling build status: ${error.message}`;
        }
      }, 5000); // Poll every 5 seconds
    },

    togglePassword() {
      this.showPassword = !this.showPassword;
    }
  },
  template: `
    <div v-if="!isLoggedIn" class="login-container" style="text-align: center;">
      <h1 style="margin-bottom: 2rem; color: white;">DevOps In Motion</h1>
      <div class="form-group" style="margin-bottom: 1rem;">
