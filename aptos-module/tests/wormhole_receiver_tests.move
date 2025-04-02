#[test_only]
module wormhole_receiver_addr::wormhole_receiver_tests {
    use std::vector;
    use std::signer;
    use aptos_framework::account;
    use wormhole_receiver_addr::wormhole_receiver;
    use aptos_std::hash;
    use aptos_std::bcs;

    const SEPOLIA_CHAIN_ID: u64 = 10002;
    const APTOS_CHAIN_ID: u16 = 22;
    const TEST_EMITTER_ADDRESS: vector<u8> = x"0102030405060708091011121314151617181920";
    
    // Test accounts
    const ADMIN: address = @0x123;
    const USER: address = @0x456;
    
    fun setup_test_accounts(): (signer, signer) {
        
        let admin = account::create_account_for_test(ADMIN);
        let user = account::create_account_for_test(USER);
        
        (admin, user)
    }
    
    // Helper function to create a mock VAA for testing
    fun create_mock_vaa(
        sequence: u64,
        destination_chain_id: u16,
        token_address: address,
        amount: u64,
        owner: address
    ): vector<u8> {
        // In a real test, you would create a properly formatted VAA
        // This is a simplified mock that would need to be replaced with actual VAA generation
        let mock_vaa = vector::empty<u8>();
        
        // Add some dummy data to represent a VAA
        // In a real implementation, you would need to properly format this
        vector::append(&mut mock_vaa, TEST_EMITTER_ADDRESS);
        
        // Add some more dummy data
        let seq_bytes = bcs::to_bytes(&sequence);
        vector::append(&mut mock_vaa, seq_bytes);
        
        // Add chain ID
        let chain_id_bytes = bcs::to_bytes(&SEPOLIA_CHAIN_ID);
        vector::append(&mut mock_vaa, chain_id_bytes);
        
        // Add destination chain ID
        let dest_chain_bytes = bcs::to_bytes(&destination_chain_id);
        vector::append(&mut mock_vaa, dest_chain_bytes);
        
        // Add token address
        let token_bytes = bcs::to_bytes(&token_address);
        vector::append(&mut mock_vaa, token_bytes);
        
        // Add amount
        let amount_bytes = bcs::to_bytes(&amount);
        vector::append(&mut mock_vaa, amount_bytes);
        
        // Add owner
        let owner_bytes = bcs::to_bytes(&owner);
        vector::append(&mut mock_vaa, owner_bytes);
        
        mock_vaa
    }
    
    #[test]
    fun test_initialize() {
        let (admin, _) = setup_test_accounts();
        
        wormhole_receiver::initialize(&admin, TEST_EMITTER_ADDRESS);
        assert!(wormhole_receiver::is_initialized(&admin), 1);
    }
    
    #[test]
    fun test_set_emitter() {
        let (admin, _) = setup_test_accounts();
        
        wormhole_receiver::initialize(&admin, TEST_EMITTER_ADDRESS);
        
        let new_emitter = x"1122334455667788990011223344556677889900";
        wormhole_receiver::set_emitter(&admin, new_emitter);

        let emitter_address = wormhole_receiver::get_emitter_address(signer::address_of(&admin));
        assert!(emitter_address == new_emitter, 1);
    }
    
    #[test]
    #[expected_failure(abort_code = wormhole_receiver_addr::wormhole_receiver::E_INVALID_STATE)]
    fun test_process_message_without_initialization() {
        let (_, user) = setup_test_accounts();
        
        // Try to process a message without initializing first
        let mock_vaa = create_mock_vaa(1, APTOS_CHAIN_ID, @0x789, 1000, USER);
        let message_hash = hash::sha3_256(mock_vaa);
        
        wormhole_receiver::process_message(
            &user,
            mock_vaa,
            APTOS_CHAIN_ID,
            @0x789,
            1000,
            USER,
            message_hash
        );
    }

    #[test]
    fun test_get_collateral() {
        let (admin, _) = setup_test_accounts();
        
        wormhole_receiver::initialize(&admin, TEST_EMITTER_ADDRESS);
        
        let message_hash = x"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
        let token_address = @0x789;
        let amount = 1000;
        
        wormhole_receiver::test_add_collateral(
            &admin,
            message_hash,
            USER,
            token_address,
            amount
        );
        
        let (owner, token, value) = wormhole_receiver::get_collateral(
            ADMIN,
            message_hash
        );
        
        assert!(owner == USER, 0);
        assert!(token == token_address, 1);
        assert!(value == amount, 2);
    }
    
    #[test]
    #[expected_failure(abort_code = 25607, location = aptos_std::table)]
    fun test_duplicate_message_processing() {
        let (admin, _) = setup_test_accounts();
        
        wormhole_receiver::initialize(&admin, TEST_EMITTER_ADDRESS);
        
        let message_hash = x"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
        let token_address = @0x789;
        let amount = 1000;
        
        wormhole_receiver::test_add_collateral(
            &admin,
            message_hash,
            USER,
            token_address,
            amount
        );
        
        // Try to add the same collateral again - this should fail
        wormhole_receiver::test_add_collateral(
            &admin,
            message_hash,
            USER,
            token_address,
            amount
        );
    }
} 