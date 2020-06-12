pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

contract SupplyChainManager {
    address manager;
    constructor() public {
        manager = msg.sender;
    }
    struct Manufacturer {
        string companyName;
        string companyAddress;
        uint32 companyPrefix;
    } 
    mapping (address => Manufacturer) manufacturers;
    mapping (uint32 => address) companyPrefixToAddress;
    mapping (address => string) relation;
    enum ProductStatus { owned, shipped, unknown }
    struct Credential {
        bytes X;
        uint y;
        uint r1;
    }
    struct Product {
        address owner;
        address recipient;
        ProductStatus status;
        int nTransferred;
        address[] traces;
        mapping (address => Credential) credential;
    }
    mapping (uint96 => Product) products;
    modifier onlyOwner(uint96 epc) {
        require (msg.sender == products[epc].owner,
        "Only the product'owner can call this function"
        );
        _;
    }
    
    // Party1: ManufacturersManager
    function enrollManufacturer(string memory companyName, string memory companyAddress, 
            uint32 companyPrefix, address account) public {
        if (msg.sender == manager){
            manufacturers[account].companyName = companyName;
            manufacturers[account].companyAddress = companyAddress;
            manufacturers[account].companyPrefix = companyPrefix;
            companyPrefixToAddress[companyPrefix] = account;
        }
    }
    function checkManufacturer(uint96 epc, address account) public view returns(bool) {
        uint32 companyPrefix_msg = getCompanyPrefixFrom(epc);
        if (companyPrefix_msg == manufacturers[account].companyPrefix) {
            return true;
        }else {
            return false;
        }
    }
    function getManufacturerAddress (uint96 epc) public view returns (address) {
        uint32 cp = getCompanyPrefixFrom(epc);
        return companyPrefixToAddress[cp];
    }
    function getCompanyPrefixFrom (uint96 epc) public pure returns (uint32) {
         uint32 prefix = uint32(uint40(bytes5(bytes12(epc))));  // 96 = 8 + 32(prefix) + 46
         return prefix;
     }
     
     // Party2: OwnershipManager ( ProductsManager )
    function enrollProduct(uint96 epc, string memory name, bytes memory X, uint y, uint r1) public {
        if (checkManufacturer(epc,msg.sender)) {
            products[epc].owner = msg.sender;
            products[epc].status = ProductStatus.owned;
            products[epc].nTransferred = 1;
            products[epc].traces.push(msg.sender);
            relation[msg.sender] = name;
            products[epc].credential[msg.sender].X = X;
            products[epc].credential[msg.sender].y = y;
            products[epc].credential[msg.sender].r1 = r1;}
    }
    function shipProduct(uint96 epc, address recipient) public onlyOwner(epc) {
        products[epc].recipient = recipient;
        products[epc].status = ProductStatus.shipped;
    }   
    function receiveProduct (uint96 epc, string memory name, bytes memory X, uint y, uint r1) public {
        if(products[epc].recipient == msg.sender && products[epc].owner != msg.sender){
            products[epc].owner = msg.sender;
            products[epc].recipient = address(0);
            products[epc].status = ProductStatus.owned;
            products[epc].nTransferred = products[epc].nTransferred + 1;
            products[epc].traces.push(msg.sender);
            relation[msg.sender] = name;
            products[epc].credential[msg.sender].X = X;
            products[epc].credential[msg.sender].y = y;
            products[epc].credential[msg.sender].r1 = r1;}
    }    
    
    // Part3: Query Manager Information
    function getManager() public view returns (address) {
        return manager;
    }
    
    // Part4: Query Manufacturer Infomation
    function getComapnyName(address account) public view returns (string memory){
        return manufacturers[account].companyName;
    }    
    function getCompanyAddress(address account) public view returns (string memory){
        return manufacturers[account].companyAddress;
    }  
    function getCompanyPrefix(address account) public view returns (uint32){
        return manufacturers[account].companyPrefix;
    }
    
    // Part5: Query Product Infomation
    function getCurrentOwner (uint96 epc) public view returns (address) {
        return products[epc].owner;
    }
    function getRecipient(uint96 epc) public view returns (address) {
        return products[epc].recipient;
    }
    function getProductStatus (uint96 epc) public view returns (ProductStatus) {
        return products[epc].status;
    }
    function getTotals(uint96 epc) public view returns (int){
        return products[epc].nTransferred;
    }
    function getTrances(uint96 epc) public view returns (address[] memory ){
        return products[epc].traces;
    }
    function getCredential(uint96 epc, address participant) public view returns (bytes memory X, uint y, uint r1){
        return (products[epc].credential[participant].X,
        products[epc].credential[participant].y,
        products[epc].credential[participant].r1);
    }
    function getRelation(address account) public view returns(string memory){
        return relation[account];
    }
}
