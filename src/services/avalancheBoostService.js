import {BehaviorSubject, combineLatest, Subject} from 'rxjs';
import config from '../config';
import {formatUnits, fromWei} from "../utils/calculate";
import DEPOSIT_REWARDER from '/artifacts/contracts/interfaces/IDepositRewarder.sol/IDepositRewarder.json'

const ethers = require('ethers');

export default class AvalancheBoostService {
    avalancheBoostUnclaimedAmounts$ = new BehaviorSubject(null);
    avalancheBoostAprs$ = new BehaviorSubject(null);

    emitRefreshAvalancheBoostData(provider, address) {
        this.updateAvalancheBoostData(provider, address);
    }

    observeAvalancheBoostUnclaimed() {
        return this.avalancheBoostUnclaimedAmounts$.asObservable();
    }

    observeAvalancheBoostRates() {
        return this.avalancheBoostAprs$.asObservable();
    }

    async updateAvalancheBoostData(provider, walletAddress) {
        const rewardsConfig = config.AVALANCHE_BOOST_CONFIG;
        const poolsAssets = Object.keys(rewardsConfig);

        let poolRates = {};
        const unclaimed = {};

        const redstonePriceDataRequest = fetch(config.redstoneFeedUrl).then(
            response => {
                response.json().then(
                    redstonePriceData => {
                        combineLatest(
                            poolsAssets.map(el => fetchRate(el))
                        ).subscribe(
                            (rates) => {
                                poolsAssets.forEach(
                                    (asset, i) => {
                                        const price = redstonePriceData[rewardsConfig[asset].rewardToken] ? redstonePriceData[rewardsConfig[asset].rewardToken][0].dataPoints[0].value : 0;
                                        poolRates[asset] = price * formatUnits(rates[i], config.ASSETS_CONFIG[rewardsConfig[asset].rewardToken].decimals);
                                    }
                                );
                                this.avalancheBoostAprs$.next(poolRates);
                            }
                        );
                    }
                )
            }
        );

        combineLatest(
            poolsAssets.map(el => fetchEarned(el))
        ).subscribe(
            (earned) => {
                poolsAssets.forEach(
                    (asset, i) => {
                        unclaimed[asset] = formatUnits(earned[i], config.ASSETS_CONFIG[rewardsConfig[asset].rewardToken].decimals);
                    }
                );

                console.log('unclaimed: ', unclaimed)

                this.avalancheBoostUnclaimedAmounts$.next(unclaimed);
            }
        );

        async function fetchRate(poolAsset) {
            const rewarderContract = new ethers.Contract(rewardsConfig[poolAsset].depositRewarderAddress, DEPOSIT_REWARDER.abi, provider.getSigner());

            return rewarderContract.rewardRate();
        }

        async function fetchEarned(poolAsset) {
            const rewarderContract = new ethers.Contract(rewardsConfig[poolAsset].depositRewarderAddress, DEPOSIT_REWARDER.abi, provider.getSigner());

            return rewarderContract.earned(walletAddress);
        }
    }
};