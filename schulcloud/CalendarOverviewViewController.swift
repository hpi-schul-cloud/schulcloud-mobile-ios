//
//  CalendarOverviewViewController.swift
//  schulcloud
//
//  Created by Max Bothe on 07.09.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import EventKit

class CalendarOverviewViewController: UIViewController {
    enum State {
        case currentEvent // Event, Event?
        case noEvents
    }

    @IBOutlet weak var currentEventName: UILabel!
    @IBOutlet weak var currentEventLocation: UILabel!
    @IBOutlet weak var currentEventDate: UILabel!
    @IBOutlet weak var nextEventName: UILabel!
    @IBOutlet weak var nextEventLocation: UILabel!
    @IBOutlet weak var nextEventDate: UILabel!
    @IBOutlet weak var currentEventProgress: UIProgressView!

    @IBOutlet weak var eventsOverview: UIStackView!
    @IBOutlet weak var noEventsView: UILabel!

    var state: CalendarOverviewViewController.State = .noEvents {
        didSet {
            self.updateUIForCurrentState()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateEvents()
    }

    func updateEvents() {
//        guard EKEventStore.authorizationStatus(for: .event) == .authorized else { return }
//        guard let calendar = CalendarHelper.schulCloudCalendar else { return [] }
    }

    func updateUIForCurrentState() {
        switch self.state {
        case .currentEvent:
            break
        case .noEvents:
            break
        }
    }
}
