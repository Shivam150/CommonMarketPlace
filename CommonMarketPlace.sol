// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC_721 is ERC721 {
    constructor() ERC721("MyToken1", "MTK") {}

    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }
}

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC_1155 is ERC1155 {
    constructor() ERC1155("") {}

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public
    {
        _mintBatch(to, ids, amounts, data);
    }
}



contract ERC_1155_721_MarketPlace
{
    uint tokenId;
    ERC_1155 token2 = new ERC_1155();
    ERC_721 token1 = new ERC_721();

    struct Details{

        string ERCType;

        address Owner ;

        uint OnSellTokenId; 
        uint totalAmountOfTokens;
        uint OnSellAmountsOfTokens;
        uint RemainingAmountOfTokens;
        uint TokenSellPrice; 

        address Buyer;

        uint BuyedTokenId;
        uint BuyedAmount;

    }

    mapping(address => mapping(uint => Details)) public details;
    mapping(uint  => address) private TokenOwner;
    mapping(address => mapping(uint  => uint)) private NftTokenPrice;


    constructor(address ERC1155Address, address ERC721Address)
    {
        token2 = ERC_1155(ERC1155Address);
        token1 = ERC_721(ERC721Address);
    }


    function CommonMint(address _owner ,uint256 _quantity) public
    {
        uint _tokenId = tokenId++;

        require(msg.sender == _owner,"Only owner can mint");

        Details memory detail = details[msg.sender][_tokenId];

        detail.Owner = _owner;

        if(_quantity == 1 && _quantity >0)
        {
            detail.ERCType = "721";

            token1.safeMint(_owner,_tokenId);

            TokenOwner[_tokenId] = _owner;
        }
        else
        {
            detail.ERCType = "1155";

            token2.mint(_owner,_tokenId,_quantity,"");

            detail.totalAmountOfTokens = token2.balanceOf(_owner,_tokenId);

            detail.RemainingAmountOfTokens = token2.balanceOf(_owner,_tokenId);

            TokenOwner[_tokenId] = _owner;

        }

        details[msg.sender][_tokenId] = detail;
        
    }



    function SetOnSell(address _owner,uint _tokenId ,uint _tokenPrice,uint _quantity) public
    {
        if(_quantity == 1 && _quantity >0)
        {
            require(msg.sender == token1.ownerOf(_tokenId),"Owner Authorization Needed");

            require(token1.ownerOf(_tokenId) == _owner,"Enter Valid tokenId");

            Details memory detail = details[msg.sender][_tokenId];

            NftTokenPrice[_owner][_tokenId] = _tokenPrice;

            detail.TokenSellPrice = NftTokenPrice[_owner][_tokenId];

            detail.OnSellTokenId = _tokenId;
            
            details[msg.sender][_tokenId] = detail;
        }
        else{

            require(msg.sender == details[msg.sender][_tokenId].Owner,"Owner Authorization Needed");

            require(TokenOwner[_tokenId] == _owner,"Enter Valid tokenId");

            require(token2.balanceOf(_owner,_tokenId) >= _quantity,"Insufficient balance to set On sell");

            Details memory detail = details[msg.sender][_tokenId];

            detail.OnSellAmountsOfTokens = _quantity;

            detail.OnSellAmountsOfTokens = _tokenId;

            details[msg.sender][_tokenId] = detail;
            
        }

    }


    function Buy(address _owner , uint _tokenId,uint _quantity) public
    {
        if(_quantity == 1 && _quantity >0)
        {
            require( NftTokenPrice[_owner][_tokenId] > 0,"Not in sell");

            Details memory detail = details[_owner][_tokenId];

            token1.safeTransferFrom(_owner,msg.sender,_tokenId);

            detail.Buyer = msg.sender;

            detail.BuyedTokenId = _tokenId;

            details[_owner][_tokenId] = detail;

        }
        else
        {
            require(details[_owner][_tokenId].setAmountsOfTokens > 0 ,"not in sell");

            require(details[_owner][_tokenId].setAmountsOfTokens >= _quantity ,"Insufficient amount to buy");

            Details memory detail = details[_owner][_tokenId];

            token2.safeTransferFrom(_owner,msg.sender,_tokenId,_quantity,"");

            detail.Buyer = msg.sender;

            detail.RemainingAmountOfTokens -= _quantity;

            detail.OnSellAmountsOfTokens -= _quantity;

            detail.BuyedAmount += _quantity;

            detail.OnSellAmountsOfTokens = _tokenId;
            
            details[_owner][_tokenId] = detail;

        }

    }

}
