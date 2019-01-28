
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

const getChangeInIndex = (newSlide, oldSlide, totalSlides) => {
  const directSlideDisplacement = newSlide - oldSlide
  let indirectSlideDistance
  let changeInIndex

  if (directSlideDisplacement > 0) {
    indirectSlideDistance = oldSlide + totalSlides - newSlide
  } else {
    indirectSlideDistance = totalSlides - oldSlide + newSlide
  }

  if (Math.abs(directSlideDisplacement) > indirectSlideDistance) {
    changeInIndex = indirectSlideDistance * -directSlideDisplacement/Math.abs(directSlideDisplacement)
  } else {
    changeInIndex = directSlideDisplacement
  }

  return changeInIndex
}

const modGreaterThanZero = (x, base) => ((x - 1 + base) % base + 1)