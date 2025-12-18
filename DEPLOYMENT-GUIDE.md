# Complete Guide: Deploy AnyTrust Chain with DAC Enabled

This is a comprehensive, step-by-step guide to deploy an Arbitrum Orbit AnyTrust chain with Data Availability Committee (DAC) on Arbitrum Sepolia testnet.

---

## Table of Contents

1. [Overview](#overview)
2. [What is AnyTrust with DAC?](#what-is-anytrust-with-dac)
3. [Deployment Modes: Development vs Production](#deployment-modes-development-vs-production)
4. [Prerequisites](#prerequisites)
5. [Environment Setup](#environment-setup)
6. [Deployment Steps](#deployment-steps)
7. [Troubleshooting](#troubleshooting)
8. [Verification](#verification)
9. [Production Considerations](#production-considerations)
10. [Architecture Details](#architecture-details)
11. [FAQ](#faq)

---

## Overview

**Project**: orbit-playground
**Chain Type**: AnyTrust (L3)
**Parent Chain**: Arbitrum Sepolia (Testnet)
**Data Availability**: Data Availability Committee (DAC)
**Node Architecture**: **Split nodes (production-ready)** ✅

**Key Configuration**:
- `USE_ANYTRUST=true` - Enables AnyTrust mode with DAC
- `SPLIT_NODES=true` - **Production-ready split node architecture**
- `ARBITRUM_CHAIN_NAME=BloxbergL2` - Your chain name
- `PARENT_CHAIN_ID=421614` - Arbitrum Sepolia

**This guide uses production-ready split nodes configuration for better security, scalability, and real-world deployment practices.**

---

## What is AnyTrust with DAC?

### AnyTrust Chain
AnyTrust is an alternative to Rollup mode where:
- **Traditional Rollup**: Posts ALL transaction data to parent chain (expensive, ~$100-1000/day)
- **AnyTrust**: Posts only a data availability certificate (cheap, ~$1-10/day)
- **Trust Model**: Requires at least 1 honest DAC member
- **Use Case**: Gaming, social apps, high-throughput applications

### Data Availability Committee (DAC)
The DAC consists of:
1. **DAS (Data Availability Server)** - Stores transaction data off-chain
2. **BLS Keys** - Used for signing data availability certificates
3. **Keyset** - Stored in SequencerInbox contract for verification

**How it works**:
```
User Transaction
    ↓
Sequencer (orders txs)
    ↓
Batch Poster
    ├─→ Sends full data to DAS Server (off-chain)
    │   └─→ DAS signs with BLS key
    └─→ Posts tiny certificate to parent chain (~100 bytes vs 10KB+)
```

**Security**: As long as 1 DAC member is honest and available, users can reconstruct state.

---

## Deployment Modes: Development vs Production

This guide uses **Production-Ready Split Nodes** configuration by default. Here's why:

### Split Nodes Architecture (This Guide ✅)

**Configuration**: `SPLIT_NODES=true`

**Components**:
- Separate containers for batch-poster, staker, RPC, and DAS
- Each runs independently with isolated keys and resources
- Industry best practice for real deployments

**Advantages**:
- ✅ **Better Security**: Keys are isolated per role
- ✅ **Horizontal Scaling**: Run multiple RPC nodes for more users
- ✅ **Fault Isolation**: One component failure doesn't affect others
- ✅ **Independent Monitoring**: Clear logs and metrics per component
- ✅ **Flexible Upgrades**: Update components without full restart
- ✅ **Production-Ready**: Same architecture used by Arbitrum chains in production

**Use for**:
- Production mainnet deployments
- Public testnets
- Learning production best practices
- Any serious deployment

### Single Node Architecture (Alternative)

**Configuration**: `SPLIT_NODES=false`

**Components**:
- One container running all roles (sequencer + batch-poster + staker + RPC)

**Advantages**:
- Simpler setup
- Fewer containers to manage
- Slightly lower resource usage

**Disadvantages**:
- ❌ Single point of failure
- ❌ Can't scale components independently
- ❌ All keys in one place
- ❌ Harder to debug issues

**Use for**:
- Quick local testing only
- Learning basic concepts
- Temporary experiments

### Comparison Table

| Feature | Single Node | Split Nodes (This Guide) ✅ |
|---------|-------------|---------------------------|
| **Containers** | 2 (nitro + DAS) | 4 (batch-poster + staker + RPC + DAS) |
| **Setup Complexity** | Simple | Moderate |
| **Production Ready** | ❌ No | ✅ Yes |
| **Security** | Low (keys together) | High (keys isolated) |
| **Scalability** | None | Excellent |
| **Reliability** | Single failure point | Fault tolerant |
| **Monitoring** | Basic | Detailed per component |
| **Cost** | Lower (dev only) | Optimized (production) |
| **Best For** | Quick tests | Real deployments |

**Decision**: This guide uses split nodes because:
1. It teaches production best practices from day one
2. You learn the same architecture used by real Arbitrum chains
3. Migration from development to production is seamless
4. Better understanding of how components interact

**Note**: If you want to use single node mode for quick testing, simply change `.env`:
```bash
SPLIT_NODES=false  # Change to false
```
Then follow the same deployment steps. All commands remain the same.

---

## Prerequisites

### 1. System Requirements

**Hardware**:
- CPU: 4+ cores
- RAM: 16GB minimum (32GB recommended)
- Storage: 100GB+ SSD
- Network: Stable internet connection

**Software**:
- Ubuntu 22.04 or similar Linux distribution
- Docker v27.5+ with Compose v2
- Node.js v18+ and Yarn v1.22+
- Git

### 2. Check Your Versions

```bash
# Check Docker
docker --version
# Should show: Docker version 27.5.1 or higher

# Check Docker Compose (v2)
docker compose version
# Should show: Docker Compose version v2.x.x

# Check Node.js
node --version
# Should show: v18.x.x or higher

# Check Yarn
yarn --version
# Should show: 1.22.x
```

### 3. Upgrade Docker Compose (if needed)

If you have docker-compose v1.x, upgrade to v2:

```bash
# Remove old docker-compose
sudo apt-get remove docker-compose

# Install Docker Compose v2 plugin
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Verify
docker compose version
```

### 4. Fund Your Accounts

You need **3 accounts** funded with Arbitrum Sepolia ETH:

**From your .env file**:

```bash
# Chain Owner (deploys contracts, owns chain)
Private Key: 0x74b6260ca7d6bbbf07878ae31ef71344f9da414aec0a76eff5808b9389647f92
Address: 0x2d00E8d40BD6b44f4dFa67FE0D8D57A1BC61da56

# Batch Poster (posts batches to parent chain)
Private Key: 0xe300802b4389707e2d350b276b176c31fcc34611b122f28dab7af68967f202e4
Address: 0x3AF89E6C77a29C8E45Ab03adFBcD34B25F0e2618

# Staker (validates and makes assertions)
Private Key: 0xac01739258e63b16b29c4c6584350faa6f665ddfa1b910b3cff106ab0f5063c1
Address: 0xF96eC44c5b778E28fa5EB52F27e29fFc5b1A8F62
```

**Fund each address with 0.5 ETH on Arbitrum Sepolia**:
- Faucet: https://faucet.arbitrum.io/
- Bridge from Sepolia: https://bridge.arbitrum.io/

**Check balances**:
```bash
# Using cast (from foundry)
cast balance 0x2d00E8d40BD6b44f4dFa67FE0D8D57A1BC61da56 --rpc-url https://sepolia-rollup.arbitrum.io/rpc
cast balance 0x3AF89E6C77a29C8E45Ab03adFBcD34B25F0e2618 --rpc-url https://sepolia-rollup.arbitrum.io/rpc
cast balance 0xF96eC44c5b778E28fa5EB52F27e29fFc5b1A8F62 --rpc-url https://sepolia-rollup.arbitrum.io/rpc
```

---

## Environment Setup

### 1. Clone and Install

```bash
# Clone repository
git clone https://github.com/TucksonDev/orbit-playground.git
cd orbit-playground

# Install dependencies
yarn install

# Initialize submodules (nitro node code)
git submodule update --init --recursive --force
```

### 2. Configure Environment

Your `.env` file is already configured with:

```bash
# Key Settings for AnyTrust
USE_ANYTRUST=true                    # ✅ Enables AnyTrust mode
DAS_LOCAL_STORAGE='chainDasData'     # ✅ DAS data storage directory
ARBITRUM_CHAIN_NAME=BloxbergL2       # ✅ Your chain name

# Parent chain
PARENT_CHAIN_ID=421614               # Arbitrum Sepolia
PARENT_CHAIN_RPC_URL=https://sepolia-rollup.arbitrum.io/rpc

# Node settings
NITRO_DOCKER_IMAGE_TAG="offchainlabs/nitro-node:v3.8.0-62c0aa7"
NITRO_PORT=8449

# Production-ready: Split nodes architecture ✅
SPLIT_NODES=true                     # Separate batch-poster, staker, and rpc nodes
                                     # Better security, scalability, and isolation

# Testnet optimizations (for faster testing)
# For production mainnet, set these to false
DISABLE_L1_FINALITY=true             # Don't wait for L1 finalization (faster testing)
USE_FAST_L1_POSTING=true             # Post batches every minute (faster testing)

# Optional
ENABLE_BLOCKSCOUT=false              # Set to true for block explorer
```

**Verify configuration**:
```bash
# Check AnyTrust is enabled
cat .env | grep USE_ANYTRUST
# Should show: USE_ANYTRUST=true

# Check split nodes is enabled
cat .env | grep SPLIT_NODES
# Should show: SPLIT_NODES=true
```

**Why Split Nodes?**
- ✅ **Security**: Each component runs in isolation with separate keys
- ✅ **Scalability**: Can scale RPC nodes horizontally for more users
- ✅ **Reliability**: If one component fails, others keep running
- ✅ **Production-ready**: Industry best practice for real deployments

---

## Deployment Steps

### Overview

```
Step 1: Deploy Contracts    → Creates contracts on Arbitrum Sepolia
Step 2: Fix Permissions     → Ensures Docker can write to volumes
Step 3: Start Nodes         → Launches Nitro + DAS containers
Step 4: Initialize Chain    → Funds accounts and starts operation
```

---

### Step 1: Deploy Chain Contracts

This deploys the core rollup contracts to Arbitrum Sepolia and configures the DAC.

```bash
yarn deploy-chain
```

**What happens**:
1. ✅ Generates a random chain ID (e.g., 34409397898)
2. ✅ Deploys core contracts:
   - RollupCore
   - SequencerInbox
   - Bridge
   - Inbox/Outbox
   - UpgradeExecutor
3. ✅ Sets the DAC keyset in SequencerInbox (AnyTrust specific)
4. ✅ Generates BLS keys for DAS server
5. ✅ Creates configuration files

**Expected output**:
```
Chain ID: 34409397898
Deploying core contracts...
✓ RollupCore deployed at: 0xD19aA130a979FABd950C075968811C722C3b5913
✓ SequencerInbox deployed at: 0x437fD9199152A24473E558AF1918ad4fa873745B
✓ Bridge deployed at: 0x7b82BADe8D82DC5f5219841959280657B1f6574e
...
Setting keyset for AnyTrust chain...
✓ Keyset transaction: 0x...
✓ Node config written to chainConfig/rpc/rpc-config.json
✓ Core contracts written to chainConfig/core-contracts.json
```

**Generated files**:
```
chainConfig/
├── core-contracts.json           # Contract addresses on parent chain
├── rpc/
│   └── rpc-config.json          # Nitro node configuration
└── das-server/
    ├── das-config.json          # DAS server configuration (created in Step 2)
    └── keys/
        ├── das_bls              # BLS private key
        └── das_bls.pub          # BLS public key
```

**Verification**:
```bash
# Check contract addresses
cat chainConfig/core-contracts.json

# Check chain ID and AnyTrust flag
cat chainConfig/rpc/rpc-config.json | grep -A2 "DataAvailabilityCommittee"
# Should show: "DataAvailabilityCommittee": true
```

**If deployment fails**:
- Ensure accounts have sufficient Arbitrum Sepolia ETH
- Check parent chain RPC is accessible
- Review error messages for specific issues

---

### Step 2: Fix Permissions and Create DAS Config

Due to Docker container user permissions, you need to fix file permissions and ensure the DAS config exists.

```bash
# Run the permission fix script
./fix-permissions.sh
```

**What the script does**:
```bash
# 1. Fix ownership
sudo chown -R $USER:$USER chainConfig/

# 2. Make writable for Docker (777 for local dev)
sudo chmod -R 777 chainConfig/

# 3. Create and fix DAS data directory
mkdir -p chainDasData
sudo chmod -R 777 chainDasData/
sudo chown -R $USER:$USER chainDasData/
```

**Why this is needed**:
- Docker containers run as a specific user inside the container
- Mounted volumes need write permissions for the container user
- The nitro container needs to create subdirectories in `.arbitrum/`
- The das-server needs to write data to `das-data/`

**Verify DAS config exists**:
```bash
ls -la chainConfig/das-server/das-config.json
cat chainConfig/das-server/das-config.json
```

**Expected output**:
```json
{
  "data-availability": {
    "parent-chain-node-url": "https://sepolia-rollup.arbitrum.io/rpc",
    "sequencer-inbox-address": "0x437fD9199152A24473E558AF1918ad4fa873745B",
    "key": {
      "key-dir": "/home/user/.arbitrum/keys"
    },
    "local-cache": {
      "enable": true
    },
    "local-file-storage": {
      "enable": true,
      "data-dir": "/home/user/das-data"
    }
  },
  "enable-rpc": true,
  "rpc-addr": "0.0.0.0",
  "enable-rest": true,
  "rest-addr": "0.0.0.0",
  "log-level": "INFO"
}
```

**Check permissions**:
```bash
ls -la chainConfig/
ls -la chainConfig/rpc/
ls -la chainConfig/das-server/
ls -la chainDasData/
```

All directories should be writable (rwx permissions).

---

### Step 3: Start Nodes (Production Split Node Architecture)

Launch the Docker containers for your Arbitrum chain with split nodes architecture.

```bash
yarn start-node
```

**What starts** (with `SPLIT_NODES=true` - Production configuration ✅):

1. **batch-poster container** - Sequencer and Batch Posting:
   - Sequences transactions (orders them)
   - Creates batches of transactions
   - Posts batches to parent chain
   - Sends data to DAS server
   - **Port 8149**: Internal monitoring
   - **Port 9642**: Feed output (for staker and RPC)

2. **staker container** - Validator:
   - Validates state transitions
   - Makes assertions on parent chain
   - Requests data from DAS if needed
   - **Port 8249**: Internal monitoring
   - **Connected to**: batch-poster (via feed)

3. **rpc container** - Public RPC Server:
   - Serves user JSON-RPC requests
   - Handles eth_* and web3_* calls
   - Public-facing endpoint
   - **Port 8449**: Main RPC endpoint (public)
   - **Connected to**: batch-poster (via feed)

4. **das-server container** - Data Availability Server:
   - Stores transaction batch data
   - Signs data with BLS keys
   - Provides REST + RPC APIs for data retrieval
   - **Port 9876**: DAS RPC
   - **Port 9877**: DAS REST API

**Expected output**:
```
WARN[0000] docker-compose.yaml: the attribute `version` is obsolete
[+] Running 4/4
 ✓ Container orbit-playground-batch-poster-1 Created
 ✓ Container orbit-playground-staker-1       Created
 ✓ Container orbit-playground-rpc-1          Created
 ✓ Container orbit-playground-das-server-1   Created
Attaching to batch-poster-1, das-server-1, rpc-1, staker-1

das-server-1     | INFO[12-18|11:30:00.123] Starting DAS server
das-server-1     | INFO[12-18|11:30:00.234] REST API listening on port 9877
das-server-1     | INFO[12-18|11:30:00.345] RPC API listening on port 9876

batch-poster-1   | INFO[12-18|11:30:01.123] Starting Arbitrum Nitro node (Batch Poster)
batch-poster-1   | INFO[12-18|11:30:02.234] Chain ID: 34409397898
batch-poster-1   | INFO[12-18|11:30:03.345] Sequencer started
batch-poster-1   | INFO[12-18|11:30:04.456] Batch poster enabled
batch-poster-1   | INFO[12-18|11:30:05.567] Feed output enabled on port 9642

staker-1         | INFO[12-18|11:30:06.123] Starting Arbitrum Nitro node (Staker)
staker-1         | INFO[12-18|11:30:07.234] Staker enabled
staker-1         | INFO[12-18|11:30:08.345] Connected to batch-poster feed

rpc-1            | INFO[12-18|11:30:09.123] Starting Arbitrum Nitro node (RPC)
rpc-1            | INFO[12-18|11:30:10.234] HTTP server listening on port 8449
rpc-1            | INFO[12-18|11:30:11.345] Connected to batch-poster feed
```

**Architecture Diagram**:
```
┌─────────────────────────────────┐
│     BATCH-POSTER (Sequencer)    │
│  Port 8149 (internal monitor)   │
│  Port 9642 (feed output)         │
│  ┌───────────────────────────┐  │
│  │ • Orders transactions     │  │
│  │ • Creates batches         │  │
│  │ • Posts to parent chain   │  │
│  │ • Sends data to DAS       │  │
│  └───────────────────────────┘  │
└────────┬──────────────┬──────────┘
         │ feed         │
    ┌────┴────┐    ┌────┴────┐
    ▼         ▼    ▼         ▼
┌─────────┐  ┌──────────┐  ┌──────────────┐
│ STAKER  │  │   RPC    │  │  DAS SERVER  │
│ Port    │  │ Port 8449│  │  Ports       │
│ 8249    │  │ (PUBLIC) │  │  9876, 9877  │
└─────────┘  └──────────┘  └──────────────┘
   Validates   Serves       Stores data
   state       users        & signs
```

**Ports exposed**:
```
8449  → RPC endpoint (main public access) ✅
8149  → Batch poster monitoring (internal)
8249  → Staker monitoring (internal)
9642  → Feed output (internal communication)
9876  → DAS RPC (internal)
9877  → DAS REST API (internal)
```

**Verify containers are running**:
```bash
docker ps
```

**Expected output (4 containers)**:
```
CONTAINER ID   IMAGE                                   NAMES                              STATUS
abc123def456   offchainlabs/nitro-node:v3.8.0-62c0aa7  orbit-playground-batch-poster-1    Up 30 seconds
def456abc789   offchainlabs/nitro-node:v3.8.0-62c0aa7  orbit-playground-staker-1          Up 30 seconds
ghi789jkl012   offchainlabs/nitro-node:v3.8.0-62c0aa7  orbit-playground-rpc-1             Up 30 seconds
mno345pqr678   offchainlabs/nitro-node:v3.8.0-62c0aa7  orbit-playground-das-server-1      Up 30 seconds
```

**View logs**:
```bash
# Follow all logs
docker compose logs -f

# Individual containers
docker logs -f orbit-playground-batch-poster-1
docker logs -f orbit-playground-staker-1
docker logs -f orbit-playground-rpc-1
docker logs -f orbit-playground-das-server-1

# Last 100 lines for batch-poster
docker logs --tail 100 orbit-playground-batch-poster-1
```

**Stop containers** (if needed):
```bash
# Stop all
docker compose stop

# Stop specific containers
docker compose stop batch-poster
docker compose stop staker
docker compose stop rpc
docker compose stop das-server

# Restart specific container
docker compose restart rpc
```

**Monitor resource usage**:
```bash
# Real-time stats for all containers
docker stats

# Stats for specific container
docker stats orbit-playground-batch-poster-1
```

**Benefits of Split Nodes in Production**:

| Aspect | Single Node | Split Nodes (This Setup) ✅ |
|--------|-------------|---------------------------|
| **Security** | All keys in one container | Keys isolated per role |
| **Scalability** | Can't scale separately | Scale RPC independently |
| **Reliability** | Single point of failure | One component can fail |
| **Monitoring** | Harder to debug | Clear separation of concerns |
| **Upgrades** | Restart everything | Update components independently |
| **Cost** | Fixed resources | Optimize per component |

---

### Step 4: Initialize Chain

Fund the necessary accounts on both parent chain and your L3.

**Open a new terminal** (keep the first terminal with logs running):

```bash
yarn initialize-chain
```

**What happens**:
1. ✅ Funds batch poster on Arbitrum Sepolia (0.1 ETH)
   - Needs funds to post batches to parent chain
2. ✅ Funds staker on Arbitrum Sepolia (0.1 ETH + stake tokens)
   - Needs funds to make assertions
3. ✅ Deposits ETH to your L3 for chain owner
   - Initial funds on your new chain

**Expected output**:
```
Funding batch poster on parent chain...
✓ Transaction sent: 0x...
Waiting for confirmation...
✓ Batch poster funded: 0.1 ETH

Funding staker on parent chain...
✓ Transaction sent: 0x...
✓ Staker funded with ETH and stake tokens

Depositing to L3 for chain owner...
✓ Deposit transaction: 0x...
Waiting for L3 balance...
✓ Chain owner funded on L3

Initialization complete! 🎉
```

**Wait for synchronization** (check logs in first terminal):
```
nitro-1       | INFO[...] Synced to block 1
nitro-1       | INFO[...] Synced to block 10
nitro-1       | INFO[...] Batch posted to parent chain
das-server-1  | INFO[...] Stored batch data, size: 1234 bytes
```

---

## Verification

### 1. Test RPC Connection

```bash
# Check chain ID
curl -X POST http://localhost:8449 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'

# Expected: {"jsonrpc":"2.0","id":1,"result":"0x800e0cdaa"}
# This is 34409397898 in hex
```

### 2. Check DAS Server

```bash
# Health check
curl http://localhost:9877/health

# Expected: {"status":"ok"}

# Check DAS info
curl http://localhost:9877/info
```

### 3. Get Block Number

```bash
curl -X POST http://localhost:8449 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# Expected: {"jsonrpc":"2.0","id":1,"result":"0x..."}
```

### 4. Connect MetaMask

1. Open MetaMask
2. Click Network dropdown → "Add Network"
3. Enter:
   - **Network Name**: BloxbergL2 (Local)
   - **RPC URL**: http://localhost:8449
   - **Chain ID**: 34409397898 (from your deployment)
   - **Currency Symbol**: ETH
4. Click "Save"
5. Import your chain owner private key to see funds

### 5. Deploy Test Contract

```bash
# Using cast from Foundry
cast send --rpc-url http://localhost:8449 \
  --private-key 0x74b6260ca7d6bbbf07878ae31ef71344f9da414aec0a76eff5808b9389647f92 \
  --create $(cat <<EOF
608060405234801561001057600080fd5b5060405161012a38038061012a833981016040819052610...
EOF
)
```

### 6. Verify AnyTrust is Working

Check the logs for DAS activity:

```bash
docker logs orbit-playground-das-server-1 | grep "Stored batch"
```

You should see messages like:
```
INFO[...] Stored batch data, size: 1234 bytes, hash: 0x...
```

Check parent chain for certificate posting (not full data):

```bash
# Get sequencer inbox contract
SEQUENCER_INBOX=$(cat chainConfig/core-contracts.json | jq -r '.sequencerInbox')

# Check recent transactions
cast logs --rpc-url https://sepolia-rollup.arbitrum.io/rpc \
  --address $SEQUENCER_INBOX \
  --from-block latest
```

AnyTrust transactions will have small calldata (~100 bytes certificate) vs Rollup (~10KB+ data).

---

## Troubleshooting

### Issue 1: Permission Denied Errors

**Symptoms**:
```
Fatal configuration error: unable to create chain directory: mkdir /home/user/.arbitrum/BloxbergL2: permission denied
ERROR couldn't start LocalFileStorageService, directory '/home/user/das-data' must be readable and writeable
```

**Solution**:
```bash
# Run the fix script
./fix-permissions.sh

# Or manually
sudo chown -R $USER:$USER chainConfig/
sudo chmod -R 777 chainConfig/
mkdir -p chainDasData
sudo chmod -R 777 chainDasData/

# Restart
docker compose down
yarn start-node
```

**Root cause**: Docker containers need write access to mounted volumes.

---

### Issue 2: DAS Config Missing

**Symptoms**:
```
Fatal configuration error: error loading local config file: open /home/user/.arbitrum/das-config.json: no such file or directory
```

**Solution**:
The `das-config.json` file should be created automatically, but if missing:

```bash
# Check if it exists
ls chainConfig/das-server/das-config.json

# If missing, create it manually
cat > chainConfig/das-server/das-config.json << 'EOF'
{
  "data-availability": {
    "parent-chain-node-url": "https://sepolia-rollup.arbitrum.io/rpc",
    "sequencer-inbox-address": "REPLACE_WITH_YOUR_SEQUENCER_INBOX",
    "key": {
      "key-dir": "/home/user/.arbitrum/keys"
    },
    "local-cache": {
      "enable": true
    },
    "local-file-storage": {
      "enable": true,
      "data-dir": "/home/user/das-data"
    }
  },
  "enable-rpc": true,
  "rpc-addr": "0.0.0.0",
  "enable-rest": true,
  "rest-addr": "0.0.0.0",
  "log-level": "INFO"
}
EOF

# Get sequencer inbox address and update
SEQUENCER_INBOX=$(cat chainConfig/core-contracts.json | jq -r '.sequencerInbox')
sed -i "s/REPLACE_WITH_YOUR_SEQUENCER_INBOX/$SEQUENCER_INBOX/g" chainConfig/das-server/das-config.json

# Fix permissions
chmod 777 chainConfig/das-server/das-config.json
```

---

### Issue 3: Docker Compose v1 vs v2

**Symptoms**:
```
ERROR: The Compose file './docker-compose.yaml' is invalid because:
'include' does not match any of the regexes: '^x-'
```

**Solution**:
Upgrade to Docker Compose v2:

```bash
# Remove old version
sudo apt-get remove docker-compose

# Install v2 plugin
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Verify
docker compose version
# Should show v2.x.x
```

The repository has been updated to merge all compose files for compatibility.

---

### Issue 4: Port Already in Use

**Symptoms**:
```
Error starting userland proxy: listen tcp4 0.0.0.0:8449: bind: address already in use
```

**Solution**:
```bash
# Find process using port 8449
sudo lsof -i :8449

# Kill the process
sudo kill -9 <PID>

# Or use a different port in .env
echo "NITRO_PORT=8450" >> .env
```

---

### Issue 5: Insufficient Funds

**Symptoms**:
```
Error: insufficient funds for gas * price + value
Transaction failed: insufficient funds
```

**Solution**:
Fund your accounts on Arbitrum Sepolia:
```bash
# Check balances
cast balance 0x2d00E8d40BD6b44f4dFa67FE0D8D57A1BC61da56 --rpc-url https://sepolia-rollup.arbitrum.io/rpc

# Get testnet ETH
# Visit: https://faucet.arbitrum.io/
```

Each account needs at least 0.5 ETH.

---

### Issue 6: Parent Chain Connection Failed

**Symptoms**:
```
Error connecting to parent chain: dial tcp: lookup sepolia-rollup.arbitrum.io: no such host
```

**Solution**:
```bash
# Test connectivity
curl -X POST https://sepolia-rollup.arbitrum.io/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'

# If fails, check DNS or use alternative RPC
# Update .env:
PARENT_CHAIN_RPC_URL=https://arb-sepolia.g.alchemy.com/v2/YOUR_KEY
```

---

### Issue 7: Containers Keep Restarting

**Symptoms**:
```bash
docker ps -a
# Shows containers with "Restarting" status
```

**Solution**:
```bash
# Check logs for errors
docker logs orbit-playground-nitro-1
docker logs orbit-playground-das-server-1

# Common causes:
# 1. Config file errors → Fix config and restart
# 2. Permission issues → Run ./fix-permissions.sh
# 3. Port conflicts → Change ports in .env
# 4. Out of memory → Check docker stats

# Clean restart
docker compose down
docker compose rm -f
yarn start-node
```

---

## Production Considerations

### 1. Switch to Split Nodes

For production, use separate containers for each role:

```bash
# Update .env
SPLIT_NODES=true

# Redeploy
yarn clean
yarn deploy-chain
./fix-permissions.sh
yarn start-node
```

**Architecture with split nodes**:
```
┌─────────────────┐
│  Batch Poster   │  Port 8149 (internal)
│  (Sequencer)    │  Posts batches + data to DAS
└────────┬────────┘
         │ feed (9642)
         ├────────────┐
         ▼            ▼
┌─────────────┐  ┌────────────┐
│   Staker    │  │    RPC     │
│ (Validator) │  │  (Public)  │
│ Port 8249   │  │ Port 8449  │
└─────────────┘  └────────────┘
         │
         ▼
┌─────────────────┐
│   DAS Server    │
│  Ports 9876-77  │
└─────────────────┘
```

Benefits:
- ✅ Better security (separate keys)
- ✅ Horizontal scaling (multiple RPC nodes)
- ✅ Independent upgrades
- ✅ Resource optimization

### 2. Production Environment Variables

```bash
# Security
DISABLE_L1_FINALITY=false        # Wait for finalized L1 blocks
USE_FAST_L1_POSTING=false        # Post every 5 minutes (not 1 min)

# Monitoring
ENABLE_BLOCKSCOUT=true           # Block explorer

# Resources
# Increase Docker container limits in docker-compose.yaml
```

### 3. Multiple DAS Servers

For redundancy, run multiple DAS servers:

```bash
# Start 3 DAS servers on different machines
# Update RPC config to include all DAS endpoints

"rest-aggregator": {
  "enable": true,
  "urls": [
    "http://das-1.example.com:9877",
    "http://das-2.example.com:9877",
    "http://das-3.example.com:9877"
  ]
}
```

### 4. Monitoring Setup

**Prometheus + Grafana**:
```bash
# Add to docker-compose.yaml
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
```

**Key metrics to monitor**:
- Batch posting frequency
- DAS storage size
- RPC request rate
- Block production rate
- Gas usage on parent chain

### 5. Backup Strategy

```bash
# Backup chain data
docker compose stop
tar -czf backup-$(date +%Y%m%d).tar.gz chainConfig/ chainDasData/
docker compose start

# Automated backup script
cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d-%H%M%S)
tar -czf $BACKUP_DIR/orbit-backup-$DATE.tar.gz chainConfig/ chainDasData/
find $BACKUP_DIR -name "orbit-backup-*.tar.gz" -mtime +7 -delete
EOF
chmod +x backup.sh

# Add to crontab for daily backups
crontab -e
# Add: 0 2 * * * /home/ghag/orbit-playground/backup.sh
```

### 6. Security Hardening

**For production**:

1. **Use secrets management**:
   ```bash
   # Don't store private keys in .env
   # Use HashiCorp Vault, AWS Secrets Manager, etc.
   ```

2. **Firewall rules**:
   ```bash
   # Only expose RPC port publicly
   # Keep internal ports (8149, 8249, 9876) private

   sudo ufw allow 8449/tcp   # RPC (public)
   sudo ufw deny 9876/tcp    # DAS RPC (internal only)
   sudo ufw deny 9877/tcp    # DAS REST (internal only)
   ```

3. **Use reverse proxy**:
   ```nginx
   # nginx config for RPC
   server {
       listen 80;
       server_name your-chain.example.com;

       location / {
           proxy_pass http://localhost:8449;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

4. **Regular updates**:
   ```bash
   # Update Nitro version in .env
   NITRO_DOCKER_IMAGE_TAG="offchainlabs/nitro-node:v3.9.0-latest"

   # Pull new image and restart
   docker compose pull
   docker compose up -d
   ```

### 7. Load Balancing RPC Nodes

**For high traffic**:

```bash
# Run multiple RPC nodes (split mode)
# docker-compose-prod.yaml

services:
  rpc-1:
    image: "${NITRO_DOCKER_IMAGE_TAG}"
    # ... rpc config ...
    ports:
      - "8449:8449"

  rpc-2:
    image: "${NITRO_DOCKER_IMAGE_TAG}"
    # ... rpc config ...
    ports:
      - "8450:8449"

  rpc-3:
    image: "${NITRO_DOCKER_IMAGE_TAG}"
    # ... rpc config ...
    ports:
      - "8451:8449"
```

**NGINX load balancer**:
```nginx
upstream rpc_backend {
    least_conn;
    server localhost:8449;
    server localhost:8450;
    server localhost:8451;
}

server {
    listen 80;
    location / {
        proxy_pass http://rpc_backend;
    }
}
```

---

## Architecture Details

### File Structure

```
orbit-playground/
├── .env                              # Environment configuration
├── docker-compose.yaml               # Container definitions
├── package.json                      # NPM scripts
├── fix-permissions.sh                # Permission fix script
│
├── scripts/
│   └── chain-deployer/
│       ├── deployNewChain.ts         # Main deployment script
│       ├── initializeChain.ts        # Chain initialization
│       ├── deployTokenBridge.ts      # Token bridge deployment
│       └── transferOwnership.ts      # Ownership transfer
│
├── src/
│   └── utils/
│       ├── node-configuration.ts     # Node config generation (includes DAS)
│       ├── chain-info-helpers.ts     # Chain utilities
│       └── helpers.ts                # General helpers
│
├── chainConfig/                      # Generated configurations
│   ├── core-contracts.json           # Contract addresses
│   ├── rpc/
│   │   └── rpc-config.json          # Nitro node config
│   ├── das-server/
│   │   ├── das-config.json          # DAS config
│   │   └── keys/
│   │       ├── das_bls              # BLS private key
│   │       └── das_bls.pub          # BLS public key
│   ├── batch-poster/                 # (if SPLIT_NODES=true)
│   └── staker/                       # (if SPLIT_NODES=true)
│
├── chainDasData/                     # DAS data storage
│   └── ... (batch data)
│
├── shell-scripts/
│   ├── start-nitro.sh               # Node startup
│   ├── das-server.sh                # DAS startup
│   ├── build-nitro.sh               # Build custom Nitro
│   └── clean.sh                     # Cleanup script
│
└── nitro/                           # Nitro node submodule
```

### Key Configuration Files

#### 1. core-contracts.json
```json
{
  "rollup": "0x...",              // Main rollup contract
  "inbox": "0x...",               // Message inbox
  "sequencerInbox": "0x...",      // Batch posting (contains DAC keyset)
  "bridge": "0x...",              // Token bridge
  "upgradeExecutor": "0x..."      // Upgrades
}
```

#### 2. rpc-config.json (Nitro Node)
```json
{
  "chain": {
    "info-json": "[{\"arbitrum\":{\"DataAvailabilityCommittee\":true}}]"
  },
  "node": {
    "sequencer": true,
    "batch-poster": { "enable": true },
    "staker": { "enable": true },
    "data-availability": {
      "enable": true,
      "sequencer-inbox-address": "0x...",
      "rest-aggregator": {
        "urls": ["http://localhost:9877"]
      }
    }
  }
}
```

#### 3. das-config.json (DAS Server)
```json
{
  "data-availability": {
    "parent-chain-node-url": "https://sepolia-rollup.arbitrum.io/rpc",
    "sequencer-inbox-address": "0x...",
    "key": {
      "key-dir": "/home/user/.arbitrum/keys"
    },
    "local-file-storage": {
      "enable": true,
      "data-dir": "/home/user/das-data"
    }
  },
  "enable-rpc": true,
  "enable-rest": true
}
```

### Transaction Flow

**Complete AnyTrust transaction lifecycle**:

```
1. USER submits transaction
   ↓ (JSON-RPC to port 8449)

2. SEQUENCER receives and orders transaction
   ↓ (in nitro container)

3. SEQUENCER creates batch of transactions
   ↓

4. BATCH POSTER processes batch:
   ├─→ (A) Sends full batch data to DAS Server
   │        ↓ (POST to http://localhost:9877)
   │   DAS Server stores data and signs with BLS key
   │        ↓
   │   Returns signature + hash (certificate)
   │
   └─→ (B) Posts certificate to parent chain
            ↓ (transaction to SequencerInbox contract)
       Parent chain stores ~100 byte certificate
       (instead of full 10KB+ batch data)

5. STAKER reads certificate from parent chain
   ↓
   Requests full data from DAS if needed
   ↓
   Validates state transition
   ↓
   Posts assertion to parent chain

6. Challenge period elapses (7 days mainnet, faster testnet)
   ↓
   State finalized on parent chain
```

**Cost comparison**:
- Rollup: ~$100-1000/day (posts all data on-chain)
- AnyTrust: ~$1-10/day (posts tiny certificates)

### Network Communication

```
External Users
    ↓ (RPC requests)
[localhost:8449] ← Nitro RPC
    ↓
[Internal] → Sequencer
    ↓
[Internal] → Batch Poster
    ├─→ [localhost:9877] → DAS REST API
    │   [localhost:9876] → DAS RPC
    │
    └─→ [https://sepolia-rollup.arbitrum.io/rpc] → Parent Chain

[Internal] → Staker
    ├─→ [localhost:9876] → DAS (if needed for validation)
    └─→ [https://sepolia-rollup.arbitrum.io/rpc] → Parent Chain
```

---

## FAQ

### Q1: What's the difference between Rollup and AnyTrust?

**Rollup**:
- Posts all transaction data to parent chain
- Fully trustless (anyone can reconstruct state)
- Expensive (~$100-1000/day on mainnet)
- Use for: DeFi, high-value applications

**AnyTrust**:
- Posts only data availability certificate
- Trusts at least 1 DAC member is honest
- Cheap (~$1-10/day on mainnet)
- Use for: Gaming, social apps, high-throughput

### Q2: How many DAS servers do I need?

**Development**: 1 is fine
**Production**: Minimum 3, recommended 5+

The DAC only needs 1 honest member, but more servers provide:
- Redundancy if servers go down
- Better availability for data requests
- Geographic distribution

### Q3: Can I switch from AnyTrust to Rollup later?

No, this is a permanent decision made at deployment. To switch, you'd need to:
1. Deploy a new chain in Rollup mode
2. Migrate state from old chain
3. Update all applications

Choose carefully!

### Q4: What happens if all DAS servers go offline?

- Sequencer can't post new batches (no certificates)
- Chain halts until DAS comes back online
- Users can't withdraw (need data for exit proofs)

This is why you need multiple redundant DAS servers in production.

### Q5: How much does it cost to run?

**Testnet** (Arbitrum Sepolia):
- Parent chain transactions: Free (testnet ETH)
- Infrastructure: ~$50-200/month (VPS)

**Mainnet** (Arbitrum One):
- Parent chain transactions: ~$1-10/day (AnyTrust)
- Infrastructure: ~$200-500/month (production-grade)

### Q6: Can I use a custom token as gas?

Yes! Set `NATIVE_TOKEN_ADDRESS` in `.env` to your token address on the parent chain.

```bash
NATIVE_TOKEN_ADDRESS=0x... # Your ERC-20 token
```

Deploy with this setting, and your chain will use that token for gas instead of ETH.

### Q7: How do I upgrade my chain?

**For non-STF changes** (doesn't affect state transition):
```bash
# Update Nitro version
NITRO_DOCKER_IMAGE_TAG="offchainlabs/nitro-node:v3.9.0"

# Rebuild and restart
yarn build-nitro
docker compose down
yarn start-node
```

**For STF changes** (affects state transition):
1. Build new WASM module root
2. Submit upgrade proposal via UpgradeExecutor
3. Execute upgrade after delay
4. Update all nodes

See: https://docs.arbitrum.io/launch-arbitrum-chain/customize-your-chain/customize-stf

### Q8: Can I run this on mainnet?

Yes! Update `.env`:

```bash
# For L3 on Arbitrum One
PARENT_CHAIN_ID=42161
PARENT_CHAIN_RPC_URL=https://arb1.arbitrum.io/rpc

# For L2 on Ethereum mainnet
PARENT_CHAIN_ID=1
PARENT_CHAIN_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
```

**Important**:
- Fund accounts with real ETH
- Use production settings (DISABLE_L1_FINALITY=false)
- Run split nodes for security
- Set up monitoring and backups

### Q9: How do I add more validators?

Validators (stakers) are permissionless. Anyone can:

1. Run a node in staker mode
2. Stake tokens (specified in core-contracts.json)
3. Make assertions

To add a staker:
```bash
# On a new machine
git clone ...
# Copy chainConfig/ from original deployment
# Update .env with new staker private key
# Set SPLIT_NODES=true and only run staker container
```

### Q10: What's the challenge period?

The challenge period is how long validators have to dispute invalid assertions:

- **Testnet**: ~10 minutes (for fast iteration)
- **Mainnet**: 7 days (for security)

After the challenge period, state is finalized on the parent chain.

### Q11: Can I pause my chain?

Yes, the chain owner can:

```bash
# Via UpgradeExecutor, call:
# rollup.pause()

# Resume with:
# rollup.unpause()
```

This stops the sequencer from accepting new transactions.

### Q12: What ports need to be open?

**Public** (open to internet):
- `8449` - RPC endpoint for users

**Internal** (firewall protected):
- `8149` - Batch poster monitoring
- `8249` - Staker monitoring
- `9876` - DAS RPC (between nodes only)
- `9877` - DAS REST (between nodes only)
- `9642` - Feed (between nodes only)

### Q13: How do I monitor my chain?

**Basic monitoring**:
```bash
# Check block production
watch -n 5 'curl -s -X POST http://localhost:8449 \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}" \
  | jq -r ".result" | xargs printf "%d\n"'

# Check DAS health
watch -n 5 'curl -s http://localhost:9877/health'

# Check container health
watch -n 5 'docker ps'
```

**Advanced monitoring**:
- Set up Prometheus + Grafana
- Monitor gas usage on parent chain
- Track batch posting frequency
- Alert on container restarts

### Q14: How do I clean up and start fresh?

```bash
# Stop containers
docker compose down

# Clean all data
yarn clean

# This removes:
# - chainConfig/ (all configs and keys)
# - chainDasData/ (DAS stored data)
# - Docker volumes

# Start fresh deployment
yarn deploy-chain
./fix-permissions.sh
yarn start-node
yarn initialize-chain
```

**Warning**: This deletes all chain data. Back up if needed!

---

## Additional Resources

### Documentation
- **Arbitrum Docs**: https://docs.arbitrum.io/
- **Orbit Docs**: https://docs.arbitrum.io/launch-arbitrum-chain/orbit-gentle-introduction
- **AnyTrust**: https://docs.arbitrum.io/how-arbitrum-works/inside-arbitrum-nitro#anytrust
- **Nitro GitHub**: https://github.com/OffchainLabs/nitro

### Tools
- **Arbitrum SDK**: https://github.com/OffchainLabs/arbitrum-sdk
- **Block Explorer**: Set `ENABLE_BLOCKSCOUT=true` in `.env`
- **Foundry** (for testing): https://book.getfoundry.sh/

### Community
- **Discord**: https://discord.gg/arbitrum
- **Forum**: https://forum.arbitrum.foundation/
- **Telegram**: https://t.me/arbitrum

### Support
- GitHub Issues: https://github.com/TucksonDev/orbit-playground/issues
- Arbitrum Support: https://docs.arbitrum.io/support

---

## Summary Checklist

Use this checklist to track your deployment:

- [ ] **Prerequisites**
  - [ ] Docker v27.5+ with Compose v2 installed
  - [ ] Node.js v18+ and Yarn installed
  - [ ] 3 accounts funded with 0.5 ETH each on Arbitrum Sepolia

- [ ] **Setup**
  - [ ] Repository cloned and dependencies installed
  - [ ] `.env` configured with private keys
  - [ ] `USE_ANYTRUST=true` set in `.env`

- [ ] **Deployment**
  - [ ] `yarn deploy-chain` completed successfully
  - [ ] Contract addresses saved in `chainConfig/core-contracts.json`
  - [ ] `./fix-permissions.sh` executed
  - [ ] DAS config exists at `chainConfig/das-server/das-config.json`

- [ ] **Node Startup**
  - [ ] `yarn start-node` running without errors
  - [ ] Both `nitro` and `das-server` containers running
  - [ ] Logs show successful startup

- [ ] **Initialization**
  - [ ] `yarn initialize-chain` completed
  - [ ] All accounts funded correctly
  - [ ] Chain producing blocks

- [ ] **Verification**
  - [ ] RPC responds to `eth_chainId`
  - [ ] DAS health check returns OK
  - [ ] Can connect with MetaMask
  - [ ] Test transaction successful

- [ ] **Production** (optional)
  - [ ] Switched to `SPLIT_NODES=true`
  - [ ] Multiple DAS servers running
  - [ ] Monitoring set up
  - [ ] Backups configured
  - [ ] Firewall rules applied

---

**Congratulations!** 🎉

You now have a fully functional AnyTrust chain with Data Availability Committee running locally!

**Your chain details**:
- Chain ID: `34409397898` (check your `chainConfig/rpc/rpc-config.json`)
- RPC Endpoint: `http://localhost:8449`
- Block Explorer: `http://localhost` (if ENABLE_BLOCKSCOUT=true)
- DAS REST API: `http://localhost:9877`

**Next steps**:
1. Deploy your smart contracts
2. Build your dApp frontend
3. Connect users via MetaMask
4. Monitor performance and costs
5. Plan production migration

For questions or issues, refer to the [Troubleshooting](#troubleshooting) section or seek help in the Arbitrum Discord.

---

**Document Version**: 1.0
**Last Updated**: 2025-12-18
**Repository**: https://github.com/TucksonDev/orbit-playground
