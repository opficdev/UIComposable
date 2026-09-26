import SwiftUI
import UIComposable

struct LifecycleRiskDemo: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                UnusedCandidateLifecycleDemo()
                StaticConstraintLifecycleDemo()
                StrongReferenceCycleLifecycleDemo()
            }
            .padding()
        }
        .navigationTitle("생명주기 위험")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct UnusedCandidateLifecycleDemo: View {
    @State private var revision = 0
    @State private var snapshot = InitializerObserverMetrics.Snapshot()

    var body: some View {
        DemoRegion(.swiftUI) {
            VStack(alignment: .leading, spacing: 12) {
                Text("1. 미사용 인스턴스의 init 부작용")
                    .font(.headline)
                Text("body를 다시 계산할 때 새 UILabel이 만들어지지만 화면에는 처음 객체가 남습니다. 새 객체가 init에서 등록한 Observer는 disconnect 대상이 아닙니다.")
                CandidateHost(revision: revision)
                    .equatable()
                    .frame(height: 56)

                Button("body 재평가") {
                    revision += 1
                    refreshAfterUpdate()
                }
                .buttonStyle(.borderedProminent)

                Button("알림 보내기") {
                    InitializerObserverMetrics.shared.postNotification()
                    refresh()
                }
                .buttonStyle(.bordered)

                Button("남은 Observer 정리") {
                    InitializerObserverMetrics.shared.stopAllObservers()
                    refreshAfterUpdate()
                }
                .buttonStyle(.bordered)

                LabeledContent("생성된 객체", value: "\(snapshot.createdCount)")
                LabeledContent("살아 있는 객체", value: "\(snapshot.liveCount)")
                LabeledContent("표시 중인 객체", value: snapshot.displayedID.map { "#\($0)" } ?? "없음")
                LabeledContent("알림 수신 합계", value: "\(snapshot.notificationCount)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task {
            await Task.yield()
            refresh()
        }
        .onDisappear {
            InitializerObserverMetrics.shared.stopAllObservers()
        }
    }

    private func refresh() {
        snapshot = InitializerObserverMetrics.shared.snapshot
    }

    private func refreshAfterUpdate() {
        Task { @MainActor in
            await Task.yield()
            refresh()
        }
    }
}

private struct CandidateHost: View, Equatable {
    let revision: Int

    var body: some View {
        InitializerObserverLabel()
            .composable { label in
                InitializerObserverMetrics.shared.markDisplayed(label.id)
                label.text = "표시 객체 #\(label.id), 갱신 \(revision)회"
                label.textAlignment = .center
                label.backgroundColor = .secondarySystemBackground
            }
    }
}

private struct StaticConstraintLifecycleDemo: View {
    @State private var basicTapCount = 0
    @State private var coordinatedTapCount = 0

    var body: some View {
        DemoRegion(.swiftUI) {
            VStack(alignment: .leading, spacing: 12) {
                Text("2. 제네릭 제약에 따른 Bridge 선택")
                    .font(.headline)
                Text("두 UIButton은 같은 타입입니다. UIComposable 제약으로 감싼 첫 버튼은 Coordinator가 연결되지 않아 눌러도 횟수가 바뀌지 않습니다.")

                basicComposable(LifecycleActionButton()) {
                    basicTapCount += 1
                }
                .frame(height: 44)

                coordinatedComposable(LifecycleActionButton()) {
                    coordinatedTapCount += 1
                }
                .frame(height: 44)

                LabeledContent("UIComposable 제약", value: "\(basicTapCount)회")
                LabeledContent("UICoordinatedComposable 제약", value: "\(coordinatedTapCount)회")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func basicComposable<Content>(
        _ content: Content,
        onTap: @escaping @MainActor () -> Void
    ) -> some View where Content: UIButton & UIComposable & LifecycleActionPresenting {
        content.composable { button in
            button.configuration = .filled()
            button.configuration?.title = "UIComposable 제약 버튼"
            button.onTap = onTap
        }
    }

    private func coordinatedComposable<Content>(
        _ content: Content,
        onTap: @escaping @MainActor () -> Void
    ) -> some View where Content: UIButton & UICoordinatedComposable & LifecycleActionPresenting {
        content.composable { button in
            button.configuration = .filled()
            button.configuration?.title = "UICoordinatedComposable 제약 버튼"
            button.onTap = onTap
        }
    }
}

private struct StrongReferenceCycleLifecycleDemo: View {
    @State private var isPresented = true
    @State private var snapshot = StrongReferenceCycleMetrics.Snapshot()

    var body: some View {
        DemoRegion(.swiftUI) {
            VStack(alignment: .leading, spacing: 12) {
                Text("3. disconnect 뒤에 남는 강한 참조")
                    .font(.headline)
                Text("UILabel과 Coordinator가 서로 강하게 참조하고 disconnect가 이를 끊지 않는 구현입니다. 화면에서 제거해도 살아 있는 객체 수가 줄지 않습니다.")

                if isPresented {
                    StrongReferenceCycleLabel()
                        .composable { label in
                            label.text = "강한 참조가 연결된 객체 #\(label.id)"
                            label.textAlignment = .center
                            label.backgroundColor = .secondarySystemBackground
                        }
                        .frame(height: 56)
                }

                Button(isPresented ? "화면에서 제거" : "다시 표시") {
                    isPresented.toggle()
                    refreshAfterUpdate()
                }
                .buttonStyle(.borderedProminent)

                Button("강한 참조 직접 해제") {
                    StrongReferenceCycleMetrics.shared.breakAllCycles()
                    refreshAfterUpdate()
                }
                .buttonStyle(.bordered)

                LabeledContent("생성된 객체", value: "\(snapshot.createdCount)")
                LabeledContent("disconnect 호출", value: "\(snapshot.disconnectCount)")
                LabeledContent("살아 있는 객체", value: "\(snapshot.liveCount)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task {
            await Task.yield()
            refresh()
        }
        .onDisappear {
            StrongReferenceCycleMetrics.shared.breakAllCycles()
        }
    }

    private func refresh() {
        snapshot = StrongReferenceCycleMetrics.shared.snapshot
    }

    private func refreshAfterUpdate() {
        Task { @MainActor in
            await Task.yield()
            refresh()
        }
    }
}

@MainActor
private protocol LifecycleActionPresenting: AnyObject {
    var onTap: @MainActor () -> Void { get set }
}

@MainActor
private final class InitializerObserverLabel: UILabel, UICoordinatedComposable {
    final class Coordinator {}

    let id: Int
    private var observer: NSObjectProtocol?

    override init(frame: CGRect) {
        let metrics = InitializerObserverMetrics.shared
        id = metrics.makeID()
        super.init(frame: frame)
        metrics.track(self)
        observer = NotificationCenter.default.addObserver(
            forName: InitializerObserverMetrics.notification,
            object: nil,
            queue: .main
        ) { [self] _ in
            MainActor.assumeIsolated {
                InitializerObserverMetrics.shared.recordNotification(from: id)
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func connect(coordinator: Coordinator) {}

    func update(coordinator: Coordinator) {}

    func disconnect(coordinator: Coordinator) {
        stopObserving()
    }

    func stopObserving() {
        guard let observer else {
            return
        }

        NotificationCenter.default.removeObserver(observer)
        self.observer = nil
    }
}

@MainActor
private final class LifecycleActionButton: UIButton, UICoordinatedComposable, LifecycleActionPresenting {
    @MainActor
    final class LifecycleActionCoordinator: NSObject {
        var onTap: @MainActor () -> Void = {}

        @objc func didTap() {
            onTap()
        }
    }

    var onTap: @MainActor () -> Void = {}

    func makeCoordinator() -> LifecycleActionCoordinator {
        LifecycleActionCoordinator()
    }

    func connect(coordinator: LifecycleActionCoordinator) {
        addTarget(coordinator, action: #selector(LifecycleActionCoordinator.didTap), for: .touchUpInside)
    }

    func update(coordinator: LifecycleActionCoordinator) {
        coordinator.onTap = onTap
    }

    func disconnect(coordinator: LifecycleActionCoordinator) {
        removeTarget(coordinator, action: #selector(LifecycleActionCoordinator.didTap), for: .touchUpInside)
        coordinator.onTap = {}
    }
}

@MainActor
private final class StrongReferenceCycleLabel: UILabel, UICoordinatedComposable {
    final class StrongReferenceCycleCoordinator {
        var content: StrongReferenceCycleLabel?
    }

    let id: Int
    private var retainedCoordinator: StrongReferenceCycleCoordinator?

    override init(frame: CGRect) {
        let metrics = StrongReferenceCycleMetrics.shared
        id = metrics.makeID()
        super.init(frame: frame)
        metrics.track(self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeCoordinator() -> StrongReferenceCycleCoordinator {
        StrongReferenceCycleCoordinator()
    }

    func connect(coordinator: StrongReferenceCycleCoordinator) {
        retainedCoordinator = coordinator
        coordinator.content = self
    }

    func update(coordinator: StrongReferenceCycleCoordinator) {}

    func disconnect(coordinator: StrongReferenceCycleCoordinator) {
        StrongReferenceCycleMetrics.shared.recordDisconnect()
    }

    func breakCycle() {
        retainedCoordinator?.content = nil
        retainedCoordinator = nil
    }
}

@MainActor
private final class InitializerObserverMetrics {
    struct Snapshot {
        var createdCount = 0
        var liveCount = 0
        var notificationCount = 0
        var displayedID: Int?
    }

    static let shared = InitializerObserverMetrics()
    static let notification = Notification.Name("UIComposable.InitializerObserverDemo")

    private var nextID = 0
    private var references: [WeakReference<InitializerObserverLabel>] = []
    private var notificationCount = 0
    private var displayedID: Int?

    var snapshot: Snapshot {
        removeReleasedReferences()
        return Snapshot(
            createdCount: nextID,
            liveCount: references.count,
            notificationCount: notificationCount,
            displayedID: displayedID
        )
    }

    func makeID() -> Int {
        nextID += 1
        return nextID
    }

    func track(_ label: InitializerObserverLabel) {
        references.append(WeakReference(label))
    }

    func markDisplayed(_ id: Int) {
        displayedID = id
    }

    func recordNotification(from id: Int) {
        _ = id
        notificationCount += 1
    }

    func postNotification() {
        NotificationCenter.default.post(name: Self.notification, object: nil)
    }

    func stopAllObservers() {
        references.compactMap(\.value).forEach { $0.stopObserving() }
        removeReleasedReferences()
    }

    private func removeReleasedReferences() {
        references.removeAll { $0.value == nil }
    }
}

@MainActor
private final class StrongReferenceCycleMetrics {
    struct Snapshot {
        var createdCount = 0
        var disconnectCount = 0
        var liveCount = 0
    }

    static let shared = StrongReferenceCycleMetrics()

    private var nextID = 0
    private var disconnectCount = 0
    private var references: [WeakReference<StrongReferenceCycleLabel>] = []

    var snapshot: Snapshot {
        removeReleasedReferences()
        return Snapshot(
            createdCount: nextID,
            disconnectCount: disconnectCount,
            liveCount: references.count
        )
    }

    func makeID() -> Int {
        nextID += 1
        return nextID
    }

    func track(_ label: StrongReferenceCycleLabel) {
        references.append(WeakReference(label))
    }

    func recordDisconnect() {
        disconnectCount += 1
    }

    func breakAllCycles() {
        references.compactMap(\.value).forEach { $0.breakCycle() }
        removeReleasedReferences()
    }

    private func removeReleasedReferences() {
        references.removeAll { $0.value == nil }
    }
}

@MainActor
private final class WeakReference<Value> where Value: AnyObject {
    weak var value: Value?

    init(_ value: Value) {
        self.value = value
    }
}
