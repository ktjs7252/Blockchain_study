pragma solidity =0.5.16;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo; //수수료 생성 0.05%
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) { //토큰 주소가 들어와서 새로운 pair 컨트랙트 만들어내는 함수
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');         // 토큰A,B가 같지 않은지 체크
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);  // 토큰 두개를 정렬 (a-b) or (b-a)
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');  //주솟값은 0으로 시작될수 없다. 체크
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient//소유자가 같은 토큰이 이미 가지고 있는지 체크(있디면 수행x)
        bytes memory bytecode = type(UniswapV2Pair).creationCode; //contracts 디렉토리에 있던 토큰페어컨트랙트를 바이트 코드로 가져옴
        bytes32 salt = keccak256(abi.encodePacked(token0, token1)); //해시함수 만들어냄
        assembly { //어셈블리언어로 {}가 있으면 그 안에서만 사용할 수 있다;.
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt) //해시함수abi로pair 만들기
        }
        IUniswapV2Pair(pair).initialize(token0, token1); //만들어낸 토큰두개 초기화 - >토큰두개를 교환할 수 있고 pool을 형성
        getPair[token0][token1] = pair;  //안정성을 위해 그냥 두개다 자료구조 만들어줌
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length); //새로 만들었다는 로그 만듬
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
