// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Escrow_original {

  address payable public buyer;
  address payable public seller; 
  uint public purchaseAmount = 0;


  bool public initiated = false;
  bool public finalized = false;

  uint public buyerRequiredEscrow = 0;
  uint public sellerRequiredEscrow = 0;
  uint public totalEscrowAmount = 0;
  uint public totalAmount = 0;
  uint public TotalRequiredEscrow = 0;

  uint public buyerEscrowedFunds = 0;
  uint public sellerEscrowedFunds = 0;

  uint256 public purchaseAmountTotal;

  uint256 public partyArequiredFunding; 
  uint256 public partyBrequiredFunding;

  address public partyA; //BUYER
  address public partyB; //SELLER

  uint256 public mutualEscrowAmount;

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
 
    require(_seller != address(0));
    require(_buyer != address(0));
    require(_buyer != _seller, "Seller and buyer are not the same, they have different accounts and do not share the same one. We are writing this error message to let you know that the buyer and the seller are not the same. Perhaps you made a typo or you are just trying to be very descriptive. Please try again with a shorter string for reason.");

    require(msg.sender == _seller || msg.sender == _buyer);

    require(_purchaseAmount != 0);

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
      initiateselling(_counterParty,_purchaseAmount);
 
 
    } else if (_buyingNotSelling == false) {
      initiatebuying(_counterParty,_purchaseAmount);
 
    } else {
      revert(); // Fallback
    }
 
    initiated = true;
    return true;
  }
 
  function initiateselling(address c, uint256 p) public {
      partyA = msg.sender; //Buyer
      partyB = c; //Seller
      partyArequiredFunding = p * 2;
      partyBrequiredFunding = p;
  }
 
  function initiatebuying(address c, uint256 p) public {
      partyA = c; //Buyer
      partyB = msg.sender; //Seller
      partyArequiredFunding = p;
      partyBrequiredFunding = p * 2;
  }


  fallback() external payable {
    address _funder = msg.sender;
    uint _amount = msg.value;
    fundContract(_funder, _amount);
    emit FundsReceived(_funder, _amount);
  }

  receive() external payable {
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

  function getPurchaseAmount() public view returns(uint){
    return purchaseAmount;
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
    require(sellerHasFunded == true);
    require(buyerHasFunded == true);

    require(buyerfinalized == true);
    require(sellerfinalized == true);

    require(finalized == false);

    uint forSeller = purchaseAmount + sellerEscrowedFunds;

    uint forBuyer = buyerEscrowedFunds - purchaseAmount;

    emit EscrowComplete(finalized, forBuyer, forSeller);

    seller.transfer(forSeller);
    buyer.transfer(forBuyer);

    finalized = true;
    selfdestruct(seller);
  }
}