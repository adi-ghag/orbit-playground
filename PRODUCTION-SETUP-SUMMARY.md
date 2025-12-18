# Production-Ready Split Nodes Configuration - Summary

## What Changed

Your orbit-playground deployment has been configured for **production-ready split nodes architecture** with AnyTrust and DAC enabled.

---

## Configuration Changes

### 1. Environment File (`.env`)

**Added/Updated**:
```bash
# Production-ready deployment: Split nodes for better security and scalability
SPLIT_NODES=true
```

**Key Settings**:
- ✅ `USE_ANYTRUST=true` - AnyTrust mode with DAC
- ✅ `SPLIT_NODES=true` - **Split node architecture** (production-ready)
- ✅ `ARBITRUM_CHAIN_NAME=BloxbergL2`
- ✅ `PARENT_CHAIN_ID=421614` (Arbitrum Sepolia)

### 2. Documentation Updated

**New/Updated Sections in `DEPLOYMENT-GUIDE.md`**:

1. **Deployment Modes Section** (NEW)
   - Explains split nodes vs single node
   - Comparison table with pros/cons
   - Why split nodes is recommended

2. **Overview Section**
   - Now highlights split nodes architecture
   - Production-ready focus

3. **Environment Setup**
   - Updated to show `SPLIT_NODES=true`
   - Added verification for split nodes config

4. **Step 3: Start Nodes**
   - Complete rewrite for split nodes architecture
   - Shows 4 containers (batch-poster, staker, rpc, das-server)
   - Architecture diagram
   - Detailed explanation of each component
   - Updated commands for split nodes

5. **Table of Contents**
   - Added new "Deployment Modes" section

---

## Architecture Overview

### What You'll Deploy

**4 Docker Containers** (production architecture):

```
┌─────────────────────────────────┐
│  BATCH-POSTER (Sequencer)       │
│  • Port 8149 (monitor)          │
│  • Port 9642 (feed)             │
│  • Orders transactions          │
│  • Posts batches to parent      │
│  • Sends data to DAS            │
└────────┬──────────────┬──────────┘
         │              │
    ┌────┴────┐    ┌────┴────┐
    ▼         ▼    ▼         ▼
┌─────────┐ ┌──────────┐ ┌──────────────┐
│ STAKER  │ │   RPC    │ │  DAS SERVER  │
│ Port    │ │ Port 8449│ │  Ports       │
│ 8249    │ │ (PUBLIC) │ │  9876, 9877  │
└─────────┘ └──────────┘ └──────────────┘
```

### Ports

| Port | Component | Access | Purpose |
|------|-----------|--------|---------|
| **8449** | RPC | **PUBLIC** | Main endpoint for users |
| 8149 | Batch Poster | Internal | Monitoring |
| 8249 | Staker | Internal | Monitoring |
| 9642 | Batch Poster | Internal | Feed to staker/RPC |
| 9876 | DAS Server | Internal | DAS RPC |
| 9877 | DAS Server | Internal | DAS REST API |

---

## Why Split Nodes?

### Security ✅
- **Isolated Keys**: Each component uses only the keys it needs
- **Smaller Attack Surface**: Batch poster keys not exposed to public RPC
- **Better Secrets Management**: Can use different secret stores per component

### Scalability ✅
- **Horizontal RPC Scaling**: Run multiple RPC nodes behind load balancer
- **Resource Optimization**: Allocate resources based on component needs
- **Independent Scaling**: Scale what you need without over-provisioning

### Reliability ✅
- **Fault Isolation**: If RPC crashes, batch posting continues
- **Independent Restarts**: Update one component without downtime
- **Better Monitoring**: Clear separation makes debugging easier

### Production Ready ✅
- **Industry Standard**: Same architecture as Nova, Arbitrum One
- **Proven at Scale**: Battle-tested by high-traffic chains
- **Future-Proof**: Easy to add more nodes as you grow

---

## Comparison: Before vs After

### Before (Single Node)
```yaml
containers:
  - nitro-1 (all roles combined)
  - das-server-1

total: 2 containers
```

**Issues**:
- ❌ Single point of failure
- ❌ Can't scale separately
- ❌ All keys in one place
- ❌ Hard to monitor specific components

### After (Split Nodes) ✅
```yaml
containers:
  - batch-poster-1 (sequencer + batch posting)
  - staker-1 (validation)
  - rpc-1 (public API)
  - das-server-1 (data availability)

total: 4 containers
```

**Benefits**:
- ✅ Isolated components
- ✅ Horizontal scaling ready
- ✅ Keys separated by role
- ✅ Clear component monitoring
- ✅ Production-grade architecture

---

## Deployment Process (Unchanged)

The deployment commands remain the same:

```bash
# 1. Deploy contracts and generate configs
yarn deploy-chain

# 2. Fix permissions
./fix-permissions.sh

# 3. Start nodes (now starts 4 containers instead of 2)
yarn start-node

# 4. Initialize chain
yarn initialize-chain
```

**What's Different**:
- Step 1 now generates configs for 3 node types (batch-poster, staker, rpc)
- Step 3 starts 4 containers instead of 2
- All other steps are identical

---

## File Structure

### Generated Configurations

With `SPLIT_NODES=true`, the deployment creates:

```
chainConfig/
├── core-contracts.json           # Contract addresses (same)
├── batch-poster/
│   └── batch-poster-config.json  # Sequencer + batch posting config
├── staker/
│   └── staker-config.json        # Validator config
├── rpc/
│   └── rpc-config.json           # RPC server config
└── das-server/
    ├── das-config.json           # DAS server config
    └── keys/
        ├── das_bls               # BLS private key
        └── das_bls.pub           # BLS public key
```

