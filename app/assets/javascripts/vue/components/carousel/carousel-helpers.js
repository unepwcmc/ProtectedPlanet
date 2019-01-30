
const getTransitionDuration = el => 
  parseFloat(getElementStyle(el).transitionDuration) * 1000

const getWidthWithMargins = el => {
  const style = getElementStyle(el)

  return el.offsetWidth + parseInt(style.marginLeft, 10) + parseInt(style.marginRight, 10)
}

const getElementStyle = el =>
  el.currentStyle || window.getComputedStyle(el)

const getNewOrder = (oldOrder, changeInIndex, totalSlides) => {
  const newOrderBeforeMod = oldOrder - changeInIndex
  let newOrder;

  if (newOrderBeforeMod < 0) {
    newOrder = newOrderBeforeMod + totalSlides * 3
  } else if (newOrderBeforeMod > totalSlides * 3 - 1) {
    newOrder = newOrderBeforeMod - totalSlides * 3
  } else {
    newOrder = newOrderBeforeMod
  }

  return newOrder
}

const getChangeInIndex = (newSlide, oldSlide, totalSlides, forceDirection) => {
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

const modGreaterThanZero = (x, base) => ((x - 1 + base) % base + 1)