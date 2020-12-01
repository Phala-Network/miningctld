const logger = require('../logger');
const ONE_PHA = 1000000000000;

const wait = t => new Promise(resolve => setTimeout(resolve, t));

const waitExtrinsicSend = (tx, keypair) => new Promise(async resolve => {
  const { nonce } = await global.polkadotApi.query.system.account(keypair.address);

  tx.signAndSend(keypair, { nonce }, ({ events = [], status }) => {
    logger.info('Transaction status:', status.type);
    if (status.isInBlock) {
      logger.info('Included at block hash', status.asInBlock.toHex());
      logger.info('Events:');
      events.forEach(({ event: { data, method, section }, phase }) => {
        logger.info('\t', phase.toString(), `: ${section}.${method}`, data.toString());
      });
      resolve(events.map(({ event: { data, method, section }, phase }) => {
        return {
          phase,
          section,
          method,
          data
        };
      }));
    } else if (status.isFinalized) {
      logger.info('Finalized block hash', status.asFinalized.toHex());
    }
  });
});

const bindStash = async ctx => {
  const api = ctx.app.polkadotApi;
  const { controllerSs58, stashUri } = ctx.request.body;
  const stash = api.keyring.addFromUri(stashUri);

  const events = await waitExtrinsicSend(
    api.tx.phalaModule.setStash(controllerSs58),
    stash
  );

  ctx.body = {
    error: false,
    message: 'extrinsic sent',
    extra: events
  };
};

const topUp = async ctx => {
  const api = ctx.app.polkadotApi;
  const { controllerSs58, stashUri } = ctx.request.body;
  const amount = ctx.request.body.amount * ONE_PHA;
  const stash = api.keyring.addFromUri(stashUri);

  let { data: { free: controllerBalance } } = await api.query.system.account(controllerSs58);
  let { data: { free: stashBalance } } = await api.query.system.account(stash.address);

  logger.info(`before: Controller Balance: ${controllerBalance * 1.0 / ONE_PHA} PHA`);
  logger.info(`before: Stash Balance: ${stashBalance * 1.0 / ONE_PHA} PHA`);

  if (controllerBalance >= amount || stashBalance <= amount) {
    ctx.body = {
      success: false,
      controllerBalance,
      stashBalance
    };

    return;
  }

  const events = await waitExtrinsicSend(
    api.tx.balances.transfer(controllerSs58, amount),
    stash
  );
  await wait(6000);
  // wait for a block

  ({ data: { free: controllerBalance } } = await api.query.system.account(controllerSs58));
  ({ data: { free: stashBalance } } = await api.query.system.account(stash.address));

  ctx.body = {
    success: true,
    controllerBalance,
    stashBalance,
    events
  };
};

const setCommission = async ctx => {
  const api = ctx.app.polkadotApi;
  const { commission, target, controllerUri } = ctx.request.body;
  const controller = api.keyring.addFromUri(controllerUri);

  const events = await api.tx.phalaModule.setPayoutPrefs(commission, target).signAndSend(controller);

  ctx.body = {
    success: true,
    events
  };
};

const startIntention = async ctx => {
  const api = ctx.app.polkadotApi;
  const { stashUri } = ctx.request.body;
  const stash = api.keyring.addFromUri(stashUri);

  const events = await api.tx.phalaModule.startMiningIntention().signAndSend(stash);

  ctx.body = {
    success: true,
    events
  };
};

const stopIntention = async ctx => {
  const api = ctx.app.polkadotApi;
  const { stashUri } = ctx.request.body;
  const stash = api.keyring.addFromUri(stashUri);

  const events = await api.tx.phalaModule.stopMiningIntention().signAndSend(stash);

  ctx.body = {
    success: true,
    events
  };
};


exports.bindStash = bindStash;
exports.topUp = topUp;
exports.setCommission = setCommission;
exports.startIntention = startIntention;
exports.stopIntention = stopIntention;
