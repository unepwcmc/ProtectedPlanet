export const getWidthWithMargins = el => el.offsetWidth
  + getNumericCssProperty(el, 'marginLeft')
  + getNumericCssProperty(el, 'marginRight')

const getNumericCssProperty = (el, property) => {
  const propertyStyle = getElementStyle(el)[property]

  if(propertyStyle.indexOf('rem') !== -1) {
    return convertRem(parseFloat(propertyStyle))
  }
  return parseInt(propertyStyle, 10)
}

const convertRem = value => value * getRootElementFontSize()

//for ie - maybe not the safest method - assumes returns pxs
const getRootElementFontSize = () => 
  parseFloat(getComputedStyle(document.documentElement).fontSize)

const getElementStyle = el =>
  el.currentStyle || window.getComputedStyle(el)

export const getNewOrder = (oldOrder, changeInIndex, totalSlides) => {
  const newOrderBeforeMod = oldOrder - changeInIndex
  let newOrder

  if (newOrderBeforeMod < 0) {
    newOrder = newOrderBeforeMod + totalSlides * 3
  } else if (newOrderBeforeMod > totalSlides * 3 - 1) {
    newOrder = newOrderBeforeMod - totalSlides * 3
  } else {
    newOrder = newOrderBeforeMod
  }

  return newOrder
}

export const getChangeInIndex = (newSlide, oldSlide, totalSlides, forceDirection) => {
  const directSlideDisplacement = newSlide - oldSlide
  let indirectSlideDisplacement

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

export const modGreaterThanZero = (x, base) => ((x - 1 + base) % base + 1)