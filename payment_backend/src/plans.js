const MEMBERSHIP_PLANS = {
  'membership.lifetime': {
    sku: 'membership.lifetime',
    type: 'membership',
    days: null,
    bonusWords: 500000,
    priceFen: 19800,
  },
  'membership.yearly': {
    sku: 'membership.yearly',
    type: 'membership',
    days: 365,
    bonusWords: 500000,
    priceFen: 16800,
  },
  'membership.monthly': {
    sku: 'membership.monthly',
    type: 'membership',
    days: 30,
    bonusWords: 500000,
    priceFen: 2800,
  },
  'membership.weekly': {
    sku: 'membership.weekly',
    type: 'membership',
    days: 7,
    bonusWords: 500000,
    priceFen: 800,
  },
};

const WORDPACK_SKUS = {
  'wordpack.500k': {
    sku: 'wordpack.500k',
    type: 'wordpack',
    words: 500000,
    validityDays: 90,
    priceFen: 600,
  },
  'wordpack.2m': {
    sku: 'wordpack.2m',
    type: 'wordpack',
    words: 2000000,
    validityDays: 90,
    priceFen: 1800,
  },
  'wordpack.6m': {
    sku: 'wordpack.6m',
    type: 'wordpack',
    words: 6000000,
    validityDays: 90,
    priceFen: 4500,
  },
};

function getSku(sku) {
  return MEMBERSHIP_PLANS[sku] || WORDPACK_SKUS[sku] || null;
}

module.exports = {
  MEMBERSHIP_PLANS,
  WORDPACK_SKUS,
  getSku,
};
