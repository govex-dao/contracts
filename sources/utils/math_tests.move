#[allow(lint(abort_without_constant))]
#[test_only]
module futarchy::math_tests {
    use futarchy::math::{Self};

    #[test]
    public fun test_mul_div_to_64() {
        // Basic cases
        assert!(math::mul_div_to_64(500, 2000, 1000) == 1000, 0);
        assert!(math::mul_div_to_64(100, 100, 100) == 100, 1);
        assert!(math::mul_div_to_64(0, 1000, 1) == 0, 2);
        
        // Edge cases
        assert!(math::mul_div_to_64(1, 1, 1) == 1, 3);
        assert!(math::mul_div_to_64(0, 0, 1) == 0, 4);
        
        // Large numbers (but not overflowing)
        assert!(math::mul_div_to_64(1000000000, 2000000000, 1000000000) == 2000000000, 5);
        
        // Division resulting in decimal (should truncate)
        assert!(math::mul_div_to_64(10, 10, 3) == 33, 6); // 100/3 = 33.333...
        assert!(math::mul_div_to_64(7, 7, 2) == 24, 7); // 49/2 = 24.5
    }

    #[test]
    public fun test_mul_div_up() {
        // Basic cases
        assert!(math::mul_div_up(500, 2000, 1000) == 1000, 0);
        assert!(math::mul_div_up(100, 100, 100) == 100, 1);
        assert!(math::mul_div_up(0, 1000, 1) == 0, 2);
        
        // Cases requiring rounding up
        assert!(math::mul_div_up(5, 2, 3) == 4, 3); // 10/3 ≈ 3.33... -> 4
        assert!(math::mul_div_up(7, 7, 2) == 25, 4); // 49/2 = 24.5 -> 25
        assert!(math::mul_div_up(10, 10, 3) == 34, 5); // 100/3 = 33.333... -> 34
        
        // Edge cases
        assert!(math::mul_div_up(1, 1, 1) == 1, 6);
        assert!(math::mul_div_up(0, 0, 1) == 0, 7);
        
        // Cases that divide evenly (shouldn't round up)
        assert!(math::mul_div_up(5, 2, 2) == 5, 8);
        assert!(math::mul_div_up(100, 100, 10) == 1000, 9);
        
        // Large numbers (but not overflowing)
        assert!(math::mul_div_up(1000000000, 2000000000, 1000000000) == 2000000000, 10);
    }

    #[test]
    #[expected_failure(abort_code = math::EDIVIDE_BY_ZERO)]
    public fun test_mul_div_div_by_zero() {
        math::mul_div_to_64(100, 100, 0);
    }

    #[test]
    #[expected_failure(abort_code = math::EDIVIDE_BY_ZERO)]
    public fun test_mul_div_up_div_by_zero() {
        math::mul_div_up(100, 100, 0);
    }

    #[test]
    #[expected_failure(abort_code = math::EOVERFLOW)]
    public fun test_mul_div_overflow() {
        math::mul_div_to_64(18446744073709551615, 18446744073709551615, 1);
    }

    #[test]
    #[expected_failure(abort_code = math::EOVERFLOW)]
    public fun test_mul_div_up_overflow() {
        math::mul_div_up(18446744073709551615, 18446744073709551615, 1);
    }
}