'use strict';

const Koa = require('koa');
const logging = require('@kasa/koa-logging');
const requestId = require('@kasa/koa-request-id');
const bodyParser = require('./middlewares/body-parser');
const cors = require('./middlewares/cors');
const errorHandler = require('./middlewares/error-handler');
const corsConfig = require('./config/cors');
const logger = require('./logger');
const router = require('./routes');
const typedef = require('./typedef.json');

const { ApiPromise, WsProvider, Keyring } = require('@polkadot/api');

const NODE_ENDPOINT = process.env.NODE_ENDPOINT || 'ws://phala-node:9944';

class App extends Koa {
  constructor(...params) {
    super(...params);

    // Trust proxy
    this.proxy = true;
    // Disable `console.errors` except development env
    this.silent = this.env !== 'development';

    this.servers = [];

    this._configureMiddlewares();
    this._configureRoutes();

    this.initPolkadotApi();
  }

  _configureMiddlewares() {
    this.use(errorHandler());
    this.use(requestId());
    this.use(logging({
      logger,
      overrideSerializers: false
    }));
    this.use(
      bodyParser({})
    );
    this.use(
      cors({
        origins: corsConfig.origins,
        allowMethods: ['GET', 'HEAD', 'PUT', 'POST', 'DELETE', 'PATCH'],
        allowHeaders: ['Content-Type', 'Authorization'],
        exposeHeaders: ['Content-Length', 'Date', 'X-Request-Id']
      })
    );
  }

  _configureRoutes() {
    // Bootstrap application router
    this.use(router.routes());
    this.use(router.allowedMethods());
  }

  listen(...args) {
    const server = super.listen(...args);
    this.servers.push(server);
    return server;
  }

  async initPolkadotApi() {
    const provider = new WsProvider(NODE_ENDPOINT);

    // Create the API and wait until ready
    const api = await ApiPromise.create({
      provider,
      types: typedef
    });

    // Retrieve the chain & node information information via rpc calls
    const [chain, nodeName, nodeVersion] = await Promise.all([
      api.rpc.system.chain(),
      api.rpc.system.name(),
      api.rpc.system.version()
    ]);

    api.keyring = new Keyring({ type: 'sr25519', ss58Format: 30 });

    console.log(`You are connected to chain ${chain} using ${nodeName} v${nodeVersion}`);
    this.polkadotApi = api;
    global.polkadotApi = api;
  }

  async terminate() {
    // TODO: Implement graceful shutdown with pending request counter
    for (const server of this.servers) {
      server.close();
    }
  }
}

module.exports = App;
