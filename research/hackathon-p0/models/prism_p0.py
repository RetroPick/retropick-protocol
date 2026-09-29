"""Exact lot and custody oracle for the deliberately reduced PRISM P0 profile."""
from __future__ import annotations

from dataclasses import dataclass
from fractions import Fraction
from math import gcd, lcm
from typing import Iterable, Sequence


MAX_COMPONENTS = 4
MAX_SERIES_SUPPLY = 2**128 - 1
MAX_WEIGHT_PART = 2**64 - 1
SEMANTIC_VERSION = "RETROPICK_PRISM_P0_V1"


class PrismP0Error(ValueError):
    """Rejected P0 operation. Rejections must preserve the prior state."""


@dataclass(frozen=True)
class ComponentIdentity:
    token: str
    market: str
    outcome_index: int
    collateral: str
    decimals: int
    resolution_spec_hash: str
    semantic_version: str = "RETROPICK_PREDICTION_P0_V1"
    factory_admitted: bool = True


def _fraction(value: Fraction | int | str) -> Fraction:
    result = value if isinstance(value, Fraction) else Fraction(value)
    if result <= 0:
        raise PrismP0Error("component weights must be strictly positive")
    if result.numerator > MAX_WEIGHT_PART or result.denominator > MAX_WEIGHT_PART:
        raise PrismP0Error("reduced weight numerator/denominator exceeds uint64 P0 bound")
    return result


def derive_lot_size(weights: Iterable[Fraction | int | str]) -> int:
    normalized = tuple(_fraction(weight) for weight in weights)
    if not normalized or len(normalized) > MAX_COMPONENTS:
        raise PrismP0Error("component count must be between one and four")
    lot = lcm(*(weight.denominator for weight in normalized))
    if lot > MAX_SERIES_SUPPLY:
        raise PrismP0Error("derived lot exceeds the P0 uint128 supply domain")
    return lot


def exact_component_amount(amount: int, weight: Fraction | int | str, lot_size_raw: int) -> int:
    ratio = _fraction(weight)
    if amount < 0 or lot_size_raw <= 0 or amount % lot_size_raw:
        raise PrismP0Error("amount must be a nonnegative multiple of lotSizeRaw")
    quotient, remainder = divmod(amount, ratio.denominator)
    if remainder:
        raise AssertionError("lot-size derivation failed to make the component amount integral")
    return quotient * ratio.numerator


def required_backing(supply: int, weight: Fraction | int | str, lot_size_raw: int) -> int:
    return exact_component_amount(supply, weight, lot_size_raw)


def exact_replication_certificate(
    matrix: Sequence[Sequence[Fraction | int | str]],
    target: Sequence[Fraction | int | str],
    weights: Sequence[Fraction | int | str],
    components: Sequence[ComponentIdentity],
) -> dict:
    """Recheck Gx=h exactly and return a JSON-safe evidence record."""
    G = tuple(tuple(Fraction(item) for item in row) for row in matrix)
    h = tuple(Fraction(item) for item in target)
    x = tuple(_fraction(item) for item in weights)
    if not G or len(G) != len(h) or any(len(row) != len(x) for row in G):
        raise PrismP0Error("replication matrix, target, and weights dimensions disagree")
    if len(components) != len(x):
        raise PrismP0Error("source identity count differs from replication weights")
    result = tuple(sum(G[row][column] * x[column] for column in range(len(x))) for row in range(len(G)))
    if result != h:
        raise PrismP0Error(f"exact replication recheck failed: Gx={result}, h={h}")
    return {
        "state_labels": [f"state_{index}" for index in range(len(G))],
        "G": [[str(value) for value in row] for row in G],
        "h": [str(value) for value in h],
        "x": [str(value) for value in x],
        "recomputed_Gx": [str(value) for value in result],
        "exact_recheck": True,
        "components": [
            {
                "token": item.token,
                "market": item.market,
                "outcome_index": item.outcome_index,
                "collateral": item.collateral,
                "decimals": item.decimals,
                "resolution_spec_hash": item.resolution_spec_hash,
                "semantic_version": item.semantic_version,
                "factory_admitted": item.factory_admitted,
            }
            for item in components
        ],
    }


class HackathonPrismFactory:
    """P0 model of the canonical factory's deployment-pinned creator gate."""

    def __init__(self, series_creator: str = "deployer"):
        if not series_creator:
            raise PrismP0Error("series creator must be nonzero")
        self.series_creator = series_creator
        self.series: list[HackathonPrismModel] = []

    def create_series(
        self,
        caller: str,
        components: Sequence[ComponentIdentity],
        weights: Sequence[Fraction | int | str],
    ) -> HackathonPrismModel:
        if caller != self.series_creator:
            raise PrismP0Error("only the deployment-pinned series creator may admit a series")
        series = HackathonPrismModel(components, weights, _factory=self, _caller=caller)
        self.series.append(series)
        return series

    def is_series(self, series: HackathonPrismModel) -> bool:
        return any(admitted is series for admitted in self.series)


