const getWidthWithMargins = function (el) {
  return el.offsetWidth
    + getNumericCssProperty(el, 'marginLeft') 
    + getNumericCssProperty(el, 'marginRight') 
}

const getNumericCssProperty = function (el, property) {
  const propertyStyle = getElementStyle(el)[property]

  if(propertyStyle.indexOf('rem') !== -1) {
    return convertRem(parseFloat(propertyStyle))
  }
  return parseInt(propertyStyle, 10)
}

const getElementStyle = function (el) {
  return el.currentStyle || window.getComputedStyle(el)
}

const convertRem = function (value) {
  return value * getRootElementFontSize()
}

const getRootElementFontSize = function () {
  return parseFloat(
    getElementStyle(document.documentElement).fontSize
  );
}

const getNewOrder = function (oldOrder, changeInIndex, totalSlides) {
  const newOrderBeforeMod = oldOrder - changeInIndex
  var newOrder;

  if (newOrderBeforeMod < 0) {
    newOrder = newOrderBeforeMod + totalSlides * 3
  } else if (newOrderBeforeMod > totalSlides * 3 - 1) {
    newOrder = newOrderBeforeMod - totalSlides * 3
  } else {
    newOrder = newOrderBeforeMod
  }

  return newOrder
}

const getChangeInIndex = function (newSlide, oldSlide, totalSlides, forceDirection) {
  const directSlideDisplacement = newSlide - oldSlide
  var indirectSlideDisplacement

  if (directSlideDisplacement > 0) {
    indirectSlideDisplacement = - (oldSlide + totalSlides - newSlide)
  } else {
    indirectSlideDisplacement = totalSlides - oldSlide + newSlide
  }

  if(forceDirection > 0) {
    return Math.max(indirectSlideDisplacement, directSlideDisplacement)
  } else if (forceDirection < 0) {
    return Math.min(indirectSlideDisplacement, directSlideDisplacement)
  }

  if (Math.abs(directSlideDisplacement) > Math.abs(indirectSlideDisplacement)) {
    return indirectSlideDisplacement
  } else {
    return directSlideDisplacement
  }
}

const modGreaterThanZero = function (x, base) {
  return ((x - 1 + base) % base + 1)
}