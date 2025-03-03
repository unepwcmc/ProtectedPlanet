export default function useCommon() {
    let timer = undefined

    function debounceFn(func, timeout = 700) {
        return (...args) => {
            clearTimeout(timer);
            timer = setTimeout(() => { func.apply(this, args); }, timeout);
        }
    }
    return {
        debounceFn
    }
}