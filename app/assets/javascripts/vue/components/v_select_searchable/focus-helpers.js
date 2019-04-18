var INPUT_SELECTORS = 'select, input, textarea, button, a, [tabindex]:not([tabindex="-1"])'
var DISABLED_TAB_VALUE = -5;
var TAB_KEYCODE = 9;

var isTabForward = function (e) {
  return e.keyCode === TAB_KEYCODE && !e.shiftKey
}

var isTabBackward = function (e) {
  return e.keyCode === TAB_KEYCODE && e.shiftKey
}

var getInputs = function (el) {
  return el.querySelectorAll(INPUT_SELECTORS)
}

var preventTab = function (e) {
  if (e.keyCode === TAB_KEYCODE) {
    e.preventDefault()
  }
}

var disableTabbing = function (el) {
  Array.prototype.forEach.call(getInputs(el), function (input) {
    input.tabIndex = DISABLED_TAB_VALUE
  })
}

var reenableTabbing = function (el) {
  Array.prototype.forEach.call(el.querySelectorAll("[tabindex='" + DISABLED_TAB_VALUE + "']"), function (input) {
    input.tabIndex = 0
  })
}

var getRadioToFocus = function (optionEls) {
  var radioToFocus = null

  for (var i = 0; i < optionEls.length; i++) {
    var input = optionEls[i].querySelector('input')

    if(optionEls[i].style.display !== 'none' && (!radioToFocus || input.checked)) {
      radioToFocus = input
    }
  }

  return radioToFocus
}