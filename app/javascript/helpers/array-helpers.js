export const containsObjectWithId = (array, id) =>
  Boolean(array.filter(x => x.id === id).length)

export const spliceByObjectId = (array, id) => {
  let removedObject = {}

  array.forEach((x, index) => {
    if (x.id === id) {
      removedObject = array.splice(index, 1)
    }
  })

  return removedObject
}
  
export const pushIfUniqueId = (array, object) => {
  if(!containsObjectWithId(array, object.id)) {
    array.push(object)
  }

  return array
}