import Charts
import SwiftUI

/// 流量速率图表
struct TrafficSpeedChart: View {
  let uploadData: [TrafficDataPoint]
  let downloadData: [TrafficDataPoint]

  var body: some View {
    Chart {
      // 下载数据 - 绿色线
      ForEach(downloadData) { point in
        LineMark(
          x: .value("时间", point.timestamp),
          y: .value("速率", point.value),
          series: .value("类型", "下载")
        )
        .foregroundStyle(Color.green)
        .lineStyle(StrokeStyle(lineWidth: 2))
        .interpolationMethod(.catmullRom)
        .symbol(Circle().strokeBorder(lineWidth: 0))
      }

      // 上传数据 - 蓝色线
      ForEach(uploadData) { point in
        LineMark(
          x: .value("时间", point.timestamp),
          y: .value("速率", point.value),
          series: .value("类型", "上传")
        )
        .foregroundStyle(Color.blue)
        .lineStyle(StrokeStyle(lineWidth: 2))
        .interpolationMethod(.catmullRom)
        .symbol(Circle().strokeBorder(lineWidth: 0))
      }
    }
    .chartXAxis {
      AxisMarks(values: .automatic(desiredCount: 5)) { _ in
        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
          .foregroundStyle(Color.gray.opacity(0.2))
      }
    }
    .chartYAxis {
      AxisMarks(position: .leading) { value in
        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
          .foregroundStyle(Color.gray.opacity(0.2))
        AxisValueLabel {
          if let speed = value.as(Double.self) {
            Text(formatSpeed(speed))
              .font(.system(size: 9))
              .foregroundColor(Theme.Colors.tertiaryText)
          }
        }
      }
    }
    .chartLegend(position: .top, alignment: .leading) {
      HStack(spacing: 12) {
        HStack(spacing: 4) {
          Circle()
            .fill(Color.green)
            .frame(width: 6, height: 6)
          Text("下载")
            .font(.system(size: 10))
            .foregroundColor(Theme.Colors.secondaryText)
        }
        HStack(spacing: 4) {
          Circle()
            .fill(Color.blue)
            .frame(width: 6, height: 6)
          Text("上传")
            .font(.system(size: 10))
            .foregroundColor(Theme.Colors.secondaryText)
        }
      }
    }
    .chartPlotStyle { plotArea in
      plotArea
        .background(Color.black.opacity(0.05))
    }
    .frame(height: 120)
  }

  private func formatSpeed(_ bytes: Double) -> String {
    if bytes < 1024 {
      return String(format: "%.0f B/s", bytes)
    } else if bytes < 1024 * 1024 {
      return String(format: "%.1f KB/s", bytes / 1024)
    } else {
      return String(format: "%.1f MB/s", bytes / (1024 * 1024))
    }
  }
}

/// 流量分布环形图
struct TrafficDistributionChart: View {
  let upload: Int64
  let download: Int64

  var body: some View {
    let total = max(upload + download, 1)
    let uploadPercent = Double(upload) / Double(total) * 100
    let downloadPercent = Double(download) / Double(total) * 100

    HStack(spacing: 20) {
      // 环形图
      ZStack {
        Circle()
          .stroke(Color.gray.opacity(0.1), lineWidth: 12)

        Circle()
          .trim(from: 0, to: CGFloat(download) / CGFloat(total))
          .stroke(
            Color.green,
            style: StrokeStyle(lineWidth: 12, lineCap: .round)
          )
          .rotationEffect(.degrees(-90))

        Circle()
          .trim(from: CGFloat(download) / CGFloat(total), to: 1.0)
          .stroke(
            Color.blue,
            style: StrokeStyle(lineWidth: 12, lineCap: .round)
          )
          .rotationEffect(.degrees(-90))

        VStack(spacing: 2) {
          Text("总计")
            .font(.system(size: 9))
            .foregroundColor(Theme.Colors.tertiaryText)
          Text(formatBytes(total))
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Theme.Colors.primaryText)
        }
      }
      .frame(width: 80, height: 80)

      // 图例
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
          Circle()
            .fill(Color.green)
            .frame(width: 8, height: 8)
          VStack(alignment: .leading, spacing: 2) {
            Text("下载")
              .font(.system(size: 10))
              .foregroundColor(Theme.Colors.tertiaryText)
            HStack(spacing: 4) {
              Text(formatBytes(download))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.secondaryText)
              Text(String(format: "%.1f%%", downloadPercent))
                .font(.system(size: 9))
                .foregroundColor(Theme.Colors.tertiaryText)
            }
          }
        }

        HStack(spacing: 8) {
          Circle()
            .fill(Color.blue)
            .frame(width: 8, height: 8)
          VStack(alignment: .leading, spacing: 2) {
            Text("上传")
              .font(.system(size: 10))
              .foregroundColor(Theme.Colors.tertiaryText)
            HStack(spacing: 4) {
              Text(formatBytes(upload))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.secondaryText)
              Text(String(format: "%.1f%%", uploadPercent))
                .font(.system(size: 9))
                .foregroundColor(Theme.Colors.tertiaryText)
            }
          }
        }
      }
    }
  }

  private func formatBytes(_ bytes: Int64) -> String {
    let kb = Double(bytes) / 1024
    let mb = kb / 1024
    let gb = mb / 1024

    if gb >= 1 {
      return String(format: "%.2f GB", gb)
    } else if mb >= 1 {
      return String(format: "%.2f MB", mb)
    } else {
      return String(format: "%.2f KB", kb)
    }
  }
}

/// 流量数据点
struct TrafficDataPoint: Identifiable {
  let id = UUID()
  let timestamp: Date
  let value: Double  // bytes per second
}

#Preview {
  VStack(spacing: 20) {
    TrafficSpeedChart(
      uploadData: (0..<30).map { i in
        TrafficDataPoint(
          timestamp: Date().addingTimeInterval(TimeInterval(-29 + i)),
          value: Double.random(in: 1000...50000)
        )
      },
      downloadData: (0..<30).map { i in
        TrafficDataPoint(
          timestamp: Date().addingTimeInterval(TimeInterval(-29 + i)),
          value: Double.random(in: 5000...100000)
        )
      }
    )

    TrafficDistributionChart(
      upload: 1024 * 1024 * 150,
      download: 1024 * 1024 * 850
    )
  }
  .padding()
  .frame(width: 400)
}
