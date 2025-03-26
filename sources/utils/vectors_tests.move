#[allow(lint(abort_without_constant))]
#[test_only]
module futarchy::vectors_tests {
    use std::string::{Self, String};
    use futarchy::vectors;

    // ===== Empty vector tests =====
    #[test]
    fun test_empty_vector() {
        let empty = vector::empty<String>();
        assert!(!vectors::check_valid_outcomes(empty, 10), 0);
    }

    // ===== Length constraint tests =====
    #[test]
    fun test_single_string_within_limit() {
        let mut v = vector::empty<String>();
        vector::push_back(&mut v, string::utf8(b"hello"));
        assert!(vectors::check_valid_outcomes(v, 5), 0);
    }

    #[test]
    fun test_single_string_at_limit() {
        let mut v = vector::empty<String>();
        vector::push_back(&mut v, string::utf8(b"hello"));
        assert!(vectors::check_valid_outcomes(v, 5), 0);
    }

    #[test]
    fun test_single_string_exceeds_limit() {
        let mut v = vector::empty<String>();
        vector::push_back(&mut v, string::utf8(b"hello"));
        assert!(!vectors::check_valid_outcomes(v, 4), 0);
    }

    #[test]
    fun test_zero_length_string() {
        let mut v = vector::empty<String>();
        vector::push_back(&mut v, string::utf8(b""));
        assert!(!vectors::check_valid_outcomes(v, 5), 0);
    }

    #[test]
    fun test_multiple_strings_within_limit() {
        let mut v = vector::empty<String>();
        vector::push_back(&mut v, string::utf8(b"one"));
        vector::push_back(&mut v, string::utf8(b"two"));
        vector::push_back(&mut v, string::utf8(b"three"));
        assert!(vectors::check_valid_outcomes(v, 5), 0);
    }

    #[test]
    fun test_multiple_strings_one_exceeds() {
        let mut v = vector::empty<String>();
        vector::push_back(&mut v, string::utf8(b"one"));
        vector::push_back(&mut v, string::utf8(b"toolong"));
        vector::push_back(&mut v, string::utf8(b"three"));
        assert!(!vectors::check_valid_outcomes(v, 5), 0);
    }

    #[test]
    fun test_zero_max_length() {
        let mut v = vector::empty<String>();
        vector::push_back(&mut v, string::utf8(b"a"));
        assert!(!vectors::check_valid_outcomes(v, 0), 0);
    }

    // ===== Uniqueness tests =====
    #[test]
    fun test_unique_strings() {
        let mut v = vector::empty<String>();
        vector::push_back(&mut v, string::utf8(b"one"));
        vector::push_back(&mut v, string::utf8(b"two"));
        vector::push_back(&mut v, string::utf8(b"three"));
        assert!(vectors::check_valid_outcomes(v, 5), 0);
    }

    #[test]
    fun test_duplicate_strings() {
        let mut v = vector::empty<String>();
        vector::push_back(&mut v, string::utf8(b"one"));
        vector::push_back(&mut v, string::utf8(b"one")); // Duplicate
        vector::push_back(&mut v, string::utf8(b"three"));
        assert!(!vectors::check_valid_outcomes(v, 5), 0);
    }

    #[test]
    fun test_duplicate_strings_different_cases() {
        let mut v = vector::empty<String>();
        vector::push_back(&mut v, string::utf8(b"One"));
        vector::push_back(&mut v, string::utf8(b"one")); // Different case, but unique bytes
        vector::push_back(&mut v, string::utf8(b"three"));
        assert!(vectors::check_valid_outcomes(v, 5), 0);
    }

    #[test]
    fun test_multiple_duplicates() {
        let mut v = vector::empty<String>();
        vector::push_back(&mut v, string::utf8(b"one"));
        vector::push_back(&mut v, string::utf8(b"two"));
        vector::push_back(&mut v, string::utf8(b"one")); // Duplicate
        vector::push_back(&mut v, string::utf8(b"two")); // Duplicate
        assert!(!vectors::check_valid_outcomes(v, 5), 0);
    }

