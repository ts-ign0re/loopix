import SwiftUI
import UIKit

struct FilterStripView: View {
    @Binding var selectedIndex: Int
    var onLockedFilterTapped: (() -> Void)?

    private let filters = BuiltInFilters.all
    private var subscription: SubscriptionManager { SubscriptionManager.shared }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(filters.enumerated()), id: \.element.id) { index, filter in
                        let locked = !subscription.isPro && !SubscriptionManager.freeFilterIDs.contains(filter.id)
                        FilterCardView(
                            filter: filter,
                            isSelected: index == selectedIndex,
                            isLocked: locked
                        ) {
                            UISelectionFeedbackGenerator().selectionChanged()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedIndex = index
                            }
                            if locked {
                                onLockedFilterTapped?()
                            }
                        }
                        .id(index)
                    }
                }
                .padding(.horizontal, CameraTheme.paddingLarge)
                .padding(.vertical, 4)
            }
            .onAppear {
                proxy.scrollTo(selectedIndex, anchor: .center)
            }
            .onChange(of: selectedIndex) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
        .frame(height: 92)
    }
}
