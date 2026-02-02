//
//  AnimatedNumberLabel.swift
//  BonMot
//
//  Created by BonMot contributors.
//  Copyright © 2024 Rightpoint. All rights reserved.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// A view that displays numbers with a rolling animation when digits change.
/// When the value changes, only the modified digits animate with a roll-up effect.
///
/// Example:
/// ```swift
/// let label = AnimatedNumberLabel()
/// label.bonMotStyle = StringStyle(.font(.systemFont(ofSize: 24)), .color(.black))
/// label.setText("1,000,000원", animated: false)
/// label.setText("1,100,000원", animated: true) // Only the changed digit rolls up
/// ```
@objc(BONAnimatedNumberLabel)
public class AnimatedNumberLabel: UIView {

    // MARK: - Types

    /// The direction of the roll animation.
    @objc(BONAnimatedNumberLabelRollDirection)
    public enum RollDirection: Int {
        /// Always roll upward.
        case up
        /// Always roll downward.
        case down
        /// Automatically determine direction based on digit value change.
        /// Rolls up when digit increases, down when digit decreases.
        case automatic
    }

    // MARK: - Public Properties

    /// The direction of the roll animation. Defaults to `.up`.
    public var rollDirection: RollDirection = .up

    /// The duration of the roll animation in seconds.
    public var animationDuration: TimeInterval = 0.3

    /// The animation curve for the roll effect.
    public var animationCurve: UIView.AnimationOptions = .curveEaseInOut

    /// The current text being displayed.
    public private(set) var text: String = ""

    /// A string style applied to all character labels.
    public var bonMotStyle: StringStyle? {
        didSet {
            applyStyleToAllLabels()
        }
    }

    /// The name of a style in the global `NamedStyles` registry.
    @IBInspectable
    public var bonMotStyleName: String? {
        get { return nil }
        set {
            guard let name = newValue, let style = NamedStyles.shared.style(forName: name) else {
                bonMotStyle = nil
                return
            }
            bonMotStyle = style
        }
    }

    /// The font for the labels. If bonMotStyle has a font, this is ignored.
    public var font: UIFont = .systemFont(ofSize: 17) {
        didSet {
            applyStyleToAllLabels()
        }
    }

    /// The text color for the labels. If bonMotStyle has a color, this is ignored.
    public var textColor: UIColor = .black {
        didSet {
            applyStyleToAllLabels()
        }
    }

    /// Text alignment within the view.
    public var textAlignment: NSTextAlignment = .left {
        didSet {
            updateAlignment()
        }
    }

    // MARK: - Private Properties

    private let containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var characterContainers: [CharacterContainerView] = []

    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    private var centerXConstraint: NSLayoutConstraint?

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        clipsToBounds = true
        addSubview(containerStackView)

