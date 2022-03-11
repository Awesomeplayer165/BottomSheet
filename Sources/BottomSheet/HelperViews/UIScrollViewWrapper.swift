//
//  UIScrollViewWrapper.swift
//
//  Created by Lucas Zischka.
//  Copyright © 2021-2022 Lucas Zischka. All rights reserved.
//

import SwiftUI

internal struct UIScrollViewWrapper<Content: View>: UIViewControllerRepresentable {
    
    @Binding var offset: CGPoint
    @Binding var isScrollEnabled: Bool
    var content: Content
    
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> UIScrollViewViewController<Content> {
        let viewController = UIScrollViewViewController(rootView: self.content)
        viewController.scrollView.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ viewController: UIScrollViewViewController<Content>, context: UIViewControllerRepresentableContext<Self>) {
        viewController.hostingController.rootView = content
        viewController.scrollView.addSubview(viewController.hostingController.view)
        
        var contentSize: CGSize = viewController.hostingController.view.intrinsicContentSize
        contentSize.width = viewController.scrollView.frame.width
        viewController.hostingController.view.frame.size = contentSize
        viewController.scrollView.contentSize = contentSize
        
        viewController.view.updateConstraintsIfNeeded()
        viewController.view.layoutIfNeeded()
        
        viewController.scrollView.isScrollEnabled = self.isScrollEnabled
        if viewController.scrollView.contentOffset != self.offset {
            viewController.scrollView.setContentOffset(self.offset, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(offset: self.$offset, isScrollEnabled: self.$isScrollEnabled)
    }
    
    
    init(offset: Binding<CGPoint>, isScrollEnabled: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self._offset = offset
        self._isScrollEnabled = isScrollEnabled
        self.content = content()
    }
    
    
    final class Coordinator: NSObject, UIScrollViewDelegate {
        
        @Binding var offset: CGPoint
        @Binding var isScrollEnabled: Bool
        
        func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
            DispatchQueue.main.async {
                self.isScrollEnabled = true
            }
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            self.updateScroll(for: scrollView.contentOffset)
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            self.updateScroll(for: scrollView.contentOffset)
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            DispatchQueue.main.async {
                self.offset = scrollView.contentOffset
            }
        }
        
        private func updateScroll(for offset: CGPoint) {
            DispatchQueue.main.async {
                if offset.y <= 0 {
                    self.isScrollEnabled = false
                } else {
                    self.isScrollEnabled = true
                }
            }
        }
        
        
        init(offset: Binding<CGPoint>, isScrollEnabled: Binding<Bool>) {
            self._offset = offset
            self._isScrollEnabled = isScrollEnabled
        }
    }
}

internal class UIScrollViewViewController<Content: View>: UIViewController {
    
    let scrollView: UIScrollView
    let hostingController: UIHostingController<Content>
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.scrollView)
        NSLayoutConstraint.activate([
            self.scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        self.view.setNeedsUpdateConstraints()
        self.view.updateConstraintsIfNeeded()
        self.view.layoutIfNeeded()
    }
    
    
    init(rootView: Content) {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        self.scrollView = scrollView
        
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .clear
        self.hostingController = hostingController
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct UIScrollViewWrapper_Previews: PreviewProvider {
    static var previews: some View {
        UIScrollViewWrapper(offset: .constant(.zero), isScrollEnabled: .constant(true)) {
            ForEach(0..<100) { i in
                Text("\(i)")
            }
        }
    }
}
