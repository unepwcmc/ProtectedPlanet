function debounceFn(func, timeout = 700) {
    return (...args) => {
        clearTimeout(this.timer);
        this.timer = setTimeout(() => { func.apply(this, args); }, timeout);
    }
}

export default function useCommon() {
    return {
        debounceFn
    }
}