export const containsObjectWithId = (array, id) =>
  Boolean(array.filter(x => x.id === id).length)

  
export const addObjectToArrayIfAbsent = (array, object) => {
  if(!containsObjectWithId(array, object.id)) {
    return array.concat([object])
  }

  return [...array]
}