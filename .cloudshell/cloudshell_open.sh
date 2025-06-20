#!/bin/bash

echo "🚀 Welcome to K8s Monitoring Setup!"
echo "📦 Auto-running setup script..."

# Make sure we're in the right directory
cd /home/$USER/cloudshell_open/k8s-monitoring*

# Make the setup script executable (in case it wasn't already)
chmod +x setup.sh

# Run the setup script
echo "🔧 Starting setup process..."
./setup.sh

echo "✅ Setup complete! Check the output above for next steps." 