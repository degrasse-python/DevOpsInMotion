const app = {
  data() {
    return {
      githubRepo: '',
      buildStatus: '',
      loading: false,
      selectedNginx: '',
      installCertManager: false,
      clusterDetails: null,
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
    async submitJob() {
      try {
        this.loading = true;
        this.buildStatus = 'Submitting job...';
        
        // Send job to Buildkite with additional options
        const response = await axios.post('/api/trigger-build', {
          repo: this.githubRepo,
          nginxType: this.selectedNginx,
          certManager: this.installCertManager
        });

        this.buildStatus = `Build triggered! Build ID: ${response.data.buildId}`;
        
        // Set cluster details from response
        if (response.data.clusterDetails) {
          this.clusterDetails = response.data.clusterDetails;
        }

      } catch (error) {
        this.buildStatus = `Error: ${error.message}`;
      } finally {
        this.loading = false;
      }
    }
  },
  template: `
    <div class="container">
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
Vue.createApp(app).mount('#app');