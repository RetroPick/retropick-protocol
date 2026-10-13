// src/commands/retropick/markets.ts
import { PluginCommand } from "@metamask/agent-wallet/plugin";

// src/context.ts
import { createPublicClient, http } from "viem";

// src/policy.ts
var RETROPICK_CHAIN_ID = 10143;
var DEFAULT_POLICY = {
  chainId: RETROPICK_CHAIN_ID,
  verifiedMarkets: ["0x1f5de72616a7fe645cf45ac66dfce8ac7452c57f"],
  maxNotionalQuoteRaw: 5n * 10n ** 16n,
  maxOrderSizeBaseRaw: 2000000n * 10n ** 18n,
  quoteExpiryMs: 30000,
  maxBookLagBlocks: 16,
  minPriceX18: 10n ** 14n
};
function assessRisk(policy, input) {
  const notes = [];
  const oneSided = input.bestBidX18 === 0n || input.bestAskX18 === 0n;
  let spreadBps = null;
  if (!oneSided && input.midX18 > 0n) {
    spreadBps = (input.bestAskX18 - input.bestBidX18) * 10000n / input.midX18;
    if (spreadBps > 300n)
      notes.push(`wide spread (${spreadBps} bps) — crossing costs are high`);
  } else {
    notes.push("one-sided or empty book — market orders may fail");
  }
  const lag = input.lastTradeBlock === null ? null : input.headBlock - input.lastTradeBlock;
  const staleBook = input.lastTradeBlock === null || lag === null ? false : lag > policy.maxBookLagBlocks * 8;
  if (input.lastTradeBlock === null)
    notes.push("no observed trades yet");
  else if (staleBook)
    notes.push(`last trade ${lag} blocks ago — activity may have moved`);
  return { spreadBps, oneSided, staleBook, notes, caution: notes.length > 0 };
}

// src/context.ts
var COORDINATOR_ABI = [
  { type: "function", name: "ledger", inputs: [{ name: "token", type: "address" }], outputs: [{ name: "", type: "tuple", internalType: "struct GraduationLedger", components: [
    { name: "phase", type: "uint8", internalType: "enum GraduationState" },
    { name: "securedQuote", type: "uint256" },
    { name: "securedLaunchTokens", type: "uint256" },
    { name: "consumedQuote", type: "uint256" },
    { name: "consumedLaunchTokens", type: "uint256" },
    { name: "destinationIdentity", type: "bytes32" },
    { name: "receiptHash", type: "bytes32" },
    { name: "protectedLPReceiver", type: "address" },
    { name: "protectedLPAmount", type: "uint256" },
    { name: "protectedExcessReceiver", type: "address" },
    { name: "protectedExcessAmount", type: "uint256" },
    { name: "securedAt", type: "uint256" }
  ] }] },
  { type: "function", name: "receipt", inputs: [{ name: "token", type: "address" }], outputs: [{ name: "", type: "tuple", internalType: "struct GraduationReceipt", components: [
    { name: "packetHash", type: "bytes32" },
    { name: "destinationIdentity", type: "bytes32" },
    { name: "market", type: "address" },
    { name: "vault", type: "address" },
    { name: "lpAsset", type: "address" },
    { name: "positionId", type: "uint256" },
    { name: "seededQuote", type: "uint256" },
    { name: "seededLaunchTokens", type: "uint256" },
    { name: "quoteResidual", type: "uint256" },
    { name: "quoteResidualReceiver", type: "address" },
    { name: "protectedLPReceiver", type: "address" },
    { name: "protectedLPAmount", type: "uint256" },
    { name: "protectedExcessReceiver", type: "address" },
    { name: "protectedExcessAmount", type: "uint256" }
  ] }] }
];
var KURU_ABI = [
  { type: "function", name: "bestBidAsk", inputs: [], outputs: [{ name: "", type: "uint256" }, { name: "", type: "uint256" }], stateMutability: "view" },
  { type: "function", name: "getMarketParams", inputs: [], outputs: [
    { name: "", type: "uint32" },
    { name: "", type: "uint96" },
    { name: "", type: "address" },
    { name: "", type: "uint256" },
    { name: "", type: "address" },
    { name: "", type: "address" },
    { name: "", type: "uint256" },
    { name: "", type: "uint32" },
    { name: "", type: "uint96" },
    { name: "", type: "uint96" },
    { name: "", type: "uint256" },
    { name: "", type: "uint256" }
  ], stateMutability: "view" }
];
var MARGIN_ABI = [
  { type: "function", name: "getBalance", inputs: [{ name: "user", type: "address" }, { name: "asset", type: "address" }], outputs: [{ name: "", type: "uint256" }], stateMutability: "view" }
];
var RETROPICK = {
  chainId: RETROPICK_CHAIN_ID,
  coordinator: "0xaD62309242EA65BB07C833669EC6a4ED23AF738F",
  factory: "0xa7f18b9eceb0A9852b08408854A45D00fc682454",
  router: "0x7EFbE105Ca7415dE98F96622173458ac1c054630",
  marginAccount: "0xd029C2D98ff85D8F64799017fE00a59B1159CE02",
  tokens: [{ token: "0x43e7e9b1b7d9A143573307b13D14B51580c18f15", market: "0x1F5dE72616a7fe645Cf45aC66dfce8Ac7452C57F", vault: "0xc88DED06eB0081430Ff02d124C22b532e122CbE7" }]
};
var abis = { coordinator: COORDINATOR_ABI, kuru: KURU_ABI, margin: MARGIN_ABI };
function monadClient() {
  return createPublicClient({ transport: http("https://testnet-rpc.monad.xyz") });
}
function policyOf() {
  return { ...DEFAULT_POLICY, verifiedMarkets: RETROPICK.tokens.map((t) => t.market.toLowerCase()) };
}

// src/commands/retropick/markets.ts
class MarketsCommand extends PluginCommand {
  static description = "List verified RetroPick launches with lifecycle phase and Kuru market";
  pluginCommandId = "retropick markets";
  async execute(io) {
    const client = monadClient();
    const out = [];
    for (const entry of RETROPICK.tokens) {
      const ledger = await client.readContract({ abi: abis.coordinator, functionName: "ledger", address: RETROPICK.coordinator, args: [entry.token] });
      const receipt = await client.readContract({ abi: abis.coordinator, functionName: "receipt", address: RETROPICK.coordinator, args: [entry.token] });
      const phase = Number(ledger[0]);
      const market = phase === 2 ? String(receipt[2]) : null;
      out.push({ token: entry.token, phase, market });
      io.emit(`${entry.token} phase=${phase} (${phase === 2 ? `graduated → Kuru ${market}` : "on curve"})`);
    }
    return out;
  }
}
export {
  MarketsCommand as default
};
