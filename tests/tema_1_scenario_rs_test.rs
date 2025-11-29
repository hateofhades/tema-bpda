use multiversx_sc_scenario::imports::*;

fn world() -> ScenarioWorld {
    let mut blockchain = ScenarioWorld::new();

    // blockchain.set_current_dir_from_workspace("relative path to your workspace, if applicable");
    blockchain.register_contract("mxsc:output/tema-1.mxsc.json", tema_1::ContractBuilder);
    blockchain
}

#[test]
fn empty_rs() {
    world().run("scenarios/tema_1.scen.json");
}
