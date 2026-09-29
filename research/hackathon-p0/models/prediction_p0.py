"""Integer-only semantic oracle for the bounded binary Hackathon P0 profile."""

from dataclasses import dataclass


MAX_OUTCOME_SUPPLY = (1 << 128) - 1


class Reject(Exception):
    """An operation rejected by the P0 state machine."""


@dataclass
class PredictionP0:
    state: str = "DRAFT"
    result: str = "NONE"
    collateral_locked: int = 0
    physical_balance: int = 0
    yes_supply: int = 0
    no_supply: int = 0
    yes_holders: dict[str, int] | None = None
    no_holders: dict[str, int] | None = None

    def __post_init__(self):
        self.yes_holders = {} if self.yes_holders is None else self.yes_holders
        self.no_holders = {} if self.no_holders is None else self.no_holders

    @property
    def liability(self) -> int:
        if self.result == "YES_WIN":
            return self.yes_supply
        if self.result == "NO_WIN":
            return self.no_supply
        return self.collateral_locked

    def activate(self):
        self._require(self.state == "DRAFT")
        self.state = "OPEN"

    def split(self, holder: str, amount: int, received: int | None = None):
        self._require(self.state == "OPEN")
        self._require(amount > 0)
        self._require(self.yes_supply + amount <= MAX_OUTCOME_SUPPLY)
        self._require((amount if received is None else received) == amount)
        self.physical_balance += amount if received is None else received
        self.collateral_locked += amount
        self.yes_supply += amount
        self.no_supply += amount
        self.yes_holders[holder] = self.yes_holders.get(holder, 0) + amount
        self.no_holders[holder] = self.no_holders.get(holder, 0) + amount

    def merge(self, holder: str, amount: int):
        self._require(self.state in ("OPEN", "LOCKED") and amount > 0)
        self._require(self.yes_holders.get(holder, 0) >= amount)
        self._require(self.no_holders.get(holder, 0) >= amount)
        self.yes_holders[holder] -= amount
        self.no_holders[holder] -= amount
        self.yes_supply -= amount
        self.no_supply -= amount
        self.collateral_locked -= amount
        self.physical_balance -= amount

    def close_mint(self):
        self._require(self.state == "OPEN")
        self.state = "LOCKED"

    def resolve(self, result: str):
        self._require(self.state == "LOCKED" and result in ("YES_WIN", "NO_WIN"))
        self.result = result
        self.state = "RESOLVED"

    def open_redemption(self):
        self._require(self.state == "RESOLVED" and self.physical_balance >= self.liability)
        self.state = "REDEEMABLE"

    def redeem(self, holder: str, side: str, amount: int) -> int:
        self._require(self.state == "REDEEMABLE" and amount > 0)
        self._require(side == self.result.removesuffix("_WIN"))
        balances = self.yes_holders if side == "YES" else self.no_holders
        self._require(balances.get(holder, 0) >= amount)
        balances[holder] -= amount
        if side == "YES":
            self.yes_supply -= amount
        else:
            self.no_supply -= amount
        self.collateral_locked -= amount
        self.physical_balance -= amount
        return amount

    def burn_worthless(self, holder: str, side: str, amount: int):
        self._require(self.state == "REDEEMABLE" and amount > 0)
        self._require(side != self.result.removesuffix("_WIN"))
        balances = self.yes_holders if side == "YES" else self.no_holders
        self._require(balances.get(holder, 0) >= amount)
        balances[holder] -= amount
        if side == "YES":
            self.yes_supply -= amount
        else:
            self.no_supply -= amount

    def archive(self):
        self._require(self.state == "REDEEMABLE" and self.liability == 0)
        self.state = "ARCHIVED"

    def transfer(self, sender: str, recipient: str, side: str, amount: int):
        self._require(sender != recipient and amount > 0)
        balances = self.yes_holders if side == "YES" else self.no_holders
        self._require(side in ("YES", "NO") and balances.get(sender, 0) >= amount)
        balances[sender] -= amount
        balances[recipient] = balances.get(recipient, 0) + amount

    def snapshot(self, holder: str, second_holder: str = "bob") -> dict:
        return {
            "state": self.state,
            "result": self.result,
            "collateral_locked": self.collateral_locked,
            "physical_balance": self.physical_balance,
            "liability": self.liability,
            "yes_supply": self.yes_supply,
            "no_supply": self.no_supply,
            "yes_balance": self.yes_holders.get(holder, 0),
            "no_balance": self.no_holders.get(holder, 0),
            "second_yes_balance": self.yes_holders.get(second_holder, 0),
            "second_no_balance": self.no_holders.get(second_holder, 0),
        }

    @staticmethod
    def _require(condition: bool):
        if not condition:
            raise Reject


