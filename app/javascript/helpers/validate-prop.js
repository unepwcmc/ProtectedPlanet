/**
 * validateProp can be used as a simple prop validator in Vue components.
 *
 *    Example usage:
 *
 *    let myProp = {
 *        name: "bob",
 *        age: 99,
 *        cool: true,
 *        children: [
 *            {
 *                name: "sam",
 *                age: 75
 *            },
 *            {
 *                name: "dan",
 *                age: 77
 *            }
 *        ]
 *    }
 *
 *    let myRules = {
 *        name: 'string',
 *        age: 'number',
 *        cool: 'boolean',
 *        children: {
 *            name: 'string',
 *            age: 'number'
 *        }
 *    }
 *
 *    validateProp(myProp, myRules)
 * 
 */

const VALIDATORS = {
    array: value => value.isArray(),
    bigint: value => typeof value === 'bigint',
    boolean: value => typeof value === 'boolean',
    null: value => value === null,
    number: value => typeof value === 'number',
    string: value => typeof value === 'string',
    symbol: value => typeof value === 'symbol',
    undefined: value => value === undefined,
}
export default function validateProp (obj, options) {
    if (options) {
        for (let key in options) {
            const value = obj[key]
            const validator = options[key]
            if (typeof validator === 'object') {
                if (validateProp(value, validator) === false) {
                    // return false if the recursive call returns false when the value is also an object
                    return false
                }
            } else if (value.isArray()) {
                for (let index in value) {
                    if (validateProp(value[index], validator) === false) {
                        // return false if the recursive call returns false when the value is also an object
                        return false
                    }
                }
            } else if (obj.hasOwnProperty(key) && VALIDATORS[validator](value)) {
                // continue if the object this is called has the option's key and is an instance of the value
            } else {
                return false
            }
        }
    }
    return true
}