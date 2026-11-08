//
//  FireWireTests.swift
//  FireWireTests
//
//  Created by Sujitha Palanisamy on 12/11/24.
//

import XCTest
@testable import FireWire

final class FireWireTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    // MARK: Unit chip text contrast (FireWireTheme pure helpers)

    func testBlackOnLightChips() {
        XCTAssertTrue(FireWireTheme.prefersBlackText(onRGB: 0xF7C948), "chief yellow")
        XCTAssertTrue(FireWireTheme.prefersBlackText(onRGB: 0x17B26A), "marine green")
        XCTAssertTrue(FireWireTheme.prefersBlackText(onRGB: 0xFCF0E4), "SOC light tint")
        XCTAssertTrue(FireWireTheme.prefersBlackText(onRGB: 0xFFFFFF), "white")
        XCTAssertTrue(FireWireTheme.prefersBlackText(onRGB: 0xE5342A), "brand red (4.85:1 black vs 4.33:1 white, same as the server)")
    }

    func testWhiteOnDarkChips() {
        XCTAssertFalse(FireWireTheme.prefersBlackText(onRGB: 0x1C1C1E), "engine near-black")
        XCTAssertFalse(FireWireTheme.prefersBlackText(onRGB: 0x000000), "black")
        XCTAssertFalse(FireWireTheme.prefersBlackText(onRGB: 0x2F6FE4), "blue")
        XCTAssertFalse(FireWireTheme.prefersBlackText(onRGB: 0x7A4DD8), "purple")
    }

    func testLuminanceAndContrastRatio() {
        XCTAssertEqual(FireWireTheme.relativeLuminance(rgb: 0xFFFFFF), 1, accuracy: 0.0001)
        XCTAssertEqual(FireWireTheme.relativeLuminance(rgb: 0x000000), 0, accuracy: 0.0001)
        XCTAssertEqual(FireWireTheme.contrastRatio(luminance: 1, 0), 21, accuracy: 0.0001)
        XCTAssertEqual(FireWireTheme.contrastRatio(luminance: 0, 1), 21, accuracy: 0.0001)
    }

    func testContrastingTextResolvesPerAppearance() {
        let light = UITraitCollection(userInterfaceStyle: .light)
        let dark = UITraitCollection(userInterfaceStyle: .dark)
        // Translucent SOC tint: light = pale tint → black; dark = 20% orange over dark surface → white.
        let soc = FireWireTheme.contrastingText(on: FireWireTheme.unitSOCBackground)
        XCTAssertEqual(soc.resolvedColor(with: light).rgbComponents.red, 0, accuracy: 0.001)
        XCTAssertEqual(soc.resolvedColor(with: dark).rgbComponents.red, 1, accuracy: 0.001)
        // Missing fg from the server → auto on bg; invalid fg too.
        let onRed = FireWireTheme.unitText(light: nil, dark: "not-a-color", hasDarkBackground: false, on: FireWireTheme.red)
        XCTAssertEqual(onRed.resolvedColor(with: light).rgbComponents.red, 0, accuracy: 0.001)
        XCTAssertEqual(onRed.resolvedColor(with: dark).rgbComponents.red, 0, accuracy: 0.001)
        let onBlack = FireWireTheme.unitText(light: "#FF0000", dark: nil, hasDarkBackground: true, on: UIColor(rgb: 0x1C1C1E))
        XCTAssertEqual(onBlack.resolvedColor(with: light).rgbComponents.green, 0, accuracy: 0.001)  // explicit red kept
        XCTAssertEqual(onBlack.resolvedColor(with: dark).rgbComponents.green, 1, accuracy: 0.001)   // auto white
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
