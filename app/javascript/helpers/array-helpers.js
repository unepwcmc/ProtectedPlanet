export const containsObjectWithId = (array, id) =>
  Boolean(array.filter(x => x.id === id).length)

export const spliceByObjectId = (array, id) => {
  array.forEach((x, index) => {
    if (x.id === id) {
      array.splice(index, 1)
    }
  })
}
  
export const pushIfUniqueId = (array, object) => {
  if(!containsObjectWithId(array, object.id)) {
    array.push(object)
  }
}