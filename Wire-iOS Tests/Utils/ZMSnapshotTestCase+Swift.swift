// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


import Foundation
@testable import Wire


extension UITableViewCell: UITableViewDelegate, UITableViewDataSource {
    @objc public func wrapInTableView() -> UITableView {
        let tableView = UITableView(frame: self.bounds, style: .plain)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.layoutMargins = self.layoutMargins
        
        let size = self.systemLayoutSizeFitting(CGSize(width: bounds.width, height: 0.0) , withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        self.layoutSubviews()
        
        self.bounds = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        self.contentView.bounds = self.bounds
        
        tableView.reloadData()
        tableView.bounds = self.bounds
        tableView.layoutIfNeeded()

        NSLayoutConstraint.activate([
            tableView.heightAnchor.constraint(equalToConstant: size.height)
            ])

        self.layoutSubviews()
        return tableView
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.bounds.size.height
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self
    }
}


extension StaticString {
    func utf8SignedStart() -> UnsafePointer<Int8> {
        let fileUnsafePointer = self.utf8Start
        let reboundToSigned = fileUnsafePointer.withMemoryRebound(to: Int8.self, capacity: self.utf8CodeUnitCount) {
            return UnsafePointer($0)
        }
        return reboundToSigned
    }
}

// MARK: - verify the snapshots in multiple devices

/// Performs multiple assertions with the given view using the screen sizes of
/// the common iPhones in Portrait and iPad in Landscape and Portrait.
/// This method only makes sense for views that will be on presented fullscreen.
extension ZMSnapshotTestCase {
    
    static let phoneScreenSizes: [String:CGSize] = [
        "iPhone4_0Inch": CGSize.DeviceScreen.iPhone4_0Inch,
        "iPhone4_7Inch": CGSize.DeviceScreen.iPhone4_7Inch,
        "iPhone5_5Inch": CGSize.DeviceScreen.iPhone5_5Inch,
        "iPhone5_8Inch": CGSize.DeviceScreen.iPhone5_8Inch,
        "iPhone6_5Inch": CGSize.DeviceScreen.iPhone6_5Inch
        ]

    // We should add iPad Pro sizes 1366x1024, 1194x834
    static let tabletScreenSizes: [String:CGSize] = [
        "iPadPortrait": CGSize.DeviceScreen.iPadPortrait,
        "iPadLandscape": CGSize.DeviceScreen.iPadLandscape
    ]
    
    typealias ConfigurationWithDeviceType = (_ view: UIView, _ isPad: Bool) -> Void
    typealias Configuration = (_ view: UIView) -> Void

    private static var deviceScreenSizes: [String:CGSize] = {
        return phoneScreenSizes.merging(tabletScreenSizes) { $1 }
    }()

    ///iPhone X's width is same and iPhone 6 and iPhone XR's width is same as iPhone 6 plus
    static let phoneWidths: [String:CGFloat] = [
        "320": CGSize.DeviceScreen.iPhone4_0Inch.width,
        "375": CGSize.DeviceScreen.iPhone4_7Inch.width,
        "414": CGSize.DeviceScreen.iPhone5_5Inch.width
    ]

    private static var tabletWidths: [String:CGFloat] = {
        return Dictionary(uniqueKeysWithValues:
            tabletScreenSizes.map { key, value in (key, value.width) })
    }()

    func verifyMultipleSize(view: UIView,
                            extraLayoutPass: Bool,
                            inSizes sizes: [String:CGSize],
                            configuration: ConfigurationWithDeviceType?,
                file: StaticString = #file, line: UInt = #line) {
        for (deviceName, size) in sizes {
            view.frame = CGRect(origin: .zero, size: size)
            if let configuration = configuration {
                let iPad = size.equalTo(CGSize.DeviceScreen.iPadLandscape) || size.equalTo(CGSize.DeviceScreen.iPadPortrait)
                UIView.performWithoutAnimation({
                    configuration(view, iPad)
                })
            }
            verify(view: view,
                   extraLayoutPass: extraLayoutPass,
                   deviceName: deviceName,
                   file: file,
                   line: line)
        }
    }

    func verifyInAllPhoneSizes( view: UIView, extraLayoutPass: Bool, file: StaticString = #file, line: UInt = #line, configurationBlock configuration: Configuration?) {
        verifyMultipleSize(view: view, extraLayoutPass: extraLayoutPass, inSizes: ZMSnapshotTestCase.phoneScreenSizes, configuration: { view, isPad in
            if let configuration = configuration {
                configuration(view)
            }
        }, file: file, line: line)
    }

