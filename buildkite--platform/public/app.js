const app = {
  data() {
    return {
      githubRepo: '',
      buildStatus: '',
      loading: false
    }
  },
  methods: {
    async submitJob() {
      try {
        this.loading = true;
        this.buildStatus = 'Submitting job...';
        
        // Send job to Buildkite
        const response = await axios.post('/api/trigger-build', {
          repo: this.githubRepo
        });

        this.buildStatus = `Build triggered! Build ID: ${response.data.buildId}`;
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
      
      <div class="form">
        <input 
          v-model="githubRepo"
          placeholder="Enter GitHub repository URL"
          :disabled="loading"
        />
        
        <button 
          @click="submitJob"
          :disabled="loading || !githubRepo"
        >
          Provision Cluster
        </button>
      </div>

      <div class="status" v-if="buildStatus">
        {{ buildStatus }}
      </div>
    </div>
  `
};

// Mount Vue app
Vue.createApp(app).mount('#app');