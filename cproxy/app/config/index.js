'use strict';

const dotenv = require('dotenv');


// Load environment variables from .env file
dotenv.config();

const env = process.env.NODE_ENV || 'development';
const configs = {
  base: {
    env,
    name: 'phala-chain-proxy',
    host: '0.0.0.0',
    port: 7070
  },
  production: {
    name: 'phala-chain-proxy',
    host: '0.0.0.0',
    port: 7070
  },
  development: {
  },
  test: {
    port: 7070,
  }
};
const config = Object.assign(configs.base, configs[env]);

module.exports = config;
