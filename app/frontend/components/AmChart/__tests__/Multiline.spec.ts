import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'

function createAxisMock() {
  const renderer = {
    grid: { template: { set: vi.fn() } },
    setAll: vi.fn(),
    ticks: { template: { setAll: vi.fn() } },
    labels: { template: { setAll: vi.fn() } }
  }
  return {
    get: vi.fn((key: string) => (key === 'renderer' ? renderer : undefined)),
    children: { unshift: vi.fn() }
  }
}

function createSeriesMock(options: Record<string, unknown>) {
  return {
    options,
    strokes: { template: { set: vi.fn() } },
    data: { setAll: vi.fn() },
    bullets: { push: vi.fn((factory: () => unknown) => factory()) }
  }
}

function createChartMock() {
  const set = vi.fn()
  const xAxisMock = createAxisMock()
  const yAxisMock = createAxisMock()
  const seriesList: ReturnType<typeof createSeriesMock>[] = []

  return {
    set,
    xAxes: { push: vi.fn(() => xAxisMock), getIndex: vi.fn(() => xAxisMock) },
    yAxes: { push: vi.fn(() => yAxisMock) },
    series: {
      push: vi.fn((series: ReturnType<typeof createSeriesMock>) => {
        seriesList.push(series)
        return series
      }),
      get values() {
        return seriesList
      }
    },
    children: { push: vi.fn((legend: unknown) => legend) }
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

vi.mock('@amcharts/amcharts5', () => ({
  Root: {
    new: vi.fn(() => {
      const root = {
        setThemes: vi.fn(),
        container: { children: { push: vi.fn((child: unknown) => child) } },
        horizontalLayout: 'horizontalLayout',
        dispose: vi.fn()
      }
      rootInstances.push(root)
      return root
    })
  },
  color: vi.fn((value: string) => value),
  percent: vi.fn((value: number) => `${value}%`),
  p0: 'p0',
  p50: 'p50',
  p100: 'p100',
  Label: { new: vi.fn((_root: unknown, options: Record<string, unknown>) => options) },
  Legend: {
    new: vi.fn(() => ({
      data: { setAll: vi.fn() },
      labels: { template: { setAll: vi.fn() } }
    }))
  },
  Bullet: { new: vi.fn((_root: unknown, options: Record<string, unknown>) => options) },
  Circle: { new: vi.fn((_root: unknown, options: Record<string, unknown>) => options) },
  Rectangle: { new: vi.fn((_root: unknown, options: Record<string, unknown>) => options) }
}))

vi.mock('@amcharts/amcharts5/xy', () => ({
  XYChart: {
    new: vi.fn(() => {
      const chart = createChartMock()
      chartInstances.push(chart)
      return chart
    })
  },
  DateAxis: { new: vi.fn((_root: unknown, options: Record<string, unknown>) => options) },
  ValueAxis: { new: vi.fn((_root: unknown, options: Record<string, unknown>) => options) },
  AxisRendererX: { new: vi.fn((_root: unknown, options: Record<string, unknown>) => options) },
  AxisRendererY: { new: vi.fn((_root: unknown, options: Record<string, unknown>) => options) },
  LineSeries: {
    new: vi.fn((_root: unknown, options: Record<string, unknown>) => createSeriesMock(options))
  }
}))

const { default: AmChartMultiline } = await import('@/components/AmChart/Multiline.vue')

const data = {
  units: 'km2',
  legend: ['National', 'ABNJ', 'Global'],
  datapoints: [{ x: '2020', 1: 10, 2: 20, 3: 30 }]
}

describe('AmChartMultiline', () => {
  it('creates one line series per datapoint key (minus x), named from data.legend', () => {
    mount(AmChartMultiline, { props: { data } })

    const chart = lastChart()
    expect(chart.series.values).toHaveLength(3)
    expect(chart.series.values.map(s => s.options.name)).toEqual(data.legend)

    const [seriesData] = chart.series.values[0].data.setAll.mock.calls[0]
    expect(seriesData[0].x).toBe(new Date('2020').getTime())
  })

  it('adds a bullet per series only when dots is true', () => {
    mount(AmChartMultiline, { props: { data, dots: true } })

    const chart = lastChart()
    chart.series.values.forEach((series) => {
      expect(series.bullets.push).toHaveBeenCalled()
    })
  })

  it('defaults the chart background to white', () => {
    mount(AmChartMultiline, { props: { data } })
    const backgroundCall = lastChart().set.mock.calls.find(([key]) => key === 'background')
    expect((backgroundCall?.[1] as { fill: unknown }).fill).toBe('#ffffff')
  })

  it('disposes the root on unmount', () => {
    const wrapper = mount(AmChartMultiline, { props: { data } })
    const root = lastRoot()

    wrapper.unmount()

    expect(root.dispose).toHaveBeenCalled()
  })
})
