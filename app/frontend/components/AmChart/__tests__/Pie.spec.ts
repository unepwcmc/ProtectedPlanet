import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'

function createSeriesMock() {
  return {
    data: { setAll: vi.fn() },
    slices: {
      template: {
        states: { create: vi.fn() },
        setAll: vi.fn(),
        set: vi.fn()
      }
    },
    labels: { template: { set: vi.fn() } },
    ticks: { template: { set: vi.fn() } },
    set: vi.fn(),
    events: { once: vi.fn() }
  }
}

function createChartMock(options: Record<string, unknown>) {
  return {
    options,
    series: { push: vi.fn((series: ReturnType<typeof createSeriesMock>) => series) }
  }
}

type ChartMock = ReturnType<typeof createChartMock>
type RootMock = { dispose: ReturnType<typeof vi.fn> }

const chartInstances: ChartMock[] = []
const rootInstances: RootMock[] = []

function lastChart() {
  return chartInstances.at(-1)!
}

function lastRoot() {
  return rootInstances.at(-1)!
}

function lastPieSeries() {
  return lastChart().series.push.mock.results[0].value as ReturnType<typeof createSeriesMock>
}

vi.mock('@amcharts/amcharts5', () => ({
  Root: {
    new: vi.fn(() => {
      const root = {
        setThemes: vi.fn(),
        container: { children: { push: vi.fn((child: unknown) => child) } },
        dispose: vi.fn()
      }
      rootInstances.push(root)
      return root
    })
  },
  percent: vi.fn((value: number) => `${value}%`),
  color: vi.fn((value: string) => value),
  ColorSet: { new: vi.fn((_root: unknown, options: Record<string, unknown>) => options) },
  Tooltip: {
    new: vi.fn(() => ({
      get: vi.fn(() => ({ setAll: vi.fn() })),
      label: { setAll: vi.fn() }
    }))
  }
}))

vi.mock('@amcharts/amcharts5/percent', () => ({
  PieChart: {
    new: vi.fn((_root: unknown, options: Record<string, unknown>) => {
      const chart = createChartMock(options)
      chartInstances.push(chart)
      return chart
    })
  },
  PieSeries: { new: vi.fn(() => createSeriesMock()) }
}))

const markRenderDone = vi.fn()
vi.mock('@/lib/pdfReady', () => ({
  registerPendingRender: vi.fn(() => markRenderDone)
}))

const { default: AmChartPie } = await import('@/components/AmChart/Pie.vue')

describe('AmChartPie', () => {
  it('creates a pie chart from the dataset with 12 theme colours', () => {
    const dataset = [{ id: 1, title: 'A', value: 5 }]
    mount(AmChartPie, { props: { dataset } })

    const pieSeries = lastPieSeries()
    expect(pieSeries.data.setAll).toHaveBeenCalledWith(dataset)
    expect(pieSeries.labels.template.set).toHaveBeenCalledWith('forceHidden', true)
    expect(pieSeries.ticks.template.set).toHaveBeenCalledWith('forceHidden', true)

    const colorsCall = pieSeries.set.mock.calls.find(([key]) => key === 'colors')
    expect((colorsCall?.[1] as { colors: unknown[] }).colors).toHaveLength(12)
  })

  it('sets innerRadius only when doughnut is true', () => {
    mount(AmChartPie, { props: { dataset: [], doughnut: true } })
    expect(lastChart().options.innerRadius).toBe('50%')

    mount(AmChartPie, { props: { dataset: [] } })
    expect(lastChart().options.innerRadius).toBe(0)
  })

  it('adds a slice stroke only when spacers is true', () => {
    mount(AmChartPie, { props: { dataset: [], spacers: true } })
    expect(lastPieSeries().slices.template.setAll).toHaveBeenCalledWith(
      expect.objectContaining({ stroke: '#ffffff' })
    )

    mount(AmChartPie, { props: { dataset: [] } })
    expect(lastPieSeries().slices.template.setAll).not.toHaveBeenCalled()
  })

  it('updates chart.data when the dataset prop changes', async () => {
    const wrapper = mount(AmChartPie, { props: { dataset: [{ id: 1, title: 'A', value: 1 }] } })
    const pieSeries = lastPieSeries()

    const nextDataset = [{ id: 2, title: 'B', value: 2 }]
    await wrapper.setProps({ dataset: nextDataset })

    expect(pieSeries.data.setAll).toHaveBeenLastCalledWith(nextDataset)
  })

  it('disposes the root on unmount', () => {
    const wrapper = mount(AmChartPie, { props: { dataset: [] } })
    const root = lastRoot()

    wrapper.unmount()

    expect(root.dispose).toHaveBeenCalled()
  })

  it('holds the PDF-ready flag open until amCharts reports the series drawn', () => {
    mount(AmChartPie, { props: { dataset: [{ id: 1, title: 'A', value: 5 }] } })
    const pieSeries = lastPieSeries()

    expect(markRenderDone).not.toHaveBeenCalled()

    const [event, callback] = pieSeries.events.once.mock.calls[0]
    expect(event).toBe('datavalidated')
    callback()

    expect(markRenderDone).toHaveBeenCalled()
  })
})