**Note**: With `SPLIT_NODES=false`, only `chainConfig/rpc/rpc-config.json` is created (all-in-one config).

---

## Docker Container Management

### View Running Containers
```bash
docker ps

# Expected: 4 containers
# - orbit-playground-batch-poster-1
# - orbit-playground-staker-1
# - orbit-playground-rpc-1
# - orbit-playground-das-server-1
```

### View Logs
```bash
# All containers
docker compose logs -f

# Individual components
docker logs -f orbit-playground-batch-poster-1
docker logs -f orbit-playground-staker-1
docker logs -f orbit-playground-rpc-1
docker logs -f orbit-playground-das-server-1
```

### Stop/Start Components
```bash
# Stop specific component
docker compose stop rpc

# Start specific component
docker compose start rpc

# Restart specific component
docker compose restart rpc

# Stop all
docker compose stop
```

### Monitor Resources
```bash
# Real-time resource usage
docker stats

# Specific container
docker stats orbit-playground-batch-poster-1
```

---

## Testing Your Setup

### 1. Verify All Containers Running
```bash
docker ps | grep orbit-playground

# Should show 4 containers all with status "Up"
```

### 2. Test RPC Endpoint
```bash
curl -X POST http://localhost:8449 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'

# Should return your chain ID
```

### 3. Check DAS Health
```bash
curl http://localhost:9877/health

# Should return: {"status":"ok"}
```

### 4. Monitor Batch Posting
```bash
docker logs -f orbit-playground-batch-poster-1 | grep "batch posted"

# Should see batch posting activity
```

### 5. Check Component Connectivity
```bash
# Staker should connect to batch-poster feed
docker logs orbit-playground-staker-1 | grep "feed"

# RPC should connect to batch-poster feed
docker logs orbit-playground-rpc-1 | grep "feed"
```

---

## Production Deployment Checklist

When deploying to mainnet, ensure:

- [ ] **Update Environment Variables**:
  ```bash
  PARENT_CHAIN_ID=42161  # Arbitrum One (or 1 for Ethereum)
  PARENT_CHAIN_RPC_URL=https://arb1.arbitrum.io/rpc
  DISABLE_L1_FINALITY=false  # Wait for L1 finalization
  USE_FAST_L1_POSTING=false  # Post every 5 min (saves gas)
  ```

- [ ] **Secure Private Keys**:
  - Use secrets management (HashiCorp Vault, AWS Secrets Manager)
  - Don't store keys in `.env` file
  - Use environment variables from secure storage

- [ ] **Set Up Monitoring**:
  - Prometheus + Grafana for metrics
  - Alert on container restarts
  - Monitor batch posting frequency
  - Track DAS storage growth

- [ ] **Configure Firewall**:
  - Only expose port 8449 (RPC) publicly
  - Block ports 8149, 8249, 9876, 9877 from internet
  - Use VPN or private network for internal monitoring

- [ ] **Multiple DAS Servers**:
  - Run at least 3 DAS servers for redundancy
  - Distribute across different geographic regions
  - Update RPC config with all DAS endpoints

- [ ] **Load Balancer for RPC**:
  - Run multiple RPC containers (rpc-1, rpc-2, rpc-3)
  - Set up NGINX or cloud load balancer
  - Enable health checks

- [ ] **Backup Strategy**:
  - Daily backups of chainConfig/ and chainDasData/
  - Store backups in different location
  - Test restore procedure

- [ ] **Domain and SSL**:
  - Set up domain name for RPC endpoint
  - Enable HTTPS with valid SSL certificate
  - Use Cloudflare or similar for DDoS protection

---

## Switching Back to Single Node (If Needed)

If you want to test single node mode:

```bash
# 1. Stop current deployment
docker compose down

# 2. Update .env
sed -i 's/SPLIT_NODES=true/SPLIT_NODES=false/' .env

# 3. Clean and redeploy
yarn clean
yarn deploy-chain
./fix-permissions.sh
yarn start-node
yarn initialize-chain
```

**Note**: Only use single node for quick local testing. Production should always use split nodes.

---

## Next Steps

1. **Complete Deployment**:
   ```bash
   yarn deploy-chain
   ./fix-permissions.sh
   yarn start-node
   yarn initialize-chain
   ```

2. **Verify Setup**:
   - Check all 4 containers are running
   - Test RPC endpoint
   - Monitor logs for errors

3. **Deploy Your dApp**:
   - Connect MetaMask to http://localhost:8449
   - Deploy smart contracts
   - Build frontend

4. **Plan Production Migration**:
   - Set up cloud infrastructure
   - Configure monitoring
   - Implement security measures
   - Deploy to mainnet

---

## Support and Resources

- **Full Guide**: See `DEPLOYMENT-GUIDE.md` for complete step-by-step instructions
- **Troubleshooting**: Check the Troubleshooting section in the guide
- **Arbitrum Docs**: https://docs.arbitrum.io/
- **Discord**: https://discord.gg/arbitrum

---

## Summary

Your deployment is now configured for **production-ready split nodes architecture**:

✅ 4 separate containers for better isolation
✅ Keys separated by component role
✅ Horizontally scalable RPC nodes
✅ Fault-tolerant design
✅ Industry best practice
✅ Ready for production deployment

The same commands work for both split and single node modes - we've just changed the architecture to be production-ready from day one!

---

**Document Version**: 1.0
**Last Updated**: 2025-12-18
**Configuration**: Production Split Nodes + AnyTrust + DAC
