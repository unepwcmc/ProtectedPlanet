import { KEYCODES } from './keyboard-helpers'

const INPUT_SELECTORS = 'select, input, textarea, button, a, [tabindex]:not([tabindex="-1"])'

const DISABLED_TAB_VALUE = -5

export const TAB_KEYCODE = 9

export const isTabForward = e => e.keyCode === KEYCODES.tab && !e.shiftKey

export const isTabBackward = e => e.keyCode === KEYCODES.tab && e.shiftKey

export const getInputs = el => el.querySelectorAll(INPUT_SELECTORS)

export const preventTab = e => {
  if (e.keyCode === KEYCODES.tab) {
    e.preventDefault()
  }
}

export const disableTabbing = el => {
  Array.prototype.forEach.call(getInputs(el), input => {
    input.tabIndex = DISABLED_TAB_VALUE
  })
}

export const reenableTabbing = el => {
  Array.prototype.forEach.call(el.querySelectorAll(`[tabindex='${DISABLED_TAB_VALUE}']`), input => {
    input.tabIndex = 0
  })
}

export const getRadioToFocus = optionEls => {
  let radioToFocus = optionEls[0].querySelector('input')

  for (let i = 0; i < optionEls.length; i++) {
    const input = optionEls[i].querySelector('input')

    if(optionEls[i].style.display !== 'none' && (!radioToFocus || input.checked)) {
      radioToFocus = input
    }
  }

  return radioToFocus
}