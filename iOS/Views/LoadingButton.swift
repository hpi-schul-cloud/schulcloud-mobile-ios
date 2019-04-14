//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import UIKit

class LoadingButton: UIButton {

    private static let animationTime = 0.2

    private lazy var spinner: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .white)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()



    override func awakeFromNib() {
        super.awakeFromNib()
        self.addSubview(self.spinner)
        self.addConstraints([
            self.spinner.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.spinner.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.spinner.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.5),
            self.spinner.widthAnchor.constraint(equalTo: self.spinner.heightAnchor),
        ])
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.spinner.tintColor = self.tintColor
    }

    func startAnimation() {
        let hideTitleLabel: () -> Void = { [weak self] in self?.titleLabel?.layer.opacity = 0.0 }
        let showSpinner: () -> Void = { [weak self] in self?.spinner.alpha = 1.0 }
        self.spinner.startAnimating()
        UIView.animate(withDuration: LoadingButton.animationTime, delay: 0, options: .curveEaseIn, animations: hideTitleLabel) { [weak self] _ in
            self?.titleLabel?.isHidden = true
            UIView.animate(withDuration: LoadingButton.animationTime, delay: 0, options: .curveEaseOut, animations: showSpinner)
        }
    }

    func stopAnimation() {
        let hideSpinner: () -> Void = { [weak self] in self?.spinner.alpha = 0.0 }
        let showTitleLabel: () -> Void = { [weak self] in self?.titleLabel?.layer.opacity = 1.0 }
        self.titleLabel?.layer.opacity = 0.0
        self.titleLabel?.isHidden = false
        UIView.animate(withDuration: LoadingButton.animationTime, delay: 0, options: .curveEaseIn, animations: hideSpinner) { _ in
            UIView.animate(withDuration: LoadingButton.animationTime, delay: 0, options: .curveEaseOut, animations: showTitleLabel) { [weak self] _ in
                self?.spinner.startAnimating()
            }
        }
    }

}