        leadingConstraint = containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor)
        trailingConstraint = containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        centerXConstraint = containerStackView.centerXAnchor.constraint(equalTo: centerXAnchor)

        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        updateAlignment()
    }

    private func updateAlignment() {
        leadingConstraint?.isActive = false
        trailingConstraint?.isActive = false
        centerXConstraint?.isActive = false

        switch textAlignment {
        case .left, .natural:
            leadingConstraint?.isActive = true
        case .right:
            trailingConstraint?.isActive = true
        case .center:
            centerXConstraint?.isActive = true
        case .justified:
            leadingConstraint?.isActive = true
            trailingConstraint?.isActive = true
        @unknown default:
            leadingConstraint?.isActive = true
        }
    }

    // MARK: - Public Methods

    /// Sets the text with optional animation.
    /// - Parameters:
    ///   - newText: The new text to display.
    ///   - animated: If true, changed characters will animate with a roll-up effect.
    ///   - completion: Called when the animation completes.
    public func setText(_ newText: String, animated: Bool, completion: (() -> Void)? = nil) {
        let oldText = text
        text = newText

        if !animated || oldText.isEmpty {
            rebuildLabels(for: newText)
            completion?()
            return
        }

        animateTextChange(from: oldText, to: newText, completion: completion)
    }

    /// Sets a numeric value with formatting.
    /// - Parameters:
    ///   - value: The numeric value to display.
    ///   - formatter: A NumberFormatter to format the value.
    ///   - suffix: An optional suffix (e.g., "원", "$").
    ///   - animated: If true, changed digits will animate.
    ///   - completion: Called when the animation completes.
    public func setValue(_ value: NSNumber, formatter: NumberFormatter, suffix: String? = nil, animated: Bool, completion: (() -> Void)? = nil) {
        var formattedText = formatter.string(from: value) ?? "\(value)"
        if let suffix = suffix {
            formattedText += suffix
        }
        setText(formattedText, animated: animated, completion: completion)
    }

    // MARK: - Private Methods

    private func rebuildLabels(for text: String) {
        // Remove all existing containers
        characterContainers.forEach { $0.removeFromSuperview() }
        characterContainers.removeAll()

        // Create new containers for each character
        for char in text {
            let container = createCharacterContainer(for: String(char))
            containerStackView.addArrangedSubview(container)
            characterContainers.append(container)
        }
    }

    private func createCharacterContainer(for character: String) -> CharacterContainerView {
        let container = CharacterContainerView()
        container.clipsToBounds = true

        let label = createLabel(for: character)
        container.currentLabel = label
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        return container
    }

    private func createLabel(for text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false

        if let style = bonMotStyle {
            label.attributedText = text.styled(with: style)
        } else {
            label.text = text
            label.font = font
            label.textColor = textColor
        }

        label.textAlignment = .center
        return label
    }

    private func applyStyleToAllLabels() {
        for container in characterContainers {
            if let label = container.currentLabel {
                let text = label.text ?? ""
                if let style = bonMotStyle {
                    label.attributedText = text.styled(with: style)
                } else {
                    label.font = font
                    label.textColor = textColor
                }
            }
        }
    }

    private func animateTextChange(from oldText: String, to newText: String, completion: (() -> Void)?) {
        let oldChars = Array(oldText)
        let newChars = Array(newText)

        // Find the differences
        let maxLength = max(oldChars.count, newChars.count)
        var changedIndices: [Int] = []

        // Align from the end for currency-like numbers
        let oldOffset = maxLength - oldChars.count
        let newOffset = maxLength - newChars.count

        for i in 0..<maxLength {
            let oldIndex = i - oldOffset
            let newIndex = i - newOffset

            let oldChar: Character? = (oldIndex >= 0 && oldIndex < oldChars.count) ? oldChars[oldIndex] : nil
            let newChar: Character? = (newIndex >= 0 && newIndex < newChars.count) ? newChars[newIndex] : nil

            if oldChar != newChar {
                changedIndices.append(i)
            }
        }

        // If length changed significantly, just rebuild
        if abs(oldChars.count - newChars.count) > 2 || changedIndices.count > newChars.count / 2 {
            rebuildWithAnimation(to: newText, completion: completion)
            return
        }

        // Adjust containers if needed
        adjustContainerCount(to: newChars.count)

        // Animate changed characters
        let animationGroup = DispatchGroup()

        for (index, char) in newChars.enumerated() {
            let oldIndex = index - newOffset + oldOffset
            let oldChar: Character? = (oldIndex >= 0 && oldIndex < oldChars.count) ? oldChars[oldIndex] : nil

            if oldChar != char {
                animationGroup.enter()
                animateCharacter(at: index, from: oldChar.map { String($0) }, to: String(char)) {
                    animationGroup.leave()
                }
            } else if index < characterContainers.count {
                // Update non-animated characters
                if let label = characterContainers[index].currentLabel {
                    updateLabel(label, with: String(char))
                }
            }
        }

        animationGroup.notify(queue: .main) {
            completion?()
        }
    }

    private func adjustContainerCount(to count: Int) {
        while characterContainers.count > count {
            if let last = characterContainers.popLast() {
                last.removeFromSuperview()
            }
        }

        while characterContainers.count < count {
            let container = createCharacterContainer(for: "")
            containerStackView.addArrangedSubview(container)
            characterContainers.append(container)
        }
    }

    private func animateCharacter(at index: Int, from oldChar: String?, to newChar: String, completion: @escaping () -> Void) {
        guard index < characterContainers.count else {
            completion()
            return
        }

        let container = characterContainers[index]
        let oldLabel = container.currentLabel

        // Determine roll direction
        let shouldRollUp = determineRollDirection(from: oldChar, to: newChar)

        // Create new label
        let newLabel = createLabel(for: newChar)
        container.addSubview(newLabel)

        NSLayoutConstraint.activate([
            newLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            newLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            newLabel.heightAnchor.constraint(equalTo: container.heightAnchor),
        ])

        // Position new label based on roll direction
        let initialOffset = shouldRollUp ? container.bounds.height : -container.bounds.height
        let topConstraint = newLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: initialOffset)
        topConstraint.isActive = true

        container.layoutIfNeeded()

        // Animate
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
            // Move old label out
            if let oldLabel = oldLabel {
                let exitOffset = shouldRollUp ? -container.bounds.height : container.bounds.height
                oldLabel.transform = CGAffineTransform(translationX: 0, y: exitOffset)
                oldLabel.alpha = 0
            }

            // Move new label into position
            topConstraint.constant = 0
            container.layoutIfNeeded()
        }, completion: { _ in
            oldLabel?.removeFromSuperview()
            container.currentLabel = newLabel
            completion()
        })
    }

    private func determineRollDirection(from oldChar: String?, to newChar: String) -> Bool {
        switch rollDirection {
        case .up:
            return true
        case .down:
            return false
        case .automatic:
            // Compare digit values if both are digits
            guard let oldChar = oldChar,
                  let oldDigit = Int(oldChar),
                  let newDigit = Int(newChar) else {
                return true // Default to up for non-numeric characters
            }
            // Roll up when increasing, down when decreasing
            return newDigit > oldDigit
        }
    }

    private func rebuildWithAnimation(to newText: String, shouldRollUp: Bool = true, completion: (() -> Void)?) {
        let oldContainers = characterContainers
        characterContainers = []

        let rollUp = (rollDirection == .down) ? false : shouldRollUp

        // Create new containers
        for char in newText {
            let container = createCharacterContainer(for: String(char))
            container.alpha = 0
            let initialOffset = rollUp ? bounds.height / 2 : -bounds.height / 2
            container.transform = CGAffineTransform(translationX: 0, y: initialOffset)
            containerStackView.addArrangedSubview(container)
            characterContainers.append(container)
        }

        UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
            // Fade out old
            let exitOffset = rollUp ? -self.bounds.height / 2 : self.bounds.height / 2
            for container in oldContainers {
                container.alpha = 0
                container.transform = CGAffineTransform(translationX: 0, y: exitOffset)
            }
            // Fade in new
            for container in self.characterContainers {
                container.alpha = 1
                container.transform = .identity
            }
        }, completion: { _ in
            oldContainers.forEach { $0.removeFromSuperview() }
            completion?()
        })
    }

    private func updateLabel(_ label: UILabel, with text: String) {
        if let style = bonMotStyle {
            label.attributedText = text.styled(with: style)
        } else {
            label.text = text
        }
    }

    // MARK: - Intrinsic Content Size

    public override var intrinsicContentSize: CGSize {
        return containerStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
}

// MARK: - CharacterContainerView

/// A container view that holds a single character label and manages its animation.
private class CharacterContainerView: UIView {

    var currentLabel: UILabel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        translatesAutoresizingMaskIntoConstraints = false
    }

    override var intrinsicContentSize: CGSize {
        return currentLabel?.intrinsicContentSize ?? .zero
    }

    override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        currentLabel?.invalidateIntrinsicContentSize()
    }
}

#endif
