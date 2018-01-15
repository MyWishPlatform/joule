module.exports = {
    printNextContracts: async (joule, count) => {
        if (typeof count === 'undefined') {
            count = Number(await joule.length());
        }

        const result = await joule.getTop(count);

        if (result[0].length === 0) {
            console.info('No contracts');
            return;
        }

        for (let i = 0; i < result[0].length; i++) {
            console.info(result[0][i], Number(result[1][i]), Number(result[2][i]), Number(result[3][i]));
        }
    },

    /**
     * Prints 'Log(string what, uint how)' events
     */
    printTxLogs: (tx) => {
        tx.logs
            .filter(log => log.event === 'Log')
            .map(({args}) => `Log(what: \'${args.what}\', how: \'${Number(args.how)}\')`)
            .forEach(log => console.info(log));
    }
};