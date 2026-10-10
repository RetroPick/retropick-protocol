/**
 * E2E-ONLY session wallet bridge. Loaded exclusively when
 * VITE_WALLET_BRIDGE_URL is configured (never in production builds): registers
 * an EIP-1193 provider backed by the local signing service, so Gate 5 live
 * testnet transactions originate through retro-ui's real pipeline while the
 * keystore stays outside the page. Keys/passwords never enter the browser.
 */
import type { Eip1193Provider } from '@retropick/launchpad-sdk/wallet';

export function installSessionBridge(baseUrl: string): void {
  const root = globalThis as Record<string, unknown>;
  if (root.ethereum) return;
  const url = baseUrl.replace(/\/$/, '');
  const request = (method: string, params?: unknown[] | object) =>
    fetch(`${url}/rpc`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ method, params }),
    }).then(async (response) => {
      const body = await response.json() as { result?: unknown; error?: { message: string } };
      if (body.error) throw Object.assign(Error(body.error.message), { code: -32000 }); // server error, not disconnection
      return body.result;
    });
  const provider: Eip1193Provider = {
    request: async ({ method, params }) => {
      switch (method) {
        case 'eth_accounts':
        case 'eth_requestAccounts':
          return request('eth_accounts') as Promise<string[]>;
        case 'eth_chainId':
          return request('eth_chainId') as Promise<string>;
        case 'eth_sendTransaction':
          return request('eth_sendTransaction', params) as Promise<string>;
        case 'wallet_switchEthereumChain':
        case 'wallet_addEthereumChain':
          return null; // the bridge wallet is already on Monad Testnet
        default:
          throw Object.assign(Error(`session bridge: ${method} unsupported`), { code: 4200 });
      }
    },
    on: () => {},
    removeListener: () => {},
  };
  root.ethereum = provider;
  const detail = { info: { uuid: 'retropick-session-bridge', name: 'RetroPick Session Bridge (E2E)', icon: 'data:,', rdns: 'retropick.e2e.bridge' }, provider };
  // Announce now AND on every discovery request (providers must respond to
  // eip6963:requestProvider; a one-shot load-time announcement is missed by
  // listeners that mount later).
  globalThis.addEventListener('eip6963:requestProvider', () => {
    globalThis.dispatchEvent(new CustomEvent('eip6963:announceProvider', { detail }));
  });
  globalThis.dispatchEvent(new CustomEvent('eip6963:announceProvider', { detail }));
}
