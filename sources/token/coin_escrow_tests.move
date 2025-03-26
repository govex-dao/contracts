#[allow(lint(abort_without_constant))]
#[test_only]
module futarchy::coin_escrow_tests {
    use futarchy::coin_escrow;
    use futarchy::market_state::{Self};
    use sui::test_utils;

    // Define dummy types to stand in for actual asset and stable types.
    public struct DummyAsset has copy, drop, store {}
    public struct DummyStable has copy, drop, store {}

    // Create a dummy MarketState instance for testing.
    public fun create_dummy_market_state(ctx: &mut tx_context::TxContext): market_state::MarketState {
        // For simplicity, create a market with 1 outcome.
        market_state::create_for_testing(1, ctx)
    }

    // Create a dummy TxContext.
    public fun create_dummy_tx_context(): tx_context::TxContext {
        tx_context::dummy()
    }

    #[test]
    public fun test_new_token_escrow() {
        let mut ctx = create_dummy_tx_context();
        let ms = create_dummy_market_state(&mut ctx);

        // Create a new token escrow instance.
        let escrow = coin_escrow::new<DummyAsset, DummyStable>(ms, &mut ctx);

        // Retrieve the escrowed balances.
        let (asset_balance, stable_balance) = coin_escrow::get_balances(&escrow);

        // Verify that initial balances are zero.
        assert!(asset_balance == 0, 0);
        assert!(stable_balance == 0, 0);

        test_utils::destroy(escrow);
    }
}
