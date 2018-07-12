pragma solidity ^0.4.24;

interface ERC165 {
	/// @notice Query if a contract implements an interface
	/// @param interfaceID The interface identifier, as 
	///  specified in ERC-165
	/// @dev Interface identification is specified in 
	///  ERC-165. This function uses less than 30,000 gas.
	/// @return `true` if the contract implements `interfaceID` 
	///  and `interfaceID` is not 0xffffffff, `false` otherwise
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

// @dev Note: the ERC-165 identifier for this interface is 0xf0b9e5ba
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. This function MUST use 50,000 gas or less. Return of other
    ///  than the magic value MUST result in the transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _from The sending address
    /// @param _tokenId The NFT identifier which is being transfered
    /// @param data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}


contract CheckERC165 is ERC165 {
    mapping (bytes4 => bool) internal supportedInterfaces;

    constructor() public {
        supportedInterfaces[this.supportsInterface.selector] = true;
    }
    
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool){
        return supportedInterfaces[interfaceID];
    }
}

contract TokenERC721 is ERC721, CheckERC165{
    using SafeMath for uint256;
	
	// The address of the contract creator
	address internal creator;
	
	// The highest valid tokenId, for checking if a tokenId is valid
	uint256 internal maxId;
	
	// A mapping storing the balance of each address
	mapping(address => uint256) internal balances;

	// A mapping of burnt tokens, for checking if a tokenId is valid
	// Not needed if your token can't be burnt
	mapping(uint256 => bool) internal burned;
	
	// A mapping of token owners
	mapping(uint256 => address) internal owners;

	// A mapping of the "approved" address for each token
	mapping (uint256 => address) internal allowance;
	
	// A nested mapping for managing "operators"
	mapping (address => mapping (address => bool)) internal authorised;
	
	constructor(uint _initialSupply) public CheckERC165(){
		// Store the address of the creator
		creator = msg.sender;
    
		// All initial tokens belong to creator, so set the balance
		balances[msg.sender] = _initialSupply;
		
		// Set maxId to number of tokens
		maxId = _initialSupply;
		
		//Add to ERC165 Interface Check
		supportedInterfaces[
			this.balanceOf.selector ^
			this.ownerOf.selector ^
		bytes4(keccak256("safeTransferFrom(address,address,uint256"))^
        bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes"))^
			this.transferFrom.selector ^
			this.approve.selector ^
			this.setApprovalForAll.selector ^
			this.getApproved.selector ^
			this.isApprovedForAll.selector
		] = true;

	}

	function isValidToken(uint256 _tokenId) internal view returns(bool){
		return _tokenId != 0 && _tokenId <= maxId && !burned[_tokenId];
	}
	
	function balanceOf(address _owner) external view returns (uint256){
		return balances[_owner];
	}

	function ownerOf(uint256 _tokenId) public view returns(address){
		require(isValidToken(_tokenId));
    
		if(owners[_tokenId] != 0x0 ){
			return owners[_tokenId];
		}else{
			return creator;
		}
	}	
	
	function issueTokens(uint256 _extraTokens) public{ 
    
		// Make sure only the contract creator can call this
		require(msg.sender == creator);
		balances[msg.sender] = balances[msg.sender].add(_extraTokens);
		maxId = maxId.add(_extraTokens);
    
		//We have to emit an event for each token that gets created
		for(uint i = maxId - _extraTokens + 1; i <= maxId; i++){
			emit Transfer(0x0, creator, i);
		}
	}
	
	//function setApprovalForAll(address _operator, bool _approved) external;
	
	function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
		return authorised[_owner][_operator];
	}
	
	function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
		return authorised[_owner][_operator];
	}
	
	event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
	
	function setApprovalForAll(address _operator, bool _approved) external {
		emit ApprovalForAll(msg.sender,_operator, _approved);
		authorised[msg.sender][_operator] = _approved;
	}
	
	//function approve(address _approved, uint256 _tokenId) external payable;
	
	//function getApproved(uint256 _tokenId) external view returns (address);
	
	function getApproved(uint256 _tokenId) external view returns (address) {
		require(isValidToken(_tokenId));
		return allowance[_tokenId];
	}
	
	function approve(address _approved, uint256 _tokenId)  external{
		address owner = ownerOf(_tokenId);
		require( owner == msg.sender                    
		|| authorised[owner][msg.sender]                
		);
		
		emit Approval(owner, _approved, _tokenId);
		allowance[_tokenId] = _approved;
	}
	
	function transferFrom(address _from, address _to, uint256 _tokenId) public {
		address owner = ownerOf(_tokenId);
		require ( owner == msg.sender
		|| allowance[_tokenId] == msg.sender
		|| authorised[owner][msg.sender]
		);
		
		require(owner == _from);
		require(_to != 0x0);
		emit Transfer(_from, _to, _tokenId);
		owners[_tokenId] = _to;
		balances[_from]--;
		balances[_to]++;
		
		if(allowance[_tokenId] != 0x0){
			delete allowance[_tokenId];
		}
	}
	
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public{
		transferFrom(_from, _to, _tokenId);
		
		uint32 size;
		assembly {
			size := extcodesize(_to)
		}
		
		if(size > 0){
			ERC721TokenReceiver receiver = ERC721TokenReceiver(_to);
			require(receiver.onERC721Received(_from,_tokenId,data) == bytes4(keccak256("onERC721Received(address,uint256,bytes)")));
		}
	}
		
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
		safeTransferFrom(_from,_to,_tokenId,"");
	}
	
}	