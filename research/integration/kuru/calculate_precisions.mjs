/**
 * Local reproduction of ParamCreator.calculatePrecisions.
 *
 * Source: https://github.com/Kuru-Labs/kuru-sdk/blob/636509c2eafd63479d3f399703354e0d09f51e18/src/create/market.ts
 * Package: @kuru-labs/kuru-sdk 0.0.97
 * Retrieved: 2026-09-26
 *
 * This file does not deploy a market and does not choose RetroPick parameters.
 * The arithmetic follows the published function, including its JavaScript numbers.
 */

const DEFAULT_PRICE_PRECISION_DECIMALS = 4;

function countDecimals(value) {
  if (value === 0) return 0;
  let str = value.toString();
  if (str.includes("e")) {
    const [_base, exponent] = str.split("e");
    const exp = parseInt(exponent, 10);
    if (exp < 0) return Math.abs(exp);
    str = value.toLocaleString("fullwide", { useGrouping: false });
  }
  if (!str.includes(".")) return 0;
  const decimalPart = str.split(".")[1];
  return decimalPart ? decimalPart.length : 0;
}

function parseUnits(value, decimals) {
  const text = String(value);
  const negative = text.startsWith("-");
  const body = negative ? text.slice(1) : text;
  const [whole, frac = ""] = body.split(".");
  const significant = frac.replace(/0+$/, "");
  if (significant.length > decimals) {
    throw new Error(`fractional component exceeds decimals: ${text} / ${decimals}`);
  }
  const padded = (frac + "0".repeat(decimals)).slice(0, decimals);
  const combined = BigInt(whole || "0") * 10n ** BigInt(decimals) + BigInt(padded || "0");
  return negative ? -combined : combined;
}

function limitRecurring(text) {
  const [whole, decimalPart] = text.split(".");
  if (!decimalPart) return Number(text);
  let significantStart = 0;
  while (significantStart < decimalPart.length && decimalPart[significantStart] === "0") {
    significantStart += 1;
  }
  const significantPart = decimalPart.slice(significantStart);
  for (let len = 1; len <= 4; len += 1) {
    const pattern = significantPart.slice(0, len);
    const nextPattern = significantPart.slice(len, len * 2);
    if (pattern === nextPattern && pattern !== "0") {
      const limitedDecimal = decimalPart.slice(0, significantStart) + pattern.repeat(2);
      return Number(`${whole}.${limitedDecimal}`);
    }
  }
  return Number(text);
}

function getMaxSizeAtPrice(price, sizePrecision) {
  const uint32Max = 2n ** 32n - 1n;
  const rawMaxSize = (uint32Max * sizePrecision) / price;
  const digits = rawMaxSize.toString().length;
  return 10n ** BigInt(digits - 1);
}

function calculatePrecisions(quote, base, maxPrice, minSize, tickSizeBps = 10) {
  let currentPrice = quote / base;
  let tickSize = Math.max(currentPrice * (tickSizeBps / 10000), currentPrice / 1000000, 0.00000001);
  const tickStr = tickSize.toFixed(9);
  const priceStr = currentPrice.toFixed(9);
  currentPrice = limitRecurring(priceStr);
  if (currentPrice === 0 || !currentPrice) {
    throw new Error(`Current price is too low: ${currentPrice}`);
  }
  tickSize = limitRecurring(tickStr);
  const priceDecimals = Math.max(
    countDecimals(Number(priceStr)),
    DEFAULT_PRICE_PRECISION_DECIMALS,
    countDecimals(Number(tickStr)),
  );
  if (priceDecimals > 9) {
    throw new Error("Price precision exceeds maximum (9 decimals)");
  }
  const pricePrecision = BigInt(10 ** priceDecimals);
  const tickSizeInPrecision = parseUnits(tickStr, priceDecimals);
  const maxPriceWithPrecision = maxPrice * 10 ** priceDecimals;
  const sizeDecimalsPower = Math.floor(Math.log10(maxPriceWithPrecision));
  const sizeDecimals = Math.max(countDecimals(minSize), sizeDecimalsPower);
  const sizePrecision = BigInt(10 ** sizeDecimals);
  const priceInPrecision = parseUnits(currentPrice.toFixed(priceDecimals), priceDecimals);
  const maxSize = getMaxSizeAtPrice(priceInPrecision, sizePrecision);
  const minSizeInPrecision = parseUnits(minSize.toString(), sizeDecimals);
  return {
    pricePrecision: pricePrecision.toString(),
    sizePrecision: sizePrecision.toString(),
    tickSize: tickSizeInPrecision.toString(),
    minSize: minSizeInPrecision.toString(),
    maxSize: maxSize.toString(),
    priceDecimals,
    sizeDecimals,
  };
}

const cases = [
  {
    id: "docs-deploy-market-first-snippet",
    source: "https://docs.kuru.io/sdk/deploy-market",
    inputs: { quote: 10, base: 1, maxPrice: 10000, minSize: 1, tickSizeBps: 100 },
  },
  {
    id: "docs-deploy-market-router-example",
    source: "https://docs.kuru.io/sdk/deploy-market",
    inputs: { quote: 10, base: 1, maxPrice: 20, minSize: 0.01, tickSizeBps: 10 },
  },
  {
    id: "sdk-readme-example",
    source: "https://github.com/Kuru-Labs/kuru-sdk/blob/636509c2eafd63479d3f399703354e0d09f51e18/README.md",
    inputs: { quote: 1, base: 456789, maxPrice: 10, minSize: 0.01, tickSizeBps: 10 },
  },
];

const results = cases.map((row) => {
  try {
    return { ...row, status: "computed", output: calculatePrecisions(...Object.values(row.inputs)) };
  } catch (error) {
    return { ...row, status: "error", error: String(error.message || error) };
  }
});

process.stdout.write(`${JSON.stringify({ node: process.version, results }, null, 2)}\n`);
