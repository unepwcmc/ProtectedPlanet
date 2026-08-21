import { describe, it, expect } from 'vitest'
import { defineComponent, h } from 'vue'
import { mount } from '@vue/test-utils'
import { createMapOverlays, provideMapOverlays, useMapOverlays } from '@/composables/useMapOverlays'

const terrestrial = { id: 'layer-1', type: 'raster_tile' as const, url: 'https://tiles.example/t/{z}/{x}/{y}.png' }
const marine = { id: 'layer-2', type: 'raster_tile' as const, url: 'https://tiles.example/m/{z}/{x}/{y}.png' }

describe('createMapOverlays', () => {
  it('registers an overlay and its layers', () => {
    const { visibleOverlays, visibleLayers, addOverlay } = createMapOverlays()

    addOverlay({ id: 'terrestrial', layers: [terrestrial] })

    expect(visibleOverlays.value).toEqual([{ id: 'terrestrial', layers: [terrestrial] }])
    expect(visibleLayers.value).toEqual([terrestrial])
  })

  // Overlay.vue re-registers on every toggle-on, and two overlays can share a
  // layer — neither may produce a duplicate MapLibre layer id.
  it('ignores a repeat registration of the same overlay or layer id', () => {
    const { visibleOverlays, visibleLayers, addOverlay } = createMapOverlays()

    addOverlay({ id: 'terrestrial', layers: [terrestrial] })
    addOverlay({ id: 'terrestrial', layers: [terrestrial] })
    addOverlay({ id: 'combined', layers: [terrestrial, marine] })

    expect(visibleOverlays.value.map(o => o.id)).toEqual(['terrestrial', 'combined'])
    expect(visibleLayers.value).toEqual([terrestrial, marine])
  })

  it('removes an overlay and its layers', () => {
    const { visibleOverlays, visibleLayers, addOverlay, removeOverlay } = createMapOverlays()

    addOverlay({ id: 'terrestrial', layers: [terrestrial] })
    addOverlay({ id: 'marine', layers: [marine] })
    removeOverlay({ id: 'terrestrial', layers: [terrestrial] })

    expect(visibleOverlays.value.map(o => o.id)).toEqual(['marine'])
    expect(visibleLayers.value).toEqual([marine])
  })

  // MapBase watches `visibleLayers`, and an in-place push would not trigger it,
  // so both mutators must replace the array.
  it('replaces the layer array rather than mutating it, so watchers fire', () => {
    const { visibleLayers, addOverlay } = createMapOverlays()
    const before = visibleLayers.value

    addOverlay({ id: 'terrestrial', layers: [terrestrial] })

    expect(visibleLayers.value).not.toBe(before)
  })
})

describe('useMapOverlays', () => {
  it('reads the context provided by an ancestor', () => {
    const Child = defineComponent({
      setup() {
        const { addOverlay } = useMapOverlays()
        addOverlay({ id: 'terrestrial', layers: [terrestrial] })
        return () => h('div')
      }
    })
    let provided: ReturnType<typeof provideMapOverlays> | undefined
    const Parent = defineComponent({
      setup() {
        provided = provideMapOverlays()
        return () => h(Child)
      }
    })

    mount(Parent)

    expect(provided!.visibleLayers.value).toEqual([terrestrial])
  })

  // Outside a Map/Index.vue tree a map component would otherwise talk to state
  // nothing else can see — silent and hard to debug.
  it('throws when there is no enclosing map', () => {
    const Orphan = defineComponent({
      setup() {
        useMapOverlays()
        return () => h('div')
      }
    })

    expect(() => mount(Orphan)).toThrow(/must be called inside a Map/)
  })
})
