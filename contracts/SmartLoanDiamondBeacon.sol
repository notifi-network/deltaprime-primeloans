// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: c5c938a0524b45376dd482cd5c8fb83fa94c2fcc;
pragma solidity 0.8.17;

import {DiamondStorageLib} from "./lib/DiamondStorageLib.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";

/**
 * @title SmartLoanDiamondBeacon
 * A contract that is authorised to borrow funds using delegated credit.
 * It maintains solvency calculating the current value of assets and borrowings.
 * In case the value of assets held drops below certain level, part of the funds may be forcibly repaid.
 * It permits only a limited and safe token transfer.
 *
 */

contract SmartLoanDiamondBeacon {
    constructor(address _contractOwner, address _diamondCutFacet) payable {
        DiamondStorageLib.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](3);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        functionSelectors[1] = IDiamondCut.pause.selector;
        functionSelectors[2] = IDiamondCut.unpause.selector;
        cut[0] = IDiamondCut.FacetCut({
        facetAddress : _diamondCutFacet,
        action : IDiamondCut.FacetCutAction.Add,
        functionSelectors : functionSelectors
        });
        DiamondStorageLib.diamondCut(cut, address(0), "");
    }

    function implementation() public view returns (address) {
        return address(this);
    }

    function getStatus() public view returns(bool) {
        DiamondStorageLib.DiamondStorage storage ds = DiamondStorageLib.diamondStorage();
        return ds._active;
    }

    function implementation(bytes4 funcSignature) public view notPausedOrUpgrading returns (address) {
        DiamondStorageLib.DiamondStorage storage ds;
        bytes32 position = DiamondStorageLib.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[funcSignature].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        return facet;
    }


    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        address facet = implementation(msg.sig);
        // Execute external function from facet using delegatecall and return any value.
        assembly {
        // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
        // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
        // get any return value
            returndatacopy(0, 0, returndatasize())
        // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return (0, returndatasize())
            }
        }
    }

    function proposeBeaconOwnershipTransfer(address _newOwner) external {
        DiamondStorageLib.enforceIsContractOwner();
        require(_newOwner != msg.sender, "Can't propose oneself as a contract owner");
        DiamondStorageLib.setProposedOwner(_newOwner);

        emit OwnershipProposalCreated(msg.sender, _newOwner);
    }

    function acceptBeaconOwnership() external {
        require(DiamondStorageLib.proposedOwner() == msg.sender, "Only a proposed user can accept ownership");
        DiamondStorageLib.setContractOwner(msg.sender);
        DiamondStorageLib.setProposedOwner(address(0));

        emit OwnershipProposalAccepted(msg.sender);
    }

    modifier notPausedOrUpgrading() {
        // diamondCut(); unpause()
        if(msg.sig != 0x1f931c1c && msg.sig != 0x3f4ba83a) {
            DiamondStorageLib.DiamondStorage storage ds = DiamondStorageLib.diamondStorage();
            require(ds._active, "ProtocolUpgrade: paused.");
        }
        _;
    }

    /**
     * @dev emitted after creating a ownership transfer proposal by the owner
     * @param owner address of the current owner
     * @param proposed address of the proposed owner
     **/
    event OwnershipProposalCreated(address indexed owner, address indexed proposed);

    /**
     * @dev emitted after accepting a ownership transfer proposal by the new owner
     * @param newOwner address of the new owner
     **/
    event OwnershipProposalAccepted(address indexed newOwner);
}