    func verifyInAllDeviceSizes(view: UIView, extraLayoutPass: Bool, file: StaticString = #file, line: UInt = #line, configurationBlock configuration: ConfigurationWithDeviceType? = nil) {

        verifyMultipleSize(view: view, extraLayoutPass: extraLayoutPass, inSizes: ZMSnapshotTestCase.deviceScreenSizes,
               configuration: configuration,
               file: file, line: line)
    }
}

// MARK: - verify the snapshots in multiple widths

extension ZMSnapshotTestCase {
    func verifyInAllPhoneWidths(view: UIView,
                                extraLayoutPass: Bool = false,
                                tolerance: Float = 0,
                                file: StaticString = #file,
                                line: UInt = #line) {
        assertAmbigousLayout(view, file: file.utf8SignedStart(), line: line)
        for (deviceName, width) in ZMSnapshotTestCase.phoneWidths {
            verifyView(view,
                       extraLayoutPass: extraLayoutPass,
                       tolerance: 0,
                       width: width, file: file.utf8SignedStart(), line: line, deviceName: deviceName)
        }
    }

    func verifyInAllTabletWidths(view: UIView,
                                 extraLayoutPass: Bool = false,
                                 file: StaticString = #file,
                                 line: UInt = #line) {
        assertAmbigousLayout(view, file: file.utf8SignedStart(), line: line)
        for (deviceName, width) in ZMSnapshotTestCase.tabletWidths {
            verifyView(view,
                       extraLayoutPass: extraLayoutPass,
                       tolerance: 0,
                       width: width, file: file.utf8SignedStart(), line: line, deviceName: deviceName)
        }
    }
}

extension ZMSnapshotTestCase {

    func verify(view: UIView,
                extraLayoutPass: Bool = false,
                identifier: String = "",
                tolerance: Float = 0,
                deviceName: String? = nil,
                file: StaticString = #file,
                line: UInt = #line) {
        verifyView(view, extraLayoutPass: extraLayoutPass, tolerance: tolerance, file: file.utf8SignedStart(), line: line, identifier: identifier, deviceName: deviceName)
    }
    
    func verifyInAllDeviceSizes(view: UIView, file: StaticString = #file, line: UInt = #line, configuration: @escaping (UIView, Bool) -> () = { _, _ in }) {
        verifyInAllDeviceSizes(view: view, extraLayoutPass: false, file: file, line: line, configurationBlock: configuration)
    }

    /// return the smallest iPhone screen size that Wire app supports
    private var defaultIPhoneSize: CGSize {
        return CGSize.DeviceScreen.iPhone4_0Inch
    }

    func verifyInIPhoneSize(view: UIView, file: StaticString = #file, line: UInt = #line) {

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: defaultIPhoneSize.height),
            view.widthAnchor.constraint(equalToConstant: defaultIPhoneSize.width)
            ])

        view.setNeedsLayout()
        view.layoutIfNeeded()
        verifyView(view, extraLayoutPass: false, tolerance: 0, file: file.utf8SignedStart(), line: line, identifier: "", deviceName: nil)
    }
    
    func verifyInAllIPhoneSizes(view: UIView, extraLayoutPass: Bool = false, file: StaticString = #file, line: UInt = #line, configurationBlock: ((UIView) -> Swift.Void)? = nil) {
        verifyInAllPhoneSizes(view: view, extraLayoutPass: extraLayoutPass, file: file, line: line, configurationBlock: configurationBlock)
    }
    
    func verifyInAllColorSchemes(view: UIView, tolerance: Float = 0, file: StaticString = #file, line: UInt = #line) {
        if var themeable = view as? Themeable {
            themeable.colorSchemeVariant = .light
            snapshotBackgroundColor = .white
            verifyView(view, extraLayoutPass: false, tolerance: tolerance, file: file.utf8SignedStart(), line: line, identifier: "LightTheme", deviceName: nil)
            themeable.colorSchemeVariant = .dark
            snapshotBackgroundColor = .black
            verifyView(view, extraLayoutPass: false, tolerance: tolerance, file: file.utf8SignedStart(), line: line, identifier: "DarkTheme", deviceName: nil)
        } else {
            XCTFail("View doesn't support Themable protocol")
        }
    }
    
    @available(iOS 11.0, *)
    func verifySafeAreas(
        viewController: UIViewController,
        tolerance: Float = 0,
        file: StaticString = #file,
        line: UInt = #line
        ) {
        viewController.additionalSafeAreaInsets = UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
        viewController.viewSafeAreaInsetsDidChange()
        viewController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        verify(view: viewController.view)
    }
    
    func resetColorScheme() {
        ColorScheme.default.variant = .light

        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
    }
}

// MARK: - UIAlertController
extension ZMSnapshotTestCase {
    func verifyAlertController(_ controller: UIAlertController, file: StaticString = #file, line: UInt = #line) {
        // Given
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 375, height: 667))
        let container = UIViewController()
        container.loadViewIfNeeded()
        window.rootViewController = container
        window.makeKeyAndVisible()
        controller.loadViewIfNeeded()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        // When
        let presentationExpectation = expectation(description: "It should be presented")
        container.present(controller, animated: false) {
            presentationExpectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 2, handler: nil)
        verify(view: controller.view, file: file, line: line)
    }
}
