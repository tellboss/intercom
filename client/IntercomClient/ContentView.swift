import SwiftUI

struct Agent: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let avatar: String
    let avatarColor: Color
    let lastMessage: String
    let time: String
    let unreadCount: Int

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Agent, rhs: Agent) -> Bool { lhs.id == rhs.id }
}

let sampleAgents: [Agent] = [
    Agent(name: "研发工程师", avatar: "desktopcomputer.circle.fill", avatarColor: .indigo, lastMessage: "PR #327 已提交，等待 review", time: "刚刚", unreadCount: 3),
]

struct MessageRow: View {
    let agent: Agent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: agent.avatar)
                .font(.system(size: 46))
                .foregroundStyle(agent.avatarColor)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(agent.name)
                        .font(.body)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(agent.time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text(agent.lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    if agent.unreadCount > 0 {
                        Text("\(agent.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red, in: Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromAgent: Bool
    let time: String
}

func sampleMessages(for agent: Agent) -> [ChatMessage] {
    switch agent.name {
    case "客服助手":
        return [
            ChatMessage(text: "您好，我想咨询一下退款流程", isFromAgent: false, time: "14:20"),
            ChatMessage(text: "您好，请问有什么可以帮您？", isFromAgent: true, time: "14:20"),
            ChatMessage(text: "请提供您的订单号，我来帮您查询", isFromAgent: true, time: "14:21"),
        ]
    case "订单管家":
        return [
            ChatMessage(text: "我的快递到哪了？", isFromAgent: false, time: "10:25"),
            ChatMessage(text: "正在为您查询物流信息...", isFromAgent: true, time: "10:26"),
            ChatMessage(text: "您的订单已发货，预计明天送达", isFromAgent: true, time: "10:30"),
        ]
    case "代码助手":
        return [
            ChatMessage(text: "帮我 review 一下这个 PR", isFromAgent: false, time: "15:00"),
            ChatMessage(text: "好的，我来看看", isFromAgent: true, time: "15:01"),
            ChatMessage(text: "代码逻辑没问题，建议补充单元测试", isFromAgent: true, time: "15:10"),
            ChatMessage(text: "已补充，麻烦再看一下", isFromAgent: false, time: "16:00"),
            ChatMessage(text: "PR 已通过 review，可以合并了", isFromAgent: true, time: "16:05"),
        ]
    default:
        return [
            ChatMessage(text: "你好", isFromAgent: false, time: "09:00"),
            ChatMessage(text: "你好！有什么可以帮您的吗？", isFromAgent: true, time: "09:01"),
            ChatMessage(text: agent.lastMessage, isFromAgent: true, time: "09:05"),
        ]
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    let agentColor: Color

    var body: some View {
        HStack {
            if !message.isFromAgent { Spacer() }

            VStack(alignment: message.isFromAgent ? .leading : .trailing, spacing: 2) {
                Text(message.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.isFromAgent ? Color(.systemGray5) : agentColor)
                    .foregroundStyle(message.isFromAgent ? Color.primary : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(message.time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if message.isFromAgent { Spacer() }
        }
    }
}

// MARK: - Voice Input

enum RecordingState {
    case idle
    case recording
    case cancel
    case edit
}

struct VoiceInputBar: View {
    let accentColor: Color
    var onSend: (String) -> Void

    @State private var recordingState: RecordingState = .idle
    @State private var isEditing = false
    @State private var editText = ""
    @State private var pulsePhase = false

    private let dragThreshold: CGFloat = 60
    private let buttonSize: CGFloat = 72

    var body: some View {
        if isEditing {
            HStack(spacing: 10) {
                TextField("编辑消息...", text: $editText)
                    .textFieldStyle(.roundedBorder)
                Button {
                    if !editText.trimmingCharacters(in: .whitespaces).isEmpty {
                        onSend(editText)
                    }
                    editText = ""
                    isEditing = false
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(accentColor)
                        .font(.title3)
                }
                Button {
                    editText = ""
                    isEditing = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        } else {
            VStack(spacing: 8) {
                // 录音时顶部提示区
                if recordingState != .idle {
                    HStack(spacing: 0) {
                        // 左：取消
                        VStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.body.bold())
                            Text("取消")
                                .font(.caption2)
                        }
                        .foregroundStyle(recordingState == .cancel ? .white : .secondary)
                        .frame(width: 52, height: 52)
                        .background(
                            Circle().fill(recordingState == .cancel ? Color.red : Color(.systemGray5))
                        )

                        Spacer()

                        // 中间状态
                        VStack(spacing: 4) {
                            Text(stateLabel)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            if recordingState == .recording {
                                WaveformView(color: accentColor)
                                    .frame(height: 20)
                            }
                        }

                        Spacer()

                        // 右：编辑
                        VStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.body.bold())
                            Text("编辑")
                                .font(.caption2)
                        }
                        .foregroundStyle(recordingState == .edit ? .white : .secondary)
                        .frame(width: 52, height: 52)
                        .background(
                            Circle().fill(recordingState == .edit ? Color.green : Color(.systemGray5))
                        )
                    }
                    .padding(.horizontal, 30)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // 对讲机按钮
                ZStack {
                    // 脉冲光环
                    if recordingState == .recording {
                        Circle()
                            .stroke(accentColor.opacity(0.2), lineWidth: 2)
                            .frame(width: buttonSize + 24, height: buttonSize + 24)
                            .scaleEffect(pulsePhase ? 1.3 : 1.0)
                            .opacity(pulsePhase ? 0 : 0.6)

                        Circle()
                            .stroke(accentColor.opacity(0.15), lineWidth: 1.5)
                            .frame(width: buttonSize + 40, height: buttonSize + 40)
                            .scaleEffect(pulsePhase ? 1.4 : 1.0)
                            .opacity(pulsePhase ? 0 : 0.4)
                    }

                    // 外圈
                    Circle()
                        .fill(
                            recordingState == .idle
                                ? Color(.systemGray5)
                                : buttonColor.opacity(0.15)
                        )
                        .frame(width: buttonSize + 12, height: buttonSize + 12)

                    // 主按钮
                    Circle()
                        .fill(
                            recordingState == .idle
                                ? LinearGradient(colors: [accentColor, accentColor.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [buttonColor, buttonColor.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: buttonSize, height: buttonSize)
                        .shadow(color: (recordingState == .idle ? accentColor : buttonColor).opacity(0.4), radius: recordingState == .idle ? 4 : 10, y: 2)

                    // 图标
                    Image(systemName: recordingState == .idle ? "mic.fill" : "waveform")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(.white)
                        .symbolEffect(.variableColor.iterative, isActive: recordingState == .recording)
                }
                .scaleEffect(recordingState != .idle ? 1.08 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: recordingState)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            withAnimation(.easeOut(duration: 0.15)) {
                                if recordingState == .idle {
                                    recordingState = .recording
                                    pulsePhase = false
                                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                                        pulsePhase = true
                                    }
                                }
                                let dx = value.translation.width
                                if dx < -dragThreshold {
                                    recordingState = .cancel
                                } else if dx > dragThreshold {
                                    recordingState = .edit
                                } else {
                                    recordingState = .recording
                                }
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.3)) {
                                handleRelease()
                                pulsePhase = false
                            }
                        }
                )

                // 底部文字
                Text(recordingState == .idle ? "按住说话" : "")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 10)
        }
    }

    private var stateLabel: String {
        switch recordingState {
        case .idle: return ""
        case .recording: return "松开发送"
        case .cancel: return "松开取消"
        case .edit: return "松开编辑"
        }
    }

    private var buttonColor: Color {
        switch recordingState {
        case .cancel: return .red
        case .edit: return .green
        default: return accentColor
        }
    }

    private func handleRelease() {
        let state = recordingState
        recordingState = .idle
        switch state {
        case .recording:
            onSend("[语音消息]")
        case .edit:
            editText = "这是一段语音识别的文字"
            isEditing = true
        case .cancel, .idle:
            break
        }
    }
}

struct WaveformView: View {
    let color: Color
    @State private var animating = false

    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<7, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(color)
                    .frame(width: 3)
                    .frame(height: animating ? CGFloat.random(in: 6...20) : 6)
                    .animation(
                        .easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.08),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

struct AgentStatusView: View {
    let agent: Agent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 头像 + 名称 + 状态
                HStack(spacing: 12) {
                    Image(systemName: agent.avatar)
                        .font(.system(size: 50))
                        .foregroundStyle(agent.avatarColor)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(agent.name)
                            .font(.title3)
                            .fontWeight(.bold)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("编码中")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                // Token 用量
                VStack(alignment: .leading, spacing: 10) {
                    Label("Token 用量", systemImage: "bolt.circle")
                        .font(.headline)

                    HStack(spacing: 16) {
                        StatItem(value: "32.5k", label: "今日")
                        StatItem(value: "28.1k", label: "日均")
                        StatItem(value: "196k", label: "本周累计")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("最近 7 天趋势")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(alignment: .bottom, spacing: 6) {
                            TokenBar(value: 0.6, label: "一")
                            TokenBar(value: 0.75, label: "二")
                            TokenBar(value: 0.5, label: "三")
                            TokenBar(value: 0.9, label: "四")
                            TokenBar(value: 0.85, label: "五")
                            TokenBar(value: 0.3, label: "六")
                            TokenBar(value: 0.8, label: "今")
                        }
                        .frame(height: 80)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("月度额度")
                                .font(.subheadline)
                            Spacer()
                            Text("620k / 1M")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        ProgressView(value: 0.62)
                            .tint(.blue)
                    }
                }

                Divider()

                // 当前 Sprint
                VStack(alignment: .leading, spacing: 10) {
                    Label("Sprint 进度", systemImage: "flag.circle")
                        .font(.headline)
                    HStack {
                        Text("Sprint 24 · 第 8/10 天")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("80%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    ProgressView(value: 0.8)
                        .tint(agent.avatarColor)
                }

                Divider()

                // 当前任务
                VStack(alignment: .leading, spacing: 10) {
                    Label("进行中", systemImage: "hammer.circle")
                        .font(.headline)

                    TaskRow(title: "用户登录流程重构", tag: "Feature", tagColor: .blue, branch: "feat/auth-refactor", priority: "P1")
                    TaskRow(title: "修复列表页内存泄漏", tag: "Bug", tagColor: .red, branch: "fix/list-memory-leak", priority: "P0")
                }

                Divider()

                // OKR
                VStack(alignment: .leading, spacing: 10) {
                    Label("Q2 OKR", systemImage: "target")
                        .font(.headline)

                    OKRRow(objective: "核心接口 P99 < 200ms", progress: 0.85, color: .green)
                    OKRRow(objective: "单测覆盖率 ≥ 80%", progress: 0.72, color: .orange)
                    OKRRow(objective: "线上故障 ≤ 2 次/月", progress: 0.95, color: .green)
                }

                Divider()

                // 代码统计
                VStack(alignment: .leading, spacing: 10) {
                    Label("本周代码", systemImage: "chevron.left.forwardslash.chevron.right")
                        .font(.headline)
                    HStack(spacing: 16) {
                        StatItem(value: "12", label: "Commits")
                        StatItem(value: "5", label: "PRs")
                        StatItem(value: "+2.4k", label: "行增")
                        StatItem(value: "-800", label: "行删")
                    }
                }

                Divider()

                // 最近 PR
                VStack(alignment: .leading, spacing: 10) {
                    Label("最近 PR", systemImage: "arrow.triangle.branch")
                        .font(.headline)

                    PRRow(title: "#327 重构登录模块", status: "Review 中", statusColor: .orange)
                    PRRow(title: "#325 修复内存泄漏", status: "已合并", statusColor: .purple)
                    PRRow(title: "#322 添加单元测试", status: "已合并", statusColor: .purple)
                }

                Divider()

                // 技术栈
                VStack(alignment: .leading, spacing: 10) {
                    Label("技术栈", systemImage: "cpu")
                        .font(.headline)
                    FlowLayout(spacing: 8) {
                        TechTag("Swift")
                        TechTag("SwiftUI")
                        TechTag("Combine")
                        TechTag("Core Data")
                        TechTag("GraphQL")
                        TechTag("Docker")
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct TaskRow: View {
    let title: String
    let tag: String
    let tagColor: Color
    let branch: String
    let priority: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(priority)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priority == "P0" ? .red : .orange, in: Capsule())
                Text(tag)
                    .font(.caption2)
                    .foregroundStyle(tagColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(tagColor.opacity(0.15), in: Capsule())
            }
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(branch)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospaced()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct OKRRow: View {
    let objective: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(objective)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
            }
            ProgressView(value: progress)
                .tint(color)
        }
    }
}

struct PRRow: View {
    let title: String
    let status: String
    let statusColor: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(status)
                .font(.caption)
                .foregroundStyle(statusColor)
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}

struct TokenBar: View {
    let value: Double // 0...1
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.blue.opacity(label == "今" ? 1.0 : 0.5))
                .frame(maxHeight: .infinity, alignment: .bottom)
                .frame(height: CGFloat(value) * 60)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TechTag: View {
    let name: String
    init(_ name: String) { self.name = name }

    var body: some View {
        Text(name)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.quaternary, in: Capsule())
    }
}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ChatDetailView: View {
    let agent: Agent
    @State private var messages: [ChatMessage] = []
    @State private var showStatus = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let panelWidth = geo.size.width * 0.75
            let currentOffset = showStatus ? -panelWidth : 0

            HStack(spacing: 0) {
                // 聊天内容
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(messages) { msg in
                                    ChatBubble(message: msg, agentColor: agent.avatarColor)
                                        .id(msg.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages.count) {
                            if let last = messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    Divider()

                    VoiceInputBar(accentColor: agent.avatarColor) { text in
                        messages.append(ChatMessage(text: text, isFromAgent: false, time: "现在"))
                    }
                }
                .frame(width: geo.size.width)
                .overlay {
                    if showStatus {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showStatus = false
                                }
                            }
                    }
                }

                // 状态面板
                AgentStatusView(agent: agent)
                    .frame(width: panelWidth)
            }
            .offset(x: currentOffset + dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation.width
                        if showStatus {
                            dragOffset = max(0, translation)
                        } else {
                            dragOffset = min(0, translation)
                        }
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 100
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            if showStatus {
                                showStatus = value.translation.width < threshold
                            } else {
                                showStatus = value.translation.width < -threshold
                            }
                            dragOffset = 0
                        }
                    }
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(showStatus ? .hidden : .visible, for: .navigationBar)
        .animation(.easeInOut(duration: 0.25), value: showStatus)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: agent.avatar)
                        .foregroundStyle(agent.avatarColor)
                    Text(agent.name)
                        .fontWeight(.semibold)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showStatus.toggle()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .onAppear {
            messages = sampleMessages(for: agent)
        }
    }
}

struct AddAgentSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Button {
                    dismiss()
                    // TODO: 扫码
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("扫码添加")
                            Text("扫描 Agent 二维码")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }

                Button {
                    dismiss()
                    // TODO: 输入 Token
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("输入 Token")
                            Text("手动输入 Agent 令牌")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "keyboard")
                            .font(.title2)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("添加 Agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

struct MessagesView: View {
    @State private var searchText = ""
    @State private var showAddMenu = false

    var filteredAgents: [Agent] {
        if searchText.isEmpty {
            return sampleAgents
        }
        return sampleAgents.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredAgents) { agent in
                    NavigationLink(destination: ChatDetailView(agent: agent)) {
                        MessageRow(agent: agent)
                    }
                }

                Button {
                    showAddMenu = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 46))
                            .foregroundStyle(.gray)

                        Text("添加 Agent")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("对讲机")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜索 Agent")
            .sheet(isPresented: $showAddMenu) {
                AddAgentSheet()
                    .presentationDetents([.height(220)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.blue)

                Text("用户名")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("这里是个人主页")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("我")
        }
    }
}

struct ContentView: View {
    var body: some View {
        MessagesView()
    }
}

#Preview {
    ContentView()
}
