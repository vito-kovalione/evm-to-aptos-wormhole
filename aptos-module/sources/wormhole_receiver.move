module wormhole_receiver_addr::wormhole_receiver {
    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_std::table::{Self, Table};
    use aptos_std::hash;
    use aptos_std::bcs;
    use std::signer;
    use std::vector;
    use wormhole::vaa;
    use wormhole::external_address;
    use wormhole::u16;

    /// Errors
    const E_INVALID_EMITTER_CHAIN: u64 = 0;
    const E_INVALID_EMITTER_ADDRESS: u64 = 1;
    const E_ALREADY_PROCESSED: u64 = 2;
    const E_INVALID_STATE: u64 = 3;

    // Sepolia chain ID in Wormhole format
    const SEPOLIA_CHAIN_ID: u64 = 10002;
    const APTOS_CHAIN_ID: u16 = 22;

    /// Struct to store collateral information
    struct Collateral has store, drop {
        owner: address,
        token_address: address,
        amount: u64,
        message_hash: vector<u8>,
    }

    /// Event emitted when a message is processed
    struct MessageProcessedEvent has drop, store {
        emitter_chain: u64,
        emitter_address: vector<u8>,
        sequence: u64,
        owner: address,
        amount: u64,
    }

    /// Resource to track processed VAAs and store collateral data
    struct WormholeReceiverState has key {
        processed_vaa_hashes: Table<vector<u8>, bool>,
        collaterals: Table<vector<u8>, Collateral>,
        message_processed_events: EventHandle<MessageProcessedEvent>,
        emitter_address: vector<u8>,
    }

    /// Initialize the module
    public entry fun initialize(account: &signer, emitter_address: vector<u8>) {
        let account_addr = signer::address_of(account);
        
        if (!exists<WormholeReceiverState>(account_addr)) {
            move_to(account, WormholeReceiverState {
                processed_vaa_hashes: table::new(),
                collaterals: table::new(),
                message_processed_events: account::new_event_handle<MessageProcessedEvent>(account),
                emitter_address,
            });
        };
    }

    /// Set the expected emitter configuration
    public entry fun set_emitter(
        account: &signer,
        emitter_address: vector<u8>
    ) acquires WormholeReceiverState {
        let account_addr = signer::address_of(account);
        let state = borrow_global_mut<WormholeReceiverState>(account_addr);
        state.emitter_address = emitter_address;
    }

    /// Process a message with individual parameters and message hash verification
    public entry fun process_message(
        account: &signer,
        vaa_bytes: vector<u8>,
        destination_chain_id: u16,
        token_address: address,
        amount: u64,
        owner: address,
        message_hash: vector<u8>
    ) acquires WormholeReceiverState {
        let account_addr = signer::address_of(account);
        
        assert!(exists<WormholeReceiverState>(account_addr), E_INVALID_STATE);
        
        let parsed_vaa = vaa::parse_and_verify(vaa_bytes);
        let emitter_chain = vaa::get_emitter_chain(&parsed_vaa);
        let emitter_address = vaa::get_emitter_address(&parsed_vaa);
        let sequence = vaa::get_sequence(&parsed_vaa);
        let _payload = vaa::get_payload(&parsed_vaa);
        
        let chain_id_value = u16::to_u64(emitter_chain);
        let emitter_bytes = external_address::get_bytes(&emitter_address);
        let sequence_value = sequence;

        vaa::destroy(parsed_vaa);

        // TODO: compute the expected payload and compare it with the payload
        // let expected_payload = compute_payload(destination_chain_id, token_address, amount, owner, emitter_bytes);

        
        // Check if this VAA has already been processed
        let vaa_hash = hash::sha3_256(vaa_bytes);
        let state = borrow_global_mut<WormholeReceiverState>(account_addr);
        assert!(!table::contains(&state.processed_vaa_hashes, vaa_hash), E_ALREADY_PROCESSED);
        
        // Verify the source chain is sepolia and the destination chain is aptos
        assert!(chain_id_value == SEPOLIA_CHAIN_ID, E_INVALID_EMITTER_CHAIN);
        assert!(destination_chain_id == APTOS_CHAIN_ID, E_INVALID_EMITTER_CHAIN);
        
        // TODO: Verify the emitter address matches our expected emitter
        
        let collateral = Collateral {
            owner,
            token_address,
            amount,
            message_hash,
        };
        
        table::add(&mut state.collaterals, message_hash, collateral);
        table::add(&mut state.processed_vaa_hashes, vaa_hash, true);
        
        event::emit_event(
            &mut state.message_processed_events,
            MessageProcessedEvent {
                emitter_chain: chain_id_value,
                emitter_address: emitter_bytes,
                sequence: sequence_value,
                owner,
                amount,
            },
        );
    }

    #[view]
    public fun get_collateral(
        account_addr: address,
        message_hash: vector<u8>
    ): (address, address, u64) acquires WormholeReceiverState {
        let state = borrow_global<WormholeReceiverState>(account_addr);
        let collateral = table::borrow(&state.collaterals, message_hash);
        (
            collateral.owner,
            collateral.token_address,
            collateral.amount,
        )
    }

    #[view]
    public fun get_emitter_address(account_addr: address): vector<u8> acquires WormholeReceiverState {
        borrow_global<WormholeReceiverState>(account_addr).emitter_address
    }

    /// encode data into a vector
    fun compute_payload(
        destination_chain_id: u16,
        token_address: address,
        amount: u64,
        owner: address,
        receiver_address: vector<u8>
    ): vector<u8> {
        let data = vector::empty<u8>();
        
        let chain_id_bytes = bcs::to_bytes(&destination_chain_id);
        vector::append(&mut data, chain_id_bytes);
        
        let token_addr_bytes = bcs::to_bytes(&token_address);
        vector::append(&mut data, token_addr_bytes);
        
        let amount_bytes = bcs::to_bytes(&amount);
        vector::append(&mut data, amount_bytes);
        
        let owner_bytes = bcs::to_bytes(&owner);
        vector::append(&mut data, owner_bytes);
        
        vector::append(&mut data, receiver_address);

        data
    }
    
    #[test_only]
    /// Test-only wrapper for compute_payload
    public fun test_compute_payload(
        destination_chain_id: u16,
        token_address: address,
        amount: u64,
        owner: address,
        receiver_address: vector<u8>
    ): vector<u8> {
        compute_payload(
            destination_chain_id,
            token_address,
            amount,
            owner,
            receiver_address
        )
    }

    #[test_only]
    /// Test-only function to add a collateral entry directly
    public fun test_add_collateral(
        account: &signer,
        message_hash: vector<u8>,
        owner: address,
        token_address: address,
        amount: u64
    ) acquires WormholeReceiverState {
        let account_addr = signer::address_of(account);
        let state = borrow_global_mut<WormholeReceiverState>(account_addr);
        
        let collateral = Collateral {
            owner,
            token_address,
            amount,
            message_hash: message_hash,
        };
        
        table::add(&mut state.collaterals, message_hash, collateral);
    }

    #[test_only]
    /// Test-only function to check if the module is initialized
    public fun is_initialized(account: &signer): bool {
        let account_addr = signer::address_of(account);
        exists<WormholeReceiverState>(account_addr)
    }

    #[test_only]
    /// Test-only function to check if the module is initialized and get the emitter address
    public fun test_is_initialized(account_addr: address): (bool, vector<u8>) acquires WormholeReceiverState {
        if (exists<WormholeReceiverState>(account_addr)) {
            let state = borrow_global<WormholeReceiverState>(account_addr);
            (true, state.emitter_address)
        } else {
            (false, vector::empty<u8>())
        }
    }
}