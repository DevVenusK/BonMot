//
//  AnimatedNumberDemoViewController.swift
//  BonMot
//
//  Created by BonMot contributors.
//  Copyright © 2024 Rightpoint. All rights reserved.
//

import BonMot
import UIKit

/// A demo view controller showing AnimatedNumberLabel in action.
/// Demonstrates rolling animation when numbers change.
class AnimatedNumberDemoViewController: UIViewController {

    // MARK: - Properties

    private let animatedLabel = AnimatedNumberLabel()
    private let stepper = UIStepper()
    private let segmentedControl = UISegmentedControl(items: ["Up", "Down", "Auto"])

    private var currentValue: Int = 1_000_000

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateLabel(animated: false)
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Number Animation"
        view.backgroundColor = .white

        // Configure animated label
        animatedLabel.translatesAutoresizingMaskIntoConstraints = false
        animatedLabel.bonMotStyle = StringStyle(
            .font(UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .bold)),
            .color(.black)
        )
        animatedLabel.textAlignment = .center
        animatedLabel.animationDuration = 0.3
        animatedLabel.rollDirection = .up

        // Configure stepper
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.minimumValue = 0
        stepper.maximumValue = 10_000_000
        stepper.stepValue = 100_000
        stepper.value = Double(currentValue)
        stepper.addTarget(self, action: #selector(stepperValueChanged), for: .valueChanged)

        // Configure segmented control for roll direction
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(rollDirectionChanged), for: .valueChanged)

        // Labels
        let directionLabel = UILabel()
        directionLabel.translatesAutoresizingMaskIntoConstraints = false
        directionLabel.text = "Roll Direction:"
        directionLabel.font = .systemFont(ofSize: 14)
        directionLabel.textColor = .darkGray

        let instructionLabel = UILabel()
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.text = "Use the stepper to change the value.\nOnly changed digits will animate!"
        instructionLabel.font = .systemFont(ofSize: 14)
        instructionLabel.textColor = .gray
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0

        // Stack view for controls
        let controlsStack = UIStackView(arrangedSubviews: [directionLabel, segmentedControl])
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        controlsStack.axis = .horizontal
        controlsStack.spacing = 12
        controlsStack.alignment = .center

        // Add subviews
        view.addSubview(animatedLabel)
        view.addSubview(stepper)
        view.addSubview(controlsStack)
        view.addSubview(instructionLabel)

        // Layout
        NSLayoutConstraint.activate([
            animatedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animatedLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            animatedLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            animatedLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            stepper.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stepper.topAnchor.constraint(equalTo: animatedLabel.bottomAnchor, constant: 40),

            controlsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            controlsStack.topAnchor.constraint(equalTo: stepper.bottomAnchor, constant: 30),

            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.topAnchor.constraint(equalTo: controlsStack.bottomAnchor, constant: 30),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    // MARK: - Actions

    @objc private func stepperValueChanged(_ sender: UIStepper) {
        currentValue = Int(sender.value)
        updateLabel(animated: true)
    }

    @objc private func rollDirectionChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            animatedLabel.rollDirection = .up
        case 1:
            animatedLabel.rollDirection = .down
        case 2:
            animatedLabel.rollDirection = .automatic
        default:
            break
        }
    }

    // MARK: - Helpers

    private func updateLabel(animated: Bool) {
        let formattedValue = currencyFormatter.string(from: NSNumber(value: currentValue)) ?? "\(currentValue)"
        animatedLabel.setText(formattedValue + "원", animated: animated)
    }
}
