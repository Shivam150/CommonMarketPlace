// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC_721 is ERC721 {

    address  _MarketAddress;

    constructor() ERC721("MyToken1", "MTK") {}

    function safeMint(address to, uint256 tokenId) public {
        require(_MarketAddress == msg.sender,"Only Market Can Mint");
        _safeMint(to, tokenId);
    }

    function Setter721(address MarketAddress) external  
    {
       _MarketAddress = MarketAddress;
    }

}

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC_1155 is ERC1155 {

    address public _MarketAddress;

    constructor() ERC1155("") {}


    function mint(address account, uint256 id, uint256 amount, bytes memory data) public
    {
        require(msg.sender == _MarketAddress,"Only Market Can Mint");
        _mint(account, id, amount, data);
    }

    function Setter1155(address MarketAddress) external
    {
        _MarketAddress = MarketAddress;
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts,bytes memory data) public
    {
        _mintBatch(to, ids, amounts, data);
    }
}



contract Common_MarketPlace
{
    address marketAddress = address(this); 

    uint private HighestBidPrice;

    address User ;

    uint TokenId;

    uint Royalty;

    uint Time;

    uint tokenId;

    ERC_1155 token2 = new ERC_1155();
    ERC_721 token1 = new ERC_721();

    struct Details{

        string ERCType;
        address Owner ;
        uint OnSellTokenId; 
        uint OnSellAmountsOfTokens;
        uint RemainingAmountOfTokens;
        uint TokenSellPrice;
        uint PriceAmount;
        uint OnBidTokenId; 
        uint Wallet; 
    }

    mapping(address => mapping(uint => Details)) public details;
    mapping(address => uint) public Creater;
    mapping(uint  => address) private TokenOwner;
    mapping(address => mapping(uint => uint)) private MarketPlace;
    mapping(address => mapping(uint  => uint)) private NftTokenPrice;


    constructor(address ERC1155Address, address ERC721Address)
    {
        token2 = ERC_1155(ERC1155Address);
        token1 = ERC_721(ERC721Address);
        token1.Setter721(marketAddress);
        token2.Setter1155(marketAddress);
    }


    function CommonMint(address _owner ,uint256 _Supply,uint _Royalty) public
    {
        Royalty = _Royalty;

        uint _tokenId = tokenId++;

        require(msg.sender == _owner,"Owner Authorization needed");

        Details memory detail = details[msg.sender][_tokenId];

        detail.Owner = _owner;

        if(_Supply == 1 && _Supply >0)
        {
            detail.ERCType = "721";

            token1.safeMint(_owner,_tokenId);

            TokenOwner[_tokenId] = _owner;
        }
        else
        {
            detail.ERCType = "1155";

            token2.mint(_owner,_tokenId,_Supply,"");

            detail.RemainingAmountOfTokens = token2.balanceOf(_owner,_tokenId);

            TokenOwner[_tokenId] = _owner;

        }

        details[msg.sender][_tokenId] = detail;
        
    }



    function SetOnSell(address _owner,uint _tokenId ,uint _tokenPrice,uint _Supply) public
    {
        if(_Supply == 1 &&_Supply >0)
        {
            require(msg.sender == token1.ownerOf(_tokenId),"Only Token Owner Can Set On Sell");

            require(token1.ownerOf(_tokenId) == _owner,"Enter Valid tokenId");

            Details memory detail = details[msg.sender][_tokenId];

            NftTokenPrice[_owner][_tokenId] = _tokenPrice;

            detail.TokenSellPrice = NftTokenPrice[_owner][_tokenId];

            detail.OnSellAmountsOfTokens = _Supply;

            detail.OnSellTokenId = _tokenId;
            
            details[msg.sender][_tokenId] = detail;
        }
        else{

            require(msg.sender == TokenOwner[_tokenId],"Only Token Owner Can Set On Sell");

            require(TokenOwner[_tokenId] == _owner,"Enter Valid tokenId");

            require(token2.balanceOf(_owner,_tokenId) >= _Supply,"Insufficient Supply to set On sell");

            Details memory detail = details[msg.sender][_tokenId];

            NftTokenPrice[_owner][_tokenId] = _tokenPrice;

            detail.TokenSellPrice = NftTokenPrice[_owner][_tokenId];

            detail.OnSellAmountsOfTokens = _Supply;

            detail.OnSellTokenId = _tokenId;

            details[msg.sender][_tokenId] = detail;
            
        }

    }

    function VestNft(uint _tokenId , uint _Supply , uint timeInMinute)  public
    {
        // require(msg.sender == );
        require(TokenOwner[_tokenId] == msg.sender,"Enter Valid tokenId");

        require( NftTokenPrice[msg.sender][_tokenId] > 0,"Not in sell");

        require(details[msg.sender][_tokenId].OnSellAmountsOfTokens >= _Supply ,"Insufficient Supply in sell");

        // MarketPlace[address(this)][_tokenId] = _quantity;

        if(_Supply == 1 && _Supply >0)
        {
             token1.safeTransferFrom(msg.sender,address(this) ,_tokenId);
        }
        else{
            token2.safeTransferFrom(msg.sender,address(this), _tokenId, _Supply, "");
            MarketPlace[address(this)][_tokenId] = _Supply;
        }

        // MarketPlace[address(this)][_tokenId] = _quantity;

        Details memory detail = details[msg.sender][_tokenId];

        detail.OnSellTokenId -= _tokenId;

        detail.OnSellAmountsOfTokens -= _Supply;

        uint _time  = block.timestamp + timeInMinute*1 minutes;

        Time = _time ;

        details[msg.sender][_tokenId] = detail;
        
    }


    function Redeam(address _owner , uint _tokenId) public 
    {
            uint  _Supply = MarketPlace[address(this)][_tokenId];

            require(msg.sender == _owner, "Only Owner can Redeam");
            
            require(TokenOwner[_tokenId] == _owner,"Enter Valid tokenId");

            require(MarketPlace[address(this)][_tokenId] > 0,"Nft Not Vested");

            require(Time <= block.timestamp,"locked");

             if( _Supply == 1 &&  _Supply >0)
            {
               token1.safeTransferFrom(address(this),_owner,_tokenId);
            }
            else{
               token2.safeTransferFrom(address(this), _owner, _tokenId, _Supply, "");
            } 

            // MarketPlace[address(this)][_tokenId] -= _quantity;

            Details memory detail = details[_owner][_tokenId];

            detail.OnSellTokenId  += _tokenId;

            detail.OnSellAmountsOfTokens +=  _Supply; 

            details[_owner][_tokenId] = detail; 

    }

     function SetOnBid(address _owner ,uint _tokenId ,uint _tokenPrice) public
    {
        require(msg.sender == token1.ownerOf(_tokenId),"Owner Authorization Needed");
        require( token1.ownerOf(tokenId) == _owner,"Enter Valid tokenId");

        Details memory detail = details[_owner][_tokenId];

        detail.PriceAmount = _tokenPrice;
        detail.OnBidTokenId = _tokenId;

       details[_owner][tokenId] = detail;

    }


     function BidOnNft(address user , uint Amount, uint _tokenId) public
    {  

       require(msg.sender == token1.ownerOf(tokenId),"Owner Authorization needed");
       require(Amount != HighestBidPrice,"Price given");
       require(details[msg.sender][_tokenId].OnBidTokenId == _tokenId,"Token is not in Bid");
       require(Amount > details[msg.sender][_tokenId].PriceAmount,"Amount must be Greater than");
       require(user != token1.ownerOf(tokenId),"Owner can not Bid his Own Nft");

        if(Amount > HighestBidPrice)
        {
            User = user;
            TokenId = tokenId;
            HighestBidPrice = Amount;
        }

    }


    function FetchHighestBit() public view returns(uint)
    {
        return HighestBidPrice;
    }

     function EndAuction() public
    {
            Details memory detail= details[msg.sender][TokenId];
            require(msg.sender == token1.ownerOf(TokenId),"Only token owner can End Auction");
            // detail.TokenId= 0;

            detail.Owner =  0x0000000000000000000000000000000000000000;

            detail.Wallet += HighestBidPrice;

            details[msg.sender][TokenId] = detail;

            // NftToken[User].TokenId = 0;
            // NftToken[User].PriceAmount = 0;

            Details memory detail2 = details[User][TokenId];

            // detail2.TokenId = TokenId;
            detail2.Owner = User;
            
            details[User][TokenId] = detail2;
    }



    function Buy(address _owner , uint _tokenId,uint  _Supply) public payable 
    {
        require(msg.value != 0,"Payment amount can not be zero");

        uint PayAmount = msg.value;

        if( _Supply == 1 && _Supply >0)
        {
            require( NftTokenPrice[_owner][_tokenId] > 0,"Not in sell");

            require(PayAmount == NftTokenPrice[_owner][_tokenId],"Invalid Payment Amount");

            Details memory detail = details[_owner][_tokenId];

            Details memory Buyer = details[msg.sender][_tokenId];

            token1.safeTransferFrom(_owner,msg.sender,_tokenId);

            uint _Royalty = (msg.value)*Royalty/100;

            PayAmount -= _Royalty;

            Creater[address(this)] += _Royalty;

            detail.Wallet += PayAmount;

            Buyer.Owner = msg.sender;

            TokenOwner[_tokenId] = msg.sender;

            details[_owner][_tokenId] = detail;
            details[msg.sender][_tokenId] = Buyer;

        }
        else
        {
            require(details[_owner][_tokenId].OnSellAmountsOfTokens > 0 ,"not in sell");

            require(details[_owner][_tokenId].OnSellAmountsOfTokens >=  _Supply ,"Insufficient amount to buy");

            require(PayAmount == NftTokenPrice[_owner][_tokenId],"Invalid Payment Amount");

            Details memory detail = details[_owner][_tokenId];

            Details memory Buyer = details[msg.sender][_tokenId];

            token2.safeTransferFrom(_owner,msg.sender,_tokenId, _Supply,"");

            uint _Royalty = PayAmount*Royalty/100;

            PayAmount -= _Royalty;

            Creater[address(this)] += _Royalty;

            detail.Wallet += PayAmount;

            Buyer.Owner = msg.sender;


            detail.RemainingAmountOfTokens -= _Supply;

            detail.OnSellAmountsOfTokens -=  _Supply;

            Buyer.Owner = msg.sender;

            TokenOwner[_tokenId] = msg.sender;
            
            details[_owner][_tokenId] = detail;

            details[msg.sender][_tokenId] = Buyer;

        }

    }

}