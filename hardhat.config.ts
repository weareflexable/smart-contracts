import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import dotenv from "dotenv";
dotenv.config();

// TESTNET
const MATIC_RPC_URL =
  process.env.AMOY_RPC_URL || "https://polygon-mumbai.g.alchemy.com/v2/api-key";

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || "https://ETH-RPC-URL";

const BASE_TESTNET_RPC_URL =
  process.env.BASE_TESTNET_RPC_URL || "wss://base-sepolia-rpc.publicnode.com";

// PRIVAT/MNEMONIC
const MNEMONIC =
  process.env.MNEMONIC ||
  "ajkskjfjksjkf ssfaasff asklkfl klfkas dfklhao asfj sfk klsfjs fkjs";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

// BLOCK EXPLORER API
const POLYGONSCAN_API_KEY =
  process.env.POLYGONSCAN_API_KEY || "lklsdkskldjklgdklkld";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "Etherscan API key";
const BASESCAN_API_KEY = process.env.BASESCAN_API_KEY || "Basescan API Key";

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      initialBaseFeePerGas: 0,
    },
    // TESTNET NETWORKS
    amoy: {
      networkId: 80002,
      url: MATIC_RPC_URL,
      accounts: [PRIVATE_KEY],
    },
    sepolia: {
      networkId: 11155111,
      url: SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY],
    },
    baseTestnet: {
      networkId: 84532,
      url: BASE_TESTNET_RPC_URL,
      accounts: {
        mnemonic: MNEMONIC,
      },
    },
    //MAINNET
    matic: {
      chainId: 137,
      url: MATIC_RPC_URL,
      accounts: {
        mnemonic: MNEMONIC,
      },
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: {
      polygonAmoy: POLYGONSCAN_API_KEY,
      sepolia: ETHERSCAN_API_KEY,
      baseSepolia: BASESCAN_API_KEY,
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 20000,
  },
};
