
import UIKit

public class IBDatePicker: UIControl, UIPickerViewDataSource, UIPickerViewDelegate {
	
	// MARK: -
	// MARK: Public Properties
	
	/// The font for the date picker.
	public var font = UIFont.systemFontOfSize(25.0)
	
	/// The text color for the date picker components.
	public var textColor = UIColor.blackColor()
	
	public var completionHandler: ((datePicker: IBDatePicker, row: Int, component: Int) -> Void)?
	//	public var completionHandler: ((datePicker: IBDatePicker, row: Int, component: Int) -> Void)?
	
	/// The minimum date to show for the date picker. Set to NSDate.distantPast() by default
	public var minimumDate = NSDate.distantPast() {
		didSet {
			self.validateMinimumAndMaximumDate()
		}
	}
	
	/// The maximum date to show for the date picker. Set to NSDate.distantFuture() by default
	public var maximumDate = NSDate.distantFuture() {
		didSet {
			let dateComponents = NSDateComponents()
			dateComponents.year = 1
			maximumDate = calendar.dateByAddingComponents(dateComponents, toDate: maximumDate, options: .MatchFirst)!
			setDate(maximumDate, animated: true)
			self.validateMinimumAndMaximumDate()
		}
	}
	
	/// The current locale to use for formatting the date picker. By default, set to the device's current locale
	public var locale : NSLocale = NSLocale.currentLocale() {
		didSet {
			self.calendar.locale = self.locale
		}
	}
	
	/// The current date value of the date picker.
	public private(set) var date = NSDate()
	
	// MARK: -
	// MARK: Private Variables
	
	private let maximumNumberOfRows = Int(INT16_MAX)
	
	/// The internal picker view used for laying out the date components.
	private let pickerView = UIPickerView()
	
	/// The calendar used for formatting dates.
	private var calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
	
	/// Calculates the current calendar components for the current date.
	private var currentCalendarComponents : NSDateComponents {
		get {
			return self.calendar.components([.Year, .Month, .Day], fromDate: self.date)
		}
	}
	
	/// Calculates today's calendar components for the current date.
	private var todayCalendarComponents : NSDateComponents {
		get {
			return self.calendar.components([.Year, .Month, .Day], fromDate: NSDate())
		}
	}
	
	/// Gets the text color to be used for the label in a disabled state
	private var disabledTextColor : UIColor {
		get {
			var r : CGFloat = 0
			var g : CGFloat = 0
			var b : CGFloat = 0
			
			self.textColor.getRed(&r, green: &g, blue: &b, alpha: nil)
			
			return UIColor(red: r, green: g, blue: b, alpha: 0.35)
		}
	}
	
	/// The order in which each component should be ordered in.
	private var datePickerComponentOrdering = [IBDatePickerComponents]()
	
