//
//  ViewController.swift
//  DatePickerCongig
//
//  Created by Issam Bendaas on 12/05/16.
//  Copyright © 2016 Issam Bendaas. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	
	let dayComponent = 0
	let monthComponent = 1
	let yearComponent = 2
	
	var selectedDay: Int!
	var selectedMonth: Int!
	var selectedYear: AnyObject! = "----"
	
	
	@IBOutlet weak var datePicker: IBDatePicker!
	
	let validPast: NSTimeInterval = -10000000000
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		datePicker.minimumDate = NSDate().dateByAddingTimeInterval(validPast)
		datePicker.maximumDate = NSDate()
		
	}
	
}

extension ViewController: IBDatePickerDelegate {
	
	func pickerView(pickerView: IBDatePicker, didSelectRow row: Int, inComponent component: Int) {
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateStyle = .ShortStyle
		//		self.label.text = dateFormatter.stringFromDate(pickerView.date)
	}
	
}
extension ViewController: UIPickerViewDataSource {
	
	func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
		return 3
	}
	
	func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		switch component {
		case dayComponent:
			return 30
		case monthComponent:
			return 12
		default:
			return (2016 - 1900)
		}
	}
	
	func getDaysInMonth(month: Int, year: Int) -> Int {
		let dateComponents = NSDateComponents()
		
		dateComponents.year = year
		dateComponents.month = month
		let calendar = NSCalendar.currentCalendar()
		let date = calendar.dateFromComponents(dateComponents)
		let range = calendar.rangeOfUnit(.Day, inUnit: .Month, forDate: date!)
		
		return range.length
		
		//		NSDateComponents *comps = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
		//
		//		NSUInteger month = [pickerView selectedRowInComponent:1]+1 ;
		//		NSUInteger actualYear = [comps year];
		//
		//		NSDateComponents *selectMothComps = [[NSDateComponents alloc] init];
		//		selectMothComps.year = actualYear;
		//		selectMothComps.month = month;
		//		selectMothComps.day = 1;
		//
		//		NSDateComponents *nextMothComps = [[NSDateComponents alloc] init];
		//		nextMothComps.year = actualYear;
		//		nextMothComps.month = month+1;
		//		nextMothComps.day = 1;
		//
		//		NSDate *thisMonthDate = [[NSCalendar currentCalendar] dateFromComponents:selectMothComps];
		//		NSDate *nextMonthDate = [[NSCalendar currentCalendar] dateFromComponents:nextMothComps];
		//
		//		NSDateComponents *differnce = [[NSCalendar currentCalendar]  components:NSDayCalendarUnit
		//		fromDate:thisMonthDate
		//		toDate:nextMonthDate
		//		options:0];
		//
		//		number = [differnce day];
		//		ret
	}
}

//extension ViewController: UIPickerViewDelegate {
//
////	func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
////
////	}
//
//	func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
//		return 44
//	}
//	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//
//		switch component {
//		case 0:
//			return String(row + 1)
//		case 1:
//			return "May"
//		case 2:
////			if row
//			return "May"
//		default:
//			return "----"
//		}
//	}
//}


