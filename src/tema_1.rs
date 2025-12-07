#![no_std]

use multiversx_sc::imports::*;
use multiversx_sc::proxy_imports::*;

#[type_abi]
#[derive(TopEncode, TopDecode, NestedEncode, NestedDecode)]
pub struct Slot<M: ManagedTypeApi> {
    pub start: u64,
    pub end: u64,
    pub payer: ManagedAddress<M>,
    pub amount: BigUint<M>,
    pub confirmed: bool,
}

/// An empty contract. To be used as a template when starting a new contract from scratch.
#[multiversx_sc::contract]
pub trait Tema1 {
    #[init]
    fn init(&self) {}

    #[upgrade]
    fn upgrade(&self) {}

    // --- Events ---

    #[event("football_slot_created")]
    fn football_slot_created_event(
        &self,
        #[indexed] initiator: &ManagedAddress,
        #[indexed] start: u64,
        #[indexed] end: u64,
        amount: &BigUint,
    );

    #[event("participate_to_football")]
    fn participate_to_football_event(
        &self,
        #[indexed] participant: &ManagedAddress,
        #[indexed] slot_start: u64,
        #[indexed] slot_end: u64,
        amount: &BigUint,
    );

    // --- Functions ---

    #[only_owner]
    #[endpoint(setFootballCourtCost)]
    fn set_football_court_cost(&self, cost: BigUint) {
        self.football_court_cost().set(cost);
    }

    #[payable("EGLD")]
    #[endpoint(participateToFootballSlot)]
    fn participate_to_football_slot(&self) {
        // Ensure there is a reserved slot
        let slot = self
            .reserved_slot()
            .get()
            .expect("No football slot is currently reserved");

        let caller = self.blockchain().get_caller();
        let payment = self.call_value().egld().clone();

        require!(
            !self.participants().contains(&caller),
            "You have already participated in this slot"
        );

        require!(payment == slot.amount, "Payment must equal the slot amount");

        // Register the participant
        self.participants().insert(caller.clone());
        self.participate_to_football_event(&caller, slot.start, slot.end, &payment);
    }

    #[payable("EGLD")]
    #[endpoint(createFootballSlot)]
    fn create_football_slot(&self, start: u64, end: u64) {
        require!(
            self.reserved_slot().get().is_none(),
            "A football slot already exists"
        );

        let payment = self.call_value().egld().clone();
        let caller = self.blockchain().get_caller();

        // Get the required deposit
        let court_cost = self.football_court_cost().get();
        require!(payment == court_cost, "Payment must equal the court cost");

        // Create the slot and store it and the caller as participant
        let slot = Slot {
            start,
            end,
            payer: caller.clone(),
            amount: payment.clone(),
            confirmed: false,
        };

        self.reserved_slot().set(Some(slot));
        self.participants().insert(caller.clone());
        self.football_slot_created_event(&caller, start, end, &payment);
    }

    // --- Storage Mappers ---

    // Address of the manager of the football field
    #[view(getFootballFieldManager)]
    #[storage_mapper("football_field_manager_address")]
    fn football_field_manager_address(&self) -> SingleValueMapper<ManagedAddress>;

    // Cost per court / slot
    #[view(getFootballCourtCost)]
    #[storage_mapper("football_court_cost")]
    fn football_court_cost(&self) -> SingleValueMapper<BigUint>;

    // List of participants (addresses)
    #[view(getParticipants)]
    #[storage_mapper("participants")]
    fn participants(&self) -> UnorderedSetMapper<ManagedAddress>;

    #[view(getReservedSlot)]
    #[storage_mapper("reserved_slot")]
    fn reserved_slot(&self) -> SingleValueMapper<Option<Slot<Self::Api>>>;
}