	// MARK: -
	// MARK: LifeCycle
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.commonInit()
	}
	
	override public init(frame: CGRect) {
		super.init(frame: frame)
		self.commonInit()
	}
	
	
	/**
	Handles the common initialization amongst all init()
	*/
	private func commonInit() {
		self.translatesAutoresizingMaskIntoConstraints = false
		self.pickerView.translatesAutoresizingMaskIntoConstraints = false
		
		self.pickerView.dataSource = self
		self.pickerView.delegate = self
		
		self.addSubview(self.pickerView)
		
		let topConstraint = NSLayoutConstraint(item: self.pickerView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0)
		let bottomConstraint = NSLayoutConstraint(item: self.pickerView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0)
		let leftConstraint = NSLayoutConstraint(item: self.pickerView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0)
		let rightConstraint = NSLayoutConstraint(item: self.pickerView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: 0)
		self.addConstraints([topConstraint, leftConstraint, bottomConstraint, rightConstraint])
		
	}
	
	
	
	// MARK: -
	// MARK: Override
	public override func intrinsicContentSize() -> CGSize {
		return self.pickerView.intrinsicContentSize()
	}
	
	public override func willMoveToSuperview(newSuperview: UIView?) {
		super.willMoveToSuperview(newSuperview)
		self.reloadAllComponents()
		
		self.setDate(self.date)
	}
	
	// MARK: -
	// MARK: Public
	
	/**
	Reset DatePicker so it shows today's day. Month. ----
	*/
	public func resetDatePicker() {
		self.maximumDate = NSDate()
	}
	
	/**
	Reloads all of the components in the date picker.
	*/
	public func reloadAllComponents() {
		self.refreshComponentOrdering()
		self.pickerView.reloadAllComponents()
	}
	
	/**
	Sets the current date value for the date picker.
	
	:param: date     The date to set the picker to.
	:param: animated True if the date picker should changed with an animation; otherwise false,
	*/
	public func setDate(date : NSDate, animated : Bool) {
		self.date = date
		self.updatePickerViewComponentValuesAnimated(animated)
	}
	
	// MARK: -
	// MARK: Private
	
	/**
	Sets the current date with no animation.
	
	:param: date The date to be set.
	*/
	private func setDate(date : NSDate) {
		self.setDate(date, animated: false)
	}
	
	/**
	Creates a new date formatter with the locale and calendar
	
	:returns: A new instance of NSDateFormatter
	*/
	private func dateFormatter() -> NSDateFormatter {
		let dateFormatter = NSDateFormatter()
		dateFormatter.calendar = self.calendar
		dateFormatter.locale = self.locale
		
		return dateFormatter
	}
	
	/**
	Refreshes the ordering of components based on the current locale. Calling this function will not refresh the picker view.
	*/
	private func refreshComponentOrdering() {
		guard var componentOrdering = NSDateFormatter.dateFormatFromTemplate("yMMMMd", options: 0, locale: self.locale) else {
			return
		}
		
		let firstComponentOrderingString = componentOrdering[componentOrdering.startIndex.advancedBy(0)]
		let lastComponentOrderingString = componentOrdering[componentOrdering.startIndex.advancedBy(componentOrdering.characters.count - 1)]
		let characterSet = NSMutableCharacterSet()
		
		characterSet.formUnionWithCharacterSet(NSCharacterSet(charactersInString: String(firstComponentOrderingString) +
			String(lastComponentOrderingString)))
		characterSet.formUnionWithCharacterSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
		characterSet.formUnionWithCharacterSet(NSCharacterSet.punctuationCharacterSet())
		
		componentOrdering = componentOrdering.stringByTrimmingCharactersInSet(characterSet)
		let remainingValue = componentOrdering[componentOrdering.startIndex.advancedBy(0)]
		
		let firstComponent = IBDatePickerComponents(rawValue: firstComponentOrderingString)
		let secondComponent = IBDatePickerComponents(rawValue: remainingValue)
		let lastComponent = IBDatePickerComponents(rawValue: lastComponentOrderingString)
		
		guard let first = firstComponent, let second = secondComponent, let third = lastComponent else {
			return
		}
		
		self.datePickerComponentOrdering = [first, second, third]
	}
	
	/**
	Validates that the set minimum and maximum dates are valid.
	*/
	private func validateMinimumAndMaximumDate() {
		let ordering = self.minimumDate.compare(self.maximumDate)
		if (ordering != .OrderedAscending ){
			fatalError("Cannot set a maximum date that is equal or less than the minimum date.")
		}
	}
	
	/**
	Gets the value of the current component at the specified row.
	
	:param: row            The row index whose value is required
	:param: componentIndex The component index for the row.
	
	:returns: A string containing the value of the current row at the component index.
	*/
	private func titleForRow(row : Int, inComponentIndex componentIndex: Int) -> String {
		let dateComponent = self.componentAtIndex(componentIndex)
		
		let value = self.rawValueForRow(row, inComponent: dateComponent)
		switch dateComponent {
		case IBDatePickerComponents.Day:
			return "\(value)."
		case IBDatePickerComponents.Month:
			let dateFormatter = self.dateFormatter()
			return dateFormatter.monthSymbols[value - 1]
		case IBDatePickerComponents.Year:
			return stringFromYear(value)
		default:
			return String(value)
		}
	}
	
	private func stringFromYear(year: Int) -> String {
		
		if year == maxValueForComponent(.Year){
			return "----"
		} else if (year > maxValueForComponent(.Year) + 1) {
			return ""
		}
		
		return String(year)
	}
	
	/**
	Gets the value of the input component using the current date.
	
	:param: component The component whose value is needed.
	
	:returns: The value of the component.
	*/
	private func valueForDateComponent(component : IBDatePickerComponents) -> Int{
		if component == .Year {
			return self.currentCalendarComponents.year
		} else if component == .Day {
			return self.currentCalendarComponents.day
		} else {
			return self.currentCalendarComponents.month
		}
	}
	
	/**
	Gets the maximum range for the specified date picker component.
	
	:param: component The component to get the range for.
	
	:returns: The maximum date range for that component.
	*/
	private func maximumRangeForComponent(component : IBDatePickerComponents) -> NSRange {
		var calendarUnit : NSCalendarUnit
		if component == .Year {
			calendarUnit = .Year
		} else if component == .Day {
			calendarUnit = .Day
		} else {
			calendarUnit = .Month
		}
		
		return self.calendar.maximumRangeOfUnit(calendarUnit)
	}
	
	/**
	Calculates the raw value of the row at the current index.
	
	:param: row       The row to get.
	:param: component The component which the row belongs to.
	
	:returns: The raw value of the row, in integer. Use NSDateComponents to convert to a usable date object.
	*/
	private func rawValueForRow(row : Int, inComponent component : IBDatePickerComponents) -> Int {
		let calendarUnitRange = self.maximumRangeForComponent(component)
		return calendarUnitRange.location + (row % calendarUnitRange.length)
	}
	
	/**
	Checks if the specified row should be enabled or not.
	
	:param: row       The row to check.
	:param: component The component to check the row in.
	
	:returns: YES if the row should be enabled; otherwise NO.
	*/
	private func isRowEnabled(row: Int, forComponent component : IBDatePickerComponents) -> Bool {
		
		let rawValue = self.rawValueForRow(row, inComponent: component)
		
		let components = NSDateComponents()
		components.year = self.currentCalendarComponents.year
		components.month = self.currentCalendarComponents.month
		components.day = self.currentCalendarComponents.day
		
		if component == .Year {
			components.year = rawValue
		} else if component == .Day {
			components.day = rawValue
		} else if component == .Month {
			components.month = rawValue
		}
		
		let dateForRow = self.calendar.dateFromComponents(components)!
		
		return self.dateIsInRange(dateForRow)
	}
	
	/**
	Checks if the input date falls within the date picker's minimum and maximum date ranges.
	
	:param: date The date to be checked.
	
	:returns: True if the input date is within range of the minimum and maximum; otherwise false.
	*/
	private func dateIsInRange(date : NSDate) -> Bool {
		return self.minimumDate.compare(date) != NSComparisonResult.OrderedDescending &&
			self.maximumDate.compare(date) != NSComparisonResult.OrderedAscending
	}
	
	/**
	Updates all of the date picker components to the value of the current date.
	
	:param: animated True if the update should be animated; otherwise false.
	*/
	private func updatePickerViewComponentValuesAnimated(animated : Bool) {
		for (_, dateComponent) in self.datePickerComponentOrdering.enumerate() {
			self.setIndexOfComponent(dateComponent, animated: animated)
		}
	}
	
	/**
	Updates the index of the specified component to its relevant value in the current date.
	
	:param: component The component to be updated.
	:param: animated  True if the update should be animated; otherwise false.
	*/
	private func setIndexOfComponent(component : IBDatePickerComponents, animated: Bool) {
		self.setIndexOfComponent(component, toValue: self.valueForDateComponent(component), animated: animated)
	}
	
	/**
	Updates the index of the specified component to the input value.
	
	:param: component The component to be updated.
	:param: value     The value the component should be updated ot.
	:param: animated  True if the update should be animated; otherwise false.
	*/
	private func setIndexOfComponent(component : IBDatePickerComponents, toValue value : Int, animated: Bool) {
		let componentRange = self.maximumRangeForComponent(component)
		
		let idx = (value - componentRange.location)
		let middleIndex = (self.maximumNumberOfRows / 2) - (maximumNumberOfRows / 2) % componentRange.length + idx
		
		var componentIndex = 0
		
		for (index, dateComponent) in self.datePickerComponentOrdering.enumerate() {
			if (dateComponent == component) {
				componentIndex = index
			}
		}
		
		self.pickerView.selectRow(middleIndex, inComponent: componentIndex, animated: animated)
	}
	
	/**
	Gets the component type at the current component index.
	
	:param: index The component index
	
	:returns: The date picker component type at the index.
	*/
	private func componentAtIndex(index: Int) -> IBDatePickerComponents {
		return self.datePickerComponentOrdering[index]
	}
	
	/**
	Gets the number of days of the specified month in the specified year.
	
	:param: month The month whose maximum date value is requested.
	:param: year  The year for which the maximum date value is required.
	
	:returns: The number of days in the month.
	*/
	private func numberOfDaysForMonth(month : Int, inYear year : Int) -> Int {
		let components = NSDateComponents()
		components.month = month
		components.day = 1
		components.year = year
		
		let calendarRange = self.calendar.rangeOfUnit(.Day, inUnit: .Month, forDate: self.calendar.dateFromComponents(components)!)
		let numberOfDaysInMonth = calendarRange.length
		
		return numberOfDaysInMonth
	}
	
	/**
	Determines if updating the specified component to the input value would evaluate to a valid date using the current date values.
	
	:param: value     The value to be updated to.
	:param: component The component whose value should be updated.
	
	:returns: True if updating the component to the specified value would result in a valid date; otherwise false.
	*/
	private func isValidValue(value : Int, forComponent component: IBDatePickerComponents) -> Bool {
		if (component == .Year) {
			let numberOfDaysInMonth = self.numberOfDaysForMonth(self.currentCalendarComponents.month, inYear: value)
			return self.currentCalendarComponents.day <= numberOfDaysInMonth
		} else if (component == .Day) {
			let numberOfDaysInMonth = self.numberOfDaysForMonth(self.currentCalendarComponents.month, inYear: self.currentCalendarComponents.year)
			return value <= numberOfDaysInMonth
		} else if (component == .Month) {
			let numberOfDaysInMonth = self.numberOfDaysForMonth(value, inYear: self.currentCalendarComponents.year)
			return self.currentCalendarComponents.day <= numberOfDaysInMonth
		}
		
		return true
	}
	
	/**
	Creates date components by updating the specified component to the input value. This does not do any date validation.
	
	:param: component The component to be updated.
	:param: value     The value the component should be updated to.
	
	:returns: The components by updating the current date's components to the specified value.
	*/
	private func currentCalendarComponentsByUpdatingComponent(component : IBDatePickerComponents, toValue value : Int) -> NSDateComponents {
		let components = self.currentCalendarComponents
		
		if (component == .Month) {
			components.month = value
		} else if (component == .Day) {
			components.day = value
		} else {
			components.year = value
		}
		
		return components
	}
	
	/**
	Creates date components by updating the specified component to the input value. If the resulting value is not a valid date object, the components will be updated to the closest best value.
	
	:param: component The component to be updated.
	:param: value     The value the component should be updated to.
	
	:returns: The components by updating the specified value; the components will be a valid date object.
	*/
	private func validDateValueByUpdatingComponent(component : IBDatePickerComponents, toValue value : Int) -> NSDateComponents {
		let components = self.currentCalendarComponentsByUpdatingComponent(component, toValue: value)
		
		if (!self.isValidValue(value, forComponent: component)) {
			if (component == .Month) {
				components.day = self.numberOfDaysForMonth(value, inYear: components.year)
			} else if (component == .Day) {
				components.day = self.numberOfDaysForMonth(components.month, inYear:components.year)
			} else {
				components.day = self.numberOfDaysForMonth(components.month, inYear: value)
			}
		}
		
		return components
	}
	
	// MARK: -
	// MARK: Protocols
	// MARK: UIPickerViewDelegate
	
	public func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		
		// If the year not set yet, do nothing
		if !yearIsSet() { return }
		
		let datePickerComponent = self.componentAtIndex(component)
		let value = self.rawValueForRow(row, inComponent: datePickerComponent)
		
		// Create the newest valid date components.
		let components = self.validDateValueByUpdatingComponent(datePickerComponent, toValue: value)
		
		// If the resulting components are not in the date range ...
		if (!self.dateIsInRange(self.calendar.dateFromComponents(components)!)) {
			// ... go back to original date
			self.setDate(self.date, animated: true)
		} else {
			
			// Get the components that would result by just force-updating the current components.
			let rawComponents = self.currentCalendarComponentsByUpdatingComponent(datePickerComponent, toValue: value)
			
			if (rawComponents.day != components.day) {
				// Only animate the change if the day value is not a valid date.
				self.setIndexOfComponent(.Day, toValue: components.day, animated: self.isValidValue(components.day, forComponent: .Day))
			}
			
			if (rawComponents.month != components.month) {
				self.setIndexOfComponent(.Month, toValue: components.day, animated: datePickerComponent != .Month)
			}
			
			if (rawComponents.year != components.year) {
				self.setIndexOfComponent(.Year, toValue: components.day, animated: datePickerComponent != .Year)
			}
			
			self.date = self.calendar.dateFromComponents(components)!
			self.sendActionsForControlEvents(.ValueChanged)
		}
		
		self.completionHandler?(datePicker: self, row: row, component: component)
	}
	
	func yearIsSet() -> Bool {
		//get selected row
		let row = self.pickerView.selectedRowInComponent(2)
		let text = self.titleForRow(row, inComponentIndex: 2)
		return text != "----"
	}
	
	public func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
		let label = view as? UILabel == nil ? UILabel() : view as! UILabel
		
		label.font = self.font
		label.textColor = self.textColor
		label.text = self.titleForRow(row, inComponentIndex: component)
		label.textAlignment = NSTextAlignment.Center
		return label
	}
	
	public func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
		let widthBuffer = 25.0
		
		let calendarComponent = self.componentAtIndex(component)
		let stringSizingAttributes = [NSFontAttributeName : self.font]
		var size = 0.01
		
		if calendarComponent == .Month {
			let dateFormatter = self.dateFormatter()
			
			// Get the length of the longest month string and set the size to it.
			for symbol in dateFormatter.monthSymbols as [String] {
				let monthSize = NSString(string: symbol).sizeWithAttributes(stringSizingAttributes)
				size = max(size, Double(monthSize.width))
			}
		} else if calendarComponent == .Day{
			// Pad the day string to two digits
			let dayComponentSizingString = NSString(string: "00")
			size = Double(dayComponentSizingString.sizeWithAttributes(stringSizingAttributes).width)
		} else if calendarComponent == .Year  {
			// Pad the year string to four digits.
			let yearComponentSizingString = NSString(string: "0000")
			size = Double(yearComponentSizingString.sizeWithAttributes(stringSizingAttributes).width)
		}
		
		// Add the width buffer in order to allow the picker components not to run up against the edges
		return CGFloat(size + widthBuffer)
	}
	
	public func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
		return 35
	}
	
	// MARK: UIPickerViewDataSource
	public func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		let calendarComponent = self.componentAtIndex(component)
		return maxValueForComponent(calendarComponent)
	}
	
	func maxValueForComponent(component: IBDatePickerComponents) -> Int {
		let components = calendar.components([.Day , .Month , .Year], fromDate: maximumDate)
		switch component {
		case .Year:
			return components.year
		default:
			return self.maximumNumberOfRows
		}
	}
	
	public func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
		return 3
	}
	
}
