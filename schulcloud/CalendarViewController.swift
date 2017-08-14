import UIKit
import CalendarKit
import DateToolsSwift

enum SelectedStyle {
    case Dark
    case Light
}

class CalendarViewController: DayViewController {
    
    var data = [["Breakfast at Tiffany's",
                 "New York, 5th avenue"],
                
                ["Workout",
                 "Tufteparken"],
                
                ["Meeting with Alex",
                 "Home",
                 "Oslo, Tjuvholmen"],
                
                ["Beach Volleyball",
                 "Ipanema Beach",
                 "Rio De Janeiro"],
                
                ["WWDC",
                 "Moscone West Convention Center",
                 "747 Howard St"],
                
                ["Google I/O",
                 "Shoreline Amphitheatre",
                 "One Amphitheatre Parkway"],
                
                ["✈️️ to Svalbard ❄️️❄️️❄️️❤️️",
                 "Oslo Gardermoen"],
                
                ["💻📲 Developing CalendarKit",
                 "🌍 Worldwide"],
                
                ["Software Development Lecture",
                 "Mikpoli MB310",
                 "Craig Federighi"],
                
                ]
    
    var colors = [UIColor.blue,
                  UIColor.yellow,
                  UIColor.black,
                  UIColor.green,
                  UIColor.red]
    
    var currentStyle = SelectedStyle.Light
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = false
        reloadData()
        //get hour
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        dayView.scrollTo(hour24: Float(hour))
    }
    
        // MARK: DayViewDataSource
    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
        var date = date.add(TimeChunk(seconds: 0,
                                      minutes: 0,
                                      hours: Int(arc4random_uniform(10) + 5),
                                      days: 0,
                                      weeks: 0,
                                      months: 0,
                                      years: 0))
        var events = [Event]()
        
        for i in 0...5 {
            let event = Event()
            let duration = Int(arc4random_uniform(160) + 60)
            let datePeriod = TimePeriod(beginning: date,
                                        chunk: TimeChunk(seconds: 0,
                                                         minutes: duration,
                                                         hours: 0,
                                                         days: 0,
                                                         weeks: 0,
                                                         months: 0,
                                                         years: 0))
            
            event.datePeriod = datePeriod
            var info = data[Int(arc4random_uniform(UInt32(data.count)))]
            info.append("\(datePeriod.beginning!.format(with: "HH:mm")) - \(datePeriod.end!.format(with: "HH:mm"))")
            event.text = info.reduce("", {$0 + $1 + "\n"})
            event.color = colors[Int(arc4random_uniform(UInt32(colors.count)))]
            events.append(event)
            
            let nextOffset = Int(arc4random_uniform(250) + 40)
            date = date.add(TimeChunk(seconds: 0,
                                      minutes: nextOffset,
                                      hours: 0,
                                      days: 0,
                                      weeks: 0,
                                      months: 0,
                                      years: 0))
            event.userInfo = String(i)
        }
        
        return events
    }
    
    // MARK: DayViewDelegate
    override func dayViewDidSelectEventView(_ eventView: EventView) {
        guard let descriptor = eventView.descriptor as? Event else {
            return
        }
        print("Event has been selected: \(descriptor) \(String(describing: descriptor.userInfo))")
    }
    
    override func dayViewDidLongPressEventView(_ eventView: EventView) {
        guard let descriptor = eventView.descriptor as? Event else {
            return
        }
        print("Event has been longPressed: \(descriptor) \(String(describing: descriptor.userInfo))")
    }
    
    override func dayView(dayView: DayView, willMoveTo date: Date) {
        //    print("DayView = \(dayView) will move to: \(date)")
    }
    
    override func dayView(dayView: DayView, didMoveTo date: Date) {
        //    print("DayView = \(dayView) did move to: \(date)")
    }
}
