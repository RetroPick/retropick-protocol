import { DatabaseSync } from 'node:sqlite';
import { createHash } from 'node:crypto';
import { ApiError, type Association, type Challenge, type IndexFreshness, type QualifyingEvent, type ReferralSummary } from './model.ts';

type Row = Record<string, unknown>;
const hashToken = (token: string) => createHash('sha256').update(token).digest('hex');

/** Stores ownership associations and attribution only; it never records signatures or funds. */
export class ReferralStore {
  private db: DatabaseSync;
  constructor(file: string) {
    this.db = new DatabaseSync(file);
    this.db.exec(`PRAGMA journal_mode=WAL; PRAGMA foreign_keys=ON;
      CREATE TABLE IF NOT EXISTS challenges(id TEXT PRIMARY KEY, wallet TEXT NOT NULL, referrer TEXT, nonce TEXT NOT NULL UNIQUE, message TEXT NOT NULL, created_at INTEGER NOT NULL, expires_at INTEGER NOT NULL, first_seen_at INTEGER NOT NULL, consumed INTEGER NOT NULL DEFAULT 0);
      CREATE TABLE IF NOT EXISTS sessions(token_hash TEXT PRIMARY KEY, wallet TEXT NOT NULL, expires_at INTEGER NOT NULL);
      CREATE TABLE IF NOT EXISTS associations(referred_wallet TEXT PRIMARY KEY, referrer_wallet TEXT NOT NULL, first_seen_at INTEGER NOT NULL, associated_at INTEGER NOT NULL, association_block INTEGER NOT NULL);
      CREATE INDEX IF NOT EXISTS associations_referrer ON associations(referrer_wallet);
      CREATE TABLE IF NOT EXISTS activity(id TEXT PRIMARY KEY, block_number INTEGER NOT NULL, block_hash TEXT NOT NULL, tx_hash TEXT NOT NULL, log_index INTEGER NOT NULL, payload TEXT NOT NULL, UNIQUE(tx_hash,log_index));
      CREATE TABLE IF NOT EXISTS state(key TEXT PRIMARY KEY, value TEXT NOT NULL);`);
  }
  close() { this.db.close(); }
  addChallenge(c: Challenge) {
    this.db.prepare('INSERT INTO challenges(id,wallet,referrer,nonce,message,created_at,expires_at,first_seen_at) VALUES(?,?,?,?,?,?,?,?)').run(c.id,c.wallet,c.referrer,c.nonce,c.message,c.createdAt,c.expiresAt,c.firstSeenAt);
  }
  takeChallenge(id: string, now: number): Challenge {
    const row = this.db.prepare('UPDATE challenges SET consumed=1 WHERE id=? AND consumed=0 AND expires_at>? RETURNING *').get(id,now) as Row | undefined;
    if (!row) throw new ApiError(401,'CHALLENGE_EXPIRED_OR_USED');
    return { id: String(row.id), wallet: String(row.wallet), referrer: row.referrer ? String(row.referrer) : null, nonce: String(row.nonce), message: String(row.message), createdAt: Number(row.created_at), expiresAt: Number(row.expires_at), firstSeenAt: Number(row.first_seen_at) };
  }
  association(wallet: string): Association | null {
    const row = this.db.prepare('SELECT * FROM associations WHERE referred_wallet=?').get(wallet) as Row | undefined;
    return row ? { referredWallet: String(row.referred_wallet), referrerWallet: String(row.referrer_wallet), firstSeenAt: Number(row.first_seen_at), associatedAt: Number(row.associated_at), associationBlock: Number(row.association_block) } : null;
  }
  associate(c: Challenge, block: number, now: number) {
    if (!c.referrer) return;
    if (c.referrer === c.wallet) throw new ApiError(400,'SELF_REFERRAL');
    const existing = this.association(c.wallet);
    if (existing && existing.referrerWallet !== c.referrer) throw new ApiError(409,'REFERRER_IMMUTABLE');
    this.db.prepare('INSERT OR IGNORE INTO associations VALUES(?,?,?,?,?)').run(c.wallet,c.referrer,c.firstSeenAt,now,block);
  }
  addSession(token: string, wallet: string, expiresAt: number) { this.db.prepare('INSERT INTO sessions VALUES(?,?,?)').run(hashToken(token),wallet,expiresAt); }
  session(token: string, now: number): string | null {
    const row = this.db.prepare('SELECT wallet FROM sessions WHERE token_hash=? AND expires_at>?').get(hashToken(token),now) as Row | undefined;
    return row ? String(row.wallet) : null;
  }
  logout(token: string) { this.db.prepare('DELETE FROM sessions WHERE token_hash=?').run(hashToken(token)); }
  cleanup(now: number) {
    this.db.prepare('DELETE FROM challenges WHERE expires_at<=?').run(now);
    this.db.prepare('DELETE FROM sessions WHERE expires_at<=?').run(now);
  }
  earliestAssociationBlock(): number | null {
    const row = this.db.prepare('SELECT MIN(association_block) AS block FROM associations').get() as Row;
    return row.block === null ? null : Number(row.block);
  }
  freshness(): IndexFreshness | null {
    const row = this.db.prepare("SELECT value FROM state WHERE key='freshness'").get() as Row | undefined;
    return row ? JSON.parse(String(row.value)) as IndexFreshness : null;
  }
  /** Apply only a complete canonical paginated window; remove orphaned rows on rewind. */
  reconcile(fromBlock: number, toBlock: number, events: QualifyingEvent[], freshness: IndexFreshness) {
    this.db.exec('BEGIN IMMEDIATE');
    try {
      this.db.prepare('DELETE FROM activity WHERE block_number>=? AND block_number<=? OR block_number>?').run(fromBlock,toBlock,toBlock);
      const insert = this.db.prepare('INSERT INTO activity VALUES(?,?,?,?,?,?)');
      for (const e of events) insert.run(e.id,e.blockNumber,e.blockHash,e.txHash,e.logIndex,JSON.stringify(e));
      this.db.prepare("INSERT INTO state VALUES('freshness',?) ON CONFLICT(key) DO UPDATE SET value=excluded.value").run(JSON.stringify(freshness));
      this.db.exec('COMMIT');
    } catch (error) { this.db.exec('ROLLBACK'); throw error; }
  }
  summary(wallet: string): ReferralSummary {
    const associations = this.db.prepare('SELECT * FROM associations WHERE referrer_wallet=? ORDER BY associated_at DESC').all(wallet) as Row[];
    const events = (this.db.prepare('SELECT payload FROM activity ORDER BY block_number,log_index').all() as Row[]).map(r=>JSON.parse(String(r.payload)) as QualifyingEvent);
    const totals = new Map<string,bigint>(); let qualifiedWallets=0; let createdLaunches=0;
    const referrals = associations.map(a => {
      const mine = events.filter(e=>e.actor===a.referred_wallet && e.blockNumber>Number(a.association_block));
      if (mine.length) qualifiedWallets++;
      for (const e of mine) {
        if (e.eventName==='TokenLaunched') createdLaunches++;
        else totals.set(e.quote,(totals.get(e.quote)??0n)+BigInt(e.quoteAmountRaw));
      }
      return { wallet: String(a.referred_wallet), firstSeenAt: new Date(Number(a.first_seen_at)).toISOString(), status: mine.length ? 'QUALIFIED' as const : 'ASSOCIATED' as const, qualifyingAction: mine[0]?.eventName??null, qualifyingTxHash: mine[0]?.txHash??null, createdLaunch: mine.find(e=>e.eventName==='TokenLaunched')?.token??null };
    });
    return { wallet, referralCode: wallet, earningsEnabled:false, referralPayoutRequiresProtocolChange:true, referredBy:this.association(wallet)?.referrerWallet??null, referredWallets:associations.length,qualifiedWallets,createdLaunches,volumeByQuote:[...totals].map(([quote,volume])=>({quote,volumeRaw:volume.toString()})),referrals,freshness:this.freshness() };
  }
}