    // ===== Combined constraint tests =====
    #[test]
    fun test_valid_length_and_unique() {
        let mut v = vector::empty<String>();
        vector::push_back(&mut v, string::utf8(b"one"));
        vector::push_back(&mut v, string::utf8(b"two"));
        vector::push_back(&mut v, string::utf8(b"three"));
        assert!(vectors::check_valid_outcomes(v, 5), 0);
    }

    #[test]
    fun test_invalid_length_but_unique() {
        let mut v = vector::empty<String>();
        vector::push_back(&mut v, string::utf8(b"one"));
        vector::push_back(&mut v, string::utf8(b"toolong")); // Too long
        vector::push_back(&mut v, string::utf8(b"three"));
        assert!(!vectors::check_valid_outcomes(v, 5), 0);
    }

    #[test]
    fun test_valid_length_but_not_unique() {
        let mut v = vector::empty<String>();
        vector::push_back(&mut v, string::utf8(b"one"));
        vector::push_back(&mut v, string::utf8(b"two"));
        vector::push_back(&mut v, string::utf8(b"one")); // Duplicate
        assert!(!vectors::check_valid_outcomes(v, 5), 0);
    }

    #[test]
    fun test_invalid_length_and_not_unique() {
        let mut v = vector::empty<String>();
        vector::push_back(&mut v, string::utf8(b"one"));
        vector::push_back(&mut v, string::utf8(b"toolong")); // Too long
        vector::push_back(&mut v, string::utf8(b"one")); // Duplicate
        assert!(!vectors::check_valid_outcomes(v, 5), 0);
    }

    // ===== Multibyte character tests =====
    #[test]
    fun test_multibyte_string_within_limit() {
        let mut v = vector::empty<String>();
        // "你好" in UTF-8: two Chinese characters
        vector::push_back(&mut v, string::utf8(b"\xe4\xbd\xa0\xe5\xa5\xbd"));
        assert!(vectors::check_valid_outcomes(v, 6), 0);
    }

    #[test]
    fun test_multibyte_string_exceeds_limit() {
        let mut v = vector::empty<String>();
        // "你好" in UTF-8: two Chinese characters
        vector::push_back(&mut v, string::utf8(b"\xe4\xbd\xa0\xe5\xa5\xbd"));
        assert!(!vectors::check_valid_outcomes(v, 5), 0);
    }

    #[test]
    fun test_mixed_ascii_and_multibyte_strings() {
        let mut v = vector::empty<String>();
        // "hello" is 5 ASCII characters
        vector::push_back(&mut v, string::utf8(b"hello"));
        // "😊" in UTF-8: emoji character
        vector::push_back(&mut v, string::utf8(b"\xf0\x9f\x98\x8a"));
        assert!(vectors::check_valid_outcomes(v, 5), 0);
    }

    #[test]
    fun test_duplicate_multibyte_strings() {
        let mut v = vector::empty<String>();
        // "你好" in UTF-8: two Chinese characters
        vector::push_back(&mut v, string::utf8(b"\xe4\xbd\xa0\xe5\xa5\xbd"));
        // Duplicate of "你好"
        vector::push_back(&mut v, string::utf8(b"\xe4\xbd\xa0\xe5\xa5\xbd"));
        assert!(!vectors::check_valid_outcomes(v, 10), 0);
    }

    // ===== Edge cases =====
    #[test]
    fun test_large_vector() {
        let mut v = vector::empty<String>();
        let mut i = 0;
        while (i < 100) {
            // Generate unique strings
            vector::push_back(&mut v, string::utf8(vector::singleton(i)));
            i = i + 1;
        };
        assert!(vectors::check_valid_outcomes(v, 10), 0);
    }

    #[test]
    fun test_large_max_length() {
        let mut v = vector::empty<String>();
        vector::push_back(&mut v, string::utf8(b"short"));
        vector::push_back(&mut v, string::utf8(b"another"));
        assert!(vectors::check_valid_outcomes(v, 1000), 0);
    }
}