def scenario(result: str) -> dict:
    model = PredictionP0()
    draft = model.snapshot("alice")
    model.activate()
    activated = model.snapshot("alice")
    model.split("alice", 12)
    split = model.snapshot("alice")
    model.transfer("alice", "bob", "YES", 2)
    model.transfer("alice", "bob", "NO", 2)
    transferred = model.snapshot("alice")
    model.merge("alice", 2)
    merged = model.snapshot("alice")
    model.close_mint()
    closed = model.snapshot("alice")
    model.merge("bob", 1)
    locked_merged = model.snapshot("alice")
    model.resolve(result)
    resolved = model.snapshot("alice")
    model.open_redemption()
    opened = model.snapshot("alice")
    payout = model.redeem("alice", result.removesuffix("_WIN"), 4)
    redeemed = model.snapshot("alice")
    bob_payout = model.redeem("bob", result.removesuffix("_WIN"), 1)
    bob_redeemed = model.snapshot("alice")
    model.burn_worthless("alice", "NO" if result == "YES_WIN" else "YES", 8)
    model.burn_worthless("bob", "NO" if result == "YES_WIN" else "YES", 1)
    burned = model.snapshot("alice")
    final_payout = model.redeem("alice", result.removesuffix("_WIN"), 4)
    final_redeemed = model.snapshot("alice")
    model.archive()
    archived = model.snapshot("alice")
    return {
        "result": result,
        "draft": draft,
        "activated": activated,
        "split": split,
        "transferred": transferred,
        "merged": merged,
        "closed": closed,
        "locked_merged": locked_merged,
        "resolved": resolved,
        "opened": opened,
        "first_payout": payout,
        "redeemed": redeemed,
        "bob_redeemed": bob_redeemed,
        "bob_payout": bob_payout,
        "final_payout": final_payout,
        "burned": burned,
        "final_redeemed": final_redeemed,
        "archived": archived,
    }


def differential_fixture() -> dict:
    checkpoints = [
        "draft", "activated", "split", "transferred", "merged", "closed", "locked_merged", "resolved", "opened",
        "redeemed", "bob_redeemed", "burned", "final_redeemed", "archived"
    ]
    state_codes = {"DRAFT": 0, "OPEN": 1, "LOCKED": 2, "RESOLVED": 3, "REDEEMABLE": 4, "ARCHIVED": 5}
    result_codes = {"NONE": 0, "YES_WIN": 1, "NO_WIN": 2}
    fields = [
        "state", "result", "collateral_locked", "physical_balance", "liability",
        "yes_supply", "no_supply", "yes_balance", "no_balance",
        "second_yes_balance", "second_no_balance",
    ]
    cases = []
    for winning_result in ("YES_WIN", "NO_WIN"):
        run = scenario(winning_result)
        snapshots = []
        for checkpoint in checkpoints:
            snapshot = run[checkpoint]
            snapshots.append([
                state_codes[snapshot[field]] if field == "state" else
                result_codes[snapshot[field]] if field == "result" else snapshot[field]
                for field in fields
            ])
        cases.append({
            "result": winning_result,
            "snapshots": snapshots,
            "payouts": [run["first_payout"], run["bob_payout"], run["final_payout"]],
        })
    return {
        "schema_version": 1,
        "model": "HackathonPredictionModel",
        "scenario": {
        "split_amount": 12,
        "transfer_amount": 2,
            "merge_amount": 2,
        "first_redeem_amount": 4,
        "bob_redeem_amount": 1,
        "worthless_burn_amount": 8,
        "bob_worthless_burn_amount": 1,
        "final_redeem_amount": 4,
        "checkpoints": checkpoints,
            "snapshot_fields": fields,
        },
        "cases": cases,
    }


if __name__ == "__main__":
    import json

    print(json.dumps(differential_fixture(), indent=2))
