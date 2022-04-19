// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Escrow_optimised {

  address payable public buyer;
  address payable public seller; 

  bool public initiated = false;
  bool public finalized = false;

  // 1: Packing variables into a single slot
  uint public purchaseAmount;
  uint public buyerRequiredEscrow;
  uint public sellerRequiredEscrow;
  uint public totalEscrowAmount;
  uint public buyerEscrowedFunds;
  uint public sellerEscrowedFunds;
  uint256 public purchaseAmountTotal;
  uint256 public partyArequiredFunding; 
  uint256 public partyBrequiredFunding;
  uint256 public mutualEscrowAmount;

  address public partyA; //BUYER
  address public partyB; //SELLER

  bool public buyerHasFunded = false;
  bool public sellerHasFunded = false;

  bool public escrowFullyFunded = false;

  bool public buyerfinalized = false;
  bool public sellerfinalized = false;

  event Terms(uint purchaseAmount, uint totalEscrowAmount, uint BuyerRequiredFunding, uint SellerRequiredFunding);
  event Initiated(address initiator, address buyer, address seller, uint tradeFundsforXfer);
  event FundsReceived(address sender, uint amount);
  event PartyFinalized(address party);
  event EscrowComplete(bool completed, uint buyerReceives, uint sellerReceives);

  function EscrowFunc(
    address payable _buyer,
    address payable _seller,
    uint _purchaseAmount
  ) public {
 
    require((_seller != address(0)) && (_buyer != address(0)) && (_buyer != _seller) && (msg.sender == _seller || msg.sender == _buyer) && (_purchaseAmount != 0) , "Seller and buyer are not the same.");


    escrowFullyFunded = false;

    buyer = _buyer; 
    seller = _seller; 

    initiated = true;

    buyerRequiredEscrow = _purchaseAmount * 2;
    sellerRequiredEscrow = _purchaseAmount;
    totalEscrowAmount = _purchaseAmount * 3;
    purchaseAmount = _purchaseAmount;

    assert(totalEscrowAmount == (buyerRequiredEscrow + sellerRequiredEscrow));

    emit Initiated(msg.sender, buyer, seller, _purchaseAmount);
    emit Terms(purchaseAmount, totalEscrowAmount, buyerRequiredEscrow, sellerRequiredEscrow);
  }

  function Initiate(
    address _counterParty,
    uint256 _purchaseAmount,
    bool _buyingNotSelling // TRUE if Buyer; FALSE if seller;
  )
  public returns
  (bool) {
    purchaseAmountTotal = _purchaseAmount;
    mutualEscrowAmount = _purchaseAmount * 3;
 
    if (_buyingNotSelling == true) {
      partyA = msg.sender; //Buyer
      partyB = _counterParty; //Seller
      partyArequiredFunding = _purchaseAmount * 2;
      partyBrequiredFunding = _purchaseAmount;
 
 
    } else if (_buyingNotSelling == false) {
      partyA = _counterParty; //Buyer
      partyB = msg.sender; //Seller
      partyArequiredFunding = _purchaseAmount;
      partyBrequiredFunding = _purchaseAmount * 2;
 
    } else {
      revert(); // Fallback
    }
 
    initiated = true;
    return true;
  }

  function fundContract(address _funder, uint _amount) public {
    if (_funder == buyer && buyerEscrowedFunds <= buyerRequiredEscrow) {
      uint buyerCurrentFunds = buyerEscrowedFunds;
      buyerEscrowedFunds = buyerCurrentFunds + _amount;
    } 
    if (_funder == seller && sellerEscrowedFunds <= sellerRequiredEscrow) {
      uint sellerCurrentFunds = sellerEscrowedFunds;
      sellerEscrowedFunds = sellerCurrentFunds + _amount;
    }
    checkFundingStatus();
  }

     
  function checkFundingStatus() internal {
    if (buyerEscrowedFunds >= buyerRequiredEscrow) {
      buyerHasFunded = true;
      fundContract(buyer, buyerEscrowedFunds);
    }
    if (sellerEscrowedFunds >= sellerRequiredEscrow) {
      sellerHasFunded = true;
      fundContract(seller, sellerEscrowedFunds);
    }
    if (sellerHasFunded == true && buyerHasFunded == true) {
      escrowFullyFunded = true;
    } else {
      escrowFullyFunded = false;
    }
  }
  
  function buyerFinalize() public {
    require(msg.sender == buyer);
    buyerfinalized = true;
    emit PartyFinalized(msg.sender);
    
    if (sellerfinalized == true) {
      return finalizeTrade();
    }
  }

  function sellerFinalize() public {
    require(msg.sender == seller);
    sellerfinalized = true;
    emit PartyFinalized(msg.sender);

    if (buyerfinalized == true) {
      return finalizeTrade();
    }
  }

  function finalizeTrade() internal {
    require((sellerHasFunded == true) && (buyerHasFunded == true) && (buyerfinalized == true) && (sellerfinalized == true) && (finalized == false));


    uint forSeller = purchaseAmount + sellerEscrowedFunds;

    uint forBuyer = buyerEscrowedFunds - purchaseAmount;

    emit EscrowComplete(finalized, forBuyer, forSeller);

    seller.transfer(forSeller);
    buyer.transfer(forBuyer);

    finalized = true;
    selfdestruct(seller);
  }
}