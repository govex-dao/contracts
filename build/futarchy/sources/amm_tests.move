#[test_only]
module futarchy::amm_tests {
    use sui::test_scenario::{Self as test, Scenario, ctx};
    use std::string::{Self, String};
    use sui::clock::{Self, Clock};
    use futarchy::amm::{Self, LiquidityPool};
    use futarchy::market_state::{Self, MarketState};
    use std::debug;

    // ======== Constants ========
    const ADMIN: address = @0xAD;
    
    const INITIAL_ASSET: u64 = 1000000000; // 1000 units
    const INITIAL_STABLE: u64 = 1000000000; // 1000 units
    const SWAP_AMOUNT: u64 = 100000000; // 100 units (10% of pool)
    const FEE_SCALE: u64 = 10000;
    const DEFAULT_FEE: u64 = 50; // 0.5%

    
    const BASIS_POINTS: u64 = 1_000_000_000_000;
    const TWAP_START_DELAY: u64 = 2000;
    const TWAP_STEP_MAX: u64 = 1000;
    const OUTCOME_COUNT: u64 = 2;
    const MIN_ASSET_AMOUNT: u64 = 1000000000;
    const MIN_STABLE_AMOUNT: u64 = 1000000000;

    // ======== Test Setup Functions ========
    fun setup_test(): (Scenario, Clock) {
        let mut scenario = test::begin(ADMIN);
        let clock = clock::create_for_testing(ctx(&mut scenario));
        (scenario, clock)
    }

    fun setup_market(scenario: &mut Scenario, clock: &Clock): (MarketState) {
    let market_id = object::id_from_address(@0x1); // Using a dummy ID for testing
    let dao_id = object::id_from_address(@0x2); // Using a dummy ID for testing

        // Create outcome messages
        let mut outcome_messages = vector::empty<String>();
        vector::push_back(&mut outcome_messages, string::utf8(b"Yes"));
        vector::push_back(&mut outcome_messages, string::utf8(b"No"));

        let (mut state) = market_state::new(
            market_id,
            dao_id,
            OUTCOME_COUNT,
            outcome_messages,
            clock,
            ctx(scenario)
        );

        market_state::start_trading(
            &mut state, 
            clock::timestamp_ms(clock),
            clock,
        );

        (state)
    }

    fun setup_pool(
        scenario: &mut Scenario,
        state: &MarketState,
        clock: &Clock,
    ): LiquidityPool {
        amm::new_pool(
            state,
            0, // outcome_idx
            INITIAL_ASSET,
            INITIAL_STABLE,
            TWAP_START_DELAY,
            TWAP_STEP_MAX,
            clock::timestamp_ms(clock),
            MIN_ASSET_AMOUNT,
            MIN_STABLE_AMOUNT,
            ctx(scenario)
        )
    }

    // ======== Basic Functionality Tests ========
    #[test]
    fun test_pool_creation() {
        let (mut scenario, clock) = setup_test();
        let (state) = setup_market(&mut scenario, &clock);
        
        let pool = setup_pool(&mut scenario, &state, &clock);
        
        let (asset_reserve, stable_reserve) = amm::get_reserves(&pool);
        assert!(asset_reserve == INITIAL_ASSET, 0);
        assert!(stable_reserve == INITIAL_STABLE, 0);
        
        // Verify initial price
        let initial_price = amm::get_current_price(&pool);
        assert!(initial_price == (BASIS_POINTS as u128), 1); // Price should be 1.0 initially
        
        amm::destroy_for_testing(pool);
        market_state::destroy_for_testing(state); 
        clock::destroy_for_testing(clock);
        test::end(scenario);
    }

    #[test]
    fun test_swap_asset_to_stable() {
        let (mut scenario, clock) = setup_test();
        let (state) = setup_market(&mut scenario, &clock);
        
        let mut pool = setup_pool(&mut scenario, &state, &clock);
        
        let initial_price = amm::get_current_price(&pool);
        
        let _ = amm::swap_asset_to_stable(
            &mut pool,
            &state,
            SWAP_AMOUNT,
            0,
            &clock,
            ctx(&mut scenario)
        );
        
        let new_price = amm::get_current_price(&pool);
        debug::print(&b"Price comparison:");
        debug::print(&initial_price);
        debug::print(&new_price);
        
        assert!(new_price < initial_price, 2);
        
        amm::destroy_for_testing(pool);
        market_state::destroy_for_testing(state); 
        clock::destroy_for_testing(clock);
        test::end(scenario);
    }


    #[test]
    fun test_swap_stable_to_asset() {
        let (mut scenario, clock) = setup_test();
        let (state,) = setup_market(&mut scenario, &clock);
        
        let mut pool = setup_pool(&mut scenario, &state, &clock);
        
        let initial_price = amm::get_current_price(&pool);
        
        let amount_out = amm::swap_stable_to_asset(
            &mut pool,
            &state,
            SWAP_AMOUNT,
            0,
            &clock,
            ctx(&mut scenario)
        );
        
        let (asset_reserve, stable_reserve) = amm::get_reserves(&pool);
        // DEFAULT_FEE is 50 (0.5%)
        let fee_amount = (SWAP_AMOUNT * DEFAULT_FEE) / FEE_SCALE;
        assert!(stable_reserve == INITIAL_STABLE + (SWAP_AMOUNT - fee_amount), 0);
        assert!(asset_reserve == INITIAL_ASSET - amount_out, 1);
        
        let new_price = amm::get_current_price(&pool);
        debug::print(&b"Swap stable_to_asset:");
        debug::print(&b"Initial price:");
        debug::print(&initial_price);
        debug::print(&b"New price:");
        debug::print(&new_price);
        
        // When we buy assets with stable tokens:
        // - asset_reserve decreases
        // - stable_reserve increases
        // - price (asset/stable) should decrease
        assert!(new_price > initial_price, 2);
        
        amm::destroy_for_testing(pool);
        market_state::destroy_for_testing(state); 
        clock::destroy_for_testing(clock);
        test::end(scenario);
    }

    // ======== Oracle Tests ========
    #[test]
    fun test_oracle_price_updates() {
        let (mut scenario, mut clock) = setup_test();
        let (state) = setup_market(&mut scenario, &clock);
        
        let mut pool = setup_pool(&mut scenario, &state, &clock);
        
        // Initial price check
        let initial_price = amm::get_current_price(&pool);
        debug::print(&b"Initial price check:");
        debug::print(&initial_price);
        
        // Perform swap
        clock::set_for_testing(&mut clock, 2000); 
        let _ = amm::swap_asset_to_stable(
            &mut pool,
            &state,
            SWAP_AMOUNT,
            0,
            &clock,
            ctx(&mut scenario)
        );
        
        // Check new price
        let new_price = amm::get_current_price(&pool);
        debug::print(&b"New price check:");
        debug::print(&new_price);
        
        assert!(new_price < initial_price, 1);
        
        amm::destroy_for_testing(pool);
        market_state::destroy_for_testing(state); 
        clock::destroy_for_testing(clock);
        test::end(scenario);
    }
}