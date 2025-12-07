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

    #[event("set_football_court_cost")]
    fn set_football_court_cost_event(&self, #[indexed] cost: &BigUint);

    #[event("set_football_field_manager")]
    fn set_football_field_manager_event(&self, #[indexed] manager: &ManagedAddress);

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

    #[event("football_slot_canceled")]
    fn football_slot_canceled_event(
        &self,
        #[indexed] initiator: &ManagedAddress,
        #[indexed] start: u64,
        #[indexed] end: u64,
        amount: &BigUint,
    );

    #[event("football_slot_confirmed")]
    fn football_slot_confirmed_event(
        &self,
        #[indexed] initiator: &ManagedAddress,
        #[indexed] start: u64,
        #[indexed] end: u64,
        amount: &BigUint,
    );

    #[event("pay_court")]
    fn pay_court_event(&self, #[indexed] manager: &ManagedAddress, amount: &BigUint);

    // --- Functions ---

    #[only_owner]
    #[endpoint(setFootballFieldManager)]
    fn set_football_field_manager(&self, manager: ManagedAddress) {
        self.football_field_manager_address().set(manager.clone());
        self.set_football_field_manager_event(&manager);
    }

    #[only_owner]
    #[endpoint(setFootballCourtCost)]
    fn set_football_court_cost(&self, cost: BigUint) {
        self.football_court_cost().set(cost.clone());
        self.set_football_court_cost_event(&cost);
    }

    #[endpoint(confirmSlot)]
    fn confirm_slot(&self) {
        let slot_option = self.reserved_slot().get();
        require!(slot_option.is_some(), "No football slot to confirm");

        let slot = slot_option.unwrap();
        let caller = self.blockchain().get_caller();

        require!(
            caller == self.football_field_manager_address().get()
                || caller == self.blockchain().get_owner_address(),
            "Only the football field manager or owner can confirm the slot"
        );

        require!(!slot.confirmed, "Football slot is already confirmed");

        // Mark the slot as confirmed
        let confirmed_slot = Slot {
            start: slot.start,
            end: slot.end,
            payer: slot.payer.clone(),
            amount: slot.amount.clone(),
            confirmed: true,
        };

        self.reserved_slot().set(Some(confirmed_slot));
        self.football_slot_confirmed_event(&caller, slot.start, slot.end, &slot.amount);
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

    #[endpoint(cancelFootballSlot)]
    fn cancel_football_slot(&self) {
        let slot_option = self.reserved_slot().get();
        require!(slot_option.is_some(), "No football slot to cancel");

        let slot = slot_option.unwrap();
        let caller = self.blockchain().get_caller();

        require!(
            caller == slot.payer,
            "Only the slot creator can cancel the football slot"
        );

        require!(!slot.confirmed, "Football slot is already confirmed");

        let now = self.blockchain().get_block_timestamp();
        let time_before_start = if slot.start > now {
            slot.start - now
        } else {
            0
        };

        let refund_amount = if time_before_start < 60 * 60 {
            BigUint::zero()
        } else if time_before_start >= 12 * 60 * 60 && time_before_start < 24 * 60 * 60 {
            slot.amount.clone() / 2u32
        } else {
            slot.amount.clone()
        };

        if refund_amount > BigUint::zero() {
            for participant in self.participants().iter() {
                self.send().direct_egld(&participant, &refund_amount);
            }
        }

        // Clear the slot and participants
        self.reserved_slot().set(None);
        self.participants().clear();
        self.football_slot_canceled_event(&caller, slot.start, slot.end, &slot.amount);
    }

    #[endpoint(payCourt)]
    fn pay_court(&self) {
        let slot_option = self.reserved_slot().get();
        require!(slot_option.is_some(), "No football slot to pay for");

        let slot = slot_option.unwrap();
        let caller = self.blockchain().get_caller();

        require!(
            caller == slot.payer,
            "Only the slot creator can pay for the football court"
        );

        require!(slot.confirmed, "Football slot is not yet confirmed");
        require!(
            self.football_field_manager_address().get() != ManagedAddress::zero(),
            "Football field manager is not set"
        );
        require!(
            self.football_court_cost().get() > BigUint::zero(),
            "Football court cost is not set"
        );

        // Pay the football field manager
        let total_amount =
            self.football_court_cost().get() * BigUint::from(self.participants().len());
        self.send()
            .direct_egld(&self.football_field_manager_address().get(), &total_amount);
        self.pay_court_event(&caller, &total_amount);

        // Clear the slot and participants
        self.reserved_slot().set(None);
        self.participants().clear();
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
