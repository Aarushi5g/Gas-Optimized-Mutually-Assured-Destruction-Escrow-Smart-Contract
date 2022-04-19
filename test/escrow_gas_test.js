let Escrow_gas = artifacts.require("Escrow_gas");

contract ("Escrow_gas", (accounts)=>{
    let accountB = accounts[0];
    let accountS = accounts[1];
    console.log("Account1 "+accountB);
    console.log("Account2 "+accountS);
    
    let instance;
    beforeEach( async ()=>{
        let instance = await Escrow_gas.deployed();
    });
    it("testing the contract", async ()=>{
        let instance = await Escrow_gas.deployed();
        const amount = 3;
      await instance.Initiate(accounts[1], amount, 'true', { from: accounts[0] });
        const init = await instance.initiated.call();
      const fnl = await instance.finalized.call();
      assert.equal(init, true);
      assert.equal(fnl, false);
    });

});