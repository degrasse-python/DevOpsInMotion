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
        alert('Login failed');
        console.error(err);
      }
    },

    async submitJob() {
      try {
        this.loading = true;
        this.buildStatus = 'Submitting job...';
        
        const credentials = localStorage.getItem('credentials');
        
        // Send job to Buildkite with additional options
        const response = await axios.post('/api/trigger-build', {
          repo: this.githubRepo,
          nginxType: this.selectedNginx,
          certManager: this.installCertManager
        }, {
          headers: {
            'Authorization': `Basic ${credentials}`
          }
        });

        this.buildStatus = `Build triggered! Build ID: ${response.data.buildId}`;
        
        // Set cluster details from response
        if (response.data.clusterDetails) {
          this.clusterDetails = response.data.clusterDetails;
        }

        // Poll for build status updates
        this.pollBuildStatus(response.data.buildId);

      } catch (error) {
        this.buildStatus = `Error: ${error.message}`;
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
        <input 
          v-model="username"
          type="text"
          placeholder="Username"
          class="form-input"
          style="width: 200px;"
        />
      </div>
      <div class="form-group" style="margin-bottom: 1rem;">
        <div style="position: relative; width: 200px; margin: 0 auto;">
          <input
            v-model="password" 
            :type="showPassword ? 'text' : 'password'"
            placeholder="Password"
            class="form-input"
            style="width: 100%; padding-right: 30px;"
          />
          <button 
            @click="togglePassword"
            type="button"
            style="position: absolute; right: 5px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; padding: 5px;"
          >
            👁️
          </button>
        </div>
      </div>
      <button @click="login" class="login-button" style="display: inline-block;">Login</button>
    </div>
    <div v-else class="container">
      <h1>Kubernetes Cluster Provisioner</h1>
      
      <div class="form-vertical" style="position: relative;">
        <div class="form-group">
          <label>GitHub Repository URL </label>
          <input 
            v-model="githubRepo"
            placeholder="Enter GitHub repository URL"
            :disabled="loading"
            class="form-input"
          />
        </div>

        <div class="form-group">
          <label>Nginx Version    </label>
          <select
            v-model="selectedNginx"
            :disabled="loading"
            class="form-select"
          >
            <option value="" disabled>Select Nginx Version</option>
            <option 
              v-for="option in nginxOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.name }}
            </option>
          </select>
        </div>

        <div class="form-group checkbox-container">
          <input
            type="checkbox"
            id="cert-manager"
            v-model="installCertManager"
            :disabled="loading"
          />
          <label for="cert-manager">Install cert-manager</label>
        </div>
        
        <button 
          @click="submitJob"
          :disabled="loading || !githubRepo || !selectedNginx"
          class="submit-button"
          style="position: absolute; bottom: 0; right: 0;"
        >
          {{ loading ? 'Provisioning...' : 'Provision Cluster' }}
        </button>
      </div>

      <div class="status" v-if="buildStatus">
        {{ buildStatus }}
      </div>

      <div class="cluster-details" v-if="clusterDetails">
        <h2>Cluster Details</h2>
        <div class="details-grid">
          <div class="detail-item">
            <label>Cluster Name:</label>
            <span>{{ clusterDetails.clusterName }}</span>
          </div>
          <div class="detail-item">
            <label>Region:</label>
            <span>{{ clusterDetails.region }}</span>
          </div>
          <div class="detail-item">
            <label>Console URL:</label>
            <a :href="clusterDetails.consoleUrl" target="_blank" class="console-link">
              View in AWS Console
            </a>
          </div>
          <div class="detail-item">
            <label>Access Command:</label>
            <code class="access-command">aws eks update-kubeconfig --name {{ clusterDetails.clusterName }} --region {{ clusterDetails.region }}</code>
          </div>
        </div>
      </div>
    </div>
  `
};

// Mount Vue app
const { createApp } = Vue;
createApp(app).mount('#app');