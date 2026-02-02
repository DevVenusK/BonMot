//
//  StyleViewController.swift
//  BonMot
//
//  Created by Brian King on 8/26/16.
//  Copyright © 2016 Rightpoint. All rights reserved.
//

import BonMot
import UIKit

/// UITableViewCell's built in labels are re-created when the content size
/// category changes, so we use a cell subclass with a custom label to avoid this.
class BaseTableViewCell: UITableViewCell {

    @IBOutlet var titleLabel: UILabel?

}

class StyleViewController: UITableViewController {
    var styles: [(String, [NSAttributedString])] = [
        ("Simple Use Case", [DemoStrings.simpleExample]),
        ("XML", [
            DemoStrings.xmlExample,
            DemoStrings.xmlWithEmphasis,
            ]),
        ("Composition", [DemoStrings.compositionExample]),
        ("Images & Special Characters", [DemoStrings.imagesExample, DemoStrings.noBreakSpaceExample]),
        ("Baseline Offset", [DemoStrings.heartsExample]),
        ("Indentation", DemoStrings.indentationExamples),
        ("Advanced XML and Kerning", [DemoStrings.advancedXMLAndKerningExample]),
        ("Dynamic Type", [DemoStrings.dynamicTypeUIKitExample, DemoStrings.preferredFontsExample]),
        ("OpenType Features", [
            DemoStrings.figureStylesExample,
            DemoStrings.ordinalsExample,
            DemoStrings.scientificInferiorsExample,
            DemoStrings.fractionsExample,
            DemoStrings.stylisticAlternatesExample,
            ]),
        ("Accessibility Speech", DemoStrings.accessibilitySpeechExamples),
        ("Animated Numbers", [DemoStrings.animatedNumberExample]),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
    }

    func cell(at indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "StyleCell", for: indexPath) as? BaseTableViewCell else {
            fatalError("Misconfigured VC")
        }
        let attributedText = styles[indexPath.section].1[indexPath.row]
        cell.titleLabel?.attributedText = attributedText.adapted(to: traitCollection)
        let hasStoryboard = attributedText.attribute("Storyboard", at: 0, effectiveRange: nil) != nil
        let hasViewControllerClass = attributedText.attribute("ViewControllerClass", at: 0, effectiveRange: nil) != nil
        cell.accessoryType = (hasStoryboard || hasViewControllerClass) ? .disclosureIndicator : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let attributedText = styles[indexPath.section].1[indexPath.row]
        if attributedText.attribute("Storyboard", at: 0, effectiveRange: nil) is String {
            return true
        }
        if attributedText.attribute("ViewControllerClass", at: 0, effectiveRange: nil) is String {
            return true
        }
        return false
    }

    func selectRow(at indexPath: IndexPath) {
        let attributedText = styles[indexPath.section].1[indexPath.row]
        if let storyboardIdentifier = attributedText.attribute("Storyboard", at: 0, effectiveRange: nil) as? String {
            guard let nextVC = storyboard?.instantiateViewController(withIdentifier: storyboardIdentifier) else {
                fatalError("No Storyboard identifier \(storyboardIdentifier)")
            }
            navigationController?.pushViewController(nextVC, animated: true)
        }
        else if let className = attributedText.attribute("ViewControllerClass", at: 0, effectiveRange: nil) as? String {
            let nextVC = instantiateViewController(className: className)
            navigationController?.pushViewController(nextVC, animated: true)
        }
        else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    private func instantiateViewController(className: String) -> UIViewController {
        switch className {
        case "AnimatedNumberDemoViewController":
            return AnimatedNumberDemoViewController()
        default:
            fatalError("Unknown view controller class: \(className)")
        }
    }
}

extension StyleViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return styles.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return styles[section].1.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cell(at: indexPath)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return styles[section].0
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectRow(at: indexPath)
    }
}
