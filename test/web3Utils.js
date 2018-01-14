const estimateConstructGasWithValue = (target, value, ...args) => {
    return new Promise((resolve, reject) => {
        const web3contract = target.web3.eth.contract(target.abi);
        args.push({
            data: target.unlinked_binary
        });
        const constructData = web3contract.new.getData.apply(web3contract.new, args);
        web3.eth.estimateGas({data: constructData, value: value}, function (err, gas) {
            if (err) {
                reject(err);
            }
            else {
                resolve(gas);
            }
        });
    });
};

const web3async = (that, func, ...args) => {
    return new Promise((resolve, reject) => {
        args.push(
            function (error, result) {
                if (error) {
                    reject(error);
                } else {
                    resolve(result);
                }
            }
        );
        func.apply(that, args);
    });
};

module.exports = {
    web3async: web3async,
    estimateConstructGas: (target, ...args) => {
        args.unshift(0);
        args.unshift(target);
        return estimateConstructGasWithValue.apply(this, args);
    },

    estimateConstructGasWithValue: estimateConstructGasWithValue,

    getBalance: (address) => web3async(web3.eth, web3.eth.getBalance, address)
};