class HackathonPrismModel:
    """Small independent state model of atomic minter-funded in-kind backing."""

    def __init__(
        self,
        components: Sequence[ComponentIdentity],
        weights: Sequence[Fraction | int | str],
        *,
        _factory: HackathonPrismFactory | None = None,
        _caller: str = "",
    ):
        if not 1 <= len(components) <= MAX_COMPONENTS or len(components) != len(weights):
            raise PrismP0Error("component count must be between one and four and match weights")
        if _factory is None or _caller != _factory.series_creator:
            raise PrismP0Error("series must be admitted through its deployment-pinned factory")
        tokens = [component.token for component in components]
        if any(not token for token in tokens) or len(set(tokens)) != len(tokens):
            raise PrismP0Error("component tokens must be nonzero and distinct")
        if any(not component.factory_admitted for component in components):
            raise PrismP0Error("component market is not registered by the accepted PredictionFactoryP0")
        if any(component.semantic_version != "RETROPICK_PREDICTION_P0_V1" for component in components):
            raise PrismP0Error("component does not use the admitted Prediction P0 semantic version")
        if any(component.outcome_index not in (0, 1) for component in components):
            raise PrismP0Error("component outcome index must be YES or NO")
        if len({component.collateral for component in components}) != 1:
            raise PrismP0Error("components must share the factory-approved collateral")
        if len({component.decimals for component in components}) != 1:
            raise PrismP0Error("components must follow one fixed decimal policy")
        self.components = tuple(components)
        self.series_factory = _factory
        self.weights = tuple(_fraction(weight) for weight in weights)
        self.lot_size_raw = derive_lot_size(self.weights)
        self.total_supply = 0
        self.holder_balances: dict[str, int] = {}
        self.wallet_components: dict[str, list[int]] = {}
        self.physical_balances = [0] * len(components)

    def _wallet(self, account: str) -> list[int]:
        return self.wallet_components.setdefault(account, [0] * len(self.components))

    def state(self) -> dict:
        return {
            "total_supply": self.total_supply,
            "holder_balances": dict(sorted(self.holder_balances.items())),
            "wallet_components": {key: list(value) for key, value in sorted(self.wallet_components.items())},
            "physical_balances": list(self.physical_balances),
            "required_backing": [
                required_backing(self.total_supply, weight, self.lot_size_raw) for weight in self.weights
            ],
        }

    def fund_wallet(self, account: str, component_index: int, amount: int) -> None:
        if amount < 0 or not 0 <= component_index < len(self.components):
            raise PrismP0Error("invalid external wallet funding")
        self._wallet(account)[component_index] += amount

    def donate(self, component_index: int, amount: int) -> None:
        if amount < 0 or not 0 <= component_index < len(self.components):
            raise PrismP0Error("invalid direct donation")
        self.physical_balances[component_index] += amount
        self.assert_backed()

    def mint(self, minter: str, amount: int, receiver: str) -> None:
        if amount <= 0 or amount % self.lot_size_raw:
            raise PrismP0Error("mint amount must be positive and lot aligned")
        if not receiver:
            raise PrismP0Error("receiver must be nonzero")
        if amount > MAX_SERIES_SUPPLY - self.total_supply:
            raise PrismP0Error("P0 series supply cap exceeded")
        required = [exact_component_amount(amount, weight, self.lot_size_raw) for weight in self.weights]
        wallet = self.wallet_components.get(minter, [0] * len(self.components))
        if any(wallet[i] < required[i] for i in range(len(required))):
            raise PrismP0Error("minter lacks its own exact component amounts")
        wallet = self._wallet(minter)
        for index, value in enumerate(required):
            wallet[index] -= value
            self.physical_balances[index] += value
        self.total_supply += amount
        self.holder_balances[receiver] = self.holder_balances.get(receiver, 0) + amount
        self.assert_backed()

    def transfer(self, sender: str, receiver: str, amount: int) -> None:
        if amount < 0 or not sender or not receiver or self.holder_balances.get(sender, 0) < amount:
            raise PrismP0Error("invalid or underfunded PRISM transfer")
        if amount == 0 or sender == receiver:
            return
        self.holder_balances[sender] -= amount
        self.holder_balances[receiver] = self.holder_balances.get(receiver, 0) + amount
        self.assert_backed()

    def redeem_in_kind(self, holder: str, amount: int, receiver: str | None = None) -> tuple[int, ...]:
        receiver = receiver or holder
        if amount <= 0 or amount % self.lot_size_raw:
            raise PrismP0Error("redemption amount must be positive and lot aligned")
        if not receiver or self.holder_balances.get(holder, 0) < amount:
            raise PrismP0Error("holder does not own the requested PRISM amount")
        amounts = tuple(exact_component_amount(amount, weight, self.lot_size_raw) for weight in self.weights)
        if any(self.physical_balances[i] < amounts[i] for i in range(len(amounts))):
            raise PrismP0Error("physical component balance is insufficient")
        self.holder_balances[holder] -= amount
        self.total_supply -= amount
        for index, value in enumerate(amounts):
            self.physical_balances[index] -= value
            self._wallet(receiver)[index] += value
        self.assert_backed()
        return amounts

    def assert_backed(self) -> None:
        required = [required_backing(self.total_supply, weight, self.lot_size_raw) for weight in self.weights]
        if any(self.physical_balances[i] < required[i] for i in range(len(required))):
            raise AssertionError("physical component backing invariant violated")

    def snapshot(self) -> tuple:
        return (
            self.total_supply,
            tuple(sorted(self.holder_balances.items())),
            tuple((key, tuple(value)) for key, value in sorted(self.wallet_components.items())),
            tuple(self.physical_balances),
        )
